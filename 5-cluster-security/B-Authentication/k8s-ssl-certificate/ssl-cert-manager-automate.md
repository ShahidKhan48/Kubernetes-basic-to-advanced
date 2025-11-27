Perfect! We can fully automate the SSL issuance for both QA and PROD using Cert-Manager with Let’s Encrypt via the ACME protocol. Here’s a clean step-by-step guide:

1️⃣ Install Cert-Manager in the Cluster
# Add Jetstack Helm repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.crds.yaml

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.0


Check pods in cert-manager namespace:

kubectl get pods -n cert-manager


You should see cert-manager, cert-manager-webhook, and cert-manager-cainjector running.

2️⃣ Create ClusterIssuer for Let’s Encrypt

We’ll use DNS-01 challenge (so SSL can be issued even for wildcard or subdomains). Replace your DNS provider with the appropriate solver (Cloudflare, Route53, Azure DNS, etc.). Example with Cloudflare:
---------------------------------------------------
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    email: your-email@ninjacart.in
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-dns-key
    solvers:
    - dns01:
        cloudflare:
          email: your-cloudflare-email
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token

# ---------------------------------------------------------
### explanation##
Line by Line Explanation

apiVersion: cert-manager.io/v1

This specifies the API version for Cert-Manager resources.

kind: ClusterIssuer

ClusterIssuer is a cluster-wide issuer.

It can issue certificates for any namespace.

Unlike Issuer, which is namespace-scoped, ClusterIssuer works across all namespaces.

metadata:

name: letsencrypt-dns → This is the name you use in your Certificate resource to refer to this issuer.

spec: → Defines how Cert-Manager will obtain certificates.

acme: → ACME protocol (used by Let’s Encrypt).

email:

Your email for Let’s Encrypt notifications (expiry alerts, etc.)

server:

ACME endpoint.

https://acme-v02.api.letsencrypt.org/directory is the production server.

You can use https://acme-staging-v02.api.letsencrypt.org/directory for testing.

privateKeySecretRef:

Name of the Kubernetes secret where Cert-Manager stores the private key for ACME.

solvers: → How to prove ownership of the domain.

dns01: → Use a DNS challenge to verify domain ownership.

cloudflare: → This tells Cert-Manager to automatically create TXT records in Cloudflare using API credentials.

email: your-cloudflare-email
apiTokenSecretRef:
  name: cloudflare-api-token-secret
  key: api-token


email → Cloudflare account email (not needed for some token types).

apiTokenSecretRef → Kubernetes secret that holds the Cloudflare API token.

If Your Domain is with GoDaddy

GoDaddy also supports DNS-01 challenges via API. You just need:
# ----------------------------------------------------------------------
Apply it:

kubectl apply -f cluster-issuer.yaml


Cert-Manager will now be ready to issue SSL certificates automatically using ACME protocol.

3️⃣ Create the Certificate for QA
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bifrost-v2-cert
  namespace: qa-bifrost-v2
spec:
  secretName: prod-cert
  issuerRef:
    name: letsencrypt-dns
    kind: ClusterIssuer
  commonName: bifrost-v2.trafyn.info
  dnsNames:
    - bifrost-v2.trafyn.info


Apply:

kubectl apply -f qa-certificate.yaml


Cert-Manager will automatically issue the certificate and store it in the secret prod-cert.

4️⃣ Patch the Ingress to use the new secret
kubectl patch ingress bifrost-v2-ingress -n qa-bifrost-v2 \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/tls/0/secretName", "value": "prod-cert"}]'


After patching, your ingress serves HTTPS using the Let’s Encrypt certificate.

5️⃣ Create the Certificate for PROD
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bifrost-v2-prod-cert
  namespace: prod-bifrost-v2
spec:
  secretName: prod-cert
  issuerRef:
    name: letsencrypt-dns
    kind: ClusterIssuer
  commonName: bifrost-v2.ninjacart.in
  dnsNames:
    - bifrost-v2.ninjacart.in


Apply:

kubectl apply -f prod-certificate.yaml


Patch the ingress:

kubectl patch ingress prod-bifrost-v2-ingress -n prod-bifrost-v2 \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/tls/0/secretName", "value": "prod-cert"}]'

6️⃣ Verify Certificates
kubectl describe certificate -n qa-bifrost-v2 bifrost-v2-cert
kubectl describe certificate -n prod-bifrost-v2 bifrost-v2-prod-cert

# Or check via openssl
openssl s_client -connect bifrost-v2.trafyn.info:443 -servername bifrost-v2.trafyn.info | openssl x509 -noout -dates
openssl s_client -connect bifrost-v2.ninjacart.in:443 -servername bifrost-v2.ninjacart.in | openssl x509 -noout -dates

7️⃣ Auto-Renewal

Cert-Manager automatically renews certificates 30 days before expiry.

You don’t need manual Certbot commands anymore.

Just ensure the ClusterIssuer is valid and your DNS provider allows Cert-Manager to create TXT records for DNS-01 validation.

This method removes all manual steps and keeps QA and PROD certificates fully automated.
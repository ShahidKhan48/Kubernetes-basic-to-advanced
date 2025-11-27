Perfect! Let’s create a fully automated setup using Cert-Manager for your prod domain bifrost-v2.ninjacart.in with GoDaddy DNS. I’ll provide two YAMLs:

ClusterIssuer → Tells Cert-Manager how to get certs from Let’s Encrypt using GoDaddy DNS-01 challenge.

Certificate → Requests a certificate for your domain and stores it in a secret for the Ingress to use.

Step 1: Create Kubernetes Secret for GoDaddy API

First, create a secret with your GoDaddy API key and secret:

kubectl create secret generic godaddy-api-secret \
  --from-literal=api-key="YOUR_GODADDY_KEY" \
  --from-literal=api-secret="YOUR_GODADDY_SECRET" \
  -n cert-manager


Replace YOUR_GODADDY_KEY and YOUR_GODADDY_SECRET with your actual GoDaddy developer API credentials.

Step 2: ClusterIssuer YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-godaddy
spec:
  acme:
    email: your-email@ninjacart.in
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-godaddy-key
    solvers:
      - dns01:
          godaddy:
            apiKeySecretRef:
              name: godaddy-api-secret
              key: api-key
            apiSecretSecretRef:
              name: godaddy-api-secret
              key: api-secret


Explanation:

letsencrypt-godaddy → Name of the ClusterIssuer.

email → Your email for Let’s Encrypt notifications.

privateKeySecretRef → Secret where the ACME account key is stored.

solvers.dns01.godaddy → Configures Cert-Manager to use GoDaddy API for TXT record verification.

Apply it:

kubectl apply -f clusterissuer-godaddy.yaml


Check if ready:

kubectl get clusterissuer letsencrypt-godaddy


It should show READY True.

Step 3: Certificate YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: prod-bifrost-v2-cert
  namespace: prod-bifrost-v2
spec:
  secretName: prod-cert
  issuerRef:
    name: letsencrypt-godaddy
    kind: ClusterIssuer
  commonName: bifrost-v2.ninjacart.in
  dnsNames:
    - bifrost-v2.ninjacart.in


Explanation:

secretName → Name of the Kubernetes TLS secret that will store the certificate.

issuerRef → References the ClusterIssuer we created.

commonName / dnsNames → Domain(s) for the certificate.

Apply it:

kubectl apply -f certificate-prod-bifrost-v2.yaml


Check status:

kubectl describe certificate prod-bifrost-v2-cert -n prod-bifrost-v2


Once ready, it will automatically create the secret prod-cert which your Ingress can reference.

Step 4: Update Ingress

Make sure your Ingress references the prod-cert secret:

spec:
  tls:
    - hosts:
        - bifrost-v2.ninjacart.in
      secretName: prod-cert


Apply Ingress changes:

kubectl apply -f prod-bifrost-v2-ingress.yaml


✅ Done!

Now Cert-Manager will automatically handle:

Certificate issuance using Let’s Encrypt.

Renewals before expiry (no manual certbot commands needed).

DNS-01 validation via GoDaddy API.
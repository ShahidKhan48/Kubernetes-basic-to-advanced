Kubernetes SSL Certificate Issue

Kubernetes TLS Setup – Let’s Encrypt (QA & Prod)

Step 0: Prerequisites
Requirement	Details
Kubernetes Cluster	With Ingress Controller (NGINX recommended) installed
Domain	QA: bifrost-v2.trafyn.info 
Prod: bifrost-v2.ninjacart.in
DNS Access	Ability to create TXT records
Tools	kubectl, certbot, openssl
Step 1: Issue Let’s Encrypt Certificate (Manual DNS)
Environment	Command	Notes
QA	sudo certbot certonly --manual --preferred-challenges dns -d bifrost-v2.trafrost-v2.trafyn.info	Certbot gives a TXT record value; add to your DNS
Prod	sudo certbot certonly --manual --preferred-challenges dns -d bifrost-v2.ninjacart.in	Same as QA
DNS TXT Verification Example:

dig TXT _acme-challenge.bifrost-v2.trafyn.info @8.8.8.8
dig TXT _acme-challenge.bifrost-v2.ninjacart.in @8.8.8.8

Step 2: Copy Certificates for Kubernetes
Environment	Commands
QA	bash sudo cp /etc/letsencrypt/live/bifrost-v2.trafyn.info/fullchain.pem /tmp/ 
sudo cp /etc/letsencrypt/live/bifrost-v2.trafyn.info/privkey.pem /tmp/ 
sudo chmod 644 /tmp/fullchain.pem /tmp/privkey.pem
Prod	bash sudo cp /etc/letsencrypt/live/bifrost-v2.ninjacart.in/fullchain.pem /tmp/ 
sudo cp /etc/letsencrypt/live/bifrost-v2.ninjacart.in/privkey.pem /tmp/ 
sudo chmod 644 /tmp/fullchain.pem /tmp/privkey.pem
Step 3: Create Kubernetes TLS Secret
Environment	Command	Notes
QA	bash kubectl delete secret prod-cert -n qa-bifrost-v2 
bash kubectl create secret tls prod-cert -n qa-bifrost-v2 --cert=/tmp/fullchain.pem --key=/tmp/privkey.pem	Deletes old secret if exists
Prod	bash kubectl delete secret prod-cert -n prod-bifrost-v2 
bash kubectl create secret tls prod-cert -n prod-bifrost-v2 --cert=/tmp/fullchain.pem --key=/tmp/privkey.pem	Same as QA
Verify:

kubectl get secret -n qa-bifrost-v2
kubectl get secret -n prod-bifrost-v2

Step 4: Update Ingress to Use TLS Secret
Environment	Command	Notes
QA	bash kubectl patch ing bifrost-v2-ingress -n qa-bifrost-v2 --type='json' -p='[{"op": "replace", "path": "/spec/tls/0/secretName", "value": "prod-cert"}]'	Ensure secretName matches the created secret
Prod	bash kubectl patch ing prod-bifrost-v2-ingress -n prod-bifrost-v2 --type='json' -p='[{"op": "replace", "path": "/spec/tls/0/secretName", "value": "prod-cert"}]'	Same as QA
Verify:

kubectl get ing bifrost-v2-ingress -n qa-bifrost-v2 -o yaml | grep secretName
kubectl get ing prod-bifrost-v2-ingress -n prod-bifrost-v2 -o yaml | grep secretName

Step 5: Verify HTTPS Certificate
Environment	Command	Example Output
QA	```bash openssl s_client -connect bifrost-v2.trafyn.info:443 -servername bifrost-v2.trafyn.info	openssl x509 -noout -dates```
Prod	```bash openssl s_client -connect bifrost-v2.ninjacart.in:443 -servername bifrost-v2.ninjacart.in	openssl x509 -noout -dates```
✅ Indicates valid Let’s Encrypt certificates are applied successfully.

Step 6: Notes & Recommendations
* Manual DNS certificates do not auto-renew. For auto-renewal, use Cert-Manager or --manual-auth-hook.
* Keep /etc/letsencrypt secure; private keys must not be exposed.
* TLS secrets can be reused for multiple Ingresses if needed.
* Confirm DNS propagation before pressing Enter in Certbot.

Optional Diagram – Flow

[Domain] ---> [DNS TXT record for _acme-challenge] ---> [Certbot] ---> [fullchain.pem + privkey.pem] ---> [Kubernetes TLS Secret] ---> [Ingress] ---> [HTTPS Access]

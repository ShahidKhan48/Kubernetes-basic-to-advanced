# Certificate Management

## 📚 Overview
Kubernetes PKI infrastructure aur X.509 certificate management.

## 🎯 Certificate Types
- **Cluster CA**: Root certificate authority
- **Client Certificates**: User authentication
- **Server Certificates**: API server, etcd, kubelet

## 📖 Certificate Operations

### Generate Client Certificate
```bash
# 1. Generate private key
openssl genrsa -out client.key 2048

# 2. Create CSR
openssl req -new -key client.key -out client.csr -subj "/CN=admin/O=system:masters"

# 3. Sign with cluster CA
openssl x509 -req -in client.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial -out client.crt -days 365
```

### Kubernetes CSR API
```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: user-csr
spec:
  request: LS0tLS1CRUdJTi0tLS0t  # base64 encoded CSR
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
```

## 🔧 Commands
```bash
# Check certificate expiry
kubeadm certs check-expiration

# Renew certificates
kubeadm certs renew all

# Verify certificate
openssl x509 -in client.crt -text -noout
```
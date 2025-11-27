# Authentication

## 📚 Overview
Kubernetes authentication mechanisms aur identity management.

## 📖 Components

### 1. [Certificates](./certificates/)
X.509 client certificates aur PKI management

### 2. [Client Certificates](./client-certs/)
Manual certificate generation aur signing

### 3. [SSL Certificate Management](./k8s-ssl-certificate/)
Automated SSL certificate management with cert-manager

### 4. [Kubeconfig](./kubeconfig/)
Client configuration aur context management

### 5. [OIDC Identity Provider](./oidc-identity-provider/)
External identity provider integration

### 6. [Service Accounts](./service-accounts/)
Pod identity aur token management

### 7. [Token Request API](./token-request-api/)
Secure token generation aur validation

## 🔧 Quick Commands
```bash
# Check current authentication
kubectl config current-context
kubectl auth can-i get pods

# Create service account
kubectl create serviceaccount my-sa
kubectl create token my-sa
```
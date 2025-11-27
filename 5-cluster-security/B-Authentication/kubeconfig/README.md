# Kubeconfig Management

## 📚 Overview
Kubernetes client configuration aur context management.

## 🎯 Kubeconfig Structure
```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTi...
    server: https://api.spicybiryaniwala.shop:6443
  name: production-cluster
users:
- name: admin
  user:
    client-certificate-data: LS0tLS1CRUdJTi...
    client-key-data: LS0tLS1CRUdJTi...
contexts:
- context:
    cluster: production-cluster
    user: admin
    namespace: default
  name: admin@production
current-context: admin@production
```

## 📖 Configuration Management

### Add Cluster
```bash
kubectl config set-cluster production \
  --server=https://api.spicybiryaniwala.shop:6443 \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true
```

### Add User
```bash
# Certificate-based user
kubectl config set-credentials admin \
  --client-certificate=/path/to/admin.crt \
  --client-key=/path/to/admin.key \
  --embed-certs=true

# Token-based user
kubectl config set-credentials developer \
  --token=eyJhbGciOiJSUzI1NiIs...
```

### Create Context
```bash
kubectl config set-context admin@production \
  --cluster=production \
  --user=admin \
  --namespace=default

kubectl config use-context admin@production
```

## 🔧 Multi-cluster Setup
```bash
# Production cluster
kubectl config set-cluster prod \
  --server=https://prod.spicybiryaniwala.shop:6443 \
  --certificate-authority=prod-ca.crt

# Staging cluster  
kubectl config set-cluster staging \
  --server=https://staging.spicybiryaniwala.shop:6443 \
  --certificate-authority=staging-ca.crt

# Development cluster
kubectl config set-cluster dev \
  --server=https://dev.spicybiryaniwala.shop:6443 \
  --certificate-authority=dev-ca.crt
```

## 📋 Best Practices
- Use separate contexts for different environments
- Embed certificates for portability
- Regular credential rotation
- Secure kubeconfig file permissions (600)
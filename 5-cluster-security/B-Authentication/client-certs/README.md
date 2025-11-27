# Client Certificates

## 📚 Overview
Manual client certificate generation for user authentication.

## 📖 Step-by-Step Process

### 1. Generate Private Key
```bash
openssl genrsa -out user.key 2048
```

### 2. Create Certificate Signing Request
```bash
# For admin user
openssl req -new -key user.key -out user.csr -subj "/CN=admin/O=system:masters"

# For developer user
openssl req -new -key dev.key -out dev.csr -subj "/CN=developer/O=developers"
```

### 3. Sign Certificate
```bash
openssl x509 -req -in user.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial -out user.crt -days 365
```

### 4. Configure Kubeconfig
```bash
# Set cluster
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --server=https://api.spicybiryaniwala.shop:6443

# Set user credentials
kubectl config set-credentials admin \
  --client-certificate=user.crt \
  --client-key=user.key

# Create context
kubectl config set-context admin@kubernetes \
  --cluster=kubernetes --user=admin

# Use context
kubectl config use-context admin@kubernetes
```

## 🔒 Security Best Practices
- Store private keys securely
- Regular certificate rotation
- Monitor certificate expiry
- Use strong key lengths (2048+ bits)
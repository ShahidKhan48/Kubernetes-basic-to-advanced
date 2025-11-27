# OIDC Identity Provider

## 📚 Overview
Kubernetes OIDC integration for external identity providers.

## 🎯 OIDC Configuration

### API Server Setup
```bash
# Add to kube-apiserver flags
--oidc-issuer-url=https://accounts.google.com
--oidc-client-id=spicybiryaniwala-k8s.apps.googleusercontent.com
--oidc-username-claim=email
--oidc-groups-claim=groups
--oidc-ca-file=/etc/ssl/certs/ca-certificates.crt
```

### Keycloak Integration
```bash
# Keycloak OIDC configuration
--oidc-issuer-url=https://keycloak.spicybiryaniwala.shop/auth/realms/kubernetes
--oidc-client-id=kubernetes
--oidc-username-claim=preferred_username
--oidc-groups-claim=groups
```

## 📖 Client Configuration

### OIDC Kubeconfig
```yaml
apiVersion: v1
kind: Config
users:
- name: oidc-user
  user:
    auth-provider:
      name: oidc
      config:
        client-id: kubernetes
        client-secret: your-client-secret
        id-token: eyJhbGciOiJSUzI1NiIs...
        idp-issuer-url: https://keycloak.spicybiryaniwala.shop/auth/realms/kubernetes
        refresh-token: eyJhbGciOiJSUzI1NiIs...
```

### kubectl OIDC Plugin
```bash
# Install oidc-login plugin
kubectl krew install oidc-login

# Setup OIDC login
kubectl oidc-login setup \
  --oidc-issuer-url=https://keycloak.spicybiryaniwala.shop/auth/realms/kubernetes \
  --oidc-client-id=kubernetes \
  --oidc-client-secret=your-secret
```

## 🔗 RBAC Integration
```yaml
# Group-based RBAC
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-developers
subjects:
- kind: Group
  name: developers  # OIDC group claim
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
```

## 🔧 Testing
```bash
# Test OIDC authentication
kubectl auth can-i get pods --as=oidc-user

# Verify token claims
echo "eyJhbGciOiJSUzI1NiIs..." | base64 -d | jq .

# Test OIDC endpoint
curl -k https://keycloak.spicybiryaniwala.shop/auth/realms/kubernetes/.well-known/openid_configuration
```

## 📋 Best Practices
- Use short-lived tokens with refresh
- Implement proper group mapping
- Secure HTTPS communication
- Monitor authentication events
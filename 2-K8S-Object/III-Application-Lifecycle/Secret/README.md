# Secrets - Sensitive Data Management

## 📚 Overview
Kubernetes Secrets sensitive information store karne ka secure mechanism hai. Passwords, tokens, keys aur certificates safely manage karta hai.

## 🎯 Secret Types
- **Opaque** - Generic secrets (default)
- **kubernetes.io/tls** - TLS certificates
- **kubernetes.io/dockerconfigjson** - Docker registry credentials
- **kubernetes.io/service-account-token** - Service account tokens

## 📖 Examples

### 1. **Basic Secret**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database-password: cGFzc3dvcmQxMjM=  # base64: password123
  api-key: YWJjZGVmZ2hpams=            # base64: abcdefghijk
  jwt-secret: c2VjcmV0a2V5MTIz         # base64: secretkey123
```

### 2. **TLS Secret**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi...  # base64 encoded certificate
  tls.key: LS0tLS1CRUdJTi...  # base64 encoded private key
```

## 🔧 Usage Patterns

### Environment Variables
```yaml
spec:
  containers:
  - name: app
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database-password
```

### Volume Mounts
```yaml
spec:
  containers:
  - name: app
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secrets
```

## 🛡️ Security Best Practices
- Use RBAC to control access
- Enable encryption at rest
- Rotate secrets regularly
- Use external secret management (Vault, AWS Secrets Manager)

## 🔗 Related Topics
- [ConfigMaps](../configmap/) - Non-sensitive config
- [Environment Variables](../env-variables-application/) - Runtime config

---

**Next:** [Environment Variables](../env-variables-application/) - Runtime Configuration
# Environment Variables - Runtime Configuration

## 📚 Overview
Environment Variables applications ko runtime configuration provide karne ka flexible method hai. ConfigMaps, Secrets, aur field references se values inject kar sakte hain.

## 🎯 Variable Sources
- **Direct values** - Static configuration
- **ConfigMap references** - Non-sensitive config
- **Secret references** - Sensitive data
- **Field references** - Pod/Node metadata
- **Resource references** - Resource limits/requests

## 📖 Examples

### 1. **Multiple Sources**
```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        # Direct values
        - name: APP_ENV
          value: "production"
        
        # From ConfigMap
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_host
        
        # From Secret
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-password
        
        # Field references
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        
        # Resource references
        - name: CPU_LIMIT
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
```

## 🔧 Best Practices
- Use ConfigMaps for non-sensitive data
- Use Secrets for passwords/tokens
- Validate environment variables in application
- Use meaningful variable names
- Document required variables

## 🔗 Related Topics
- [ConfigMaps](../configmap/) - Configuration data
- [Secrets](../Secret/) - Sensitive data

---

**Next:** [Init Containers](../initcontainers/) - Initialization Logic
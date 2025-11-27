# Configure Applications

## 📚 Overview
Application configuration management in Kubernetes using various methods.

## 🎯 Configuration Methods
- **Environment Variables**: Simple key-value pairs
- **ConfigMaps**: Configuration data storage
- **Secrets**: Sensitive data management
- **Volume Mounts**: File-based configuration

## 📖 Configuration Examples

### Environment Variables
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-config
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: APP_ENV
      value: "production"
    - name: DB_HOST
      value: "db.spicybiryaniwala.shop"
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: api-secrets
          key: api-key
```

### ConfigMap Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.properties: |
    host=db.spicybiryaniwala.shop
    port=5432
    database=myapp
  app.yaml: |
    server:
      port: 8080
    logging:
      level: INFO
---
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
  - name: app
    image: myapp:v1.0.0
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
```

## 🔧 Commands
```bash
# Create configmap from file
kubectl create configmap app-config --from-file=config.properties

# Create configmap from literal
kubectl create configmap db-config --from-literal=host=localhost --from-literal=port=5432

# View configmap
kubectl get configmap app-config -o yaml
```

## 📋 Best Practices
- Separate configuration from code
- Use appropriate method for data type
- Version configuration changes
- Validate configuration before deployment
# ConfigMaps - Configuration Management

## 📚 Overview
ConfigMaps non-sensitive configuration data store karne ka mechanism hai. Environment variables, command-line arguments, aur configuration files provide karta hai.

## 🎯 Use Cases
- Application configuration
- Environment-specific settings
- Feature flags
- Database connections (non-sensitive)

## 📖 Examples

### 1. **Basic ConfigMap**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: "db.spicybiryaniwala.shop"
  database_port: "5432"
  log_level: "info"
  feature_flags: "new-ui=true,analytics=false"
```

### 2. **File-based ConfigMap**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
        listen 80;
        server_name spicybiryaniwala.shop;
        
        location / {
            proxy_pass http://backend:8080;
            proxy_set_header Host $host;
        }
        
        location /health {
            return 200 "OK";
        }
    }
```

## 🔧 Usage Patterns

### Environment Variables
```yaml
spec:
  containers:
  - name: app
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
```

### Volume Mounts
```yaml
spec:
  containers:
  - name: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: config-volume
    configMap:
      name: nginx-config
```

## 🔗 Related Topics
- [Secrets](../Secret/) - Sensitive data
- [Environment Variables](../env-variables-application/) - Runtime config

---

**Next:** [Secrets](../Secret/) - Sensitive Configuration
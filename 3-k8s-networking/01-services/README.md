# Services - Network Access & Load Balancing

## 📚 Overview
Kubernetes Services stable network endpoints provide karte hain pods ke liye. Load balancing, service discovery aur external access handle karte hain.

## 🎯 Service Types

### 1. **ClusterIP (Default)**
Internal cluster access only
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-clusterip
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
```

### 2. **NodePort**
External access via node ports (30000-32767)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-nodeport
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

### 3. **LoadBalancer**
Cloud provider load balancer
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-lb
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
```

### 4. **ExternalName**
DNS CNAME mapping
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: database.spicybiryaniwala.shop
```

### 5. **Headless Service**
Direct pod access (clusterIP: None)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-headless
spec:
  clusterIP: None
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
```

## 🔧 Commands
```bash
# List services
kubectl get services

# Expose deployment
kubectl expose deployment app --port=80 --type=LoadBalancer

# Port forward
kubectl port-forward service/app 8080:80

# Check endpoints
kubectl get endpoints
```

## 🔗 Related Topics
- [Ingress](../02-ingress-ingressController/) - HTTP routing
- [DNS](../05-dns-coredns/) - Service discovery

---

**Next:** [Ingress Controllers](../02-ingress-ingressController/) - HTTP/HTTPS Routing
# Namespaces - Network Isolation & Organization

## 📚 Overview
Namespaces logical separation provide karte hain resources ke liye. Multi-tenancy, environment isolation aur resource organization ke liye use hote hain.

## 🎯 Use Cases

### 1. **Environment Separation**
- Development
- Staging  
- Production
- Testing

### 2. **Team Isolation**
- Frontend team
- Backend team
- DevOps team
- Data team

### 3. **Application Isolation**
- Microservices
- Different applications
- Customer environments

## 📖 Examples

### Basic Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: prod
    team: backend
```

### Namespace with Resource Quota
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: development
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "10"
    services: "5"
```

### Network Policy for Namespace
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: namespace-isolation
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: prod
```

## 🔧 Commands
```bash
# Create namespace
kubectl create namespace production

# List namespaces
kubectl get namespaces

# Set default namespace
kubectl config set-context --current --namespace=production

# Delete namespace (deletes all resources)
kubectl delete namespace development
```

## 🔗 Related Topics
- [Network Policies](../07-network-policies/) - Traffic control
- [RBAC](../../5-cluster-security/C-RBAC/) - Access control

---

**Next:** [Network Policies](../07-network-policies/) - Traffic Control & Security
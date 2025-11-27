# Network Policy

## 📚 Overview
Kubernetes network policies for micro-segmentation aur traffic control.

## 📖 Policy Types
- **Ingress**: Incoming traffic control
- **Egress**: Outgoing traffic control
- **Combined**: Both ingress and egress rules

## 🎯 Policy Examples

### Default Deny All
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Allow Frontend to Backend
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### Database Access Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
```

## 🔧 Commands
```bash
# Get network policies
kubectl get networkpolicies --all-namespaces

# Describe policy
kubectl describe networkpolicy frontend-to-backend -n production

# Test connectivity
kubectl exec -it frontend-pod -- nc -zv backend-service 8080
```

## 📋 Best Practices
- Default deny policies
- Least privilege access
- Clear labeling strategy
- Regular policy reviews
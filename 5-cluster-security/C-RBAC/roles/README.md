# Roles

## 📚 Overview
Namespace-scoped permissions for Kubernetes resources.

## 📖 Role Structure
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

## 🎯 Common Role Examples

### Pod Reader
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

### Service Manager
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: service-manager
rules:
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### ConfigMap Secret Manager
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: config-manager
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  resourceNames: ["app-config", "app-secrets"]  # Specific resources
```

## 🔧 Commands
```bash
# Create role
kubectl apply -f role.yaml

# Get roles
kubectl get roles -n production

# Describe role
kubectl describe role pod-reader -n production
```
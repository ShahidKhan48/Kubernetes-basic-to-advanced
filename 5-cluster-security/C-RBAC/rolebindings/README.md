# RoleBindings

## 📚 Overview
Namespace-scoped permission assignments to users, groups, and service accounts.

## 🎯 RoleBinding Examples

### User to Role Binding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
subjects:
- kind: User
  name: john.doe@spicybiryaniwala.shop
  apiGroup: rbac.authorization.k8s.io
- kind: User
  name: jane.smith@spicybiryaniwala.shop
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

### Group to Role Binding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: qa-team-binding
  namespace: testing
subjects:
- kind: Group
  name: qa-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: tester-role
  apiGroup: rbac.authorization.k8s.io
```

### Service Account Binding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: monitoring-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: monitoring-sa
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### ClusterRole in Namespace
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-binding
  namespace: production
subjects:
- kind: User
  name: admin@spicybiryaniwala.shop
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole  # Using ClusterRole in namespace scope
  name: admin
  apiGroup: rbac.authorization.k8s.io
```

## 🔧 Commands
```bash
# Get role bindings
kubectl get rolebindings -n production

# Describe role binding
kubectl describe rolebinding developer-binding -n development

# Check permissions
kubectl auth can-i get pods --as=john.doe@spicybiryaniwala.shop -n development
```

## 📋 Best Practices
- Use groups instead of individual users
- Keep bindings namespace-specific
- Regular binding audits
- Clear naming conventions
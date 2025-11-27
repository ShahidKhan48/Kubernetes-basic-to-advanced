# Least Privilege Access

## 📚 Overview
Minimal permission strategies aur security best practices.

## 🎯 Least Privilege Examples

### Restricted Pod Access
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-logs-reader
rules:
- apiGroups: [""]
  resources: ["pods/log"]  # Only logs, not pod management
  verbs: ["get", "list"]
  resourceNames: ["app-pod-*"]  # Specific pod pattern only
```

### Limited Service Account
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backup-sa
  namespace: production
automountServiceAccountToken: false  # Disable auto-mounting
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: backup-role
rules:
- apiGroups: [""]
  resources: ["persistentvolumes", "persistentvolumeclaims"]
  verbs: ["get", "list"]  # Read-only for backup
```

### Time-bound Access
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: debug-access
  annotations:
    rbac.spicybiryaniwala.shop/expires: "2024-12-31T23:59:59Z"
rules:
- apiGroups: [""]
  resources: ["pods/exec", "pods/log"]
  verbs: ["create", "get"]
```

## 🔧 Permission Auditing
```bash
# Check current permissions
kubectl auth can-i --list --as=system:serviceaccount:production:app-sa

# Audit user permissions
kubectl auth can-i --list --as=john.doe@spicybiryaniwala.shop -n development

# Permission matrix script
#!/bin/bash
USERS=("developer" "tester" "admin")
RESOURCES=("pods" "services" "deployments" "secrets")
VERBS=("get" "list" "create" "update" "delete")

for user in "${USERS[@]}"; do
  echo "=== Permissions for $user ==="
  for resource in "${RESOURCES[@]}"; do
    for verb in "${VERBS[@]}"; do
      if kubectl auth can-i $verb $resource --as=$user -n production >/dev/null 2>&1; then
        echo "✓ $user can $verb $resource"
      fi
    done
  done
done
```

## 🛡️ Security Hardening
```yaml
# Disable default service account auto-mounting
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: production
automountServiceAccountToken: false
```

### Resource Quotas Integration
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: rbac-quota
  namespace: development
spec:
  hard:
    count/rolebindings.rbac.authorization.k8s.io: "10"
    count/roles.rbac.authorization.k8s.io: "5"
```

## 📋 Best Practices
- Start with no permissions
- Add permissions incrementally
- Use specific resource names
- Avoid wildcard permissions
- Regular access reviews
- Automated compliance checks
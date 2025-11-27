# Access Review

## 📚 Overview
RBAC permission auditing aur compliance checking procedures.

## 🎯 Access Review Types

### Self Subject Access Review
```yaml
apiVersion: authorization.k8s.io/v1
kind: SelfSubjectAccessReview
spec:
  resourceAttributes:
    namespace: production
    verb: get
    group: ""
    resource: pods
```

### Subject Access Review
```yaml
apiVersion: authorization.k8s.io/v1
kind: SubjectAccessReview
spec:
  resourceAttributes:
    namespace: production
    verb: create
    group: apps
    resource: deployments
  user: developer@spicybiryaniwala.shop
```

## 🔧 Review Commands
```bash
# Check current user permissions
kubectl auth can-i get pods
kubectl auth can-i create deployments -n production

# Check as different user
kubectl auth can-i get secrets --as=developer -n production

# List all permissions
kubectl auth can-i --list
kubectl auth can-i --list --as=system:serviceaccount:default:app-sa
```

## 📊 Audit Scripts

### Comprehensive RBAC Audit
```bash
#!/bin/bash
# RBAC Audit Script

NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
USERS=("developer" "tester" "admin")

echo "=== RBAC Access Review Report ==="
echo "Generated: $(date)"

# Check user permissions
for user in "${USERS[@]}"; do
  echo "=== User: $user ==="
  kubectl auth can-i --list --as=$user 2>/dev/null | head -20
done

# Check service account permissions
echo "=== Service Account Permissions ==="
kubectl get sa --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers | while read ns sa; do
  echo "SA: $ns/$sa"
  kubectl auth can-i --list --as=system:serviceaccount:$ns:$sa 2>/dev/null | head -5
done
```

### Permission Matrix
```bash
#!/bin/bash
# Generate permission matrix

RESOURCES=("pods" "services" "deployments" "secrets")
VERBS=("get" "list" "create" "update" "delete")
SUBJECTS=("developer" "tester" "admin")

echo "Resource,Verb,Developer,Tester,Admin"
for resource in "${RESOURCES[@]}"; do
  for verb in "${VERBS[@]}"; do
    line="$resource,$verb"
    for subject in "${SUBJECTS[@]}"; do
      if kubectl auth can-i $verb $resource --as=$subject -n production >/dev/null 2>&1; then
        line="$line,✓"
      else
        line="$line,✗"
      fi
    done
    echo $line
  done
done
```

### Compliance Check
```bash
#!/bin/bash
# RBAC Compliance Check

echo "=== RBAC Compliance Report ==="

# Check for cluster-admin bindings
echo "1. Cluster Admin Bindings:"
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name'

# Check for privileged service accounts
echo "2. Privileged Service Accounts:"
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.subjects[]?.kind=="ServiceAccount") | .metadata.name'

# Check for wildcard permissions
echo "3. Wildcard Permissions:"
kubectl get roles,clusterroles --all-namespaces -o json | jq -r '.items[] | select(.rules[]?.resources[]? == "*") | .metadata.name'
```

## 📋 Best Practices
- Monthly access reviews
- Automated compliance checks
- Document access justifications
- Regular permission cleanup
- Audit trail maintenance
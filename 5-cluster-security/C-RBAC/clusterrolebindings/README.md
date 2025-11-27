# ClusterRoleBindings

## 📚 Overview
Cluster-wide permission assignments for system-level access.

## 🎯 ClusterRoleBinding Examples

### Cluster Admin Binding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-binding
subjects:
- kind: User
  name: admin@spicybiryaniwala.shop
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: cluster-admins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

### Monitoring System Binding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-binding
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
- kind: ServiceAccount
  name: grafana
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: monitoring-reader
  apiGroup: rbac.authorization.k8s.io
```

### Node Manager Binding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-manager-binding
subjects:
- kind: ServiceAccount
  name: node-manager
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: system:node
  apiGroup: rbac.authorization.k8s.io
```

### Custom Operator Binding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: application-operator-binding
subjects:
- kind: ServiceAccount
  name: application-operator
  namespace: operator-system
roleRef:
  kind: ClusterRole
  name: application-operator
  apiGroup: rbac.authorization.k8s.io
```

## 🔧 System Bindings
```bash
# View system cluster role bindings
kubectl get clusterrolebindings | grep system:

# Important system bindings
kubectl describe clusterrolebinding cluster-admin
kubectl describe clusterrolebinding system:node
```

## 🔧 Commands
```bash
# Get cluster role bindings
kubectl get clusterrolebindings

# Check cluster-wide permissions
kubectl auth can-i get nodes --as=monitoring-user
kubectl auth can-i --list --as=admin@spicybiryaniwala.shop
```

## 📋 Best Practices
- Minimize cluster-wide permissions
- Use dedicated service accounts
- Regular permission audits
- Document binding purposes
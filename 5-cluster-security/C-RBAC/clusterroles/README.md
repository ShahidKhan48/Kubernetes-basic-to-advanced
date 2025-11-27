# ClusterRoles

## 📚 Overview
Cluster-wide permissions for Kubernetes resources.

## 🎯 ClusterRole Examples

### Node Manager
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-manager
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["nodes/status"]
  verbs: ["update", "patch"]
```

### Monitoring Reader
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/metrics", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "daemonsets", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]
```

### CRD Manager
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: crd-manager
rules:
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["spicybiryaniwala.shop"]
  resources: ["applications", "databases"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

## 🔧 Built-in ClusterRoles
```bash
# View system cluster roles
kubectl get clusterroles | grep system:

# Important built-in roles
kubectl describe clusterrole cluster-admin
kubectl describe clusterrole edit
kubectl describe clusterrole view
```

## 📋 Best Practices
- Avoid cluster-admin when possible
- Use specific resource targeting
- Implement role aggregation
- Document role purposes
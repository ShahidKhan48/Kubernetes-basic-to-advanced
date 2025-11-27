# RBAC (Role-Based Access Control)

## 📚 Overview
Kubernetes authorization system for controlling access to cluster resources.

## 📖 Components

### 1. [Roles](./roles/)
Namespace-scoped permissions for resources

### 2. [ClusterRoles](./clusterroles/)
Cluster-wide permissions for resources

### 3. [RoleBindings](./rolebindings/)
Bind roles to users/groups in namespaces

### 4. [ClusterRoleBindings](./clusterrolebindings/)
Bind cluster roles to users/groups cluster-wide

### 5. [Least Privilege](./least-privilege/)
Minimal permission strategies aur best practices

### 6. [Access Review](./access-review/)
Permission auditing aur compliance checking

## 🎯 RBAC Flow
```
User/Group/ServiceAccount → RoleBinding → Role → Resources
User/Group/ServiceAccount → ClusterRoleBinding → ClusterRole → Resources
```

## 🔧 Quick Commands
```bash
# Check permissions
kubectl auth can-i get pods
kubectl auth can-i create deployments --namespace=production

# List permissions
kubectl auth can-i --list

# Check as different user
kubectl auth can-i get secrets --as=developer
```

## 📋 Best Practices
- Use least privilege principle
- Regular access reviews
- Group-based permissions
- Namespace isolation
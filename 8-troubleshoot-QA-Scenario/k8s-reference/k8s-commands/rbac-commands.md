# RBAC Commands (Role, ClusterRole, RoleBinding, ClusterRoleBinding)

## Role Commands
```bash
# Create Role
kubectl apply -f role.yaml
kubectl create role my-role --verb=get,list,watch --resource=pods

# Get Roles
kubectl get roles
kubectl get roles -A  # all namespaces

# Describe Role
kubectl describe role my-role

# Delete Role
kubectl delete role my-role
```

## ClusterRole Commands
```bash
# Create ClusterRole
kubectl apply -f clusterrole.yaml
kubectl create clusterrole my-cluster-role --verb=get,list,watch --resource=nodes

# Get ClusterRoles
kubectl get clusterroles

# Describe ClusterRole
kubectl describe clusterrole my-cluster-role

# Delete ClusterRole
kubectl delete clusterrole my-cluster-role
```

## RoleBinding Commands
```bash
# Create RoleBinding
kubectl apply -f rolebinding.yaml
kubectl create rolebinding my-role-binding --role=my-role --user=my-user

# Get RoleBindings
kubectl get rolebindings
kubectl get rolebindings -A

# Describe RoleBinding
kubectl describe rolebinding my-role-binding

# Delete RoleBinding
kubectl delete rolebinding my-role-binding
```

## ClusterRoleBinding Commands
```bash
# Create ClusterRoleBinding
kubectl apply -f clusterrolebinding.yaml
kubectl create clusterrolebinding my-cluster-role-binding --clusterrole=my-cluster-role --user=my-user

# Get ClusterRoleBindings
kubectl get clusterrolebindings

# Describe ClusterRoleBinding
kubectl describe clusterrolebinding my-cluster-role-binding

# Delete ClusterRoleBinding
kubectl delete clusterrolebinding my-cluster-role-binding
```

## ServiceAccount Commands
```bash
# Create ServiceAccount
kubectl apply -f serviceaccount.yaml
kubectl create serviceaccount my-service-account

# Get ServiceAccounts
kubectl get serviceaccounts
kubectl get sa

# Describe ServiceAccount
kubectl describe sa my-service-account

# Delete ServiceAccount
kubectl delete sa my-service-account
```
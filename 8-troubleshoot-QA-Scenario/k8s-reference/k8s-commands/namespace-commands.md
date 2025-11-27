# Namespace Commands

## Create Namespace
```bash
kubectl apply -f namespace.yaml
kubectl create namespace my-namespace
```

## Get Namespaces
```bash
kubectl get namespaces
kubectl get ns
```

## Switch Namespace Context
```bash
kubectl config set-context --current --namespace=my-namespace
```

## Get Resources in Namespace
```bash
kubectl get all -n my-namespace
kubectl get pods -n my-namespace
```

## Delete Namespace
```bash
kubectl delete namespace my-namespace
```

## Default Namespaces
- `default` - Default namespace
- `kube-system` - System components
- `kube-public` - Public resources
- `kube-node-lease` - Node lease objects
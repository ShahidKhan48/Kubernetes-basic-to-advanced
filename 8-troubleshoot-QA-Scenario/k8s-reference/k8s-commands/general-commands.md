# General Kubernetes Commands

## Cluster Info
```bash
kubectl cluster-info
kubectl get nodes
kubectl get componentstatuses
```

## Get All Resources
```bash
kubectl get all
kubectl get all -A  # all namespaces
```

## Apply/Delete Multiple Files
```bash
kubectl apply -f .
kubectl delete -f .
```

## Watch Resources
```bash
kubectl get pods -w
kubectl get events -w
```

## Resource Usage
```bash
kubectl top nodes
kubectl top pods
```

## Context Management
```bash
kubectl config get-contexts
kubectl config use-context context-name
kubectl config current-context
```

## Help Commands
```bash
kubectl --help
kubectl get --help
kubectl explain pod
```
# DaemonSet & StatefulSet Commands

## DaemonSet Commands
```bash
# Create DaemonSet
kubectl apply -f daemonset.yaml

# Get DaemonSets
kubectl get daemonsets
kubectl get ds

# Describe DaemonSet
kubectl describe ds my-daemonset

# Delete DaemonSet
kubectl delete ds my-daemonset
```

## StatefulSet Commands
```bash
# Create StatefulSet
kubectl apply -f statefulset.yaml

# Get StatefulSets
kubectl get statefulsets
kubectl get sts

# Scale StatefulSet
kubectl scale sts my-statefulset --replicas=5

# Describe StatefulSet
kubectl describe sts my-statefulset

# Delete StatefulSet
kubectl delete sts my-statefulset

# Get StatefulSet Pods
kubectl get pods -l app=my-stateful-app
```
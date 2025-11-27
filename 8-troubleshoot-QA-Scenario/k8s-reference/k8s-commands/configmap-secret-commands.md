# ConfigMap & Secret Commands

## ConfigMap Commands
```bash
# Create ConfigMap
kubectl apply -f configmap.yaml
kubectl create configmap my-config --from-literal=key1=value1

# Get ConfigMaps
kubectl get configmaps
kubectl get cm

# Describe ConfigMap
kubectl describe configmap my-configmap

# Delete ConfigMap
kubectl delete configmap my-configmap
```

## Secret Commands
```bash
# Create Secret
kubectl apply -f secret.yaml
kubectl create secret generic my-secret --from-literal=username=admin

# Get Secrets
kubectl get secrets

# Describe Secret
kubectl describe secret my-secret

# Decode Secret
kubectl get secret my-secret -o jsonpath='{.data.username}' | base64 -d

# Delete Secret
kubectl delete secret my-secret
```
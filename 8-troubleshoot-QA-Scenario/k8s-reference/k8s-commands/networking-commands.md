# Networking Commands (Ingress, NetworkPolicy, IngressClass)

## Ingress Commands
```bash
# Create Ingress
kubectl apply -f ingress.yaml

# Get Ingress
kubectl get ingress
kubectl get ing

# Describe Ingress
kubectl describe ingress my-ingress

# Delete Ingress
kubectl delete ingress my-ingress
```

## IngressClass Commands
```bash
# Create IngressClass
kubectl apply -f ingressclass.yaml

# Get IngressClasses
kubectl get ingressclass

# Describe IngressClass
kubectl describe ingressclass my-ingress-class

# Delete IngressClass
kubectl delete ingressclass my-ingress-class
```

## NetworkPolicy Commands
```bash
# Create NetworkPolicy
kubectl apply -f networkpolicy.yaml

# Get NetworkPolicies
kubectl get networkpolicies
kubectl get netpol

# Describe NetworkPolicy
kubectl describe networkpolicy my-network-policy

# Delete NetworkPolicy
kubectl delete networkpolicy my-network-policy
```

## Endpoints Commands
```bash
# Get Endpoints
kubectl get endpoints
kubectl get ep

# Describe Endpoints
kubectl describe endpoints my-service
```
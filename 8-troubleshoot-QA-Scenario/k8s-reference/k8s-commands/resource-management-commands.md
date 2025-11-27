# Resource Management Commands (LimitRange, ResourceQuota, PDB, HPA)

## LimitRange Commands
```bash
# Create LimitRange
kubectl apply -f limitrange.yaml

# Get LimitRanges
kubectl get limitranges
kubectl get limits

# Describe LimitRange
kubectl describe limitrange my-limit-range

# Delete LimitRange
kubectl delete limitrange my-limit-range
```

## ResourceQuota Commands
```bash
# Create ResourceQuota
kubectl apply -f resourcequota.yaml

# Get ResourceQuotas
kubectl get resourcequotas
kubectl get quota

# Describe ResourceQuota
kubectl describe quota my-resource-quota

# Delete ResourceQuota
kubectl delete quota my-resource-quota
```

## PodDisruptionBudget Commands
```bash
# Create PDB
kubectl apply -f poddisruptionbudget.yaml

# Get PDBs
kubectl get poddisruptionbudgets
kubectl get pdb

# Describe PDB
kubectl describe pdb my-pdb

# Delete PDB
kubectl delete pdb my-pdb
```

## HorizontalPodAutoscaler Commands
```bash
# Create HPA
kubectl apply -f horizontalpodautoscaler.yaml
kubectl autoscale deployment my-deployment --cpu-percent=70 --min=2 --max=10

# Get HPAs
kubectl get horizontalpodautoscalers
kubectl get hpa

# Describe HPA
kubectl describe hpa my-hpa

# Delete HPA
kubectl delete hpa my-hpa
```

## Events Commands
```bash
# Get Events
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events -w  # watch events

# Get Events for specific object
kubectl get events --field-selector involvedObject.name=my-pod
```
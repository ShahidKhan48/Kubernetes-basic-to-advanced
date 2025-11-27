# Storage Commands (PV, PVC, StorageClass)

## PersistentVolume Commands
```bash
# Create PV
kubectl apply -f persistentvolume.yaml

# Get PVs
kubectl get pv
kubectl get persistentvolumes

# Describe PV
kubectl describe pv my-pv

# Delete PV
kubectl delete pv my-pv
```

## PersistentVolumeClaim Commands
```bash
# Create PVC
kubectl apply -f pvc.yaml

# Get PVCs
kubectl get pvc
kubectl get persistentvolumeclaims

# Describe PVC
kubectl describe pvc my-pvc

# Delete PVC
kubectl delete pvc my-pvc
```

## StorageClass Commands
```bash
# Create StorageClass
kubectl apply -f storageclass.yaml

# Get StorageClasses
kubectl get storageclass
kubectl get sc

# Describe StorageClass
kubectl describe sc my-storage-class

# Set Default StorageClass
kubectl patch storageclass my-storage-class -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Delete StorageClass
kubectl delete sc my-storage-class
```
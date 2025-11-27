# Storage Classes - Dynamic Storage Provisioning

## 📚 Overview
Storage Classes dynamic storage provisioning enable karte hain. PVC create karne par automatically PV provision ho jata hai.

## 🎯 Key Features

### 1. **Dynamic Provisioning**
- Automatic PV creation
- No manual PV management
- On-demand storage allocation

### 2. **Storage Parameters**
- Performance tiers (SSD, HDD)
- Replication settings
- Encryption options

### 3. **Provisioners**
- **kubernetes.io/aws-ebs** - AWS EBS
- **kubernetes.io/gce-pd** - GCE Persistent Disk
- **kubernetes.io/azure-disk** - Azure Disk

## 📖 Examples

### Basic StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
  encrypted: "true"
reclaimPolicy: Delete
allowVolumeExpansion: true
```

### PVC with StorageClass
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 10Gi
```

### StatefulSet with Dynamic Storage
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
spec:
  serviceName: database
  replicas: 3
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 20Gi
```

## 🔧 Commands
```bash
# List storage classes
kubectl get storageclass

# Describe storage class
kubectl describe storageclass <name>

# Set default storage class
kubectl patch storageclass <name> -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## 🔗 Related Topics
- [Persistent Volumes](../02-persistent-volumes/) - Manual provisioning
- [StatefulSets](../../A-workloads/statefulset/) - Ordered storage

---

**Next:** [Examples](../04-examples/) - Complete Storage Examples
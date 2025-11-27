# Persistent Volumes - Cluster Storage Management

## 📚 Overview
Persistent Volumes (PV) cluster-level storage resources hain jo pods se independent exist karte hain. PVC (PersistentVolumeClaim) storage request karta hai.

## 🎯 Key Concepts

### 1. **PersistentVolume (PV)**
- Cluster-level storage resource
- Administrator provisioned
- Independent lifecycle

### 2. **PersistentVolumeClaim (PVC)**
- Storage request by user
- Binds to available PV
- Used in pod specs

### 3. **Access Modes**
- **ReadWriteOnce (RWO)** - Single node read-write
- **ReadOnlyMany (ROX)** - Multiple nodes read-only
- **ReadWriteMany (RWX)** - Multiple nodes read-write

## 📖 Examples

### Basic PV and PVC
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: web-app-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/web-app
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-app-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### Pod using PVC
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app-pod
spec:
  containers:
  - name: web-app
    image: nginx:1.21
    volumeMounts:
    - name: web-storage
      mountPath: /usr/share/nginx/html
  
  volumes:
  - name: web-storage
    persistentVolumeClaim:
      claimName: web-app-pvc
```

## 🔧 Commands
```bash
# Check PVs
kubectl get pv

# Check PVCs
kubectl get pvc

# Describe PV
kubectl describe pv <pv-name>

# Check PVC status
kubectl describe pvc <pvc-name>
```

## 🔗 Related Topics
- [Storage Classes](../03-storage-classes/) - Dynamic provisioning
- [StatefulSets](../../A-workloads/statefulset/) - Ordered storage

---

**Next:** [Storage Classes](../03-storage-classes/) - Dynamic Storage Provisioning
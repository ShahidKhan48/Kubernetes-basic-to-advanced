# Kubernetes Storage Guide

## 📁 Directory Structure

### 01-volumes/
Basic volume types for temporary and configuration data:
- **emptydir.yml** - Temporary storage shared between containers
- **hostpath.yml** - Mount host filesystem into pods
- **configmap-secret.yml** - Configuration and secret volumes

### 02-persistent-volumes/
Persistent storage for stateful applications:
- **pv.yml** - PersistentVolume definitions
- **pvc.yml** - PersistentVolumeClaim examples

### 03-storage-classes/
Dynamic storage provisioning:
- **storage-classes.yml** - StorageClass definitions for different storage types

### 04-examples/
Complete examples combining storage concepts:
- **pod-with-pvc.yml** - Pods using persistent storage
- **statefulset-with-storage.yml** - StatefulSet with volume templates
- **multi-volume-pod.yml** - Pod with multiple volume types

## 🔄 Storage Types Sequence

### 1. Temporary Storage (emptyDir)
```bash
kubectl apply -f 01-volumes/emptydir.yml
kubectl exec -it emptydir-pod -c writer -- sh
```

### 2. Host Storage (hostPath)
```bash
kubectl apply -f 01-volumes/hostpath.yml
kubectl exec -it hostpath-pod -- ls -la /usr/share/nginx/html
```

### 3. Configuration Storage (ConfigMap/Secret)
```bash
kubectl apply -f 01-volumes/configmap-secret.yml
kubectl exec -it configmap-secret-pod -- cat /etc/config/app.properties
```

### 4. Persistent Storage (PV/PVC)
```bash
# Create PV first
kubectl apply -f 02-persistent-volumes/pv.yml

# Create PVC
kubectl apply -f 02-persistent-volumes/pvc.yml

# Use in Pod
kubectl apply -f 04-examples/pod-with-pvc.yml
```

### 5. Dynamic Storage (StorageClass)
```bash
kubectl apply -f 03-storage-classes/storage-classes.yml
kubectl get storageclass
```

### 6. StatefulSet Storage
```bash
kubectl apply -f 04-examples/statefulset-with-storage.yml
kubectl get pvc
```

## 📊 Storage Comparison

| Type | Persistence | Sharing | Use Case |
|------|-------------|---------|----------|
| emptyDir | Pod lifetime | Same pod containers | Temporary files, cache |
| hostPath | Node lifetime | Single node | Node-specific data |
| ConfigMap | Cluster lifetime | Multiple pods | Configuration files |
| Secret | Cluster lifetime | Multiple pods | Sensitive data |
| PV/PVC | Independent | Based on access mode | Databases, file storage |

## 🎯 Best Practices

1. **Use appropriate storage type** for your use case
2. **Set resource limits** on emptyDir volumes
3. **Use StorageClasses** for dynamic provisioning
4. **Implement backup strategies** for persistent data
5. **Monitor storage usage** and set alerts
6. **Use ReadWriteMany** only when necessary
7. **Consider performance requirements** when choosing storage classes

## 🔍 Troubleshooting Commands

```bash
# Check PV status
kubectl get pv

# Check PVC status
kubectl get pvc

# Describe storage issues
kubectl describe pvc <pvc-name>

# Check storage classes
kubectl get storageclass

# Check volume mounts in pod
kubectl describe pod <pod-name>
```
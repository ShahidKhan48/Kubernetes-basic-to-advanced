# Volumes - Data Persistence

## 📚 Overview
Kubernetes Volumes containers ko persistent storage provide karte hain. Data pod restarts ke baad bhi survive karta hai.

## 🎯 Volume Types

### 1. **emptyDir**
- Temporary storage
- Pod lifetime bound
- Shared between containers

### 2. **hostPath**
- Node filesystem access
- Persistent across pod restarts
- Node-specific data

### 3. **configMap/secret**
- Configuration as volumes
- Read-only mounts
- Dynamic updates

## 📖 Examples

### emptyDir Volume
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-storage-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh", "-c", "echo 'Hello World' > /shared/data.txt; sleep 3600"]
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  
  - name: reader
    image: busybox
    command: ["sh", "-c", "while true; do cat /shared/data.txt; sleep 10; done"]
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  
  volumes:
  - name: shared-data
    emptyDir: {}
```

### hostPath Volume
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  containers:
  - name: app
    image: nginx:1.21
    volumeMounts:
    - name: host-storage
      mountPath: /usr/share/nginx/html
  
  volumes:
  - name: host-storage
    hostPath:
      path: /data/nginx
      type: DirectoryOrCreate
```

## 🔧 Commands
```bash
# Check volume mounts
kubectl describe pod <pod-name>

# Execute into pod to check volumes
kubectl exec -it <pod-name> -- ls -la /mounted/path
```

## 🔗 Related Topics
- [Persistent Volumes](../02-persistent-volumes/) - Cluster-wide storage
- [Storage Classes](../03-storage-classes/) - Dynamic provisioning

---

**Next:** [Persistent Volumes](../02-persistent-volumes/) - Cluster Storage Management
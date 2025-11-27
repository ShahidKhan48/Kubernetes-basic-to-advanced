# Storage Troubleshooting Guide

## Common Storage Issues

### 1. PVC Stuck in Pending

**Symptoms:**
- PVC remains in `Pending` status
- Pod cannot start due to volume mount issues

**Diagnosis:**
```bash
kubectl describe pvc <pvc-name>
kubectl get events --field-selector involvedObject.name=<pvc-name>
kubectl get storageclass
```

**Common Causes & Solutions:**

#### No Available Storage Class
```bash
# Check available storage classes
kubectl get storageclass

# Create default storage class
kubectl patch storageclass <storage-class-name> -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### Insufficient Storage
```bash
# Check available storage
kubectl get pv
kubectl describe nodes | grep -A5 "Allocated resources"

# Solution: Add more storage or reduce PVC size
```

#### Zone/Region Mismatch
```bash
# Check node zones
kubectl get nodes --show-labels | grep zone

# Check PV zones
kubectl get pv -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.failure-domain\\.beta\\.kubernetes\\.io/zone
```

### 2. Volume Mount Failures

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Common Issues:**
- Volume not found
- Permission issues
- Mount path conflicts

**Solutions:**
```bash
# Check volume permissions
kubectl exec <pod-name> -- ls -la /mount/path

# Fix permissions
kubectl exec <pod-name> -- chown -R 1000:1000 /mount/path
```

### 3. CSI Driver Issues

**AWS EBS CSI:**
```bash
# Check CSI driver pods
kubectl get pods -n kube-system -l app=ebs-csi-controller
kubectl get pods -n kube-system -l app=ebs-csi-node

# Check CSI driver logs
kubectl logs -n kube-system deployment/ebs-csi-controller
kubectl logs -n kube-system daemonset/ebs-csi-node
```

**Solutions:**
```bash
# Restart CSI driver
kubectl rollout restart deployment/ebs-csi-controller -n kube-system
kubectl rollout restart daemonset/ebs-csi-node -n kube-system

# Check IAM permissions for CSI driver
aws sts get-caller-identity
```

### 4. StatefulSet Storage Issues

**Diagnosis:**
```bash
kubectl describe statefulset <statefulset-name>
kubectl get pvc -l app=<statefulset-name>
```

**Common Issues:**
- PVC template misconfiguration
- Storage class not found
- Volume expansion issues

**Solutions:**
```bash
# Check PVC templates
kubectl get statefulset <name> -o yaml | grep -A10 volumeClaimTemplates

# Expand PVC (if supported)
kubectl patch pvc <pvc-name> -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'
```

## Storage Performance Issues

### 1. Slow I/O Performance

**Diagnosis:**
```bash
# Test disk performance
kubectl run disk-test --image=busybox --rm -it --restart=Never -- sh
# Inside pod:
dd if=/dev/zero of=/tmp/test bs=1M count=1000 oflag=direct

# Check IOPS and throughput
iostat -x 1
```

**Solutions:**
- Use faster storage classes (gp3, io1, io2)
- Increase IOPS provisioning
- Check for CPU throttling

### 2. Volume Attachment Issues

**Diagnosis:**
```bash
# Check volume attachments
kubectl get volumeattachments
kubectl describe volumeattachment <attachment-name>

# Check node capacity
kubectl describe node <node-name> | grep -A10 "Allocated resources"
```

**AWS Specific:**
```bash
# Check EBS volume status
aws ec2 describe-volumes --volume-ids <volume-id>

# Check instance volume limits
aws ec2 describe-instance-types --instance-types <instance-type> --query 'InstanceTypes[0].EbsInfo'
```

## Backup and Recovery Issues

### 1. Volume Snapshot Problems

**Diagnosis:**
```bash
kubectl get volumesnapshots
kubectl describe volumesnapshot <snapshot-name>
kubectl get volumesnapshotcontents
```

**Solutions:**
```bash
# Check snapshot class
kubectl get volumesnapshotclass

# Create manual snapshot
kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: manual-snapshot
spec:
  volumeSnapshotClassName: <snapshot-class>
  source:
    persistentVolumeClaimName: <pvc-name>
EOF
```

### 2. Backup Failures

**Velero Issues:**
```bash
# Check Velero status
kubectl get backups -n velero
kubectl describe backup <backup-name> -n velero

# Check Velero logs
kubectl logs deployment/velero -n velero
```

## Storage Monitoring

### Key Metrics
```bash
# PVC usage
kubectl get pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage

# Storage class usage
kubectl get pv -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName,STATUS:.status.phase

# Volume attachment status
kubectl get volumeattachments -o custom-columns=NAME:.metadata.name,ATTACHED:.status.attached,NODE:.spec.nodeName
```

### Storage Alerts
```yaml
# PVC usage alert
- alert: PVCUsageHigh
  expr: kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.9
  labels:
    severity: warning

# PVC stuck in pending
- alert: PVCPending
  expr: kube_persistentvolumeclaim_status_phase{phase="Pending"} == 1
  for: 5m
```

## Storage Debugging Tools

### Debug Pod with Storage
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-debug
spec:
  containers:
  - name: debug
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "sleep 3600"]
    volumeMounts:
    - name: debug-volume
      mountPath: /data
  volumes:
  - name: debug-volume
    persistentVolumeClaim:
      claimName: <pvc-name>
```

### Useful Storage Commands
```bash
# Check filesystem
kubectl exec <pod-name> -- df -h
kubectl exec <pod-name> -- du -sh /mount/path/*

# Test I/O performance
kubectl exec <pod-name> -- dd if=/dev/zero of=/data/test bs=1M count=100 oflag=direct
kubectl exec <pod-name> -- sync && echo 3 > /proc/sys/vm/drop_caches

# Check mount points
kubectl exec <pod-name> -- mount | grep /data
kubectl exec <pod-name> -- lsblk
```

## Common Storage Fixes

### Force Delete Stuck PVC
```bash
# Remove finalizers
kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers":null}}'

# Force delete
kubectl delete pvc <pvc-name> --force --grace-period=0
```

### Expand PVC
```bash
# Check if storage class supports expansion
kubectl get storageclass <storage-class> -o yaml | grep allowVolumeExpansion

# Expand PVC
kubectl patch pvc <pvc-name> -p '{"spec":{"resources":{"requests":{"storage":"200Gi"}}}}'

# Restart pod to trigger filesystem resize
kubectl delete pod <pod-name>
```

### Fix Permission Issues
```bash
# Create init container to fix permissions
apiVersion: v1
kind: Pod
metadata:
  name: fix-permissions
spec:
  initContainers:
  - name: fix-perms
    image: busybox
    command: ['sh', '-c', 'chown -R 1000:1000 /data && chmod -R 755 /data']
    volumeMounts:
    - name: data
      mountPath: /data
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: <pvc-name>
```

## Storage Best Practices

### Monitoring Storage Health
- Monitor PVC usage and capacity
- Set up alerts for storage issues
- Regular backup testing
- Monitor I/O performance metrics

### Troubleshooting Checklist
1. Check PVC and PV status
2. Verify storage class configuration
3. Check CSI driver health
4. Validate node storage capacity
5. Test I/O performance
6. Check backup and snapshot status
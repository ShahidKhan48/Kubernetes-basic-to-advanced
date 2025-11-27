# StatefulSet Troubleshooting Guide

## Common StatefulSet Issues

### 1. Pods Not Starting in Order

#### Symptoms
```bash
kubectl get pods -l app=mysql
NAME              READY   STATUS    RESTARTS   AGE
mysql-statefulset-0  1/1     Running   0          5m
mysql-statefulset-2  0/1     Pending   0          2m
# mysql-statefulset-1 is missing or not ready
```

#### Troubleshooting Steps
```bash
# Check StatefulSet status
kubectl get statefulset mysql-statefulset
kubectl describe statefulset mysql-statefulset

# Check pod management policy
kubectl get statefulset mysql-statefulset -o jsonpath='{.spec.podManagementPolicy}'

# Check individual pod status
kubectl describe pod mysql-statefulset-1
kubectl logs mysql-statefulset-1
```

#### Common Causes
- Pod 1 is not ready, blocking pod 2 (OrderedReady policy)
- PVC provisioning issues
- Resource constraints
- Init container failures

#### Solutions
```bash
# Check if using Parallel pod management
kubectl patch statefulset mysql-statefulset -p '{"spec":{"podManagementPolicy":"Parallel"}}'

# Force delete stuck pod
kubectl delete pod mysql-statefulset-1 --force --grace-period=0

# Check PVC status
kubectl get pvc -l app=mysql
kubectl describe pvc mysql-data-mysql-statefulset-1
```

### 2. PVC Provisioning Issues

#### Symptoms
```bash
kubectl get pvc
NAME                           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-data-mysql-statefulset-0   Bound     pv-001   10Gi       RWO            fast-ssd       5m
mysql-data-mysql-statefulset-1   Pending                                     fast-ssd       3m
```

#### Troubleshooting
```bash
# Check PVC events
kubectl describe pvc mysql-data-mysql-statefulset-1

# Check storage class
kubectl get storageclass fast-ssd
kubectl describe storageclass fast-ssd

# Check available PVs
kubectl get pv
kubectl describe pv

# Check provisioner logs
kubectl logs -n kube-system -l app=csi-provisioner
```

#### Solutions
```bash
# Create manual PV if needed
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-1
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fast-ssd
  hostPath:
    path: /data/mysql-1
EOF

# Or use different storage class
kubectl patch statefulset mysql-statefulset -p '{"spec":{"volumeClaimTemplates":[{"metadata":{"name":"mysql-data"},"spec":{"storageClassName":"standard"}}]}}'
```

### 3. StatefulSet Update Issues

#### Symptoms
```bash
kubectl rollout status statefulset/mysql-statefulset
# Waiting for statefulset rolling update to complete...
# Update stuck on specific pod
```

#### Troubleshooting
```bash
# Check update strategy
kubectl get statefulset mysql-statefulset -o jsonpath='{.spec.updateStrategy}'

# Check rollout status
kubectl rollout status statefulset/mysql-statefulset --timeout=300s

# Check partition setting
kubectl get statefulset mysql-statefulset -o jsonpath='{.spec.updateStrategy.rollingUpdate.partition}'

# Check pod status during update
kubectl get pods -l app=mysql -w
```

#### Solutions
```bash
# Adjust partition for controlled rollout
kubectl patch statefulset mysql-statefulset -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":1}}}}'

# Force update by deleting pods
kubectl delete pod mysql-statefulset-2
kubectl delete pod mysql-statefulset-1
kubectl delete pod mysql-statefulset-0

# Change to OnDelete strategy for manual control
kubectl patch statefulset mysql-statefulset -p '{"spec":{"updateStrategy":{"type":"OnDelete"}}}'
```

### 4. Headless Service Issues

#### Symptoms
```bash
# DNS resolution not working for individual pods
kubectl exec test-pod -- nslookup mysql-statefulset-0.mysql-headless.default.svc.cluster.local
# nslookup: can't resolve
```

#### Troubleshooting
```bash
# Check headless service
kubectl get service mysql-headless
kubectl describe service mysql-headless

# Verify clusterIP is None
kubectl get service mysql-headless -o jsonpath='{.spec.clusterIP}'

# Check service selector matches StatefulSet
kubectl get service mysql-headless -o jsonpath='{.spec.selector}'
kubectl get statefulset mysql-statefulset -o jsonpath='{.spec.selector.matchLabels}'

# Test DNS resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup mysql-headless.default.svc.cluster.local
```

#### Solutions
```bash
# Ensure service name matches StatefulSet serviceName
kubectl patch statefulset mysql-statefulset -p '{"spec":{"serviceName":"mysql-headless"}}'

# Fix service selector
kubectl patch service mysql-headless -p '{"spec":{"selector":{"app":"mysql"}}}'

# Recreate headless service
kubectl delete service mysql-headless
kubectl expose statefulset mysql-statefulset --port=3306 --cluster-ip=None --name=mysql-headless
```

### 5. Data Persistence Issues

#### Symptoms
```bash
# Data lost after pod restart
kubectl exec mysql-statefulset-0 -- ls -la /var/lib/mysql
# Directory empty or missing expected files
```

#### Troubleshooting
```bash
# Check volume mounts
kubectl describe pod mysql-statefulset-0 | grep -A 10 "Mounts"

# Check PVC binding
kubectl get pvc mysql-data-mysql-statefulset-0
kubectl describe pvc mysql-data-mysql-statefulset-0

# Check PV details
kubectl get pv
kubectl describe pv <pv-name>

# Check if data exists on the volume
kubectl exec mysql-statefulset-0 -- df -h /var/lib/mysql
```

#### Solutions
```bash
# Verify volume claim template
kubectl get statefulset mysql-statefulset -o yaml | grep -A 20 volumeClaimTemplates

# Check mount path in container
kubectl exec mysql-statefulset-0 -- mount | grep mysql

# Restore from backup if needed
kubectl exec mysql-statefulset-0 -- mysql -u root -p < backup.sql
```

## Debugging Commands

### StatefulSet Information
```bash
# Get StatefulSet details
kubectl get statefulsets
kubectl get sts  # Short form
kubectl describe statefulset <statefulset-name>

# Get StatefulSet status
kubectl get statefulset <statefulset-name> -o wide

# Check StatefulSet YAML
kubectl get statefulset <statefulset-name> -o yaml

# Watch StatefulSet changes
kubectl get statefulsets -w
```

### Pod Analysis
```bash
# Get pods for StatefulSet
kubectl get pods -l app=<app-label>
kubectl get pods -l app=<app-label> -o wide

# Check pod order and readiness
kubectl get pods -l app=<app-label> --sort-by=.metadata.name

# Describe specific pod
kubectl describe pod <statefulset-name-0>
kubectl logs <statefulset-name-0>

# Check pod startup order
kubectl get events --sort-by=.metadata.creationTimestamp | grep <statefulset-name>
```

### Volume Analysis
```bash
# Check PVCs for StatefulSet
kubectl get pvc -l app=<app-label>
kubectl describe pvc <pvc-name>

# Check PV binding
kubectl get pv
kubectl describe pv <pv-name>

# Check storage class
kubectl get storageclass
kubectl describe storageclass <storage-class-name>
```

### Service Analysis
```bash
# Check headless service
kubectl get service <headless-service-name>
kubectl describe service <headless-service-name>

# Test DNS resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup <pod-name>.<service-name>.<namespace>.svc.cluster.local

# Check service endpoints
kubectl get endpoints <service-name>
kubectl describe endpoints <service-name>
```

## Common Error Messages

### "Waiting for StatefulSet to roll out"
```bash
# Check update strategy and partition
kubectl get statefulset <name> -o jsonpath='{.spec.updateStrategy}'

# Check pod readiness
kubectl get pods -l app=<app> --sort-by=.metadata.name

# Force update by adjusting partition
kubectl patch statefulset <name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

### "Pod has unbound immediate PersistentVolumeClaims"
```bash
# Check PVC status
kubectl get pvc -l app=<app>
kubectl describe pvc <pvc-name>

# Check storage class availability
kubectl get storageclass
kubectl describe storageclass <storage-class>

# Check PV availability
kubectl get pv --sort-by=.spec.capacity.storage
```

### "StatefulSet is waiting for Pod to be Running and Ready"
```bash
# Check pod status
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Check readiness probe
kubectl get pod <pod-name> -o yaml | grep -A 10 readinessProbe

# Test readiness probe manually
kubectl exec <pod-name> -- <readiness-command>
```

## Best Practices for Troubleshooting

### 1. Check StatefulSet Components
```bash
# StatefulSet, Pods, PVCs, Service
kubectl get statefulset,pods,pvc,service -l app=<app>
```

### 2. Verify Ordered Startup
```bash
# Check if pods start in order (0, 1, 2...)
kubectl get pods -l app=<app> --sort-by=.metadata.name
kubectl get events --sort-by=.metadata.creationTimestamp | grep <statefulset-name>
```

### 3. Test DNS Resolution
```bash
# Test individual pod DNS
kubectl run test-pod --image=busybox --rm -it -- nslookup <pod-name>.<service-name>.<namespace>.svc.cluster.local
```

### 4. Check Volume Persistence
```bash
# Verify data persists across pod restarts
kubectl exec <pod-name> -- ls -la <mount-path>
kubectl delete pod <pod-name>
# Wait for pod to restart
kubectl exec <pod-name> -- ls -la <mount-path>
```

### 5. Monitor Update Process
```bash
# Watch rollout progress
kubectl rollout status statefulset/<name> -w
kubectl get pods -l app=<app> -w
```

### 6. Use Partition for Safe Updates
```bash
# Update one pod at a time
kubectl patch statefulset <name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'
# Verify pod 2 is healthy, then continue
kubectl patch statefulset <name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":1}}}}'
```

### 7. Backup Before Major Changes
```bash
# Backup StatefulSet configuration
kubectl get statefulset <name> -o yaml > statefulset-backup.yaml

# Backup data if possible
kubectl exec <pod-name> -- mysqldump -u root -p --all-databases > backup.sql
```
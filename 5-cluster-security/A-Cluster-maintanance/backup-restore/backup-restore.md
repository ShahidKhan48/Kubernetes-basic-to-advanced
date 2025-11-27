# Backup & Restore - Data Protection Strategies

## 📚 Overview
Kubernetes cluster aur application data ke backup aur restore procedures. etcd backups, application data protection aur disaster recovery strategies.

## 🎯 Backup Components

### 1. **etcd Backup**
Cluster state ka complete backup
```bash
# Create etcd snapshot
ETCDCTL_API=3 etcdctl snapshot save backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify snapshot
ETCDCTL_API=3 etcdctl snapshot status backup.db
```

### 2. **Configuration Backup**
Important cluster configurations
```bash
# Backup Kubernetes configs
cp -r /etc/kubernetes /backup/kubernetes-$(date +%Y%m%d)

# Backup kubelet config
cp -r /var/lib/kubelet /backup/kubelet-$(date +%Y%m%d)

# Export all resources
kubectl get all --all-namespaces -o yaml > /backup/all-resources-$(date +%Y%m%d).yaml
```

### 3. **Application Data Backup**
Persistent volume data protection
```bash
# Backup PV data (example with rsync)
rsync -av /var/lib/docker/volumes/ /backup/volumes/

# Database backup (PostgreSQL example)
kubectl exec postgres-pod -- pg_dump -U postgres dbname > /backup/postgres-$(date +%Y%m%d).sql
```

## 📖 Automated Backup Scripts

### Daily Backup Script
```bash
#!/bin/bash
# Daily backup script for Kubernetes cluster

BACKUP_DIR="/opt/kubernetes-backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"

mkdir -p $BACKUP_PATH

echo "🚀 Starting backup at $(date)"

# etcd backup
echo "💾 Backing up etcd..."
ETCDCTL_API=3 etcdctl snapshot save $BACKUP_PATH/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify etcd backup
ETCDCTL_API=3 etcdctl snapshot status $BACKUP_PATH/etcd-backup.db

# Kubernetes configurations
echo "📄 Backing up configurations..."
cp -r /etc/kubernetes $BACKUP_PATH/
cp -r /var/lib/kubelet $BACKUP_PATH/

# Export all resources
echo "📋 Exporting resources..."
kubectl get all --all-namespaces -o yaml > $BACKUP_PATH/all-resources.yaml
kubectl get pv -o yaml > $BACKUP_PATH/persistent-volumes.yaml
kubectl get pvc --all-namespaces -o yaml > $BACKUP_PATH/persistent-volume-claims.yaml

# Application-specific backups
echo "🗄️ Backing up applications..."

# PostgreSQL backup
kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}' | xargs -I {} \
  kubectl exec {} -- pg_dumpall -U postgres > $BACKUP_PATH/postgres-backup.sql

# MongoDB backup
kubectl get pods -l app=mongodb -o jsonpath='{.items[0].metadata.name}' | xargs -I {} \
  kubectl exec {} -- mongodump --archive > $BACKUP_PATH/mongodb-backup.archive

# Compress backup
echo "🗜️ Compressing backup..."
tar -czf $BACKUP_PATH.tar.gz -C $BACKUP_DIR $DATE

# Clean up old backups (keep 30 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "✅ Backup completed: $BACKUP_PATH.tar.gz"
```

### Backup CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: kube-system
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: etcd-backup
            image: k8s.gcr.io/etcd:3.5.0-0
            command:
            - /bin/sh
            - -c
            - |
              ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-backup-$(date +%Y%m%d-%H%M%S).db \
                --endpoints=https://etcd:2379 \
                --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                --cert=/etc/kubernetes/pki/etcd/server.crt \
                --key=/etc/kubernetes/pki/etcd/server.key
            
            volumeMounts:
            - name: etcd-certs
              mountPath: /etc/kubernetes/pki/etcd
              readOnly: true
            - name: backup-storage
              mountPath: /backup
          
          volumes:
          - name: etcd-certs
            hostPath:
              path: /etc/kubernetes/pki/etcd
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          
          restartPolicy: OnFailure
```

## 🔄 Restore Procedures

### etcd Restore
```bash
# Stop API server and etcd
sudo systemctl stop kube-apiserver
sudo systemctl stop etcd

# Restore from snapshot
ETCDCTL_API=3 etcdctl snapshot restore backup.db \
  --data-dir=/var/lib/etcd-restore \
  --name=master \
  --initial-cluster=master=https://127.0.0.1:2380 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380

# Update etcd data directory
sudo mv /var/lib/etcd /var/lib/etcd-backup
sudo mv /var/lib/etcd-restore /var/lib/etcd

# Start services
sudo systemctl start etcd
sudo systemctl start kube-apiserver

# Verify restore
kubectl get nodes
kubectl get pods --all-namespaces
```

### Application Data Restore
```bash
# PostgreSQL restore
kubectl exec -i postgres-pod -- psql -U postgres < postgres-backup.sql

# MongoDB restore
kubectl exec -i mongodb-pod -- mongorestore --archive < mongodb-backup.archive

# File system restore
rsync -av /backup/volumes/ /var/lib/docker/volumes/
```

### Complete Cluster Restore
```bash
#!/bin/bash
# Complete cluster restore script

BACKUP_FILE=$1
if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file.tar.gz>"
    exit 1
fi

echo "🔄 Starting cluster restore from $BACKUP_FILE"

# Extract backup
RESTORE_DIR="/tmp/restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p $RESTORE_DIR
tar -xzf $BACKUP_FILE -C $RESTORE_DIR

# Stop cluster components
echo "⏹️ Stopping cluster components..."
sudo systemctl stop kubelet
sudo systemctl stop kube-apiserver
sudo systemctl stop kube-controller-manager
sudo systemctl stop kube-scheduler
sudo systemctl stop etcd

# Restore etcd
echo "💾 Restoring etcd..."
ETCDCTL_API=3 etcdctl snapshot restore $RESTORE_DIR/*/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore

sudo mv /var/lib/etcd /var/lib/etcd-backup-$(date +%Y%m%d)
sudo mv /var/lib/etcd-restore /var/lib/etcd

# Restore configurations
echo "📄 Restoring configurations..."
sudo cp -r $RESTORE_DIR/*/kubernetes /etc/
sudo cp -r $RESTORE_DIR/*/kubelet /var/lib/

# Start cluster components
echo "▶️ Starting cluster components..."
sudo systemctl start etcd
sleep 10
sudo systemctl start kube-apiserver
sleep 10
sudo systemctl start kube-controller-manager
sudo systemctl start kube-scheduler
sudo systemctl start kubelet

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
sleep 30

# Verify restore
kubectl get nodes
kubectl get pods --all-namespaces

echo "✅ Cluster restore completed"
```

## 🔧 Monitoring & Verification

### Backup Verification
```bash
# Verify etcd backup
ETCDCTL_API=3 etcdctl snapshot status backup.db --write-out=table

# Test restore in staging
# Create test cluster and restore backup

# Verify backup integrity
sha256sum backup.db > backup.db.sha256
sha256sum -c backup.db.sha256
```

### Backup Monitoring
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backup-monitoring
spec:
  groups:
  - name: backup.rules
    rules:
    - alert: BackupFailed
      expr: increase(backup_job_failures_total[1h]) > 0
      for: 0m
      labels:
        severity: critical
      annotations:
        summary: "Backup job failed"
        description: "Backup job has failed in the last hour"
    
    - alert: BackupOld
      expr: time() - backup_last_success_timestamp > 86400
      for: 0m
      labels:
        severity: warning
      annotations:
        summary: "Backup is old"
        description: "Last successful backup was more than 24 hours ago"
```

## 📊 Best Practices

### 1. **3-2-1 Backup Rule**
- 3 copies of data
- 2 different storage types
- 1 offsite backup

### 2. **Regular Testing**
- Test restore procedures monthly
- Verify backup integrity
- Document restore times
- Train team on procedures

### 3. **Automation**
- Automated daily backups
- Monitoring and alerting
- Retention policies
- Offsite replication

### 4. **Security**
- Encrypt backups
- Secure backup storage
- Access controls
- Audit backup access
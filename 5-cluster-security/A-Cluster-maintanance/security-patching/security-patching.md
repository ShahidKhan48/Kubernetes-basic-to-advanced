# Security Patching - Security Update Procedures

## 📚 Overview
Kubernetes cluster aur components ke security patches safely apply karne ke procedures. CVE management, vulnerability scanning aur patch deployment strategies.

## 🎯 Patching Components

### 1. **Kubernetes Components**
- API Server
- Controller Manager  
- Scheduler
- kubelet
- kube-proxy
- etcd

### 2. **Operating System**
- Kernel updates
- System libraries
- Security packages
- Container runtime

### 3. **Container Images**
- Base images
- Application images
- System containers
- Third-party images

## 📖 Patching Procedures

### Security Assessment
```bash
# Check current versions
kubectl version --short
docker version
containerd --version

# Scan for vulnerabilities
trivy image nginx:latest
clair-scanner nginx:latest

# Check CVE databases
curl -s https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=kubernetes
```

### Kubernetes Component Patching
```bash
#!/bin/bash
# Kubernetes security patch script

PATCH_VERSION=$1
if [ -z "$PATCH_VERSION" ]; then
    echo "Usage: $0 <patch-version>"
    exit 1
fi

echo "🔒 Applying security patches for Kubernetes $PATCH_VERSION"

# Pre-patch backup
echo "💾 Creating backup..."
BACKUP_DIR="/opt/security-patches/$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup etcd
ETCDCTL_API=3 etcdctl snapshot save $BACKUP_DIR/etcd-backup.db

# Backup configs
cp -r /etc/kubernetes $BACKUP_DIR/

# Check for security advisories
echo "📋 Checking security advisories..."
curl -s https://kubernetes.io/docs/reference/issues-security/

# Update package lists
apt-get update

# Patch kubeadm first
echo "🔧 Patching kubeadm..."
apt-mark unhold kubeadm
apt-get install -y kubeadm=$PATCH_VERSION-00
apt-mark hold kubeadm

# Apply patches
echo "⚡ Applying security patches..."
kubeadm upgrade apply v$PATCH_VERSION --yes

# Patch kubelet and kubectl
echo "🔧 Patching kubelet and kubectl..."
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=$PATCH_VERSION-00 kubectl=$PATCH_VERSION-00
apt-mark hold kubelet kubectl

# Restart services
systemctl daemon-reload
systemctl restart kubelet

echo "✅ Security patches applied successfully"
```

### OS Security Patching
```bash
#!/bin/bash
# OS security patching with node rotation

NODE_NAME=$1
if [ -z "$NODE_NAME" ]; then
    echo "Usage: $0 <node-name>"
    exit 1
fi

echo "🔒 Applying OS security patches to $NODE_NAME"

# Drain node
kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data

# SSH to node and apply patches
ssh $NODE_NAME << 'EOF'
    # Update security packages only
    sudo apt-get update
    sudo apt-get upgrade -y --with-new-pkgs
    
    # Check if reboot required
    if [ -f /var/run/reboot-required ]; then
        echo "🔄 Reboot required, rebooting..."
        sudo reboot
    fi
EOF

# Wait for node to come back
echo "⏳ Waiting for node to be ready..."
sleep 120

# Verify node is ready
kubectl wait --for=condition=Ready node/$NODE_NAME --timeout=300s

# Uncordon node
kubectl uncordon $NODE_NAME

echo "✅ OS patches applied to $NODE_NAME"
```

### Container Image Patching
```bash
#!/bin/bash
# Container image security patching

echo "🔒 Scanning and updating container images for security vulnerabilities"

# Get all images in use
kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}' | \
tr ' ' '\n' | sort -u > current-images.txt

# Scan each image
while read image; do
    echo "🔍 Scanning $image"
    
    # Scan for vulnerabilities
    trivy image --severity HIGH,CRITICAL $image
    
    # Check for updates
    if [[ $image == *":"* ]]; then
        base_image=$(echo $image | cut -d':' -f1)
        echo "📦 Checking for updates to $base_image"
        
        # Pull latest tag to check for updates
        docker pull $base_image:latest
        
        # Compare digests
        current_digest=$(docker inspect $image --format='{{.RepoDigests}}')
        latest_digest=$(docker inspect $base_image:latest --format='{{.RepoDigests}}')
        
        if [ "$current_digest" != "$latest_digest" ]; then
            echo "⚠️ Update available for $image"
        fi
    fi
done < current-images.txt

echo "✅ Image security scan completed"
```

## 🚨 Emergency Patching

### Critical CVE Response
```bash
#!/bin/bash
# Emergency patch deployment for critical CVEs

CVE_ID=$1
PATCH_VERSION=$2

if [ -z "$CVE_ID" ] || [ -z "$PATCH_VERSION" ]; then
    echo "Usage: $0 <CVE-ID> <patch-version>"
    exit 1
fi

echo "🚨 Emergency patching for $CVE_ID"

# Create emergency backup
EMERGENCY_BACKUP="/opt/emergency-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $EMERGENCY_BACKUP

# Quick etcd backup
ETCDCTL_API=3 etcdctl snapshot save $EMERGENCY_BACKUP/etcd-emergency.db

# Notify stakeholders
echo "📢 Notifying stakeholders about emergency patch..."
# Send notifications (Slack, email, etc.)

# Apply emergency patch
echo "⚡ Applying emergency patch..."

# For control plane
kubeadm upgrade apply v$PATCH_VERSION --yes --force

# For worker nodes (parallel patching)
kubectl get nodes --no-headers | awk '{print $1}' | while read node; do
    if [[ $node != *"master"* ]] && [[ $node != *"control-plane"* ]]; then
        echo "🔧 Patching worker node: $node"
        
        # Drain node
        kubectl drain $node --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 &
        
        # SSH and patch (in background)
        ssh $node "sudo apt-get update && sudo apt-get install -y kubelet=$PATCH_VERSION-00 && sudo systemctl restart kubelet" &
    fi
done

# Wait for all background jobs
wait

# Uncordon all nodes
kubectl get nodes --no-headers | awk '{print $1}' | while read node; do
    kubectl uncordon $node
done

# Verify cluster health
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

echo "✅ Emergency patch $CVE_ID applied"
```

### Rollback Procedures
```bash
#!/bin/bash
# Security patch rollback

BACKUP_DIR=$1
if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup-directory>"
    exit 1
fi

echo "🔄 Rolling back security patches..."

# Stop services
systemctl stop kubelet kube-apiserver kube-controller-manager kube-scheduler

# Restore etcd
ETCDCTL_API=3 etcdctl snapshot restore $BACKUP_DIR/etcd-backup.db \
  --data-dir=/var/lib/etcd-rollback

mv /var/lib/etcd /var/lib/etcd-patched
mv /var/lib/etcd-rollback /var/lib/etcd

# Restore configs
cp -r $BACKUP_DIR/kubernetes /etc/

# Downgrade packages
PREVIOUS_VERSION=$(cat $BACKUP_DIR/version.txt)
apt-mark unhold kubeadm kubelet kubectl
apt-get install -y kubeadm=$PREVIOUS_VERSION-00 kubelet=$PREVIOUS_VERSION-00 kubectl=$PREVIOUS_VERSION-00
apt-mark hold kubeadm kubelet kubectl

# Start services
systemctl start etcd kube-apiserver kube-controller-manager kube-scheduler kubelet

echo "✅ Rollback completed"
```

## 📊 Vulnerability Management

### Automated Scanning
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: vulnerability-scan
  namespace: security
spec:
  schedule: "0 6 * * *"  # Daily at 6 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: trivy-scanner
            image: aquasec/trivy:latest
            command:
            - /bin/sh
            - -c
            - |
              # Scan all images in cluster
              kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}' | \
              tr ' ' '\n' | sort -u | while read image; do
                echo "Scanning $image"
                trivy image --format json --output /reports/$(echo $image | tr '/' '_' | tr ':' '_').json $image
              done
            
            volumeMounts:
            - name: reports
              mountPath: /reports
          
          volumes:
          - name: reports
            persistentVolumeClaim:
              claimName: scan-reports-pvc
          
          restartPolicy: OnFailure
```

### Patch Management Dashboard
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: patch-dashboard
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Security Patch Management",
        "panels": [
          {
            "title": "CVE Status",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(vulnerability_count) by (severity)"
              }
            ]
          },
          {
            "title": "Patch Compliance",
            "type": "gauge",
            "targets": [
              {
                "expr": "patch_compliance_percentage"
              }
            ]
          },
          {
            "title": "Last Patch Date",
            "type": "stat",
            "targets": [
              {
                "expr": "time() - last_patch_timestamp"
              }
            ]
          }
        ]
      }
    }
```

## 🔧 Best Practices

### 1. **Patch Management Process**
- Regular vulnerability assessments
- Prioritize critical patches
- Test in staging first
- Maintain patch inventory

### 2. **Automation**
- Automated vulnerability scanning
- Patch deployment pipelines
- Rollback procedures
- Compliance monitoring

### 3. **Communication**
- Security advisory subscriptions
- Stakeholder notifications
- Maintenance windows
- Post-patch reports

### 4. **Testing**
- Staging environment testing
- Canary deployments
- Rollback testing
- Performance impact assessment
#!/bin/bash

# Kubernetes Cluster Upgrade Script
# Usage: ./upgrade-script.sh <target-version>

set -e

TARGET_VERSION=${1:-"1.28.0"}
BACKUP_DIR="/opt/kubernetes-backups/$(date +%Y%m%d-%H%M%S)"

echo "🚀 Starting Kubernetes cluster upgrade to version $TARGET_VERSION"

# Pre-upgrade checks
echo "📋 Running pre-upgrade checks..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   exit 1
fi

# Check cluster health
echo "🔍 Checking cluster health..."
kubectl get nodes || { echo "❌ Cannot connect to cluster"; exit 1; }

# Create backup directory
mkdir -p $BACKUP_DIR
echo "📁 Backup directory: $BACKUP_DIR"

# Backup etcd
echo "💾 Creating etcd backup..."
ETCDCTL_API=3 etcdctl snapshot save $BACKUP_DIR/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup
ETCDCTL_API=3 etcdctl snapshot status $BACKUP_DIR/etcd-backup.db

# Backup important configs
echo "📄 Backing up configurations..."
cp -r /etc/kubernetes $BACKUP_DIR/
cp -r /var/lib/kubelet $BACKUP_DIR/

# Upgrade control plane
echo "🔄 Upgrading control plane..."

# Update package lists
apt-get update

# Upgrade kubeadm
echo "📦 Upgrading kubeadm..."
apt-mark unhold kubeadm
apt-get install -y kubeadm=${TARGET_VERSION}-00
apt-mark hold kubeadm

# Verify kubeadm version
kubeadm version

# Plan upgrade
echo "📋 Planning upgrade..."
kubeadm upgrade plan

# Apply upgrade
echo "⚡ Applying upgrade..."
kubeadm upgrade apply v${TARGET_VERSION} --yes

# Upgrade kubelet and kubectl
echo "📦 Upgrading kubelet and kubectl..."
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=${TARGET_VERSION}-00 kubectl=${TARGET_VERSION}-00
apt-mark hold kubelet kubectl

# Restart kubelet
echo "🔄 Restarting kubelet..."
systemctl daemon-reload
systemctl restart kubelet

# Wait for node to be ready
echo "⏳ Waiting for node to be ready..."
sleep 30

# Verify upgrade
echo "✅ Verifying upgrade..."
kubectl get nodes
kubectl version --short

echo "🎉 Control plane upgrade completed successfully!"
echo "📝 Next steps:"
echo "   1. Upgrade worker nodes using: kubectl drain <node> && kubeadm upgrade node"
echo "   2. Verify all pods are running: kubectl get pods --all-namespaces"
echo "   3. Test applications"

echo "💾 Backup location: $BACKUP_DIR"
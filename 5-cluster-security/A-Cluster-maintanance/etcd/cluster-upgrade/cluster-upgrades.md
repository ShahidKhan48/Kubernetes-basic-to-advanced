# Cluster Upgrades - Safe Version Upgrades

## 📚 Overview
Kubernetes cluster upgrades safely perform karne ke procedures. Version compatibility, rolling upgrades aur rollback strategies.

## 🎯 Upgrade Strategy

### 1. **Pre-Upgrade Checklist**
- [ ] Backup etcd cluster
- [ ] Check version compatibility
- [ ] Review breaking changes
- [ ] Test in staging environment
- [ ] Plan maintenance window

### 2. **Upgrade Order**
1. **etcd** (if separate)
2. **Control Plane** components
3. **Worker Nodes**
4. **Add-ons** and plugins

### 3. **Version Skew Policy**
- Control plane: N to N+1
- Nodes: N-1 to N+1
- kubectl: N-1 to N+1

## 📖 Examples

### Control Plane Upgrade
```bash
# Check current version
kubectl version --short

# Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.0-00
sudo apt-mark hold kubeadm

# Plan upgrade
sudo kubeadm upgrade plan

# Apply upgrade
sudo kubeadm upgrade apply v1.28.0

# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
sudo apt-mark hold kubelet kubectl

# Restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### Worker Node Upgrade
```bash
# Drain node
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# On the node:
# Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.0-00
sudo apt-mark hold kubeadm

# Upgrade node
sudo kubeadm upgrade node

# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
sudo apt-mark hold kubelet kubectl

# Restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Uncordon node
kubectl uncordon <node-name>
```

## 🔧 Commands
```bash
# Check upgrade plan
kubeadm upgrade plan

# Verify cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Check component versions
kubectl get nodes -o wide
kubectl version
```

## 🚨 Rollback Procedures
```bash
# If upgrade fails, restore from backup
# Stop API server
sudo systemctl stop kube-apiserver

# Restore etcd
ETCDCTL_API=3 etcdctl snapshot restore backup.db

# Restart components
sudo systemctl start etcd
sudo systemctl start kube-apiserver
```
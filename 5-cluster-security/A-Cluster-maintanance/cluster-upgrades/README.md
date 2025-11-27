# Cluster Upgrades

## 📚 Overview
Kubernetes cluster version upgrades aur control plane maintenance.

## 🎯 Upgrade Process

### Pre-upgrade Checklist
```bash
# Check current version
kubectl version --short
kubeadm version

# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Check component status
kubectl get componentstatuses

# Backup etcd
ETCDCTL_API=3 etcdctl snapshot save backup.db
```

### Control plane Upgrade Steps
```bash
# 1. Upgrade kubeadm
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.28.0-00
apt-mark hold kubeadm

# 2. Plan upgrade
kubeadm upgrade plan

# 3. Apply upgrade
kubeadm upgrade apply v1.28.0

# 4. Upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
apt-mark hold kubelet kubectl

# 5. Restart kubelet
systemctl daemon-reload
systemctl restart kubelet
```

### Worker Node Upgrade
```bash
# 1. Drain node
kubectl drain <node-name> --ignore-daemonsets

# 2. Upgrade kubeadm on node
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.28.0-00
apt-mark hold kubeadm

# 3. Upgrade node
kubeadm upgrade node

# 4. Upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
apt-mark hold kubelet kubectl

# 5. Restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# 6. Uncordon node
kubectl uncordon <node-name>
```

## 📋 Best Practices
- Always backup before upgrade
- Test in staging environment
- Upgrade one node at a time
- Monitor cluster health during upgrade
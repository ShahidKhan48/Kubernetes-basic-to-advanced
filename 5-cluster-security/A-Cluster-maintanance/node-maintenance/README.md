# Node Maintenance

## 📚 Overview
Kubernetes node maintenance procedures aur lifecycle management.

## 🎯 Node Operations

### Node Drain
```bash
# Drain node safely
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Force drain if needed
kubectl drain <node-name> --ignore-daemonsets --force --grace-period=0

# Drain with timeout
kubectl drain <node-name> --ignore-daemonsets --timeout=300s
```

### Node Cordon/Uncordon
```bash
# Cordon node (mark unschedulable)
kubectl cordon <node-name>

# Uncordon node (mark schedulable)
kubectl uncordon <node-name>

# Check node status
kubectl get nodes
```

### Node Replacement
```bash
# 1. Drain old node
kubectl drain <old-node> --ignore-daemonsets --delete-emptydir-data

# 2. Delete node from cluster
kubectl delete node <old-node>

# 3. Join new node
kubeadm token create --print-join-command

# 4. On new node, run join command
kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

### Maintenance Window
```yaml
# PodDisruptionBudget for maintenance
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web-app
```

## 🔧 Monitoring Commands
```bash
# Check node resources
kubectl top nodes
kubectl describe node <node-name>

# Check node conditions
kubectl get nodes -o wide
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type

# Check node events
kubectl get events --field-selector involvedObject.name=<node-name>
```

## 📋 Best Practices
- Always use PodDisruptionBudgets
- Plan maintenance windows
- Monitor application availability
- Keep node documentation updated
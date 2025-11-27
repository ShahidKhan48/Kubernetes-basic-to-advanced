# Node Maintenance - Node Lifecycle Management

## 📚 Overview
Kubernetes nodes ki maintenance procedures - draining, cordoning, patching aur replacement operations safely perform karne ke methods.

## 🎯 Node Operations

### 1. **Node Draining**
Pods ko safely evict karna maintenance ke liye
```bash
# Drain node (evict all pods)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Drain with grace period
kubectl drain <node-name> --grace-period=300 --ignore-daemonsets

# Force drain (use carefully)
kubectl drain <node-name> --force --ignore-daemonsets --delete-emptydir-data
```

### 2. **Node Cordoning**
New pods ko schedule hone se rokna
```bash
# Cordon node (prevent new scheduling)
kubectl cordon <node-name>

# Uncordon node (allow scheduling)
kubectl uncordon <node-name>

# Check node status
kubectl get nodes
```

### 3. **OS Patching**
Operating system updates safely apply karna
```bash
# 1. Drain node
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# 2. SSH to node and update
ssh worker-1
sudo apt update && sudo apt upgrade -y
sudo reboot

# 3. Wait for node to come back
# 4. Uncordon node
kubectl uncordon worker-1
```

## 📖 Maintenance Procedures

### Planned Maintenance
```bash
#!/bin/bash
# Planned node maintenance script

NODE_NAME=$1
if [ -z "$NODE_NAME" ]; then
    echo "Usage: $0 <node-name>"
    exit 1
fi

echo "🔧 Starting maintenance for node: $NODE_NAME"

# Check node status
kubectl get node $NODE_NAME

# Drain node
echo "🚰 Draining node..."
kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data --grace-period=300

# Wait for pods to be evicted
echo "⏳ Waiting for pods to be evicted..."
sleep 60

# Verify no pods running (except DaemonSets)
kubectl get pods --all-namespaces --field-selector spec.nodeName=$NODE_NAME

echo "✅ Node $NODE_NAME is ready for maintenance"
echo "📝 After maintenance, run: kubectl uncordon $NODE_NAME"
```

### Emergency Node Removal
```bash
# If node is completely failed
kubectl delete node <failed-node-name>

# Clean up node resources
kubectl get pods --all-namespaces --field-selector spec.nodeName=<failed-node-name>
kubectl delete pods --all-namespaces --field-selector spec.nodeName=<failed-node-name> --force --grace-period=0
```

### Node Replacement
```bash
# 1. Drain old node
kubectl drain old-node --ignore-daemonsets --delete-emptydir-data

# 2. Remove from cluster
kubectl delete node old-node

# 3. Provision new node
# 4. Join new node to cluster
kubeadm join <control-plane-endpoint> --token <token> --discovery-token-ca-cert-hash <hash>

# 5. Verify new node
kubectl get nodes
kubectl describe node new-node
```

## 🔧 Monitoring Commands

### Node Health Checks
```bash
# Check node conditions
kubectl describe node <node-name> | grep Conditions -A 10

# Check node resources
kubectl top node <node-name>

# Check system pods on node
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name>

# Check node events
kubectl get events --field-selector involvedObject.name=<node-name>
```

### Resource Usage
```bash
# Node resource usage
kubectl top nodes

# Detailed node information
kubectl describe nodes

# Check disk usage on nodes
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, capacity: .status.capacity, allocatable: .status.allocatable}'
```

## 🚨 Troubleshooting

### Node NotReady
```bash
# Check node status
kubectl describe node <node-name>

# Check kubelet logs
ssh <node-name>
sudo journalctl -u kubelet -f

# Check system resources
df -h
free -h
top
```

### Pod Eviction Issues
```bash
# Check PodDisruptionBudgets
kubectl get pdb --all-namespaces

# Force delete stuck pods
kubectl delete pod <pod-name> --force --grace-period=0

# Check for finalizers
kubectl get pod <pod-name> -o yaml | grep finalizers
```

### Network Issues
```bash
# Check node network
kubectl get nodes -o wide

# Test pod-to-pod communication
kubectl run test-pod --image=busybox -it --rm -- ping <pod-ip>

# Check CNI status
ssh <node-name>
sudo systemctl status kubelet
```

## 📊 Best Practices

### 1. **Maintenance Windows**
- Schedule during low traffic
- Notify stakeholders
- Have rollback plan
- Monitor during maintenance

### 2. **Pod Disruption Budgets**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web-app
```

### 3. **Node Affinity**
```yaml
# Spread pods across nodes
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app: web-app
      topologyKey: kubernetes.io/hostname
```

### 4. **Graceful Shutdown**
```yaml
# Configure graceful termination
spec:
  terminationGracePeriodSeconds: 30
  containers:
  - name: app
    lifecycle:
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 15"]
```
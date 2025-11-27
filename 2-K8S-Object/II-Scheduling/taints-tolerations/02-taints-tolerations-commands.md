# Taints and Tolerations Commands Reference

## Taint Management Commands

### Add Taints to Nodes
```bash
# Add NoSchedule taint
kubectl taint node <node-name> key=value:NoSchedule

# Add NoExecute taint
kubectl taint node <node-name> key=value:NoExecute

# Add PreferNoSchedule taint
kubectl taint node <node-name> key=value:PreferNoSchedule

# Examples
kubectl taint node node1 dedicated=gpu:NoSchedule
kubectl taint node node2 maintenance=true:NoExecute
kubectl taint node node3 storage-optimized=true:PreferNoSchedule
```

### View Node Taints
```bash
# Show all node taints
kubectl describe nodes | grep -A 5 Taints

# Show taints for specific node
kubectl describe node <node-name> | grep -A 5 Taints

# Get taints in custom format
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key
```

### Remove Taints from Nodes
```bash
# Remove specific taint
kubectl taint node <node-name> key=value:NoSchedule-

# Remove taint by key only
kubectl taint node <node-name> key-

# Examples
kubectl taint node node1 dedicated=gpu:NoSchedule-
kubectl taint node node2 maintenance-
```

## Common Taint Scenarios

### Master/Control Plane Taints
```bash
# View master node taints
kubectl describe node <master-node> | grep Taints

# Common master taints:
# node-role.kubernetes.io/master:NoSchedule
# node-role.kubernetes.io/control-plane:NoSchedule
```

### Dedicated Node Taints
```bash
# Dedicate node for GPU workloads
kubectl taint node gpu-node dedicated=gpu:NoSchedule
kubectl label node gpu-node accelerator=nvidia-tesla-k80

# Dedicate node for database
kubectl taint node db-node dedicated=database:NoSchedule
kubectl label node db-node workload-type=database

# Dedicate node for monitoring
kubectl taint node monitor-node dedicated=monitoring:NoSchedule
kubectl label node monitor-node monitoring=true
```

### Maintenance Taints
```bash
# Mark node for maintenance (evict pods)
kubectl taint node <node-name> maintenance=true:NoExecute

# Mark node as unschedulable (no new pods)
kubectl taint node <node-name> maintenance=true:NoSchedule

# Remove maintenance taint
kubectl taint node <node-name> maintenance-
```

## Toleration Configuration

### Pod Tolerations
```bash
# Create pod with toleration
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
# Edit pod.yaml to add tolerations, then:
kubectl apply -f pod.yaml

# Patch existing pod (limited)
kubectl patch pod nginx -p '{"spec":{"tolerations":[{"key":"dedicated","operator":"Equal","value":"gpu","effect":"NoSchedule"}]}}'
```

### Deployment Tolerations
```bash
# Update deployment with tolerations
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"dedicated","operator":"Equal","value":"gpu","effect":"NoSchedule"}]}}}}'

# Add multiple tolerations
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"dedicated","operator":"Equal","value":"gpu","effect":"NoSchedule"},{"key":"maintenance","operator":"Exists","effect":"NoExecute","tolerationSeconds":300}]}}}}'
```

## Troubleshooting Commands

### Debug Scheduling Issues
```bash
# Check pod status
kubectl get pods -o wide

# Check pod events
kubectl describe pod <pod-name>

# Check node taints
kubectl describe node <node-name> | grep -A 5 Taints

# Check if pod has required tolerations
kubectl get pod <pod-name> -o yaml | grep -A 10 tolerations
```

### Check Taint Effects
```bash
# NoSchedule: New pods won't be scheduled
# NoExecute: Existing pods will be evicted
# PreferNoSchedule: Scheduler tries to avoid but not guaranteed

# Check pods on tainted nodes
kubectl get pods --field-selector spec.nodeName=<tainted-node-name>

# Check evicted pods
kubectl get pods --field-selector status.phase=Failed
```

## Advanced Taint Operations

### Conditional Taints
```bash
# Taint based on node condition
kubectl taint node <node-name> node.kubernetes.io/disk-pressure:NoSchedule

# Common condition taints:
# node.kubernetes.io/not-ready:NoExecute
# node.kubernetes.io/unreachable:NoExecute
# node.kubernetes.io/disk-pressure:NoSchedule
# node.kubernetes.io/memory-pressure:NoSchedule
# node.kubernetes.io/pid-pressure:NoSchedule
```

### Batch Taint Operations
```bash
# Taint multiple nodes
kubectl get nodes -l environment=production -o name | xargs -I {} kubectl taint {} dedicated=production:NoSchedule

# Remove taints from multiple nodes
kubectl get nodes -l maintenance=true -o name | xargs -I {} kubectl taint {} maintenance-

# Taint all worker nodes
kubectl taint nodes --all dedicated=workload:NoSchedule --overwrite
```

### Toleration Operators
```bash
# Equal operator (exact match)
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "gpu"
  effect: "NoSchedule"

# Exists operator (key exists, ignore value)
tolerations:
- key: "dedicated"
  operator: "Exists"
  effect: "NoSchedule"

# Tolerate all taints
tolerations:
- operator: "Exists"
```

## Best Practices

### System Pods
```bash
# DaemonSets should tolerate all taints
tolerations:
- operator: Exists

# System pods should tolerate master taints
tolerations:
- key: node-role.kubernetes.io/master
  operator: Exists
  effect: NoSchedule
```

### Application Isolation
```bash
# Dedicate nodes for specific applications
kubectl taint node app-node dedicated=myapp:NoSchedule
kubectl label node app-node app=myapp

# Use both nodeSelector and tolerations
nodeSelector:
  app: myapp
tolerations:
- key: dedicated
  operator: Equal
  value: myapp
  effect: NoSchedule
```

### Maintenance Windows
```bash
# Drain node for maintenance
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Or use NoExecute taint for gradual eviction
kubectl taint node <node-name> maintenance=true:NoExecute

# Uncordon after maintenance
kubectl uncordon <node-name>
kubectl taint node <node-name> maintenance-
```
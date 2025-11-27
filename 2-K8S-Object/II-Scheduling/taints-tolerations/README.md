# Taints & Tolerations - Node Restrictions

## 📚 Overview
Taints aur Tolerations nodes ko specific workloads ke liye dedicate karne ka mechanism hai. Taints nodes par restrictions lagata hai, Tolerations pods ko un restrictions ko bypass karne ki permission deta hai.

## 🎯 How it Works

### Concept
```
Node Taint (Restriction) + Pod Toleration (Permission) = Scheduling Allowed
```

### Taint Effects
- **NoSchedule** - New pods won't be scheduled
- **PreferNoSchedule** - Avoid scheduling if possible
- **NoExecute** - Evict existing pods + no new scheduling

## 📖 Examples

### 1. Basic Taint & Toleration
```yaml
# 01-taints-tolerations-basic.yaml
apiVersion: v1
kind: Pod
metadata:
  name: dedicated-pod
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
  
  containers:
  - name: postgres
    image: postgres:13
    env:
    - name: POSTGRES_PASSWORD
      value: "password"
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
```

### 2. Multiple Tolerations
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: system-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: system-app
  template:
    metadata:
      labels:
        app: system-app
    spec:
      tolerations:
      # Tolerate dedicated nodes
      - key: "dedicated"
        operator: "Equal"
        value: "system"
        effect: "NoSchedule"
      
      # Tolerate any taint with specific effect
      - key: "maintenance"
        operator: "Exists"
        effect: "PreferNoSchedule"
      
      # Tolerate node being unready
      - key: "node.kubernetes.io/not-ready"
        operator: "Exists"
        effect: "NoExecute"
        tolerationSeconds: 300
      
      containers:
      - name: app
        image: spicybiryaniwala.shop/system-app:latest
```

### 3. GPU Node Dedication
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ml-training-pod
spec:
  tolerations:
  - key: "nvidia.com/gpu"
    operator: "Exists"
    effect: "NoSchedule"
  
  nodeSelector:
    accelerator: nvidia-tesla-v100
  
  containers:
  - name: ml-trainer
    image: tensorflow/tensorflow:latest-gpu
    resources:
      limits:
        nvidia.com/gpu: 2
      requests:
        memory: 8Gi
        cpu: 4000m
```

### 4. Production Node Isolation
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-critical-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      tolerations:
      # Production nodes taint
      - key: "environment"
        operator: "Equal"
        value: "production"
        effect: "NoSchedule"
      
      # High priority taint
      - key: "priority"
        operator: "Equal"
        value: "high"
        effect: "NoSchedule"
      
      # Node maintenance toleration
      - key: "node.kubernetes.io/unschedulable"
        operator: "Exists"
        effect: "NoSchedule"
        tolerationSeconds: 600
      
      containers:
      - name: app
        image: spicybiryaniwala.shop/critical-app:v1.0.0
        resources:
          requests:
            memory: 1Gi
            cpu: 500m
          limits:
            memory: 2Gi
            cpu: 1000m
        
        # Health checks for critical app
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

## 🔧 Taint Management Commands

### Apply Taints
```bash
# Basic taint
kubectl taint nodes node1 key=value:NoSchedule

# Dedicated database node
kubectl taint nodes db-node-1 dedicated=database:NoSchedule

# GPU node dedication
kubectl taint nodes gpu-node-1 nvidia.com/gpu=true:NoSchedule

# Production environment
kubectl taint nodes prod-node-1 environment=production:NoSchedule

# Maintenance mode
kubectl taint nodes node1 maintenance=true:PreferNoSchedule

# Evict existing pods
kubectl taint nodes node1 critical=true:NoExecute
```

### Remove Taints
```bash
# Remove specific taint
kubectl taint nodes node1 key=value:NoSchedule-

# Remove all taints with specific key
kubectl taint nodes node1 dedicated-

# Remove maintenance taint
kubectl taint nodes node1 maintenance-
```

### View Taints
```bash
# Check node taints
kubectl describe node node1 | grep Taints

# Get all nodes with taints
kubectl get nodes -o json | jq '.items[] | select(.spec.taints != null) | {name: .metadata.name, taints: .spec.taints}'

# Check specific taint
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

## 🚨 Common Use Cases

### 1. **Dedicated Node Pools**
```bash
# Database nodes
kubectl taint nodes db-node-1 db-node-2 dedicated=database:NoSchedule

# GPU nodes
kubectl taint nodes gpu-node-1 gpu-node-2 nvidia.com/gpu=true:NoSchedule

# System nodes
kubectl taint nodes system-node-1 node-role.kubernetes.io/master:NoSchedule
```

### 2. **Environment Isolation**
```bash
# Production nodes
kubectl taint nodes prod-node-1 prod-node-2 environment=production:NoSchedule

# Development nodes
kubectl taint nodes dev-node-1 dev-node-2 environment=development:NoSchedule
```

### 3. **Maintenance Operations**
```bash
# Drain node for maintenance
kubectl taint nodes node1 maintenance=true:NoExecute

# Prevent new scheduling during updates
kubectl taint nodes node1 updating=true:NoSchedule
```

## 🛡️ Best Practices

### 1. **Consistent Taint Strategy**
```bash
# Use standard keys
kubectl taint nodes node1 workload-type=database:NoSchedule
kubectl taint nodes node2 environment=production:NoSchedule
kubectl taint nodes node3 priority=high:NoSchedule
```

### 2. **Graceful Eviction**
```yaml
tolerations:
- key: "maintenance"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 300  # 5 minutes grace period
```

### 3. **System Pod Tolerations**
```yaml
# System pods should tolerate common taints
tolerations:
- operator: "Exists"
  effect: "NoSchedule"
- operator: "Exists"
  effect: "PreferNoSchedule"
- operator: "Exists"
  effect: "NoExecute"
```

## 🚨 Troubleshooting

### Pod Stuck in Pending
```bash
# Check pod tolerations
kubectl describe pod <pod-name> | grep -A 10 Tolerations

# Check node taints
kubectl describe nodes | grep -A 5 Taints

# Check scheduling events
kubectl get events --field-selector reason=FailedScheduling
```

### Pods Being Evicted
```bash
# Check NoExecute taints
kubectl get nodes -o json | jq '.items[] | select(.spec.taints[]?.effect == "NoExecute")'

# Check pod toleration seconds
kubectl describe pod <pod-name> | grep tolerationSeconds

# Check eviction events
kubectl get events --field-selector reason=Evicted
```

## 📊 Toleration Operators

### Equal Operator
```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "database"
  effect: "NoSchedule"
```

### Exists Operator
```yaml
tolerations:
- key: "maintenance"
  operator: "Exists"
  effect: "NoSchedule"

# Tolerate any taint
- operator: "Exists"
```

## 📋 Practical Examples

### Example 1: Database Node Dedication
```bash
# 1. Taint database nodes
kubectl taint nodes db-node-1 dedicated=database:NoSchedule

# 2. Deploy database with toleration
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "database"
        effect: "NoSchedule"
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_PASSWORD
          value: "password"
EOF

# 3. Verify placement
kubectl get pods -o wide
```

### Example 2: Node Maintenance
```bash
# 1. Mark node for maintenance (evict pods)
kubectl taint nodes node1 maintenance=true:NoExecute

# 2. Wait for pods to be evicted
kubectl get pods -o wide

# 3. Perform maintenance
# ... maintenance tasks ...

# 4. Remove maintenance taint
kubectl taint nodes node1 maintenance-

# 5. Verify node is schedulable
kubectl describe node node1 | grep Taints
```

### Example 3: GPU Workload Isolation
```bash
# 1. Taint GPU nodes
kubectl taint nodes gpu-node-1 nvidia.com/gpu=true:NoSchedule

# 2. Deploy GPU workload
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: gpu-job
spec:
  tolerations:
  - key: "nvidia.com/gpu"
    operator: "Exists"
    effect: "NoSchedule"
  containers:
  - name: gpu-app
    image: tensorflow/tensorflow:latest-gpu
    resources:
      limits:
        nvidia.com/gpu: 1
EOF
```

## 🔗 Related Topics
- **[Node Selectors](../node-selector/)** - Basic node selection
- **[Affinity & Anti-Affinity](../affinity-antiaffinity/)** - Advanced placement
- **[Priority Classes](../priority-class/)** - Pod priorities

---

**Next:** [Affinity & Anti-Affinity](../affinity-antiaffinity/) - Advanced Placement Rules
# Node Selectors - Basic Node Selection

## 📚 Overview
Node Selectors Kubernetes mein sabse simple way hai pods ko specific nodes par schedule karne ka. Ye label-based matching use karta hai.

## 🎯 What is Node Selector?

### Definition
- **Label-based** node selection mechanism
- **Simple key-value** matching
- **Static scheduling** constraint
- **Basic node targeting**

### How it Works
```
Pod with nodeSelector → Scheduler → Matching Node Labels → Pod Placement
```

## 📖 Examples

### 1. Basic Node Selector
```yaml
# 01-node-selector-basic.yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  nodeSelector:
    accelerator: nvidia-tesla-k80
    node-type: gpu
  containers:
  - name: ml-app
    image: tensorflow/tensorflow:latest-gpu
    resources:
      limits:
        nvidia.com/gpu: 1
```

### 2. Environment-based Selection
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: production-app
  template:
    metadata:
      labels:
        app: production-app
    spec:
      nodeSelector:
        environment: production
        node-tier: high-performance
      containers:
      - name: app
        image: spicybiryaniwala.shop/app:v1.0.0
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
```

### 3. Storage-specific Selection
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: database-pod
spec:
  nodeSelector:
    storage-type: ssd
    zone: us-west-1a
  containers:
  - name: postgres
    image: postgres:13
    env:
    - name: POSTGRES_PASSWORD
      value: "password"
    volumeMounts:
    - name: postgres-storage
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: postgres-storage
    persistentVolumeClaim:
      claimName: postgres-pvc
```

## 🔧 Node Management Commands

### Label Nodes
```bash
# Add labels to nodes
kubectl label nodes node1 accelerator=nvidia-tesla-k80
kubectl label nodes node1 node-type=gpu
kubectl label nodes node2 environment=production
kubectl label nodes node3 storage-type=ssd

# View node labels
kubectl get nodes --show-labels
kubectl describe node node1

# Remove labels
kubectl label nodes node1 accelerator-
```

### Check Pod Scheduling
```bash
# Check where pods are scheduled
kubectl get pods -o wide

# Check scheduling events
kubectl describe pod gpu-pod

# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## 🚨 Common Use Cases

### 1. **Hardware-specific Workloads**
```yaml
# GPU nodes for ML/AI
nodeSelector:
  accelerator: nvidia-tesla-v100
  gpu-memory: 32gb

# High-memory nodes for analytics
nodeSelector:
  memory-type: high-memory
  instance-type: r5.xlarge
```

### 2. **Geographic Distribution**
```yaml
# Zone-specific deployment
nodeSelector:
  topology.kubernetes.io/zone: us-west-1a
  failure-domain.beta.kubernetes.io/region: us-west-1
```

### 3. **Environment Isolation**
```yaml
# Production workloads
nodeSelector:
  environment: production
  security-level: high

# Development workloads
nodeSelector:
  environment: development
  cost-optimization: spot-instances
```

## 🛡️ Best Practices

### 1. **Consistent Labeling**
```bash
# Standard labels
kubectl label nodes node1 environment=production
kubectl label nodes node1 node-type=application
kubectl label nodes node1 zone=us-west-1a
kubectl label nodes node1 instance-type=m5.large
```

### 2. **Fallback Strategy**
```yaml
# Use with node affinity for flexibility
spec:
  nodeSelector:
    environment: production
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 50
        preference:
          matchExpressions:
          - key: node-type
            operator: In
            values:
            - high-performance
```

### 3. **Resource Matching**
```yaml
spec:
  nodeSelector:
    node-type: memory-optimized
  containers:
  - name: app
    resources:
      requests:
        memory: 8Gi
      limits:
        memory: 16Gi
```

## 🚨 Troubleshooting

### Pod Stuck in Pending
```bash
# Check scheduling events
kubectl describe pod <pod-name>

# Verify node labels exist
kubectl get nodes -l accelerator=nvidia-tesla-k80

# Check node availability
kubectl get nodes --show-labels | grep gpu
```

### No Matching Nodes
```bash
# List all node labels
kubectl get nodes --show-labels

# Check specific label
kubectl get nodes -l environment=production

# Add missing labels
kubectl label nodes node1 environment=production
```

## 📋 Practical Examples

### Example 1: GPU Workload
```bash
# 1. Label GPU node
kubectl label nodes gpu-node-1 accelerator=nvidia-tesla-k80

# 2. Deploy GPU pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: gpu-workload
spec:
  nodeSelector:
    accelerator: nvidia-tesla-k80
  containers:
  - name: gpu-app
    image: tensorflow/tensorflow:latest-gpu
EOF

# 3. Verify placement
kubectl get pod gpu-workload -o wide
```

### Example 2: Environment Separation
```bash
# 1. Label nodes by environment
kubectl label nodes prod-node-1 environment=production
kubectl label nodes dev-node-1 environment=development

# 2. Deploy to production
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prod-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: prod-app
  template:
    metadata:
      labels:
        app: prod-app
    spec:
      nodeSelector:
        environment: production
      containers:
      - name: app
        image: nginx:1.21
EOF
```

## 🔗 Related Topics
- **[Affinity & Anti-Affinity](../affinity-antiaffinity/)** - Advanced placement
- **[Taints & Tolerations](../taints-tolerations/)** - Node restrictions
- **[Multiple Schedulers](../multiple-scheduler/)** - Custom scheduling

---

**Next:** [Taints & Tolerations](../taints-tolerations/) - Node Restrictions
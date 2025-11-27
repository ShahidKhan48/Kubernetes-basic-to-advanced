# Affinity & Anti-Affinity - Advanced Placement Rules

## 📚 Overview
Affinity aur Anti-Affinity advanced scheduling mechanisms hain jo complex placement rules define karne ke liye use hote hain. Ye Node Selectors se zyada flexible aur powerful hain.

## 🎯 Types of Affinity

### 1. **Node Affinity** - Pod-to-Node placement
### 2. **Pod Affinity** - Pod-to-Pod co-location  
### 3. **Pod Anti-Affinity** - Pod-to-Pod separation

### Scheduling Types
- **requiredDuringSchedulingIgnoredDuringExecution** - Hard requirement
- **preferredDuringSchedulingIgnoredDuringExecution** - Soft preference

## 📖 Examples

### 1. Node Affinity - Basic
```yaml
# 01-affinity-basic.yaml
apiVersion: v1
kind: Pod
metadata:
  name: node-affinity-pod
spec:
  affinity:
    nodeAffinity:
      # Hard requirement
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64
          - key: node-type
            operator: In
            values:
            - high-performance
      
      # Soft preference
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 80
        preference:
          matchExpressions:
          - key: zone
            operator: In
            values:
            - us-west-1a
      - weight: 20
        preference:
          matchExpressions:
          - key: instance-type
            operator: In
            values:
            - m5.xlarge
  
  containers:
  - name: app
    image: spicybiryaniwala.shop/app:latest
```

### 2. Pod Anti-Affinity - High Availability
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-ha
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      affinity:
        # Spread pods across different nodes
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-app
            topologyKey: kubernetes.io/hostname
          
          # Prefer different zones
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - web-app
              topologyKey: topology.kubernetes.io/zone
      
      containers:
      - name: web-app
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

### 3. Pod Affinity - Co-location
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      affinity:
        # Co-locate with web-app pods
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - web-app
              topologyKey: kubernetes.io/hostname
        
        # But spread cache pods across nodes
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 50
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - cache
              topologyKey: kubernetes.io/hostname
      
      containers:
      - name: redis
        image: redis:7-alpine
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
```

### 4. Complex Multi-Tier Application
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: database
      tier: data
  template:
    metadata:
      labels:
        app: database
        tier: data
        component: postgres
    spec:
      affinity:
        # Node requirements for database
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: storage-type
                operator: In
                values:
                - ssd
              - key: node-type
                operator: In
                values:
                - database
          
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 80
            preference:
              matchExpressions:
              - key: zone
                operator: In
                values:
                - us-west-1a
                - us-west-1b
          - weight: 20
            preference:
              matchExpressions:
              - key: instance-type
                operator: In
                values:
                - r5.xlarge
                - r5.2xlarge
        
        # Database anti-affinity for HA
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - database
            topologyKey: kubernetes.io/hostname
          
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: tier
                  operator: In
                  values:
                  - data
              topologyKey: topology.kubernetes.io/zone
      
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        resources:
          requests:
            cpu: 1000m
            memory: 2Gi
          limits:
            cpu: 2000m
            memory: 4Gi
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```

### 5. Microservices with Affinity Rules
```yaml
# Frontend deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 4
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: web
    spec:
      affinity:
        # Prefer nodes with web workloads
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 50
            preference:
              matchExpressions:
              - key: workload-type
                operator: In
                values:
                - web
        
        # Spread across zones for HA
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - frontend
              topologyKey: topology.kubernetes.io/zone
          - weight: 50
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - frontend
              topologyKey: kubernetes.io/hostname
      
      containers:
      - name: frontend
        image: spicybiryaniwala.shop/frontend:v1.0.0
---
# Backend deployment with affinity to frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 6
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        tier: api
    spec:
      affinity:
        # Co-locate with frontend for low latency
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 80
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: tier
                  operator: In
                  values:
                  - web
              topologyKey: kubernetes.io/hostname
        
        # But spread backend pods
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - backend
              topologyKey: kubernetes.io/hostname
      
      containers:
      - name: backend
        image: spicybiryaniwala.shop/backend:v1.0.0
```

## 🔧 Affinity Management Commands

### Check Pod Placement
```bash
# View pod distribution across nodes
kubectl get pods -o wide --sort-by=.spec.nodeName

# Check pod affinity rules
kubectl describe pod <pod-name> | grep -A 20 Affinity

# View node labels
kubectl get nodes --show-labels

# Check topology domains
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, zone: .metadata.labels["topology.kubernetes.io/zone"]}'
```

### Debug Scheduling Issues
```bash
# Check scheduling events
kubectl get events --field-selector reason=FailedScheduling

# Describe pod for affinity conflicts
kubectl describe pod <pod-name>

# Check available nodes for affinity rules
kubectl get nodes -l node-type=high-performance
```

## 🚨 Common Use Cases

### 1. **High Availability Patterns**
```yaml
# Spread across zones and nodes
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        app: critical-app
    topologyKey: kubernetes.io/hostname
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app: critical-app
      topologyKey: topology.kubernetes.io/zone
```

### 2. **Performance Optimization**
```yaml
# Co-locate related services
podAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app: database
      topologyKey: kubernetes.io/hostname
```

### 3. **Resource Optimization**
```yaml
# Prefer specific node types
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 80
    preference:
      matchExpressions:
      - key: instance-type
        operator: In
        values:
        - c5.xlarge  # CPU optimized
  - weight: 20
    preference:
      matchExpressions:
      - key: node-lifecycle
        operator: In
        values:
        - spot  # Cost optimization
```

## 🛡️ Best Practices

### 1. **Use Weights Effectively**
```yaml
preferredDuringSchedulingIgnoredDuringExecution:
- weight: 100  # Highest priority
  preference:
    matchExpressions:
    - key: zone
      operator: In
      values:
      - us-west-1a
- weight: 50   # Medium priority
  preference:
    matchExpressions:
    - key: instance-type
      operator: In
      values:
      - m5.large
```

### 2. **Combine with Resource Requests**
```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-type
            operator: In
            values:
            - high-memory
  containers:
  - name: app
    resources:
      requests:
        memory: 8Gi  # Match node capability
```

### 3. **Use Appropriate Topology Keys**
```yaml
# Common topology keys
topologyKey: kubernetes.io/hostname          # Node level
topologyKey: topology.kubernetes.io/zone     # Zone level
topologyKey: topology.kubernetes.io/region   # Region level
topologyKey: node.kubernetes.io/instance-type # Instance type
```

## 📊 Operators Reference

### Node Affinity Operators
- **In** - Label value in list
- **NotIn** - Label value not in list  
- **Exists** - Label key exists
- **DoesNotExist** - Label key doesn't exist
- **Gt** - Numeric greater than
- **Lt** - Numeric less than

### Example Usage
```yaml
matchExpressions:
- key: kubernetes.io/arch
  operator: In
  values: ["amd64", "arm64"]
- key: node-type
  operator: NotIn
  values: ["spot"]
- key: gpu
  operator: Exists
- key: maintenance
  operator: DoesNotExist
```

## 📋 Practical Examples

### Example 1: Database HA Setup
```bash
# 1. Label nodes by zone
kubectl label nodes node1 topology.kubernetes.io/zone=us-west-1a
kubectl label nodes node2 topology.kubernetes.io/zone=us-west-1b
kubectl label nodes node3 topology.kubernetes.io/zone=us-west-1c

# 2. Deploy database with anti-affinity
kubectl apply -f database-ha-deployment.yaml

# 3. Verify distribution
kubectl get pods -o wide -l app=database
```

### Example 2: Microservices Co-location
```bash
# 1. Deploy frontend
kubectl apply -f frontend-deployment.yaml

# 2. Deploy backend with affinity to frontend
kubectl apply -f backend-deployment.yaml

# 3. Check co-location
kubectl get pods -o wide | grep -E "(frontend|backend)"
```

## 🔗 Related Topics
- **[Node Selectors](../node-selector/)** - Basic node selection
- **[Taints & Tolerations](../taints-tolerations/)** - Node restrictions
- **[Priority Classes](../priority-class/)** - Pod priorities

---

**Next:** [Priority Classes](../priority-class/) - Pod Priority Management
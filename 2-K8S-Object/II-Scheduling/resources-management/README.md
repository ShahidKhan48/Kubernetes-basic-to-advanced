# Resource Management - CPU & Memory Control

## 📚 Overview
Kubernetes Resource Management CPU, Memory aur storage resources ko control karne ka mechanism hai. Ye QoS classes, limits, aur quotas provide karta hai.

## 🎯 Resource Types

### CPU Resources
- **Requests** - Guaranteed CPU allocation
- **Limits** - Maximum CPU usage
- **Units** - millicores (m) or cores

### Memory Resources  
- **Requests** - Guaranteed memory allocation
- **Limits** - Maximum memory usage
- **Units** - Bytes (Ki, Mi, Gi, Ti)

## 📖 Examples

### 1. Basic Resource Configuration
```yaml
# 01-resources-basic.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: app
    image: nginx:1.21
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

### 2. LimitRange Configuration
```yaml
# 02-limit-range.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: production
spec:
  limits:
  # Pod limits
  - type: Pod
    max:
      cpu: "4"
      memory: "8Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
  
  # Container limits
  - type: Container
    default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "4Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
  
  # PVC limits
  - type: PersistentVolumeClaim
    max:
      storage: "100Gi"
    min:
      storage: "1Gi"
```

### 3. ResourceQuota Configuration
```yaml
# 03-resource-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    # Compute resources
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    
    # Object counts
    pods: "50"
    persistentvolumeclaims: "20"
    services: "10"
    secrets: "20"
    configmaps: "20"
    
    # Storage
    requests.storage: "500Gi"
```

### 4. Production Deployment with Resources
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-production
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: spicybiryaniwala.shop/web-app:v1.0.0
        
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        
        # Health checks
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

## 🔧 Resource Commands

### Check Resource Usage
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods

# Namespace resource usage
kubectl top pods -n production

# Resource quotas
kubectl describe resourcequota -n production
```

### Manage Resources
```bash
# Apply resource limits
kubectl apply -f limit-range.yaml

# Check limit ranges
kubectl describe limitrange -n production

# Update pod resources
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"web-app","resources":{"requests":{"cpu":"1000m"}}}]}}}}'
```

## 🚨 QoS Classes

### Guaranteed
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "1Gi"    # Same as requests
    cpu: "500m"      # Same as requests
```

### Burstable
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"    # Higher than requests
    cpu: "1000m"     # Higher than requests
```

### BestEffort
```yaml
# No resources specified
containers:
- name: app
  image: nginx:1.21
  # No resources block
```

## 📊 Best Practices

### 1. Always Set Requests
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 2. Use Appropriate Ratios
```yaml
# CPU: 1:2 ratio (request:limit)
# Memory: 1:1.5 ratio (request:limit)
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "1.5Gi"
    cpu: "1000m"
```

### 3. Monitor and Adjust
```bash
# Check actual usage
kubectl top pods --containers

# Adjust based on metrics
kubectl patch deployment app -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"memory":"512Mi"}}}]}}}}'
```

## 🔗 Related Topics
- **[Priority Classes](../priority-class/)** - Pod priorities
- **[HPA](../../C-Application-lifecycle-management/Auto-scalling/HPA/)** - Auto scaling
- **[VPA](../../C-Application-lifecycle-management/Auto-scalling/VPA/)** - Vertical scaling

---

**Next:** [Admission Controllers](../admission-controller/) - Policy Enforcement
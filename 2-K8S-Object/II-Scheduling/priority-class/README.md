# Priority Classes - Pod Priority Management

## 📚 Overview
Priority Classes Kubernetes mein pods ko priority assign karne ka mechanism hai. Higher priority pods lower priority pods ko preempt kar sakte hain jab resources limited hain.

## 🎯 How Priority Works

### Priority Scheduling
```
High Priority Pod → Scheduler → Preempt Lower Priority → Schedule High Priority
```

### Key Concepts
- **Priority Value** - Higher number = Higher priority
- **Preemption** - Evicting lower priority pods
- **Global Default** - Default priority for pods
- **System Priorities** - Reserved for system components

## 📖 Examples

### 1. Basic Priority Classes
```yaml
# 01-priority-class-basic.yaml
# System critical priority
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: system-critical
value: 2000000000  # Very high priority
globalDefault: false
description: "System critical components"
---
# High priority for production apps
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority for critical applications"
---
# Medium priority (default)
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: medium-priority
value: 500
globalDefault: true
description: "Default priority for regular applications"
---
# Low priority for batch jobs
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: false
description: "Low priority for batch and background jobs"
```

### 2. Critical Application with High Priority
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-payment-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
        priority: critical
    spec:
      priorityClassName: high-priority
      
      containers:
      - name: payment-service
        image: spicybiryaniwala.shop/payment-service:v1.0.0
        ports:
        - containerPort: 8080
        
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
        
        # Health checks for critical service
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
        
        env:
        - name: SERVICE_PRIORITY
          value: "critical"
        - name: PAYMENT_GATEWAY_URL
          valueFrom:
            secretKeyRef:
              name: payment-secrets
              key: gateway-url
```

### 3. Batch Job with Low Priority
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processing-job
spec:
  parallelism: 5
  completions: 10
  template:
    metadata:
      labels:
        app: data-processor
        priority: low
    spec:
      priorityClassName: low-priority
      
      containers:
      - name: processor
        image: spicybiryaniwala.shop/data-processor:latest
        command: ["python", "process_data.py"]
        
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 1Gi
        
        env:
        - name: BATCH_SIZE
          value: "1000"
        - name: PROCESSING_MODE
          value: "batch"
      
      restartPolicy: OnFailure
      
      # Allow preemption for higher priority pods
      preemptionPolicy: PreemptLowerPriority
```

### 4. Multi-Tier Application with Different Priorities
```yaml
# Frontend - High Priority
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
      priorityClassName: high-priority
      
      containers:
      - name: frontend
        image: spicybiryaniwala.shop/frontend:v1.0.0
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
---
# Backend API - High Priority  
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
spec:
  replicas: 6
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
        tier: api
    spec:
      priorityClassName: high-priority
      
      containers:
      - name: api
        image: spicybiryaniwala.shop/backend-api:v1.0.0
        resources:
          requests:
            cpu: 300m
            memory: 512Mi
---
# Background Workers - Medium Priority
apiVersion: apps/v1
kind: Deployment
metadata:
  name: background-workers
spec:
  replicas: 3
  selector:
    matchLabels:
      app: background-workers
  template:
    metadata:
      labels:
        app: background-workers
        tier: worker
    spec:
      priorityClassName: medium-priority
      
      containers:
      - name: worker
        image: spicybiryaniwala.shop/worker:v1.0.0
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
---
# Analytics Jobs - Low Priority
apiVersion: batch/v1
kind: CronJob
metadata:
  name: analytics-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: analytics
            tier: batch
        spec:
          priorityClassName: low-priority
          
          containers:
          - name: analytics
            image: spicybiryaniwala.shop/analytics:latest
            resources:
              requests:
                cpu: 500m
                memory: 2Gi
          
          restartPolicy: OnFailure
```

### 5. System Components with System Priority
```yaml
# Custom system component
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: custom-node-agent
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      priorityClassName: system-critical
      
      hostNetwork: true
      hostPID: true
      
      tolerations:
      - operator: "Exists"
        effect: "NoSchedule"
      - operator: "Exists"
        effect: "PreferNoSchedule"
      - operator: "Exists"
        effect: "NoExecute"
      
      containers:
      - name: agent
        image: spicybiryaniwala.shop/node-agent:latest
        securityContext:
          privileged: true
        
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 256Mi
        
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
      
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
```

## 🔧 Priority Management Commands

### Create Priority Classes
```bash
# Create high priority class
kubectl apply -f - <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority class"
EOF

# Create low priority class
kubectl apply -f - <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: false
description: "Low priority class"
EOF
```

### View Priority Classes
```bash
# List all priority classes
kubectl get priorityclasses

# Describe priority class
kubectl describe priorityclass high-priority

# Get priority class YAML
kubectl get priorityclass high-priority -o yaml
```

### Check Pod Priorities
```bash
# View pods with priorities
kubectl get pods -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priorityClassName,NODE:.spec.nodeName

# Check pod priority value
kubectl get pod <pod-name> -o jsonpath='{.spec.priority}'

# View preemption events
kubectl get events --field-selector reason=Preempted
```

## 🚨 Priority Ranges

### System Priorities
```yaml
# System critical (reserved)
value: 2000000000  # kubernetes system components

# System important
value: 1000000000  # important system services
```

### Application Priorities
```yaml
# Critical applications
value: 1000-10000

# Normal applications  
value: 100-999

# Background/batch jobs
value: 1-99

# Best effort (no priority class)
value: 0 (default)
```

## 🛡️ Best Practices

### 1. **Priority Class Hierarchy**
```yaml
# Define clear hierarchy
system-critical: 2000000000
high-priority: 1000
medium-priority: 500  # globalDefault: true
low-priority: 100
batch-priority: 50
```

### 2. **Resource Requests with Priorities**
```yaml
spec:
  priorityClassName: high-priority
  containers:
  - name: app
    resources:
      requests:  # Always set requests with priorities
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: 1000m
        memory: 2Gi
```

### 3. **Preemption Policy**
```yaml
spec:
  priorityClassName: high-priority
  preemptionPolicy: PreemptLowerPriority  # Default
  # or
  preemptionPolicy: Never  # Don't preempt others
```

## 🚨 Troubleshooting

### Pod Preemption Issues
```bash
# Check preemption events
kubectl get events --field-selector reason=Preempted

# Check pod priority
kubectl describe pod <pod-name> | grep Priority

# Check available resources
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Priority Class Not Found
```bash
# List available priority classes
kubectl get priorityclasses

# Check pod spec
kubectl describe pod <pod-name> | grep priorityClassName

# Create missing priority class
kubectl apply -f priority-class.yaml
```

### Scheduling Delays
```bash
# Check pending pods
kubectl get pods --field-selector=status.phase=Pending

# Check scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler

# Check resource availability
kubectl top nodes
```

## 📊 Preemption Scenarios

### 1. **Resource Contention**
```bash
# High priority pod needs resources
# Lower priority pods get preempted
# New pod gets scheduled
```

### 2. **Node Pressure**
```bash
# Node running out of resources
# Scheduler preempts lowest priority pods
# Makes room for higher priority workloads
```

### 3. **Critical Service Deployment**
```bash
# Critical service needs immediate scheduling
# Background jobs get preempted
# Service gets resources instantly
```

## 📋 Practical Examples

### Example 1: E-commerce Application Priorities
```bash
# 1. Create priority classes
kubectl apply -f - <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: critical-ecommerce
value: 1000
description: "Critical e-commerce services"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: normal-ecommerce
value: 500
globalDefault: true
description: "Normal e-commerce services"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: batch-ecommerce
value: 100
description: "Batch processing jobs"
EOF

# 2. Deploy payment service (critical)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment
  template:
    metadata:
      labels:
        app: payment
    spec:
      priorityClassName: critical-ecommerce
      containers:
      - name: payment
        image: nginx:1.21
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
EOF

# 3. Deploy analytics job (batch)
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: analytics-job
spec:
  template:
    metadata:
      labels:
        app: analytics
    spec:
      priorityClassName: batch-ecommerce
      containers:
      - name: analytics
        image: busybox
        command: ["sleep", "3600"]
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
      restartPolicy: Never
EOF

# 4. Check priorities
kubectl get pods -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priorityClassName
```

### Example 2: Resource Pressure Simulation
```bash
# 1. Fill cluster with low priority pods
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-hog
spec:
  replicas: 10
  selector:
    matchLabels:
      app: resource-hog
  template:
    metadata:
      labels:
        app: resource-hog
    spec:
      priorityClassName: low-priority
      containers:
      - name: hog
        image: busybox
        command: ["sleep", "3600"]
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
EOF

# 2. Deploy high priority pod (should preempt)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: critical-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: critical
    image: nginx:1.21
    resources:
      requests:
        cpu: 1000m
        memory: 2Gi
EOF

# 3. Watch preemption
kubectl get events --watch | grep Preempted
```

## 🔗 Related Topics
- **[Resource Management](../resources-management/)** - CPU/Memory limits
- **[Affinity & Anti-Affinity](../affinity-antiaffinity/)** - Advanced placement
- **[Admission Controllers](../admission-controller/)** - Policy enforcement

---

**Next:** [Resource Management](../resources-management/) - CPU & Memory Management
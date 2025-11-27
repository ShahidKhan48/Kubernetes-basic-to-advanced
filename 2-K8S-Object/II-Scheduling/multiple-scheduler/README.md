# Multiple Schedulers - Custom Scheduling

## 📚 Overview
Kubernetes mein multiple schedulers run kar sakte hain different scheduling algorithms ke liye. Custom schedulers specific workload requirements handle karte hain.

## 🎯 Use Cases

### Custom Scheduling Needs
- **ML/AI Workloads** - GPU-aware scheduling
- **Batch Processing** - Cost-optimized scheduling  
- **Real-time Systems** - Latency-aware scheduling
- **Multi-tenant** - Tenant-specific policies

## 📖 Examples

### 1. Custom Scheduler Deployment
```yaml
# 01-custom-scheduler.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-custom-scheduler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-custom-scheduler
  template:
    metadata:
      labels:
        app: my-custom-scheduler
    spec:
      serviceAccountName: my-scheduler
      containers:
      - name: kube-scheduler
        image: k8s.gcr.io/kube-scheduler:v1.28.0
        command:
        - kube-scheduler
        - --config=/etc/kubernetes/scheduler-config.yaml
        - --v=2
        volumeMounts:
        - name: config
          mountPath: /etc/kubernetes
      volumes:
      - name: config
        configMap:
          name: scheduler-config
```

### 2. Scheduler Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scheduler-config
  namespace: kube-system
data:
  scheduler-config.yaml: |
    apiVersion: kubescheduler.config.k8s.io/v1beta3
    kind: KubeSchedulerConfiguration
    profiles:
    - schedulerName: my-custom-scheduler
      plugins:
        score:
          enabled:
          - name: NodeResourcesFit
          - name: NodeAffinity
          disabled:
          - name: NodeResourcesBalancedAllocation
      pluginConfig:
      - name: NodeResourcesFit
        args:
          scoringStrategy:
            type: LeastAllocated
```

### 3. Pod Using Custom Scheduler
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-scheduled-pod
spec:
  schedulerName: my-custom-scheduler
  containers:
  - name: app
    image: nginx:1.21
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
```

### 4. GPU-Aware Scheduler
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gpu-scheduler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gpu-scheduler
  template:
    metadata:
      labels:
        app: gpu-scheduler
    spec:
      containers:
      - name: gpu-scheduler
        image: spicybiryaniwala.shop/gpu-scheduler:v1.0.0
        env:
        - name: SCHEDULER_NAME
          value: "gpu-scheduler"
        - name: GPU_RESOURCE
          value: "nvidia.com/gpu"
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
```

### 5. Batch Job Scheduler
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-processing-job
spec:
  parallelism: 10
  template:
    metadata:
      labels:
        scheduler-type: batch-optimized
    spec:
      schedulerName: batch-scheduler
      containers:
      - name: processor
        image: spicybiryaniwala.shop/batch-processor:latest
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
      restartPolicy: Never
```

## 🔧 Scheduler Commands

### Deploy Custom Scheduler
```bash
# Create service account
kubectl create serviceaccount my-scheduler -n kube-system

# Create cluster role binding
kubectl create clusterrolebinding my-scheduler --clusterrole=system:kube-scheduler --serviceaccount=kube-system:my-scheduler

# Deploy scheduler
kubectl apply -f custom-scheduler.yaml
```

### Check Schedulers
```bash
# List scheduler pods
kubectl get pods -n kube-system -l app=my-custom-scheduler

# Check scheduler logs
kubectl logs -n kube-system deployment/my-custom-scheduler

# View scheduler events
kubectl get events --field-selector source=my-custom-scheduler
```

### Test Custom Scheduling
```bash
# Create pod with custom scheduler
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-custom-schedule
spec:
  schedulerName: my-custom-scheduler
  containers:
  - name: test
    image: busybox
    command: ["sleep", "3600"]
EOF

# Check scheduling
kubectl describe pod test-custom-schedule
```

## 🚨 Scheduler Types

### 1. **Default Scheduler**
```yaml
spec:
  schedulerName: default-scheduler  # Default
```

### 2. **Custom Algorithm Scheduler**
```yaml
spec:
  schedulerName: cost-optimized-scheduler
```

### 3. **Workload-Specific Scheduler**
```yaml
spec:
  schedulerName: ml-gpu-scheduler
```

## 📊 Best Practices

### 1. **Scheduler Naming**
```yaml
# Use descriptive names
schedulerName: gpu-aware-scheduler
schedulerName: batch-cost-optimizer
schedulerName: latency-sensitive-scheduler
```

### 2. **Resource Management**
```yaml
# Scheduler pod resources
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 3. **High Availability**
```yaml
# Multiple scheduler replicas
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
```

## 🚨 Troubleshooting

### Scheduler Not Working
```bash
# Check scheduler pod status
kubectl get pods -n kube-system -l app=my-custom-scheduler

# Check scheduler logs
kubectl logs -n kube-system deployment/my-custom-scheduler

# Verify RBAC permissions
kubectl auth can-i get pods --as=system:serviceaccount:kube-system:my-scheduler
```

### Pod Not Scheduled
```bash
# Check pod events
kubectl describe pod <pod-name>

# Verify scheduler name
kubectl get pod <pod-name> -o jsonpath='{.spec.schedulerName}'

# Check scheduler availability
kubectl get pods -n kube-system | grep scheduler
```

## 📋 Practical Example

### Complete Custom Scheduler Setup
```bash
# 1. Create RBAC
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: custom-scheduler
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: custom-scheduler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-scheduler
subjects:
- kind: ServiceAccount
  name: custom-scheduler
  namespace: kube-system
EOF

# 2. Deploy scheduler
kubectl apply -f custom-scheduler.yaml

# 3. Test with pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  schedulerName: my-custom-scheduler
  containers:
  - name: test
    image: nginx:1.21
EOF

# 4. Verify scheduling
kubectl get pod test-pod -o wide
```

## 🔗 Related Topics
- **[Scheduler Profiles](../scheduler-profiles/)** - Scheduler configuration
- **[Priority Classes](../priority-class/)** - Pod priorities
- **[Affinity Rules](../affinity-antiaffinity/)** - Placement constraints

---

**Next:** [Scheduler Profiles](../scheduler-profiles/) - Scheduler Configuration
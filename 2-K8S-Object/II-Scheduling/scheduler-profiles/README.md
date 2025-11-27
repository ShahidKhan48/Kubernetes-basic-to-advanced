# Scheduler Profiles - Advanced Configuration

## 📚 Overview
Scheduler Profiles Kubernetes scheduler ko customize karne ka advanced method hai. Multiple scheduling profiles ek hi scheduler mein configure kar sakte hain.

## 🎯 Key Features

### Profile Components
- **Plugins** - Scheduling algorithms
- **Plugin Configuration** - Algorithm parameters
- **Scheduler Name** - Profile identifier
- **Plugin Order** - Execution sequence

## 📖 Examples

### 1. Basic Scheduler Profile
```yaml
# 01-scheduler-profiles.yaml
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: default-scheduler
  plugins:
    filter:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
      - name: PodTopologySpread
    score:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
  pluginConfig:
  - name: NodeResourcesFit
    args:
      scoringStrategy:
        type: LeastAllocated
```

### 2. Multi-Profile Configuration
```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
# High Performance Profile
- schedulerName: high-performance-scheduler
  plugins:
    filter:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
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
        type: MostAllocated  # Pack tightly

# Balanced Profile  
- schedulerName: balanced-scheduler
  plugins:
    filter:
      enabled:
      - name: NodeResourcesFit
      - name: PodTopologySpread
    score:
      enabled:
      - name: NodeResourcesFit
      - name: NodeResourcesBalancedAllocation
  pluginConfig:
  - name: NodeResourcesFit
    args:
      scoringStrategy:
        type: LeastAllocated

# GPU Profile
- schedulerName: gpu-scheduler
  plugins:
    filter:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
    score:
      enabled:
      - name: NodeResourcesFit
  pluginConfig:
  - name: NodeResourcesFit
    args:
      scoringStrategy:
        type: LeastAllocated
        resources:
        - name: nvidia.com/gpu
          weight: 100
```

### 3. Cost-Optimized Profile
```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: cost-optimized-scheduler
  plugins:
    filter:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
    score:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
    reserve:
      enabled:
      - name: VolumeBinding
  pluginConfig:
  - name: NodeResourcesFit
    args:
      scoringStrategy:
        type: MostAllocated  # Maximize utilization
  - name: NodeAffinity
    args:
      addedAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: node-lifecycle
              operator: In
              values:
              - spot
```

### 4. Latency-Sensitive Profile
```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: latency-sensitive-scheduler
  plugins:
    filter:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
      - name: PodTopologySpread
    score:
      enabled:
      - name: NodeResourcesFit
      - name: NodeAffinity
      - name: InterPodAffinity
  pluginConfig:
  - name: PodTopologySpread
    args:
      defaultConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
  - name: InterPodAffinity
    args:
      hardPodAffinityWeight: 100
```

### 5. Production Scheduler Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-scheduler
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: custom-scheduler
  template:
    metadata:
      labels:
        app: custom-scheduler
    spec:
      serviceAccountName: custom-scheduler
      containers:
      - name: kube-scheduler
        image: k8s.gcr.io/kube-scheduler:v1.28.0
        command:
        - kube-scheduler
        - --config=/etc/kubernetes/scheduler-config.yaml
        - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
        - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
        - --bind-address=0.0.0.0
        - --leader-elect=true
        - --leader-elect-resource-name=custom-scheduler
        - --v=2
        
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        volumeMounts:
        - name: config
          mountPath: /etc/kubernetes
          readOnly: true
        
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10259
            scheme: HTTPS
          initialDelaySeconds: 15
        
        readinessProbe:
          httpGet:
            path: /healthz
            port: 10259
            scheme: HTTPS
      
      volumes:
      - name: config
        configMap:
          name: scheduler-config
```

## 🔧 Profile Management

### Deploy Scheduler with Profiles
```bash
# Create ConfigMap with profiles
kubectl create configmap scheduler-config \
  --from-file=scheduler-config.yaml \
  -n kube-system

# Deploy scheduler
kubectl apply -f scheduler-deployment.yaml

# Check scheduler status
kubectl get pods -n kube-system -l app=custom-scheduler
```

### Test Different Profiles
```bash
# High performance workload
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: high-perf-pod
spec:
  schedulerName: high-performance-scheduler
  containers:
  - name: app
    image: nginx:1.21
    resources:
      requests:
        cpu: 1000m
        memory: 2Gi
EOF

# Cost optimized workload
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  template:
    spec:
      schedulerName: cost-optimized-scheduler
      containers:
      - name: worker
        image: busybox
        command: ["sleep", "300"]
      restartPolicy: Never
EOF
```

## 📊 Plugin Types

### Filter Plugins
- **NodeResourcesFit** - Resource availability
- **NodeAffinity** - Node selection
- **PodTopologySpread** - Distribution rules
- **TaintToleration** - Taint handling

### Score Plugins  
- **NodeResourcesFit** - Resource scoring
- **NodeAffinity** - Affinity scoring
- **InterPodAffinity** - Pod relationships
- **NodeResourcesBalancedAllocation** - Balance scoring

### Bind Plugins
- **DefaultBinder** - Standard binding
- **VolumeBinding** - Volume attachment

## 🛡️ Best Practices

### 1. **Profile Naming**
```yaml
# Use descriptive names
schedulerName: ml-gpu-scheduler
schedulerName: batch-cost-optimizer
schedulerName: realtime-latency-scheduler
```

### 2. **Resource Scoring**
```yaml
# Configure appropriate scoring
pluginConfig:
- name: NodeResourcesFit
  args:
    scoringStrategy:
      type: LeastAllocated  # For general workloads
      # type: MostAllocated   # For cost optimization
```

### 3. **Plugin Ordering**
```yaml
# Order matters for performance
plugins:
  filter:
    enabled:
    - name: NodeResourcesFit    # Fast filter first
    - name: NodeAffinity        # Then affinity
    - name: PodTopologySpread   # Complex rules last
```

## 🚨 Troubleshooting

### Profile Not Working
```bash
# Check scheduler config
kubectl get configmap scheduler-config -n kube-system -o yaml

# Check scheduler logs
kubectl logs -n kube-system deployment/custom-scheduler

# Verify profile syntax
kubectl apply --dry-run=server -f scheduler-config.yaml
```

### Scheduling Issues
```bash
# Check pod events
kubectl describe pod <pod-name>

# Verify scheduler name
kubectl get pod <pod-name> -o jsonpath='{.spec.schedulerName}'

# Check available schedulers
kubectl get pods -n kube-system | grep scheduler
```

## 📋 Practical Example

### Complete Multi-Profile Setup
```bash
# 1. Create scheduler profiles config
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: multi-scheduler-config
  namespace: kube-system
data:
  config.yaml: |
    apiVersion: kubescheduler.config.k8s.io/v1beta3
    kind: KubeSchedulerConfiguration
    profiles:
    - schedulerName: performance-scheduler
      plugins:
        score:
          enabled:
          - name: NodeResourcesFit
      pluginConfig:
      - name: NodeResourcesFit
        args:
          scoringStrategy:
            type: MostAllocated
    - schedulerName: efficiency-scheduler
      plugins:
        score:
          enabled:
          - name: NodeResourcesFit
      pluginConfig:
      - name: NodeResourcesFit
        args:
          scoringStrategy:
            type: LeastAllocated
EOF

# 2. Deploy multi-profile scheduler
kubectl apply -f multi-scheduler-deployment.yaml

# 3. Test different profiles
kubectl run perf-test --image=nginx --scheduler-name=performance-scheduler
kubectl run eff-test --image=nginx --scheduler-name=efficiency-scheduler
```

## 🔗 Related Topics
- **[Multiple Schedulers](../multiple-scheduler/)** - Custom schedulers
- **[Priority Classes](../priority-class/)** - Pod priorities
- **[Resource Management](../resources-management/)** - Resource control

---

**Next:** [Validation & Mutation Webhooks](../validation-mutation-admisContlr/) - Advanced Admission Control
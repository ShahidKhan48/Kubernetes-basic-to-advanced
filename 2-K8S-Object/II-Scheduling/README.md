# B. Kubernetes Scheduling

## 📚 Overview
Kubernetes Scheduling advanced concepts aur mechanisms. Ye section aapko sikhayega ki kaise pods ko efficiently schedule karna hai, resource management karna hai, aur custom scheduling logic implement karna hai.

## 🎯 What You'll Learn
- Advanced pod scheduling techniques
- Resource management strategies
- Custom scheduling mechanisms
- Admission control policies
- Production-grade scheduling configurations

## 📖 Scheduling Components

### 1. [Node Selectors](./node-selector/) 🎯
**Basic node selection mechanism**

**Key Concepts:**
- Label-based node selection
- Simple scheduling constraints
- Hardware-specific deployments

**Use Cases:**
- GPU nodes for ML workloads
- SSD nodes for databases
- Specific OS requirements

**Example:**
```yaml
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
```

---

### 2. [Taints & Tolerations](./taints-tolerations/) 🚫
**Node restrictions aur exceptions**

**Key Concepts:**
- Node taints (restrictions)
- Pod tolerations (exceptions)
- Dedicated node pools
- Workload isolation

**Use Cases:**
- Dedicated nodes for specific workloads
- Node maintenance
- Resource isolation
- Security boundaries

**Example:**
```yaml
# Taint on node
kubectl taint nodes node1 key=value:NoSchedule

# Toleration in pod
apiVersion: v1
kind: Pod
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
```

---

### 3. [Affinity & Anti-Affinity](./affinity-antiaffinity/) 🧲
**Advanced placement rules**

**Key Concepts:**
- Node affinity (preferred/required)
- Pod affinity (co-location)
- Pod anti-affinity (separation)
- Topology constraints

**Use Cases:**
- High availability deployments
- Performance optimization
- Compliance requirements
- Disaster recovery

**Example:**
```yaml
apiVersion: v1
kind: Pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64
    podAntiAffinity:
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
```

---

### 4. [Priority Classes](./priority-class/) ⭐
**Pod priority management**

**Key Concepts:**
- Priority-based scheduling
- Preemption mechanisms
- Critical workload protection
- Resource allocation priorities

**Use Cases:**
- System critical pods
- Production vs development priorities
- Emergency workload scheduling
- Resource contention resolution

**Example:**
```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority class for critical applications"
---
apiVersion: v1
kind: Pod
spec:
  priorityClassName: high-priority
  containers:
  - name: critical-app
    image: critical-app:latest
```

---

### 5. [Resource Management](./resources-management/) 💾
**CPU, Memory, aur storage management**

**Key Concepts:**
- Resource requests & limits
- Quality of Service (QoS) classes
- Resource quotas
- Limit ranges

**Use Cases:**
- Performance guarantees
- Resource isolation
- Cost optimization
- Capacity planning

**Example:**
```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: app:latest
    resources:
      requests:
        memory: "256Mi"
        cpu: "500m"
      limits:
        memory: "512Mi"
        cpu: "1000m"
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
```

---

### 6. [Admission Controllers](./admission-controller/) 🛡️
**Policy enforcement mechanisms**

**Key Concepts:**
- Validating admission controllers
- Mutating admission controllers
- Policy enforcement
- Security controls

**Use Cases:**
- Security policy enforcement
- Resource validation
- Configuration standardization
- Compliance requirements

**Example:**
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: pod-security-webhook
webhooks:
- name: pod-security.example.com
  clientConfig:
    service:
      name: pod-security-webhook
      namespace: default
      path: "/validate"
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
```

---

### 7. [Multiple Schedulers](./multiple-scheduler/) 🔄
**Custom scheduling logic**

**Key Concepts:**
- Custom scheduler implementation
- Scheduler selection
- Specialized scheduling algorithms
- Multi-tenant scheduling

**Use Cases:**
- ML/AI workload scheduling
- Batch job optimization
- Custom resource scheduling
- Performance-specific scheduling

**Example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-scheduled-pod
spec:
  schedulerName: my-custom-scheduler
  containers:
  - name: app
    image: app:latest
```

---

### 8. [Scheduler Profiles](./scheduler-profiles/) ⚙️
**Scheduler configuration & tuning**

**Key Concepts:**
- Scheduler configuration
- Plugin configuration
- Performance tuning
- Scheduling policies

**Use Cases:**
- Performance optimization
- Custom scheduling behavior
- Multi-tenant environments
- Specialized workloads

**Example:**
```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: default-scheduler
  plugins:
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

---

### 9. [Validation & Mutation Webhooks](./validation-mutation-admisContlr/) 🔍
**Advanced admission control**

**Key Concepts:**
- Custom validation logic
- Resource mutation
- Policy as code
- Dynamic admission control

**Use Cases:**
- Custom security policies
- Resource standardization
- Configuration injection
- Compliance automation

**Example:**
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionWebhook
metadata:
  name: resource-injector
webhooks:
- name: inject-resources.example.com
  clientConfig:
    service:
      name: resource-injector
      namespace: default
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
```

## 🔧 Common Scheduling Commands

### Node Management
```bash
# Label nodes
kubectl label nodes node1 node-type=gpu
kubectl label nodes node2 zone=us-west-1a

# Taint nodes
kubectl taint nodes node1 key=value:NoSchedule
kubectl taint nodes node1 key=value:NoExecute

# Remove taints
kubectl taint nodes node1 key=value:NoSchedule-

# Check node labels and taints
kubectl describe node node1
```

### Pod Scheduling
```bash
# Check pod scheduling
kubectl get pods -o wide

# Check pod events
kubectl describe pod <pod-name>

# Check scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler

# Force reschedule pod
kubectl delete pod <pod-name>
```

### Resource Management
```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Check resource quotas
kubectl describe resourcequota

# Check limit ranges
kubectl describe limitrange
```

## 📊 Scheduling Strategies

### 1. **High Availability**
```yaml
# Anti-affinity for pod distribution
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app
        operator: In
        values:
        - web-app
    topologyKey: kubernetes.io/hostname
```

### 2. **Performance Optimization**
```yaml
# Node affinity for performance
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: node-type
        operator: In
        values:
        - high-performance
```

### 3. **Resource Isolation**
```yaml
# Dedicated nodes with taints
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "database"
  effect: "NoSchedule"
```

### 4. **Cost Optimization**
```yaml
# Prefer spot instances
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 50
    preference:
      matchExpressions:
      - key: node-lifecycle
        operator: In
        values:
        - spot
```

## 🛡️ Security & Compliance

### 1. **Pod Security Standards**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 2. **Network Policies**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scheduling-netpol
spec:
  podSelector:
    matchLabels:
      scheduled-by: custom-scheduler
  policyTypes:
  - Ingress
  - Egress
```

### 3. **RBAC for Schedulers**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: custom-scheduler
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
```

## 🚨 Troubleshooting

### Common Scheduling Issues

#### 1. **Pod Stuck in Pending**
```bash
# Check scheduling events
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes

# Check taints and tolerations
kubectl get nodes -o json | jq '.items[].spec.taints'
```

#### 2. **Insufficient Resources**
```bash
# Check resource requests vs available
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check resource quotas
kubectl describe resourcequota -n <namespace>

# Check limit ranges
kubectl describe limitrange -n <namespace>
```

#### 3. **Affinity Conflicts**
```bash
# Check affinity rules
kubectl get pod <pod-name> -o yaml | grep -A 20 affinity

# Check node labels
kubectl get nodes --show-labels

# Check pod distribution
kubectl get pods -o wide --sort-by=.spec.nodeName
```

## 📋 Best Practices

### 1. **Resource Planning**
- Always set resource requests
- Use appropriate QoS classes
- Monitor resource utilization
- Plan for peak loads

### 2. **High Availability**
- Use pod anti-affinity
- Distribute across zones
- Implement pod disruption budgets
- Use multiple replicas

### 3. **Performance**
- Use node affinity for performance-critical workloads
- Consider NUMA topology
- Optimize scheduler configuration
- Monitor scheduling latency

### 4. **Security**
- Implement admission controllers
- Use pod security standards
- Apply network policies
- Regular security audits

## 🎯 Learning Path

### Beginner (Week 1)
1. **Node Selectors** - Basic node selection
2. **Resource Management** - Requests and limits
3. **Basic Affinity** - Simple placement rules

### Intermediate (Week 2-3)
1. **Taints & Tolerations** - Node restrictions
2. **Advanced Affinity** - Complex placement rules
3. **Priority Classes** - Priority management

### Advanced (Week 4-5)
1. **Admission Controllers** - Policy enforcement
2. **Multiple Schedulers** - Custom scheduling
3. **Scheduler Profiles** - Advanced configuration

### Expert (Week 6+)
1. **Custom Webhooks** - Advanced admission control
2. **Scheduler Development** - Custom scheduler implementation
3. **Performance Tuning** - Optimization techniques

## 📊 Monitoring & Observability

### Scheduler Metrics
```bash
# Scheduler performance
kubectl top pods -n kube-system -l component=kube-scheduler

# Scheduling latency
kubectl get events --sort-by=.firstTimestamp | grep Scheduled

# Failed scheduling attempts
kubectl get events --field-selector reason=FailedScheduling
```

### Resource Utilization
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods --all-namespaces

# Resource quota usage
kubectl describe resourcequota --all-namespaces
```

## 🔗 Quick Navigation

| Component | Complexity | Use Case | Production Ready |
|-----------|------------|----------|------------------|
| [Node Selectors](./node-selector/) | ⭐ | Basic node selection | ✅ |
| [Taints & Tolerations](./taints-tolerations/) | ⭐⭐ | Node restrictions | ✅ |
| [Affinity & Anti-Affinity](./affinity-antiaffinity/) | ⭐⭐⭐ | Advanced placement | ✅ |
| [Priority Classes](./priority-class/) | ⭐⭐ | Priority management | ✅ |
| [Resource Management](./resources-management/) | ⭐⭐⭐ | Resource control | ✅ |
| [Admission Controllers](./admission-controller/) | ⭐⭐⭐⭐ | Policy enforcement | ✅ |
| [Multiple Schedulers](./multiple-scheduler/) | ⭐⭐⭐⭐ | Custom scheduling | ⚠️ |
| [Scheduler Profiles](./scheduler-profiles/) | ⭐⭐⭐⭐ | Advanced config | ⚠️ |
| [Webhooks](./validation-mutation-admisContlr/) | ⭐⭐⭐⭐⭐ | Advanced admission | ⚠️ |

---

**Next:** [C-Application-lifecycle-management](../C-Application-lifecycle-management/) - Application Lifecycle Management
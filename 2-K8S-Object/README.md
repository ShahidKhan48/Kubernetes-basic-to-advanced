# Lesson 2: Kubernetes Objects (K8S Objects)

## 📚 Overview
Kubernetes Objects ke bare mein complete understanding aur practical examples. Ye lesson aapko Kubernetes ke core components aur unke usage ke bare mein sikhayega.

## 🎯 Learning Objectives
- Kubernetes Objects ki complete understanding
- Workloads, Scheduling, Application Lifecycle Management
- Storage aur practical implementation
- Production-ready configurations

## 📖 Table of Contents

### A. [Workloads](./A-workloads/)
Kubernetes workloads ke sare types aur unka usage:
- **Pods** - Basic unit of deployment
- **ReplicaSets** - Pod replication management
- **Deployments** - Application deployment aur updates
- **Services** - Network access aur load balancing
- **Namespaces** - Resource isolation
- **StatefulSets** - Stateful applications
- **DaemonSets** - Node-level services
- **Jobs/CronJobs** - Batch processing

### B. [Scheduling](./B-Sheduling/)
Advanced scheduling mechanisms:
- **Node Selectors** - Basic node selection
- **Taints & Tolerations** - Node restrictions
- **Affinity & Anti-Affinity** - Advanced placement rules
- **Priority Classes** - Pod priority management
- **Resource Management** - CPU/Memory limits
- **Admission Controllers** - Policy enforcement
- **Multiple Schedulers** - Custom scheduling
- **Scheduler Profiles** - Scheduler configuration
- **Validation/Mutation Webhooks** - Custom admission logic

### C. [Application Lifecycle Management](./C-Application-lifecycle-management/)
Complete application management:
- **Auto Scaling** - HPA, VPA, Cluster Autoscaling
- **ConfigMaps & Secrets** - Configuration management
- **Environment Variables** - Application configuration
- **Init Containers** - Initialization logic
- **Multi-Pod Design Patterns** - Sidecar, Ambassador, Adapter
- **Deployment Strategies** - Rolling, Blue-Green, Canary
- **Self-Healing Applications** - Health checks aur recovery

### D. [Storage](./D-k8s-storage/)
Kubernetes storage solutions:
- **Volumes** - Data persistence
- **Persistent Volumes** - Cluster-level storage
- **Storage Classes** - Dynamic provisioning
- **StatefulSet Storage** - Ordered storage

## 🚀 Quick Start Guide

### Prerequisites
```bash
# Kubernetes cluster running
kubectl cluster-info

# Basic tools installed
kubectl version --client
```

### Basic Commands
```bash
# Get all resources
kubectl get all

# Describe any resource
kubectl describe <resource-type> <resource-name>

# Apply configuration
kubectl apply -f <filename.yaml>

# Delete resources
kubectl delete -f <filename.yaml>
```

## 📝 Best Practices

### 1. Resource Management
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

### 2. Health Checks
```yaml
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

### 3. Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
  capabilities:
    drop:
    - ALL
```

## 🔧 Troubleshooting Commands

### Pod Issues
```bash
# Check pod status
kubectl get pods -o wide

# Check pod logs
kubectl logs <pod-name> -f

# Describe pod for events
kubectl describe pod <pod-name>

# Execute into pod
kubectl exec -it <pod-name> -- /bin/bash
```

### Service Issues
```bash
# Check service endpoints
kubectl get endpoints

# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- nslookup <service-name>
```

### Resource Issues
```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Check resource quotas
kubectl describe resourcequota
```

## 📊 Monitoring & Observability

### Essential Metrics
- **Pod Status** - Running, Pending, Failed
- **Resource Usage** - CPU, Memory utilization
- **Network Traffic** - Ingress/Egress
- **Storage Usage** - PV/PVC status

### Logging Strategy
```yaml
# Structured logging example
apiVersion: v1
kind: ConfigMap
metadata:
  name: logging-config
data:
  log-level: "info"
  log-format: "json"
```

## 🎓 Learning Path

### Beginner Level
1. Start with **Pods** - Basic understanding
2. Learn **Services** - Network connectivity
3. Practice **Deployments** - Application management
4. Understand **ConfigMaps/Secrets** - Configuration

### Intermediate Level
1. **Scheduling** concepts
2. **Storage** management
3. **Auto-scaling** mechanisms
4. **Multi-container** patterns

### Advanced Level
1. **Custom Resources** (CRDs)
2. **Operators** development
3. **Admission Controllers**
4. **Custom Schedulers**

## 🔗 Useful Links

### Official Documentation
- [Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)
- [Workloads](https://kubernetes.io/docs/concepts/workloads/)
- [Services and Networking](https://kubernetes.io/docs/concepts/services-networking/)

### Tools & Utilities
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [YAML Validator](https://kubeyaml.com/)
- [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

## 📋 Checklist

### Before Starting
- [ ] Kubernetes cluster access
- [ ] kubectl configured
- [ ] Basic YAML understanding
- [ ] Docker concepts clear

### After Completion
- [ ] Can create and manage pods
- [ ] Understand service types
- [ ] Can deploy applications
- [ ] Know scheduling concepts
- [ ] Understand storage options

## 🤝 Contributing

Agar aap koi improvement suggest karna chahte hain:
1. Issues create karein
2. Pull requests submit karein
3. Documentation improve karein
4. Examples add karein

## 📞 Support

Questions ya help ke liye:
- GitHub Issues create karein
- Documentation check karein
- Community forums use karein

---

**Next:** [A-workloads](./A-workloads/) - Kubernetes Workloads ki detailed study
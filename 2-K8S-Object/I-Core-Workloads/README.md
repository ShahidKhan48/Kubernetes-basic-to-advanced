# A. Kubernetes Workloads

## 📚 Overview
Kubernetes Workloads complete guide - sare types ke workloads aur unka practical usage. Production-ready examples ke saath comprehensive learning material.

## 🎯 What You'll Learn
- Kubernetes ke sare workload types
- Production-grade configurations
- Troubleshooting techniques
- Best practices aur security

## 📖 Workload Types

### 1. [Pods](./pods/) 🚀
**Basic unit of deployment in Kubernetes**

**Key Concepts:**
- Single/Multi-container pods
- Lifecycle management
- Resource allocation
- Health checks

**Use Cases:**
- Simple applications
- Testing environments
- Debugging purposes

**Example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

---

### 2. [ReplicaSets](./replicaset/) 🔄
**Pod replication aur availability management**

**Key Concepts:**
- Desired state management
- Pod template
- Label selectors
- Scaling operations

**Use Cases:**
- High availability
- Load distribution
- Fault tolerance

**Example:**
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
```

---

### 3. [Deployments](./deployment/) 🚢
**Application deployment aur rolling updates**

**Key Concepts:**
- Rolling updates
- Rollback capabilities
- Deployment strategies
- Version management

**Use Cases:**
- Production applications
- CI/CD pipelines
- Version control
- Zero-downtime updates

**Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

---

### 4. [Services](./services/) 🌐
**Network access aur load balancing**

**Key Concepts:**
- Service discovery
- Load balancing
- Network policies
- External access

**Service Types:**
- **ClusterIP** - Internal cluster access
- **NodePort** - External access via node ports
- **LoadBalancer** - Cloud load balancer
- **ExternalName** - DNS CNAME mapping
- **Headless** - Direct pod access

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
```

---

### 5. [Namespaces](./namespace/) 📁
**Resource isolation aur organization**

**Key Concepts:**
- Resource isolation
- Access control
- Resource quotas
- Multi-tenancy

**Use Cases:**
- Environment separation (dev/staging/prod)
- Team isolation
- Resource management
- Security boundaries

**Example:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: prod
    team: backend
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: production
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "10"
```

---

### 6. [StatefulSets](./statefulset/) 🗄️
**Stateful applications management**

**Key Concepts:**
- Ordered deployment
- Stable network identities
- Persistent storage
- Ordered scaling

**Use Cases:**
- Databases (MySQL, PostgreSQL)
- Message queues (Kafka, RabbitMQ)
- Distributed systems (Elasticsearch, Cassandra)

**Example:**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-statefulset
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "password"
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

---

### 7. [DaemonSets](./deamonset/) 👥
**Node-level services aur system components**

**Key Concepts:**
- One pod per node
- System-level services
- Node monitoring
- Log collection

**Use Cases:**
- Log collectors (Fluentd, Filebeat)
- Monitoring agents (Node Exporter)
- Network plugins (Calico, Flannel)
- Security agents

**Example:**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-daemonset
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluentd:v1.14
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

---

### 8. [Jobs & CronJobs](./jobs/) ⏰
**Batch processing aur scheduled tasks**

**Key Concepts:**
- One-time tasks (Jobs)
- Scheduled tasks (CronJobs)
- Parallel processing
- Completion tracking

**Use Cases:**
- Data processing
- Backup operations
- Batch analytics
- Scheduled maintenance

**Job Example:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processing-job
spec:
  parallelism: 3
  completions: 6
  template:
    spec:
      containers:
      - name: processor
        image: busybox
        command: ["sh", "-c", "echo Processing data && sleep 30"]
      restartPolicy: Never
  backoffLimit: 4
```

**CronJob Example:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-cronjob
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tool:latest
            command: ["sh", "-c", "backup-script.sh"]
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

## 🔧 Common Commands

### Basic Operations
```bash
# Get all workloads
kubectl get all

# Get specific workload type
kubectl get pods,deployments,services

# Watch resources in real-time
kubectl get pods -w

# Get detailed information
kubectl describe deployment nginx-deployment
```

### Scaling Operations
```bash
# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5

# Autoscale deployment
kubectl autoscale deployment nginx-deployment --min=2 --max=10 --cpu-percent=80
```

### Update Operations
```bash
# Update image
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# Rollback deployment
kubectl rollout undo deployment/nginx-deployment
```

## 📊 Monitoring & Troubleshooting

### Health Checks
```bash
# Check pod health
kubectl get pods -o wide

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check logs
kubectl logs -f deployment/nginx-deployment
```

### Resource Usage
```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Check resource quotas
kubectl describe resourcequota -n production
```

## 🛡️ Security Best Practices

### 1. Resource Limits
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

### 2. Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
  capabilities:
    drop:
    - ALL
```

### 3. Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## 🎯 Learning Path

### Beginner (Week 1-2)
1. **Pods** - Basic concepts aur simple examples
2. **Services** - Network connectivity
3. **Deployments** - Application management

### Intermediate (Week 3-4)
1. **ReplicaSets** - Replication management
2. **Namespaces** - Resource organization
3. **Jobs/CronJobs** - Batch processing

### Advanced (Week 5-6)
1. **StatefulSets** - Stateful applications
2. **DaemonSets** - System services
3. **Advanced configurations** - Production setups

## 📋 Practical Exercises

### Exercise 1: Basic Web Application
```bash
# Create namespace
kubectl create namespace webapp

# Deploy application
kubectl apply -f deployment/01-deployment-basic.yaml -n webapp

# Expose service
kubectl apply -f services/01-services-basic.yaml -n webapp

# Test connectivity
kubectl port-forward service/nginx-service 8080:80 -n webapp
```

### Exercise 2: Stateful Database
```bash
# Deploy StatefulSet
kubectl apply -f statefulset/01-statefulset-basic.yaml

# Check ordered creation
kubectl get pods -l app=mysql -w

# Test persistence
kubectl exec mysql-0 -- mysql -u root -ppassword -e "CREATE DATABASE testdb;"
```

### Exercise 3: Batch Processing
```bash
# Run one-time job
kubectl apply -f jobs/01-jobs-cronjob-basic.yaml

# Check job completion
kubectl get jobs -w

# Schedule recurring task
kubectl apply -f jobs/cronjob-example.yaml
```

## 🔗 Quick Navigation

| Workload Type | Use Case | Complexity | Production Ready |
|---------------|----------|------------|------------------|
| [Pods](./pods/) | Testing, Debugging | ⭐ | ❌ |
| [ReplicaSets](./replicaset/) | Basic Replication | ⭐⭐ | ⚠️ |
| [Deployments](./deployment/) | Applications | ⭐⭐⭐ | ✅ |
| [Services](./services/) | Networking | ⭐⭐ | ✅ |
| [Namespaces](./namespace/) | Organization | ⭐ | ✅ |
| [StatefulSets](./statefulset/) | Databases | ⭐⭐⭐⭐ | ✅ |
| [DaemonSets](./deamonset/) | System Services | ⭐⭐⭐ | ✅ |
| [Jobs/CronJobs](./jobs/) | Batch Processing | ⭐⭐ | ✅ |

---

**Next:** [B-Scheduling](../B-Sheduling/) - Advanced Kubernetes Scheduling
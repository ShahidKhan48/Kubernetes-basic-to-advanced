# Kubernetes Workloads - Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [Pod](#pod)
3. [ReplicaSet](#replicaset)
4. [Deployment](#deployment)
5. [DaemonSet](#daemonset)
6. [StatefulSet](#statefulset)
7. [Job](#job)
8. [CronJob](#cronjob)
9. [Workload Comparison](#workload-comparison)
10. [Best Practices](#best-practices)

---

## Overview

Kubernetes workloads are objects that manage the execution of pods. They provide different patterns for running applications based on specific requirements like scaling, persistence, scheduling, and lifecycle management.

### Workload Types Hierarchy

Workloads
├── Pod (Basic unit)
├── ReplicaSet (Replica management)
├── Deployment (Application lifecycle)
├── DaemonSet (Node-level services)
├── StatefulSet (Stateful applications)
├── Job (Batch processing)
└── CronJob (Scheduled tasks)


---

## Pod

### Definition
Pod is the smallest deployable unit in Kubernetes, representing a single instance of a running process.

### Key Characteristics
- **Atomic Unit**: Cannot be split across nodes
- **Shared Resources**: Containers share network and storage
- **Ephemeral**: Pods are mortal and replaceable
- **Single IP**: All containers share the same IP address

### Lifecycle States
1. **Pending**: Pod accepted but not scheduled
2. **Running**: Pod bound to node and containers created
3. **Succeeded**: All containers terminated successfully
4. **Failed**: All containers terminated, at least one failed
5. **Unknown**: Pod state cannot be determined

### Container Patterns in Pods

#### Single Container Pattern

spec:
  containers:
  - name: app
    image: nginx:1.21
```

#### Multi-Container Patterns

##### Sidecar Pattern

spec:
  containers:
  - name: app
    image: nginx:1.21
  - name: log-shipper
    image: fluent/fluent-bit:1.8


##### Ambassador Pattern

spec:
  containers:
  - name: app
    image: myapp:latest
  - name: proxy
    image: envoy:v1.20


##### Adapter Pattern

spec:
  containers:
  - name: app
    image: legacy-app:1.0
  - name: adapter
    image: metrics-adapter:1.0

### Resource Management
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"


### Health Checks
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

startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 10

### Use Cases
- Development and testing
- Single-instance applications
- Debugging and troubleshooting
- Init containers for setup tasks

---

## ReplicaSet

### Definition
ReplicaSet ensures a specified number of pod replicas are running at any given time.

### Key Characteristics
- **Replica Management**: Maintains desired pod count
- **Label Selectors**: Uses labels to identify pods
- **Self-Healing**: Replaces failed pods automatically
- **Horizontal Scaling**: Scales pods up/down

### Controller Logic
```
Desired State: 3 replicas
Current State: 2 replicas
Action: Create 1 new pod

Desired State: 3 replicas  
Current State: 4 replicas
Action: Delete 1 pod
```

### Selector Types
```yaml
selector:
  matchLabels:
    app: nginx
    tier: frontend
  matchExpressions:
  - key: environment
    operator: In
    values: [production, staging]
```

### Scaling Operations
```bash
# Manual scaling
kubectl scale replicaset nginx-rs --replicas=5

# Check status
kubectl get replicaset nginx-rs
```

### Use Cases
- Ensuring high availability
- Load distribution
- Fault tolerance
- Basic scaling requirements

### Limitations
- No rolling updates
- No deployment history
- Limited update strategies

---

## Deployment

### Definition
Deployment provides declarative updates for Pods and ReplicaSets, managing the complete application lifecycle.

### Key Characteristics
- **Declarative Updates**: Desired state management
- **Rolling Updates**: Zero-downtime deployments
- **Rollback Capability**: Easy version rollback
- **Revision History**: Maintains deployment history
- **Multiple Strategies**: Different update approaches

### Deployment Strategies

#### Rolling Update (Default)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 25%
```

**Process:**
1. Create new pods gradually
2. Terminate old pods gradually
3. Ensure minimum availability

#### Recreate Strategy
```yaml
strategy:
  type: Recreate
```

**Process:**
1. Terminate all existing pods
2. Create new pods
3. Brief downtime occurs

### Update Process
```bash
# Update image
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment
```

### Advanced Configurations
```yaml
spec:
  replicas: 3
  minReadySeconds: 10
  progressDeadlineSeconds: 600
  revisionHistoryLimit: 10
```

### Blue-Green Deployment Pattern
```yaml
# Blue deployment (current)
metadata:
  name: app-blue
  labels:
    version: blue

# Green deployment (new)
metadata:
  name: app-green
  labels:
    version: green
```

### Canary Deployment Pattern
```yaml
# Stable deployment (90%)
spec:
  replicas: 9

# Canary deployment (10%)
spec:
  replicas: 1
```

### Use Cases
- Web applications
- API services
- Microservices
- Stateless applications
- CI/CD pipelines

---

## DaemonSet

### Definition
DaemonSet ensures that all (or some) nodes run a copy of a pod, typically for system-level services.

### Key Characteristics
- **Node Coverage**: Runs on every node
- **Automatic Scheduling**: New nodes get pods automatically
- **System Services**: Typically for infrastructure components
- **Node Affinity**: Can target specific nodes

### Scheduling Behavior
```
New Node Added → DaemonSet Controller → Pod Created on New Node
Node Removed → Pod Automatically Deleted
```

### Update Strategies

#### Rolling Update
```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
```

#### On Delete
```yaml
updateStrategy:
  type: OnDelete
```

### Node Selection
```yaml
nodeSelector:
  kubernetes.io/os: linux

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-type
          operator: In
          values: [worker]
```

### Tolerations for System Pods
```yaml
tolerations:
- operator: Exists
  effect: NoSchedule
- operator: Exists
  effect: NoExecute
```

### Common Use Cases
- **Logging**: Fluentd, Logstash
- **Monitoring**: Node Exporter, cAdvisor
- **Networking**: Calico, Flannel
- **Storage**: Ceph, GlusterFS
- **Security**: Falco, Twistlock

### Management Commands
```bash
# Get DaemonSet status
kubectl get daemonset

# Check pod distribution
kubectl get pods -o wide -l app=fluentd

# Update DaemonSet
kubectl patch daemonset fluentd -p '{"spec":{"template":{"spec":{"containers":[{"name":"fluentd","image":"fluent/fluentd:v1.14"}]}}}}'
```

---

## StatefulSet

### Definition
StatefulSet manages stateful applications, providing guarantees about ordering and uniqueness of pods.

### Key Characteristics
- **Stable Identity**: Each pod has unique, persistent identity
- **Ordered Operations**: Sequential deployment, scaling, updates
- **Persistent Storage**: Each pod can have dedicated storage
- **Stable Network**: Predictable DNS names

### Pod Identity
```
StatefulSet: mysql
Pods: mysql-0, mysql-1, mysql-2
DNS: mysql-0.mysql-headless.default.svc.cluster.local
```

### Deployment Order
```
Deployment: mysql-0 → mysql-1 → mysql-2
Scaling Up: mysql-3 → mysql-4
Scaling Down: mysql-4 → mysql-3
Updates: mysql-2 → mysql-1 → mysql-0
```

### Update Strategies

#### Rolling Update
```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 0  # Update all pods
```

#### On Delete
```yaml
updateStrategy:
  type: OnDelete
```

### Partition Updates
```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 2  # Only update pods with ordinal >= 2
```

### Volume Claim Templates
```yaml
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: ["ReadWriteOnce"]
    storageClassName: fast-ssd
    resources:
      requests:
        storage: 10Gi
```

### Headless Service Requirement
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None
  selector:
    app: mysql
```

### Common Patterns

#### Master-Slave Database
```yaml
# Master pod: mysql-0
# Slave pods: mysql-1, mysql-2, mysql-3
```

#### Distributed Systems
```yaml
# Kafka brokers: kafka-0, kafka-1, kafka-2
# Each with unique broker.id
```

### Use Cases
- **Databases**: MySQL, PostgreSQL, MongoDB
- **Distributed Systems**: Kafka, Elasticsearch, Cassandra
- **Stateful Applications**: Jenkins, GitLab
- **Clustered Applications**: Redis Cluster, Consul

### Management Commands
```bash
# Scale StatefulSet
kubectl scale statefulset mysql --replicas=5

# Delete StatefulSet (keep PVCs)
kubectl delete statefulset mysql --cascade=orphan

# Force delete stuck pod
kubectl delete pod mysql-2 --force --grace-period=0
```

---

## Job

### Definition
Job creates one or more pods and ensures that a specified number of them successfully terminate.

### Key Characteristics
- **Completion Tracking**: Monitors successful completions
- **Retry Logic**: Automatically retries failed pods
- **Parallelism**: Can run multiple pods simultaneously
- **Finite Execution**: Designed for batch processing

### Job Types

#### Single Job
```yaml
spec:
  completions: 1
  parallelism: 1
```

#### Parallel Jobs with Fixed Completion Count
```yaml
spec:
  completions: 10
  parallelism: 3
```

#### Parallel Jobs with Work Queue
```yaml
spec:
  parallelism: 5
  # No completions specified
```

### Completion Patterns

#### Sequential Processing
```
Job: Process 100 items
Completions: 100
Parallelism: 1
Result: 100 pods run sequentially
```

#### Parallel Processing
```
Job: Process 100 items
Completions: 100  
Parallelism: 10
Result: 10 pods run in parallel, 10 batches total
```

#### Work Queue Pattern
```
Job: Process queue until empty
Completions: Not specified
Parallelism: 5
Result: 5 workers process until queue empty
```

### Failure Handling
```yaml
spec:
  backoffLimit: 3  # Retry failed pods 3 times
  activeDeadlineSeconds: 3600  # Job timeout
```

### Restart Policies
```yaml
spec:
  template:
    spec:
      restartPolicy: Never  # or OnFailure
```

### Job Patterns

#### Database Migration
```yaml
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: migrate/migrate
        command: ["migrate", "-path", "/migrations", "-database", "$DB_URL", "up"]
```

#### Data Processing
```yaml
spec:
  completions: 100
  parallelism: 10
  template:
    spec:
      containers:
      - name: processor
        image: data-processor:v1
        env:
        - name: BATCH_ID
          value: "$(JOB_COMPLETION_INDEX)"
```

### Use Cases
- Database migrations
- Data processing
- Backup operations
- Batch computations
- ETL pipelines
- Machine learning training

### Management Commands
```bash
# Create job from YAML
kubectl apply -f job.yaml

# Monitor job progress
kubectl get jobs
kubectl describe job my-job

# View job logs
kubectl logs job/my-job

# Delete completed jobs
kubectl delete job my-job
```

---

## CronJob

### Definition
CronJob creates Jobs on a repeating schedule, similar to Unix cron.

### Key Characteristics
- **Scheduled Execution**: Based on cron expressions
- **Job Management**: Creates and manages underlying Jobs
- **History Management**: Controls completed job retention
- **Concurrency Control**: Manages overlapping executions

### Cron Schedule Format
```
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday)
# │ │ │ │ │
# * * * * *
```

### Common Cron Expressions
```yaml
"0 2 * * *"      # Daily at 2:00 AM
"*/15 * * * *"   # Every 15 minutes
"0 0 * * 0"      # Weekly on Sunday at midnight
"0 0 1 * *"      # Monthly on 1st day at midnight
"0 0 1 1 *"      # Yearly on Jan 1st at midnight
```

### Concurrency Policies

#### Allow (Default)
```yaml
concurrencyPolicy: Allow
# Multiple jobs can run simultaneously
```

#### Forbid
```yaml
concurrencyPolicy: Forbid
# Skip new job if previous still running
```

#### Replace
```yaml
concurrencyPolicy: Replace
# Cancel running job and start new one
```

### History Management
```yaml
spec:
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

### Deadline Management
```yaml
spec:
  startingDeadlineSeconds: 300  # Start within 5 minutes
  jobTemplate:
    spec:
      activeDeadlineSeconds: 3600  # Job timeout: 1 hour
```

### Common Patterns

#### Daily Backup
```yaml
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tool:v1
            command: ["backup-script.sh"]
```

#### Log Cleanup
```yaml
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cleanup
            image: busybox
            command: ["find", "/logs", "-mtime", "+7", "-delete"]
```

#### Health Monitoring
```yaml
spec:
  schedule: "*/5 * * * *"  # Every 5 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: health-check
            image: curl
            command: ["curl", "-f", "http://api/health"]
```

### Use Cases
- Scheduled backups
- Log rotation and cleanup
- Report generation
- Data synchronization
- Health checks
- Certificate renewal
- Batch processing

### Management Commands
```bash
# Create CronJob
kubectl apply -f cronjob.yaml

# List CronJobs
kubectl get cronjobs

# Manually trigger job
kubectl create job manual-backup --from=cronjob/backup-cronjob

# Suspend CronJob
kubectl patch cronjob backup-cronjob -p '{"spec":{"suspend":true}}'

# Resume CronJob
kubectl patch cronjob backup-cronjob -p '{"spec":{"suspend":false}}'
```

---

## Workload Comparison

| Workload | Use Case | Scaling | Updates | Persistence | Scheduling |
|----------|----------|---------|---------|-------------|------------|
| **Pod** | Single instance | Manual | Manual | Ephemeral | One-time |
| **ReplicaSet** | Basic replication | Manual | Manual | Ephemeral | Continuous |
| **Deployment** | Stateless apps | Manual/Auto | Rolling/Recreate | Ephemeral | Continuous |
| **DaemonSet** | Node services | Node-based | Rolling/OnDelete | Ephemeral | Per-node |
| **StatefulSet** | Stateful apps | Manual | Rolling/OnDelete | Persistent | Ordered |
| **Job** | Batch processing | Fixed | N/A | Ephemeral | One-time |
| **CronJob** | Scheduled tasks | Fixed | N/A | Ephemeral | Scheduled |

### Selection Criteria

#### Choose Pod when:
- Debugging or testing
- Single instance requirement
- Simple, short-lived tasks

#### Choose ReplicaSet when:
- Basic replication needed
- No update requirements
- Simple scaling needs

#### Choose Deployment when:
- Stateless applications
- Rolling updates required
- Web services and APIs
- Microservices

#### Choose DaemonSet when:
- Node-level services
- System monitoring
- Log collection
- Network plugins

#### Choose StatefulSet when:
- Databases
- Persistent storage required
- Ordered deployment needed
- Stable network identity required

#### Choose Job when:
- Batch processing
- One-time tasks
- Data migration
- Finite workloads

#### Choose CronJob when:
- Scheduled tasks
- Periodic backups
- Regular maintenance
- Time-based automation

---

## Best Practices

### General Workload Practices

#### Resource Management
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

#### Health Checks
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

#### Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
```

#### Labels and Annotations
```yaml
metadata:
  labels:
    app: myapp
    version: v1.0.0
    component: backend
    tier: api
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
```

### Deployment-Specific Practices

#### Update Strategy
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 25%
```

#### Readiness Gates
```yaml
spec:
  readinessGates:
  - conditionType: "example.com/feature-1"
```

### StatefulSet-Specific Practices

#### Headless Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None
  selector:
    app: mysql
```

#### Pod Management Policy
```yaml
spec:
  podManagementPolicy: OrderedReady  # or Parallel
```

### Job-Specific Practices

#### Completion Mode
```yaml
spec:
  completionMode: Indexed  # or NonIndexed
  completions: 10
  parallelism: 3
```

#### TTL After Finished
```yaml
spec:
  ttlSecondsAfterFinished: 3600  # Clean up after 1 hour
```

### Monitoring and Observability

#### Prometheus Metrics
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9090"
  prometheus.io/path: "/metrics"
```

#### Logging Configuration
```yaml
env:
- name: LOG_LEVEL
  value: "INFO"
- name: LOG_FORMAT
  value: "json"
```

### Performance Optimization

#### Node Affinity
```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      preference:
        matchExpressions:
        - key: node-type
          operator: In
          values: [compute-optimized]
```

#### Pod Anti-Affinity
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values: [myapp]
        topologyKey: kubernetes.io/hostname
```

### Troubleshooting Commands

```bash
# Check workload status
kubectl get pods,deployments,replicasets,jobs,cronjobs

# Describe workload
kubectl describe deployment myapp

# View logs
kubectl logs -f deployment/myapp

# Debug pod
kubectl exec -it pod-name -- /bin/bash

# Port forward for testing
kubectl port-forward deployment/myapp 8080:8080

# Scale workload
kubectl scale deployment myapp --replicas=5

# Check resource usage
kubectl top pods
kubectl top nodes
```

This comprehensive guide covers all Kubernetes workloads with practical examples, use cases, and best practices for production environments.
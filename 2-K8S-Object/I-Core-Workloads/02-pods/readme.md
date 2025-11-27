# Pods - Kubernetes Basic Unit

## 📚 Overview
Pod Kubernetes ka sabse basic aur fundamental unit hai. Ye ek ya multiple containers ko wrap karta hai aur shared resources provide karta hai.

## 🎯 What is a Pod?

### Definition
- **Pod** = Smallest deployable unit in Kubernetes
- **Container Group** = One or more tightly coupled containers
- **Shared Resources** = Network, storage, aur lifecycle
- **Atomic Unit** = Deploy, scale, aur manage together

### Key Characteristics
```
┌─────────────────────────────────────┐
│                POD                  │
│  ┌─────────────┐  ┌─────────────┐   │
│  │ Container 1 │  │ Container 2 │   │
│  │   (nginx)   │  │  (sidecar)  │   │
│  └─────────────┘  └─────────────┘   │
│                                     │
│  Shared:                            │
│  • Network (IP Address)             │
│  • Storage (Volumes)                │
│  • Lifecycle                        │
└─────────────────────────────────────┘
```

## 📖 Pod Types & Examples

### 1. Single Container Pod
**Most common pattern - ek container per pod**

```yaml
# 01-pod-basic.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    environment: development
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
      name: http
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

### 2. Multi-Container Pod
**Sidecar pattern - main container + helper container**

```yaml
# 02-pod-advanced.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app-pod
  labels:
    app: web-app
spec:
  containers:
  # Main application container
  - name: web-app
    image: nginx:1.21
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
    
  # Sidecar container for log processing
  - name: log-processor
    image: busybox
    command: ["sh", "-c"]
    args:
    - while true; do
        echo "Processing logs at $(date)" >> /var/log/app/processed.log;
        sleep 30;
      done
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/app
  
  volumes:
  - name: shared-logs
    emptyDir: {}
```

### 3. Init Container Pod
**Initialization logic before main containers**

```yaml
# 03-pod-lifecycle.yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo-pod
spec:
  initContainers:
  - name: init-database
    image: busybox:1.35
    command: ['sh', '-c']
    args:
    - echo "Initializing database...";
      sleep 10;
      echo "Database ready!";
  
  - name: init-cache
    image: busybox:1.35
    command: ['sh', '-c']
    args:
    - echo "Setting up cache...";
      sleep 5;
      echo "Cache ready!";
  
  containers:
  - name: main-app
    image: nginx:1.21
    ports:
    - containerPort: 80
```

### 4. Production-Ready Pod
**Complete configuration with all best practices**

```yaml
# 04-pod-production.yaml
apiVersion: v1
kind: Pod
metadata:
  name: production-app
  labels:
    app: production-app
    version: v1.0.0
    environment: production
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
spec:
  # Security Context
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  
  containers:
  - name: app
    image: spicybiryaniwala.shop/app:v1.0.0
    imagePullPolicy: Always
    
    ports:
    - containerPort: 8080
      name: http
    - containerPort: 9090
      name: metrics
    
    # Environment Variables
    env:
    - name: APP_ENV
      value: "production"
    - name: DB_HOST
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: host
    
    # Resource Management
    resources:
      requests:
        memory: "256Mi"
        cpu: "500m"
      limits:
        memory: "512Mi"
        cpu: "1000m"
    
    # Health Checks
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      failureThreshold: 3
    
    # Startup Probe (for slow starting apps)
    startupProbe:
      httpGet:
        path: /startup
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 30
    
    # Volume Mounts
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
    
    # Security Context
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
  
  # Volumes
  volumes:
  - name: config-volume
    configMap:
      name: app-config
  - name: secret-volume
    secret:
      secretName: app-secret
  
  # Image Pull Secrets
  imagePullSecrets:
  - name: registry-secret
  
  # Node Selection
  nodeSelector:
    kubernetes.io/os: linux
    node-type: application
  
  # Tolerations
  tolerations:
  - key: "app-nodes"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  
  # Restart Policy
  restartPolicy: Always
  
  # DNS Policy
  dnsPolicy: ClusterFirst
```

## 🔧 Pod Management Commands

### Basic Operations
```bash
# Create pod from YAML
kubectl apply -f 01-pod-basic.yaml

# Get pods
kubectl get pods
kubectl get pods -o wide
kubectl get pods --show-labels

# Describe pod (detailed info)
kubectl describe pod nginx-pod

# Get pod YAML
kubectl get pod nginx-pod -o yaml

# Delete pod
kubectl delete pod nginx-pod
kubectl delete -f 01-pod-basic.yaml
```

### Debugging Commands
```bash
# Check pod logs
kubectl logs nginx-pod
kubectl logs nginx-pod -f  # Follow logs
kubectl logs nginx-pod --previous  # Previous container logs

# Multi-container pod logs
kubectl logs web-app-pod -c web-app
kubectl logs web-app-pod -c log-processor

# Execute commands in pod
kubectl exec nginx-pod -- ls -la
kubectl exec -it nginx-pod -- /bin/bash

# Multi-container pod exec
kubectl exec -it web-app-pod -c web-app -- /bin/bash

# Port forwarding
kubectl port-forward nginx-pod 8080:80

# Copy files
kubectl cp nginx-pod:/etc/nginx/nginx.conf ./nginx.conf
kubectl cp ./local-file.txt nginx-pod:/tmp/
```

### Monitoring Commands
```bash
# Resource usage
kubectl top pod nginx-pod

# Events
kubectl get events --field-selector involvedObject.name=nginx-pod

# Pod status
kubectl get pod nginx-pod -o jsonpath='{.status.phase}'

# Container status
kubectl get pod nginx-pod -o jsonpath='{.status.containerStatuses[0].state}'
```

## 🔍 Pod Lifecycle

### Pod Phases
```
Pending → Running → Succeeded/Failed
   ↓         ↓           ↓
Creating  Executing   Completed
```

### Container States
```yaml
# Container States
state:
  waiting:
    reason: "ImagePullBackOff"
  running:
    startedAt: "2024-01-15T10:30:00Z"
  terminated:
    exitCode: 0
    finishedAt: "2024-01-15T11:00:00Z"
```

### Restart Policies
```yaml
# Always (default) - restart on any termination
restartPolicy: Always

# OnFailure - restart only on failure
restartPolicy: OnFailure

# Never - never restart
restartPolicy: Never
```

## 🛡️ Security Best Practices

### 1. Security Context
```yaml
securityContext:
  # Pod level
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000
  
  # Container level
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE
  readOnlyRootFilesystem: true
```

### 2. Resource Limits
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

### 3. Health Checks
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

## 🚨 Common Issues & Troubleshooting

### 1. ImagePullBackOff
```bash
# Check image name and tag
kubectl describe pod <pod-name>

# Check image pull secrets
kubectl get secrets

# Test image pull manually
docker pull <image-name>
```

### 2. CrashLoopBackOff
```bash
# Check logs
kubectl logs <pod-name> --previous

# Check resource limits
kubectl describe pod <pod-name>

# Check health probes
kubectl get pod <pod-name> -o yaml | grep -A 10 "livenessProbe"
```

### 3. Pending State
```bash
# Check node resources
kubectl describe nodes

# Check pod requirements
kubectl describe pod <pod-name>

# Check scheduling constraints
kubectl get pod <pod-name> -o yaml | grep -A 5 "nodeSelector"
```

### 4. OOMKilled (Out of Memory)
```bash
# Check resource usage
kubectl top pod <pod-name>

# Check resource limits
kubectl describe pod <pod-name> | grep -A 5 "Limits"

# Increase memory limits
kubectl patch pod <pod-name> -p '{"spec":{"containers":[{"name":"<container>","resources":{"limits":{"memory":"512Mi"}}}]}}'
```

## 📊 Monitoring & Observability

### Metrics to Monitor
```bash
# CPU Usage
kubectl top pod --containers

# Memory Usage
kubectl top pod --sort-by=memory

# Network I/O
kubectl exec <pod-name> -- cat /proc/net/dev

# Disk Usage
kubectl exec <pod-name> -- df -h
```

### Logging Strategy
```yaml
# Structured logging
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    env:
    - name: LOG_LEVEL
      value: "info"
    - name: LOG_FORMAT
      value: "json"
```

## 🎯 Best Practices

### 1. **Single Responsibility**
- Ek pod mein ek main application
- Sidecar containers for supporting functions

### 2. **Resource Management**
- Always set resource requests aur limits
- Monitor resource usage regularly

### 3. **Health Checks**
- Implement liveness aur readiness probes
- Use startup probes for slow applications

### 4. **Security**
- Run as non-root user
- Use read-only root filesystem
- Drop unnecessary capabilities

### 5. **Configuration**
- Use ConfigMaps for configuration
- Use Secrets for sensitive data
- Avoid hardcoding values

## 📋 Practical Exercises

### Exercise 1: Basic Pod Creation
```bash
# 1. Create a simple nginx pod
kubectl run nginx --image=nginx:1.21 --port=80

# 2. Check pod status
kubectl get pods

# 3. Access pod
kubectl port-forward nginx 8080:80

# 4. Test in browser: http://localhost:8080
```

### Exercise 2: Multi-Container Pod
```bash
# 1. Apply multi-container pod
kubectl apply -f 02-pod-advanced.yaml

# 2. Check both containers
kubectl get pod web-app-pod -o jsonpath='{.spec.containers[*].name}'

# 3. Check logs from both containers
kubectl logs web-app-pod -c web-app
kubectl logs web-app-pod -c log-processor
```

### Exercise 3: Troubleshooting
```bash
# 1. Create a problematic pod
kubectl run broken-pod --image=nginx:wrong-tag

# 2. Debug the issue
kubectl describe pod broken-pod
kubectl get events --field-selector involvedObject.name=broken-pod

# 3. Fix and recreate
kubectl delete pod broken-pod
kubectl run fixed-pod --image=nginx:1.21
```

## 🔗 Related Topics

- **[ReplicaSets](../replicaset/)** - Pod replication
- **[Deployments](../deployment/)** - Pod management
- **[Services](../services/)** - Pod networking
- **[ConfigMaps & Secrets](../../C-Application-lifecycle-management/configmap/)** - Pod configuration

---

**Next:** [ReplicaSets](../replicaset/) - Pod Replication Management
# C. Application Lifecycle Management

## 📚 Overview
Kubernetes Application Lifecycle Management complete guide. Ye section aapko sikhayega ki kaise applications ko efficiently manage karna hai - deployment se leker scaling, configuration, aur maintenance tak.

## 🎯 What You'll Learn
- Complete application deployment strategies
- Configuration management techniques
- Auto-scaling mechanisms
- Multi-container design patterns
- Self-healing application architectures
- Production-grade lifecycle management

## 📖 Lifecycle Components

### 1. [Core Concepts](./core-concept/) 🎯
**Fundamental application management concepts**

**Key Topics:**
- Application architecture patterns
- Kubernetes-native applications
- Microservices design
- Container orchestration principles

**Use Cases:**
- Application design planning
- Architecture decisions
- Best practices implementation

---

### 2. [Deployment Strategies](./deployment-strategy/) 🚀
**Advanced deployment techniques**

**Strategies Covered:**
- **Rolling Update** - Gradual replacement
- **Blue-Green** - Environment switching
- **Canary** - Gradual traffic shifting
- **Recreate** - Complete replacement

**Example - Canary Deployment:**
```yaml
# canary.yml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app-canary
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10    # 10% traffic to canary
      - pause: {duration: 30s}
      - setWeight: 50    # 50% traffic to canary
      - pause: {duration: 60s}
      - setWeight: 100   # Full rollout
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
        image: spicybiryaniwala.shop/web-app:v2.0.0
```

---

### 3. [Auto Scaling](./Auto-scalling/) 📈
**Automatic resource scaling mechanisms**

#### A. [Horizontal Pod Autoscaler (HPA)](./Auto-scalling/HPA/)
**Pod count scaling based on metrics**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

#### B. [Vertical Pod Autoscaler (VPA)](./Auto-scalling/VPA/)
**Resource limit scaling**

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: web-app
      maxAllowed:
        cpu: 2
        memory: 4Gi
      minAllowed:
        cpu: 100m
        memory: 128Mi
```

#### C. [Cluster Autoscaling](./Auto-scalling/KARPENTER-CASTAI/)
**Node-level scaling with Karpenter/CAST AI**

```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      labels:
        node-type: general-purpose
    spec:
      requirements:
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ["t3.medium", "t3.large", "t3.xlarge"]
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default
  disruption:
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 30s
```

---

### 4. [Configuration Management](./configure-application/) ⚙️
**Application configuration strategies**

#### [ConfigMaps](./configmap/)
**Non-sensitive configuration data**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.properties: |
    host=database.spicybiryaniwala.shop
    port=5432
    name=production_db
    pool_size=20
  app.yaml: |
    server:
      port: 8080
      host: 0.0.0.0
    logging:
      level: info
      format: json
```

#### [Secrets](./Secret/)
**Sensitive configuration data**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database-password: cGFzc3dvcmQxMjM=  # base64 encoded
  api-key: YWJjZGVmZ2hpams=
  jwt-secret: c2VjcmV0a2V5MTIz
```

#### [Environment Variables](./env-variables-application/)
**Runtime configuration injection**

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: web-app
        env:
        # Direct values
        - name: APP_ENV
          value: "production"
        
        # From ConfigMap
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database.host
        
        # From Secret
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-password
        
        # Field references
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        
        # Resource references
        - name: CPU_LIMIT
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
```

---

### 5. [Multi-Pod Design Patterns](./multi-pods-design-pattern/) 🏗️
**Container collaboration patterns**

#### **Sidecar Pattern**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app-with-sidecar
spec:
  containers:
  # Main application
  - name: web-app
    image: spicybiryaniwala.shop/web-app:latest
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/app
  
  # Sidecar for log processing
  - name: log-processor
    image: fluentd:v1.14
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/app
    - name: fluentd-config
      mountPath: /fluentd/etc
  
  volumes:
  - name: shared-logs
    emptyDir: {}
  - name: fluentd-config
    configMap:
      name: fluentd-config
```

#### **Ambassador Pattern**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-ambassador
spec:
  containers:
  # Main application
  - name: app
    image: spicybiryaniwala.shop/app:latest
    env:
    - name: DATABASE_URL
      value: "localhost:5432"  # Connect via ambassador
  
  # Ambassador proxy
  - name: db-ambassador
    image: haproxy:2.4
    ports:
    - containerPort: 5432
    volumeMounts:
    - name: haproxy-config
      mountPath: /usr/local/etc/haproxy
  
  volumes:
  - name: haproxy-config
    configMap:
      name: haproxy-config
```

---

### 6. [Init Containers](./initcontainers/) 🚀
**Initialization logic before main containers**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-init
spec:
  initContainers:
  # Database migration
  - name: db-migration
    image: spicybiryaniwala.shop/db-migrator:latest
    env:
    - name: DB_URL
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: url
    command: ["migrate", "up"]
  
  # Cache warming
  - name: cache-warmer
    image: redis:7-alpine
    command: ["redis-cli", "-h", "redis-service", "ping"]
  
  # Configuration setup
  - name: config-setup
    image: busybox
    command: ["sh", "-c"]
    args:
    - |
      echo "Setting up configuration..."
      cp /config-template/* /shared-config/
      chmod 644 /shared-config/*
    volumeMounts:
    - name: config-template
      mountPath: /config-template
    - name: shared-config
      mountPath: /shared-config
  
  containers:
  - name: main-app
    image: spicybiryaniwala.shop/app:latest
    volumeMounts:
    - name: shared-config
      mountPath: /etc/app-config
  
  volumes:
  - name: config-template
    configMap:
      name: app-config-template
  - name: shared-config
    emptyDir: {}
```

---

### 7. [Self-Healing Applications](./self-healing-app/) 🔄
**Automatic recovery mechanisms**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: self-healing-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: spicybiryaniwala.shop/app:latest
        
        # Health checks for self-healing
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
        
        # Startup probe for slow applications
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 30
        
        # Resource limits for stability
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        # Lifecycle hooks
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
      
      # Restart policy
      restartPolicy: Always
      
      # Termination grace period
      terminationGracePeriodSeconds: 30
---
# Pod Disruption Budget for availability
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: self-healing-app
```

---

### 8. [Commands & Arguments](./cmd-argument-k8s/) 💻
**Container command customization**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-command-pod
spec:
  containers:
  # Override Docker ENTRYPOINT and CMD
  - name: app
    image: spicybiryaniwala.shop/app:latest
    command: ["/bin/sh"]  # Override ENTRYPOINT
    args: ["-c", "while true; do echo hello; sleep 10; done"]  # Override CMD
  
  # Environment-specific startup
  - name: worker
    image: spicybiryaniwala.shop/worker:latest
    command: ["python"]
    args: ["worker.py", "--env", "production", "--workers", "4"]
    env:
    - name: WORKER_TYPE
      value: "background"
  
  # Conditional execution
  - name: conditional-app
    image: spicybiryaniwala.shop/app:latest
    command: ["/bin/bash", "-c"]
    args:
    - |
      if [ "$APP_ENV" = "production" ]; then
        exec /app/production-start.sh
      else
        exec /app/development-start.sh
      fi
    env:
    - name: APP_ENV
      value: "production"
```

---

### 9. [Application Scaling](./scale-application/) 📊
**Manual and automatic scaling strategies**

```yaml
# Manual scaling
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scalable-app
spec:
  replicas: 5  # Manual replica count
  
  # Rolling update strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  
  template:
    spec:
      containers:
      - name: app
        image: spicybiryaniwala.shop/app:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
# Automatic scaling with custom metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: custom-metrics-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: scalable-app
  minReplicas: 2
  maxReplicas: 50
  metrics:
  # CPU utilization
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  
  # Memory utilization
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  
  # Custom metrics (requires metrics server)
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "100"
  
  # External metrics
  - type: External
    external:
      metric:
        name: queue_length
        selector:
          matchLabels:
            queue: worker-queue
      target:
        type: Value
        value: "10"
  
  # Scaling behavior
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
```

## 🔧 Lifecycle Management Commands

### Deployment Management
```bash
# Create deployment
kubectl create deployment app --image=nginx:1.21 --replicas=3

# Scale deployment
kubectl scale deployment app --replicas=5

# Update image
kubectl set image deployment/app nginx=nginx:1.22

# Check rollout status
kubectl rollout status deployment/app

# Rollback deployment
kubectl rollout undo deployment/app
```

### Configuration Management
```bash
# Create ConfigMap from file
kubectl create configmap app-config --from-file=config.properties

# Create Secret from literal
kubectl create secret generic app-secret --from-literal=password=secret123

# Update ConfigMap
kubectl patch configmap app-config -p '{"data":{"key":"new-value"}}'

# Restart deployment after config change
kubectl rollout restart deployment/app
```

### Auto-scaling Management
```bash
# Create HPA
kubectl autoscale deployment app --min=2 --max=10 --cpu-percent=80

# Check HPA status
kubectl get hpa

# Describe HPA
kubectl describe hpa app

# Delete HPA
kubectl delete hpa app
```

## 🚨 Troubleshooting

### Common Issues

#### 1. **Configuration Issues**
```bash
# Check ConfigMap/Secret mounting
kubectl describe pod <pod-name> | grep -A 10 Mounts

# Verify configuration data
kubectl get configmap app-config -o yaml
kubectl get secret app-secret -o yaml

# Check environment variables
kubectl exec <pod-name> -- env | grep APP_
```

#### 2. **Scaling Issues**
```bash
# Check HPA status
kubectl describe hpa <hpa-name>

# Check metrics server
kubectl top nodes
kubectl top pods

# Check resource requests/limits
kubectl describe deployment <deployment-name> | grep -A 5 Limits
```

#### 3. **Health Check Failures**
```bash
# Check probe configuration
kubectl describe pod <pod-name> | grep -A 10 Liveness

# Check application logs
kubectl logs <pod-name> --previous

# Test health endpoints manually
kubectl exec <pod-name> -- curl localhost:8080/health
```

## 📊 Best Practices

### 1. **Configuration Management**
- Use ConfigMaps for non-sensitive data
- Use Secrets for sensitive information
- Implement configuration validation
- Version your configurations

### 2. **Health Checks**
- Always implement health endpoints
- Use appropriate probe timeouts
- Implement graceful shutdown
- Monitor probe failures

### 3. **Resource Management**
- Set appropriate resource requests/limits
- Use HPA for automatic scaling
- Monitor resource utilization
- Plan for peak loads

### 4. **Deployment Strategies**
- Use rolling updates for zero downtime
- Implement canary deployments for risk mitigation
- Use blue-green for instant rollbacks
- Test deployment strategies in staging

## 🎯 Learning Path

### Week 1: Fundamentals
1. **Core Concepts** - Application architecture
2. **Configuration** - ConfigMaps and Secrets
3. **Basic Deployment** - Simple deployment strategies

### Week 2: Intermediate
1. **Health Checks** - Probes and self-healing
2. **Init Containers** - Initialization patterns
3. **Multi-Container** - Design patterns

### Week 3: Advanced
1. **Auto-scaling** - HPA and VPA
2. **Deployment Strategies** - Blue-green, Canary
3. **Advanced Patterns** - Sidecar, Ambassador

### Week 4: Production
1. **Monitoring** - Observability setup
2. **Security** - Security best practices
3. **Optimization** - Performance tuning

## 🔗 Quick Navigation

| Component | Complexity | Use Case | Production Ready |
|-----------|------------|----------|------------------|
| [Core Concepts](./core-concept/) | ⭐ | Foundation | ✅ |
| [Deployment Strategies](./deployment-strategy/) | ⭐⭐⭐ | Zero-downtime deployments | ✅ |
| [Auto Scaling](./Auto-scalling/) | ⭐⭐⭐ | Resource optimization | ✅ |
| [Configuration](./configure-application/) | ⭐⭐ | App configuration | ✅ |
| [Multi-Pod Patterns](./multi-pods-design-pattern/) | ⭐⭐⭐ | Complex architectures | ✅ |
| [Init Containers](./initcontainers/) | ⭐⭐ | Initialization logic | ✅ |
| [Self-Healing](./self-healing-app/) | ⭐⭐⭐ | High availability | ✅ |
| [Commands & Args](./cmd-argument-k8s/) | ⭐ | Container customization | ✅ |
| [Scaling](./scale-application/) | ⭐⭐ | Performance management | ✅ |

---

**Next:** [D-k8s-storage](../D-k8s-storage/) - Kubernetes Storage Management
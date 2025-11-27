# Deployments - Application Management

## 📚 Overview
Kubernetes Deployment sabse important workload type hai production applications ke liye. Ye ReplicaSets ko manage karta hai aur rolling updates, rollbacks, aur scaling provide karta hai.

## 🎯 What is a Deployment?

### Definition
- **Higher-level abstraction** over ReplicaSets
- **Declarative updates** for Pods aur ReplicaSets
- **Rolling updates** aur rollback capabilities
- **Version management** aur deployment strategies

### Architecture
```
Deployment
    ↓
ReplicaSet (v1) → Pod → Pod → Pod
    ↓
ReplicaSet (v2) → Pod → Pod → Pod (New Version)
```

## 📖 Deployment Examples

### 1. Basic Deployment
**Simple web application deployment**

```yaml
# 01-deployment-basic.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
    environment: development
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
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

### 2. Production Deployment
**Complete production-ready configuration**

```yaml
# 02-deployment-production.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-deployment
  namespace: production
  labels:
    app: web-app
    version: v1.0.0
    environment: production
  annotations:
    deployment.kubernetes.io/revision: "1"
    kubernetes.io/change-cause: "Initial deployment v1.0.0"
spec:
  replicas: 5
  
  # Deployment Strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2          # 2 extra pods during update
      maxUnavailable: 1    # Max 1 pod unavailable
  
  # Revision History
  revisionHistoryLimit: 10
  
  # Progress Deadline
  progressDeadlineSeconds: 600
  
  selector:
    matchLabels:
      app: web-app
  
  template:
    metadata:
      labels:
        app: web-app
        version: v1.0.0
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
      - name: web-app
        image: spicybiryaniwala.shop/web-app:v1.0.0
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
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: redis-url
        
        # Resource Management
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
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
        
        # Startup Probe
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 30
        
        # Volume Mounts
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
        - name: temp-volume
          mountPath: /tmp
        
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
      - name: temp-volume
        emptyDir: {}
      
      # Image Pull Secrets
      imagePullSecrets:
      - name: registry-secret
      
      # Node Selection
      nodeSelector:
        kubernetes.io/os: linux
        node-type: application
      
      # Affinity Rules
      affinity:
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
      
      # Tolerations
      tolerations:
      - key: "app-nodes"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
```

### 3. Multi-Environment Deployment
**Different configurations for different environments**

```yaml
# 03-deployment-staging.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-staging
  namespace: staging
  labels:
    app: web-app
    environment: staging
spec:
  replicas: 2  # Less replicas for staging
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero downtime for staging tests
  
  selector:
    matchLabels:
      app: web-app
      environment: staging
  
  template:
    metadata:
      labels:
        app: web-app
        environment: staging
    spec:
      containers:
      - name: web-app
        image: spicybiryaniwala.shop/web-app:staging-latest
        
        env:
        - name: APP_ENV
          value: "staging"
        - name: DEBUG_MODE
          value: "true"
        - name: LOG_LEVEL
          value: "debug"
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        # More frequent health checks for testing
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 5
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 3
```

### 4. Canary Deployment
**Gradual rollout strategy**

```yaml
# 04-deployment-canary.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-canary
  labels:
    app: web-app
    version: canary
spec:
  replicas: 1  # Start with 1 replica for canary
  
  selector:
    matchLabels:
      app: web-app
      version: canary
  
  template:
    metadata:
      labels:
        app: web-app
        version: canary
    spec:
      containers:
      - name: web-app
        image: spicybiryaniwala.shop/web-app:v2.0.0-canary
        
        env:
        - name: CANARY_DEPLOYMENT
          value: "true"
        - name: FEATURE_FLAGS
          value: "new-feature=true"
        
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

## 🔧 Deployment Management Commands

### Basic Operations
```bash
# Create deployment
kubectl apply -f 01-deployment-basic.yaml

# Get deployments
kubectl get deployments
kubectl get deploy -o wide

# Describe deployment
kubectl describe deployment nginx-deployment

# Get deployment YAML
kubectl get deployment nginx-deployment -o yaml
```

### Scaling Operations
```bash
# Manual scaling
kubectl scale deployment nginx-deployment --replicas=5

# Check scaling status
kubectl get deployment nginx-deployment -w

# Autoscaling
kubectl autoscale deployment nginx-deployment --min=2 --max=10 --cpu-percent=80

# Check HPA
kubectl get hpa
```

### Update Operations
```bash
# Update image (rolling update)
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# Update with annotation
kubectl annotate deployment nginx-deployment kubernetes.io/change-cause="Updated to nginx 1.22"

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# Check rollout history
kubectl rollout history deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Rollback to specific revision
kubectl rollout undo deployment/nginx-deployment --to-revision=2

# Pause rollout
kubectl rollout pause deployment/nginx-deployment

# Resume rollout
kubectl rollout resume deployment/nginx-deployment
```

### Advanced Operations
```bash
# Edit deployment
kubectl edit deployment nginx-deployment

# Patch deployment
kubectl patch deployment nginx-deployment -p '{"spec":{"replicas":3}}'

# Replace deployment
kubectl replace -f updated-deployment.yaml

# Delete deployment
kubectl delete deployment nginx-deployment
```

## 🚀 Deployment Strategies

### 1. Rolling Update (Default)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%        # 25% extra pods
    maxUnavailable: 25%  # 25% pods can be unavailable
```

**Advantages:**
- Zero downtime
- Gradual rollout
- Easy rollback

**Use Cases:**
- Production applications
- Stateless services
- Web applications

### 2. Recreate Strategy
```yaml
strategy:
  type: Recreate
```

**Process:**
1. Stop all old pods
2. Start new pods
3. Brief downtime

**Use Cases:**
- Stateful applications
- Database migrations
- Resource constraints

### 3. Blue-Green Deployment
```bash
# Step 1: Deploy green version
kubectl apply -f deployment-green.yaml

# Step 2: Test green version
kubectl port-forward deployment/app-green 8080:80

# Step 3: Switch traffic (update service)
kubectl patch service app-service -p '{"spec":{"selector":{"version":"green"}}}'

# Step 4: Remove blue version
kubectl delete deployment app-blue
```

### 4. Canary Deployment
```bash
# Step 1: Deploy canary (10% traffic)
kubectl apply -f deployment-canary.yaml
kubectl scale deployment app-canary --replicas=1
kubectl scale deployment app-stable --replicas=9

# Step 2: Monitor metrics
kubectl top pods -l app=web-app

# Step 3: Gradually increase canary traffic
kubectl scale deployment app-canary --replicas=3
kubectl scale deployment app-stable --replicas=7

# Step 4: Full rollout or rollback
kubectl scale deployment app-canary --replicas=10
kubectl delete deployment app-stable
```

## 🔍 Monitoring & Observability

### Deployment Status
```bash
# Check deployment status
kubectl get deployment nginx-deployment -o jsonpath='{.status}'

# Check replica status
kubectl get rs -l app=nginx

# Check pod status
kubectl get pods -l app=nginx

# Watch deployment progress
kubectl get deployment nginx-deployment -w
```

### Metrics & Events
```bash
# Resource usage
kubectl top deployment

# Events
kubectl get events --field-selector involvedObject.name=nginx-deployment

# Deployment conditions
kubectl get deployment nginx-deployment -o jsonpath='{.status.conditions[*].type}'
```

### Logging
```bash
# All pods logs
kubectl logs -l app=nginx --tail=100

# Follow logs
kubectl logs -f deployment/nginx-deployment

# Previous deployment logs
kubectl logs deployment/nginx-deployment --previous
```

## 🚨 Troubleshooting

### Common Issues

#### 1. ImagePullBackOff
```bash
# Check image and registry
kubectl describe deployment nginx-deployment

# Check image pull secrets
kubectl get secrets

# Fix: Update image or add pull secret
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"registry-secret"}]}}}}'
```

#### 2. Insufficient Resources
```bash
# Check node resources
kubectl describe nodes

# Check resource requests
kubectl describe deployment nginx-deployment

# Fix: Adjust resource requests or add nodes
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"memory":"128Mi"}}}]}}}}'
```

#### 3. Failed Rollout
```bash
# Check rollout status
kubectl rollout status deployment/nginx-deployment --timeout=300s

# Check events
kubectl describe deployment nginx-deployment

# Rollback if needed
kubectl rollout undo deployment/nginx-deployment
```

#### 4. Pod Scheduling Issues
```bash
# Check pod events
kubectl get events --field-selector reason=FailedScheduling

# Check node selectors and affinity
kubectl get deployment nginx-deployment -o yaml | grep -A 10 nodeSelector

# Fix: Adjust scheduling constraints
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'
```

## 🛡️ Security Best Practices

### 1. Image Security
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        image: spicybiryaniwala.shop/app:v1.0.0@sha256:abc123...  # Use digest
        imagePullPolicy: Always
```

### 2. Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
  seccompProfile:
    type: RuntimeDefault
```

### 3. Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-app-netpol
spec:
  podSelector:
    matchLabels:
      app: web-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### 4. Resource Limits
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 📊 Performance Optimization

### 1. Resource Tuning
```bash
# Monitor resource usage
kubectl top pods -l app=nginx

# Adjust based on metrics
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"cpu":"500m","memory":"512Mi"}}}]}}}}'
```

### 2. Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2
  maxReplicas: 10
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

### 3. Pod Disruption Budget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: nginx
```

## 📋 Practical Exercises

### Exercise 1: Basic Deployment
```bash
# 1. Create deployment
kubectl create deployment nginx --image=nginx:1.21 --replicas=3

# 2. Expose deployment
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# 3. Scale deployment
kubectl scale deployment nginx --replicas=5

# 4. Update image
kubectl set image deployment/nginx nginx=nginx:1.22

# 5. Check rollout
kubectl rollout status deployment/nginx
```

### Exercise 2: Rolling Update
```bash
# 1. Create deployment with annotation
kubectl create deployment web-app --image=nginx:1.20
kubectl annotate deployment web-app kubernetes.io/change-cause="Initial deployment"

# 2. Update to new version
kubectl set image deployment/web-app nginx=nginx:1.21
kubectl annotate deployment web-app kubernetes.io/change-cause="Updated to nginx 1.21"

# 3. Check history
kubectl rollout history deployment/web-app

# 4. Rollback
kubectl rollout undo deployment/web-app

# 5. Verify rollback
kubectl rollout history deployment/web-app
```

### Exercise 3: Canary Deployment
```bash
# 1. Create stable deployment
kubectl create deployment app-stable --image=nginx:1.20 --replicas=9
kubectl label deployment app-stable version=stable

# 2. Create canary deployment
kubectl create deployment app-canary --image=nginx:1.21 --replicas=1
kubectl label deployment app-canary version=canary

# 3. Create service for both
kubectl create service clusterip app-service --tcp=80:80
kubectl patch service app-service -p '{"spec":{"selector":{"app":"app"}}}'

# 4. Monitor and adjust traffic
kubectl get pods -l app=app --show-labels
```

## 🔗 Related Topics

- **[ReplicaSets](../replicaset/)** - Underlying pod management
- **[Services](../services/)** - Network access
- **[ConfigMaps & Secrets](../../C-Application-lifecycle-management/configmap/)** - Configuration
- **[HPA](../../C-Application-lifecycle-management/Auto-scalling/HPA/)** - Auto scaling

---

**Next:** [Services](../services/) - Network Access & Load Balancing
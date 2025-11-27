# Services - Network Access & Load Balancing

## 📚 Overview
Kubernetes Services network connectivity aur load balancing provide karte hain. Ye pods ko stable network identity aur discovery mechanism dete hain.

## 🎯 What is a Service?

### Definition
- **Network abstraction** for accessing pods
- **Load balancing** across multiple pods
- **Service discovery** mechanism
- **Stable endpoint** despite pod changes

### Architecture
```
Client Request
     ↓
Service (Virtual IP)
     ↓
Load Balancer
     ↓
Pod1    Pod2    Pod3
```

## 📖 Service Types

### 1. ClusterIP (Default)
**Internal cluster access only**

```yaml
# 01-service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-clusterip
  labels:
    app: web-app
    service-type: clusterip
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - name: http
    port: 80          # Service port
    targetPort: 8080  # Pod port
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: 9090
    protocol: TCP
```

**Use Cases:**
- Internal microservices communication
- Database access within cluster
- Internal APIs

### 2. NodePort
**External access via node ports**

```yaml
# 02-service-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-nodeport
  labels:
    app: web-app
    service-type: nodeport
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
    nodePort: 30080    # External port (30000-32767)
    protocol: TCP
```

**Access:** `http://<node-ip>:30080`

**Use Cases:**
- Development environments
- Testing external access
- Simple external exposure

### 3. LoadBalancer
**Cloud load balancer integration**

```yaml
# 03-service-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-loadbalancer
  labels:
    app: web-app
    service-type: loadbalancer
  annotations:
    # AWS Load Balancer Controller annotations
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    # Health check annotations
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/health"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 8443
    protocol: TCP
  
  # Load balancer source ranges (security)
  loadBalancerSourceRanges:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
```

**Use Cases:**
- Production web applications
- Public APIs
- External services

### 4. ExternalName
**DNS CNAME mapping**

```yaml
# 04-service-externalname.yaml
apiVersion: v1
kind: Service
metadata:
  name: external-database
  labels:
    service-type: externalname
spec:
  type: ExternalName
  externalName: database.spicybiryaniwala.shop
  ports:
  - port: 5432
    targetPort: 5432
    protocol: TCP
```

**Use Cases:**
- External database access
- Third-party service integration
- Service migration

### 5. Headless Service
**Direct pod access without load balancing**

```yaml
# 05-service-headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-headless
  labels:
    app: web-app
    service-type: headless
spec:
  clusterIP: None  # Makes it headless
  selector:
    app: web-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
```

**Use Cases:**
- StatefulSets
- Database clusters
- Service mesh
- Custom load balancing

## 🔧 Advanced Service Configurations

### 1. Multi-Port Service
```yaml
# 06-service-multiport.yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: web-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
  - name: metrics
    port: 9090
    targetPort: 9090
  - name: admin
    port: 8081
    targetPort: 8081
```

### 2. Service with Session Affinity
```yaml
# 07-service-session-affinity.yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-session-service
spec:
  selector:
    app: web-app
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 hours
  ports:
  - port: 80
    targetPort: 8080
```

### 3. Service with Custom Endpoints
```yaml
# 08-service-custom-endpoints.yaml
apiVersion: v1
kind: Service
metadata:
  name: custom-endpoint-service
spec:
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Endpoints
metadata:
  name: custom-endpoint-service
subsets:
- addresses:
  - ip: 192.168.1.100
  - ip: 192.168.1.101
  ports:
  - port: 8080
```

### 4. Production-Ready Service
```yaml
# 09-service-production.yaml
apiVersion: v1
kind: Service
metadata:
  name: production-web-service
  namespace: production
  labels:
    app: web-app
    environment: production
    version: v1.0.0
  annotations:
    # Monitoring annotations
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
    
    # AWS Load Balancer annotations
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
    
    # SSL/TLS annotations
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:region:account:certificate/cert-id"
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
    
    # Health check annotations
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/health"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "5"
    service.beta.kubernetes.io/aws-load-balancer-healthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-unhealthy-threshold: "3"

spec:
  type: LoadBalancer
  
  # Pod selector
  selector:
    app: web-app
    environment: production
  
  # Port configuration
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 8080
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: 9090
    protocol: TCP
  
  # Security: Restrict source IPs
  loadBalancerSourceRanges:
  - 0.0.0.0/0  # Allow all (adjust for production)
  
  # External traffic policy
  externalTrafficPolicy: Local  # Preserve source IP
```

## 🔧 Service Management Commands

### Basic Operations
```bash
# Create service
kubectl apply -f 01-service-clusterip.yaml

# Get services
kubectl get services
kubectl get svc -o wide

# Describe service
kubectl describe service web-app-clusterip

# Get service YAML
kubectl get service web-app-clusterip -o yaml

# Delete service
kubectl delete service web-app-clusterip
```

### Service Discovery
```bash
# Get service endpoints
kubectl get endpoints web-app-clusterip

# Check service DNS
kubectl run test-pod --image=busybox -it --rm -- nslookup web-app-clusterip

# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- wget -qO- web-app-clusterip
```

### Port Forwarding
```bash
# Forward local port to service
kubectl port-forward service/web-app-clusterip 8080:80

# Forward to specific pod
kubectl port-forward pod/web-app-pod-123 8080:8080

# Forward with specific address
kubectl port-forward --address 0.0.0.0 service/web-app-clusterip 8080:80
```

### Service Troubleshooting
```bash
# Check service endpoints
kubectl get endpoints

# Check service selector
kubectl get service web-app-clusterip -o jsonpath='{.spec.selector}'

# Check matching pods
kubectl get pods -l app=web-app

# Test service from inside cluster
kubectl exec -it test-pod -- curl web-app-clusterip
```

## 🔍 Service Discovery & DNS

### DNS Resolution
```bash
# Service DNS format
<service-name>.<namespace>.svc.cluster.local

# Examples
web-app-clusterip.default.svc.cluster.local
database.production.svc.cluster.local
```

### Environment Variables
```bash
# Kubernetes automatically creates environment variables
WEB_APP_CLUSTERIP_SERVICE_HOST=10.96.1.100
WEB_APP_CLUSTERIP_SERVICE_PORT=80
WEB_APP_CLUSTERIP_PORT_80_TCP=tcp://10.96.1.100:80
```

### Service Discovery Testing
```yaml
# test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test
    image: busybox
    command: ["sleep", "3600"]
```

```bash
# Test DNS resolution
kubectl exec test-pod -- nslookup web-app-clusterip
kubectl exec test-pod -- nslookup web-app-clusterip.default.svc.cluster.local

# Test connectivity
kubectl exec test-pod -- wget -qO- web-app-clusterip:80
kubectl exec test-pod -- telnet web-app-clusterip 80
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Service Not Accessible
```bash
# Check service exists
kubectl get service web-app-clusterip

# Check endpoints
kubectl get endpoints web-app-clusterip

# Check pod labels match service selector
kubectl get pods --show-labels
kubectl get service web-app-clusterip -o jsonpath='{.spec.selector}'
```

#### 2. No Endpoints
```bash
# Check if pods are running
kubectl get pods -l app=web-app

# Check pod labels
kubectl describe pod <pod-name> | grep Labels

# Check service selector
kubectl describe service web-app-clusterip | grep Selector
```

#### 3. LoadBalancer Pending
```bash
# Check cloud provider support
kubectl describe service web-app-loadbalancer

# Check events
kubectl get events --field-selector involvedObject.name=web-app-loadbalancer

# Check annotations
kubectl get service web-app-loadbalancer -o yaml | grep annotations -A 10
```

#### 4. Connection Refused
```bash
# Check target port
kubectl describe service web-app-clusterip | grep TargetPort

# Check pod port
kubectl describe pod <pod-name> | grep Port

# Test pod directly
kubectl exec -it <pod-name> -- netstat -tlnp
```

## 🛡️ Security Best Practices

### 1. Network Policies
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

### 2. Service Account
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: web-app-sa
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
    serviceAccount: web-app-sa
```

### 3. TLS/SSL Configuration
```yaml
apiVersion: v1
kind: Service
metadata:
  name: secure-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:region:account:certificate/cert-id"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "https"
spec:
  type: LoadBalancer
  ports:
  - port: 443
    targetPort: 8443
```

## 📊 Monitoring & Observability

### Service Metrics
```bash
# Service endpoints
kubectl get endpoints -o wide

# Service status
kubectl get service -o wide

# Network traffic (requires monitoring tools)
kubectl top pods --containers
```

### Health Checks
```yaml
# Service with health check annotations
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/health"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "5"
```

### Logging
```bash
# Service events
kubectl get events --field-selector involvedObject.name=web-app-service

# Load balancer logs (cloud provider specific)
# AWS: CloudWatch logs
# GCP: Cloud Logging
# Azure: Azure Monitor
```

## 🎯 Best Practices

### 1. **Naming Convention**
```yaml
metadata:
  name: <app-name>-<service-type>
  # Examples:
  # web-app-clusterip
  # api-gateway-loadbalancer
  # database-headless
```

### 2. **Labels & Selectors**
```yaml
metadata:
  labels:
    app: web-app
    component: backend
    version: v1.0.0
spec:
  selector:
    app: web-app
    component: backend
```

### 3. **Port Naming**
```yaml
ports:
- name: http      # Always name ports
  port: 80
- name: https
  port: 443
- name: metrics
  port: 9090
```

### 4. **Health Checks**
```yaml
# Configure proper health checks
annotations:
  service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/health"
  service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
```

## 📋 Practical Exercises

### Exercise 1: Basic Service Creation
```bash
# 1. Create deployment
kubectl create deployment nginx --image=nginx:1.21 --replicas=3

# 2. Expose as ClusterIP
kubectl expose deployment nginx --port=80 --target-port=80

# 3. Test service
kubectl run test-pod --image=busybox -it --rm -- wget -qO- nginx

# 4. Check endpoints
kubectl get endpoints nginx
```

### Exercise 2: Service Types
```bash
# 1. Create NodePort service
kubectl expose deployment nginx --type=NodePort --port=80

# 2. Get NodePort
kubectl get service nginx -o jsonpath='{.spec.ports[0].nodePort}'

# 3. Test external access
curl http://<node-ip>:<nodeport>

# 4. Convert to LoadBalancer
kubectl patch service nginx -p '{"spec":{"type":"LoadBalancer"}}'
```

### Exercise 3: Service Discovery
```bash
# 1. Create multiple services
kubectl create deployment web --image=nginx:1.21
kubectl create deployment api --image=nginx:1.21
kubectl expose deployment web --port=80
kubectl expose deployment api --port=80

# 2. Test DNS resolution
kubectl run test --image=busybox -it --rm -- nslookup web
kubectl run test --image=busybox -it --rm -- nslookup api

# 3. Test connectivity
kubectl run test --image=busybox -it --rm -- wget -qO- web
kubectl run test --image=busybox -it --rm -- wget -qO- api
```

## 🔗 Related Topics

- **[Deployments](../deployment/)** - Application management
- **[Ingress](../../../3-k8s-networking/02-ingress-ingressController/)** - HTTP/HTTPS routing
- **[Network Policies](../../../5-cluster-security/F-Network-policy/)** - Network security
- **[DNS](../../../3-k8s-networking/05-dns-coredns/)** - Service discovery

---

**Next:** [Namespaces](../namespace/) - Resource Organization & Isolation
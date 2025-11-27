# Multi-Tier Kubernetes Applications

Complete collection of tier-based applications demonstrating different architectural patterns in Kubernetes.

## 🏗️ Architecture Overview

### 1-Tier Application
**Static Blog App (HTML/CSS/JS)**
- Single container with Nginx
- Client-side JavaScript functionality
- Local storage for data persistence
- Perfect for static websites and SPAs

### 2-Tier Application  
**Python Full-Stack App (Flask)**
- Frontend: HTML templates served by Flask
- Backend: Python Flask with SQLite
- Single application handling both UI and API
- Session-based authentication

### 3-Tier Application
**E-commerce App (React + Node.js + MongoDB)**
- Frontend: React SPA with Material-UI
- Backend: Node.js Express API
- Database: MongoDB with Mongoose ODM
- JWT-based authentication

### 4-Tier Application
**Microservices (React + Spring Boot + PostgreSQL + Redis)**
- Frontend: React SPA
- API Gateway: Spring Boot Gateway
- Microservices: User, Product, Order services (Spring Boot)
- Database: PostgreSQL with separate schemas
- Cache: Redis for session and data caching

## 🚀 Quick Start

### Prerequisites
```bash
# Install required tools
kubectl version --client
docker --version
helm version

# Start local Kubernetes cluster
minikube start
# OR
kind create cluster
```

### Deploy Applications

#### 1-Tier Blog App
```bash
cd 1-tier
docker build -t blog-app:latest .
kubectl apply -f k8s-manifests/
kubectl port-forward svc/blog-app-service 8080:80
```

#### 2-Tier Python App
```bash
cd 2-tier/backend
docker build -t python-2tier-app:latest .
kubectl apply -f ../k8s-manifests/
kubectl port`-forward svc/python-2tier-service 8080:80
```

#### 3-Tier E-commerce App
```bash
# Build and deploy backend
cd 3-tier/backend
docker build -t nodejs-backend:latest .

# Build and deploy frontend
cd ../frontend
docker build -t react-frontend:latest .

# Deploy all components
kubectl apply -f ../k8s-manifests/
```

#### 4-Tier Microservices
```bash
# Build all services
cd 4-tier
docker build -t user-service:latest ./user-service/
docker build -t product-service:latest ./product-service/
docker build -t order-service:latest ./order-service/
docker build -t api-gateway:latest ./api-gateway/
docker build -t frontend-app:latest ./frontend/

# Deploy complete stack
kubectl apply -f k8s-manifests/
kubectl apply -f cache/
```

## 🔍 Monitoring & Observability

### Install Monitoring Stack
```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus + Grafana
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

# Install Jaeger for tracing
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.45.0/jaeger-operator.yaml
```

### Access Monitoring Tools
```bash
# Grafana (admin/prom-operator)
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Jaeger
kubectl port-forward -n observability svc/jaeger-query 16686:16686
```

## 🔄 GitOps with ArgoCD

### Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose ArgoCD UI
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Deploy Applications via GitOps
```bash
# Apply ArgoCD applications
kubectl apply -f gitops/argocd-applications.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## 📊 Application Features

### 1-Tier Blog App
- ✅ Responsive design
- ✅ Local storage persistence
- ✅ Search and filtering
- ✅ CRUD operations
- ✅ Export/Import functionality

### 2-Tier Python App
- ✅ User authentication
- ✅ Blog post management
- ✅ Comment system
- ✅ Real-time statistics
- ✅ Session management

### 3-Tier E-commerce App
- ✅ Product catalog
- ✅ Shopping cart
- ✅ Order management
- ✅ User profiles
- ✅ JWT authentication
- ✅ Real-time updates

### 4-Tier Microservices
- ✅ API Gateway pattern
- ✅ Service discovery
- ✅ Circuit breakers
- ✅ Distributed tracing
- ✅ Redis caching
- ✅ Database per service
- ✅ Event-driven architecture

## 🛡️ Security Features

### Network Security
- Network policies for pod-to-pod communication
- Ingress controllers with TLS termination
- Service mesh integration ready

### Application Security
- Non-root containers
- Read-only root filesystems
- Security contexts and capabilities
- Secret management
- RBAC configurations

### Data Security
- Encrypted secrets
- Database connection security
- Redis AUTH (when configured)
- Input validation and sanitization

## 📈 Performance & Scaling

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Resource Optimization
- Proper resource requests and limits
- Quality of Service classes
- Node affinity and anti-affinity
- Pod disruption budgets

## 🔧 Development Workflow

### Local Development
```bash
# Start development environment
docker-compose up -d

# Run tests
npm test  # For Node.js/React apps
mvn test  # For Spring Boot apps
python -m pytest  # For Python apps

# Build and push images
docker build -t your-registry/app:tag .
docker push your-registry/app:tag
```

### CI/CD Pipeline
1. **Code Commit** → Git repository
2. **Build** → Docker images
3. **Test** → Unit and integration tests
4. **Security Scan** → Container vulnerability scanning
5. **Deploy** → ArgoCD sync
6. **Monitor** → Prometheus/Grafana alerts

## 🚨 Troubleshooting

### Common Issues

#### Pod Startup Issues
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> -f
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Service Discovery Issues
```bash
kubectl get endpoints
kubectl run debug --image=busybox --rm -it --restart=Never -- nslookup <service-name>
```

#### Database Connection Issues
```bash
kubectl exec -it <db-pod> -- psql -U <username> -d <database>
kubectl port-forward <db-pod> 5432:5432
```

### Performance Debugging
```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Check HPA status
kubectl get hpa
kubectl describe hpa <hpa-name>
```

## 📚 Learning Resources

### Kubernetes Concepts Covered
- Deployments and Services
- ConfigMaps and Secrets
- Persistent Volumes and Claims
- Ingress and Network Policies
- Horizontal Pod Autoscaling
- Resource Management
- Health Checks and Probes

### Architecture Patterns
- Monolithic (1-tier)
- Client-Server (2-tier)
- Three-tier architecture
- Microservices (4-tier)
- API Gateway pattern
- Database per service
- Caching strategies

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Next Steps

- [ ] Add Istio service mesh
- [ ] Implement distributed tracing
- [ ] Add chaos engineering tests
- [ ] Create Helm charts
- [ ] Add automated testing pipeline
- [ ] Implement blue-green deployments
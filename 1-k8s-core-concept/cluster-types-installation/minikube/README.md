# Minikube - Local Kubernetes Development

## 🎯 Learning Objectives
- Set up local Kubernetes development environment
- Master Minikube commands and configuration
- Understand different drivers and their use cases
- Practice cluster management and troubleshooting
- Deploy and test applications locally

---

## 📖 What is Minikube?

Minikube is a tool that runs a single-node Kubernetes cluster locally for development and testing purposes.

### **Key Features:**
- **Single-node cluster** - Master and worker on same machine
- **Multiple drivers** - Docker, VirtualBox, VMware, etc.
- **Add-ons support** - Dashboard, ingress, metrics-server
- **Cross-platform** - Windows, macOS, Linux
- **Resource control** - CPU, memory, disk configuration

---

## 🚀 Installation Guide

### **macOS Installation:**
```bash
# Using Homebrew (Recommended)
brew install minikube

# Using curl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube

# Verify installation
minikube version
```

### **Linux Installation:**
```bash
# Using curl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Using package manager (Ubuntu/Debian)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install minikube
```

### **Windows Installation:**
```powershell
# Using Chocolatey
choco install minikube

# Using Scoop
scoop install minikube

# Manual download
# Download from: https://github.com/kubernetes/minikube/releases
```

---

## 🔧 Driver Configuration

### **Docker Driver (Recommended):**
```bash
# Start with Docker driver
minikube start --driver=docker

# Set Docker as default driver
minikube config set driver docker

# Verify driver
minikube config view
```

### **VirtualBox Driver:**
```bash
# Install VirtualBox first
# macOS: brew install --cask virtualbox
# Linux: sudo apt install virtualbox

# Start with VirtualBox
minikube start --driver=virtualbox --memory=4096 --cpus=2
```

### **VMware Driver:**
```bash
# Install VMware Fusion (macOS) or Workstation (Linux/Windows)
# Install docker-machine-driver-vmware

# Start with VMware
minikube start --driver=vmware
```

### **Hyperkit Driver (macOS only):**
```bash
# Install hyperkit
brew install hyperkit

# Start with hyperkit
minikube start --driver=hyperkit
```

---

## 🎮 Basic Minikube Commands

### **Cluster Management:**
```bash
# Start cluster
minikube start

# Start with specific configuration
minikube start --cpus=4 --memory=8192 --disk-size=50g --kubernetes-version=v1.28.0

# Check status
minikube status

# Stop cluster
minikube stop

# Delete cluster
minikube delete

# Pause cluster (save resources)
minikube pause

# Unpause cluster
minikube unpause
```

### **Cluster Information:**
```bash
# Get cluster info
minikube ip
minikube ssh
minikube logs

# Check resource usage
minikube ssh -- top
minikube ssh -- df -h

# View cluster configuration
kubectl cluster-info
kubectl get nodes -o wide
```

---

## 🔌 Add-ons Management

### **Available Add-ons:**
```bash
# List all add-ons
minikube addons list

# Enable popular add-ons
minikube addons enable dashboard
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable registry
minikube addons enable storage-provisioner

# Disable add-on
minikube addons disable dashboard

# Check add-on status
minikube addons list | grep enabled
```

### **Dashboard Access:**
```bash
# Enable and access dashboard
minikube addons enable dashboard
minikube dashboard

# Get dashboard URL
minikube dashboard --url

# Access in background
minikube dashboard &
```

---

## 🌐 Networking & Services

### **Service Access:**
```bash
# Expose service via NodePort
kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello-minikube --type=NodePort --port=8080

# Get service URL
minikube service hello-minikube --url

# Open service in browser
minikube service hello-minikube

# List all services
minikube service list
```

### **Ingress Configuration:**
```bash
# Enable ingress add-on
minikube addons enable ingress

# Create ingress resource
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
spec:
  rules:
  - host: hello-world.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-minikube
            port:
              number: 8080
EOF

# Add to /etc/hosts
echo "$(minikube ip) hello-world.local" | sudo tee -a /etc/hosts

# Test ingress
curl http://hello-world.local
```

### **LoadBalancer Services:**
```bash
# Create LoadBalancer service
kubectl expose deployment hello-minikube --type=LoadBalancer --port=8080

# Access via tunnel (required for LoadBalancer)
minikube tunnel

# In another terminal, get external IP
kubectl get services
```

---

## 💾 Storage & Volumes

### **Persistent Volumes:**
```bash
# Create PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Use PVC in pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: myfrontend
    image: nginx
    volumeMounts:
    - mountPath: "/var/www/html"
      name: mypd
  volumes:
  - name: mypd
    persistentVolumeClaim:
      claimName: myclaim
EOF
```

### **Host Path Volumes:**
```bash
# Mount host directory
minikube mount /host/path:/minikube/path &

# Use in pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: host-volume
  volumes:
  - name: host-volume
    hostPath:
      path: /minikube/path
      type: Directory
EOF
```

---

## 🐳 Docker Integration

### **Using Minikube's Docker Daemon:**
```bash
# Configure shell to use minikube's docker
eval $(minikube docker-env)

# Build image directly in minikube
docker build -t my-app:local .

# Use local image in pod (set imagePullPolicy: Never)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: local-image-pod
spec:
  containers:
  - name: my-app
    image: my-app:local
    imagePullPolicy: Never
EOF

# Reset to host docker
eval $(minikube docker-env -u)
```

### **Registry Add-on:**
```bash
# Enable registry
minikube addons enable registry

# Get registry endpoint
kubectl get service -n kube-system registry

# Push image to registry
docker tag my-app:local localhost:5000/my-app:latest
docker push localhost:5000/my-app:latest
```

---

## 🛠️ Hands-on Labs

### **Lab 1: Complete Application Deployment**
```bash
# 1. Start minikube with specific resources
minikube start --cpus=2 --memory=4096 --disk-size=20g

# 2. Enable required add-ons
minikube addons enable dashboard
minikube addons enable ingress
minikube addons enable metrics-server

# 3. Deploy application
kubectl create deployment webapp --image=nginx --replicas=3

# 4. Create service
kubectl expose deployment webapp --type=NodePort --port=80

# 5. Access application
minikube service webapp --url

# 6. Scale application
kubectl scale deployment webapp --replicas=5

# 7. Check in dashboard
minikube dashboard
```

### **Lab 2: Multi-Service Application**
```bash
# Deploy frontend and backend
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: redis
        image: redis
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 6379
    targetPort: 6379
EOF

# Test connectivity
kubectl run test-pod --image=busybox -it --rm -- nslookup backend-service
```

### **Lab 3: Persistent Storage**
```bash
# Create storage class (already exists in minikube)
kubectl get storageclass

# Create PVC and pod with persistent storage
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-app
  template:
    metadata:
      labels:
        app: data-app
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: data-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: data-pvc
EOF

# Test persistence
kubectl exec -it deployment/data-app -- bash -c "echo 'Hello Persistent World' > /usr/share/nginx/html/index.html"
kubectl delete pod -l app=data-app
kubectl get pods -l app=data-app -w
# Verify data persists after pod recreation
```

---

## 🔍 Troubleshooting Guide

### **Common Issues:**

#### **Minikube Won't Start:**
```bash
# Check system resources
minikube start --alsologtostderr -v=1

# Clear minikube state
minikube delete
minikube start

# Check driver issues
minikube start --driver=docker --alsologtostderr -v=1

# Verify prerequisites
docker --version
kubectl version --client
```

#### **Resource Issues:**
```bash
# Check resource usage
minikube ssh -- free -h
minikube ssh -- df -h

# Increase resources
minikube stop
minikube start --cpus=4 --memory=8192

# Clean up unused resources
minikube ssh -- docker system prune -f
```

#### **Network Problems:**
```bash
# Check minikube IP
minikube ip
ping $(minikube ip)

# Restart networking
minikube stop
minikube start

# Check service endpoints
kubectl get endpoints
minikube service list
```

#### **Add-on Issues:**
```bash
# Check add-on status
minikube addons list
kubectl get pods -n kube-system

# Restart add-on
minikube addons disable dashboard
minikube addons enable dashboard

# Check add-on logs
kubectl logs -n kube-system -l k8s-app=kubernetes-dashboard
```

---

## ⚡ Performance Optimization

### **Resource Allocation:**
```bash
# Optimal settings for development
minikube start \
  --cpus=4 \
  --memory=8192 \
  --disk-size=50g \
  --driver=docker

# For CI/CD environments
minikube start \
  --cpus=2 \
  --memory=4096 \
  --disk-size=20g \
  --driver=docker \
  --no-vtx-check
```

### **Caching & Performance:**
```bash
# Enable image caching
minikube cache add nginx:latest
minikube cache add redis:latest

# List cached images
minikube cache list

# Preload images
minikube image load my-app:latest
```

---

## 🎯 Best Practices

### **Development Workflow:**
1. **Start with adequate resources** - Don't starve your cluster
2. **Use add-ons wisely** - Only enable what you need
3. **Leverage docker-env** - Build images directly in minikube
4. **Regular cleanup** - Delete unused resources
5. **Version consistency** - Match production Kubernetes version

### **Configuration Management:**
```bash
# Set default configuration
minikube config set cpus 4
minikube config set memory 8192
minikube config set driver docker

# View configuration
minikube config view

# Profile management
minikube start -p dev-cluster
minikube start -p test-cluster
minikube profile list
```

---

## 🎯 Assessment Checklist

### **Skills to Master:**
- [ ] Install and configure Minikube
- [ ] Start/stop clusters with custom resources
- [ ] Enable and use add-ons effectively
- [ ] Deploy multi-service applications
- [ ] Configure networking and ingress
- [ ] Manage persistent storage
- [ ] Troubleshoot common issues
- [ ] Optimize performance for development

---

## 🔗 Additional Resources

### **Documentation:**
- [Minikube Official Docs](https://minikube.sigs.k8s.io/docs/)
- [Minikube GitHub](https://github.com/kubernetes/minikube)

### **Alternatives:**
- [Kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
- [MicroK8s](https://microk8s.io/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)

### **Tools:**
- [k9s - Terminal UI](https://k9scli.io/)
- [Lens - Kubernetes IDE](https://k8slens.dev/)
- [kubectl plugins](https://krew.sigs.k8s.io/)

---

**Next:** [EKS Cluster Setup](../EKS-cluster-setup-script/README.md)
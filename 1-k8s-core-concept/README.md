# Kubernetes Core Concepts - Complete Guide

## 📖 Overview
This module covers the fundamental concepts of Kubernetes that every practitioner must understand. From basic container orchestration to advanced cluster architecture.

---

## 🎯 Learning Objectives
By the end of this module, you will:
- Understand what Kubernetes is and why it's needed
- Know the complete Kubernetes architecture
- Set up and manage Kubernetes clusters
- Use kubectl effectively for cluster management
- Deploy and manage basic applications

---

## 📚 Module Structure

### **1. Introduction & History** (`1.k8s-intro-history/`)
**Duration:** 2-3 days

#### What You'll Learn:
- **Container Orchestration Need**
  - Problems with manual container management
  - Scaling challenges in containerized environments
  - Service discovery and load balancing issues

- **Kubernetes Evolution**
  - Google's Borg system heritage
  - Open-source journey and CNCF adoption
  - Current ecosystem and community

- **Core Benefits**
  - Automated deployment and scaling
  - Self-healing capabilities
  - Service discovery and load balancing
  - Storage orchestration
  - Secret and configuration management

#### Hands-on Labs:
```bash
# Lab 1: Compare Docker vs Kubernetes deployment
docker run -d nginx
kubectl create deployment nginx --image=nginx

# Lab 2: Explore Kubernetes ecosystem
kubectl version
kubectl cluster-info
```

---

### **2. Kubernetes Architecture** (`2.k8s-architecture/`)
**Duration:** 4-5 days

#### Master Node Components:
- **API Server (kube-apiserver)**
  - Central management entity
  - RESTful API for all operations
  - Authentication and authorization

- **etcd**
  - Distributed key-value store
  - Cluster state and configuration data
  - Backup and recovery strategies

- **Controller Manager (kube-controller-manager)**
  - Node Controller
  - Replication Controller
  - Endpoints Controller
  - Service Account & Token Controllers

- **Scheduler (kube-scheduler)**
  - Pod placement decisions
  - Resource requirements and constraints
  - Affinity and anti-affinity rules

#### Worker Node Components:
- **kubelet**
  - Node agent communication with API server
  - Pod lifecycle management
  - Container runtime interface (CRI)

- **kube-proxy**
  - Network proxy and load balancer
  - Service abstraction implementation
  - iptables/IPVS rules management

- **Container Runtime**
  - Docker, containerd, CRI-O
  - Container lifecycle management
  - Image pulling and storage

#### Hands-on Labs:
```bash
# Lab 1: Explore cluster components
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl describe node <node-name>

# Lab 2: Check component health
kubectl get componentstatuses
kubectl logs -n kube-system kube-apiserver-<master-node>
```

---

### **3. Cluster Setup Options** (`minikube/`, `EKS-cluster-setup-script/`, `terraform-code/`)

#### **Local Development Setup** (`minikube/`)
**Duration:** 1-2 days

##### Minikube Installation & Configuration:
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube

# Start cluster
minikube start --driver=docker --cpus=2 --memory=4g
minikube status
minikube dashboard
```

##### Alternative Local Options:
- **Kind (Kubernetes in Docker)**
- **Docker Desktop Kubernetes**
- **MicroK8s**

#### **Cloud Setup - AWS EKS** (`EKS-cluster-setup-script/`)
**Duration:** 2-3 days

##### Prerequisites:
- AWS CLI configured
- eksctl installed
- kubectl installed

##### Quick EKS Setup:
```bash
# Create EKS cluster
eksctl create cluster \
  --name my-cluster \
  --version 1.28 \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name my-cluster
```

#### **Infrastructure as Code** (`terraform-code/`)
**Duration:** 2-3 days

##### Terraform Modules Structure:
```
terraform-code/
├── modules/
│   ├── vpc/          # VPC, subnets, security groups
│   ├── eks/          # EKS cluster configuration
│   ├── iam/          # IAM roles and policies
│   └── s3-bucket-db/ # S3 backend for state
└── script/           # Deployment scripts
```

##### Sample Terraform Usage:
```hcl
module "vpc" {
  source = "./modules/vpc"
  cluster_name = "my-eks-cluster"
}

module "eks" {
  source = "./modules/eks"
  cluster_name = "my-eks-cluster"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}
```

---

## 🛠️ kubectl Fundamentals

### **Essential Commands:**
```bash
# Cluster Information
kubectl cluster-info
kubectl get nodes
kubectl describe node <node-name>

# Resource Management
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get all

# Creating Resources
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl scale deployment nginx --replicas=3

# Debugging
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Configuration
kubectl config view
kubectl config current-context
kubectl config use-context <context-name>
```

### **YAML Manifests:**
```yaml
# Basic Pod Definition
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.20
    ports:
    - containerPort: 80
```

---

## 🧪 Practical Exercises

### **Exercise 1: First Application Deployment**
```bash
# 1. Create a deployment
kubectl create deployment hello-world --image=nginx

# 2. Scale the deployment
kubectl scale deployment hello-world --replicas=3

# 3. Expose the service
kubectl expose deployment hello-world --port=80 --type=NodePort

# 4. Access the application
minikube service hello-world --url
```

### **Exercise 2: Multi-Container Pod**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: web-server
    image: nginx
    ports:
    - containerPort: 80
  - name: log-agent
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Logging..."; sleep 30; done']
```

### **Exercise 3: Cluster Exploration**
```bash
# Explore cluster resources
kubectl get all --all-namespaces
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl top nodes
kubectl top pods
```

---

## 🔍 Troubleshooting Guide

### **Common Issues & Solutions:**

#### **Pod Not Starting:**
```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Common causes:
# - Image pull errors
# - Resource constraints
# - Configuration issues
```

#### **Service Not Accessible:**
```bash
# Check service configuration
kubectl get services
kubectl describe service <service-name>
kubectl get endpoints <service-name>

# Test connectivity
kubectl run test-pod --image=busybox -it --rm -- wget -qO- <service-name>
```

#### **Node Issues:**
```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>
kubectl get events --field-selector involvedObject.name=<node-name>
```

---

## 📝 Best Practices

### **Resource Management:**
- Always specify resource requests and limits
- Use namespaces for environment separation
- Implement proper labeling strategy
- Regular cluster maintenance and updates

### **Security:**
- Use non-root containers when possible
- Implement RBAC from the beginning
- Regular security scanning of images
- Network policies for traffic control

### **Monitoring:**
- Set up cluster monitoring early
- Monitor resource usage patterns
- Implement logging strategy
- Regular backup of etcd data

---

## 🎯 Assessment Checklist

### **Knowledge Check:**
- [ ] Explain Kubernetes architecture components
- [ ] Demonstrate kubectl basic operations
- [ ] Deploy applications using YAML manifests
- [ ] Troubleshoot common pod issues
- [ ] Set up local development environment

### **Practical Skills:**
- [ ] Create and manage deployments
- [ ] Scale applications up and down
- [ ] Access application logs and metrics
- [ ] Configure services for application access
- [ ] Use kubectl for cluster administration

---

## 🔗 Additional Resources

### **Official Documentation:**
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

### **Interactive Learning:**
- [Kubernetes Playground](https://labs.play-with-k8s.com/)
- [Katacoda Kubernetes Scenarios](https://katacoda.com/courses/kubernetes)

### **Tools & Utilities:**
- [k9s - Terminal UI](https://k9scli.io/)
- [Lens - Kubernetes IDE](https://k8slens.dev/)
- [Helm - Package Manager](https://helm.sh/)

---

## 📈 Next Steps
After completing this module, proceed to:
1. **Module 2:** Kubernetes Objects & Workloads
2. Practice deploying real applications
3. Explore advanced kubectl features
4. Set up monitoring and logging

**Estimated Completion Time:** 2-3 weeks
**Prerequisites for Next Module:** Comfortable with kubectl, basic pod/deployment management
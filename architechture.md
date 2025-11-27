# Kubernetes Learning Architecture

## 📁 Directory Structure Overview

### 🏗️ **0-cluster-setup** - Infrastructure Foundation
- **EKS-cluster-setup-script/**: AWS EKS cluster automation
- **minikube/**: Local development environment
- **terraform-code/**: Infrastructure as Code
  - **modules/**: Reusable Terraform modules (eks, iam, s3-bucket-db, vpc)
  - **script/**: Deployment automation scripts

### 📚 **09-k8s-reference** - Knowledge Base
- **k8s-commands/**: Complete command reference (13 command files)
- **k8s-yaml-templates/**: Production-ready YAML templates (25 templates)
- **k8s-concepts-terms.txt**: Terminology and concepts
- **README.md**: Reference documentation

### 🎯 **1-k8s-objects** - Core Workloads
- **Workload Types**: pod, deployment, replicaset, statefulset, daemonset
- **Job Management**: jobs, cronjobs
- **Service Discovery**: services
- **Documentation**: workloads-documentation.md

### 💾 **2-storage** - Data Persistence
- **01-volumes/**: Basic volume types (configmap, secret, emptydir, hostpath)
- **02-persistent-volumes/**: Persistent storage (pv, pvc)
- **03-storage-classes/**: Dynamic provisioning
- **04-examples/**: Real-world storage scenarios

### 🌐 **3-k8s-networking** - Network Architecture
- **01-services/**: Service types (ClusterIP, NodePort, LoadBalancer, ExternalName)
- **02-ingress/**: HTTP/HTTPS routing (basic, advanced, TLS)
- **03-load-balancers/**: Cloud load balancers (AWS ALB/NLB)
- **04-network-policies/**: Security policies
- **05-dns/**: DNS configuration
- **06-namespaces/**: Environment isolation
- **07-examples/**: Complete networking scenarios

### 🚀 **4-deployment-strategy** - Release Management
- **Deployment Patterns**: rolling-update, blue-green, canary, recreate
- **Advanced Strategies**: a-b-testing, feature-toggle, shadow, ramped-slow-rollout

### 🔒 **5-k8s-security** - Security Framework
- **Secret Management**: secret.yml, vault.yml
- **Configuration**: configmap.yml
- **Documentation**: security best practices

### 👥 **6-cluster-management** - Access Control
- **RBAC**: Role-Based Access Control
- **Autoscaling**: Horizontal/Vertical Pod Autoscaling
- **Service Accounts**: Identity management
- **Cluster/Namespace Roles**: Permission management

### ⚡ **7-k8s-advanced** - Advanced Features
- **Scheduling**: affinity, taint, tolerations
- **Resource Management**: requests, limits
- **Health Checks**: liveness, readiness probes

### 🔧 **8-k8s-troubleshooting** - Problem Resolution
- **Networking**: Network troubleshooting guides
- **Security**: Security issue resolution
- **Storage**: Storage problem diagnosis
- **Workloads**: Application troubleshooting

### 📦 **10-helm** - Package Management
- **Application Deployment**: Multi-environment Helm charts
- **Security Tools**: SonarQube, Trivy, Vault configurations
- **Documentation**: Helm best practices

### 🏢 **11-k8s-project** - Real-World Applications
- **Multi-Tier Applications**: 1-tier, 2-tier, 3-tier, 4-tier architectures
- **Microservices**: Complete microservice deployments
- **GitOps**: ArgoCD application configurations
- **Retail Store**: Full-featured sample application

### 🔄 **12-ARGOCD** - GitOps & CI/CD
- **GitOps Fundamentals**: Introduction and basics
- **Setup & Installation**: ArgoCD deployment
- **Application Management**: CLI, UI, and declarative approaches
- **Advanced Features**: App of Apps, ApplicationSets, multi-cluster
- **Integrations**: Notifications, image updater, monitoring
- **Security & Scaling**: RBAC, SSO, high availability
- **Argo Ecosystem**: Rollouts, Workflows, Events
- **Production**: Real-world projects and use cases

### 📊 **13-monitoring-stack** - Observability Platform
- **01-grafana/**: Visualization & dashboards (v10.1.4, App: 12.2.1)
- **02-mimir/**: Long-term metrics storage (v6.0.3, App: 3.0.0)
- **03-tempo/**: Distributed tracing (v1.56.0, App: 2.9.0)
- **04-loki/**: Log aggregation (v6.46.0, App: 3.5.7)
- **05-alloy/**: Telemetry collection (v3.5.6, App: 1.5.0)
- **06-prometheus/**: Metrics collection (v27.45.0, App: v3.7.3)
- **08-dashboards/**: Pre-built dashboards (Application, DevOps, Database, etc.)
- **alertmanager/**: Alert management
- **alerts/**: Alert rules and configurations

## 🎯 Learning Path Architecture

### **Phase 1: Foundation** (0, 09, 1)
1. **Cluster Setup**: Infrastructure provisioning
2. **Reference Materials**: Commands and templates
3. **Core Objects**: Basic workload understanding

### **Phase 2: Core Concepts** (2, 3, 5)
1. **Storage**: Data persistence patterns
2. **Networking**: Service discovery and routing
3. **Security**: Access control and secrets

### **Phase 3: Operations** (4, 6, 7, 8)
1. **Deployment Strategies**: Release management
2. **Cluster Management**: RBAC and scaling
3. **Advanced Features**: Scheduling and resources
4. **Troubleshooting**: Problem resolution

### **Phase 4: Production** (10, 11, 12, 13)
1. **Package Management**: Helm charts
2. **Real Applications**: Multi-tier projects
3. **GitOps**: ArgoCD and CI/CD
4. **Observability**: Complete monitoring stack

## 📈 Complexity Progression

```
Basic → Intermediate → Advanced → Production
  ↓         ↓           ↓           ↓
1-3       4-8         9-10       11-13
```

## 🛠️ Technology Stack

### **Container Orchestration**
- Kubernetes (Core platform)
- Docker (Container runtime)

### **Infrastructure**
- AWS EKS (Managed Kubernetes)
- Terraform (Infrastructure as Code)
- Minikube (Local development)

### **Package Management**
- Helm (Application packaging)
- Kustomize (Configuration management)

### **GitOps & CI/CD**
- ArgoCD (GitOps operator)
- Argo Rollouts (Progressive delivery)
- Argo Workflows (Workflow engine)
- Argo Events (Event-driven automation)

### **Observability Stack**
- Grafana (Visualization)
- Mimir (Metrics storage)
- Loki (Log aggregation)
- Tempo (Distributed tracing)
- Alloy (Telemetry collection)
- Prometheus (Metrics collection)

### **Security Tools**
- Vault (Secret management)
- Trivy (Vulnerability scanning)
- SonarQube (Code quality)

## 📊 Component Statistics

- **Total Directories**: 14 main sections
- **YAML Templates**: 25+ production-ready templates
- **Command References**: 13 comprehensive command files
- **Deployment Strategies**: 8 different patterns
- **Monitoring Components**: 6 observability tools
- **ArgoCD Modules**: 14 comprehensive sections
- **Project Examples**: 4-tier application architectures
- **Troubleshooting Guides**: 4 specialized areas

## 🎯 Key Learning Outcomes

### **Infrastructure Skills**
- Kubernetes cluster setup and management
- Infrastructure as Code with Terraform
- Multi-environment deployment strategies

### **Application Development**
- Containerized application deployment
- Microservices architecture patterns
- Multi-tier application design

### **DevOps Practices**
- GitOps implementation with ArgoCD
- CI/CD pipeline automation
- Progressive delivery strategies

### **Observability & Monitoring**
- Complete observability stack setup
- Metrics, logs, and traces correlation
- Alert management and dashboards

### **Security & Compliance**
- RBAC implementation
- Secret management
- Security scanning and compliance

This architecture provides a comprehensive learning path from basic Kubernetes concepts to production-ready implementations with modern DevOps practices.
# Kubernetes Reference Materials

## 📚 Contents

### k8s-commands/
Complete kubectl command reference organized by resource type:
- Pod commands
- Deployment commands  
- Service commands
- Storage commands
- RBAC commands
- Networking commands
- General commands

### k8s-yaml-templates/
Production-ready YAML templates for all Kubernetes objects:
- Basic objects (Pod, Deployment, Service)
- Storage (PV, PVC, StorageClass)
- Networking (Ingress, NetworkPolicy)
- Security (RBAC, ServiceAccount)
- Autoscaling (HPA, VPA)

### k8s-concepts-terms.txt
Comprehensive guide covering 75+ Kubernetes concepts:
- Basic concepts (Labels, Selectors, Annotations)
- Pod lifecycle and management
- Scheduling and placement
- Resource management
- Storage concepts
- Networking
- Security
- Advanced topics

## 🚀 Quick Access

### Most Used Commands
```bash
# Get resources
kubectl get pods
kubectl get services
kubectl get deployments

# Describe resources
kubectl describe pod <pod-name>
kubectl describe service <service-name>

# Apply manifests
kubectl apply -f <file.yaml>

# Port forwarding
kubectl port-forward <pod-name> 8080:80

# Logs
kubectl logs <pod-name> -f
```

### Template Usage
```bash
# Copy template
cp k8s-yaml-templates/deployment.yaml my-app-deployment.yaml

# Edit as needed
vim my-app-deployment.yaml

# Apply
kubectl apply -f my-app-deployment.yaml
```

This reference section provides quick access to all essential Kubernetes commands, templates, and concepts!
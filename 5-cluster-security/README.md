# Kubernetes Cluster Security

## 📚 Overview
Kubernetes cluster security ke comprehensive topics. Production-grade security implementations, authentication, authorization, admission control, network policies aur custom controllers.

## 📖 Topics

### [A. Cluster Maintenance](./A-Cluster-maintanance/)
- Cluster upgrades aur version management
- Node maintenance procedures
- Backup & restore strategies
- Security patching
- Monitoring & alerting

### [B. Authentication](./B-Authentication/)
- Certificate management
- Service accounts
- OIDC integration
- Kubeconfig management
- Token request API

### [C. RBAC (Role-Based Access Control)](./C-RBAC/)
- Roles & ClusterRoles
- RoleBindings & ClusterRoleBindings
- Least privilege access
- Access reviews

### [D. Admission Control](./D-Admission-Control/)
- Pod Security Standards (PSS)
- Pod Security Admission (PSA)
- OPA Gatekeeper
- Kyverno policies
- Custom webhooks

### [F. Network Policy](./F-Network-policy/)
- Default network policies
- Application-specific policies
- Micro-segmentation

### [G. Custom Resource Definitions](./G-CRDs/)
- CRD creation aur management
- API extensions
- Validation schemas

### [H. Custom Controllers & Operators](./H-Customcontroller-operation-frame-works/)
- Controller patterns
- Operator frameworks
- Custom resource management

## 🚀 Quick Start
```bash
# Check cluster security status
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get networkpolicies --all-namespaces
```
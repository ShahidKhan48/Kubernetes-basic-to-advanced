# Lesson 3: Kubernetes Networking

## 📚 Overview
Kubernetes Networking complete guide - services, ingress, DNS, network policies aur advanced networking concepts. Production-ready networking solutions ke saath.

## 🎯 What You'll Learn
- Service types aur networking patterns
- Ingress controllers aur HTTP routing
- DNS resolution aur service discovery
- Network security aur policies
- Advanced networking concepts

## 📖 Networking Components

### 1. [Services](./01-services/) 🌐
**Network access aur load balancing**

**Service Types:**
- **ClusterIP** - Internal cluster access
- **NodePort** - External access via nodes
- **LoadBalancer** - Cloud load balancer
- **ExternalName** - DNS mapping
- **Headless** - Direct pod access

### 2. [Ingress & Controllers](./02-ingress-ingressController/) 🚪
**HTTP/HTTPS routing aur SSL termination**

**Controllers:**
- **NGINX Ingress** - Most popular
- **HAProxy Ingress** - High performance
- **APISIX Controller** - API Gateway features

### 3. [DNS & CoreDNS](./05-dns-coredns/) 🔍
**Service discovery aur name resolution**

**Features:**
- Automatic service DNS
- Custom DNS entries
- External DNS integration
- DNS policies

### 4. [Namespaces](./06-namespaces/) 📁
**Network isolation aur multi-tenancy**

**Use Cases:**
- Environment separation
- Team isolation
- Resource organization

### 5. [Network Policies](./07-network-policies/) 🛡️
**Traffic control aur security**

**Policy Types:**
- Ingress policies
- Egress policies
- Pod-to-pod communication
- Namespace isolation

## 🔧 Quick Commands

### Service Management
```bash
# List services
kubectl get services

# Expose deployment
kubectl expose deployment app --port=80 --type=LoadBalancer

# Port forward
kubectl port-forward service/app 8080:80
```

### Ingress Management
```bash
# List ingress
kubectl get ingress

# Describe ingress
kubectl describe ingress app-ingress
```

### Network Troubleshooting
```bash
# Test connectivity
kubectl run test --image=busybox -it --rm -- nslookup service-name

# Check endpoints
kubectl get endpoints

# Network policies
kubectl get networkpolicies
```

## 🎯 Learning Path

### Week 1: Fundamentals
1. **Services** - All service types
2. **Basic Ingress** - HTTP routing
3. **DNS** - Service discovery

### Week 2: Advanced
1. **Network Policies** - Security
2. **Advanced Ingress** - SSL, authentication
3. **Multi-cluster** - Cross-cluster networking

## 🔗 Quick Navigation

| Component | Complexity | Use Case | Production Ready |
|-----------|------------|----------|------------------|
| [Services](./01-services/) | ⭐⭐ | Basic networking | ✅ |
| [Ingress](./02-ingress-ingressController/) | ⭐⭐⭐ | HTTP routing | ✅ |
| [DNS](./05-dns-coredns/) | ⭐⭐ | Service discovery | ✅ |
| [Namespaces](./06-namespaces/) | ⭐ | Organization | ✅ |
| [Network Policies](./07-network-policies/) | ⭐⭐⭐⭐ | Security | ✅ |

---

**Next:** [Services](./01-services/) - Network Access & Load Balancing
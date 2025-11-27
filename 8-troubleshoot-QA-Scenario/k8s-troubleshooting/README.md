# Kubernetes Troubleshooting Guide

## 🔧 Overview
Comprehensive troubleshooting guides, tools, and scripts for diagnosing and resolving Kubernetes issues across all components and layers.

## 📁 Directory Structure

### **01-pod-issues/** - Pod Troubleshooting
- **pod-troubleshooting.md**: Pod lifecycle issues, container problems, resource constraints, and debugging techniques

### **02-networking/** - Network Troubleshooting
- **network-troubleshooting.md**: Service discovery, connectivity issues, CNI problems, ingress, and load balancer troubleshooting

### **03-storage/** - Storage Troubleshooting
- **storage-troubleshooting.md**: PVC issues, volume mounting, CSI drivers, StatefulSet storage, and performance problems

### **04-cluster-issues/** - Cluster-Level Troubleshooting
- **cluster-troubleshooting.md**: Node issues, control plane problems, etcd, authentication, and cluster upgrades

### **05-performance/** - Performance Troubleshooting
- **performance-troubleshooting.md**: Application performance, resource optimization, scaling issues, and monitoring

### **06-security/** - Security Troubleshooting
- **security-troubleshooting.md**: RBAC issues, pod security, network policies, certificates, and admission controllers

### **07-monitoring/** - Monitoring Stack Troubleshooting
- **monitoring-troubleshooting.md**: Prometheus, Grafana, Alertmanager, metrics collection, and observability issues

### **08-tools-scripts/** - Troubleshooting Tools & Scripts
- **troubleshooting-tools.yml**: Debug pods, monitoring jobs, and utility containers
- **troubleshooting-scripts.sh**: Automated troubleshooting scripts and health checks

## 🚨 Common Issues Quick Reference

### Pod Issues
| Issue | Symptoms | Quick Fix |
|-------|----------|-----------|
| Pending | Pod stuck in Pending | Check resources, node selectors, taints |
| CrashLoopBackOff | Pod keeps restarting | Check logs, resource limits, health probes |
| ImagePullBackOff | Cannot pull image | Check image name, registry credentials |
| ContainerCreating | Stuck creating | Check volumes, secrets, network policies |

### Network Issues
| Issue | Symptoms | Quick Fix |
|-------|----------|-----------|
| DNS Resolution | Cannot resolve service names | Restart CoreDNS, check network policies |
| Service Unreachable | Cannot connect to service | Check endpoints, service selector |
| Ingress Not Working | External access fails | Check ingress controller, TLS certificates |
| Network Policy | Blocked connections | Review network policy rules |

### Storage Issues
| Issue | Symptoms | Quick Fix |
|-------|----------|-----------|
| PVC Pending | Volume not provisioned | Check storage class, node zones |
| Mount Failed | Volume mount errors | Check permissions, volume availability |
| Out of Space | Disk full errors | Expand PVC, clean up old data |
| Performance | Slow I/O | Use faster storage class, check IOPS |

## 🛠️ Quick Troubleshooting Commands

### Essential Debug Commands
```bash
# Pod troubleshooting
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
kubectl exec -it <pod-name> -- /bin/bash

# Service troubleshooting
kubectl get endpoints <service-name>
kubectl describe service <service-name>

# Node troubleshooting
kubectl describe node <node-name>
kubectl top nodes

# Network debugging
kubectl run debug --image=nicolaka/netshoot --rm -it --restart=Never
```

### Health Check Commands
```bash
# Cluster health
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running
kubectl get events --sort-by=.metadata.creationTimestamp

# Component status
kubectl get componentstatuses
kubectl cluster-info

# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

## 🔍 Diagnostic Tools

### Debug Pods
```bash
# Network debugging
kubectl apply -f 08-tools-scripts/troubleshooting-tools.yml
kubectl exec -it netshoot-debug -- /bin/bash

# System debugging
kubectl exec -it system-debug -- /bin/sh

# Storage debugging
kubectl exec -it storage-debug -- /bin/sh
```

### Automated Scripts
```bash
# Make script executable
chmod +x 08-tools-scripts/troubleshooting-scripts.sh

# Run interactive menu
./08-tools-scripts/troubleshooting-scripts.sh

# Run specific checks
./08-tools-scripts/troubleshooting-scripts.sh health
./08-tools-scripts/troubleshooting-scripts.sh pod <pod-name>
./08-tools-scripts/troubleshooting-scripts.sh network
```

## 📊 Monitoring & Alerting

### Key Metrics to Monitor
- **Pod Health**: Restart count, ready status, resource usage
- **Node Health**: CPU, memory, disk usage, network connectivity
- **Cluster Health**: API server response time, etcd health
- **Application Health**: Response time, error rate, throughput

### Critical Alerts
```yaml
# Pod restart alert
- alert: PodRestartingTooMuch
  expr: rate(kube_pod_container_status_restarts_total[1h]) > 0.1

# Node not ready
- alert: NodeNotReady
  expr: kube_node_status_condition{condition="Ready",status="true"} == 0

# High memory usage
- alert: HighMemoryUsage
  expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
```

## 🔄 Troubleshooting Workflow

### 1. Initial Assessment
1. Check cluster overview: `kubectl get nodes,pods --all-namespaces`
2. Review recent events: `kubectl get events --sort-by=.metadata.creationTimestamp`
3. Check resource usage: `kubectl top nodes`

### 2. Component-Specific Diagnosis
1. **Pods**: Use pod troubleshooting guide
2. **Services**: Check endpoints and network policies
3. **Storage**: Verify PVCs and storage classes
4. **Network**: Test connectivity and DNS

### 3. Deep Dive Investigation
1. Examine logs: `kubectl logs <resource-name>`
2. Describe resources: `kubectl describe <resource-type> <resource-name>`
3. Use debug pods for interactive troubleshooting

### 4. Resolution and Validation
1. Apply fixes based on diagnosis
2. Monitor for issue resolution
3. Document solution for future reference

## 🚀 Performance Optimization

### Resource Right-Sizing
```bash
# Check actual resource usage
kubectl top pods --containers

# Use VPA recommendations
kubectl get vpa <vpa-name> -o yaml

# Monitor resource allocation
kubectl describe nodes | grep -A5 "Allocated resources"
```

### Scaling Optimization
```bash
# Check HPA status
kubectl get hpa
kubectl describe hpa <hpa-name>

# Monitor scaling events
kubectl get events | grep -i scale
```

## 🔐 Security Troubleshooting

### RBAC Issues
```bash
# Test permissions
kubectl auth can-i create pods --as=<user>
kubectl auth can-i --list --as=<user>

# Check role bindings
kubectl get rolebindings,clusterrolebindings -A
```

### Pod Security
```bash
# Check security contexts
kubectl get pods -o jsonpath='{.items[*].spec.securityContext}'

# Verify pod security standards
kubectl get namespaces --show-labels | grep pod-security
```

## 📝 Best Practices

### Troubleshooting Approach
1. **Start with basics**: Check status, events, logs
2. **Use systematic approach**: Follow troubleshooting guides
3. **Isolate issues**: Test components individually
4. **Document findings**: Keep track of solutions

### Prevention Strategies
1. **Monitoring**: Implement comprehensive monitoring
2. **Alerting**: Set up proactive alerts
3. **Testing**: Regular health checks and testing
4. **Documentation**: Maintain runbooks and procedures

### Emergency Procedures
1. **Cluster access**: Emergency access procedures
2. **Backup/Restore**: etcd backup and recovery
3. **Rollback**: Application and cluster rollback procedures
4. **Escalation**: When to escalate issues

This troubleshooting guide provides comprehensive coverage of Kubernetes issues with practical solutions, automated tools, and best practices for maintaining cluster health.
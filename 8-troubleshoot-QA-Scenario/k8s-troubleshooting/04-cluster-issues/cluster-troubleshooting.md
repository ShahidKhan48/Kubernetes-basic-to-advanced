# Cluster Troubleshooting Guide

## Node Issues

### 1. Node Not Ready

**Symptoms:**
- Node shows `NotReady` status
- Pods cannot be scheduled on the node

**Diagnosis:**
```bash
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl get events --field-selector involvedObject.name=<node-name>
```

**Common Causes & Solutions:**

#### Kubelet Issues
```bash
# Check kubelet status
systemctl status kubelet
journalctl -u kubelet -f

# Restart kubelet
systemctl restart kubelet
```

#### Network Issues
```bash
# Check CNI plugin
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl logs -n kube-system <cni-pod-name>

# Check node network connectivity
ping <master-node-ip>
telnet <master-node-ip> 6443
```

#### Disk Pressure
```bash
# Check disk usage
df -h
du -sh /var/lib/kubelet/*

# Clean up
docker system prune -a
kubectl delete pods --field-selector=status.phase=Succeeded -A
```

### 2. Control Plane Issues

**API Server Problems:**
```bash
# Check API server
kubectl get componentstatuses
kubectl get --raw /healthz

# Check API server logs
journalctl -u kube-apiserver -f
kubectl logs -n kube-system kube-apiserver-<master-node>
```

**etcd Issues:**
```bash
# Check etcd health
kubectl get --raw /healthz/etcd
etcdctl endpoint health --cluster

# Check etcd logs
journalctl -u etcd -f
kubectl logs -n kube-system etcd-<master-node>
```

**Scheduler Issues:**
```bash
# Check scheduler
kubectl get events | grep FailedScheduling
kubectl logs -n kube-system kube-scheduler-<master-node>
```

### 3. Resource Exhaustion

**CPU/Memory Pressure:**
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes | grep -A5 "Allocated resources"

# Check system resources
top
free -h
iostat -x 1
```

**Pod Limit Reached:**
```bash
# Check pod limits
kubectl describe node <node-name> | grep "Non-terminated Pods"

# Increase pod limit (if needed)
# Edit kubelet config: --max-pods=250
```

## Cluster Networking Issues

### 1. DNS Resolution Problems

**Diagnosis:**
```bash
# Test DNS from pod
kubectl run debug --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

**Solutions:**
```bash
# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Check CoreDNS configuration
kubectl get configmap coredns -n kube-system -o yaml
```

### 2. Service Mesh Issues

**Istio Problems:**
```bash
# Check Istio components
kubectl get pods -n istio-system
istioctl analyze

# Check sidecar injection
kubectl get namespace -L istio-injection
kubectl describe pod <pod-name> | grep istio-proxy
```

## Authentication & Authorization Issues

### 1. RBAC Problems

**Diagnosis:**
```bash
# Test permissions
kubectl auth can-i create pods --as=system:serviceaccount:default:default
kubectl auth can-i '*' '*' --as=<user>

# Check roles and bindings
kubectl get clusterroles,clusterrolebindings
kubectl describe clusterrolebinding <binding-name>
```

**Solutions:**
```bash
# Create service account with proper permissions
kubectl create serviceaccount <sa-name>
kubectl create clusterrolebinding <binding-name> --clusterrole=<role> --serviceaccount=<namespace>:<sa-name>
```

### 2. Certificate Issues

**Diagnosis:**
```bash
# Check certificate expiration
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep "Not After"

# Check certificate validity
kubectl get csr
kubectl describe csr <csr-name>
```

**Solutions:**
```bash
# Renew certificates (kubeadm)
kubeadm certs check-expiration
kubeadm certs renew all
```

## Cluster Upgrades Issues

### 1. Upgrade Failures

**Pre-upgrade Checks:**
```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get componentstatuses

# Check for deprecated APIs
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -A
```

**Common Issues:**
- Deprecated API versions
- Incompatible addons
- Resource constraints

### 2. Node Upgrade Issues

**Diagnosis:**
```bash
# Check node version
kubectl get nodes -o wide

# Check kubelet version
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kubeletVersion}'
```

**Solutions:**
```bash
# Drain node before upgrade
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Upgrade node
# ... perform upgrade steps ...

# Uncordon node
kubectl uncordon <node-name>
```

## Monitoring & Observability Issues

### 1. Metrics Server Problems

**Diagnosis:**
```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl logs -n kube-system deployment/metrics-server
kubectl top nodes
```

**Solutions:**
```bash
# Restart metrics server
kubectl rollout restart deployment/metrics-server -n kube-system

# Check metrics server configuration
kubectl get deployment metrics-server -n kube-system -o yaml
```

### 2. Logging Issues

**Diagnosis:**
```bash
# Check log collection
kubectl get pods -n kube-system -l name=fluentd
kubectl logs -n kube-system <fluentd-pod>

# Check log rotation
ls -la /var/log/containers/
```

## Cluster Security Issues

### 1. Pod Security Policy Violations

**Diagnosis:**
```bash
kubectl get psp
kubectl describe psp <policy-name>
kubectl get events | grep "violates PodSecurityPolicy"
```

### 2. Network Policy Issues

**Diagnosis:**
```bash
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name>

# Test connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- <target-service>
```

## Disaster Recovery

### 1. etcd Backup and Restore

**Backup:**
```bash
ETCDCTL_API=3 etcdctl snapshot save backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

**Restore:**
```bash
ETCDCTL_API=3 etcdctl snapshot restore backup.db \
  --data-dir=/var/lib/etcd-restore
```

### 2. Cluster State Recovery

**Check cluster state:**
```bash
kubectl get all --all-namespaces
kubectl get pv,pvc --all-namespaces
kubectl get secrets --all-namespaces
```

## Performance Troubleshooting

### 1. API Server Performance

**Diagnosis:**
```bash
# Check API server metrics
kubectl get --raw /metrics | grep apiserver_request_duration_seconds

# Check API server load
kubectl top pods -n kube-system | grep apiserver
```

### 2. Scheduler Performance

**Diagnosis:**
```bash
# Check scheduling latency
kubectl get events | grep "Successfully assigned"
kubectl get --raw /metrics | grep scheduler_scheduling_duration_seconds
```

## Common Cluster Fixes

### Reset Cluster Component
```bash
# Reset kubelet
systemctl stop kubelet
rm -rf /var/lib/kubelet/*
systemctl start kubelet

# Reset CNI
rm -rf /etc/cni/net.d/*
rm -rf /var/lib/cni/*
```

### Emergency Cluster Access
```bash
# Direct etcd access
ETCDCTL_API=3 etcdctl get "" --prefix --keys-only

# Bypass RBAC (emergency only)
kubectl create clusterrolebinding emergency --clusterrole=cluster-admin --user=<user>
```

### Cluster Health Check Script
```bash
#!/bin/bash
echo "=== Cluster Health Check ==="
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running
kubectl get componentstatuses
kubectl top nodes
echo "=== Recent Events ==="
kubectl get events --sort-by=.metadata.creationTimestamp | tail -10
```
# Pod Troubleshooting Guide

## Common Pod Issues and Solutions

### 1. Pod Stuck in Pending State

#### Symptoms
```bash
kubectl get pods
NAME        READY   STATUS    RESTARTS   AGE
my-pod      0/1     Pending   0          5m
```

#### Causes and Solutions
```bash
# Check pod events
kubectl describe pod my-pod

# Common causes:
# 1. Insufficient resources
kubectl describe nodes
kubectl top nodes

# 2. Node selector issues
kubectl get nodes --show-labels

# 3. Taints and tolerations
kubectl describe node <node-name>

# 4. PVC not available
kubectl get pvc
```

### 2. Pod in CrashLoopBackOff

#### Symptoms
```bash
NAME        READY   STATUS             RESTARTS   AGE
my-pod      0/1     CrashLoopBackOff   5          10m
```

#### Troubleshooting Steps
```bash
# Check pod logs
kubectl logs my-pod
kubectl logs my-pod --previous

# Check pod events
kubectl describe pod my-pod

# Check resource limits
kubectl describe pod my-pod | grep -A 5 "Limits\|Requests"

# Debug with different image
kubectl run debug-pod --image=busybox --command -- sleep 3600
```

### 3. Pod in ImagePullBackOff

#### Symptoms
```bash
NAME        READY   STATUS             RESTARTS   AGE
my-pod      0/1     ImagePullBackOff   0          2m
```

#### Solutions
```bash
# Check image name and tag
kubectl describe pod my-pod

# Check image pull secrets
kubectl get secrets
kubectl describe secret <image-pull-secret>

# Test image pull manually
docker pull <image-name>

# Check registry connectivity
kubectl run test-pod --image=busybox --rm -it -- nslookup registry.domain.com
```

### 4. Pod Running but Not Ready

#### Symptoms
```bash
NAME        READY   STATUS    RESTARTS   AGE
my-pod      0/1     Running   0          5m
```

#### Troubleshooting
```bash
# Check readiness probe
kubectl describe pod my-pod

# Check application logs
kubectl logs my-pod

# Test readiness probe manually
kubectl exec my-pod -- curl localhost:8080/health

# Check service endpoints
kubectl get endpoints
```

### 5. Pod Networking Issues

#### DNS Resolution Problems
```bash
# Test DNS resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup kubernetes.default

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check DNS configuration
kubectl exec my-pod -- cat /etc/resolv.conf
```

#### Service Connectivity Issues
```bash
# Test service connectivity
kubectl exec my-pod -- curl <service-name>.<namespace>.svc.cluster.local

# Check service endpoints
kubectl get endpoints <service-name>

# Check network policies
kubectl get networkpolicies
```

### 6. Resource Issues

#### Out of Memory (OOMKilled)
```bash
# Check pod events
kubectl describe pod my-pod

# Check resource usage
kubectl top pod my-pod

# Increase memory limits
kubectl patch deployment my-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"my-container","resources":{"limits":{"memory":"512Mi"}}}]}}}}'
```

#### CPU Throttling
```bash
# Check CPU usage
kubectl top pod my-pod

# Check CPU limits
kubectl describe pod my-pod | grep -A 5 "Limits"

# Monitor CPU throttling
kubectl exec my-pod -- cat /sys/fs/cgroup/cpu/cpu.stat
```

## Debugging Commands

### Essential Debugging Commands
```bash
# Get pod information
kubectl get pods -o wide
kubectl get pods --show-labels
kubectl get pods -o yaml

# Describe pod (most important)
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f
kubectl logs <pod-name> --previous
kubectl logs <pod-name> -c <container-name>

# Execute commands in pod
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- /bin/sh

# Debug with ephemeral containers (K8s 1.23+)
kubectl debug <pod-name> -it --image=busybox --target=<container-name>

# Port forwarding for testing
kubectl port-forward <pod-name> 8080:80

# Copy files for debugging
kubectl cp <pod-name>:/path/to/file ./local-file
```

### Advanced Debugging
```bash
# Create debug pod in same namespace
kubectl run debug --image=busybox --rm -it -- sh

# Check node conditions
kubectl describe node <node-name>

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource quotas
kubectl describe resourcequota

# Check limit ranges
kubectl describe limitrange

# Monitor resource usage
kubectl top pods
kubectl top nodes
```

## Troubleshooting Checklist

### Pre-Deployment Checklist
- [ ] Image exists and is accessible
- [ ] Resource requests and limits are appropriate
- [ ] Node selectors and affinity rules are correct
- [ ] Required secrets and configmaps exist
- [ ] PVCs are available if needed
- [ ] Network policies allow required traffic

### Runtime Issues Checklist
- [ ] Check pod status and events
- [ ] Verify application logs
- [ ] Test health check endpoints
- [ ] Validate environment variables
- [ ] Check resource usage
- [ ] Verify network connectivity
- [ ] Validate persistent volume mounts

### Performance Issues Checklist
- [ ] Monitor CPU and memory usage
- [ ] Check for resource throttling
- [ ] Validate storage I/O
- [ ] Test network latency
- [ ] Review application metrics
- [ ] Check for resource contention
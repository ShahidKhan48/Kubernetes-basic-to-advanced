# Pod Troubleshooting Guide

## Common Pod Issues

### 1. Pod Stuck in Pending State

**Symptoms:**
- Pod remains in `Pending` status
- No containers are running

**Diagnosis Commands:**
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get nodes -o wide
```

**Common Causes & Solutions:**

#### Insufficient Resources
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Solution: Add more nodes or reduce resource requests
```

#### Node Selector Issues
```bash
# Check node labels
kubectl get nodes --show-labels

# Solution: Update nodeSelector or add labels to nodes
kubectl label nodes <node-name> <key>=<value>
```

#### Taints and Tolerations
```bash
# Check node taints
kubectl describe node <node-name> | grep Taints

# Solution: Add tolerations to pod spec
```

### 2. Pod Stuck in ContainerCreating

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Common Causes:**
- Image pull issues
- Volume mount problems
- Secret/ConfigMap not found

**Solutions:**
```bash
# Check image pull secrets
kubectl get secrets
kubectl describe secret <image-pull-secret>

# Check volumes
kubectl get pv,pvc
kubectl describe pvc <pvc-name>
```

### 3. CrashLoopBackOff

**Diagnosis:**
```bash
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
```

**Common Causes:**
- Application crashes on startup
- Incorrect command/args
- Missing dependencies
- Resource limits too low

**Solutions:**
```bash
# Increase resource limits
# Fix application configuration
# Check liveness/readiness probes
```

### 4. ImagePullBackOff

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl get events
```

**Solutions:**
```bash
# Check image name and tag
# Verify registry credentials
kubectl create secret docker-registry <secret-name> \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password>

# Test image pull manually
docker pull <image-name>
```

### 5. Pod Evicted

**Diagnosis:**
```bash
kubectl get pods --field-selector=status.phase=Failed
kubectl describe pod <evicted-pod>
```

**Common Reasons:**
- Node pressure (CPU, memory, disk)
- Exceeding resource limits

**Solutions:**
```bash
# Check node conditions
kubectl describe nodes

# Increase resource requests/limits
# Add more nodes to cluster
```

## Pod Debugging Tools

### Debug Pod Template
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
spec:
  containers:
  - name: debug
    image: nicolaka/netshoot
    command: ["/bin/bash"]
    args: ["-c", "sleep 3600"]
    securityContext:
      capabilities:
        add: ["NET_ADMIN"]
  restartPolicy: Never
```

### Useful Debug Commands
```bash
# Create debug pod
kubectl run debug --image=busybox --rm -it --restart=Never -- sh

# Debug networking
kubectl run netshoot --image=nicolaka/netshoot --rm -it --restart=Never

# Check DNS resolution
nslookup kubernetes.default.svc.cluster.local

# Test connectivity
wget -qO- http://service-name:port/health
```

## Pod Lifecycle Troubleshooting

### Init Container Issues
```bash
# Check init container logs
kubectl logs <pod-name> -c <init-container-name>

# Describe pod for init container status
kubectl describe pod <pod-name>
```

### Sidecar Container Issues
```bash
# Check all container logs
kubectl logs <pod-name> --all-containers=true

# Check specific container
kubectl logs <pod-name> -c <container-name>
```

### Health Check Failures
```bash
# Check probe configuration
kubectl describe pod <pod-name>

# Test health endpoints manually
kubectl exec <pod-name> -- curl localhost:8080/health
```

## Resource Troubleshooting

### Memory Issues
```bash
# Check memory usage
kubectl top pods
kubectl describe pod <pod-name>

# Check for OOMKilled
kubectl get events | grep OOMKilling
```

### CPU Throttling
```bash
# Check CPU metrics
kubectl top pods
kubectl describe pod <pod-name>

# Check for CPU throttling in metrics
```

## Quick Fix Commands

```bash
# Restart deployment
kubectl rollout restart deployment <deployment-name>

# Scale deployment
kubectl scale deployment <deployment-name> --replicas=3

# Delete stuck pod
kubectl delete pod <pod-name> --force --grace-period=0

# Patch pod
kubectl patch pod <pod-name> -p '{"spec":{"containers":[{"name":"<container>","image":"<new-image>"}]}}'
```
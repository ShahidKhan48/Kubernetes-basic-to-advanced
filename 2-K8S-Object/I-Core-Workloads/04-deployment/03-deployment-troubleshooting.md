# Deployment Troubleshooting Guide

## Common Deployment Issues

### 1. Deployment Stuck in Progressing State

#### Symptoms
```bash
kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/3     1            2           10m

kubectl rollout status deployment/nginx-deployment
Waiting for deployment "nginx-deployment" rollout to finish: 1 of 3 updated replicas are available...
```

#### Troubleshooting Steps
```bash
# Check deployment status and events
kubectl describe deployment nginx-deployment

# Check ReplicaSet status
kubectl get rs -l app=nginx
kubectl describe rs <replicaset-name>

# Check pod status
kubectl get pods -l app=nginx
kubectl describe pods -l app=nginx

# Check rollout history
kubectl rollout history deployment/nginx-deployment
```

#### Common Causes
- Image pull failures
- Insufficient resources
- Failed health checks
- Configuration errors
- Resource quotas exceeded

### 2. ImagePullBackOff in Deployment

#### Symptoms
```bash
kubectl get pods
NAME                               READY   STATUS             RESTARTS   AGE
nginx-deployment-7d6b7d4f8-abc123  0/1     ImagePullBackOff   0          5m
```

#### Solutions
```bash
# Check image name and tag
kubectl describe deployment nginx-deployment | grep Image

# Check image pull secrets
kubectl get secrets
kubectl describe secret <image-pull-secret>

# Verify image exists
docker pull <image-name>

# Check pod events for detailed error
kubectl describe pod <pod-name>

# Fix image name or add image pull secrets
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"registry-secret"}]}}}}'
```

### 3. Rolling Update Failures

#### Symptoms
```bash
kubectl rollout status deployment/nginx-deployment
error: deployment "nginx-deployment" exceeded its progress deadline
```

#### Troubleshooting
```bash
# Check rollout status
kubectl rollout status deployment/nginx-deployment --timeout=300s

# Check deployment conditions
kubectl get deployment nginx-deployment -o yaml | grep -A 10 conditions

# Check new ReplicaSet
kubectl get rs -l app=nginx --sort-by=.metadata.creationTimestamp

# Check failed pods
kubectl get pods -l app=nginx | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff)"

# Rollback if needed
kubectl rollout undo deployment/nginx-deployment
```

### 4. Resource Constraint Issues

#### Symptoms
```bash
# Pods stuck in Pending state
kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
nginx-deployment-7d6b7d4f8-xyz789  0/1     Pending   0          10m
```

#### Solutions
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Check resource requests in deployment
kubectl describe deployment nginx-deployment | grep -A 10 "Requests\|Limits"

# Check resource quotas
kubectl get resourcequota
kubectl describe resourcequota

# Check limit ranges
kubectl get limitrange
kubectl describe limitrange

# Adjust resource requests/limits
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"memory":"64Mi","cpu":"50m"}}}]}}}}'
```

### 5. Health Check Failures

#### Symptoms
```bash
# Pods not becoming ready
kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
nginx-deployment-7d6b7d4f8-abc123  0/1     Running   0          5m
```

#### Troubleshooting
```bash
# Check readiness probe configuration
kubectl describe deployment nginx-deployment | grep -A 10 "Readiness"

# Test health check endpoint manually
kubectl exec <pod-name> -- curl localhost:8080/health

# Check application logs
kubectl logs <pod-name>

# Temporarily disable probes for debugging
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","readinessProbe":null}]}}}}'
```

### 6. Configuration Issues

#### ConfigMap/Secret Not Found
```bash
# Check if ConfigMap/Secret exists
kubectl get configmap
kubectl get secret

# Check deployment references
kubectl describe deployment nginx-deployment | grep -E "(ConfigMap|Secret)"

# Create missing resources
kubectl create configmap app-config --from-literal=key=value
kubectl create secret generic app-secret --from-literal=password=secret123
```

#### Environment Variable Issues
```bash
# Check environment variables in pods
kubectl exec <pod-name> -- env

# Verify ConfigMap/Secret data
kubectl get configmap <configmap-name> -o yaml
kubectl get secret <secret-name> -o yaml

# Test with debug pod
kubectl run debug --image=busybox --rm -it -- sh
```

## Debugging Commands

### Deployment Status Commands
```bash
# Get deployment information
kubectl get deployments
kubectl get deployments -o wide
kubectl describe deployment <deployment-name>

# Check rollout status
kubectl rollout status deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>

# Get deployment conditions
kubectl get deployment <deployment-name> -o jsonpath='{.status.conditions[*].type}'
kubectl get deployment <deployment-name> -o yaml | grep -A 20 conditions
```

### ReplicaSet Analysis
```bash
# Get ReplicaSets for deployment
kubectl get rs -l app=<app-label>
kubectl get rs --sort-by=.metadata.creationTimestamp

# Check current and old ReplicaSets
kubectl describe rs <current-replicaset>
kubectl describe rs <old-replicaset>

# Get ReplicaSet events
kubectl get events --field-selector involvedObject.kind=ReplicaSet
```

### Pod-Level Debugging
```bash
# Get pods for deployment
kubectl get pods -l app=<app-label>
kubectl get pods -l app=<app-label> -o wide

# Check pod events and logs
kubectl describe pods -l app=<app-label>
kubectl logs -l app=<app-label> --all-containers=true

# Debug specific pod
kubectl exec -it <pod-name> -- /bin/sh
kubectl port-forward <pod-name> 8080:80
```

### Resource Analysis
```bash
# Check resource usage
kubectl top pods -l app=<app-label>
kubectl top nodes

# Check resource quotas and limits
kubectl describe resourcequota
kubectl describe limitrange

# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## Common Error Messages and Solutions

### "Deployment does not have minimum availability"
```bash
# Check pod disruption budget
kubectl get pdb
kubectl describe pdb <pdb-name>

# Check rolling update strategy
kubectl get deployment <name> -o yaml | grep -A 5 strategy

# Adjust maxUnavailable
kubectl patch deployment <name> -p '{"spec":{"strategy":{"rollingUpdate":{"maxUnavailable":"50%"}}}}'
```

### "ReplicaSet has no matching pods"
```bash
# Check selector vs pod labels
kubectl get deployment <name> -o jsonpath='{.spec.selector}'
kubectl get pods --show-labels -l app=<app>

# Fix label mismatch
kubectl patch deployment <name> -p '{"spec":{"template":{"metadata":{"labels":{"app":"correct-label"}}}}}'
```

### "Exceeded progress deadline"
```bash
# Increase progress deadline
kubectl patch deployment <name> -p '{"spec":{"progressDeadlineSeconds":1200}}'

# Check what's blocking progress
kubectl describe deployment <name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

### "Insufficient resources"
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Reduce resource requests
kubectl patch deployment <name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"memory":"64Mi","cpu":"50m"}}}]}}}}'

# Add more nodes or increase node capacity
```

## Best Practices for Troubleshooting

### 1. Start with High-Level View
```bash
kubectl get deployments
kubectl describe deployment <name>
kubectl rollout status deployment/<name>
```

### 2. Check the Deployment Hierarchy
```bash
# Deployment -> ReplicaSet -> Pods
kubectl get deployment,rs,pods -l app=<app>
```

### 3. Examine Events Chronologically
```bash
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector involvedObject.name=<deployment-name>
```

### 4. Use Labels for Filtering
```bash
kubectl get all -l app=<app>
kubectl describe all -l app=<app>
```

### 5. Check Resource Constraints
```bash
kubectl describe nodes
kubectl get resourcequota,limitrange
kubectl top nodes,pods
```

### 6. Validate Configuration
```bash
kubectl apply -f deployment.yaml --dry-run=client
kubectl diff -f deployment.yaml
```

### 7. Use Rollback When Needed
```bash
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=2
```

### 8. Monitor During Updates
```bash
kubectl rollout status deployment/<name> -w
kubectl get pods -l app=<app> -w
```
# ReplicaSet Troubleshooting Guide

## Common ReplicaSet Issues

### 1. ReplicaSet Not Creating Pods

#### Symptoms
```bash
kubectl get rs
NAME               DESIRED   CURRENT   READY   AGE
nginx-replicaset   3         0         0       5m
```

#### Troubleshooting Steps
```bash
# Check ReplicaSet events
kubectl describe rs nginx-replicaset

# Check ReplicaSet selector
kubectl get rs nginx-replicaset -o yaml | grep -A 10 selector

# Verify pod template
kubectl get rs nginx-replicaset -o yaml | grep -A 20 template

# Check for resource constraints
kubectl describe nodes
kubectl get resourcequota
kubectl get limitrange
```

#### Common Causes
- Selector doesn't match pod labels
- Insufficient cluster resources
- Image pull issues
- Resource quota exceeded
- Invalid pod template

### 2. Pods Not Matching ReplicaSet

#### Symptoms
```bash
kubectl get pods --show-labels
NAME                     READY   STATUS    LABELS
nginx-pod-12345         1/1     Running   app=nginx,version=v2
nginx-replicaset-67890  1/1     Running   app=nginx,version=v1
```

#### Solutions
```bash
# Check label mismatch
kubectl get rs nginx-replicaset -o yaml | grep -A 5 matchLabels
kubectl get pods -l app=nginx --show-labels

# Fix pod labels
kubectl label pod nginx-pod-12345 version=v1 --overwrite

# Or remove conflicting pods
kubectl delete pod nginx-pod-12345
```

### 3. ReplicaSet Scaling Issues

#### Symptoms
```bash
# Scaling command doesn't work
kubectl scale rs nginx-replicaset --replicas=5
# Pods remain at old count
```

#### Troubleshooting
```bash
# Check ReplicaSet status
kubectl get rs nginx-replicaset -o wide

# Check events
kubectl describe rs nginx-replicaset

# Check resource availability
kubectl top nodes
kubectl describe nodes

# Check pod disruption budgets
kubectl get pdb
```

### 4. Pod Template Update Issues

#### Problem
ReplicaSet doesn't update existing pods when template changes

#### Solution
```bash
# ReplicaSets don't update existing pods automatically
# You need to delete pods manually for updates

# Delete pods to trigger recreation with new template
kubectl delete pods -l app=nginx

# Or use rolling update with Deployment instead
kubectl create deployment nginx-deployment --image=nginx:alpine
```

### 5. Orphaned Pods

#### Symptoms
```bash
# Pods exist but ReplicaSet shows 0 current
kubectl get rs
NAME               DESIRED   CURRENT   READY   AGE
nginx-replicaset   3         0         0       10m

kubectl get pods -l app=nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-replicaset-abc123  1/1     Running   0          10m
nginx-replicaset-def456  1/1     Running   0          10m
```

#### Solutions
```bash
# Check pod ownership
kubectl get pods -l app=nginx -o yaml | grep -A 5 ownerReferences

# Adopt orphaned pods by fixing labels
kubectl label pods -l app=nginx version=v1

# Or delete orphaned pods
kubectl delete pods -l app=nginx
```

## Debugging Commands

### ReplicaSet Information
```bash
# Get ReplicaSet details
kubectl get rs
kubectl get rs -o wide
kubectl get rs --show-labels
kubectl describe rs <replicaset-name>

# Get ReplicaSet YAML
kubectl get rs <replicaset-name> -o yaml

# Check ReplicaSet events
kubectl get events --field-selector involvedObject.kind=ReplicaSet
```

### Pod Relationship
```bash
# Get pods managed by ReplicaSet
kubectl get pods -l <selector-labels>
kubectl get pods --show-labels | grep <replicaset-name>

# Check pod ownership
kubectl get pods -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].name

# Verify selector matching
kubectl get rs <replicaset-name> -o jsonpath='{.spec.selector}'
kubectl get pods -l <selector> --show-labels
```

### Resource Analysis
```bash
# Check resource usage
kubectl top pods -l <selector>
kubectl describe nodes

# Check resource quotas
kubectl get resourcequota
kubectl describe resourcequota

# Check limit ranges
kubectl get limitrange
kubectl describe limitrange
```

## Common Error Messages

### "ReplicaSet has no matching pods"
```bash
# Check selector vs pod labels
kubectl get rs <name> -o jsonpath='{.spec.selector.matchLabels}'
kubectl get pods --show-labels

# Fix: Update pod labels or ReplicaSet selector
kubectl label pod <pod-name> <key>=<value>
```

### "Forbidden: pod updates may not change fields"
```bash
# ReplicaSet template changes don't update existing pods
# Solution: Delete pods to recreate with new template
kubectl delete pods -l <selector>
```

### "Insufficient resources"
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Check resource requests in template
kubectl get rs <name> -o yaml | grep -A 10 resources
```

## Best Practices for Troubleshooting

### 1. Always Check Events First
```bash
kubectl describe rs <replicaset-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

### 2. Verify Label Selectors
```bash
# Ensure selector matches pod labels exactly
kubectl get rs <name> -o jsonpath='{.spec.selector}'
kubectl get pods -l <selector> --show-labels
```

### 3. Check Resource Constraints
```bash
# Node resources
kubectl describe nodes
kubectl top nodes

# Namespace quotas
kubectl describe resourcequota
kubectl describe limitrange
```

### 4. Monitor Pod States
```bash
# Watch pod creation/deletion
kubectl get pods -w -l <selector>

# Check pod events
kubectl describe pods -l <selector>
```

### 5. Use Deployments Instead
ReplicaSets are typically managed by Deployments. Consider using Deployments for:
- Rolling updates
- Rollback capabilities
- Better update strategies
- Easier management

```bash
# Convert ReplicaSet to Deployment
kubectl create deployment <name> --image=<image> --dry-run=client -o yaml > deployment.yaml
```
# ReplicaSet Commands Reference

## ReplicaSet Creation Commands

### Imperative Creation
```bash
# Create ReplicaSet from image (not directly supported)
# Use deployment and get the ReplicaSet
kubectl create deployment nginx-deploy --image=nginx:alpine
kubectl get rs

# Create ReplicaSet from YAML
kubectl apply -f replicaset.yaml
kubectl create -f replicaset.yaml

# Generate ReplicaSet YAML
kubectl create deployment temp-deploy --image=nginx --dry-run=client -o yaml | \
  sed 's/Deployment/ReplicaSet/g' | \
  sed '/strategy:/,+3d' > replicaset.yaml
```

### Declarative Management
```bash
# Apply ReplicaSet configuration
kubectl apply -f replicaset.yaml
kubectl apply -f ./replicasets/

# Validate configuration
kubectl apply -f replicaset.yaml --dry-run=client
kubectl apply -f replicaset.yaml --validate=true

# Show differences
kubectl diff -f replicaset.yaml
```

## ReplicaSet Information Commands

### Basic Information
```bash
# List ReplicaSets
kubectl get rs
kubectl get replicasets
kubectl get rs -A                     # All namespaces
kubectl get rs -n <namespace>         # Specific namespace
kubectl get rs -o wide               # Extended information
kubectl get rs --show-labels        # Show labels

# Filter ReplicaSets
kubectl get rs -l app=nginx         # Filter by labels
kubectl get rs --field-selector=metadata.name=nginx-rs

# Detailed ReplicaSet information
kubectl describe rs <replicaset-name>
kubectl describe rs                  # All ReplicaSets
kubectl describe rs -l app=nginx    # Filtered ReplicaSets
```

### ReplicaSet Status
```bash
# Get ReplicaSet status
kubectl get rs -o custom-columns=NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas

# Watch ReplicaSet changes
kubectl get rs -w
kubectl get rs -w -o wide

# Get ReplicaSet YAML/JSON
kubectl get rs <replicaset-name> -o yaml
kubectl get rs <replicaset-name> -o json
```

### ReplicaSet Events
```bash
# Get ReplicaSet events
kubectl get events --field-selector involvedObject.kind=ReplicaSet
kubectl get events --field-selector involvedObject.name=<replicaset-name>
kubectl get events --sort-by=.metadata.creationTimestamp

# Describe for events
kubectl describe rs <replicaset-name>
```

## ReplicaSet Scaling Commands

### Manual Scaling
```bash
# Scale ReplicaSet
kubectl scale rs <replicaset-name> --replicas=5
kubectl scale rs <replicaset-name> --replicas=0  # Scale down to 0

# Scale multiple ReplicaSets
kubectl scale rs nginx-rs web-rs --replicas=3

# Scale with condition
kubectl scale rs <replicaset-name> --current-replicas=3 --replicas=5

# Scale ReplicaSets by label
kubectl scale rs -l app=nginx --replicas=2
```

### Scaling Information
```bash
# Check current scale
kubectl get rs <replicaset-name> -o jsonpath='{.spec.replicas}'
kubectl get rs <replicaset-name> -o jsonpath='{.status.replicas}'

# Monitor scaling
kubectl get rs <replicaset-name> -w
kubectl get pods -l <selector> -w
```

## Pod Management Commands

### Pod Information
```bash
# Get pods managed by ReplicaSet
kubectl get pods -l <selector-labels>
kubectl get pods --show-labels | grep <replicaset-name>

# Get pod ownership information
kubectl get pods -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].name,KIND:.metadata.ownerReferences[0].kind

# Check pod-ReplicaSet relationship
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.ownerReferences[0].name}{"\n"}{end}'
```

### Pod Operations
```bash
# Delete pods (ReplicaSet will recreate)
kubectl delete pod <pod-name>
kubectl delete pods -l <selector>

# Force delete pods
kubectl delete pod <pod-name> --force --grace-period=0

# Get pod logs from ReplicaSet
kubectl logs -l <selector>
kubectl logs -l <selector> --all-containers=true
kubectl logs -l <selector> -f
```

## ReplicaSet Configuration Commands

### Label and Selector Operations
```bash
# Get ReplicaSet selector
kubectl get rs <replicaset-name> -o jsonpath='{.spec.selector}'
kubectl get rs <replicaset-name> -o jsonpath='{.spec.selector.matchLabels}'

# Update ReplicaSet labels
kubectl label rs <replicaset-name> environment=production
kubectl label rs <replicaset-name> version=v2 --overwrite

# Remove labels
kubectl label rs <replicaset-name> environment-

# Get pods matching selector
kubectl get pods -l $(kubectl get rs <replicaset-name> -o jsonpath='{.spec.selector.matchLabels}' | tr -d '{}' | tr ' ' ',')
```

### Template Operations
```bash
# Get pod template
kubectl get rs <replicaset-name> -o jsonpath='{.spec.template}'

# Update image in ReplicaSet (requires pod deletion for effect)
kubectl patch rs <replicaset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","image":"<new-image>"}]}}}}'

# Update resource limits
kubectl patch rs <replicaset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"512Mi"}}}]}}}}'
```

## ReplicaSet Deletion Commands

### Delete ReplicaSet
```bash
# Delete ReplicaSet and its pods
kubectl delete rs <replicaset-name>

# Delete ReplicaSet but keep pods (orphan pods)
kubectl delete rs <replicaset-name> --cascade=orphan

# Delete ReplicaSets by label
kubectl delete rs -l app=nginx

# Delete all ReplicaSets in namespace
kubectl delete rs --all

# Force delete ReplicaSet
kubectl delete rs <replicaset-name> --force --grace-period=0
```

### Cleanup Operations
```bash
# Delete ReplicaSet and wait for completion
kubectl delete rs <replicaset-name> --wait=true

# Delete with specific timeout
kubectl delete rs <replicaset-name> --timeout=60s

# Delete from file
kubectl delete -f replicaset.yaml
```

## Debugging and Troubleshooting Commands

### Status Checking
```bash
# Check ReplicaSet health
kubectl get rs <replicaset-name> -o custom-columns=NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas,AGE:.metadata.creationTimestamp

# Check pod distribution
kubectl get pods -l <selector> -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase

# Check resource usage
kubectl top pods -l <selector>
```

### Debugging Commands
```bash
# Debug ReplicaSet issues
kubectl describe rs <replicaset-name>
kubectl get events --field-selector involvedObject.name=<replicaset-name>

# Check selector matching
kubectl get rs <replicaset-name> -o jsonpath='{.spec.selector.matchLabels}'
kubectl get pods --show-labels -l <selector>

# Verify pod template
kubectl get rs <replicaset-name> -o yaml | grep -A 50 template

# Check for conflicting resources
kubectl get pods --show-labels | grep -v <replicaset-name>
```

### Resource Analysis
```bash
# Check resource requests/limits
kubectl get rs <replicaset-name> -o jsonpath='{.spec.template.spec.containers[*].resources}'

# Check node capacity
kubectl describe nodes
kubectl top nodes

# Check resource quotas
kubectl get resourcequota
kubectl describe resourcequota
```

## Advanced ReplicaSet Operations

### Ownership and Adoption
```bash
# Check pod ownership
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.ownerReferences[0].name}{"\n"}{end}'

# Adopt orphaned pods (by matching labels)
kubectl label pods -l <selector> <required-labels>

# Release pods from ReplicaSet
kubectl patch pod <pod-name> -p '{"metadata":{"ownerReferences":null}}'
```

### Batch Operations
```bash
# Scale multiple ReplicaSets
for rs in $(kubectl get rs -o name); do
  kubectl scale $rs --replicas=2
done

# Get status of all ReplicaSets
kubectl get rs -o custom-columns=NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas

# Delete all ReplicaSets with specific label
kubectl delete rs -l environment=test

# Update image for all ReplicaSets with label
kubectl get rs -l app=myapp -o name | xargs -I {} kubectl patch {} -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"myapp:v2"}]}}}}'
```

### Monitoring Commands
```bash
# Watch ReplicaSet and pod status
kubectl get rs,pods -l <selector> -w

# Monitor resource usage
watch kubectl top pods -l <selector>

# Check ReplicaSet history (limited compared to Deployments)
kubectl describe rs <replicaset-name> | grep -A 10 Events

# Export ReplicaSet configuration
kubectl get rs <replicaset-name> -o yaml --export > replicaset-backup.yaml
```

## ReplicaSet vs Deployment Commands

### Convert ReplicaSet to Deployment
```bash
# Get ReplicaSet YAML and modify
kubectl get rs <replicaset-name> -o yaml > rs.yaml

# Create Deployment from ReplicaSet template
kubectl create deployment <deployment-name> --image=<image> --dry-run=client -o yaml > deployment.yaml

# Apply Deployment and delete ReplicaSet
kubectl apply -f deployment.yaml
kubectl delete rs <replicaset-name> --cascade=orphan  # Keep pods
```

### Deployment to ReplicaSet Relationship
```bash
# Get ReplicaSets created by Deployment
kubectl get rs -l app=<deployment-name>

# Get current ReplicaSet for Deployment
kubectl get deployment <deployment-name> -o jsonpath='{.metadata.labels.pod-template-hash}'

# Describe Deployment to see ReplicaSet events
kubectl describe deployment <deployment-name>
```
# DaemonSet Commands Reference

## DaemonSet Creation Commands

### Imperative Creation
```bash
# Create DaemonSet from YAML
kubectl apply -f daemonset.yaml
kubectl create -f daemonset.yaml

# Generate DaemonSet YAML from deployment
kubectl create deployment nginx-deploy --image=nginx --dry-run=client -o yaml | \
  sed 's/Deployment/DaemonSet/g' | \
  sed '/replicas:/d' | \
  sed '/strategy:/,+3d' > daemonset.yaml

# Create from existing deployment
kubectl get deployment <deployment-name> -o yaml | \
  sed 's/kind: Deployment/kind: DaemonSet/' | \
  sed '/replicas:/d' | \
  kubectl apply -f -
```

### Declarative Management
```bash
# Apply DaemonSet configuration
kubectl apply -f daemonset.yaml
kubectl apply -f ./daemonsets/

# Validate configuration
kubectl apply -f daemonset.yaml --dry-run=client
kubectl apply -f daemonset.yaml --validate=true

# Show differences
kubectl diff -f daemonset.yaml
```

## DaemonSet Information Commands

### Basic Information
```bash
# List DaemonSets
kubectl get daemonsets
kubectl get ds                       # Short form
kubectl get daemonsets -A            # All namespaces
kubectl get daemonsets -n <namespace>  # Specific namespace
kubectl get daemonsets -o wide       # Extended information
kubectl get daemonsets --show-labels # Show labels

# Filter DaemonSets
kubectl get daemonsets -l app=nginx
kubectl get daemonsets --field-selector=metadata.name=log-collector

# Detailed DaemonSet information
kubectl describe daemonset <daemonset-name>
kubectl describe daemonsets          # All DaemonSets
kubectl describe ds <daemonset-name> # Short form
```

### DaemonSet Status
```bash
# Get DaemonSet status
kubectl get daemonsets -o custom-columns=NAME:.metadata.name,DESIRED:.status.desiredNumberScheduled,CURRENT:.status.currentNumberScheduled,READY:.status.numberReady,UP-TO-DATE:.status.updatedNumberScheduled,AVAILABLE:.status.numberAvailable

# Watch DaemonSet changes
kubectl get daemonsets -w
kubectl get daemonsets -w -o wide

# Get DaemonSet YAML/JSON
kubectl get daemonset <daemonset-name> -o yaml
kubectl get daemonset <daemonset-name> -o json

# Get DaemonSet conditions
kubectl get daemonset <daemonset-name> -o jsonpath='{.status.conditions[*].type}'
```

## DaemonSet Update Commands

### Image Updates
```bash
# Update DaemonSet image
kubectl set image daemonset/<daemonset-name> <container-name>=<new-image>
kubectl set image ds/<daemonset-name> nginx=nginx:1.20

# Update multiple containers
kubectl set image daemonset/<daemonset-name> app=myapp:v2 sidecar=sidecar:v1.1

# Update all containers
kubectl set image daemonset/<daemonset-name> *=<new-image>
```

### Configuration Updates
```bash
# Update environment variables
kubectl set env daemonset/<daemonset-name> ENV=production DEBUG=false
kubectl set env ds/<daemonset-name> --from=configmap/<configmap-name>

# Remove environment variable
kubectl set env daemonset/<daemonset-name> ENV-

# Update resource limits
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"256Mi","cpu":"200m"}}}]}}}}'

# Update labels
kubectl label daemonset <daemonset-name> version=v2 --overwrite

# Update annotations
kubectl annotate daemonset <daemonset-name> description="Updated DaemonSet"
```

### Update Strategy Management
```bash
# Check update strategy
kubectl get daemonset <daemonset-name> -o jsonpath='{.spec.updateStrategy}'

# Set rolling update strategy
kubectl patch daemonset <daemonset-name> -p '{"spec":{"updateStrategy":{"type":"RollingUpdate"}}}'

# Set OnDelete strategy
kubectl patch daemonset <daemonset-name> -p '{"spec":{"updateStrategy":{"type":"OnDelete"}}}'

# Configure maxUnavailable
kubectl patch daemonset <daemonset-name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"maxUnavailable":"25%"}}}}'
kubectl patch daemonset <daemonset-name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"maxUnavailable":2}}}}'
```

## Rollout Management Commands

### Rollout Status and Control
```bash
# Check rollout status
kubectl rollout status daemonset/<daemonset-name>
kubectl rollout status ds/<daemonset-name> --timeout=300s

# Watch rollout progress
kubectl rollout status daemonset/<daemonset-name> -w

# Restart DaemonSet (rolling restart)
kubectl rollout restart daemonset/<daemonset-name>

# Get rollout history (limited compared to Deployments)
kubectl describe daemonset <daemonset-name> | grep -A 10 Events
```

### Manual Pod Management
```bash
# Delete pods to trigger update (with OnDelete strategy)
kubectl delete pods -l <selector>

# Delete specific pod
kubectl delete pod <daemonset-pod-name>

# Force delete pod
kubectl delete pod <daemonset-pod-name> --force --grace-period=0
```

## Pod Management Commands

### Pod Information
```bash
# Get pods for DaemonSet
kubectl get pods -l <selector-labels>
kubectl get pods -l <selector-labels> -o wide

# Get pods by node
kubectl get pods --field-selector=spec.nodeName=<node-name>
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase

# Check pod distribution
kubectl get pods -l <selector> -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c

# Get pod ownership
kubectl get pods -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].name,KIND:.metadata.ownerReferences[0].kind
```

### Pod Operations
```bash
# Get logs from DaemonSet pods
kubectl logs -l <selector>
kubectl logs -l <selector> --all-containers=true
kubectl logs -l <selector> -f

# Execute commands in DaemonSet pods
kubectl exec -it <daemonset-pod-name> -- /bin/bash
kubectl exec <daemonset-pod-name> -- <command>

# Execute on all DaemonSet pods
for pod in $(kubectl get pods -l <selector> -o jsonpath='{.items[*].metadata.name}'); do
  kubectl exec $pod -- <command>
done
```

## Node Management Commands

### Node Information
```bash
# Get nodes and their status
kubectl get nodes
kubectl get nodes -o wide
kubectl get nodes --show-labels

# Check node taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key
kubectl describe node <node-name> | grep -A 5 Taints

# Check node capacity
kubectl describe nodes | grep -A 10 "Capacity\|Allocatable"
kubectl top nodes
```

### Node Scheduling
```bash
# Cordon node (prevent new pods)
kubectl cordon <node-name>

# Uncordon node (allow scheduling)
kubectl uncordon <node-name>

# Drain node (remove pods)
kubectl drain <node-name> --ignore-daemonsets

# Add taint to node
kubectl taint node <node-name> key=value:NoSchedule

# Remove taint from node
kubectl taint node <node-name> key=value:NoSchedule-
```

## Scheduling Configuration Commands

### Tolerations
```bash
# Get current tolerations
kubectl get daemonset <daemonset-name> -o jsonpath='{.spec.template.spec.tolerations[*]}'

# Add toleration for master nodes
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Exists","effect":"NoSchedule"}]}}}}'

# Add toleration for all taints
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"tolerations":[{"operator":"Exists"}]}}}}'

# Add specific toleration
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"special","operator":"Equal","value":"true","effect":"NoSchedule"}]}}}}'
```

### Node Selector
```bash
# Get current node selector
kubectl get daemonset <daemonset-name> -o jsonpath='{.spec.template.spec.nodeSelector}'

# Add node selector
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/os":"linux"}}}}}'

# Remove node selector
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'

# Add multiple node selectors
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/os":"linux","disktype":"ssd"}}}}}'
```

### Affinity Rules
```bash
# Add node affinity
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/arch","operator":"In","values":["amd64"]}]}]}}}}}}}'

# Add pod anti-affinity
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["myapp"]}]},"topologyKey":"kubernetes.io/hostname"}}]}}}}}}'
```

## DaemonSet Deletion Commands

### Safe Deletion
```bash
# Delete DaemonSet
kubectl delete daemonset <daemonset-name>

# Delete DaemonSet but keep pods (orphan pods)
kubectl delete daemonset <daemonset-name> --cascade=orphan

# Delete DaemonSets by label
kubectl delete daemonsets -l app=nginx

# Delete all DaemonSets in namespace
kubectl delete daemonsets --all

# Delete from file
kubectl delete -f daemonset.yaml
```

### Force Deletion
```bash
# Force delete DaemonSet
kubectl delete daemonset <daemonset-name> --force --grace-period=0

# Delete with timeout
kubectl delete daemonset <daemonset-name> --timeout=60s
```

## Debugging Commands

### Status Analysis
```bash
# Check DaemonSet health
kubectl get daemonset <daemonset-name> -o custom-columns=NAME:.metadata.name,DESIRED:.status.desiredNumberScheduled,CURRENT:.status.currentNumberScheduled,READY:.status.numberReady

# Check pod readiness across nodes
kubectl get pods -l <selector> -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,READY:.status.containerStatuses[*].ready,STATUS:.status.phase

# Check resource usage
kubectl top pods -l <selector>
kubectl top pods -l <selector> --containers
```

### Event Analysis
```bash
# Get DaemonSet events
kubectl get events --field-selector involvedObject.kind=DaemonSet
kubectl get events --field-selector involvedObject.name=<daemonset-name>

# Get pod events
kubectl get events --field-selector involvedObject.kind=Pod | grep <daemonset-name>

# Sort events by time
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Scheduling Analysis
```bash
# Check why pods aren't scheduled on certain nodes
kubectl describe node <node-name> | grep -A 10 "Non-terminated Pods"

# Check node conditions
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[?(@.type==\"Ready\")].status

# Check resource constraints
kubectl describe nodes | grep -A 10 "Allocated resources"
```

## Advanced DaemonSet Operations

### Batch Operations
```bash
# Update image for multiple DaemonSets
kubectl set image daemonsets -l environment=production *=myapp:v2

# Get status of all DaemonSets
kubectl get daemonsets -o custom-columns=NAME:.metadata.name,DESIRED:.status.desiredNumberScheduled,READY:.status.numberReady

# Delete multiple DaemonSets
kubectl delete daemonsets -l environment=test

# Scale down all DaemonSets (by adding node selector that matches no nodes)
kubectl patch daemonsets -l app=myapp -p '{"spec":{"template":{"spec":{"nodeSelector":{"nonexistent":"true"}}}}}'
```

### Monitoring Commands
```bash
# Watch DaemonSet and pod status
kubectl get daemonset,pods -l <selector> -w

# Monitor resource usage
watch kubectl top pods -l <selector>

# Monitor node coverage
watch 'kubectl get nodes --no-headers | wc -l; kubectl get pods -l <selector> --no-headers | wc -l'
```

### Integration Commands
```bash
# Get all related resources
kubectl get daemonset,pods,service -l <selector>

# Check services for DaemonSet
kubectl get services -l <selector>

# Check network policies affecting DaemonSet
kubectl get networkpolicy -o yaml | grep -B 5 -A 10 <selector>

# Check pod disruption budgets
kubectl get pdb -l <selector>
```

## DaemonSet Best Practices Commands

### Security Configuration
```bash
# Add security context
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"securityContext":{"runAsUser":1000,"runAsGroup":3000,"fsGroup":2000}}}}}'

# Enable privileged mode (for system DaemonSets)
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","securityContext":{"privileged":true}}]}}}}'

# Add capabilities
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","securityContext":{"capabilities":{"add":["NET_ADMIN","SYS_TIME"]}}}]}}}}'
```

### Resource Management
```bash
# Set resource requests and limits
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"requests":{"memory":"128Mi","cpu":"100m"},"limits":{"memory":"256Mi","cpu":"200m"}}}]}}}}'

# Set priority class for system DaemonSets
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"priorityClassName":"system-node-critical"}}}}'

# Enable host network (for network plugins)
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"hostNetwork":true}}}}'
```

### Health Checks
```bash
# Add liveness probe
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","livenessProbe":{"httpGet":{"path":"/health","port":8080},"initialDelaySeconds":30,"periodSeconds":10}}]}}}}'

# Add readiness probe
kubectl patch daemonset <daemonset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5}}]}}}}'
```
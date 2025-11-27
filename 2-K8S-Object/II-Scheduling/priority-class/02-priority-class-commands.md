# Priority Class Commands Reference

## Priority Class Management

### Create Priority Classes
```bash
# Create high priority class
kubectl create priorityclass high-priority --value=1000000 --description="High priority for critical apps"

# Create low priority class
kubectl create priorityclass low-priority --value=100000 --description="Low priority for batch jobs"

# Create priority class with global default
kubectl create priorityclass default-priority --value=500000 --global-default --description="Default priority class"

# Create from YAML
kubectl apply -f priority-class.yaml
```

### View Priority Classes
```bash
# List all priority classes
kubectl get priorityclasses
kubectl get pc  # Short form

# Show priority class details
kubectl describe priorityclass high-priority

# Get priority class YAML
kubectl get priorityclass high-priority -o yaml

# Sort by priority value
kubectl get priorityclasses --sort-by=.value
```

### Delete Priority Classes
```bash
# Delete specific priority class
kubectl delete priorityclass low-priority

# Delete multiple priority classes
kubectl delete priorityclasses high-priority medium-priority
```

## Pod Priority Management

### Assign Priority to Pods
```bash
# Create pod with priority class
kubectl run high-priority-pod --image=nginx --priority-class-name=high-priority

# Create deployment with priority class
kubectl create deployment critical-app --image=nginx --dry-run=client -o yaml > deployment.yaml
# Edit deployment.yaml to add priorityClassName, then:
kubectl apply -f deployment.yaml
```

### Update Pod Priority
```bash
# Update deployment priority class
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'

# Remove priority class from deployment
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"priorityClassName":null}}}}'
```

### Check Pod Priorities
```bash
# Show pods with their priority classes
kubectl get pods -o custom-columns=NAME:.metadata.name,PRIORITY-CLASS:.spec.priorityClassName,PRIORITY:.spec.priority

# Filter pods by priority class
kubectl get pods --field-selector=spec.priorityClassName=high-priority

# Show pods sorted by priority
kubectl get pods -o json | jq -r '.items | sort_by(.spec.priority // 0) | reverse | .[] | "\(.metadata.name) \(.spec.priority // 0) \(.spec.priorityClassName // "none")"'
```

## Troubleshooting Priority Issues

### Debug Scheduling with Priority
```bash
# Check pod events for priority-related issues
kubectl describe pod <pod-name>

# Check scheduler logs for preemption events
kubectl logs -n kube-system -l component=kube-scheduler | grep -i preempt

# Check cluster events for preemption
kubectl get events --field-selector reason=Preempted

# Check node resource usage
kubectl top nodes
kubectl describe nodes
```

### Monitor Preemption
```bash
# Watch for preemption events
kubectl get events -w --field-selector reason=Preempted

# Check preempted pods
kubectl get pods --field-selector status.phase=Failed,status.reason=Preempted

# Get preemption details
kubectl get events -o json | jq '.items[] | select(.reason == "Preempted") | {pod: .involvedObject.name, message: .message, time: .firstTimestamp}'
```

## Priority Class Validation

### Check Default Priority Class
```bash
# Find global default priority class
kubectl get priorityclasses -o json | jq '.items[] | select(.globalDefault == true) | .metadata.name'

# Check if pod uses default priority
kubectl get pod <pod-name> -o jsonpath='{.spec.priorityClassName}'
```

### Validate Priority Values
```bash
# Check priority class values
kubectl get priorityclasses -o custom-columns=NAME:.metadata.name,VALUE:.value,DEFAULT:.globalDefault

# Compare pod priorities
kubectl get pods -o json | jq -r '.items[] | "\(.metadata.name): \(.spec.priority // 0)"' | sort -k2 -nr
```

## Advanced Priority Operations

### Batch Priority Updates
```bash
# Update all deployments in namespace with priority class
kubectl get deployments -o name | xargs -I {} kubectl patch {} -p '{"spec":{"template":{"spec":{"priorityClassName":"medium-priority"}}}}'

# Update specific app deployments
kubectl patch deployments -l app=web-app -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
```

### Priority-based Resource Management
```bash
# Create resource quota with priority class scope
kubectl create quota high-priority-quota --hard=requests.cpu=4,requests.memory=8Gi --scopes=PriorityClass --scope-selector=priorityClassName=high-priority

# Check quota usage by priority
kubectl describe quota high-priority-quota
```

### Monitor Priority Distribution
```bash
# Count pods by priority class
kubectl get pods -o json | jq -r '.items[].spec.priorityClassName // "none"' | sort | uniq -c

# Show resource usage by priority
kubectl top pods --sort-by=cpu | while read line; do
  pod=$(echo $line | awk '{print $1}')
  if [ "$pod" != "NAME" ]; then
    priority=$(kubectl get pod $pod -o jsonpath='{.spec.priorityClassName}' 2>/dev/null || echo "none")
    echo "$line (Priority: $priority)"
  else
    echo "$line Priority-Class"
  fi
done
```

## Best Practices

### System Priority Classes
```bash
# Built-in system priority classes (read-only)
kubectl get priorityclasses system-cluster-critical system-node-critical

# Values for reference:
# system-cluster-critical: 2000000000
# system-node-critical: 2000001000
```

### Custom Priority Hierarchy
```bash
# Recommended priority values:
# Critical system: 2000000000+
# High priority apps: 1000000
# Medium priority apps: 500000 (default)
# Low priority batch: 100000
# Best effort: 0

# Create hierarchy
kubectl create priorityclass critical --value=2000000 --description="Critical applications"
kubectl create priorityclass high --value=1000000 --description="High priority applications"
kubectl create priorityclass normal --value=500000 --global-default --description="Normal priority"
kubectl create priorityclass low --value=100000 --description="Low priority batch jobs"
kubectl create priorityclass besteffort --value=0 --description="Best effort workloads"
```

### Preemption Control
```bash
# Disable preemption for priority class
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: no-preempt-high
value: 1000000
preemptionPolicy: Never  # Disable preemption
description: "High priority without preemption"

# Enable preemption (default)
preemptionPolicy: PreemptLowerPriority
```

### Resource Quotas with Priority
```bash
# Create quota scoped to priority class
kubectl create quota critical-quota \
  --hard=requests.cpu=8,requests.memory=16Gi,pods=20 \
  --scopes=PriorityClass \
  --scope-selector=priorityClassName=critical

# Create quota for multiple priority classes
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: high-medium-quota
spec:
  hard:
    requests.cpu: "12"
    requests.memory: 24Gi
    pods: "50"
  scopes: ["PriorityClass"]
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values: ["high-priority", "medium-priority"]
EOF
```

### Monitoring and Alerting
```bash
# Create alert for preemption events
kubectl get events --field-selector reason=Preempted -o json | jq '.items | length'

# Monitor priority class usage
kubectl get pods -o json | jq -r '
  .items | 
  group_by(.spec.priorityClassName // "none") | 
  map({
    priorityClass: .[0].spec.priorityClassName // "none",
    count: length,
    totalCPU: map(.spec.containers[].resources.requests.cpu // "0m" | rtrimstr("m") | tonumber) | add,
    totalMemory: map(.spec.containers[].resources.requests.memory // "0Mi" | rtrimstr("Mi") | tonumber) | add
  })
'
```
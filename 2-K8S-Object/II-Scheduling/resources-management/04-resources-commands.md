# Resource Management Commands Reference

## Resource Monitoring Commands

### Check Resource Usage
```bash
# Node resource usage
kubectl top nodes
kubectl top nodes --sort-by=cpu
kubectl top nodes --sort-by=memory

# Pod resource usage
kubectl top pods
kubectl top pods --all-namespaces
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory
kubectl top pods --containers

# Namespace resource usage
kubectl top pods -n production
kubectl top pods -n development
```

### Detailed Resource Information
```bash
# Node capacity and allocatable resources
kubectl describe nodes
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU-CAPACITY:.status.capacity.cpu,MEMORY-CAPACITY:.status.capacity.memory

# Pod resource requests and limits
kubectl describe pod <pod-name>
kubectl get pods -o custom-columns=NAME:.metadata.name,CPU-REQ:.spec.containers[*].resources.requests.cpu,MEM-REQ:.spec.containers[*].resources.requests.memory

# Check resource allocation on nodes
kubectl describe node <node-name> | grep -A 10 "Allocated resources"
```

## Resource Quota Management

### Create Resource Quotas
```bash
# Create basic resource quota
kubectl create quota basic-quota --hard=cpu=4,memory=8Gi,pods=20,services=10

# Create resource quota with storage
kubectl create quota storage-quota --hard=requests.storage=100Gi,persistentvolumeclaims=10

# Create from YAML
kubectl apply -f resource-quota.yaml
```

### View Resource Quotas
```bash
# List resource quotas
kubectl get resourcequota
kubectl get quota  # Short form

# Show quota details
kubectl describe resourcequota <quota-name>
kubectl describe quota

# Check quota usage
kubectl get resourcequota -o custom-columns=NAME:.metadata.name,CPU-USED:.status.used.requests\.cpu,CPU-HARD:.status.hard.requests\.cpu,MEMORY-USED:.status.used.requests\.memory,MEMORY-HARD:.status.hard.requests\.memory
```

### Update Resource Quotas
```bash
# Update quota limits
kubectl patch resourcequota basic-quota -p '{"spec":{"hard":{"cpu":"8","memory":"16Gi"}}}'

# Add new resource to quota
kubectl patch resourcequota basic-quota -p '{"spec":{"hard":{"requests.storage":"200Gi"}}}'
```

## Limit Range Management

### Create Limit Ranges
```bash
# Create from YAML (recommended)
kubectl apply -f limit-range.yaml

# View limit ranges
kubectl get limitrange
kubectl get limits  # Short form

# Show limit range details
kubectl describe limitrange <limitrange-name>
kubectl describe limits
```

### Check Limit Range Effects
```bash
# Check default values applied to pods
kubectl get pod <pod-name> -o yaml | grep -A 10 resources

# Validate pod against limit ranges
kubectl apply -f pod.yaml --dry-run=client
```

## Pod Resource Management

### Update Pod Resources
```bash
# Update deployment resources
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"web-app","resources":{"requests":{"memory":"256Mi","cpu":"200m"},"limits":{"memory":"512Mi","cpu":"400m"}}}]}}}}'

# Scale deployment based on resource availability
kubectl scale deployment web-app --replicas=5

# Update StatefulSet resources
kubectl patch statefulset database -p '{"spec":{"template":{"spec":{"containers":[{"name":"postgres","resources":{"requests":{"memory":"1Gi","cpu":"500m"}}}]}}}}'
```

### Resource Validation
```bash
# Check if pod fits on nodes
kubectl describe pod <pending-pod-name>

# Check node resource availability
kubectl describe node <node-name> | grep -A 10 "Allocatable\|Allocated"

# Check resource conflicts
kubectl get events --field-selector reason=FailedScheduling
```

## Quality of Service (QoS) Management

### Check Pod QoS Classes
```bash
# Show QoS class for pods
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass

# Filter pods by QoS class
kubectl get pods --field-selector status.qosClass=Guaranteed
kubectl get pods --field-selector status.qosClass=Burstable
kubectl get pods --field-selector status.qosClass=BestEffort
```

### QoS Class Rules
```bash
# Guaranteed: requests = limits for all containers
# Burstable: requests < limits or only requests specified
# BestEffort: no requests or limits specified

# Create Guaranteed QoS pod
kubectl run guaranteed-pod --image=nginx --requests='cpu=100m,memory=128Mi' --limits='cpu=100m,memory=128Mi'

# Create Burstable QoS pod
kubectl run burstable-pod --image=nginx --requests='cpu=100m,memory=128Mi' --limits='cpu=200m,memory=256Mi'

# Create BestEffort QoS pod
kubectl run besteffort-pod --image=nginx
```

## Resource Troubleshooting

### Debug Resource Issues
```bash
# Check pod scheduling issues
kubectl get pods --field-selector status.phase=Pending
kubectl describe pod <pending-pod-name>

# Check resource exhaustion
kubectl top nodes
kubectl describe nodes | grep -A 5 "Conditions\|Allocated resources"

# Check resource quota violations
kubectl describe resourcequota
kubectl get events --field-selector reason=ExceededQuota
```

### Node Resource Analysis
```bash
# Check node pressure conditions
kubectl get nodes -o custom-columns=NAME:.metadata.name,MEMORY-PRESSURE:.status.conditions[?(@.type==\"MemoryPressure\")].status,DISK-PRESSURE:.status.conditions[?(@.type==\"DiskPressure\")].status

# Check node allocatable vs capacity
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, capacity: .status.capacity, allocatable: .status.allocatable}'

# Find nodes with available resources
kubectl describe nodes | grep -E "Name:|cpu.*available|memory.*available"
```

## Advanced Resource Operations

### Resource Calculations
```bash
# Calculate total cluster resources
kubectl get nodes -o json | jq '[.items[] | .status.capacity] | {cpu: map(.cpu | rtrimstr("m") | tonumber) | add, memory: map(.memory | rtrimstr("Ki") | tonumber) | add}'

# Calculate resource utilization percentage
kubectl top nodes --no-headers | awk '{print $1, $2, $4}' | while read node cpu memory; do
  capacity_cpu=$(kubectl get node $node -o jsonpath='{.status.capacity.cpu}')
  capacity_memory=$(kubectl get node $node -o jsonpath='{.status.capacity.memory}')
  echo "Node: $node, CPU: $cpu/$capacity_cpu, Memory: $memory/$capacity_memory"
done
```

### Batch Resource Operations
```bash
# Update resources for all deployments in namespace
kubectl get deployments -o name | xargs -I {} kubectl patch {} -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"memory":"128Mi","cpu":"100m"}}}]}}}}'

# Scale all deployments based on resource availability
kubectl get deployments -o name | xargs -I {} kubectl scale {} --replicas=2

# Check resource usage across namespaces
for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
  echo "Namespace: $ns"
  kubectl top pods -n $ns --no-headers 2>/dev/null | awk '{cpu+=$2; memory+=$3} END {print "Total CPU:", cpu "m", "Total Memory:", memory "Mi"}'
  echo "---"
done
```

### Resource Monitoring Scripts
```bash
# Monitor resource usage over time
watch -n 5 'kubectl top nodes; echo ""; kubectl top pods --all-namespaces | head -10'

# Check for resource-constrained pods
kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting?.reason == "CreateContainerConfigError" or .status.phase == "Pending") | "\(.metadata.namespace)/\(.metadata.name): \(.status.phase)"'

# Find pods with high resource usage
kubectl top pods --all-namespaces --sort-by=cpu | head -20
kubectl top pods --all-namespaces --sort-by=memory | head -20
```

## Resource Optimization

### Right-sizing Recommendations
```bash
# Analyze resource usage patterns
kubectl top pods --containers | awk 'NR>1 {print $1, $3, $4}' | sort -k2 -nr

# Find over-provisioned pods
kubectl get pods -o json | jq -r '.items[] | select(.spec.containers[].resources.limits.cpu) | "\(.metadata.name): CPU limit \(.spec.containers[].resources.limits.cpu), Current usage: \(.status.containerStatuses[].usage.cpu // "N/A")"'

# Find under-provisioned pods (those being throttled)
kubectl top pods --containers | awk 'NR>1 && $3 > 80 {print $1 " is using " $3 "% CPU"}'
```

### Resource Cleanup
```bash
# Find and delete completed jobs
kubectl delete jobs --field-selector status.successful=1

# Find pods with high restart counts (potential resource issues)
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount | awk '$3 > 5'

# Clean up evicted pods
kubectl get pods --all-namespaces --field-selector status.phase=Failed -o json | jq '.items[] | select(.status.reason == "Evicted") | "\(.metadata.namespace) \(.metadata.name)"' | xargs -n 2 kubectl delete pod -n
```
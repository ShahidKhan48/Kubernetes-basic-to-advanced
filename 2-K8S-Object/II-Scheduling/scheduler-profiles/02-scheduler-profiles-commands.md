# Scheduler Profiles Commands Reference

## Scheduler Profile Configuration

### View Scheduler Profiles
```bash
# Get scheduler configuration
kubectl get configmap multi-profile-scheduler-config -n kube-system -o yaml

# List all scheduler profiles
kubectl get configmap multi-profile-scheduler-config -n kube-system -o jsonpath='{.data.config\.yaml}' | grep -A 2 "schedulerName:"

# Check active scheduler profiles
kubectl logs -n kube-system -l app=multi-profile-scheduler | grep "profile"
```

### Update Scheduler Profiles
```bash
# Update scheduler profile configuration
kubectl patch configmap multi-profile-scheduler-config -n kube-system --type merge -p '{"data":{"config.yaml":"<updated-config>"}}'

# Restart scheduler to apply changes
kubectl rollout restart deployment multi-profile-scheduler -n kube-system

# Verify profile update
kubectl logs -n kube-system -l app=multi-profile-scheduler | tail -20
```

## Using Different Scheduler Profiles

### Schedule Pods with Specific Profiles
```bash
# Create pod with high-performance scheduler
kubectl run cpu-intensive-pod --image=nginx --scheduler-name=high-performance-scheduler

# Create deployment with GPU scheduler
kubectl create deployment gpu-app --image=tensorflow/tensorflow:latest-gpu --dry-run=client -o yaml | \
  sed 's/spec:/spec:\n      schedulerName: gpu-scheduler/' | \
  kubectl apply -f -

# Create job with batch scheduler
kubectl create job batch-job --image=busybox --dry-run=client -o yaml | \
  sed 's/spec:/spec:\n      schedulerName: batch-scheduler/' | \
  kubectl apply -f -
```

### Check Pod Scheduler Assignment
```bash
# List pods with their schedulers
kubectl get pods -o custom-columns=NAME:.metadata.name,SCHEDULER:.spec.schedulerName,NODE:.spec.nodeName

# Filter pods by scheduler
kubectl get pods --field-selector spec.schedulerName=gpu-scheduler

# Check scheduling events by profile
kubectl get events --field-selector source=gpu-scheduler
```

## Profile Performance Analysis

### Monitor Scheduler Profile Performance
```bash
# Check scheduling latency by profile
kubectl get events --field-selector reason=Scheduled -o custom-columns=OBJECT:.involvedObject.name,SCHEDULER:.source.component,TIME:.firstTimestamp | sort -k3

# Monitor failed scheduling by profile
kubectl get events --field-selector reason=FailedScheduling -o custom-columns=OBJECT:.involvedObject.name,REASON:.message,TIME:.firstTimestamp

# Check resource utilization by scheduler
for scheduler in default-scheduler high-performance-scheduler gpu-scheduler; do
  echo "=== $scheduler ==="
  kubectl get pods --field-selector spec.schedulerName=$scheduler -o json | jq -r '.items[] | "\(.metadata.name): CPU=\(.spec.containers[0].resources.requests.cpu // "none"), Memory=\(.spec.containers[0].resources.requests.memory // "none")"'
done
```

### Profile Effectiveness Analysis
```bash
# Check node resource distribution by scheduler
kubectl get pods -o json | jq -r '.items[] | "\(.spec.schedulerName // "default") \(.spec.nodeName)"' | sort | uniq -c

# Analyze scheduling decisions
kubectl get events --field-selector reason=Scheduled -o json | jq -r '.items[] | "\(.source.component) scheduled \(.involvedObject.name) to \(.message | split(" ")[0])"'

# Check profile-specific plugin execution
kubectl logs -n kube-system -l app=multi-profile-scheduler | grep -E "(high-performance|gpu|memory|batch|spread)-scheduler"
```

## Profile-Specific Troubleshooting

### Debug Profile Issues
```bash
# Check if specific scheduler profile is working
kubectl get pods --field-selector spec.schedulerName=gpu-scheduler,status.phase=Pending

# Debug profile configuration
kubectl get configmap multi-profile-scheduler-config -n kube-system -o jsonpath='{.data.config\.yaml}' | grep -A 20 "schedulerName: gpu-scheduler"

# Check profile-specific logs
kubectl logs -n kube-system -l app=multi-profile-scheduler | grep "gpu-scheduler"

# Validate profile plugin configuration
kubectl logs -n kube-system -l app=multi-profile-scheduler | grep -i "plugin.*error"
```

### Common Profile Issues
```bash
# Profile not found
kubectl get events --field-selector reason=SchedulerNotFound

# Plugin configuration errors
kubectl logs -n kube-system -l app=multi-profile-scheduler | grep -i "plugin.*config"

# Resource scoring issues
kubectl logs -n kube-system -l app=multi-profile-scheduler | grep -i "score.*error"
```

## Advanced Profile Operations

### Dynamic Profile Management
```bash
# Add new scheduler profile
kubectl patch configmap multi-profile-scheduler-config -n kube-system --type merge -p '{
  "data": {
    "config.yaml": "$(kubectl get configmap multi-profile-scheduler-config -n kube-system -o jsonpath='{.data.config\.yaml}' | sed '/profiles:/a\    - schedulerName: new-profile\n      plugins:\n        filter:\n          enabled:\n          - name: NodeResourcesFit')"
  }
}'

# Remove scheduler profile
kubectl get configmap multi-profile-scheduler-config -n kube-system -o yaml > scheduler-config-backup.yaml
# Edit the config to remove profile, then apply
kubectl apply -f scheduler-config-modified.yaml
```

### Profile Plugin Customization
```bash
# Enable specific plugin for profile
kubectl patch configmap multi-profile-scheduler-config -n kube-system --type merge -p '{
  "data": {
    "config.yaml": "# Updated config with new plugin"
  }
}'

# Configure plugin parameters
kubectl get configmap multi-profile-scheduler-config -n kube-system -o yaml | \
  sed 's/type: LeastAllocated/type: MostAllocated/' | \
  kubectl apply -f -
```

## Profile Comparison and Testing

### Compare Profile Behavior
```bash
# Create test pods with different profiles
for profile in default-scheduler high-performance-scheduler gpu-scheduler; do
  kubectl run test-$profile --image=nginx --scheduler-name=$profile --labels="test=profile-comparison"
done

# Compare scheduling results
kubectl get pods -l test=profile-comparison -o custom-columns=NAME:.metadata.name,SCHEDULER:.spec.schedulerName,NODE:.spec.nodeName

# Analyze scheduling time differences
kubectl get events --field-selector reason=Scheduled -o json | jq -r '.items[] | select(.involvedObject.name | startswith("test-")) | "\(.involvedObject.name): \(.firstTimestamp)"'
```

### Load Testing Profiles
```bash
# Create load test for specific profile
for i in {1..20}; do
  kubectl run load-test-$i --image=nginx --scheduler-name=high-performance-scheduler --labels="load-test=true"
done

# Monitor profile performance under load
kubectl get events --field-selector source=high-performance-scheduler | wc -l

# Check scheduling distribution
kubectl get pods -l load-test=true -o json | jq -r '.items[].spec.nodeName' | sort | uniq -c
```

## Profile Monitoring and Metrics

### Scheduler Profile Metrics
```bash
# Enable scheduler metrics (if available)
kubectl port-forward -n kube-system deployment/multi-profile-scheduler 10251:10251

# Get profile-specific metrics
curl http://localhost:10251/metrics | grep scheduler_profile

# Monitor profile queue lengths
curl http://localhost:10251/metrics | grep scheduler_queue_incoming_pods
```

### Profile Health Monitoring
```bash
# Check profile scheduler health
kubectl get pods -n kube-system -l app=multi-profile-scheduler

# Monitor profile scheduling success rate
kubectl get events --field-selector reason=Scheduled | grep -c "high-performance-scheduler"
kubectl get events --field-selector reason=FailedScheduling | grep -c "high-performance-scheduler"

# Check profile resource usage
kubectl top pods -n kube-system -l app=multi-profile-scheduler
```

## Profile Best Practices

### Profile Selection Guidelines
```bash
# CPU-intensive workloads
kubectl patch deployment cpu-app -p '{"spec":{"template":{"spec":{"schedulerName":"high-performance-scheduler"}}}}'

# GPU workloads
kubectl patch deployment ml-training -p '{"spec":{"template":{"spec":{"schedulerName":"gpu-scheduler"}}}}'

# Memory-intensive workloads
kubectl patch statefulset database -p '{"spec":{"template":{"spec":{"schedulerName":"memory-scheduler"}}}}'

# Batch processing
kubectl patch job data-processing -p '{"spec":{"template":{"spec":{"schedulerName":"batch-scheduler"}}}}'

# High availability applications
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"schedulerName":"spread-scheduler"}}}}'
```

### Profile Optimization
```bash
# Analyze current profile usage
kubectl get pods -o json | jq -r '.items[] | .spec.schedulerName // "default"' | sort | uniq -c

# Identify underutilized profiles
kubectl get events --field-selector reason=Scheduled -o json | jq -r '.items[].source.component' | sort | uniq -c

# Optimize profile configurations based on usage patterns
kubectl logs -n kube-system -l app=multi-profile-scheduler | grep -E "scheduling.*took" | sort
```
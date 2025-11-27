# Multiple Scheduler Commands Reference

## Default Scheduler Management

### Check Default Scheduler
```bash
# Check default scheduler pods
kubectl get pods -n kube-system -l component=kube-scheduler

# Check scheduler configuration
kubectl get configmap -n kube-system | grep scheduler

# View scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler
```

## Custom Scheduler Deployment

### Deploy Custom Scheduler
```bash
# Create custom scheduler
kubectl apply -f custom-scheduler.yaml

# Check custom scheduler status
kubectl get pods -n kube-system -l app=custom-scheduler

# View custom scheduler logs
kubectl logs -n kube-system -l app=custom-scheduler
```

### Verify Scheduler Registration
```bash
# Check if scheduler is registered
kubectl get events --field-selector source=custom-scheduler

# Check scheduler leader election
kubectl get lease -n kube-system | grep scheduler

# Check scheduler endpoints
kubectl get endpoints -n kube-system | grep scheduler
```

## Using Custom Schedulers

### Schedule Pods with Custom Scheduler
```bash
# Create pod with custom scheduler
kubectl run test-pod --image=nginx --scheduler-name=custom-scheduler

# Create deployment with custom scheduler
kubectl create deployment web-app --image=nginx --dry-run=client -o yaml | \
  sed 's/spec:/spec:\n      schedulerName: custom-scheduler/' | \
  kubectl apply -f -

# Update existing deployment to use custom scheduler
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"schedulerName":"custom-scheduler"}}}}'
```

### Check Pod Scheduling
```bash
# Check which scheduler scheduled a pod
kubectl get pod <pod-name> -o jsonpath='{.spec.schedulerName}'

# Check pod scheduling events
kubectl describe pod <pod-name> | grep -A 5 Events

# List pods by scheduler
kubectl get pods -o custom-columns=NAME:.metadata.name,SCHEDULER:.spec.schedulerName
```

## Scheduler Configuration

### Update Scheduler Configuration
```bash
# Update scheduler config map
kubectl patch configmap custom-scheduler-config -n kube-system -p '{"data":{"scheduler-config.yaml":"<new-config>"}}'

# Restart scheduler to apply new config
kubectl rollout restart deployment custom-scheduler -n kube-system

# Check config update
kubectl get configmap custom-scheduler-config -n kube-system -o yaml
```

### Scheduler Profiles
```bash
# List scheduler profiles
kubectl get configmap custom-scheduler-config -n kube-system -o jsonpath='{.data.scheduler-config\.yaml}' | grep -A 5 profiles

# Check active scheduler profile
kubectl logs -n kube-system -l app=custom-scheduler | grep profile
```

## Scheduler Monitoring

### Monitor Scheduler Performance
```bash
# Check scheduler metrics (if enabled)
kubectl port-forward -n kube-system deployment/custom-scheduler 10251:10251
curl http://localhost:10251/metrics

# Monitor scheduling latency
kubectl get events --field-selector reason=Scheduled -o custom-columns=OBJECT:.involvedObject.name,SCHEDULER:.source.component,TIME:.firstTimestamp

# Check failed scheduling attempts
kubectl get events --field-selector reason=FailedScheduling
```

### Scheduler Health Check
```bash
# Check scheduler readiness
kubectl get pods -n kube-system -l app=custom-scheduler -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready

# Check scheduler resource usage
kubectl top pods -n kube-system -l app=custom-scheduler

# Check scheduler logs for errors
kubectl logs -n kube-system -l app=custom-scheduler | grep -i error
```

## Troubleshooting Multiple Schedulers

### Debug Scheduling Issues
```bash
# Check if pod is stuck in pending
kubectl get pods --field-selector status.phase=Pending

# Check scheduler assignment
kubectl describe pod <pending-pod> | grep "Scheduled\|scheduler"

# Check scheduler logs for specific pod
kubectl logs -n kube-system -l app=custom-scheduler | grep <pod-name>

# Verify scheduler is running
kubectl get pods -n kube-system | grep scheduler
```

### Common Issues
```bash
# Scheduler not found
kubectl get events --field-selector reason=SchedulerNotFound

# Multiple schedulers conflict
kubectl get lease -n kube-system | grep scheduler

# Scheduler configuration errors
kubectl logs -n kube-system -l app=custom-scheduler | grep -i "config\|error"

# RBAC issues
kubectl auth can-i create pods --as=system:serviceaccount:kube-system:custom-scheduler
```

## Scheduler Comparison

### Compare Scheduler Performance
```bash
# Create test pods with different schedulers
kubectl run default-pod --image=nginx
kubectl run custom-pod --image=nginx --scheduler-name=custom-scheduler

# Compare scheduling times
kubectl get events --field-selector involvedObject.name=default-pod,reason=Scheduled
kubectl get events --field-selector involvedObject.name=custom-pod,reason=Scheduled

# Check pod distribution
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,SCHEDULER:.spec.schedulerName
```

### Scheduler Load Testing
```bash
# Create multiple pods to test scheduler performance
for i in {1..10}; do
  kubectl run test-pod-$i --image=nginx --scheduler-name=custom-scheduler
done

# Monitor scheduling rate
kubectl get events --field-selector reason=Scheduled | grep custom-scheduler | wc -l

# Check scheduler resource usage during load
kubectl top pods -n kube-system -l app=custom-scheduler
```

## Advanced Scheduler Operations

### Scheduler Failover
```bash
# Scale custom scheduler for HA
kubectl scale deployment custom-scheduler --replicas=2 -n kube-system

# Check leader election
kubectl get lease -n kube-system custom-scheduler -o yaml

# Force scheduler failover
kubectl delete pod -n kube-system -l app=custom-scheduler
```

### Scheduler Plugins
```bash
# List available scheduler plugins
kubectl get configmap custom-scheduler-config -n kube-system -o jsonpath='{.data.scheduler-config\.yaml}' | grep -A 20 plugins

# Enable/disable specific plugins
kubectl patch configmap custom-scheduler-config -n kube-system --type merge -p '{"data":{"scheduler-config.yaml":"<updated-config>"}}'

# Check plugin execution
kubectl logs -n kube-system -l app=custom-scheduler | grep plugin
```

### Scheduler Extenders
```bash
# Configure scheduler extender
kubectl patch configmap custom-scheduler-config -n kube-system --type merge -p '{
  "data": {
    "scheduler-config.yaml": "
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
extenders:
- urlPrefix: \"http://extender-service:80\"
  filterVerb: \"filter\"
  prioritizeVerb: \"prioritize\"
  weight: 100
  nodeCacheCapable: false
  ignoredResources: []
  managedResources: []
"
  }
}'
```

## Scheduler Cleanup

### Remove Custom Scheduler
```bash
# Delete custom scheduler deployment
kubectl delete deployment custom-scheduler -n kube-system

# Delete scheduler configuration
kubectl delete configmap custom-scheduler-config -n kube-system

# Delete scheduler RBAC
kubectl delete clusterrolebinding custom-scheduler
kubectl delete serviceaccount custom-scheduler -n kube-system

# Clean up scheduler lease
kubectl delete lease custom-scheduler -n kube-system
```

### Migrate Pods to Different Scheduler
```bash
# Update deployment to use different scheduler
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"schedulerName":"default-scheduler"}}}}'

# Force pod recreation with new scheduler
kubectl rollout restart deployment web-app

# Verify scheduler change
kubectl get pods -l app=web-app -o custom-columns=NAME:.metadata.name,SCHEDULER:.spec.schedulerName
```
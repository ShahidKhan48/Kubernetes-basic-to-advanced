# StatefulSet Commands Reference

## StatefulSet Creation Commands

### Imperative Creation
```bash
# Create basic StatefulSet (limited options)
kubectl create -f statefulset.yaml

# Generate StatefulSet YAML from deployment
kubectl create deployment nginx-deploy --image=nginx --dry-run=client -o yaml | \
  sed 's/Deployment/StatefulSet/g' | \
  sed '/strategy:/,+3d' > statefulset.yaml

# Create from YAML file
kubectl apply -f statefulset.yaml
```

### Declarative Management
```bash
# Apply StatefulSet configuration
kubectl apply -f statefulset.yaml
kubectl apply -f ./statefulsets/

# Validate configuration
kubectl apply -f statefulset.yaml --dry-run=client
kubectl apply -f statefulset.yaml --validate=true

# Show differences
kubectl diff -f statefulset.yaml
```

## StatefulSet Information Commands

### Basic Information
```bash
# List StatefulSets
kubectl get statefulsets
kubectl get sts                      # Short form
kubectl get statefulsets -A          # All namespaces
kubectl get statefulsets -n <namespace>  # Specific namespace
kubectl get statefulsets -o wide     # Extended information
kubectl get statefulsets --show-labels  # Show labels

# Filter StatefulSets
kubectl get statefulsets -l app=mysql
kubectl get statefulsets --field-selector=metadata.name=mysql-sts

# Detailed StatefulSet information
kubectl describe statefulset <statefulset-name>
kubectl describe statefulsets        # All StatefulSets
kubectl describe sts <statefulset-name>  # Short form
```

### StatefulSet Status
```bash
# Get StatefulSet status
kubectl get statefulsets -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,CURRENT:.status.currentReplicas,AGE:.metadata.creationTimestamp

# Watch StatefulSet changes
kubectl get statefulsets -w
kubectl get statefulsets -w -o wide

# Get StatefulSet YAML/JSON
kubectl get statefulset <statefulset-name> -o yaml
kubectl get statefulset <statefulset-name> -o json

# Get StatefulSet conditions
kubectl get statefulset <statefulset-name> -o jsonpath='{.status.conditions[*].type}'
```

## StatefulSet Scaling Commands

### Manual Scaling
```bash
# Scale StatefulSet
kubectl scale statefulset <statefulset-name> --replicas=5
kubectl scale sts <statefulset-name> --replicas=3  # Short form

# Scale to zero (careful with data!)
kubectl scale statefulset <statefulset-name> --replicas=0

# Scale with condition
kubectl scale statefulset <statefulset-name> --current-replicas=3 --replicas=5

# Scale StatefulSets by label
kubectl scale statefulsets -l app=mysql --replicas=2
```

### Scaling Information
```bash
# Check current scale
kubectl get statefulset <statefulset-name> -o jsonpath='{.spec.replicas}'
kubectl get statefulset <statefulset-name> -o jsonpath='{.status.replicas}'

# Monitor scaling
kubectl get statefulset <statefulset-name> -w
kubectl get pods -l <selector> -w --sort-by=.metadata.name
```

## StatefulSet Update Commands

### Rolling Updates
```bash
# Update StatefulSet image
kubectl set image statefulset/<statefulset-name> <container-name>=<new-image>
kubectl set image sts/<statefulset-name> mysql=mysql:8.0

# Update multiple containers
kubectl set image statefulset/<statefulset-name> app=myapp:v2 sidecar=sidecar:v1.1

# Update environment variables
kubectl set env statefulset/<statefulset-name> ENV=production DEBUG=false
kubectl set env sts/<statefulset-name> --from=configmap/<configmap-name>

# Update resource limits
kubectl patch statefulset <statefulset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"1Gi","cpu":"500m"}}}]}}}}'
```

### Update Strategy Management
```bash
# Check update strategy
kubectl get statefulset <statefulset-name> -o jsonpath='{.spec.updateStrategy}'

# Set rolling update strategy
kubectl patch statefulset <statefulset-name> -p '{"spec":{"updateStrategy":{"type":"RollingUpdate"}}}'

# Set OnDelete strategy
kubectl patch statefulset <statefulset-name> -p '{"spec":{"updateStrategy":{"type":"OnDelete"}}}'

# Set partition for controlled rollout
kubectl patch statefulset <statefulset-name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'

# Remove partition (update all pods)
kubectl patch statefulset <statefulset-name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

### Rollout Management
```bash
# Check rollout status
kubectl rollout status statefulset/<statefulset-name>
kubectl rollout status sts/<statefulset-name> --timeout=300s

# Watch rollout progress
kubectl rollout status statefulset/<statefulset-name> -w

# Restart StatefulSet (rolling restart)
kubectl rollout restart statefulset/<statefulset-name>

# Get rollout history (limited compared to Deployments)
kubectl describe statefulset <statefulset-name> | grep -A 10 Events
```

## Pod Management Commands

### Pod Information
```bash
# Get pods for StatefulSet
kubectl get pods -l <selector-labels>
kubectl get pods -l <selector-labels> --sort-by=.metadata.name

# Get pods with ordinal index
kubectl get pods -l <selector-labels> -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase

# Check pod ownership
kubectl get pods -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].name,KIND:.metadata.ownerReferences[0].kind
```

### Individual Pod Operations
```bash
# Delete specific pod (will be recreated)
kubectl delete pod <statefulset-name-0>
kubectl delete pod <statefulset-name-1>

# Force delete pod
kubectl delete pod <statefulset-name-0> --force --grace-period=0

# Get logs from specific pod
kubectl logs <statefulset-name-0>
kubectl logs <statefulset-name-0> -c <container-name>

# Execute commands in specific pod
kubectl exec -it <statefulset-name-0> -- /bin/bash
kubectl exec <statefulset-name-0> -- <command>
```

### Pod Ordering
```bash
# Check pod management policy
kubectl get statefulset <statefulset-name> -o jsonpath='{.spec.podManagementPolicy}'

# Set to OrderedReady (default)
kubectl patch statefulset <statefulset-name> -p '{"spec":{"podManagementPolicy":"OrderedReady"}}'

# Set to Parallel
kubectl patch statefulset <statefulset-name> -p '{"spec":{"podManagementPolicy":"Parallel"}}'

# Monitor pod creation order
kubectl get pods -l <selector> -w --sort-by=.metadata.name
```

## Volume Management Commands

### PVC Information
```bash
# Get PVCs for StatefulSet
kubectl get pvc -l <selector-labels>
kubectl get pvc | grep <statefulset-name>

# Describe specific PVC
kubectl describe pvc <pvc-name>

# Get PVC status
kubectl get pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.status.capacity.storage

# Check PVC usage
kubectl get pvc -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.spec.resources.requests.storage}{"\n"}{end}'
```

### Volume Operations
```bash
# Get volume claim templates
kubectl get statefulset <statefulset-name> -o jsonpath='{.spec.volumeClaimTemplates[*]}'

# Check volume mounts in pods
kubectl describe pod <statefulset-name-0> | grep -A 10 "Mounts"

# List persistent volumes
kubectl get pv
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,STATUS:.status.phase,CLAIM:.spec.claimRef.name
```

### Volume Expansion
```bash
# Check if storage class supports expansion
kubectl get storageclass <storage-class-name> -o jsonpath='{.allowVolumeExpansion}'

# Expand PVC (if supported)
kubectl patch pvc <pvc-name> -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Monitor expansion
kubectl get pvc <pvc-name> -w
```

## Service Management Commands

### Headless Service
```bash
# Get headless service
kubectl get service <headless-service-name>
kubectl describe service <headless-service-name>

# Verify clusterIP is None
kubectl get service <headless-service-name> -o jsonpath='{.spec.clusterIP}'

# Check service selector
kubectl get service <headless-service-name> -o jsonpath='{.spec.selector}'

# Test DNS resolution for individual pods
kubectl run test-pod --image=busybox --rm -it -- nslookup <pod-name>.<service-name>.<namespace>.svc.cluster.local
```

### Service Endpoints
```bash
# Get service endpoints
kubectl get endpoints <service-name>
kubectl describe endpoints <service-name>

# Get endpoint IPs
kubectl get endpoints <service-name> -o jsonpath='{.subsets[*].addresses[*].ip}'

# Check if all pods are in endpoints
kubectl get pods -l <selector> -o jsonpath='{.items[*].status.podIP}'
```

## StatefulSet Deletion Commands

### Safe Deletion
```bash
# Scale down to zero first
kubectl scale statefulset <statefulset-name> --replicas=0

# Wait for pods to terminate
kubectl get pods -l <selector> -w

# Delete StatefulSet (keeps PVCs)
kubectl delete statefulset <statefulset-name>

# Delete StatefulSet and orphan pods
kubectl delete statefulset <statefulset-name> --cascade=orphan
```

### Complete Cleanup
```bash
# Delete StatefulSet
kubectl delete statefulset <statefulset-name>

# Delete associated PVCs (careful - this deletes data!)
kubectl delete pvc -l <selector>

# Delete headless service
kubectl delete service <headless-service-name>

# Delete from file
kubectl delete -f statefulset.yaml
```

### Force Deletion
```bash
# Force delete StatefulSet
kubectl delete statefulset <statefulset-name> --force --grace-period=0

# Force delete stuck pods
kubectl delete pod <statefulset-name-0> --force --grace-period=0

# Delete PVCs with force
kubectl delete pvc <pvc-name> --force --grace-period=0
```

## Debugging Commands

### Status Analysis
```bash
# Check StatefulSet health
kubectl get statefulset <statefulset-name> -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,CURRENT:.status.currentReplicas,UPDATED:.status.updatedReplicas

# Check pod readiness
kubectl get pods -l <selector> -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[*].ready,STATUS:.status.phase

# Check pod distribution
kubectl get pods -l <selector> -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase --sort-by=.metadata.name
```

### Event Analysis
```bash
# Get StatefulSet events
kubectl get events --field-selector involvedObject.kind=StatefulSet
kubectl get events --field-selector involvedObject.name=<statefulset-name>

# Get pod events
kubectl get events --field-selector involvedObject.kind=Pod | grep <statefulset-name>

# Sort events by time
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Resource Analysis
```bash
# Check resource usage
kubectl top pods -l <selector>
kubectl top pods -l <selector> --containers

# Check resource requests/limits
kubectl describe statefulset <statefulset-name> | grep -A 10 "Requests\|Limits"

# Check node capacity
kubectl describe nodes
kubectl top nodes
```

## Advanced StatefulSet Operations

### Backup and Restore
```bash
# Backup StatefulSet configuration
kubectl get statefulset <statefulset-name> -o yaml > statefulset-backup.yaml

# Backup PVC information
kubectl get pvc -l <selector> -o yaml > pvc-backup.yaml

# Create snapshot of volumes (if supported)
kubectl create volumesnapshot <snapshot-name> --volume-snapshot-class=<class> --source-pvc=<pvc-name>
```

### Batch Operations
```bash
# Scale multiple StatefulSets
kubectl scale statefulsets -l environment=production --replicas=3

# Update image for multiple StatefulSets
kubectl set image statefulsets -l app=myapp *=myapp:v2

# Get status of all StatefulSets
kubectl get statefulsets -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,CURRENT:.status.currentReplicas

# Delete multiple StatefulSets
kubectl delete statefulsets -l environment=test
```

### Monitoring Commands
```bash
# Watch StatefulSet and pod status
kubectl get statefulset,pods -l <selector> -w

# Monitor resource usage
watch kubectl top pods -l <selector>

# Monitor PVC usage
kubectl get pvc -l <selector> -w

# Check StatefulSet metrics (if metrics-server is installed)
kubectl top statefulsets
```

### Integration Commands
```bash
# Get all related resources
kubectl get statefulset,pods,pvc,service -l <selector>

# Check HPA for StatefulSet
kubectl get hpa -l <selector>

# Check PDB for StatefulSet
kubectl get pdb -l <selector>

# Get network policies affecting StatefulSet
kubectl get networkpolicy -o yaml | grep -B 5 -A 10 <selector>
```

## StatefulSet Best Practices Commands

### Health Checks
```bash
# Add liveness probe
kubectl patch statefulset <statefulset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","livenessProbe":{"httpGet":{"path":"/health","port":8080},"initialDelaySeconds":30,"periodSeconds":10}}]}}}}'

# Add readiness probe
kubectl patch statefulset <statefulset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5}}]}}}}'
```

### Resource Management
```bash
# Set resource requests and limits
kubectl patch statefulset <statefulset-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"requests":{"memory":"512Mi","cpu":"250m"},"limits":{"memory":"1Gi","cpu":"500m"}}}]}}}}'

# Add node selector
kubectl patch statefulset <statefulset-name> -p '{"spec":{"template":{"spec":{"nodeSelector":{"disktype":"ssd"}}}}}'

# Add pod anti-affinity
kubectl patch statefulset <statefulset-name> -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":[{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["mysql"]}]},"topologyKey":"kubernetes.io/hostname"}]}}}}}}'
```
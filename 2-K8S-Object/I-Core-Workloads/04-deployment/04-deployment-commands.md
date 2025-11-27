# Deployment Commands Reference

## Deployment Creation Commands

### Imperative Creation
```bash
# Create basic deployment
kubectl create deployment nginx-deploy --image=nginx:alpine
kubectl create deployment web-app --image=nginx:alpine --replicas=3

# Create deployment with port
kubectl create deployment api-server --image=myapp:v1 --port=8080

# Create deployment with environment variables
kubectl create deployment app --image=myapp:v1 --env="ENV=prod" --env="DEBUG=false"

# Generate deployment YAML
kubectl create deployment nginx-deploy --image=nginx:alpine --dry-run=client -o yaml > deployment.yaml

# Create from YAML file
kubectl apply -f deployment.yaml
kubectl create -f deployment.yaml
```

### Declarative Management
```bash
# Apply deployment configuration
kubectl apply -f deployment.yaml
kubectl apply -f ./deployments/
kubectl apply -f ./k8s/ -R

# Validate configuration
kubectl apply -f deployment.yaml --dry-run=client
kubectl apply -f deployment.yaml --validate=true

# Show differences
kubectl diff -f deployment.yaml
```

## Deployment Information Commands

### Basic Information
```bash
# List deployments
kubectl get deployments
kubectl get deploy                    # Short form
kubectl get deployments -A           # All namespaces
kubectl get deployments -n <namespace>  # Specific namespace
kubectl get deployments -o wide      # Extended information
kubectl get deployments --show-labels  # Show labels

# Filter deployments
kubectl get deployments -l app=nginx
kubectl get deployments --field-selector=metadata.name=nginx-deploy

# Detailed deployment information
kubectl describe deployment <deployment-name>
kubectl describe deployments         # All deployments
kubectl describe deployments -l app=nginx  # Filtered deployments
```

### Deployment Status
```bash
# Get deployment status
kubectl get deployments -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,UP-TO-DATE:.status.updatedReplicas,AVAILABLE:.status.availableReplicas

# Watch deployment changes
kubectl get deployments -w
kubectl get deployments -w -o wide

# Get deployment YAML/JSON
kubectl get deployment <deployment-name> -o yaml
kubectl get deployment <deployment-name> -o json

# Get deployment conditions
kubectl get deployment <deployment-name> -o jsonpath='{.status.conditions[*].type}'
```

## Deployment Scaling Commands

### Manual Scaling
```bash
# Scale deployment
kubectl scale deployment <deployment-name> --replicas=5
kubectl scale deployment <deployment-name> --replicas=0  # Scale down to 0

# Scale multiple deployments
kubectl scale deployment nginx-deploy web-deploy --replicas=3

# Scale with condition
kubectl scale deployment <deployment-name> --current-replicas=3 --replicas=5

# Scale deployments by label
kubectl scale deployments -l app=nginx --replicas=2
```

### Auto Scaling
```bash
# Create Horizontal Pod Autoscaler
kubectl autoscale deployment <deployment-name> --cpu-percent=50 --min=1 --max=10
kubectl autoscale deployment <deployment-name> --cpu-percent=70 --min=2 --max=20

# Get HPA status
kubectl get hpa
kubectl describe hpa <hpa-name>

# Delete HPA
kubectl delete hpa <hpa-name>
```

## Deployment Update Commands

### Image Updates
```bash
# Update deployment image
kubectl set image deployment/<deployment-name> <container-name>=<new-image>
kubectl set image deployment/nginx-deploy nginx=nginx:1.20

# Update multiple containers
kubectl set image deployment/web-app app=myapp:v2 sidecar=sidecar:v1.1

# Update image for all containers
kubectl set image deployment/<deployment-name> *=<new-image>

# Update with image pull policy
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","image":"<new-image>","imagePullPolicy":"Always"}]}}}}'
```

### Configuration Updates
```bash
# Update environment variables
kubectl set env deployment/<deployment-name> ENV=production DEBUG=false
kubectl set env deployment/<deployment-name> --from=configmap/<configmap-name>
kubectl set env deployment/<deployment-name> --from=secret/<secret-name>

# Remove environment variable
kubectl set env deployment/<deployment-name> ENV-

# Update resource limits
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"512Mi","cpu":"500m"}}}]}}}}'

# Update labels
kubectl label deployment <deployment-name> version=v2 --overwrite
kubectl label deployment <deployment-name> environment=production

# Update annotations
kubectl annotate deployment <deployment-name> description="Updated deployment"
```

## Rollout Management Commands

### Rollout Status and History
```bash
# Check rollout status
kubectl rollout status deployment/<deployment-name>
kubectl rollout status deployment/<deployment-name> --timeout=300s

# Get rollout history
kubectl rollout history deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name> --revision=3

# Watch rollout progress
kubectl rollout status deployment/<deployment-name> -w
```

### Rollout Control
```bash
# Pause rollout
kubectl rollout pause deployment/<deployment-name>

# Resume rollout
kubectl rollout resume deployment/<deployment-name>

# Restart deployment (rolling restart)
kubectl rollout restart deployment/<deployment-name>

# Undo rollout (rollback to previous version)
kubectl rollout undo deployment/<deployment-name>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=2
```

## Pod Management Commands

### Pod Information
```bash
# Get pods for deployment
kubectl get pods -l app=<app-label>
kubectl get pods --show-labels | grep <deployment-name>

# Get ReplicaSets for deployment
kubectl get rs -l app=<app-label>
kubectl get rs --sort-by=.metadata.creationTimestamp

# Check pod distribution across nodes
kubectl get pods -l app=<app-label> -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase
```

### Pod Operations
```bash
# Get logs from deployment pods
kubectl logs -l app=<app-label>
kubectl logs -l app=<app-label> --all-containers=true
kubectl logs -l app=<app-label> -f

# Execute commands in deployment pods
kubectl exec -it deployment/<deployment-name> -- /bin/bash
kubectl exec deployment/<deployment-name> -- <command>

# Port forward to deployment
kubectl port-forward deployment/<deployment-name> 8080:80
```

## Deployment Strategy Commands

### Rolling Update Configuration
```bash
# Update rolling update strategy
kubectl patch deployment <deployment-name> -p '{"spec":{"strategy":{"rollingUpdate":{"maxUnavailable":"25%","maxSurge":"25%"}}}}'

# Set min ready seconds
kubectl patch deployment <deployment-name> -p '{"spec":{"minReadySeconds":30}}'

# Set progress deadline
kubectl patch deployment <deployment-name> -p '{"spec":{"progressDeadlineSeconds":600}}'

# Set revision history limit
kubectl patch deployment <deployment-name> -p '{"spec":{"revisionHistoryLimit":5}}'
```

### Recreate Strategy
```bash
# Change to recreate strategy
kubectl patch deployment <deployment-name> -p '{"spec":{"strategy":{"type":"Recreate"}}}'

# Change back to rolling update
kubectl patch deployment <deployment-name> -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxUnavailable":"25%","maxSurge":"25%"}}}}'
```

## Deployment Deletion Commands

### Delete Deployment
```bash
# Delete deployment and its pods
kubectl delete deployment <deployment-name>

# Delete deployment but keep pods (orphan pods)
kubectl delete deployment <deployment-name> --cascade=orphan

# Delete deployments by label
kubectl delete deployments -l app=nginx

# Delete all deployments in namespace
kubectl delete deployments --all

# Force delete deployment
kubectl delete deployment <deployment-name> --force --grace-period=0
```

### Cleanup Operations
```bash
# Delete deployment and wait for completion
kubectl delete deployment <deployment-name> --wait=true

# Delete with specific timeout
kubectl delete deployment <deployment-name> --timeout=60s

# Delete from file
kubectl delete -f deployment.yaml
```

## Debugging and Troubleshooting Commands

### Status Analysis
```bash
# Check deployment health
kubectl get deployment <deployment-name> -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,UP-TO-DATE:.status.updatedReplicas,AVAILABLE:.status.availableReplicas,AGE:.metadata.creationTimestamp

# Check deployment conditions
kubectl get deployment <deployment-name> -o jsonpath='{.status.conditions[*]}'

# Get deployment events
kubectl get events --field-selector involvedObject.name=<deployment-name>
kubectl get events --field-selector involvedObject.kind=Deployment
```

### Resource Analysis
```bash
# Check resource usage
kubectl top pods -l app=<app-label>
kubectl top pods -l app=<app-label> --containers

# Check resource requests/limits
kubectl describe deployment <deployment-name> | grep -A 10 "Requests\|Limits"

# Check node capacity
kubectl describe nodes
kubectl top nodes
```

### Configuration Validation
```bash
# Validate deployment configuration
kubectl apply -f deployment.yaml --dry-run=client
kubectl apply -f deployment.yaml --validate=true

# Check deployment selector
kubectl get deployment <deployment-name> -o jsonpath='{.spec.selector}'

# Verify pod template
kubectl get deployment <deployment-name> -o yaml | grep -A 50 template
```

## Advanced Deployment Operations

### Batch Operations
```bash
# Scale all deployments with label
kubectl scale deployments -l environment=production --replicas=3

# Update image for all deployments with label
kubectl set image deployments -l app=myapp *=myapp:v2

# Get status of all deployments
kubectl get deployments -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,AVAILABLE:.status.availableReplicas

# Restart all deployments with label
for deploy in $(kubectl get deployments -l app=myapp -o name); do
  kubectl rollout restart $deploy
done
```

### Deployment Comparison
```bash
# Compare two deployment revisions
kubectl rollout history deployment/<deployment-name> --revision=1
kubectl rollout history deployment/<deployment-name> --revision=2

# Export deployment configuration
kubectl get deployment <deployment-name> -o yaml --export > deployment-backup.yaml

# Diff between file and cluster
kubectl diff -f deployment.yaml
```

### Monitoring Commands
```bash
# Watch deployment and pod status
kubectl get deployment,rs,pods -l app=<app> -w

# Monitor rollout progress
kubectl rollout status deployment/<deployment-name> -w

# Monitor resource usage
watch kubectl top pods -l app=<app>

# Monitor events
kubectl get events -w --field-selector involvedObject.kind=Deployment
```

### Integration with Other Resources
```bash
# Get services for deployment
kubectl get services -l app=<app-label>

# Get ingress for deployment
kubectl get ingress -l app=<app-label>

# Get HPA for deployment
kubectl get hpa -l app=<app-label>

# Get PDB for deployment
kubectl get pdb -l app=<app-label>

# Get all related resources
kubectl get all -l app=<app-label>
```

## Deployment Best Practices Commands

### Health Checks
```bash
# Add liveness probe
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","livenessProbe":{"httpGet":{"path":"/health","port":8080},"initialDelaySeconds":30,"periodSeconds":10}}]}}}}'

# Add readiness probe
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","readinessProbe":{"httpGet":{"path":"/ready","port":8080},"initialDelaySeconds":5,"periodSeconds":5}}]}}}}'
```

### Security
```bash
# Add security context
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"securityContext":{"runAsUser":1000,"runAsGroup":3000,"fsGroup":2000}}}}}'

# Add image pull secrets
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"registry-secret"}]}}}}'
```

### Resource Management
```bash
# Set resource requests and limits
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"requests":{"memory":"128Mi","cpu":"100m"},"limits":{"memory":"256Mi","cpu":"200m"}}}]}}}}'

# Add node selector
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/os":"linux"}}}}}'
```
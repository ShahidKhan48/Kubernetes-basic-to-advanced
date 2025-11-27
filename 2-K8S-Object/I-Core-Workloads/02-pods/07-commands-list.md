# Pod Commands Reference

## Pod Creation Commands

### Imperative Pod Creation
```bash
# Basic pod creation
kubectl run nginx-pod --image=nginx:alpine
kubectl run busybox-pod --image=busybox --command -- sleep 3600

# Pod with specific configurations
kubectl run web-pod --image=nginx:alpine --port=80
kubectl run app-pod --image=myapp:v1 --env="ENV=prod" --env="DEBUG=false"
kubectl run limited-pod --image=nginx --requests='cpu=100m,memory=128Mi' --limits='cpu=200m,memory=256Mi'

# Pod with labels and annotations
kubectl run labeled-pod --image=nginx --labels="app=web,version=v1"

# Pod in specific namespace
kubectl run test-pod --image=nginx -n testing

# Pod with restart policy
kubectl run job-pod --image=busybox --restart=Never -- echo "Hello"
kubectl run cronjob-pod --image=busybox --restart=OnFailure -- date

# Generate YAML without creating
kubectl run nginx-pod --image=nginx --dry-run=client -o yaml > pod.yaml
```

### Declarative Pod Management
```bash
# Apply pod configuration
kubectl apply -f pod.yaml
kubectl apply -f ./pods/
kubectl apply -f ./k8s/ -R

# Validate configuration
kubectl apply -f pod.yaml --dry-run=client
kubectl apply -f pod.yaml --validate=true

# Show differences
kubectl diff -f pod.yaml
```

## Pod Information Commands

### Basic Information
```bash
# List pods
kubectl get pods
kubectl get pods -A                    # All namespaces
kubectl get pods -n <namespace>        # Specific namespace
kubectl get pods -o wide              # Extended information
kubectl get pods --show-labels        # Show labels
kubectl get pods -l app=nginx         # Filter by labels
kubectl get pods --field-selector=status.phase=Running

# Detailed pod information
kubectl describe pod <pod-name>
kubectl describe pods                  # All pods
kubectl describe pods -l app=nginx    # Filtered pods

# Pod YAML/JSON output
kubectl get pod <pod-name> -o yaml
kubectl get pod <pod-name> -o json
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

### Pod Status and Events
```bash
# Watch pod status changes
kubectl get pods -w
kubectl get pods -w -o wide

# Get pod events
kubectl get events
kubectl get events --field-selector involvedObject.name=<pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp

# Pod conditions
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CONDITIONS:.status.conditions[*].type
```

## Pod Logs Commands

### Basic Logging
```bash
# Get pod logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f            # Follow logs
kubectl logs <pod-name> --tail=100    # Last 100 lines
kubectl logs <pod-name> --since=1h    # Last hour
kubectl logs <pod-name> --since-time=2023-01-01T00:00:00Z

# Multi-container pod logs
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --all-containers=true

# Previous container logs
kubectl logs <pod-name> --previous
kubectl logs <pod-name> -c <container-name> --previous
```

### Advanced Logging
```bash
# Logs with timestamps
kubectl logs <pod-name> --timestamps

# Logs from multiple pods
kubectl logs -l app=nginx
kubectl logs -l app=nginx --all-containers=true

# Save logs to file
kubectl logs <pod-name> > pod-logs.txt
kubectl logs <pod-name> -f | tee pod-logs.txt
```

## Pod Execution Commands

### Execute Commands in Pods
```bash
# Execute single command
kubectl exec <pod-name> -- <command>
kubectl exec <pod-name> -- ls -la
kubectl exec <pod-name> -- ps aux
kubectl exec <pod-name> -- env

# Interactive shell
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- /bin/sh

# Multi-container pod execution
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash

# Execute with specific user
kubectl exec -it <pod-name> -- su - <username>
```

### File Operations
```bash
# Copy files to/from pod
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp ./local-file <pod-name>:/path/to/file
kubectl cp <pod-name>:/path/to/file ./local-file -c <container-name>

# Copy directories
kubectl cp <pod-name>:/path/to/dir ./local-dir
kubectl cp ./local-dir <pod-name>:/path/to/dir
```

## Pod Networking Commands

### Port Forwarding
```bash
# Forward single port
kubectl port-forward <pod-name> 8080:80
kubectl port-forward <pod-name> 8080:80 --address=0.0.0.0

# Forward multiple ports
kubectl port-forward <pod-name> 8080:80 9090:90

# Forward to service
kubectl port-forward service/<service-name> 8080:80
```

### Network Debugging
```bash
# Test DNS resolution
kubectl exec <pod-name> -- nslookup kubernetes.default
kubectl exec <pod-name> -- dig kubernetes.default.svc.cluster.local

# Test connectivity
kubectl exec <pod-name> -- curl <service-name>
kubectl exec <pod-name> -- wget -qO- <service-name>
kubectl exec <pod-name> -- telnet <service-name> 80

# Check network interfaces
kubectl exec <pod-name> -- ip addr show
kubectl exec <pod-name> -- netstat -tuln
```

## Pod Resource Commands

### Resource Usage
```bash
# Current resource usage
kubectl top pod <pod-name>
kubectl top pods
kubectl top pods -A
kubectl top pods -l app=nginx

# Resource usage with containers
kubectl top pods --containers
kubectl top pods --containers -A
```

### Resource Management
```bash
# Update resource limits
kubectl patch pod <pod-name> -p '{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"512Mi"}}}]}}'

# Scale deployment (affects pods)
kubectl scale deployment <deployment-name> --replicas=3

# Horizontal Pod Autoscaler
kubectl autoscale deployment <deployment-name> --cpu-percent=50 --min=1 --max=10
```

## Pod Lifecycle Commands

### Pod States and Phases
```bash
# Get pod phase
kubectl get pods -o custom-columns=NAME:.metadata.name,PHASE:.status.phase

# Get pod conditions
kubectl get pods -o custom-columns=NAME:.metadata.name,CONDITIONS:.status.conditions[*].type

# Get container states
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[*].state}{"\n"}{end}'
```

### Pod Restart and Deletion
```bash
# Restart pod (delete and recreate)
kubectl delete pod <pod-name>
kubectl rollout restart deployment <deployment-name>

# Force delete pod
kubectl delete pod <pod-name> --force --grace-period=0

# Delete multiple pods
kubectl delete pods -l app=nginx
kubectl delete pods --all
kubectl delete pods --field-selector=status.phase=Failed
```

## Pod Debugging Commands

### Debug Information
```bash
# Debug pod with ephemeral container (K8s 1.23+)
kubectl debug <pod-name> -it --image=busybox
kubectl debug <pod-name> -it --image=busybox --target=<container-name>

# Create debug pod
kubectl run debug-pod --image=busybox --rm -it -- sh

# Debug networking
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- bash
```

### Troubleshooting Commands
```bash
# Check pod readiness
kubectl get pods -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[*].ready

# Check pod restart count
kubectl get pods -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount

# Get pod IP and node
kubectl get pods -o custom-columns=NAME:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName

# Check pod security context
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'
```

## Pod Filtering and Selection

### Label-based Selection
```bash
# Filter by single label
kubectl get pods -l app=nginx
kubectl get pods -l version=v1
kubectl get pods -l environment=production

# Filter by multiple labels
kubectl get pods -l app=nginx,version=v1
kubectl get pods -l 'app in (nginx,apache)'
kubectl get pods -l 'version notin (v1,v2)'

# Filter by label existence
kubectl get pods -l app
kubectl get pods -l '!app'
```

### Field-based Selection
```bash
# Filter by pod phase
kubectl get pods --field-selector=status.phase=Running
kubectl get pods --field-selector=status.phase=Pending
kubectl get pods --field-selector=status.phase=Failed

# Filter by node
kubectl get pods --field-selector=spec.nodeName=<node-name>

# Filter by namespace
kubectl get pods --field-selector=metadata.namespace=default
```

## Batch Operations

### Multiple Pod Operations
```bash
# Delete all pods with label
kubectl delete pods -l app=nginx

# Get logs from multiple pods
kubectl logs -l app=nginx --all-containers=true

# Execute command on multiple pods
for pod in $(kubectl get pods -l app=nginx -o jsonpath='{.items[*].metadata.name}'); do
  kubectl exec $pod -- <command>
done

# Port forward to multiple pods
kubectl get pods -l app=nginx -o name | xargs -I {} kubectl port-forward {} 8080:80
```
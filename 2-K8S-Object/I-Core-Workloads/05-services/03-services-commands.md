# Services Commands Reference

## Service Creation Commands

### Imperative Creation
```bash
# Create ClusterIP service (default)
kubectl expose deployment nginx-deployment --port=80 --target-port=80
kubectl expose pod nginx-pod --port=80 --target-port=80

# Create NodePort service
kubectl expose deployment nginx-deployment --type=NodePort --port=80 --target-port=80
kubectl expose deployment nginx-deployment --type=NodePort --port=80 --target-port=80 --node-port=30080

# Create LoadBalancer service
kubectl expose deployment nginx-deployment --type=LoadBalancer --port=80 --target-port=80

# Create service with specific name
kubectl expose deployment nginx-deployment --port=80 --name=nginx-service

# Create service with labels
kubectl expose deployment nginx-deployment --port=80 --labels="app=nginx,version=v1"

# Generate service YAML
kubectl expose deployment nginx-deployment --port=80 --dry-run=client -o yaml > service.yaml

# Create from YAML
kubectl apply -f service.yaml
kubectl create -f service.yaml
```

### Declarative Management
```bash
# Apply service configuration
kubectl apply -f service.yaml
kubectl apply -f ./services/

# Validate configuration
kubectl apply -f service.yaml --dry-run=client
kubectl apply -f service.yaml --validate=true

# Show differences
kubectl diff -f service.yaml
```

## Service Information Commands

### Basic Information
```bash
# List services
kubectl get services
kubectl get svc                      # Short form
kubectl get services -A              # All namespaces
kubectl get services -n <namespace>  # Specific namespace
kubectl get services -o wide         # Extended information
kubectl get services --show-labels   # Show labels

# Filter services
kubectl get services -l app=nginx
kubectl get services --field-selector=spec.type=LoadBalancer

# Detailed service information
kubectl describe service <service-name>
kubectl describe services            # All services
kubectl describe services -l app=nginx  # Filtered services
```

### Service Status and Details
```bash
# Get service with custom columns
kubectl get services -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip,PORTS:.spec.ports[*].port

# Get service YAML/JSON
kubectl get service <service-name> -o yaml
kubectl get service <service-name> -o json

# Get service endpoints
kubectl get endpoints
kubectl get endpoints <service-name>
kubectl describe endpoints <service-name>

# Watch service changes
kubectl get services -w
kubectl get services -w -o wide
```

## Service Types Commands

### ClusterIP Services
```bash
# Create ClusterIP service
kubectl expose deployment <deployment-name> --port=80 --target-port=8080

# Get ClusterIP
kubectl get service <service-name> -o jsonpath='{.spec.clusterIP}'

# Test ClusterIP service
kubectl run test-pod --image=busybox --rm -it -- wget -qO- <service-name>:<port>
```

### NodePort Services
```bash
# Create NodePort service
kubectl expose deployment <deployment-name> --type=NodePort --port=80 --target-port=8080

# Create with specific NodePort
kubectl expose deployment <deployment-name> --type=NodePort --port=80 --target-port=8080 --node-port=30080

# Get NodePort
kubectl get service <service-name> -o jsonpath='{.spec.ports[0].nodePort}'

# Get node IPs for access
kubectl get nodes -o wide
```

### LoadBalancer Services
```bash
# Create LoadBalancer service
kubectl expose deployment <deployment-name> --type=LoadBalancer --port=80 --target-port=8080

# Get LoadBalancer IP
kubectl get service <service-name> -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
kubectl get service <service-name> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Wait for LoadBalancer IP
kubectl get service <service-name> -w
```

### ExternalName Services
```bash
# Create ExternalName service
kubectl create service externalname <service-name> --external-name=example.com

# Update external name
kubectl patch service <service-name> -p '{"spec":{"externalName":"new-domain.com"}}'
```

## Service Configuration Commands

### Port Management
```bash
# Add port to existing service
kubectl patch service <service-name> -p '{"spec":{"ports":[{"name":"http","port":80,"targetPort":8080},{"name":"https","port":443,"targetPort":8443}]}}'

# Update target port
kubectl patch service <service-name> -p '{"spec":{"ports":[{"port":80,"targetPort":9090}]}}'

# Get service ports
kubectl get service <service-name> -o jsonpath='{.spec.ports[*]}'
```

### Selector Management
```bash
# Update service selector
kubectl patch service <service-name> -p '{"spec":{"selector":{"app":"new-app","version":"v2"}}}'

# Get service selector
kubectl get service <service-name> -o jsonpath='{.spec.selector}'

# Remove selector (for ExternalName or manual endpoints)
kubectl patch service <service-name> -p '{"spec":{"selector":null}}'
```

### Session Affinity
```bash
# Enable session affinity
kubectl patch service <service-name> -p '{"spec":{"sessionAffinity":"ClientIP"}}'

# Configure session affinity timeout
kubectl patch service <service-name> -p '{"spec":{"sessionAffinity":"ClientIP","sessionAffinityConfig":{"clientIP":{"timeoutSeconds":3600}}}}'

# Disable session affinity
kubectl patch service <service-name> -p '{"spec":{"sessionAffinity":"None"}}'
```

## Endpoints Management Commands

### Endpoints Information
```bash
# Get endpoints
kubectl get endpoints
kubectl get endpoints <service-name>
kubectl describe endpoints <service-name>

# Get endpoint IPs
kubectl get endpoints <service-name> -o jsonpath='{.subsets[*].addresses[*].ip}'

# Get endpoint ports
kubectl get endpoints <service-name> -o jsonpath='{.subsets[*].ports[*]}'
```

### Manual Endpoints
```bash
# Create service without selector
kubectl create service clusterip <service-name> --tcp=80:8080

# Create manual endpoints
kubectl create -f - <<EOF
apiVersion: v1
kind: Endpoints
metadata:
  name: <service-name>
subsets:
- addresses:
  - ip: 192.168.1.100
  - ip: 192.168.1.101
  ports:
  - port: 8080
EOF

# Update endpoints
kubectl patch endpoints <service-name> -p '{"subsets":[{"addresses":[{"ip":"192.168.1.200"}],"ports":[{"port":8080}]}]}'
```

## Service Testing Commands

### Connectivity Testing
```bash
# Test service from within cluster
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod:
wget -qO- <service-name>:<port>
nslookup <service-name>
telnet <service-name> <port>

# Test service with curl
kubectl run curl-test --image=curlimages/curl --rm -it -- curl <service-name>:<port>

# Test specific endpoint
kubectl exec <pod-name> -- curl <service-cluster-ip>:<port>
```

### DNS Testing
```bash
# Test DNS resolution
kubectl exec <pod-name> -- nslookup <service-name>
kubectl exec <pod-name> -- nslookup <service-name>.<namespace>.svc.cluster.local

# Test from different namespace
kubectl run test-pod -n other-namespace --image=busybox --rm -it -- nslookup <service-name>.default.svc.cluster.local

# Check DNS configuration
kubectl exec <pod-name> -- cat /etc/resolv.conf
```

### Port Forwarding
```bash
# Forward service port to local machine
kubectl port-forward service/<service-name> 8080:80
kubectl port-forward service/<service-name> 8080:80 --address=0.0.0.0

# Forward multiple ports
kubectl port-forward service/<service-name> 8080:80 9090:90
```

## Service Deletion Commands

### Delete Services
```bash
# Delete service
kubectl delete service <service-name>

# Delete services by label
kubectl delete services -l app=nginx

# Delete all services in namespace
kubectl delete services --all

# Delete from file
kubectl delete -f service.yaml

# Force delete service
kubectl delete service <service-name> --force --grace-period=0
```

## Debugging Commands

### Service Health Check
```bash
# Check service status
kubectl get service <service-name> -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip

# Check service endpoints
kubectl get endpoints <service-name> -o wide

# Verify pod labels match service selector
kubectl get service <service-name> -o jsonpath='{.spec.selector}'
kubectl get pods --show-labels -l <selector>
```

### Network Debugging
```bash
# Check if pods are ready
kubectl get pods -l <service-selector>
kubectl describe pods -l <service-selector>

# Test pod connectivity directly
kubectl get pods -l <service-selector> -o wide
kubectl exec <pod-name> -- curl localhost:<target-port>

# Check network policies
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>
```

### Service Events
```bash
# Get service events
kubectl get events --field-selector involvedObject.kind=Service
kubectl get events --field-selector involvedObject.name=<service-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Advanced Service Operations

### Service Annotations
```bash
# Add annotations (cloud provider specific)
kubectl annotate service <service-name> service.beta.kubernetes.io/aws-load-balancer-type=nlb

# Remove annotation
kubectl annotate service <service-name> service.beta.kubernetes.io/aws-load-balancer-type-

# Get annotations
kubectl get service <service-name> -o jsonpath='{.metadata.annotations}'
```

### Service Labels
```bash
# Add labels
kubectl label service <service-name> environment=production version=v1

# Update labels
kubectl label service <service-name> version=v2 --overwrite

# Remove labels
kubectl label service <service-name> version-

# Get labels
kubectl get service <service-name> --show-labels
```

### Batch Operations
```bash
# Get all services with specific label
kubectl get services -l environment=production

# Delete all services with label
kubectl delete services -l environment=test

# Update all services with label
kubectl label services -l app=myapp version=v2 --overwrite

# Export service configuration
kubectl get service <service-name> -o yaml --export > service-backup.yaml
```

## Service Monitoring Commands

### Resource Usage
```bash
# Monitor service endpoints
kubectl get endpoints -w

# Watch service changes
kubectl get services -w

# Monitor related pods
kubectl get pods -l <service-selector> -w
```

### Service Mesh Integration
```bash
# Istio service mesh
kubectl get virtualservices,destinationrules
istioctl proxy-config cluster <pod-name>

# Linkerd service mesh
linkerd stat services
linkerd routes service/<service-name>
```

### Load Balancer Status
```bash
# Check LoadBalancer status
kubectl get service <service-name> -o jsonpath='{.status.loadBalancer}'

# Wait for LoadBalancer IP
kubectl wait --for=condition=ready service/<service-name> --timeout=300s

# Get LoadBalancer ingress
kubectl get service <service-name> -o jsonpath='{.status.loadBalancer.ingress[*]}'
```

## Service Integration Commands

### With Ingress
```bash
# Get ingress using service
kubectl get ingress -o yaml | grep -A 5 -B 5 <service-name>

# Create ingress for service
kubectl create ingress <ingress-name> --rule="host.com/*=<service-name>:80"
```

### With Deployments
```bash
# Get deployment for service
kubectl get deployment -l <service-selector>

# Scale deployment (affects service endpoints)
kubectl scale deployment <deployment-name> --replicas=5

# Update deployment (affects service endpoints)
kubectl set image deployment/<deployment-name> <container>=<new-image>
```

### Service Discovery
```bash
# List all services and their endpoints
kubectl get services,endpoints

# Get service discovery information
kubectl get services -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORTS:.spec.ports[*].port

# Check DNS entries
kubectl exec <pod-name> -- nslookup kubernetes.default.svc.cluster.local
```
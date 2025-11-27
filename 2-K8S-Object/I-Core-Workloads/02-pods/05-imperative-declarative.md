# Imperative vs Declarative Pod Management

## Imperative Commands (kubectl run)

### Basic Pod Creation
```bash
# Create a simple pod
kubectl run nginx-pod --image=nginx:alpine

# Create pod with port
kubectl run web-pod --image=nginx:alpine --port=80

# Create pod with resource limits
kubectl run limited-pod --image=nginx:alpine --requests='cpu=100m,memory=128Mi' --limits='cpu=200m,memory=256Mi'

# Create pod with environment variables
kubectl run env-pod --image=nginx:alpine --env="ENV=production" --env="DEBUG=false"

# Create pod with labels
kubectl run labeled-pod --image=nginx:alpine --labels="app=web,version=v1"

# Create pod and expose as service
kubectl run web-pod --image=nginx:alpine --port=80 --expose

# Create pod with command override
kubectl run busybox-pod --image=busybox --command -- sleep 3600

# Create pod in specific namespace
kubectl run test-pod --image=nginx:alpine -n testing

# Create pod with restart policy
kubectl run job-pod --image=busybox --restart=Never -- echo "Hello World"

# Create pod with dry-run (generate YAML)
kubectl run nginx-pod --image=nginx:alpine --dry-run=client -o yaml > pod.yaml
```

### Pod Management Commands
```bash
# Get pod information
kubectl get pods
kubectl get pods -o wide
kubectl get pods --show-labels
kubectl get pods -l app=nginx

# Describe pod
kubectl describe pod nginx-pod

# Get pod logs
kubectl logs nginx-pod
kubectl logs nginx-pod -f  # follow logs
kubectl logs nginx-pod --previous  # previous container logs

# Execute commands in pod
kubectl exec nginx-pod -- ls -la
kubectl exec -it nginx-pod -- /bin/sh

# Port forwarding
kubectl port-forward nginx-pod 8080:80

# Copy files
kubectl cp nginx-pod:/etc/nginx/nginx.conf ./nginx.conf
kubectl cp ./index.html nginx-pod:/usr/share/nginx/html/

# Delete pod
kubectl delete pod nginx-pod
kubectl delete pods --all
```

## Declarative Approach (YAML Manifests)

### Advantages of Declarative
- Version control friendly
- Reproducible deployments
- Infrastructure as Code
- Better for production environments
- Supports complex configurations

### Basic Declarative Workflow
```bash
# Apply configuration
kubectl apply -f pod.yaml

# Apply multiple files
kubectl apply -f ./manifests/

# Apply with recursive directory
kubectl apply -f ./k8s/ -R

# Validate without applying
kubectl apply -f pod.yaml --dry-run=client

# Show differences
kubectl diff -f pod.yaml

# Delete using manifest
kubectl delete -f pod.yaml
```

### Imperative vs Declarative Comparison

| Aspect | Imperative | Declarative |
|--------|------------|-------------|
| **Approach** | Tell what to do | Describe desired state |
| **Commands** | kubectl run, create, delete | kubectl apply |
| **Version Control** | Difficult | Easy |
| **Reproducibility** | Manual recreation | Automated |
| **Complexity** | Simple operations | Complex configurations |
| **Production Use** | Quick testing | Recommended |
| **Rollback** | Manual | Git-based |
| **Documentation** | Command history | YAML files |

### Best Practices

#### Use Imperative for:
- Quick testing and debugging
- One-time operations
- Learning and experimentation
- Emergency fixes

#### Use Declarative for:
- Production deployments
- CI/CD pipelines
- Infrastructure as Code
- Team collaboration
- Complex configurations

### Hybrid Approach
```bash
# Generate YAML with imperative, then use declaratively
kubectl run nginx-pod --image=nginx:alpine --dry-run=client -o yaml > nginx-pod.yaml

# Edit the generated YAML
vim nginx-pod.yaml

# Apply declaratively
kubectl apply -f nginx-pod.yaml
```
# Namespace Commands Reference

## Namespace Creation Commands

### Imperative Creation
```bash
# Create basic namespace
kubectl create namespace development
kubectl create ns production  # Short form

# Create namespace with labels
kubectl create namespace testing --labels="environment=test,team=qa"

# Generate namespace YAML
kubectl create namespace staging --dry-run=client -o yaml > namespace.yaml

# Create from YAML
kubectl apply -f namespace.yaml
kubectl create -f namespace.yaml
```

### Declarative Management
```bash
# Apply namespace configuration
kubectl apply -f namespace.yaml
kubectl apply -f ./namespaces/

# Validate configuration
kubectl apply -f namespace.yaml --dry-run=client
kubectl apply -f namespace.yaml --validate=true

# Show differences
kubectl diff -f namespace.yaml
```

## Namespace Information Commands

### Basic Information
```bash
# List namespaces
kubectl get namespaces
kubectl get ns                    # Short form
kubectl get namespaces --show-labels
kubectl get namespaces -o wide

# Filter namespaces
kubectl get namespaces -l environment=production
kubectl get namespaces --field-selector=status.phase=Active

# Detailed namespace information
kubectl describe namespace <namespace-name>
kubectl describe namespaces       # All namespaces
kubectl describe ns <namespace-name>  # Short form
```

### Namespace Status
```bash
# Get namespace status
kubectl get namespace <namespace-name> -o jsonpath='{.status.phase}'

# Get namespace with custom columns
kubectl get namespaces -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,AGE:.metadata.creationTimestamp

# Get namespace YAML/JSON
kubectl get namespace <namespace-name> -o yaml
kubectl get namespace <namespace-name> -o json

# Watch namespace changes
kubectl get namespaces -w
```

## Working with Namespace Context

### Context Management
```bash
# Get current namespace context
kubectl config view --minify | grep namespace

# Set default namespace for current context
kubectl config set-context --current --namespace=<namespace-name>

# Create new context with specific namespace
kubectl config set-context <context-name> --cluster=<cluster> --user=<user> --namespace=<namespace>

# Switch context
kubectl config use-context <context-name>

# View all contexts
kubectl config get-contexts
```

### Namespace-Specific Operations
```bash
# Run commands in specific namespace
kubectl get pods -n <namespace-name>
kubectl get all -n <namespace-name>

# Run commands in all namespaces
kubectl get pods -A
kubectl get all -A

# Set namespace for current session (if kubens is installed)
kubens <namespace-name>
kubens -                          # Switch to previous namespace
kubens                           # List all namespaces
```

## Resource Management in Namespaces

### Resource Quotas
```bash
# Create resource quota
kubectl create quota <quota-name> -n <namespace> --hard=cpu=2,memory=4Gi,pods=10

# Get resource quotas
kubectl get resourcequota -n <namespace>
kubectl get quota -n <namespace>  # Short form

# Describe resource quota
kubectl describe resourcequota <quota-name> -n <namespace>
kubectl describe quota -n <namespace>

# Update resource quota
kubectl patch resourcequota <quota-name> -n <namespace> -p '{"spec":{"hard":{"cpu":"4","memory":"8Gi"}}}'

# Delete resource quota
kubectl delete resourcequota <quota-name> -n <namespace>
```

### Limit Ranges
```bash
# Get limit ranges
kubectl get limitrange -n <namespace>
kubectl get limits -n <namespace>  # Short form

# Describe limit range
kubectl describe limitrange <limitrange-name> -n <namespace>
kubectl describe limits -n <namespace>

# Delete limit range
kubectl delete limitrange <limitrange-name> -n <namespace>
```

### Resource Usage
```bash
# Check resource usage in namespace
kubectl top pods -n <namespace>
kubectl top nodes

# Get resource usage summary
kubectl describe resourcequota -n <namespace>

# List all resources in namespace
kubectl get all -n <namespace>
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
```

## Namespace Security Commands

### Network Policies
```bash
# Get network policies
kubectl get networkpolicies -n <namespace>
kubectl get netpol -n <namespace>  # Short form

# Describe network policy
kubectl describe networkpolicy <policy-name> -n <namespace>

# Create simple network policy
kubectl create -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: <namespace>
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Delete network policy
kubectl delete networkpolicy <policy-name> -n <namespace>
```

### RBAC in Namespaces
```bash
# Get role bindings in namespace
kubectl get rolebindings -n <namespace>
kubectl get rolebinding -n <namespace>  # Short form

# Describe role binding
kubectl describe rolebinding <binding-name> -n <namespace>

# Create role in namespace
kubectl create role <role-name> -n <namespace> --verb=get,list,watch --resource=pods

# Create role binding
kubectl create rolebinding <binding-name> -n <namespace> --role=<role-name> --user=<username>

# Check permissions in namespace
kubectl auth can-i get pods -n <namespace>
kubectl auth can-i --list -n <namespace>

# Check permissions for specific user
kubectl auth can-i get pods -n <namespace> --as=<username>
```

## Namespace Deletion Commands

### Safe Deletion
```bash
# Delete namespace (this deletes all resources in it)
kubectl delete namespace <namespace-name>

# Delete namespace with confirmation
kubectl delete namespace <namespace-name> --wait=true

# Delete namespace with timeout
kubectl delete namespace <namespace-name> --timeout=300s

# Delete from file
kubectl delete -f namespace.yaml
```

### Force Deletion
```bash
# Force delete namespace
kubectl delete namespace <namespace-name> --force --grace-period=0

# Delete stuck namespace by removing finalizers
kubectl patch namespace <namespace-name> -p '{"metadata":{"finalizers":[]}}' --type=merge

# Delete all resources in namespace first
kubectl delete all --all -n <namespace-name>
```

## Debugging Commands

### Namespace Status Check
```bash
# Check namespace phase
kubectl get namespace <namespace-name> -o jsonpath='{.status.phase}'

# Check for stuck namespaces
kubectl get namespaces | grep Terminating

# Get namespace events
kubectl get events -n <namespace-name>
kubectl get events --field-selector involvedObject.namespace=<namespace-name>
```

### Resource Analysis
```bash
# Count resources in namespace
kubectl get all -n <namespace> --no-headers | wc -l

# Get resource types and counts
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 sh -c 'echo "$1: $(kubectl get "$1" -n <namespace> --no-headers 2>/dev/null | wc -l)"' --

# Find resource-heavy pods
kubectl top pods -n <namespace> --sort-by=cpu
kubectl top pods -n <namespace> --sort-by=memory

# Check for failed resources
kubectl get pods -n <namespace> --field-selector=status.phase=Failed
kubectl get jobs -n <namespace> --field-selector=status.successful!=1
```

### Troubleshooting Stuck Namespaces
```bash
# List all resources preventing namespace deletion
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>

# Check for finalizers
kubectl get namespace <namespace> -o yaml | grep -A 10 finalizers

# Force delete specific resources
kubectl delete <resource-type> <resource-name> -n <namespace> --force --grace-period=0

# Patch out finalizers (use with extreme caution)
kubectl patch <resource-type> <resource-name> -n <namespace> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

## Batch Operations

### Multiple Namespace Operations
```bash
# Create multiple namespaces
for ns in dev staging prod; do kubectl create namespace $ns; done

# Apply labels to multiple namespaces
kubectl label namespaces dev staging environment=non-prod

# Get resources from multiple namespaces
kubectl get pods -n dev,staging,prod

# Delete multiple namespaces
kubectl delete namespaces dev staging test
```

### Resource Management Across Namespaces
```bash
# Get all pods across namespaces
kubectl get pods -A

# Get specific resource type across namespaces
kubectl get deployments -A
kubectl get services -A

# Filter resources across namespaces
kubectl get pods -A -l app=nginx
kubectl get services -A --field-selector=spec.type=LoadBalancer
```

## Namespace Utilities

### Namespace Switching (with kubens)
```bash
# Install kubens (part of kubectx)
# macOS: brew install kubectx
# Linux: Download from GitHub releases

# List namespaces
kubens

# Switch to namespace
kubens <namespace-name>

# Switch to previous namespace
kubens -

# Get current namespace
kubens -c
```

### Namespace Information Scripts
```bash
# Get namespace resource summary
kubectl get namespaces -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,AGE:.metadata.creationTimestamp

# Count pods per namespace
kubectl get pods -A --no-headers | awk '{print $1}' | sort | uniq -c

# Get resource quotas summary
kubectl get resourcequota -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CPU-REQUESTS:.status.used.requests\.cpu,MEMORY-REQUESTS:.status.used.requests\.memory
```

## Advanced Namespace Operations

### Namespace Templates
```bash
# Create namespace template
cat > namespace-template.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: NAMESPACE_NAME
  labels:
    environment: ENVIRONMENT
    team: TEAM_NAME
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: NAMESPACE_NAME-quota
  namespace: NAMESPACE_NAME
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "10"
EOF

# Use template to create namespace
sed 's/NAMESPACE_NAME/development/g; s/ENVIRONMENT/dev/g; s/TEAM_NAME/backend/g' namespace-template.yaml | kubectl apply -f -
```

### Namespace Backup and Restore
```bash
# Backup namespace configuration
kubectl get namespace <namespace> -o yaml > namespace-backup.yaml

# Backup all resources in namespace
kubectl get all -n <namespace> -o yaml > namespace-resources-backup.yaml

# Restore namespace
kubectl apply -f namespace-backup.yaml
kubectl apply -f namespace-resources-backup.yaml
```

### Monitoring Namespaces
```bash
# Watch namespace resource usage
watch kubectl top pods -n <namespace>

# Monitor namespace events
kubectl get events -n <namespace> -w

# Check namespace health
kubectl get all -n <namespace>
kubectl describe resourcequota -n <namespace>
kubectl describe limitrange -n <namespace>
```
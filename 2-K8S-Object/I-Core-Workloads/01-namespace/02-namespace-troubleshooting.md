# Namespace Troubleshooting Guide

## Common Namespace Issues

### 1. Resource Quota Exceeded

#### Symptoms
```bash
kubectl get pods -n production
# Error creating pods: "exceeded quota"

kubectl describe resourcequota -n production
# Shows usage vs limits
```

#### Troubleshooting Steps
```bash
# Check current resource usage
kubectl describe resourcequota -n production
kubectl top pods -n production
kubectl top nodes

# Check resource requests in pods
kubectl describe pods -n production | grep -A 5 "Requests"

# List all resources in namespace
kubectl get all -n production
kubectl get pvc,secrets,configmaps -n production
```

#### Solutions
```bash
# Increase resource quota
kubectl patch resourcequota production-quota -n production -p '{"spec":{"hard":{"requests.cpu":"8","requests.memory":"16Gi"}}}'

# Delete unused resources
kubectl delete pods -n production --field-selector=status.phase=Succeeded
kubectl delete pods -n production --field-selector=status.phase=Failed

# Optimize resource requests
kubectl patch deployment <deployment-name> -n production -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"cpu":"50m","memory":"64Mi"}}}]}}}}'
```

### 2. Namespace Stuck in Terminating State

#### Symptoms
```bash
kubectl get namespaces
NAME          STATUS        AGE
old-project   Terminating   30m
```

#### Troubleshooting
```bash
# Check what resources are preventing deletion
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n old-project

# Check finalizers
kubectl get namespace old-project -o yaml | grep -A 10 finalizers

# Check for stuck resources
kubectl get all -n old-project
kubectl get pvc,secrets,configmaps -n old-project
```

#### Solutions
```bash
# Force delete remaining resources
kubectl delete all --all -n old-project --force --grace-period=0

# Remove finalizers (use with caution)
kubectl patch namespace old-project -p '{"metadata":{"finalizers":[]}}' --type=merge

# Delete specific stuck resources
kubectl delete <resource-type> <resource-name> -n old-project --force --grace-period=0
```

### 3. Cross-Namespace Communication Issues

#### Symptoms
```bash
# Service in namespace A cannot reach service in namespace B
kubectl exec pod-a -n namespace-a -- curl service-b.namespace-b.svc.cluster.local
# Connection timeout or refused
```

#### Troubleshooting
```bash
# Check network policies
kubectl get networkpolicies -n namespace-a
kubectl get networkpolicies -n namespace-b
kubectl describe networkpolicy <policy-name> -n <namespace>

# Test DNS resolution
kubectl exec pod-a -n namespace-a -- nslookup service-b.namespace-b.svc.cluster.local

# Check service endpoints
kubectl get endpoints service-b -n namespace-b

# Test without network policies (temporarily)
kubectl delete networkpolicy <policy-name> -n <namespace>
```

#### Solutions
```bash
# Allow cross-namespace communication
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-cross-namespace
  namespace: namespace-b
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: namespace-a
EOF
```

### 4. RBAC Permission Issues

#### Symptoms
```bash
kubectl get pods -n restricted-namespace
# Error: User cannot list pods in namespace "restricted-namespace"
```

#### Troubleshooting
```bash
# Check current user permissions
kubectl auth can-i get pods -n restricted-namespace
kubectl auth can-i --list -n restricted-namespace

# Check role bindings
kubectl get rolebindings -n restricted-namespace
kubectl get clusterrolebindings | grep <username>

# Describe role bindings
kubectl describe rolebinding <binding-name> -n restricted-namespace
```

#### Solutions
```bash
# Create role and role binding
kubectl create role pod-reader -n restricted-namespace --verb=get,list,watch --resource=pods
kubectl create rolebinding pod-reader-binding -n restricted-namespace --role=pod-reader --user=<username>

# Or use cluster role
kubectl create clusterrolebinding namespace-admin --clusterrole=admin --user=<username> --namespace=restricted-namespace
```

### 5. Limit Range Violations

#### Symptoms
```bash
kubectl apply -f pod.yaml -n production
# Error: Pod exceeds limit range
```

#### Troubleshooting
```bash
# Check limit ranges
kubectl get limitrange -n production
kubectl describe limitrange -n production

# Check pod resource specifications
kubectl describe pod <pod-name> -n production | grep -A 10 "Requests\|Limits"
```

#### Solutions
```bash
# Adjust pod resources to fit limit range
kubectl patch deployment <deployment-name> -n production -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}}}'

# Or adjust limit range
kubectl patch limitrange production-limits -n production -p '{"spec":{"limits":[{"default":{"cpu":"1","memory":"1Gi"},"defaultRequest":{"cpu":"100m","memory":"128Mi"},"type":"Container"}]}}'
```

## Debugging Commands

### Namespace Information
```bash
# List all namespaces
kubectl get namespaces
kubectl get ns --show-labels

# Describe namespace
kubectl describe namespace <namespace-name>

# Get namespace YAML
kubectl get namespace <namespace-name> -o yaml

# Check namespace status
kubectl get namespace <namespace-name> -o jsonpath='{.status.phase}'
```

### Resource Usage Analysis
```bash
# Check resource quotas
kubectl get resourcequota -n <namespace>
kubectl describe resourcequota -n <namespace>

# Check limit ranges
kubectl get limitrange -n <namespace>
kubectl describe limitrange -n <namespace>

# Get resource usage
kubectl top pods -n <namespace>
kubectl top nodes

# List all resources in namespace
kubectl get all -n <namespace>
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
```

### Network Policy Analysis
```bash
# Check network policies
kubectl get networkpolicies -n <namespace>
kubectl describe networkpolicy <policy-name> -n <namespace>

# Test network connectivity
kubectl run test-pod -n <namespace> --image=busybox --rm -it -- sh
# Inside pod: wget -qO- <service>.<target-namespace>.svc.cluster.local
```

### RBAC Analysis
```bash
# Check permissions for namespace
kubectl auth can-i --list -n <namespace>
kubectl auth can-i get pods -n <namespace>

# Check role bindings
kubectl get rolebindings -n <namespace>
kubectl get clusterrolebindings | grep <namespace>

# Describe bindings
kubectl describe rolebinding <binding-name> -n <namespace>
```

## Common Error Messages

### "Exceeded quota"
```bash
# Check quota usage
kubectl describe resourcequota -n <namespace>

# Find resource-heavy pods
kubectl top pods -n <namespace> --sort-by=cpu
kubectl top pods -n <namespace> --sort-by=memory

# Solution: Increase quota or reduce usage
kubectl patch resourcequota <quota-name> -n <namespace> -p '{"spec":{"hard":{"requests.cpu":"4"}}}'
```

### "Namespace is terminating"
```bash
# Check for stuck resources
kubectl get all -n <namespace>
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>

# Force delete stuck resources
kubectl delete <resource-type> <resource-name> -n <namespace> --force --grace-period=0
```

### "Forbidden: User cannot access namespace"
```bash
# Check RBAC permissions
kubectl auth can-i get pods -n <namespace>
kubectl get rolebindings,clusterrolebindings -A | grep <username>

# Create appropriate role binding
kubectl create rolebinding <binding-name> -n <namespace> --clusterrole=view --user=<username>
```

## Best Practices for Troubleshooting

### 1. Check Resource Constraints First
```bash
kubectl describe resourcequota -n <namespace>
kubectl describe limitrange -n <namespace>
kubectl top pods -n <namespace>
```

### 2. Verify Network Policies
```bash
kubectl get networkpolicies -n <namespace>
kubectl describe networkpolicy <policy-name> -n <namespace>
```

### 3. Test Cross-Namespace Communication
```bash
# From source namespace
kubectl run test-pod -n source-ns --image=busybox --rm -it -- nslookup service.target-ns.svc.cluster.local
```

### 4. Check RBAC Permissions
```bash
kubectl auth can-i --list -n <namespace>
kubectl get rolebindings -n <namespace>
```

### 5. Monitor Namespace Events
```bash
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector involvedObject.namespace=<namespace>
```

### 6. Use Namespace Context
```bash
# Set default namespace context
kubectl config set-context --current --namespace=<namespace>

# Or use kubens (if installed)
kubens <namespace>
```

### 7. Clean Up Regularly
```bash
# Delete completed jobs
kubectl delete jobs -n <namespace> --field-selector=status.successful=1

# Delete failed pods
kubectl delete pods -n <namespace> --field-selector=status.phase=Failed

# Delete evicted pods
kubectl delete pods -n <namespace> --field-selector=status.phase=Failed
```
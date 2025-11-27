# Kyverno

## 📚 Overview
YAML-based policy engine for Kubernetes validation, mutation, and generation.

## 🎯 Installation
```bash
# Install Kyverno
kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml

# Verify installation
kubectl get pods -n kyverno
```

## 📖 Policy Examples

### Require Labels Policy
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: enforce
  background: true
  rules:
  - name: check-labels
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Required labels missing"
      pattern:
        metadata:
          labels:
            app: "?*"
            version: "?*"
```

### Image Security Policy
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: image-security
spec:
  validationFailureAction: enforce
  rules:
  - name: require-image-tag
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Images must have specific tags (not latest)"
      pattern:
        spec:
          containers:
          - image: "!*:latest"
  
  - name: trusted-registries
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Images must come from trusted registries"
      anyPattern:
      - spec:
          containers:
          - image: "spicybiryaniwala.shop/*"
      - spec:
          containers:
          - image: "gcr.io/spicybiryaniwala/*"
```

### Security Context Mutation
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-security-context
spec:
  rules:
  - name: add-security-context
    match:
      any:
      - resources:
          kinds:
          - Pod
    mutate:
      patchStrategicMerge:
        spec:
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
          containers:
          - (name): "*"
            securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
```

### Generate NetworkPolicy
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-network-policy
spec:
  rules:
  - name: generate-netpol
    match:
      any:
      - resources:
          kinds:
          - Namespace
    generate:
      kind: NetworkPolicy
      name: default-deny-all
      namespace: "{{request.object.metadata.name}}"
      data:
        spec:
          podSelector: {}
          policyTypes:
          - Ingress
          - Egress
```

## 🔧 Management Commands
```bash
# List policies
kubectl get clusterpolicies
kubectl get policies --all-namespaces

# Check policy status
kubectl describe clusterpolicy require-labels

# View policy violations
kubectl get events --field-selector reason=PolicyViolation
```

## 🛠️ Testing
```bash
# Test with dry-run
kubectl apply --dry-run=server -f test-pod.yaml

# Check policy reports
kubectl get policyreports --all-namespaces
kubectl get clusterpolicyreports
```

## 📋 Best Practices
- Start with warn mode
- Test policies in development
- Use background scanning
- Monitor policy performance
- Implement policy exceptions when needed
# Admission Control

## 📚 Overview
Kubernetes admission controllers for policy enforcement aur resource validation.

## 📖 Components

### 1. [Pod Security Standards (PSS)](./pss/)
Built-in security policies (privileged, baseline, restricted)

### 2. [Pod Security Admission (PSA)](./psa/)
Namespace-level security policy enforcement

### 3. [OPA Gatekeeper](./opa-gatekeeper/)
Policy as code using Rego language

### 4. [Kyverno](./kyverno/)
YAML-based policy engine for validation aur mutation

### 5. [Webhooks](./webhooks/)
- [Validating Webhooks](./webhooks/validating/) - Custom validation logic
- [Mutating Webhooks](./webhooks/mutating/) - Resource modification

## 🎯 Admission Flow
```
API Request → Mutating Admission → Validating Admission → Persist to etcd
```

## 🔧 Quick Commands
```bash
# Check admission controllers
kubectl get validatingadmissionwebhooks
kubectl get mutatingadmissionwebhooks

# Test with dry-run
kubectl apply --dry-run=server -f pod.yaml

# Check PSA labels
kubectl get namespaces -o custom-columns=NAME:.metadata.name,ENFORCE:.metadata.labels.'pod-security\.kubernetes\.io/enforce'
```

## 📋 Best Practices
- Start with warn mode
- Test policies thoroughly
- Monitor violations
- Clear error messages
# OPA Gatekeeper

## 📚 Overview
Open Policy Agent (OPA) Gatekeeper for policy-as-code enforcement.

## 🎯 Installation
```bash
# Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# Verify installation
kubectl get pods -n gatekeeper-system
```

## 📖 Policy Examples

### Required Labels Template
```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        
        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("Missing required label: %v", [missing])
        }
```

### Required Labels Constraint
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-labels
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
      - apiGroups: [""]
        kinds: ["Service"]
  parameters:
    labels: ["app", "version", "environment"]
```

### Container Security Template
```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8scontainersecurity
spec:
  crd:
    spec:
      names:
        kind: K8sContainerSecurity
      validation:
        openAPIV3Schema:
          type: object
          properties:
            allowPrivileged:
              type: boolean
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8scontainersecurity
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          container.securityContext.privileged == true
          not input.parameters.allowPrivileged
          msg := "Privileged containers are not allowed"
        }
```

## 🔧 Management Commands
```bash
# List constraint templates
kubectl get constrainttemplates

# List constraints
kubectl get constraints

# Check violations
kubectl get k8srequiredlabels must-have-labels -o yaml

# Check Gatekeeper logs
kubectl logs -n gatekeeper-system deployment/gatekeeper-controller-manager
```

## 🛠️ Debugging
```bash
# Test policy with dry-run
kubectl apply --dry-run=server -f test-deployment.yaml

# Check constraint status
kubectl get constraint must-have-labels -o jsonpath='{.status}'
```

## 📊 Audit Script
```bash
#!/bin/bash
echo "=== Gatekeeper Policy Audit ==="

# List all constraint templates
echo "=== Constraint Templates ==="
kubectl get constrainttemplates

echo "=== Active Constraints ==="
kubectl get constraints --all-namespaces

echo "=== Policy Violations ==="
for constraint in $(kubectl get constraints -o name); do
  violations=$(kubectl get $constraint -o jsonpath='{.status.violations[*].message}' 2>/dev/null)
  if [ -n "$violations" ]; then
    echo "Violations in $constraint: $violations"
  fi
done
```

## 📋 Best Practices
- Start with warn mode
- Test policies thoroughly
- Use descriptive error messages
- Monitor policy performance
- Version control policies
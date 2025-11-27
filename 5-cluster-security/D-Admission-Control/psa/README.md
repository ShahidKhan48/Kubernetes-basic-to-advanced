# Pod Security Admission (PSA)

## 📚 Overview
Built-in admission controller for Pod Security Standards enforcement.

## 🎯 PSA Modes
- **Enforce**: Policy violations rejected
- **Audit**: Policy violations logged
- **Warn**: Policy violations warned

## 📖 Namespace Configuration

### Enforce Restricted Policy
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/enforce-version: v1.28
```

### Mixed Policy Levels
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Privileged Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: system-privileged
  labels:
    pod-security.kubernetes.io/enforce: privileged
```

## 🔧 Cluster-wide Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: psa-config
  namespace: kube-system
data:
  config.yaml: |
    apiVersion: apiserver.config.k8s.io/v1
    kind: AdmissionConfiguration
    plugins:
    - name: PodSecurity
      configuration:
        apiVersion: pod-security.admission.config.k8s.io/v1beta1
        kind: PodSecurityConfiguration
        defaults:
          enforce: "baseline"
          audit: "restricted"
          warn: "restricted"
        exemptions:
          usernames: ["system:serviceaccount:kube-system:*"]
          namespaces: ["kube-system", "kube-public"]
```

## 🛠️ Testing and Validation
```bash
# Check namespace PSA labels
kubectl get namespaces -o custom-columns=NAME:.metadata.name,ENFORCE:.metadata.labels.'pod-security\.kubernetes\.io/enforce'

# Test with non-compliant pod
kubectl apply --dry-run=server -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-privileged
  namespace: secure-production
spec:
  containers:
  - name: test
    image: nginx
    securityContext:
      privileged: true
EOF
```

### PSA Validation Script
```bash
#!/bin/bash
NAMESPACE=$1

echo "=== PSA Configuration for namespace: $NAMESPACE ==="

ENFORCE=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
AUDIT=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/audit}' 2>/dev/null)
WARN=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/warn}' 2>/dev/null)

echo "Enforce: ${ENFORCE:-not-set}"
echo "Audit: ${AUDIT:-not-set}"
echo "Warn: ${WARN:-not-set}"
```

## 📊 Monitoring
```yaml
# PSA violation metrics
groups:
- name: psa.rules
  rules:
  - alert: PSAViolation
    expr: increase(apiserver_admission_webhook_admission_duration_seconds_count{name="PodSecurity",rejected="true"}[5m]) > 0
    labels:
      severity: warning
    annotations:
      summary: "Pod Security Admission violation detected"
```

## 📋 Best Practices
- Start with warn mode
- Monitor violation patterns
- Gradual policy enforcement
- Application compatibility testing
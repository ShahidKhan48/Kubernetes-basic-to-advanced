# Pod Security Standards (PSS)

## 📚 Overview
Kubernetes built-in security policies for pod security contexts.

## 🎯 Security Levels

### 1. Privileged
No restrictions - allows everything
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      privileged: true
      runAsUser: 0
  hostNetwork: true
  hostPID: true
```

### 2. Baseline
Minimal restrictions - prevents known privilege escalations
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: baseline-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
```

### 3. Restricted
Heavily restricted - security best practices enforced
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      capabilities:
        drop: ["ALL"]
      readOnlyRootFilesystem: true
      seccompProfile:
        type: RuntimeDefault
    resources:
      limits:
        memory: "128Mi"
        cpu: "100m"
```

## 🔧 Compliance Checking

### Baseline Compliance Script
```bash
#!/bin/bash
POD_NAME=$1
NAMESPACE=${2:-default}

echo "Checking pod $POD_NAME for baseline compliance..."

# Check privileged
if kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[*].securityContext.privileged}' | grep -q true; then
  echo "❌ FAIL: Privileged container detected"
fi

# Check host namespaces
if kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.hostNetwork}' | grep -q true; then
  echo "❌ FAIL: Host network enabled"
fi

echo "✅ Baseline compliance check completed"
```

### Restricted Compliance Script
```bash
#!/bin/bash
POD_NAME=$1
NAMESPACE=${2:-default}

echo "Checking pod $POD_NAME for restricted compliance..."

# Check runAsNonRoot
if ! kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.securityContext.runAsNonRoot}' | grep -q true; then
  echo "❌ FAIL: runAsNonRoot not set"
fi

# Check capabilities dropped
DROPPED_CAPS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[*].securityContext.capabilities.drop[*]}')
if ! echo $DROPPED_CAPS | grep -q "ALL"; then
  echo "❌ FAIL: All capabilities not dropped"
fi

echo "✅ Restricted compliance check completed"
```

## 📋 Migration Guide
```yaml
# Step 1: Add security context
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000

# Step 2: Update container security
containers:
- securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]

# Step 3: Add resource limits
  resources:
    limits:
      memory: "128Mi"
      cpu: "100m"
```

## 📋 Best Practices
- Start with baseline level
- Test applications thoroughly
- Migrate to restricted incrementally
- Monitor for violations
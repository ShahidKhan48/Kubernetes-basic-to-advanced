# Mutating Admission Webhooks

## 📚 Overview
Automatic resource modification through webhook services.

## 🎯 Webhook Configuration
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionWebhook
metadata:
  name: pod-mutator.spicybiryaniwala.shop
webhooks:
- name: pod-mutator.spicybiryaniwala.shop
  clientConfig:
    service:
      name: mutating-webhook-service
      namespace: webhook-system
      path: "/mutate-pods"
    caBundle: LS0tLS1CRUdJTi0tLS0t  # Base64 encoded CA
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1", "v1beta1"]
  sideEffects: None
  failurePolicy: Fail
```

## 📖 Mutation Examples

### Security Context Injection
```yaml
# Original Pod
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx

# After Mutation
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    injected-by: mutating-webhook
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    image: nginx
    resources:
      limits:
        memory: 256Mi
        cpu: 200m
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
```

### Sidecar Injection
```yaml
# Sidecar container mutation
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
  annotations:
    sidecar.spicybiryaniwala.shop/inject: "true"
spec:
  containers:
  - name: app
    image: nginx
  - name: logging-sidecar  # Injected by webhook
    image: spicybiryaniwala.shop/fluent-bit:v1.0.0
    volumeMounts:
    - name: logs
      mountPath: /var/log
  volumes:
  - name: logs  # Injected by webhook
    emptyDir: {}
```

## 🔧 Webhook Service
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mutating-webhook
  namespace: webhook-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mutating-webhook
  template:
    metadata:
      labels:
        app: mutating-webhook
    spec:
      containers:
      - name: webhook
        image: spicybiryaniwala.shop/mutating-webhook:v1.0.0
        ports:
        - containerPort: 8443
        volumeMounts:
        - name: webhook-certs
          mountPath: /etc/certs
          readOnly: true
      volumes:
      - name: webhook-certs
        secret:
          secretName: webhook-certs
```

## 🛠️ Testing Mutations
```bash
# Create test pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-mutation
  annotations:
    mutation.spicybiryaniwala.shop/inject-security: "true"
spec:
  containers:
  - name: app
    image: nginx
EOF

# Check mutations applied
kubectl get pod test-mutation -o yaml | grep -A 10 "securityContext\|injected-by"
```

## 🔧 Mutation Verification
```bash
#!/bin/bash
POD_NAME=$1
NAMESPACE=${2:-default}

echo "Checking mutations for pod $POD_NAME..."

# Check injected labels
INJECTED_BY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.metadata.labels.injected-by}')
if [ "$INJECTED_BY" = "mutating-webhook" ]; then
  echo "✅ Mutation label found"
else
  echo "❌ Mutation label missing"
fi

# Check security context
RUN_AS_NON_ROOT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.securityContext.runAsNonRoot}')
if [ "$RUN_AS_NON_ROOT" = "true" ]; then
  echo "✅ Security context injected"
else
  echo "❌ Security context missing"
fi
```

## 📋 Best Practices
- Minimal necessary changes
- Preserve user intent
- Document mutations clearly
- Efficient patch generation
- Monitor webhook latency
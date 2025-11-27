# Validation & Mutation Webhooks - Advanced Admission Control

## 📚 Overview
Validation aur Mutation Webhooks custom admission logic implement karne ka advanced method hai. Ye API requests ko validate aur modify kar sakte hain.

## 🎯 Webhook Types

### Validating Webhooks
- **Purpose** - Request validation
- **Action** - Allow/Deny requests
- **Use Case** - Policy enforcement

### Mutating Webhooks  
- **Purpose** - Request modification
- **Action** - Modify resources
- **Use Case** - Auto-injection, defaults

## 📖 Examples

### 1. Basic Validation Webhook
```yaml
# 01-webhook-examples.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: pod-security-validator
webhooks:
- name: pod-security.spicybiryaniwala.shop
  clientConfig:
    service:
      name: pod-security-webhook
      namespace: webhook-system
      path: "/validate-pods"
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
  failurePolicy: Fail
```

### 2. Resource Injection Webhook
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionWebhook
metadata:
  name: resource-injector
webhooks:
- name: inject-resources.spicybiryaniwala.shop
  clientConfig:
    service:
      name: resource-injector
      namespace: webhook-system
      path: "/mutate"
  rules:
  - operations: ["CREATE"]
    apiGroups: ["apps"]
    apiVersions: ["v1"]
    resources: ["deployments"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
```

### 3. Security Policy Webhook
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: security-policy-webhook
webhooks:
- name: security.spicybiryaniwala.shop
  clientConfig:
    service:
      name: security-webhook
      namespace: security-system
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  namespaceSelector:
    matchLabels:
      security-policy: "enforced"
  admissionReviewVersions: ["v1"]
```

### 4. Sidecar Injection Webhook
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionWebhook
metadata:
  name: sidecar-injector
webhooks:
- name: sidecar.spicybiryaniwala.shop
  clientConfig:
    service:
      name: sidecar-injector
      namespace: istio-system
      path: "/inject"
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  namespaceSelector:
    matchLabels:
      istio-injection: enabled
  admissionReviewVersions: ["v1"]
```

### 5. Complete Webhook Server
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admission-webhook
  namespace: webhook-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: admission-webhook
  template:
    metadata:
      labels:
        app: admission-webhook
    spec:
      serviceAccountName: admission-webhook
      containers:
      - name: webhook
        image: spicybiryaniwala.shop/admission-webhook:v1.0.0
        ports:
        - containerPort: 8443
          name: webhook-api
        
        env:
        - name: TLS_CERT_FILE
          value: /etc/webhook/certs/tls.crt
        - name: TLS_PRIVATE_KEY_FILE
          value: /etc/webhook/certs/tls.key
        
        volumeMounts:
        - name: webhook-certs
          mountPath: /etc/webhook/certs
          readOnly: true
        
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        livenessProbe:
          httpGet:
            path: /health
            port: 8443
            scheme: HTTPS
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8443
            scheme: HTTPS
      
      volumes:
      - name: webhook-certs
        secret:
          secretName: webhook-certs
---
apiVersion: v1
kind: Service
metadata:
  name: admission-webhook
  namespace: webhook-system
spec:
  selector:
    app: admission-webhook
  ports:
  - port: 443
    targetPort: 8443
    protocol: TCP
```

## 🔧 Webhook Management

### Deploy Webhook
```bash
# Create namespace
kubectl create namespace webhook-system

# Generate certificates
./generate-certs.sh

# Create secret with certs
kubectl create secret tls webhook-certs \
  --cert=server.crt \
  --key=server.key \
  -n webhook-system

# Deploy webhook server
kubectl apply -f webhook-deployment.yaml

# Register webhook
kubectl apply -f webhook-registration.yaml
```

### Test Webhook
```bash
# Test validation
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test
    image: nginx:1.21
EOF

# Check webhook logs
kubectl logs -n webhook-system deployment/admission-webhook

# View admission events
kubectl get events --field-selector reason=FailedAdmissionWebhook
```

## 🛡️ Security Considerations

### 1. **TLS Configuration**
```yaml
# Webhook requires TLS
clientConfig:
  service:
    name: webhook-service
    namespace: webhook-system
  caBundle: LS0tLS1CRUdJTi... # Base64 encoded CA cert
```

### 2. **RBAC Permissions**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: admission-webhook
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
```

### 3. **Failure Policy**
```yaml
# Fail closed (secure)
failurePolicy: Fail

# Fail open (availability)
failurePolicy: Ignore
```

## 📊 Common Use Cases

### 1. **Resource Validation**
- Enforce resource limits
- Validate image sources
- Check security contexts

### 2. **Auto-injection**
- Sidecar containers
- Environment variables
- Volume mounts

### 3. **Policy Enforcement**
- Security policies
- Compliance rules
- Organizational standards

## 🚨 Troubleshooting

### Webhook Not Called
```bash
# Check webhook registration
kubectl get validatingadmissionwebhooks

# Verify service endpoints
kubectl get endpoints -n webhook-system

# Check namespace selectors
kubectl describe validatingadmissionwebhook webhook-name
```

### Certificate Issues
```bash
# Check certificate validity
openssl x509 -in server.crt -text -noout

# Verify CA bundle
kubectl get validatingadmissionwebhook webhook-name -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | base64 -d | openssl x509 -text -noout

# Test TLS connection
openssl s_client -connect webhook-service.webhook-system.svc:443
```

### Webhook Failures
```bash
# Check webhook logs
kubectl logs -n webhook-system deployment/admission-webhook

# Check admission events
kubectl get events --field-selector reason=FailedAdmissionWebhook

# Test webhook endpoint
kubectl run test --image=busybox --dry-run=server
```

## 📋 Practical Example

### Simple Resource Validator
```bash
# 1. Create webhook server
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-validator
  namespace: webhook-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resource-validator
  template:
    metadata:
      labels:
        app: resource-validator
    spec:
      containers:
      - name: validator
        image: spicybiryaniwala.shop/resource-validator:latest
        ports:
        - containerPort: 8443
EOF

# 2. Register validation webhook
kubectl apply -f - <<EOF
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: resource-validator
webhooks:
- name: resources.spicybiryaniwala.shop
  clientConfig:
    service:
      name: resource-validator
      namespace: webhook-system
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
EOF

# 3. Test validation
kubectl run test-pod --image=nginx:1.21
```

## 🔗 Related Topics
- **[Admission Controllers](../admission-controller/)** - Built-in controllers
- **[Pod Security Standards](../../../5-cluster-security/D-Admission-Control/pss/)** - Security policies
- **[RBAC](../../../5-cluster-security/C-RBAC/)** - Access control

---

**Completed:** B-Scheduling Documentation - All 9 components covered with comprehensive examples and best practices.
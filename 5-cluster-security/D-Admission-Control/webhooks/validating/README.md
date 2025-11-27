# Validating Admission Webhooks

## 📚 Overview
Custom validation logic through external webhook services.

## 🎯 Webhook Configuration
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: pod-validator.spicybiryaniwala.shop
webhooks:
- name: pod-validator.spicybiryaniwala.shop
  clientConfig:
    service:
      name: validation-webhook-service
      namespace: webhook-system
      path: "/validate-pods"
    caBundle: LS0tLS1CRUdJTi0tLS0t  # Base64 encoded CA
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1", "v1beta1"]
  sideEffects: None
  failurePolicy: Fail
```

## 📖 Webhook Service
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: validation-webhook
  namespace: webhook-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: validation-webhook
  template:
    metadata:
      labels:
        app: validation-webhook
    spec:
      containers:
      - name: webhook
        image: spicybiryaniwala.shop/validation-webhook:v1.0.0
        ports:
        - containerPort: 8443
          name: webhook-api
        env:
        - name: TLS_CERT_FILE
          value: /etc/certs/tls.crt
        - name: TLS_PRIVATE_KEY_FILE
          value: /etc/certs/tls.key
        volumeMounts:
        - name: webhook-certs
          mountPath: /etc/certs
          readOnly: true
      volumes:
      - name: webhook-certs
        secret:
          secretName: webhook-certs
```

## 🔧 Certificate Generation
```bash
#!/bin/bash
NAMESPACE="webhook-system"
SERVICE="validation-webhook-service"

# Generate CA
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -out ca.crt -subj "/CN=webhook-ca"

# Generate server certificate
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=${SERVICE}.${NAMESPACE}.svc"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365

# Create secret
kubectl create secret tls webhook-certs \
  --cert=server.crt \
  --key=server.key \
  -n $NAMESPACE

# Get CA bundle
CA_BUNDLE=$(cat ca.crt | base64 | tr -d '\n')
echo "CA Bundle: $CA_BUNDLE"
```

## 🛠️ Testing
```bash
# Test with valid pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: valid-pod
  labels:
    app: test-app
spec:
  containers:
  - name: app
    image: spicybiryaniwala.shop/nginx:v1.0.0
EOF

# Test with invalid pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: invalid-pod
spec:
  containers:
  - name: app
    image: nginx:latest  # Should be rejected
EOF
```

## 🔧 Debugging
```bash
# Check webhook logs
kubectl logs -n webhook-system deployment/validation-webhook

# Check webhook configuration
kubectl get validatingadmissionwebhooks

# Test connectivity
kubectl get --raw /api/v1/namespaces/webhook-system/services/validation-webhook-service:443/proxy/health
```

## 📋 Best Practices
- Implement health checks
- Use multiple replicas
- Set appropriate timeouts
- Handle failures gracefully
- Secure certificate management
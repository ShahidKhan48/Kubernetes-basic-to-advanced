# Service Accounts

## 📚 Overview
Kubernetes service accounts for pod identity aur authentication.

## 🎯 Service Account Management

### Basic Service Account
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: production
automountServiceAccountToken: true
```

### Service Account with Secret
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitoring-sa
  namespace: monitoring
---
apiVersion: v1
kind: Secret
metadata:
  name: monitoring-sa-token
  namespace: monitoring
  annotations:
    kubernetes.io/service-account.name: monitoring-sa
type: kubernetes.io/service-account-token
```

## 📖 Token Management

### Create Token
```bash
# Create short-lived token
kubectl create token monitoring-sa

# Create token with custom duration
kubectl create token monitoring-sa --duration=1h

# Create token with audience
kubectl create token monitoring-sa --audience=https://api.spicybiryaniwala.shop
```

### Pod Token Mounting
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  serviceAccountName: app-service-account
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: token
      mountPath: /var/run/secrets/tokens
      readOnly: true
  volumes:
  - name: token
    projected:
      sources:
      - serviceAccountToken:
          path: token
          expirationSeconds: 3600
          audience: https://api.spicybiryaniwala.shop
```

## 🔗 RBAC Integration
```yaml
# Service account with role binding
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

## 🔧 Commands
```bash
# Create service account
kubectl create serviceaccount my-sa

# Get service accounts
kubectl get serviceaccounts
kubectl describe serviceaccount my-sa

# Test permissions
kubectl auth can-i get pods --as=system:serviceaccount:default:my-sa

# Get token from secret
kubectl get secret my-sa-token -o jsonpath='{.data.token}' | base64 -d
```

## 📋 Best Practices
- Disable auto-mounting when not needed
- Use least privilege principle
- Regular token rotation
- Proper RBAC bindings
- Monitor service account usage
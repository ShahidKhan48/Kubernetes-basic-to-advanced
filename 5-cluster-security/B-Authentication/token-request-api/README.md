# Token Request API

## 📚 Overview
Kubernetes Token Request API for secure service account token generation.

## 🎯 Token Request Features
- **Bound Tokens**: Pod/node-bound tokens
- **Time-bound**: Automatic expiration
- **Audience Validation**: Scoped token usage
- **Security**: No long-lived secrets

## 📖 Token Generation

### API-based Token Creation
```bash
# Create token via API
kubectl create token monitoring-sa

# Token with custom expiration
kubectl create token monitoring-sa --duration=2h

# Token with specific audience
kubectl create token monitoring-sa --audience=https://vault.spicybiryaniwala.shop
```

### Token Request YAML
```yaml
apiVersion: authentication.k8s.io/v1
kind: TokenRequest
metadata:
  name: app-token-request
spec:
  audiences:
  - https://api.spicybiryaniwala.shop
  - https://vault.spicybiryaniwala.shop
  expirationSeconds: 3600
  boundObjectRef:
    kind: Pod
    apiVersion: v1
    name: app-pod
```

## 🔧 Projected Volume Token
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  serviceAccountName: secure-sa
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
          expirationSeconds: 1800  # 30 minutes
          audience: https://api.spicybiryaniwala.shop
```

### Automatic Token Refresh
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: token-consumer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: token-consumer
  template:
    metadata:
      labels:
        app: token-consumer
    spec:
      serviceAccountName: consumer-sa
      containers:
      - name: consumer
        image: spicybiryaniwala.shop/token-consumer:v1.0.0
        env:
        - name: TOKEN_PATH
          value: /var/run/secrets/kubernetes.io/serviceaccount/token
```

## 🛡️ Security Validation
```bash
# Decode token payload
TOKEN=$(kubectl create token monitoring-sa)
echo $TOKEN | cut -d. -f2 | base64 -d | jq .

# Verify token with API server
kubectl auth can-i get pods --token=$TOKEN

# Test audience validation
TOKEN=$(kubectl create token monitoring-sa --audience=https://vault.spicybiryaniwala.shop)
curl -H "Authorization: Bearer $TOKEN" https://vault.spicybiryaniwala.shop/v1/auth/kubernetes/login
```

## 📋 Best Practices
- Use minimal token lifetime
- Specify target audiences
- Let Kubernetes handle token refresh
- Monitor token usage patterns
- Implement proper audience validation
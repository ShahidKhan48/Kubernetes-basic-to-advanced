# Ingress & Controllers - HTTP/HTTPS Routing

## 📚 Overview
Ingress HTTP aur HTTPS traffic ko cluster mein route karta hai. SSL termination, path-based routing aur virtual hosting provide karta hai.

## 🎯 Ingress Controllers

### 1. **NGINX Ingress Controller**
Most popular aur feature-rich
- SSL termination
- Path-based routing
- Authentication
- Rate limiting

### 2. **HAProxy Ingress**
High performance aur enterprise features
- Advanced load balancing
- Circuit breakers
- Blue-green deployments

### 3. **APISIX Controller**
API Gateway features
- Plugin ecosystem
- Dynamic configuration
- Observability

## 📖 Examples

### Basic Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
spec:
  rules:
  - host: spicybiryaniwala.shop
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

### TLS Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
  - hosts:
    - spicybiryaniwala.shop
    secretName: tls-secret
  rules:
  - host: spicybiryaniwala.shop
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

### Advanced Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: advanced-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - api.spicybiryaniwala.shop
    secretName: api-tls-secret
  rules:
  - host: api.spicybiryaniwala.shop
    http:
      paths:
      - path: /api/v1
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /api/v2
        pathType: Prefix
        backend:
          service:
            name: api-v2-service
            port:
              number: 80
```

## 🔧 Commands
```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# List ingress
kubectl get ingress

# Describe ingress
kubectl describe ingress web-app-ingress

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## 🔗 Related Topics
- [Services](../01-services/) - Backend services
- [TLS Certificates](../../5-cluster-security/B-Authentication/k8s-ssl-certificate/) - SSL setup

---

**Next:** [DNS & CoreDNS](../05-dns-coredns/) - Service Discovery
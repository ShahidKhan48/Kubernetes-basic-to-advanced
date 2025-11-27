# Helm Package Manager Guide

## 📦 Overview
Comprehensive Helm guide covering installation, chart development, advanced features, production deployments, security tools, monitoring, troubleshooting, and best practices.

## 📁 Directory Structure

### **01-helm-basics/** - Helm Fundamentals
- **helm-installation.md**: Installation, basic commands, repository management, and configuration

### **02-chart-development/** - Chart Creation & Development
- **chart-structure.md**: Chart anatomy, templates, values, helpers, and testing

### **03-advanced-features/** - Advanced Helm Capabilities
- **advanced-helm.md**: Dependencies, hooks, functions, multi-environment deployments, and packaging

### **04-production-charts/** - Production-Ready Charts
- **production-ready-chart.yml**: Complete production chart with security, monitoring, and best practices

### **05-security-tools/** - Security-Focused Charts
- **security-charts.yml**: Vault, Trivy, Falco, OPA Gatekeeper, External Secrets, and Cert-Manager

### **06-monitoring-charts/** - Observability Stack
- **monitoring-stack.yml**: Prometheus, Grafana, Loki, Tempo, Jaeger, and metrics collection

### **07-troubleshooting/** - Problem Resolution
- **helm-troubleshooting.md**: Common issues, debugging techniques, and resolution strategies

### **08-best-practices/** - Production Guidelines
- **helm-best-practices.md**: Chart development, security, testing, and maintenance best practices

## 🚀 Quick Start Guide

### 1. Install Helm
```bash
# Linux/macOS
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# macOS with Homebrew
brew install helm

# Verify installation
helm version
```

### 2. Add Repositories
```bash
# Add popular repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io

# Update repositories
helm repo update
```

### 3. Deploy Your First Application
```bash
# Install NGINX
helm install my-nginx bitnami/nginx

# Check status
helm status my-nginx

# Access application
kubectl port-forward svc/my-nginx 8080:80
```

### 4. Create Your Own Chart
```bash
# Create new chart
helm create my-app

# Customize values
vim my-app/values.yaml

# Install chart
helm install my-app ./my-app

# Upgrade chart
helm upgrade my-app ./my-app
```

## 📊 Chart Categories

### Application Charts
- **Web Applications**: NGINX, Apache, Node.js, React
- **Databases**: PostgreSQL, MySQL, MongoDB, Redis
- **Message Queues**: RabbitMQ, Apache Kafka, NATS
- **API Gateways**: Kong, Ambassador, Istio Gateway

### Infrastructure Charts
- **Monitoring**: Prometheus, Grafana, Alertmanager
- **Logging**: Loki, Fluent Bit, Elasticsearch
- **Security**: Vault, Falco, OPA Gatekeeper
- **Networking**: Ingress Controllers, Service Mesh

### Development Tools
- **CI/CD**: Jenkins, GitLab Runner, Tekton
- **Code Quality**: SonarQube, CodeClimate
- **Container Registry**: Harbor, ChartMuseum
- **Development**: JupyterHub, Code Server

## 🔧 Common Helm Commands

### Repository Management
```bash
# List repositories
helm repo list

# Search charts
helm search repo nginx
helm search hub wordpress

# Add repository
helm repo add stable https://charts.helm.sh/stable

# Update repositories
helm repo update
```

### Release Management
```bash
# Install release
helm install my-release chart-name

# List releases
helm list
helm list --all-namespaces

# Upgrade release
helm upgrade my-release chart-name

# Rollback release
helm rollback my-release 1

# Uninstall release
helm uninstall my-release
```

### Chart Development
```bash
# Create chart
helm create my-chart

# Lint chart
helm lint ./my-chart

# Template chart
helm template my-release ./my-chart

# Package chart
helm package ./my-chart

# Test chart
helm test my-release
```

## 🏗️ Production Deployment Patterns

### Blue-Green Deployment
```bash
# Deploy blue version
helm install app-blue ./my-app --set version=blue

# Deploy green version
helm install app-green ./my-app --set version=green

# Switch traffic (update ingress/service)
helm upgrade app-blue ./my-app --set traffic.weight=0
helm upgrade app-green ./my-app --set traffic.weight=100
```

### Canary Deployment
```bash
# Deploy stable version
helm install app-stable ./my-app --set version=stable

# Deploy canary version
helm install app-canary ./my-app --set version=canary --set replicas=1

# Gradually increase canary traffic
helm upgrade app-canary ./my-app --set traffic.weight=10
helm upgrade app-canary ./my-app --set traffic.weight=50
```

### Multi-Environment Management
```bash
# Development
helm install my-app ./my-chart -f values-dev.yaml -n development

# Staging
helm install my-app ./my-chart -f values-staging.yaml -n staging

# Production
helm install my-app ./my-chart -f values-prod.yaml -n production
```

## 🔐 Security Best Practices

### Chart Security
- Use non-root containers
- Implement read-only root filesystems
- Set resource limits and requests
- Use security contexts and pod security standards
- Implement network policies

### Secret Management
```bash
# Use external secret management
helm install my-app ./my-chart \
  --set externalSecrets.enabled=true \
  --set externalSecrets.secretStore=vault-backend

# Use sealed secrets for GitOps
kubeseal --format=yaml < secret.yaml > sealed-secret.yaml
```

### RBAC Configuration
```yaml
# Minimal RBAC permissions
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-app-role

rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["configmaps"]
      verbs: ["get", "list", "watch"]
```

## 📈 Monitoring and Observability

### Prometheus Integration
```yaml
# ServiceMonitor for metrics collection
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /metrics
    labels:
      app: monitoring
```

### Grafana Dashboards
```yaml
# Dashboard ConfigMap
dashboards:
  enabled: true
  configMaps:
    - name: app-dashboard
      data:
        dashboard.json: |
          {
            "dashboard": {
              "title": "Application Metrics",
              "panels": [...]
            }
          }
```

### Logging Configuration
```yaml
# Fluent Bit sidecar
logging:
  enabled: true
  sidecar:
    image: fluent/fluent-bit:2.1.10
    config:
      outputs: |
        [OUTPUT]
            Name loki
            Match *
            Host loki.monitoring.svc.cluster.local
            Port 3100
```

## 🧪 Testing Strategies

### Unit Testing
```bash
# Install helm-unittest plugin
helm plugin install https://github.com/quintush/helm-unittest

# Run unit tests
helm unittest ./my-chart
```

### Integration Testing
```bash
# Test chart installation
helm install test-release ./my-chart --dry-run --debug

# Run chart tests
helm test test-release --logs

# Validate with kubeval
helm template test-release ./my-chart | kubeval
```

### Security Testing
```bash
# Scan chart for security issues
helm template my-release ./my-chart | kubesec scan -

# Check for misconfigurations
helm template my-release ./my-chart | polaris audit --audit-path -
```

## 🔄 CI/CD Integration

### GitLab CI Pipeline
```yaml
# .gitlab-ci.yml
stages:
  - lint
  - test
  - deploy

helm-lint:
  stage: lint
  script:
    - helm lint ./charts/my-app

helm-test:
  stage: test
  script:
    - helm unittest ./charts/my-app

deploy-staging:
  stage: deploy
  script:
    - helm upgrade --install my-app ./charts/my-app -f values-staging.yaml -n staging
  only:
    - develop

deploy-production:
  stage: deploy
  script:
    - helm upgrade --install my-app ./charts/my-app -f values-prod.yaml -n production
  only:
    - main
```

### GitHub Actions
```yaml
# .github/workflows/helm.yml
name: Helm Chart CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Helm
      uses: azure/setup-helm@v3
    - name: Lint chart
      run: helm lint ./charts/my-app
    - name: Run tests
      run: helm unittest ./charts/my-app
```

## 📚 Learning Resources

### Official Documentation
- [Helm Documentation](https://helm.sh/docs/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Chart Template Guide](https://helm.sh/docs/chart_template_guide/)

### Community Resources
- [Artifact Hub](https://artifacthub.io/) - Discover charts
- [Helm Hub](https://hub.helm.sh/) - Chart repository
- [Bitnami Charts](https://github.com/bitnami/charts) - Production-ready charts

### Tools and Plugins
- [helm-diff](https://github.com/databus23/helm-diff) - Preview changes
- [helm-secrets](https://github.com/jkroepke/helm-secrets) - Manage secrets
- [helm-unittest](https://github.com/quintush/helm-unittest) - Unit testing
- [helmfile](https://github.com/roboll/helmfile) - Declarative deployment

This comprehensive Helm guide provides everything needed for effective Kubernetes application management, from basic usage to advanced production deployments with security, monitoring, and best practices.
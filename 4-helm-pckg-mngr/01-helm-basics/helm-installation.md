# Helm Installation and Basic Commands

## Helm Installation

### Install Helm on Different Platforms

#### Linux/macOS
```bash
# Using script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Using package managers
# macOS
brew install helm

# Ubuntu/Debian
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

#### Windows
```powershell
# Using Chocolatey
choco install kubernetes-helm

# Using Scoop
scoop install helm
```

### Verify Installation
```bash
helm version
helm help
```

## Basic Helm Commands

### Repository Management
```bash
# Add repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# List repositories
helm repo list

# Update repositories
helm repo update

# Search charts
helm search repo nginx
helm search hub wordpress

# Remove repository
helm repo remove bitnami
```

### Chart Installation
```bash
# Install chart
helm install my-release bitnami/nginx

# Install with custom values
helm install my-release bitnami/nginx --set service.type=LoadBalancer

# Install with values file
helm install my-release bitnami/nginx -f values.yaml

# Install in specific namespace
helm install my-release bitnami/nginx -n production --create-namespace

# Dry run (test installation)
helm install my-release bitnami/nginx --dry-run --debug
```

### Release Management
```bash
# List releases
helm list
helm list -A  # All namespaces
helm list -n production

# Get release status
helm status my-release

# Get release values
helm get values my-release
helm get values my-release --all

# Get release manifest
helm get manifest my-release

# Get release notes
helm get notes my-release
```

### Upgrade and Rollback
```bash
# Upgrade release
helm upgrade my-release bitnami/nginx
helm upgrade my-release bitnami/nginx --set image.tag=1.21

# Upgrade with new values
helm upgrade my-release bitnami/nginx -f new-values.yaml

# Get release history
helm history my-release

# Rollback to previous version
helm rollback my-release

# Rollback to specific revision
helm rollback my-release 2
```

### Uninstall
```bash
# Uninstall release
helm uninstall my-release

# Uninstall and keep history
helm uninstall my-release --keep-history

# List uninstalled releases
helm list --uninstalled
```

## Working with Values

### Default Values
```bash
# Show default values
helm show values bitnami/nginx

# Show chart information
helm show chart bitnami/nginx
helm show readme bitnami/nginx
helm show all bitnami/nginx
```

### Custom Values File
```yaml
# values.yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.21"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: app.spicybiryaniwala.shop
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.spicybiryaniwala.shop

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### Environment-Specific Values
```bash
# Development values
helm install my-app ./my-chart -f values-dev.yaml

# Production values
helm install my-app ./my-chart -f values-prod.yaml

# Multiple values files
helm install my-app ./my-chart -f values.yaml -f values-prod.yaml
```

## Helm Configuration

### Helm Configuration File
```yaml
# ~/.config/helm/repositories.yaml
apiVersion: ""
generated: "2023-01-01T00:00:00Z"
repositories:
- caFile: ""
  certFile: ""
  insecure_skip_tls_verify: false
  keyFile: ""
  name: bitnami
  pass_credentials_all: false
  password: ""
  url: https://charts.bitnami.com/bitnami
  username: ""
```

### Environment Variables
```bash
# Helm configuration directory
export HELM_CONFIG_HOME=~/.config/helm

# Helm cache directory
export HELM_CACHE_HOME=~/.cache/helm

# Helm data directory
export HELM_DATA_HOME=~/.local/share/helm

# Default namespace
export HELM_NAMESPACE=production

# Kubeconfig file
export KUBECONFIG=~/.kube/config
```

## Helm Plugins

### Popular Plugins
```bash
# Install plugins
helm plugin install https://github.com/databus23/helm-diff
helm plugin install https://github.com/helm/helm-2to3
helm plugin install https://github.com/chartmuseum/helm-push

# List plugins
helm plugin list

# Use diff plugin
helm diff upgrade my-release bitnami/nginx -f new-values.yaml

# Use push plugin
helm push my-chart/ chartmuseum
```

## Common Use Cases

### Install with Custom Configuration
```bash
# Install PostgreSQL with custom settings
helm install postgres bitnami/postgresql \
  --set auth.postgresPassword=secretpassword \
  --set auth.database=myapp \
  --set primary.persistence.size=20Gi \
  --set primary.resources.requests.memory=1Gi

# Install Redis cluster
helm install redis bitnami/redis \
  --set architecture=replication \
  --set auth.enabled=true \
  --set auth.password=redispassword \
  --set replica.replicaCount=3
```

### Monitoring Stack Installation
```bash
# Install Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi

# Install Grafana
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set adminPassword=admin123
```

## Troubleshooting

### Common Issues
```bash
# Debug installation
helm install my-release bitnami/nginx --debug --dry-run

# Check release status
helm status my-release

# Get release history
helm history my-release

# Check values
helm get values my-release --all

# Validate chart
helm lint ./my-chart

# Template rendering
helm template my-release ./my-chart
```

### Cleanup
```bash
# Uninstall release
helm uninstall my-release

# Clean up failed releases
helm list --failed
helm uninstall failed-release

# Clean up pending releases
helm list --pending
helm rollback pending-release
```

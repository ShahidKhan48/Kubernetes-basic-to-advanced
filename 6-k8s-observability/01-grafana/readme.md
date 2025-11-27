# Grafana - Visualization & Dashboards

## 📊 Overview
Grafana is the visualization layer of our observability stack, providing dashboards and alerting for metrics, logs, and traces.

## 🏷️ Chart Information
- **Chart**: `grafana/grafana`
- **Version**: `10.1.4`
- **App Version**: `11.4.0`
- **Namespace**: `monitoring`

## 🚀 Installation

### Prerequisites
```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
```

### Install Grafana
```bash
# Install with custom values
helm install grafana grafana/grafana \
  -f grafana-values.yml \
  -n monitoring

# Verify installation
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
```

## 🔗 Access

### Production URL
- **URL**: https://grafana.spicybiryaniwala.shop
- **Username**: `admin`
- **Password**: `admin` (change in production)

### Local Access
```bash
# Port forward to local machine
kubectl port-forward -n monitoring svc/grafana 3000:80

# Access at http://localhost:3000
```

## 📊 Pre-configured Datasources

### Prometheus/Mimir
- **URL**: `http://mimir-nginx:80/prometheus`
- **Type**: Prometheus
- **Default**: Yes

### Loki
- **URL**: `http://loki-gateway:80`
- **Type**: Loki
- **Features**: Log correlation with traces

### Tempo
- **URL**: `http://tempo-query-frontend:3200`
- **Type**: Tempo
- **Features**: Distributed tracing, service maps

## 🎯 Key Features

### Dashboards
- **Auto-provisioning**: Enabled via sidecar
- **Folder structure**: Organized by service type
- **Import**: Supports JSON dashboard imports

### Alerting
- **Unified Alerting**: Enabled
- **Notification channels**: Slack, email, webhooks
- **Alert rules**: Prometheus-compatible

### Authentication
- **Local**: Admin user with password
- **OAuth**: Google OAuth configured for ninjacart.com domain
- **RBAC**: Role-based access control

## 🔧 Configuration

### Custom Dashboards
```bash
# Add dashboard via ConfigMap
kubectl create configmap custom-dashboard \
  --from-file=dashboard.json \
  -n monitoring

# Label for auto-discovery
kubectl label configmap custom-dashboard \
  grafana_dashboard=1 \
  -n monitoring
```

### Datasource Configuration
```yaml
# Add new datasource
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Custom Prometheus
        type: prometheus
        url: http://custom-prometheus:9090
        access: proxy
        isDefault: false
```

## 📈 Monitoring

### Health Checks
```bash
# Check Grafana health
kubectl exec -n monitoring deployment/grafana -- \
  curl -f http://localhost:3000/api/health

# Check datasource connectivity
kubectl logs -n monitoring deployment/grafana -f
```

### Metrics
- **Endpoint**: `/metrics`
- **Port**: `3000`
- **Scraping**: Auto-discovered by Prometheus

## 🔒 Security

### TLS/SSL
- **Ingress**: Automatic TLS via cert-manager
- **Certificate**: Let's Encrypt wildcard cert
- **Redirect**: HTTP to HTTPS

### Access Control
```yaml
# RBAC configuration
auth:
  disable_login_form: false
  oauth_auto_login: true
  
users:
  auto_assign_org_role: Editor
  default_theme: dark
```

## 🛠️ Troubleshooting

### Common Issues

#### Dashboard Not Loading
```bash
# Check sidecar logs
kubectl logs -n monitoring deployment/grafana -c grafana-sc-dashboard

# Verify ConfigMap labels
kubectl get configmaps -n monitoring -l grafana_dashboard=1
```

#### Datasource Connection Failed
```bash
# Test connectivity
kubectl exec -n monitoring deployment/grafana -- \
  curl -v http://mimir-nginx:80/prometheus/api/v1/query?query=up

# Check service endpoints
kubectl get endpoints -n monitoring mimir-nginx
```

#### Login Issues
```bash
# Reset admin password
kubectl exec -n monitoring deployment/grafana -- \
  grafana-cli admin reset-admin-password newpassword

# Check OAuth configuration
kubectl logs -n monitoring deployment/grafana | grep oauth
```

## 📚 Resources

### Official Documentation
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Helm Chart Values](https://github.com/grafana/helm-charts/tree/main/charts/grafana)

### Dashboard Libraries
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- [Kubernetes Dashboards](https://grafana.com/grafana/dashboards/?search=kubernetes)
- [Application Dashboards](https://grafana.com/grafana/dashboards/?search=application)

### Best Practices
- Use template variables for dynamic dashboards
- Organize dashboards in folders by team/service
- Set up proper alerting rules with runbooks
- Regular backup of dashboard configurations
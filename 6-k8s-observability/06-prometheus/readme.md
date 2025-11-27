# Prometheus - Metrics Collection (Optional)

## 📊 Overview
Prometheus is a monitoring system and time series database. In this stack, it's optional since Alloy can directly send metrics to Mimir, but it can be useful for local development or as a backup metrics collector.

## 🏷️ Chart Information
- **Chart**: `prometheus-community/prometheus`
- **Version**: `27.45.0`
- **App Version**: `2.55.1`
- **Namespace**: `monitoring`

## 🚀 Installation

### Prerequisites
```bash
# Add Prometheus Community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
```

### Install Prometheus
```bash
# Install with custom values
helm install prometheus prometheus-community/prometheus \
  -f prometheus-values.yml \
  -n monitoring

# Verify installation
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
```

## 🔗 Access

### Internal Services
- **Prometheus Server**: `http://prometheus-server:80`
- **Alertmanager**: `http://prometheus-alertmanager:9093`
- **Pushgateway**: `http://prometheus-pushgateway:9091`

### Web UI Access
```bash
# Port forward to access Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Access at http://localhost:9090
```

## 🏗️ Architecture

### Components
- **Prometheus Server**: Main metrics collection and storage
- **Alertmanager**: Handles alerts sent by Prometheus
- **Node Exporter**: System metrics from nodes
- **Kube State Metrics**: Kubernetes object metrics
- **Pushgateway**: For batch jobs and short-lived services

### Data Flow
```
Targets → Prometheus → [Local Storage | Remote Write to Mimir]
```

## 📊 Key Features

### Service Discovery
- **Kubernetes**: Automatic discovery of pods, services, endpoints
- **Static Config**: Manual target configuration
- **File-based**: Dynamic configuration via files

### Remote Write
```yaml
# Send metrics to Mimir
remote_write:
  - url: http://mimir-nginx:80/api/v1/push
    headers:
      X-Scope-OrgID: prometheus-metrics
```

### Alerting Rules
```yaml
# Example alerting rule
groups:
  - name: kubernetes-alerts
    rules:
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: Pod {{ $labels.pod }} is crash looping
```

## 🔧 Configuration

### Scrape Configuration
```yaml
scrape_configs:
  # Kubernetes API server
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

  # Kubernetes nodes
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  # Kubernetes pods
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
```

## 📈 Monitoring

### Health Checks
```bash
# Check Prometheus health
kubectl exec -n monitoring deployment/prometheus-server -- \
  curl -f http://localhost:9090/-/healthy

# Check targets
kubectl exec -n monitoring deployment/prometheus-server -- \
  curl http://localhost:9090/api/v1/targets
```

### Key Metrics
```promql
# Prometheus metrics
prometheus_tsdb_head_samples_appended_total
prometheus_config_last_reload_successful
prometheus_notifications_total

# Kubernetes metrics
up{job="kubernetes-nodes"}
kube_node_status_condition{condition="Ready"}
kube_pod_status_phase{phase="Running"}
```

## 🔒 Security

### RBAC Configuration
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources:
      - nodes
      - nodes/proxy
      - services
      - endpoints
      - pods
    verbs: ["get", "list", "watch"]
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs: ["get", "list", "watch"]
```

### Network Policies
```yaml
# Allow ingress to Prometheus
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prometheus-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: prometheus
  ingress:
    - from: []
      ports:
        - protocol: TCP
          port: 9090
```

## 🛠️ Troubleshooting

### Common Issues

#### High Memory Usage
```bash
# Check Prometheus memory usage
kubectl top pods -n monitoring -l app.kubernetes.io/name=prometheus

# Adjust retention settings
kubectl patch configmap prometheus-server \
  --patch '{"data":{"prometheus.yml":"global:\n  retention: 7d"}}' \
  -n monitoring
```

#### Scrape Failures
```bash
# Check Prometheus logs
kubectl logs -n monitoring deployment/prometheus-server -f

# Check target status
kubectl exec -n monitoring deployment/prometheus-server -- \
  curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

#### Remote Write Issues
```bash
# Check remote write status
kubectl exec -n monitoring deployment/prometheus-server -- \
  curl http://localhost:9090/api/v1/status/tsdb

# Verify Mimir connectivity
kubectl exec -n monitoring deployment/prometheus-server -- \
  curl -v http://mimir-nginx:80/api/v1/push
```

## 🎯 Use Cases

### Development Environment
- Local metrics collection and storage
- Quick prototyping and testing
- Grafana datasource for development

### Backup Metrics Collector
- Redundant metrics collection
- Fallback when Alloy is unavailable
- Cross-validation of metrics

### Legacy Integration
- Existing Prometheus-based monitoring
- Gradual migration to Alloy
- Compatibility with existing dashboards

## 🔗 Integration

### With Grafana
```yaml
# Prometheus datasource
- name: Prometheus
  type: prometheus
  url: http://prometheus-server:80
  access: proxy
  isDefault: false
```

### With Alertmanager
```yaml
# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - prometheus-alertmanager:9093
```

## 📚 Resources

### Official Documentation
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Helm Chart Values](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)

### Configuration Examples
- [Kubernetes Monitoring](https://prometheus.io/docs/guides/kubernetes-monitoring/)
- [Recording Rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)

### Best Practices
- Use appropriate retention policies
- Implement proper service discovery
- Monitor Prometheus performance
- Set up proper alerting rules
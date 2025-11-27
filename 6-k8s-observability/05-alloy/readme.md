# Alloy (k8s-monitoring) - Telemetry Collection

## 🔄 Overview
Grafana Alloy (k8s-monitoring) is a vendor-neutral, OpenTelemetry-native telemetry collector that gathers metrics, logs, and traces from Kubernetes clusters.

## 🏷️ Chart Information
- **Chart**: `grafana/k8s-monitoring`
- **Version**: `3.5.6`
- **App Version**: `1.5.0`
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

### Install k8s-monitoring
```bash
# Install with custom values
helm install k8s-monitoring grafana/k8s-monitoring \
  -f alloy-values.yml \
  -n monitoring

# Verify installation
kubectl get pods -n monitoring -l app.kubernetes.io/name=alloy
```

## 🔗 Access

### Internal Services
- **Alloy Metrics**: `http://alloy:12345`
- **OTLP gRPC**: `http://alloy:4317`
- **OTLP HTTP**: `http://alloy:4318`

### Health Checks
```bash
# Check Alloy health
kubectl exec -n monitoring daemonset/alloy-logs -- \
  curl -f http://localhost:12345/-/healthy

# Check configuration
kubectl exec -n monitoring daemonset/alloy-logs -- \
  curl http://localhost:12345/api/v0/web/config
```

## 🏗️ Architecture

### Components
- **Alloy (Main)**: Metrics collection and processing
- **Alloy Events**: Kubernetes events collection
- **Alloy Logs**: Log collection via DaemonSet
- **Alloy Profiles**: Continuous profiling (optional)

### Data Flow
```
Kubernetes → Alloy → [Mimir/Loki/Tempo] → Grafana
```

## 📊 Key Features

### Metrics Collection
- **Kubernetes Metrics**: kubelet, cAdvisor, kube-state-metrics
- **Node Metrics**: node-exporter for system metrics
- **Application Metrics**: Auto-discovery via annotations
- **Custom Metrics**: ServiceMonitor and PodMonitor support

### Log Collection
- **Pod Logs**: Automatic log collection from all pods
- **System Logs**: Journal logs and system components
- **Structured Logs**: JSON parsing and label extraction
- **Log Correlation**: Automatic trace ID extraction

### Trace Collection
- **OTLP**: OpenTelemetry Protocol (gRPC/HTTP)
- **Jaeger**: Native Jaeger receiver
- **Zipkin**: Zipkin format support
- **Auto-instrumentation**: Kubernetes operator support

## 🔧 Configuration

### Cluster Configuration
```yaml
cluster:
  name: production-cluster
  kubernetesAPIService: kubernetes.default.svc.cluster.local:443
  platform: ""
```

### External Services
```yaml
externalServices:
  prometheus:
    host: http://mimir-nginx:80
    writeEndpoint: /api/v1/push
    tenantId: default
  
  loki:
    host: http://loki-gateway:80
    writeEndpoint: /loki/api/v1/push
    tenantId: default
  
  tempo:
    host: http://tempo-distributor:4317
    protocol: otlp
    tenantId: default
```

## 📈 Monitoring

### Metrics Collection
```yaml
metrics:
  enabled: true
  scrapeInterval: 60s
  
  # Auto-discovery
  autoDiscover:
    enabled: true
    annotations:
      scrape: k8s.grafana.com/scrape
      job: k8s.grafana.com/job
      
  # Kubernetes components
  kubelet:
    enabled: true
  cadvisor:
    enabled: true
  kube-state-metrics:
    enabled: true
  node-exporter:
    enabled: true
```

### Log Collection
```yaml
logs:
  enabled: true
  
  # Pod logs
  pod_logs:
    enabled: true
    discovery: all
    gatherMethod: volumes
    
  # Cluster events
  cluster_events:
    enabled: true
    logFormat: logfmt
```

### Trace Collection
```yaml
traces:
  enabled: true
  
receivers:
  grpc:
    enabled: true
    port: 4317
  http:
    enabled: true
    port: 4318
```

## 🎯 Auto-Discovery

### Metrics Auto-Discovery
```yaml
# Pod annotations for metrics scraping
apiVersion: v1
kind: Pod
metadata:
  annotations:
    k8s.grafana.com/scrape: "true"
    k8s.grafana.com/job: "my-app"
    k8s.grafana.com/metrics.portName: "metrics"
    k8s.grafana.com/metrics.path: "/metrics"
spec:
  containers:
    - name: app
      ports:
        - name: metrics
          containerPort: 8080
```

### Log Auto-Discovery
```yaml
# Pod annotations for log collection
apiVersion: v1
kind: Pod
metadata:
  annotations:
    k8s.grafana.com/logs.autogather: "true"
    k8s.grafana.com/logs.job: "my-app-logs"
spec:
  containers:
    - name: app
      # Logs automatically collected from stdout/stderr
```

## 🔒 Security

### RBAC Configuration
```yaml
rbac:
  create: true
  
serviceAccount:
  create: true
  name: alloy
```

### Network Policies
```yaml
# Allow ingress for OTLP
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: alloy-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: alloy
  ingress:
    - ports:
        - protocol: TCP
          port: 4317
        - protocol: TCP
          port: 4318
```

## 🛠️ Troubleshooting

### Common Issues

#### High Memory Usage
```bash
# Check Alloy memory usage
kubectl top pods -n monitoring -l app.kubernetes.io/name=alloy

# Adjust memory limits
kubectl patch daemonset alloy-logs \
  --patch '{"spec":{"template":{"spec":{"containers":[{"name":"alloy","resources":{"limits":{"memory":"2Gi"}}}]}}}}' \
  -n monitoring
```

#### Missing Metrics
```bash
# Check Alloy configuration
kubectl exec -n monitoring daemonset/alloy-logs -- \
  curl http://localhost:12345/api/v0/web/config

# Check targets
kubectl exec -n monitoring daemonset/alloy-logs -- \
  curl http://localhost:12345/api/v0/web/targets
```

#### Log Collection Issues
```bash
# Check log collection status
kubectl logs -n monitoring daemonset/alloy-logs -c alloy

# Verify volume mounts
kubectl describe daemonset alloy-logs -n monitoring
```

### Performance Tuning

#### Batch Processing
```yaml
processors:
  batch:
    size: 16384
    timeout: 2s
    
  memoryLimiter:
    enabled: true
    limit: 1Gi
```

#### Resource Optimization
```yaml
# Adjust resource requests/limits
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

## 🔗 Integration

### With Prometheus
```yaml
# ServiceMonitor for custom metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: metrics
      path: /metrics
```

### With OpenTelemetry
```yaml
# OpenTelemetry instrumentation
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-config
data:
  config.yaml: |
    exporters:
      otlp:
        endpoint: http://alloy:4317
        tls:
          insecure: true
```

## 📊 Dashboards

### Alloy Monitoring
- **Metrics**: Collection rates, error rates, resource usage
- **Logs**: Log ingestion rates, parsing errors
- **Traces**: Trace ingestion, processing latency

### Kubernetes Monitoring
- **Cluster Overview**: Node status, pod health, resource usage
- **Workload Monitoring**: Deployment status, replica counts
- **Resource Monitoring**: CPU, memory, storage usage

## 📚 Resources

### Official Documentation
- [k8s-monitoring Documentation](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/)
- [Helm Chart Values](https://github.com/grafana/helm-charts/tree/main/charts/k8s-monitoring)

### Configuration Examples
- [Auto-discovery Configuration](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/config-autodiscovery/)
- [Custom Metrics Collection](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/config-metrics/)

### Best Practices
- Use appropriate resource limits for Alloy pods
- Configure proper auto-discovery rules
- Monitor Alloy performance and adjust accordingly
- Implement proper RBAC and security policies
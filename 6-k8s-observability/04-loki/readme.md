# Loki - Log Aggregation System

## 📝 Overview
Grafana Loki is a horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus.

## 🏷️ Chart Information
- **Chart**: `grafana/loki`
- **Version**: `6.46.0`
- **App Version**: `3.3.1`
- **Namespace**: `monitoring`

## 🚀 Installation

### Prerequisites
```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create MinIO secret for object storage (development)
kubectl create secret generic minio-credentials \
  --from-literal=rootUser=minioadmin \
  --from-literal=rootPassword=minioadmin123 \
  -n monitoring
```

### Install Loki
```bash
# Install with custom values
helm install loki grafana/loki \
  -f loki-values.yml \
  -n monitoring

# Verify installation
kubectl get pods -n monitoring -l app.kubernetes.io/name=loki
```

## 🔗 Access

### Internal Services
- **Gateway**: `http://loki-gateway:80`
- **Query Frontend**: `http://loki-query-frontend:3100`
- **Distributor**: `http://loki-distributor:3100`

### API Endpoints
```bash
# Query logs
curl "http://loki-gateway:80/loki/api/v1/query?query={app=\"nginx\"}"

# Query range
curl "http://loki-gateway:80/loki/api/v1/query_range?query={app=\"nginx\"}&start=1h&end=now"

# Push logs
curl -X POST "http://loki-gateway:80/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  --data-raw '{"streams": [{"stream": {"job": "test"}, "values": [["1640995200000000000", "test log message"]]}]}'
```

## 🏗️ Architecture

### Components
- **Distributor**: Receives logs from clients
- **Ingester**: Writes logs to storage
- **Querier**: Queries logs from storage
- **Query Frontend**: Handles query requests and caching
- **Index Gateway**: Handles index queries
- **Compactor**: Compacts index files
- **Ruler**: Evaluates LogQL rules and alerts

### Storage
- **Chunks**: Log data stored in object storage
- **Index**: Index files for fast querying
- **Retention**: 30 days (configurable)

## 📊 Key Features

### LogQL Query Language
```logql
# Basic log stream selection
{app="nginx"}

# Filter by log content
{app="nginx"} |= "error"

# Regex filtering
{app="nginx"} |~ "error|warning"

# Metric queries
rate({app="nginx"}[5m])

# Aggregation
sum(rate({app="nginx"}[5m])) by (instance)
```

### Log Processing
- **Parsing**: JSON, regex, and structured parsing
- **Filtering**: Include/exclude log lines
- **Labeling**: Extract labels from log content
- **Metrics**: Generate metrics from logs

## 🔧 Configuration

### Log Ingestion
```yaml
# Promtail configuration for log collection
clients:
  - url: http://loki-gateway:80/loki/api/v1/push
    tenant_id: default

scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

### Storage Configuration
```yaml
# Object storage backend
storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
    shared_store: s3
  aws:
    s3: s3://loki-chunks
    region: us-east-1
```

## 📈 Monitoring

### Health Checks
```bash
# Check component health
kubectl exec -n monitoring deployment/loki-query-frontend -- \
  curl -f http://localhost:3100/ready

# Check ingestion
kubectl logs -n monitoring deployment/loki-distributor -f
```

### Metrics
- **Endpoint**: `/metrics`
- **Port**: `3100`
- **Scraping**: Auto-discovered by Prometheus

### Key Metrics to Monitor
```promql
# Ingestion rate
rate(loki_distributor_lines_received_total[5m])

# Query latency
histogram_quantile(0.99, rate(loki_request_duration_seconds_bucket[5m]))

# Storage usage
loki_ingester_memory_streams

# Error rate
rate(loki_request_duration_seconds_count{status_code!~"2.."}[5m])
```

## 🔍 LogQL Examples

### Basic Queries
```logql
# All logs from nginx pods
{app="nginx"}

# Error logs only
{app="nginx"} |= "error"

# Logs from specific namespace
{namespace="production"}

# Multiple label filters
{app="nginx", environment="prod"} |= "error"
```

### Advanced Queries
```logql
# Parse JSON logs
{app="api"} | json | status_code >= 400

# Extract fields with regex
{app="nginx"} | regexp "(?P<method>\\w+) (?P<path>\\S+)"

# Rate of error logs
rate({app="nginx"} |= "error" [5m])

# Top error messages
topk(10, sum by (error_message) (rate({app="api"} | json | level="error" [5m])))
```

### Alerting Rules
```yaml
# LogQL alerting rules
groups:
  - name: loki-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({app="api"} |= "error" [5m])) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High error rate detected
```

## 🔒 Security

### Multi-tenancy
```bash
# Send logs with tenant header
curl -X POST "http://loki-gateway:80/loki/api/v1/push" \
  -H "X-Scope-OrgID: tenant1" \
  -H "Content-Type: application/json" \
  --data-raw '{"streams": [...]}'
```

### Authentication
```yaml
# Basic auth configuration
auth_enabled: true
server:
  http_listen_port: 3100
  grpc_listen_port: 9095
```

## 🛠️ Troubleshooting

### Common Issues

#### High Memory Usage
```bash
# Check ingester memory
kubectl top pods -n monitoring -l app.kubernetes.io/component=ingester

# Scale ingesters
kubectl scale deployment loki-ingester --replicas=5 -n monitoring
```

#### Query Timeouts
```bash
# Check query frontend logs
kubectl logs -n monitoring deployment/loki-query-frontend -f

# Increase query timeout
kubectl patch configmap loki-config \
  --patch '{"data":{"loki.yaml":"query_range:\n  max_query_parallelism: 32"}}' \
  -n monitoring
```

#### Log Ingestion Issues
```bash
# Check distributor logs
kubectl logs -n monitoring deployment/loki-distributor -f

# Verify ingestion endpoint
kubectl exec -n monitoring deployment/loki-distributor -- \
  netstat -tlnp | grep 3100
```

### Performance Tuning

#### Ingestion Optimization
```yaml
# Increase distributor replicas
distributor:
  replicas: 5
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
```

#### Query Optimization
```yaml
# Enable query parallelization
query_range:
  parallelise_shardable_queries: true
  max_query_parallelism: 32
```

## 🔗 Integration

### With Grafana
```yaml
# Loki datasource configuration
- name: Loki
  type: loki
  url: http://loki-gateway:80
  jsonData:
    derivedFields:
      - name: TraceID
        matcherRegex: "traceID=(\\w+)"
        url: "$${__value.raw}"
        datasourceUid: tempo
```

### With Promtail
```yaml
# Promtail configuration
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki-gateway:80/loki/api/v1/push

scrape_configs:
  - job_name: containers
    static_configs:
      - targets:
          - localhost
        labels:
          job: containerlogs
          __path__: /var/log/containers/*log
```

## 📚 Resources

### Official Documentation
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Helm Chart Values](https://github.com/grafana/helm-charts/tree/main/charts/loki)

### LogQL Documentation
- [LogQL Guide](https://grafana.com/docs/loki/latest/logql/)
- [Query Examples](https://grafana.com/docs/loki/latest/logql/examples/)

### Best Practices
- Use appropriate log retention policies
- Implement proper log parsing and labeling
- Monitor ingestion and query performance
- Set up alerting for log-based metrics
# Tempo - Distributed Tracing

## 🔍 Overview
Grafana Tempo is a high-scale distributed tracing backend that ingests traces in multiple formats and provides efficient storage and querying.

## 🏷️ Chart Information
- **Chart**: `grafana/tempo-distributed`
- **Version**: `1.56.0`
- **App Version**: `2.6.1`
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

### Install Tempo
```bash
# Install with custom values
helm install tempo grafana/tempo-distributed \
  -f tempo-values.yml \
  -n monitoring

# Verify installation
kubectl get pods -n monitoring -l app.kubernetes.io/name=tempo
```

## 🔗 Access

### Internal Services
- **Query Frontend**: `http://tempo-query-frontend:3200`
- **Gateway**: `http://tempo-gateway:80`
- **Distributor**: `http://tempo-distributor:3200`

### API Endpoints
```bash
# Search traces
curl "http://tempo-query-frontend:3200/api/search?tags=service.name=my-service"

# Get trace by ID
curl "http://tempo-query-frontend:3200/api/traces/trace-id"

# Health check
curl "http://tempo-query-frontend:3200/ready"
```

## 🏗️ Architecture

### Components
- **Distributor**: Receives traces from applications
- **Ingester**: Writes traces to storage
- **Querier**: Queries traces from storage
- **Query Frontend**: Handles query requests and caching
- **Compactor**: Compacts blocks in object storage
- **Metrics Generator**: Generates metrics from traces

### Storage
- **Short-term**: In-memory + local disk
- **Long-term**: MinIO S3-compatible storage
- **Retention**: 30 days (configurable)

## 📊 Key Features

### Trace Ingestion
- **OTLP**: OpenTelemetry Protocol (gRPC/HTTP)
- **Jaeger**: Native Jaeger formats
- **Zipkin**: Zipkin JSON format
- **Rate Limiting**: Per-tenant ingestion limits

### Query Capabilities
- **TraceQL**: Powerful trace query language
- **Service Map**: Automatic service dependency mapping
- **Metrics Generation**: RED metrics from traces

## 🔧 Configuration

### Ingestion Protocols
```yaml
# Enable multiple protocols
traces:
  otlp:
    grpc:
      enabled: true
      endpoint: 0.0.0.0:4317
    http:
      enabled: true
      endpoint: 0.0.0.0:4318
  jaeger:
    grpc:
      enabled: true
      endpoint: 0.0.0.0:14250
  zipkin:
    enabled: true
    endpoint: 0.0.0.0:9411
```

### Storage Configuration
```yaml
# Object storage backend
storage:
  trace:
    backend: s3
    s3:
      bucket: tempo-traces
      endpoint: minio:9000
      access_key: minioadmin
      secret_key: minioadmin123
      insecure: true
```

## 📈 Monitoring

### Health Checks
```bash
# Check component health
kubectl exec -n monitoring deployment/tempo-query-frontend -- \
  curl -f http://localhost:3200/ready

# Check ingestion
kubectl logs -n monitoring deployment/tempo-distributor -f
```

### Metrics
- **Endpoint**: `/metrics`
- **Port**: `3200`
- **Scraping**: Auto-discovered by Prometheus

### Key Metrics to Monitor
```promql
# Ingestion rate
rate(tempo_distributor_spans_received_total[5m])

# Query latency
histogram_quantile(0.99, rate(tempo_request_duration_seconds_bucket[5m]))

# Storage usage
tempo_ingester_blocks_per_compactor

# Error rate
rate(tempo_request_duration_seconds_count{status_code!~"2.."}[5m])
```

## 🔍 TraceQL Examples

### Basic Queries
```traceql
# Find traces for a specific service
{ service.name = "frontend" }

# Find slow traces
{ duration > 1s }

# Find error traces
{ status = error }

# Complex query
{ service.name = "frontend" && duration > 500ms && span.http.status_code >= 400 }
```

### Service Map Queries
```traceql
# Find all services calling a specific service
{ span.service.name = "database" } | by(service.name)

# Find traces with specific tags
{ span.http.method = "POST" && span.http.route = "/api/users" }
```

## 🎯 Metrics Generation

### RED Metrics
```yaml
# Generate RED metrics from traces
metricsGenerator:
  enabled: true
  config:
    processor:
      span_metrics:
        dimensions:
          - http.method
          - http.status_code
          - service.version
      service_graphs:
        dimensions:
          - http.method
          - http.status_code
```

### Custom Metrics
```yaml
# Custom metric generation
processor:
  span_metrics:
    histogram_buckets: [0.1, 0.5, 1.0, 2.5, 5.0, 10.0]
    dimensions:
      - service.name
      - operation
      - span.kind
```

## 🔒 Security

### Multi-tenancy
```bash
# Send traces with tenant header
curl -X POST http://tempo-distributor:3200/v1/traces \
  -H "X-Scope-OrgID: tenant1" \
  -H "Content-Type: application/x-protobuf" \
  --data-binary @traces.pb
```

### Network Policies
```yaml
# Allow ingress from applications
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tempo-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: tempo
  ingress:
    - from: []
      ports:
        - protocol: TCP
          port: 4317
        - protocol: TCP
          port: 4318
```

## 🛠️ Troubleshooting

### Common Issues

#### High Memory Usage
```bash
# Check ingester memory
kubectl top pods -n monitoring -l app.kubernetes.io/component=ingester

# Scale ingesters
kubectl scale deployment tempo-ingester --replicas=5 -n monitoring
```

#### Query Timeouts
```bash
# Check query frontend logs
kubectl logs -n monitoring deployment/tempo-query-frontend -f

# Increase query timeout
kubectl patch configmap tempo-config \
  --patch '{"data":{"tempo.yaml":"query_frontend:\n  max_outstanding_per_tenant: 2000"}}' \
  -n monitoring
```

#### Trace Ingestion Issues
```bash
# Check distributor logs
kubectl logs -n monitoring deployment/tempo-distributor -f

# Verify OTLP endpoint
kubectl exec -n monitoring deployment/tempo-distributor -- \
  netstat -tlnp | grep 4317
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
# Enable query sharding
query_frontend:
  search:
    concurrent_jobs: 1000
    target_bytes_per_job: 104857600
```

## 🔗 Integration

### With Grafana
```yaml
# Tempo datasource configuration
- name: Tempo
  type: tempo
  url: http://tempo-query-frontend:3200
  jsonData:
    tracesToLogs:
      datasourceUid: loki
      filterByTraceID: true
    serviceMap:
      datasourceUid: prometheus
```

### With Loki
```yaml
# Derived fields for trace correlation
derivedFields:
  - name: TraceID
    matcherRegex: "traceID=(\\w+)"
    url: "$${__value.raw}"
    datasourceUid: tempo
```

## 📚 Resources

### Official Documentation
- [Tempo Documentation](https://grafana.com/docs/tempo/latest/)
- [Helm Chart Values](https://github.com/grafana/helm-charts/tree/main/charts/tempo-distributed)

### TraceQL Documentation
- [TraceQL Guide](https://grafana.com/docs/tempo/latest/traceql/)
- [Query Examples](https://grafana.com/docs/tempo/latest/traceql/examples/)

### Best Practices
- Use appropriate sampling rates
- Implement proper trace correlation
- Monitor ingestion and query performance
- Set up alerting for trace errors
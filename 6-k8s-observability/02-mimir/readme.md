# Mimir - Long-term Metrics Storage

## 📊 Overview
Grafana Mimir is a horizontally scalable, highly available, multi-tenant TSDB for long-term storage of Prometheus metrics.

## 🏷️ Chart Information
- **Chart**: `grafana/mimir-distributed`
- **Version**: `6.0.3`
- **App Version**: `2.14.1`
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

### Install Mimir
```bash
# Install with custom values
helm install mimir grafana/mimir-distributed \
  -f mimir-values.yml \
  -n monitoring

# Verify installation
kubectl get pods -n monitoring -l app.kubernetes.io/name=mimir
```

## 🔗 Access

### Internal Services
- **Query Frontend**: `http://mimir-query-frontend:8080`
- **Nginx Gateway**: `http://mimir-nginx:80`
- **Distributor**: `http://mimir-distributor:8080`

### API Endpoints
```bash
# Prometheus-compatible query API
curl http://mimir-nginx:80/prometheus/api/v1/query?query=up

# Admin API
curl http://mimir-nginx:80/api/v1/status/config

# Alertmanager API
curl http://mimir-nginx:80/alertmanager/api/v1/alerts
```

## 🏗️ Architecture

### Components
- **Distributor**: Receives metrics from Prometheus
- **Ingester**: Writes metrics to storage
- **Querier**: Queries metrics from storage
- **Query Frontend**: Handles query requests
- **Compactor**: Compacts blocks in object storage
- **Store Gateway**: Queries long-term storage
- **Alertmanager**: Handles alerts
- **Ruler**: Evaluates recording/alerting rules

### Storage
- **Short-term**: In-memory + local disk
- **Long-term**: MinIO S3-compatible storage
- **Retention**: 90 days (configurable)

## 📊 Key Features

### Multi-tenancy
```bash
# Send metrics with tenant header
curl -X POST http://mimir-nginx:80/api/v1/push \
  -H "X-Scope-OrgID: tenant1" \
  -H "Content-Type: application/x-protobuf" \
  --data-binary @metrics.pb
```

### High Availability
- **Replication Factor**: 3 (configurable)
- **Zone Awareness**: Enabled
- **Auto-scaling**: HPA configured

### Performance
- **Ingestion Rate**: 1M samples/sec
- **Query Performance**: Parallel processing
- **Caching**: Multi-level caching strategy

## 🔧 Configuration

### Limits Configuration
```yaml
# Per-tenant limits
limits:
  ingestion_rate: 100000
  ingestion_burst_size: 200000
  max_global_series_per_user: 1000000
  max_global_series_per_metric: 50000
```

### Storage Configuration
```yaml
# Object storage backend
blocks_storage:
  backend: s3
  s3:
    endpoint: minio:9000
    bucket_name: mimir-blocks
    access_key_id: minioadmin
    secret_access_key: minioadmin123
    insecure: true
```

## 📈 Monitoring

### Health Checks
```bash
# Check component health
kubectl exec -n monitoring deployment/mimir-query-frontend -- \
  curl -f http://localhost:8080/ready

# Check ingestion
kubectl logs -n monitoring deployment/mimir-distributor -f
```

### Metrics
- **Endpoint**: `/metrics`
- **Port**: `8080`
- **Scraping**: Auto-discovered by Prometheus

### Key Metrics to Monitor
```promql
# Ingestion rate
rate(cortex_distributor_samples_in_total[5m])

# Query latency
histogram_quantile(0.99, rate(cortex_request_duration_seconds_bucket[5m]))

# Storage usage
cortex_ingester_memory_series

# Error rate
rate(cortex_request_duration_seconds_count{status_code!~"2.."}[5m])
```

## 🔒 Security

### Authentication
- **Basic Auth**: Username/password
- **Multi-tenancy**: X-Scope-OrgID header
- **TLS**: Optional for internal communication

### Network Policies
```yaml
# Allow ingress from Prometheus
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mimir-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: mimir
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: prometheus
```

## 🛠️ Troubleshooting

### Common Issues

#### High Memory Usage
```bash
# Check ingester memory
kubectl top pods -n monitoring -l app.kubernetes.io/component=ingester

# Scale ingesters
kubectl scale deployment mimir-ingester --replicas=5 -n monitoring
```

#### Query Timeouts
```bash
# Check query frontend logs
kubectl logs -n monitoring deployment/mimir-query-frontend -f

# Increase query timeout
kubectl patch configmap mimir-config \
  --patch '{"data":{"mimir.yaml":"query_frontend:\n  max_outstanding_requests_per_tenant: 1000"}}' \
  -n monitoring
```

#### Storage Issues
```bash
# Check compactor status
kubectl logs -n monitoring deployment/mimir-compactor -f

# Verify MinIO connectivity
kubectl exec -n monitoring deployment/mimir-compactor -- \
  curl -v http://minio:9000/minio/health/live
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
  parallelize_shardable_queries: true
  
# Increase cache size
frontend:
  results_cache:
    backend: memcached
    memcached:
      addresses: memcached:11211
```

## 📚 Resources

### Official Documentation
- [Mimir Documentation](https://grafana.com/docs/mimir/latest/)
- [Helm Chart Values](https://github.com/grafana/helm-charts/tree/main/charts/mimir-distributed)

### Configuration Examples
- [Production Configuration](https://grafana.com/docs/mimir/latest/operators-guide/configure/configure-mimir/)
- [Scaling Guide](https://grafana.com/docs/mimir/latest/operators-guide/run-production-environment/scaling-out/)

### Best Practices
- Use appropriate retention policies
- Monitor ingestion and query performance
- Implement proper alerting rules
- Regular backup of configuration and rules
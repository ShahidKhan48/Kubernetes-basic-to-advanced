# Monitoring Troubleshooting Guide

## Prometheus Issues

### 1. Prometheus Not Scraping Targets

**Symptoms:**
- Missing metrics for services
- Targets showing as down
- Incomplete monitoring data

**Diagnosis:**
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check ServiceMonitor configuration
kubectl get servicemonitors -A
kubectl describe servicemonitor <servicemonitor-name>

# Check service labels
kubectl get services --show-labels
```

**Common Causes & Solutions:**

#### Service Labels Mismatch
```bash
# Check service labels match ServiceMonitor selector
kubectl get service <service-name> -o yaml | grep -A5 labels
kubectl get servicemonitor <servicemonitor-name> -o yaml | grep -A5 selector
```

#### Network Policy Blocking
```bash
# Check if network policies block Prometheus
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name>

# Create allow rule for Prometheus
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus
spec:
  podSelector:
    matchLabels:
      app: prometheus
  policyTypes:
  - Egress
  egress:
  - {}
```

#### Incorrect Port Configuration
```bash
# Verify service port matches ServiceMonitor
kubectl get service <service-name> -o yaml | grep -A5 ports
kubectl get servicemonitor <servicemonitor-name> -o yaml | grep -A5 endpoints
```

### 2. Prometheus Storage Issues

**Diagnosis:**
```bash
# Check Prometheus storage
kubectl get pvc -n monitoring
kubectl describe pvc prometheus-storage

# Check disk usage
kubectl exec -n monitoring prometheus-0 -- df -h
```

**Solutions:**
```bash
# Expand PVC if supported
kubectl patch pvc prometheus-storage -n monitoring -p '{"spec":{"resources":{"requests":{"storage":"200Gi"}}}}'

# Reduce retention period
kubectl patch prometheus prometheus -n monitoring --type='json' -p='[{"op": "replace", "path": "/spec/retention", "value": "15d"}]'
```

### 3. High Cardinality Issues

**Diagnosis:**
```bash
# Check series count
curl http://prometheus:9090/api/v1/label/__name__/values | jq '.data | length'

# Find high cardinality metrics
curl http://prometheus:9090/api/v1/query?query=topk\(10,count+by+\(__name__\)\(\{__name__=~\".%2B\"\}\)\)
```

**Solutions:**
```bash
# Add metric relabeling to drop high cardinality labels
spec:
  serviceMonitorSelector: {}
  ruleSelector: {}
  additionalScrapeConfigs:
  - job_name: 'kubernetes-pods'
    metric_relabel_configs:
    - source_labels: [__name__]
      regex: 'high_cardinality_metric.*'
      action: drop
```

## Grafana Issues

### 1. Grafana Dashboard Not Loading

**Diagnosis:**
```bash
# Check Grafana pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring deployment/grafana

# Check Grafana service
kubectl get service grafana -n monitoring
kubectl port-forward -n monitoring svc/grafana 3000:80
```

**Common Issues:**
- Database connection problems
- Plugin loading failures
- Configuration errors

**Solutions:**
```bash
# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring

# Check Grafana configuration
kubectl get configmap grafana -n monitoring -o yaml

# Reset Grafana admin password
kubectl exec -n monitoring deployment/grafana -- grafana-cli admin reset-admin-password newpassword
```

### 2. Data Source Connection Issues

**Diagnosis:**
```bash
# Test data source connectivity from Grafana pod
kubectl exec -n monitoring deployment/grafana -- curl -v http://prometheus:9090/api/v1/query?query=up

# Check data source configuration
# Access Grafana UI -> Configuration -> Data Sources
```

**Solutions:**
```bash
# Update data source URL
# Ensure Prometheus service is accessible
kubectl get service prometheus -n monitoring

# Check network policies
kubectl get networkpolicies -n monitoring
```

### 3. Dashboard Import Issues

**Diagnosis:**
```bash
# Check dashboard ConfigMaps
kubectl get configmaps -n monitoring -l grafana_dashboard=1

# Check Grafana sidecar logs
kubectl logs -n monitoring deployment/grafana -c grafana-sc-dashboard
```

**Solutions:**
```bash
# Recreate dashboard ConfigMap
kubectl delete configmap <dashboard-configmap> -n monitoring
kubectl apply -f dashboard-configmap.yaml

# Restart Grafana sidecar
kubectl rollout restart deployment/grafana -n monitoring
```

## Alertmanager Issues

### 1. Alerts Not Firing

**Diagnosis:**
```bash
# Check Prometheus rules
kubectl get prometheusrules -A
kubectl describe prometheusrule <rule-name>

# Check alert status in Prometheus
# Visit http://prometheus:9090/alerts

# Check Alertmanager
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
# Visit http://localhost:9093
```

**Common Causes:**
- Incorrect alert rules
- Missing labels
- Threshold not met

**Solutions:**
```bash
# Test alert rule
promtool query instant http://prometheus:9090 'up == 0'

# Check rule syntax
promtool check rules alert-rules.yaml
```

### 2. Alert Notifications Not Sent

**Diagnosis:**
```bash
# Check Alertmanager configuration
kubectl get secret alertmanager-alertmanager -n monitoring -o yaml

# Check Alertmanager logs
kubectl logs -n monitoring alertmanager-alertmanager-0
```

**Common Issues:**
- Incorrect webhook URLs
- Authentication failures
- Network connectivity

**Solutions:**
```bash
# Test webhook manually
kubectl exec -n monitoring alertmanager-alertmanager-0 -- curl -X POST <webhook-url> -d '{"text":"test"}'

# Update Alertmanager configuration
kubectl create secret generic alertmanager-alertmanager --from-file=alertmanager.yml -n monitoring --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Alert Routing Issues

**Diagnosis:**
```bash
# Check routing configuration
kubectl get secret alertmanager-alertmanager -n monitoring -o jsonpath='{.data.alertmanager\.yml}' | base64 -d

# Test routing
# Use Alertmanager UI to check routing tree
```

**Solutions:**
```bash
# Update routing rules
# Ensure matchers are correct
# Check receiver configurations
```

## Metrics Server Issues

### 1. Metrics Server Not Working

**Diagnosis:**
```bash
# Check metrics server pods
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl logs -n kube-system deployment/metrics-server

# Test metrics API
kubectl top nodes
kubectl top pods
```

**Common Issues:**
- TLS certificate problems
- Kubelet connectivity issues
- Resource constraints

**Solutions:**
```bash
# Add insecure TLS flag (development only)
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Check kubelet configuration
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
```

### 2. Missing Resource Metrics

**Diagnosis:**
```bash
# Check if metrics are available
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods

# Check kubelet metrics endpoint
kubectl get --raw /api/v1/nodes/<node-name>/proxy/metrics/resource
```

**Solutions:**
```bash
# Restart metrics server
kubectl rollout restart deployment/metrics-server -n kube-system

# Check kubelet configuration
systemctl status kubelet
journalctl -u kubelet -f
```

## Custom Metrics Issues

### 1. Custom Metrics API Not Available

**Diagnosis:**
```bash
# Check custom metrics API
kubectl get apiservices | grep custom.metrics
kubectl describe apiservice v1beta1.custom.metrics.k8s.io

# Check adapter pods
kubectl get pods -n monitoring -l app=prometheus-adapter
kubectl logs -n monitoring deployment/prometheus-adapter
```

**Solutions:**
```bash
# Restart prometheus adapter
kubectl rollout restart deployment/prometheus-adapter -n monitoring

# Check adapter configuration
kubectl get configmap adapter-config -n monitoring -o yaml
```

### 2. HPA Not Scaling on Custom Metrics

**Diagnosis:**
```bash
# Check HPA status
kubectl describe hpa <hpa-name>
kubectl get hpa <hpa-name> -o yaml

# Test custom metrics query
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/<namespace>/pods/*/http_requests_per_second"
```

**Solutions:**
```bash
# Verify metric name and query
# Check if metric exists in Prometheus
# Update HPA configuration
```

## Log Collection Issues

### 1. Fluent Bit Not Collecting Logs

**Diagnosis:**
```bash
# Check Fluent Bit pods
kubectl get pods -n logging -l app=fluent-bit
kubectl logs -n logging daemonset/fluent-bit

# Check log files on nodes
kubectl exec -n logging <fluent-bit-pod> -- ls -la /var/log/containers/
```

**Common Issues:**
- Log file permissions
- Configuration errors
- Output destination problems

**Solutions:**
```bash
# Check Fluent Bit configuration
kubectl get configmap fluent-bit -n logging -o yaml

# Test log parsing
kubectl exec -n logging <fluent-bit-pod> -- fluent-bit --config=/fluent-bit/etc/fluent-bit.conf --dry-run
```

### 2. Loki Storage Issues

**Diagnosis:**
```bash
# Check Loki pods
kubectl get pods -n logging -l app=loki
kubectl logs -n logging deployment/loki

# Check Loki storage
kubectl get pvc -n logging
kubectl describe pvc loki-storage
```

**Solutions:**
```bash
# Expand Loki storage
kubectl patch pvc loki-storage -n logging -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'

# Configure retention policy
# Update Loki configuration
```

## Jaeger Tracing Issues

### 1. Traces Not Appearing

**Diagnosis:**
```bash
# Check Jaeger components
kubectl get pods -n observability -l app=jaeger
kubectl logs -n observability deployment/jaeger-collector

# Check trace ingestion
kubectl port-forward -n observability svc/jaeger-query 16686:16686
# Visit http://localhost:16686
```

**Common Issues:**
- Application not instrumented
- Sampling rate too low
- Network connectivity

**Solutions:**
```bash
# Check application instrumentation
kubectl logs <app-pod> | grep -i jaeger

# Increase sampling rate
# Update Jaeger configuration
```

### 2. Jaeger Storage Issues

**Diagnosis:**
```bash
# Check Elasticsearch/storage backend
kubectl get pods -n observability -l app=elasticsearch
kubectl logs -n observability deployment/elasticsearch

# Check storage usage
kubectl exec -n observability <elasticsearch-pod> -- df -h
```

**Solutions:**
```bash
# Clean up old traces
# Increase storage capacity
# Configure retention policies
```

## Monitoring Troubleshooting Tools

### Debug Monitoring Stack
```bash
#!/bin/bash
echo "=== Monitoring Stack Health Check ==="

echo "Prometheus:"
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
kubectl get servicemonitors -A --no-headers | wc -l
echo "ServiceMonitors found: $(kubectl get servicemonitors -A --no-headers | wc -l)"

echo "Grafana:"
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

echo "Alertmanager:"
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager

echo "Metrics Server:"
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl top nodes --no-headers | wc -l
echo "Nodes with metrics: $(kubectl top nodes --no-headers | wc -l)"
```

### Metrics Validation
```bash
# Check if metrics are being scraped
curl -s http://prometheus:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up") | {job: .labels.job, health: .health, lastError: .lastError}'

# Check metric cardinality
curl -s http://prometheus:9090/api/v1/label/__name__/values | jq '.data | length'

# Test alert rules
promtool query instant http://prometheus:9090 'ALERTS{alertstate="firing"}'
```

## Common Monitoring Fixes

### Restart Monitoring Components
```bash
# Restart Prometheus
kubectl rollout restart statefulset/prometheus-prometheus -n monitoring

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring

# Restart Alertmanager
kubectl rollout restart statefulset/alertmanager-alertmanager -n monitoring

# Restart Metrics Server
kubectl rollout restart deployment/metrics-server -n kube-system
```

### Reset Monitoring Configuration
```bash
# Recreate ServiceMonitor
kubectl delete servicemonitor <servicemonitor-name> -n monitoring
kubectl apply -f servicemonitor.yaml

# Update Prometheus rules
kubectl delete prometheusrule <rule-name> -n monitoring
kubectl apply -f prometheus-rules.yaml

# Reset Grafana dashboards
kubectl delete configmap <dashboard-configmap> -n monitoring
kubectl apply -f dashboard-configmap.yaml
```

## Monitoring Best Practices

### Health Checks
- Monitor monitoring stack itself
- Set up alerts for monitoring failures
- Regular backup of configurations
- Test alert delivery regularly

### Performance Optimization
- Monitor metric cardinality
- Optimize query performance
- Configure appropriate retention
- Use recording rules for complex queries
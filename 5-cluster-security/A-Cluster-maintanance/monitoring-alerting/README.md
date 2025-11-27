# Monitoring & Alerting

## 📚 Overview
Kubernetes cluster monitoring, metrics collection aur alerting setup.

## 🎯 Monitoring Components

### Prometheus Setup
```yaml
# Prometheus deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v2.40.0
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: storage
          mountPath: /prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: storage
        emptyDir: {}
```

### Grafana Dashboard
```yaml
# Grafana deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:9.0.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
```

### Alert Rules
```yaml
# AlertManager configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'smtp.spicybiryaniwala.shop:587'
      smtp_from: 'alerts@spicybiryaniwala.shop'
    
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
    
    receivers:
    - name: 'web.hook'
      email_configs:
      - to: 'admin@spicybiryaniwala.shop'
        subject: 'Cluster Alert: {{ .GroupLabels.alertname }}'
```

## 🔧 Health Checks

### Cluster Health Commands
```bash
# Component status
kubectl get componentstatuses

# Node health
kubectl get nodes -o wide
kubectl top nodes

# Pod health
kubectl get pods --all-namespaces
kubectl top pods --all-namespaces

# API server health
curl -k https://localhost:6443/healthz

# etcd health
ETCDCTL_API=3 etcdctl endpoint health
```

### Custom Health Check
```bash
#!/bin/bash
# Cluster health check script

echo "=== Kubernetes Cluster Health Check ==="

# Check API server
if kubectl cluster-info >/dev/null 2>&1; then
  echo "✅ API Server: Healthy"
else
  echo "❌ API Server: Unhealthy"
fi

# Check nodes
READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready ")
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
echo "📊 Nodes: $READY_NODES/$TOTAL_NODES Ready"

# Check system pods
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers | grep -c "Running")
echo "📊 System Pods Running: $SYSTEM_PODS"

# Check resource usage
echo "📊 Resource Usage:"
kubectl top nodes --no-headers | awk '{print "  Node " $1 ": CPU " $3 ", Memory " $5}'
```

## 📊 Metrics Collection

### Key Metrics to Monitor
- **Cluster Level**: API server latency, etcd performance
- **Node Level**: CPU, memory, disk usage
- **Pod Level**: Container restarts, resource usage
- **Application Level**: Request rate, error rate, latency

### Monitoring Commands
```bash
# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Events monitoring
kubectl get events --sort-by=.metadata.creationTimestamp

# Logs monitoring
kubectl logs -n kube-system -l component=kube-apiserver
```

## 📋 Best Practices
- Monitor all cluster components
- Set appropriate alert thresholds
- Use multiple notification channels
- Regular dashboard reviews
- Automated health checks
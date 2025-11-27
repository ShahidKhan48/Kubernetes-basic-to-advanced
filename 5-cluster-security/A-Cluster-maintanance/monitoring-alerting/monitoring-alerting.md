# Monitoring & Alerting - Cluster Health Monitoring

## 📚 Overview
Kubernetes cluster health monitoring aur alerting setup. Cluster components, nodes, security events aur performance metrics ki comprehensive monitoring.

## 🎯 Monitoring Components

### 1. **Cluster Components**
- API Server health
- etcd cluster status
- Controller Manager
- Scheduler health
- kubelet status

### 2. **Node Monitoring**
- Resource utilization
- Disk space
- Network connectivity
- System services

### 3. **Security Events**
- Failed authentication
- RBAC violations
- Pod security violations
- Network policy violations

## 📖 Monitoring Setup

### Prometheus Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
    - "/etc/prometheus/rules/*.yml"
    
    scrape_configs:
    # Kubernetes API Server
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
    
    # Kubelet metrics
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
    
    # etcd monitoring
    - job_name: 'etcd'
      static_configs:
      - targets: ['etcd:2379']
      scheme: https
      tls_config:
        ca_file: /etc/kubernetes/pki/etcd/ca.crt
        cert_file: /etc/kubernetes/pki/etcd/server.crt
        key_file: /etc/kubernetes/pki/etcd/server.key
```

### Alert Rules
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: monitoring
data:
  cluster-alerts.yml: |
    groups:
    - name: cluster.rules
      rules:
      # API Server alerts
      - alert: KubernetesAPIServerDown
        expr: up{job="kubernetes-apiservers"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Kubernetes API Server is down"
          description: "API Server has been down for more than 5 minutes"
      
      # etcd alerts
      - alert: EtcdClusterUnavailable
        expr: etcd_server_has_leader == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "etcd cluster has no leader"
          description: "etcd cluster is unavailable"
      
      # Node alerts
      - alert: NodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node {{ $labels.node }} is not ready"
          description: "Node has been not ready for more than 5 minutes"
      
      # Disk space alerts
      - alert: NodeDiskSpaceHigh
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node {{ $labels.instance }} disk space is low"
          description: "Disk space is below 10%"
      
      # Memory alerts
      - alert: NodeMemoryHigh
        expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node {{ $labels.instance }} memory usage is high"
          description: "Memory usage is above 90%"
```

## 🔧 Commands

### Health Checks
```bash
# Cluster component status
kubectl get componentstatuses

# Node health
kubectl get nodes
kubectl describe nodes

# System pods
kubectl get pods -n kube-system

# API server health
curl -k https://localhost:6443/healthz

# etcd health
ETCDCTL_API=3 etcdctl endpoint health
```

### Monitoring Commands
```bash
# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Events monitoring
kubectl get events --sort-by=.metadata.creationTimestamp

# Logs monitoring
kubectl logs -n kube-system -l component=kube-apiserver
kubectl logs -n kube-system -l component=etcd
```

## 📊 Dashboards

### Cluster Overview Dashboard
```json
{
  "dashboard": {
    "title": "Kubernetes Cluster Overview",
    "panels": [
      {
        "title": "Cluster Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"kubernetes-apiservers\"}"
          }
        ]
      },
      {
        "title": "Node Status",
        "type": "stat",
        "targets": [
          {
            "expr": "kube_node_status_condition{condition=\"Ready\",status=\"true\"}"
          }
        ]
      },
      {
        "title": "Pod Status",
        "type": "stat",
        "targets": [
          {
            "expr": "kube_pod_status_phase"
          }
        ]
      }
    ]
  }
}
```

## 🚨 Alerting Setup

### AlertManager Configuration
```yaml
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
      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'
    
    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://webhook-service:5000/alerts'
    
    - name: 'critical-alerts'
      email_configs:
      - to: 'oncall@spicybiryaniwala.shop'
        subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
      slack_configs:
      - api_url: 'https://hooks.slack.com/services/...'
        channel: '#alerts-critical'
        title: 'Critical Alert'
        text: '{{ .CommonAnnotations.summary }}'
    
    - name: 'warning-alerts'
      email_configs:
      - to: 'team@spicybiryaniwala.shop'
        subject: 'WARNING: {{ .GroupLabels.alertname }}'
```

## 📋 Best Practices

### 1. **Monitoring Strategy**
- Monitor all cluster components
- Set appropriate thresholds
- Use multiple notification channels
- Regular dashboard reviews

### 2. **Alert Management**
- Prioritize alerts by severity
- Avoid alert fatigue
- Document runbooks
- Regular alert tuning

### 3. **Data Retention**
- Long-term metric storage
- Log aggregation
- Backup monitoring data
- Compliance requirements

### 4. **Performance**
- Optimize query performance
- Use recording rules
- Efficient dashboards
- Resource allocation
# Performance Troubleshooting Guide

## Application Performance Issues

### 1. High Response Times

**Diagnosis:**
```bash
# Check application metrics
kubectl top pods -n <namespace>
kubectl describe pod <pod-name>

# Check resource utilization
kubectl exec <pod-name> -- top
kubectl exec <pod-name> -- free -h
```

**Common Causes:**
- CPU throttling
- Memory pressure
- I/O bottlenecks
- Network latency

**Solutions:**
```bash
# Increase resource limits
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"limits":{"cpu":"2","memory":"2Gi"}}}]}}}}'

# Check for CPU throttling
kubectl exec <pod-name> -- cat /sys/fs/cgroup/cpu/cpu.stat | grep throttled
```

### 2. Memory Issues

**Out of Memory (OOM) Kills:**
```bash
# Check for OOM events
kubectl get events | grep OOMKilling
dmesg | grep -i "killed process"

# Check memory usage
kubectl top pods --sort-by=memory
kubectl exec <pod-name> -- cat /proc/meminfo
```

**Memory Leaks:**
```bash
# Monitor memory usage over time
kubectl exec <pod-name> -- ps aux --sort=-%mem | head -10

# Check heap dumps (Java applications)
kubectl exec <pod-name> -- jcmd <pid> GC.run_finalization
kubectl exec <pod-name> -- jcmd <pid> VM.gc
```

**Solutions:**
```bash
# Increase memory limits
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"limits":{"memory":"4Gi"}}}]}}}}'

# Enable memory profiling
# Add environment variables for profiling
```

### 3. CPU Performance Issues

**High CPU Usage:**
```bash
# Check CPU usage
kubectl top pods --sort-by=cpu
kubectl exec <pod-name> -- top -p <pid>

# Check CPU throttling
kubectl describe pod <pod-name> | grep -A5 "Limits"
```

**CPU Throttling:**
```bash
# Check throttling metrics
kubectl exec <pod-name> -- cat /sys/fs/cgroup/cpu/cpu.stat

# Monitor CPU usage patterns
kubectl exec <pod-name> -- sar -u 1 10
```

**Solutions:**
```bash
# Increase CPU limits
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"limits":{"cpu":"4"}}}]}}}}'

# Optimize application code
# Use profiling tools to identify bottlenecks
```

## Cluster Performance Issues

### 1. Node Performance

**High Node Resource Usage:**
```bash
# Check node resources
kubectl top nodes
kubectl describe node <node-name> | grep -A10 "Allocated resources"

# Check system processes
ssh <node> "top -b -n1 | head -20"
ssh <node> "iostat -x 1 5"
```

**Disk I/O Issues:**
```bash
# Check disk usage
kubectl exec <pod-name> -- df -h
ssh <node> "iotop -a -o -d 1"

# Check for disk pressure
kubectl describe node <node-name> | grep DiskPressure
```

**Solutions:**
```bash
# Add more nodes
# Optimize disk I/O
# Use faster storage classes
# Implement pod disruption budgets
```

### 2. Network Performance

**High Network Latency:**
```bash
# Test network latency
kubectl run ping-test --image=busybox --rm -it --restart=Never -- ping -c 10 <target-ip>

# Check network interface statistics
kubectl exec <pod-name> -- cat /proc/net/dev
```

**Network Bandwidth Issues:**
```bash
# Test bandwidth
kubectl run iperf-server --image=networkstatic/iperf3 --port=5201
kubectl run iperf-client --image=networkstatic/iperf3 --rm -it --restart=Never -- iperf3 -c <server-ip>

# Check network policies impact
kubectl get networkpolicies -A
```

### 3. API Server Performance

**Slow API Responses:**
```bash
# Check API server metrics
kubectl get --raw /metrics | grep apiserver_request_duration_seconds

# Check API server load
kubectl top pods -n kube-system | grep apiserver
kubectl logs -n kube-system kube-apiserver-<master> | grep -i slow
```

**Solutions:**
```bash
# Increase API server resources
# Optimize etcd performance
# Reduce API call frequency
# Use informers instead of polling
```

## Database Performance Issues

### 1. Database Connection Issues

**Connection Pool Exhaustion:**
```bash
# Check database connections
kubectl exec <db-pod> -- psql -c "SELECT count(*) FROM pg_stat_activity;"
kubectl exec <db-pod> -- mysql -e "SHOW PROCESSLIST;"

# Check application connection pools
kubectl logs <app-pod> | grep -i connection
```

**Solutions:**
```bash
# Increase connection pool size
# Implement connection pooling (PgBouncer, ProxySQL)
# Optimize query performance
```

### 2. Database Query Performance

**Slow Queries:**
```bash
# Enable slow query logging
kubectl exec <db-pod> -- mysql -e "SET GLOBAL slow_query_log = 'ON';"
kubectl exec <db-pod> -- psql -c "ALTER SYSTEM SET log_min_duration_statement = 1000;"

# Check query performance
kubectl exec <db-pod> -- mysqldumpslow /var/log/mysql/slow.log
kubectl exec <db-pod> -- psql -c "SELECT query, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

## Monitoring Performance

### 1. Key Performance Metrics

**Application Metrics:**
```bash
# Response time percentiles
# Error rates
# Throughput (requests per second)
# Resource utilization
```

**Infrastructure Metrics:**
```bash
# CPU usage and throttling
# Memory usage and OOM kills
# Disk I/O and latency
# Network throughput and latency
```

### 2. Performance Monitoring Tools

**Prometheus Queries:**
```promql
# CPU throttling
rate(container_cpu_cfs_throttled_seconds_total[5m])

# Memory usage
container_memory_usage_bytes / container_spec_memory_limit_bytes

# Request latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**Grafana Dashboards:**
- Kubernetes cluster overview
- Application performance
- Database performance
- Network performance

## Performance Optimization

### 1. Resource Optimization

**Right-sizing Resources:**
```bash
# Use VPA recommendations
kubectl get vpa <vpa-name> -o yaml

# Monitor actual usage
kubectl top pods --containers
```

**Quality of Service (QoS):**
```yaml
# Guaranteed QoS
resources:
  requests:
    cpu: 1
    memory: 1Gi
  limits:
    cpu: 1
    memory: 1Gi

# Burstable QoS
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 2. Scaling Optimization

**Horizontal Pod Autoscaler (HPA):**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
```

**Vertical Pod Autoscaler (VPA):**
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  updatePolicy:
    updateMode: "Auto"
```

### 3. Application Optimization

**JVM Tuning (Java Applications):**
```bash
# Heap size optimization
-Xms2g -Xmx4g

# Garbage collection tuning
-XX:+UseG1GC -XX:MaxGCPauseMillis=200

# JIT compilation
-XX:+TieredCompilation
```

**Node.js Optimization:**
```bash
# Event loop monitoring
--max-old-space-size=4096
--inspect=0.0.0.0:9229
```

## Performance Testing

### 1. Load Testing

**Using Apache Bench:**
```bash
kubectl run ab-test --image=httpd --rm -it --restart=Never -- ab -n 1000 -c 10 http://service-name/
```

**Using wrk:**
```bash
kubectl run wrk-test --image=williamyeh/wrk --rm -it --restart=Never -- wrk -t12 -c400 -d30s http://service-name/
```

### 2. Stress Testing

**CPU Stress Test:**
```bash
kubectl run cpu-stress --image=progrium/stress --rm -it --restart=Never -- stress --cpu 4 --timeout 60s
```

**Memory Stress Test:**
```bash
kubectl run memory-stress --image=progrium/stress --rm -it --restart=Never -- stress --vm 1 --vm-bytes 1G --timeout 60s
```

## Performance Troubleshooting Checklist

### Application Level
1. Check resource requests and limits
2. Monitor CPU and memory usage
3. Analyze application logs for errors
4. Profile application performance
5. Check database query performance

### Infrastructure Level
1. Monitor node resource utilization
2. Check network latency and throughput
3. Analyze storage I/O performance
4. Monitor API server performance
5. Check cluster autoscaling behavior

### Optimization Actions
1. Right-size resource allocations
2. Implement proper scaling policies
3. Optimize application code
4. Tune database performance
5. Implement caching strategies
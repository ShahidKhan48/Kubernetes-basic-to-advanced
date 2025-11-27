# HPA - Horizontal Pod Autoscaler

## 📚 Overview
HPA automatically scales pod replicas based on CPU, memory, or custom metrics. Load ke according pods increase/decrease karta hai.

## 🎯 Scaling Metrics
- **CPU Utilization** - Most common
- **Memory Utilization** - Memory-based scaling
- **Custom Metrics** - Application-specific metrics
- **External Metrics** - Queue length, etc.

## 📖 Examples

### 1. **Basic CPU-based HPA**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 2. **Multi-metric HPA**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: advanced-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 3
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
```

## 🔧 Commands
```bash
# Create HPA
kubectl autoscale deployment web-app --min=2 --max=10 --cpu-percent=80

# Check HPA status
kubectl get hpa

# Describe HPA
kubectl describe hpa web-app-hpa
```

## 🔗 Related Topics
- [VPA](../VPA/) - Vertical scaling
- [Resource Management](../../resources-management/) - Resource limits

---

**Next:** [VPA](../VPA/) - Vertical Pod Autoscaler
# Scale Application - Manual & Automatic Scaling

## 📚 Overview
Application scaling horizontal (replicas) aur vertical (resources) dono ways mein kar sakte hain. Manual commands aur automatic mechanisms available hain.

## 🎯 Scaling Types

### 1. **Manual Scaling**
- kubectl scale command
- Deployment replica updates
- Resource limit changes

### 2. **Automatic Scaling**
- HPA (Horizontal Pod Autoscaler)
- VPA (Vertical Pod Autoscaler)
- Custom metrics scaling

## 📖 Examples

### Manual Scaling
```bash
# Scale deployment
kubectl scale deployment web-app --replicas=5

# Scale with conditions
kubectl scale deployment web-app --replicas=10 --current-replicas=3
```

### Automatic Scaling
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
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 🔧 Scaling Commands
```bash
# Manual scaling
kubectl scale deployment app --replicas=5

# Check HPA
kubectl get hpa

# Autoscale deployment
kubectl autoscale deployment app --min=2 --max=10 --cpu-percent=80
```

## 🔗 Related Topics
- [HPA](../Auto-scalling/HPA/) - Horizontal scaling
- [VPA](../Auto-scalling/VPA/) - Vertical scaling
- [Resource Management](../../B-Sheduling/resources-management/) - Resource control

---

**Completed:** C-Application-lifecycle-management - All components documented with examples
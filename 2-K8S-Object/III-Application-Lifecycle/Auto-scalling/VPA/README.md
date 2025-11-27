# VPA - Vertical Pod Autoscaler

## 📚 Overview
VPA automatically adjusts CPU aur memory requests/limits based on actual usage. Right-sizing containers ke liye use hota hai.

## 🎯 Update Modes
- **Off** - Only recommendations
- **Initial** - Set resources at pod creation
- **Auto** - Update running pods
- **Recreate** - Delete and recreate pods

## 📖 Examples

### 1. **Basic VPA**
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  updatePolicy:
    updateMode: "Auto"
```

### 2. **VPA with Limits**
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: constrained-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: api-server
      maxAllowed:
        cpu: 2
        memory: 4Gi
      minAllowed:
        cpu: 100m
        memory: 128Mi
```

## 🔧 Commands
```bash
# Check VPA status
kubectl get vpa

# View recommendations
kubectl describe vpa web-app-vpa
```

## 🔗 Related Topics
- [HPA](../HPA/) - Horizontal scaling
- [Resource Management](../../resources-management/) - Resource limits

---

**Next:** [Multi-Pod Design Patterns](../../multi-pods-design-pattern/) - Container Collaboration
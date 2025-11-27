# Pod Resizing & Resource Management

## 📚 Overview
Dynamic pod resource management aur in-place resource updates.

## 🎯 Pod Resizing Features
- **In-place Updates**: No pod restart required
- **Resource Optimization**: Right-sizing containers
- **Cost Efficiency**: Optimal resource utilization
- **Performance Tuning**: Dynamic resource adjustment

## 📖 Resource Resize Examples

### Deployment with Resizable Resources
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resizable-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resizable-app
  template:
    metadata:
      labels:
        app: resizable-app
    spec:
      containers:
      - name: web-app
        image: spicybiryaniwala.shop/web-app:v1.0.0
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: JAVA_OPTS
          value: "-Xmx400m -Xms200m"
```

### VPA for Automatic Resizing
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: resizable-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: resizable-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: web-app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1
        memory: 1Gi
      controlledResources: ["cpu", "memory"]
```

## 🔧 Resize Commands
```bash
# Check current resources
kubectl top pods
kubectl describe pod <pod-name>

# Update deployment resources
kubectl patch deployment resizable-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"web-app","resources":{"requests":{"memory":"512Mi","cpu":"500m"}}}]}}}}'

# Check VPA recommendations
kubectl get vpa resizable-app-vpa -o yaml

# Manual pod resize (if supported)
kubectl patch pod <pod-name> -p '{"spec":{"containers":[{"name":"container-name","resources":{"requests":{"memory":"512Mi"}}}]}}'
```

## 📊 Monitoring Resize Operations
```bash
# Watch resource changes
kubectl get pods -w
kubectl top pods --containers

# Check events for resize operations
kubectl get events --field-selector reason=ResourcesUpdated

# Monitor VPA activity
kubectl logs -n kube-system deployment/vpa-recommender
```

## 📋 Best Practices
- Monitor application performance during resizing
- Set appropriate min/max limits
- Test resize operations in staging
- Use gradual resource adjustments
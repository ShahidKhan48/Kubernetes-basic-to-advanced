# Self-Healing Applications - Automatic Recovery

## 📚 Overview
Self-healing applications automatically detect aur recover from failures. Health checks, restart policies, aur monitoring use karte hain.

## 🎯 Self-Healing Mechanisms

### 1. **Health Checks**
- **Liveness Probe** - Container restart karne ke liye
- **Readiness Probe** - Traffic routing control
- **Startup Probe** - Slow starting applications

### 2. **Restart Policies**
- **Always** - Always restart (default)
- **OnFailure** - Only on failure
- **Never** - Never restart

### 3. **Pod Disruption Budgets**
- Minimum available pods during disruptions
- Voluntary disruption protection

## 📖 Examples

### Complete Self-Healing App
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: self-healing-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: spicybiryaniwala.shop/app:latest
        
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      
      restartPolicy: Always
```

## 🔧 Best Practices
- Implement proper health endpoints
- Use appropriate probe timeouts
- Set resource limits
- Monitor application metrics
- Implement graceful shutdown

## 🔗 Related Topics
- [Health Checks](../../../A-workloads/pods/) - Pod health monitoring
- [Resource Management](../../B-Sheduling/resources-management/) - Resource limits

---

**Next:** [Scale Application](../scale-application/) - Application Scaling
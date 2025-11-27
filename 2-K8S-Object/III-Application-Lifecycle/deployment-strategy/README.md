# Kubernetes Deployment Strategies

## Overview
This directory contains YAML examples for different deployment strategies in Kubernetes.

## Deployment Strategies

### 1. Rolling Update (`rolling-update.yml`)
**Default Kubernetes strategy**
- Gradually replaces old pods with new ones
- Zero downtime deployment
- Configurable `maxUnavailable` and `maxSurge`
- **Use Case**: Most web applications, APIs

### 2. Recreate (`recreate.yml`)
**All-at-once replacement**
- Terminates all old pods before creating new ones
- Brief downtime during deployment
- **Use Case**: Databases, stateful applications, single-instance apps

### 3. Blue-Green (`blue-green.yml`)
**Two identical environments**
- Blue (current) and Green (new) environments
- Instant traffic switch between environments
- Easy rollback capability
- **Use Case**: Critical applications, zero-downtime requirements

### 4. Canary (`canary.yml`)
**Gradual traffic shifting**
- Small percentage of traffic to new version
- Monitor metrics before full rollout
- Risk mitigation through limited exposure
- **Use Case**: High-risk deployments, A/B testing

### 5. A/B Testing (`a-b-testing.yml`)
**Parallel version comparison**
- Split traffic between versions for testing
- Header-based or percentage-based routing
- Data-driven deployment decisions
- **Use Case**: Feature comparison, user experience testing

### 6. Shadow/Dark Launch (`shadow.yml`)
**Traffic mirroring**
- Production traffic mirrored to new version
- New version doesn't affect users
- Performance and behavior testing
- **Use Case**: Testing with real traffic, performance validation

### 7. Feature Toggle (`feature-toggle.yml`)
**Runtime feature control**
- Enable/disable features without deployment
- Gradual feature rollout
- A/B testing capabilities
- **Use Case**: Feature experimentation, risk mitigation

### 8. Ramped Slow Rollout (`ramped-slow-rollout.yml`)
**Controlled gradual deployment**
- Very slow, controlled rollout
- Enhanced monitoring and validation
- Conservative approach
- **Use Case**: Critical systems, large-scale deployments

## Deployment Strategy Comparison

| Strategy | Downtime | Rollback Speed | Resource Usage | Complexity | Risk |
|----------|----------|----------------|----------------|------------|------|
| Rolling Update | None | Medium | Low | Low | Low |
| Recreate | Yes | Fast | Low | Low | Medium |
| Blue-Green | None | Instant | High | Medium | Low |
| Canary | None | Medium | Medium | High | Low |
| A/B Testing | None | Medium | Medium | High | Low |
| Shadow | None | Fast | High | High | Very Low |
| Feature Toggle | None | Instant | Low | High | Low |
| Ramped | None | Slow | Low | Medium | Very Low |

## Commands for Each Strategy

### Rolling Update
```bash
kubectl apply -f rolling-update.yml
kubectl rollout status deployment/rolling-update-deployment
kubectl rollout undo deployment/rolling-update-deployment
```

### Recreate
```bash
kubectl apply -f recreate.yml
kubectl get pods -w  # Watch pod recreation
```

### Blue-Green
```bash
# Deploy both environments
kubectl apply -f blue-green.yml

# Switch traffic to green
kubectl patch service production-service -p '{"spec":{"selector":{"version":"green"}}}'

# Rollback to blue
kubectl patch service production-service -p '{"spec":{"selector":{"version":"blue"}}}'
```

### Canary
```bash
kubectl apply -f canary.yml
# Monitor metrics and gradually increase canary traffic
kubectl scale deployment canary-deployment --replicas=3
kubectl scale deployment stable-deployment --replicas=7
```

### A/B Testing
```bash
kubectl apply -f a-b-testing.yml
# Test with headers
curl -H "X-Version: A" http://app.example.com
curl -H "X-Version: B" http://app.example.com
```

### Shadow
```bash
kubectl apply -f shadow.yml
# Monitor shadow service logs
kubectl logs -f deployment/shadow-deployment
```

### Feature Toggle
```bash
kubectl apply -f feature-toggle.yml
# Update feature flags
kubectl patch configmap feature-flags -p '{"data":{"new-ui":"false"}}'
```

### Ramped Slow Rollout
```bash
kubectl apply -f ramped-slow-rollout.yml
kubectl rollout status deployment/ramped-deployment --timeout=600s
```

## Best Practices

1. **Always use health checks** (liveness and readiness probes)
2. **Monitor metrics** during deployments
3. **Have rollback plans** ready
4. **Test in staging** environment first
5. **Use appropriate strategy** for your use case
6. **Implement proper logging** and monitoring
7. **Consider resource requirements** for each strategy

## Monitoring Deployments

```bash
# Watch deployment progress
kubectl get pods -w

# Check deployment status
kubectl rollout status deployment/<deployment-name>

# View deployment history
kubectl rollout history deployment/<deployment-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Monitor resource usage
kubectl top pods
```
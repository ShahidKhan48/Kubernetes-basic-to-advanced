# Validation and Mutation Admission Controller Commands Reference

## Admission Webhook Management

### List Admission Webhooks
```bash
# List validating admission webhooks
kubectl get validatingadmissionwebhooks
kubectl get validatingadmissionwebhook <webhook-name> -o yaml

# List mutating admission webhooks
kubectl get mutatingadmissionwebhooks
kubectl get mutatingadmissionwebhook <webhook-name> -o yaml

# Get webhook details
kubectl describe validatingadmissionwebhook <webhook-name>
kubectl describe mutatingadmissionwebhook <webhook-name>
```

### Create and Update Webhooks
```bash
# Create validating webhook
kubectl apply -f validating-webhook.yaml

# Create mutating webhook
kubectl apply -f mutating-webhook.yaml

# Update webhook configuration
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","failurePolicy":"Ignore"}]}'

# Update webhook rules
kubectl patch mutatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","rules":[{"operations":["CREATE","UPDATE"],"apiGroups":["apps"],"apiVersions":["v1"],"resources":["deployments"]}]}]}'
```

### Delete Admission Webhooks
```bash
# Delete validating webhook
kubectl delete validatingadmissionwebhook <webhook-name>

# Delete mutating webhook
kubectl delete mutatingadmissionwebhook <webhook-name>

# Delete all webhooks with label
kubectl delete validatingadmissionwebhooks -l app=my-webhook
```

## Webhook Service Management

### Deploy Webhook Service
```bash
# Create webhook namespace
kubectl create namespace webhook-system

# Deploy webhook service
kubectl apply -f webhook-deployment.yaml

# Check webhook service status
kubectl get pods -n webhook-system -l app=webhook-server
kubectl get service -n webhook-system webhook-service
```

### Webhook Service Troubleshooting
```bash
# Check webhook pod logs
kubectl logs -n webhook-system -l app=webhook-server

# Check webhook service connectivity
kubectl run test-pod --image=busybox --rm -it -- wget -qO- https://webhook-service.webhook-system.svc:443/health

# Test webhook endpoint
kubectl port-forward -n webhook-system service/webhook-service 8443:443
curl -k https://localhost:8443/health
```

## Certificate Management

### Generate Webhook Certificates
```bash
# Generate private key
openssl genrsa -out webhook.key 2048

# Generate certificate signing request
openssl req -new -key webhook.key -out webhook.csr -subj "/CN=webhook-service.webhook-system.svc"

# Generate self-signed certificate
openssl x509 -req -in webhook.csr -signkey webhook.key -out webhook.crt -days 365

# Create Kubernetes secret
kubectl create secret tls webhook-certs --cert=webhook.crt --key=webhook.key -n webhook-system
```

### Update Webhook CA Bundle
```bash
# Get CA certificate
CA_BUNDLE=$(cat webhook.crt | base64 | tr -d '\n')

# Update validating webhook with CA bundle
kubectl patch validatingadmissionwebhook <webhook-name> -p "{\"webhooks\":[{\"name\":\"<webhook-name>\",\"clientConfig\":{\"caBundle\":\"$CA_BUNDLE\"}}]}"

# Update mutating webhook with CA bundle
kubectl patch mutatingadmissionwebhook <webhook-name> -p "{\"webhooks\":[{\"name\":\"<webhook-name>\",\"clientConfig\":{\"caBundle\":\"$CA_BUNDLE\"}}]}"
```

## Testing Admission Webhooks

### Test Validating Webhooks
```bash
# Create test resource to trigger validation
kubectl apply -f test-pod.yaml

# Check validation results
kubectl get events --field-selector reason=FailedAdmissionWebhook

# Test with dry-run
kubectl apply -f test-pod.yaml --dry-run=server

# Check webhook logs for validation
kubectl logs -n webhook-system -l app=webhook-server | grep validate
```

### Test Mutating Webhooks
```bash
# Create resource to trigger mutation
kubectl apply -f test-pod.yaml

# Check if mutations were applied
kubectl get pod test-pod -o yaml | grep -A 10 "resources\|containers"

# Compare original vs mutated
kubectl apply -f test-pod.yaml --dry-run=server -o yaml > mutated.yaml
diff test-pod.yaml mutated.yaml

# Check webhook logs for mutations
kubectl logs -n webhook-system -l app=webhook-server | grep mutate
```

## Webhook Configuration

### Namespace Selectors
```bash
# Configure webhook for specific namespaces
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","namespaceSelector":{"matchLabels":{"webhook":"enabled"}}}]}'

# Label namespace to enable webhook
kubectl label namespace production webhook=enabled

# Exclude namespace from webhook
kubectl label namespace kube-system webhook=disabled
```

### Object Selectors
```bash
# Configure webhook for specific objects
kubectl patch mutatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","objectSelector":{"matchLabels":{"inject":"sidecar"}}}]}'

# Label pod to trigger webhook
kubectl label pod test-pod inject=sidecar
```

### Failure Policies
```bash
# Set failure policy to Fail (reject on webhook failure)
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","failurePolicy":"Fail"}]}'

# Set failure policy to Ignore (allow on webhook failure)
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","failurePolicy":"Ignore"}]}'
```

## Debugging Admission Webhooks

### Common Issues
```bash
# Webhook timeout issues
kubectl get events --field-selector reason=AdmissionWebhookTimeout

# Certificate issues
kubectl logs -n webhook-system -l app=webhook-server | grep -i cert
kubectl get secret webhook-certs -n webhook-system -o yaml

# Network connectivity issues
kubectl describe service webhook-service -n webhook-system
kubectl get endpoints webhook-service -n webhook-system

# RBAC issues
kubectl auth can-i get pods --as=system:serviceaccount:webhook-system:webhook-service-account
```

### Webhook Performance
```bash
# Monitor webhook latency
kubectl get events --field-selector reason=AdmissionWebhookLatency

# Check webhook resource usage
kubectl top pods -n webhook-system -l app=webhook-server

# Monitor webhook request rate
kubectl logs -n webhook-system -l app=webhook-server | grep -c "admission request"
```

## Advanced Webhook Operations

### Webhook Admission Review
```bash
# Check admission review version
kubectl get validatingadmissionwebhook <webhook-name> -o jsonpath='{.webhooks[0].admissionReviewVersions}'

# Update admission review versions
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","admissionReviewVersions":["v1","v1beta1"]}]}'
```

### Webhook Side Effects
```bash
# Set side effects to None (no side effects)
kubectl patch mutatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","sideEffects":"None"}]}'

# Set side effects to NoneOnDryRun (side effects only on real requests)
kubectl patch mutatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","sideEffects":"NoneOnDryRun"}]}'
```

### Webhook Timeouts
```bash
# Set webhook timeout
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","timeoutSeconds":30}]}'

# Check webhook timeout events
kubectl get events --field-selector reason=AdmissionWebhookTimeout
```

## Webhook Monitoring

### Monitor Webhook Health
```bash
# Check webhook pod health
kubectl get pods -n webhook-system -l app=webhook-server

# Check webhook service health
kubectl get service -n webhook-system webhook-service

# Test webhook health endpoint
kubectl exec -n webhook-system deployment/webhook-server -- curl -k https://localhost:8443/health
```

### Webhook Metrics
```bash
# Port forward to webhook metrics endpoint
kubectl port-forward -n webhook-system deployment/webhook-server 8080:8080

# Get webhook metrics
curl http://localhost:8080/metrics | grep webhook

# Monitor admission request metrics
curl http://localhost:8080/metrics | grep admission_requests_total
```

## Webhook Security

### RBAC for Webhooks
```bash
# Create webhook service account
kubectl create serviceaccount webhook-service-account -n webhook-system

# Create cluster role for webhook
kubectl create clusterrole webhook-reader --verb=get,list,watch --resource=pods,deployments

# Create cluster role binding
kubectl create clusterrolebinding webhook-binding --clusterrole=webhook-reader --serviceaccount=webhook-system:webhook-service-account
```

### Network Policies for Webhooks
```bash
# Apply network policy for webhook namespace
kubectl apply -f webhook-network-policy.yaml

# Test network connectivity
kubectl run test-pod --image=busybox --rm -it -- nc -zv webhook-service.webhook-system.svc 443
```

## Webhook Best Practices

### High Availability
```bash
# Scale webhook deployment
kubectl scale deployment webhook-server --replicas=3 -n webhook-system

# Check webhook pod distribution
kubectl get pods -n webhook-system -l app=webhook-server -o wide

# Configure pod disruption budget
kubectl apply -f webhook-pdb.yaml
```

### Resource Management
```bash
# Set resource limits for webhook
kubectl patch deployment webhook-server -n webhook-system -p '{"spec":{"template":{"spec":{"containers":[{"name":"webhook","resources":{"requests":{"memory":"128Mi","cpu":"100m"},"limits":{"memory":"256Mi","cpu":"200m"}}}]}}}}'

# Monitor webhook resource usage
kubectl top pods -n webhook-system -l app=webhook-server
```

### Webhook Cleanup
```bash
# Remove webhook configuration
kubectl delete validatingadmissionwebhook <webhook-name>
kubectl delete mutatingadmissionwebhook <webhook-name>

# Clean up webhook resources
kubectl delete namespace webhook-system

# Remove webhook certificates
kubectl delete secret webhook-certs -n webhook-system
```
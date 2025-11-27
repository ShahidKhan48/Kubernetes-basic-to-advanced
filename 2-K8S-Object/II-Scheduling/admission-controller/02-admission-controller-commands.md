# Admission Controller Commands Reference

## Built-in Admission Controllers

### View Enabled Admission Controllers
```bash
# Check enabled admission controllers
kubectl get --raw /api/v1 | jq '.serverAddressByClientCIDRs'

# Check API server configuration (if accessible)
kubectl -n kube-system get pod kube-apiserver-<master-node> -o yaml | grep admission

# Common built-in admission controllers:
# - NamespaceLifecycle
# - LimitRanger
# - ServiceAccount
# - DefaultStorageClass
# - ResourceQuota
# - PodSecurityPolicy (deprecated)
# - NodeRestriction
```

## Validating Admission Webhooks

### Create Validating Webhook
```bash
# Create validating admission webhook
kubectl apply -f validating-webhook.yaml

# List validating webhooks
kubectl get validatingadmissionwebhooks
kubectl get validatingadmissionwebhook <webhook-name> -o yaml

# Delete validating webhook
kubectl delete validatingadmissionwebhook <webhook-name>
```

### Test Validating Webhook
```bash
# Test webhook by creating resources
kubectl apply -f test-pod.yaml

# Check webhook logs
kubectl logs -n webhook-system -l app=webhook-server

# Check admission review
kubectl get events --field-selector reason=FailedAdmissionWebhook
```

## Mutating Admission Webhooks

### Create Mutating Webhook
```bash
# Create mutating admission webhook
kubectl apply -f mutating-webhook.yaml

# List mutating webhooks
kubectl get mutatingadmissionwebhooks
kubectl get mutatingadmissionwebhook <webhook-name> -o yaml

# Delete mutating webhook
kubectl delete mutatingadmissionwebhook <webhook-name>
```

### Debug Mutating Webhook
```bash
# Check if mutations are applied
kubectl get pod <pod-name> -o yaml

# Compare original vs mutated resource
kubectl apply -f original-pod.yaml --dry-run=server -o yaml

# Check webhook service
kubectl get service -n webhook-system
kubectl describe service webhook-service -n webhook-system
```

## Webhook Configuration

### Update Webhook Configuration
```bash
# Update webhook rules
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","rules":[{"operations":["CREATE","UPDATE"],"apiGroups":["apps"],"apiVersions":["v1"],"resources":["deployments"]}]}]}'

# Update failure policy
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","failurePolicy":"Ignore"}]}'

# Update namespace selector
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","namespaceSelector":{"matchLabels":{"webhook":"enabled"}}}]}'
```

### Webhook Certificates
```bash
# Create webhook certificates
openssl req -new -x509 -key webhook.key -out webhook.crt -days 365 -subj "/CN=webhook-service.webhook-system.svc"

# Create secret with certificates
kubectl create secret tls webhook-certs --cert=webhook.crt --key=webhook.key -n webhook-system

# Update webhook with CA bundle
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","clientConfig":{"caBundle":"<base64-encoded-ca>"}}]}'
```

## Admission Controller Troubleshooting

### Debug Admission Failures
```bash
# Check admission controller logs
kubectl logs -n kube-system kube-apiserver-<master-node> | grep admission

# Check webhook service connectivity
kubectl run test-pod --image=busybox --rm -it -- wget -qO- https://webhook-service.webhook-system.svc:443/health

# Test webhook endpoint
curl -k https://<webhook-service-ip>:443/validate

# Check webhook service endpoints
kubectl get endpoints webhook-service -n webhook-system
```

### Common Issues
```bash
# Webhook timeout issues
kubectl get events --field-selector reason=FailedAdmissionWebhook

# Certificate issues
kubectl logs -n webhook-system -l app=webhook-server | grep -i cert

# Network connectivity issues
kubectl describe service webhook-service -n webhook-system
kubectl get networkpolicies -n webhook-system
```

## Resource Quota with Admission Control

### Quota Enforcement
```bash
# Check resource quota status
kubectl describe resourcequota -n <namespace>

# Test quota enforcement
kubectl run test-pod --image=nginx --requests='cpu=1000m,memory=1Gi'

# Check quota violations
kubectl get events --field-selector reason=ExceededQuota
```

## Limit Range with Admission Control

### Limit Range Enforcement
```bash
# Check limit range
kubectl describe limitrange -n <namespace>

# Test limit range enforcement
kubectl run test-pod --image=nginx --limits='cpu=2000m,memory=4Gi'

# Check limit violations
kubectl get events --field-selector reason=LimitRangeViolation
```

## Pod Security Standards (PSS)

### Configure Pod Security Standards
```bash
# Label namespace for pod security
kubectl label namespace <namespace> pod-security.kubernetes.io/enforce=restricted
kubectl label namespace <namespace> pod-security.kubernetes.io/audit=restricted
kubectl label namespace <namespace> pod-security.kubernetes.io/warn=restricted

# Check pod security violations
kubectl get events --field-selector reason=PodSecurityViolation

# Test pod security
kubectl apply -f privileged-pod.yaml -n <namespace>
```

## Custom Admission Controllers

### Deploy Custom Admission Controller
```bash
# Create namespace for admission controller
kubectl create namespace admission-system

# Deploy admission controller
kubectl apply -f admission-controller-deployment.yaml

# Create webhook configuration
kubectl apply -f admission-webhook-config.yaml

# Test custom admission logic
kubectl apply -f test-resource.yaml
```

### Monitor Custom Admission Controller
```bash
# Check admission controller logs
kubectl logs -n admission-system -l app=custom-admission-controller

# Monitor webhook performance
kubectl top pods -n admission-system

# Check webhook metrics (if available)
kubectl port-forward -n admission-system service/admission-controller 8080:8080
curl http://localhost:8080/metrics
```

## Admission Controller Best Practices

### Security Considerations
```bash
# Use TLS for webhook communication
# Validate webhook certificates
openssl x509 -in webhook.crt -text -noout

# Restrict webhook access with RBAC
kubectl create clusterrole webhook-reader --verb=get,list,watch --resource=pods,deployments
kubectl create clusterrolebinding webhook-binding --clusterrole=webhook-reader --serviceaccount=webhook-system:webhook-service-account

# Use network policies for webhook isolation
kubectl apply -f webhook-network-policy.yaml
```

### Performance Optimization
```bash
# Set appropriate timeout values
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","timeoutSeconds":10}]}'

# Use namespace selectors to limit scope
kubectl patch validatingadmissionwebhook <webhook-name> -p '{"webhooks":[{"name":"<webhook-name>","namespaceSelector":{"matchLabels":{"admission":"enabled"}}}]}'

# Monitor webhook latency
kubectl get events --field-selector reason=AdmissionWebhookLatency
```

### High Availability
```bash
# Deploy multiple webhook replicas
kubectl scale deployment webhook-server --replicas=3 -n webhook-system

# Use failure policy appropriately
# Fail: Reject requests if webhook fails (more secure)
# Ignore: Allow requests if webhook fails (more available)

# Monitor webhook availability
kubectl get pods -n webhook-system -l app=webhook-server
```
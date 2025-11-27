# Security Troubleshooting Guide

## Authentication Issues

### 1. User Authentication Problems

**Symptoms:**
- Unable to access cluster
- Authentication failures
- Certificate errors

**Diagnosis:**
```bash
# Check current user context
kubectl config current-context
kubectl config view

# Test authentication
kubectl auth whoami
kubectl get nodes
```

**Common Issues:**

#### Certificate Expiration
```bash
# Check certificate expiration
openssl x509 -in ~/.kube/config -text -noout | grep "Not After"
kubeadm certs check-expiration

# Renew certificates
kubeadm certs renew all
```

#### Invalid Kubeconfig
```bash
# Validate kubeconfig
kubectl config view --validate

# Reset kubeconfig
kubectl config unset current-context
kubectl config set-context <context-name> --cluster=<cluster> --user=<user>
```

### 2. Service Account Issues

**Diagnosis:**
```bash
# Check service account
kubectl get serviceaccounts
kubectl describe serviceaccount <sa-name>

# Check service account token
kubectl get secrets | grep <sa-name>
kubectl describe secret <sa-token-secret>
```

**Solutions:**
```bash
# Create service account
kubectl create serviceaccount <sa-name>

# Create token secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: <sa-name>-token
  annotations:
    kubernetes.io/service-account.name: <sa-name>
type: kubernetes.io/service-account-token
EOF
```

## Authorization Issues (RBAC)

### 1. Permission Denied Errors

**Diagnosis:**
```bash
# Test permissions
kubectl auth can-i create pods
kubectl auth can-i create pods --as=system:serviceaccount:default:default
kubectl auth can-i '*' '*' --as=<user>

# Check current permissions
kubectl auth can-i --list
```

**Common Solutions:**

#### Missing ClusterRole/Role
```bash
# Check existing roles
kubectl get clusterroles | grep <role-name>
kubectl get roles -A | grep <role-name>

# Create role
kubectl create clusterrole <role-name> --verb=get,list,watch --resource=pods
```

#### Missing RoleBinding/ClusterRoleBinding
```bash
# Check bindings
kubectl get clusterrolebindings | grep <user>
kubectl get rolebindings -A | grep <user>

# Create binding
kubectl create clusterrolebinding <binding-name> --clusterrole=<role> --user=<user>
```

### 2. Service Account RBAC Issues

**Diagnosis:**
```bash
# Check service account permissions
kubectl auth can-i create pods --as=system:serviceaccount:<namespace>:<sa-name>

# Check role bindings for service account
kubectl get rolebindings,clusterrolebindings -A -o json | jq '.items[] | select(.subjects[]?.name=="<sa-name>")'
```

**Solutions:**
```bash
# Bind service account to role
kubectl create rolebinding <binding-name> --role=<role> --serviceaccount=<namespace>:<sa-name>
kubectl create clusterrolebinding <binding-name> --clusterrole=<role> --serviceaccount=<namespace>:<sa-name>
```

## Pod Security Issues

### 1. Pod Security Policy Violations

**Diagnosis:**
```bash
kubectl get psp
kubectl describe psp <policy-name>
kubectl get events | grep "violates PodSecurityPolicy"
```

**Common Violations:**
- Running as root
- Privileged containers
- Host network access
- Volume types not allowed

**Solutions:**
```bash
# Update pod security context
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

### 2. Pod Security Standards Issues

**Diagnosis:**
```bash
# Check namespace pod security labels
kubectl get namespace <namespace> --show-labels

# Check pod security violations
kubectl get events | grep "violates pod security"
```

**Solutions:**
```bash
# Set appropriate pod security standard
kubectl label namespace <namespace> pod-security.kubernetes.io/enforce=restricted
kubectl label namespace <namespace> pod-security.kubernetes.io/audit=restricted
kubectl label namespace <namespace> pod-security.kubernetes.io/warn=restricted
```

## Network Security Issues

### 1. Network Policy Violations

**Diagnosis:**
```bash
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name>

# Test connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- <target-service>
```

**Common Issues:**
- Default deny policies blocking traffic
- Incorrect label selectors
- Missing ingress/egress rules

**Solutions:**
```bash
# Temporarily disable network policy for testing
kubectl delete networkpolicy <policy-name>

# Create allow-all policy for debugging
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-debug
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
```

### 2. TLS/SSL Certificate Issues

**Diagnosis:**
```bash
# Check certificate validity
openssl s_client -connect <service>:<port> -servername <hostname>
kubectl get certificates -A
kubectl describe certificate <cert-name>
```

**Cert-Manager Issues:**
```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
kubectl get certificaterequests -A
kubectl describe certificaterequest <request-name>
```

**Solutions:**
```bash
# Recreate certificate
kubectl delete certificate <cert-name>
kubectl apply -f certificate.yaml

# Check issuer configuration
kubectl get clusterissuer,issuer -A
kubectl describe clusterissuer <issuer-name>
```

## Image Security Issues

### 1. Image Pull Failures

**Diagnosis:**
```bash
kubectl describe pod <pod-name> | grep -A5 "Failed to pull image"
kubectl get events | grep "Failed to pull image"
```

**Common Causes:**
- Missing image pull secrets
- Incorrect registry credentials
- Image not found
- Registry access issues

**Solutions:**
```bash
# Create image pull secret
kubectl create secret docker-registry <secret-name> \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password>

# Add secret to service account
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "<secret-name>"}]}'
```

### 2. Image Vulnerability Issues

**Diagnosis:**
```bash
# Scan image for vulnerabilities
trivy image <image-name>
kubectl get vulnerabilityreports -A
```

**Solutions:**
- Update base images
- Apply security patches
- Use minimal base images
- Implement image scanning in CI/CD

## Admission Controller Issues

### 1. Webhook Failures

**Diagnosis:**
```bash
kubectl get validatingadmissionwebhooks
kubectl get mutatingadmissionwebhooks
kubectl describe validatingadmissionwebhook <webhook-name>
```

**Common Issues:**
- Webhook service not available
- Certificate issues
- Timeout errors

**Solutions:**
```bash
# Check webhook service
kubectl get service <webhook-service> -n <namespace>
kubectl logs deployment/<webhook-deployment> -n <namespace>

# Update webhook configuration
kubectl patch validatingadmissionwebhook <webhook-name> --type='json' -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value": "Ignore"}]'
```

### 2. OPA Gatekeeper Issues

**Diagnosis:**
```bash
kubectl get constraints
kubectl describe constraint <constraint-name>
kubectl logs -n gatekeeper-system deployment/gatekeeper-controller-manager
```

**Solutions:**
```bash
# Disable constraint temporarily
kubectl patch constraint <constraint-name> --type='json' -p='[{"op": "replace", "path": "/spec/enforcementAction", "value": "warn"}]'

# Check constraint template
kubectl get constrainttemplates
kubectl describe constrainttemplate <template-name>
```

## Secrets Management Issues

### 1. Secret Access Problems

**Diagnosis:**
```bash
kubectl get secrets
kubectl describe secret <secret-name>
kubectl get pods -o jsonpath='{.items[*].spec.volumes[*].secret.secretName}'
```

**Common Issues:**
- Secret not found
- Incorrect secret key references
- Permission issues

**Solutions:**
```bash
# Check secret exists in correct namespace
kubectl get secrets -n <namespace>

# Verify secret data
kubectl get secret <secret-name> -o yaml

# Check pod secret references
kubectl describe pod <pod-name> | grep -A5 "Mounts"
```

### 2. External Secrets Issues

**Diagnosis:**
```bash
kubectl get externalsecrets -A
kubectl describe externalsecret <external-secret-name>
kubectl logs -n external-secrets-system deployment/external-secrets
```

**Solutions:**
```bash
# Check secret store configuration
kubectl get secretstore,clustersecretstore -A
kubectl describe secretstore <store-name>

# Verify external secret provider credentials
kubectl get secret <provider-secret> -o yaml
```

## Security Monitoring Issues

### 1. Falco Alert Issues

**Diagnosis:**
```bash
kubectl get pods -n falco-system
kubectl logs -n falco-system daemonset/falco
```

**Common Issues:**
- Falco not receiving events
- Rule configuration problems
- Alert delivery failures

**Solutions:**
```bash
# Restart Falco
kubectl rollout restart daemonset/falco -n falco-system

# Check Falco configuration
kubectl get configmap falco -n falco-system -o yaml
```

### 2. Security Scanning Issues

**Diagnosis:**
```bash
# Check vulnerability reports
kubectl get vulnerabilityreports -A
kubectl describe vulnerabilityreport <report-name>

# Check compliance reports
kubectl get configauditreports -A
```

## Security Troubleshooting Tools

### Security Debug Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-debug
spec:
  containers:
  - name: debug
    image: nicolaka/netshoot
    command: ["/bin/bash"]
    args: ["-c", "sleep 3600"]
    securityContext:
      runAsUser: 0
      capabilities:
        add: ["NET_ADMIN", "SYS_ADMIN"]
  hostNetwork: true
  hostPID: true
  restartPolicy: Never
```

### Useful Security Commands
```bash
# Check running processes
kubectl exec <pod-name> -- ps aux

# Check network connections
kubectl exec <pod-name> -- netstat -tulpn

# Check file permissions
kubectl exec <pod-name> -- ls -la /etc/passwd

# Check capabilities
kubectl exec <pod-name> -- capsh --print

# Check SELinux/AppArmor status
kubectl exec <pod-name> -- getenforce
kubectl exec <pod-name> -- aa-status
```

## Security Best Practices Checklist

### Authentication & Authorization
- [ ] Use strong authentication methods
- [ ] Implement least privilege RBAC
- [ ] Regular audit of permissions
- [ ] Rotate certificates regularly

### Pod Security
- [ ] Run containers as non-root
- [ ] Use read-only root filesystems
- [ ] Drop all capabilities
- [ ] Implement pod security standards

### Network Security
- [ ] Implement network policies
- [ ] Use TLS for all communications
- [ ] Segment network traffic
- [ ] Monitor network activity

### Image Security
- [ ] Scan images for vulnerabilities
- [ ] Use trusted registries
- [ ] Sign and verify images
- [ ] Keep images updated

### Secrets Management
- [ ] Use external secret management
- [ ] Encrypt secrets at rest
- [ ] Rotate secrets regularly
- [ ] Audit secret access
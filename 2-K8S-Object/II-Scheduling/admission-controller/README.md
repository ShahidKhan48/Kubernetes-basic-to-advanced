# Admission Controllers - Policy Enforcement

## 📚 Overview
Admission Controllers Kubernetes API requests ko validate aur modify karte hain. Ye security policies aur resource constraints enforce karte hain.

## 🎯 Types

### Built-in Controllers
- **NamespaceLifecycle** - Namespace validation
- **ResourceQuota** - Resource limits
- **PodSecurityPolicy** - Security policies
- **NodeRestriction** - Node permissions

### Custom Controllers
- **ValidatingAdmissionWebhook** - Custom validation
- **MutatingAdmissionWebhook** - Resource modification

## 📖 Examples

### 1. Basic Admission Webhook
```yaml
# 01-admission-controller-basic.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: pod-security-validator
webhooks:
- name: pod-security.spicybiryaniwala.shop
  clientConfig:
    service:
      name: pod-security-webhook
      namespace: default
      path: "/validate"
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1", "v1beta1"]
```

### 2. Mutating Webhook for Resource Injection
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionWebhook
metadata:
  name: resource-injector
webhooks:
- name: inject-resources.spicybiryaniwala.shop
  clientConfig:
    service:
      name: resource-injector
      namespace: kube-system
      path: "/mutate"
  rules:
  - operations: ["CREATE"]
    apiGroups: ["apps"]
    apiVersions: ["v1"]
    resources: ["deployments"]
  admissionReviewVersions: ["v1"]
```

### 3. Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 4. Network Policy Admission
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: network-policy-validator
webhooks:
- name: netpol.spicybiryaniwala.shop
  clientConfig:
    service:
      name: netpol-webhook
      namespace: security-system
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: ["networking.k8s.io"]
    apiVersions: ["v1"]
    resources: ["networkpolicies"]
```

## 🔧 Management Commands

### View Admission Controllers
```bash
# List validating webhooks
kubectl get validatingadmissionwebhooks

# List mutating webhooks  
kubectl get mutatingadmissionwebhooks

# Describe webhook
kubectl describe validatingadmissionwebhook pod-security-validator
```

### Test Admission
```bash
# Test pod creation
kubectl apply -f test-pod.yaml

# Check admission events
kubectl get events --field-selector reason=FailedAdmissionWebhook

# Debug webhook
kubectl logs -n kube-system deployment/webhook-server
```

## 🛡️ Security Policies

### 1. Resource Requirements
```yaml
# Webhook validates resource requests
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "128Mi"  # Required
        cpu: "100m"      # Required
```

### 2. Security Context Validation
```yaml
# Webhook enforces security context
securityContext:
  runAsNonRoot: true     # Required
  runAsUser: 1000        # Required
  capabilities:
    drop: ["ALL"]        # Required
```

### 3. Image Policy
```yaml
# Webhook validates image sources
containers:
- name: app
  image: spicybiryaniwala.shop/app:v1.0.0  # Allowed registry
```

## 📊 Common Use Cases

### 1. **Resource Enforcement**
- Ensure all pods have resource limits
- Validate resource quotas
- Enforce QoS classes

### 2. **Security Compliance**
- Block privileged containers
- Enforce security contexts
- Validate image sources

### 3. **Policy Automation**
- Auto-inject sidecars
- Add monitoring labels
- Configure network policies

## 🚨 Troubleshooting

### Webhook Failures
```bash
# Check webhook status
kubectl get validatingadmissionwebhooks -o yaml

# Check service endpoints
kubectl get endpoints webhook-service

# Test webhook connectivity
kubectl run test --image=busybox --dry-run=server
```

### Certificate Issues
```bash
# Check webhook certificates
kubectl describe validatingadmissionwebhook webhook-name

# Verify CA bundle
kubectl get validatingadmissionwebhook webhook-name -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | base64 -d
```

## 🔗 Related Topics
- **[Pod Security Standards](../../../5-cluster-security/D-Admission-Control/pss/)** - Security policies
- **[Network Policies](../../../5-cluster-security/F-Network-policy/)** - Network security
- **[RBAC](../../../5-cluster-security/C-RBAC/)** - Access control

---

**Next:** [Multiple Schedulers](../multiple-scheduler/) - Custom Scheduling
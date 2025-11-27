# Helm Troubleshooting Guide

## Common Helm Issues

### 1. Installation Failures

#### Release Already Exists
```bash
# Error: release "my-app" already exists
# Solution: Use upgrade instead
helm upgrade my-app ./my-chart

# Or uninstall first
helm uninstall my-app
helm install my-app ./my-chart
```

#### Timeout Issues
```bash
# Increase timeout
helm install my-app ./my-chart --timeout 10m

# Check pod status during installation
kubectl get pods -w

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Resource Conflicts
```bash
# Error: resource already exists
# Check existing resources
kubectl get all -l app.kubernetes.io/managed-by=Helm

# Force replace
helm upgrade my-app ./my-chart --force

# Or use different release name
helm install my-app-v2 ./my-chart
```

### 2. Template Rendering Issues

#### Syntax Errors
```bash
# Debug template rendering
helm template my-app ./my-chart --debug

# Validate templates
helm lint ./my-chart

# Check specific template
helm template my-app ./my-chart -s templates/deployment.yaml
```

#### Missing Values
```bash
# Error: template: deployment.yaml:10:20: executing "deployment.yaml" at <.Values.missing>: nil pointer evaluating interface {}.missing

# Check values
helm show values ./my-chart

# Provide missing values
helm install my-app ./my-chart --set missing.value=default

# Use values file
helm install my-app ./my-chart -f values.yaml
```

#### Type Conversion Issues
```bash
# Error: wrong type for value; expected string; got int
# Fix in template:
{{ .Values.port | quote }}

# Or in values.yaml:
port: "8080"  # String instead of int
```

### 3. Dependency Issues

#### Dependency Download Failures
```bash
# Update dependencies
helm dependency update

# Check dependency status
helm dependency list

# Manual download
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm dependency build
```

#### Version Conflicts
```bash
# Error: found in Chart.yaml, but missing in charts/ directory
# Clean and rebuild
rm -rf charts/
helm dependency build

# Check Chart.lock
cat Chart.lock

# Force update
helm dependency update --skip-refresh
```

### 4. Upgrade Issues

#### Failed Upgrades
```bash
# Check upgrade status
helm status my-app

# Get upgrade history
helm history my-app

# Rollback to previous version
helm rollback my-app

# Rollback to specific revision
helm rollback my-app 2
```

#### Stuck in Pending-Upgrade
```bash
# Check release status
helm list --pending

# Force delete pending release
kubectl delete secret sh.helm.release.v1.my-app.v2 -n default

# Or use helm plugin
helm plugin install https://github.com/hickeyma/helm-mapkubeapis
helm mapkubeapis my-app
```

#### Resource Immutable Fields
```bash
# Error: field is immutable
# Delete and recreate resource
kubectl delete deployment my-app
helm upgrade my-app ./my-chart

# Or use --force flag
helm upgrade my-app ./my-chart --force
```

## Debugging Techniques

### 1. Dry Run and Debug
```bash
# Dry run installation
helm install my-app ./my-chart --dry-run --debug

# Template with debug
helm template my-app ./my-chart --debug

# Show computed values
helm get values my-app --all
```

### 2. Manifest Inspection
```bash
# Get rendered manifests
helm get manifest my-app

# Compare manifests
helm diff upgrade my-app ./my-chart

# Check specific resource
helm get manifest my-app | grep -A 20 "kind: Deployment"
```

### 3. Release Information
```bash
# Get release status
helm status my-app

# Get release history
helm history my-app

# Get release notes
helm get notes my-app

# List all releases
helm list --all-namespaces
```

## Chart Development Issues

### 1. Template Functions
```bash
# Common function errors
# Wrong: {{ .Values.name | upper }}
# Right: {{ .Values.name | upper | quote }}

# Date functions
{{ now | date "2006-01-02T15:04:05Z" }}

# Default values
{{ .Values.port | default 8080 }}

# Conditional rendering
{{- if .Values.ingress.enabled }}
# ingress configuration
{{- end }}
```

### 2. Helper Templates
```yaml
# _helpers.tpl
{{/*
Common labels
*/}}
{{- define "my-app.labels" -}}
helm.sh/chart: {{ include "my-app.chart" . }}
{{ include "my-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

# Usage in templates
labels:
  {{- include "my-app.labels" . | nindent 4 }}
```

### 3. Values Validation
```json
// values.schema.json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1
    },
    "image": {
      "type": "object",
      "properties": {
        "repository": {"type": "string"},
        "tag": {"type": "string"}
      },
      "required": ["repository"]
    }
  }
}
```

## Performance Issues

### 1. Large Charts
```bash
# Optimize chart size
# Remove unnecessary files in .helmignore
echo "*.md" >> .helmignore
echo "docs/" >> .helmignore

# Use subcharts for complex applications
# Split monolithic chart into smaller charts
```

### 2. Template Rendering Performance
```bash
# Avoid complex loops in templates
# Use range with break conditions
{{- range $index, $item := .Values.items }}
{{- if lt $index 10 }}
# Process only first 10 items
{{- end }}
{{- end }}

# Cache computed values
{{- $fullName := include "my-app.fullname" . }}
```

### 3. Resource Management
```bash
# Set appropriate resource limits
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"

# Use horizontal pod autoscaling
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 100
```

## Security Issues

### 1. Secret Management
```bash
# Don't store secrets in values.yaml
# Use external secret management
externalSecrets:
  enabled: true
  secretStore: vault-backend

# Use sealed secrets for GitOps
sealedSecrets:
  enabled: true
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
```

### 2. RBAC Configuration
```yaml
# Minimal RBAC permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: my-app-role
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
```

### 3. Security Context
```yaml
# Secure pod configuration
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
  seccompProfile:
    type: RuntimeDefault

containers:
- name: app
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
      - ALL
```

## Troubleshooting Tools

### 1. Helm Plugins
```bash
# Install useful plugins
helm plugin install https://github.com/databus23/helm-diff
helm plugin install https://github.com/chartmuseum/helm-push
helm plugin install https://github.com/quintush/helm-unittest

# Use diff plugin
helm diff upgrade my-app ./my-chart

# Run unit tests
helm unittest ./my-chart
```

### 2. Debugging Scripts
```bash
#!/bin/bash
# helm-debug.sh

RELEASE_NAME=$1
NAMESPACE=${2:-default}

echo "=== Helm Release Debug ==="
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo ""

echo "=== Release Status ==="
helm status $RELEASE_NAME -n $NAMESPACE

echo ""
echo "=== Release History ==="
helm history $RELEASE_NAME -n $NAMESPACE

echo ""
echo "=== Release Values ==="
helm get values $RELEASE_NAME -n $NAMESPACE --all

echo ""
echo "=== Kubernetes Resources ==="
kubectl get all -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE

echo ""
echo "=== Recent Events ==="
kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp | tail -10
```

### 3. Chart Testing
```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-app.fullname" . }}-test-connection"
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  restartPolicy: Never
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "my-app.fullname" . }}:{{ .Values.service.port }}']
```

```bash
# Run tests
helm test my-app --logs
```

## Best Practices for Troubleshooting

### 1. Preventive Measures
- Always use `helm lint` before installation
- Test charts in development environment
- Use `--dry-run` flag for validation
- Implement comprehensive tests
- Monitor release health

### 2. Debugging Workflow
1. Check Helm release status
2. Examine Kubernetes resources
3. Review pod logs and events
4. Validate template rendering
5. Check values and configuration
6. Test with minimal configuration

### 3. Documentation
- Document known issues and solutions
- Maintain troubleshooting runbooks
- Keep track of common problems
- Share knowledge with team members

### 4. Monitoring and Alerting
- Monitor Helm release health
- Set up alerts for failed deployments
- Track deployment metrics
- Implement automated rollback procedures
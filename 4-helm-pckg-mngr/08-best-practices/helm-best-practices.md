# Helm Best Practices

## Chart Development Best Practices

### 1. Chart Structure and Organization

#### Standard Directory Structure
```
my-chart/
├── Chart.yaml          # Chart metadata
├── Chart.lock          # Dependency lock file
├── values.yaml         # Default configuration values
├── values.schema.json  # JSON schema for values validation
├── README.md           # Chart documentation
├── .helmignore         # Files to ignore when packaging
├── templates/          # Kubernetes manifest templates
│   ├── NOTES.txt      # Post-installation notes
│   ├── _helpers.tpl   # Template helpers
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── rbac.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   ├── networkpolicy.yaml
│   └── tests/
│       └── test-connection.yaml
├── charts/             # Chart dependencies
└── crds/              # Custom Resource Definitions
```

#### Naming Conventions
```yaml
# Use kebab-case for chart names
name: my-web-app

# Use consistent resource naming
metadata:
  name: {{ include "my-web-app.fullname" . }}

# Use descriptive labels
labels:
  {{- include "my-web-app.labels" . | nindent 4 }}
  component: web-server
  tier: frontend
```

### 2. Values and Configuration

#### Well-Structured values.yaml
```yaml
# Global values (shared across subcharts)
global:
  imageRegistry: registry.spicybiryaniwala.shop
  storageClass: fast-ssd
  domain: spicybiryaniwala.shop

# Application configuration
replicaCount: 1

image:
  repository: my-web-app
  pullPolicy: IfNotPresent
  tag: ""  # Defaults to .Chart.AppVersion

imagePullSecrets: []

# Service account configuration
serviceAccount:
  create: true
  annotations: {}
  name: ""

# Pod configuration
podAnnotations: {}
podLabels: {}

podSecurityContext:
  fsGroup: 2000

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

# Service configuration
service:
  type: ClusterIP
  port: 80
  targetPort: http
  annotations: {}

# Ingress configuration
ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

# Resource management
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Autoscaling
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

# Node selection
nodeSelector: {}
tolerations: []
affinity: {}

# Health checks
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5

# Application-specific configuration
config:
  logLevel: info
  database:
    host: ""
    port: 5432
    name: myapp

# Feature flags
features:
  monitoring: true
  backup: false
  ssl: true
```

#### Values Schema Validation
```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100
    },
    "image": {
      "type": "object",
      "properties": {
        "repository": {
          "type": "string"
        },
        "tag": {
          "type": "string"
        },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"]
        }
      },
      "required": ["repository"]
    },
    "service": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string",
          "enum": ["ClusterIP", "NodePort", "LoadBalancer", "ExternalName"]
        },
        "port": {
          "type": "integer",
          "minimum": 1,
          "maximum": 65535
        }
      }
    }
  },
  "required": ["image"]
}
```

### 3. Template Best Practices

#### Helper Templates (_helpers.tpl)
```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "my-web-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "my-web-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "my-web-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "my-web-app.labels" -}}
helm.sh/chart: {{ include "my-web-app.chart" . }}
{{ include "my-web-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "my-web-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-web-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "my-web-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "my-web-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate environment variables from config
*/}}
{{- define "my-web-app.envVars" -}}
{{- range $key, $value := . }}
- name: {{ $key | upper }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
```

#### Conditional Resource Creation
```yaml
# Only create ingress if enabled
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "my-web-app.fullname" . }}
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  # ... ingress spec
{{- end }}

# Conditional blocks within resources
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}

{{- if .Values.autoscaling.enabled }}
# HPA configuration
{{- else }}
replicas: {{ .Values.replicaCount }}
{{- end }}
```

#### Resource Validation
```yaml
# Validate required values
{{- if not .Values.image.repository }}
{{- fail "image.repository is required" }}
{{- end }}

# Validate value ranges
{{- if or (lt (.Values.replicaCount | int) 1) (gt (.Values.replicaCount | int) 100) }}
{{- fail "replicaCount must be between 1 and 100" }}
{{- end }}

# Validate dependencies
{{- if and .Values.ingress.enabled (not .Values.service.enabled) }}
{{- fail "Service must be enabled when Ingress is enabled" }}
{{- end }}
```

## Security Best Practices

### 1. Pod Security
```yaml
# Secure pod security context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000
  seccompProfile:
    type: RuntimeDefault

# Secure container security context
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE  # Only if needed
```

### 2. Secret Management
```yaml
# Use external secret management
{{- if .Values.externalSecrets.enabled }}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "my-web-app.fullname" . }}
spec:
  secretStoreRef:
    name: {{ .Values.externalSecrets.secretStore }}
    kind: SecretStore
  target:
    name: {{ include "my-web-app.fullname" . }}-secrets
  data:
  {{- range .Values.externalSecrets.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .key }}
      property: {{ .property }}
  {{- end }}
{{- end }}

# Avoid hardcoded secrets in values
# Wrong:
secrets:
  password: "hardcoded-password"

# Right:
secrets: {}  # Provide via external secret management
```

### 3. RBAC Configuration
```yaml
# Minimal RBAC permissions
{{- if .Values.serviceAccount.create -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "my-web-app.fullname" . }}
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["{{ include "my-web-app.fullname" . }}-secrets"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "my-web-app.fullname" . }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "my-web-app.fullname" . }}
subjects:
- kind: ServiceAccount
  name: {{ include "my-web-app.serviceAccountName" . }}
{{- end }}
```

## Production Readiness

### 1. Resource Management
```yaml
# Always set resource requests and limits
resources:
  requests:
    cpu: 100m
    memory: 128Mi
    ephemeral-storage: 1Gi
  limits:
    cpu: 500m
    memory: 512Mi
    ephemeral-storage: 2Gi

# Use appropriate QoS class
# Guaranteed: requests = limits
# Burstable: requests < limits
# BestEffort: no requests/limits (avoid in production)
```

### 2. Health Checks
```yaml
# Comprehensive health checks
livenessProbe:
  httpGet:
    path: /health
    port: http
    scheme: HTTP
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1

readinessProbe:
  httpGet:
    path: /ready
    port: http
    scheme: HTTP
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
  successThreshold: 1

startupProbe:
  httpGet:
    path: /startup
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 30
```

### 3. High Availability
```yaml
# Pod disruption budget
{{- if gt (.Values.replicaCount | int) 1 }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "my-web-app.fullname" . }}
spec:
  minAvailable: {{ .Values.podDisruptionBudget.minAvailable | default "50%" }}
  selector:
    matchLabels:
      {{- include "my-web-app.selectorLabels" . | nindent 6 }}
{{- end }}

# Anti-affinity for pod distribution
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - {{ include "my-web-app.name" . }}
        topologyKey: kubernetes.io/hostname
```

## Testing and Validation

### 1. Chart Testing
```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-web-app.fullname" . }}-test-connection"
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  restartPolicy: Never
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "my-web-app.fullname" . }}:{{ .Values.service.port }}/health']
      resources:
        requests:
          cpu: 10m
          memory: 16Mi
        limits:
          cpu: 100m
          memory: 128Mi
```

### 2. Unit Testing
```yaml
# tests/deployment_test.yaml
suite: test deployment
templates:
  - deployment.yaml
tests:
  - it: should render deployment
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: metadata.name
          value: RELEASE-NAME-my-web-app

  - it: should set correct replicas
    set:
      replicaCount: 3
    asserts:
      - equal:
          path: spec.replicas
          value: 3

  - it: should set resource limits
    asserts:
      - equal:
          path: spec.template.spec.containers[0].resources.limits.cpu
          value: 500m
```

### 3. Integration Testing
```bash
#!/bin/bash
# test-chart.sh

set -e

CHART_DIR="./my-web-app"
NAMESPACE="test-$(date +%s)"

echo "Testing chart: $CHART_DIR"

# Lint chart
echo "Linting chart..."
helm lint $CHART_DIR

# Validate templates
echo "Validating templates..."
helm template test $CHART_DIR --validate

# Create test namespace
kubectl create namespace $NAMESPACE

# Install chart
echo "Installing chart..."
helm install test $CHART_DIR -n $NAMESPACE --wait --timeout 5m

# Run tests
echo "Running tests..."
helm test test -n $NAMESPACE --logs

# Cleanup
echo "Cleaning up..."
helm uninstall test -n $NAMESPACE
kubectl delete namespace $NAMESPACE

echo "Chart test completed successfully!"
```

## Documentation and Maintenance

### 1. Chart Documentation
```markdown
# My Web App Helm Chart

## Overview
This chart deploys a web application with optional database and caching.

## Prerequisites
- Kubernetes 1.20+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart
```bash
helm repo add my-repo https://charts.spicybiryaniwala.shop
helm install my-app my-repo/my-web-app
```

## Configuration
| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `""` |
| `image.tag` | Image tag | `""` |

## Examples
See [examples/](examples/) directory for common configurations.
```

### 2. Version Management
```yaml
# Chart.yaml versioning
apiVersion: v2
name: my-web-app
version: 1.2.3  # Chart version (SemVer)
appVersion: "2.1.0"  # Application version

# Follow semantic versioning:
# MAJOR.MINOR.PATCH
# - MAJOR: Breaking changes
# - MINOR: New features, backward compatible
# - PATCH: Bug fixes, backward compatible
```

### 3. Changelog Maintenance
```markdown
# Changelog

## [1.2.3] - 2023-12-01
### Added
- Support for custom annotations
- Health check configuration

### Changed
- Updated default resource limits
- Improved security context

### Fixed
- Fixed ingress TLS configuration
- Corrected service port mapping

## [1.2.2] - 2023-11-15
### Fixed
- Fixed template rendering issue with empty values
```

This comprehensive guide covers all aspects of Helm best practices for production-ready chart development, security, testing, and maintenance.
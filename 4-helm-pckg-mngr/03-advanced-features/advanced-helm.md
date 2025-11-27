# Advanced Helm Features

## Chart Dependencies

### Managing Dependencies
```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: 12.1.2
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
    tags:
      - database
  - name: redis
    version: 17.4.3
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
    tags:
      - cache
  - name: nginx
    version: 13.2.4
    repository: https://charts.bitnami.com/bitnami
    condition: nginx.enabled
    alias: web-server
```

### Dependency Commands
```bash
# Download dependencies
helm dependency update

# List dependencies
helm dependency list

# Build dependencies
helm dependency build

# Install with dependencies
helm install my-app ./my-chart --dependency-update
```

### Conditional Dependencies
```yaml
# values.yaml
postgresql:
  enabled: true
  auth:
    postgresPassword: secretpassword
    database: myapp

redis:
  enabled: false

tags:
  database: true
  cache: false
```

## Hooks and Lifecycle Management

### Hook Types
```yaml
# templates/pre-install-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "my-app.fullname" . }}-pre-install"
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: pre-install
        image: busybox
        command: ['sh', '-c', 'echo "Pre-install hook executed"']
```

### Available Hooks
- `pre-install`: Before resources are installed
- `post-install`: After all resources are installed
- `pre-delete`: Before resources are deleted
- `post-delete`: After resources are deleted
- `pre-upgrade`: Before resources are upgraded
- `post-upgrade`: After resources are upgraded
- `pre-rollback`: Before rollback
- `post-rollback`: After rollback
- `test`: When `helm test` is run

### Database Migration Hook
```yaml
# templates/migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "my-app.fullname" . }}-migration"
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install
    "helm.sh/hook-weight": "-1"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migration
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        command: ["npm", "run", "migrate"]
        env:
        - name: DATABASE_URL
          value: "postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "my-app.fullname" . }}-postgresql:5432/{{ .Values.postgresql.auth.database }}"
```

## Template Functions and Pipelines

### Built-in Functions
```yaml
# String functions
name: {{ .Values.name | upper | quote }}
config: {{ .Values.config | toYaml | nindent 2 }}
secret: {{ .Values.password | b64enc }}

# Math functions
replicas: {{ add .Values.baseReplicas .Values.extraReplicas }}
memory: {{ mul .Values.memoryBase 1024 }}

# Date functions
timestamp: {{ now | date "2006-01-02T15:04:05Z" }}

# Conditional functions
{{- if .Values.ingress.enabled }}
ingress: enabled
{{- else }}
ingress: disabled
{{- end }}

# Default values
port: {{ .Values.port | default 8080 }}
```

### Custom Functions
```yaml
# _helpers.tpl
{{/*
Generate database URL
*/}}
{{- define "my-app.databaseUrl" -}}
{{- if .Values.postgresql.enabled -}}
postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "my-app.fullname" . }}-postgresql:5432/{{ .Values.postgresql.auth.database }}
{{- else -}}
{{ .Values.externalDatabase.url }}
{{- end -}}
{{- end }}

# Usage in templates
env:
- name: DATABASE_URL
  value: {{ include "my-app.databaseUrl" . | quote }}
```

### Flow Control
```yaml
# Range loops
{{- range .Values.environments }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}

# With blocks
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}

# If conditions
{{- if and .Values.ingress.enabled .Values.ingress.tls }}
tls:
  {{- range .Values.ingress.tls }}
  - hosts:
    {{- range .hosts }}
    - {{ . | quote }}
    {{- end }}
    secretName: {{ .secretName }}
  {{- end }}
{{- end }}
```

## Multi-Environment Deployments

### Environment-Specific Values
```bash
# Directory structure
environments/
├── values-dev.yaml
├── values-staging.yaml
└── values-prod.yaml
```

```yaml
# values-dev.yaml
replicaCount: 1
image:
  tag: "dev"
ingress:
  hosts:
    - host: app-dev.spicybiryaniwala.shop
resources:
  requests:
    cpu: 100m
    memory: 128Mi

# values-prod.yaml
replicaCount: 3
image:
  tag: "v1.0.0"
ingress:
  hosts:
    - host: app.spicybiryaniwala.shop
  tls:
    - secretName: app-tls
      hosts:
        - app.spicybiryaniwala.shop
resources:
  requests:
    cpu: 500m
    memory: 512Mi
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
```

### Deployment Commands
```bash
# Deploy to development
helm upgrade --install my-app ./my-chart \
  -f environments/values-dev.yaml \
  -n development --create-namespace

# Deploy to production
helm upgrade --install my-app ./my-chart \
  -f environments/values-prod.yaml \
  -n production --create-namespace
```

## Secrets Management

### Using Kubernetes Secrets
```yaml
# templates/secret.yaml
{{- if .Values.secrets }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
type: Opaque
data:
  {{- range $key, $value := .Values.secrets }}
  {{ $key }}: {{ $value | b64enc | quote }}
  {{- end }}
{{- end }}
```

### External Secrets Integration
```yaml
# templates/external-secret.yaml
{{- if .Values.externalSecrets.enabled }}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  refreshInterval: {{ .Values.externalSecrets.refreshInterval | default "15s" }}
  secretStoreRef:
    name: {{ .Values.externalSecrets.secretStore }}
    kind: SecretStore
  target:
    name: {{ include "my-app.fullname" . }}-external
    creationPolicy: Owner
  data:
  {{- range .Values.externalSecrets.data }}
  - secretKey: {{ .secretKey }}
    remoteRef:
      key: {{ .key }}
      property: {{ .property | default .secretKey }}
  {{- end }}
{{- end }}
```

### Sealed Secrets
```yaml
# templates/sealed-secret.yaml
{{- if .Values.sealedSecrets.enabled }}
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: {{ include "my-app.fullname" . }}-sealed
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  encryptedData:
    {{- range $key, $value := .Values.sealedSecrets.encryptedData }}
    {{ $key }}: {{ $value }}
    {{- end }}
  template:
    metadata:
      name: {{ include "my-app.fullname" . }}-sealed
      labels:
        {{- include "my-app.labels" . | nindent 8 }}
    type: Opaque
{{- end }}
```

## Advanced Templating

### Subcharts and Global Values
```yaml
# values.yaml (parent chart)
global:
  imageRegistry: registry.spicybiryaniwala.shop
  storageClass: fast-ssd
  domain: spicybiryaniwala.shop

postgresql:
  global:
    postgresql:
      auth:
        postgresPassword: secretpassword
```

### Named Templates with Parameters
```yaml
# _helpers.tpl
{{/*
Create environment variables from config
*/}}
{{- define "my-app.envVars" -}}
{{- range $key, $value := . }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

# Usage in deployment
env:
  {{- include "my-app.envVars" .Values.env | nindent 2 }}
```

### Complex Conditionals
```yaml
{{- $isProduction := eq .Values.environment "production" }}
{{- $hasDatabase := .Values.postgresql.enabled }}
{{- $needsMigration := and $hasDatabase (not .Values.skipMigration) }}

{{- if $needsMigration }}
# Include migration job
{{- include "my-app.migrationJob" . }}
{{- end }}

{{- if and $isProduction .Values.monitoring.enabled }}
# Include monitoring resources
{{- include "my-app.serviceMonitor" . }}
{{- end }}
```

## Chart Packaging and Distribution

### Package Chart
```bash
# Package chart
helm package ./my-chart

# Package with specific version
helm package ./my-chart --version 1.0.0 --app-version 2.1.0

# Sign package
helm package ./my-chart --sign --key mykey --keyring ~/.gnupg/secring.gpg
```

### Chart Repository
```bash
# Create repository index
helm repo index ./charts --url https://charts.spicybiryaniwala.shop

# Update repository
helm repo add my-repo https://charts.spicybiryaniwala.shop
helm repo update

# Push to ChartMuseum
helm push my-chart-1.0.0.tgz chartmuseum
```

### OCI Registry
```bash
# Login to registry
helm registry login registry.spicybiryaniwala.shop

# Push chart to OCI registry
helm push my-chart-1.0.0.tgz oci://registry.spicybiryaniwala.shop/helm-charts

# Install from OCI registry
helm install my-app oci://registry.spicybiryaniwala.shop/helm-charts/my-chart --version 1.0.0
```

## Chart Validation and Testing

### Schema Validation
```json
// values.schema.json
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
    }
  },
  "required": ["image"]
}
```

### Chart Testing
```bash
# Lint chart
helm lint ./my-chart

# Template and validate
helm template my-app ./my-chart --validate

# Dry run installation
helm install my-app ./my-chart --dry-run --debug

# Run chart tests
helm test my-app
```

### Unit Testing with Helm Unittest
```yaml
# tests/deployment_test.yaml
suite: test deployment
templates:
  - deployment.yaml
tests:
  - it: should create deployment
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: metadata.name
          value: my-app
  - it: should set replicas
    set:
      replicaCount: 3
    asserts:
      - equal:
          path: spec.replicas
          value: 3
```

```bash
# Install unittest plugin
helm plugin install https://github.com/quintush/helm-unittest

# Run tests
helm unittest ./my-chart
```
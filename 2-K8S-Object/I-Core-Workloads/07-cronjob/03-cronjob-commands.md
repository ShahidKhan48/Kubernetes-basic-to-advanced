# CronJob Commands

## 📋 Basic Commands

### Create and Manage CronJobs
```bash
# Create cronjob from YAML
kubectl apply -f cronjob.yaml

# Create cronjob imperatively
kubectl create cronjob hello --image=busybox --schedule="*/1 * * * *" -- echo hello

# Get cronjobs
kubectl get cronjobs
kubectl get cj  # Short form

# Describe cronjob
kubectl describe cronjob <cronjob-name>

# Delete cronjob
kubectl delete cronjob <cronjob-name>
```

### Job Management
```bash
# List jobs created by cronjob
kubectl get jobs --selector=job-name=<cronjob-name>

# Create manual job from cronjob
kubectl create job --from=cronjob/<cronjob-name> <manual-job-name>

# Delete all jobs from cronjob
kubectl delete jobs --selector=job-name=<cronjob-name>
```

### Monitoring and Debugging
```bash
# Watch cronjob execution
kubectl get cronjobs -w

# Check cronjob events
kubectl get events --field-selector involvedObject.name=<cronjob-name>

# View job logs
kubectl logs job/<job-name>

# Get job pods
kubectl get pods --selector=job-name=<job-name>
```

### Advanced Operations
```bash
# Suspend cronjob
kubectl patch cronjob <cronjob-name> -p '{"spec":{"suspend":true}}'

# Resume cronjob
kubectl patch cronjob <cronjob-name> -p '{"spec":{"suspend":false}}'

# Update schedule
kubectl patch cronjob <cronjob-name> -p '{"spec":{"schedule":"0 3 * * *"}}'

# Export cronjob YAML
kubectl get cronjob <cronjob-name> -o yaml > cronjob-backup.yaml
```

## 🔧 Useful Aliases
```bash
alias kcj='kubectl get cronjobs'
alias kdcj='kubectl describe cronjob'
alias kdelcj='kubectl delete cronjob'
```
# CronJob Troubleshooting

## 🔍 Common Issues

### 1. CronJob Not Running
```bash
# Check cronjob status
kubectl get cronjobs
kubectl describe cronjob <cronjob-name>

# Check if jobs are being created
kubectl get jobs --selector=job-name=<cronjob-name>

# Verify schedule format
kubectl get cronjob <cronjob-name> -o yaml | grep schedule
```

### 2. Jobs Failing
```bash
# Check job status
kubectl get jobs
kubectl describe job <job-name>

# Check pod logs
kubectl logs job/<job-name>
kubectl get pods --selector=job-name=<job-name>
```

### 3. Schedule Issues
```bash
# Validate cron expression
# Use online cron validators
# Format: "minute hour day month dayofweek"

# Check timezone (CronJobs use UTC)
kubectl get cronjob <cronjob-name> -o yaml | grep schedule
```

## 🛠️ Debugging Commands
```bash
# Manual job creation for testing
kubectl create job --from=cronjob/<cronjob-name> test-job

# Check events
kubectl get events --field-selector involvedObject.name=<cronjob-name>

# View cronjob history
kubectl get jobs --selector=job-name=<cronjob-name> --sort-by=.metadata.creationTimestamp
```

## 📋 Best Practices
- Test cron expressions before deployment
- Monitor job execution and failures
- Set appropriate resource limits
- Use proper restart policies
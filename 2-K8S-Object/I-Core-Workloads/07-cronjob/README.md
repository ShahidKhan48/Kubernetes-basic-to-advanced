# CronJob

## 📚 Overview
Kubernetes CronJob for scheduled task execution aur batch processing.

## 🎯 CronJob Features
- **Scheduled Execution**: Cron-based scheduling
- **Job Management**: Automatic job creation
- **History Management**: Success/failure history
- **Concurrency Control**: Parallel execution control

## 📖 Basic CronJob Example
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-cronjob
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: spicybiryaniwala.shop/backup:v1.0.0
            command:
            - /bin/sh
            - -c
            - |
              echo "Starting backup at $(date)"
              # Backup logic here
              echo "Backup completed at $(date)"
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

## 🔧 Commands
```bash
# Create cronjob
kubectl apply -f cronjob.yaml

# Get cronjobs
kubectl get cronjobs

# Describe cronjob
kubectl describe cronjob backup-cronjob

# Get jobs created by cronjob
kubectl get jobs --selector=job-name=backup-cronjob

# Manual trigger
kubectl create job --from=cronjob/backup-cronjob manual-backup
```

## 📋 Best Practices
- Use appropriate restart policies
- Set resource limits
- Monitor job execution
- Handle failures gracefully
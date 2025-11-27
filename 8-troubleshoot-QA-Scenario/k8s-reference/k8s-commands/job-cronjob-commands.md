# Job & CronJob Commands

## Job Commands
```bash
# Create Job
kubectl apply -f job.yaml
kubectl create job my-job --image=busybox -- echo "Hello World"

# Get Jobs
kubectl get jobs
kubectl get jobs -w  # watch

# Describe Job
kubectl describe job my-job

# Get Job Logs
kubectl logs job/my-job

# Delete Job
kubectl delete job my-job
```

## CronJob Commands
```bash
# Create CronJob
kubectl apply -f cronjob.yaml
kubectl create cronjob my-cronjob --image=busybox --schedule="0 2 * * *" -- echo "Hello"

# Get CronJobs
kubectl get cronjobs
kubectl get cj

# Describe CronJob
kubectl describe cronjob my-cronjob

# Suspend/Resume CronJob
kubectl patch cronjob my-cronjob -p '{"spec":{"suspend":true}}'
kubectl patch cronjob my-cronjob -p '{"spec":{"suspend":false}}'

# Delete CronJob
kubectl delete cronjob my-cronjob
```
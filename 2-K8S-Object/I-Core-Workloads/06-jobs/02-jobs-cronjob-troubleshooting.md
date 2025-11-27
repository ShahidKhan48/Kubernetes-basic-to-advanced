# Jobs and CronJob Troubleshooting Guide

## Common Job Issues

### 1. Job Not Completing Successfully

#### Symptoms
```bash
kubectl get jobs
NAME        COMPLETIONS   DURATION   AGE
basic-job   0/1           5m         5m

kubectl get pods -l job-name=basic-job
NAME              READY   STATUS   RESTARTS   AGE
basic-job-abc123  0/1     Error    0          5m
```

#### Troubleshooting Steps
```bash
# Check job status and events
kubectl describe job basic-job

# Check pod logs
kubectl logs -l job-name=basic-job
kubectl logs basic-job-abc123

# Check pod events
kubectl describe pod basic-job-abc123

# Check job configuration
kubectl get job basic-job -o yaml | grep -A 10 spec
```

#### Common Causes
- Container command/script failures
- Resource constraints
- Image pull failures
- Incorrect restart policy
- Environment variable issues

#### Solutions
```bash
# Check and fix restart policy (should be Never or OnFailure)
kubectl patch job basic-job -p '{"spec":{"template":{"spec":{"restartPolicy":"Never"}}}}'

# Increase backoff limit for retries
kubectl patch job basic-job -p '{"spec":{"backoffLimit":5}}'

# Check resource requests
kubectl describe job basic-job | grep -A 5 "Requests\|Limits"
```

### 2. Job Pods Stuck in Pending State

#### Symptoms
```bash
kubectl get pods -l job-name=parallel-job
NAME                  READY   STATUS    RESTARTS   AGE
parallel-job-abc123   0/1     Pending   0          10m
parallel-job-def456   0/1     Pending   0          10m
```

#### Troubleshooting
```bash
# Check pod events
kubectl describe pods -l job-name=parallel-job

# Check node resources
kubectl describe nodes | grep -A 10 "Allocated resources"
kubectl top nodes

# Check resource quotas
kubectl get resourcequota
kubectl describe resourcequota

# Check if nodes are available
kubectl get nodes
```

#### Solutions
```bash
# Reduce resource requests
kubectl patch job parallel-job -p '{"spec":{"template":{"spec":{"containers":[{"name":"worker","resources":{"requests":{"memory":"32Mi","cpu":"25m"}}}]}}}}'

# Reduce parallelism
kubectl patch job parallel-job -p '{"spec":{"parallelism":1}}'

# Check and increase resource quotas if needed
kubectl patch resourcequota <quota-name> -p '{"spec":{"hard":{"requests.cpu":"4","requests.memory":"8Gi"}}}'
```

### 3. Job Taking Too Long to Complete

#### Symptoms
```bash
kubectl get jobs
NAME           COMPLETIONS   DURATION   AGE
long-job       2/5           30m        30m
```

#### Troubleshooting
```bash
# Check active deadline
kubectl get job long-job -o jsonpath='{.spec.activeDeadlineSeconds}'

# Check parallelism vs completions
kubectl get job long-job -o jsonpath='{.spec.parallelism}'
kubectl get job long-job -o jsonpath='{.spec.completions}'

# Check pod status
kubectl get pods -l job-name=long-job
kubectl logs -l job-name=long-job --tail=50
```

#### Solutions
```bash
# Increase parallelism
kubectl patch job long-job -p '{"spec":{"parallelism":3}}'

# Extend active deadline
kubectl patch job long-job -p '{"spec":{"activeDeadlineSeconds":7200}}'

# Check if pods are actually working
kubectl exec <job-pod-name> -- ps aux
```

### 4. Job Failing with BackoffLimitExceeded

#### Symptoms
```bash
kubectl get jobs
NAME          COMPLETIONS   DURATION   AGE
failing-job   0/1           10m        10m

kubectl describe job failing-job
# Conditions: BackoffLimitExceeded
```

#### Troubleshooting
```bash
# Check failed pods
kubectl get pods -l job-name=failing-job
kubectl logs <failed-pod-name>

# Check backoff limit
kubectl get job failing-job -o jsonpath='{.spec.backoffLimit}'

# Check pod restart policy
kubectl get job failing-job -o jsonpath='{.spec.template.spec.restartPolicy}'
```

#### Solutions
```bash
# Increase backoff limit
kubectl patch job failing-job -p '{"spec":{"backoffLimit":10}}'

# Fix the underlying issue in the container
# Then delete and recreate the job
kubectl delete job failing-job
kubectl apply -f fixed-job.yaml
```

## Common CronJob Issues

### 1. CronJob Not Creating Jobs

#### Symptoms
```bash
kubectl get cronjobs
NAME            SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
backup-cronjob  0 2 * * *     False     0        <none>          1d
```

#### Troubleshooting Steps
```bash
# Check CronJob status
kubectl describe cronjob backup-cronjob

# Check schedule format
kubectl get cronjob backup-cronjob -o jsonpath='{.spec.schedule}'

# Check if suspended
kubectl get cronjob backup-cronjob -o jsonpath='{.spec.suspend}'

# Check starting deadline
kubectl get cronjob backup-cronjob -o jsonpath='{.spec.startingDeadlineSeconds}'

# Check timezone
kubectl get cronjob backup-cronjob -o jsonpath='{.spec.timeZone}'
```

#### Solutions
```bash
# Fix schedule format (use online cron validators)
kubectl patch cronjob backup-cronjob -p '{"spec":{"schedule":"0 2 * * *"}}'

# Unsuspend if suspended
kubectl patch cronjob backup-cronjob -p '{"spec":{"suspend":false}}'

# Increase starting deadline
kubectl patch cronjob backup-cronjob -p '{"spec":{"startingDeadlineSeconds":300}}'

# Manually trigger job for testing
kubectl create job manual-backup --from=cronjob/backup-cronjob
```

### 2. CronJob Creating Too Many Jobs

#### Symptoms
```bash
kubectl get jobs | grep backup-cronjob
backup-cronjob-1234567890   1/1     30s     2m
backup-cronjob-1234567891   1/1     30s     1m
backup-cronjob-1234567892   0/1     30s     30s
```

#### Troubleshooting
```bash
# Check concurrency policy
kubectl get cronjob backup-cronjob -o jsonpath='{.spec.concurrencyPolicy}'

# Check job history limits
kubectl get cronjob backup-cronjob -o jsonpath='{.spec.successfulJobsHistoryLimit}'
kubectl get cronjob backup-cronjob -o jsonpath='{.spec.failedJobsHistoryLimit}'

# Check if jobs are completing
kubectl get jobs -l job-name=backup-cronjob
```

#### Solutions
```bash
# Set concurrency policy to Forbid
kubectl patch cronjob backup-cronjob -p '{"spec":{"concurrencyPolicy":"Forbid"}}'

# Reduce history limits
kubectl patch cronjob backup-cronjob -p '{"spec":{"successfulJobsHistoryLimit":1,"failedJobsHistoryLimit":1}}'

# Clean up old jobs manually
kubectl delete jobs -l job-name=backup-cronjob --field-selector=status.successful=1
```

### 3. CronJob Jobs Failing Consistently

#### Symptoms
```bash
kubectl get jobs | grep report-cronjob
report-cronjob-1234567890   0/1     5m      5m
report-cronjob-1234567891   0/1     5m      10m
```

#### Troubleshooting
```bash
# Check recent job logs
kubectl logs -l job-name=report-cronjob --tail=100

# Check job template configuration
kubectl get cronjob report-cronjob -o yaml | grep -A 50 jobTemplate

# Check if it's a timing issue
kubectl describe cronjob report-cronjob | grep -A 10 Events
```

#### Solutions
```bash
# Increase job deadline
kubectl patch cronjob report-cronjob -p '{"spec":{"jobTemplate":{"spec":{"activeDeadlineSeconds":3600}}}}'

# Increase backoff limit
kubectl patch cronjob report-cronjob -p '{"spec":{"jobTemplate":{"spec":{"backoffLimit":3}}}}'

# Test with manual job
kubectl create job test-report --from=cronjob/report-cronjob
kubectl logs -f job/test-report
```

### 4. CronJob Schedule Issues

#### Symptoms
```bash
# CronJob should run every hour but last ran 3 hours ago
kubectl get cronjobs
NAME         SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hourly-job   0 * * * *   False     0        3h              1d
```

#### Troubleshooting
```bash
# Check CronJob controller logs
kubectl logs -n kube-system -l component=kube-controller-manager | grep cronjob

# Check system time on nodes
kubectl get nodes -o wide

# Verify schedule syntax
echo "0 * * * *" | crontab -

# Check starting deadline
kubectl get cronjob hourly-job -o jsonpath='{.spec.startingDeadlineSeconds}'
```

#### Solutions
```bash
# Set appropriate starting deadline
kubectl patch cronjob hourly-job -p '{"spec":{"startingDeadlineSeconds":3600}}'

# Check and fix timezone if needed
kubectl patch cronjob hourly-job -p '{"spec":{"timeZone":"UTC"}}'

# Restart CronJob controller if needed (cluster admin task)
kubectl rollout restart deployment/kube-controller-manager -n kube-system
```

## Debugging Commands

### Job Information
```bash
# Get job details
kubectl get jobs
kubectl get jobs -o wide
kubectl describe job <job-name>

# Get job status
kubectl get job <job-name> -o jsonpath='{.status}'

# Check job conditions
kubectl get job <job-name> -o jsonpath='{.status.conditions[*].type}'

# Get job YAML
kubectl get job <job-name> -o yaml
```

### CronJob Information
```bash
# Get CronJob details
kubectl get cronjobs
kubectl get cj  # Short form
kubectl describe cronjob <cronjob-name>

# Check CronJob schedule
kubectl get cronjob <cronjob-name> -o jsonpath='{.spec.schedule}'

# Check last schedule time
kubectl get cronjob <cronjob-name> -o jsonpath='{.status.lastScheduleTime}'

# Get CronJob YAML
kubectl get cronjob <cronjob-name> -o yaml
```

### Pod Analysis
```bash
# Get pods for job
kubectl get pods -l job-name=<job-name>
kubectl get pods --show-labels | grep <job-name>

# Get pod logs
kubectl logs -l job-name=<job-name>
kubectl logs <job-pod-name>

# Check pod events
kubectl describe pods -l job-name=<job-name>
```

### Resource Analysis
```bash
# Check resource usage
kubectl top pods -l job-name=<job-name>

# Check resource requests
kubectl describe job <job-name> | grep -A 5 "Requests\|Limits"

# Check node resources
kubectl describe nodes | grep -A 10 "Allocated resources"
```

## Common Error Messages

### "Job has reached the specified backoff limit"
```bash
# Check failed pods
kubectl get pods -l job-name=<job-name> | grep Error

# Check logs of failed pods
kubectl logs <failed-pod-name>

# Increase backoff limit or fix the underlying issue
kubectl patch job <job-name> -p '{"spec":{"backoffLimit":10}}'
```

### "Job was active longer than specified deadline"
```bash
# Check active deadline
kubectl get job <job-name> -o jsonpath='{.spec.activeDeadlineSeconds}'

# Increase deadline or optimize job performance
kubectl patch job <job-name> -p '{"spec":{"activeDeadlineSeconds":7200}}'
```

### "CronJob schedule format is invalid"
```bash
# Validate cron schedule format
# Use online cron validators or:
echo "0 2 * * *" | crontab -

# Fix schedule format
kubectl patch cronjob <cronjob-name> -p '{"spec":{"schedule":"0 2 * * *"}}'
```

## Best Practices for Troubleshooting

### 1. Check Job Configuration
```bash
kubectl describe job <job-name>
kubectl get job <job-name> -o yaml | grep -A 20 spec
```

### 2. Monitor Pod Lifecycle
```bash
kubectl get pods -l job-name=<job-name> -w
kubectl logs -l job-name=<job-name> -f
```

### 3. Validate Resource Requirements
```bash
kubectl top pods -l job-name=<job-name>
kubectl describe nodes | grep -A 10 "Allocated resources"
```

### 4. Test with Manual Jobs
```bash
# Create manual job from CronJob
kubectl create job test-job --from=cronjob/<cronjob-name>
kubectl logs -f job/test-job
```

### 5. Check System Resources
```bash
kubectl get resourcequota
kubectl describe limitrange
kubectl top nodes
```

### 6. Monitor Job History
```bash
# For CronJobs, check job history
kubectl get jobs -l job-name=<cronjob-name> --sort-by=.metadata.creationTimestamp

# Clean up old jobs
kubectl delete jobs -l job-name=<cronjob-name> --field-selector=status.successful=1
```

### 7. Use Appropriate Restart Policies
- **Never**: For jobs that should not restart on failure
- **OnFailure**: For jobs that should retry on failure
- **Always**: Not recommended for Jobs (use for long-running services)

### 8. Set Reasonable Timeouts
```bash
# Set active deadline for jobs
kubectl patch job <job-name> -p '{"spec":{"activeDeadlineSeconds":3600}}'

# Set starting deadline for CronJobs
kubectl patch cronjob <cronjob-name> -p '{"spec":{"startingDeadlineSeconds":300}}'
```
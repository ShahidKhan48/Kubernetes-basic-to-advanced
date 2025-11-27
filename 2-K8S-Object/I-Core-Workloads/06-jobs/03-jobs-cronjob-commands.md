# Jobs and CronJob Commands Reference

## Job Creation Commands

### Imperative Creation
```bash
# Create job from image
kubectl create job hello-job --image=busybox -- echo "Hello World"
kubectl create job pi-job --image=perl -- perl -Mbignum=bpi -wle 'print bpi(2000)'

# Create job with specific command
kubectl create job data-processor --image=busybox -- /bin/sh -c 'echo "Processing data"; sleep 30; echo "Done"'

# Generate job YAML
kubectl create job sample-job --image=busybox --dry-run=client -o yaml -- echo "Hello" > job.yaml

# Create from YAML
kubectl apply -f job.yaml
kubectl create -f job.yaml
```

### Declarative Management
```bash
# Apply job configuration
kubectl apply -f job.yaml
kubectl apply -f ./jobs/

# Validate configuration
kubectl apply -f job.yaml --dry-run=client
kubectl apply -f job.yaml --validate=true

# Show differences
kubectl diff -f job.yaml
```

## CronJob Creation Commands

### Imperative Creation
```bash
# Create basic CronJob
kubectl create cronjob hello-cron --image=busybox --schedule="*/1 * * * *" -- echo "Hello World"

# Create CronJob with specific schedule
kubectl create cronjob backup-cron --image=mysql:8.0 --schedule="0 2 * * *" -- mysqldump -h mysql-host --all-databases

# Generate CronJob YAML
kubectl create cronjob sample-cron --image=busybox --schedule="0 */6 * * *" --dry-run=client -o yaml -- echo "Hello" > cronjob.yaml

# Create from YAML
kubectl apply -f cronjob.yaml
```

### Manual Job Creation from CronJob
```bash
# Create job from CronJob template
kubectl create job manual-backup --from=cronjob/backup-cron
kubectl create job test-run --from=cronjob/hello-cron

# Create job with custom name
kubectl create job backup-$(date +%Y%m%d) --from=cronjob/backup-cron
```

## Job Information Commands

### Basic Information
```bash
# List jobs
kubectl get jobs
kubectl get job                      # Singular form
kubectl get jobs -A                  # All namespaces
kubectl get jobs -n <namespace>      # Specific namespace
kubectl get jobs -o wide             # Extended information
kubectl get jobs --show-labels       # Show labels

# Filter jobs
kubectl get jobs -l app=data-processor
kubectl get jobs --field-selector=status.successful=1

# Detailed job information
kubectl describe job <job-name>
kubectl describe jobs                # All jobs
```

### Job Status
```bash
# Get job status
kubectl get jobs -o custom-columns=NAME:.metadata.name,COMPLETIONS:.spec.completions,SUCCESSFUL:.status.succeeded,ACTIVE:.status.active,AGE:.metadata.creationTimestamp

# Check job conditions
kubectl get job <job-name> -o jsonpath='{.status.conditions[*].type}'
kubectl get job <job-name> -o jsonpath='{.status.conditions[*].reason}'

# Get job completion status
kubectl get job <job-name> -o jsonpath='{.status.succeeded}'
kubectl get job <job-name> -o jsonpath='{.status.failed}'

# Watch job progress
kubectl get jobs -w
kubectl get jobs <job-name> -w
```

## CronJob Information Commands

### Basic Information
```bash
# List CronJobs
kubectl get cronjobs
kubectl get cj                       # Short form
kubectl get cronjobs -A              # All namespaces
kubectl get cronjobs -n <namespace>  # Specific namespace
kubectl get cronjobs -o wide         # Extended information
kubectl get cronjobs --show-labels   # Show labels

# Detailed CronJob information
kubectl describe cronjob <cronjob-name>
kubectl describe cronjobs            # All CronJobs
```

### CronJob Status
```bash
# Get CronJob status
kubectl get cronjobs -o custom-columns=NAME:.metadata.name,SCHEDULE:.spec.schedule,SUSPEND:.spec.suspend,ACTIVE:.status.active,LAST-SCHEDULE:.status.lastScheduleTime

# Check last schedule time
kubectl get cronjob <cronjob-name> -o jsonpath='{.status.lastScheduleTime}'

# Check next schedule time (calculated)
kubectl get cronjob <cronjob-name> -o jsonpath='{.status.lastScheduleTime}'

# Watch CronJob changes
kubectl get cronjobs -w
```

## Job Management Commands

### Job Execution Control
```bash
# Wait for job completion
kubectl wait --for=condition=complete job/<job-name>
kubectl wait --for=condition=complete job/<job-name> --timeout=300s

# Wait for job failure
kubectl wait --for=condition=failed job/<job-name>

# Check if job is complete
kubectl get job <job-name> -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}'
```

### Job Configuration Updates
```bash
# Update job parallelism (before job starts)
kubectl patch job <job-name> -p '{"spec":{"parallelism":5}}'

# Update backoff limit
kubectl patch job <job-name> -p '{"spec":{"backoffLimit":10}}'

# Update active deadline
kubectl patch job <job-name> -p '{"spec":{"activeDeadlineSeconds":3600}}'

# Add labels to job
kubectl label job <job-name> environment=production version=v1

# Add annotations
kubectl annotate job <job-name> description="Data processing job"
```

## CronJob Management Commands

### Schedule Management
```bash
# Update CronJob schedule
kubectl patch cronjob <cronjob-name> -p '{"spec":{"schedule":"0 3 * * *"}}'

# Suspend CronJob
kubectl patch cronjob <cronjob-name> -p '{"spec":{"suspend":true}}'

# Resume CronJob
kubectl patch cronjob <cronjob-name> -p '{"spec":{"suspend":false}}'

# Update timezone
kubectl patch cronjob <cronjob-name> -p '{"spec":{"timeZone":"America/New_York"}}'
```

### CronJob Configuration Updates
```bash
# Update concurrency policy
kubectl patch cronjob <cronjob-name> -p '{"spec":{"concurrencyPolicy":"Forbid"}}'
# Options: Allow, Forbid, Replace

# Update job history limits
kubectl patch cronjob <cronjob-name> -p '{"spec":{"successfulJobsHistoryLimit":5,"failedJobsHistoryLimit":3}}'

# Update starting deadline
kubectl patch cronjob <cronjob-name> -p '{"spec":{"startingDeadlineSeconds":300}}'

# Update job template
kubectl patch cronjob <cronjob-name> -p '{"spec":{"jobTemplate":{"spec":{"backoffLimit":5}}}}'
```

## Pod Management Commands

### Job Pod Information
```bash
# Get pods for job
kubectl get pods -l job-name=<job-name>
kubectl get pods --selector=job-name=<job-name>

# Get pods with job ownership
kubectl get pods -o custom-columns=NAME:.metadata.name,JOB:.metadata.ownerReferences[0].name,STATUS:.status.phase

# Check pod completion status
kubectl get pods -l job-name=<job-name> -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount
```

### Pod Operations
```bash
# Get logs from job pods
kubectl logs -l job-name=<job-name>
kubectl logs -l job-name=<job-name> --all-containers=true
kubectl logs -l job-name=<job-name> -f

# Get logs from specific job pod
kubectl logs <job-pod-name>
kubectl logs <job-pod-name> -f

# Execute commands in job pod (if still running)
kubectl exec -it <job-pod-name> -- /bin/bash
kubectl exec <job-pod-name> -- <command>

# Delete job pods (job will recreate if not complete)
kubectl delete pods -l job-name=<job-name>
```

## Job Deletion Commands

### Job Cleanup
```bash
# Delete specific job
kubectl delete job <job-name>

# Delete jobs by label
kubectl delete jobs -l app=data-processor

# Delete completed jobs
kubectl delete jobs --field-selector=status.successful=1

# Delete failed jobs
kubectl delete jobs --field-selector=status.failed=1

# Delete all jobs in namespace
kubectl delete jobs --all

# Delete from file
kubectl delete -f job.yaml
```

### CronJob Cleanup
```bash
# Delete CronJob
kubectl delete cronjob <cronjob-name>

# Delete CronJob and its jobs
kubectl delete cronjob <cronjob-name>
kubectl delete jobs -l job-name=<cronjob-name>

# Delete CronJobs by label
kubectl delete cronjobs -l environment=test

# Delete from file
kubectl delete -f cronjob.yaml
```

### Batch Cleanup
```bash
# Delete old completed jobs (keep last 3)
kubectl get jobs --sort-by=.metadata.creationTimestamp -o name | head -n -3 | xargs kubectl delete

# Delete jobs older than 1 day
kubectl get jobs -o json | jq -r '.items[] | select(.metadata.creationTimestamp < (now - 86400 | strftime("%Y-%m-%dT%H:%M:%SZ"))) | .metadata.name' | xargs kubectl delete job

# Clean up jobs for specific CronJob
kubectl delete jobs -l job-name=<cronjob-name> --field-selector=status.successful=1
```

## Debugging Commands

### Job Status Analysis
```bash
# Check job completion
kubectl get job <job-name> -o jsonpath='{.status.succeeded}/{.spec.completions}'

# Check job failure reasons
kubectl get job <job-name> -o jsonpath='{.status.conditions[?(@.type=="Failed")].reason}'

# Check active pods
kubectl get job <job-name> -o jsonpath='{.status.active}'

# Get job events
kubectl get events --field-selector involvedObject.kind=Job
kubectl get events --field-selector involvedObject.name=<job-name>
```

### CronJob Analysis
```bash
# Check CronJob schedule validity
kubectl get cronjob <cronjob-name> -o jsonpath='{.spec.schedule}'

# Check if CronJob is suspended
kubectl get cronjob <cronjob-name> -o jsonpath='{.spec.suspend}'

# Check active jobs from CronJob
kubectl get cronjob <cronjob-name> -o jsonpath='{.status.active[*].name}'

# Get CronJob events
kubectl get events --field-selector involvedObject.kind=CronJob
kubectl get events --field-selector involvedObject.name=<cronjob-name>
```

### Resource Analysis
```bash
# Check resource usage of job pods
kubectl top pods -l job-name=<job-name>

# Check resource requests/limits
kubectl describe job <job-name> | grep -A 5 "Requests\|Limits"

# Check node resources
kubectl describe nodes | grep -A 10 "Allocated resources"
kubectl top nodes
```

## Advanced Operations

### Job Scaling and Parallelism
```bash
# Check current parallelism
kubectl get job <job-name> -o jsonpath='{.spec.parallelism}'

# Update parallelism (only before job completion)
kubectl patch job <job-name> -p '{"spec":{"parallelism":10}}'

# Check completions vs parallelism
kubectl get job <job-name> -o jsonpath='{.spec.completions}'
kubectl get job <job-name> -o jsonpath='{.spec.parallelism}'
```

### Job Templates and Patterns
```bash
# Create job template
kubectl create job template-job --image=busybox --dry-run=client -o yaml -- echo "Template" > job-template.yaml

# Use template to create multiple jobs
for i in {1..5}; do
  sed "s/template-job/job-$i/g" job-template.yaml | kubectl apply -f -
done

# Create job with unique name
kubectl create job backup-$(date +%Y%m%d-%H%M%S) --image=mysql:8.0 -- mysqldump --all-databases
```

### Monitoring and Alerting
```bash
# Monitor job completion rate
kubectl get jobs -o json | jq '.items[] | select(.status.succeeded == .spec.completions) | .metadata.name'

# Monitor failed jobs
kubectl get jobs -o json | jq '.items[] | select(.status.failed > 0) | .metadata.name'

# Check job duration
kubectl get jobs -o custom-columns=NAME:.metadata.name,DURATION:.status.completionTime,START:.status.startTime

# Monitor CronJob execution
kubectl get jobs -l job-name=<cronjob-name> --sort-by=.metadata.creationTimestamp
```

### Backup and Restore
```bash
# Backup job configuration
kubectl get job <job-name> -o yaml > job-backup.yaml

# Backup CronJob configuration
kubectl get cronjob <cronjob-name> -o yaml > cronjob-backup.yaml

# Export all jobs
kubectl get jobs -o yaml > all-jobs-backup.yaml

# Export all CronJobs
kubectl get cronjobs -o yaml > all-cronjobs-backup.yaml
```

## Best Practices Commands

### Job Configuration
```bash
# Set appropriate restart policy
kubectl patch job <job-name> -p '{"spec":{"template":{"spec":{"restartPolicy":"Never"}}}}'

# Set resource limits
kubectl patch job <job-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"job","resources":{"requests":{"memory":"128Mi","cpu":"100m"},"limits":{"memory":"256Mi","cpu":"200m"}}}]}}}}'

# Set active deadline
kubectl patch job <job-name> -p '{"spec":{"activeDeadlineSeconds":3600}}'

# Set backoff limit
kubectl patch job <job-name> -p '{"spec":{"backoffLimit":3}}'
```

### CronJob Configuration
```bash
# Set concurrency policy
kubectl patch cronjob <cronjob-name> -p '{"spec":{"concurrencyPolicy":"Forbid"}}'

# Set job history limits
kubectl patch cronjob <cronjob-name> -p '{"spec":{"successfulJobsHistoryLimit":3,"failedJobsHistoryLimit":1}}'

# Set starting deadline
kubectl patch cronjob <cronjob-name> -p '{"spec":{"startingDeadlineSeconds":300}}'

# Set timezone
kubectl patch cronjob <cronjob-name> -p '{"spec":{"timeZone":"UTC"}}'
```

### Security and Permissions
```bash
# Set security context
kubectl patch job <job-name> -p '{"spec":{"template":{"spec":{"securityContext":{"runAsUser":1000,"runAsGroup":3000,"fsGroup":2000}}}}}'

# Add service account
kubectl patch job <job-name> -p '{"spec":{"template":{"spec":{"serviceAccountName":"job-service-account"}}}}'

# Set pod security context
kubectl patch job <job-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"job","securityContext":{"allowPrivilegeEscalation":false,"readOnlyRootFilesystem":true}}]}}}}'
```

### Cleanup Automation
```bash
# Set TTL for job cleanup (Kubernetes 1.23+)
kubectl patch job <job-name> -p '{"spec":{"ttlSecondsAfterFinished":3600}}'

# Create cleanup CronJob
kubectl create cronjob job-cleanup --image=bitnami/kubectl --schedule="0 2 * * *" -- kubectl delete jobs --field-selector=status.successful=1
```
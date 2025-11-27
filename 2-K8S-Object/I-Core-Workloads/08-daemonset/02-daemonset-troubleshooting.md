# DaemonSet Troubleshooting Guide

## Common DaemonSet Issues

### 1. DaemonSet Pods Not Running on All Nodes

#### Symptoms
```bash
kubectl get daemonset
NAME                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
log-collector       3         2         2       2            2           <none>          10m

kubectl get nodes
NAME     STATUS   ROLES           AGE   VERSION
node-1   Ready    control-plane   1d    v1.28.0
node-2   Ready    <none>          1d    v1.28.0
node-3   Ready    <none>          1d    v1.28.0
```

#### Troubleshooting Steps
```bash
# Check DaemonSet status
kubectl describe daemonset log-collector

# Check node taints
kubectl describe nodes | grep -A 5 Taints

# Check node selectors
kubectl get daemonset log-collector -o yaml | grep -A 5 nodeSelector

# Check tolerations
kubectl get daemonset log-collector -o yaml | grep -A 10 tolerations

# Check pod status on each node
kubectl get pods -o wide | grep log-collector
```

#### Common Causes
- Node taints preventing pod scheduling
- Node selector not matching node labels
- Missing tolerations for tainted nodes
- Resource constraints on nodes
- Node cordoned or unschedulable

#### Solutions
```bash
# Add tolerations for master nodes
kubectl patch daemonset log-collector -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Exists","effect":"NoSchedule"}]}}}}'

# Remove node selector if too restrictive
kubectl patch daemonset log-collector -p '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'

# Check and uncordon nodes
kubectl uncordon <node-name>
```

### 2. DaemonSet Update Stuck

#### Symptoms
```bash
kubectl rollout status daemonset/log-collector
# Waiting for daemon set "log-collector" rollout to finish: 1 of 3 updated pods are available...
```

#### Troubleshooting
```bash
# Check update strategy
kubectl get daemonset log-collector -o jsonpath='{.spec.updateStrategy}'

# Check maxUnavailable setting
kubectl get daemonset log-collector -o jsonpath='{.spec.updateStrategy.rollingUpdate.maxUnavailable}'

# Check pod status during update
kubectl get pods -l app=log-collector -o wide

# Check events
kubectl describe daemonset log-collector
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Solutions
```bash
# Increase maxUnavailable for faster updates
kubectl patch daemonset log-collector -p '{"spec":{"updateStrategy":{"rollingUpdate":{"maxUnavailable":"50%"}}}}'

# Force update by deleting pods
kubectl delete pods -l app=log-collector

# Change to OnDelete strategy for manual control
kubectl patch daemonset log-collector -p '{"spec":{"updateStrategy":{"type":"OnDelete"}}}'
```

### 3. Privileged Operations Failing

#### Symptoms
```bash
kubectl logs node-exporter-abc123
# Error: permission denied accessing /proc
# Error: operation not permitted
```

#### Troubleshooting
```bash
# Check security context
kubectl get daemonset node-exporter -o yaml | grep -A 10 securityContext

# Check if privileged mode is enabled
kubectl describe pod node-exporter-abc123 | grep -i privileged

# Check host network/PID settings
kubectl get daemonset node-exporter -o yaml | grep -E "hostNetwork|hostPID"
```

#### Solutions
```bash
# Enable privileged mode
kubectl patch daemonset node-exporter -p '{"spec":{"template":{"spec":{"containers":[{"name":"node-exporter","securityContext":{"privileged":true}}]}}}}'

# Enable host network
kubectl patch daemonset node-exporter -p '{"spec":{"template":{"spec":{"hostNetwork":true}}}}'

# Add required capabilities
kubectl patch daemonset node-exporter -p '{"spec":{"template":{"spec":{"containers":[{"name":"node-exporter","securityContext":{"capabilities":{"add":["SYS_TIME","NET_ADMIN"]}}}]}}}}'
```

### 4. Resource Constraints

#### Symptoms
```bash
kubectl get pods -l app=log-collector
NAME                    READY   STATUS    RESTARTS   AGE
log-collector-node1     0/1     Pending   0          5m
log-collector-node2     1/1     Running   0          5m
log-collector-node3     1/1     Running   0          5m
```

#### Troubleshooting
```bash
# Check pod events
kubectl describe pod log-collector-node1

# Check node resources
kubectl describe node node1 | grep -A 10 "Allocated resources"
kubectl top nodes

# Check resource requests
kubectl describe daemonset log-collector | grep -A 5 "Requests"
```

#### Solutions
```bash
# Reduce resource requests
kubectl patch daemonset log-collector -p '{"spec":{"template":{"spec":{"containers":[{"name":"log-collector","resources":{"requests":{"memory":"64Mi","cpu":"50m"}}}]}}}}'

# Add node with more resources
# Or remove resource requests for system DaemonSets
kubectl patch daemonset log-collector -p '{"spec":{"template":{"spec":{"containers":[{"name":"log-collector","resources":null}]}}}}'
```

### 5. Host Path Volume Issues

#### Symptoms
```bash
kubectl logs log-collector-abc123
# Error: failed to mount volume: no such file or directory
# Error: permission denied writing to /var/log
```

#### Troubleshooting
```bash
# Check volume mounts
kubectl describe pod log-collector-abc123 | grep -A 10 "Mounts"

# Check host path existence
kubectl exec log-collector-abc123 -- ls -la /var/log

# Check volume configuration
kubectl get daemonset log-collector -o yaml | grep -A 10 volumes
```

#### Solutions
```bash
# Use DirectoryOrCreate for host paths
kubectl patch daemonset log-collector -p '{"spec":{"template":{"spec":{"volumes":[{"name":"varlog","hostPath":{"path":"/var/log","type":"DirectoryOrCreate"}}]}}}}'

# Fix permissions with init container
kubectl patch daemonset log-collector -p '{"spec":{"template":{"spec":{"initContainers":[{"name":"fix-permissions","image":"busybox","command":["sh","-c","mkdir -p /var/log && chmod 755 /var/log"],"volumeMounts":[{"name":"varlog","mountPath":"/var/log"}]}]}}}}'
```

## Debugging Commands

### DaemonSet Information
```bash
# Get DaemonSet details
kubectl get daemonsets
kubectl get ds  # Short form
kubectl describe daemonset <daemonset-name>

# Get DaemonSet status
kubectl get daemonset <daemonset-name> -o wide

# Check DaemonSet YAML
kubectl get daemonset <daemonset-name> -o yaml

# Watch DaemonSet changes
kubectl get daemonsets -w
```

### Pod Distribution Analysis
```bash
# Get pods for DaemonSet
kubectl get pods -l <selector-labels> -o wide
kubectl get pods --field-selector=spec.nodeName=<node-name>

# Check pod distribution across nodes
kubectl get pods -l <selector> -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase

# Count pods per node
kubectl get pods -l <selector> -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c
```

### Node Analysis
```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check node taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key

# Check node labels
kubectl get nodes --show-labels

# Check node resources
kubectl top nodes
kubectl describe nodes | grep -A 10 "Allocated resources"
```

### Scheduling Analysis
```bash
# Check tolerations
kubectl get daemonset <name> -o jsonpath='{.spec.template.spec.tolerations[*]}'

# Check node selector
kubectl get daemonset <name> -o jsonpath='{.spec.template.spec.nodeSelector}'

# Check affinity rules
kubectl get daemonset <name> -o yaml | grep -A 20 affinity
```

## Common Error Messages

### "Pod didn't trigger scale-up (it wouldn't fit if a new node is added)"
```bash
# Check resource requests vs node capacity
kubectl describe nodes | grep -A 10 "Allocated resources"
kubectl describe daemonset <name> | grep -A 5 "Requests"

# Solution: Reduce resource requests or add larger nodes
kubectl patch daemonset <name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"memory":"64Mi","cpu":"50m"}}}]}}}}'
```

### "Node had taints that the pod didn't tolerate"
```bash
# Check node taints
kubectl describe node <node-name> | grep -A 5 Taints

# Add required tolerations
kubectl patch daemonset <name> -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"<taint-key>","operator":"Exists","effect":"NoSchedule"}]}}}}'
```

### "Didn't match node selector"
```bash
# Check node selector vs node labels
kubectl get daemonset <name> -o jsonpath='{.spec.template.spec.nodeSelector}'
kubectl get nodes --show-labels

# Fix node selector or add labels to nodes
kubectl label node <node-name> <key>=<value>
```

## Best Practices for Troubleshooting

### 1. Check Node Coverage
```bash
kubectl get nodes
kubectl get pods -l <selector> -o wide
# Ensure pod count matches node count (minus any excluded nodes)
```

### 2. Verify Tolerations
```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key
kubectl get daemonset <name> -o jsonpath='{.spec.template.spec.tolerations[*].key}'
```

### 3. Monitor Resource Usage
```bash
kubectl top nodes
kubectl top pods -l <selector>
kubectl describe nodes | grep -A 10 "Allocated resources"
```

### 4. Check Update Strategy
```bash
kubectl get daemonset <name> -o jsonpath='{.spec.updateStrategy}'
kubectl rollout status daemonset/<name>
```

### 5. Validate Host Access
```bash
# For DaemonSets that need host access
kubectl exec <pod-name> -- ls -la /host/proc
kubectl exec <pod-name> -- mount | grep host
```

### 6. Use System Priority
```bash
# For system DaemonSets
kubectl patch daemonset <name> -p '{"spec":{"template":{"spec":{"priorityClassName":"system-node-critical"}}}}'
```

### 7. Monitor Events
```bash
kubectl get events --sort-by=.metadata.creationTimestamp | grep DaemonSet
kubectl get events --field-selector involvedObject.kind=DaemonSet
```
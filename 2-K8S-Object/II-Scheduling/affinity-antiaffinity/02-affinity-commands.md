# Affinity and Anti-Affinity Commands Reference

## Node Affinity Commands

### View Node Labels
```bash
# Show all node labels
kubectl get nodes --show-labels

# Show specific labels
kubectl get nodes -o custom-columns=NAME:.metadata.name,ARCH:.metadata.labels.kubernetes\.io/arch,ZONE:.metadata.labels.topology\.kubernetes\.io/zone

# Filter nodes by labels
kubectl get nodes -l disktype=ssd
kubectl get nodes -l instance-type=c5.large
```

### Add Node Labels for Affinity
```bash
# Add architecture labels
kubectl label node <node-name> kubernetes.io/arch=amd64

# Add instance type labels
kubectl label node <node-name> instance-type=c5.large
kubectl label node <node-name> memory-optimized=true

# Add zone labels
kubectl label node <node-name> topology.kubernetes.io/zone=us-west-2a

# Add custom labels
kubectl label node <node-name> disktype=ssd storage-tier=premium
```

## Pod Affinity Configuration

### Update Deployment with Node Affinity
```bash
# Add node affinity to deployment
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"disktype","operator":"In","values":["ssd"]}]}]}}}}}}}'

# Add preferred node affinity
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"preference":{"matchExpressions":[{"key":"instance-type","operator":"In","values":["c5.large"]}]}}]}}}}}'
```

### Update Deployment with Pod Anti-Affinity
```bash
# Add pod anti-affinity (spread across nodes)
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":[{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["web-app"]}]},"topologyKey":"kubernetes.io/hostname"}]}}}}}}'

# Add preferred pod anti-affinity (spread across zones)
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"affinity":{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["web-app"]}]},"topologyKey":"topology.kubernetes.io/zone"}}]}}}}}}'
```

## Troubleshooting Commands

### Check Pod Scheduling
```bash
# Check pod placement
kubectl get pods -o wide

# Check pod affinity rules
kubectl get pod <pod-name> -o yaml | grep -A 20 affinity

# Check pod events for scheduling issues
kubectl describe pod <pod-name>

# Check scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler
```

### Debug Affinity Issues
```bash
# Check if nodes match affinity rules
kubectl get nodes -l disktype=ssd

# Check pod distribution
kubectl get pods -l app=web-app -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName

# Check topology domains
kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone,HOSTNAME:.metadata.labels.kubernetes\.io/hostname
```

## Affinity Operators

### Node Affinity Operators
```bash
# In - label value is in the list
matchExpressions:
- key: instance-type
  operator: In
  values: ["c5.large", "c5.xlarge"]

# NotIn - label value is not in the list
matchExpressions:
- key: instance-type
  operator: NotIn
  values: ["t3.micro", "t3.small"]

# Exists - label key exists (ignore value)
matchExpressions:
- key: gpu-enabled
  operator: Exists

# DoesNotExist - label key does not exist
matchExpressions:
- key: spot-instance
  operator: DoesNotExist

# Gt - label value is greater than
matchExpressions:
- key: cpu-cores
  operator: Gt
  values: ["4"]

# Lt - label value is less than
matchExpressions:
- key: memory-gb
  operator: Lt
  values: ["32"]
```

## Common Affinity Patterns

### High Availability Deployment
```bash
# Create deployment with anti-affinity
kubectl create deployment ha-app --image=nginx --replicas=3 --dry-run=client -o yaml > ha-deployment.yaml

# Edit to add anti-affinity rules
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: ha-app
            topologyKey: kubernetes.io/hostname
```

### Database Cluster with Zone Distribution
```bash
# StatefulSet with zone anti-affinity
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: database
              topologyKey: topology.kubernetes.io/zone
```

### Co-located Services (Cache with Database)
```bash
# Cache deployment with database affinity
spec:
  template:
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: database
            topologyKey: kubernetes.io/hostname
```

## Advanced Affinity Commands

### Multiple Affinity Rules
```bash
# Combine node affinity and pod anti-affinity
kubectl patch deployment web-app -p '{
  "spec": {
    "template": {
      "spec": {
        "affinity": {
          "nodeAffinity": {
            "requiredDuringSchedulingIgnoredDuringExecution": {
              "nodeSelectorTerms": [{
                "matchExpressions": [{
                  "key": "disktype",
                  "operator": "In",
                  "values": ["ssd"]
                }]
              }]
            }
          },
          "podAntiAffinity": {
            "requiredDuringSchedulingIgnoredDuringExecution": [{
              "labelSelector": {
                "matchLabels": {
                  "app": "web-app"
                }
              },
              "topologyKey": "kubernetes.io/hostname"
            }]
          }
        }
      }
    }
  }
}'
```

### Remove Affinity Rules
```bash
# Remove all affinity rules
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"affinity":null}}}}'

# Remove only node affinity
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":null}}}}}'

# Remove only pod affinity
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"affinity":{"podAffinity":null}}}}}'
```

## Monitoring and Validation

### Check Affinity Effectiveness
```bash
# Check pod distribution across nodes
kubectl get pods -l app=web-app -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName | sort -k2

# Check pod distribution across zones
kubectl get pods -l app=web-app -o json | jq -r '.items[] | "\(.metadata.name) \(.spec.nodeName)"' | while read pod node; do
  zone=$(kubectl get node $node -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}')
  echo "$pod $node $zone"
done

# Count pods per node
kubectl get pods -l app=web-app -o json | jq -r '.items[].spec.nodeName' | sort | uniq -c

# Count pods per zone
kubectl get pods -l app=web-app -o json | jq -r '.items[] | .spec.nodeName' | while read node; do
  kubectl get node $node -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
  echo
done | sort | uniq -c
```

### Validate Topology Keys
```bash
# Check available topology keys
kubectl get nodes -o json | jq -r '.items[].metadata.labels | keys[]' | grep -E "(topology|zone|region|hostname)" | sort -u

# Common topology keys:
# kubernetes.io/hostname - node level
# topology.kubernetes.io/zone - zone level
# topology.kubernetes.io/region - region level
# topology.kubernetes.io/rack - rack level (custom)
```
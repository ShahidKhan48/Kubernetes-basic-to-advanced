# Node Selector Commands Reference

## Node Labeling Commands

### Add Labels to Nodes
```bash
# Add single label
kubectl label node <node-name> disktype=ssd
kubectl label node <node-name> environment=production

# Add multiple labels
kubectl label node <node-name> disktype=ssd environment=production zone=us-west-2a

# Add GPU label
kubectl label node <node-name> accelerator=nvidia-tesla-k80 gpu-enabled=true

# Add instance type label
kubectl label node <node-name> instance-type=c5.large memory-optimized=true
```

### View Node Labels
```bash
# Show all node labels
kubectl get nodes --show-labels

# Show specific labels
kubectl get nodes -o custom-columns=NAME:.metadata.name,LABELS:.metadata.labels

# Filter nodes by label
kubectl get nodes -l disktype=ssd
kubectl get nodes -l environment=production
kubectl get nodes -l gpu-enabled=true
```

### Remove Labels from Nodes
```bash
# Remove single label
kubectl label node <node-name> disktype-

# Remove multiple labels
kubectl label node <node-name> disktype- environment-
```

## Pod Scheduling Commands

### Create Pods with Node Selector
```bash
# Create pod with node selector
kubectl run nginx-pod --image=nginx --dry-run=client -o yaml > pod.yaml
# Edit pod.yaml to add nodeSelector, then:
kubectl apply -f pod.yaml

# Create deployment with node selector
kubectl create deployment web-app --image=nginx --dry-run=client -o yaml > deployment.yaml
# Edit deployment.yaml to add nodeSelector, then:
kubectl apply -f deployment.yaml
```

### Check Pod Scheduling
```bash
# Check where pods are scheduled
kubectl get pods -o wide

# Check pod events for scheduling info
kubectl describe pod <pod-name>

# Check pods on specific node
kubectl get pods --field-selector spec.nodeName=<node-name>
```

### Update Node Selector
```bash
# Update deployment node selector
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"nodeSelector":{"disktype":"ssd"}}}}}'

# Remove node selector
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'
```

## Troubleshooting Commands

### Debug Scheduling Issues
```bash
# Check if nodes have required labels
kubectl get nodes -l disktype=ssd

# Check pod status
kubectl get pods
kubectl describe pod <pending-pod-name>

# Check scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler

# Check node capacity
kubectl describe node <node-name>
```

### Common Node Labels
```bash
# Built-in Kubernetes labels
kubectl get nodes -l kubernetes.io/os=linux
kubectl get nodes -l kubernetes.io/arch=amd64
kubectl get nodes -l node.kubernetes.io/instance-type

# Cloud provider labels (AWS)
kubectl get nodes -l topology.kubernetes.io/zone
kubectl get nodes -l node.kubernetes.io/instance-type

# Custom labels
kubectl get nodes -l environment=production
kubectl get nodes -l disktype=ssd
```
# Services Troubleshooting Guide

## Common Service Issues

### 1. Service Not Routing Traffic to Pods

#### Symptoms
```bash
kubectl get svc
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
nginx-service   ClusterIP   10.96.123.45   <none>        80/TCP    5m

# But service doesn't respond
curl 10.96.123.45  # Connection refused or timeout
```

#### Troubleshooting Steps
```bash
# Check service endpoints
kubectl get endpoints nginx-service
kubectl describe endpoints nginx-service

# Check service selector
kubectl get service nginx-service -o yaml | grep -A 5 selector

# Check pod labels
kubectl get pods --show-labels
kubectl get pods -l app=nginx --show-labels

# Test pod directly
kubectl get pods -l app=nginx -o wide
curl <pod-ip>:80
```

#### Common Causes
- Selector doesn't match pod labels
- No pods running with matching labels
- Pods not ready (failing readiness probes)
- Wrong target port configuration

### 2. LoadBalancer Service Stuck in Pending

#### Symptoms
```bash
kubectl get svc
NAME               TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-loadbalancer LoadBalancer   10.96.123.45   <pending>     80:30123/TCP   10m
```

#### Solutions
```bash
# Check cloud provider support
kubectl describe service nginx-loadbalancer

# Check service annotations
kubectl get service nginx-loadbalancer -o yaml | grep -A 10 annotations

# For AWS EKS - check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# For GKE - check if cluster has load balancer support
kubectl describe nodes | grep -i "cloud provider"

# Check service events
kubectl describe service nginx-loadbalancer
```

### 3. NodePort Service Not Accessible

#### Symptoms
```bash
# Service shows NodePort but not accessible from outside
kubectl get svc
NAME               TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-nodeport     NodePort   10.96.123.45   <none>        80:30080/TCP   5m

# But curl <node-ip>:30080 fails
```

#### Troubleshooting
```bash
# Check node IPs
kubectl get nodes -o wide

# Check if NodePort is in valid range (30000-32767)
kubectl describe service nginx-nodeport

# Check firewall rules
# For cloud providers, ensure security groups allow the port

# Test from within cluster first
kubectl run test-pod --image=busybox --rm -it -- wget -qO- nginx-nodeport:80

# Check if pods are ready
kubectl get pods -l app=nginx
kubectl describe pods -l app=nginx
```

### 4. DNS Resolution Issues

#### Symptoms
```bash
# Service exists but DNS doesn't resolve
kubectl exec test-pod -- nslookup nginx-service
# nslookup: can't resolve 'nginx-service'
```

#### Solutions
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check service exists
kubectl get service nginx-service

# Test with FQDN
kubectl exec test-pod -- nslookup nginx-service.default.svc.cluster.local

# Check DNS configuration in pod
kubectl exec test-pod -- cat /etc/resolv.conf

# Test DNS from different namespace
kubectl run test-pod -n kube-system --image=busybox --rm -it -- nslookup nginx-service.default.svc.cluster.local
```

### 5. ExternalName Service Issues

#### Symptoms
```bash
# ExternalName service not resolving external domain
kubectl get svc external-db
NAME          TYPE           CLUSTER-IP   EXTERNAL-IP           PORT(S)    AGE
external-db   ExternalName   <none>       database.example.com  5432/TCP   5m
```

#### Troubleshooting
```bash
# Test external domain resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup database.example.com

# Test service resolution
kubectl exec test-pod -- nslookup external-db

# Check if external domain is accessible
kubectl exec test-pod -- telnet database.example.com 5432

# Verify service configuration
kubectl get service external-db -o yaml
```

## Debugging Commands

### Service Information
```bash
# Get service details
kubectl get services
kubectl get svc -o wide
kubectl describe service <service-name>

# Get service YAML
kubectl get service <service-name> -o yaml

# Check service endpoints
kubectl get endpoints
kubectl get endpoints <service-name>
kubectl describe endpoints <service-name>
```

### Connectivity Testing
```bash
# Test service from within cluster
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod:
wget -qO- <service-name>:<port>
nslookup <service-name>
telnet <service-name> <port>

# Test specific endpoint
kubectl exec test-pod -- curl <service-cluster-ip>:<port>

# Test NodePort from node
ssh <node-ip>
curl localhost:<nodeport>
```

### Network Analysis
```bash
# Check pod network connectivity
kubectl get pods -o wide
kubectl exec <pod-name> -- ip addr show
kubectl exec <pod-name> -- netstat -tuln

# Check service network policies
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>

# Check kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

## Common Error Messages

### "No endpoints available for service"
```bash
# Check if pods are running and ready
kubectl get pods -l <service-selector>
kubectl describe pods -l <service-selector>

# Check readiness probes
kubectl get pods -l <service-selector> -o yaml | grep -A 10 readinessProbe

# Fix: Ensure pods are ready and labels match
kubectl label pod <pod-name> <key>=<value>
```

### "Connection refused"
```bash
# Check if application is listening on correct port
kubectl exec <pod-name> -- netstat -tuln
kubectl exec <pod-name> -- ss -tuln

# Check targetPort in service
kubectl get service <service-name> -o yaml | grep targetPort

# Test pod directly
kubectl exec <pod-name> -- curl localhost:<target-port>
```

### "Service has no endpoints"
```bash
# Check service selector
kubectl get service <service-name> -o jsonpath='{.spec.selector}'

# Check pod labels
kubectl get pods --show-labels

# Verify selector matches pod labels
kubectl get pods -l <selector-from-service>
```

## Service Types Troubleshooting

### ClusterIP Issues
```bash
# Test from within cluster
kubectl run debug --image=busybox --rm -it -- sh
wget -qO- <service-name>.<namespace>.svc.cluster.local

# Check cluster IP range
kubectl cluster-info dump | grep service-cluster-ip-range
```

### NodePort Issues
```bash
# Check NodePort range
kubectl describe service <service-name> | grep NodePort

# Check node firewall
# AWS: Security Groups
# GCP: Firewall Rules
# On-premise: iptables/firewalld

# Test from node
kubectl get nodes -o wide
ssh <node-ip>
curl localhost:<nodeport>
```

### LoadBalancer Issues
```bash
# Check cloud provider integration
kubectl get nodes -o yaml | grep providerID

# Check load balancer controller
kubectl get pods -n kube-system | grep -E "(aws-load-balancer|cloud-controller)"

# Check service annotations
kubectl get service <service-name> -o yaml | grep -A 20 annotations
```

### Headless Service Issues
```bash
# Check clusterIP is None
kubectl get service <service-name> -o jsonpath='{.spec.clusterIP}'

# Test DNS returns pod IPs
kubectl run test --image=busybox --rm -it -- nslookup <service-name>

# Should return multiple A records (pod IPs)
```

## Best Practices for Troubleshooting

### 1. Start with Service and Endpoints
```bash
kubectl get service,endpoints <service-name>
kubectl describe service <service-name>
```

### 2. Verify Pod Labels and Selectors
```bash
kubectl get service <service-name> -o jsonpath='{.spec.selector}'
kubectl get pods --show-labels -l <selector>
```

### 3. Test Connectivity Step by Step
```bash
# 1. Test pod directly
kubectl exec <pod-name> -- curl localhost:<port>

# 2. Test service from same namespace
kubectl exec test-pod -- curl <service-name>:<port>

# 3. Test service from different namespace
kubectl exec test-pod -n other-ns -- curl <service-name>.<namespace>.svc.cluster.local:<port>

# 4. Test external access (NodePort/LoadBalancer)
curl <external-ip>:<port>
```

### 4. Check Network Policies
```bash
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>
```

### 5. Monitor Service Events
```bash
kubectl get events --field-selector involvedObject.kind=Service
kubectl get events --field-selector involvedObject.name=<service-name>
```

### 6. Use Service Mesh Debugging (if applicable)
```bash
# Istio
kubectl get virtualservices,destinationrules
istioctl proxy-config cluster <pod-name>

# Linkerd
linkerd check
linkerd stat deploy
```
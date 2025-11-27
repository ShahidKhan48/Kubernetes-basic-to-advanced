# Network Troubleshooting Guide

## Common Network Issues

### 1. Service Discovery Problems

**Symptoms:**
- Cannot reach service by name
- DNS resolution failures
- Connection timeouts

**Diagnosis:**
```bash
# Test DNS resolution
kubectl run debug --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local

# Check service endpoints
kubectl get endpoints <service-name>
kubectl describe service <service-name>

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

**Solutions:**
```bash
# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Check service selector
kubectl get pods --show-labels
kubectl describe service <service-name>
```

### 2. Pod-to-Pod Communication Issues

**Diagnosis:**
```bash
# Create network debug pod
kubectl run netshoot --image=nicolaka/netshoot --rm -it --restart=Never

# Test connectivity between pods
kubectl exec -it <pod1> -- ping <pod2-ip>
kubectl exec -it <pod1> -- telnet <pod2-ip> <port>
```

**Network Policy Issues:**
```bash
# Check network policies
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name>

# Test with policy disabled
kubectl delete networkpolicy <policy-name>
```

### 3. Ingress Issues

**Diagnosis:**
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check ingress configuration
kubectl describe ingress <ingress-name>
kubectl get ingress -o yaml
```

**Common Issues:**
- SSL/TLS certificate problems
- Backend service not found
- Path routing issues

**Solutions:**
```bash
# Check TLS secrets
kubectl get secrets
kubectl describe secret <tls-secret>

# Test backend service
kubectl port-forward service/<service-name> 8080:80
```

### 4. Load Balancer Issues

**AWS Load Balancer:**
```bash
# Check service annotations
kubectl describe service <service-name>

# Check AWS Load Balancer Controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

**Solutions:**
```bash
# Recreate service
kubectl delete service <service-name>
kubectl apply -f service.yaml

# Check security groups and subnets
aws ec2 describe-security-groups
aws ec2 describe-subnets
```

## CNI Troubleshooting

### Calico Issues
```bash
# Check Calico pods
kubectl get pods -n kube-system -l k8s-app=calico-node

# Check Calico configuration
kubectl get ippools -o yaml
kubectl get bgpconfigurations -o yaml

# Calico node status
kubectl exec -n kube-system <calico-node-pod> -- calicoctl node status
```

### Flannel Issues
```bash
# Check Flannel pods
kubectl get pods -n kube-system -l app=flannel

# Check Flannel configuration
kubectl get configmap kube-flannel-cfg -n kube-system -o yaml
```

### Cilium Issues
```bash
# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# Cilium connectivity test
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/master/examples/kubernetes/connectivity-check/connectivity-check.yaml

# Cilium status
kubectl exec -n kube-system <cilium-pod> -- cilium status
```

## Network Debugging Tools

### Network Debug Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: network-debug
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["/bin/bash"]
    args: ["-c", "sleep 3600"]
    securityContext:
      capabilities:
        add: ["NET_ADMIN", "NET_RAW"]
  hostNetwork: true
  restartPolicy: Never
```

### Useful Network Commands
```bash
# DNS troubleshooting
dig @10.96.0.10 kubernetes.default.svc.cluster.local
nslookup kubernetes.default.svc.cluster.local 10.96.0.10

# Network connectivity
ping <target-ip>
telnet <target-ip> <port>
nc -zv <target-ip> <port>

# Network interface info
ip addr show
ip route show
netstat -tulpn

# Packet capture
tcpdump -i any -w capture.pcap
```

## Service Mesh Troubleshooting

### Istio Issues
```bash
# Check Istio components
kubectl get pods -n istio-system

# Check sidecar injection
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].name}'

# Istio proxy logs
kubectl logs <pod-name> -c istio-proxy

# Istio configuration
istioctl analyze
istioctl proxy-config cluster <pod-name>
```

### Linkerd Issues
```bash
# Check Linkerd
linkerd check

# Check proxy injection
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].name}'

# Linkerd proxy logs
kubectl logs <pod-name> -c linkerd-proxy
```

## Performance Issues

### Network Latency
```bash
# Measure latency
kubectl run ping-test --image=busybox --rm -it --restart=Never -- ping -c 10 <target-ip>

# Network performance test
kubectl run iperf-server --image=networkstatic/iperf3 --port=5201
kubectl run iperf-client --image=networkstatic/iperf3 --rm -it --restart=Never -- iperf3 -c <server-ip>
```

### Bandwidth Issues
```bash
# Check network usage
kubectl top nodes
kubectl top pods

# Monitor network interfaces
watch -n 1 'cat /proc/net/dev'
```

## Common Network Fixes

### Reset Network Components
```bash
# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Restart CNI pods
kubectl delete pods -n kube-system -l k8s-app=calico-node
kubectl delete pods -n kube-system -l app=flannel

# Restart ingress controller
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx
```

### Network Policy Debugging
```bash
# Temporarily disable all network policies
kubectl get networkpolicies -A -o name | xargs kubectl delete

# Create allow-all policy for testing
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
```

## Monitoring Network Health

### Key Metrics to Monitor
- DNS query success rate
- Service endpoint availability
- Network policy violations
- Ingress controller error rates
- Load balancer health checks

### Alerting Rules
```yaml
# DNS failures
- alert: DNSFailures
  expr: rate(coredns_dns_request_count_total{rcode!="NOERROR"}[5m]) > 0.1

# Service endpoint down
- alert: ServiceEndpointDown
  expr: up{job="kubernetes-endpoints"} == 0
```
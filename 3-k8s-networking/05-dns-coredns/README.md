# DNS & CoreDNS - Service Discovery

## 📚 Overview
CoreDNS Kubernetes mein DNS resolution provide karta hai. Service discovery, custom DNS entries aur external DNS integration handle karta hai.

## 🎯 DNS Features

### 1. **Automatic Service DNS**
Services automatically DNS names get karte hain
- `service-name.namespace.svc.cluster.local`
- `service-name.namespace.svc`
- `service-name` (same namespace)

### 2. **Pod DNS**
Pods ko bhi DNS names milte hain
- `pod-ip.namespace.pod.cluster.local`
- Headless services ke saath direct pod access

### 3. **Custom DNS**
External services ke liye custom DNS entries

## 📖 Examples

### Service DNS Resolution
```bash
# From within cluster
nslookup web-app-service
nslookup web-app-service.default.svc.cluster.local
nslookup api-service.production.svc.cluster.local
```

### CoreDNS Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
```

### Custom DNS Entries
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  spicybiryaniwala.server: |
    spicybiryaniwala.shop:53 {
        errors
        cache 30
        forward . 8.8.8.8 8.8.4.4
    }
```

## 🔧 Commands
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run test-dns --image=busybox -it --rm -- nslookup kubernetes.default

# Check CoreDNS config
kubectl get configmap coredns -n kube-system -o yaml

# CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

## 🔗 Related Topics
- [Services](../01-services/) - Service networking
- [Namespaces](../06-namespaces/) - DNS isolation

---

**Next:** [Namespaces](../06-namespaces/) - Network Isolation
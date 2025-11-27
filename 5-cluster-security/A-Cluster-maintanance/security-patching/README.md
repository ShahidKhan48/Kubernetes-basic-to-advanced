# Security Patching

## 📚 Overview
Kubernetes cluster security patching aur vulnerability management.

## 🎯 Patching Strategy

### OS Security Updates
```bash
# Check available updates
apt list --upgradable

# Update package lists
apt-get update

# Install security updates only
apt-get upgrade -s | grep -i security

# Apply security patches
unattended-upgrade --dry-run
unattended-upgrade
```

### Kubernetes Security Patches
```bash
# Check for security advisories
kubectl version --short
kubeadm version

# Check CVE database
curl -s https://kubernetes.io/docs/reference/issues-security/

# Upgrade to patched version
kubeadm upgrade plan
kubeadm upgrade apply v1.28.2
```

### Container Image Updates
```bash
# Scan images for vulnerabilities
trivy image nginx:1.20

# Update deployment images
kubectl set image deployment/web-app container=nginx:1.21-secure

# Check rollout status
kubectl rollout status deployment/web-app
```

### Automated Patching
```yaml
# CronJob for security updates
apiVersion: batch/v1
kind: CronJob
metadata:
  name: security-patcher
spec:
  schedule: "0 2 * * 1"  # Every Monday at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: patcher
            image: ubuntu:20.04
            command:
            - /bin/bash
            - -c
            - |
              apt-get update
              apt-get upgrade -y
              apt-get autoremove -y
          restartPolicy: OnFailure
```

## 🛡️ Security Scanning

### Cluster Security Scan
```bash
# Use kube-bench for CIS benchmarks
kube-bench run --targets master,node,etcd,policies

# Use kube-hunter for penetration testing
kube-hunter --remote <cluster-ip>

# Use Falco for runtime security
kubectl apply -f https://raw.githubusercontent.com/falcosecurity/falco/master/deploy/kubernetes/falco-daemonset-configmap.yaml
```

### Vulnerability Assessment
```bash
# Scan node OS
lynis audit system

# Scan container images
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image nginx:latest

# Check for outdated packages
apt list --installed | grep -v automatic
```

## 📋 Best Practices
- Regular security scanning
- Automated patch management
- Test patches in staging
- Maintain patch documentation
- Monitor security advisories
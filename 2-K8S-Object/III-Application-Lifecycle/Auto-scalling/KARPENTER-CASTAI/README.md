# Karpenter & CAST AI

## 📚 Overview
Advanced cluster autoscaling solutions for cost optimization aur intelligent node management.

## 🎯 Karpenter Features
- **Just-in-time Provisioning**: Rapid node provisioning
- **Cost Optimization**: Right-sized instances
- **Multi-architecture**: ARM and x86 support
- **Spot Instance Support**: Cost-effective scaling

## 📖 Karpenter Setup

### Karpenter NodePool
```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      labels:
        karpenter.sh/nodepool: default
    spec:
      requirements:
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ["m5.large", "m5.xlarge", "c5.large", "c5.xlarge"]
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default
      taints:
      - key: spicybiryaniwala.shop/workload
        value: "batch"
        effect: NoSchedule
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
```

### EC2NodeClass
```yaml
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: "spicybiryaniwala-cluster"
  securityGroupSelectorTerms:
  - tags:
      karpenter.sh/discovery: "spicybiryaniwala-cluster"
  instanceStorePolicy: RAID0
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh spicybiryaniwala-cluster
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
```

## 🎯 CAST AI Features
- **AI-driven Optimization**: Machine learning-based scaling
- **Multi-cloud Support**: AWS, GCP, Azure
- **Cost Monitoring**: Real-time cost tracking
- **Security Scanning**: Automated security checks

## 📖 CAST AI Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: castai-config
data:
  config.yaml: |
    cluster:
      name: spicybiryaniwala-cluster
      region: us-west-2
    
    autoscaling:
      enabled: true
      min_nodes: 2
      max_nodes: 100
      
    optimization:
      spot_instances: true
      cost_optimization: true
      performance_optimization: true
    
    policies:
      scale_down_delay: 10m
      scale_up_threshold: 80
      scale_down_threshold: 30
```

## 🔧 Commands
```bash
# Install Karpenter
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version ${KARPENTER_VERSION}

# Check Karpenter status
kubectl get nodepool
kubectl get ec2nodeclass

# CAST AI CLI
castai cluster connect --cluster-id=<cluster-id>
castai nodes list
```

## 📋 Best Practices
- Monitor cost optimization metrics
- Use appropriate instance types
- Configure proper resource requests
- Regular policy reviews
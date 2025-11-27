# Kubernetes Architecture Deep Dive

## 🎯 Learning Objectives
- Understand Kubernetes cluster architecture
- Learn about control plane components
- Explore worker node components
- Master component interactions and data flow
- Practice architecture troubleshooting

---

## 🏗️ Kubernetes Cluster Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                      │
│                                                             │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │   Master Node   │              │  Worker Node 1  │      │
│  │  (Control Plane)│              │                 │      │
│  │                 │              │                 │      │
│  │  ┌───────────┐  │              │  ┌───────────┐  │      │
│  │  │API Server │  │◄────────────►│  │  kubelet  │  │      │
│  │  └───────────┘  │              │  └───────────┘  │      │
│  │  ┌───────────┐  │              │  ┌───────────┐  │      │
│  │  │   etcd    │  │              │  │kube-proxy │  │      │
│  │  └───────────┘  │              │  └───────────┘  │      │
│  │  ┌───────────┐  │              │  ┌───────────┐  │      │
│  │  │Controller │  │              │  │Container  │  │      │
│  │  │ Manager   │  │              │  │ Runtime   │  │      │
│  │  └───────────┘  │              │  └───────────┘  │      │
│  │  ┌───────────┐  │              │                 │      │
│  │  │Scheduler  │  │              │     Pods        │      │
│  │  └───────────┘  │              │  ┌─────┐┌─────┐ │      │
│  └─────────────────┘              │  │Pod 1││Pod 2│ │      │
│                                   │  └─────┘└─────┘ │      │
│                                   └─────────────────┘      │
│                                                             │
│                    ┌─────────────────┐                     │
│                    │  Worker Node 2  │                     │
│                    │                 │                     │
│                    │  ┌───────────┐  │                     │
│                    │  │  kubelet  │  │                     │
│                    │  └───────────┘  │                     │
│                    │  ┌───────────┐  │                     │
│                    │  │kube-proxy │  │                     │
│                    │  └───────────┘  │                     │
│                    │  ┌───────────┐  │                     │
│                    │  │Container  │  │                     │
│                    │  │ Runtime   │  │                     │
│                    │  └───────────┘  │                     │
│                    │                 │                     │
│                    │     Pods        │                     │
│                    │  ┌─────┐┌─────┐ │                     │
│                    │  │Pod 3││Pod 4│ │                     │
│                    │  └─────┘└─────┘ │                     │
│                    └─────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎛️ Control Plane Components (Master Node)

### **1. API Server (kube-apiserver)**

#### **Purpose:**
- Central management entity and communication hub
- Exposes Kubernetes API (RESTful interface)
- All cluster communication goes through API server

#### **Key Functions:**
- **Authentication & Authorization**
- **Admission Control**
- **API Validation**
- **Resource Management**

#### **API Server Workflow:**
```
Client Request → Authentication → Authorization → Admission Controllers → Validation → etcd
```

#### **Example API Calls:**
```bash
# Get cluster information
kubectl get nodes
# Translates to: GET /api/v1/nodes

# Create a pod
kubectl create -f pod.yaml
# Translates to: POST /api/v1/namespaces/default/pods

# Watch for changes
kubectl get pods -w
# Translates to: GET /api/v1/namespaces/default/pods?watch=true
```

#### **Configuration:**
```yaml
# API Server common flags
--etcd-servers=https://127.0.0.1:2379
--service-cluster-ip-range=10.96.0.0/12
--service-node-port-range=30000-32767
--enable-admission-plugins=NodeRestriction,ResourceQuota
--audit-log-path=/var/log/audit.log
```

---

### **2. etcd - Cluster Data Store**

#### **Purpose:**
- Distributed key-value store
- Single source of truth for cluster state
- Stores all cluster data and configuration

#### **What's Stored in etcd:**
- Cluster configuration
- Resource definitions (pods, services, etc.)
- Secrets and ConfigMaps
- Network policies
- RBAC policies

#### **etcd Architecture:**
```
┌─────────────────────────────────────┐
│              etcd Cluster           │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │ etcd-1  │ │ etcd-2  │ │ etcd-3  ││
│  │(Leader) │ │(Follower│ │(Follower││
│  └─────────┘ └─────────┘ └─────────┘│
└─────────────────────────────────────┘
```

#### **Key Features:**
- **Consistency:** Strong consistency using Raft consensus
- **Reliability:** Fault-tolerant with odd number of nodes
- **Performance:** Optimized for read-heavy workloads
- **Security:** TLS encryption and RBAC

#### **etcd Operations:**
```bash
# Direct etcd interaction (not recommended in production)
ETCDCTL_API=3 etcdctl get /registry/pods/default/nginx

# Backup etcd
ETCDCTL_API=3 etcdctl snapshot save backup.db

# Restore etcd
ETCDCTL_API=3 etcdctl snapshot restore backup.db
```

---

### **3. Controller Manager (kube-controller-manager)**

#### **Purpose:**
- Runs controller processes that regulate cluster state
- Watches API server for changes and takes corrective actions
- Implements the control loop pattern

#### **Built-in Controllers:**

##### **Node Controller:**
- Monitors node health
- Handles node failures
- Manages node lifecycle

```yaml
# Node Controller behavior
nodeMonitorPeriod: 5s
nodeMonitorGracePeriod: 40s
podEvictionTimeout: 5m
```

##### **Replication Controller:**
- Ensures desired number of pod replicas
- Creates/deletes pods as needed
- Handles pod failures

##### **Endpoints Controller:**
- Populates Endpoints objects
- Links Services to Pods
- Updates endpoints when pods change

##### **Service Account & Token Controllers:**
- Creates default service accounts
- Manages API access tokens
- Handles token rotation

#### **Controller Pattern:**
```go
// Simplified controller loop
for {
    desired := getDesiredState()
    current := getCurrentState()
    if desired != current {
        reconcile(desired, current)
    }
    sleep(reconciliationPeriod)
}
```

---

### **4. Scheduler (kube-scheduler)**

#### **Purpose:**
- Assigns pods to nodes
- Makes scheduling decisions based on resource requirements
- Considers constraints and policies

#### **Scheduling Process:**
```
1. Filtering Phase (Predicates)
   ├── Node has sufficient resources
   ├── Node matches node selector
   ├── Pod tolerates node taints
   └── Volume requirements met

2. Scoring Phase (Priorities)
   ├── Resource utilization
   ├── Affinity/Anti-affinity
   ├── Image locality
   └── Custom priorities

3. Binding Phase
   └── Assign pod to highest-scored node
```

#### **Scheduling Factors:**
```yaml
# Resource requirements
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"

# Node selection
nodeSelector:
  disktype: ssd

# Affinity rules
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64
```

---

## 👷 Worker Node Components

### **1. kubelet - Node Agent**

#### **Purpose:**
- Primary node agent running on each worker node
- Communicates with API server
- Manages pod lifecycle on the node

#### **Key Responsibilities:**
- **Pod Management:** Creates, starts, stops pods
- **Health Monitoring:** Runs liveness and readiness probes
- **Resource Reporting:** Reports node and pod status
- **Volume Management:** Mounts and unmounts volumes

#### **kubelet Workflow:**
```
API Server → kubelet → Container Runtime → Pod Creation
     ↑                                           ↓
     └─────── Status Updates ←──────────────────┘
```

#### **Configuration:**
```yaml
# kubelet config
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
address: 0.0.0.0
port: 10250
readOnlyPort: 10255
cgroupDriver: systemd
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
```

---

### **2. kube-proxy - Network Proxy**

#### **Purpose:**
- Network proxy running on each node
- Implements Kubernetes Service concept
- Manages network rules for service communication

#### **Proxy Modes:**

##### **iptables Mode (Default):**
```bash
# Example iptables rules created by kube-proxy
-A KUBE-SERVICES -d 10.96.0.1/32 -p tcp -m tcp --dport 443 -j KUBE-SVC-NPX46M4PTMTKRN6Y
-A KUBE-SVC-NPX46M4PTMTKRN6Y -m statistic --mode random --probability 0.33333333349 -j KUBE-SEP-YBKBG2XDNXNBQHPZ
```

##### **IPVS Mode (Advanced):**
```bash
# IPVS provides better performance for large clusters
ipvsadm -ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.96.0.1:443 rr
  -> 192.168.1.10:6443            Masq    1      0          0
```

#### **Service Types Handled:**
- **ClusterIP:** Internal cluster communication
- **NodePort:** External access via node ports
- **LoadBalancer:** Cloud provider load balancers
- **ExternalName:** DNS-based service discovery

---

### **3. Container Runtime**

#### **Purpose:**
- Manages container lifecycle
- Pulls container images
- Runs and stops containers

#### **Supported Runtimes:**

##### **containerd (Recommended):**
```bash
# containerd configuration
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "k8s.gcr.io/pause:3.5"
  
[plugins."io.containerd.grpc.v1.cri".containerd]
  default_runtime_name = "runc"
```

##### **CRI-O:**
```bash
# CRI-O configuration
[crio.runtime]
default_runtime = "runc"
runtime_path = "/usr/bin/runc"
```

##### **Docker (Deprecated):**
```bash
# Docker with dockershim (removed in K8s 1.24+)
# Use containerd or CRI-O instead
```

#### **Container Runtime Interface (CRI):**
```
kubelet ←→ CRI ←→ Container Runtime ←→ Containers
```

---

## 🔄 Component Interactions & Data Flow

### **Pod Creation Flow:**
```
1. kubectl create pod → API Server
2. API Server → etcd (store pod spec)
3. Scheduler watches API Server → selects node
4. API Server updates pod with node assignment
5. kubelet on selected node watches API Server
6. kubelet → Container Runtime → creates containers
7. kubelet reports status → API Server → etcd
```

### **Service Discovery Flow:**
```
1. Service created → API Server → etcd
2. Endpoints Controller watches → creates Endpoints
3. kube-proxy watches Services/Endpoints
4. kube-proxy updates iptables/IPVS rules
5. Pod-to-Service communication uses proxy rules
```

### **Health Check Flow:**
```
1. kubelet runs liveness/readiness probes
2. Probe results → kubelet → API Server
3. Failed liveness → kubelet restarts container
4. Failed readiness → Endpoints Controller removes from service
```

---

## 🛠️ Hands-on Labs

### **Lab 1: Explore Cluster Components**
```bash
# Check cluster components
kubectl get componentstatuses
kubectl get nodes -o wide

# Examine control plane pods
kubectl get pods -n kube-system
kubectl describe pod kube-apiserver-master -n kube-system

# Check component logs
kubectl logs kube-scheduler-master -n kube-system
kubectl logs kube-controller-manager-master -n kube-system
```

### **Lab 2: API Server Interaction**
```bash
# Direct API calls (requires authentication)
kubectl proxy --port=8080 &
curl http://localhost:8080/api/v1/nodes
curl http://localhost:8080/api/v1/namespaces/default/pods

# Watch API events
kubectl get events --watch
kubectl get pods --watch
```

### **Lab 3: etcd Exploration**
```bash
# Access etcd (in a real cluster, requires certificates)
kubectl exec -it etcd-master -n kube-system -- sh

# Inside etcd container
ETCDCTL_API=3 etcdctl get /registry/pods/default --prefix --keys-only
ETCDCTL_API=3 etcdctl get /registry/services/default --prefix --keys-only
```

### **Lab 4: Scheduler Behavior**
```bash
# Create pod with specific requirements
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: scheduler-test
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
EOF

# Watch scheduling events
kubectl describe pod scheduler-test
kubectl get events --field-selector involvedObject.name=scheduler-test
```

---

## 🔍 Troubleshooting Architecture Issues

### **Common Problems & Solutions:**

#### **API Server Issues:**
```bash
# Check API server status
kubectl get componentstatuses
systemctl status kubelet

# API server logs
journalctl -u kube-apiserver -f
kubectl logs kube-apiserver-master -n kube-system
```

#### **etcd Problems:**
```bash
# Check etcd health
kubectl get cs
ETCDCTL_API=3 etcdctl endpoint health

# etcd cluster status
ETCDCTL_API=3 etcdctl endpoint status --cluster -w table
```

#### **Scheduler Issues:**
```bash
# Pods stuck in Pending state
kubectl get pods
kubectl describe pod <pending-pod>

# Check scheduler logs
kubectl logs kube-scheduler-master -n kube-system
```

#### **kubelet Problems:**
```bash
# Node NotReady status
kubectl get nodes
kubectl describe node <node-name>

# kubelet logs
journalctl -u kubelet -f
systemctl status kubelet
```

---

## 📊 Architecture Best Practices

### **High Availability Setup:**
```yaml
# Multi-master configuration
Master Node 1: API Server, etcd, Controller Manager, Scheduler
Master Node 2: API Server, etcd, Controller Manager, Scheduler  
Master Node 3: API Server, etcd, Controller Manager, Scheduler
Load Balancer: Distributes API requests across masters
```

### **Security Considerations:**
- Enable TLS for all components
- Use RBAC for API access
- Secure etcd with encryption at rest
- Network policies for component isolation
- Regular security updates

### **Performance Optimization:**
- Separate etcd from API server for large clusters
- Use SSD storage for etcd
- Monitor resource usage of control plane
- Implement proper resource requests/limits

---

## 🎯 Assessment Questions

1. Explain the role of each control plane component
2. How does the scheduler make pod placement decisions?
3. What happens when etcd becomes unavailable?
4. Describe the pod creation workflow from kubectl to running container
5. How does kube-proxy implement service load balancing?

---

## 🔗 Additional Resources

### **Documentation:**
- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
- [etcd Documentation](https://etcd.io/docs/)
- [Container Runtime Interface](https://kubernetes.io/docs/concepts/architecture/cri/)

### **Tools:**
- [etcdctl](https://github.com/etcd-io/etcd/tree/main/etcdctl)
- [crictl](https://github.com/kubernetes-sigs/cri-tools)
- [kubectl debug](https://kubernetes.io/docs/tasks/debug-application-cluster/)

---

**Next:** [Cluster Setup Options](../minikube/README.md)
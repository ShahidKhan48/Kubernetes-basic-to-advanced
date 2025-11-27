#!/bin/bash

# Kubernetes Troubleshooting Scripts Collection

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Cluster Health Check
cluster_health_check() {
    print_header "Cluster Health Check"
    
    print_status "Checking cluster info..."
    kubectl cluster-info
    
    print_status "Checking node status..."
    kubectl get nodes -o wide
    
    print_status "Checking system pods..."
    kubectl get pods -n kube-system | grep -v Running | head -10
    
    print_status "Checking component status..."
    kubectl get componentstatuses 2>/dev/null || print_warning "Component status API not available"
    
    print_status "Checking recent events..."
    kubectl get events --sort-by=.metadata.creationTimestamp | tail -10
    
    print_status "Checking resource usage..."
    kubectl top nodes 2>/dev/null || print_warning "Metrics server not available"
}

# Pod Troubleshooting
pod_troubleshoot() {
    local pod_name=$1
    local namespace=${2:-default}
    
    if [ -z "$pod_name" ]; then
        print_error "Pod name is required"
        echo "Usage: pod_troubleshoot <pod-name> [namespace]"
        return 1
    fi
    
    print_header "Pod Troubleshooting: $pod_name"
    
    print_status "Pod status..."
    kubectl get pod $pod_name -n $namespace -o wide
    
    print_status "Pod description..."
    kubectl describe pod $pod_name -n $namespace
    
    print_status "Pod logs..."
    kubectl logs $pod_name -n $namespace --tail=50
    
    print_status "Previous logs (if available)..."
    kubectl logs $pod_name -n $namespace --previous --tail=20 2>/dev/null || print_warning "No previous logs available"
    
    print_status "Pod events..."
    kubectl get events --field-selector involvedObject.name=$pod_name -n $namespace
}

# Network Troubleshooting
network_troubleshoot() {
    print_header "Network Troubleshooting"
    
    print_status "Creating network debug pod..."
    kubectl run netdebug --image=nicolaka/netshoot --rm -it --restart=Never -- /bin/bash -c "
        echo 'Testing DNS resolution...'
        nslookup kubernetes.default.svc.cluster.local
        echo ''
        echo 'Testing external connectivity...'
        ping -c 3 8.8.8.8
        echo ''
        echo 'Network interfaces:'
        ip addr show
        echo ''
        echo 'Routing table:'
        ip route show
    "
}

# Storage Troubleshooting
storage_troubleshoot() {
    print_header "Storage Troubleshooting"
    
    print_status "Checking PVs..."
    kubectl get pv
    
    print_status "Checking PVCs..."
    kubectl get pvc --all-namespaces
    
    print_status "Checking storage classes..."
    kubectl get storageclass
    
    print_status "Checking volume attachments..."
    kubectl get volumeattachments
    
    print_status "Recent storage events..."
    kubectl get events --all-namespaces | grep -i -E "(volume|pv|pvc|storage)" | tail -10
}

# Service Troubleshooting
service_troubleshoot() {
    local service_name=$1
    local namespace=${2:-default}
    
    if [ -z "$service_name" ]; then
        print_error "Service name is required"
        echo "Usage: service_troubleshoot <service-name> [namespace]"
        return 1
    fi
    
    print_header "Service Troubleshooting: $service_name"
    
    print_status "Service details..."
    kubectl get service $service_name -n $namespace -o wide
    
    print_status "Service description..."
    kubectl describe service $service_name -n $namespace
    
    print_status "Service endpoints..."
    kubectl get endpoints $service_name -n $namespace
    
    print_status "Testing service connectivity..."
    kubectl run service-test --image=busybox --rm -it --restart=Never -- /bin/sh -c "
        echo 'Testing service DNS resolution...'
        nslookup $service_name.$namespace.svc.cluster.local
        echo ''
        echo 'Testing service connectivity...'
        wget -qO- --timeout=5 http://$service_name.$namespace.svc.cluster.local/ || echo 'Connection failed'
    "
}

# Resource Usage Check
resource_usage_check() {
    print_header "Resource Usage Check"
    
    print_status "Node resource usage..."
    kubectl top nodes 2>/dev/null || print_warning "Metrics server not available"
    
    print_status "Pod resource usage (top 10)..."
    kubectl top pods --all-namespaces --sort-by=cpu | head -11
    
    print_status "Pods with high restart count..."
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.containerStatuses[]?.restartCount > 5) | "\(.metadata.namespace)/\(.metadata.name): \(.status.containerStatuses[0].restartCount) restarts"' | head -10
    
    print_status "Node resource allocation..."
    kubectl describe nodes | grep -A 5 "Allocated resources"
}

# Security Check
security_check() {
    print_header "Security Check"
    
    print_status "Checking pod security policies..."
    kubectl get psp 2>/dev/null || print_warning "Pod Security Policies not available"
    
    print_status "Checking network policies..."
    kubectl get networkpolicies --all-namespaces
    
    print_status "Checking RBAC..."
    kubectl get clusterroles | wc -l
    kubectl get clusterrolebindings | wc -l
    
    print_status "Checking service accounts with cluster-admin..."
    kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .subjects[]? | "\(.kind)/\(.name)"'
    
    print_status "Checking privileged pods..."
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[]?.securityContext?.privileged==true) | "\(.metadata.namespace)/\(.metadata.name)"'
}

# Monitoring Check
monitoring_check() {
    print_header "Monitoring Stack Check"
    
    print_status "Checking Prometheus..."
    kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus 2>/dev/null || print_warning "Prometheus not found"
    
    print_status "Checking Grafana..."
    kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana 2>/dev/null || print_warning "Grafana not found"
    
    print_status "Checking Alertmanager..."
    kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager 2>/dev/null || print_warning "Alertmanager not found"
    
    print_status "Checking ServiceMonitors..."
    kubectl get servicemonitors --all-namespaces 2>/dev/null | wc -l || print_warning "ServiceMonitors not available"
}

# Performance Test
performance_test() {
    print_header "Performance Test"
    
    print_status "Running CPU stress test..."
    kubectl run cpu-stress --image=progrium/stress --rm -it --restart=Never -- stress --cpu 2 --timeout 30s
    
    print_status "Running memory stress test..."
    kubectl run memory-stress --image=progrium/stress --rm -it --restart=Never -- stress --vm 1 --vm-bytes 512M --timeout 30s
    
    print_status "Running disk I/O test..."
    kubectl run disk-test --image=busybox --rm -it --restart=Never -- /bin/sh -c "
        dd if=/dev/zero of=/tmp/test bs=1M count=100 oflag=direct
        rm /tmp/test
    "
}

# Cleanup Stuck Resources
cleanup_stuck_resources() {
    print_header "Cleanup Stuck Resources"
    
    print_status "Finding stuck pods..."
    kubectl get pods --all-namespaces --field-selector=status.phase=Failed
    
    print_status "Finding stuck PVCs..."
    kubectl get pvc --all-namespaces | grep -E "(Pending|Lost)"
    
    print_warning "To force delete stuck resources, run:"
    echo "kubectl delete pod <pod-name> --force --grace-period=0"
    echo "kubectl patch pvc <pvc-name> -p '{\"metadata\":{\"finalizers\":null}}'"
}

# Generate Cluster Report
generate_cluster_report() {
    local report_file="cluster-report-$(date +%Y%m%d-%H%M%S).txt"
    
    print_header "Generating Cluster Report"
    
    {
        echo "Kubernetes Cluster Report - $(date)"
        echo "========================================"
        echo ""
        
        echo "CLUSTER INFO:"
        kubectl cluster-info
        echo ""
        
        echo "NODES:"
        kubectl get nodes -o wide
        echo ""
        
        echo "NAMESPACES:"
        kubectl get namespaces
        echo ""
        
        echo "PODS (Non-Running):"
        kubectl get pods --all-namespaces | grep -v Running
        echo ""
        
        echo "SERVICES:"
        kubectl get services --all-namespaces
        echo ""
        
        echo "INGRESSES:"
        kubectl get ingress --all-namespaces
        echo ""
        
        echo "PERSISTENT VOLUMES:"
        kubectl get pv
        echo ""
        
        echo "STORAGE CLASSES:"
        kubectl get storageclass
        echo ""
        
        echo "RECENT EVENTS:"
        kubectl get events --sort-by=.metadata.creationTimestamp | tail -20
        echo ""
        
        echo "RESOURCE USAGE:"
        kubectl top nodes 2>/dev/null || echo "Metrics server not available"
        echo ""
        
    } > $report_file
    
    print_status "Cluster report generated: $report_file"
}

# Main menu
show_menu() {
    echo ""
    print_header "Kubernetes Troubleshooting Menu"
    echo "1. Cluster Health Check"
    echo "2. Pod Troubleshooting"
    echo "3. Network Troubleshooting"
    echo "4. Storage Troubleshooting"
    echo "5. Service Troubleshooting"
    echo "6. Resource Usage Check"
    echo "7. Security Check"
    echo "8. Monitoring Check"
    echo "9. Performance Test"
    echo "10. Cleanup Stuck Resources"
    echo "11. Generate Cluster Report"
    echo "0. Exit"
    echo ""
}

# Main script logic
if [ $# -eq 0 ]; then
    while true; do
        show_menu
        read -p "Select an option (0-11): " choice
        
        case $choice in
            1) cluster_health_check ;;
            2) 
                read -p "Enter pod name: " pod_name
                read -p "Enter namespace (default: default): " namespace
                namespace=${namespace:-default}
                pod_troubleshoot $pod_name $namespace
                ;;
            3) network_troubleshoot ;;
            4) storage_troubleshoot ;;
            5)
                read -p "Enter service name: " service_name
                read -p "Enter namespace (default: default): " namespace
                namespace=${namespace:-default}
                service_troubleshoot $service_name $namespace
                ;;
            6) resource_usage_check ;;
            7) security_check ;;
            8) monitoring_check ;;
            9) performance_test ;;
            10) cleanup_stuck_resources ;;
            11) generate_cluster_report ;;
            0) print_status "Exiting..."; exit 0 ;;
            *) print_error "Invalid option. Please try again." ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
else
    # Command line usage
    case $1 in
        "health") cluster_health_check ;;
        "pod") pod_troubleshoot $2 $3 ;;
        "network") network_troubleshoot ;;
        "storage") storage_troubleshoot ;;
        "service") service_troubleshoot $2 $3 ;;
        "resources") resource_usage_check ;;
        "security") security_check ;;
        "monitoring") monitoring_check ;;
        "performance") performance_test ;;
        "cleanup") cleanup_stuck_resources ;;
        "report") generate_cluster_report ;;
        *)
            echo "Usage: $0 [command] [args...]"
            echo "Commands:"
            echo "  health                    - Run cluster health check"
            echo "  pod <name> [namespace]    - Troubleshoot specific pod"
            echo "  network                   - Run network troubleshooting"
            echo "  storage                   - Check storage issues"
            echo "  service <name> [namespace] - Troubleshoot specific service"
            echo "  resources                 - Check resource usage"
            echo "  security                  - Run security checks"
            echo "  monitoring                - Check monitoring stack"
            echo "  performance               - Run performance tests"
            echo "  cleanup                   - Find stuck resources"
            echo "  report                    - Generate cluster report"
            ;;
    esac
fi
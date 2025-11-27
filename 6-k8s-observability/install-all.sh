#!/bin/bash

# Grafana Observability Stack Installation Script
# This script installs the complete monitoring stack with latest versions
# Chart Versions: Grafana 10.1.4, Mimir 6.0.3, Tempo 1.56.0, Loki 6.46.0, k8s-monitoring 3.5.6

set -e

echo "🚀 Installing Grafana Observability Stack (Latest Versions)..."
echo "============================================================="
echo "📦 Chart Versions:"
echo "   • Grafana: 10.1.4 (App: 12.2.1)"
echo "   • Mimir: 6.0.3 (App: 3.0.0)"
echo "   • Tempo: 1.56.0 (App: 2.9.0)"
echo "   • Loki: 6.46.0 (App: 3.5.7)"
echo "   • k8s-monitoring: 3.5.6 (App: 1.5.0)"
echo "   • Prometheus: 27.45.0 (App: v3.7.3) [Optional]"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_component() {
    echo -e "${PURPLE}[COMPONENT]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed or not in PATH"
    exit 1
fi

# Check Kubernetes connection
print_status "Checking Kubernetes connection..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi
print_success "Kubernetes cluster connection verified"

print_status "Adding Helm repositories..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
print_success "Helm repositories added and updated"

print_status "Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
print_success "Monitoring namespace created"

print_status "Installing MinIO credentials secret..."
kubectl create secret generic minio-credentials \
  --from-literal=rootUser=minioadmin \
  --from-literal=rootPassword=minioadmin123 \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
print_success "MinIO credentials secret created"

echo ""
echo "📊 Installing Grafana Stack Components (Latest Versions)..."
echo "=========================================================="

# Install Mimir first (storage backend)
print_component "Installing Mimir v6.0.3 (Metrics Storage)..."
helm upgrade --install mimir grafana/mimir-distributed \
  --version 6.0.3 \
  -f 02-mimir/mimir-values.yml \
  -n monitoring \
  --wait --timeout=15m
print_success "Mimir v6.0.3 installed successfully"

# Install Loki (log storage)
print_component "Installing Loki v6.46.0 (Log Storage)..."
helm upgrade --install loki grafana/loki \
  --version 6.46.0 \
  -f 04-loki/loki-values.yml \
  -n monitoring \
  --wait --timeout=15m
print_success "Loki v6.46.0 installed successfully"

# Install Tempo (trace storage)
print_component "Installing Tempo v1.56.0 (Trace Storage)..."
helm upgrade --install tempo grafana/tempo-distributed \
  --version 1.56.0 \
  -f 03-tempo/tempo-values.yml \
  -n monitoring \
  --wait --timeout=15m
print_success "Tempo v1.56.0 installed successfully"

# Install k8s-monitoring (Alloy)
print_component "Installing k8s-monitoring v3.5.6 (Alloy Telemetry Collector)..."
helm upgrade --install k8s-monitoring grafana/k8s-monitoring \
  --version 3.5.6 \
  -f 05-alloy/alloy-values.yml \
  -n monitoring \
  --wait --timeout=15m
print_success "k8s-monitoring v3.5.6 (Alloy) installed successfully"

# Install Grafana (visualization)
print_component "Installing Grafana v10.1.4 (Visualization & Dashboards)..."
helm upgrade --install grafana grafana/grafana \
  --version 10.1.4 \
  -f 01-grafana/grafana-values.yml \
  -n monitoring \
  --wait --timeout=15m
print_success "Grafana v10.1.4 installed successfully"

# Optional: Install Prometheus
read -p "Do you want to install Prometheus v27.45.0 (optional backup collector)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_component "Installing Prometheus v27.45.0 (Optional Metrics Collector)..."
    helm upgrade --install prometheus prometheus-community/prometheus \
      --version 27.45.0 \
      -f 06-prometheus/prometheus-values.yml \
      -n monitoring \
      --wait --timeout=15m
    print_success "Prometheus v27.45.0 installed successfully"
else
    print_warning "Skipping Prometheus installation (recommended for production)"
fi

# Deploy Java application
print_component "Deploying Java demo application..."
kubectl apply -f 07-java-app/java-app-deployment.yml -n monitoring
print_success "Java demo application deployed"

# Wait for pods to be ready
print_status "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mimir -n monitoring --timeout=300s
print_success "All core components are ready"

echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
print_success "Grafana Observability Stack (Latest Versions) has been successfully installed!"
echo ""
echo "📋 Access Information:"
echo "----------------------"
echo "🎨 Grafana UI (v12.2.1):"
echo "   kubectl port-forward -n monitoring svc/grafana 3000:80"
echo "   → http://localhost:3000 (admin/admin)"
echo ""
echo "📊 Mimir API (v3.0.0):"
echo "   kubectl port-forward -n monitoring svc/mimir-nginx 8080:80"
echo "   → http://localhost:8080/prometheus"
echo ""
echo "📝 Loki API (v3.5.7):"
echo "   kubectl port-forward -n monitoring svc/loki-gateway 3100:80"
echo "   → http://localhost:3100"
echo ""
echo "🔍 Tempo API (v2.9.0):"
echo "   kubectl port-forward -n monitoring svc/tempo-query-frontend 3200:3200"
echo "   → http://localhost:3200"
echo ""
echo "☕ Java Demo App:"
echo "   kubectl port-forward -n monitoring svc/java-app 8080:8080"
echo "   → http://localhost:8080"
echo ""
echo "🌐 Production Access (if ingress enabled):"
echo "   → https://grafana.spicybiryaniwala.shop"
echo ""
echo "🔍 Verify Installation:"
echo "-----------------------"
echo "kubectl get pods -n monitoring"
echo "kubectl get svc -n monitoring"
echo "kubectl get pvc -n monitoring"
echo ""
echo "📊 Test Queries:"
echo "----------------"
echo "# Mimir (PromQL): curl 'http://localhost:8080/prometheus/api/v1/query?query=up'"
echo "# Loki (LogQL): curl 'http://localhost:3100/loki/api/v1/query?query={app=\"java-app\"}'"
echo "# Tempo (TraceQL): curl 'http://localhost:3200/api/search?tags=service.name=java-app'"
echo ""
print_success "Happy Monitoring with the Latest Grafana Stack! 📊📈📉🔍"
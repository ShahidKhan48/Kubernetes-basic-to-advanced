# Custom Controllers & Operator Frameworks

## 📚 Overview
Kubernetes custom controllers aur operator development frameworks.

## 🎯 Controller Pattern
- **Watch**: Monitor resource changes
- **Reconcile**: Ensure desired state
- **Event-driven**: React to cluster events
- **Error Handling**: Retry failed operations

## 📖 Controller Components

### 1. **Controller Logic**
```go
func (r *ApplicationReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    // Fetch the Application instance
    var app appsv1.Application
    if err := r.Get(ctx, req.NamespacedName, &app); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }
    
    // Reconcile deployment
    if err := r.reconcileDeployment(ctx, &app); err != nil {
        return ctrl.Result{}, err
    }
    
    // Update status
    app.Status.Phase = "Running"
    return ctrl.Result{}, r.Status().Update(ctx, &app)
}
```

### 2. **Operator Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: application-operator
  namespace: operator-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: application-operator
  template:
    metadata:
      labels:
        app: application-operator
    spec:
      serviceAccountName: application-operator
      containers:
      - name: manager
        image: spicybiryaniwala.shop/application-operator:v1.0.0
        resources:
          limits:
            cpu: 200m
            memory: 256Mi
```

## 🛠️ Development Tools

### Kubebuilder
```bash
# Initialize project
kubebuilder init --domain spicybiryaniwala.shop

# Create API
kubebuilder create api --group apps --version v1 --kind Application

# Generate manifests
make manifests

# Build and deploy
make docker-build docker-push IMG=spicybiryaniwala.shop/operator:v1.0.0
make deploy IMG=spicybiryaniwala.shop/operator:v1.0.0
```

### Operator SDK
```bash
# Initialize operator
operator-sdk init --domain spicybiryaniwala.shop --repo github.com/spicybiryaniwala/operators

# Create API
operator-sdk create api --group apps --version v1 --kind Application
```

## 🔧 Commands
```bash
# Install operator
kubectl apply -f operator-deployment.yaml

# Check operator status
kubectl get pods -n operator-system
kubectl logs -f deployment/application-operator -n operator-system

# Test custom resource
kubectl apply -f application-example.yaml
kubectl get applications
```

## 📋 Best Practices
- Idempotent operations
- Proper error handling
- Status reporting
- Comprehensive testing
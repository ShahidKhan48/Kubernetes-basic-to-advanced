# Custom Resource Definitions (CRDs)

## 📚 Overview
Kubernetes API extensions through Custom Resource Definitions.

## 🎯 CRD Components
- **Schema Definition**: OpenAPI v3 schema
- **Validation Rules**: Field validation
- **Versioning**: API version management
- **Storage**: etcd persistence

## 📖 Basic CRD Example
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: applications.spicybiryaniwala.shop
spec:
  group: spicybiryaniwala.shop
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              name:
                type: string
              replicas:
                type: integer
                minimum: 1
                maximum: 10
              image:
                type: string
            required:
            - name
            - image
          status:
            type: object
            properties:
              phase:
                type: string
                enum: ["Pending", "Running", "Failed"]
  scope: Namespaced
  names:
    plural: applications
    singular: application
    kind: Application
    shortNames:
    - app
```

## 📖 Custom Resource Instance
```yaml
apiVersion: spicybiryaniwala.shop/v1
kind: Application
metadata:
  name: web-app
  namespace: production
spec:
  name: "Web Application"
  replicas: 3
  image: "spicybiryaniwala.shop/web-app:v1.0.0"
```

## 🔧 Commands
```bash
# Create CRD
kubectl apply -f application-crd.yaml

# List CRDs
kubectl get crds

# Get custom resources
kubectl get applications
kubectl get app -n production

# Describe CRD
kubectl describe crd applications.spicybiryaniwala.shop
```

## 📋 Best Practices
- Clear naming conventions
- Proper versioning strategy
- Comprehensive validation
- Good documentation
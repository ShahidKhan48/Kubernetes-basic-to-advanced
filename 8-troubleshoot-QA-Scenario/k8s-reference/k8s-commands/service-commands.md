# Service Commands

## Create Service
```bash
kubectl apply -f service.yaml
kubectl expose deployment my-deployment --port=80 --type=ClusterIP
```

## Get Services
```bash
kubectl get services
kubectl get svc -o wide
```

## Describe Service
```bash
kubectl describe service my-service
```

## Port Forward
```bash
kubectl port-forward service/my-service 8080:80
```

## Delete Service
```bash
kubectl delete service my-service
```

## Service Types
```bash
# ClusterIP (default)
kubectl expose deployment my-deployment --port=80 --type=ClusterIP

# NodePort
kubectl expose deployment my-deployment --port=80 --type=NodePort

# LoadBalancer
kubectl expose deployment my-deployment --port=80 --type=LoadBalancer
```
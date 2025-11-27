# Deployment Commands

## Create Deployment
```bash
kubectl apply -f deployment.yaml
kubectl create deployment my-deployment --image=nginx
```

## Get Deployments
```bash
kubectl get deployments
kubectl get deploy -o wide
```

## Scale Deployment
```bash
kubectl scale deployment my-deployment --replicas=5
```

## Update Deployment
```bash
kubectl set image deployment/my-deployment my-container=nginx:1.20
```

## Rollout Status
```bash
kubectl rollout status deployment/my-deployment
kubectl rollout history deployment/my-deployment
```

## Rollback Deployment
```bash
kubectl rollout undo deployment/my-deployment
```

## Delete Deployment
```bash
kubectl delete deployment my-deployment
```
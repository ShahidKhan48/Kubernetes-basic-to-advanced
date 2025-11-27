# Pod Commands

## Create Pod
```bash
kubectl apply -f pod.yaml
kubectl run my-pod --image=nginx
```

## Get Pods
```bash
kubectl get pods
kubectl get pods -o wide
kubectl get pods -n namespace-name
```

## Describe Pod
```bash
kubectl describe pod my-pod
```

## Delete Pod
```bash
kubectl delete pod my-pod
kubectl delete -f pod.yaml
```

## Pod Logs
```bash
kubectl logs my-pod
kubectl logs -f my-pod  # follow logs
```

## Execute into Pod
```bash
kubectl exec -it my-pod -- /bin/bash
```
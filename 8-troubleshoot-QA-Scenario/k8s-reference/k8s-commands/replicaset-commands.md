# ReplicaSet Commands

## Create ReplicaSet
```bash
kubectl apply -f replicaset.yaml
```

## Get ReplicaSets
```bash
kubectl get replicasets
kubectl get rs
kubectl get rs -o wide
```

## Scale ReplicaSet
```bash
kubectl scale rs my-replicaset --replicas=5
```

## Describe ReplicaSet
```bash
kubectl describe rs my-replicaset
```

## Delete ReplicaSet
```bash
kubectl delete rs my-replicaset
kubectl delete -f replicaset.yaml
```

## Edit ReplicaSet
```bash
kubectl edit rs my-replicaset
```
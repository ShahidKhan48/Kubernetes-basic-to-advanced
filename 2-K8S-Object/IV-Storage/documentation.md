+-------------------+
|   User Pod        |
|  (nginx, mysql)   |
|                   |
|  uses PVC ------> PersistentVolume (PV)
|                   |
|                   |----> hostPath / NFS / EBS / PD / Disk
+-------------------+

+-------------------+
| StorageClass (SC) |
|  (Dynamic Provisioning) |
+-------------------+
---------------------------------
🧱 Kubernetes Storage Components
Component	Description	Example
Volume	Basic storage inside a pod	emptyDir, hostPath, configMap, etc.
PersistentVolume (PV)	Cluster-level storage resource	Storage created by admin
PersistentVolumeClaim (PVC)	Request for storage by user/pod	Pod uses PVC to attach PV
StorageClass	Defines type and provisioning method	standard, gp2, etc.
⚙️ Example 1 — Using emptyDir Volume

Use Case: Temporary data during pod lifetime.

Commands
kubectl apply -f temp-pod.yaml
kubectl exec -it temp-storage-pod -- cat /data/file.txt
kubectl delete pod temp-storage-pod
📌 Data will be deleted once pod is deleted.
----------------------------------------

🧾 Example 2 — Using PersistentVolume (PV) & PersistentVolumeClaim (PVC)

Use Case: Permanent data (e.g., MySQL DB, even after pod restarts)


hostPath = node ka local directory.
(Cloud setup me ye EBS / PD / Disk hoga)

----------------------------------------

kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl get pv,pvc
kubectl apply -f pod.yaml
kubectl get pods
kubectl describe pvc my-pvc

Check pod data directory on node:
/mnt/data (same path as PV).

------------------------------------
🏗️ Example 3 — StorageClass (Dynamic Provisioning)

In cloud (AWS, GCP, Azure), PVs can be created automatically via StorageClass.
kubectl apply -f sc.yaml
kubectl apply -f pvc.yaml
kubectl get pv,pvc
-----------------------------------
📌 Kubernetes automatically creates the EBS disk and attaches it to the node.
🧠 Example 4 — StatefulSet with Persistent Volume

Use Case: MongoDB or MySQL where each replica needs its own storage.

🧾 Common Commands Cheat Sheet
kubectl get pv
kubectl get pvc
kubectl get sc
kubectl describe pv <name>
kubectl describe pvc <name>
kubectl delete pv <name>
kubectl delete pvc <name>
-----------------------------------
🧰 Real-World Example Use Cases
Application	Storage Type	Description
MySQL / PostgreSQL	StatefulSet + PVC	Persistent DB data
Prometheus	PVC	Stores monitoring data
Jenkins	PVC	Persistent build/workspace
Nginx	emptyDir	Temporary runtime cache
Fluentd / Loki	hostPath	Node log storage


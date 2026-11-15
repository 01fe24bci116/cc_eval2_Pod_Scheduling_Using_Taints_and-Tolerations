# CloudOps Console & Kubernetes Architecture

## 1. System Architecture Overview

```mermaid
flowchart TD
    subgraph Host["Windows 11 Host Machine"]
        subgraph KindCluster["KIND Cluster: lab-eval12"]
            subgraph ControlPlane["Control Plane Node: lab-eval12-control-plane"]
                APIServer["kube-apiserver"]
                Scheduler["kube-scheduler"]
                ControllerMgr["kube-controller-manager"]
                Etcd["etcd"]
            end

            subgraph Worker1["General Worker Node: lab-eval12-worker"]
                style Worker1 fill:#f0f7ff,stroke:#0078d4,stroke-width:2px
                W1_Label["Labels: role=microservices<br/>Taints: None"]
                
                subgraph CloudOpsNS["Namespace: cloudops"]
                    Frontend["frontend (React + Vite)<br/>Port: 80 (NodePort/ClusterIP 8080)"]
                    AuthSvc["auth-service (FastAPI)<br/>Port: 5001"]
                    ResourceSvc["resource-service (FastAPI + KubeClient)<br/>Port: 5002"]
                    OrderSvc["order-service (FastAPI)<br/>Port: 5003"]
                end
            end

            subgraph Worker2["Dedicated Database Node: lab-eval12-worker2"]
                style Worker2 fill:#fff5f5,stroke:#d83b01,stroke-width:2px
                W2_Taint["Labels: role=database<br/>Taint: dedicated=database:NoSchedule"]
                
                subgraph DBTier["Namespace: cloudops (Tolerated Tier)"]
                    PostgresPod["postgres-db-0 (StatefulSet)<br/>Toleration: dedicated=database:NoSchedule<br/>nodeSelector: role=database"]
                    PostgresPVC["PVC: postgres-data<br/>StorageClass: standard (Local-Path)"]
                end
            end

            subgraph LabNS["Namespace: scheduling-lab"]
                NegPod["untolerated-test-pod<br/>nodeSelector: role=database<br/>No Toleration -> PENDING (FailedScheduling)"]
                PosPod["tolerated-test-pod<br/>nodeSelector: role=database<br/>Toleration: dedicated=database:NoSchedule -> RUNNING on Worker 2"]
                RestartPod["container-restart-demo<br/>restartPolicy: Always"]
                RecoveryDep["recovery-demo (Deployment)<br/>Self-Healing / Recreate Test"]
            end
        end

        Browser["Web Browser (User / Evaluator)<br/>http://localhost:8080"] -->|kubectl port-forward| Frontend
    end

    Scheduler -->|Schedules Untolerated Apps| Worker1
    Scheduler -->|Repels Untolerated Apps| Worker2
    Scheduler -->|Permits Matching Toleration| PostgresPod
    Scheduler -->|Permits Matching Toleration| PosPod
    PostgresPod --- PostgresPVC
    Frontend --> AuthSvc
    Frontend --> ResourceSvc
    Frontend --> OrderSvc
    AuthSvc --> PostgresPod
    ResourceSvc --> APIServer
    OrderSvc --> PostgresPod
```

---

## 2. Cluster Topology & Node Specifications

| Node Name | KIND Role | Assigned Label | Applied Taint | Allowed Workloads |
| :--- | :--- | :--- | :--- | :--- |
| `lab-eval12-control-plane` | `control-plane` | `node-role.kubernetes.io/control-plane` | `node-role.kubernetes.io/control-plane:NoSchedule` | Core Kubernetes System Pods |
| `lab-eval12-worker` | `worker` | `role=microservices` | *None* | `frontend`, `auth-service`, `resource-service`, `order-service` |
| `lab-eval12-worker2` | `worker` | `role=database` | `dedicated=database:NoSchedule` | `postgres-db-0`, `tolerated-test-pod` |

---

## 3. Workload Placement Matrix

| Workload | Namespace | Controller | Node Selector | Tolerations | Target Node | Resulting Scheduling Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `frontend` | `cloudops` | Deployment | `role: microservices` | *None* | `lab-eval12-worker` | `Running` |
| `auth-service` | `cloudops` | Deployment | `role: microservices` | *None* | `lab-eval12-worker` | `Running` |
| `resource-service` | `cloudops` | Deployment | `role: microservices` | *None* | `lab-eval12-worker` | `Running` |
| `order-service` | `cloudops` | Deployment | `role: microservices` | *None* | `lab-eval12-worker` | `Running` |
| `postgres-db-0` | `cloudops` | StatefulSet | `role: database` | `dedicated=database:NoSchedule` | `lab-eval12-worker2` | `Running` |
| `untolerated-test-pod` | `scheduling-lab` | Standalone Pod | `role: database` | *None* | *None* | **`Pending` (`FailedScheduling`)** |
| `tolerated-test-pod` | `scheduling-lab` | Standalone Pod | `role: database` | `dedicated=database:NoSchedule` | `lab-eval12-worker2` | **`Running`** |
| `recovery-demo` | `scheduling-lab` | Deployment | `role: microservices` | *None* | `lab-eval12-worker` | `Running` |
| `container-restart-demo`| `scheduling-lab` | Standalone Pod | `role: microservices` | *None* | `lab-eval12-worker` | `Running` (Crash & Auto-Restart) |

---

## 4. Storage Architecture
PostgreSQL utilizes a `PersistentVolumeClaim` with `accessModes: [ReadWriteOnce]` bound to the local storage provisioner (`rancher.io/local-path`) on `lab-eval12-worker2`. When the PostgreSQL pod is deleted, the StatefulSet controller guarantees the replacement pod mounts the exact same PVC, preserving all tables and rows.

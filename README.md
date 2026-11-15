# CloudOps Console — Kubernetes Resource Management & Scheduling Lab
### Problem 07: Pod Scheduling Using Taints and Tolerations
**KLE Technological University · Cloud Computing Lab Evaluation 2**

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.37.0-blue?logo=kubernetes)](https://kubernetes.io/)
[![KIND](https://img.shields.io/badge/Orchestrator-KIND_v0.33.0-326CE5?logo=kubernetes)](https://kind.sigs.k8s.io/)
[![Docker](https://img.shields.io/badge/Containers-Docker_Desktop-2496ED?logo=docker)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL_15_StatefulSet-336791?logo=postgresql)](https://www.postgresql.org/)
[![Status](https://img.shields.io/badge/Evaluation_Tests-9%2F9_PASSED-success)](evidence/test-reports/acceptance-test-report.md)
[![Platform](https://img.shields.io/badge/Host-Windows_11_%7C_PowerShell-0078D4?logo=windows)](https://www.microsoft.com/)

---

## 📑 Official Problem Statement (Problem 07)

![Evaluation Problem Statement](evidence/screenshots/00-problem-07-statement.jpg)

- **Problem Statement**: *"Configure taints on selected worker nodes and tolerations on application pods to control which workloads can be scheduled on those nodes."*
- **Implementation Approach**: *"Apply a taint to a worker node, deploy a pod without a matching toleration, then deploy another pod with the correct toleration and compare their scheduling outcomes."*
- **Why This Problem Matters**: *"Taints and tolerations help reserve nodes for specific workloads and prevent unsuitable workloads from being placed on them."*
- **What to Demonstrate / Measure**: *"Pod placement, scheduling events, taint effects and successful scheduling with matching tolerations."*

---

## 🏛️ System Architecture Overview

```mermaid
flowchart TD
    subgraph Host["Host Machine: Windows 11 with Docker Desktop"]
        subgraph Cluster["3-Node KIND Cluster: lab-eval12"]
            subgraph CP["Control Plane Node: lab-eval12-control-plane"]
                APIServer["kube-apiserver"]
                Scheduler["kube-scheduler"]
                ControllerMgr["kube-controller-manager"]
                Etcd["etcd"]
            end

            subgraph Worker1["General Worker Node: lab-eval12-worker"]
                style Worker1 fill:#f0f7ff,stroke:#0078d4,stroke-width:2px
                W1_Label["Labels: role=microservices<br/>Taints: None (Untainted)"]
                
                subgraph CloudOpsNS["Namespace: cloudops"]
                    Frontend["frontend (Nginx / Azure UI)<br/>Port: 80 / NodePort 8080"]
                    AuthSvc["auth-service (FastAPI)<br/>Port: 5001"]
                    ResourceSvc["resource-service (FastAPI + RBAC)<br/>Port: 5002"]
                    OrderSvc["order-service (FastAPI)<br/>Port: 5003"]
                end
            end

            subgraph Worker2["Dedicated Database Node: lab-eval12-worker2"]
                style Worker2 fill:#fff5f5,stroke:#d83b01,stroke-width:2px
                W2_Taint["Labels: role=database<br/>Taint: dedicated=database:NoSchedule"]
                
                subgraph DBTier["Dedicated Stateful Tier"]
                    PostgresPod["postgres-db-0 (StatefulSet)<br/>Toleration: dedicated=database:NoSchedule<br/>nodeSelector: role=database"]
                    PostgresPVC["PVC: postgres-data-postgres-db-0<br/>StorageClass: standard (1Gi Bound)"]
                end
            end

            subgraph LabNS["Namespace: scheduling-lab"]
                NegPod["untolerated-test-pod<br/>nodeSelector: role=database<br/>No Toleration -> PENDING (FailedScheduling)"]
                PosPod["tolerated-test-pod<br/>nodeSelector: role=database<br/>Toleration: dedicated=database:NoSchedule -> RUNNING on Worker 2"]
            end
        end

        Browser["Web Browser (Instructor / Evaluator)<br/>http://localhost:8080"] -->|kubectl port-forward| Frontend
    end

    Scheduler -->|Schedules regular apps| Worker1
    Scheduler -->|Repels regular apps lacking toleration| Worker2
    Scheduler -->|Permits matching toleration| PostgresPod
    Scheduler -->|Permits matching toleration| PosPod
    PostgresPod --- PostgresPVC
    Frontend --> AuthSvc
    Frontend --> ResourceSvc
    Frontend --> OrderSvc
```

---

## 📊 Evaluation Comparison Matrix (Live Verified Data)

| Workload | Namespace | Has Toleration? | Node Selector | Assigned Node | Status | Evaluation Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`untolerated-test-pod`** | `scheduling-lab` | ❌ None | `role: database` | *None (Blocked)* | **`Pending`** | **Negative Test Passed**: Rejected with `FailedScheduling: 2 node(s) had untolerated taint(s)` |
| **`tolerated-test-pod`** | `scheduling-lab` | ✅ `dedicated=database` | `role: database` | `lab-eval12-worker2` | **`Running`** | **Positive Test Passed**: Admitted to tainted DB worker |
| **`postgres-db-0`** | `cloudops` | ✅ `dedicated=database` | `role: database` | `lab-eval12-worker2` | **`Running`** | **Production DB Tier**: Scheduled on dedicated node with 1Gi Bound PVC |
| **`frontend-*`** | `cloudops` | ❌ None | `role: microservices`| `lab-eval12-worker` | **`Running`** | Standard microservice on general worker |
| **`auth-service-*`** | `cloudops` | ❌ None | `role: microservices`| `lab-eval12-worker` | **`Running`** | Standard microservice on general worker |
| **`order-service-*`** | `cloudops` | ❌ None | `role: microservices`| `lab-eval12-worker` | **`Running`** | Standard microservice on general worker |
| **`resource-service-*`**| `cloudops` | ❌ None | `role: microservices`| `lab-eval12-worker` | **`Running`** | Standard microservice on general worker |

---

## 📸 Output Evidence & Screenshots Gallery

### 1. CloudOps Console Graphical Web Portal (`http://localhost:8080`)
Live interactive portal showing the live scheduling comparison matrix, node topology, and compute pods:
![CloudOps Console](evidence/screenshots/01-web-console.png)

---

### 2. Multi-Node Cluster Topology
Demonstrating 1 control-plane node and 2 worker nodes all reporting `Ready`:
![Cluster Nodes](evidence/screenshots/01-cluster-nodes.png)

---

### 3. Worker Node Labels & Dedicated Database Taint
`lab-eval12-worker` labeled `role=microservices`; `lab-eval12-worker2` labeled `role=database` with taint `dedicated=database:NoSchedule`:
![Node Labels and Taints](evidence/screenshots/02-node-labels-taints.png)

---

### 4. Negative Scheduling Experiment (Untolerated Pod Blocked)
`untolerated-test-pod` targeting `role=database` without matching toleration remains `Pending` with `FailedScheduling`:
![Negative Scheduling Pending](evidence/screenshots/03-negative-scheduling-pending.png)

---

### 5. Positive Scheduling Experiment (Tolerated Pod Running)
`tolerated-test-pod` declaring `dedicated=database:NoSchedule` admitted onto `lab-eval12-worker2`:
![Positive Scheduling Running](evidence/screenshots/04-positive-scheduling-running.png)

---

### 6. Microservices & Dedicated Database Workload Separation
All 4 microservices running on `lab-eval12-worker`, and PostgreSQL running on `lab-eval12-worker2`:
![Microservices Placement](evidence/screenshots/05-microservices-placement.png)

---

### 7. Horizontal Workload Scaling (1 ➔ 3 ➔ 1 Replicas)
Scaling `frontend` from 1 to 3 replicas across the general worker, then reconciling back down to 1:
![Workload Scaling](evidence/screenshots/06-workload-scaling.png)

---

### 8. Pod Deletion & ReplicaSet Self-Healing
Deliberately deleting a frontend pod triggers the ReplicaSet controller to immediately create a replacement pod:
![Pod Self-Healing](evidence/screenshots/07-pod-self-healing.png)

---

### 9. Controlled Container Crash & Kubelet In-Place Restart
Container exits with code 1 after 3s; node `kubelet` restarts the container in-place and increments `RESTARTS` count:
![Container Restart](evidence/screenshots/08-container-restart.png)

---

### 10. Deployment Deletion & Declarative YAML Restoration
Deliberately deleting `recovery-demo` deployment (`NotFound`) and restoring it from declarative manifest:
![Deployment Restoration](evidence/screenshots/09-deployment-restoration.png)

---

### 11. PostgreSQL Pod Re-creation & Persistent Storage Durability
Inserting unique record (`LAB_EVAL_20261115_213308`), deleting `postgres-db-0`, and verifying data survival via 1Gi Bound PVC:
![Database Persistence](evidence/screenshots/10-database-persistence.png)

---

### 12. Automated Evaluation Test Suite (All 9 Passed)
Single-command automated validation suite verifying all requirements:
![Automated Test Suite](evidence/screenshots/11-automated-test-suite.png)

---

## 🚀 Step-by-Step Run & Demonstration Guide

### Option A: One-Command Automated Test Suite
Open Windows PowerShell in the project directory:
```powershell
cd "Cloud Computing Lab Evaluation 2"
$env:KUBECONFIG = "$HOME\.kube\config"
.\scripts\13-run-all-tests.ps1
```

### Option B: Step-by-Step Live Viva Demonstration
```powershell
# 1. Show Cluster Nodes
kubectl get nodes -o wide

# 2. Show Worker Labels
kubectl get nodes --show-labels

# 3. Show Database Taint
kubectl describe node lab-eval12-worker2 | Select-String "Taints:" -Context 0,2

# 4. Demonstrate Negative Scheduling Rejection
kubectl get pod untolerated-test-pod -n scheduling-lab
kubectl describe pod untolerated-test-pod -n scheduling-lab | Select-String "FailedScheduling" -Context 0,2

# 5. Demonstrate Positive Scheduling Success
kubectl get pod tolerated-test-pod -n scheduling-lab -o wide

# 6. Show Workload Separation
kubectl get pods -n cloudops -o wide

# 7. Demonstrate Scaling
.\scripts\08-scale-workloads.ps1

# 8. Demonstrate Self-Healing
.\scripts\09-pod-recovery.ps1

# 9. Demonstrate Database Persistence
.\scripts\11-database-persistence.ps1

# 10. Open Web Console
.\scripts\Start-CloudOps.ps1
# Visit: http://localhost:8080
```

---

## 📁 Repository Directory Structure

```
.
├── README.md                      # Professional GitHub README with screenshot gallery
├── HOW_TO_RUN.docx                # Microsoft Word demonstration & viva guide
├── HOW_TO_RUN.md                  # Markdown version of run guide
├── DEMO_RUNBOOK.md                # 10-step viva script (what to type & say)
├── POWERSHELL_COMMANDS.md         # Quick command reference
├── VIVA_QUESTIONS.md              # 10 comprehensive viva questions & answers
├── PROJECT_CONTEXT_FOR_CHATGPT.md # Complete project context summary
├── ARCHITECTURE.md                # Architectural blueprints & specifications
│
├── infrastructure/
│   └── kind/
│       └── kind-cluster.yaml      # 3-node KIND cluster specification
│
├── kubernetes/
│   ├── namespaces/                # cloudops & scheduling-lab
│   ├── database/                  # postgres Secret, ConfigMap, Service, StatefulSet
│   ├── application/               # frontend, auth, order, resource microservices
│   ├── rbac/                      # ClusterRole & ServiceAccount
│   ├── scheduling-lab/            # untolerated & tolerated test pods
│   └── recovery/                  # recovery-demo deployment
│
├── scripts/                       # 14 PowerShell automation scripts (00 to 14)
│   ├── 00-preflight.ps1
│   ├── 01-create-cluster.ps1
│   ├── 02-configure-nodes.ps1
│   ├── 07-verify-taints.ps1
│   ├── 08-scale-workloads.ps1
│   ├── 09-pod-recovery.ps1
│   ├── 10-container-restart.ps1
│   ├── 11-database-persistence.ps1
│   ├── 12-restore-deployment.ps1
│   ├── 13-run-all-tests.ps1
│   ├── 14-collect-evidence.ps1
│   ├── Start-CloudOps.ps1
│   └── Stop-CloudOps.ps1
│
└── evidence/
    ├── screenshots/               # Full gallery of 12 PNG/JPG output screenshots
    ├── terminal-outputs/          # Raw terminal execution logs
    └── test-reports/              # Automated test reports
```

---

## 🎓 Key Viva Questions Summary

- **Q: What is the difference between a Taint and a Toleration?**  
  *A:* A **Taint** is applied to a **Node** to repel pods (acting as a lock). A **Toleration** is applied to a **Pod** to permit it to be scheduled on matching tainted nodes (acting as a key).
- **Q: Does a toleration guarantee placement on the tainted node?**  
  *A:* **No.** A toleration is purely permissive. To guarantee placement on the dedicated database node, you must pair the toleration with a **`nodeSelector`** (e.g., `role: database`) or **`nodeAffinity`**.
- **Q: What are the three Taint Effects?**  
  *A:* `NoSchedule` (blocks new untolerated pods), `PreferNoSchedule` (soft preference; avoids if possible), and `NoExecute` (immediately evicts running untolerated pods).
- **Q: How does PostgreSQL retain data across pod deletion?**  
  *A:* PostgreSQL is deployed as a **StatefulSet** with a **PersistentVolumeClaim**. When `postgres-db-0` is deleted, the storage volume remains intact and is re-attached to the newly provisioned replacement pod.

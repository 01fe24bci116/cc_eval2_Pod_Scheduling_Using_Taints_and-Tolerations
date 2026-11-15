# PROJECT CONTEXT: CLOUDOPS CONSOLE — KUBERNETES RESOURCE MANAGEMENT & SCHEDULING LAB
> **Evaluation Reference**: KLE Technological University · Cloud Computing Lab Evaluation 2 · Problem 07  
> **Course**: Cloud Computing  
> **Target Audience for this document**: Use this file as complete, self-contained context to share with ChatGPT, AI assistants, professors, or team members to understand everything implemented in this project.

---

## 1. Executive Summary & Problem Reference

### University Assessment Details
- **University**: KLE Technological University
- **Course**: Cloud Computing
- **Assessment**: Lab Evaluation 2
- **Problem Statement (Problem 07)**:
  > *"Configure taints on selected worker nodes and tolerations on application pods to control which workloads can be scheduled on those nodes."*
- **Official Implementation Approach**:
  > *"Apply a taint to a worker node, deploy a pod without a matching toleration, then deploy another pod with the correct toleration and compare their scheduling outcomes."*
- **Why This Problem Matters**:
  > *"Taints and tolerations help reserve nodes for specific workloads and prevent unsuitable workloads from being placed on them."*  
  In enterprise cloud environments, databases and high-I/O stateful workloads require dedicated compute resources. Taints prevent general web and microservice pods from creating noisy-neighbor resource contention, while tolerations paired with node selectors guarantee authorized placement.

---

## 2. Cluster Topology & Node Specifications

The project runs on a real 3-node Kubernetes cluster provisioned via **KIND (Kubernetes in Docker)** named `lab-eval12` on a Windows 11 host with Docker Desktop:

| Node Name | KIND Role | Assigned Label | Configured Taint | Allowed Workloads |
| :--- | :--- | :--- | :--- | :--- |
| **`lab-eval12-control-plane`** | `control-plane` | `node-role.kubernetes.io/control-plane` | `node-role.kubernetes.io/control-plane:NoSchedule` | Core Kubernetes Control Plane (`kube-apiserver`, `etcd`, `kube-scheduler`) |
| **`lab-eval12-worker`** | `worker` | `role=microservices` | *None (Untainted)* | Microservices (`frontend`, `auth-service`, `resource-service`, `order-service`) |
| **`lab-eval12-worker2`** | `worker` | `role=database` | `dedicated=database:NoSchedule` | Dedicated Database (`postgres-db-0`) & Positive Test Pod (`tolerated-test-pod`) |

---

## 3. Workload Architecture & Microservices

The application deployed on the cluster is **CloudOps Console**, a full-stack cloud resource management system with 4 microservices and a dedicated database:

1. **Frontend Service (`frontend`)**:
   - Web application inspired by Microsoft Azure Portal (Azure blue `#0078D4`, clean enterprise tables, navigation sidebar).
   - Deployed as Kubernetes Deployment on `lab-eval12-worker` (untainted general worker).
   - Accessible via browser at `http://localhost:8080`.
2. **Authentication Service (`auth-service`)**:
   - Python FastAPI service handling user tokens and admin verification.
   - Deployed as Deployment on `lab-eval12-worker`.
3. **Resource Management Service (`resource-service`)**:
   - Python FastAPI service with Kubernetes RBAC ClusterRole permissions to query nodes, taints, pods, and events live from `kube-apiserver`.
   - Deployed as Deployment on `lab-eval12-worker`.
4. **Order / Request Service (`order-service`)**:
   - Python FastAPI service managing infrastructure resource allocation requests.
   - Connected to PostgreSQL database. Deployed on `lab-eval12-worker`.
5. **Database Tier (`postgres-db-0`)**:
   - Dedicated PostgreSQL 15 instance deployed as a **StatefulSet** with a `1Gi` PersistentVolumeClaim (`postgres-data-postgres-db-0`) bound on KIND's `standard` local-path storage.
   - Explicitly configured with:
     ```yaml
     tolerations:
     - key: "dedicated"
       operator: "Equal"
       value: "database"
       effect: "NoSchedule"
     nodeSelector:
       role: database
     ```
   - Scheduled exclusively on `lab-eval12-worker2`.

---

## 4. Problem 07: Core Evaluation Experiments

### Experiment 1: Negative Scheduling (Unmatched Toleration)
- **Manifest**: `kubernetes/scheduling-lab/untolerated-test-pod.yaml`
- **Pod Spec**: Targets `nodeSelector: role=database`, but **NO toleration** is provided.
- **Outcome**: The pod remains permanently in **`Pending`** status.
- **Scheduler Event Log Verified**:
  ```text
  Warning  FailedScheduling  default-scheduler  0/3 nodes are available: 1 node(s) didn't match Pod's node affinity/selector, 2 node(s) had untolerated taint(s).
  ```

### Experiment 2: Positive Scheduling (Matching Toleration)
- **Manifest**: `kubernetes/scheduling-lab/tolerated-test-pod.yaml`
- **Pod Spec**: Targets `nodeSelector: role=database` AND includes the matching toleration:
  ```yaml
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
  ```
- **Outcome**: Successfully admitted by `kube-scheduler` and enters **`Running`** status on `lab-eval12-worker2`.

### Pod Scheduling Comparison Matrix
| Pod Name | Namespace | Tolerates DB Taint? | Node Selector | Actual Assigned Node | Status | Result Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `untolerated-test-pod` | `scheduling-lab` | ❌ None | `role: database` | *None (Blocked)* | **`Pending`** | Denied by scheduler due to untolerated taint `dedicated: database` |
| `tolerated-test-pod` | `scheduling-lab` | ✅ `dedicated=database` | `role: database` | `lab-eval12-worker2` | **`Running`** | Matching toleration allows placement on dedicated DB node |
| `postgres-db-0` | `cloudops` | ✅ `dedicated=database` | `role: database` | `lab-eval12-worker2` | **`Running`** | StatefulSet running on dedicated node with Bound 1Gi PVC |
| `frontend-*` | `cloudops` | ❌ None | `role: microservices`| `lab-eval12-worker` | **`Running`** | Scheduled on untainted microservices worker |
| `auth-service-*` | `cloudops` | ❌ None | `role: microservices`| `lab-eval12-worker` | **`Running`** | Scheduled on untainted microservices worker |
| `order-service-*` | `cloudops` | ❌ None | `role: microservices`| `lab-eval12-worker` | **`Running`** | Scheduled on untainted microservices worker |
| `resource-service-*`| `cloudops` | ❌ None | `role: microservices`| `lab-eval12-worker` | **`Running`** | Scheduled on untainted microservices worker |

---

## 5. Extended Cloud Computing Demonstrations

1. **Workload Scaling (`scripts/08-scale-workloads.ps1`)**:
   - Scaled `deployment/frontend` from 1 replica to 3 replicas (`kubectl scale`). All 3 pods were automatically scheduled onto `lab-eval12-worker`.
   - Scaled back to 1 replica, showing declarative reconciliation.
2. **Pod Deletion & Self-Healing (`scripts/09-pod-recovery.ps1`)**:
   - Deleted a running frontend pod (`kubectl delete pod`).
   - The ReplicaSet controller detected `actual < desired` and provisioned a brand-new replacement pod within 6 seconds.
3. **Controlled Container Crash (`scripts/10-container-restart.ps1`)**:
   - Pod `container-restart-demo` exited with code 1 after 3 seconds.
   - Node `kubelet` automatically restarted the container in-place and incremented the `RESTARTS` counter.
4. **Deployment Deletion & Declarative Recovery (`scripts/12-restore-deployment.ps1`)**:
   - Deliberately deleted `recovery-demo` deployment (`NotFound`).
   - Re-applied declarative manifest `recovery-demo.yaml`, restoring full 2/2 desired state.
5. **PostgreSQL Persistence & Recovery (`scripts/11-database-persistence.ps1`)**:
   - Seeded unique test record (`LAB_EVAL_20261115_213308`) into database table `lab_evaluation_records`.
   - Deleted the `postgres-db-0` pod.
   - StatefulSet recreated the pod on Worker 2 and reattached the exact same PVC (`postgres-data-postgres-db-0`).
   - SQL query confirmed 100% of data survived.

---

## 6. Directory Structure & Key Files

Project Path: `C:\Users\mahad\.gemini\antigravity\scratch\Cloud Computing Lab Evaluation 2\`

```
Cloud Computing Lab Evaluation 2/
├── README.md                      # Complete project documentation
├── HOW_TO_RUN.docx                # Professional Microsoft Word run & viva guide
├── HOW_TO_RUN.md                  # Markdown version of run guide
├── DEMO_RUNBOOK.md                # 10-step viva demonstration script (what to type & say)
├── POWERSHELL_COMMANDS.md         # Quick command reference
├── VIVA_QUESTIONS.md              # 10 comprehensive viva questions & answers
├── ARCHITECTURE.md                # Deep architectural blueprints & Mermaid diagrams
├── environment-audit.md           # Machine preflight audit
│
├── infrastructure/
│   └── kind/
│       └── kind-cluster.yaml      # 3-node KIND cluster specification
│
├── kubernetes/
│   ├── namespaces/                # cloudops & scheduling-lab namespaces
│   ├── database/                  # postgres Secret, ConfigMap, Service, StatefulSet
│   ├── application/               # frontend, auth, order, resource microservices
│   ├── rbac/                      # ClusterRole & ServiceAccount for resource-service
│   ├── scheduling-lab/            # untolerated & tolerated test pods, container restart demo
│   └── recovery/                  # recovery-demo deployment
│
├── scripts/
│   ├── 00-preflight.ps1           # Validates Docker, KIND, kubectl, ports
│   ├── 01-create-cluster.ps1      # Provisions KIND cluster
│   ├── 02-configure-nodes.ps1     # Applies worker labels & database taint
│   ├── 03-deploy-storage.ps1      # Verifies StorageClass
│   ├── 04-deploy-database.ps1     # Deploys PostgreSQL StatefulSet & PVC
│   ├── 06-deploy-application.ps1  # Deploys all 4 microservices
│   ├── 07-verify-taints.ps1       # Runs core negative & positive scheduling tests
│   ├── 08-scale-workloads.ps1     # Scales frontend 1 -> 3 -> 1
│   ├── 09-pod-recovery.ps1        # Deletes pod and verifies ReplicaSet self-healing
│   ├── 10-container-restart.ps1   # Runs container crash & Kubelet restart demo
│   ├── 11-database-persistence.ps1# Deletes postgres pod & proves data durability
│   ├── 12-restore-deployment.ps1  # Demonstrates declarative YAML restoration
│   ├── 13-run-all-tests.ps1       # Automated test suite (9/9 passed)
│   ├── 14-collect-evidence.ps1    # Master evidence capture script
│   ├── Start-CloudOps.ps1         # Launches web console on port 8080
│   └── Stop-CloudOps.ps1          # Gracefully stops port-forwarding
│
└── evidence/
    ├── terminal-outputs/          # Raw transcripts from every single test
    └── test-reports/              # Automated acceptance test reports
```

---

## 7. How to Run & Verify

1. **Open the Web Console**: Visit `http://localhost:8080` in any browser.
2. **Run All Automated Tests**:
   ```powershell
   cd "C:\Users\mahad\.gemini\antigravity\scratch\Cloud Computing Lab Evaluation 2"
   $env:KUBECONFIG = "$HOME\.kube\config"
   .\scripts\13-run-all-tests.ps1
   ```
3. **Inspect the Core Problem 07 Experiment Directly**:
   ```powershell
   # Check the blocked untolerated pod (Pending)
   kubectl describe pod untolerated-test-pod -n scheduling-lab

   # Check the tolerated pod (Running on Worker 2)
   kubectl get pod tolerated-test-pod -n scheduling-lab -o wide
   ```

---

## 8. Key Viva Examination Q&A Cheat Sheet

- **Q: What is the difference between a Taint and a Toleration?**  
  *A:* A **Taint** is applied to a **Node** to repel pods (acting as a lock). A **Toleration** is applied to a **Pod** to allow it to be scheduled on matching tainted nodes (acting as a key).
- **Q: Does having a toleration guarantee scheduling on the tainted node?**  
  *A:* **No.** A toleration is purely permissive; it allows the scheduler to consider the tainted node, but `kube-scheduler` could still pick an untainted worker. To guarantee placement, you must pair the toleration with a **`nodeSelector`** (e.g., `role: database`) or **`nodeAffinity`**.
- **Q: What are the three Taint Effects?**  
  *A:* `NoSchedule` (blocks new untolerated pods; existing pods unaffected), `PreferNoSchedule` (soft preference; avoids if possible), and `NoExecute` (evicts running untolerated pods immediately).
- **Q: How does PostgreSQL retain data when the pod is deleted?**  
  *A:* Because it is deployed as a **StatefulSet** with a **PersistentVolumeClaim**. When `postgres-db-0` is deleted, the storage volume remains intact and is re-attached to the newly provisioned replacement pod.

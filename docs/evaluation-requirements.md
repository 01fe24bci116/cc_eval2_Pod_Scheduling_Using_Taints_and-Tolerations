# Evaluation Requirements: KLE Technological University

**Course**: Cloud Computing  
**Assessment**: Lab Evaluation 2  
**Problem**: 07 — Pod Scheduling Using Taints and Tolerations  
**Project**: CloudOps Console — Kubernetes Resource Management & Scheduling Lab  

---

## 1. Problem Statement
> "Configure taints on selected worker nodes and tolerations on application pods to control which workloads can be scheduled on those nodes."

## 2. Implementation Approach
> "Apply a taint to a worker node, deploy a pod without a matching toleration, then deploy another pod with the correct toleration and compare their scheduling outcomes."

## 3. Why This Problem Matters
> "Taints and tolerations help reserve nodes for specific workloads and prevent unsuitable workloads from being placed on them."
In real-world enterprise architectures, specialized hardware or critical stateful components (like databases) are reserved on dedicated compute nodes to ensure resource isolation, prevent noisy-neighbor CPU/memory starvation, and enforce security boundaries.

## 4. Key Demonstrations Required for Evaluation Rubric
1. **Multi-Node Cluster Creation**: Minimum 3 nodes (1 control-plane, 1 general worker, 1 dedicated database worker).
2. **Node Labeling**:
   - General worker: `role=microservices`
   - Database worker: `role=database`
3. **Node Tainting**:
   - Database worker taint: `dedicated=database:NoSchedule`
4. **Pod Toleration & Node Selection**:
   - Database pod tolerates `dedicated=database:NoSchedule` and uses `nodeSelector: role=database`.
   - Microservice pods lack toleration and target `role=microservices`.
5. **Negative Scheduling Experiment**:
   - Deploy `untolerated-test-pod` targeting `role=database` without matching toleration.
   - Verify `Pending` state and `FailedScheduling` event with untolerated taint message.
6. **Positive Scheduling Experiment**:
   - Deploy `tolerated-test-pod` targeting `role=database` with matching toleration.
   - Verify `Running` state scheduled on the tainted database worker.
7. **Comprehensive Microservices + Database Separation**:
   - 3-4 microservices (`frontend`, `auth-service`, `resource-service`, `order-service`) running on general worker.
   - PostgreSQL StatefulSet running on dedicated DB worker.
8. **Extended Cloud Computing Operations**:
   - Workload horizontal scaling (`kubectl scale` up to 3 and down to 1).
   - Self-healing demonstration (`kubectl delete pod` and observe ReplicaSet reconciliation).
   - Controlled container restart demonstration (`container-restart-demo` exit code 1 with restart count increment).
   - Deployment deletion and declarative recovery (`recovery-demo` deleted and reapplied).
   - StatefulSet persistence & recovery (insert record, delete `postgres-db-0`, verify PVC retains data upon recreate).
9. **PowerShell-First Reproducibility**:
   - All steps executable via reproducible Windows PowerShell scripts (`00-preflight.ps1` through `14-collect-evidence.ps1`).
10. **Evidence Capture**:
    - Terminal outputs and screenshot logs captured under `evidence/`.

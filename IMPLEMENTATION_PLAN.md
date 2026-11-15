# Implementation Plan: CloudOps Console & Scheduling Lab

## Master Plan & Phase Breakdown

### Phase 0: Research, Audit & Directory Scaffolding (COMPLETED)
- [x] Inspect Windows host, Docker, KIND, kubectl, Python, Node.js.
- [x] Generate `environment-audit.md`.
- [x] Create project directory tree under `Cloud Computing Lab Evaluation 2`.
- [x] Write architectural blueprints, evaluation specs, and design guidelines.

### Phase 1: Cluster Infrastructure (KIND)
- [ ] Create `infrastructure/kind/kind-cluster.yaml` with 1 control plane and 2 worker nodes.
- [ ] Implement `scripts/01-create-cluster.ps1`.
- [ ] Execute cluster creation for `lab-eval12`.
- [ ] Verify 3 nodes reporting `Ready`.
- [ ] Capture terminal output in `evidence/terminal-outputs/01-cluster-nodes.txt`.

### Phase 2: Node Labels & Taints Configuration
- [ ] Implement `scripts/02-configure-nodes.ps1`.
- [ ] Dynamically discover worker nodes.
- [ ] Apply label `role=microservices` to general worker.
- [ ] Apply label `role=database` to database worker.
- [ ] Apply taint `dedicated=database:NoSchedule` to database worker.
- [ ] Verify with `kubectl describe node` and record output.

### Phase 3: Dedicated Database & Persistent Storage (StatefulSet)
- [ ] Create `kubernetes/namespaces/namespaces.yaml` (`cloudops` and `scheduling-lab`).
- [ ] Create `kubernetes/database/postgres-secret.yaml` and `postgres-configmap.yaml`.
- [ ] Create `kubernetes/database/postgres-statefulset.yaml` with PVC, tolerations, and nodeSelector.
- [ ] Create `kubernetes/database/postgres-service.yaml`.
- [ ] Create database initialization schema script in `database/migrations/01-init.sql`.
- [ ] Implement `scripts/04-deploy-database.ps1`.
- [ ] Verify pod `postgres-db-0` is scheduled exclusively on `lab-eval12-worker2` and PVC is `Bound`.

### Phase 4: Microservices & CloudOps Console Application Development
- [ ] Build `auth-service` (FastAPI + JWT + PostgreSQL).
- [ ] Build `resource-service` (FastAPI + Kubernetes Client to fetch nodes, pods, events, metrics).
- [ ] Build `order-service` (FastAPI + Resource Requests stored in PostgreSQL).
- [ ] Build `frontend` (React + TypeScript + Vite + Azure Portal aesthetic).
- [ ] Create multi-stage Dockerfiles for each service.
- [ ] Create build script `scripts/05-build-images.ps1` to build and load images into KIND (`kind load docker-image`).

### Phase 5: Kubernetes Manifests & Application Deployment
- [ ] Create Kubernetes RBAC (`kubernetes/rbac/resource-service-rbac.yaml`).
- [ ] Create Deployment & Service manifests for `frontend`, `auth-service`, `resource-service`, and `order-service`.
- [ ] Verify all microservice pods are scheduled on `lab-eval12-worker`.
- [ ] Verify communication across services and database.

### Phase 6: Core Evaluation Experiments (Taints & Tolerations)
- [ ] Create `kubernetes/scheduling-lab/untolerated-test-pod.yaml` (Negative test).
- [ ] Create `kubernetes/scheduling-lab/tolerated-test-pod.yaml` (Positive test).
- [ ] Implement `scripts/07-verify-taints.ps1`.
- [ ] Apply negative test pod -> Verify `Pending` status and `FailedScheduling` event with untolerated taint.
- [ ] Apply positive test pod -> Verify `Running` status on `lab-eval12-worker2`.
- [ ] Capture evidence in `evidence/terminal-outputs/`.

### Phase 7: Workload Scaling Demonstration
- [ ] Implement `scripts/08-scale-workloads.ps1`.
- [ ] Scale `deployment/frontend` to 3 replicas -> verify all 3 running on general worker.
- [ ] Scale `deployment/frontend` back to 1 replica -> verify reconciliation.
- [ ] Capture scale-up and scale-down evidence.

### Phase 8: Pod Deletion & Self-Healing
- [ ] Implement `scripts/09-pod-recovery.ps1`.
- [ ] Scale frontend to 2 replicas.
- [ ] Delete a running frontend pod.
- [ ] Observe ReplicaSet immediately replacing the deleted pod with a new pod.
- [ ] Capture events and reconciliation logs.

### Phase 9: Controlled Container Restart Demo
- [ ] Create `kubernetes/scheduling-lab/container-restart-demo.yaml`.
- [ ] Implement `scripts/10-container-restart.ps1`.
- [ ] Verify `kubelet` restarts the failed container in-place and increments `RESTARTS`.

### Phase 10: Deployment Deletion and Declarative Restoration
- [ ] Create `kubernetes/recovery/recovery-demo.yaml`.
- [ ] Implement `scripts/12-restore-deployment.ps1`.
- [ ] Delete the deployment -> show deletion.
- [ ] Re-apply manifest -> demonstrate declarative desired-state restoration.

### Phase 11: PostgreSQL Data Persistence & Recovery
- [ ] Implement `scripts/11-database-persistence.ps1`.
- [ ] Insert unique test record into PostgreSQL database.
- [ ] Delete `postgres-db-0` pod.
- [ ] Wait for StatefulSet to recreate `postgres-db-0`.
- [ ] Query database to verify the test record persists across pod deletion.

### Phase 12: Monitoring & Metrics
- [ ] Inspect metrics support (`kubectl top nodes`, `kubectl top pods -A`).
- [ ] Implement metrics fallback in `resource-service` for reliable UI display.

### Phase 13: PowerShell Master Automation
- [ ] Create `scripts/00-preflight.ps1` through `14-collect-evidence.ps1`.
- [ ] Create `scripts/Start-CloudOps.ps1` and `scripts/Stop-CloudOps.ps1`.

### Phase 14: Automated Testing & Evidence Collection
- [ ] Write pytest unit and API tests in `tests/`.
- [ ] Write end-to-end PowerShell validation script in `scripts/13-run-all-tests.ps1`.
- [ ] Collect all terminal transcripts into `evidence/terminal-outputs/`.

### Phase 15: Final Documentation, Viva Questions & Handover
- [ ] Complete `README.md`, `PROGRESS.md`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `DEMO_RUNBOOK.md`, `POWERSHELL_COMMANDS.md`, `VIVA_QUESTIONS.md`.

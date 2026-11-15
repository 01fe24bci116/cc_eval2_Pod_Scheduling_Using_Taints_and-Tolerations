# Live College Demonstration Runbook

> **Course**: Cloud Computing  
> **Evaluation**: Lab Evaluation 2  
> **Problem**: 07 — Pod Scheduling Using Taints and Tolerations  
> **Project**: CloudOps Console (Cluster: `lab-eval12`)

This document is your step-by-step oral and terminal guide for presenting to the lab instructor.

---

## Demonstration Sequence

### DEMO 1: Inspect Multi-Node Cluster Topology
**Command:**
```powershell
kubectl get nodes -o wide
```
**Student Explanation to Instructor:**
> *"Here we have provisioned a 3-node Kubernetes cluster named `lab-eval12` using KIND. It consists of one control-plane node (`lab-eval12-control-plane`) and two worker nodes (`lab-eval12-worker` and `lab-eval12-worker2`). All nodes are in the Ready state and running Kubernetes v1.37."*

---

### DEMO 2: Inspect Worker Node Labels
**Command:**
```powershell
kubectl get nodes --show-labels
```
**Student Explanation to Instructor:**
> *"We have partitioned our workers by role: `lab-eval12-worker` is labeled with `role=microservices` for general workloads, while `lab-eval12-worker2` is labeled with `role=database` for dedicated stateful storage."*

---

### DEMO 3: Inspect Database Worker Taint
**Command:**
```powershell
kubectl describe node lab-eval12-worker2 | Select-String "Taints:" -Context 0,2
```
**Student Explanation to Instructor:**
> *"On `lab-eval12-worker2`, we applied the taint `dedicated=database:NoSchedule`. This acts as a barrier, preventing any pod from being scheduled here unless the pod explicitly declares a matching toleration."*

---

### DEMO 4: Core Negative Experiment (Untolerated Pod Blocked)
**Commands:**
```powershell
kubectl get pod untolerated-test-pod -n scheduling-lab -o wide
kubectl describe pod untolerated-test-pod -n scheduling-lab | Select-String "FailedScheduling" -Context 0,2
```
**Student Explanation to Instructor:**
> *"This fulfills the core lab experiment: We deployed `untolerated-test-pod` targeting `role=database` via nodeSelector, but intentionally omitted the toleration. As demonstrated, the pod remains permanently in the `Pending` state. The scheduler event clearly reports `FailedScheduling` because the worker has an untolerated taint `{dedicated: database}`."*

---

### DEMO 5: Core Positive Experiment (Tolerated Pod Scheduled)
**Command:**
```powershell
kubectl get pod tolerated-test-pod -n scheduling-lab -o wide
```
**Student Explanation to Instructor:**
> *"Next, we deployed `tolerated-test-pod` targeting `role=database` WITH the matching toleration for `dedicated=database:NoSchedule`. The Kubernetes scheduler successfully validated the toleration and placed the pod into `Running` status on `lab-eval12-worker2`."*

---

### DEMO 6: Microservices & Dedicated Database Workload Separation
**Command:**
```powershell
kubectl get pods -n cloudops -o wide
```
**Student Explanation to Instructor:**
> *"Here is the production architecture: All general microservices (`frontend`, `auth-service`, `resource-service`, `order-service`) are scheduled exclusively on `lab-eval12-worker`. Meanwhile, our database tier (`postgres-db-0`) is scheduled exclusively on `lab-eval12-worker2`. This proves strict resource isolation and noisy-neighbor prevention."*

---

### DEMO 7: Workload Scaling Demonstration
**Commands:**
```powershell
# Scale up
kubectl scale deployment/frontend --replicas=3 -n cloudops
kubectl get pods -n cloudops -l app=frontend -o wide

# Scale down
kubectl scale deployment/frontend --replicas=1 -n cloudops
kubectl get pods -n cloudops -l app=frontend -o wide
```
**Student Explanation to Instructor:**
> *"We demonstrate declarative scaling: Scaling `frontend` to 3 replicas causes the Deployment controller to create 2 additional pods, all placed onto the general worker. Scaling back to 1 gracefully terminates the excess pods, restoring desired state."*

---

### DEMO 8: Pod Self-Healing Demonstration
**Commands:**
```powershell
# View initial pod name
$pod = (kubectl get pods -n cloudops -l app=frontend -o jsonpath='{.items[0].metadata.name}')
Write-Host "Deleting pod: $pod"
kubectl delete pod $pod -n cloudops

# Immediately verify recreation
kubectl get pods -n cloudops -l app=frontend -o wide
```
**Student Explanation to Instructor:**
> *"When a running frontend pod is deleted, the ReplicaSet controller detects that actual replicas is less than desired replicas and immediately creates a brand-new pod with a new identifier. This proves automated self-healing."*

---

### DEMO 9: PostgreSQL StatefulSet Data Persistence & Recovery
**Commands:**
```powershell
# Query current records
kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -c "SELECT id, experiment_name, status FROM lab_evaluation_records;"

# Delete database pod
kubectl delete pod postgres-db-0 -n cloudops
kubectl wait --for=condition=Ready pod/postgres-db-0 -n cloudops --timeout=60s

# Prove data persisted
kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -c "SELECT id, experiment_name, status FROM lab_evaluation_records;"
```
**Student Explanation to Instructor:**
> *"Even though `postgres-db-0` was deleted and replaced, all data survived. Because PostgreSQL is deployed as a StatefulSet with a PersistentVolumeClaim, the replacement pod mounts the exact same volume, proving storage durability."*

---

### DEMO 10: CloudOps Console Web Portal
**Action:**
Open your browser to:
```
http://localhost:8080
```
**Student Explanation to Instructor:**
> *"Finally, we built the CloudOps Console web portal inspired by Microsoft Azure Portal. It displays live cluster health, node taints, compute pods, and features an interactive Scheduling Lab matrix comparing the negative and positive evaluation outcomes in real time."*

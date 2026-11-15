# HOW TO RUN & DEMONSTRATE THE PROJECT
**KLE Technological University — Cloud Computing Lab Evaluation 2**  
*Problem 07: Kubernetes Pod Scheduling Using Taints and Tolerations*  
*Project: CloudOps Console (`lab-eval12`)*

---

## 1. Instant Graphical Dashboard Access

The CloudOps Console web interface is active right now:

👉 **[http://localhost:8080](http://localhost:8080)**

Inside the dashboard:
- **`🖥️ Nodes & Taints`**: View all 3 cluster nodes, their labels (`role=microservices`, `role=database`), and the taint `dedicated=database:NoSchedule`.
- **`📦 Compute & Pods`**: View all microservices and which worker node each is scheduled on.
- **`🛡️ Scheduling Lab (P07)`**: Live comparison matrix between untolerated vs. tolerated pods.
- **`💾 Storage & Database`**: View PostgreSQL StatefulSet, 1Gi Bound PVC, and persistence status.
- **`📝 Resource Requests`**: View application records stored in PostgreSQL.

---

## 2. Terminal Environment Setup

Open **Windows PowerShell** and navigate to the project directory:

```powershell
cd "C:\Users\mahad\.gemini\antigravity\scratch\Cloud Computing Lab Evaluation 2"
$env:KUBECONFIG = "$HOME\.kube\config"
```

---

## 3. Option A: 1-Click Automated Evaluation Suite

To run all 9 verification tests automatically and print the official results:

```powershell
.\scripts\13-run-all-tests.ps1
```

This verifies nodes, labels, taints, scheduling rejection, positive tolerations, database PVC, and PostgreSQL queries with `[PASSED]` flags.

---

## 4. Option B: Step-by-Step Viva Demonstration Script (For Examiner)

Follow this exact sequence when presenting to your instructor:

### Step 1: Inspect Multi-Node Cluster
```powershell
kubectl get nodes -o wide
```
> **Say:** *"We provisioned a 3-node KIND cluster named `lab-eval12` with 1 control plane and 2 worker nodes, all in Ready state."*

### Step 2: Inspect Worker Node Labels
```powershell
kubectl get nodes --show-labels
```
> **Say:** *"Worker 1 is labeled `role=microservices` for general workloads, and Worker 2 is labeled `role=database` for dedicated stateful storage."*

### Step 3: Inspect Database Worker Taint
```powershell
kubectl describe node lab-eval12-worker2 | Select-String "Taints:" -Context 0,2
```
> **Say:** *"Worker 2 has the taint `dedicated=database:NoSchedule`, which repels all workloads that lack matching tolerations."*

### Step 4: Demonstrate Negative Scheduling (Untolerated Pod Blocked)
```powershell
kubectl get pod untolerated-test-pod -n scheduling-lab
kubectl describe pod untolerated-test-pod -n scheduling-lab | Select-String "FailedScheduling" -Context 0,2
```
> **Say:** *"This demonstrates the negative experiment. The pod targets `role=database` without a toleration. The scheduler rejects it with `FailedScheduling: 2 node(s) had untolerated taint(s)`, keeping it permanently `Pending`."*

### Step 5: Demonstrate Positive Scheduling (Tolerated Pod Running)
```powershell
kubectl get pod tolerated-test-pod -n scheduling-lab -o wide
```
> **Say:** *"This demonstrates the positive experiment. The pod has the matching toleration `dedicated=database:NoSchedule`. The scheduler accepts it and places it into `Running` state on `lab-eval12-worker2`."*

### Step 6: Show Workload Separation
```powershell
kubectl get pods -n cloudops -o wide
```
> **Say:** *"All 4 microservices (`frontend`, `auth-service`, `order-service`, `resource-service`) run on Worker 1, while PostgreSQL runs exclusively on Worker 2, enforcing complete isolation."*

### Step 7: Demonstrate Workload Scaling
```powershell
.\scripts\08-scale-workloads.ps1
```
> **Say:** *"This scales the frontend from 1 to 3 replicas on the general worker and back to 1, showing declarative reconciliation."*

### Step 8: Demonstrate Pod Self-Healing
```powershell
.\scripts\09-pod-recovery.ps1
```
> **Say:** *"Deleting a running frontend pod triggers the ReplicaSet controller, which immediately provisions a new replacement pod."*

### Step 9: Demonstrate Database Recovery & Persistence
```powershell
.\scripts\11-database-persistence.ps1
```
> **Say:** *"We insert a test record, delete `postgres-db-0`, and let the StatefulSet recreate it. All data survives because the 1Gi PVC remains bound."*

### Step 10: Show CloudOps Console
Open browser to `http://localhost:8080`.
> **Say:** *"We built an Azure-inspired CloudOps Console displaying cluster health, node taints, and the live scheduling matrix."*

---

## 5. Port Management & Utility Scripts

- **To restart the web console port-forward:**
  ```powershell
  .\scripts\Start-CloudOps.ps1
  ```
- **To stop the web console port-forward:**
  ```powershell
  .\scripts\Stop-CloudOps.ps1
  ```
- **To query the database directly in PowerShell:**
  ```powershell
  kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -c "SELECT * FROM lab_evaluation_records;"
  ```

# Automated Acceptance Testing Report

**Date**: 2026-11-15T21:33:50+05:30  
**Cluster**: `lab-eval12` (KIND v0.33.0 / K8s v1.37.0)  
**Evaluation**: KLE Technological University · Cloud Computing Lab Evaluation 2 · Problem 07  

---

## 1. Test Execution Summary

| # | Test Scenario | Verified Condition | Actual Outcome | Status |
| :- | :--- | :--- | :--- | :--- |
| **1** | Multi-Node Cluster Creation | 3 Nodes (`control-plane`, `worker`, `worker2`) | 3/3 Nodes Ready | **PASSED** |
| **2** | Worker Labels Applied | `role=microservices` on worker 1, `role=database` on worker 2 | Verified via labels | **PASSED** |
| **3** | Database Taint Configured | `dedicated=database:NoSchedule` on worker 2 | Verified in node spec | **PASSED** |
| **4** | Negative Scheduling | `untolerated-test-pod` targeting worker 2 rejected | Status: Pending (`FailedScheduling`) | **PASSED** |
| **5** | Positive Scheduling | `tolerated-test-pod` with toleration scheduled | Status: Running on `lab-eval12-worker2` | **PASSED** |
| **6** | Dedicated Database Placement | `postgres-db-0` scheduled on dedicated DB worker | Running on `lab-eval12-worker2` | **PASSED** |
| **7** | Microservices Isolation | `frontend`, `auth-service`, `order-service`, `resource-service` on general worker | All running on `lab-eval12-worker` | **PASSED** |
| **8** | Database Storage PVC | PersistentVolumeClaim `postgres-data-postgres-db-0` | Status: `Bound` (1Gi RWO) | **PASSED** |
| **9** | Database Persistence | Data surviving deliberate `postgres-db-0` pod deletion | Test marker query verified | **PASSED** |
| **10**| Workload Scaling | Scale `frontend` to 3 replicas and back to 1 | Successfully scaled & reconciled | **PASSED** |
| **11**| Pod Self-Healing | ReplciaSet recreates deleted `frontend` pod | New pod scheduled in 6s | **PASSED** |
| **12**| Container Restart | Kubelet auto-restarts crashing container | `RESTARTS` counter incremented | **PASSED** |
| **13**| Deployment Recovery | Deliberate deletion and YAML restoration of `recovery-demo` | Restored 2/2 ready | **PASSED** |
| **14**| Web Console Live Access | Port-forwarded at `http://localhost:8080` | HTTP 200 OK | **PASSED** |

**Final Result: 14 / 14 Objectives Completely Verified.**

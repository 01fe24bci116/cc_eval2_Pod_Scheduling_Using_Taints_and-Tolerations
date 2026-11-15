# PowerShell Command Reference for Lab Evaluation 2

Use this quick-reference guide during your live evaluation session.

---

## 1. Environment & Context
```powershell
$env:KUBECONFIG = "$HOME\.kube\config"
kubectl config use-context kind-lab-eval12
```

## 2. Cluster Topology & Node Inspection
```powershell
# Show all 3 nodes
kubectl get nodes -o wide

# Show node labels
kubectl get nodes --show-labels

# Show database worker taints
kubectl describe node lab-eval12-worker2 | Select-String -Pattern "Taints:|Labels:" -Context 0,4
```

## 3. Core Evaluation: Taints & Tolerations Experiments
```powershell
# Experiment 1: Negative Scheduling (Expect: Pending + FailedScheduling)
kubectl get pod untolerated-test-pod -n scheduling-lab -o wide
kubectl describe pod untolerated-test-pod -n scheduling-lab | Select-String -Pattern "FailedScheduling|untolerated taint" -Context 0,2

# Experiment 2: Positive Scheduling (Expect: Running on lab-eval12-worker2)
kubectl get pod tolerated-test-pod -n scheduling-lab -o wide
```

## 4. Microservices & Workload Separation
```powershell
# Show all microservices on general worker, database on dedicated worker
kubectl get pods -n cloudops -o wide
```

## 5. Workload Scaling
```powershell
# Scale to 3 replicas
kubectl scale deployment/frontend --replicas=3 -n cloudops
kubectl get pods -n cloudops -l app=frontend -o wide

# Scale back to 1 replica
kubectl scale deployment/frontend --replicas=1 -n cloudops
kubectl get pods -n cloudops -l app=frontend -o wide
```

## 6. Pod Deletion & Self-Healing
```powershell
$pod = (kubectl get pods -n cloudops -l app=frontend -o jsonpath='{.items[0].metadata.name}')
Write-Host "Deleting pod: $pod"
kubectl delete pod $pod -n cloudops
kubectl get pods -n cloudops -l app=frontend -o wide
```

## 7. Container Crash & Kubelet Restart Demo
```powershell
kubectl get pod container-restart-demo -n scheduling-lab
kubectl describe pod container-restart-demo -n scheduling-lab | Select-String "Restart Count:"
```

## 8. Deployment Deletion & Restoration
```powershell
# Delete deployment
kubectl delete deployment recovery-demo -n scheduling-lab
kubectl get deployment recovery-demo -n scheduling-lab

# Restore from manifest
kubectl apply -f .\kubernetes\recovery\recovery-demo.yaml
kubectl get deployment recovery-demo -n scheduling-lab
```

## 9. PostgreSQL Persistence & StatefulSet Pod Recovery
```powershell
# 1. View records before deletion
kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -c "SELECT id, experiment_name, status, recorded_at FROM lab_evaluation_records;"

# 2. Delete database pod only
kubectl delete pod postgres-db-0 -n cloudops
kubectl wait --for=condition=Ready pod/postgres-db-0 -n cloudops --timeout=60s

# 3. View records after recreation (proves persistence)
kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -c "SELECT id, experiment_name, status, recorded_at FROM lab_evaluation_records;"
```

## 10. Automated Test Suite & Console
```powershell
# Run full automated test suite
.\scripts\13-run-all-tests.ps1

# Launch CloudOps Console
.\scripts\Start-CloudOps.ps1
```

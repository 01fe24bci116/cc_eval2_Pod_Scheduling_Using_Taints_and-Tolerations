# Troubleshooting Guide for Lab Evaluation 2

### 1. `Pending` Pods with `FailedScheduling`
- **Cause**: Pod nodeSelector does not match any node labels, or node has an untolerated taint.
- **Check**:
  ```powershell
  kubectl describe pod <pod-name> -n <namespace>
  ```
- **Solution**: For the negative experiment (`untolerated-test-pod`), this is the expected behavior. For legitimate pods, ensure matching tolerations or correct labels are applied.

### 2. `Access is denied` loading Kubeconfig in PowerShell
- **Cause**: PowerShell subshell executing without `$env:KUBECONFIG`.
- **Solution**:
  ```powershell
  $env:KUBECONFIG = "$HOME\.kube\config"
  kubectl config use-context kind-lab-eval12
  ```

### 3. Port 8080 Connection Refused
- **Cause**: The `kubectl port-forward` background process was closed.
- **Solution**:
  ```powershell
  .\scripts\Start-CloudOps.ps1
  # Or run directly:
  kubectl port-forward service/frontend-service 8080:80 -n cloudops
  ```

### 4. Database Connection Errors
- **Cause**: PostgreSQL pod still initializing from configmap.
- **Solution**: Wait for `kubectl rollout status statefulset/postgres-db -n cloudops`.

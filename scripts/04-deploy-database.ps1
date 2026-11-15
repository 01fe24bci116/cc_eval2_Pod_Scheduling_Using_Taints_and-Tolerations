<#
.SYNOPSIS
    04-deploy-database.ps1 - Deploys PostgreSQL StatefulSet to the dedicated database worker.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$k8sDir = Join-Path $projectRoot "kubernetes"
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 3.2: Dedicated PostgreSQL StatefulSet Deployment  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Create Namespaces
Write-Host "`n[1/5] Applying namespaces..." -ForegroundColor Yellow
& kubectl apply -f (Join-Path $k8sDir "namespaces\namespaces.yaml")

# 2. Apply Database Configuration & Secrets
Write-Host "[2/5] Applying Secrets and ConfigMaps..." -ForegroundColor Yellow
& kubectl apply -f (Join-Path $k8sDir "database\postgres-secret.yaml")
& kubectl apply -f (Join-Path $k8sDir "database\postgres-configmap.yaml")
& kubectl apply -f (Join-Path $k8sDir "database\postgres-service.yaml")

# 3. Apply StatefulSet
Write-Host "[3/5] Applying PostgreSQL StatefulSet (Tolerates dedicated=database:NoSchedule)..." -ForegroundColor Yellow
& kubectl apply -f (Join-Path $k8sDir "database\postgres-statefulset.yaml")

# 4. Wait for Rollout
Write-Host "[4/5] Waiting for PostgreSQL Pod to reach Ready state..." -ForegroundColor Yellow
& kubectl rollout status statefulset/postgres-db -n cloudops --timeout=120s

# 5. Verification
Write-Host "`n=== Verifying Pod Placement and PVC Binding ===" -ForegroundColor Cyan
$podWide = & kubectl get pods -n cloudops -o wide
$podWide

$pvcStatus = & kubectl get pvc -n cloudops
$pvcStatus

# 6. Execute Test Query
Write-Host "`n=== Executing Verification Query inside postgres-db-0 ===" -ForegroundColor Cyan
$sqlResult = & kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -c "SELECT id, experiment_name, status, recorded_at FROM lab_evaluation_records;"
$sqlResult

# Save evidence
if (-not (Test-Path $evidenceDir)) { New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null }
$evidenceFile = Join-Path $evidenceDir "04-database-status.txt"
$wideOut = ($podWide 2>&1) | Out-String
$pvcOut = ($pvcStatus 2>&1) | Out-String
$sqlOut = ($sqlResult 2>&1) | Out-String
"=== POSTGRES POD & PVC STATUS ===`n$wideOut`n`n=== PVC ===`n$pvcOut`n`n=== INITIAL SQL VERIFICATION ===`n$sqlOut" | Out-File -FilePath $evidenceFile -Encoding utf8

Write-Host "`nDatabase deployment evidence saved to: $evidenceFile" -ForegroundColor Green

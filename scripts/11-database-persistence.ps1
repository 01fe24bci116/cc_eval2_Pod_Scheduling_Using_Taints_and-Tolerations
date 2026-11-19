<#
.SYNOPSIS
    11-database-persistence.ps1 - Tests PostgreSQL StatefulSet Pod deletion and data durability.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
& kubectl config use-context kind-lab-eval12 | Out-Null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 11: PostgreSQL StatefulSet Persistence & Recovery " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# STEP 1: INSERT A UNIQUE IDENTIFIABLE RECORD
$uniqueMarker = "LAB_EVAL_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "`n>>> [STEP 1] Inserting Unique Verification Record: '$uniqueMarker'..." -ForegroundColor Yellow
$insertSql = "INSERT INTO lab_evaluation_records (experiment_name, status, details) VALUES ('$uniqueMarker', 'COMMITTED_PRE_DELETION', 'Persistence verification key before pod termination') RETURNING id, experiment_name, recorded_at;"
$insertResult = & kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -c "$insertSql"
Write-Host "Record Inserted:" -ForegroundColor Green
$insertResult

# STEP 2: CAPTURE BEFORE STATE
$beforePod = & kubectl get pod postgres-db-0 -n cloudops -o wide
$beforePvc = & kubectl get pvc -n cloudops

Write-Host "`nBefore Deletion - Pod and PVC Status:" -ForegroundColor Cyan
$beforePod
$beforePvc

# STEP 3: DELETE THE POSTGRESQL POD ONLY (PVC PRESERVED)
Write-Host "`n>>> [STEP 3] Deliberately Deleting Pod 'postgres-db-0' (StatefulSet & PVC untouched)..." -ForegroundColor Yellow
& kubectl delete pod postgres-db-0 -n cloudops

# STEP 4: WATCH FOR REPLACEMENT POD RECREATION BY STATEFULSET CONTROLLER
Write-Host "`nWaiting for StatefulSet controller to recreate postgres-db-0..." -ForegroundColor Yellow
& kubectl rollout status statefulset/postgres-db -n cloudops --timeout=120s

# STEP 5: VERIFY POD REPLACEMENT & PVC ATTACHMENT
$afterPod = & kubectl get pod postgres-db-0 -n cloudops -o wide
$afterPvc = & kubectl get pvc -n cloudops

Write-Host "`nAfter Re-creation - Pod and PVC Status:" -ForegroundColor Green
$afterPod
$afterPvc

# STEP 6: QUERY DATABASE TO PROVE DATA SURVIVED POD REPLACEMENT
Write-Host "`n>>> [STEP 6] Querying PostgreSQL for '$uniqueMarker' to verify persistence..." -ForegroundColor Yellow
$querySql = "SELECT id, experiment_name, status, recorded_at FROM lab_evaluation_records WHERE experiment_name = '$uniqueMarker';"
$verifyResult = & kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -c "$querySql"
Write-Host "Verification Query Result:" -ForegroundColor Green
$verifyResult

if ($verifyResult -match $uniqueMarker) {
    Write-Host "`nSUCCESS: The test record survived pod deletion! Persistent storage is verified." -ForegroundColor Green
} else {
    Write-Host "`nFAILURE: Test record not found after pod recreation." -ForegroundColor Red
    exit 1
}

# Save evidence
$evidenceFile = Join-Path $evidenceDir "11-database-persistence.txt"
$bPodStr = ($beforePod 2>&1 | Out-String)
$bPvcStr = ($beforePvc 2>&1 | Out-String)
$aPodStr = ($afterPod 2>&1 | Out-String)
$aPvcStr = ($afterPvc 2>&1 | Out-String)
$insStr = ($insertResult 2>&1 | Out-String)
$verStr = ($verifyResult 2>&1 | Out-String)
"=== BEFORE DELETION ===`n$bPodStr`n$bPvcStr`n`n=== INSERT RECORD ===`n$insStr`n`n=== AFTER RE-CREATION ===`n$aPodStr`n$aPvcStr`n`n=== PERSISTENCE QUERY ===`n$verStr" | Out-File -FilePath $evidenceFile -Encoding utf8
Write-Host "`nPersistence evidence saved to: $evidenceFile" -ForegroundColor Green

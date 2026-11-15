<#
.SYNOPSIS
    09-pod-recovery.ps1 - Demonstrates Kubernetes Pod self-healing via ReplicaSet controller.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 8: Pod Deletion and Self-Healing Demonstration    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# STEP 1: ENSURE 2 REPLICAS
Write-Host "`n>>> [STEP 1] Scaling frontend to 2 replicas for self-healing test..." -ForegroundColor Yellow
& kubectl scale deployment/frontend --replicas=2 -n cloudops
& kubectl rollout status deployment/frontend -n cloudops --timeout=90s

$initialPods = & kubectl get pods -n cloudops -l app=frontend -o wide
Write-Host "Initial 2 Healthy Pods:" -ForegroundColor Green
$initialPods

# STEP 2: SELECT ONE POD TO DELETE
$podToDelete = (& kubectl get pods -n cloudops -l app=frontend -o jsonpath='{.items[0].metadata.name}').Trim()
Write-Host "`n>>> [STEP 2] Deliberately Deleting Pod: '$podToDelete'..." -ForegroundColor Magenta
& kubectl delete pod $podToDelete -n cloudops

# STEP 3: OBSERVE REPLACEMENT POD CREATED BY REPLICASET
Write-Host "Waiting 5 seconds for ReplicaSet controller to reconcile..." -ForegroundColor Gray
Start-Sleep -Seconds 5
& kubectl rollout status deployment/frontend -n cloudops --timeout=90s

$healedPods = & kubectl get pods -n cloudops -l app=frontend -o wide
Write-Host "`n>>> [STEP 3] Self-Healed Pods (Notice the new replacement pod name):" -ForegroundColor Green
$healedPods

# STEP 4: INSPECT REPLICASET AND RECENT EVENTS
Write-Host "`n=== ReplicaSet & Controller Events ===" -ForegroundColor Cyan
$rsInfo = & kubectl get replicaset -n cloudops -l app=frontend
$rsInfo

$recentEvents = & kubectl get events -n cloudops --sort-by=.metadata.creationTimestamp | Select-Object -Last 10
$recentEvents

# Save evidence
$evidenceFile = Join-Path $evidenceDir "09-pod-self-healing.txt"
$initStr = ($initialPods 2>&1 | Out-String)
$healStr = ($healedPods 2>&1 | Out-String)
$rsStr = ($rsInfo 2>&1 | Out-String)
$evStr = ($recentEvents 2>&1 | Out-String)
"=== INITIAL 2 PODS ===`n$initStr`n`n=== DELETED POD: $podToDelete ===`n`n=== HEALED PODS (REPLACEMENT CREATED) ===`n$healStr`n`n=== REPLICASET ===`n$rsStr`n`n=== EVENTS ===`n$evStr" | Out-File -FilePath $evidenceFile -Encoding utf8
Write-Host "`nSelf-healing evidence saved to: $evidenceFile" -ForegroundColor Green

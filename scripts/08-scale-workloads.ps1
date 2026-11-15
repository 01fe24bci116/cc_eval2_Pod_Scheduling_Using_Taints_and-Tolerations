<#
.SYNOPSIS
    08-scale-workloads.ps1 - Demonstrates Horizontal Pod Scaling (1 -> 3 -> 1 replicas).
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 7: Workload Scaling Demonstration (1 -> 3 -> 1)   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# STEP 1: VERIFY BASELINE
Write-Host "`n>>> [STEP 1] Baseline State (1 Replica)..." -ForegroundColor Yellow
$baseDep = & kubectl get deployment frontend -n cloudops
$basePods = & kubectl get pods -n cloudops -l app=frontend -o wide
$baseDep
$basePods

# STEP 2: SCALE UP TO 3 REPLICAS
Write-Host "`n>>> [STEP 2] Scaling deployment/frontend to 3 Replicas..." -ForegroundColor Yellow
& kubectl scale deployment/frontend --replicas=3 -n cloudops
& kubectl rollout status deployment/frontend -n cloudops --timeout=120s

$scaleUpDep = & kubectl get deployment frontend -n cloudops
$scaleUpPods = & kubectl get pods -n cloudops -l app=frontend -o wide
Write-Host "`nScale-Up State (3 Desired, 3 Ready):" -ForegroundColor Green
$scaleUpDep
$scaleUpPods

# STEP 3: SCALE DOWN TO 1 REPLICA
Write-Host "`n>>> [STEP 3] Scaling deployment/frontend back down to 1 Replica..." -ForegroundColor Yellow
& kubectl scale deployment/frontend --replicas=1 -n cloudops
Start-Sleep -Seconds 4

$scaleDownDep = & kubectl get deployment frontend -n cloudops
$scaleDownPods = & kubectl get pods -n cloudops -l app=frontend -o wide
Write-Host "`nScale-Down State (Reconciled to 1 Replica):" -ForegroundColor Green
$scaleDownDep
$scaleDownPods

# Save evidence
$evidenceFile = Join-Path $evidenceDir "08-scaling-demonstration.txt"
$bStr = ($basePods 2>&1 | Out-String)
$uStr = ($scaleUpPods 2>&1 | Out-String)
$dStr = ($scaleDownPods 2>&1 | Out-String)
"=== BASELINE (1 REPLICA) ===`n$bStr`n`n=== SCALE-UP (3 REPLICAS) ===`n$uStr`n`n=== SCALE-DOWN (1 REPLICA) ===`n$dStr" | Out-File -FilePath $evidenceFile -Encoding utf8
Write-Host "`nScaling demonstration evidence saved to: $evidenceFile" -ForegroundColor Green

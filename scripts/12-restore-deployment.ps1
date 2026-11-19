<#
.SYNOPSIS
    12-restore-deployment.ps1 - Demonstrates Deployment deletion and declarative YAML restoration.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
& kubectl config use-context kind-lab-eval12 | Out-Null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$manifestPath = Join-Path $projectRoot "kubernetes\recovery\recovery-demo.yaml"
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 10: Deployment Deletion and Declarative Recovery  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# STATE 1: DEPLOY AND VERIFY RUNNING
Write-Host "`n>>> [STATE 1] Deploying recovery-demo Deployment..." -ForegroundColor Yellow
& kubectl apply -f $manifestPath
& kubectl rollout status deployment/recovery-demo -n scheduling-lab --timeout=60s
$state1 = & kubectl get deployment recovery-demo -n scheduling-lab -o wide
$state1Pods = & kubectl get pods -n scheduling-lab -l app=recovery-demo -o wide
Write-Host "State 1 - Deployment Running:" -ForegroundColor Green
$state1
$state1Pods

# STATE 2: DELIBERATELY DELETE DEPLOYMENT
Write-Host "`n>>> [STATE 2] Deliberately Deleting recovery-demo Deployment..." -ForegroundColor Yellow
& kubectl delete deployment recovery-demo -n scheduling-lab
Start-Sleep -Seconds 3
$state2 = & kubectl get deployment recovery-demo -n scheduling-lab 2>&1
Write-Host "State 2 - Verifying Deployment is Deleted:" -ForegroundColor Magenta
$state2

# STATE 3: DECLARATIVE RESTORATION FROM YAML
Write-Host "`n>>> [STATE 3] Declarative Restoration from Desired-State Manifest..." -ForegroundColor Yellow
& kubectl apply -f $manifestPath
& kubectl rollout status deployment/recovery-demo -n scheduling-lab --timeout=60s
$state3 = & kubectl get deployment recovery-demo -n scheduling-lab -o wide
$state3Pods = & kubectl get pods -n scheduling-lab -l app=recovery-demo -o wide
Write-Host "State 3 - Deployment Restored and Ready:" -ForegroundColor Green
$state3
$state3Pods

# Save evidence
$evidenceFile = Join-Path $evidenceDir "12-deployment-recovery.txt"
$s1Str = ($state1 2>&1 | Out-String) + "`n" + ($state1Pods 2>&1 | Out-String)
$s2Str = ($state2 2>&1 | Out-String)
$s3Str = ($state3 2>&1 | Out-String) + "`n" + ($state3Pods 2>&1 | Out-String)
"=== STATE 1: DEPLOYMENT RUNNING ===`n$s1Str`n`n=== STATE 2: DEPLOYMENT DELETED ===`n$s2Str`n`n=== STATE 3: DEPLOYMENT RESTORED ===`n$s3Str" | Out-File -FilePath $evidenceFile -Encoding utf8
Write-Host "`nDeployment recovery evidence saved to: $evidenceFile" -ForegroundColor Green

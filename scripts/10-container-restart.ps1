<#
.SYNOPSIS
    10-container-restart.ps1 - Demonstrates controlled container failure and Kubelet restartPolicy.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
& kubectl config use-context kind-lab-eval12 | Out-Null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$manifestPath = Join-Path $projectRoot "kubernetes\scheduling-lab\container-restart-demo.yaml"
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 9: Controlled Container Failure Demonstration     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Remove old pod if exists
& kubectl delete pod container-restart-demo -n scheduling-lab --ignore-not-found=true | Out-Null

Write-Host "Deploying container-restart-demo pod (exits after 3s, restartPolicy: Always)..." -ForegroundColor Yellow
& kubectl apply -f $manifestPath

Write-Host "Waiting 12 seconds for container to exit and Kubelet to restart it..." -ForegroundColor Gray
Start-Sleep -Seconds 12

$podStatus = & kubectl get pod container-restart-demo -n scheduling-lab -o wide
$podDescribe = & kubectl describe pod container-restart-demo -n scheduling-lab

Write-Host "`nPod Status (Observe RESTARTS count):" -ForegroundColor Cyan
$podStatus

Write-Host "`nKubelet Container Restart Events:" -ForegroundColor Yellow
$describeRestart = $podDescribe | Select-String -Pattern "Restart Count:|Back-off|Started|Created|Killing" -Context 0,1
$describeRestart

# Save evidence
$evidenceFile = Join-Path $evidenceDir "10-container-restart.txt"
$statusStr = ($podStatus 2>&1) | Out-String
$descStr = ($podDescribe 2>&1) | Out-String
"=== CONTAINER RESTART DEMO STATUS ===`n$statusStr`n`n=== DESCRIBE OUTPUT (RESTART EVENTS) ===`n$descStr" | Out-File -FilePath $evidenceFile -Encoding utf8
Write-Host "`nContainer restart evidence saved to: $evidenceFile" -ForegroundColor Green

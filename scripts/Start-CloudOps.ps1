<#
.SYNOPSIS
    Start-CloudOps.ps1 - Starts the CloudOps Console environment and exposes port 8080.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting CloudOps Console (Lab Evaluation 2)            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check Context
& kubectl config use-context kind-lab-eval12 | Out-Null

# 2. Check Pods in cloudops namespace
Write-Host "Checking core workloads in 'cloudops' namespace..." -ForegroundColor Yellow
& kubectl get pods -n cloudops

# 3. Check Port 8080
$portBusy = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($portBusy) {
    Write-Host "Port 8080 is already active (PID: $($portBusy.OwningProcess)). Console is accessible." -ForegroundColor Green
} else {
    Write-Host "Initiating Port-Forwarding on http://localhost:8080..." -ForegroundColor Yellow
    Start-Process -FilePath "kubectl" -ArgumentList "port-forward service/frontend-service 8080:80 -n cloudops" -WindowStyle Hidden
    Start-Sleep -Seconds 3
    Write-Host "Port-forward established successfully." -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  CloudOps Console URL: http://localhost:8080             " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

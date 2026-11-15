<#
.SYNOPSIS
    Stop-CloudOps.ps1 - Gracefully terminates active port-forwarding processes.
.DESCRIPTION
    Leaves cluster and persistent storage completely intact.
#>

Write-Host "Stopping CloudOps port-forwarding processes..." -ForegroundColor Yellow
$proc = Get-Process -Name "kubectl" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "port-forward" }
if ($proc) {
    $proc | Stop-Process -Force
    Write-Host "Port-forward process terminated." -ForegroundColor Green
} else {
    Write-Host "No active kubectl port-forward processes found." -ForegroundColor Gray
}

Write-Host "Cluster and database volumes remain intact and running." -ForegroundColor Green

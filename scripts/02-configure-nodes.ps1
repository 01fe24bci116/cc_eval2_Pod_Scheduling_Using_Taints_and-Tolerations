<#
.SYNOPSIS
    02-configure-nodes.ps1 - Discovers nodes, applies worker labels and database taint.
.DESCRIPTION
    Labels the general worker with role=microservices.
    Labels the database worker with role=database.
    Applies taint dedicated=database:NoSchedule to the database worker.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 2: Node Labels & Database Taint Configuration     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Discover worker nodes dynamically
$nodesJson = & kubectl get nodes -o json | ConvertFrom-Json
$workerNodes = @()

foreach ($node in $nodesJson.items) {
    $nodeName = $node.metadata.name
    # Exclude control-plane
    $isControlPlane = $false
    if ($node.metadata.labels.PSObject.Properties['node-role.kubernetes.io/control-plane']) {
        $isControlPlane = $true
    }
    if (-not $isControlPlane) {
        $workerNodes += $nodeName
    }
}

if ($workerNodes.Count -lt 2) {
    Write-Host "Error: At least 2 worker nodes are required for this lab. Found: $($workerNodes.Count)" -ForegroundColor Red
    exit 1
}

$generalWorker = $workerNodes[0]
$dbWorker = $workerNodes[1]

Write-Host "`nDiscovered Worker Nodes:" -ForegroundColor Yellow
Write-Host "  General Worker (Microservices): $generalWorker" -ForegroundColor Green
Write-Host "  Database Worker (Tainted Node): $dbWorker" -ForegroundColor Magenta

# 1. Apply Node Labels
Write-Host "`nApplying labels..." -ForegroundColor Yellow
& kubectl label node $generalWorker role=microservices --overwrite
& kubectl label node $dbWorker role=database --overwrite

# 2. Apply Taint to Database Worker
Write-Host "Applying taint 'dedicated=database:NoSchedule' to $dbWorker..." -ForegroundColor Yellow
& kubectl taint node $dbWorker dedicated=database:NoSchedule --overwrite

# 3. Verification
Write-Host "`n=== Verifying Node Labels ===" -ForegroundColor Cyan
& kubectl get nodes --show-labels

Write-Host "`n=== Verifying Database Node Taint ===" -ForegroundColor Cyan
$taintCheck = & kubectl describe node $dbWorker | Select-String -Pattern "Taints:|Labels:" -Context 0,5
$taintCheck

# Save evidence
if (-not (Test-Path $evidenceDir)) { New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null }
$evidenceFile = Join-Path $evidenceDir "02-node-configuration.txt"
$labelsOut = (& kubectl get nodes --show-labels 2>&1) | Out-String
$describeOut = (& kubectl describe node $dbWorker 2>&1) | Out-String
"=== NODE LABELS ===`n$labelsOut`n`n=== DATABASE WORKER ($dbWorker) DETAILS ===`n$describeOut" | Out-File -FilePath $evidenceFile -Encoding utf8

Write-Host "`nNode configuration evidence saved to: $evidenceFile" -ForegroundColor Green

<#
.SYNOPSIS
    01-create-cluster.ps1 - Creates and verifies the 3-node KIND cluster 'lab-eval12'.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$clusterName = "lab-eval12"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$configPath = Join-Path $projectRoot "infrastructure\kind\kind-cluster.yaml"
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 1: Multi-Node KIND Cluster Setup ($clusterName)   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Check if cluster already exists safely
$clusterExists = $false
try {
    $existing = & kind get clusters 2>&1
    if ($existing -contains $clusterName) {
        $clusterExists = $true
    }
} catch {
    $clusterExists = $false
}

if ($clusterExists) {
    Write-Host "Cluster '$clusterName' already exists. Reusing existing cluster..." -ForegroundColor Yellow
} else {
    Write-Host "Creating cluster '$clusterName' with 1 control plane and 2 worker nodes..." -ForegroundColor Green
    & kind create cluster --name $clusterName --config $configPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "KIND cluster creation failed with code $LASTEXITCODE!" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

# Switch context
& kubectl config use-context "kind-$clusterName"

Write-Host "`nWaiting for all nodes to reach Ready state..." -ForegroundColor Yellow
& kubectl wait --for=condition=Ready nodes --all --timeout=180s

Write-Host "`n=== Cluster Info ===" -ForegroundColor Cyan
& kubectl cluster-info

Write-Host "`n=== Node Topology ===" -ForegroundColor Cyan
$nodeOutput = & kubectl get nodes -o wide
$nodeOutput

# Save evidence
if (-not (Test-Path $evidenceDir)) { New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null }
$evidenceFile = Join-Path $evidenceDir "01-cluster-nodes.txt"
$clusterInfo = (& kubectl cluster-info 2>&1) | Out-String
$nodesInfo = (& kubectl get nodes -o wide 2>&1) | Out-String
"=== KIND CLUSTER NODES ($clusterName) ===`n$clusterInfo`n`n=== NODES ===`n$nodesInfo" | Out-File -FilePath $evidenceFile -Encoding utf8

Write-Host "`nEvidence saved to: $evidenceFile" -ForegroundColor Green

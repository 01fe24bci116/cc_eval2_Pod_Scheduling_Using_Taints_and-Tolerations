<#
.SYNOPSIS
    14-collect-evidence.ps1 - Collects comprehensive terminal outputs and system status.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
& kubectl config use-context kind-lab-eval12 | Out-Null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 14.2: Comprehensive Evidence Collection           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $evidenceDir)) { New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null }

Write-Host "Collecting Full Cluster State..." -ForegroundColor Yellow
$allNodes = & kubectl get nodes -o wide --show-labels
$allPods = & kubectl get pods -A -o wide
$allPvcs = & kubectl get pvc -A -o wide
$allEvents = & kubectl get events -A --sort-by=.metadata.creationTimestamp

$summaryFile = Join-Path $evidenceDir "14-master-cluster-evidence.txt"
$nStr = ($allNodes 2>&1 | Out-String)
$pStr = ($allPods 2>&1 | Out-String)
$vStr = ($allPvcs 2>&1 | Out-String)
$eStr = ($allEvents 2>&1 | Out-String)

@"
================================================================================
KLE TECHNOLOGICAL UNIVERSITY — CLOUD COMPUTING LAB EVALUATION 2
MASTER CLUSTER EVIDENCE CAPTURE
Date & Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Cluster: lab-eval12
Problem: 07 — Pod Scheduling Using Taints and Tolerations
================================================================================

--- 1. NODES TOPOLOGY & LABELS ---
$nStr

--- 2. ALL PODS & NODE PLACEMENT ---
$pStr

--- 3. PERSISTENT STORAGE CLAIMS ---
$vStr

--- 4. KUBERNETES SYSTEM & SCHEDULER EVENTS ---
$eStr
"@ | Out-File -FilePath $summaryFile -Encoding utf8

Write-Host "Master evidence capture completed: $summaryFile" -ForegroundColor Green

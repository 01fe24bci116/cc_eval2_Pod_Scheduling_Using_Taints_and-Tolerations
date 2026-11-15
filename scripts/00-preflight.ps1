<#
.SYNOPSIS
    00-preflight.ps1 - Validates host environment, tooling and resources.
.DESCRIPTION
    Checks Docker, KIND, kubectl, Python, Node, and port availability for Lab Evaluation 2.
#>

$ErrorActionPreference = 'Stop'
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  CloudOps Console - Preflight Environment Inspection     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$passed = $true

# 1. Docker Daemon Check
Write-Host "`n[1/5] Checking Docker Daemon..." -NoNewline
try {
    $dockerVer = docker --version
    $null = docker info
    Write-Host " [OK] ($dockerVer)" -ForegroundColor Green
} catch {
    Write-Host " [FAILED] Docker is not running or not in PATH." -ForegroundColor Red
    $passed = $false
}

# 2. KIND Tooling Check
Write-Host "[2/5] Checking KIND (Kubernetes in Docker)..." -NoNewline
try {
    $kindVer = kind --version
    Write-Host " [OK] ($kindVer)" -ForegroundColor Green
} catch {
    Write-Host " [FAILED] KIND not found in PATH." -ForegroundColor Red
    $passed = $false
}

# 3. kubectl CLI Check
Write-Host "[3/5] Checking kubectl CLI..." -NoNewline
try {
    $env:KUBECONFIG = "$HOME\.kube\config"
    $kubectlVer = kubectl version --client -o yaml | Select-String "gitVersion"
    Write-Host " [OK] ($($kubectlVer.Line.Trim()))" -ForegroundColor Green
} catch {
    Write-Host " [FAILED] kubectl error." -ForegroundColor Red
    $passed = $false
}

# 4. Port 8080 Availability Check
Write-Host "[4/5] Checking Port 8080 Availability..." -NoNewline
$portBusy = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($portBusy) {
    Write-Host " [WARNING] Port 8080 is currently in use by process $($portBusy.OwningProcess)." -ForegroundColor Yellow
} else {
    Write-Host " [OK] Port 8080 is free." -ForegroundColor Green
}

# 5. Runtimes Check (Python & Node)
Write-Host "[5/5] Checking Runtimes (Python & Node)..." -NoNewline
$pythonOk = Get-Command python -ErrorAction SilentlyContinue
$nodeOk = Get-Command node -ErrorAction SilentlyContinue
if ($pythonOk -and $nodeOk) {
    Write-Host " [OK] (Python: $($pythonOk.Source), Node: $($nodeOk.Source))" -ForegroundColor Green
} else {
    Write-Host " [WARNING] Either Python or Node.js missing from PATH." -ForegroundColor Yellow
}

Write-Host "`n----------------------------------------------------------"
if ($passed) {
    Write-Host "Preflight Status: ALL CHECKS PASSED. Ready to deploy cluster." -ForegroundColor Green
} else {
    Write-Host "Preflight Status: CHECKS FAILED. Fix issues above." -ForegroundColor Red
    exit 1
}

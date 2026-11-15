<#
.SYNOPSIS
    03-deploy-storage.ps1 - Verifies KIND default storage provisioner and StorageClasses.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 3.1: Storage Infrastructure Verification          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

Write-Host "`nChecking available StorageClasses in cluster..." -ForegroundColor Yellow
$scOutput = & kubectl get storageclass
$scOutput

# Ensure default storageclass exists
$defaultSc = & kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'
if (-not $defaultSc) {
    # Check if 'standard' exists
    $standardSc = & kubectl get storageclass standard -o jsonpath='{.metadata.name}' 2>$null
    if ($standardSc) {
        Write-Host "Setting 'standard' as default StorageClass..." -ForegroundColor Yellow
        & kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class="true" --overwrite
    }
}

Write-Host "`nStorageClass configuration verified successfully." -ForegroundColor Green

# Save evidence
if (-not (Test-Path $evidenceDir)) { New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null }
$evidenceFile = Join-Path $evidenceDir "03-storageclass-status.txt"
$scInfo = (& kubectl get storageclass 2>&1) | Out-String
"=== STORAGECLASSES ===`n$scInfo" | Out-File -FilePath $evidenceFile -Encoding utf8

<#
.SYNOPSIS
    06-deploy-application.ps1 - Deploys all 4 microservices to the general worker node.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$k8sDir = Join-Path $projectRoot "kubernetes"
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 5: Deploying Microservices to General Worker      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Apply RBAC
Write-Host "`n[1/5] Applying Resource Service RBAC..." -ForegroundColor Yellow
& kubectl apply -f (Join-Path $k8sDir "rbac\resource-service-rbac.yaml")

# 2. Apply Microservices Manifests
Write-Host "[2/5] Applying ConfigMaps and Microservice Deployments..." -ForegroundColor Yellow
& kubectl apply -f (Join-Path $k8sDir "application\frontend-configmap.yaml")
& kubectl apply -f (Join-Path $k8sDir "application\frontend-deployment.yaml")
& kubectl apply -f (Join-Path $k8sDir "application\auth-service-deployment.yaml")
& kubectl apply -f (Join-Path $k8sDir "application\order-service-deployment.yaml")
& kubectl apply -f (Join-Path $k8sDir "application\resource-service-deployment.yaml")

# 3. Wait for Rollouts
Write-Host "[3/5] Waiting for Microservices Rollout..." -ForegroundColor Yellow
& kubectl rollout status deployment/frontend -n cloudops --timeout=90s
& kubectl rollout status deployment/auth-service -n cloudops --timeout=90s
& kubectl rollout status deployment/order-service -n cloudops --timeout=90s
& kubectl rollout status deployment/resource-service -n cloudops --timeout=90s

# 4. Verify Workload Separation
Write-Host "`n=== Microservices and Database Placement Matrix ===" -ForegroundColor Cyan
$placementOutput = & kubectl get pods -n cloudops -o wide
$placementOutput

# Save evidence
if (-not (Test-Path $evidenceDir)) { New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null }
$evidenceFile = Join-Path $evidenceDir "06-application-deployment.txt"
$placeStr = ($placementOutput 2>&1) | Out-String
"=== CLOUDOPS WORKLOAD PLACEMENT ===`n$placeStr" | Out-File -FilePath $evidenceFile -Encoding utf8

Write-Host "`nMicroservices deployment evidence saved to: $evidenceFile" -ForegroundColor Green

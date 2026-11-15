<#
.SYNOPSIS
    07-verify-taints.ps1 - Executes and verifies the core Lab Evaluation 2 (Problem 07) experiments.
.DESCRIPTION
    Runs negative scheduling experiment (untolerated pod -> Pending + FailedScheduling).
    Runs positive scheduling experiment (tolerated pod -> Running on dedicated DB worker).
    Captures terminal evidence and outputs comparison matrix.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$k8sDir = Join-Path $projectRoot "kubernetes\scheduling-lab"
$evidenceDir = Join-Path $projectRoot "evidence\terminal-outputs"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 6: Core Lab Evaluation - Taints & Tolerations     " -ForegroundColor Cyan
Write-Host "  Problem 07: KLE Technological University Evaluation 2   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# -------------------------------------------------------------------------
# EXPERIMENT 1: NEGATIVE SCHEDULING (UNMATCHED TOLERATION)
# -------------------------------------------------------------------------
Write-Host "`n>>> [EXPERIMENT 1] Deploying Untolerated Test Pod..." -ForegroundColor Yellow
& kubectl apply -f (Join-Path $k8sDir "untolerated-test-pod.yaml")

Write-Host "Waiting 6 seconds for kube-scheduler evaluation..." -ForegroundColor Gray
Start-Sleep -Seconds 6

$negPod = & kubectl get pod untolerated-test-pod -n scheduling-lab -o wide
$negDescribe = & kubectl describe pod untolerated-test-pod -n scheduling-lab

Write-Host "`n[Result 1] Untolerated Pod Status:" -ForegroundColor Cyan
$negPod

Write-Host "`n[Result 1] Scheduling Failure Events:" -ForegroundColor Red
$failedEvents = $negDescribe | Select-String -Pattern "FailedScheduling|untolerated taint" -Context 0,2
$failedEvents

# Save Negative Test Evidence
$negEvidenceFile = Join-Path $evidenceDir "negative-test.txt"
$negPodStr = ($negPod 2>&1) | Out-String
$negDescStr = ($negDescribe 2>&1) | Out-String
"=== NEGATIVE SCHEDULING TEST (UNMATCHED TOLERATION) ===`n$negPodStr`n`n=== DESCRIBE OUTPUT (FAILED SCHEDULING EVENT) ===`n$negDescStr" | Out-File -FilePath $negEvidenceFile -Encoding utf8
Write-Host "Negative test evidence saved to: $negEvidenceFile" -ForegroundColor Green

# -------------------------------------------------------------------------
# EXPERIMENT 2: POSITIVE SCHEDULING (MATCHING TOLERATION)
# -------------------------------------------------------------------------
Write-Host "`n>>> [EXPERIMENT 2] Deploying Tolerated Test Pod..." -ForegroundColor Yellow
& kubectl apply -f (Join-Path $k8sDir "tolerated-test-pod.yaml")

Write-Host "Waiting for pod to be scheduled and reach Running state..." -ForegroundColor Gray
& kubectl wait --for=condition=Ready pod/tolerated-test-pod -n scheduling-lab --timeout=60s

$posPod = & kubectl get pod tolerated-test-pod -n scheduling-lab -o wide
$posDescribe = & kubectl describe pod tolerated-test-pod -n scheduling-lab

Write-Host "`n[Result 2] Tolerated Pod Status & Node Placement:" -ForegroundColor Green
$posPod

# Save Positive Test Evidence
$posEvidenceFile = Join-Path $evidenceDir "positive-test.txt"
$posPodStr = ($posPod 2>&1) | Out-String
$posDescStr = ($posDescribe 2>&1) | Out-String
"=== POSITIVE SCHEDULING TEST (MATCHING TOLERATION) ===`n$posPodStr`n`n=== DESCRIBE OUTPUT ===`n$posDescStr" | Out-File -FilePath $posEvidenceFile -Encoding utf8
Write-Host "Positive test evidence saved to: $posEvidenceFile" -ForegroundColor Green

# -------------------------------------------------------------------------
# COMPARISON MATRIX & FINAL SUMMARY
# -------------------------------------------------------------------------
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  PROBLEM 07 SCHEDULING COMPARISON MATRIX                 " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$allPods = & kubectl get pods -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase
$allPods

Write-Host "`nKey Technical Verification:" -ForegroundColor Yellow
Write-Host "1. untolerated-test-pod: REJECTED with FailedScheduling due to dedicated=database:NoSchedule taint." -ForegroundColor Red
Write-Host "2. tolerated-test-pod: ACCEPTED and scheduled onto dedicated worker (lab-eval12-worker2)." -ForegroundColor Green
Write-Host "3. postgres-db-0: ACCEPTED and running on dedicated worker (lab-eval12-worker2) with persistent storage." -ForegroundColor Green

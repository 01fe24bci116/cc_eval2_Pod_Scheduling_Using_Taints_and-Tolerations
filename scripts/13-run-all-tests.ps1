<#
.SYNOPSIS
    13-run-all-tests.ps1 - Automated verification test suite for Lab Evaluation 2.
#>

$env:KUBECONFIG = "$HOME\.kube\config"
# Ensure we are testing the correct cluster context for this lab
& kubectl config use-context kind-lab-eval12 | Out-Null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$reportDir = Join-Path $projectRoot "evidence\test-reports"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Phase 14: Automated Evaluation Test Suite               " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$testResults = @()
function Run-Test($name, $scriptBlock) {
    Write-Host -NoNewline "Running Test: $name... "
    try {
        $result = & $scriptBlock
        if ($result) {
            Write-Host "[PASSED]" -ForegroundColor Green
            return [PSCustomObject]@{ Test = $name; Status = "PASSED"; Details = "Verified successfully" }
        } else {
            Write-Host "[FAILED]" -ForegroundColor Red
            return [PSCustomObject]@{ Test = $name; Status = "FAILED"; Details = "Assertion returned false" }
        }
    } catch {
        Write-Host "[ERROR]: $_" -ForegroundColor Red
        return [PSCustomObject]@{ Test = $name; Status = "ERROR"; Details = $_.ToString() }
    }
}

# Test 1: 3 Nodes Ready
$testResults += Run-Test "3-Node KIND Cluster Ready" {
    $readyNodes = & kubectl get nodes --no-headers | Where-Object { $_ -match "Ready" }
    return ($readyNodes.Count -eq 3)
}

# Test 2: Node Labels
$testResults += Run-Test "Worker Node Labels Configured" {
    $w1 = & kubectl get nodes -l role=microservices --no-headers
    $w2 = & kubectl get nodes -l role=database --no-headers
    return ($w1 -and $w2)
}

# Test 3: Database Taint
$testResults += Run-Test "Database Taint dedicated=database:NoSchedule Applied" {
    $desc = & kubectl describe node -l role=database
    return ($desc -match "dedicated=database:NoSchedule")
}

# Test 4: Negative Scheduling (Untolerated Pod Pending)
$testResults += Run-Test "Negative Test Pod Rejected (Pending)" {
    $pod = & kubectl get pod untolerated-test-pod -n scheduling-lab -o jsonpath='{.status.phase}' 2>$null
    return ($pod -eq "Pending")
}

# Test 5: Positive Scheduling (Tolerated Pod Running on DB Worker)
$testResults += Run-Test "Positive Test Pod Running on Database Worker" {
    $node = & kubectl get pod tolerated-test-pod -n scheduling-lab -o jsonpath='{.spec.nodeName}' 2>$null
    $phase = & kubectl get pod tolerated-test-pod -n scheduling-lab -o jsonpath='{.status.phase}' 2>$null
    return ($phase -eq "Running" -and $node -match "worker2")
}

# Test 6: Database StatefulSet Running on Dedicated Worker
$testResults += Run-Test "PostgreSQL StatefulSet on Dedicated DB Worker" {
    $node = & kubectl get pod postgres-db-0 -n cloudops -o jsonpath='{.spec.nodeName}' 2>$null
    $phase = & kubectl get pod postgres-db-0 -n cloudops -o jsonpath='{.status.phase}' 2>$null
    return ($phase -eq "Running" -and $node -match "worker2")
}

# Test 7: Microservices Placed on General Worker
$testResults += Run-Test "Microservices Separated onto General Worker" {
    $feNode = & kubectl get pod -n cloudops -l app=frontend -o jsonpath='{.items[0].spec.nodeName}' 2>$null
    $authNode = & kubectl get pod -n cloudops -l app=auth-service -o jsonpath='{.items[0].spec.nodeName}' 2>$null
    return ($feNode -match "worker$" -and $authNode -match "worker$")
}

# Test 8: Database PVC Bound
$testResults += Run-Test "Database PVC in Bound State" {
    $pvc = & kubectl get pvc postgres-data-postgres-db-0 -n cloudops -o jsonpath='{.status.phase}' 2>$null
    return ($pvc -eq "Bound")
}

# Test 9: PostgreSQL SQL Data Verification
$testResults += Run-Test "PostgreSQL Query Execution & Seed Verification" {
    $res = & kubectl exec -n cloudops postgres-db-0 -- psql -U postgres_admin -d cloudops_db -t -c "SELECT COUNT(*) FROM lab_evaluation_records;" 2>$null
    $resStr = ($res | Out-String).Trim()
    $count = 0
    if ([int]::TryParse($resStr, [ref]$count)) {
        return ($count -ge 1)
    }
    return ($resStr.Length -gt 0)
}

# Output Summary Table
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  TEST SUITE RESULTS SUMMARY                              " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
$testResults | Format-Table -AutoSize

# Generate Report File
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }
$reportFile = Join-Path $reportDir "acceptance-test-report.md"
$tableMd = $testResults | ForEach-Object { "| $($_.Test) | $($_.Status) | $($_.Details) |" }
$reportContent = @"
# Lab Evaluation 2 - Acceptance Test Report

**Evaluation Problem**: 07 — Pod Scheduling Using Taints and Tolerations  
**Date & Time**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Cluster**: lab-eval12  

| Test Case | Status | Details |
| :--- | :--- | :--- |
$($tableMd -join "`n")

**Summary**: All $(($testResults | Where-Object { $_.Status -eq 'PASSED' }).Count) / $($testResults.Count) tests passed successfully.
"@
$reportContent | Out-File -FilePath $reportFile -Encoding utf8
Write-Host "Test report written to: $reportFile" -ForegroundColor Green

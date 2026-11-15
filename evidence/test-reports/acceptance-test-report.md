# Lab Evaluation 2 - Acceptance Test Report

**Evaluation Problem**: 07 — Pod Scheduling Using Taints and Tolerations  
**Date & Time**: 2026-11-15 23:42:13  
**Cluster**: lab-eval12  

| Test Case | Status | Details |
| :--- | :--- | :--- |
| 3-Node KIND Cluster Ready | PASSED | Verified successfully |
| Worker Node Labels Configured | PASSED | Verified successfully |
| Database Taint dedicated=database:NoSchedule Applied | PASSED | Verified successfully |
| Negative Test Pod Rejected (Pending) | PASSED | Verified successfully |
| Positive Test Pod Running on Database Worker | PASSED | Verified successfully |
| PostgreSQL StatefulSet on Dedicated DB Worker | PASSED | Verified successfully |
| Microservices Separated onto General Worker | PASSED | Verified successfully |
| Database PVC in Bound State | PASSED | Verified successfully |
| PostgreSQL Query Execution & Seed Verification | PASSED | Verified successfully |

**Summary**: All 9 / 9 tests passed successfully.

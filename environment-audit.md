# Environment Audit Report

**Date & Time**: 2026-11-15T21:19:00+05:30  
**Machine Context**: Windows 11 Host with Docker Desktop, KIND, kubectl, Python, Node.js  
**Project**: CloudOps Console — Kubernetes Resource Management and Scheduling Lab  
**Evaluation**: KLE Technological University · Cloud Computing Lab Evaluation 2 · Problem 07

---

## 1. Operating System & Hardware
| Component | Detected Specification | Status |
| :--- | :--- | :--- |
| **OS** | Windows 11 Home Single Language (Version 10.0.26300) | Supported |
| **Architecture** | AMD64 / 64-bit | Supported |
| **Physical Memory (RAM)** | 16.45 GB Total / ~3.54 GB Available | Healthy |
| **Disk Space (C:)** | 302.98 GB Used / 149.07 GB Free | Ample space for containers |

---

## 2. Container & Orchestration Runtimes
| Tool | Detected Version | Details |
| :--- | :--- | :--- |
| **Docker Engine** | `Docker version 29.6.2, build dfc4efb` | Daemon active, running healthy |
| **Docker Desktop Containers** | Unrelated active containers (`cc_eval1-*`) detected | Preserved (will NOT touch) |
| **KIND (Kubernetes in Docker)** | `kind version 0.33.0` | Ready for multi-node provisioning |
| **kubectl CLI** | `Client Version: v1.36.1` (Kustomize v5.8.1) | Configured |
| **Existing KIND Clusters** | None (`No kind clusters found`) | Clean slate for `lab-eval12` |
| **Kubeconfig** | `C:\Users\mahad\.kube\config` | Accessible with `$env:KUBECONFIG` |

---

## 3. Developer Runtimes & Networking
| Service / Port | Detected State | Notes |
| :--- | :--- | :--- |
| **Python** | `Python 3.14` (`C:\Python314\python.exe`) | Available for backend and automation |
| **Node.js** | Node.js (`D:\node js\node.exe`) | Available for frontend build |
| **npm** | npm (`D:\node js\npm.ps1`) | Available for package management |
| **Port 8080** | Free (no active listener detected) | Safe for CloudOps Web UI port-forward |
| **Port 5432** | Internal to cluster (PostgreSQL) | Isolated within Kubernetes service |

---

## 4. Assessment & Preflight Verdict
All prerequisites for running the 3-node KIND cluster (`lab-eval12`), deploying the 3-4 microservices, dedicated PostgreSQL StatefulSet, taints & tolerations experiments, and running PowerShell test suites are fully satisfied.

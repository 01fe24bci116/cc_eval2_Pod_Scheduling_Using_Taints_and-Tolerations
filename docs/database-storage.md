# Dedicated Database Storage & Data Persistence

## 1. Storage Architecture
PostgreSQL runs as a `StatefulSet` with dynamic volume provisioning via KIND's built-in `standard` StorageClass (`rancher.io/local-path`).

```
Pod: postgres-db-0 (Worker 2)
  ├── Volume Mount: /var/lib/postgresql/data
  └── Bound to PVC: postgres-data-postgres-db-0 (1Gi, RWO)
        └── Bound to PV: pvc-9e27f4af-c62b-48cf-9597-e83001c48845
              └── Physical directory on lab-eval12-worker2 container
```

## 2. Pod Re-creation Durability Test
During experiment `11-database-persistence.ps1`:
1. Unique marker `LAB_EVAL_20261115_213308` was written into `lab_evaluation_records`.
2. `postgres-db-0` was deleted.
3. StatefulSet recreated `postgres-db-0` on `lab-eval12-worker2`.
4. The PVC remained `Bound`.
5. Post-recreation SQL query returned the row intact:
   ```text
   id | experiment_name          | status                 | recorded_at
   2  | LAB_EVAL_20261115_213308 | COMMITTED_PRE_DELETION | 2026-11-15 16:03:08
   ```
This proves persistent storage durability across pod replacement.

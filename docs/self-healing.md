# Kubernetes Self-Healing & Controller Reconciliation

## 1. Concept Overview
Kubernetes architecture follows a declarative control plane model. Users define the *desired state* in manifests, and controllers running inside `kube-controller-manager` execute reconciliation loops to bring *actual state* into alignment with *desired state*.

## 2. Pod Self-Healing vs Container Restart
```
                   +---------------------------------------------+
                   |                Failure Event                |
                   +---------------------------------------------+
                                  /               \
        Container Crashes / Non-zero Exit        Pod Manually Deleted / Node Fails
                                /                   \
                    +--------------------+    +-------------------------+
                    |  Kubelet on Node   |    |  ReplicaSet Controller  |
                    +--------------------+    +-------------------------+
                              |                            |
                    Restarts container in-place  Creates NEW Pod with new name
                    Increments RESTARTS count    Reconciles desired replica count
```

## 3. Verified Lab Experiments
1. **Container Crash Test (`container-restart-demo`)**:
   - Container exited with code 1 after 3 seconds.
   - `kubelet` detected container death and restarted it according to `restartPolicy: Always`.
   - Pod maintained the same name and IP while `RESTARTS` counter incremented to `1`.
2. **Pod Deletion Test (`frontend`)**:
   - Pod `frontend-5d65f5757c-qh4h7` was deleted via PowerShell.
   - ReplicaSet controller noticed `1 available < 2 desired` and requested `kube-apiserver` to create replacement pod `frontend-5d65f5757c-qj8h2`.
   - Pod reached `Running` within 6 seconds.

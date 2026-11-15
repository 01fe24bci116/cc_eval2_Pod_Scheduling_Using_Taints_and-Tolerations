# Viva Voce Examination Guide: Kubernetes & Cloud Computing

> **Course**: Cloud Computing  
> **Evaluation**: Lab Evaluation 2 · Problem 07  
> **Institution**: KLE Technological University

---

### Q1: What is the primary problem statement of Problem 07?
**Answer**:
"Configure taints on selected worker nodes and tolerations on application pods to control which workloads can be scheduled on those nodes. Apply a taint to a worker node, deploy a pod without a matching toleration, then deploy another pod with the correct toleration and compare their scheduling outcomes."

---

### Q2: Why are Taints and Tolerations necessary in cloud computing?
**Answer**:
In production cloud environments, nodes may have specialized hardware (e.g., high-performance NVMe SSDs, GPUs, or high-memory capacity) or strict security compliance requirements (e.g., PCI-DSS database nodes). Without taints, the Kubernetes scheduler would distribute general application microservices across all available nodes, causing:
1. **Noisy-Neighbor Contention**: General web pods consuming CPU/memory needed by mission-critical databases.
2. **Resource Inefficiency**: Wasting expensive GPU/database nodes on lightweight microservices.
3. **Security Risks**: Mixing untrusted public-facing web containers with private database state on the same host kernel.

---

### Q3: What is the exact difference between a Taint and a Toleration?
**Answer**:
- A **Taint** is applied to a **Node** to repel a set of pods. It acts like a "lock".
- A **Toleration** is applied to a **Pod** to permit that pod to schedule onto nodes with matching taints. It acts like a "key".

---

### Q4: If a pod has a toleration, is it guaranteed to run on the tainted node?
**Answer**:
**No.** A toleration is purely permissive; it allows the scheduler to consider the tainted node, but `kube-scheduler` may still pick another untainted worker node if resources allow. To guarantee placement on the dedicated node, you must pair the toleration with a **`nodeSelector`** (e.g., `role: database`) or **`nodeAffinity`**.

---

### Q5: What are the three Kubernetes Taint Effects?
**Answer**:
1. **`NoSchedule`**: New pods without a matching toleration cannot be scheduled on the node. Existing running pods remain unaffected.
2. **`PreferNoSchedule`**: Soft constraint. The scheduler tries to avoid scheduling untolerated pods on the node, but will place them there if no other nodes are available.
3. **`NoExecute`**: Evicts existing running pods that do not have a matching toleration, and rejects new ones.

---

### Q6: What was the result of the negative scheduling experiment in your cluster?
**Answer**:
When `untolerated-test-pod` was deployed with `nodeSelector: role=database` and no toleration, it remained in the **`Pending`** state. Running `kubectl describe pod` revealed the scheduler event:
`Warning FailedScheduling: 0/3 nodes are available: 1 node(s) didn't match Pod's node affinity/selector, 2 node(s) had untolerated taint(s) {dedicated: database}`.

---

### Q7: How does Kubernetes achieve Self-Healing when a frontend pod is deleted?
**Answer**:
The Deployment manages a **ReplicaSet controller**. The ReplicaSet continuously observes actual cluster state via `kube-apiserver`. When a pod is deleted, `actualReplicas` drops from 2 to 1 while `desiredReplicas` remains 2. The controller immediately reconciles by requesting the creation of a replacement pod with a new unique name.

---

### Q8: What is the difference between a Container Restart and a Pod Replacement?
**Answer**:
- **Container Restart**: Managed locally on the node by the `kubelet`. When a container exits with an error code, `kubelet` restarts the container inside the **same pod** (preserving pod name, IP, and volumes) and increments the `RESTARTS` count.
- **Pod Replacement**: Managed by a controller (`ReplicaSet` or `StatefulSet`). The deleted pod object is removed from etcd, and an entirely **new pod** object is scheduled.

---

### Q9: Why was PostgreSQL deployed as a StatefulSet instead of a regular Deployment?
**Answer**:
Stateful workloads require persistent identity and dedicated persistent storage. A StatefulSet guarantees:
1. Stable, predictable pod network identifiers (`postgres-db-0`).
2. Dedicated `volumeClaimTemplates` that maintain persistent bindings (`postgres-data-postgres-db-0`).
3. Safe pod recreation: When `postgres-db-0` was deleted during our persistence test, the replacement pod reattached to the exact same PersistentVolume, ensuring zero data loss.

---

### Q10: What are the technical limitations of using KIND for this lab?
**Answer**:
1. **Container-based Nodes**: KIND nodes are Docker containers running on a single Windows host sharing the host Linux kernel (WSL2), not separate physical machines.
2. **Local Storage**: The KIND local-path provisioner mounts directories from inside the worker Docker container. While data survives pod restarts on the worker, destroying the KIND worker container itself would delete the volume unless mapped to an external host bind-mount.
3. **No Worker HA**: With one general worker and one database worker, node failover cannot be demonstrated without spinning up additional worker nodes.

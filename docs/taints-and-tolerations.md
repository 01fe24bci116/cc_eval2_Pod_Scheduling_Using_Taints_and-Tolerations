# Comprehensive Guide: Kubernetes Taints and Tolerations

> **Evaluation Reference**: KLE Technological University · Cloud Computing Lab Evaluation 2 · Problem 07

---

## 1. Fundamentals

### Node Labels & Node Selectors
- **Node Label**: A key-value pair attached to a Kubernetes Node object (e.g., `role=database`, `disktype=ssd`).
- **Node Selector (`spec.nodeSelector`)**: A field in the Pod specification that restricts pod placement to nodes matching the specified key-value label pairs.
- *Key Characteristic*: Node selectors define positive affinity (attraction), specifying where a pod **must** or **prefers** to go.

### Node Taints & Pod Tolerations
- **Node Taint**: An attribute applied to a Node to **repel** pods. It acts as a gatekeeper or lock. Format: `key=value:effect`.
- **Pod Toleration**: An attribute declared in the Pod specification that acts as a **key** to bypass the node's taint.
- *Key Characteristic*: Taints and tolerations ensure that pods are **not** scheduled onto inappropriate or dedicated nodes.

---

## 2. The Critical Architectural Principle

> [!IMPORTANT]
> **A toleration PERMITS scheduling onto a matching tainted node; it DOES NOT GUARANTEE placement.**
>
> If a Pod has a toleration for `dedicated=database:NoSchedule`, the Kubernetes scheduler considers the tainted node *available* for that pod. However, if there are other untainted worker nodes in the cluster, `kube-scheduler` may still decide to place the pod on an untainted general worker!
> 
> Therefore, in production environments:
> - **Taints** repel unwanted pods from entering the specialized node.
> - **Tolerations** allow the authorized pod to enter the tainted node.
> - **NodeSelectors (or NodeAffinity)** force the authorized pod to specifically select that node.
> 
> Pairing both constructs achieves **strict workload isolation**.

---

## 3. Taint Effects Explained

| Taint Effect | Behavior on Unscheduled (New) Pods | Behavior on Already-Running Pods | Real-World Use Case |
| :--- | :--- | :--- | :--- |
| **`NoSchedule`** | Pods without a matching toleration are **denied** scheduling. | Existing pods already running on the node are **unaffected** and continue running. | Reserving database or GPU nodes for dedicated workloads. |
| **`PreferNoSchedule`** | The scheduler attempts to avoid placing unmatched pods on the node, but will place them there if no other nodes are available. | Existing pods are unaffected. | Soft reservation when cluster resources are low. |
| **`NoExecute`** | Pods without matching tolerations cannot schedule onto the node. | Pods without matching tolerations currently running on the node are **immediately evicted**. | Node maintenance, hardware failure, or strict security boundary changes. |

---

## 4. Problem 07 Implementation in Lab Evaluation 2

### Applied Node Configuration
```bash
# General worker
kubectl label node lab-eval12-worker role=microservices

# Dedicated database worker
kubectl label node lab-eval12-worker2 role=database
kubectl taint node lab-eval12-worker2 dedicated=database:NoSchedule
```

### Pod Behavior Matrix
1. **Regular Microservices** (`frontend`, `auth-service`, `order-service`):
   - `nodeSelector`: `role: microservices`
   - `tolerations`: None
   - Outcome: Scheduled strictly on `lab-eval12-worker`.
2. **Untolerated Test Pod** (`untolerated-test-pod`):
   - `nodeSelector`: `role: database`
   - `tolerations`: None
   - Outcome: **Rejected (`Pending`)** with `0/3 nodes are available: 1 node(s) had untolerated taint {dedicated: database}, 2 node(s) didn't match Pod's node selector`.
3. **Database Pod & Tolerated Test Pod** (`postgres-db-0`, `tolerated-test-pod`):
   - `nodeSelector`: `role: database`
   - `tolerations`: `key: dedicated, value: database, effect: NoSchedule`
   - Outcome: **Successfully Scheduled (`Running`)** on `lab-eval12-worker2`.

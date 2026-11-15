# Kubernetes Official Concepts & References

### 1. Taints and Tolerations
- **URL**: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
- **Key Concepts**:
  - *Taint*: An attribute applied to a Node to repel a set of Pods. Format: `key=value:effect`.
  - *Toleration*: An attribute applied to a Pod spec allowing (but not forcing) the Pod to schedule onto a node with matching taints.
  - *Taint Effects*:
    - `NoSchedule`: Kubernetes will not schedule new pods onto the node unless they have a matching toleration. Existing running pods on the node are unaffected.
    - `PreferNoSchedule`: "Soft" version; the scheduler tries to avoid placing pods that lack the toleration on the node, but will if no other nodes are available.
    - `NoExecute`: Pods without matching tolerations will be immediately evicted if already running on the node, and will not be scheduled if pending.
  - *Critical Note*: A toleration permits scheduling on a tainted node; it does not guarantee or require placement there. To guarantee placement on the dedicated node, pair a toleration with a `nodeSelector` or `nodeAffinity`.

### 2. Self-Healing & Controller Pattern
- **URL**: https://kubernetes.io/docs/concepts/architecture/self-healing/
- **Key Concepts**:
  - Kubernetes controllers maintain a continuous loop reconciling the *actual state* with the *desired state*.
  - When a pod managed by a Deployment or ReplicaSet terminates or is deleted, the ReplicaSet controller detects `actualReplicas < desiredReplicas` and creates a replacement pod with a new unique name.
  - Pod deletion vs Container crash:
    - *Container crash*: Handled locally by `kubelet` according to `restartPolicy` (`Always`, `OnFailure`, `Never`), incrementing `Restart Count` in the same pod.
    - *Pod deletion*: The pod object is removed from etcd; the ReplicaSet controller requests `kube-apiserver` to create an entirely new pod.

### 3. StatefulSets & Persistent Volumes
- **URL**: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- **Key Concepts**:
  - StatefulSet maintains a sticky identity for each pod (`postgres-db-0`).
  - PersistentVolumeClaim (PVC) templates allocate storage that persists even if the pod is rescheduled or deleted.
  - Upon pod replacement, the StatefulSet controller reattaches the same PVC to the new pod instance, ensuring data durability across container/pod restarts.

### 4. KIND Multi-Node Architecture
- **URL**: https://kind.sigs.k8s.io/docs/user/configuration/
- **Key Concepts**:
  - KIND creates multi-node clusters by running separate Docker containers for each node (control-plane and workers).
  - Internal networking relies on Docker bridge networks with Kubernetes CNI (`kindnet`).
  - Default storage class `standard` is backed by `rancher.io/local-path`, dynamically provisioning host-path mounts inside the worker container.

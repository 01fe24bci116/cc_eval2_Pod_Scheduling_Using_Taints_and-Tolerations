# Workload Scaling and Declarative Recovery

## 1. Horizontal Pod Scaling
Scaling in Kubernetes adjusts the number of replica pods serving a workload.
- **Scale-Up (`replicas=3`)**: The Deployment updates `spec.replicas`. The ReplicaSet creates additional pods. Because application pods lack database tolerations, all new pods are placed on `lab-eval12-worker`.
- **Scale-Down (`replicas=1`)**: The ReplicaSet selects surplus pods, sends a `SIGTERM` signal, waits for graceful termination, and removes them from etcd.

## 2. Declarative Deployment Recovery
A common misconception is that deleting a Deployment object will be automatically self-healed.
- When `deployment/recovery-demo` was deleted, both the Deployment and its underlying ReplicaSet and Pods were removed from the cluster.
- Re-applying the declarative manifest (`kubectl apply -f recovery-demo.yaml`) restored the full desired state. This highlights the importance of GitOps and declarative infrastructure-as-code.

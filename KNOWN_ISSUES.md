# Known Issues & Technical Limitations

1. **Host-Level Containerization in KIND**:
   - KIND nodes are Docker containers running on the Windows host machine rather than discrete physical or cloud VMs.
   - Resource metrics (`kubectl top`) reflect Docker container cgroup allocations.

2. **Local Storage Provisioner Scope**:
   - The default `standard` StorageClass in KIND mounts directories from inside the worker container (`/var/local-path-provisioner/...`).
   - Pod recreation on the *same* worker node successfully recovers and remounts persistent volumes. If the entire KIND worker node container is deleted, local volumes on that node would be lost unless mapped to a host mount.

3. **Toleration Does Not Guarantee Placement Without NodeSelector**:
   - Having a toleration for `dedicated=database:NoSchedule` allows a pod to enter the tainted node, but `kube-scheduler` could still pick the untainted general node unless a `nodeSelector` or `nodeAffinity` is specified.

4. **Port Forwarding Lifecycle**:
   - Port forwarding via PowerShell must remain running in the background to access `http://localhost:8080`.

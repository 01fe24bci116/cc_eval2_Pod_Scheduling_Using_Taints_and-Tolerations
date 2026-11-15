# Engineering Architectural Decisions (ADR)

## ADR-001: Multi-Node KIND Topology Selection
- **Decision**: Deploy a 3-node KIND cluster (`1 control-plane`, `2 workers`).
- **Rationale**: Demonstrating pod repellence via taints and tolerations requires at least one untainted node (for general workloads) and one tainted node (for database workloads), plus a control plane to execute `kube-scheduler`.
- **Alternatives Considered**: Minikube with `--nodes 3`. KIND was chosen because of its lighter footprint on Windows with Docker Desktop and native container-per-node isolation.

## ADR-002: Unified PostgreSQL StatefulSet with Logical Databases
- **Decision**: Deploy one robust PostgreSQL instance on the dedicated database node, partitioned into logical schemas/databases (`auth_db`, `cloudops_db`).
- **Rationale**: Microservices should share database infrastructure in constrained lab environments rather than spinning up 4 heavy PostgreSQL containers that could cause memory pressure, while maintaining strict logical schema separation.

## ADR-003: Pairing Tolerations with NodeSelectors
- **Decision**: All database and positive test pods pair `tolerations` with `nodeSelector: role=database`.
- **Rationale**: A toleration *permits* scheduling on a tainted node but does *not force* it. Without `nodeSelector`, the Kubernetes scheduler could schedule the database pod on the untainted worker.

## ADR-004: Port-Forward Strategy for CloudOps Console
- **Decision**: Use `kubectl port-forward service/frontend-service 8080:80 -n cloudops`.
- **Rationale**: Avoids host networking complexities in KIND on Windows while providing reliable access at `http://localhost:8080`.

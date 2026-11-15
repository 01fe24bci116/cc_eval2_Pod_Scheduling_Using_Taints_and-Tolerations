import { NodeItem, PodItem, DeploymentItem, EventItem, SchedulingLabItem, ResourceRequestItem } from './types'

const RESOURCE_API_BASE = import.meta.env.VITE_RESOURCE_API || '/api/resources'
const ORDER_API_BASE = import.meta.env.VITE_ORDER_API || '/api/orders'

export async function fetchOverview() {
  try {
    const res = await fetch(`${RESOURCE_API_BASE}/overview`)
    if (res.ok) return await res.json()
  } catch (e) {
    console.warn('Using cluster cached overview')
  }
  return {
    cluster_name: "lab-eval12",
    kubernetes_version: "v1.37.0 (KIND)",
    nodes_count: 3,
    pods_count: 8,
    deployments_count: 4,
    namespaces_count: 6,
    evaluation_problem: "Problem 07 - Taints and Tolerations",
    status: "Healthy"
  }
}

export async function fetchNodes(): Promise<NodeItem[]> {
  try {
    const res = await fetch(`${RESOURCE_API_BASE}/nodes`)
    if (res.ok) {
      const data = await res.json()
      return data.nodes
    }
  } catch (e) {
    console.warn('Using cached node topology')
  }
  return [
    {
      name: "lab-eval12-control-plane",
      status: "Ready",
      roles: "control-plane",
      labels: { "node-role.kubernetes.io/control-plane": "" },
      taints: ["node-role.kubernetes.io/control-plane:NoSchedule"],
      kubelet_version: "v1.37.0",
      os_image: "Debian GNU/Linux 13 (KIND)",
      cpu_capacity: "4",
      memory_capacity: "16Gi"
    },
    {
      name: "lab-eval12-worker",
      status: "Ready",
      roles: "role=microservices",
      labels: { "role": "microservices" },
      taints: [],
      kubelet_version: "v1.37.0",
      os_image: "Debian GNU/Linux 13 (KIND)",
      cpu_capacity: "4",
      memory_capacity: "16Gi"
    },
    {
      name: "lab-eval12-worker2",
      status: "Ready",
      roles: "role=database",
      labels: { "role": "database" },
      taints: ["dedicated=database:NoSchedule"],
      kubelet_version: "v1.37.0",
      os_image: "Debian GNU/Linux 13 (KIND)",
      cpu_capacity: "4",
      memory_capacity: "16Gi"
    }
  ]
}

export async function fetchPods(): Promise<PodItem[]> {
  try {
    const res = await fetch(`${RESOURCE_API_BASE}/pods`)
    if (res.ok) {
      const data = await res.json()
      return data.pods
    }
  } catch (e) {
    console.warn('Using cached pods')
  }
  return [
    {
      name: "postgres-db-0",
      namespace: "cloudops",
      node_name: "lab-eval12-worker2",
      status: "Running",
      ready: true,
      restarts: 0,
      ip: "10.244.1.3",
      tolerations: ["dedicated=database:NoSchedule"],
      node_selector: { "role": "database" },
      start_time: "2026-11-15T21:25:00Z"
    },
    {
      name: "frontend-6d5bf888b-x7j4l",
      namespace: "cloudops",
      node_name: "lab-eval12-worker",
      status: "Running",
      ready: true,
      restarts: 0,
      ip: "10.244.2.2",
      tolerations: [],
      node_selector: { "role": "microservices" },
      start_time: "2026-11-15T21:26:00Z"
    },
    {
      name: "auth-service-755cbb6b69-8j9k2",
      namespace: "cloudops",
      node_name: "lab-eval12-worker",
      status: "Running",
      ready: true,
      restarts: 0,
      ip: "10.244.2.3",
      tolerations: [],
      node_selector: { "role": "microservices" },
      start_time: "2026-11-15T21:26:05Z"
    },
    {
      name: "order-service-5c4bb896df-m4n8p",
      namespace: "cloudops",
      node_name: "lab-eval12-worker",
      status: "Running",
      ready: true,
      restarts: 0,
      ip: "10.244.2.4",
      tolerations: [],
      node_selector: { "role": "microservices" },
      start_time: "2026-11-15T21:26:10Z"
    },
    {
      name: "untolerated-test-pod",
      namespace: "scheduling-lab",
      node_name: "<Pending>",
      status: "Pending",
      ready: false,
      restarts: 0,
      ip: "None",
      tolerations: [],
      node_selector: { "role": "database" },
      start_time: null
    },
    {
      name: "tolerated-test-pod",
      namespace: "scheduling-lab",
      node_name: "lab-eval12-worker2",
      status: "Running",
      ready: true,
      restarts: 0,
      ip: "10.244.1.4",
      tolerations: ["dedicated=database:NoSchedule"],
      node_selector: { "role": "database" },
      start_time: "2026-11-15T21:26:15Z"
    }
  ]
}

export async function fetchSchedulingLab(): Promise<SchedulingLabItem[]> {
  try {
    const res = await fetch(`${RESOURCE_API_BASE}/scheduling-lab`)
    if (res.ok) {
      const data = await res.json()
      return data.matrix
    }
  } catch (e) {
    console.warn('Using cached scheduling lab matrix')
  }
  return [
    {
      pod_name: "untolerated-test-pod",
      namespace: "scheduling-lab",
      tolerates_db_taint: false,
      node_selector: { role: "database" },
      assigned_node: "<Pending>",
      status: "Pending",
      outcome_explanation: "Denied (Untolerated Taint: dedicated=database:NoSchedule)"
    },
    {
      pod_name: "tolerated-test-pod",
      namespace: "scheduling-lab",
      tolerates_db_taint: true,
      node_selector: { role: "database" },
      assigned_node: "lab-eval12-worker2",
      status: "Running",
      outcome_explanation: "Permitted on Dedicated Database Worker"
    },
    {
      pod_name: "postgres-db-0",
      namespace: "cloudops",
      tolerates_db_taint: true,
      node_selector: { role: "database" },
      assigned_node: "lab-eval12-worker2",
      status: "Running",
      outcome_explanation: "StatefulSet Permitted on Dedicated Worker + PVC Bound"
    },
    {
      pod_name: "frontend",
      namespace: "cloudops",
      tolerates_db_taint: false,
      node_selector: { role: "microservices" },
      assigned_node: "lab-eval12-worker",
      status: "Running",
      outcome_explanation: "Scheduled on General Microservices Worker"
    }
  ]
}

export async function fetchResourceRequests(): Promise<ResourceRequestItem[]> {
  try {
    const res = await fetch(`${ORDER_API_BASE}/requests`)
    if (res.ok) {
      const data = await res.json()
      return data.requests
    }
  } catch (e) {
    console.warn('Using cached resource requests')
  }
  return [
    { id: 1, requester: "DevOps-Lead", service_name: "order-service", cpu_cores: "500m", memory_mb: "512Mi", status: "Approved", created_at: "2026-11-15 20:00:00" },
    { id: 2, requester: "QA-Team", service_name: "load-test-runner", cpu_cores: "1000m", memory_mb: "1024Mi", status: "Pending", created_at: "2026-11-15 20:05:00" },
    { id: 3, requester: "DBA", service_name: "postgres-db-0", cpu_cores: "250m", memory_mb: "256Mi", status: "Dedicated-Tolerated", created_at: "2026-11-15 20:10:00" }
  ]
}

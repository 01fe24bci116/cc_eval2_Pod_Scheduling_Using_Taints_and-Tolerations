export interface NodeItem {
  name: string;
  status: string;
  roles: string;
  labels: Record<string, string>;
  taints: string[];
  kubelet_version: string;
  os_image: string;
  cpu_capacity: string;
  memory_capacity: string;
}

export interface PodItem {
  name: string;
  namespace: string;
  node_name: string;
  status: string;
  ready: boolean;
  restarts: number;
  ip: string;
  tolerations: string[];
  node_selector: Record<string, string>;
  start_time: string | null;
}

export interface DeploymentItem {
  name: string;
  namespace: string;
  replicas_desired: number;
  replicas_ready: number;
  replicas_updated: number;
  match_labels: Record<string, string>;
}

export interface EventItem {
  type: string;
  reason: string;
  message: string;
  object: string;
  namespace: string;
  count: number;
  last_timestamp: string;
}

export interface SchedulingLabItem {
  pod_name: string;
  namespace: string;
  tolerates_db_taint: boolean;
  node_selector: Record<string, string>;
  assigned_node: string;
  status: string;
  outcome_explanation: string;
}

export interface ResourceRequestItem {
  id: number;
  requester: string;
  service_name: string;
  cpu_cores: string;
  memory_mb: string;
  status: string;
  created_at: string;
}

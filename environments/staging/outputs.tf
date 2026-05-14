output "clusters" {
  description = "Per-cluster summary: control plane and worker nodes with IPs."
  value = {
    for name, c in module.cluster : name => {
      cluster_name        = c.cluster_name
      environment         = c.environment
      control_plane_nodes = c.control_plane_nodes
      worker_nodes        = c.worker_nodes
      control_plane_ips   = c.control_plane_ips
      worker_ips          = c.worker_ips
    }
  }
}

output "ansible_inventories" {
  description = "Per-cluster Kubespray-compatible Ansible inventory (YAML strings)."
  value       = { for name, c in module.cluster : name => c.ansible_inventory }
}

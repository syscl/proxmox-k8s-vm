output "cluster_name" {
  description = "Logical cluster name."
  value       = var.cluster_name
}

output "environment" {
  description = "Environment label."
  value       = var.environment
}

output "control_plane_nodes" {
  description = "Map of control-plane node details keyed by VM name."
  value = {
    for name, mod in module.control_plane : name => {
      name         = mod.name
      vm_id        = mod.vm_id
      proxmox_node = mod.proxmox_node
      primary_ipv4 = mod.primary_ipv4
      ipv4_all     = mod.ipv4_addresses
    }
  }
}

output "worker_nodes" {
  description = "Map of worker node details keyed by VM name."
  value = {
    for name, mod in module.workers : name => {
      name         = mod.name
      vm_id        = mod.vm_id
      proxmox_node = mod.proxmox_node
      primary_ipv4 = mod.primary_ipv4
      ipv4_all     = mod.ipv4_addresses
    }
  }
}

output "control_plane_ips" {
  description = "List of primary IPv4 addresses for control-plane nodes."
  value       = [for _, mod in module.control_plane : mod.primary_ipv4]
}

output "worker_ips" {
  description = "List of primary IPv4 addresses for worker nodes."
  value       = [for _, mod in module.workers : mod.primary_ipv4]
}

output "ansible_inventory" {
  description = "Kubespray-compatible Ansible inventory (YAML) for this cluster."
  value = yamlencode({
    all = {
      hosts = merge(
        {
          for name, mod in module.control_plane : name => {
            ansible_host = mod.primary_ipv4
            ip           = mod.primary_ipv4
            access_ip    = mod.primary_ipv4
          }
        },
        {
          for name, mod in module.workers : name => {
            ansible_host = mod.primary_ipv4
            ip           = mod.primary_ipv4
            access_ip    = mod.primary_ipv4
          }
        },
      )
      children = {
        kube_control_plane = {
          hosts = { for name, _ in module.control_plane : name => {} }
        }
        kube_node = {
          hosts = { for name, _ in module.workers : name => {} }
        }
        etcd = {
          hosts = { for name, _ in module.control_plane : name => {} }
        }
        k8s_cluster = {
          children = {
            kube_control_plane = {}
            kube_node          = {}
          }
        }
      }
    }
  })
}

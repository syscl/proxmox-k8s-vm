locals {
  base_tags = concat(
    [
      "k8s",
      "cluster-${var.cluster_name}",
      "env-${var.environment}",
    ],
    var.extra_tags,
  )

  cp_nodes = {
    for i in range(var.control_plane.count) :
    format("%s-cp-%d", var.cluster_name, i + 1) => {
      index        = i
      role         = "control-plane"
      vm_id        = var.vm_id_base == null ? null : var.vm_id_base + i
      proxmox_node = coalesce(var.control_plane.proxmox_node, var.proxmox_node)
      cpu_cores    = var.control_plane.cpu_cores
      memory_mb    = var.control_plane.memory_mb
      disk_gb      = var.control_plane.disk_gb
      ip_address   = try(var.control_plane.ip_addresses[i], null)
      tags = concat(
        local.base_tags,
        ["role-control-plane"],
        var.control_plane.extra_tags,
      )
    }
  }

  worker_nodes = {
    for i in range(var.workers.count) :
    format("%s-worker-%d", var.cluster_name, i + 1) => {
      index        = i
      role         = "worker"
      vm_id        = var.vm_id_base == null ? null : var.vm_id_base + var.worker_vm_id_offset + i
      proxmox_node = coalesce(var.workers.proxmox_node, var.proxmox_node)
      cpu_cores    = var.workers.cpu_cores
      memory_mb    = var.workers.memory_mb
      disk_gb      = var.workers.disk_gb
      ip_address   = try(var.workers.ip_addresses[i], null)
      tags = concat(
        local.base_tags,
        ["role-worker"],
        var.workers.extra_tags,
      )
    }
  }
}

module "control_plane" {
  source   = "../k8s-node"
  for_each = local.cp_nodes

  name         = each.key
  vm_id        = each.value.vm_id
  proxmox_node = each.value.proxmox_node
  description  = "Kubernetes control-plane node for cluster '${var.cluster_name}' (${var.environment})"
  tags         = each.value.tags

  cpu_cores    = each.value.cpu_cores
  memory_mb    = each.value.memory_mb
  disk_size_gb = each.value.disk_gb

  disk_datastore_id = var.datastore_id
  ci_datastore_id   = var.ci_datastore_id
  image_file_id     = var.image_file_id

  network_bridge  = var.network.bridge
  network_vlan_id = var.network.vlan_id
  ip_address      = each.value.ip_address
  gateway         = each.value.ip_address == null ? null : var.network.gateway
  dns_servers     = var.network.dns_servers
  dns_domain      = var.network.dns_domain

  ssh_username    = var.ssh_username
  ssh_public_keys = var.ssh_public_keys

  vendor_data_file_id = var.vendor_data_file_id
  machine_type        = var.machine_type
  bios                = var.bios
  qemu_agent_enabled  = var.qemu_agent_enabled
  start_on_boot       = var.start_on_boot
  started             = var.started
}

module "workers" {
  source   = "../k8s-node"
  for_each = local.worker_nodes

  name         = each.key
  vm_id        = each.value.vm_id
  proxmox_node = each.value.proxmox_node
  description  = "Kubernetes worker node for cluster '${var.cluster_name}' (${var.environment})"
  tags         = each.value.tags

  cpu_cores    = each.value.cpu_cores
  memory_mb    = each.value.memory_mb
  disk_size_gb = each.value.disk_gb

  disk_datastore_id = var.datastore_id
  ci_datastore_id   = var.ci_datastore_id
  image_file_id     = var.image_file_id

  network_bridge  = var.network.bridge
  network_vlan_id = var.network.vlan_id
  ip_address      = each.value.ip_address
  gateway         = each.value.ip_address == null ? null : var.network.gateway
  dns_servers     = var.network.dns_servers
  dns_domain      = var.network.dns_domain

  ssh_username    = var.ssh_username
  ssh_public_keys = var.ssh_public_keys

  vendor_data_file_id = var.vendor_data_file_id
  machine_type        = var.machine_type
  bios                = var.bios
  qemu_agent_enabled  = var.qemu_agent_enabled
  start_on_boot       = var.start_on_boot
  started             = var.started
}

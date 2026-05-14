resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  tags        = var.tags
  node_name   = var.proxmox_node
  vm_id       = var.vm_id

  machine       = var.machine_type
  bios          = var.bios
  scsi_hardware = var.scsi_hardware

  on_boot = var.start_on_boot
  started = var.started

  agent {
    enabled = var.qemu_agent_enabled
    trim    = true
    type    = "virtio"
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = var.disk_datastore_id
    file_id      = var.image_file_id
    interface    = var.disk_interface
    size         = var.disk_size_gb
    iothread     = true
    discard      = "on"
    ssd          = true
    file_format  = "raw"
  }

  network_device {
    bridge  = var.network_bridge
    model   = var.network_model
    vlan_id = var.network_vlan_id
  }

  initialization {
    datastore_id = var.ci_datastore_id

    dns {
      servers = length(var.dns_servers) > 0 ? var.dns_servers : null
      domain  = var.dns_domain
    }

    ip_config {
      ipv4 {
        address = var.ip_address == null ? "dhcp" : var.ip_address
        gateway = var.ip_address == null ? null : var.gateway
      }
    }

    user_account {
      username = var.ssh_username
      keys     = var.ssh_public_keys
    }
  }

  lifecycle {
    ignore_changes = [
      # Cloud-init regenerates these on every apply; ignore to avoid noisy diffs.
      initialization[0].user_account,
    ]
  }
}

variable "cluster_name" {
  description = "Logical cluster name. Used as VM name prefix and as a tag."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}$", var.cluster_name))
    error_message = "cluster_name must be lowercase alphanumeric/hyphens, 2-41 chars, starting with [a-z0-9]."
  }
}

variable "environment" {
  description = "Environment label applied as a tag (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "proxmox_node" {
  description = "Proxmox host (node) to place all VMs on. Override per-role via *_proxmox_node if needed."
  type        = string
}

variable "image_file_id" {
  description = "File ID of the downloaded cloud image (output of proxmox_virtual_environment_download_file)."
  type        = string
}

variable "control_plane" {
  description = "Control plane node spec (count + sizing)."
  type = object({
    count        = number
    cpu_cores    = number
    memory_mb    = number
    disk_gb      = number
    proxmox_node = optional(string)
    ip_addresses = optional(list(string), [])
    extra_tags   = optional(list(string), [])
  })

  validation {
    condition     = var.control_plane.count >= 1
    error_message = "control_plane.count must be at least 1."
  }
}

variable "workers" {
  description = "Worker node spec (count + sizing)."
  type = object({
    count        = number
    cpu_cores    = number
    memory_mb    = number
    disk_gb      = number
    proxmox_node = optional(string)
    ip_addresses = optional(list(string), [])
    extra_tags   = optional(list(string), [])
  })

  validation {
    condition     = var.workers.count >= 0
    error_message = "workers.count must be >= 0."
  }
}

variable "network" {
  description = "Network configuration shared by all nodes in the cluster."
  type = object({
    bridge      = optional(string, "vmbr0")
    vlan_id     = optional(number)
    gateway     = optional(string)
    dns_servers = optional(list(string), [])
    dns_domain  = optional(string)
  })
  default = {}
}

variable "datastore_id" {
  description = "Datastore for VM disks (e.g. 'local-lvm', 'local-zfs')."
  type        = string
  default     = "local-lvm"
}

variable "ci_datastore_id" {
  description = "Datastore for the cloud-init drive."
  type        = string
  default     = null
}

variable "ssh_username" {
  description = "Cloud-init user to create on every node."
  type        = string
  default     = "debian"
}

variable "ssh_public_keys" {
  description = "SSH public keys authorized on every node."
  type        = list(string)
}

variable "vm_id_base" {
  description = "Base VM ID. Control plane VMs use base+0..count-1; workers use base+50+0..count-1. Set null to let Proxmox auto-assign."
  type        = number
  default     = null
}

variable "worker_vm_id_offset" {
  description = "Offset added to vm_id_base for the first worker. Must be >= control_plane.count."
  type        = number
  default     = 50
}

variable "machine_type" {
  description = "QEMU machine type for all nodes."
  type        = string
  default     = "q35"
}

variable "bios" {
  description = "BIOS type for all nodes."
  type        = string
  default     = "seabios"
}

variable "qemu_agent_enabled" {
  description = "Enable QEMU guest agent on all nodes."
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Auto-start VMs when the Proxmox host boots."
  type        = bool
  default     = true
}

variable "started" {
  description = "Whether VMs should be started after creation."
  type        = bool
  default     = true
}

variable "extra_tags" {
  description = "Extra tags appended to every VM in the cluster."
  type        = list(string)
  default     = []
}

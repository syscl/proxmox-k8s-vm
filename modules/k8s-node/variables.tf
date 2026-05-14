variable "name" {
  description = "VM name (also used as cloud-init hostname)."
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID. Set null to let Proxmox auto-assign."
  type        = number
  default     = null
}

variable "proxmox_node" {
  description = "Proxmox host (node) name to place the VM on."
  type        = string
}

variable "description" {
  description = "Free-form VM description shown in the Proxmox UI."
  type        = string
  default     = "Managed by OpenTofu (proxmox-k8s-vm)"
}

variable "tags" {
  description = "Tags applied to the VM in Proxmox."
  type        = list(string)
  default     = []
}

variable "cpu_cores" {
  description = "Number of vCPU cores."
  type        = number
}

variable "cpu_type" {
  description = "CPU type to expose to the guest. 'host' gives best performance."
  type        = string
  default     = "host"
}

variable "memory_mb" {
  description = "RAM in MiB."
  type        = number
}

variable "disk_size_gb" {
  description = "Root disk size in GiB (must be >= the source image size)."
  type        = number
}

variable "disk_datastore_id" {
  description = "Proxmox datastore for the VM disk (e.g. 'local-lvm', 'local-zfs')."
  type        = string
}

variable "disk_interface" {
  description = "Disk interface (scsi0, virtio0, ...). scsi0 with virtio-scsi-single is recommended."
  type        = string
  default     = "scsi0"
}

variable "scsi_hardware" {
  description = "SCSI controller type."
  type        = string
  default     = "virtio-scsi-single"
}

variable "image_file_id" {
  description = "File ID of the cloud image to clone from (output of proxmox_virtual_environment_download_file)."
  type        = string
}

variable "network_bridge" {
  description = "Proxmox bridge for the VM NIC."
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_id" {
  description = "VLAN tag for the NIC. null = untagged."
  type        = number
  default     = null
}

variable "network_model" {
  description = "NIC model."
  type        = string
  default     = "virtio"
}

variable "ip_address" {
  description = "Static IPv4 address in CIDR notation (e.g. '10.0.0.10/24'). null = DHCP."
  type        = string
  default     = null
}

variable "gateway" {
  description = "Default IPv4 gateway. Used only when ip_address is set."
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "DNS servers passed via cloud-init."
  type        = list(string)
  default     = []
}

variable "dns_domain" {
  description = "Search domain passed via cloud-init."
  type        = string
  default     = null
}

variable "ssh_username" {
  description = "Cloud-init user to create."
  type        = string
  default     = "debian"
}

variable "ssh_public_keys" {
  description = "SSH public keys authorized for ssh_username."
  type        = list(string)
}

variable "ci_datastore_id" {
  description = "Datastore that holds the cloud-init drive (often 'local-lvm' or 'local')."
  type        = string
  default     = null
}

variable "vendor_data_file_id" {
  description = "File ID of a cloud-init vendor-data snippet (proxmox_virtual_environment_file). Runs alongside Proxmox-managed user-data so it does not conflict with user/key setup."
  type        = string
  default     = null
}

variable "start_on_boot" {
  description = "Auto-start the VM when the Proxmox host boots."
  type        = bool
  default     = true
}

variable "started" {
  description = "Whether the VM should be in 'started' state after creation."
  type        = bool
  default     = true
}

variable "qemu_agent_enabled" {
  description = "Enable the QEMU guest agent integration in Proxmox. Requires qemu-guest-agent inside the VM."
  type        = bool
  default     = true
}

variable "machine_type" {
  description = "Machine type. 'q35' is recommended for modern Linux guests."
  type        = string
  default     = "q35"
}

variable "bios" {
  description = "BIOS type: 'seabios' or 'ovmf' (UEFI)."
  type        = string
  default     = "seabios"
}

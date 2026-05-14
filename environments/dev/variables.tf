############################
# Environment metadata
############################

variable "environment" {
  description = "Environment name applied as a tag on all VMs."
  type        = string
}

############################
# Proxmox connection
############################

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://pve.example.com:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in 'USER@REALM!TOKENID=SECRET' form."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification of the Proxmox API (set true for self-signed certs in labs)."
  type        = bool
  default     = false
}

variable "proxmox_ssh_username" {
  description = "SSH username used by the bpg/proxmox provider for snippet/file uploads."
  type        = string
  default     = "root"
}

variable "proxmox_ssh_agent" {
  description = "Use the local SSH agent when the provider needs SSH access."
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Default Proxmox host (node) to place VMs on."
  type        = string
}

############################
# Base image (Debian 13 cloud image)
############################

variable "debian_image_url" {
  description = "URL of the Debian 13 (Trixie) generic cloud image (qcow2/raw)."
  type        = string
  default     = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

variable "debian_image_checksum" {
  description = "SHA256 checksum of debian_image_url. Recommended; set to null to skip."
  type        = string
  default     = null
}

variable "image_datastore_id" {
  description = "Datastore that stores the downloaded cloud image (must allow ISO/import content)."
  type        = string
  default     = "local"
}

variable "datastore_id" {
  description = "Default datastore used for VM disks."
  type        = string
  default     = "local-lvm"
}

variable "ci_datastore_id" {
  description = "Datastore used for cloud-init drives. null = same as datastore_id."
  type        = string
  default     = null
}

############################
# Common cluster defaults
############################

variable "ssh_username" {
  description = "Cloud-init user created on every node."
  type        = string
  default     = "debian"
}

variable "ssh_public_keys" {
  description = "SSH public keys authorized on every node."
  type        = list(string)
}

############################
# Clusters to provision
############################

variable "clusters" {
  description = <<-EOT
    Map of clusters to provision in this environment. Key is the cluster name.

    Example:
      clusters = {
        "k8s-dev-01" = {
          proxmox_node = "pve1"
          control_plane = { count = 1, cpu_cores = 2, memory_mb = 4096, disk_gb = 40 }
          workers       = { count = 2, cpu_cores = 4, memory_mb = 8192, disk_gb = 80 }
        }
      }
  EOT

  type = map(object({
    proxmox_node = optional(string)
    vm_id_base   = optional(number)

    control_plane = object({
      count        = number
      cpu_cores    = number
      memory_mb    = number
      disk_gb      = number
      proxmox_node = optional(string)
      ip_addresses = optional(list(string), [])
      extra_tags   = optional(list(string), [])
    })

    workers = object({
      count        = number
      cpu_cores    = number
      memory_mb    = number
      disk_gb      = number
      proxmox_node = optional(string)
      ip_addresses = optional(list(string), [])
      extra_tags   = optional(list(string), [])
    })

    network = optional(object({
      bridge      = optional(string, "vmbr0")
      vlan_id     = optional(number)
      gateway     = optional(string)
      dns_servers = optional(list(string), [])
      dns_domain  = optional(string)
    }), {})

    datastore_id    = optional(string)
    ci_datastore_id = optional(string)
    extra_tags      = optional(list(string), [])
  }))
}

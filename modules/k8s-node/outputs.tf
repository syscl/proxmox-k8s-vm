output "name" {
  description = "VM name."
  value       = proxmox_virtual_environment_vm.this.name
}

output "vm_id" {
  description = "Proxmox VM ID."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "proxmox_node" {
  description = "Proxmox host the VM lives on."
  value       = proxmox_virtual_environment_vm.this.node_name
}

output "ipv4_addresses" {
  description = "All IPv4 addresses reported by the QEMU guest agent (per interface)."
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}

output "primary_ipv4" {
  description = "First non-loopback, non-link-local IPv4 address (best-effort, requires qemu-guest-agent)."
  value = try(
    [
      for a in flatten(proxmox_virtual_environment_vm.this.ipv4_addresses) :
      a if a != "127.0.0.1" && !startswith(a, "169.254.")
    ][0],
    null
  )
}

output "mac_addresses" {
  description = "NIC MAC addresses."
  value       = proxmox_virtual_environment_vm.this.mac_addresses
}

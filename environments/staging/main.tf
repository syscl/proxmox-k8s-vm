locals {
  image_file_name = "debian-13-genericcloud-amd64.img"
}

resource "proxmox_download_file" "debian13" {
  content_type        = "iso"
  datastore_id        = var.image_datastore_id
  node_name           = var.proxmox_node
  url                 = var.debian_image_url
  file_name           = local.image_file_name
  checksum            = var.debian_image_checksum
  checksum_algorithm  = var.debian_image_checksum == null ? null : "sha256"
  overwrite           = false
  overwrite_unmanaged = true
}

module "cluster" {
  source   = "../../modules/k8s-cluster"
  for_each = var.clusters

  cluster_name = each.key
  environment  = var.environment
  proxmox_node = coalesce(each.value.proxmox_node, var.proxmox_node)

  image_file_id = proxmox_download_file.debian13.id

  control_plane = each.value.control_plane
  workers       = each.value.workers
  network       = each.value.network

  datastore_id    = coalesce(each.value.datastore_id, var.datastore_id)
  ci_datastore_id = coalesce(each.value.ci_datastore_id, var.ci_datastore_id, var.datastore_id)

  ssh_username    = var.ssh_username
  ssh_public_keys = var.ssh_public_keys

  vm_id_base = each.value.vm_id_base
  extra_tags = each.value.extra_tags
}

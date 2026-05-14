# proxmox-k8s-vm

OpenTofu modules and per-environment stacks for provisioning **Kubernetes-ready VMs on
Proxmox VE**, grouped as logical *clusters*. This repo only handles **VM provisioning**
(Debian 13 Trixie cloud image, cloud-init, networking, sizing). Actual Kubernetes
bring-up is left to a separate tool such as **Kubespray**, which can consume the
Ansible inventory emitted by this stack.

## Layout

```
.
├── modules/
│   ├── k8s-node/        # One Proxmox VM (CP or worker) from a cloud image + cloud-init
│   └── k8s-cluster/     # A cluster = N control-plane VMs + M worker VMs (uses k8s-node)
└── environments/
    ├── dev/             # One OpenTofu root per environment (separate state)
    ├── staging/
    └── prod/
```

### Why this shape

- **`modules/k8s-node`** is the smallest reusable unit. It owns *one VM*. You can use
  it directly for one-off boxes (jumphosts, bastions) without going through the
  cluster module.
- **`modules/k8s-cluster`** composes `k8s-node` to produce a named cluster
  (`<cluster_name>-cp-1 .. -cp-N`, `<cluster_name>-worker-1 .. -worker-M`) with
  consistent tags (`k8s`, `cluster-<name>`, `env-<env>`, `role-control-plane|worker`)
  and a Kubespray-shaped Ansible inventory output.
- **`environments/<env>`** are *root modules*. Each has its own state, its own
  Proxmox credentials, and its own `clusters` map. Provisioning N clusters in an
  env is "add another entry to the map".

### Variable naming

The user-facing variables map to your requested names like this:

| Your name                          | This repo                                       |
| ---------------------------------- | ----------------------------------------------- |
| `K8S_CLUSTER_NAME`                 | `cluster_name` (map key in `clusters`)          |
| `K8S_CONTROL_PANEL_NODE_SIZE`*     | `control_plane.count` (+ `cpu_cores`, `memory_mb`, `disk_gb` for sizing) |
| `K8S_WORKER_NODE_SIZE`             | `workers.count` (+ `cpu_cores`, `memory_mb`, `disk_gb` for sizing) |

\* "control plane", not "control panel". Sizing and count are separated because in
practice you change them independently.

## Prerequisites

1. **OpenTofu** `>= 1.11.7`.
2. A reachable **Proxmox VE 8.x** cluster.
3. A Proxmox **API token** for an account that can create VMs, manage cloud-init
   drives, and download files. Token format: `USER@REALM!TOKENID=SECRET`.
   Minimum recommended role: `PVEVMAdmin` on `/vms`, plus `Datastore.AllocateSpace`
   and `Sys.Audit` on the relevant datastores/nodes. For simplicity in a lab,
   `Administrator` on `/` is fine.
4. SSH access to the Proxmox host(s) for the operator running OpenTofu, with the
   key loaded into `ssh-agent`. The `bpg/proxmox` provider uses SSH for some
   privileged operations (cloud image conversion, snippets, etc).
5. A datastore that accepts ISO/import content (defaults to `local`) for the
   cloud image, and a datastore for VM disks (defaults to `local-lvm`).

## Bootstrap a cluster

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: endpoint, token, node name, SSH keys, clusters...

tofu init
tofu plan -out plan.bin
tofu apply plan.bin
```

Outputs:

```bash
tofu output clusters            # JSON: VM IDs, primary IPv4, etc.
tofu output -raw ansible_inventories   # map of cluster_name -> inventory YAML
```

Write a single cluster's inventory to disk for Kubespray:

```bash
mkdir -p ../../inventory/k8s-dev-01
tofu output -json ansible_inventories \
  | jq -r '.["k8s-dev-01"]' \
  > ../../inventory/k8s-dev-01/inventory.yaml
```

## State / backends

Each environment uses an **independent local backend** by default
(`environments/<env>/terraform.tfstate`). That keeps blast radius scoped per env
even before you move state to remote storage.

When you outgrow local state, swap `backend.tf` in each env for a remote backend
(S3/MinIO/HTTP/Consul/etc.) — typically with a per-env state key, e.g.
`proxmox-k8s-vm/<env>/terraform.tfstate`. The rest of the layout does not change.

## Multiple clusters per environment

The `clusters` variable is a map. Provisioning a second dev cluster is just:

```hcl
clusters = {
  "k8s-dev-01" = { ... }
  "k8s-dev-02" = {
    proxmox_node = "pve2"
    vm_id_base   = 1200
    control_plane = { count = 1, cpu_cores = 2, memory_mb = 4096, disk_gb = 40 }
    workers       = { count = 2, cpu_cores = 4, memory_mb = 8192, disk_gb = 80 }
  }
}
```

`tofu plan` will show new VMs only for the added entries; existing clusters stay
untouched.

## VM ID allocation

For each cluster, set `vm_id_base = N`. The module allocates:

- control-plane: `N, N+1, ... N+(control_plane.count - 1)`
- workers:       `N+50, N+51, ...` (offset configurable via `worker_vm_id_offset`)

Pick non-overlapping bases across clusters/envs (e.g. `1100/1200/...` for dev,
`2100/2200/...` for staging, `3100/3200/...` for prod). Set `vm_id_base = null`
to let Proxmox auto-assign IDs.

## Networking

Per-cluster `network` block:

- DHCP (default): leave `control_plane.ip_addresses` / `workers.ip_addresses`
  empty. The QEMU guest agent surfaces assigned IPs via `tofu output`.
- Static: supply CIDR strings (one per node, in order) plus `network.gateway`.

Add `network.vlan_id` to tag the NIC, and `network.dns_servers` /
`network.dns_domain` for cloud-init DNS.

## Cloud image

By default the stack downloads the latest **Debian 13 (Trixie) generic cloud
image** to `image_datastore_id` (default `local`) and uses it as the root disk
source for every VM. Each VM gets a full disk copy resized to `disk_gb`.

To pin the image to a specific build, set `debian_image_url` to the dated path
(e.g. `.../debian-13-genericcloud-amd64-YYYYMMDD-NNNN.qcow2`) and
`debian_image_checksum` to its published SHA256.

## Security notes

- `terraform.tfvars` is git-ignored. Never commit your real `proxmox_api_token`.
  For CI, pass it via environment variable: `export TF_VAR_proxmox_api_token=...`.
- `proxmox_insecure = true` is acceptable for self-signed lab clusters. Production
  Proxmox endpoints should use a real CA cert and set this to `false`.
- The cloud-init `user_account` provisions the user `debian` (override with
  `ssh_username`) authorized via `ssh_public_keys`. No password is set.

## Handing off to Kubespray

The output `ansible_inventories[<cluster_name>]` is a YAML string with the
groups Kubespray expects (`kube_control_plane`, `kube_node`, `etcd`,
`k8s_cluster`). Persist it under your Kubespray inventory directory and run
`ansible-playbook cluster.yml -i inventory.yaml` as usual. This repo is
deliberately *not* coupled to Kubespray so you can swap it for `kubeadm` scripts,
`k3sup`, Talos, etc.

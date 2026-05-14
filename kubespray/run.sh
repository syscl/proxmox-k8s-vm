#!/usr/bin/env bash
# Wrapper: dump tofu inventory -> run kubespray ansible-playbook.
#
# Usage:
#   ./kubespray/run.sh <environment> <cluster_name> [ansible-playbook extra args...]
#
# Examples:
#   ./kubespray/run.sh dev k8s-dev-01
#   ./kubespray/run.sh dev k8s-dev-01 --tags=download
#   ./kubespray/run.sh dev k8s-dev-01 --limit=k8s-dev-01-worker-1
#
# Prerequisites:
#   - tofu init already ran in environments/<env>
#   - kubespray cloned next to this repo (../kubespray) or set KUBESPRAY_DIR
#   - uv (https://docs.astral.sh/uv/)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

info()  { echo "[INFO]  $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# --- Args ---
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <environment> <cluster_name> [extra ansible-playbook args...]"
    echo "  environment:  dev | staging | prod"
    echo "  cluster_name: key from your clusters map (e.g. k8s-dev-01)"
    exit 1
fi

ENV="$1"; shift
CLUSTER="$1"; shift
EXTRA_ARGS=("$@")

ENV_DIR="$REPO_DIR/environments/$ENV"
[[ -d "$ENV_DIR" ]] || error "Environment directory not found: $ENV_DIR"

KUBESPRAY_DIR="${KUBESPRAY_DIR:-$REPO_DIR/../kubespray}"
[[ -d "$KUBESPRAY_DIR" ]] || error "Kubespray not found at $KUBESPRAY_DIR. Clone it or set KUBESPRAY_DIR."
[[ -f "$KUBESPRAY_DIR/cluster.yml" ]] || error "$KUBESPRAY_DIR does not look like a kubespray checkout (missing cluster.yml)."

# --- Ensure kubespray python deps are installed ---
PYTHON_VERSION="3.13.11"
VENV_DIR="$KUBESPRAY_DIR/.venv"

info "Syncing virtualenv (python $PYTHON_VERSION)..."
uv venv --python "$PYTHON_VERSION" "$VENV_DIR" --allow-existing
uv pip install --python "$VENV_DIR/bin/python" -r "$KUBESPRAY_DIR/requirements.txt"

export PATH="$VENV_DIR/bin:$PATH"

# --- Build inventory directory (standard kubespray layout) ---
# Per https://github.com/kubernetes-sigs/kubespray/blob/master/docs/getting_started/getting-started.md:
#   1. Copy inventory/sample as the base (includes all default group_vars)
#   2. Drop our hosts file in
#   3. Overlay our group_vars customizations on top
INVENTORY_DIR="$SCRIPT_DIR/inventory/$CLUSTER"

info "Building inventory at $INVENTORY_DIR..."
rm -rf "$INVENTORY_DIR"
cp -rfp "$KUBESPRAY_DIR/inventory/sample" "$INVENTORY_DIR"

# Extract hosts from tofu output
info "Extracting inventory for cluster '$CLUSTER' from $ENV_DIR..."
INVENTORY_JSON=$(cd "$ENV_DIR" && tofu output -json ansible_inventories 2>/dev/null)
if [[ -z "$INVENTORY_JSON" ]]; then
    error "Failed to read tofu output. Did you run 'tofu apply' in $ENV_DIR?"
fi

echo "$INVENTORY_JSON" \
  | python3 -c "import json,sys; data=json.load(sys.stdin); k='$CLUSTER'; print(data[k]) if k in data else sys.exit('Cluster \"'+k+'\" not found. Available: '+', '.join(data.keys()))" \
  > "$INVENTORY_DIR/inventory.yaml"

info "Hosts written to $INVENTORY_DIR/inventory.yaml"

# Overlay our group_vars on top of kubespray defaults
for yml in "$SCRIPT_DIR/group_vars"/*/*.yml; do
    [[ -f "$yml" ]] || continue
    rel="${yml#"$SCRIPT_DIR/group_vars/"}"
    target="$INVENTORY_DIR/group_vars/$rel"
    mkdir -p "$(dirname "$target")"
    cp "$yml" "$target"
    info "Override: group_vars/$rel"
done

# --- SSH key detection ---
SSH_KEY=""
for candidate in ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do
    if [[ -f "$candidate" ]]; then
        SSH_KEY="$candidate"
        break
    fi
done
[[ -n "$SSH_KEY" ]] || error "No SSH private key found in ~/.ssh/"

# --- Run Kubespray ---
info "Running kubespray cluster.yml for '$CLUSTER' ($ENV)..."
info "Kubespray dir: $KUBESPRAY_DIR"
info "SSH key: $SSH_KEY"
echo ""

# Point -i at the directory so Ansible picks up group_vars/ automatically.
# https://github.com/kubernetes-sigs/kubespray/blob/master/docs/getting_started/getting-started.md
ANSIBLE_ROLES_PATH="$KUBESPRAY_DIR/roles" \
ANSIBLE_COLLECTIONS_PATH="$KUBESPRAY_DIR/collections" \
ANSIBLE_HOST_KEY_CHECKING=False \
ansible-playbook "$KUBESPRAY_DIR/cluster.yml" \
    -i "$INVENTORY_DIR/" \
    -u debian \
    --private-key "$SSH_KEY" \
    --become \
    --flush-cache \
    "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"

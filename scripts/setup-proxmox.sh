#!/usr/bin/env bash
set -euo pipefail

info()  { echo "[INFO]  $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# Must run as root
[[ $EUID -eq 0 ]] || error "Run this script as root on the Proxmox host."

# Enable snippets content type on the local datastore
CURRENT=$(pvesm status --output-format json | python3 -c "
import json, sys
stores = json.load(sys.stdin)
for s in stores:
    if s.get('storage') == 'local':
        print(s.get('content', ''))
" 2>/dev/null || true)

if echo "$CURRENT" | grep -q "snippets"; then
    info "local datastore already has snippets enabled."
else
    info "Enabling snippets on local datastore..."
    pvesm set local --content iso,images,snippets,backup,vztmpl
    info "Done."
fi

# Create the snippets directory if missing
SNIPPETS_DIR="/var/lib/vz/snippets"
if [[ -d "$SNIPPETS_DIR" ]]; then
    info "Snippets directory already exists: $SNIPPETS_DIR"
else
    info "Creating $SNIPPETS_DIR..."
    mkdir -p "$SNIPPETS_DIR"
    info "Done."
fi

info "Proxmox host is ready for tofu apply."

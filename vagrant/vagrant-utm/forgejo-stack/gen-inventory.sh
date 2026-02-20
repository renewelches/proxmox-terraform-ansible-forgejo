#!/usr/bin/env bash
# Generates ansible/inventory/dev/vagrant-utm/forgejo-stack/inventory.ini from vagrant ssh-config.
# Run from this directory (vagrant/vagrant-utm/forgejo-stack/).
#
# Usage: ./gen-inventory.sh <forgejo_domain>
#   Example: ./gen-inventory.sh forgejo.example.com

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_OUT="${SCRIPT_DIR}/../../../ansible/inventory/dev/vagrant-utm/forgejo-stack/inventory.ini"

FORGEJO_DOMAIN="${1:-}"
if [ -z "$FORGEJO_DOMAIN" ]; then
  echo "Usage: $0 <forgejo_domain>" >&2
  echo "  Example: $0 forgejo.example.com" >&2
  exit 1
fi

get_ssh_field() {
  vagrant ssh-config "$1" 2>/dev/null | awk -v f="$2" '$1 == f {print $2}'
}

echo "Reading SSH config from vagrant..."
FG_PORT=$(get_ssh_field forgejo Port)
FG_KEY=$(get_ssh_field forgejo IdentityFile)

mkdir -p "$(dirname "$INVENTORY_OUT")"
cat > "$INVENTORY_OUT" << EOF
[all]
forgejo ansible_host=127.0.0.1 ansible_port=${FG_PORT} ansible_ssh_private_key_file=${FG_KEY}

[containers]
forgejo

[forgejo]
forgejo

[all:vars]
ansible_user=vagrant
ansible_python_interpreter=/usr/bin/python3.13
forgejo_domain=${FORGEJO_DOMAIN}
EOF

echo "Inventory written to: ${INVENTORY_OUT}"

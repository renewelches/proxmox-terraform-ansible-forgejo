# prod/proxmox / forgejo-stack

Provisions a single LXC container on Proxmox VE for Forgejo (self-hosted Git service). Generates the Ansible inventory at `ansible/inventory/prod/proxmox/forgejo-stack/inventory.ini`.

## Container

| Service | Hostname | Cores | RAM | Swap | Disk | IP |
|---------|----------|-------|-----|------|------|----|
| Forgejo | `forgejo` | 2 | 2 GB | 1 GB | 50 GB | 192.168.86.210 |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 3000 | HTTPS | Forgejo web UI |
| 2222 | SSH | Git SSH access |

## TLS Certificate

Forgejo runs with a self-signed certificate. The domain is set via `forgejo_domain` and passed through the Ansible inventory to the container's environment. The cert and key are deployed from `ansible/files/forgejo/` to `/etc/forgejo/certs/` on the container, owned by UID 1000 (Forgejo's `git` user).

The private key (`ansible/files/forgejo/forgejo.key`) is excluded from version control via `.gitignore`.

## Variables

Sensitive variables via environment variables:

```bash
export TF_VAR_proxmox_api_token="terraform@pve!provider=..."
export TF_VAR_proxmox_host_default_pwd="your-password"
```

Key variables in `terraform.tfvars`:

| Variable | Example value |
|----------|---------------|
| `proxmox_node` | `minis` |
| `static_ip` | `192.168.86.210` |
| `forgejo_domain` | `forgejo.example.com` |
| `template_file_id` | `pve-cluster:vztmpl/debian13-docker_v29-template.tar.gz` |

## Deploy

```bash
# From this directory
terraform init
terraform plan
terraform apply
# Generates: ansible/inventory/prod/proxmox/forgejo-stack/inventory.ini

# From repo root
ANSIBLE_CONFIG=ansible/inventory/prod/proxmox/ansible.cfg \
  ansible-playbook -i ansible/inventory/prod/proxmox/forgejo-stack/inventory.ini \
  ansible/deploy-forgejo-stack.yml
```

## First Run

On first access Forgejo shows an installation wizard at `https://<forgejo_domain>` (or `https://192.168.86.210:3000`). Complete it to create your admin account. The database uses SQLite by default.

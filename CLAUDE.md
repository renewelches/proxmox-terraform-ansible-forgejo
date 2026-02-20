# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Deploys a self-hosted Forgejo Git service with a two-stage pipeline: Terraform provisions a Proxmox LXC container, then Ansible deploys the Forgejo Docker container with HTTPS and Git SSH.

## Environment Architecture

- **`terraform/environments/prod/proxmox/`** — Provisions a single LXC container on Proxmox VE using the `bpg/proxmox` provider. Container gets a static IP and connects via SSH as `root` with keys loaded in ssh-agent.
- **`vagrant/vagrant-vb/`** — VirtualBox VM managed directly with Vagrant. Run `gen-inventory.sh` after `vagrant up` to generate the Ansible inventory.
- **`vagrant/vagrant-utm/`** — UTM VM (Apple Silicon) managed directly with Vagrant. Uses `utm/debian-12` box with `utm` provider block. Requires `vagrant plugin install vagrant-utm` (one-time).

All environments share the same Ansible playbook (`ansible/deploy-forgejo-stack.yml`) but use separate inventory configs under `ansible/inventory/<tier>/<env>/`.

## Deployment Flow

```
# Dev (Vagrant)
vagrant up  →  ./gen-inventory.sh <forgejo_domain>  →  ansible-playbook

# Prod (Terraform + Proxmox)
terraform apply  →  inventory.ini generated via templatefile()  →  ansible-playbook
```

## Commands

```bash
# VirtualBox dev
cd vagrant/vagrant-vb
vagrant up
./gen-inventory.sh forgejo.example.com

# UTM dev (Apple Silicon)
# Prerequisite: vagrant plugin install vagrant-utm  (one-time)
cd vagrant/vagrant-utm
vagrant up
./gen-inventory.sh forgejo.example.com

# Proxmox prod
cd terraform/environments/prod/proxmox
terraform init
terraform plan
terraform apply   # Generates ansible/inventory/prod/proxmox/inventory.ini

# Ansible (from repo root)
ANSIBLE_CONFIG=ansible/inventory/prod/proxmox/ansible.cfg \
  ansible-playbook -i ansible/inventory/prod/proxmox/inventory.ini \
  ansible/deploy-forgejo-stack.yml

ANSIBLE_CONFIG=ansible/inventory/dev/vagrant-vb/ansible.cfg \
  ansible-playbook -i ansible/inventory/dev/vagrant-vb/inventory.ini \
  ansible/deploy-forgejo-stack.yml

# Prerequisite: install Ansible Docker collection
ansible-galaxy collection install community.docker

# Terraform validation/formatting (run from stack dir)
terraform validate
terraform fmt
```

## Key Relationships Between Files

- `ansible/files/forgejo/forgejo.crt` — TLS certificate deployed to `/etc/forgejo/certs/` on the container. Committed to git.
- `ansible/files/forgejo/forgejo.key` — TLS private key. Git-ignored; must be present locally before running Ansible.
- `ansible/inventory/prod/proxmox/inventory.tpl` — Terraform template generating `inventory.ini` with the container's static IP and `forgejo_domain`.
- `vagrant/<env>/gen-inventory.sh` — Shell script that reads `vagrant ssh-config` and writes the Ansible inventory. Run after `vagrant up`.
- `ansible/inventory/<tier>/<env>/ansible.cfg` — Per-environment SSH config. Dev uses `StrictHostKeyChecking=no`; prod uses `StrictHostKeyChecking=accept-new`.

## Code Patterns

- Sensitive variables (`proxmox_api_token`, `proxmox_host_default_pwd`) use `sensitive = true` and are set via `TF_VAR_` env vars
- IP extraction from CIDR in prod: `split("/", ...address)[0]`
- Forgejo container runs as UID 1000 (`git` user) — cert files must be owned by `1000:1000`
- `gen-inventory.sh` parses `vagrant ssh-config <vmname>` using `awk '$1 == field {print $2}'`
- Inventory path from `terraform/environments/prod/proxmox/`: 4 levels up to repo root (`../../../../`)
- Inventory path from `vagrant/<env>/`: 2 levels up to repo root (`../../`)
- vagrant-vb box: `cloud-image/debian-13`; vagrant-utm box: `utm/debian-12` (ARM64, no disk resize)
- Private network IP: 192.168.56.10

## Configuration

Copy `terraform/environments/prod/proxmox/terraform.tfvars.example` to `terraform.tfvars` and fill in values. Sensitive values via `TF_VAR_` environment variables.

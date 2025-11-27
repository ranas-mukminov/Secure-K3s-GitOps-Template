terraform {
  required_version = ">= 1.6.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.50"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  # TODO: configure a remote backend (Terraform Cloud, S3, GCS) for production state storage.
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for tunnel + DNS management"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Public SSH key for Ansible access (only via Cloudflare Tunnel/Out-of-band)"
  type        = string
}

variable "server_location" {
  description = "Hetzner location (e.g., nbg1, fsn1)"
  type        = string
  default     = "nbg1"
}

variable "server_type" {
  description = "Hetzner server type (e.g., cpx21)"
  type        = string
  default     = "cpx21"
}

resource "hcloud_ssh_key" "admin" {
  name       = "k3s-admin"
  public_key = var.ssh_public_key
}

resource "hcloud_network" "k3s" {
  name     = "k3s-zero-trust"
  ip_range = "10.42.0.0/16"
}

resource "hcloud_subnet" "k3s_nodes" {
  type         = "cloud"
  network_id   = hcloud_network.k3s.id
  ip_range     = "10.42.0.0/24"
  network_zone = "eu-central"
}

resource "hcloud_firewall" "k3s" {
  name = "k3s-zero-trust"

  # No inbound rules: all ingress is denied by default. Access is brokered via Cloudflare Tunnel/ArgoCD agents.

  rule {
    direction       = "out"
    protocol        = "tcp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "udp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "k3s_control" {
  name        = "k3s-control-1"
  image       = "ubuntu-22.04"
  server_type = var.server_type
  location    = var.server_location

  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.k3s.id]
  networks = [
    hcloud_network.k3s.id,
  ]

  # Cloud-init here should only perform minimal setup; full hardening is applied via Ansible.
  user_data = <<-EOT
    #cloud-config
    package_update: true
    package_upgrade: true
    runcmd:
      - ufw disable
      - sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
      - systemctl restart ssh
  EOT
}

output "server_ipv4" {
  description = "Public IPv4 of the control-plane node (use Cloudflare Tunnel; do not expose ports)."
  value       = hcloud_server.k3s_control.ipv4_address
}

output "private_network" {
  description = "Private network address space for the cluster"
  value       = hcloud_network.k3s.ip_range
}

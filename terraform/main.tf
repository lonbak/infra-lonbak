# Lonbak Infrastructure
# Terraform configuration for single-node Proxmox with K3s

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.70.0"
    }
  }
}

# =============================================================================
# Proxmox Provider Configuration
# =============================================================================
provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_tls_insecure

  ssh {
    agent = true
  }
}

# =============================================================================
# Local values for computed configurations
# =============================================================================
locals {
  # Common tags for all resources
  tags = ["lonbak", "infrastructure"]

  # K3s node configuration
  k3s_node = {
    vmid     = 110
    name     = "k3s-node"
    ip       = var.k3s_ip
    hostname = "k3s.${var.base_domain}"
  }
}

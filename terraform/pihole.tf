# Pi-hole DNS Server LXC Container

# =============================================================================
# Pi-hole LXC Container
# =============================================================================

resource "proxmox_virtual_environment_container" "pihole" {
  count = var.pihole_enabled ? 1 : 0

  description = "Pi-hole DNS Server"
  node_name   = var.proxmox_node
  vm_id       = 100
  tags        = ["lonbak", "pihole", "dns", "infrastructure"]

  # Use Debian 12 template
  operating_system {
    template_file_id = "${var.iso_storage}:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  # Resources - Pi-hole is lightweight
  cpu {
    cores = var.pihole_cores
  }

  memory {
    dedicated = var.pihole_memory
    swap      = 256
  }

  # Root filesystem
  disk {
    datastore_id = var.storage_pool
    size         = 8
  }

  # Network
  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  initialization {
    hostname = "pihole"

    ip_config {
      ipv4 {
        address = "${var.pihole_ip}/${var.network_cidr}"
        gateway = var.network_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      keys = [var.ssh_public_key]
    }
  }

  # Features
  features {
    nesting = true
  }

  # Start on boot
  started       = true
  start_on_boot = true

  # Unprivileged container
  unprivileged = true
}

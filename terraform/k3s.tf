# K3s Single-Node Cluster LXC Container

# =============================================================================
# K3s LXC Container
# =============================================================================
# Note: K3s in LXC requires:
# - Privileged container with nesting enabled
# - /dev/kmsg symlink to /dev/console (created by systemd service)
# - Host kernel parameters: vm.overcommit_memory=1, kernel.panic=10, kernel.panic_on_oops=1
# - Kernel modules loaded on host: br_netfilter, overlay

resource "proxmox_virtual_environment_container" "k3s" {
  count = var.k3s_enabled ? 1 : 0

  description = "K3s Single-Node Kubernetes Cluster"
  node_name   = var.proxmox_node
  vm_id       = 110
  tags        = ["lonbak", "k3s", "kubernetes", "infrastructure"]

  # Use Debian 12 template
  operating_system {
    template_file_id = "${var.iso_storage}:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  # Resources - K3s needs decent resources
  cpu {
    cores = var.k3s_cores
  }

  memory {
    dedicated = var.k3s_memory
    swap      = 512
  }

  # Root filesystem
  disk {
    datastore_id = var.storage_pool
    size         = tonumber(replace(var.k3s_disk_size, "G", ""))
  }

  # Network
  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  initialization {
    hostname = "k3s-node"

    ip_config {
      ipv4 {
        address = "${var.k3s_ip}/${var.network_cidr}"
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

  # Features - K3s requires privileged container with nesting
  features {
    nesting = true
  }

  # Privileged container required for K3s
  unprivileged = false

  # Start on boot
  started       = true
  start_on_boot = true
}

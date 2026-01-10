# K3s Single-Node Cluster VM

# =============================================================================
# K3s VM
# =============================================================================

resource "proxmox_virtual_environment_vm" "k3s" {
  count = var.k3s_enabled ? 1 : 0

  description = "K3s Single-Node Kubernetes Cluster"
  name        = "k3s-node"
  node_name   = var.proxmox_node
  vm_id       = 110
  tags        = ["lonbak", "k3s", "kubernetes", "infrastructure"]

  # Clone from cloud image template
  clone {
    vm_id = 9000  # Template VM ID - must be created manually
  }

  # Boot configuration
  boot_order = ["scsi0"]
  bios       = "seabios"
  machine    = "q35"

  # CPU configuration
  cpu {
    cores = var.k3s_cores
    type  = "host"
  }

  # Memory - no ballooning for K3s stability
  memory {
    dedicated = var.k3s_memory
  }

  # Main disk - resize from template
  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = tonumber(replace(var.k3s_disk_size, "G", ""))
    discard      = "on"
    ssd          = true
  }

  # SCSI controller
  scsi_hardware = "virtio-scsi-single"

  # Network
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # Cloud-init configuration
  initialization {
    datastore_id = var.storage_pool

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
      username = var.default_user
      keys     = [var.ssh_public_key]
    }
  }

  # VM options
  agent {
    enabled = true
  }

  started       = true
  start_on_boot = true

  # Lifecycle - ignore network changes managed by K3s
  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}

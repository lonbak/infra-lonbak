# Lonbak Infrastructure Variables

# =============================================================================
# Proxmox Connection
# =============================================================================

variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://10.10.10.1:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., root@pam!terraform)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (for self-signed certs)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "anton"
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "network_gateway" {
  description = "Network gateway IP"
  type        = string
  default     = "192.168.0.1"
}

variable "network_cidr" {
  description = "Network CIDR suffix (24 for 192.168.0.0/24)"
  type        = string
  default     = "24"
}

variable "network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "dns_servers" {
  description = "DNS servers (before Pi-hole is set up)"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

# =============================================================================
# Storage Configuration
# =============================================================================

variable "storage_pool" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "iso_storage" {
  description = "Proxmox storage for ISO/templates"
  type        = string
  default     = "local"
}

variable "cloud_image" {
  description = "Cloud image file name for VMs"
  type        = string
  default     = "debian-12-genericcloud-amd64.qcow2"
}

# =============================================================================
# SSH Configuration
# =============================================================================

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "default_user" {
  description = "Default user for VMs"
  type        = string
  default     = "admin"
}

# =============================================================================
# Pi-hole Configuration
# =============================================================================

variable "pihole_enabled" {
  description = "Whether to create Pi-hole DNS server"
  type        = bool
  default     = true
}

variable "pihole_ip" {
  description = "Static IP for Pi-hole LXC"
  type        = string
  default     = "192.168.0.11"
}

variable "pihole_cores" {
  description = "CPU cores for Pi-hole LXC"
  type        = number
  default     = 1
}

variable "pihole_memory" {
  description = "Memory in MB for Pi-hole LXC"
  type        = number
  default     = 512
}

# =============================================================================
# K3s Configuration
# =============================================================================

variable "k3s_enabled" {
  description = "Whether to create K3s VM"
  type        = bool
  default     = true
}

variable "k3s_ip" {
  description = "Static IP for K3s VM"
  type        = string
  default     = "192.168.0.12"
}

variable "k3s_cores" {
  description = "CPU cores for K3s VM"
  type        = number
  default     = 3
}

variable "k3s_memory" {
  description = "Memory in MB for K3s VM"
  type        = number
  default     = 12288  # 12GB
}

variable "k3s_disk_size" {
  description = "Disk size for K3s VM"
  type        = string
  default     = "80G"
}

# =============================================================================
# Domain Configuration
# =============================================================================

variable "base_domain" {
  description = "Base domain for services"
  type        = string
  default     = "lonbak.local"
}

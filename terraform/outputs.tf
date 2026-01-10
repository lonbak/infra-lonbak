# Infrastructure Outputs

# =============================================================================
# Pi-hole Outputs
# =============================================================================

output "pihole_ip" {
  description = "Pi-hole DNS server IP address"
  value       = var.pihole_enabled ? var.pihole_ip : null
}

output "pihole_admin_url" {
  description = "Pi-hole admin interface URL"
  value       = var.pihole_enabled ? "http://${var.pihole_ip}/admin" : null
}

output "pihole_dns_config" {
  description = "DNS configuration for router"
  value       = var.pihole_enabled ? "Set your router's DNS server to: ${var.pihole_ip}" : null
}

# =============================================================================
# K3s Outputs
# =============================================================================

output "k3s_ip" {
  description = "K3s node IP address"
  value       = var.k3s_enabled ? var.k3s_ip : null
}

output "k3s_ssh" {
  description = "SSH command to connect to K3s node"
  value       = var.k3s_enabled ? "ssh ${var.default_user}@${var.k3s_ip}" : null
}

output "k3s_kubeconfig" {
  description = "Command to get kubeconfig from K3s"
  value       = var.k3s_enabled ? "ssh ${var.default_user}@${var.k3s_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml'" : null
}

# =============================================================================
# Network Summary
# =============================================================================

output "network_summary" {
  description = "Network configuration summary"
  value = {
    gateway     = var.network_gateway
    cidr        = var.network_cidr
    dns_servers = var.dns_servers
    pihole      = var.pihole_enabled ? var.pihole_ip : "disabled"
    k3s         = var.k3s_enabled ? var.k3s_ip : "disabled"
  }
}

# =============================================================================
# Service URLs (after K3s setup)
# =============================================================================

output "service_urls" {
  description = "Expected service URLs after K3s deployment"
  value = var.k3s_enabled ? {
    traefik_dashboard = "http://traefik.${var.base_domain}"
    uptime_kuma       = "http://status.${var.base_domain}"
    registry          = "http://registry.${var.base_domain}"
    omada             = "http://omada.${var.base_domain}"
  } : null
}

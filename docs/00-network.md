# Network Architecture

## Overview

The home network uses a /23 subnet to separate static infrastructure from DHCP clients while keeping everything on the same broadcast domain.

## Network Layout

```
LAN: 192.168.0.0/23 (255.255.254.0)
Range: 192.168.0.1 - 192.168.1.254 (510 usable hosts)

┌─────────────────────────────────────────────────────────────────┐
│  192.168.0.x - Static Infrastructure                           │
├─────────────────────────────────────────────────────────────────┤
│  .1        Gateway (Omada Router)                               │
│  .10       Proxmox host (anton)                                 │
│  .11       Pi-hole DNS (LXC)                                    │
│  .12       K3s node (LXC)                                       │
│  .20-.99   Reserved for future infrastructure                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  192.168.1.x - DHCP Clients                                     │
├─────────────────────────────────────────────────────────────────┤
│  .1-.9     Reserved (excluded from DHCP)                        │
│  .10-.199  DHCP dynamic range                                   │
│  .200-.254 DHCP static reservations (printers, IoT, etc.)       │
└─────────────────────────────────────────────────────────────────┘
```

## IP Assignments

### Infrastructure (Static)

| IP | Hostname | Description |
|----|----------|-------------|
| 192.168.0.1 | gateway | Omada Router / Network Gateway |
| 192.168.0.10 | anton / pve.lonbak.local | Proxmox VE host |
| 192.168.0.11 | pihole.lonbak.local | Pi-hole DNS server (LXC) |
| 192.168.0.12 | k3s.lonbak.local | K3s Kubernetes node (LXC) |

### Kubernetes Services (via Traefik Ingress on 192.168.0.12)

| URL | Service |
|-----|---------|
| http://omada.lonbak.local | Omada Controller |
| http://traefik.lonbak.local | Traefik Dashboard |
| http://status.lonbak.local | Uptime Kuma |
| http://registry.lonbak.local | Container Registry (if deployed) |

## DNS Configuration

### Pi-hole (192.168.0.11)

- **Upstream DNS**: Cloudflare (1.1.1.1), Google (8.8.8.8)
- **Wildcard DNS**: `*.lonbak.local` → 192.168.0.12
- **Local entries**: Defined in `/etc/pihole/pihole.toml`

### DHCP DNS Setting

All DHCP clients receive 192.168.0.11 (Pi-hole) as their DNS server.

## Omada Controller Settings

### LAN Configuration

| Setting | Value |
|---------|-------|
| Network | 192.168.0.0/23 |
| Gateway | 192.168.0.1 |
| Subnet Mask | 255.255.254.0 |

### DHCP Configuration

| Setting | Value |
|---------|-------|
| DHCP Range | 192.168.1.10 - 192.168.1.199 |
| DNS Server | 192.168.0.11 |
| Gateway | 192.168.0.1 |
| Lease Time | 24 hours |

## Kubernetes Network (Internal)

K3s uses internal overlay networks not exposed to the LAN:

| Network | CIDR | Purpose |
|---------|------|---------|
| Pod Network | 10.42.0.0/16 | Flannel overlay for pods |
| Service Network | 10.43.0.0/16 | ClusterIP services |

Traffic reaches pods via:
- **LoadBalancer**: Traefik on ports 80/443
- **hostNetwork**: Omada on ports 8088, 29810-29816

## Port Reference

### K3s Node (192.168.0.12)

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 80 | TCP | Traefik HTTP |
| 443 | TCP | Traefik HTTPS |
| 6443 | TCP | Kubernetes API |
| 8088 | TCP | Omada HTTP |
| 8043 | TCP | Omada HTTPS |
| 29810 | UDP | Omada device discovery |
| 29811-29816 | TCP | Omada device management |

### Pi-hole (192.168.0.11)

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 53 | TCP/UDP | DNS |
| 80 | TCP | Web admin |

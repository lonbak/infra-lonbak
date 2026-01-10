# Proxmox VE Setup Guide

## Overview

This guide covers installing and configuring Proxmox VE for the Lonbak infrastructure.

## Prerequisites

- Intel i5-6500T or similar CPU (4+ cores recommended)
- 16GB+ RAM
- 500GB+ storage (SSD preferred)
- USB drive for Proxmox installation

## Step 1: Install Proxmox VE

1. Download Proxmox VE ISO from https://www.proxmox.com/en/downloads
2. Create bootable USB with Balena Etcher or similar
3. Boot from USB and follow installation wizard
4. Set hostname: anton.lonbak.local
5. Set static IP: 192.168.0.10/24
6. Set gateway: 192.168.0.1 (ER605)
7. Set DNS: 1.1.1.1, 8.8.8.8

## Step 2: Post-Installation Configuration

### Access Web UI

Open browser: https://192.168.0.10:8006

### Remove Enterprise Repository (Optional)

```bash
# SSH to Proxmox
ssh root@192.168.0.10

# Disable enterprise repo
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Add no-subscription repo
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Update
apt update && apt dist-upgrade -y
```

### Create API Token for Terraform

1. Datacenter > Permissions > API Tokens
2. Add > User: root@pam, Token ID: terraform
3. Uncheck "Privilege Separation"
4. Copy the token secret (shown only once!)

### Download LXC Template

```bash
# Download Debian 12 template
pveam update
pveam download local debian-12-standard_12.12-1_amd64.tar.zst
```

### Create Cloud-Init VM Template

```bash
# Download cloud image
cd /var/lib/vz/template/iso
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

# Create VM
qm create 9000 --memory 2048 --core 2 --name debian-12-template --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9000 debian-12-genericcloud-amd64.qcow2 local-lvm

# Configure VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

## Step 3: Network Configuration

### Verify Bridge

The default bridge `vmbr0` should be configured:

```bash
cat /etc/network/interfaces
```

Should contain:
```
auto vmbr0
iface vmbr0 inet static
    address 192.168.0.10/24
    gateway 192.168.0.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
```

### Configure Router

1. Reserve static IPs in ER605 for: 192.168.0.10, 192.168.0.11, 192.168.0.12
2. After Pi-hole is set up, set ER605 DNS to: 192.168.0.11

## Step 4: Storage Configuration

### Default Storage

Proxmox creates these storage pools:
- `local`: For ISO images and templates
- `local-lvm`: For VM disks

### Check Storage

```bash
pvesm status
```

## Next Steps

1. Configure terraform.tfvars with your settings
2. Run Terraform to provision Pi-hole and K3s VM
3. Run Ansible playbooks to configure services

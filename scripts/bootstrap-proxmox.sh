#!/bin/bash
# Bootstrap script for Proxmox VE post-installation
# Run as root on the Proxmox host

set -e

echo "=== Proxmox Post-Installation Bootstrap ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Disable enterprise repository
echo "Disabling enterprise repository..."
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list
fi

# Add no-subscription repository
echo "Adding no-subscription repository..."
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Update system
echo "Updating system..."
apt update
apt dist-upgrade -y

# Install useful tools
echo "Installing tools..."
apt install -y curl wget vim htop iotop net-tools dnsutils

# Download Debian 12 LXC template
echo "Downloading Debian 12 LXC template..."
pveam update
pveam download local debian-12-standard_12.12-1_amd64.tar.zst || true

# Download Debian 12 cloud image for VMs
echo "Downloading Debian 12 cloud image..."
cd /var/lib/vz/template/iso
if [ ! -f debian-12-genericcloud-amd64.qcow2 ]; then
  wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
fi

# Check if template VM exists
if ! qm status 9000 &>/dev/null; then
  echo "Creating cloud-init VM template (ID: 9000)..."

  # Create VM
  qm create 9000 --memory 2048 --core 2 --name debian-12-template --net0 virtio,bridge=vmbr0

  # Import disk
  qm importdisk 9000 /var/lib/vz/template/iso/debian-12-genericcloud-amd64.qcow2 local-lvm

  # Configure VM
  qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
  qm set 9000 --ide2 local-lvm:cloudinit
  qm set 9000 --boot c --bootdisk scsi0
  qm set 9000 --serial0 socket --vga serial0
  qm set 9000 --agent enabled=1

  # Convert to template
  qm template 9000

  echo "Template VM 9000 created successfully!"
else
  echo "Template VM 9000 already exists, skipping..."
fi

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Next steps:"
echo "1. Create API token in Proxmox UI:"
echo "   Datacenter > Permissions > API Tokens"
echo "   User: root@pam, Token ID: terraform"
echo "   Uncheck 'Privilege Separation'"
echo ""
echo "2. Configure terraform.tfvars with your settings"
echo ""
echo "3. Run Terraform to provision infrastructure"

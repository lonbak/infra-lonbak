# Proxmox Host Recovery Guide

**Created**: 2026-01-11
**Applies to**: anton (192.168.0.10)

## Overview

This guide covers known issues and recovery procedures for the Proxmox host.

## Host Information

| Host | IP | VMs/LXC |
|------|-----|---------|
| anton | 192.168.0.10 | pihole (LXC), k3s-node (VM) |

## Known Issues

### 1. Network Card Hang (e1000e)

Intel e1000e NICs can hang under heavy network load, causing system freeze.

**Symptoms:**
- System becomes unresponsive
- SSH disconnects
- Console shows "Detected Hardware Unit Hang" errors

**Fix (applied by bootstrap script):**
```bash
# Disable TSO/GSO
ethtool -K <nic> tso off gso off
```

**Verify fix is active:**
```bash
NIC=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(enp|eno|eth)' | head -1)
ethtool -k $NIC | grep -E 'tso|gso'
# Should show: off
```

### 2. NVMe Timeouts During Boot

After a hard crash, NVMe may timeout during boot.

**Symptoms:**
- Boot hangs at "A start job is running for /dev/..."

**Usually recovers automatically** after 90-120 seconds.

## Recovery Procedures

### If System is Frozen

1. **Hard power cycle** - hold power button 5+ seconds
2. System should boot normally
3. If issues persist, select fallback kernel from GRUB menu

### If System Won't Boot

1. **At GRUB menu** (10 second timeout):
   - Select **"Advanced options for Proxmox VE GNU/Linux"**
   - Select older kernel

2. **Once booted with older kernel:**
   ```bash
   # Check what went wrong
   journalctl -b -1 -p err
   ```

### If No GRUB Menu Appears

- **During boot, hold SHIFT** (BIOS) or **press ESC repeatedly** (UEFI)

## Configuration Applied by Bootstrap

### /etc/network/interfaces
```bash
iface vmbr0 inet static
        ...
        post-up ethtool -K <nic> tso off gso off
```

### /etc/default/grub.d/recovery.cfg
```bash
GRUB_TIMEOUT=10
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
```

## Quick Commands

```bash
# Check current kernel
uname -r

# List available kernels
ls /boot/vmlinuz*

# Check last boot errors
journalctl -b -p err | head -50

# Check NIC status
NIC=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(enp|eno|eth)' | head -1)
ethtool $NIC | grep -i link
ethtool -k $NIC | grep -E 'tso|gso'

# Pin a kernel to prevent removal
apt-mark hold proxmox-kernel-<version>

# Check pinned packages
apt-mark showhold
```

## Monitoring

```bash
# Live monitoring for NIC issues
journalctl -f | grep -i e1000e

# Check for hangs in last boot
journalctl -b -p err | grep -i hang
```

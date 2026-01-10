# Omada Controller for Kubernetes

## Overview

This deploys the TP-Link Omada Software Controller for managing Omada network devices (EAPs, switches, routers).

## Important Notes

### Host Network Mode

The deployment uses `hostNetwork: true` because:
1. Omada devices discover the controller via UDP broadcast on port 29810
2. Device adoption requires direct communication on ports 29811-29814
3. Host networking ensures devices can find and connect to the controller

### Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8088 | TCP | Management web interface (HTTP) |
| 8043 | TCP | Management web interface (HTTPS) |
| 8843 | TCP | Guest portal (HTTPS) |
| 29810 | UDP | EAP discovery |
| 29811 | TCP | EAP management v1 |
| 29812 | TCP | EAP adoption v1 |
| 29813 | TCP | Firmware upgrade |
| 29814 | TCP | EAP management v2 |

## Installation

```bash
# Apply the manifests
kubectl apply -f deployment.yaml

# Wait for the pod to be ready (takes 1-2 minutes)
kubectl wait --for=condition=ready pod -l app=omada-controller -n omada --timeout=300s

# Check status
kubectl get pods -n omada
```

## Access

- **Web UI**: https://omada.home.local (or https://<k3s-ip>:8043)
- **Default login**: Set up on first access

## Device Adoption

1. Ensure devices are on the same network as the K3s node
2. Factory reset devices if previously adopted elsewhere
3. Devices should auto-discover the controller
4. If not, manually set the inform URL in device to: http://<k3s-ip>:29811

## Backup

Data is stored in the `omada-data` PVC. To backup:

```bash
# Create a backup pod
kubectl run backup --rm -it --image=alpine -n omada -- sh
# Then tar the /opt/tplink/EAPController/data directory
```

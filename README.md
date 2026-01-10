# Lonbak Infrastructure

Infrastructure as Code for a single-node Proxmox server with K3s.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Proxmox Host (4 cores, 16GB)                 │
│                        192.168.0.10                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────────────────────────┐ │
│  │    Pi-hole      │  │         K3s Single-Node              │ │
│  │     (LXC)       │  │       3 cores, 12GB RAM              │ │
│  │  1 core, 512MB  │  │       192.168.0.12                   │ │
│  │  192.168.0.11   │  ├──────────────────────────────────────┤ │
│  └─────────────────┘  │  Core Services:                      │ │
│                       │  ├─ Traefik (Ingress)      ~100MB    │ │
│                       │  ├─ GitLab Runner (CI)     ~200MB    │ │
│                       │  ├─ Docker Registry        ~100MB    │ │
│                       │  └─ Uptime Kuma            ~100MB    │ │
│                       ├──────────────────────────────────────┤ │
│                       │  Apps:                               │ │
│                       │  ├─ Omada Controller       ~500MB    │ │
│                       │  └─ Your Apps              ~remaining│ │
│                       └──────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Network Strategy

### Bootstrap Phase (Initial Setup)

Use your **existing 192.168.0.x network** to get everything running:

| Device | IP | Notes |
|--------|-----|-------|
| Router/Gateway | 192.168.0.1 | ER605 |
| Proxmox | 192.168.0.10 | Hypervisor |
| Pi-hole | 192.168.0.11 | DNS + Ad-blocking |
| K3s Node | 192.168.0.12 | Kubernetes cluster |

**Why?** Omada Controller runs in K3s, but K3s needs network to exist first. So we bootstrap with the existing network.

### After Omada is Running (Optional Migration)

Once Omada is managing your network, you can:
1. Keep 192.168.0.x (simplest - no changes needed)
2. Migrate to a different range (e.g., 10.10.0.0/16) via Omada

**Before provisioning:** Reserve static IPs in your ER605's DHCP settings for:
- 192.168.0.10 (Proxmox)
- 192.168.0.11 (Pi-hole)
- 192.168.0.12 (K3s)

## Quick Start

### Prerequisites

1. A Proxmox VE server installed and configured
2. Debian 12 LXC template downloaded in Proxmox
3. Cloud-init VM template (VM ID 9000) created
4. SSH key pair for authentication
5. Terraform >= 1.5.0 installed locally
6. Ansible >= 2.15 installed locally

### Step 1: Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### Step 2: Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 3: Configure Pi-hole

```bash
cd ansible
ansible-playbook playbooks/setup-pihole.yml
```

### Step 4: Setup K3s

```bash
ansible-playbook playbooks/setup-k3s.yml
```

### Step 5: Deploy K8s Services

```bash
# SSH to K3s node
ssh admin@192.168.0.12

# Install Traefik
cd kubernetes/traefik
./install.sh

# Deploy other services
kubectl apply -f ../registry/deployment.yaml
kubectl apply -f ../uptime-kuma/deployment.yaml
kubectl apply -f ../omada/deployment.yaml

# Install GitLab Runner (requires token)
cd ../gitlab-runner
GITLAB_RUNNER_TOKEN=glrt-xxxx ./install.sh
```

## Service URLs

After deployment, these services will be available:

| Service | URL | Purpose |
|---------|-----|---------|
| Pi-hole | http://192.168.0.11/admin | DNS & Ad-blocking |
| Traefik | http://traefik.lonbak.local | Ingress Dashboard |
| Uptime Kuma | http://status.lonbak.local | Status Monitoring |
| Registry | http://registry.lonbak.local | Container Images |
| Omada | http://omada.lonbak.local (or http://192.168.0.12:8088) | Network Management |

**Note:** `*.lonbak.local` URLs require Pi-hole to be your DNS server (configure in router).

## Directory Structure

```
infra-lonbak/
├── README.md                 # This file
├── docs/                     # Detailed documentation
│   ├── 01-proxmox-setup.md  # Proxmox installation
│   └── 02-k3s-apps.md       # Deploying apps to K3s
├── terraform/                # Infrastructure provisioning
│   ├── main.tf
│   ├── variables.tf
│   ├── pihole.tf
│   ├── k3s.tf
│   └── outputs.tf
├── ansible/                  # Configuration management
│   ├── ansible.cfg
│   ├── inventory/
│   └── playbooks/
├── kubernetes/               # K8s manifests
│   ├── traefik/
│   ├── registry/
│   ├── gitlab-runner/
│   ├── uptime-kuma/
│   └── omada/
└── scripts/                  # Helper scripts
```

## Adding Your Own Apps

1. Create a namespace for your app
2. Create deployment, service, and ingress manifests
3. Add DNS entry to Pi-hole if needed (or use *.lonbak.local wildcard)

Example for a simple app:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: registry.lonbak.local/my-app:latest
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: apps
spec:
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: my-app
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: apps
spec:
  rules:
    - host: my-app.lonbak.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

## CI/CD with GitLab

The GitLab Runner is configured to run jobs from GitLab.com. Example `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - deploy

build:
  stage: build
  tags:
    - lonbak
    - k3s
  script:
    - docker build -t registry.lonbak.local/my-app:$CI_COMMIT_SHA .
    - docker push registry.lonbak.local/my-app:$CI_COMMIT_SHA

deploy:
  stage: deploy
  tags:
    - lonbak
    - k3s
  script:
    - kubectl set image deployment/my-app my-app=registry.lonbak.local/my-app:$CI_COMMIT_SHA -n apps
```

## Maintenance

### Update Pi-hole

```bash
ssh root@192.168.0.11
pihole -up
```

### Update K3s

```bash
ssh admin@192.168.0.12
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.31.x+k3s1" sh -
```

### Backup

Key data to backup:
- Pi-hole: `/etc/pihole/` and `/etc/dnsmasq.d/`
- K3s: PersistentVolumeClaims (registry-data, uptime-kuma-data, omada-data)

## Troubleshooting

### K3s Issues

```bash
# Check K3s status
sudo systemctl status k3s
sudo journalctl -u k3s -f

# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -A
```

### Pi-hole Issues

```bash
# Check Pi-hole status
pihole status

# Restart Pi-hole
pihole restartdns
```

### Traefik Issues

```bash
# Check Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f
```

#!/bin/bash
# Install Traefik Ingress Controller via Helm
set -e

echo "Adding Traefik Helm repository..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

echo "Installing Traefik..."
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  -f values.yaml \
  --wait

echo "Traefik installed successfully!"
echo ""
echo "Dashboard available at: http://traefik.home.local"
echo "Make sure your DNS (Pi-hole) resolves *.home.local to the K3s node IP"

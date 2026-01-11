#!/bin/bash
# Setup Uptime Kuma monitors via API
#
# Prerequisites:
# 1. Create admin account at http://status.lonbak.local
# 2. Go to Settings -> API Keys -> Add API Key
# 3. Run this script with the API key
#
# Usage: ./setup-uptime-kuma.sh <api-key>

set -e

API_KEY="${1:-}"
UPTIME_KUMA_URL="${UPTIME_KUMA_URL:-http://status.lonbak.local}"

if [ -z "$API_KEY" ]; then
    echo "Usage: $0 <api-key>"
    echo ""
    echo "To get an API key:"
    echo "  1. Go to $UPTIME_KUMA_URL"
    echo "  2. Login and go to Settings -> API Keys"
    echo "  3. Click 'Add API Key' and copy the key"
    exit 1
fi

# Function to create a monitor
create_monitor() {
    local name="$1"
    local type="$2"
    local config="$3"

    echo "Creating monitor: $name"

    curl -s -X POST "$UPTIME_KUMA_URL/api/add-monitor" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$config" | jq -r '.msg // .error // "OK"'
}

echo "Setting up Uptime Kuma monitors..."
echo "URL: $UPTIME_KUMA_URL"
echo ""

# Pi-hole Admin
create_monitor "Pi-hole Admin" "http" '{
    "name": "Pi-hole Admin",
    "type": "http",
    "url": "http://192.168.0.11/admin",
    "method": "GET",
    "interval": 60,
    "maxretries": 3
}'

# Pi-hole DNS
create_monitor "Pi-hole DNS" "dns" '{
    "name": "Pi-hole DNS",
    "type": "dns",
    "hostname": "google.com",
    "dns_resolve_server": "192.168.0.11",
    "dns_resolve_type": "A",
    "interval": 60,
    "maxretries": 3
}'

# Proxmox
create_monitor "Proxmox" "http" '{
    "name": "Proxmox",
    "type": "http",
    "url": "https://192.168.0.10:8006",
    "method": "GET",
    "interval": 60,
    "maxretries": 3,
    "ignoreTls": true
}'

# K3s API
create_monitor "K3s API" "port" '{
    "name": "K3s API",
    "type": "port",
    "hostname": "192.168.0.12",
    "port": 6443,
    "interval": 60,
    "maxretries": 3
}'

# Traefik
create_monitor "Traefik" "http" '{
    "name": "Traefik",
    "type": "http",
    "url": "http://traefik.lonbak.local",
    "method": "GET",
    "interval": 60,
    "maxretries": 3
}'

# Omada Controller
create_monitor "Omada Controller" "http" '{
    "name": "Omada Controller",
    "type": "http",
    "url": "http://192.168.0.12:8088",
    "method": "GET",
    "interval": 60,
    "maxretries": 3
}'

# Gateway
create_monitor "Gateway" "ping" '{
    "name": "Gateway",
    "type": "ping",
    "hostname": "192.168.0.1",
    "interval": 60,
    "maxretries": 3
}'

echo ""
echo "Done! Check $UPTIME_KUMA_URL to verify monitors."

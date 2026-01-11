-- Uptime Kuma monitors setup
-- Run after initial admin account creation
-- kubectl exec -n uptime-kuma deployment/uptime-kuma -- sqlite3 /app/data/kuma.db < setup-monitors.sql

-- Pi-hole Admin (HTTPS with TLS ignore - Pi-hole redirects to HTTPS)
INSERT OR IGNORE INTO monitor (name, type, url, interval, maxretries, retry_interval, active, user_id, ignore_tls)
VALUES ('Pi-hole Admin', 'http', 'https://192.168.0.11/admin', 60, 3, 60, 1, 1, 1);

-- Pi-hole DNS
INSERT OR IGNORE INTO monitor (name, type, interval, maxretries, retry_interval, active, user_id, hostname, dns_resolve_server, dns_resolve_type)
VALUES ('Pi-hole DNS', 'dns', 60, 3, 60, 1, 1, 'google.com', '192.168.0.11', 'A');

-- Proxmox (HTTPS with TLS ignore)
INSERT OR IGNORE INTO monitor (name, type, url, interval, maxretries, retry_interval, active, user_id, ignore_tls)
VALUES ('Proxmox', 'http', 'https://192.168.0.10:8006', 60, 3, 60, 1, 1, 1);

-- K3s API (TCP Port)
INSERT OR IGNORE INTO monitor (name, type, hostname, port, interval, maxretries, retry_interval, active, user_id)
VALUES ('K3s API', 'port', '192.168.0.12', 6443, 60, 3, 60, 1, 1);

-- Traefik (HTTP - use IP since pod can't resolve lonbak.local, accept 404 as no default backend)
INSERT OR IGNORE INTO monitor (name, type, url, interval, maxretries, retry_interval, active, user_id, accepted_statuscodes_json)
VALUES ('Traefik', 'http', 'http://192.168.0.12', 60, 3, 60, 1, 1, '["200-299","404"]');

-- Omada Controller (HTTPS with TLS ignore - Omada uses self-signed cert on port 8043)
INSERT OR IGNORE INTO monitor (name, type, url, interval, maxretries, retry_interval, active, user_id, ignore_tls)
VALUES ('Omada Controller', 'http', 'https://192.168.0.12:8043', 60, 3, 60, 1, 1, 1);

-- Gateway (Ping)
INSERT OR IGNORE INTO monitor (name, type, hostname, interval, maxretries, retry_interval, active, user_id)
VALUES ('Gateway', 'ping', '192.168.0.1', 60, 3, 60, 1, 1);

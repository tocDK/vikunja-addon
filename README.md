# Vikunja Add-on for Home Assistant

[![Home Assistant Add-on](https://img.shields.io/badge/Home%20Assistant-Add--on-blue.svg)](https://www.home-assistant.io/hassio/)

> **Warning — Proof of Concept**
> This add-on is in early development. It works but has not been extensively tested
> in production. Use at your own risk. Data is stored locally in SQLite — back up
> `/data` before upgrading. Expect breaking changes before v1.0.

Self-hosted task management for your household, running as a Home Assistant add-on.

[Vikunja](https://vikunja.io) is an open-source, self-hosted to-do app. This add-on wraps it for
easy installation on Home Assistant OS.

## Features

- **Sidebar integration** — access Vikunja directly from the HA sidebar via ingress
- **Multi-user** — each household member gets their own account
- **Shared projects** — create shared task lists (e.g., groceries, chores)
- **Private lists** — each user also has personal tasks
- **External access** — access from your phone outside your home network
- **Persistent storage** — SQLite database, survives restarts and updates

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**
2. Click the **⋮** menu (top right) → **Repositories**
3. Add this URL:
   ```
   https://github.com/tocDK/vikunja-addon
   ```
4. Find **Vikunja** in the store and click **Install**
5. Start the add-on — **Vikunja** appears in your sidebar

## First-time setup

1. Open Vikunja from the sidebar
2. Register your account
3. Have your household members register
4. Disable registration in the add-on config
5. Create a shared project and invite members

## Configuration

| Option | Default | Description |
|---|---|---|
| `external_url` | _(empty)_ | Public URL for phone access (e.g., `https://vikunja.yourdomain.com`) |
| `enable_registration` | `true` | Allow new user signups. Disable after all members register. |

## External URL Setup

By default, Vikunja is only accessible via the HA sidebar (ingress). To access it from your
phone or outside your home network, you need to expose it externally.

### How it works

The add-on exposes port **3456** on your HA host. You then set up a reverse proxy to handle
SSL and route traffic to that port.

### Step 1: DNS

Point a subdomain to your Home Assistant server's public IP:

```
vikunja.yourdomain.com  →  your-public-ip
```

If you use a dynamic DNS service (e.g., DuckDNS), create a CNAME instead.

### Step 2: Reverse Proxy

Choose one of these setups depending on what you already run.

#### Nginx

```nginx
server {
    listen 443 ssl;
    server_name vikunja.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/vikunja.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/vikunja.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3456;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### Caddy

```
vikunja.yourdomain.com {
    reverse_proxy localhost:3456
}
```

Caddy handles SSL automatically via Let's Encrypt.

#### Traefik

```yaml
http:
  routers:
    vikunja:
      rule: "Host(`vikunja.yourdomain.com`)"
      entryPoints:
        - websecure
      service: vikunja
      tls:
        certResolver: letsencrypt
  services:
    vikunja:
      loadBalancer:
        servers:
          - url: "http://localhost:3456"
```

### Step 3: Configure the Add-on

1. In HA, go to **Settings → Add-ons → Vikunja → Configuration**
2. Set **External URL** to your public URL (e.g., `https://vikunja.yourdomain.com`)
3. Restart the add-on

### Step 4: Firewall / Router

Ensure port **443** (HTTPS) on your router forwards to your reverse proxy.
Do **not** expose port 3456 directly — always use a reverse proxy with SSL.

### Using the Nginx Proxy Manager Add-on

If you run the [Nginx Proxy Manager](https://github.com/hassio-addons/addon-nginx-proxy-manager)
add-on on HA, you can set it up there:

1. Add a new proxy host
2. Domain: `vikunja.yourdomain.com`
3. Forward to: `homeassistant.local` port `3456`
4. Enable SSL with Let's Encrypt

## Vikunja Version

This add-on mirrors Vikunja releases. Add-on version `2.1.0` = Vikunja `2.1.0`.

## Support

- [Vikunja Documentation](https://vikunja.io/docs/)
- [Report issues](https://github.com/tocDK/vikunja-addon/issues)

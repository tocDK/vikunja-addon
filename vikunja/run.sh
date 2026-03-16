#!/usr/bin/with-contenv bashio

# =============================================================================
# Vikunja Add-on Startup Script
# =============================================================================

bashio::log.info "Starting Vikunja add-on..."

# ---------------------------------------------------------------------------
# Read add-on options
# ---------------------------------------------------------------------------
if bashio::config.has_value 'external_url'; then
    EXTERNAL_URL=$(bashio::config 'external_url')
else
    EXTERNAL_URL=""
fi
ENABLE_REGISTRATION=$(bashio::config 'enable_registration')

# ---------------------------------------------------------------------------
# JWT secret — generate once, persist across restarts
# ---------------------------------------------------------------------------
JWT_SECRET_FILE="/data/jwt_secret"
if [ ! -f "${JWT_SECRET_FILE}" ]; then
    bashio::log.info "Generating JWT secret (first run)..."
    head -c 32 /dev/urandom | base64 | tr -d '\n' > "${JWT_SECRET_FILE}"
fi
JWT_SECRET=$(cat "${JWT_SECRET_FILE}")

# ---------------------------------------------------------------------------
# Ensure data directories exist
# ---------------------------------------------------------------------------
mkdir -p /data/files

# ---------------------------------------------------------------------------
# Configure Vikunja via environment variables
# ---------------------------------------------------------------------------
export VIKUNJA_SERVICE_JWTSECRET="${JWT_SECRET}"
export VIKUNJA_DATABASE_TYPE="sqlite"
export VIKUNJA_DATABASE_PATH="/data/vikunja.db"
export VIKUNJA_FILES_BASEPATH="/data/files"
export VIKUNJA_SERVICE_ENABLEREGISTRATION="${ENABLE_REGISTRATION}"

# Set public URL
if bashio::var.has_value "${EXTERNAL_URL}"; then
    export VIKUNJA_SERVICE_PUBLICURL="${EXTERNAL_URL}"
    bashio::log.info "Public URL: ${EXTERNAL_URL}"
else
    export VIKUNJA_SERVICE_PUBLICURL="http://homeassistant.local:3456"
    bashio::log.info "Public URL: http://homeassistant.local:3456"
fi

# Bind to all interfaces
export VIKUNJA_SERVICE_INTERFACE=":3456"

# ---------------------------------------------------------------------------
# Set up nginx SSL proxy if certificates exist
# ---------------------------------------------------------------------------
if [ -f /ssl/fullchain.pem ] && [ -f /ssl/privkey.pem ]; then
    bashio::log.info "SSL certificates found — starting HTTPS proxy on port 8443"

    cat > /tmp/nginx.conf <<'NGINX_EOF'
worker_processes 1;
pid /tmp/nginx.pid;
error_log /dev/stderr;

events {
    worker_connections 128;
}

http {
    access_log off;

    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 8443 ssl;

        ssl_certificate /ssl/fullchain.pem;
        ssl_certificate_key /ssl/privkey.pem;

        location / {
            proxy_pass http://127.0.0.1:3456;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
        }
    }
}
NGINX_EOF

    nginx -c /tmp/nginx.conf &
else
    bashio::log.info "No SSL certificates found at /ssl/ — HTTPS proxy disabled"
    bashio::log.info "Install DuckDNS add-on with Let's Encrypt to enable HTTPS"
fi

# ---------------------------------------------------------------------------
# Start Vikunja
# ---------------------------------------------------------------------------
bashio::log.info "Starting Vikunja..."
exec /app/vikunja/vikunja

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

# Set public URL if configured
if bashio::var.has_value "${EXTERNAL_URL}"; then
    export VIKUNJA_SERVICE_PUBLICURL="${EXTERNAL_URL}"
    bashio::log.info "External URL: ${EXTERNAL_URL}"
else
    bashio::log.info "No external URL configured — ingress-only mode"
    export VIKUNJA_SERVICE_PUBLICURL="http://localhost:3456"
fi

# Bind to all interfaces so both ingress (nginx) and external access work
export VIKUNJA_SERVICE_INTERFACE=":3456"

# ---------------------------------------------------------------------------
# Generate nginx config with ingress path baked in
# ---------------------------------------------------------------------------
INGRESS_ENTRY=$(bashio::addon.ingress_entry)
bashio::log.info "Ingress path: ${INGRESS_ENTRY}"

cat > /tmp/nginx.conf <<NGINX_EOF
worker_processes 1;
pid /tmp/nginx.pid;
error_log /dev/stderr;

events {
    worker_connections 128;
}

http {
    access_log off;

    map \$http_upgrade \$connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 8099;

        allow 172.30.32.2;
        deny all;

        location / {
            proxy_pass http://127.0.0.1:3456;

            proxy_http_version 1.1;
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header Accept-Encoding "";

            sub_filter_once on;
            sub_filter '<head>' '<head><base href="${INGRESS_ENTRY}/">';

            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \$connection_upgrade;

            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
        }
    }
}
NGINX_EOF

# ---------------------------------------------------------------------------
# Start nginx (ingress proxy) in background
# ---------------------------------------------------------------------------
bashio::log.info "Starting nginx ingress proxy..."
nginx -c /tmp/nginx.conf &

# ---------------------------------------------------------------------------
# Start Vikunja
# ---------------------------------------------------------------------------
bashio::log.info "Starting Vikunja..."
exec /app/vikunja/vikunja

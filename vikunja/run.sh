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
# Start nginx ingress proxy
# ---------------------------------------------------------------------------
bashio::log.info "Starting nginx ingress proxy on port 8099..."
nginx -c /etc/nginx/nginx.conf &

# ---------------------------------------------------------------------------
# Start Vikunja
# ---------------------------------------------------------------------------
bashio::log.info "Starting Vikunja..."
exec /app/vikunja/vikunja

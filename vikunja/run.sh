#!/usr/bin/with-contenv bashio

# =============================================================================
# Vikunja Add-on Startup Script
# =============================================================================

bashio::log.info "Starting Vikunja add-on..."

# ---------------------------------------------------------------------------
# Read add-on options
# ---------------------------------------------------------------------------
EXTERNAL_URL=$(bashio::config 'external_url')
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
    export VIKUNJA_SERVICE_PUBLICURL="/"
fi

# Bind to all interfaces so both ingress (nginx) and external access work
export VIKUNJA_SERVICE_INTERFACE=":3456"

# ---------------------------------------------------------------------------
# Start nginx (ingress proxy) in background
# ---------------------------------------------------------------------------
bashio::log.info "Starting nginx ingress proxy..."
nginx -c /etc/nginx/nginx.conf &

# ---------------------------------------------------------------------------
# Start Vikunja
# ---------------------------------------------------------------------------
bashio::log.info "Starting Vikunja..."
exec /app/vikunja/vikunja

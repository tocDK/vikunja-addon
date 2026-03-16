ARG BUILD_FROM

# Stage 1: Get Vikunja binary from official image
FROM vikunja/vikunja:2.1.0 AS vikunja

# Stage 2: Build on HA base image
FROM ${BUILD_FROM}

# Install nginx
RUN apk add --no-cache nginx

# Copy Vikunja binary and frontend
COPY --from=vikunja /app/vikunja /app/vikunja/vikunja

# Vikunja serves its own frontend from the binary — no separate files needed

# Copy rootfs overlay (nginx config)
COPY rootfs /

# Copy startup script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Ensure data directories exist
RUN mkdir -p /data/files

# Labels
LABEL \
    io.hass.name="Vikunja" \
    io.hass.description="Self-hosted task management for your household" \
    io.hass.arch="amd64|aarch64" \
    io.hass.type="addon" \
    io.hass.version="2.1.0"

# Vikunja listens on 3456, nginx ingress proxy on 8099
EXPOSE 3456 8099

CMD [ "/run.sh" ]

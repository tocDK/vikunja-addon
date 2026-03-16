# vikunja-addon — Claude Instructions

## What this is

A Home Assistant add-on that wraps Vikunja (self-hosted task manager) for easy installation on HAOS.
Single-purpose — no other services bundled.

## Repo layout

```
repository.yaml          # HA add-on store metadata
vikunja/                 # The add-on
  config.yaml            # HA add-on definition (slug, arch, ingress, ports, options)
  Dockerfile             # Multi-stage: vikunja/vikunja image → HA Alpine base + nginx
  build.yaml             # Per-arch base images (amd64, aarch64)
  run.sh                 # Startup: bashio config → env vars → nginx + vikunja
  DOCS.md                # Shown in HA add-on info panel
  CHANGELOG.md
  translations/en.yaml   # Config option labels for HA UI
  rootfs/
    etc/nginx/nginx.conf # Ingress proxy: :8099 → :3456
```

## Key architecture decisions

- **init: false** — no S6 overlay; run.sh manages nginx (background) + vikunja (foreground)
- **Nginx ingress proxy** — listens on :8099, accepts only 172.30.32.2 (Supervisor), proxies to Vikunja on :3456
- **SQLite** — no external database; stored at /data/vikunja.db
- **JWT secret** — generated on first run, persisted at /data/jwt_secret
- **Versioning** — mirrors Vikunja releases (e.g., add-on 2.1.0 = Vikunja 2.1.0)

## Updating Vikunja version

1. Update the `FROM vikunja/vikunja:<version>` tag in `Dockerfile`
2. Update `version` in `config.yaml`
3. Update `io.hass.version` label in `Dockerfile`
4. Add entry to `CHANGELOG.md`

## Testing locally

The add-on builds inside HAOS. To test the Dockerfile locally:

```bash
cd vikunja
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.21 -t vikunja-addon .
docker run -p 3456:3456 -v vikunja-data:/data vikunja-addon
```

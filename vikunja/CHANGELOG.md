# Changelog

## 2.1.4

- Fix lazy-loaded JS chunks and CSS preloads (dynamic imports use different quoting patterns)
- Fix API path rewriting in JavaScript for login/token refresh calls

## 2.1.3

- Fix 404s for fonts, images, and SVGs referenced from CSS and JavaScript

## 2.1.2

- Fix API URL for ingress — inject correct API path so frontend connects through ingress proxy

## 2.1.1

- Add HA ingress support (sidebar panel via nginx sub_filter)
- Remove SSL proxy on port 8443 (use ingress or Cloudflare Tunnel instead)

## 2.1.0

- Initial release
- Wraps Vikunja 2.1.0
- HA ingress support (sidebar panel)
- External access via configurable port
- SQLite storage with persistent data
- Multi-user with registration control

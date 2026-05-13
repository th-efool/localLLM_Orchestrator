# Remote Access Architecture

## Phase 3 target
- Remote transport: Tailscale only.
- Public internet ingress: none.
- Remote entrypoint: Traefik on `443` via `tailscale0`.
- API path: remote client -> Tailscale -> Traefik -> LiteLLM `/v1`.
- Web path: remote browser -> Tailscale -> Traefik -> Open WebUI.
- Backend services: no direct remote access.
- Local/offline mode: loopback endpoints continue without Tailscale.

## Exposure policy
Allowed remote surface:
- `https://$DOMAIN_NAME/` -> Open WebUI.
- `https://$DOMAIN_NAME/v1/*` -> LiteLLM.
- `https://$DOMAIN_NAME/health/*` -> LiteLLM health.

Blocked remote surface:
- `3000` Open WebUI direct.
- `4000` LiteLLM direct.
- `11434` Ollama direct.
- `8001` vLLM direct.
- Docker backend network.
- Tailscale Funnel unless explicitly approved.

## Modes
### Local/offline mode
Use when single user or no network.

Config:
```bash
TRAEFIK_HTTP_BIND=127.0.0.1
TRAEFIK_HTTPS_BIND=127.0.0.1
DOMAIN_NAME=localhost
TAILSCALE_DOMAIN=localhost
```

Endpoints:
- Open WebUI: `http://127.0.0.1:3000` or `https://localhost/`.
- LiteLLM: `http://127.0.0.1:4000/v1` or `https://localhost/v1`.

### Remote team mode
Use when team members need private access.

Config:
```bash
TRAEFIK_HTTP_BIND=127.0.0.1
TRAEFIK_HTTPS_BIND=<workstation-tailnet-ip>
DOMAIN_NAME=<workstation-tailnet-dns-name>
TAILSCALE_DOMAIN=<workstation-tailnet-dns-name>
```

Endpoints:
- Open WebUI: `https://$DOMAIN_NAME/`.
- LiteLLM: `https://$DOMAIN_NAME/v1`.

## Gateway-first rule
- Remote users never connect to app ports directly.
- All remote HTTP traffic enters Traefik first.
- Traefik applies TLS, headers, body-size limits, rate limits, in-flight limits, and access logs.
- LiteLLM remains canonical API gateway for all tools and agents.

## Docker binding policy
- `litellm`: `127.0.0.1:4000:4000` only.
- `open-webui`: `127.0.0.1:3000:8080` only.
- `vllm`: `127.0.0.1:8001:8000` only, optional profile.
- `reverse-proxy`: `TRAEFIK_HTTPS_BIND:443:443`.

## Remote IDE workflows
### VS Code SSH
- Connect to workstation using Tailscale SSH.
- Run repo commands on workstation terminal.
- Use API/web through `https://$DOMAIN_NAME`.

### JetBrains Gateway / terminal-only
- Connect over Tailscale SSH.
- Keep app access through Traefik URL.
- Use SSH tunnels only for emergency local debugging.

## Validation helpers
- `./scripts/remote_healthcheck.sh https://$DOMAIN_NAME`.
- `./scripts/remote_api_verify.sh https://$DOMAIN_NAME/v1 <user-key> <model>`.
- `./scripts/validate_hardening.sh`.

## Rollback to local-only
```bash
TRAEFIK_HTTP_BIND=127.0.0.1
TRAEFIK_HTTPS_BIND=127.0.0.1
DOMAIN_NAME=localhost
TAILSCALE_DOMAIN=localhost
docker compose up -d
```

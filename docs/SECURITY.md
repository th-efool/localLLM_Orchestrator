# Security Hardening (Multi-User, Single-Node)

## Security baseline
- Keep all app ports loopback-bound (`127.0.0.1`) on host.
- Expose only reverse proxy on `tailscale0` (not WAN).
- Require auth on Open WebUI (`WEBUI_AUTH=True`).
- Require API keys on LiteLLM; per-user keys, no shared key in clients.
- Store secrets in `.env` + host secret store; rotate quarterly or on incident.

## TLS termination + reverse proxy strategy
- Add Traefik or Caddy as edge on host.
- Terminate TLS at proxy using Tailscale certificates or internal CA certs.
- Proxy routes:
  - `/v1/*` -> `litellm:4000`
  - `/` -> `open-webui:8080`
- Enforce HTTPS only, HSTS, secure headers, request size limits.

## API authentication strategy
- LiteLLM master key only for admin/bootstrap.
- Create per-user/per-service scoped keys with ownership metadata.
- Enforce key revocation runbook and key age policy.
- Disable anonymous access anywhere.

## API key management strategy
- Naming: `user:<id>:<purpose>:<date>`.
- Rotation: overlap window (new key issued before old revoked).
- Audit: track key creation/revocation actor and timestamp.
- Never place keys in committed files; only templates/examples.

## User isolation assumptions
- Logical isolation (key-level, quotas, limits, audit) not compute sandboxing.
- Treat prompts/outputs as tenant data; restrict log visibility by role.
- For strict tenant isolation, plan separate nodes or isolated runtimes later.

## Rate limiting + concurrency guardrails
- Enforce at reverse proxy and LiteLLM.
- Baseline limits (tune per GPU/model):
  - 30 req/min per user key (burst 10)
  - 5 concurrent requests per key
  - request timeout 120s
- Model-level guardrails: max tokens and context length caps by route.

## Firewall assumptions
- Host default deny inbound.
- Allow inbound only on `tailscale0` proxy port (443).
- Block direct access to 3000/4000/11434/8001 from LAN/WAN.

# Multi-User Architecture (Hardened Single Node)

## Topology (recommended)
```
Remote Devices (Tailnet)
        |
   Tailscale (zero-trust)
        |
 [Traefik/Caddy TLS Edge]
   |                    |
/v1/*                / (UI)
   |                    |
 LiteLLM ---------> Open WebUI
   |
 Ollama / vLLM (local GPU)
   |
PostgreSQL + Redis (state/queues/limits)
```

## Service boundary layering
1. **Network boundary**: Tailscale ACL + host firewall.
2. **Edge boundary**: TLS termination, auth/rate policies.
3. **API boundary**: LiteLLM key auth + model routing policies.
4. **Data boundary**: Postgres for durable state; Redis for ephemeral control planes.

## Compose integration recommendations
- Add `reverse-proxy` service (Traefik or Caddy).
- Bind app services to internal Docker network; only proxy published.
- Convert service `ports` to either:
  - internal-only (remove host publish), or
  - loopback-only for local ops fallback.
- Add healthchecks for proxy/backend reachability.

## Runtime/database recommendations
- Migrate LiteLLM state to PostgreSQL (durable multi-user metadata/audit).
- Use Redis for:
  - distributed rate-limit counters
  - short-lived request/session coordination
  - optional queue buffering for overload
- Session/state assumptions:
  - Open WebUI sessions are user-scoped.
  - API keys map to users/services for audit attribution.

## Multi-user concurrency assumptions
- Concurrent users share GPU and model workers.
- Tail latency rises non-linearly with long context + high concurrency.
- Reserve admin/headroom capacity (10-20%) for control operations.

## Future scaling (without Kubernetes)
- Split edge + inference onto separate hosts later.
- Add dedicated model nodes behind LiteLLM routes.
- Introduce read replicas for Postgres if audit/reporting load grows.

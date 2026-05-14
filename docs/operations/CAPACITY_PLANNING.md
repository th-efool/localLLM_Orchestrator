# Capacity Planning (Single Node, Multi-User)

## Planning model
Capacity is bounded by:
- GPU memory per loaded model
- average context length and output length
- concurrent active requests
- target p95 latency SLO

## Guardrails (initial)
- Per-key concurrency: 3-5
- Global concurrency: set to safe GPU saturation threshold from load test
- Max context per route: strict cap by model capability
- Max output tokens: default conservative cap

## Load-test workflow
1. Pick representative prompts (short, medium, long context).
2. Run stepped concurrency tests (1, 2, 4, 8, ...).
3. Record p50/p95 latency, error rate, GPU memory headroom.
4. Set production limits at first stable step below SLO breach.

## PostgreSQL recommendations
- Use Postgres for durable multi-user metadata, key ownership, policy, and audit tables.
- Enable daily backups and WAL retention suitable for recovery objectives.

## Redis recommendations
- Use Redis for token bucket counters and transient concurrency locks.
- Set conservative TTLs to avoid stale limiter state.

## Operational runbooks
### Overload response
- Lower per-key concurrency.
- Lower max output tokens.
- Temporarily disable heavy models/routes.

### Degraded model response
- Drain route from LiteLLM.
- Route traffic to fallback model.
- Re-enable after health + latency stabilization.

## Hardened topology profile (compose)
- `base`: litellm + open-webui + ollama
- `hardened`: + traefik/caddy + postgres + redis
- Keep single-node deployment and simple rollback to base profile.

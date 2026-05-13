# Runtime Hardening Layer (Phase 1)

## Hardened Topology

```text
                Internet / Tailnet client
                          |
                    443 / 80 (TLS)
                          |
                    [ Traefik reverse-proxy ]
                   /          |            \
             /v1/*       /health/*          /
               |             |               |
          [ LiteLLM ]   [ LiteLLM ]    [ Open WebUI ]
               |
    [ Ollama / vLLM (backend-only) ]

Observability (optional profile)
  Prometheus <-- scrape --> Traefik admin + service health endpoints
  Grafana ---- query -----> Prometheus
```

## Security Defaults Implemented
- TLS termination at Traefik on `:443` with ACME certificate flow (`:80` for HTTP->HTTPS/ACME).
- LiteLLM and Open WebUI no longer publish host ports; only exposed on internal Docker network.
- Internal-only backend network (`local-ai-backend`) prevents direct host/network access to internal services.
- JSON structured runtime + access logs for proxy at `logs/traefik/*.log`.
- Request body size limit and per-client rate limits in proxy.
- Proxy timeout controls (`dial`, `response header`, `read`, `write`, `idle`).
- Open WebUI auth enabled by default.

## Compose Services Added
- `reverse-proxy` (Traefik) for TLS termination, routing, access logging, and rate limiting.
- `prometheus` + `grafana` (profile `with-observability`) for starter observability.

## Routing and Exposure Policy
- Public entrypoint: only `reverse-proxy`.
- Secure LiteLLM exposure: `https://$DOMAIN_NAME/v1/*`.
- Secure Open WebUI exposure: `https://$DOMAIN_NAME/`.
- Internal-only services: `litellm`, `open-webui`, `ollama`, `vllm-qwen-coder`, `openhands` on `local-ai-backend`.

## Tailscale-Compatible Routing
Two supported patterns:
1. **Serve/Funnel to Traefik**: map tailnet/FQDN to host `443` and keep Traefik TLS/routing controls.
2. **Direct Tailnet to Traefik domain**: set DNS for `DOMAIN_NAME` to tailnet address and allow `443` inbound in ACLs.

Recommended: keep all external access (including tailnet) through Traefik so rate limits/logging stay centralized.

## API Key Enforcement Guidance
- LiteLLM key enforcement remains authoritative using `LITELLM_MASTER_KEY`.
- Clients must send `Authorization: Bearer <key>` for `/v1/*` endpoints.
- Keep distinct keys per integration/user and rotate periodically.
- Do not embed master key in public browser clients; for Open WebUI, use server-side env only.

## Guardrails and Limits
Configure via `.env`:
- `TRAEFIK_RL_AVG`, `TRAEFIK_RL_BURST`, `TRAEFIK_RL_WEBUI_AVG`, `TRAEFIK_RL_WEBUI_BURST`
- `TRAEFIK_MAX_REQUEST_BODY_BYTES`
- `TRAEFIK_READ_TIMEOUT`, `TRAEFIK_WRITE_TIMEOUT`, `TRAEFIK_IDLE_TIMEOUT`
- `TRAEFIK_LITELLM_INFLIGHT`, `TRAEFIK_WEBUI_INFLIGHT`

Concurrency guardrails:
- Traefik in-flight request caps enforce per-route concurrency guardrails.
- Model concurrency remains bounded by backend service variables (`OLLAMA_NUM_PARALLEL`, etc.).

## Hardened Startup Workflow
```bash
cp .env.example .env   # if needed
# set DOMAIN_NAME, ACME_EMAIL, LITELLM_* secrets
scripts/hardened_up.sh
```

## Runtime Validation Procedures
```bash
scripts/validate_hardening.sh
curl -k https://$DOMAIN_NAME/health/readiness
curl -k https://$DOMAIN_NAME/v1/models -H "Authorization: Bearer $LITELLM_MASTER_KEY"
docker compose logs reverse-proxy --tail=100
```

## Failure-Mode Troubleshooting
1. **TLS cert not issued**
   - Check DNS resolves to host and ports `80/443` reachable.
   - Inspect `docker compose logs reverse-proxy` for ACME errors.
2. **429 responses spike**
   - Increase `TRAEFIK_RL_AVG`/`TRAEFIK_RL_BURST` or narrow offending client traffic.
   - Validate clients are not retry-looping.
3. **413 payload too large**
   - Increase `TRAEFIK_MAX_REQUEST_BODY_BYTES` to acceptable bound.
4. **504/502 upstream timeout**
   - Increase upstream timeout env vars and inspect backend health.
   - Confirm model container has enough memory/GPU headroom.
5. **Open WebUI login/access issues**
   - Verify `WEBUI_AUTH=True` and initialize admin account on first launch.
6. **No metrics in Grafana**
   - Start profile: `docker compose --profile with-observability up -d`.
   - Verify Prometheus target health in `http://localhost:9090/targets`.

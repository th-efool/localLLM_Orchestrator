# Troubleshooting

## Fast checks
- Run `make health` for full dependency and endpoint diagnostics.
- Run `docker compose ps` and confirm all services are `healthy`.
- Run `docker compose logs -f litellm` for boot blockers.

## Common failures

### Postgres or Redis unhealthy
- Verify env values match `.env.example`.
- Ensure named volumes are writable: `docker volume inspect postgres_data redis_data`.
- Restart only infra: `docker compose restart postgres redis`.

### LiteLLM stuck in starting
- Check migration gate container result: `docker compose ps litellm-migrate`.
- Validate config mount path exists: `litellm/litellm.yaml`.
- Confirm no schema drift flags are overridden (`DISABLE_PRISMA_GENERATE=true`, `LITELLM_DISABLE_AUTO_MIGRATIONS=true`).

### DNS or endpoint intermittency
- Compose uses dual resolvers (`1.1.1.1`, `8.8.8.8`) for resilience.
- Retry after Docker/WSL restart: `make down && make up`.

### Reset to clean state
- Full reset: `make clean && make up`.
- DB-only reset: `make reset-db`.

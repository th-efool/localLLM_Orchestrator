# OPERATIONS

## Topology
```text
Open WebUI / local tools
         |
         v
LiteLLM (http://localhost:4000/v1)
         |
         v
Ollama (host.docker.internal:11434)
```

## Canonical workflow
1. `cp .env.example .env`
2. Set `LITELLM_MASTER_KEY`, `LITELLM_SALT_KEY`
3. Confirm host Ollama: `curl -fsS http://localhost:11434/api/tags`
4. `make up`
5. `make health`
6. `make verify`

Optional:
- `make up-vllm` (uses `with-vllm` profile only if present in compose; otherwise starts base stack)

## Lifecycle
- Stop: `make down`
- Restart: `make restart`
- Logs: `make logs`
- Cleanup volumes: `make clean`

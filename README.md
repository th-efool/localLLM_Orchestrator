# Local AI Inference + Orchestration Stack

## Runtime topology
Host-native Ollama (WSL/Linux host) → Docker LiteLLM → Docker Open WebUI → optional Traefik/Postgres/Redis.

## Why host-native Ollama
For workstation-scale deployments with large local model stores, host-native Ollama reuses the existing host cache (including `qwen3:32b`, `deepseek-r1:32b`, `mistral-small`, and GGUF models), avoids duplicate Docker volume storage, eliminates model re-downloads, and reduces operational complexity.

## Required endpoints
- Ollama (host): `http://localhost:11434`
- LiteLLM (container exposed): `http://localhost:4000/v1`
- Open WebUI (container exposed): `http://localhost:3000`

## Environment
1. `cp .env.example .env`
2. Set `LITELLM_MASTER_KEY` and `LITELLM_SALT_KEY`
3. Ensure `.env` contains:
   - `OLLAMA_API_BASE=http://host.docker.internal:11434`

## Startup
```bash
make up
make health
```

## Operations
```bash
make logs
make down
```

## Validation checklist
```bash
docker compose config
curl -fsS http://localhost:11434/api/tags
curl -fsS http://localhost:4000/health/readiness
curl -fsS http://localhost:3000/health
curl -sS -H "Authorization: Bearer $LITELLM_MASTER_KEY" http://localhost:4000/v1/models
```

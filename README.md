# Local AI Inference + Orchestration Stack

## Runtime topology
Host-native Ollama (WSL/Linux host) → Docker LiteLLM → Docker Open WebUI → optional Traefik/Postgres/Redis.

## Why host-native Ollama
For workstation-scale deployments with large local model stores, host-native Ollama reuses the existing host cache (including `qwen3:32b`, `deepseek-r1:32b`, `mistral-small`, and GGUF models), avoids duplicate Docker volume storage, eliminates model re-downloads, and reduces operational complexity.

## Preflight requirements
- Host Ollama is running and reachable at `http://localhost:11434`.
- `.env` sets `OLLAMA_API_BASE=http://host.docker.internal:11434`.
- Docker Engine and Docker Compose plugin are installed.

## Required endpoints
- Ollama (host): `http://localhost:11434`
- LiteLLM (container exposed): `http://localhost:4000/v1`
- Open WebUI (container exposed): `http://localhost:3000`

## Canonical workflow
```bash
cp .env.example .env
make up
make health
make verify
# optional (future profile helper)
make up-vllm
# lifecycle
make logs
make restart
make down
make clean
```

## First-run failure hints
- **Host Ollama unreachable**: run `curl -fsS http://localhost:11434/api/tags`; if it fails, start Ollama on host before `make up`.
- **Missing LiteLLM keys**: set `LITELLM_MASTER_KEY` and `LITELLM_SALT_KEY` in `.env`.
- **Unhealthy Postgres/Redis**: run `docker compose ps` and `make logs`; wait for DB/cache health before retrying `make health` or `make verify`.

## Validation checklist
```bash
docker compose config
curl -fsS http://localhost:11434/api/tags
curl -fsS http://localhost:4000/health/readiness
curl -fsS http://localhost:3000/health
curl -sS -H "Authorization: Bearer $LITELLM_MASTER_KEY" http://localhost:4000/v1/models
```

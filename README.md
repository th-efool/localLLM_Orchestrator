# Local AI Inference + Orchestration Stack

## Runtime topology
Open WebUI → LiteLLM → host-native Ollama plus optional GPU vLLM containers → Traefik/Postgres/Redis.

## Why host-native Ollama
For workstation-scale deployments with large local model stores, host-native Ollama reuses the existing host cache (including `qwen3:32b`, `deepseek-r1:32b`, `mistral-small`, and GGUF models), avoids duplicate Docker volume storage, eliminates model re-downloads, and reduces operational complexity.

## Required endpoints
Local/offline:
- Ollama (host): `http://localhost:11434`
- LiteLLM: `http://localhost:4000/v1`
- Open WebUI: `http://localhost:3000`
- vLLM OpenAI endpoint (optional profile): `http://localhost:8001/v1`

Remote Phase 3:
- Open WebUI: `https://$DOMAIN_NAME/`
- LiteLLM: `https://$DOMAIN_NAME/v1`
- Direct `3000`, `4000`, `11434`, and `8001` remote access: blocked

## Clean clone startup
```bash
cp .env.example .env
make up
make verify
```

`.env.example` contains runnable workstation defaults, including:
- `POSTGRES_USER=localai`
- `POSTGRES_PASSWORD=localai_password`
- `POSTGRES_DB=litellm`
- `OLLAMA_API_BASE=http://host.docker.internal:11434`

Host Ollama must already be running on `http://localhost:11434`; no containerized Ollama is used.

## Startup
```bash
make verify-env  # env, compose interpolation, URLs, Ollama reachability
make up          # LiteLLM + Open WebUI + Postgres + Redis + Traefik
make up-vllm     # add GPU vLLM profile and unified LiteLLM routing
make health
make diagnose     # forensic runtime diagnostics
make diagnose-network # Docker↔WSL/Ollama diagnostics
```

## Operations
```bash
make logs
make diagnose
make diagnose-network
make down
```

## Validation checklist
```bash
docker compose --env-file .env config
curl -fsS http://localhost:11434/api/tags
curl -fsS http://localhost:4000/health/readiness
curl -fsS http://localhost:3000/health
curl -sS -H "Authorization: Bearer $LITELLM_MASTER_KEY" http://localhost:4000/v1/models
curl -fsS http://localhost:8001/v1/models        # when vLLM profile is running
docker exec localai-vllm nvidia-smi              # when vLLM profile is running
```

## Phase 3 remote setup
See `docs/PHASE3_OWNER_CONFIG.md`, `docs/TAILSCALE_SETUP.md`, and `docs/REMOTE_RUNBOOK.md`.

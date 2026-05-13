# Local AI Inference + Orchestration Stack (Docker Compose)

## Runtime topology (expected)
- `open-webui` (`localhost:3000`) -> `litellm` (`litellm:4000/v1`) inside Docker network.
- `litellm` (`localhost:4000/v1`) -> Ollama route via `OLLAMA_API_BASE`.
- Default `OLLAMA_API_BASE=http://host.docker.internal:11434` (host Ollama).
- Optional `with-ollama` profile runs containerized Ollama (`ollama:11434`); use `OLLAMA_API_BASE=http://ollama:11434`.
- Optional `with-vllm` profile runs `vllm-qwen-coder` (`localhost:8001`) for local OpenAI-compatible serving.

## Access URLs
- Open WebUI: `https://localhost/`
- LiteLLM OpenAI API: `https://localhost/v1`
- LiteLLM readiness: `https://localhost/health/readiness`

## Startup
1. `cp .env.example .env`
2. Set `LITELLM_MASTER_KEY` and `LITELLM_SALT_KEY`.
3. Verify host Ollama: `curl -fsS http://localhost:11434/api/tags`.
4. Start stack: `make start`.

Optional profiles:
- vLLM: `make start-vllm`
- Containerized Ollama:
  - `export OLLAMA_API_BASE=http://ollama:11434`
  - `make start-ollama`
- OpenHands runtime:
  - `make start-openhands`
  - Open `http://localhost:3001`
  - `make verify-openhands`

## Operational verification checklist
- Compose validity: `make validate`
- Running services: `make ps`
- LiteLLM readiness: `curl -kf https://localhost/health/readiness`
- Model list + base routing check: `make healthcheck`
- API/routing checks: `make api-verify`
- Open WebUI health: `curl -kf https://localhost/health`

PostgreSQL + Prisma verification:
- `docker compose up -d postgres litellm`
- `docker compose exec postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"`
- `docker compose logs litellm | rg -i "prisma|migrat|ready|error"`
- `docker compose exec litellm sh -lc 'echo $DATABASE_URL'`

## API validation (OpenAI-compatible)
```bash
export OPENAI_API_KEY='sk-local-change-me'
```

List models:
```bash
curl -sS -H "Authorization: Bearer $OPENAI_API_KEY" \
  http://localhost:4000/v1/models
```
Expected: `data[].id` includes baseline routes: `qwen32b`, `deepseek_r1_32b`, `mistral_small`.

Chat completion (qwen32b):
```bash
curl -sS http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen32b","messages":[{"role":"user","content":"Reply with OK"}],"temperature":0}'
```
Expected: JSON with `choices[0].message.content`.

Routing validation (deepseek + mistral):
```bash
curl -sS http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"deepseek_r1_32b","messages":[{"role":"user","content":"Reply with DEEPSEEK_OK"}],"temperature":0}'

curl -sS http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"mistral_small","messages":[{"role":"user","content":"Reply with MISTRAL_OK"}],"temperature":0}'
```

## Troubleshooting
- `401 Unauthorized`: `OPENAI_API_KEY` must match `LITELLM_MASTER_KEY`.
- `Model not found`: confirm `curl /v1/models` includes route and model name matches exactly.
- Ollama connection errors from LiteLLM:
  - host mode: ensure `OLLAMA_API_BASE=http://host.docker.internal:11434`
  - with-ollama profile: ensure `OLLAMA_API_BASE=http://ollama:11434`
- `open-webui` cannot list models: check `docker compose logs litellm open-webui`.
- GPU failures (optional services): verify `docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi`.

## Helper commands
- Start: `make start`
- Start + vLLM: `make start-vllm`
- Start + containerized Ollama: `make start-ollama`
- Stop: `make stop`
- Restart: `make restart`
- Logs: `make logs`
- Healthcheck: `make healthcheck`
- API verify: `make api-verify`

## Secure remote access (Tailscale)
- Setup and hardening: `TAILSCALE_SETUP.md`
- Access architecture/workflows: `REMOTE_ACCESS.md`
- OpenAI-compatible remote API usage: `API_ACCESS.md`

Remote helper commands:
- `make remote-healthcheck`
- `make remote-api-verify`
- `make endpoint-validate`


## Multi-user hardening docs
- Security baseline: `SECURITY.md`
- Multi-user platform layout: `MULTI_USER_ARCHITECTURE.md`
- Observability standards: `OBSERVABILITY.md`
- Capacity planning/runbooks: `CAPACITY_PLANNING.md`

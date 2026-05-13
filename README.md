# Local AI Inference + Orchestration Stack (Docker Compose)

## Open WebUI integration
Default runtime:
- `litellm` container (`:4000`) -> routes to host Ollama (`host.docker.internal:11434`)
- `open-webui` container (`:3000`) -> calls LiteLLM (`http://litellm:4000/v1`), never direct Ollama

Optional profiles:
- `with-vllm`: starts `vllm-qwen-coder` (`:8001`)
- `with-ollama`: starts containerized `ollama` (`:11434`) instead of host Ollama usage


## Access URLs
- Open WebUI: `http://localhost:3000`
- LiteLLM OpenAI API: `http://localhost:4000/v1`
- LiteLLM readiness: `http://localhost:4000/health/readiness`

## Model visibility expectations
- Open WebUI model list mirrors LiteLLM `/v1/models`.
- Expected baseline models: `qwen35_35b`, `phi4`.
- `qwen_coder_32b` appears only when `with-vllm` profile is running.

## Startup (corrected)
1. `cp .env.example .env`
2. Set `LITELLM_MASTER_KEY` and `LITELLM_SALT_KEY`.
3. Verify host Ollama: `curl http://localhost:11434/api/tags`
4. Start default stack: `make start`
5. Optional with vLLM: `make start-vllm`

## Operational verification checklist
- Compose validity: `make validate`
- Running services: `make ps`
- LiteLLM health: `curl -f http://localhost:4000/health/readiness`
- Model discovery: `make healthcheck`
- Open WebUI reachability: `curl -f http://localhost:3000/health`

## API validation (OpenAI-compatible)
Set key:
```bash
export OPENAI_API_KEY='sk-local-change-me'
```

List models:
```bash
curl -sS -H "Authorization: Bearer $OPENAI_API_KEY" \
  http://localhost:4000/v1/models
```
Expected: JSON with `data` including `qwen35_35b` and `phi4`; `qwen_coder_32b` appears when vLLM profile is up.

Chat completion (qwen):
```bash
curl -sS http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen35_35b","messages":[{"role":"user","content":"Reply with OK"}],"temperature":0}'
```
Expected: `choices[0].message.content` present.

Routing test (phi4):
```bash
curl -sS http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"phi4","messages":[{"role":"user","content":"Reply with PHI4_OK"}],"temperature":0}'
```
Expected: successful completion from phi4 route.

Routing test (vLLM, optional):
```bash
curl -sS http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen_coder_32b","messages":[{"role":"user","content":"Write one Python function stub."}],"temperature":0}'
```
Expected: success only when `with-vllm` profile is running.

## Troubleshooting
- `401 Unauthorized`: wrong `OPENAI_API_KEY` vs `LITELLM_MASTER_KEY` (used by Open WebUI backend calls).
- `Model not found`: check `/v1/models`; ensure profile/service for that route is up.
- `Connection refused to Ollama`: verify host Ollama is running and `.env` `OLLAMA_API_BASE` is correct.
- `vLLM startup failure`: validate GPU availability and VRAM; check `make logs`.
- `healthcheck` fails: inspect `docker compose logs litellm` and API base configuration.

## Helper commands
- Start: `make start`
- Start + vLLM: `make start-vllm`
- Stop: `make stop`
- Restart: `make restart`
- Logs: `make logs`
- Healthcheck: `make healthcheck`

- Container name conflicts from old runs: run `docker ps -a --filter name=open-webui` then `docker rm -f <id>` and retry.

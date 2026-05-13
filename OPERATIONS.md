# OPERATIONS

## Topology
```text
Continue/Claude/OpenHands/CrewAI/LangGraph/Open WebUI
                    |
                    v
          LiteLLM (http://localhost:4000/v1)
                    |
                    v
      Ollama (host.docker.internal:11434 or ollama:11434)
```

## Startup
1. `cp .env.example .env`
2. Set `LITELLM_MASTER_KEY`, `LITELLM_SALT_KEY`
3. Host Ollama check: `curl -fsS http://localhost:11434/api/tags`
4. `make start`

Optional:
- `make start-ollama` (set `OLLAMA_API_BASE=http://ollama:11434`)
- `make start-vllm`

## Shutdown / Restart
- Stop: `make stop`
- Restart default: `make restart`
- Restart single service: `docker compose restart litellm`

## Logs and lifecycle
- Services: `make ps`
- All logs: `make logs`
- LiteLLM logs: `make logs-litellm`
- WebUI logs: `make logs-webui`
- Health: `make healthcheck`

Expected lifecycle:
- `litellm` healthy within ~20-60s.
- `open-webui` starts after LiteLLM readiness.
- `ollama`/`vllm` optional based on profile.

## GPU expectations
- Required for large Ollama models and vLLM profile.
- Check runtime GPU visibility: `make gpu-check`
- If no GPU, large models may fail to load or be extremely slow.

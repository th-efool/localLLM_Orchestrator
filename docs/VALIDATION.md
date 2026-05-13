# VALIDATION

## Base stack validation
1. `make up`
2. `make health`
3. `make verify`

Expected:
- LiteLLM readiness passes
- Open WebUI health passes
- All host Ollama models are exposed by LiteLLM `/v1/models`

## Manual spot checks
```bash
curl -fsS http://localhost:11434/api/tags
curl -fsS http://localhost:4000/health/readiness
curl -fsS http://localhost:3000/health
curl -sS -H "Authorization: Bearer $LITELLM_MASTER_KEY" http://localhost:4000/v1/models
```

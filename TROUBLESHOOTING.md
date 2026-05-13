# TROUBLESHOOTING

## WSL networking issues
- Symptom: LiteLLM cannot reach Ollama on host.
- Check `OLLAMA_API_BASE=http://host.docker.internal:11434`.
- Verify `curl http://localhost:11434/api/tags` on host.

## Docker GPU issues
- Symptom: model load failures or CPU fallback.
- Run `make gpu-check`.
- Confirm NVIDIA Container Toolkit / Docker Desktop GPU integration.

## LiteLLM routing failures
- Symptom: `model_not_found` or 500 on completion.
- Check `/v1/models` and exact model IDs.
- Run `make route-verify` and `make api-verify`.

## OpenAI API compatibility issues
- Symptom: client rejects base URL or auth.
- Ensure base URL includes `/v1` and key matches `LITELLM_MASTER_KEY`.

## Ollama connectivity issues
- Symptom: connection refused/timeouts.
- Host mode: `OLLAMA_API_BASE=http://host.docker.internal:11434`
- Container mode: `OLLAMA_API_BASE=http://ollama:11434` with `make start-ollama`

## Model loading issues
- Symptom: long hangs, load failures.
- Validate model exists in Ollama: `ollama list`.
- Reduce active loaded models (`OLLAMA_MAX_LOADED_MODELS`).

## VRAM exhaustion behavior
- Symptoms: OOM, container restarts, extreme latency.
- Lower parallelism: `OLLAMA_NUM_PARALLEL=1`.
- Use smaller/faster model route.

## Container restart debugging
- `make ps`
- `make logs-litellm`
- `docker inspect litellm --format '{{.State.RestartCount}}'`

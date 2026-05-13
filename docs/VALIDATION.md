# VALIDATION

## Base stack validation
1. `make up`
2. `make health`
3. `make verify`

`make verify` enforces dynamic runtime discovery parity:
- Ollama `/api/tags` is non-empty.
- LiteLLM `/v1/models` is non-empty.
- Every Ollama model ID is present in LiteLLM model IDs.

## Manual dynamic discovery checks
```bash
OLLAMA_TAGS_JSON="$(curl -fsS http://localhost:11434/api/tags)"
LITELLM_MODELS_JSON="$(curl -fsS -H "Authorization: Bearer $LITELLM_MASTER_KEY" http://localhost:4000/v1/models)"
python3 - <<'PY' "$OLLAMA_TAGS_JSON" "$LITELLM_MODELS_JSON"
import json,sys
ollama=json.loads(sys.argv[1])
litellm=json.loads(sys.argv[2])
ollama_names={m.get('name') for m in ollama.get('models',[]) if m.get('name')}
litellm_ids={m.get('id') for m in litellm.get('data',[]) if m.get('id')}
assert ollama_names, 'ollama /api/tags returned no models'
assert litellm_ids, 'litellm /v1/models returned no models'
missing=sorted(ollama_names-litellm_ids)
assert not missing, f'missing in litellm: {missing}'
print(f'ok: {len(ollama_names)} ollama models exposed')
PY
```

## Optional route verification prerequisites
`scripts/route_verify.sh` is alias-oriented by design. Before using it, ensure one fast and one reasoning model alias are available in `/v1/models`:
- fast alias candidate: `phi4` (fallback: `mistral_small`)
- reasoning alias candidate: `qwen3.5:35b` (fallback: `qwen32b`)

Override with env vars if your aliases differ:
```bash
FAST_MODEL=<your-fast-alias> REASON_MODEL=<your-reasoning-alias> ./scripts/route_verify.sh
```

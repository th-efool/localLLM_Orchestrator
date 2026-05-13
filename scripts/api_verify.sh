#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://localhost:4000/v1}"
KEY="${LITELLM_MASTER_KEY:-sk-local-change-me}"
VERIFY_VLLM="${VERIFY_VLLM:-false}"

ollama_tags=$(curl -fsS http://localhost:11434/api/tags)
litellm_models=$(curl -fsS -H "Authorization: Bearer $KEY" "$BASE/models")
vllm_models='{}'
[[ "$VERIFY_VLLM" == "true" ]] && vllm_models=$(curl -fsS http://localhost:8001/v1/models)

python3 - <<'PY' "$ollama_tags" "$litellm_models" "$vllm_models"
import json, sys
ollama = {m.get('name') for m in json.loads(sys.argv[1]).get('models', []) if m.get('name')}
models = {m.get('id') for m in json.loads(sys.argv[2]).get('data', []) if m.get('id')}
vllm = {m.get('id') for m in json.loads(sys.argv[3]).get('data', []) if m.get('id')}
missing = sorted((ollama | vllm) - models)
prefixed = sorted(x for x in models if x.startswith(('ollama_chat/', 'openai/')))
assert ollama, 'ollama model list is empty'
assert not missing, f'missing models in litellm: {missing}'
assert not prefixed, f'backend-prefixed ids exposed: {prefixed}'
print('models discovered:', len(models), 'ollama models:', len(ollama), 'vllm models:', len(vllm))
PY

echo "API verification: OK"

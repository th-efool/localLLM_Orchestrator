#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://localhost:4000/v1}"
KEY="${LITELLM_MASTER_KEY:-sk-local-change-me}"

ollama_tags=$(curl -fsS http://localhost:11434/api/tags)
litellm_models=$(curl -fsS -H "Authorization: Bearer $KEY" "$BASE/models")

python3 - <<'PY' "$ollama_tags" "$litellm_models"
import json,sys
ollama={m.get('name') for m in json.loads(sys.argv[1]).get('models',[]) if m.get('name')}
models={m.get('id') for m in json.loads(sys.argv[2]).get('data',[]) if m.get('id')}
missing=sorted(ollama-models)
assert ollama, 'ollama model list is empty'
assert not missing, f'missing models in litellm: {missing}'
print('models discovered:', len(models), 'ollama models:', len(ollama))
PY

echo "API verification: OK"

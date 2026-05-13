#!/usr/bin/env bash
set -euo pipefail

DC=${DC:-"docker compose"}
KEY="${LITELLM_MASTER_KEY:-sk-local-change-me}"

$DC ps >/dev/null

for s in localai-postgres localai-redis localai-litellm localai-open-webui; do
  state=$(docker inspect -f '{{.State.Health.Status}}' "$s" 2>/dev/null || echo "missing")
  [[ "$state" == "healthy" ]] || { echo "$s health=$state"; exit 1; }
done

$DC exec -T postgres pg_isready -h 127.0.0.1 -U "${POSTGRES_USER:-litellm}" -d "${POSTGRES_DB:-litellm}" >/dev/null
$DC exec -T redis redis-cli ping | grep -q PONG
curl -fsS http://localhost:4000/health/readiness >/dev/null
curl -fsS http://localhost:3000/health >/dev/null

ollama_tags=$(curl -fsS http://localhost:11434/api/tags)
litellm_models=$(curl -fsS -H "Authorization: Bearer $KEY" http://localhost:4000/v1/models)

python3 - <<'PY' "$ollama_tags" "$litellm_models"
import json,sys
ollama=json.loads(sys.argv[1])
litellm=json.loads(sys.argv[2])
ollama_names={m.get('name') for m in ollama.get('models',[]) if m.get('name')}
ids={m.get('id') for m in litellm.get('data',[]) if m.get('id')}
missing=sorted(x for x in ollama_names if x not in ids)
if not ollama_names:
    raise SystemExit('no models returned by ollama /api/tags')
if missing:
    raise SystemExit(f'litellm missing ollama models: {missing}')
print(f'validated {len(ollama_names)} ollama models exposed by litellm')
PY

echo "verify: OK"

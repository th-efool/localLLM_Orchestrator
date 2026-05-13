#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env
require_env

DC=${DC:-$COMPOSE}
KEY="${LITELLM_MASTER_KEY}"
VERIFY_VLLM="${VERIFY_VLLM:-false}"

$DC ps >/dev/null

services=(localai-postgres localai-redis localai-litellm localai-open-webui)
[[ "$VERIFY_VLLM" == "true" ]] && services+=(localai-vllm)
for s in "${services[@]}"; do
  state=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$s" 2>/dev/null || echo "missing")
  [[ "$state" == "healthy" || "$state" == "running" ]] || { echo "$s health=$state"; exit 1; }
done

$DC exec -T postgres pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null
$DC exec -T redis redis-cli ping | grep -q PONG
curl -fsS http://localhost:4000/health/readiness >/dev/null
curl -fsS http://localhost:3000/health >/dev/null

ollama_tags=$(curl -fsS "${OLLAMA_API_BASE/http:\/\/host.docker.internal/http:\/\/localhost}/api/tags")
litellm_models=$(curl -fsS -H "Authorization: Bearer $KEY" http://localhost:4000/v1/models)
vllm_models='{}'
if [[ "$VERIFY_VLLM" == "true" ]]; then
  docker exec localai-vllm nvidia-smi >/dev/null
  vllm_models=$(curl -fsS http://localhost:8001/v1/models)
fi

python3 - <<'PY' "$ollama_tags" "$litellm_models" "$vllm_models" "$VERIFY_VLLM"
import json, sys
ollama = json.loads(sys.argv[1])
litellm = json.loads(sys.argv[2])
vllm = json.loads(sys.argv[3])
verify_vllm = sys.argv[4].lower() == 'true'
ollama_names = {m.get('name') for m in ollama.get('models', []) if m.get('name')}
vllm_ids = {m.get('id') for m in vllm.get('data', []) if m.get('id')}
ids = {m.get('id') for m in litellm.get('data', []) if m.get('id')}
missing = sorted((ollama_names | vllm_ids) - ids)
prefixed = sorted(x for x in ids if x.startswith(('ollama_chat/', 'openai/')))
if not ollama_names:
    raise SystemExit('no models returned by ollama /api/tags')
if verify_vllm and not vllm_ids:
    raise SystemExit('no models returned by vllm /v1/models')
if missing:
    raise SystemExit(f'litellm missing backend models: {missing}')
if prefixed:
    raise SystemExit(f'litellm exposed backend-prefixed ids: {prefixed}')
print(f'validated litellm exposes {len(ids)} normalized ids ({len(ollama_names)} ollama, {len(vllm_ids)} vllm)')
PY

echo "verify: OK"

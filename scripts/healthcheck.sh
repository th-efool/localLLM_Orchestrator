#!/usr/bin/env bash
set -euo pipefail

DC=${DC:-"docker compose"}

$DC version >/dev/null
$DC ps >/dev/null

services=(localai-postgres localai-redis localai-ollama localai-litellm localai-open-webui localai-traefik)
for s in "${services[@]}"; do
  state=$(docker inspect -f '{{.State.Health.Status}}' "$s" 2>/dev/null || echo "missing")
  [[ "$state" == "healthy" ]] || { echo "$s health=$state"; exit 1; }
done

$DC exec -T postgres pg_isready -h 127.0.0.1 -U "${POSTGRES_USER:-litellm}" -d "${POSTGRES_DB:-litellm}" >/dev/null
$DC exec -T redis redis-cli ping | grep -q PONG
curl -fsS http://localhost:4000/health/readiness >/dev/null
curl -fsS http://localhost:11434/api/tags >/dev/null
curl -fsS http://localhost:8080/health >/dev/null

getent hosts postgres >/dev/null
getent hosts redis >/dev/null

for v in postgres_data redis_data litellm_logs ollama_models; do
  mp=$(docker volume inspect "$v" -f '{{.Mountpoint}}')
  [[ -w "$mp" ]] || { echo "volume not writable: $v -> $mp"; exit 1; }
done

echo "all diagnostics passed"

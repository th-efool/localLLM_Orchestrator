#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

load_env
require_env
print_env_diag

validate_url DATABASE_URL "$DATABASE_URL"
validate_url REDIS_URL "$REDIS_URL"
validate_url OLLAMA_API_BASE "$OLLAMA_API_BASE"

expected_db="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
if [[ "$DATABASE_URL" != "$expected_db" ]]; then
  echo "DATABASE_URL mismatch" >&2
  echo "expected: $expected_db" >&2
  echo "actual:   $DATABASE_URL" >&2
  exit 1
fi

expected_redis="redis://${REDIS_HOST}:${REDIS_PORT}/0"
if [[ "$REDIS_URL" != "$expected_redis" ]]; then
  echo "REDIS_URL mismatch" >&2
  echo "expected: $expected_redis" >&2
  echo "actual:   $REDIS_URL" >&2
  exit 1
fi

$COMPOSE config >/dev/null
if $COMPOSE config 2>/dev/null | rg -n '\$\{|<no value>|POSTGRES_PASSWORD:\s*$|POSTGRES_USER:\s*$|POSTGRES_DB:\s*$' >/tmp/localai-compose-unresolved 2>/dev/null; then
  cat /tmp/localai-compose-unresolved >&2
  echo "compose interpolation unresolved" >&2
  exit 1
fi

ollama_check_url="$OLLAMA_API_BASE"
[[ "$ollama_check_url" == http://host.docker.internal:* ]] && ollama_check_url="${ollama_check_url/http:\/\/host.docker.internal/http:\/\/localhost}"
ollama_host="$(url_host "$ollama_check_url")"
ollama_port="$(url_port "$ollama_check_url" 11434)"
wait_for_tcp "$ollama_host" "$ollama_port" ollama 3 1
curl -fsS "${ollama_check_url%/}/api/tags" >/dev/null

if docker ps --format '{{.Names}}' | rg -qx 'localai-postgres'; then
  wait_for_tcp localhost 5432 postgres 3 1 || true
fi
if docker ps --format '{{.Names}}' | rg -qx 'localai-redis'; then
  wait_for_tcp localhost 6379 redis 3 1 || true
fi

echo "verify-env: OK"

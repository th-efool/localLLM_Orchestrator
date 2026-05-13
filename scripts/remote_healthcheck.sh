#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

BASE_URL="${1:-https://${DOMAIN_NAME:-localhost}}"
SKIP_PORT_CHECKS="${SKIP_PORT_CHECKS:-0}"
HOST="${BASE_URL#*://}"
HOST="${HOST%%/*}"
HOST="${HOST%%:*}"

command -v curl >/dev/null || { echo "curl not found"; exit 1; }

if command -v docker >/dev/null; then
  echo "[check] docker compose services"
  $COMPOSE ps >/dev/null
fi

echo "[check] proxy health"
curl -kfsS "${BASE_URL%/}/health/readiness" >/dev/null

echo "[check] webui through proxy"
curl -kfsS "${BASE_URL%/}/" >/dev/null

echo "[check] unauthenticated models rejected"
code="$(curl -ksS -o /dev/null -w '%{http_code}' "${BASE_URL%/}/v1/models")"
[[ "$code" == "401" || "$code" == "403" ]] || { echo "expected 401/403, got $code"; exit 1; }

if [[ "$SKIP_PORT_CHECKS" != "1" ]] && command -v nc >/dev/null; then
  echo "[check] direct backend ports blocked"
  for port in 3000 4000 11434 8001; do
    if nc -z -w 2 "$HOST" "$port" >/dev/null 2>&1; then
      echo "direct port reachable: $HOST:$port"
      exit 1
    fi
  done
fi

echo "remote healthcheck OK"

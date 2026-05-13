#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

BASE_API_URL="${1:-http://127.0.0.1:4000/v1}"
WEBUI_URL="${2:-http://127.0.0.1:3000}"

command -v docker >/dev/null || { echo "docker not found"; exit 1; }
command -v curl >/dev/null || { echo "curl not found"; exit 1; }

echo "[check] docker compose services"
$COMPOSE ps >/dev/null

echo "[check] litellm readiness"
curl -fsS "${BASE_API_URL%/v1}/health/readiness" >/dev/null

echo "[check] webui health"
curl -fsS "$WEBUI_URL/health" >/dev/null

echo "[check] models endpoint"
curl -fsS "$BASE_API_URL/models" >/dev/null || true

echo "remote healthcheck OK"

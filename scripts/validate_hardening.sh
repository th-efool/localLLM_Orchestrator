#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

DOMAIN=${DOMAIN_NAME:-localhost}

$COMPOSE config >/dev/null

if ! $COMPOSE ps --status running postgres reverse-proxy litellm open-webui >/dev/null; then
  echo "required services are not running"
  exit 1
fi

$COMPOSE exec -T postgres pg_isready -U "${POSTGRES_USER:?POSTGRES_USER not set}" -d "${POSTGRES_DB:?POSTGRES_DB not set}" >/dev/null

curl -fsS "http://127.0.0.1/.well-known" >/dev/null 2>&1 || true
curl -kfsS "https://${DOMAIN}/health/readiness" >/dev/null
curl -kfsS "https://${DOMAIN}/" >/dev/null

$COMPOSE logs --tail=50 reverse-proxy | tail -n 20

echo "hardening validation passed"

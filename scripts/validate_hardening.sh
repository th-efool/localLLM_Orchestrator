#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

DOMAIN=${DOMAIN_NAME:-localhost}
BASE_URL="https://${DOMAIN}"

$COMPOSE config >/dev/null

if ! $COMPOSE ps --status running postgres reverse-proxy litellm open-webui >/dev/null; then
  echo "required services are not running"
  exit 1
fi

$COMPOSE exec -T postgres pg_isready -U "${POSTGRES_USER:?POSTGRES_USER not set}" -d "${POSTGRES_DB:?POSTGRES_DB not set}" >/dev/null

curl -kfsS "${BASE_URL}/health/readiness" >/dev/null
curl -kfsS "${BASE_URL}/" >/dev/null

unauth_code="$(curl -ksS -o /dev/null -w '%{http_code}' "${BASE_URL}/v1/models")"
[[ "$unauth_code" == "401" || "$unauth_code" == "403" ]] || { echo "expected unauthenticated /v1/models to fail, got $unauth_code"; exit 1; }

curl -kfsS "${BASE_URL}/v1/models" -H "Authorization: Bearer ${LITELLM_MASTER_KEY:?LITELLM_MASTER_KEY not set}" >/dev/null

if [[ -f logs/traefik/access.log ]]; then
  tail -n 5 logs/traefik/access.log >/dev/null
fi

$COMPOSE logs --tail=50 reverse-proxy | tail -n 20

echo "hardening validation passed"

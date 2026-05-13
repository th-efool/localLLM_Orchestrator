#!/usr/bin/env bash
set -euo pipefail

COMPOSE=${COMPOSE:-docker compose}

mkdir -p data/{traefik/acme,prometheus,grafana} logs/traefik

$COMPOSE config >/dev/null
$COMPOSE up -d reverse-proxy litellm open-webui

if [[ "${ENABLE_OBSERVABILITY:-1}" == "1" ]]; then
  $COMPOSE --profile with-observability up -d prometheus grafana
fi

$COMPOSE ps

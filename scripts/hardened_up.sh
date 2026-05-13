#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env
mkdir -p data/{postgres,traefik/acme,prometheus,grafana} logs/traefik

$COMPOSE config >/dev/null
$COMPOSE up -d postgres litellm open-webui reverse-proxy

if [[ "${ENABLE_OBSERVABILITY:-1}" == "1" ]]; then
  $COMPOSE --profile with-observability up -d prometheus grafana
fi

$COMPOSE ps

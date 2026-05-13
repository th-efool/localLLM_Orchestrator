#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
COMPOSE="${COMPOSE:-docker compose --env-file $ENV_FILE}"
REQUIRED_ENV=(
  LITELLM_MASTER_KEY
  LITELLM_SALT_KEY
  POSTGRES_USER
  POSTGRES_PASSWORD
  POSTGRES_DB
  POSTGRES_HOST
  POSTGRES_PORT
  DATABASE_URL
  REDIS_HOST
  REDIS_PORT
  REDIS_URL
  OLLAMA_API_BASE
  OLLAMA_CONNECT_RETRIES
  OLLAMA_CONNECT_SLEEP
  OLLAMA_CONNECT_TIMEOUT
  ENABLE_DB_MIGRATIONS
  DISABLE_BACKGROUND_BUDGET_RESET
  MODEL_DISCOVERY_RETRIES
  MODEL_DISCOVERY_SLEEP
  DOMAIN_NAME
  TAILSCALE_DOMAIN
  ACME_EMAIL
)

load_env() {
  cd "$ROOT_DIR"
  if [[ ! -f "$ENV_FILE" ]]; then
    if [[ -f "$ROOT_DIR/.env.example" ]]; then
      cp "$ROOT_DIR/.env.example" "$ENV_FILE"
      echo "created env file: $ENV_FILE"
    else
      echo "missing env file: $ENV_FILE" >&2
      exit 1
    fi
  fi
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}

require_env() {
  local missing=()
  for v in "${REQUIRED_ENV[@]}"; do
    [[ -n "${!v:-}" ]] || missing+=("$v")
  done
  if (( ${#missing[@]} )); then
    printf 'missing required env vars in %s:\n' "$ENV_FILE" >&2
    printf '  - %s\n' "${missing[@]}" >&2
    echo "fix: cp .env.example .env, then edit non-empty values" >&2
    exit 1
  fi
}

url_host() {
  python3 - "$1" <<'PY'
import sys
from urllib.parse import urlparse
u=urlparse(sys.argv[1])
print(u.hostname or '')
PY
}

url_port() {
  python3 - "$1" "$2" <<'PY'
import sys
from urllib.parse import urlparse
u=urlparse(sys.argv[1])
print(u.port or sys.argv[2])
PY
}

validate_url() {
  local name="$1" value="$2"
  python3 - "$name" "$value" <<'PY'
import sys
from urllib.parse import urlparse
name, value = sys.argv[1:]
u = urlparse(value)
if not (u.scheme and u.hostname):
    raise SystemExit(f"invalid URL {name}={value}")
PY
}

print_env_diag() {
  local profiles="${COMPOSE_PROFILES:-default}"
  echo "env file: $ENV_FILE"
  echo "compose profiles: $profiles"
  echo "DATABASE_URL host: $(url_host "$DATABASE_URL")"
  echo "OLLAMA_API_BASE: $OLLAMA_API_BASE"
}

wait_for_tcp() {
  local host="$1" port="$2" name="$3" retries="${4:-30}" sleep_s="${5:-2}"
  for ((i=1;i<=retries;i++)); do
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" 2>/dev/null; then
      echo "$name reachable at $host:$port"
      return 0
    fi
    sleep "$sleep_s"
  done
  echo "$name unreachable at $host:$port" >&2
  return 1
}

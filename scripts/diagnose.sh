#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

section() { printf '\n===== %s =====\n' "$*"; }
run() { echo "+ $*"; "$@" || true; }
shrun() { echo "+ $*"; bash -lc "$*" || true; }

section env
print_env_diag || true
printf 'LITELLM_MASTER_KEY=%s\n' "${LITELLM_MASTER_KEY:+<set>}"
printf 'LITELLM_SALT_KEY=%s\n' "${LITELLM_SALT_KEY:+<set>}"
printf 'DATABASE_URL=%s\n' "$(python3 - <<'PY'
import os,re
print(re.sub(r'(postgresql://[^:]+:)[^@]+', r'\1<redacted>', os.environ.get('DATABASE_URL','')))
PY
)"
printf 'REDIS_URL=%s\n' "${REDIS_URL:-}"
printf 'OLLAMA_API_BASE=%s\n' "${OLLAMA_API_BASE:-}"
printf 'VLLM_API_BASE=%s\n' "${VLLM_API_BASE:-}"

section compose-ps
shrun "$COMPOSE ps"

section unhealthy
shrun "docker ps -a --filter health=unhealthy --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"

section compose-config-litellm
shrun "$COMPOSE config litellm"

section inspect-litellm
shrun "docker inspect localai-litellm"

section inspect-health
shrun "docker inspect -f '{{json .State.Health}}' localai-litellm"

section exit-codes
shrun "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.State}}' | rg 'localai-' || true"

section recent-logs
for c in localai-litellm localai-litellm-migrate localai-postgres localai-redis localai-open-webui; do
  echo "--- $c ---"
  shrun "docker logs --tail=200 $c 2>&1"
done

section generated-yaml
shrun "docker exec localai-litellm sh -lc 'echo path=\${LITELLM_GENERATED_CONFIG_PATH:-/app/config/litellm.yaml}; ls -l \${LITELLM_GENERATED_CONFIG_PATH:-/app/config/litellm.yaml}; sed -e s#postgresql://\\([^:]*\\):[^@]*@#postgresql://\\1:<redacted>@# -e s#master_key:.*#master_key: \\\"<redacted>\\\"# \${LITELLM_GENERATED_CONFIG_PATH:-/app/config/litellm.yaml}'"

section mounted-config
shrun "docker exec localai-litellm sh -lc 'ls -l /app/config /app/scripts; sed -n \"1,160p\" /app/config/litellm.yaml'"

section container-smoke
shrun "docker exec localai-litellm sh -lc 'id; pwd; command -v litellm; python3 - <<\"PY\"\nimport litellm, socket\nprint(\"litellm import ok\")\ns=socket.socket(); print(\"socket module ok\"); s.close()\nPY'"

section endpoints-host
run curl -fsS http://localhost:11434/api/tags
run curl -fsS http://localhost:4000/health/liveliness
run curl -fsS http://localhost:4000/health/readiness
run curl -fsS -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-}" http://localhost:4000/v1/models

section endpoints-container
shrun "docker exec localai-litellm python3 - <<'PY'\nimport urllib.request\nfor url in ['http://127.0.0.1:4000/health/liveliness','http://127.0.0.1:4000/health/readiness','http://host.docker.internal:11434/api/tags']:\n    try:\n        r=urllib.request.urlopen(url, timeout=5)\n        print(url, r.status, r.read(300).decode(errors='replace'))\n    except Exception as e:\n        print(url, 'ERROR', e)\nPY"

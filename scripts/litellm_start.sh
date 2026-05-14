#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo "[litellm-start] $*"; }
fail() { echo "[litellm-start] ERROR: $*" >&2; exit 1; }
redact() {
  python3 -c 'import re,sys; s=sys.stdin.read(); s=re.sub(r"(master_key:\\s*)\"?[^\"\n]+\"?", r"\\1\"<redacted>\"", s); s=re.sub(r"(postgresql://[^:]+:)[^@\\s]+", r"\\1<redacted>", s); print(s, end="")'
}

CONFIG_PATH="${LITELLM_GENERATED_CONFIG_PATH:-/app/config/litellm.yaml}"
BASE_CONFIG="/app/config-template/litellm.yaml"
CMD=(litellm --config "$CONFIG_PATH" --host 0.0.0.0 --port 4000)

trap 'rc=$?; echo "[litellm-start] failed at line $LINENO rc=$rc" >&2; exit $rc' ERR

log "phase=startup"
log "final executed command: ${CMD[*]}"
log "generated config path: $CONFIG_PATH"
log "template config path: $BASE_CONFIG"
log "workdir: $(pwd)"
log "user: $(id)"
log "DATABASE_URL host: $(python3 - <<'PY'
import os
from urllib.parse import urlparse
print(urlparse(os.environ.get('DATABASE_URL','')).hostname or '')
PY
)"
log "REDIS_URL host: $(python3 - <<'PY'
import os
from urllib.parse import urlparse
print(urlparse(os.environ.get('REDIS_URL','')).hostname or '')
PY
)"
log "OLLAMA_API_BASE: ${OLLAMA_API_BASE:-missing}"
log "VLLM_API_BASE: ${VLLM_API_BASE:-disabled}"

for v in DATABASE_URL REDIS_URL LITELLM_MASTER_KEY LITELLM_SALT_KEY OLLAMA_API_BASE; do
  [[ -n "${!v:-}" ]] || fail "missing env: $v"
done
[[ -r "$BASE_CONFIG" ]] || fail "template config not readable: $BASE_CONFIG"
command -v python3 >/dev/null || fail "python3 missing"
command -v litellm >/dev/null || fail "litellm executable missing"

log "phase=python-import"
python3 - <<'PY'
import importlib.metadata, litellm
print('[litellm-start] litellm import ok')
try:
    print('[litellm-start] litellm version:', importlib.metadata.version('litellm'))
except Exception as e:
    print('[litellm-start] litellm version unavailable:', e)
PY

log "phase=socket-bind-smoke"
python3 - <<'PY'
import socket
s=socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('0.0.0.0', 4000))
s.close()
print('[litellm-start] port 4000 bind smoke ok')
PY

log "phase=ollama-network"
python3 /app/scripts/ollama_network.py --check

log "config generation start"
python3 /app/scripts/generate_litellm_config.py
[[ -s "$CONFIG_PATH" ]] || fail "generated config empty/missing: $CONFIG_PATH"

log "phase=validate-config"
python3 - "$CONFIG_PATH" <<'PY'
import sys
from pathlib import Path
try:
    import yaml
except Exception as e:
    raise SystemExit(f'PyYAML unavailable: {e}')
path = Path(sys.argv[1])
data = yaml.safe_load(path.read_text())
if not isinstance(data, dict):
    raise SystemExit('config root must be mapping')
models = data.get('model_list')
if not isinstance(models, list) or not models:
    raise SystemExit('config model_list must be non-empty list')
seen = set()
for i, item in enumerate(models):
    if not isinstance(item, dict):
        raise SystemExit(f'model_list[{i}] must be mapping')
    name = item.get('model_name')
    params = item.get('litellm_params')
    if not name or not isinstance(name, str):
        raise SystemExit(f'model_list[{i}] missing model_name')
    if name in seen:
        raise SystemExit(f'duplicate model_name: {name}')
    seen.add(name)
    if not isinstance(params, dict):
        raise SystemExit(f'{name} missing litellm_params')
    for key in ('model', 'api_base'):
        if not params.get(key):
            raise SystemExit(f'{name} missing litellm_params.{key}')
print(f'[litellm-start] config syntax ok: {len(models)} routes')
PY

log "generated config path: $CONFIG_PATH"
log "phase=print-config"
cat "$CONFIG_PATH" | redact

log "LiteLLM bind startup: host=0.0.0.0 port=4000"
log "server ready state: starting"
"${CMD[@]}" &
pid=$!
trap 'log "received stop signal; forwarding to LiteLLM pid=$pid"; kill -TERM "$pid" 2>/dev/null || true; wait "$pid"' TERM INT
ready=0
for i in $(seq 1 120); do
  if python3 - <<'PY' >/dev/null 2>&1
import urllib.request
with urllib.request.urlopen('http://127.0.0.1:4000/health/readiness', timeout=2) as r:
    raise SystemExit(0 if 200 <= r.status < 300 else 1)
PY
  then
    log "server ready state: ready"
    ready=1
    break
  fi
  if ! kill -0 "$pid" 2>/dev/null; then
    wait "$pid"
    exit $?
  fi
  sleep 1
done
[[ "$ready" == 1 ]] || log "server ready state: not-ready-yet; healthcheck continues"
wait "$pid"

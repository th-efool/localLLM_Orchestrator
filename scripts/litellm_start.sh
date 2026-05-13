#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo "[litellm-start] $*"; }
fail() { echo "[litellm-start] ERROR: $*" >&2; exit 1; }
redact() {
  python3 -c 'import re,sys; s=sys.stdin.read(); s=re.sub(r"(master_key:\\s*)\"?[^\"\n]+\"?", r"\\1\"<redacted>\"", s); s=re.sub(r"(postgresql://[^:]+:)[^@\\s]+", r"\\1<redacted>", s); print(s, end="")'
}

CONFIG_PATH="${LITELLM_GENERATED_CONFIG_PATH:-/tmp/litellm.generated.yaml}"
BASE_CONFIG="/app/config/litellm.yaml"
CMD=(litellm --config "$CONFIG_PATH" --port 4000 --host 0.0.0.0)

trap 'rc=$?; echo "[litellm-start] failed at line $LINENO rc=$rc" >&2; exit $rc' ERR

log "phase=env"
log "effective command: ${CMD[*]}"
log "generated config path: $CONFIG_PATH"
log "mounted base config path: $BASE_CONFIG"
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
[[ -r "$BASE_CONFIG" ]] || fail "base config not readable: $BASE_CONFIG"
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

log "phase=generate-config"
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

log "phase=print-config"
cat "$CONFIG_PATH" | redact

log "phase=litellm-cli-smoke"
litellm --config "$CONFIG_PATH" --test

log "phase=exec"
exec "${CMD[@]}"

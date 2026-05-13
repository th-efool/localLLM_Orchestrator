#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import urllib.request
url = 'http://127.0.0.1:4000/health/readiness'
with urllib.request.urlopen(url, timeout=5) as r:
    if not 200 <= r.status < 300:
        raise SystemExit(f'{url} status={r.status}')
    print(f'{url} status={r.status}')
PY

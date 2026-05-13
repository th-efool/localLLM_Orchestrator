#!/usr/bin/env bash
set -euo pipefail

BASE="${OPENAI_API_BASE:-http://localhost:4000/v1}"
KEY="${OPENAI_API_KEY:-${LITELLM_MASTER_KEY:-sk-local-change-me}}"
MODEL="${OPENHANDS_MODEL:-qwen3.5:35b}"
FALLBACK="${OPENHANDS_FALLBACK_MODEL:-phi4}"

curl -fsS "${BASE%/v1}/health/readiness" >/dev/null
curl -fsS http://localhost:3001/ >/dev/null

MODELS_JSON="$(curl -fsS -H "Authorization: Bearer $KEY" "$BASE/models")"
echo "$MODELS_JSON" | python3 - "$MODEL" "$FALLBACK" <<'PY'
import json,sys
j=json.load(sys.stdin)
ids={m.get('id') for m in j.get('data', [])}
m=sys.argv[1]; f=sys.argv[2]
if m not in ids:
    print(f"missing model: {m}")
    if f not in ids:
        print(f"missing fallback model: {f}")
        raise SystemExit(1)
print("openhands_verify: OK")
PY

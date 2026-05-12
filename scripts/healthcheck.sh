#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://localhost:4000/v1}"
KEY="${LITELLM_MASTER_KEY:-sk-local-change-me}"

curl -fsS "${BASE%/v1}/health/readiness" >/dev/null
echo "LiteLLM readiness: OK"

RESPONSE="$(curl -fsS -H "Authorization: Bearer $KEY" "$BASE/models")"
echo "$RESPONSE" | python3 -c 'import json,sys; d=json.load(sys.stdin); ids=[m.get("id") for m in d.get("data",[])]; [print(x) for x in ids]; assert ids, "No models returned"'

echo "Model listing: OK"

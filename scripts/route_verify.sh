#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://localhost:4000/v1}"
KEY="${LITELLM_MASTER_KEY:-sk-local-change-me}"
FAST_MODEL="${FAST_MODEL:-phi4}"
REASON_MODEL="${REASON_MODEL:-qwen3.5:35b}"

MODELS_JSON="$(curl -fsS -H "Authorization: Bearer $KEY" "$BASE/models")"

pick_model() {
  local preferred="$1"
  local fallback="$2"
  echo "$MODELS_JSON" | python3 - "$preferred" "$fallback" <<'PY'
import json,sys
j=json.load(sys.stdin)
preferred=sys.argv[1]
fallback=sys.argv[2]
ids=[m.get("id") for m in j.get("data",[]) if m.get("id")]
if preferred in ids:
    print(preferred); raise SystemExit
if fallback in ids:
    print(fallback); raise SystemExit
print("")
PY
}

FAST_PICK="$(pick_model "$FAST_MODEL" mistral_small)"
REASON_PICK="$(pick_model "$REASON_MODEL" qwen32b)"

[ -n "$FAST_PICK" ] || { echo "No fast model available"; exit 1; }
[ -n "$REASON_PICK" ] || { echo "No reasoning model available"; exit 1; }

run_chat() {
  local model="$1"
  local token="$2"
  curl -fsS "$BASE/chat/completions" \
    -H "Authorization: Bearer $KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply exactly: $token\"}],\"temperature\":0}" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); c=d["choices"][0]["message"]["content"]; print(c); assert c.strip(), "empty response"'
}

echo "fast_model=$FAST_PICK"
run_chat "$FAST_PICK" FAST_ROUTE_OK

echo "reasoning_model=$REASON_PICK"
run_chat "$REASON_PICK" REASON_ROUTE_OK

echo "route_verify: OK"

#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4000/v1}"
API_KEY="${2:-${OPENAI_API_KEY:-}}"
MODEL="${3:-qwen32b}"

if [[ -z "$API_KEY" ]]; then
  echo "Usage: $0 [base_url] <api_key> [model]"
  exit 1
fi

curl -fsS -H "Authorization: Bearer $API_KEY" "$BASE_URL/models" >/dev/null

RESP="$(curl -fsS "$BASE_URL/chat/completions" \
  -H "Authorization: Bearer $API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with API_VERIFY_OK\"}],\"temperature\":0}")"

echo "$RESP" | rg -q 'choices' || { echo "missing choices in response"; exit 1; }
echo "remote api verify OK"

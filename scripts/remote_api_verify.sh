#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

BASE_URL="${1:-https://${DOMAIN_NAME:-localhost}/v1}"
API_KEY="${2:-${OPENAI_API_KEY:-}}"
MODEL="${3:-${FAST_MODEL:-qwen32b}}"

if [[ -z "$API_KEY" ]]; then
  echo "Usage: $0 [base_url] <api_key> [model]"
  exit 1
fi

curl -kfsS -H "Authorization: Bearer $API_KEY" "${BASE_URL%/}/models" >/dev/null

RESP="$(curl -kfsS "${BASE_URL%/}/chat/completions" \
  -H "Authorization: Bearer $API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with API_VERIFY_OK\"}],\"temperature\":0}")"

echo "$RESP" | rg -q 'choices' || { echo "missing choices in response"; exit 1; }
echo "remote api verify OK"

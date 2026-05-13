#!/usr/bin/env bash
set -euo pipefail

: "${OPENAI_API_BASE:=http://localhost:4000/v1}"
: "${OPENAI_API_KEY:=sk-local-change-me}"
: "${AGENT_MODEL:=executor_fast}"

echo "[1/3] LiteLLM models"
curl -fsS -H "Authorization: Bearer ${OPENAI_API_KEY}" "${OPENAI_API_BASE%/}/models" >/dev/null

echo "[2/3] completion"
curl -fsS "${OPENAI_API_BASE%/}/chat/completions" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"${AGENT_MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply AGENT_SMOKE_OK\"}],\"temperature\":0}" >/dev/null

echo "[3/3] route verify"
"$(dirname "$0")/route_verify.sh" >/dev/null

echo "AGENT_SMOKE_OK"

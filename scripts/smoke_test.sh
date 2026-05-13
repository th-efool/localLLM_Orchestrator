#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

BASE="${1:-http://localhost:4000/v1}"
KEY="${LITELLM_MASTER_KEY:-sk-local-change-me}"

curl -fsS "${BASE%/v1}/health/readiness" >/dev/null
curl -fsS -H "Authorization: Bearer $KEY" "$BASE/models" >/dev/null
curl -fsS "http://localhost:3000/health" >/dev/null

echo "smoke_test: OK"

#!/usr/bin/env bash
set -euo pipefail

endpoints=(
  "http://127.0.0.1:4000/health/readiness"
  "http://127.0.0.1:3000/health"
  "http://127.0.0.1:4000/v1/models"
)

for ep in "${endpoints[@]}"; do
  echo "validating $ep"
  curl -fsS "$ep" >/dev/null
  echo "OK $ep"
done

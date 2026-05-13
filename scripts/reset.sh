#!/usr/bin/env bash
set -euo pipefail

docker compose down --remove-orphans
docker volume rm -f postgres_data redis_data litellm_logs ollama_models open_webui_data || true
docker compose up -d --build

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p data/{ollama,litellm,open-webui,huggingface}

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example; edit secrets before production use."
fi

# Compose global flags (e.g. --profile) must be passed before subcommands.
COMPOSE_ARGS=("$@")

docker compose "${COMPOSE_ARGS[@]}" pull
docker compose "${COMPOSE_ARGS[@]}" up -d

echo "Stack started. LiteLLM: http://localhost:4000/v1"

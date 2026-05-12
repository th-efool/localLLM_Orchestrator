#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p data/{ollama,litellm,open-webui,huggingface}

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example; edit secrets before production use."
fi

# Default: LiteLLM + Open WebUI only (host Ollama expected).
# Optional profiles: with-vllm, with-ollama
docker compose pull
docker compose up -d "$@"

echo "Stack started. LiteLLM: http://localhost:4000/v1"

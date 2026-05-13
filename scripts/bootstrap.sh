#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

load_env
require_env
print_env_diag
mkdir -p data/{litellm,open-webui,huggingface}
./scripts/verify-env.sh
$COMPOSE pull
$COMPOSE up -d "$@"

echo "Stack started. LiteLLM: http://localhost:4000/v1"

#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

section() { printf '\n===== %s =====\n' "$*"; }
shrun() { echo "+ $*"; bash -lc "$*" || true; }
run() { echo "+ $*"; "$@" || true; }

probe='echo container=$(hostname); echo OLLAMA_API_BASE=${OLLAMA_API_BASE:-}; echo OPENAI_API_BASE_URL=${OPENAI_API_BASE_URL:-}; echo route; (ip route || route -n || true); echo hosts; (getent hosts host.docker.internal || true); echo ping; (ping -c 1 -W 2 host.docker.internal || true); echo curl-ollama; (curl -fsS http://host.docker.internal:11434/api/tags || wget -qO- http://host.docker.internal:11434/api/tags || python3 -c "import urllib.request; print(urllib.request.urlopen(\"http://host.docker.internal:11434/api/tags\", timeout=5).read().decode())")'

section host
print_env_diag || true
run curl -fsS http://localhost:11434/api/tags
run curl -fsS -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-}" http://localhost:4000/v1/models

section docker-network
shrun "docker network inspect local-ai-backend"

section compose-ps
shrun "$COMPOSE ps"

for c in localai-litellm localai-open-webui; do
  section "$c host.docker.internal"
  shrun "docker exec $c sh -lc '$probe'"
done

section litellm-ollama-discovery
shrun "docker exec localai-litellm python3 /app/scripts/ollama_network.py --json"

section openwebui-to-litellm
shrun "docker exec localai-open-webui sh -lc 'python3 -c '\''import os,urllib.request; key=os.environ.get(\"OPENAI_API_KEY\",\"\"); req=urllib.request.Request(\"http://litellm:4000/v1/models\", headers={\"Authorization\": f\"Bearer {key}\"}); r=urllib.request.urlopen(req, timeout=5); print(r.status); print(r.read().decode())'\'''"

section openwebui-to-ollama
shrun "docker exec localai-open-webui sh -lc 'python3 -c '\''import urllib.request; r=urllib.request.urlopen(\"http://host.docker.internal:11434/api/tags\", timeout=5); print(r.status); print(r.read().decode())'\'''"

section model-summary
shrun "curl -fsS -H 'Authorization: Bearer ${LITELLM_MASTER_KEY:-}' http://localhost:4000/v1/models | python3 -c 'import json,sys; data=json.load(sys.stdin); ids=[m.get(\"id\") for m in data.get(\"data\",[]) if m.get(\"id\")]; print(\"litellm_model_count=\", len(ids)); print(\"litellm_models=\", \",\".join(ids))'"

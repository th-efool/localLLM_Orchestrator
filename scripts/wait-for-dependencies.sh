#!/usr/bin/env bash
set -euo pipefail

required=(DATABASE_URL REDIS_URL LITELLM_MASTER_KEY LITELLM_SALT_KEY LITELLM_CONFIG_PATH OLLAMA_API_BASE)
for v in "${required[@]}"; do
  [[ -n "${!v:-}" ]] || { echo "missing required env: $v" >&2; exit 1; }
done

[[ -f "$LITELLM_CONFIG_PATH" ]] || { echo "missing config: $LITELLM_CONFIG_PATH" >&2; exit 1; }

wait_for_tcp() {
  local host="$1" port="$2" name="$3" retries="${4:-60}"
  for ((i=1;i<=retries;i++)); do
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" 2>/dev/null; then
      echo "$name reachable"
      return 0
    fi
    sleep 2
  done
  echo "$name unavailable at ${host}:${port}" >&2
  return 1
}

wait_for_tcp "${POSTGRES_HOST:-postgres}" "${POSTGRES_PORT:-5432}" postgres
wait_for_tcp "${REDIS_HOST:-redis}" "${REDIS_PORT:-6379}" redis

ollama_host=$(echo "$OLLAMA_API_BASE" | sed -E 's#^https?://([^/:]+).*$#\1#')
ollama_port=$(echo "$OLLAMA_API_BASE" | sed -E 's#^https?://[^/:]+:([0-9]+).*$#\1#')
[[ "$ollama_port" == "$OLLAMA_API_BASE" ]] && ollama_port=11434
wait_for_tcp "$ollama_host" "$ollama_port" ollama

echo "dependency validation passed"

#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://localhost:4000/v1}"
KEY="${LITELLM_MASTER_KEY:-sk-local-change-me}"

call_chat() {
  local model="$1"
  local marker="$2"
  curl -fsS "$BASE/chat/completions" \
    -H "Authorization: Bearer $KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply exactly: $marker\"}],\"temperature\":0}" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); c=d["choices"][0]["message"]["content"]; print(c); assert c.strip(), "empty response"'
}

curl -fsS -H "Authorization: Bearer $KEY" "$BASE/models" \
| python3 -c 'import json,sys; d=json.load(sys.stdin); ids={m.get("id") for m in d.get("data",[])}; print("models:", ", ".join(sorted(x for x in ids if x))); req={"qwen32b","deepseek_r1_32b","mistral_small"}; miss=req-ids; assert not miss, f"missing required models: {sorted(miss)}"'

echo "qwen32b test:"; call_chat qwen32b QWEN32B_OK
echo "deepseek_r1_32b test:"; call_chat deepseek_r1_32b DEEPSEEK_OK
echo "mistral_small test:"; call_chat mistral_small MISTRAL_OK

echo "API verification: OK"

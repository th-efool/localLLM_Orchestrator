#!/usr/bin/env python3
import json
import os
import urllib.request
from urllib.error import URLError, HTTPError

OLLAMA_API_BASE = os.environ.get("OLLAMA_API_BASE", "").rstrip("/")
VLLM_API_BASE = os.environ.get("VLLM_API_BASE", "").rstrip("/")
MASTER_KEY = os.environ.get("LITELLM_MASTER_KEY", "")
OUT_CONFIG = os.environ.get("LITELLM_GENERATED_CONFIG_PATH", "/tmp/litellm.generated.yaml")

if not OLLAMA_API_BASE:
    raise SystemExit("missing OLLAMA_API_BASE")
if not MASTER_KEY:
    raise SystemExit("missing LITELLM_MASTER_KEY")


def get_json(url: str, timeout: int = 20):
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


try:
    ollama_payload = get_json(f"{OLLAMA_API_BASE}/api/tags")
except (URLError, HTTPError, TimeoutError) as e:
    raise SystemExit(f"failed to query ollama tags: {e}")

ollama_models = sorted({m.get("name") for m in ollama_payload.get("models", []) if isinstance(m, dict) and m.get("name")})
if not ollama_models:
    raise SystemExit("no models discovered from ollama /api/tags")

vllm_models = []
if VLLM_API_BASE:
    try:
        vllm_payload = get_json(f"{VLLM_API_BASE}/v1/models")
        vllm_models = sorted({m.get("id") for m in vllm_payload.get("data", []) if isinstance(m, dict) and m.get("id")})
    except Exception as e:
        print(f"[litellm-config] vLLM discovery skipped: {e}")

lines = ["model_list:"]
for name in ollama_models:
    escaped = name.replace('"', '\\"')
    lines.extend([
        f'  - model_name: "{escaped}"',
        "    litellm_params:",
        f'      model: "ollama_chat/{escaped}"',
        f'      api_base: "{OLLAMA_API_BASE}"',
    ])

for model_id in vllm_models:
    escaped = model_id.replace('"', '\\"')
    lines.extend([
        f'  - model_name: "{escaped}"',
        "    litellm_params:",
        f'      model: "openai/{escaped}"',
        f'      api_base: "{VLLM_API_BASE}/v1"',
        '      api_key: "none"',
    ])

lines.extend([
    "",
    "general_settings:",
    f'  master_key: "{MASTER_KEY}"',
    "  disable_spend_logs: true",
    "  health_check_interval: 300",
    "",
    "router_settings:",
    "  routing_strategy: simple-shuffle",
    "  num_retries: 2",
    "  timeout: 180",
])

with open(OUT_CONFIG, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print("[litellm-config] discovered ollama models:")
for m in ollama_models:
    print(f"  - {m}")
print("[litellm-config] active vLLM models:")
for m in vllm_models:
    print(f"  - {m}")
if not vllm_models:
    print("  - (none)")
print("[litellm-config] generated LiteLLM routes:")
for m in ollama_models:
    print(f"  - {m} -> ollama_chat/{m}")
for m in vllm_models:
    print(f"  - {m} -> openai/{m}")
print("[litellm-config] exposed OpenAI model IDs:")
for m in [*ollama_models, *vllm_models]:
    print(f"  - {m}")
print(f"[litellm-config] wrote {OUT_CONFIG}")

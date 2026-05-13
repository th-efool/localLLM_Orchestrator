#!/usr/bin/env python3
import json
import os
import sys
import urllib.request
from urllib.error import URLError, HTTPError

OLLAMA_API_BASE = os.environ.get("OLLAMA_API_BASE", "").rstrip("/")
MASTER_KEY = os.environ.get("LITELLM_MASTER_KEY", "")
SRC_CONFIG = os.environ.get("LITELLM_CONFIG_PATH", "/app/config/litellm.yaml")
OUT_CONFIG = os.environ.get("LITELLM_GENERATED_CONFIG_PATH", "/tmp/litellm.generated.yaml")

if not OLLAMA_API_BASE:
    raise SystemExit("missing OLLAMA_API_BASE")
if not MASTER_KEY:
    raise SystemExit("missing LITELLM_MASTER_KEY")

try:
    with urllib.request.urlopen(f"{OLLAMA_API_BASE}/api/tags", timeout=20) as r:
        payload = json.loads(r.read().decode("utf-8"))
except (URLError, HTTPError, TimeoutError) as e:
    raise SystemExit(f"failed to query ollama tags: {e}")

models = sorted({m.get("name") for m in payload.get("models", []) if isinstance(m, dict) and m.get("name")})
if not models:
    raise SystemExit("no models discovered from ollama /api/tags")

lines = ["model_list:"]
for name in models:
    escaped = name.replace('"', '\\"')
    lines.extend([
        f'  - model_name: "{escaped}"',
        "    litellm_params:",
        f'      model: "ollama_chat/{escaped}"',
        f'      api_base: "{OLLAMA_API_BASE}"',
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
for m in models:
    print(f"  - {m}")
print("[litellm-config] generated routes:")
for m in models:
    print(f"  - {m} -> ollama_chat/{m}")
print("[litellm-config] exposed OpenAI model IDs:")
for m in models:
    print(f"  - {m}")
print(f"[litellm-config] wrote {OUT_CONFIG}")

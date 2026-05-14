#!/usr/bin/env python3
import json
import os
import sys
import time
import urllib.error
import urllib.request

from ollama_network import discover as discover_ollama

OUT = os.getenv("LITELLM_GENERATED_CONFIG_PATH", "/app/config/litellm.yaml")
OLLAMA = os.getenv("OLLAMA_API_BASE", "http://host.docker.internal:11434").rstrip("/")
VLLM = os.getenv("VLLM_API_BASE", "").rstrip("/")
VLLM_KEY = os.getenv("VLLM_API_KEY", "EMPTY")
MASTER_KEY = os.getenv("LITELLM_MASTER_KEY", "")
DATABASE_URL = os.getenv("DATABASE_URL", "")
RETRIES = int(os.getenv("MODEL_DISCOVERY_RETRIES", "20"))
SLEEP = float(os.getenv("MODEL_DISCOVERY_SLEEP", "2"))


print("[litellm-config] config generation start")
print("[litellm-config] target config path:", OUT)
print("[litellm-config] OLLAMA_API_BASE:", OLLAMA)
print("[litellm-config] VLLM_API_BASE:", VLLM or "disabled")

def fetch_json(url, headers=None, required=False):
    last = None
    for i in range(1, RETRIES + 1):
        try:
            req = urllib.request.Request(url, headers=headers or {})
            with urllib.request.urlopen(req, timeout=5) as r:
                return json.loads(r.read().decode())
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
            last = e
            if not required:
                break
            if i < RETRIES:
                time.sleep(SLEEP)
    if required:
        raise SystemExit(f"required discovery failed: {url}: {last}")
    print(f"[litellm-config] optional discovery skipped: {url}: {last}", file=sys.stderr)
    return {}



def validate_config(path):
    try:
        import yaml
    except Exception as e:
        raise SystemExit(f"PyYAML unavailable; cannot validate generated config: {e}")
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        raise SystemExit("generated config root must be a mapping")
    model_list = data.get("model_list")
    if not isinstance(model_list, list) or not model_list:
        raise SystemExit("generated config model_list must be non-empty list")
    seen = set()
    for idx, item in enumerate(model_list):
        if not isinstance(item, dict):
            raise SystemExit(f"model_list[{idx}] must be a mapping")
        name = item.get("model_name")
        params = item.get("litellm_params")
        if not isinstance(name, str) or not name.strip():
            raise SystemExit(f"model_list[{idx}] missing model_name")
        if name in seen:
            raise SystemExit(f"duplicate model_name: {name}")
        seen.add(name)
        if not isinstance(params, dict):
            raise SystemExit(f"{name} missing litellm_params")
        for key in ("model", "api_base"):
            if not params.get(key):
                raise SystemExit(f"{name} missing litellm_params.{key}")
    for section in ("litellm_settings", "general_settings", "router_settings"):
        if not isinstance(data.get(section), dict):
            raise SystemExit(f"generated config missing mapping section: {section}")
    print(f"[litellm-config] YAML validation ok: {len(model_list)} routes")

def q(s):
    return json.dumps(str(s))


def ids_from_openai_models(payload):
    return [m.get("id") for m in payload.get("data", []) if m.get("id")]


OLLAMA, ollama_payload = discover_ollama(required=True)
ollama_models = [m.get("name") for m in ollama_payload.get("models", []) if m.get("name")]
vllm_models = []
if VLLM:
    base = VLLM if VLLM.endswith("/v1") else f"{VLLM}/v1"
    headers = {"Authorization": f"Bearer {VLLM_KEY}"} if VLLM_KEY else {}
    vllm_models = ids_from_openai_models(fetch_json(f"{base}/models", headers=headers, required=False))
else:
    base = ""

seen = set()
routes = []
for mid in ollama_models:
    if mid in seen:
        continue
    seen.add(mid)
    routes.append((mid, f"ollama_chat/{mid}", OLLAMA, None, "ollama"))

for mid in vllm_models:
    if mid in seen:
        print(f"[litellm-config] vLLM model shadows existing Ollama id, skipping duplicate: {mid}", file=sys.stderr)
        continue
    seen.add(mid)
    routes.append((mid, f"openai/{mid}", base, VLLM_KEY, "vllm"))

if not routes:
    raise SystemExit("no backend models discovered")

wildcard = ("*", "ollama_chat/*", OLLAMA, None, "ollama-wildcard")
routes_with_wildcard = routes + [wildcard]

lines = ["model_list:"]
for name, model, api_base, api_key, src in routes_with_wildcard:
    lines += [
        f"  - model_name: {q(name)}",
        "    litellm_params:",
        f"      model: {q(model)}",
        f"      api_base: {q(api_base)}",
    ]
    if api_key is not None:
        lines.append(f"      api_key: {q(api_key)}")
    lines.append(f"    model_info:")
    lines.append(f"      source: {q(src)}")

lines += [
    "",
    "litellm_settings:",
    f"  master_key: {q(MASTER_KEY)}",
]
if DATABASE_URL:
    lines.append(f"  database_url: {q(DATABASE_URL)}")

lines += [
    "",
    "general_settings:",
    f"  master_key: {q(MASTER_KEY)}",
    "  disable_spend_logs: true",
    "  health_check_interval: 300",
    "  infer_model_from_keys: true",
    "  background_health_checks: false",
    "",
    "router_settings:",
    "  routing_strategy: simple-shuffle",
    "  num_retries: 2",
    "  timeout: 180",
]

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

validate_config(OUT)

print("[litellm-config] generated config path:", OUT)
print("[litellm-config] discovered Ollama models:", ", ".join(ollama_models) or "none")
print("[litellm-config] active vLLM models:", ", ".join(vllm_models) or "none")
print("[litellm-config] generated LiteLLM routes:")
for name, model, api_base, _, src in routes_with_wildcard:
    print(f"[litellm-config]   {name} -> {model} @ {api_base} ({src})")
print("[litellm-config] exposed OpenAI-compatible model IDs:", ", ".join(name for name, *_ in routes))
print("[litellm-config] wildcard passthrough enabled: * -> ollama_chat/*")
print(f"[litellm-config] wrote {OUT}")

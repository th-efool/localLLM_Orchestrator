# OPENHANDS_SETUP (LiteLLM-only)

## Goal
Integrate OpenHands without changing core architecture:
OpenHands -> LiteLLM (OpenAI-compatible) -> routed local models.

## 1) Environment variables

Use only LiteLLM endpoint:

```bash
OPENAI_API_BASE=http://litellm:4000/v1
OPENAI_API_KEY=${LITELLM_MASTER_KEY}
OPENHANDS_MODEL=qwen3.5:35b
OPENHANDS_FALLBACK_MODEL=phi4
```

Recommended host-side testing values:

```bash
OPENAI_API_BASE=http://localhost:4000/v1
OPENAI_API_KEY=sk-local-change-me
OPENHANDS_MODEL=qwen3.5:35b
OPENHANDS_FALLBACK_MODEL=phi4
```

## 2) docker-compose integration guidance

OpenHands is now included as `with-openhands` profile in `docker-compose.yml`.

Notes:
- Do not set Ollama endpoint in OpenHands.
- Keep routing logic in LiteLLM aliases.

## 3) Local model routing recommendations

Use LiteLLM model names:
- `qwen3.5:35b` reasoning lane.
- `phi4` utility/retry lane.
- Keep optional fallbacks (`qwen32b`, `mistral_small`) available.

## 4) Startup procedure

1. `make start-openhands`
2. Ensure LiteLLM health: `curl -f http://localhost:4000/health/readiness`
3. Open OpenHands: `http://localhost:3001`.
4. Run `scripts/openhands_workflows.sh` and use the prompts.

## 5) Testing procedure

- Verify model list via LiteLLM:
  - `curl -sS -H "Authorization: Bearer $OPENAI_API_KEY" http://localhost:4000/v1/models`
- Verify OpenHands service + routing:
  - `make verify-openhands`
- Verify OpenHands can complete:
  - repo analysis prompt,
  - code-edit prompt,
  - shell/test prompt.
- Validate no direct calls to `:11434` from OpenHands logs.

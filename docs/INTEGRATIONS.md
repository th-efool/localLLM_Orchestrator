# Tool Integrations via LiteLLM (Canonical Gateway)

Base endpoint (all tools):
- `OPENAI_BASE_URL=http://localhost:4000/v1`
- `OPENAI_API_KEY=<LITELLM_MASTER_KEY>`

Do not connect tools directly to Ollama.

## Recommended model routing
- `phi4`: lightweight prompts, autocomplete, quick iterations.
- `qwen3.5:35b`: reasoning, coding, architecture, orchestration.

Current stack note:
- If your `/v1/models` does not expose these names yet, map your existing IDs to these roles:
  - `mistral_small` -> `phi4` role
  - `qwen32b` -> `qwen3.5:35b` role

Verify available models:
```bash
curl -sS -H "Authorization: Bearer $LITELLM_MASTER_KEY" http://localhost:4000/v1/models
```

## 1) Continue.dev
Config example: `config-examples/continue.config.json`
- Set OpenAI provider pointing to LiteLLM.
- Use fast model for autocomplete, strong model for chat/edit flows.

Workflow:
1. Use `phi4` profile for tab-complete and short refactors.
2. Escalate to `qwen3.5:35b` for design/codegen/debug planning.

## 2) Claude Code
Config example: `config-examples/claude-code.env`
- Export OpenAI-compatible env vars to force LiteLLM path.

Workflow:
1. Default to `phi4` for quick Q&A.
2. Switch model env to `qwen3.5:35b` for multi-file reasoning.

## 3) OpenHands
Config example: `config-examples/openhands.env`
- Configure OpenAI endpoint/key/model through LiteLLM.

Workflow:
1. Boot OpenHands with LiteLLM vars.
2. Run issue-fix loop on `qwen3.5:35b`.
3. Use `phi4` for cheap retry loops if needed.

## 4) CrewAI
Config example: `config-examples/crewai.py`
- Use OpenAI-compatible client/base URL and route by agent role.

Workflow:
- Planner/reviewer agents -> `qwen3.5:35b`
- Executor/tool-call agents -> `phi4`

## 5) LangGraph
Config example: `config-examples/langgraph.py`
- Two-node graph: router + worker, both using LiteLLM OpenAI endpoint.

Workflow:
- Route simple tasks to `phi4`.
- Route deep reasoning to `qwen3.5:35b`.

## Example API usage
Lightweight:
```bash
curl -sS http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"phi4","messages":[{"role":"user","content":"Summarize in 3 bullets."}]}'
```

Reasoning/coding:
```bash
curl -sS http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3.5:35b","messages":[{"role":"user","content":"Design a migration plan."}]}'
```

## Troubleshooting
- `401`: wrong key; must match `LITELLM_MASTER_KEY`.
- `404 model_not_found`: check `/v1/models`; update tool model name.
- Timeouts on heavy prompts: route to `qwen3.5:35b` only when needed; shorten context for `phi4`.
- Tool still hitting Ollama directly: search its config/env for `11434` and replace with `4000/v1`.

# VALIDATION

## 1) Base stack validation
1. `make validate`
2. `make start`
3. `make ps`
4. `make smoke-test`

Expected:
- LiteLLM readiness passes
- `/v1/models` returns non-empty
- Open WebUI `/health` returns success

## 2) LiteLLM routing verification
1. `make route-verify`
2. Optional strict: `FAST_MODEL=phi4 REASON_MODEL=qwen3.5:35b make route-verify`

Expected:
- Prints selected fast/reasoning model
- Both chat calls return non-empty outputs

Failure detection:
- "No fast model available" => missing `phi4` and fallback `mistral_small`
- "No reasoning model available" => missing `qwen3.5:35b` and fallback `qwen32b`

## 3) OpenAI-compatible API verification
- `make api-verify`

Expected:
- Baseline models present: `qwen32b`, `deepseek_r1_32b`, `mistral_small`
- Completions succeed for each route

## 4) Open WebUI verification
1. Open `http://localhost:3000`
2. Ensure models shown match LiteLLM `/v1/models`
3. Send prompt to fast and reasoning models

## 5) Continue.dev verification
1. Load `config-examples/continue.config.json`
2. Set API key to `LITELLM_MASTER_KEY`
3. Test autocomplete (`phi4`) and chat (`qwen3.5:35b` or fallback)

## 6) Claude Code verification
1. `source config-examples/claude-code.env`
2. Run a quick prompt with fast model, then reasoning model.

Expected outputs
- Non-empty assistant content
- No direct `:11434` usage in tool configs

## 7) OpenHands runtime verification
1. `make start-openhands`
2. `make verify-openhands`
3. `scripts/openhands_workflows.sh`

Expected:
- OpenHands reachable on `http://localhost:3001`
- LiteLLM readiness passes
- `qwen3.5:35b` or fallback available
- `phi4` or fallback available

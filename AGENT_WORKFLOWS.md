# AGENT WORKFLOWS (Autonomous Coding)

## OpenHands workflow
1. Export LiteLLM env:
   - `OPENAI_API_BASE=http://localhost:4000/v1`
   - `OPENAI_API_KEY=<LITELLM_MASTER_KEY>`
2. Use reasoning model (`qwen3.5:35b`) as primary.
3. Use fast model (`phi4`) for retry-heavy loops.
4. Validate each run with repo tests + `make route-verify`.

Example task prompt:
- "Fix failing tests in <module>, keep API stable, show minimal diff, run checks."

## CrewAI orchestration
- Role split:
  - Planner/Reviewer -> `qwen3.5:35b`
  - Executor/Tool agent -> `phi4`
- Keep tasks short and explicit:
  - objective
  - constraints
  - acceptance checks

Example crew flow:
1. Planner: produce change plan.
2. Executor: apply patch.
3. Reviewer: validate plan vs diff and test outputs.

## LangGraph orchestration
- Use router node to dispatch:
  - simple tasks -> `phi4`
  - deep reasoning -> `qwen3.5:35b`
- Keep deterministic boundaries:
  - max loop count
  - stop on failing checks
  - explicit terminal states (done/fail)

## RooCode / Cline workflow
- Configure OpenAI-compatible endpoint to LiteLLM only.
- Use repo mode with strict boundaries:
  - read target files
  - propose patch
  - run local command checks
  - summarize exact changed files

## Local tool execution assumptions
- Single-node workstation.
- Docker + WSL2 + GPU already available.
- Agent can run local shell commands and edit files; no remote infra required.

## Safety and operational boundaries
- No direct Ollama endpoint usage in clients (`:11434`).
- No Kubernetes/distributed orchestration.
- No auth/monitoring stack additions.
- Require validation before merge:
  - syntax/build/tests
  - `make smoke-test`
  - `make route-verify`

## Local-agent operational recommendations
- Use branch-per-task.
- Enforce minimal diffs.
- Retry strategy:
  1. retry prompt refinement on same model
  2. escalate `phi4` -> `qwen3.5:35b`
  3. reduce context and isolate failing scope

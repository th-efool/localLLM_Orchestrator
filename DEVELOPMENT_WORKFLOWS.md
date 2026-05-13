# DEVELOPMENT WORKFLOWS (Local-First)

## Core pattern
1. Run stack (`make start`) and verify (`make smoke-test`).
2. Keep all tools on `http://localhost:4000/v1` with `LITELLM_MASTER_KEY`.
3. Use fast model for iteration, reasoning model for hard steps.

## Continue.dev workflow
- Configure Continue to use LiteLLM (see `config-examples/continue.config.json`).
- Suggested loop:
  1. `phi4` for autocomplete and short edits.
  2. `qwen3.5:35b` for architecture, refactors, debugging, migration plans.
  3. Run local checks (`make healthcheck`, tests/lint) after each major edit.

Example prompt (fast pass):
- "Refactor this function for readability without changing behavior. Keep diff minimal."

Example prompt (deep pass):
- "Given this repo structure, propose a 3-step migration plan with risks and rollback."

## Antigravity integration assumptions
- Antigravity uses OpenAI-compatible endpoint + key.
- Bind to:
  - `OPENAI_BASE_URL=http://localhost:4000/v1`
  - `OPENAI_API_KEY=<LITELLM_MASTER_KEY>`
- Default model split:
  - quick edits / short tool loops -> `phi4`
  - planning / large refactor reasoning -> `qwen3.5:35b`

## Repo-aware local workflow
- Scope context before prompting:
  - architecture files (`ARCHITECTURE.md`, `DECISIONS.md`)
  - target module files only
  - recent diffs/logs
- Avoid dumping entire repo in one prompt.
- Use staged context:
  1. discovery summary
  2. implementation request
  3. validation request

## Context management strategy
- Keep prompt windows small and task-specific.
- Pass constraints explicitly (no k8s/no auth/etc.) every long task.
- Reset chat when switching features to avoid stale assumptions.
- For large repos, ask for:
  - "list impacted files only"
  - "generate patch plan before code"

## Recommended model usage pattern
- `phi4`: autocomplete, command generation, quick bug triage, boilerplate.
- `qwen3.5:35b`: multi-file changes, API design, root-cause analysis, orchestration.
- Fallback when aliases unavailable:
  - `phi4` role -> `mistral_small`
  - `qwen3.5:35b` role -> `qwen32b`

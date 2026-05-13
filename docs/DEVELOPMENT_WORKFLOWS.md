# DEVELOPMENT WORKFLOWS (Local-First)

## Core pattern
1. Run stack (`make up`) and verify (`make verify`).
2. Keep all tools on `http://localhost:4000/v1` with `LITELLM_MASTER_KEY`.
3. Use fast model for iteration, reasoning model for hard steps.

## Continue.dev workflow
- Configure Continue to use LiteLLM (see `config-examples/continue.config.json`).
- Suggested loop:
  1. `phi4` for autocomplete and short edits.
  2. `qwen3.5:35b` for architecture, refactors, debugging, migration plans.
  3. Run local checks (`make health`, tests/lint) after each major edit.

## Antigravity integration assumptions
- Antigravity uses OpenAI-compatible endpoint + key.
- Bind to:
  - `OPENAI_BASE_URL=http://localhost:4000/v1`
  - `OPENAI_API_KEY=<LITELLM_MASTER_KEY>`

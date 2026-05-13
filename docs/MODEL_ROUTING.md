# MODEL ROUTING STRATEGY

## Primary routes
- `phi4` (fast lane)
  - Intended tasks: autocomplete, quick Q&A, small refactors, short tool loops.
  - Goal: low latency, high iteration speed.

- `qwen3.5:35b` (reasoning lane)
  - Intended tasks: architecture, multi-file coding, debugging, orchestration, root-cause analysis.
  - Goal: higher quality reasoning over larger context.

## Latency vs reasoning tradeoff
- `phi4`
  - lower first-token latency
  - lower per-request cost/compute
  - weaker on complex multi-hop reasoning
- `qwen3.5:35b`
  - higher first-token latency
  - slower throughput
  - better consistency on complex code tasks

## Task specialization matrix
- Fast lane (`phi4`):
  - autocomplete
  - shell command drafting
  - small patch drafting
  - quick summarization
- Reasoning lane (`qwen3.5:35b`):
  - repo-wide change planning
  - codebase architecture changes
  - complex bug isolation
  - agent orchestration planning

## Practical routing examples
- "Generate a one-line regex for this log line" -> `phi4`
- "Design migration plan across 8 files with rollback" -> `qwen3.5:35b`
- "Create minimal patch then list risks" -> `qwen3.5:35b`

## Fallback mapping (current local model IDs)
- if `phi4` alias missing: use `mistral_small`
- if `qwen3.5:35b` alias missing: use `qwen32b`

## Future vLLM direction
- Keep LiteLLM as canonical gateway.
- Add vLLM-backed high-throughput coding models behind new LiteLLM routes.
- Preserve the same client contract (`/v1`, key, model name routing).
- Scale by route-level specialization, not by adding new client endpoints.

# PERFORMANCE

## VRAM expectations (approx)
- `phi4` class (~14B): ~8-16 GB (quantization dependent)
- `mistral_small` class (~24B): ~14-24+ GB
- `qwen3.5:35b`/`qwen32b` class: ~20-40+ GB
- `deepseek_r1_32b` class: ~20-40+ GB

Actual memory depends on quantization, context window, and parallelism.

## Latency profile (local Ollama, typical)
- Fast model (`phi4` role): low latency for short prompts.
- Reasoning model (`qwen3.5:35b` role): higher first-token latency, slower sustained decode.

## Throughput/concurrency assumptions
- Default low concurrency (`OLLAMA_NUM_PARALLEL=2`) is safer for stability.
- Increase concurrency only after confirming no VRAM thrash/OOM.

## Allocation strategy
- Route quick interactions/autocomplete to `phi4` role.
- Route coding/architecture/reasoning to `qwen3.5:35b` role.
- Use fallback mappings when aliases are unavailable (`mistral_small`, `qwen32b`).

## Future vLLM notes (optional profile)
- Use `with-vllm` for higher throughput on supported models.
- Tune tensor parallelism and max model length per GPU memory.
- Keep LiteLLM as the single client-facing endpoint.

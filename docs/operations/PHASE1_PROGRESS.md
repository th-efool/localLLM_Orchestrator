# Phase 1 Progress (Current State)

## Scope Completed
- Compose-based local stack established with LiteLLM gateway, Open WebUI, optional vLLM, and optional containerized Ollama profile.
- Stable OpenAI-compatible entrypoint defined at LiteLLM `/v1`.
- Routing config in place for:
  - `qwen35_35b` -> Ollama
  - `phi4` -> Ollama
  - `qwen_coder_32b` -> vLLM (when profile enabled)
- Persistent local storage paths configured under `./data/*`.
- Startup/ops helpers available via `Makefile` + scripts.

## How It Works Now
1. **Client/UI path**
   - Open WebUI sends OpenAI-format requests to LiteLLM (`OPENAI_API_BASE_URL=http://litellm:4000/v1`).
2. **Gateway path**
   - LiteLLM validates key + routes by model alias using `litellm/litellm.yaml`.
3. **Inference path**
   - Ollama models are served from configured Ollama API base.
   - Optional vLLM route is available only when `with-vllm` profile is started.

## Current Operational Commands
- Start default stack: `make start`
- Start with vLLM: `make start-vllm`
- Start with Ollama container profile: `make start-ollama`
- Stop: `make stop`
- Logs: `make logs`
- Health check: `make healthcheck`
- Compose validation: `make validate`

## What Is Verified
- Compose startup flow works through `scripts/bootstrap.sh`.
- LiteLLM readiness endpoint is used for health gating.
- Open WebUI waits on LiteLLM health.
- `/v1/models` listing is used to confirm route visibility.

## Known Limits (Intentional)
- Local-first, single-node oriented.
- No auth hardening/reverse proxy yet (by design for current phase).
- No monitoring stack yet.
- No Kubernetes artifacts yet.
- vLLM availability depends on profile startup and GPU capacity.

## Phase-1 Exit Criteria Status
- [x] Unified OpenAI-compatible API in front of local backends.
- [x] Human test interface (Open WebUI) wired through LiteLLM.
- [x] Reproducible startup + health checks.
- [x] Clear architectural docs and guardrails.

## @end — Expansion Later On
When you’re ready, next expansion should be incremental (not a rewrite):
1. Add secure remote access path (Tailscale) while keeping LiteLLM as the only public API.
2. Add multi-user durability (Postgres for LiteLLM state) before scale-out.
3. Add orchestration workloads (OpenHands/CrewAI/LangGraph) against the same `/v1` contract.
4. Only then plan k3s migration with zero client API changes.
5. Defer distributed inference until single-node bottlenecks are measured.

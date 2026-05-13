# ROADMAP

## Phase 0 (Current): Compose Foundation
- Establish stable `/v1` contract via LiteLLM.
- Run Ollama + optional vLLM behind unified routing.
- Support local developer workflows and core client integrations.

## Phase 1: Multi-User Hardening
- Add stronger auth, TLS termination, and policy boundaries.
- Improve observability, auditability, and capacity guardrails.
- Prepare database/runtime choices for concurrent multi-user access.

## Phase 2: Agent-Oriented Orchestration
- Expand integrations for OpenHands, CrewAI, LangGraph, coding agents.
- Standardize orchestration patterns against LiteLLM contracts.
- Add repo-aware workflow conventions and execution guardrails.

## Phase 3: Remote Secure Access
- Introduce secure remote access path (Tailscale) for team workflows.
- Keep exposure surface minimal: gateway-first access model.
- Preserve local-first behavior for single-user offline operation.

### Phase 3 Exit Criteria
- Remote user reaches Open WebUI over Tailnet HTTPS.
- Remote API client calls `/v1/models` through `https://$DOMAIN_NAME/v1` with a user key.
- Direct backend ports `3000`, `4000`, `11434`, and `8001` are unreachable remotely.
- Local/offline mode works with loopback bindings and no Tailnet dependency.
- Per-user LiteLLM key issue/revoke workflow is documented.
- `remote_healthcheck.sh`, `remote_api_verify.sh`, and `validate_hardening.sh` pass on maintainer workstation.
- Rollback to local-only is documented and tested.

## Phase 4: k3s Migration (When Justified)
- Migrate services to k3s while preserving API compatibility.
- Move persistent state from local mounts to PVC-backed storage.
- Introduce cluster-native scheduling only where needed.

## Phase 5: Distributed Execution (Future)
- Explore multi-node GPU orchestration.
- Add placement/capacity policy for mixed model workloads.
- Evaluate distributed inference only after proven demand.

## Migration Strategy Principles
- Keep clients pinned to LiteLLM endpoint to decouple infra migration.
- Migrate in layers (deployment substrate first, orchestration second).
- Prefer reversible steps and measurable operational gains per phase.

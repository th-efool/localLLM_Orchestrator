# DECISIONS

## ADR-001: Compose-First Deployment
**Decision:** Use Docker Compose as the initial deployment substrate.

**Why:**
- Fast setup for single-node workstation.
- Minimal operational overhead for local development.
- Clear observability/debugging path without cluster indirection.
- Aligns with current scale and team size.

**Tradeoff:** Less native scheduling/scaling than Kubernetes; accepted for current phase.

## ADR-002: Kubernetes Intentionally Deferred
**Decision:** Defer Kubernetes/k3s until operational pressure justifies migration.

**Why:**
- Avoid premature platform complexity.
- Prevent early investment in abstractions not needed for current workload.
- Protect iteration speed while architecture stabilizes.

**Trigger to revisit:** multi-user reliability demands, node-level scheduling requirements, or sustained scaling constraints.

## ADR-003: LiteLLM as Central Contract
**Decision:** Make LiteLLM the mandatory API/routing boundary.

**Why:**
- One OpenAI-compatible endpoint for all clients/tools.
- Backend portability (swap/extend model servers without client rewrites).
- Central place for routing, retries, and policy controls.

**Tradeoff:** Extra hop and gateway dependency; accepted for consistency and maintainability.

## ADR-004: Hybrid Backend Strategy (Ollama + vLLM)
**Decision:** Keep both inference backends with distinct roles.

**Ollama role:**
- Simple, robust local runtime for resident models and dev loops.

**vLLM role:**
- Performance-oriented runtime for larger models and throughput-sensitive workloads.

**Why hybrid:**
- Balances usability and performance.
- Avoids forcing one backend to solve all workloads.

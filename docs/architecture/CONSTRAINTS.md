# CONSTRAINTS

## Anti-Overengineering Rules
- Do not add Kubernetes artifacts until migration criteria are met.
- Do not introduce service mesh without a measured, documented need.
- Do not add distributed inference abstractions before single-node limits are validated.
- Do not bypass LiteLLM contract for primary client integrations.

## Architectural Guardrails
- Keep the OpenAI-compatible `/v1` API as the stable external interface.
- Keep inference backends replaceable behind routing aliases.
- Keep orchestration concerns separate from raw model serving.
- Keep components explainable with clear operational ownership.

## Operational Simplicity Requirements
- Favor minimal moving parts in default local deployment.
- Require health checks and persistent state clarity for runtime services.
- Require explicit environment configuration for secrets and tunables.
- Prefer deterministic startup paths and reproducible local operation.

## Acceptable Complexity Boundaries
Complexity is acceptable only if it:
1. Protects API contract stability,
2. Improves reliability or security for real workloads,
3. Has clear rollback paths,
4. Does not materially reduce developer iteration speed.

If these conditions are not met, defer the change.

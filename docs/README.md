# Documentation Index

Docs are grouped by operator task area. Start with root `README.md` for quick startup.

## Architecture
- [`architecture/SYSTEM_IDENTITY.md`](architecture/SYSTEM_IDENTITY.md) — platform mission and operating philosophy.
- [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md) — current single-node architecture and layer model.
- [`architecture/DECISIONS.md`](architecture/DECISIONS.md) — architecture decision records.
- [`architecture/CONSTRAINTS.md`](architecture/CONSTRAINTS.md) — anti-overengineering guardrails.
- [`architecture/MULTI_USER_ARCHITECTURE.md`](architecture/MULTI_USER_ARCHITECTURE.md) — hardened single-node multi-user model.
- [`architecture/ROADMAP.md`](architecture/ROADMAP.md) — phased evolution plan.

## Operations
- [`operations/OPERATIONS.md`](operations/OPERATIONS.md) — startup, shutdown, logs, lifecycle.
- [`operations/VALIDATION.md`](operations/VALIDATION.md) — verification checklist.
- [`operations/TROUBLESHOOTING.md`](operations/TROUBLESHOOTING.md) — common failures and recovery.
- [`operations/PERFORMANCE.md`](operations/PERFORMANCE.md) — VRAM and throughput expectations.
- [`operations/CAPACITY_PLANNING.md`](operations/CAPACITY_PLANNING.md) — load/concurrency guardrails.
- [`operations/OBSERVABILITY.md`](operations/OBSERVABILITY.md) — logs, metrics, audit visibility.
- [`operations/PHASE1_PROGRESS.md`](operations/PHASE1_PROGRESS.md) — phase 1 status snapshot.

## Security
- [`security/SECURITY.md`](security/SECURITY.md) — security baseline and hardening model.
- [`security/HARDENING_RUNTIME.md`](security/HARDENING_RUNTIME.md) — runtime hardening layer.

## Access
- [`access/REMOTE_ACCESS.md`](access/REMOTE_ACCESS.md) — Tailscale setup, remote architecture, owner checklist, runbooks.
- [`access/API_ACCESS.md`](access/API_ACCESS.md) — OpenAI-compatible API usage and key handling.

## Agents
- [`agents/AGENT_RUNTIME_ARCHITECTURE.md`](agents/AGENT_RUNTIME_ARCHITECTURE.md) — agent runtime layers and execution flow.
- [`agents/AGENT_SAFETY.md`](agents/AGENT_SAFETY.md) — local tool execution safety.
- [`agents/AGENT_WORKFLOWS.md`](agents/AGENT_WORKFLOWS.md) — agent workflow contracts.
- [`agents/MODEL_ROUTING.md`](agents/MODEL_ROUTING.md) — task-to-model routing strategy.
- [`agents/LANGGRAPH_PATTERNS.md`](agents/LANGGRAPH_PATTERNS.md) — LangGraph orchestration patterns.
- [`agents/CREWAI_PATTERNS.md`](agents/CREWAI_PATTERNS.md) — CrewAI orchestration patterns.

## Integrations
- [`integrations/INTEGRATIONS.md`](integrations/INTEGRATIONS.md) — Continue.dev, Claude Code, OpenHands, CrewAI, LangGraph.
- [`integrations/OPENHANDS_SETUP.md`](integrations/OPENHANDS_SETUP.md) — OpenHands LiteLLM setup.
- [`integrations/DEVELOPMENT_WORKFLOWS.md`](integrations/DEVELOPMENT_WORKFLOWS.md) — local-first developer workflows.

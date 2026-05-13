# ARCHITECTURE

## Current Architecture (Single Node)
Current runtime is Docker Compose on a workstation:
- **Inference backend (current)**: host-native Ollama.
- **Routing/API layer**: LiteLLM exposes OpenAI-compatible `/v1`.
- **UI/consumer entrypoint**: Open WebUI and external tools call LiteLLM.

## Layered Architecture Model
1. **Inference Layer**
   - Runs model servers.
   - Responsibilities: model loading, token generation, backend-specific performance tuning.
   - Current component: Ollama.
   - Future option: vLLM.

2. **Routing Layer**
   - Stable API contract for all clients.
   - Responsibilities: OpenAI-compatible API, model aliasing, retries/timeouts, backend abstraction.
   - Current component: LiteLLM.

3. **Orchestration Layer**
   - Coordinates workflow-level logic across tools and model calls.
   - Responsibilities: tool invocation patterns, agent workflows, policy envelopes.
   - Near-term components: CrewAI, LangGraph, OpenHands integrations (client-side or service-level).

4. **Agent Runtime Layer**
   - Executes autonomous coding/automation agents.
   - Responsibilities: task planning, repo-aware execution, guardrails, runtime isolation.
   - Planned focus: coding agents and multi-agent workflows using the stable `/v1` contract.

5. **Future Distributed Execution Layer**
   - Deferred until demand exists.
   - Responsibilities (future): multi-node GPU scheduling, distributed inference, placement policies.

## Service Responsibilities
- **LiteLLM**: canonical API gateway; routing and model indirection.
- **Ollama**: operationally simple local model runtime for day-to-day workflows.
- **Open WebUI**: user interface consumer of unified API.
- **vLLM (future)**: optional high-performance backend for selected workloads.

## Future Orchestration Direction
- Preserve thin stable interfaces (LiteLLM `/v1`) while adding richer orchestration above it.
- Keep inference and orchestration loosely coupled.
- Migrate deployment substrate (Compose -> k3s) without changing client integration contracts.

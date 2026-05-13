# AGENT_RUNTIME_ARCHITECTURE

## 1) Runtime layering (workstation-scale)

1. **Interface layer**
   - Continue.dev, OpenHands, RooCode/Cline, Open WebUI.
   - All clients speak OpenAI-compatible API only.
2. **Agent control layer**
   - Planner/executor loops (CrewAI, LangGraph, OpenHands runtime loop).
   - Deterministic stop conditions, retry budgets, and approval checkpoints.
3. **Tool execution layer**
   - Local shell, git, tests, linters, repo readers/writers.
   - Explicit allowlist of commands and directories.
4. **Inference gateway layer (canonical)**
   - **LiteLLM only** as model abstraction and policy point.
   - Centralized routing, rate control, model aliasing, logging.
5. **Model serving layer**
   - Ollama-backed local models (and optional local OpenAI-compatible backends, still behind LiteLLM).
6. **Infrastructure layer**
   - Windows + WSL2 + Docker Desktop + single-node GPU.

---

## 2) Execution flow

1. User/task enters client (Continue/OpenHands/etc).
2. Client sends request to LiteLLM (`/v1/*`).
3. LiteLLM routes to model alias based on task class.
4. Agent proposes plan.
5. Executor performs bounded tool actions.
6. Validation runs (tests/lint/smoke).
7. Loop continues until success criteria met or retry budget exhausted.
8. Output includes diffs, checks, and rollback path.

---

## 3) Planning vs execution model

- **Planning model (higher reasoning):** qwen-class route.
  - Decomposition, risk analysis, acceptance criteria.
- **Execution model (fast/cheap):** phi-class route.
  - File edits, command execution, quick retries.
- **Escalation policy:**
  - phi -> qwen when repeated failures, ambiguity, or architecture-impacting changes.

---

## 4) Repo interaction flow

1. Read-only discovery (tree, key files, tests, ownership boundaries).
2. Plan with explicit files-to-change list.
3. Patch minimal files.
4. Run narrow checks, then broader checks.
5. Commit with concise traceable message.
6. Emit artifact summary (changed files, commands run, outcomes).

---

## 5) Tool execution assumptions

- Local execution only; no remote build farm.
- Shell commands are sandboxed by policy, not by distributed infra.
- Git is the authoritative rollback mechanism.
- Docker services are long-running shared dependencies.

---

## 6) Context management strategy

- **Layered context windows:**
  - L0: task + constraints.
  - L1: active files + failing logs.
  - L2: architecture docs + historical decisions.
- **Compression policy:** summarize old iterations; keep latest failing evidence verbatim.
- **Repo memory artifacts:**
  - `AGENT_WORKFLOWS.md` patterns.
  - issue-specific scratch notes in branch-local files.

---

## 7) Local model routing strategy (via LiteLLM)

- Route aliases (example):
  - `planner_reasoning` -> qwen route.
  - `executor_fast` -> phi route.
  - `review_guard` -> qwen route.
- Use LiteLLM metadata tags to track task type (`plan`, `edit`, `test`, `review`).
- Keep all clients configured to LiteLLM base URL and key.
- **Never direct-connect clients to Ollama.**

---

## 8) Future scaling (without premature complexity)

Near-term:
- Add stronger policy gates (command allowlist, mutation guards).
- Add structured run logs for loop analytics.
- Add local queueing for concurrent agent tasks.

Later (still workstation-first):
- Multi-repo workspace graph context.
- Controlled multi-agent parallelism with shared state store.
- Optional external observability sink.

Explicitly deferred:
- Kubernetes, service mesh, distributed orchestration.

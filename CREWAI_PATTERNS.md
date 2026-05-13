# CREWAI_PATTERNS

## 1) Local agent topologies

- **2-agent core:** Planner + Executor.
- **3-agent robust:** Planner + Executor + Reviewer.
- **4-agent extended:** Planner + Executor + Reviewer + Test/QA.

## 2) Planner/executor pattern

- Planner (qwen route): break task, define acceptance checks.
- Executor (phi route): implement minimal diffs quickly.
- Reviewer (qwen route): validate against plan and risk boundaries.

## 3) phi4 vs qwen routing strategy

- Use **phi4** for:
  - boilerplate,
  - deterministic edits,
  - retry-heavy command loops.
- Use **qwen** for:
  - architecture choices,
  - ambiguous debugging,
  - cross-file reasoning.
- Escalate phi4->qwen after repeated failed checks.

## 4) Multi-agent coordination example

1. Planner creates numbered execution plan.
2. Executor performs step 1 and reports artifacts.
3. Reviewer checks artifacts and decides continue/rollback.
4. Repeat until all steps done.
5. QA agent runs final verification matrix.

## 5) Local orchestration recommendations

- Keep per-agent context minimal and role-specific.
- Share only structured handoff objects (plan, diff summary, check results).
- Enforce iteration limits and explicit terminal states.
- Route every agent model call through LiteLLM aliases.

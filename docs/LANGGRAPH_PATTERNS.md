# LANGGRAPH_PATTERNS

## 1) Deterministic orchestration patterns

- Use explicit state schema:
  - `objective`, `plan`, `step_index`, `artifacts`, `failures`, `status`.
- Graph should include fixed nodes:
  - Intake -> Plan -> Execute -> Validate -> Decide -> (Loop|Done|Fail).

## 2) Stateful workflow example

- `PlanNode` writes task breakdown.
- `ExecNode` mutates repo for current step.
- `ValidateNode` runs checks and records outputs.
- `DecideNode` branches:
  - pass -> next step,
  - fail + budget left -> retry,
  - fail + exhausted -> abort.

## 3) Retry/error handling

- Retry classes:
  - transient command failure,
  - model output format failure,
  - failing tests.
- Strategy:
  - bounded retries per node,
  - escalating model route on persistent failures,
  - preserve failure evidence in state.

## 4) Planning/execution graph example

- `planner_reasoning` for Plan/Decide nodes.
- `executor_fast` for Execute node.
- Optional `review_guard` after Validate for high-risk changes.

## 5) Local-first recommendations

- Keep graph runner local in WSL2/Docker.
- Use repo-local checkpoints and git commits as durable milestones.
- Keep external dependencies optional and non-blocking.
- Route all model invocations through LiteLLM OpenAI-compatible endpoint.

# AGENT_WORKFLOWS

## Global workflow contract

1. Define objective, constraints, acceptance checks.
2. Run discovery (repo map + failing surface).
3. Create plan (steps + files).
4. Execute minimal patch set.
5. Run checks.
6. Iterate until pass or stop condition.

---

## 1) Repository analysis

- Commands:
  - `rg --files`
  - `rg "TODO|FIXME|HACK|XXX"`
  - `make validate`
- Output:
  - service map, dependency hot spots, flaky/test gaps.

## 2) Technical debt detection

- Signals:
  - dead code, duplicated helpers, stale docs/config drift.
- Commands:
  - `rg "deprecated|legacy|temporary"`
  - lint/type/test runs.
- Deliver:
  - debt list with risk + effort + sequencing.

## 3) Automated refactoring

- Pattern:
  - plan -> small batch edits -> targeted tests -> broader regression checks.
- Guardrails:
  - API compatibility and changelog note when contracts change.

## 4) Code generation

- Inputs:
  - concrete function/class specs + tests first where possible.
- Model split:
  - planner=qwen route, executor=phi route.
- Validate:
  - compile/lint/tests + smoke path.

## 5) Test generation

- Start from changed-file coverage.
- Add happy path + failure path + edge cases.
- Run only impacted tests first, full suite second.

## 6) Iterative debugging

Loop:
1. Reproduce.
2. Isolate failing boundary.
3. Patch minimal fix.
4. Re-run reproducer.
5. Run regression checks.

## 7) Architecture planning

- Use planner model for:
  - option analysis,
  - tradeoff matrix,
  - phased rollout.
- Keep execution model out of architecture-only loops until plan is locked.

## 8) Multi-step implementation tasks

- Template:
  - Step A schema/config.
  - Step B core logic.
  - Step C integration wiring.
  - Step D tests/docs.
- Require check pass at each step before next.

## 9) Autonomous execution loops

- Deterministic controls:
  - max iterations,
  - max command budget,
  - explicit abort conditions.
- Escalation:
  - 2 failed executor loops -> planner reassessment.


# AGENT_SAFETY

## 1) Operational boundaries

- All inference through LiteLLM only.
- No direct tool->Ollama connectivity.
- No Kubernetes/distributed/service-mesh additions at this phase.

## 2) Local execution safety

- Use explicit command allowlist by workflow class.
- Block destructive patterns by default (`rm -rf /`, wide chmod/chown, secret exfil).
- Prefer read-only discovery before mutation.

## 3) Shell/tool execution risks

- Risks:
  - accidental destructive commands,
  - leaking secrets in logs,
  - long-running GPU starvation tasks.
- Controls:
  - timeout on commands,
  - redact env secrets in logs,
  - bounded concurrency.

## 4) Repository mutation risks

- Always branch-per-task.
- Minimize diff scope.
- Require clean status before starting and before final handoff.

## 5) Approval flow (recommended)

- Low risk (docs/tests/non-runtime config): auto-apply + verify.
- Medium risk (runtime logic/config): require human review before merge.
- High risk (security, auth, data, infra lifecycle): require explicit pre-approval and post-change validation.

## 6) Rollback and versioning

- Use atomic commits aligned to plan steps.
- Tag known-good checkpoints.
- Rollback options:
  - `git revert <commit>` for shared history,
  - `git reset --hard <sha>` for local recovery.

## 7) Sandboxing considerations

- Prefer containerized execution for untrusted tools.
- Limit filesystem scope where practical.
- Keep host-level privileged access off by default.

## 8) GPU resource management

- Set model loading and parallelism caps.
- Reserve VRAM headroom for workstation responsiveness.
- Separate heavy reasoning jobs from latency-sensitive coding loops.
- Monitor GPU memory/thermals during long autonomous runs.

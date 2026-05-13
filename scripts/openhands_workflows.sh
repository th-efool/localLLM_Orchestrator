#!/usr/bin/env bash
set -euo pipefail

cat <<'TXT'
OpenHands runnable workflow prompts:

1) Repo analysis
"Analyze /workspace/repo. Output: service map, critical files, test commands, top 5 risks. No edits."

2) Autonomous code-edit
"In /workspace/repo, implement a minimal fix for <ISSUE>. Keep API stable, smallest diff, run impacted tests, report files changed and commands run."

3) Shell-command execution
"Run repo validation commands, summarize failures, propose next patch."

4) Iterative fix loop
"Repeat: patch -> run tests -> refine until pass or 3 iterations. Stop on unsafe/destructive command requests."
TXT

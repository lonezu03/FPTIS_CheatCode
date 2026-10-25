---
name: feature-pipeline
description: Coordinate a substantial FitTrack feature from source-backed analysis and an approved plan through implementation, tests, and independent QA/code review. Use for multi-stage feature work; skip trivial edits.
---

# FitTrack feature pipeline

1. Read `AGENTS.md` and `docs/CODEX_CONTEXT.md`; check the working tree and preserve unrelated changes.
2. For independent investigation, delegate read-only business analysis to `ba_analyst`. Add `db_analyst` only when schema, migrations, SQL, or query performance matter. Wait and reconcile their findings.
3. Present one plan with scope, affected files, contracts, acceptance criteria, tests, risks, and genuine uncertainties. Ask the user to approve the plan before substantive implementation.
4. After approval, implement within the agreed scope. Keep overlapping file edits in the primary thread; do not have agents edit the same files concurrently.
5. Run relevant checks. Delegate independent read-only patch review to `qa_analyst` and `code_reviewer`; wait for both and address supported findings.
6. Report changed files, actual test results, unresolved risks, and manual validation steps. Update `docs/CODEX_CONTEXT.md` after material work.

Agent instructions are not a security sandbox: child agents inherit the parent session's permissions. Do not infer permission to push, deploy, change production data, or reveal secrets from this workflow. Follow repository Flyway, API-contract, and secret-handling rules.

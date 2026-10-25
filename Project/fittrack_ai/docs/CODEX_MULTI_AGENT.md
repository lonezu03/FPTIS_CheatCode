# Codex multi-agent setup for FitTrack

The starter at `E:\Dowload\codex-multi-agent-starter` has been adapted into
this project. The existing `AGENTS.md` remains the source of FitTrack rules;
the starter's generic `AGENTS.md` was not copied over it.

- `.codex/config.toml` enables up to three concurrent child threads.
- `.codex/agents/` defines `ba_analyst`, `db_analyst`, `qa_analyst`, and
  `code_reviewer`.
- `.agents/skills/feature-pipeline/SKILL.md` defines the reusable workflow.

Open `Project/fittrack_ai` as the workspace in VS Code and start a **new**
Codex conversation so project configuration and skills are rediscovered. First
try this read-only prompt:

> Read AGENTS.md and docs/CODEX_CONTEXT.md. List the four project agents and
> the feature-pipeline skill. Do not modify files.

Then try a real request with `$feature-pipeline`, for example:

> Use $feature-pipeline to analyze a small FitTrack feature. Have ba_analyst
> inspect the current workflow and db_analyst inspect only if database changes
> are involved. Present a plan and wait for my approval before code changes.

The agent files ask for read-only behavior, but they do not create a separate
read-only sandbox. Child agents inherit the parent session's permissions.
Keep the parent session's permission setting appropriate for the work and
review all proposed changes. No agent runs continuously merely because its
TOML file exists.

For Codex client behavior, see [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
and [Build skills](https://learn.chatgpt.com/docs/build-skills).

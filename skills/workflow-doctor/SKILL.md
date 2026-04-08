---
name: workflow-doctor
description: "Validates AIDLC task-driven workflow configuration. Use when checking project health, after project-init, when task execution feels broken, or at session start."
---

# Workflow Doctor

Diagnose and report issues with the project's task-driven workflow configuration.

**Core principle:** Report problems with exact fix commands. Never auto-fix — the human decides.

**Announce at start:** "I'm using the workflow-doctor skill to check your workflow configuration."

## When to Use

- After running `project-init`
- When task execution feels broken or inconsistent
- At the start of a new session (quick health check)
- After pulling changes from other contributors
- Before milestone completion review

## The Process

### Step 1: Run Mechanical Checks

Run `./superpowers/skills/workflow-doctor/doctor.sh` from the project root. This checks file existence, permissions, and git configuration in ~2 seconds.

If the script is not available, perform these checks manually:

**Required files:**
- `.qwen/rules/task-driven-development.md` exists
- `.qwen/rules/development-workflow.md` exists
- `.githooks/pre-commit` exists and is executable
- `.githooks/commit-msg` exists and is executable

**Git configuration:**
- `git config core.hooksPath` returns `.githooks`

**Directory structure:**
- `docs/` directory exists
- `docs/specs/` directory exists (for ad-hoc brainstorming output)
- `docs/milestones/` directory exists (for task-driven work)

**Deprecated paths (should NOT exist):**
- `docs/plans/` — plans are transient or appended to specs
- `docs/superpowers/` — old path convention, replaced by `docs/specs/`

### Step 2: Semantic Checks (Agent Reads and Reasons)

**Rule file content:**
- `task-driven-development.md` has: task classification table, phase rules, verification protocol
- `development-workflow.md` has: test commands section, commit conventions

**Active milestone health (if milestones exist):**
- At least one milestone directory has a `SEQUENCE.md`
- `SEQUENCE.md` entries have status markers (⬜/🔄/✅)
- All task files referenced in `SEQUENCE.md` exist on disk
- Task files with `Task Type: Contract` have a `Phase` field (RED or GREEN)
- Dependencies in `SEQUENCE.md` reference existing task IDs
- No ⬜ task has all dependencies ✅ (potential missed unblock — flag as INFO)

**Agent configuration (if `.qwen/agents/` exists):**
- Agent files reference project documentation that exists on disk

### Step 3: Report

**Format:** Summary line + failures with fix commands.

```
Workflow Doctor: 12/14 checks passed, 2 failures

[FAIL] .githooks/pre-commit is not executable
  Fix: chmod +x .githooks/pre-commit

[FAIL] Task M1-005a.md missing Phase field
  Fix: Add "- **Phase:** RED" to task metadata

[INFO] Task M1-008a has all dependencies ✅ but is still ⬜
  Action: This task is ready to work. Pick it up next.
```

**Severity levels:**
- **FAIL** — Must fix before proceeding. Workflow will not function correctly.
- **WARN** — Should fix. Workflow works but may produce unexpected results.
- **INFO** — Informational. No action required but worth noting.

**If all checks pass:**
```
Workflow Doctor: 14/14 checks passed ✅
Your task-driven workflow is healthy.
```

**After reporting, prompt the user with next steps based on context:**

- If milestones exist with ⬜ tasks: "Next available task: [ID] — [title]. Start working on it?"
- If milestones exist but all tasks are ✅: "All tasks complete. Ready for milestone completion review?"
- If no milestones exist: "No milestones found. Would you like to plan your first milestone using the milestone-planning skill?"
- If failures were found: "Fix the issues above, then run doctor again to verify."

## Verbosity

- **Default:** Summary + failures only
- **Verbose (user requests "show all checks"):** Full pass/fail list for every check

## Key Principles

- **Report, don't fix.** Print the exact command to fix each issue. Let the human decide.
- **Fast mechanical checks first.** File existence and permissions take 2 seconds. Do those before reading file content.
- **Graceful with missing milestones.** A project with no milestones yet is not broken — it just hasn't started task-driven work. Report as INFO, not FAIL.
- **No hardcoded paths.** Check for the PATTERN (SEQUENCE.md, task files with metadata), not specific directory names.

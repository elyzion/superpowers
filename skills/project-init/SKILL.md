---
name: project-init
description: "Scaffolds the task-driven AIDLC workflow for a new project. Use when setting up a new project, when no .qwen/rules/ directory exists, or when asked to initialize the workflow."
---

# Project Init

Scaffold the task-driven AIDLC workflow for a new project through guided conversation.

**Core principle:** Detect first, ask second. Infer from project files, confirm with the user, ask only what can't be inferred.

**Announce at start:** "I'm using the project-init skill to set up the task-driven workflow for this project."

## When to Use

- New project with no `.qwen/rules/` directory
- User says "set up AIDLC", "initialize workflow", "project init"
- User wants to adopt the task-driven development workflow

## The Process

### Step 1: Detect Existing State

Check for existing AIDLC artifacts. Don't overwrite what exists.

```
Check: .qwen/rules/          → if exists, offer to reconcile (don't overwrite)
Check: .qwen/agents/         → if exists, skip agent creation
Check: .githooks/             → if exists, verify content
Check: docs/specs/            → if exists, skip
Check: docs/milestones/       → if exists, skip
Check: docs/architecture/     → if exists, skip
```

If everything already exists, suggest running `workflow-doctor` instead.

### Step 2: Detect Tech Stack

Scan project root for build files. Don't ask what the user already told you via files.

| File Found | Stack | Test Command | Lint Command |
|-----------|-------|-------------|-------------|
| `Cargo.toml` | Rust | `cargo test` | `cargo fmt -- --check && cargo clippy -- -D warnings` |
| `package.json` | Node/TypeScript | `npm test` or `yarn test` | `npx eslint .` |
| `pyproject.toml` or `requirements.txt` | Python | `pytest` or `uv run pytest` | `ruff check .` or `black --check .` |
| `go.mod` | Go | `go test ./...` | `golangci-lint run` |
| `pom.xml` or `build.gradle` | Java/Kotlin | `mvn test` or `gradle test` | `mvn checkstyle:check` |

If multiple build files exist (e.g., Rust + Python), ask which is primary.

**Confirm with user:** "I detected [stack] from [file]. I'll configure the workflow for [stack]. OK?"

### Step 3: Detect Project Structure

Check for:
- `[workspace]` in `Cargo.toml` → Rust workspace (multiple crates)
- `workspaces` in `package.json` → monorepo
- Multiple `go.mod` files → Go multi-module
- `.git/` exists → git is initialized

### Step 4: Ask What Can't Be Inferred

Only ask these questions — everything else is detected or has sensible defaults:

1. **Milestone naming convention:** "How do you want to name milestones? (default: M1-name, M2-name, ...)"
2. **Agent templates:** "Do you want me to create domain-specific agent templates in .qwen/agents/? (e.g., a specialist for your primary framework)"

Wait for answers to questions 1 and 2 before proceeding.

### Step 5: Create Files

Create each file only if it doesn't already exist. Use the templates from `stack-templates.md` parameterized by the detected stack.

**Files to create:**

```
.qwen/rules/task-driven-development.md    — Three-tier classification, RED/GREEN rules, verification
.qwen/rules/development-workflow.md       — Stack-appropriate test/lint commands, conventional commits
.qwen/rules/documentation-currency.md     — Generic documentation update rules
.githooks/pre-commit                      — Stack-appropriate lint check
.githooks/commit-msg                      — Conventional commits validation
docs/specs/.gitkeep                       — Ad-hoc brainstorming output directory
docs/milestones/.gitkeep                  — Task-driven work directory
docs/AIDLC-WORKFLOW.md                    — Human workflow guide (parameterized by stack)
```

**Optional files (if user requested agents):**
```
.qwen/agents/{framework}-engineer.md      — Framework specialist agent
.qwen/agents/project-architect.md         — Architecture reviewer agent
```

### Step 6: Configure Git Hooks

```bash
chmod +x .githooks/pre-commit .githooks/commit-msg
git config core.hooksPath .githooks
```

### Step 7: Create Example Milestone

Create a starter milestone with one example of each task type:

```
docs/milestones/M1-foundations/
├── SEQUENCE.md                           — Template with 3 example entries
└── tasks/
    ├── M1-001.md                         — Mechanical example (project setup)
    ├── M1-002a.md                        — Contract RED example (with todo!() pattern for detected stack)
    └── M1-002b.md                        — Contract GREEN example
```

The examples show the pattern. The user deletes or replaces them with real tasks.

### Step 8: Verify

Run `workflow-doctor` to validate the setup:

```
Invoke the workflow-doctor skill to verify the configuration.
```

### Step 9: Commit

```bash
git add -A
git commit -m "chore: initialize AIDLC task-driven workflow"
```

### Step 10: Report

```
AIDLC workflow initialized for [stack]:

Created:
  .qwen/rules/task-driven-development.md
  .qwen/rules/development-workflow.md
  .qwen/rules/documentation-currency.md
  .githooks/pre-commit (stack: [stack])
  .githooks/commit-msg
  docs/specs/
  docs/milestones/M1-foundations/ (with example tasks)
  docs/AIDLC-WORKFLOW.md

Configured:
  git hooks path → .githooks

Note: Example tasks created in docs/milestones/M1-foundations/. Replace with real tasks when ready.

Next steps:
  1. Review docs/AIDLC-WORKFLOW.md for the complete workflow guide
  2. Work through the example tasks to learn the workflow, or replace them with real tasks
  3. Start working: pick the first ⬜ task from SEQUENCE.md
```

**Then prompt the user:**

> "Your workflow is set up. What would you like to do next?
> 1. **Plan your first real milestone** — I'll help break down your features into tasks (milestone-planning skill)
> 2. **Work through the example tasks** — learn the workflow by doing
> 3. **Set up architecture docs first** — brainstorm your project's architecture before planning milestones
> 4. **Just explore** — I'm ready for whatever you need"

## Key Principles

- **Detect, don't ask.** If `Cargo.toml` exists, don't ask "what's your tech stack?"
- **Don't overwrite.** If a file exists, skip it or offer to reconcile.
- **Sensible defaults.** Milestone naming, directory structure, commit conventions all have defaults.
- **Show the pattern.** Example tasks teach the format better than documentation.
- **Verify after creation.** Always run workflow-doctor at the end.

## Red Flags

**Never:**
- Overwrite existing `.qwen/rules/` files without asking
- Create files without confirming the detected stack
- Skip the workflow-doctor verification
- Create milestones with real task content (only examples)
- Hardcode project-specific paths or tool names in the templates

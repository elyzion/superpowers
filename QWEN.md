# Superpowers — Project Context

## Project Overview

**Superpowers** is a complete software development workflow plugin for AI coding agents (Claude Code, Cursor, Codex, Gemini CLI, GitHub Copilot CLI, OpenCode). It provides a composable "skills" library that transforms how coding agents approach software development tasks.

**Version:** 5.0.7

**Core Philosophy:**
- **Test-Driven Development** — Write tests first, always
- **Systematic over ad-hoc** — Process over guessing
- **Complexity reduction** — Simplicity as primary goal
- **Evidence over claims** — Verify before declaring success

The plugin is **zero-dependency** by design. Skills are markdown files that shape agent behavior, not traditional code libraries.

## Architecture

```
superpowers/
├── skills/                    # Core skills library (each skill is a SKILL.md file)
│   ├── brainstorming/         # Socratic design refinement before coding
│   ├── dispatching-parallel-agents/  # Concurrent subagent workflows
│   ├── executing-plans/       # Batch execution with checkpoints
│   ├── finishing-a-development-branch/  # Merge/PR decision workflow
│   ├── receiving-code-review/ # Responding to review feedback
│   ├── requesting-code-review/  # Pre-review checklist
│   ├── subagent-driven-development/   # Fast iteration with three-stage review + specialist routing
│   ├── systematic-debugging/  # 4-phase root cause process
│   ├── test-driven-development/  # RED-GREEN-REFACTOR cycle
│   ├── using-git-worktrees/   # Parallel development branches
│   ├── using-superpowers/     # Introduction to the skills system
│   ├── verification-before-completion/  # Ensure fixes actually work
│   ├── writing-plans/         # Detailed implementation planning
│   └── writing-skills/        # Create new skills (meta-skill)
├── agents/                    # Agent configuration files
│   ├── code-reviewer.md       # General code reviewer agent definition
│   ├── rust-developer.md      # Rust specialist implementer
│   ├── qa-tester.md           # QA/testing specialist reviewer
│   └── ml-engineer.md         # ML/AI specialist implementer
├── commands/                  # CLI commands for various platforms
├── docs/                      # Documentation files
├── hooks/                     # Platform-specific hooks (Claude Code, Cursor)
├── scripts/                   # Utility scripts (e.g., bump-version.sh)
└── tests/                     # Test suites for skill behavior
    ├── brainstorm-server/
    ├── claude-code/
    ├── explicit-skill-requests/
    ├── opencode/
    ├── skill-triggering/
    └── subagent-driven-dev/
```

## Key Files

| File | Purpose |
|------|---------|
| `package.json` | Plugin metadata (name, version, entry point) |
| `.claude-plugin/plugin.json` | Claude Code plugin registration |
| `qwen-extension.json` | Qwen Code extension registration (agents directory) |
| `AGENTS.md` | Contributor guidelines (strict PR requirements) |
| `CLAUDE.md` | Same as AGENTS.md — contributor guidelines |
| `GEMINI.md` | Gemini-specific instructions + tool mapping |
| `gemini-extension.json` | Gemini CLI extension metadata |
| `hooks/hooks.json` | Hook definitions for session start |
| `hooks/run-hook.cmd` | Hook execution script |
| `agents/code-reviewer.md` | General code reviewer agent |
| `agents/rust-developer.md` | Rust specialist agent |
| `agents/qa-tester.md` | QA/testing specialist agent |
| `agents/ml-engineer.md` | ML/AI specialist agent |

## Skills Workflow

The skills trigger automatically based on context:

1. **brainstorming** → Before writing code — refines ideas through questions
2. **using-git-worktrees** → After design approval — creates isolated workspace
3. **writing-plans** → With approved design — breaks work into 2-5 minute tasks (includes Domain Specialist annotation)
4. **subagent-driven-development** / **executing-plans** → With plan — executes tasks with specialist routing and three-stage review
5. **test-driven-development** → During implementation — RED-GREEN-REFACTOR cycle
6. **requesting-code-review** → Between tasks — reviews against plan
7. **finishing-a-development-branch** → When tasks complete — merge/PR workflow

### Specialist Agent Routing

When `subagent-driven-development` executes a plan, it dispatches the appropriate agent based on:

1. **Plan-level `Domain Specialist:`** — annotated by writing-plans (e.g., `rust-developer`, `ml-engineer`, `qa-tester`)
2. **Task-level `Task Specialist:`** — per-task override in the plan
3. **Inference from task content** — file extensions, technology mentions

Specialist agents bring domain expertise that general-purpose agents lack:
- **rust-developer** — Ownership/borrowing, clippy compliance, unsafe scrutiny, ecosystem patterns
- **ml-engineer** — Data validation, evaluation rigor, reproducibility, resource management
- **qa-tester** — Systematic test strategy, edge case mining, anti-pattern detection (mandatory third review stage)

## Development Conventions

### Contributing Guidelines

This project has a **94% PR rejection rate**. Before contributing:

1. **Read the PR template** at `.github/PULL_REQUEST_TEMPLATE.md` — fill in every section
2. **Search existing PRs** (open AND closed) — reference what you found
3. **Verify it's a real problem** someone experienced — not theoretical
4. **Confirm change belongs in core** — domain-specific changes belong in standalone plugins
5. **Get human partner approval** on the complete diff before submitting

### What Will NOT Be Accepted

- Third-party dependencies (plugin is zero-dependency by design)
- "Compliance" changes to skills (skill content is carefully tuned; bar for changes is very high)
- Project-specific or personal configuration
- Bulk/spray-and-pray PRs
- Speculative or theoretical fixes
- Domain-specific skills
- Fork-specific changes
- Fabricated content
- Bundled unrelated changes

### Skill Changes

Skills are **code that shapes agent behavior**, not prose. If modifying skill content:
- Use `superpowers:writing-skills` to develop and test changes
- Run adversarial pressure testing
- Show before/after eval results in PR
- Do not modify carefully-tuned content without evidence

### TDD Workflow (from TDD skill)

The project enforces strict TDD:
1. **RED** — Write one failing test
2. **Verify RED** — Confirm test fails for expected reason
3. **GREEN** — Write minimal code to pass
4. **Verify GREEN** — Confirm test passes, all other tests still pass
5. **REFACTOR** — Clean up (keep tests green)
6. **Repeat**

**Iron Law:** No production code without a failing test first. Code written before tests must be deleted and re-implemented.

## Platform Support

| Platform | Installation Method |
|----------|-------------------|
| Claude Code | `/plugin install superpowers@claude-plugins-official` |
| Cursor | `/add-plugin superpowers` |
| Codex | Follow `.codex/INSTALL.md` |
| OpenCode | Follow `.opencode/INSTALL.md` |
| GitHub Copilot CLI | `copilot plugin install superpowers@superpowers-marketplace` |
| Gemini CLI | `gemini extensions install https://github.com/obra/superpowers` |

## Testing

Tests live in the `tests/` directory and verify skill behavior across platforms:

- `tests/claude-code/` — Claude Code specific tests
- `tests/opencode/` — OpenCode specific tests
- `tests/skill-triggering/` — Skill activation tests
- `tests/subagent-driven-dev/` — Subagent workflow tests
- `tests/explicit-skill-requests/` — Skill invocation tests
- `tests/brainstorm-server/` — Brainstorming skill tests

## Useful Commands

```bash
# Update plugin
/plugin update superpowers

# Version bump (for maintainers)
./scripts/bump-version.sh
```

## Key Terminology

- **"Human partner"** — Deliberate term for the user (not interchangeable with "the user")
- **"Skill"** — A markdown file that shapes agent behavior during development
- **"Subagent"** — A spawned agent instance for parallel task execution
- **"Specialist Agent"** — A subagent with domain-specific expertise (rust-developer, ml-engineer, qa-tester)
- **"Domain Specialist"** — Plan-level annotation that guides specialist agent dispatch
- **"Worktree"** — An isolated git workspace for development branches
- **"Slop"** — Low-quality, agent-generated PRs that will be closed without review

## Community

- **Discord:** https://discord.gg/Jd8Vphy9jq
- **Issues:** https://github.com/obra/superpowers/issues
- **Release announcements:** https://primeradiant.com/superpowers/
- **Author:** Jesse Vincent (obra)

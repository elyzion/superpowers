---
name: milestone-planning
description: "Decomposes a milestone's feature scope into ordered, dependency-mapped task files with four-tier classification (Contract/Integration/Mechanical/Content). Use when planning a new milestone, breaking down a roadmap milestone into tasks, or when asked to create a task breakdown."
---

# Milestone Planning

Decompose a milestone into ordered, dependency-mapped task files ready for task-driven execution.

**Core principle:** Read scope → decompose → classify → map dependencies → human approves → write files.

**Announce at start:** "I'm using the milestone-planning skill to break down this milestone into tasks."

## When to Use

- Planning a new milestone from the project's roadmap
- Breaking down a large feature into implementable tasks
- User says "plan milestone", "break down milestone", "create task breakdown"
- After milestone completion, planning the next one

**For ad-hoc tasks** not tied to a roadmap milestone, use `code-task-generation` instead.

## The Process

### Step 1: Read Scope

Read the project's roadmap document for the milestone's feature list and scope boundaries.
Read the project's architecture documentation for relevant contracts, types, and interfaces.

> "Planning [milestone name]. Reading roadmap and architecture docs for scope..."

If no roadmap exists, ask the user to describe the milestone's scope.

### Step 2: Identify Features

List the discrete features/components the milestone delivers. Present to the user:

> "This milestone covers [N] features:
> 1. [Feature A] — [one-line description]
> 2. [Feature B] — [one-line description]
> ...
> Does this match your expectations? Anything to add or remove?"

Wait for confirmation before proceeding.

### Step 3: Decompose Into Tasks

For each feature, break it into tasks following these sizing rules:

| Rule | Guideline |
|------|-----------|
| **One component per task** | One struct, one system, one trait — not a whole module |
| **30-150 lines of production code** | Below 30 is ceremony-heavy. Above 150 the agent loses coherence. |
| **3-10 tests per Contract task** | Enough to define behavior, not so many they're redundant |
| **1-3 files per task** | Source + test + maybe a type definition |
| **No cross-module changes** | A task works within one module. If it needs types from a shared module, those are a prerequisite task. |

For each task, determine:
- **What it produces** (types, functions, systems, configuration)
- **What it depends on** (which other tasks must complete first)
- **Stub pattern** for the project's language (e.g., `todo!()` for Rust, `raise NotImplementedError` for Python, `throw new Error('not implemented')` for TypeScript)

### Step 4: Classify Tasks

Assign each task a tier:

| Tier | Criteria | Phase Split |
|------|----------|-------------|
| **Contract** | Creates new types, systems, traits, or core logic | YES — split into RED (a) and GREEN (b) |
| **Integration** | Wires multiple existing components together | NO — single phase with tests |
| **Mechanical** | Configuration, scaffolding, file moves, formatting | NO — single phase, no TDD |
| **Content** | Non-code artifacts (YAML, prompts, config, writing) | NO — human-authored or AI draft → human review |

Split every Contract task into two:
- **[ID]a** (RED): Write failing tests + stub signatures. Zero implementation.
- **[ID]b** (GREEN): Make tests pass. Zero test changes. Depends on [ID]a.

### Step 5: Map Dependencies

Draw the dependency graph. Rules:
- GREEN tasks always depend on their RED counterpart
- Integration tasks depend on the GREEN tasks of the components they wire together
- Mechanical tasks typically have no dependencies (or depend on project setup)
- Content tasks use `M{N}-C{NNN}` naming. Front-load them in SEQUENCE.md — they block code tasks and require human input. Use schema-first pattern: define format (Mechanical) before content (Content) so tests can validate against schema while content is authored.
- No circular dependencies (if found, restructure)

Present the dependency graph:

```
M1-001 (Mechanical: project setup)
M1-002a (RED: core types tests) ← depends on M1-001
M1-002b (GREEN: core types impl) ← depends on M1-002a
M1-003a (RED: feature X tests) ← depends on M1-002b
M1-003b (GREEN: feature X impl) ← depends on M1-003a
M1-010 (Integration: X + Y wiring) ← depends on M1-003b, M1-005b
```

### Step 6: Present Complete Breakdown (HARD GATE)

Present the full task list as a table:

> "Here's the complete breakdown for [milestone]:
>
> | # | Task | Type | Phase | Depends On | Est. Lines |
> |---|------|------|-------|-----------|------------|
> | M1-001 | Project setup | Mechanical | — | — | ~30 |
> | M1-002a | Core types — tests | Contract | RED | M1-001 | ~80 |
> | M1-002b | Core types — impl | Contract | GREEN | M1-002a | ~80 |
> | ... | ... | ... | ... | ... | ... |
>
> Total: [N] tasks ([X] Contract pairs, [Y] Integration, [Z] Mechanical).
> Estimated total: ~[LOC] lines of production code.
>
> **Review this breakdown. I will NOT create any files until you approve.**
> Changes? Additions? Removals? Or approve to proceed?"

**Do NOT create any files until the user explicitly approves.** This is a hard gate.

### Step 7: Check for Existing Directory

Before writing files, check if the milestone directory already exists:
- If it exists with content: "Directory already exists with [N] files. Merge new tasks in, or replace? (This is destructive if you choose replace.)"
- If it exists but is empty: proceed silently
- If it doesn't exist: create it

### Step 8: Write Files

On approval, create:

1. **Milestone directory:** `docs/milestones/[milestone-name]/tasks/`
2. **SEQUENCE.md:** Dependency graph + ordered task table with ⬜ status markers
3. **Individual task files:** One per task, following the format defined in the project's `task-driven-development` rules

Assign a `Task Specialist` to each task based on the project's available agents and the task's domain.

> "Writing [N] task files to docs/milestones/[milestone-name]/..."

### Step 9: Commit

Ask before committing:

> "Task files written. Commit with `docs(milestones): add [milestone-name] task breakdown`?"

### Step 10: Next Steps

> "[Milestone] is planned with [N] tasks. What would you like to do?
> 1. **Start working** — the first available task is [ID]: [title]
> 2. **Review the task files** — read through them before starting
> 3. **Adjust the breakdown** — modify tasks before starting work
> 4. **Plan another milestone** — continue planning"

## Edge Cases

### Milestone Too Big
If the decomposition produces more than ~40 tasks, flag it:

> "This milestone has [N] tasks — that's larger than typical (20-35). Consider splitting into two milestones: [suggested split point]. Want me to propose a split?"

### Unclear Dependencies
If a task's dependencies are ambiguous, ask:

> "Task [ID] ([title]) — does this depend on [other task], or can it be worked independently?"

### Feature Needs Brainstorming
If a feature's scope is unclear during decomposition:

> "Feature [X] isn't well-defined enough to decompose into tasks. Want to brainstorm it first? (This will create a spec in docs/specs/ that we can then decompose.)"

## Key Principles

- **Human approves before files are written.** The skill proposes; the human disposes.
- **One component per task.** If a task touches more than one component, split it.
- **Dependencies flow downward.** RED before GREEN. Components before integration.
- **Sizing is a guideline, not a law.** 30-150 lines is the target. Some tasks will be 20, some 200. Flag outliers.
- **The task file IS the spec.** It must contain enough information for an agent with zero project context to implement it.

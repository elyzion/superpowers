---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Domain Specialist Routing

If this plan involves a specialized domain, annotate it so the subagent dispatcher knows which specialist agent to use. Add the `**Domain Specialist:**` field to the plan header (see below).

**When to specify a domain specialist:**
- **rust-developer** — Implementation is primarily Rust code (systems programming, async services, CLI tools, embedded, FFI, performance-critical code)
- **ml-engineer** — Implementation involves ML model integration, training pipelines, prompt engineering, evaluation harnesses, data validation, MLOps
- **qa-tester** — Implementation is primarily test infrastructure, QA tooling, test framework development, or coverage analysis systems

**When NOT to specify:** General application development, web frontends, API backends in common languages (Python web, Node.js, Go, etc.), configuration changes, documentation. These use the standard `general-purpose` implementer.

**Per-task overrides:** If most tasks are general but one task needs a specialist (or vice versa), add `**Task Specialist:** <agent-name>` to that specific task's metadata.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Domain Specialist:** [rust-developer | ml-engineer | qa-tester | (omit if not applicable)]

---
```

## Commit Message Format

All commits MUST follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) format. The plan specifies the exact commit message for each task — the implementer executes it verbatim.

**Format:** `<type>[scope][!]: <description>`

**Allowed types:**
- `feat` — New feature (SemVer MINOR)
- `fix` — Bug fix (SemVer PATCH)
- `test` — Test additions or modifications
- `refactor` — Code refactoring (no behavior change)
- `docs` — Documentation changes
- `chore` — Maintenance tasks, build config, tooling
- `ci` — CI/CD configuration changes
- `build` — Build system or dependency changes
- `perf` — Performance improvements
- `style` — Code style changes (formatting, whitespace, no behavior change)

**Scope:**
- Each task specifies its scope in the commit message (e.g., `feat(auth):`, `fix(parser):`)
- Use a single noun that identifies the section of the codebase (no spaces, lowercase)
- If the task touches multiple unrelated areas, split into separate commits

**Breaking changes:**
- If a task introduces a breaking change, flag it with `**Breaking Change:** yes` in the task metadata
- The commit message uses `!` suffix: `feat(api)!: deprecate v1 endpoints`
- Include a `BREAKING CHANGE:` footer in the commit body when the break isn't obvious from the description
- The spec should flag breaking changes — if the implementer discovers an unanticipated breaking, they report it and the plan is updated

**Description rules:**
- Imperative mood ("add" not "added" or "adds")
- No period at the end
- Max 72 characters
- Be specific — "add user login endpoint" not "add feature"

**Example commit messages:**
```
feat(auth): add JWT-based login with token refresh
fix(parser): handle null values in nested JSON objects
refactor(db): extract connection pooling into dedicated module
test(index): add edge cases for corrupted index recovery
feat(api)!: require authentication on all endpoints

BREAKING CHANGE: all API endpoints now require valid auth token
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Task Specialist:** [rust-developer | ml-engineer | qa-tester | (omit to use plan's Domain Specialist)]

**Commit Scope:** [scope-name]

**Breaking Change:** [yes | (omit)]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat(scope): add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Commit message format:** Does each task's Step 5 commit message follow `<type>[scope][!]: <description>` format? Is the type correct? Does the scope match the task? If breaking, is `!` present? Is the description imperative mood, no period, max 72 chars?

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Fresh subagent per task + three-stage review (spec compliance, code quality, QA/testing)
- If plan specifies Domain Specialist, that agent is dispatched for implementation tasks

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review

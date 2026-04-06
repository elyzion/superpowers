# Rust Developer Dispatch Prompt Template

Use this template when dispatching the rust-developer specialist subagent for a Rust task.

**Purpose:** Implement Rust code with proper ownership, borrowing, error handling, and clippy compliance

```
Task tool (superpowers:rust-developer):
  description: "Implement Task N (Rust): [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Rust-Specific Requirements

    [Any Rust-specific constraints: MSRV, required crates, unsafe justification, performance targets]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - Ownership patterns, lifetime design, or error type architecture
    - Dependencies or existing codebase patterns
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

    ## Your Job

    Once you're clear on requirements:
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
    3. Verify: `cargo test --all-features` passes, `cargo clippy` has zero warnings, `cargo fmt` is clean
    4. Commit your work (see Commit Message Format below)
    5. Self-review (see below)
    6. Report back

    Work from: [directory]

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.

    ## Commit Message Format

    All commits MUST follow the Conventional Commits format:

    ```
    <type>[scope][!]: <description>
    ```

    **Types:** `feat` (new feature), `fix` (bug fix), `test` (test changes), `refactor` (refactoring), `docs` (documentation), `chore` (maintenance), `ci` (CI config), `build` (build system), `perf` (performance), `style` (code style, no behavior change)

    **Scope:** Use the scope from the task: [scope-name]

    **Breaking changes:** If the task is marked **Breaking Change: yes**, add `!` after the scope. If you discover an unanticipated breaking change, report it as DONE_WITH_CONCERNS.

    **Description rules:**
    - Imperative mood: "add" not "added" or "adds"
    - No period at the end
    - Max 72 characters
    - Be specific about what changed

    If the plan provides an exact `git commit -m "..."` command, use it verbatim.
    If you are generating the commit message yourself, follow the format above.

    ## Rust Discipline

    - No `.unwrap()` or `.expect()` in production code (acceptable in tests with reasoning)
    - No `clone()` without justification in comments
    - No `unsafe` without explicit safety comment documenting invariants
    - No `#[allow(clippy::...)]` without comment explaining why the warning is incorrect
    - Error types must implement `std::error::Error` with proper `Display` and `Debug`
    - Follow existing project patterns for error handling (thiserror vs anyhow vs custom)

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Are all public API surfaces documented with `///` doc comments?
    - Are there edge cases I didn't handle?

    **Rust Correctness:**
    - Are all lifetimes correct and minimal?
    - Is `Send`/`Sync` correct for all async types?
    - Are all `Result` and `Option` cases handled explicitly?
    - Does `cargo clippy --all-features --all-targets` pass cleanly?
    - Does `cargo fmt --check` pass?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate?
    - Is the code clean and maintainable?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented (or what you attempted, if blocked)
    - Test results: `cargo test`, `cargo clippy`, `cargo fmt` output
    - Files changed
    - Self-review findings (if any)
    - Any issues or concerns (especially around ownership, lifetimes, or unsafe)

    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
    information that wasn't provided. Never silently produce work you're unsure about.
```

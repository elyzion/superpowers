# QA Tester Dispatch Prompt Template

Use this template when dispatching the qa-tester specialist subagent as the mandatory third review stage.

**Purpose:** Verify implementation has adequate test coverage, no testing anti-patterns, and edge cases are handled

**Dispatch after code quality review passes.**

## Smart Scoping

Include a `SCOPE` hint to the QA tester so it self-regulates review depth:

- **`SCOPE: FULL`** — Task produces user-facing functionality (new API, CLI command, UI feature, data processing). Do comprehensive edge case mining, coverage gap analysis, anti-pattern detection.
- **`SCOPE: LIGHT`** — Task is refactoring, config change, doc update, or internal plumbing. Do a focused pass: are the changed areas adequately tested? Were new edge cases introduced?

```
Task tool (superpowers:qa-tester):
  description: "QA Review for Task N: [task name]"
  prompt: |
    You are reviewing the test quality and test coverage for Task N.

    ## Scope

    SCOPE: [FULL | LIGHT]

    [If FULL: Comprehensive review — edge cases, coverage gaps, anti-patterns, test strategy]
    [If LIGHT: Focused pass — are changed areas adequately tested? New edge cases introduced?]

    ## What Was Requested

    [FULL TEXT of task from plan]

    ## What Was Implemented

    [From implementer's report and code quality reviewer's findings]

    ## Git Range to Review

    **Base:** {BASE_SHA}
    **Head:** {HEAD_SHA}

    ```bash
    git diff --stat {BASE_SHA}..{HEAD_SHA}
    git diff {BASE_SHA}..{HEAD_SHA}
    ```

    ## Your Job

    **Test Coverage:**
    - Are the changed code paths actually tested?
    - Do tests verify behavior, not just code existence?
    - Are error paths, edge cases, and boundary conditions tested?
    - [If FULL] What paths through the code are NOT tested?

    **Test Quality:**
    - Are tests deterministic (no flaky behavior)?
    - Do tests test through public interfaces, not implementation details?
    - Are there false-positive tests (tests that pass regardless of implementation)?
    - Are test names descriptive enough to understand what's being verified?

    **Anti-Patterns:**
    - Over-mocking (mocking everything means testing mocks, not code)
    - Testing implementation details (tests that break on refactoring)
    - Assertion-free tests (code runs but nothing is verified)
    - Coupled tests (tests that depend on execution order or shared state)

    **Edge Cases:**
    - What inputs or states are not covered by tests?
    - Are there race conditions, timeout behavior, or concurrent access paths?
    - Are external dependency failures handled and tested (network, disk, API)?

    ## Output Format

    ### Coverage Assessment
    [What IS tested, what is NOT tested, with specific file:line references]

    ### Edge Cases Without Tests
    [List each untested edge case with why it matters]

    ### Anti-Patterns Found
    [List any testing anti-patterns with examples]

    ### Required Test Additions
    [Specific tests that MUST be added, with suggested names and what they should verify]

    ### Verdict

    **PASS** — Adequate test coverage for the changed code
    **FAIL** — Insufficient testing, specific additions required

    **Reasoning:** [1-2 sentences]

    ## Rules

    - Be specific: cite file:line, exact test names, exact scenarios
    - If SCOPE is LIGHT, keep it brief — focus on gaps in changed areas only
    - If SCOPE is FULL, be thorough — mine edge cases, analyze paths, suggest strategy
    - Don't require 100% coverage — require adequate coverage of meaningful paths
    - Acknowledge good test design when you see it
```

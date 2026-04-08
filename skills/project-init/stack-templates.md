# Stack Templates

Reference templates for `project-init`. Select the appropriate template based on detected tech stack.

---

## Pre-Commit Hook Templates

### Rust
```bash
#!/bin/sh
set -e
cargo fmt -- --check 2>/dev/null || { echo "❌ cargo fmt check failed. Run: cargo fmt"; exit 1; }
cargo clippy -- -D warnings 2>/dev/null || { echo "❌ clippy warnings found. Run: cargo clippy -- -D warnings"; exit 1; }
```

### TypeScript/Node
```bash
#!/bin/sh
set -e
npx eslint . --quiet 2>/dev/null || { echo "❌ eslint failed. Run: npx eslint . --fix"; exit 1; }
npx prettier --check . 2>/dev/null || { echo "❌ prettier check failed. Run: npx prettier --write ."; exit 1; }
```

### Python
```bash
#!/bin/sh
set -e
ruff check . 2>/dev/null || { echo "❌ ruff check failed. Run: ruff check . --fix"; exit 1; }
ruff format --check . 2>/dev/null || { echo "❌ ruff format failed. Run: ruff format ."; exit 1; }
```

### Go
```bash
#!/bin/sh
set -e
gofmt -l . | grep -q . && { echo "❌ gofmt failed. Run: gofmt -w ."; exit 1; } || true
golangci-lint run 2>/dev/null || { echo "❌ golangci-lint failed"; exit 1; }
```

---

## Commit-Msg Hook (Generic — All Stacks)

```bash
#!/bin/sh
msg=$(head -1 "$1")
echo "$msg" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|chore|ci|build)(\(.+\))?!?: .+' || {
  echo "❌ Invalid commit message format."
  echo "   Expected: type(scope): description"
  echo "   Types: feat|fix|docs|style|refactor|perf|test|chore|ci|build"
  echo "   Got: $msg"
  exit 1
}
```

---

## Development Workflow Rule Templates

### Rust
```markdown
## TDD Conventions (Rust)

- Tests before implementation. No production code without a failing test.
- Per-crate test organization: `#[cfg(test)]` modules or `tests/` directory
- Mock external dependencies behind traits

### Test Commands
    cargo test                              # All workspace tests
    cargo test -p <crate-name>              # Per-crate
    cargo test --test '*'                   # Integration tests only
    cargo fmt -- --check && cargo clippy -- -D warnings && cargo test  # Full verify
```

### TypeScript
```markdown
## TDD Conventions (TypeScript)

- Tests before implementation. No production code without a failing test.
- Test files co-located: `*.test.ts` or `*.spec.ts` next to source
- Mock external dependencies with jest.mock or vitest.mock

### Test Commands
    npm test                                # All tests
    npm test -- --testPathPattern=<pattern> # Specific tests
    npx eslint . && npx prettier --check . && npm test  # Full verify
```

### Python
```markdown
## TDD Conventions (Python)

- Tests before implementation. No production code without a failing test.
- Test files in `tests/` mirroring `src/` structure
- Mock external dependencies with unittest.mock or pytest-mock

### Test Commands
    pytest                                  # All tests
    pytest tests/test_<module>.py           # Per-module
    ruff check . && ruff format --check . && pytest  # Full verify
```

### Go
```markdown
## TDD Conventions (Go)

- Tests before implementation. No production code without a failing test.
- Test files co-located: `*_test.go` next to source
- Mock external dependencies with interfaces

### Test Commands
    go test ./...                           # All tests
    go test ./pkg/<package>/                # Per-package
    gofmt -l . && golangci-lint run && go test ./...  # Full verify
```

---

## Task File Templates

### Mechanical Task Example
```markdown
# M1-001: Project Setup

## Metadata
- **Task Specialist:** general-engineer-local
- **Task Type:** Mechanical
- **Crate/Package:** (project root)
- **Depends On:** (none)

## Objective
Set up the project's build configuration and verify all tools work.

## Acceptance Criteria
- [ ] Build succeeds
- [ ] Linter passes with zero warnings
- [ ] Test command runs (even if no tests exist yet)

## Verification
Run: `<project test command>`
Expected: Clean build, zero warnings
```

### Contract RED Task Example
```markdown
# M1-002a: Core Types — TESTS

## Metadata
- **Task Specialist:** <stack>-engineer-cloud
- **Task Type:** Contract
- **Phase:** RED
- **Crate/Package:** <primary package>
- **Depends On:** M1-001

## Objective
Write failing tests for the core data types.

## Behavioral Test Scenarios
1. Type can be constructed with valid inputs
2. Type rejects invalid inputs
3. Type serializes and deserializes correctly (roundtrip)

## Constraint
Only test files and stub signatures. No implementation logic.

## Verification
Run: `<project test command>`
Expected: All tests FAIL
```

### Contract GREEN Task Example
```markdown
# M1-002b: Core Types — IMPLEMENTATION

## Metadata
- **Task Specialist:** <stack>-engineer-cloud
- **Task Type:** Contract
- **Phase:** GREEN
- **Crate/Package:** <primary package>
- **Depends On:** M1-002a

## Objective
Implement the core data types to make all failing tests pass.

## Constraint
Only implementation files. Do NOT modify test files.

## Verification
Run: `<project test command>`
Expected: All tests PASS
```

---

## SEQUENCE.md Template

```markdown
# Milestone 1: Foundations — Task Sequence

## Task Graph
    M1-001 (Mechanical: project setup)
    M1-002a (RED: core types tests) ← depends on M1-001
    M1-002b (GREEN: core types impl) ← depends on M1-002a

## Ordered Task List

| # | Task | Type | Phase | Specialist | Depends On | Status |
|---|------|------|-------|-----------|-----------|--------|
| M1-001 | Project setup | Mechanical | — | general-engineer-local | — | ⬜ |
| M1-002a | Core types — tests | Contract | RED | <stack>-engineer-cloud | M1-001 | ⬜ |
| M1-002b | Core types — impl | Contract | GREEN | <stack>-engineer-cloud | M1-002a | ⬜ |
```

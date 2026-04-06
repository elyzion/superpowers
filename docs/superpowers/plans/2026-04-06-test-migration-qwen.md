# Test Migration to Qwen Code Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all Claude Code and OpenCode tests with Qwen Code equivalents.

**Architecture:** Update existing test scripts by replacing `claude`/`opencode` CLI invocations with `qwen` CLI equivalents, session log paths from `~/.claude/projects/` to `~/.qwen/tmp`, and token analysis for Qwen session format. Delete OpenCode-specific tests. Keep platform-agnostic tests as-is.

**Tech Stack:** Bash, Python 3, Node.js, git, qwen CLI

**Domain Specialist:** qa-tester

---

### Task 1: Delete OpenCode Tests

**Files:**
- Delete: `tests/opencode/setup.sh`
- Delete: `tests/opencode/run-tests.sh`
- Delete: `tests/opencode/test-plugin-loading.sh`
- Delete: `tests/opencode/test-tools.sh`
- Delete: `tests/opencode/test-priority.sh`

**Commit Scope:** tests

- [ ] **Step 1: Delete OpenCode test files**

```bash
git rm tests/opencode/setup.sh tests/opencode/run-tests.sh tests/opencode/test-plugin-loading.sh tests/opencode/test-tools.sh tests/opencode/test-priority.sh
```

- [ ] **Step 2: Verify directory is empty, remove it**

```bash
rmdir tests/opencode
```

- [ ] **Step 3: Commit**

```bash
git add tests/opencode && git commit -m "test: remove OpenCode-specific tests

Remove all OpenCode test files (setup, plugin-loading, tools, priority,
runner). Focusing on Qwen Code as the target platform."
```

### Task 2: Update test-helpers.sh

**Files:**
- Modify: `tests/claude-code/test-helpers.sh`

**Commit Scope:** tests

- [ ] **Step 1: Replace run_claude() with run_qwen()**

Replace the `run_claude` function. Change:
- Command from `claude -p "$prompt"` to `qwen "$prompt"`
- Add `-o stream-json -y` flags by default (machine-readable output + auto-approve)
- Update the function comment from "Run Claude Code" to "Run Qwen Code"

The new function:
```bash
# Run Qwen Code with a prompt and capture output
# Usage: run_qwen "prompt text" [timeout_seconds] [allowed_tools]
run_qwen() {
    local prompt="$1"
    local timeout="${2:-60}"
    local allowed_tools="${3:-}"
    local output_file=$(mktemp)

    # Build command with stream-json output and yolo mode
    local cmd="qwen \"$prompt\" -o stream-json -y"
    if [ -n "$allowed_tools" ]; then
        cmd="$cmd --allowed-tools $allowed_tools"
    fi

    # Run Qwen in headless mode with timeout
    if timeout "$timeout" bash -c "$cmd" > "$output_file" 2>&1; then
        cat "$output_file"
        rm -f "$output_file"
        return 0
    else
        local exit_code=$?
        cat "$output_file" >&2
        rm -f "$output_file"
        return $exit_code
    fi
}
```

- [ ] **Step 2: Update exported function name**

Change the last line from `export -f run_claude` to `export -f run_qwen`.

- [ ] **Step 3: Commit**

```bash
git add tests/claude-code/test-helpers.sh && git commit -m "test: replace run_claude with run_qwen in test helpers

Update test-helpers.sh to use 'qwen' CLI instead of 'claude'.
Add -o stream-json -y flags for machine-readable output and auto-approval."
```

### Task 3: Update analyze-token-usage.py

**Files:**
- Modify: `tests/claude-code/analyze-token-usage.py`

**Commit Scope:** tests

- [ ] **Step 1: Update session file parsing for Qwen format**

The `analyze_main_session` function currently parses Claude's JSONL format. Update it to parse Qwen's session format from `~/.qwen/tmp`. The key changes:
- Qwen session files use different field names for assistant messages and tool results
- The `usage` object structure may differ — adapt field access accordingly
- Agent IDs for subagents may use a different naming scheme

Specifically:
- Replace references to `data.get('type') == 'assistant'` with Qwen's message type field
- Replace references to `data.get('type') == 'user'` with Qwen's message type field
- Replace `data.get('toolUseResult')` with Qwen's tool result field
- Replace `data['message'].get('usage', {})` with Qwen's usage field structure
- Update the `agentId` field reference to match Qwen's subagent identifier field

The function signature and output format stay the same — only the JSON parsing logic changes.

- [ ] **Step 2: Update docstring and comments**

Change docstring from "Analyze token usage from Claude Code session transcripts" to "Analyze token usage from Qwen Code session transcripts."

- [ ] **Step 3: Commit**

```bash
git add tests/claude-code/analyze-token-usage.py && git commit -m "test: adapt token analyzer for Qwen session format

Update analyze-token-usage.py to parse Qwen Code session transcripts
from ~/.qwen/tmp instead of Claude's format."
```

### Task 4: Update claude-code behavioral tests

**Files:**
- Modify: `tests/claude-code/test-document-review-system.sh`
- Modify: `tests/claude-code/test-subagent-driven-development.sh`
- Modify: `tests/claude-code/test-subagent-driven-development-integration.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`
- Modify: `tests/claude-code/README.md`

**Commit Scope:** tests

- [ ] **Step 1: Update test-document-review-system.sh**

Replace `run_claude` calls with `run_qwen` calls. Update any `source` path references. Update the platform check from `command -v claude` to `command -v qwen`.

- [ ] **Step 2: Update test-subagent-driven-development.sh**

Replace all `run_claude` calls with `run_qwen`. Keep all 9 test questions identical — only the CLI invocation changes.

- [ ] **Step 3: Update test-subagent-driven-development-integration.sh**

Replace `run_claude` with `run_qwen`. Update:
- Session file finding: `find ~/.claude/projects/ -name '*.jsonl'` → `find ~/.qwen/tmp -name '*.jsonl'`
- The timeout (30 min → consider using `--max-session-turns` instead of raw timeout)
- The token analyzer call to use the updated Python script

- [ ] **Step 4: Update run-skill-tests.sh**

Change `command -v claude` check to `command -v qwen`. Update all `run_claude` calls to `run_qwen`.

- [ ] **Step 5: Update README.md**

Replace all references to "Claude Code" with "Qwen Code" in the test documentation. Update example commands from `claude -p` to `qwen "prompt"`. Update any setup instructions.

- [ ] **Step 6: Commit**

```bash
git add tests/claude-code/ && git commit -m "test: update claude-code behavioral tests for Qwen

Replace run_claude with run_qwen in all behavioral tests.
Update session log paths, platform checks, and documentation."
```

### Task 5: Update explicit-skill-requests tests

**Files:**
- Modify: `tests/explicit-skill-requests/run-test.sh`
- Modify: `tests/explicit-skill-requests/run-all.sh`
- Modify: `tests/explicit-skill-requests/run-multiturn-test.sh`
- Modify: `tests/explicit-skill-requests/run-haiku-test.sh`
- Modify: `tests/explicit-skill-requests/run-extended-multiturn-test.sh`
- Modify: `tests/explicit-skill-requests/run-claude-describes-sdd.sh`
- Rename: `tests/explicit-skill-requests/run-claude-describes-sdd.sh` → `tests/explicit-skill-requests/run-qwen-describes-sdd.sh`

**Commit Scope:** tests

- [ ] **Step 1: Update run-test.sh**

Replace:
- `claude -p "$prompt"` → `qwen "$prompt" -o stream-json -y`
- `claude -p --continue "$prompt"` → `qwen -c "$prompt" -o stream-json -y`
- Session file finding: parse from `~/.qwen/tmp` instead of `~/.claude/projects/`
- Update the JSON stream parsing to match Qwen's `stream-json` output format

- [ ] **Step 2: Update run-all.sh**

Same changes — replace `claude` with `qwen` invocations.

- [ ] **Step 3: Update run-multiturn-test.sh**

Replace:
- `claude -p --continue` → `qwen -c`
- Session parsing updated

- [ ] **Step 4: Update run-haiku-test.sh**

Replace:
- `claude -p --model haiku` → `qwen -m <model>` (use an appropriate Qwen model)
- Update the Haiku-specific logic to Qwen model-specific logic
- The test purpose is the same: verify skill invocation after multi-turn with a smaller model

- [ ] **Step 5: Update run-extended-multiturn-test.sh**

Same pattern as run-multiturn-test.sh but with 5 turns.

- [ ] **Step 6: Rename and update run-claude-describes-sdd.sh**

Rename the file to `run-qwen-describes-sdd.sh`. Update:
- `claude -p --model haiku` → `qwen -m <model>`
- The test verifies Qwen can describe SDD then invoke it (same as the original)

- [ ] **Step 7: Commit**

```bash
git add tests/explicit-skill-requests/ && git commit -m "test: update explicit-skill-requests tests for Qwen

Replace claude CLI with qwen in all explicit skill request tests.
Rename run-claude-describes-sdd.sh to run-qwen-describes-sdd.sh."
```

### Task 6: Update skill-triggering tests

**Files:**
- Modify: `tests/skill-triggering/run-test.sh`
- Modify: `tests/skill-triggering/run-all.sh`

**Commit Scope:** tests

- [ ] **Step 1: Update run-test.sh**

Replace:
- `claude -p "$prompt" -o stream-json` → `qwen "$prompt" -o stream-json -y`
- Session file parsing: `~/.qwen/tmp` instead of `~/.claude/projects/`
- Update the Skill tool detection in stream-json output to match Qwen's format

- [ ] **Step 2: Update run-all.sh**

Update any `claude` references to `qwen`.

- [ ] **Step 3: Commit**

```bash
git add tests/skill-triggering/ && git commit -m "test: update skill-triggering tests for Qwen

Replace claude CLI with qwen in skill-triggering tests.
Update session log paths and stream-json parsing."
```

### Task 7: Update subagent-driven-dev tests

**Files:**
- Modify: `tests/subagent-driven-dev/run-test.sh`
- Modify: `tests/subagent-driven-dev/svelte-todo/scaffold.sh`
- Modify: `tests/subagent-driven-dev/go-fractals/scaffold.sh`

**Commit Scope:** tests

- [ ] **Step 1: Update run-test.sh**

Replace:
- `claude -p -o stream-json --dangerously-skip-permissions` → `qwen "prompt" -o stream-json -y`
- Session file parsing: `~/.qwen/tmp`
- Update the token extraction logic to use the updated analyze-token-usage.py

- [ ] **Step 2: Update scaffold scripts**

If scaffold scripts reference `.claude/settings.local.json` for permission allowlists, update them. Otherwise, no changes needed — they just create the project structure.

- [ ] **Step 3: Commit**

```bash
git add tests/subagent-driven-dev/ && git commit -m "test: update subagent-driven-dev tests for Qwen

Replace claude CLI with qwen in e2e subagent tests.
Update session log paths and token analysis."
```

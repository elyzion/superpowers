# Test Migration to Qwen Code — Design Spec

## Overview

Migrate the entire `tests/` suite from Claude Code and OpenCode to Qwen Code as the primary testing platform. Delete OpenCode-specific tests. Replace all Claude CLI invocations with Qwen CLI equivalents. Update session log parsing, token analysis, and all test infrastructure.

## Requirements

### R1: Remove OpenCode Tests
All `tests/opencode/` files deleted. No replacement needed — Qwen Code is the target platform.

### R2: Migrate Test Infrastructure (`test-helpers.sh`)
- `run_claude()` → `run_qwen()` — uses `qwen "prompt" -o stream-json -y`
- Add `extract_text_from_stream_json()` — parses Qwen's stream-json output (assistant message content array) to return clean text for assertions
- All assertion helpers remain platform-agnostic but use case-insensitive matching (`grep -qi`)
- `assert_order` handles same-line pattern matches via byte offset comparison
- Add 3s rate-limit delay before each Qwen API call

### R3: Migrate Token Analyzer (`analyze-token-usage.py`)
- Parse Qwen session JSONL format from `~/.qwen/projects/<path>/chats/<id>.jsonl`
- Usage metadata at top level of each data entry: `promptTokenCount`, `candidatesTokenCount`, `cachedContentTokenCount`, `thoughtsTokenCount`
- Subagent detection via `functionCall.name == 'task'`

### R4: Migrate All Test Scripts
- Replace `claude -p` → `qwen "prompt"` (positional)
- Replace `--continue` → `-c`
- Replace `--output-format stream-json` → `-o stream-json`
- Replace `--dangerously-skip-permissions` → `-y`
- Replace `--model haiku` → `-m <model>`
- Replace `~/.claude/projects/` → `~/.qwen/projects/`
- Replace `.claude/` → `.qwen/` in scaffold scripts
- Replace `CLAUDE.md` → `QWEN.md` in test setups
- Replace `claude-output.json` → `qwen-output.json`
- Update install URLs to `https://qwenlm.github.io/qwen-code-docs/`

### R5: Remove All Claude References from `tests/`
Zero remaining references to "claude" (case-insensitive) in `tests/` test code, comments, variable names, file names, or directory names.

### R6: Timeout Adjustments
- Orchestrator timeout: 300s → 600s
- Per-call timeout: 30s → 90s
- Integration test timeout: 1800s → use `run_qwen` with 600s

### R7: Test Pass Rate
All skill knowledge tests (9 assertions in `test-subagent-driven-development.sh`) must pass. Integration tests are slow (10-30 min) and run only with `--integration` flag.

## Architecture

```
tests/
├── brainstorm-server/          # UNCHANGED — platform-agnostic Node.js tests
├── claude-code/                # RENAMED in spirit — now runs Qwen Code
│   ├── run-skill-tests.sh      # Orchestrator (timeout 600s)
│   ├── test-helpers.sh         # run_qwen(), extract_text_from_stream_json(), assertions
│   ├── test-subagent-driven-development.sh   # 9 skill knowledge tests
│   ├── test-subagent-driven-development-integration.sh  # e2e (needs --integration)
│   ├── test-document-review-system.sh  # Integration test
│   ├── analyze-token-usage.py  # Qwen session format parser
│   └── README.md               # Updated documentation
├── explicit-skill-requests/    # All scripts migrated
│   ├── run-test.sh
│   ├── run-all.sh
│   ├── run-multiturn-test.sh
│   ├── run-extended-multiturn-test.sh
│   ├── run-qwen-describes-sdd.sh  # renamed from run-claude-describes-sdd.sh
│   ├── run-small-model-test.sh    # renamed from run-haiku-test.sh
│   └── prompts/                 # UNCHANGED — input data files
├── skill-triggering/           # Both scripts migrated
│   ├── run-test.sh
│   ├── run-all.sh
│   └── prompts/                 # UNCHANGED — input data files
├── subagent-driven-dev/        # e2e tests migrated
│   ├── run-test.sh
│   ├── go-fractals/             # scaffold.sh updated (.qwen/ dir)
│   └── svelte-todo/             # scaffold.sh updated (.qwen/ dir)
└── opencode/                   # DELETED
```

## File Changes

### Deleted (5 files)
- `tests/opencode/setup.sh`
- `tests/opencode/run-tests.sh`
- `tests/opencode/test-plugin-loading.sh`
- `tests/opencode/test-tools.sh`
- `tests/opencode/test-priority.sh`

### Renamed (2 files)
- `tests/explicit-skill-requests/run-claude-describes-sdd.sh` → `run-qwen-describes-sdd.sh`
- `tests/explicit-skill-requests/run-haiku-test.sh` → `run-small-model-test.sh`

### Modified (17 files)
| File | Changes |
|------|---------|
| `tests/claude-code/test-helpers.sh` | Core: `run_qwen()`, `extract_text_from_stream_json()`, `assert_order` fix, case-insensitive grep, rate-limit delay |
| `tests/claude-code/analyze-token-usage.py` | Qwen session format parser |
| `tests/claude-code/run-skill-tests.sh` | Orchestrator: timeout, version display, install URL |
| `tests/claude-code/test-document-review-system.sh` | `run_qwen` call, `-e` flag removed |
| `tests/claude-code/test-subagent-driven-development.sh` | All `run_qwen` calls, timeouts, assertion fixes, `-e` removed |
| `tests/claude-code/test-subagent-driven-development-integration.sh` | Full migration, `-e` removed |
| `tests/claude-code/README.md` | Documentation update |
| `tests/explicit-skill-requests/run-test.sh` | CLI migration, file names, comments |
| `tests/explicit-skill-requests/run-all.sh` | CLI migration |
| `tests/explicit-skill-requests/run-multiturn-test.sh` | CLI migration, comments |
| `tests/explicit-skill-requests/run-extended-multiturn-test.sh` | CLI migration |
| `tests/explicit-skill-requests/run-qwen-describes-sdd.sh` | Full rename + migration |
| `tests/explicit-skill-requests/run-small-model-test.sh` | Full rename + migration |
| `tests/skill-triggering/run-test.sh` | CLI migration, file names |
| `tests/skill-triggering/run-all.sh` | CLI migration |
| `tests/subagent-driven-dev/run-test.sh` | CLI migration, file names |
| `tests/subagent-driven-dev/go-fractals/scaffold.sh` | `.qwen/` directory |
| `tests/subagent-driven-dev/svelte-todo/scaffold.sh` | `.qwen/` directory + settings |

## Qwen Session Format

Qwen stores sessions at `~/.qwen/projects/<path>/chats/<id>.jsonl`:

```jsonl
{"type":"system","subtype":"init",...}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"response..."},{"type":"tool_use",...}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result",...}]}}
```

- `usageMetadata` at top level of assistant/data entries
- Tool calls: `content[].functionCall.name` (e.g., `"task"`, `"read_file"`)
- Text responses: `content[].text`

## Risks

| Risk | Mitigation |
|------|-----------|
| Qwen OAuth token expires | User must re-authenticate: `qwen auth login --auth-type qwen-oauth` |
| Upstream rate limiting | 3s delay between API calls |
| Non-deterministic model responses | Semantic content checks instead of positional assertions |
| Long test execution (3-4 min per skill test) | 600s orchestrator timeout, 90s per-call timeout |

## Success Criteria

1. `bash tests/claude-code/run-skill-tests.sh` — all tests PASS
2. Zero "claude" references in `tests/` (excluding `CHANGELOG`, `RELEASE-NOTES`, `package-lock`)
3. `tests/opencode/` directory does not exist
4. `qwen-extension.json` properly configured with `skills`, `agents`, `contextFileName`

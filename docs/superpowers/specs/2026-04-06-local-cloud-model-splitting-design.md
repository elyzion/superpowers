# Local/Cloud Model Splitting — Design Spec

## Overview

Extend the superpowers agent system to support explicit local and cloud model variants. Agents are split into `*-local` and `*-cloud` files, where local agents run on a local inference backend (e.g., Ollama) and cloud agents inherit the session's default cloud model. Plans use `-local` / `-cloud` suffixes on `Domain Specialist` and `Task Specialist` annotations to route tasks to the appropriate model tier.

**Rationale:** Local models offer low-latency, private, and cost-free execution but have constrained context windows and lower reasoning ceiling. Cloud models provide stronger reasoning for architecture, review, and complex debugging. Splitting agents lets the writing-plans skill route each task to the model tier best suited for it.

## Requirements

### R1: Rename Existing Agents to Consistent Naming

All agent names use the `<domain>-engineer` convention (not mixed `-developer` / `-engineer` / `-tester`).

- `rust-developer` → `rust-engineer`
- `ml-engineer` → `ml-engineer` (no change, already consistent)
- `qa-tester` → `qa-tester` (no change — "tester" is the natural term for this role)
- `code-reviewer` → `code-reviewer` (no change — "reviewer" is the natural term)

### R2: Create Local/Cloud Agent Variants

Each agent that benefits from model-tier splitting exists as two files:

| Agent | Local Variant | Cloud Variant | Notes |
|-------|---------------|---------------|-------|
| `general-engineer` | `general-engineer-local.md` | `general-engineer-cloud.md` | Replaces implicit "general-purpose" dispatch |
| `rust-engineer` | `rust-engineer-local.md` | `rust-engineer-cloud.md` | Split from `rust-developer.md` |
| `ml-engineer` | `ml-engineer-local.md` | `ml-engineer-cloud.md` | New variants |
| `qa-tester` | N/A | `qa-tester.md` | No local variant — test design benefits from cloud reasoning |
| `code-reviewer` | N/A | `code-reviewer.md` | No local variant — code review benefits from cloud reasoning |

**Local agents** specify `modelConfig` pointing to the local model.
**Cloud agents** omit `modelConfig`, inheriting the session's default model (typically a cloud model like qwen-plus via Qwen OAuth).

### R3: Local Agent Uses Qwen Native `modelConfig`

The superpowers `model: inherit` convention is replaced with Qwen Code's native `modelConfig` frontmatter field.

Local agents include:
```yaml
modelConfig:
  model: <local-model-id>
```

Cloud agents omit `modelConfig` entirely, inheriting the session default.

The local model ID is `qwen3.5:9b`, registered as an OpenAI-compatible provider via Ollama at `http://localhost:11434/v1`.

### R4: Domain Specialist Annotations Support `-local` / `-cloud` Suffixes

The `writing-plans` skill is extended to recognize suffixes on `Domain Specialist` and `Task Specialist` annotations:

```markdown
**Domain Specialist:** rust-engineer-local
**Task Specialist:** ml-engineer-cloud
```

The valid specialist values are:
- `general-engineer-local` / `general-engineer-cloud`
- `rust-engineer-local` / `rust-engineer-cloud`
- `ml-engineer-local` / `ml-engineer-cloud`
- `qa-tester` (cloud only)
- `code-reviewer` (cloud only)

### R5: Subagent-Driven-Development Routing Updated

The `subagent-driven-development` skill's specialist agent selection logic is updated to:
1. Check for `Task Specialist` override (as before)
2. Fall back to plan `Domain Specialist` (as before)
3. Inference from task content (as before) — but now also infers `-local` vs `-cloud` from context signals

New inference signals for model tier:
- **`-local`**: "simple refactoring", "boilerplate", "mechanical change", single-file edits with clear spec
- **`-cloud`**: "design", "architecture review", "debug complex", multi-file integration, error analysis

### R6: Ollama Provider Configuration Documented

The spec documents how to configure Ollama as a model provider in `~/.qwen/settings.json` so that local agents can reference the model. This is user-facing setup, not a code change in this repo.

### R7: Backward Compatibility Not Required

This fork targets Qwen Code only. No backward compatibility with Claude Code, Cursor, or OpenCode is maintained. The `model: inherit` convention is fully replaced.

## Architecture

### Agent File Structure

```
agents/
├── general-engineer-local.md     # Local: qwen3.5:9b via Ollama
├── general-engineer-cloud.md     # Cloud: inherits session model
├── rust-engineer-local.md        # Local: qwen3.5:9b via Ollama
├── rust-engineer-cloud.md        # Cloud: inherits session model
├── ml-engineer-local.md          # Local: qwen3.5:9b via Ollama
├── ml-engineer-cloud.md          # Cloud: inherits session model
├── qa-tester.md                  # Cloud only
└── code-reviewer.md              # Cloud only
```

### How Qwen Code Resolves Agent Models

1. Session starts with a default model (configured in `~/.qwen/settings.json` via `model` field or CLI `--model` flag)
2. When a subagent is dispatched, Qwen reads the agent's `.md` frontmatter
3. If `modelConfig.model` is present, the subagent runs on that model
4. If `modelConfig` is absent, the subagent inherits the session's model
5. The model must be registered in `modelProviders` in settings

### How Ollama is Registered

The user adds Ollama as an OpenAI-compatible provider:

```json
{
  "modelProviders": {
    "openai": [
      {
        "id": "qwen3.5:9b",
        "name": "Qwen3.5 9B (Ollama)",
        "envKey": "OLLAMA_API_KEY",
        "baseUrl": "http://localhost:11434/v1",
        "generationConfig": {
          "timeout": 300000,
          "contextWindowSize": 16384,
          "samplingParams": {
            "temperature": 0.7,
            "top_p": 0.9,
            "max_tokens": 4096
          }
        }
      }
    ]
  }
}
```

The `id` field must match the exact Ollama model tag. The user must export `OLLAMA_API_KEY` with any placeholder value (e.g., `export OLLAMA_API_KEY="ollama"`).

### Plan Annotation Examples

```markdown
# ECS Component Storage Implementation Plan

**Domain Specialist:** rust-engineer-cloud

### Task 1: Define component trait interfaces

**Files:**
- Create: `src/ecs/traits.rs`

**Commit Scope:** ecs

- [ ] **Step 1:** Write failing test
...
```

```markdown
# UI Component Styling Update

**Domain Specialist:** general-engineer-local

### Task 3: Add dark mode CSS variables

**Files:**
- Modify: `src/ui/styles/variables.css`
...
```

### Writing-Plans Skill Changes

The writing-plans skill header format is extended to include model-tier awareness in the Domain Specialist guidance:

```markdown
**Domain Specialist:** [rust-engineer-local | rust-engineer-cloud |
  ml-engineer-local | ml-engineer-cloud |
  general-engineer-local | general-engineer-cloud |
  qa-tester | code-reviewer]

**When to specify a domain specialist:**
- **rust-engineer-local** — Mechanical Rust changes: derive macros, boilerplate, simple trait impls, clippy fixes
- **rust-engineer-cloud** — Complex Rust: lifetime reasoning, async architecture, FFI design, performance-critical patterns
- **ml-engineer-local** — Simple ML: data loading scripts, preprocessing pipelines, basic evaluation
- **ml-engineer-cloud** — ML architecture: model selection, evaluation methodology, prompt engineering, data validation design
- **general-engineer-local** — Mechanical changes: single-file edits, boilerplate, refactoring with clear spec, CSS/HTML updates
- **general-engineer-cloud** — Multi-file integration, architecture decisions, debugging, complex error analysis
- **qa-tester** — Test strategy, coverage analysis, edge case design (cloud only)
- **code-reviewer** — Code review against plans (cloud only)
```

### Subagent-Driven-Development Skill Changes

The specialist selection flowchart is updated:

```
Read task
  │
  ├─ Task has Task Specialist override?
  │   ├─ rust-engineer-local   → dispatch rust-engineer-local
  │   ├─ rust-engineer-cloud   → dispatch rust-engineer-cloud
  │   ├─ ml-engineer-local     → dispatch ml-engineer-local
  │   ├─ ml-engineer-cloud     → dispatch ml-engineer-cloud
  │   ├─ general-engineer-local → dispatch general-engineer-local
  │   ├─ general-engineer-cloud → dispatch general-engineer-cloud
  │   ├─ qa-tester             → dispatch qa-tester
  │   └─ code-reviewer         → dispatch code-reviewer
  │
  ├─ Plan Domain Specialist set? → use it
  │
  └─ Infer from task content:
      ├─ Rust code, local signals → rust-engineer-local
      ├─ Rust code, cloud signals → rust-engineer-cloud
      ├─ ML/AI, local signals     → ml-engineer-local
      ├─ ML/AI, cloud signals     → ml-engineer-cloud
      ├─ Test infrastructure      → qa-tester
      ├─ Mechanical refactoring   → general-engineer-local
      └─ Complex integration      → general-engineer-cloud
```

Local inference signals: "simple refactoring", "boilerplate", "mechanical change", single-file edits with complete spec, CSS/HTML updates, straightforward derive/trait additions.

Cloud inference signals: "design", "architecture", "debug", "complex", multi-file coordination, error chain analysis, lifetime reasoning, async patterns.

### Model Selection Guidance in Subagent-Driven-Development

The existing "Model Selection" section is updated to reference the local/cloud split:

- **Local agents** (qwen3.5:9b via Ollama): Used for mechanical, well-specified tasks. The agent system prompt should note the 16k context window limit and encourage concise, focused output.
- **Cloud agents** (qwen-plus via Qwen OAuth): Used for tasks requiring judgment, reasoning breadth, or design decisions.
- **Review agents** (qa-tester, code-reviewer): Always cloud — review quality benefits most from strong reasoning.

## File Changes

### New Files (6)
| File | Purpose |
|------|---------|
| `agents/general-engineer-local.md` | Local general-purpose implementer (qwen3.5:9b) |
| `agents/general-engineer-cloud.md` | Cloud general-purpose implementer (inherits session model) |
| `agents/rust-engineer-local.md` | Local Rust specialist (qwen3.5:9b) |
| `agents/rust-engineer-cloud.md` | Cloud Rust specialist (inherits session model) |
| `agents/ml-engineer-local.md` | Local ML specialist (qwen3.5:9b) |
| `agents/ml-engineer-cloud.md` | Cloud ML specialist (inherits session model) |

### Renamed Files (1)
| From | To |
|------|-----|
| `agents/rust-developer.md` | `agents/rust-engineer.md` *(intermediate — will be split into local/cloud)* |

### Modified Files (2)
| File | Changes |
|------|---------|
| `skills/writing-plans/SKILL.md` | Domain Specialist field extended with `-local` / `-cloud` variants; updated routing guidance |
| `skills/subagent-driven-development/SKILL.md` | Specialist selection flowchart updated; model selection section updated; routing diagram updated |

### Deleted Files (1)
| File | Reason |
|------|--------|
| `agents/rust-developer.md` | Replaced by `rust-engineer-local.md` + `rust-engineer-cloud.md` |

### Referenced Files (unchanged)
| File | Role |
|------|------|
| `agents/qa-tester.md` | Cloud-only agent, no changes needed |
| `agents/code-reviewer.md` | Cloud-only agent, no changes needed |

### Documentation Changes

The README or a new setup guide should document:
1. How to configure Ollama as a model provider in `~/.qwen/settings.json`
2. Required environment variable (`OLLAMA_API_KEY`)
3. How to pull and run the local model
4. How to set the session's default model to qwen-plus via Qwen OAuth

This is user-facing documentation, not a code change in the skill/agent files themselves.

## Risks

| Risk | Mitigation |
|------|-----------|
| Ollama not running or model not loaded | Local agent dispatch fails; user must ensure Ollama is running before dispatching local tasks |
| 16k context window exceeded on local model | Writing-plans skill must scope tasks to fit in 16k context (input + output). Cloud agents have no such constraint |
| Qwen OAuth quota exhausted | User monitors usage and falls back to local-only by setting session default to local model. No automatic fallback in this spec |
| Agent file proliferation | Only agents that meaningfully differ between local/cloud are split. qa-tester and code-reviewer remain single files |
| Naming confusion with `-local`/`-cloud` | Domain Specialist values are enumerated in writing-plans SKILL.md — no guessing |

## Out of Scope

- **Automatic model fallback** — If cloud quota is exhausted, the system does not automatically reroute to local agents
- **Quota awareness** — Agents do not receive or report remaining request counts
- **Other platforms** — No backward compatibility with Claude Code, Cursor, OpenCode, or Gemini CLI
- **Dynamic agent spawning** — Agents invoking other agents via the `task` tool works but is not changed by this spec; the model resolution is handled by Qwen Code's native subagent system
- **Chat compression / context compaction** — Not addressed; task scoping must handle context limits

## Success Criteria

1. All 8 agent files exist and have valid Qwen Code frontmatter (`name`, `description`, `tools`, and `modelConfig` where applicable)
2. `qwen-extension.json` properly references the `agents/` directory (already configured, no change needed)
3. Writing-plans skill documents all valid Domain Specialist values including `-local`/`-cloud` variants
4. Subagent-driven-development skill routing diagram and text updated to match new naming
5. A user with Ollama running qwen3.5:9b can dispatch a local agent and a cloud agent from the same plan

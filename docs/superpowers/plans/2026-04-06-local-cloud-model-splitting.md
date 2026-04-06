# Local/Cloud Model Splitting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split all agents into local/cloud variants with qwen3.5:9b on Ollama for local tasks and session-default cloud model for reasoning-heavy tasks.

**Architecture:** Create 6 new agent files (3 domains × 2 tiers), rename rust-developer to rust-engineer, and update writing-plans and subagent-driven-development skills to route tasks to the correct agent variant via `-local`/`-cloud` suffixes on Domain Specialist and Task Specialist annotations.

**Tech Stack:** Markdown (agent files), Qwen Code subagent system, Ollama (local inference backend)

**Domain Specialist:** general-engineer-local

---

### Task 1: Create general-engineer-local.md

**Files:**
- Create: `agents/general-engineer-local.md`

**Task Specialist:** general-engineer-local

**Commit Scope:** agents

- [ ] **Step 1: Write the agent file**

Create a general-purpose implementer agent for the local model tier. It should:
- Have `name: general-engineer-local`
- Set `modelConfig.model` to `qwen3.5:9b`
- Have a clear description of when to use it
- Include `tools: ["*"]` (all tools)
- Have a system prompt that:
  - Encourages focused, concise output (16k context limit awareness)
  - Instructs to avoid chain-of-thought verbosity
  - Covers general software development practices (TDD, clean code, DRY, YAGNI)
  - Notes to keep implementations minimal and scoped to the task at hand

Content:

```markdown
---
name: general-engineer-local
description: |
  Use this agent for mechanical, well-scoped implementation tasks that don't require deep reasoning or broad codebase understanding. Examples: single-file edits, boilerplate generation, straightforward refactoring, CSS/HTML updates. Runs on a local model with a 16k context window — be concise and focused.
modelConfig:
  model: qwen3.5:9b
tools:
  - *
---

You are a focused, efficient software engineer running on a local model with a 16k context window. Your job is to implement well-scoped tasks precisely and concisely.

## Operating Principles

1. **Be Concise**: Your context window is limited. Avoid chain-of-thought verbosity, elaborate explanations, and unnecessary preamble. State what you're doing, do it, and move on.

2. **Minimal Implementation**: Write only the code needed to satisfy the task. Do not add features, abstractions, or optimizations that aren't explicitly required. YAGNI.

3. **TDD When Applicable**: If the task involves behavior changes, write tests first. If it's a mechanical change with no behavioral impact, tests may not be needed.

4. **Follow the Spec**: If you've been given a spec or plan, implement it exactly. Do not add functionality that isn't specified. Do not skip requirements.

5. **Single-File Focus**: You work best when the task is contained to one or two files. If you discover the task requires changes across many files or complex coordination, report this to the coordinator rather than attempting it blindly.

6. **Preserve Existing Patterns**: When modifying existing code, match the established conventions for naming, structure, error handling, and style. Don't introduce new patterns without justification.

7. **Commit Frequently**: Each logical unit of work should be committed. Use Conventional Commits format: `type(scope): description`.

When you encounter ambiguity, ask the coordinator for clarification before proceeding. When you encounter a scope creep (the task is larger than described), report it rather than guessing.
```

- [ ] **Step 2: Commit**

```bash
git add agents/general-engineer-local.md
git commit -m "feat(agents): add general-engineer-local agent

Local model implementer for mechanical, well-scoped tasks.
Runs on qwen3.5:9b via Ollama with 16k context awareness."
```

### Task 2: Create general-engineer-cloud.md

**Files:**
- Create: `agents/general-engineer-cloud.md`

**Task Specialist:** general-engineer-local

**Commit Scope:** agents

- [ ] **Step 1: Write the agent file**

Create a cloud variant that inherits the session's default model. Key differences from local:
- No `modelConfig` field (inherits session model — typically qwen-plus)
- Can be more thorough in reasoning and explanation
- No context window constraint warnings
- Same general software development principles

Content:

```markdown
---
name: general-engineer-cloud
description: |
  Use this agent for implementation tasks requiring multi-file coordination, architectural judgment, or complex error analysis. Runs on the session's default cloud model with full context window and stronger reasoning capabilities.
tools:
  - *
---

You are a software engineer running on a cloud model with strong reasoning capabilities. Your job is to implement tasks with good judgment, proper architecture awareness, and thorough analysis.

## Operating Principles

1. **Reason Deeply**: You have access to strong reasoning capabilities. Use them to understand complex error chains, multi-file coordination, and architectural trade-offs.

2. **TDD When Applicable**: If the task involves behavior changes, write tests first. If it's a mechanical change with no behavioral impact, tests may not be needed.

3. **Multi-File Awareness**: You can handle tasks that span multiple files and modules. Track dependencies, ensure consistency, and verify that changes integrate well across the codebase.

4. **Follow the Spec**: If you've been given a spec or plan, implement it exactly. Do not add functionality that isn't specified. Do not skip requirements.

5. **Preserve Existing Patterns**: When modifying existing code, match the established conventions for naming, structure, error handling, and style.

6. **Debug Systematically**: When you encounter errors, trace the root cause before proposing fixes. Don't apply shotgun debugging — understand the problem first.

7. **Commit Frequently**: Each logical unit of work should be committed. Use Conventional Commits format: `type(scope): description`.

When you encounter ambiguity, ask the coordinator for clarification before proceeding. When you encounter a scope creep (the task is larger than described), report it rather than guessing.
```

- [ ] **Step 2: Commit**

```bash
git add agents/general-engineer-cloud.md
git commit -m "feat(agents): add general-engineer-cloud agent

Cloud model implementer for tasks requiring reasoning breadth
and multi-file coordination. Inherits session default model."
```

### Task 3: Create rust-engineer-local.md

**Files:**
- Create: `agents/rust-engineer-local.md`

**Task Specialist:** general-engineer-local

**Commit Scope:** agents

- [ ] **Step 1: Write the agent file**

Create a Rust-specific agent for the local model. Adapt the existing rust-developer.md system prompt with local model awareness:

```markdown
---
name: rust-engineer-local
description: |
  Use this agent for mechanical Rust implementation tasks: derive macros, boilerplate, simple trait impls, clippy fixes. Runs on a local model with 16k context window — be concise and focused.
modelConfig:
  model: qwen3.5:9b
tools:
  - *
---

You are a Rust engineer running on a local model with a 16k context window. Your job is to implement well-scoped Rust tasks precisely and concisely.

## Operating Principles

1. **Be Concise**: Your context window is limited. Avoid chain-of-thought verbosity and unnecessary explanations. State what you're doing, do it, and move on.

2. **Correctness First**:
   - Enforce ownership and borrowing rules strictly — no `clone()` without justification
   - Lifetime annotations must be correct and minimal
   - Handle all `Result` and `Option` cases explicitly — no `.unwrap()` or `.expect()` in production code
   - Follow `cargo fmt` and pass `clippy` with zero warnings

3. **Idiomatic Patterns**:
   - Prefer composition over inheritance (traits, not base structs)
   - Use the type system to make invalid states unrepresentable
   - Follow Rust API Guidelines: `Copy` vs `Clone` decisions, `From`/`Into` over custom conversions
   - Prefer `thiserror` for library error types, `anyhow` for application-level handling

4. **Minimal Implementation**: Write only the code needed to satisfy the task. Do not add abstractions or optimizations that aren't explicitly required.

5. **Single-File Focus**: You work best when the task is contained to one or two files. If you discover the task requires changes across many files or complex coordination, report this to the coordinator.

6. **Testing**: Unit tests in `#[cfg(test)] mod tests`. Test public API, not implementation details. `cargo test` must pass.

7. **Ecosystem Conventions**:
   - **tokio**: Proper async/await patterns, `Send` bounds
   - **serde**: Derive over manual implementations, proper attribute usage
   - Follow existing project structure; don't restructure without plan guidance

8. **Commit Frequently**: Use Conventional Commits: `type(scope): description`.

When you encounter ambiguity or scope creep, report it to the coordinator rather than guessing.
```

- [ ] **Step 2: Commit**

```bash
git add agents/rust-engineer-local.md
git commit -m "feat(agents): add rust-engineer-local agent

Local Rust specialist for mechanical implementation tasks.
Runs on qwen3.5:9b via Ollama with 16k context awareness."
```

### Task 4: Create rust-engineer-cloud.md

**Files:**
- Create: `agents/rust-engineer-cloud.md`

**Task Specialist:** general-engineer-local

**Commit Scope:** agents

- [ ] **Step 1: Write the agent file**

Create a cloud Rust specialist with full reasoning capabilities:

```markdown
---
name: rust-engineer-cloud
description: |
  Use this agent for complex Rust implementation requiring lifetime reasoning, async architecture, FFI design, or performance-critical patterns. Runs on the session's default cloud model.
tools:
  - *
---

You are a Senior Rust Engineer running on a cloud model with strong reasoning capabilities. Your job is to implement and review Rust code with deep ownership, borrowing, and zero-cost abstraction expertise.

## Operating Principles

1. **Correctness First**:
   - Enforce ownership and borrowing rules strictly — no `clone()` without justification, no `RefCell`/`Rc` without explaining why interior mutability is needed
   - Lifetime annotations must be correct and minimal — no `'static` workarounds unless truly appropriate
   - `unsafe` code requires explicit documentation of invariants, safety comments, and justification for why safe Rust cannot express the same logic
   - Handle all `Result` and `Option` cases explicitly — no `.unwrap()` or `.expect()` in production code (acceptable in tests with clear reasoning)

2. **Idiomatic Patterns**:
   - Prefer composition over inheritance (traits, not base structs)
   - Use the type system to make invalid states unrepresentable
   - Follow the Rust API Guidelines: `Copy` vs `Clone` decisions, `Deref` only for smart pointers, `From`/`Into` over custom conversion methods
   - Error types should be descriptive and implement `std::error::Error` with source chains
   - Prefer `thiserror` for library error types, `anyhow` for application-level error handling

3. **Ecosystem Conventions**:
   - **tokio**: Proper async/await patterns, `Send` bounds, task spawning discipline, cancellation handling
   - **serde**: Derive over manual implementations when possible, proper `[serde(rename)]` / `[serde(default)]` usage, zero-copy deserialization with `&str`/`Cow` where appropriate
   - **axum/actix**: Proper layer composition, extractor patterns, middleware ordering, graceful shutdown
   - Follow `cargo fmt` formatting, pass `clippy` with zero warnings (allow only with `#[allow(clippy::...)]` and comment explaining why)

4. **Performance Awareness**:
   - Identify and eliminate unnecessary allocations in hot paths
   - Use `&str` over `String` for read-only parameters, `impl Trait` in argument position, `impl Iterator` in return position
   - Profile before optimizing — don't sacrifice clarity for hypothetical performance gains
   - Document any performance characteristics that callers should know

5. **Testing Discipline**:
   - Unit tests in the same module (`#[cfg(test)] mod tests`), integration tests in `tests/`
   - Test the public API, not implementation details
   - Test error paths, not just happy paths
   - `cargo test --all-features` must pass before reporting done

6. **Code Organization**:
   - Each file should have one clear responsibility
   - Re-export public API through `mod.rs` or `lib.rs` for clean `use` paths
   - Keep modules small enough to hold in context
   - Follow existing project structure; don't restructure without plan guidance

When implementing, follow TDD: write failing tests first, implement minimal code to pass, refactor. When reviewing, be thorough about safety, ownership, and error handling. Always explain your reasoning for non-obvious decisions.
```

- [ ] **Step 2: Commit**

```bash
git add agents/rust-engineer-cloud.md
git commit -m "feat(agents): add rust-engineer-cloud agent

Cloud Rust specialist for complex reasoning: lifetimes, async,
FFI, and performance-critical patterns. Inherits session model."
```

### Task 5: Delete rust-developer.md

**Files:**
- Delete: `agents/rust-developer.md`

**Task Specialist:** general-engineer-local

**Commit Scope:** agents

- [ ] **Step 1: Delete the old agent**

```bash
git rm agents/rust-developer.md
```

- [ ] **Step 2: Commit**

```bash
git commit -m "refactor(agents): remove rust-developer (replaced by rust-engineer-*)

Replaced by rust-engineer-local.md and rust-engineer-cloud.md
with explicit model tier routing."
```

### Task 6: Create ml-engineer-local.md

**Files:**
- Create: `agents/ml-engineer-local.md`

**Task Specialist:** general-engineer-local

**Commit Scope:** agents

- [ ] **Step 1: Write the agent file**

Adapt the existing ml-engineer.md for local model with concise output:

```markdown
---
name: ml-engineer-local
description: |
  Use this agent for simple ML implementation tasks: data loading scripts, preprocessing pipelines, basic evaluation. Runs on a local model with 16k context window — be concise and focused.
modelConfig:
  model: qwen3.5:9b
tools:
  - *
---

You are an ML/AI engineer running on a local model with a 16k context window. Your job is to implement well-scoped ML tasks precisely and concisely.

## Operating Principles

1. **Be Concise**: Your context window is limited. Avoid chain-of-thought verbosity. State what you're doing, do it, and move on.

2. **Data Quality and Validation**:
   - Every data input must be validated: schema, type, range, missing values
   - Implement data validation gates at pipeline boundaries
   - Prevent data leakage: train/test splits must be done before any feature engineering

3. **Model Lifecycle Awareness**:
   - Separate model training, evaluation, and serving into distinct components
   - Implement model loading with validation: check expected input/output shapes
   - Handle model loading failures gracefully

4. **Resource Management**:
   - GPU memory: batch sizes must be configurable, OOM handling must exist
   - Never block the main thread for model inference
   - Document hardware requirements

5. **Reproducibility**:
   - Seed everything: random seeds for training, evaluation, and test data sampling
   - Pin all dependencies: exact versions of ML libraries
   - Implement experiment tracking: each run must be identifiable

6. **Code Organization**:
   - Separate data loading, preprocessing, model definition, training, evaluation, and serving into distinct modules
   - Configuration should be externalized — no hardcoded hyperparameters
   - Each file should have one clear responsibility

7. **Testing**: Test data validation, test model input/output shapes, test evaluation metrics.

8. **Commit Frequently**: Use Conventional Commits: `type(scope): description`.

When you encounter ambiguity or scope creep, report it to the coordinator rather than guessing.
```

- [ ] **Step 2: Commit**

```bash
git add agents/ml-engineer-local.md
git commit -m "feat(agents): add ml-engineer-local agent

Local ML specialist for simple implementation tasks.
Runs on qwen3.5:9b via Ollama with 16k context awareness."
```

### Task 7: Create ml-engineer-cloud.md

**Files:**
- Create: `agents/ml-engineer-cloud.md`

**Task Specialist:** general-engineer-local

**Commit Scope:** agents

- [ ] **Step 1: Write the agent file**

Adapt the existing ml-engineer.md for cloud model (keep the existing content mostly intact, as it's already cloud-worthy):

```markdown
---
name: ml-engineer-cloud
description: |
  Use this agent for ML architecture decisions, model selection, evaluation methodology, prompt engineering, and data validation design. Runs on the session's default cloud model.
tools:
  - *
---

You are a Senior ML/AI Engineer running on a cloud model with strong reasoning capabilities. Your role is to ensure ML/AI code is correct, reproducible, evaluable, and production-ready.

## Operating Principles

1. **Data Quality and Validation**:
   - Every data input must be validated: schema, type, range, distribution, missing values
   - Implement data validation gates at pipeline boundaries — never trust upstream data without verification
   - Detect and handle data drift: training-serving skew, concept drift, covariate shift
   - Prevent data leakage: train/test splits must be done before any feature engineering, cross-validation must respect temporal ordering if applicable
   - Document data provenance: where data comes from, how it was transformed, what assumptions were made

2. **Model Lifecycle Awareness**:
   - Separate model training, evaluation, and serving into distinct components with clear interfaces
   - Model artifacts must be versioned alongside code that produced them
   - Implement model loading with validation: check expected input/output shapes, dtype, preprocessing steps
   - Handle model loading failures gracefully — never silently fall back to broken state
   - Design for model hot-swapping: the serving layer should not be coupled to a specific model version

3. **Evaluation Rigor**:
   - Metrics must match the problem: accuracy for balanced classification, F1/ROC-AUC for imbalanced, BLEU/ROUGE for generation, calibration for probability estimates
   - Evaluate on multiple dimensions: not just aggregate metrics, but per-class, per-group, per-segment performance
   - Test for fairness and bias: evaluate across demographic slices, geographic regions, or other relevant stratifications
   - Include robustness tests: adversarial examples, out-of-distribution inputs, perturbed inputs
   - Evaluation must be automated and reproducible — no manual inspection as the primary quality gate

4. **Prompt Engineering and LLM Safety** (when applicable):
   - Prompt inputs must be sanitized: prevent prompt injection, tool misuse, context window overflow
   - Output must be validated: structured outputs validated against schema, free-form outputs checked for harmful content
   - Implement rate limiting and cost tracking for API-based LLM calls
   - Test prompt determinism: same input should produce consistent output (or document when non-determinism is expected)
   - Log prompts and responses for debugging and auditing (with appropriate privacy safeguards)

5. **Resource Management**:
   - GPU memory: batch sizes must be configurable, OOM handling must exist, memory profiling guidance for large models
   - Inference latency: document expected P50/P95/P99 latencies, implement timeouts, handle slow responses
   - Throughput: implement request queuing, batching, and caching where appropriate
   - Never block the main thread for model inference — use async or background processing
   - Document hardware requirements: minimum GPU memory, CPU, RAM for each model

6. **Reproducibility**:
   - Seed everything: random seeds for training, evaluation, and test data sampling
   - Pin all dependencies: exact versions of ML libraries, CUDA toolkit, driver versions
   - Log experiment parameters: hyperparameters, data split ratios, preprocessing choices, hardware used
   - Implement experiment tracking: each run must be identifiable and its configuration recoverable
   - Model training must be resumable from checkpoints — don't lose work on interruption

7. **Code Organization**:
   - Separate data loading, preprocessing, model definition, training loop, evaluation, and serving into distinct modules
   - Configuration should be externalized (config files, environment variables) — no hardcoded hyperparameters
   - Each file should have one clear responsibility: data.py for loading, model.py for architecture, train.py for training loop, eval.py for evaluation
   - Follow existing project structure; don't restructure without plan guidance

When implementing, follow TDD where applicable: test data validation, test model input/output shapes, test evaluation metrics. When reviewing, be thorough about data safety, evaluation rigor, reproducibility, and production readiness. Always explain your reasoning for non-obvious decisions.
```

- [ ] **Step 2: Commit**

```bash
git add agents/ml-engineer-cloud.md
git commit -m "feat(agents): add ml-engineer-cloud agent

Cloud ML specialist for architecture, evaluation methodology,
and production readiness. Inherits session default model."
```

### Task 8: Update writing-plans SKILL.md

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

**Task Specialist:** general-engineer-cloud

**Commit Scope:** skills

- [ ] **Step 1: Update the Domain Specialist Routing section**

Replace the current "Domain Specialist Routing" section with the following:

```markdown
## Domain Specialist Routing

If this plan involves a specialized domain, annotate it so the subagent dispatcher knows which specialist agent to use. Add the `**Domain Specialist:**` field to the plan header (see below).

**Valid Domain Specialist values:**

- **rust-engineer-local** — Mechanical Rust changes: derive macros, boilerplate, simple trait impls, clippy fixes
- **rust-engineer-cloud** — Complex Rust: lifetime reasoning, async architecture, FFI design, performance-critical patterns
- **ml-engineer-local** — Simple ML: data loading scripts, preprocessing pipelines, basic evaluation
- **ml-engineer-cloud** — ML architecture: model selection, evaluation methodology, prompt engineering, data validation design
- **general-engineer-local** — Mechanical changes: single-file edits, boilerplate, refactoring with clear spec, CSS/HTML updates
- **general-engineer-cloud** — Multi-file integration, architecture decisions, debugging, complex error analysis
- **qa-tester** — Test strategy, coverage analysis, edge case design (cloud only)
- **code-reviewer** — Code review against plans (cloud only)

**When to specify a domain specialist:**

Choose the variant that matches the reasoning needs of the task. Local variants run on constrained models (16k context) and are suited for mechanical, well-scoped work. Cloud variants run on the session's default model and handle complex reasoning, multi-file coordination, and design decisions.

**Per-task overrides:** If most tasks are general but one task needs a specialist (or vice versa), add `**Task Specialist:** <agent-name>` to that specific task's metadata. Use any of the valid values listed above.
```

Also update the plan header example to show the new values:

```markdown
**Domain Specialist:** [rust-engineer-local | rust-engineer-cloud |
  ml-engineer-local | ml-engineer-cloud |
  general-engineer-local | general-engineer-cloud |
  qa-tester | code-reviewer | (omit if not applicable)]
```

- [ ] **Step 2: Verify the change doesn't break any downstream references**

Search for "Domain Specialist" in the skills directory and verify no other file hardcodes the old values (`rust-developer`, `ml-engineer` without suffix, `general-purpose`). If any file does, note it for the subagent-driven-development update (Task 9).

- [ ] **Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat(skills): extend writing-plans Domain Specialist with local/cloud variants

Add -local and -cloud suffixes for all engineer agents.
Replace model: inherit convention with explicit tier routing.
Update Domain Specialist guidance with all valid values."
```

### Task 9: Update subagent-driven-development SKILL.md

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

**Task Specialist:** general-engineer-cloud

**Commit Scope:** skills

- [ ] **Step 1: Update the Specialist Agent Selection section**

Replace the current "Specialist Agent Selection" section and its flowchart with the following:

Replace the existing flowchart:

```dot
digraph specialist_selection {
    "Read task" [shape=box];
    "Task has Task Specialist override?" [shape=diamond];
    "Use plan Domain Specialist" [shape=diamond];
    "Task involves Rust code?" [shape=diamond];
    "Task involves ML/AI?" [shape=diamond];
    "Task is test infrastructure?" [shape=diamond];
    "Dispatch rust-engineer-local" [shape=box style=filled fillcolor=orange];
    "Dispatch ml-engineer-cloud" [shape=box style=filled fillcolor=purple];
    "Dispatch qa-tester" [shape=box style=filled fillcolor=green];
    "Dispatch general-engineer-local" [shape=box style=filled fillcolor=lightgrey];

    "Read task" -> "Task has Task Specialist override?";
    "Task has Task Specialist override?" -> "Use plan Domain Specialist" [label="no"];
    "Task has Task Specialist override?" -> "Dispatch task specialist" [label="yes, use specified agent"];
    "Use plan Domain Specialist" -> "Infer from task content" [label="not set or general"];
    "Task involves Rust code?" -> "Task involves ML/AI?" [label="no"];
    "Task involves Rust code?" -> "rust-engineer-local or rust-engineer-cloud" [label="yes"];
    "Task involves ML/AI?" -> "Task is test infrastructure?" [label="no"];
    "Task involves ML/AI?" -> "ml-engineer-local or ml-engineer-cloud" [label="yes"];
    "Task is test infrastructure?" -> "Dispatch general-engineer-local" [label="no"];
    "Task is test infrastructure?" -> "Dispatch qa-tester" [label="yes"];
    "Infer from task content" -> "Dispatch based on signals" [label="yes"];
}
```

Replace the text description with:

```markdown
**Priority order:**
1. **Task-level `Task Specialist:`** — if the task has an explicit override, use it. Valid values: `rust-engineer-local`, `rust-engineer-cloud`, `ml-engineer-local`, `ml-engineer-cloud`, `general-engineer-local`, `general-engineer-cloud`, `qa-tester`, `code-reviewer`.
2. **Plan-level `Domain Specialist:`** — if the plan header specifies one, use it as the default.
3. **Inference from task content** — if neither is set, infer from the task:
   - File extensions `.rs`, mentions of `cargo`, `clippy`, `tokio`, `serde` → `rust-engineer-local` for mechanical changes, `rust-engineer-cloud` for complex reasoning
   - Mentions of models, training, inference, prompts, embeddings, evaluation metrics → `ml-engineer-local` for simple scripts, `ml-engineer-cloud` for architecture
   - Test framework development, coverage tooling, QA systems → `qa-tester`
   - Single-file edits, boilerplate, straightforward refactoring, CSS/HTML → `general-engineer-local`
   - Multi-file integration, architecture decisions, debugging → `general-engineer-cloud`
   - Everything else → `general-engineer-local`
```

Update the "Available specialist agents" list:

```markdown
**Available specialist agents:**
- `superpowers:rust-engineer-local` — Mechanical Rust implementation (see `./rust-engineer-local.md`)
- `superpowers:rust-engineer-cloud` — Complex Rust reasoning (see `./rust-engineer-cloud.md`)
- `superpowers:ml-engineer-local` — Simple ML implementation (see `./ml-engineer-local.md`)
- `superpowers:ml-engineer-cloud` — ML architecture (see `./ml-engineer-cloud.md`)
- `superpowers:general-engineer-local` — Mechanical general changes (see `./general-engineer-local.md`)
- `superpowers:general-engineer-cloud` — Complex general implementation (see `./general-engineer-cloud.md`)
- `superpowers:qa-tester` — QA/testing review (see `./qa-tester.md`)
- `superpowers:code-reviewer` — Code review (see `./code-reviewer.md`)
```

- [ ] **Step 2: Update the Model Selection section**

Replace the current "Model Selection" section with:

```markdown
## Model Selection

Model tier is determined by the agent variant. Local agents run on qwen3.5:9b via Ollama. Cloud agents inherit the session's default model (typically a cloud model via Qwen OAuth).

**Local agents** (qwen3.5:9b via Ollama):
- 16k context window — tasks must be scoped accordingly
- Best for: mechanical, well-specified tasks with clear input/output
- Encourages concise, focused output
- No API cost, no rate limits, private

**Cloud agents** (session default, typically qwen-plus via Qwen OAuth):
- Full context window
- Best for: tasks requiring judgment, reasoning breadth, or design decisions
- 1000 requests/day free quota — monitor usage

**Review agents** (qa-tester, code-reviewer):
- Always cloud — review quality benefits most from strong reasoning
```

- [ ] **Step 3: Update the Integration section**

In the "Integration" section under "Specialist agents (dispatched when plan specifies domain):", replace:

```markdown
**Specialist agents (dispatched when plan specifies domain):**
- **superpowers:rust-developer** - Rust systems programming implementation
- **superpowers:ml-engineer** - ML/AI pipeline implementation
- **superpowers:qa-tester** - QA/testing review (mandatory third review stage)
```

With:

```markdown
**Specialist agents (dispatched when plan specifies domain):**
- **superpowers:rust-engineer-local** - Mechanical Rust implementation
- **superpowers:rust-engineer-cloud** - Complex Rust reasoning
- **superpowers:ml-engineer-local** - Simple ML implementation
- **superpowers:ml-engineer-cloud** - ML architecture
- **superpowers:general-engineer-local** - Mechanical general implementation
- **superpowers:general-engineer-cloud** - Complex general implementation
- **superpowers:qa-tester** - QA/testing review (mandatory third review stage)
- **superpowers:code-reviewer** - Code review
```

- [ ] **Step 4: Update the Red Flags section**

In the "Red Flags" section, update any references to `Domain Specialist` or `Task Specialist` values to include the new naming. The existing "Skip specialist routing" flag should list all valid values:

```markdown
- Skip specialist routing — always check for Domain Specialist/Task Specialist before dispatching general-engineer-local
```

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "feat(skills): update subagent-driven-development routing for local/cloud

Update specialist selection flowchart and text.
Replace old agent names with new -local/-cloud variants.
Update model selection section with tier guidance.
Update integration and red flags sections."
```

### Task 10: Add Ollama Setup Documentation

**Files:**
- Create: `docs/superpowers/setup/ollama-model-provider.md`

**Task Specialist:** general-engineer-local

**Commit Scope:** docs

- [ ] **Step 1: Write the setup guide**

```markdown
# Ollama Local Model Provider Setup

This guide configures Qwen Code to use Ollama as a local inference backend for `*-local` agent variants.

## Prerequisites

- Ollama installed and running
- qwen3.5:9b model pulled: `ollama pull qwen3.5:9b`

## Configuration

Add the following to your `~/.qwen/settings.json` (or `.qwen/settings.json` for project-specific):

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

Set the environment variable (add to your shell profile):

```bash
export OLLAMA_API_KEY="ollama"
```

Any placeholder value works — Ollama doesn't require authentication.

## Verification

Start Qwen Code and verify the local model is accessible:

```bash
/model
```

You should see `qwen3.5:9b` (or the name you configured) listed as an available model.

## Session Default Model

Set your session's default model to qwen-plus (or your preferred cloud model) so that `*-cloud` agents and the main session use it:

```bash
/model qwen-plus
```

## Context Window Note

The local model has a 16,384 token context window. The `*-local` agent prompts are designed to fit within this limit. When writing plans that dispatch to local agents, ensure individual tasks are scoped so that the task description + file context + generated code stays within ~12k tokens (leaving headroom for the prompt and system message).
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/setup/ollama-model-provider.md
git commit -m "docs: add Ollama local model provider setup guide

Document how to configure Ollama as a model provider in settings.json
for *-local agent variants."
```

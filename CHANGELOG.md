# Changelog

## [5.0.7-fork] - 2026-04-08

### Added

- **Task-driven workflow extensions**: 5 existing skills now have TASK-DRIVEN WORKFLOW EXTENSION blocks
  - brainstorming: task-file short-circuit with confirmation
  - writing-plans: phase-aware generation (RED/GREEN), worktree prerequisite, conditional plan persistence
  - subagent-driven-development: phase detection, phase constraint injection, SEQUENCE.md auto-pick
  - finishing-a-development-branch: SEQUENCE.md update + next-task prompting
  - implementer-prompt: RED/GREEN/Integration/Mechanical phase constraints
- **milestone-planning skill**: Decomposes milestones into ordered, dependency-mapped task files with three-tier classification (Contract/Integration/Mechanical)
- **project-init skill**: Scaffolds the task-driven AIDLC workflow for new projects with stack detection
- **workflow-doctor skill**: Validates workflow configuration and reports issues with fix commands (includes doctor.sh)

### Changed

- Output paths: `docs/specs/` replaces `docs/superpowers/specs/`; plans are transient (milestone) or appended to spec (ad-hoc)
- All extension blocks marked with `TASK-DRIVEN WORKFLOW EXTENSION` comments for merge tracking

## [5.0.6-fork] - 2026-04-07

### Added

- **Qwen Code support**: QWEN.md context file, qwen-extension.json registration
- **Specialist agents** (8 total): rust-engineer-local/cloud, ml-engineer-local/cloud, general-engineer-local/cloud, qa-tester, code-reviewer
- **Three-stage review**: spec compliance → code quality → QA/testing in subagent-driven-development
- **Domain Specialist routing**: Plan-level and task-level specialist annotations for agent dispatch
- **Conventional Commits**: Commit message format enforcement in writing-plans and implementer-prompt
- **Ollama local model provider**: Setup guide in docs/superpowers/setup/

### Removed

- `tests/opencode/` directory (tests adapted for Qwen)

## [5.0.5] - 2026-03-17

### Fixed

- **Brainstorm server ESM fix**: Renamed `server.js` → `server.cjs` so the brainstorming server starts correctly on Node.js 22+ where the root `package.json` `"type": "module"` caused `require()` to fail. ([PR #784](https://github.com/obra/superpowers/pull/784) by @sarbojitrana, fixes [#774](https://github.com/obra/superpowers/issues/774), [#780](https://github.com/obra/superpowers/issues/780), [#783](https://github.com/obra/superpowers/issues/783))
- **Brainstorm owner-PID on Windows**: Skip `BRAINSTORM_OWNER_PID` lifecycle monitoring on Windows/MSYS2 where the PID namespace is invisible to Node.js. Prevents the server from self-terminating after 60 seconds. The 30-minute idle timeout remains as the safety net. ([#770](https://github.com/obra/superpowers/issues/770), docs from [PR #768](https://github.com/obra/superpowers/pull/768) by @lucasyhzhu-debug)
- **stop-server.sh reliability**: Verify the server process actually died before reporting success. Waits up to 2 seconds for graceful shutdown, escalates to `SIGKILL`, and reports failure if the process survives. ([#723](https://github.com/obra/superpowers/issues/723))

### Changed

- **Execution handoff**: Restore user choice between subagent-driven-development and executing-plans after plan writing. Subagent-driven is recommended but no longer mandatory. (Reverts `5e51c3e`)

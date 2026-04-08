#!/bin/sh
# Workflow Doctor — Mechanical Checks
# Runs fast file/permission/config checks. Agent handles semantic checks.
set -e

pass=0
fail=0
warn=0
info=0

check() {
  severity="$1"; desc="$2"; fix="$3"
  if eval "$4" >/dev/null 2>&1; then
    pass=$((pass + 1))
  else
    case "$severity" in
      FAIL) fail=$((fail + 1)); echo "[FAIL] $desc"; echo "  Fix: $fix" ;;
      WARN) warn=$((warn + 1)); echo "[WARN] $desc"; echo "  Fix: $fix" ;;
      INFO) info=$((info + 1)); echo "[INFO] $desc"; echo "  Action: $fix" ;;
    esac
  fi
}

# Required files
check "FAIL" ".qwen/rules/task-driven-development.md missing" \
  "Run project-init or create the file manually" \
  "test -f .qwen/rules/task-driven-development.md"

check "FAIL" ".qwen/rules/development-workflow.md missing" \
  "Run project-init or create the file manually" \
  "test -f .qwen/rules/development-workflow.md"

check "FAIL" ".githooks/pre-commit missing or not executable" \
  "Create .githooks/pre-commit and run: chmod +x .githooks/pre-commit" \
  "test -x .githooks/pre-commit"

check "FAIL" ".githooks/commit-msg missing or not executable" \
  "Create .githooks/commit-msg and run: chmod +x .githooks/commit-msg" \
  "test -x .githooks/commit-msg"

# Git config
check "FAIL" "git hooks path not set to .githooks" \
  "Run: git config core.hooksPath .githooks" \
  "test \"$(git config core.hooksPath 2>/dev/null)\" = '.githooks'"

# Directory structure
check "WARN" "docs/ directory missing" \
  "Run: mkdir -p docs" \
  "test -d docs"

check "WARN" "docs/specs/ directory missing" \
  "Run: mkdir -p docs/specs" \
  "test -d docs/specs"

check "WARN" "docs/milestones/ directory missing" \
  "Run: mkdir -p docs/milestones" \
  "test -d docs/milestones"

# Deprecated paths
check "FAIL" "docs/plans/ exists (deprecated — plans are transient or appended to specs)" \
  "Remove: rm -rf docs/plans/ (move any content to docs/specs/ first)" \
  "! test -d docs/plans"

check "FAIL" "docs/superpowers/ exists (deprecated path convention)" \
  "Remove: rm -rf docs/superpowers/ (move specs to docs/specs/ first)" \
  "! test -d docs/superpowers"

# Milestone health
if test -d docs/milestones; then
  if find docs/milestones -name "SEQUENCE.md" -print -quit 2>/dev/null | grep -q .; then
    pass=$((pass + 1))
  else
    info=$((info + 1))
    echo "[INFO] docs/milestones/ exists but no SEQUENCE.md found"
    echo "  Action: Create a SEQUENCE.md in your active milestone directory"
  fi
else
  info=$((info + 1))
  echo "[INFO] No milestones directory yet — this is fine for new projects"
  echo "  Action: Create docs/milestones/M1-name/ when ready to start task-driven work"
fi

# Summary
total=$((pass + fail + warn + info))
echo ""
echo "Workflow Doctor: $pass/$total passed, $fail failures, $warn warnings, $info info"
if [ "$fail" -eq 0 ] && [ "$warn" -eq 0 ]; then
  echo "Your task-driven workflow is healthy. ✅"
fi
exit "$fail"

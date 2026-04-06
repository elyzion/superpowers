#!/usr/bin/env bash
# Test with small-model model and user's QWEN.md
# This tests whether a cheaper/faster model fails more easily

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

TIMESTAMP=$(date +%s)
OUTPUT_DIR="/tmp/superpowers-tests/${TIMESTAMP}/explicit-skill-requests/small-model"
mkdir -p "$OUTPUT_DIR"

PROJECT_DIR="$OUTPUT_DIR/project"
mkdir -p "$PROJECT_DIR/docs/superpowers/plans"
mkdir -p "$PROJECT_DIR/.qwen"

echo "=== Small Model Test with User QWEN.md ==="
echo "Output dir: $OUTPUT_DIR"
echo "Plugin dir: $PLUGIN_DIR"
echo ""

cd "$PROJECT_DIR"

# Copy user's QWEN.md to simulate real environment
if [ -f "$HOME/.qwen/QWEN.md" ]; then
    cp "$HOME/.qwen/QWEN.md" "$PROJECT_DIR/.qwen/QWEN.md"
    echo "Copied user QWEN.md"
else
    echo "No user QWEN.md found, proceeding without"
fi

# Create a dummy plan file
cat > "$PROJECT_DIR/docs/superpowers/plans/auth-system.md" << 'EOF'
# Auth System Implementation Plan

## Task 1: Add User Model
Create user model with email and password fields.

## Task 2: Add Auth Routes
Create login and register endpoints.

## Task 3: Add JWT Middleware
Protect routes with JWT validation.

## Task 4: Write Tests
Add comprehensive test coverage.
EOF

echo ""

# Turn 1: Start brainstorming
echo ">>> Turn 1: Brainstorming request..."
qwen "I want to add user authentication to my app. Help me think through this." \
    --model small-model \
    --plugin-dir "$PLUGIN_DIR" \
    -y \
    --max-turns 3 \
    -o stream-json \
    > "$OUTPUT_DIR/turn1.json" 2>&1 || true
echo "Done."

# Turn 2: Answer questions
echo ">>> Turn 2: Answering questions..."
qwen "Let's use JWT tokens with 24-hour expiry. Email/password registration." \
    -c \
    --model small-model \
    --plugin-dir "$PLUGIN_DIR" \
    -y \
    --max-turns 3 \
    -o stream-json \
    > "$OUTPUT_DIR/turn2.json" 2>&1 || true
echo "Done."

# Turn 3: Ask to write a plan
echo ">>> Turn 3: Requesting plan..."
qwen "Great, write this up as an implementation plan." \
    -c \
    --model small-model \
    --plugin-dir "$PLUGIN_DIR" \
    -y \
    --max-turns 3 \
    -o stream-json \
    > "$OUTPUT_DIR/turn3.json" 2>&1 || true
echo "Done."

# Turn 4: Confirm plan looks good
echo ">>> Turn 4: Confirming plan..."
qwen "The plan looks good. What are my options for executing it?" \
    -c \
    --model small-model \
    --plugin-dir "$PLUGIN_DIR" \
    -y \
    --max-turns 2 \
    -o stream-json \
    > "$OUTPUT_DIR/turn4.json" 2>&1 || true
echo "Done."

# Turn 5: THE CRITICAL TEST
echo ">>> Turn 5: Requesting subagent-driven-development..."
FINAL_LOG="$OUTPUT_DIR/turn5.json"
qwen "subagent-driven-development, please" \
    -c \
    --model small-model \
    --plugin-dir "$PLUGIN_DIR" \
    -y \
    --max-turns 2 \
    -o stream-json \
    > "$FINAL_LOG" 2>&1 || true
echo "Done."
echo ""

echo "=== Results (Small model) ==="

# Check final turn
SKILL_PATTERN='"skill":"([^"]*:)?subagent-driven-development"'
if grep -q '"name":"Skill"' "$FINAL_LOG" && grep -qE "$SKILL_PATTERN" "$FINAL_LOG"; then
    echo "PASS: Skill was triggered"
    TRIGGERED=true
else
    echo "FAIL: Skill was NOT triggered"
    TRIGGERED=false

    echo ""
    echo "Tools invoked in final turn:"
    grep '"type":"tool_use"' "$FINAL_LOG" | grep -o '"name":"[^"]*"' | head -10 || echo "  (none)"
fi

echo ""
echo "Skills triggered:"
grep -o '"skill":"[^"]*"' "$FINAL_LOG" 2>/dev/null | sort -u || echo "  (none)"

echo ""
echo "Final turn response (first 500 chars):"
grep '"type":"assistant"' "$FINAL_LOG" | head -1 | jq -r '.message.content[0].text // .message.content' 2>/dev/null | head -c 500 || echo "  (could not extract)"

echo ""
echo "Logs in: $OUTPUT_DIR"

if [ "$TRIGGERED" = "true" ]; then
    exit 0
else
    exit 1
fi

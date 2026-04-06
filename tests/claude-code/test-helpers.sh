#!/usr/bin/env bash
# Helper functions for Qwen Code skill tests

# Extract assistant text from Qwen's stream-json output
# Usage: extract_text_from_stream_json "$stream_json_file"
extract_text_from_stream_json() {
    local input_file="$1"
    python3 -c "
import json
with open('$input_file') as f:
    for line in f:
        try:
            data = json.loads(line)
            if data.get('type') == 'assistant':
                msg = data.get('message', {})
                # Handle both string and dict message
                if isinstance(msg, str):
                    try:
                        msg = json.loads(msg)
                    except:
                        continue
                # Extract text from content array (Qwen stream-json format)
                content = msg.get('content', [])
                for part in content:
                    if isinstance(part, dict) and part.get('type') == 'text':
                        print(part.get('text', ''))
        except:
            pass
"
}

# Run Qwen Code with a prompt and capture output
# Usage: run_qwen "prompt text" [timeout_seconds] [allowed_tools]
# Returns clean assistant text (extracted from stream-json)
run_qwen() {
    local prompt="$1"
    local timeout="${2:-60}"
    local allowed_tools="${3:-}"
    local json_file=$(mktemp)
    local text_file=$(mktemp)

    # Build command with stream-json output and yolo mode
    local cmd="qwen \"$prompt\" -o stream-json -y"
    if [ -n "$allowed_tools" ]; then
        cmd="$cmd --allowed-tools $allowed_tools"
    fi

    # Run Qwen in headless mode, capture stream-json
    sleep 3  # Rate limit protection - don't hammer the API
    if timeout "$timeout" bash -c "$cmd" > "$json_file" 2>/dev/null; then
        # Extract clean assistant text from stream-json
        extract_text_from_stream_json "$json_file" > "$text_file"
        cat "$text_file"
        rm -f "$json_file" "$text_file"
        return 0
    else
        local exit_code=$?
        # Still extract text even on failure (timeout, etc.)
        extract_text_from_stream_json "$json_file" > "$text_file"
        cat "$text_file" >&2
        rm -f "$json_file" "$text_file"
        return $exit_code
    fi
}

# Check if output contains a pattern
# Usage: assert_contains "output" "pattern" "test name"
assert_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -qi "$pattern"; then
        echo "  [PASS] $test_name"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

# Check if output does NOT contain a pattern
# Usage: assert_not_contains "output" "pattern" "test name"
assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -qi "$pattern"; then
        echo "  [FAIL] $test_name"
        echo "  Did not expect to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    else
        echo "  [PASS] $test_name"
        return 0
    fi
}

# Check if output matches a count
# Usage: assert_count "output" "pattern" expected_count "test name"
assert_count() {
    local output="$1"
    local pattern="$2"
    local expected="$3"
    local test_name="${4:-test}"

    local actual=$(echo "$output" | grep -c "$pattern" || echo "0")

    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $test_name (found $actual instances)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected $expected instances of: $pattern"
        echo "  Found $actual instances"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

# Check if pattern A appears before pattern B
# Usage: assert_order "output" "pattern_a" "pattern_b" "test name"
assert_order() {
    local output="$1"
    local pattern_a="$2"
    local pattern_b="$3"
    local test_name="${4:-test}"

    # Get line numbers and byte positions where patterns first appear
    local match_a=$(echo "$output" | grep -n -b -o -m 1 "$pattern_a" 2>/dev/null | head -1)
    local match_b=$(echo "$output" | grep -n -b -o -m 1 "$pattern_b" 2>/dev/null | head -1)

    local line_a=$(echo "$match_a" | cut -d: -f1)
    local line_b=$(echo "$match_b" | cut -d: -f1)

    if [ -z "$line_a" ]; then
        echo "  [FAIL] $test_name: pattern A not found: $pattern_a"
        return 1
    fi

    if [ -z "$line_b" ]; then
        echo "  [FAIL] $test_name: pattern B not found: $pattern_b"
        return 1
    fi

    # If on different lines, compare line numbers
    if [ "$line_a" -ne "$line_b" ]; then
        if [ "$line_a" -lt "$line_b" ]; then
            echo "  [PASS] $test_name (A at line $line_a, B at line $line_b)"
            return 0
        else
            echo "  [FAIL] $test_name"
            echo "  Expected '$pattern_a' before '$pattern_b'"
            echo "  But found A at line $line_a, B at line $line_b"
            return 1
        fi
    fi

    # Same line — compare byte offset within that line
    local offset_a=$(echo "$match_a" | cut -d: -f2)
    local offset_b=$(echo "$match_b" | cut -d: -f2)

    if [ "$offset_a" -lt "$offset_b" ]; then
        echo "  [PASS] $test_name (A at line ${line_a}:${offset_a}, B at line ${line_b}:${offset_b})"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected '$pattern_a' before '$pattern_b'"
        echo "  But found A at line ${line_a}:${offset_a}, B at line ${line_b}:${offset_b}"
        return 1
    fi
}

# Create a temporary test project directory
# Usage: test_project=$(create_test_project)
create_test_project() {
    local test_dir=$(mktemp -d)
    echo "$test_dir"
}

# Cleanup test project
# Usage: cleanup_test_project "$test_dir"
cleanup_test_project() {
    local test_dir="$1"
    if [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
}

# Create a simple plan file for testing
# Usage: create_test_plan "$project_dir" "$plan_name"
create_test_plan() {
    local project_dir="$1"
    local plan_name="${2:-test-plan}"
    local plan_file="$project_dir/docs/superpowers/plans/$plan_name.md"

    mkdir -p "$(dirname "$plan_file")"

    cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Task 1: Create Hello Function

Create a simple hello function that returns "Hello, World!".

**File:** `src/hello.js`

**Implementation:**
```javascript
export function hello() {
  return "Hello, World!";
}
```

**Tests:** Write a test that verifies the function returns the expected string.

**Verification:** `npm test`

## Task 2: Create Goodbye Function

Create a goodbye function that takes a name and returns a goodbye message.

**File:** `src/goodbye.js`

**Implementation:**
```javascript
export function goodbye(name) {
  return `Goodbye, ${name}!`;
}
```

**Tests:** Write tests for:
- Default name
- Custom name
- Edge cases (empty string, null)

**Verification:** `npm test`
EOF

    echo "$plan_file"
}

# Export functions for use in tests
export -f extract_text_from_stream_json
export -f run_qwen
export -f assert_contains
export -f assert_not_contains
export -f assert_count
export -f assert_order
export -f create_test_project
export -f cleanup_test_project
export -f create_test_plan

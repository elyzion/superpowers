#!/usr/bin/env python3
"""
Analyze token usage from Qwen Code session transcripts.
Breaks down usage by main session and individual subagents.
"""

import json
import sys
from pathlib import Path
from collections import defaultdict

def parse_message_field(field):
    """Parse a message field that may be a string (JSON) or dict."""
    if isinstance(field, str):
        try:
            return json.loads(field)
        except (json.JSONDecodeError, TypeError):
            return {}
    return field

def analyze_main_session(filepath):
    """Analyze a Qwen Code session file and return token usage broken down by agent."""
    main_usage = {
        'input_tokens': 0,
        'output_tokens': 0,
        'cache_creation': 0,
        'cache_read': 0,
        'messages': 0
    }

    # Track usage per subagent (task tool calls)
    subagent_usage = defaultdict(lambda: {
        'input_tokens': 0,
        'output_tokens': 0,
        'cache_creation': 0,
        'cache_read': 0,
        'messages': 0,
        'description': None
    })

    subagent_counter = 0

    with open(filepath, 'r') as f:
        for line in f:
            try:
                data = json.loads(line)

                # Assistant messages (main session)
                if data.get('type') == 'assistant' and 'message' in data:
                    main_usage['messages'] += 1

                    # Usage metadata is at the top level of the data object
                    if 'usageMetadata' in data:
                        um = data['usageMetadata']
                        if isinstance(um, str):
                            um = parse_message_field(um)
                        main_usage['input_tokens'] += um.get('promptTokenCount', 0) + um.get('thoughtsTokenCount', 0)
                        main_usage['output_tokens'] += um.get('candidatesTokenCount', 0)
                        main_usage['cache_creation'] += um.get('cacheCreationInputTokens', 0)
                        main_usage['cache_read'] += um.get('cachedContentTokenCount', 0)

                    # Detect subagent (task) tool calls in message parts
                    msg = parse_message_field(data['message'])
                    parts = msg.get('parts', [])
                    if isinstance(parts, str):
                        parts = parse_message_field(parts)

                    if isinstance(parts, list):
                        for part in parts:
                            if not isinstance(part, dict):
                                continue
                            if 'functionCall' in part:
                                fc = parse_message_field(part['functionCall'])
                                if fc.get('name') == 'task':
                                    subagent_counter += 1
                                    agent_id = f"subagent-{subagent_counter}"
                                    args = parse_message_field(fc.get('args', '{}'))
                                    desc = args.get('description', f"Task {subagent_counter}")
                                    subagent_usage[agent_id]['description'] = desc[:60]
                                    subagent_usage[agent_id]['messages'] += 1

            except Exception:
                pass

    return main_usage, dict(subagent_usage)

def format_tokens(n):
    """Format token count with thousands separators."""
    return f"{n:,}"

def calculate_cost(usage, input_cost_per_m=3.0, output_cost_per_m=15.0):
    """Calculate estimated cost in dollars."""
    total_input = usage['input_tokens'] + usage['cache_creation'] + usage['cache_read']
    input_cost = total_input * input_cost_per_m / 1_000_000
    output_cost = usage['output_tokens'] * output_cost_per_m / 1_000_000
    return input_cost + output_cost

def main():
    if len(sys.argv) < 2:
        print("Usage: analyze-token-usage.py <session-file.jsonl>")
        sys.exit(1)

    main_session_file = sys.argv[1]

    if not Path(main_session_file).exists():
        print(f"Error: Session file not found: {main_session_file}")
        sys.exit(1)

    # Analyze the session
    main_usage, subagent_usage = analyze_main_session(main_session_file)

    print("=" * 100)
    print("TOKEN USAGE ANALYSIS")
    print("=" * 100)
    print()

    # Print breakdown
    print("Usage Breakdown:")
    print("-" * 100)
    print(f"{'Agent':<15} {'Description':<35} {'Msgs':>5} {'Input':>10} {'Output':>10} {'Cache':>10} {'Cost':>8}")
    print("-" * 100)

    # Main session
    cost = calculate_cost(main_usage)
    print(f"{'main':<15} {'Main session (coordinator)':<35} "
          f"{main_usage['messages']:>5} "
          f"{format_tokens(main_usage['input_tokens']):>10} "
          f"{format_tokens(main_usage['output_tokens']):>10} "
          f"{format_tokens(main_usage['cache_read']):>10} "
          f"${cost:>7.2f}")

    # Subagents (sorted by agent ID)
    for agent_id in sorted(subagent_usage.keys()):
        usage = subagent_usage[agent_id]
        cost = calculate_cost(usage)
        desc = usage['description'] or f"agent-{agent_id}"
        print(f"{agent_id:<15} {desc:<35} "
              f"{usage['messages']:>5} "
              f"{format_tokens(usage['input_tokens']):>10} "
              f"{format_tokens(usage['output_tokens']):>10} "
              f"{format_tokens(usage['cache_read']):>10} "
              f"${cost:>7.2f}")

    print("-" * 100)

    # Calculate totals
    total_usage = {
        'input_tokens': main_usage['input_tokens'],
        'output_tokens': main_usage['output_tokens'],
        'cache_creation': main_usage['cache_creation'],
        'cache_read': main_usage['cache_read'],
        'messages': main_usage['messages']
    }

    for usage in subagent_usage.values():
        total_usage['input_tokens'] += usage['input_tokens']
        total_usage['output_tokens'] += usage['output_tokens']
        total_usage['cache_creation'] += usage['cache_creation']
        total_usage['cache_read'] += usage['cache_read']
        total_usage['messages'] += usage['messages']

    total_input = total_usage['input_tokens'] + total_usage['cache_creation'] + total_usage['cache_read']
    total_tokens = total_input + total_usage['output_tokens']
    total_cost = calculate_cost(total_usage)

    print()
    print("TOTALS:")
    print(f"  Total messages:         {format_tokens(total_usage['messages'])}")
    print(f"  Input tokens:           {format_tokens(total_usage['input_tokens'])}")
    print(f"  Output tokens:          {format_tokens(total_usage['output_tokens'])}")
    print(f"  Cache creation tokens:  {format_tokens(total_usage['cache_creation'])}")
    print(f"  Cache read tokens:      {format_tokens(total_usage['cache_read'])}")
    print()
    print(f"  Total input (incl cache): {format_tokens(total_input)}")
    print(f"  Total tokens:             {format_tokens(total_tokens)}")
    print()
    print(f"  Estimated cost: ${total_cost:.2f}")
    print("  (at $3/$15 per M tokens for input/output)")
    print()
    print("=" * 100)

if __name__ == '__main__':
    main()

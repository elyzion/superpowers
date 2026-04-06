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

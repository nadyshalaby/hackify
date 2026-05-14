#!/usr/bin/env bash
# hackify v0.2.2 — UserPromptSubmit hook.
#
# Injects rules/hard-caps.md as additional context on every user prompt so
# the hard caps and zero-tolerance bans are always loaded. NON-routing — this
# hook MUST NOT inspect the prompt or classify full vs quick vs brainstorm.
#
# Output contract: the harness reads a single JSON envelope from stdout. Raw
# stdout becomes a transcript message instead of injected context, so the
# envelope wrapper is load-bearing.
#
# Failure contract: this hook MUST NOT block the user's prompt. Any failure
# path (unset env, missing file, unavailable JSON encoder, non-UTF-8 content)
# exits 0 silently — a missing injection is recoverable; a blocked prompt
# is not. `set -e` is intentionally NOT used.

set -u

if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  exit 0
fi

RULES_FILE="${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md"

if [ ! -f "$RULES_FILE" ] || [ ! -r "$RULES_FILE" ]; then
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  jq -Rs '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: .}}' "$RULES_FILE" 2>/dev/null || exit 0
elif command -v python3 >/dev/null 2>&1; then
  PYTHONIOENCODING=utf-8 python3 -c '
import json,sys
with open(sys.argv[1], encoding="utf-8") as f:
    print(json.dumps({"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":f.read()}}))
' "$RULES_FILE" 2>/dev/null || exit 0
fi

exit 0

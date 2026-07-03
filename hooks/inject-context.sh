#!/usr/bin/env bash
# hackify v0.7.0 — UserPromptSubmit context injector (generalized).
#
# Injects the markdown file given as $1 as additionalContext on every user
# prompt, so always-on doctrine is loaded every turn. hooks.json invokes this
# once per always-on file (rules/hard-caps.md, rules/expert-mindset.md,
# rules/perf-guardrails.md) as a separate UserPromptSubmit hook entry — the
# harness concatenates their additionalContext. NON-routing — this hook MUST NOT inspect the prompt or
# classify full vs quick vs groom.
#
# Output contract: the harness reads a single JSON envelope from stdout. Raw
# stdout becomes a transcript message instead of injected context, so the
# envelope wrapper is load-bearing.
#
# Failure contract: this hook MUST NOT block the user's prompt. Any failure
# path (no arg, missing file, unavailable JSON encoder, non-UTF-8 content)
# exits 0 silently — a missing injection is recoverable; a blocked prompt
# is not. `set -e` is intentionally NOT used.

set -u

RULES_FILE="${1:-}"

if [ -z "$RULES_FILE" ] || [ ! -f "$RULES_FILE" ] || [ ! -r "$RULES_FILE" ]; then
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

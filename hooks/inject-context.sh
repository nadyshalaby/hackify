#!/usr/bin/env bash
# hackify v0.11.0. UserPromptSubmit context injector (session-aware).
#
# Injects the markdown file given as $1 as additionalContext. hooks.json
# invokes this once per always-on file (rules/hard-caps.md,
# rules/expert-mindset.md, rules/perf-guardrails.md,
# rules/phase-discipline.md) as a separate UserPromptSubmit hook entry; the
# harness concatenates their additionalContext. NON-routing, this hook MUST
# NOT inspect the prompt or classify full vs quick vs groom.
#
# WHY IT IS SESSION-AWARE (v0.11.0): additionalContext is appended to the
# transcript and STAYS there. Re-injecting the same ~2.1k tokens on every
# prompt bought nothing behaviourally and cost ~64k tokens over a 30-turn
# session, one resident copy per turn. The rules are in force from the first
# prompt onward because that first copy never leaves the context window.
# So: full text on the first prompt of a session, a one-line pointer after,
# and a full re-injection every REFRESH_EVERY prompts so a very long session
# cannot drift away from the law. Coverage is unchanged; only the repetition
# is gone.
#
# Output contract: the harness reads a single JSON envelope from stdout. Raw
# stdout becomes a transcript message instead of injected context, so the
# envelope wrapper is load-bearing.
#
# Failure contract: this hook MUST NOT block the user's prompt. Any failure
# path (no arg, missing file, unavailable JSON encoder, non-UTF-8 content,
# unwritable state dir) exits 0 silently, and every one of them degrades to
# injecting the FULL text, never to injecting nothing. A missing injection is
# recoverable; a silently dropped law is not. `set -e` is intentionally NOT
# used.

set -u

RULES_FILE="${1:-}"

if [ -z "$RULES_FILE" ] || [ ! -f "$RULES_FILE" ] || [ ! -r "$RULES_FILE" ]; then
  exit 0
fi

# Full text is re-injected on turn 1 and every Nth turn thereafter.
REFRESH_EVERY="${HACKIFY_CTX_REFRESH_EVERY:-25}"

HOOK_STDIN=""
if [ ! -t 0 ]; then
  HOOK_STDIN=$(cat 2>/dev/null || true)
fi

if command -v python3 >/dev/null 2>&1; then
  HACKIFY_RULES_FILE="$RULES_FILE" \
  HACKIFY_HOOK_STDIN="$HOOK_STDIN" \
  HACKIFY_REFRESH_EVERY="$REFRESH_EVERY" \
  PYTHONIOENCODING=utf-8 python3 "$(dirname "$0")/inject_context.py" 2>/dev/null && exit 0
fi

# Degrade path: no python3. Inject the full text every prompt, exactly as
# every version before v0.11.0 did.
if command -v jq >/dev/null 2>&1; then
  jq -Rs '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: .}}' "$RULES_FILE" 2>/dev/null || exit 0
fi

exit 0

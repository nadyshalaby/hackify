#!/usr/bin/env bash
# hackify v0.11.0. Context injector for hackify's own hook events.
#
# Injects the markdown file given as the last argument as additionalContext.
#
# TWO EVENTS, ONE SCRIPT, AND THEY ARE NOT THE SAME KIND OF DOCUMENT.
#
# UserPromptSubmit (the default, no flag). hooks.json invokes this once per
# always-on rules file (rules/hard-caps.md, rules/expert-mindset.md,
# rules/perf-guardrails.md, rules/phase-discipline.md,
# rules/claim-integrity.md) as a separate hook entry; the harness concatenates
# their additionalContext. NON-routing, this hook MUST NOT inspect the prompt or
# classify full vs quick vs groom.
#
# SessionStart (--event SessionStart). One entry, rules/plugin-map.md, the
# orientation map. It fires on startup, resume, clear and compact, which is
# every moment a session needs orienting and no other moment. A map is a
# different kind of document from a law: you need it once to know what the
# plugin ships, not on turn two hundred, so it is deliberately NOT on the
# per-prompt chain. Putting it there would have cost a pointer line on every
# prompt of every session forever, including sessions that never touch hackify,
# and the pointer wording asserts "is binding verbatim", which a map is not.
#
# WHY UserPromptSubmit IS SESSION-AWARE (v0.11.0): additionalContext is appended
# to the transcript and STAYS there. Re-injecting the same ~2.1k tokens on every
# prompt bought nothing behaviourally and cost ~64k tokens over a 30-turn
# session, one resident copy per turn. The rules are in force from the first
# prompt onward because that first copy never leaves the context window.
# So: full text on the first prompt of a session, a one-line pointer after,
# and a full re-injection every REFRESH_EVERY prompts so a very long session
# cannot drift away from the law. Coverage is unchanged; only the repetition
# is gone. SessionStart needs none of that machinery: the event fires once per
# session by construction, so the map is always sent in full and no state is
# kept.
#
# Output contract: the harness reads a single JSON envelope from stdout, and
# hookEventName MUST name the event that fired. Raw stdout becomes a transcript
# message instead of injected context, so the envelope wrapper is load-bearing.
#
# Failure contract: this hook MUST NOT block the user's prompt or the session.
# Any failure path (no arg, missing file, unavailable JSON encoder, non-UTF-8
# content, unwritable state dir) exits 0 silently, and every one of them
# degrades to injecting the FULL text, never to injecting nothing. A missing
# injection is recoverable; a silently dropped law is not. `set -e` is
# intentionally NOT used.

set -u

EVENT="UserPromptSubmit"
if [ "${1:-}" = "--event" ]; then
  EVENT="${2:-}"
  shift 2
fi

RULES_FILE="${1:-}"

if [ -z "$EVENT" ] || [ -z "$RULES_FILE" ] || [ ! -f "$RULES_FILE" ] || [ ! -r "$RULES_FILE" ]; then
  exit 0
fi

# Full text of $2, wrapped in the envelope for event $1. jq first because it is
# already this script's degrade encoder; python3 second so a box with one of the
# two still injects. Both read the file directly, so neither can truncate on a
# byte the shell cannot hold.
emit_full() {
  if command -v jq > /dev/null 2>&1; then
    jq -Rs --arg e "$1" \
      '{hookSpecificOutput: {hookEventName: $e, additionalContext: .}}' \
      "$2" 2> /dev/null && return 0
  fi
  if command -v python3 > /dev/null 2>&1; then
    HACKIFY_EVENT="$1" HACKIFY_RULES_FILE="$2" PYTHONIOENCODING=utf-8 python3 -c '
import json, os, sys
with open(os.environ["HACKIFY_RULES_FILE"], encoding="utf-8") as handle:
    body = handle.read()
sys.stdout.write(json.dumps({"hookSpecificOutput": {
    "hookEventName": os.environ["HACKIFY_EVENT"],
    "additionalContext": body,
}}))
' 2> /dev/null && return 0
  fi
  return 1
}

# Any event other than UserPromptSubmit is a once-per-session injection with no
# counter, no pointer and no state directory.
if [ "$EVENT" != "UserPromptSubmit" ]; then
  emit_full "$EVENT" "$RULES_FILE"
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
emit_full "$EVENT" "$RULES_FILE"

exit 0

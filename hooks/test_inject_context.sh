#!/usr/bin/env bash
# Tests for hooks/inject-context.sh + hooks/inject_context.py.
# Exit 0 if all cases pass. Run: bash hooks/test_inject_context.sh
#
# The contract under test: full rules text on the first prompt of a session,
# a one-line pointer on later prompts, a full refresh every Nth prompt, and a
# full injection whenever session identity or state is unavailable.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/hooks/inject-context.sh"
RULES="$ROOT/rules/hard-caps.md"
PASS=0
FAIL=0

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
export TMPDIR="$TMPD"

ctx() { jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null; }
prompt() { jq -nc --arg s "$1" '{session_id:$s, hook_event_name:"UserPromptSubmit", prompt:"hi"}'; }

expect() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    printf '  ok   %s\n' "$label"; PASS=$((PASS + 1))
  else
    printf '  FAIL %s (missing: %s)\n' "$label" "$needle"; FAIL=$((FAIL + 1))
  fi
}

expect_not() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    printf '  FAIL %s (unexpectedly present: %s)\n' "$label" "$needle"; FAIL=$((FAIL + 1))
  else
    printf '  ok   %s\n' "$label"; PASS=$((PASS + 1))
  fi
}

echo "[1] first prompt of a session injects the full rules text"
OUT=$(prompt sess-a | "$HOOK" "$RULES" | ctx)
expect "turn 1 carries the size caps" "$OUT" "## Size caps"
expect_not "turn 1 is not a pointer" "$OUT" "[hackify always-on]"

echo "[2] later prompts in the same session inject the pointer only"
OUT=$(prompt sess-a | "$HOOK" "$RULES" | ctx)
expect "turn 2 is the pointer" "$OUT" "[hackify always-on]"
expect "pointer names the canonical source" "$OUT" "rules/hard-caps.md"
expect_not "turn 2 does not repeat the caps" "$OUT" "## Size caps"

echo "[3] the pointer is materially smaller than the full text"
FULL=$(prompt sess-full | "$HOOK" "$RULES" | ctx | wc -c | tr -d ' ')
PTR=$(prompt sess-a | "$HOOK" "$RULES" | ctx | wc -c | tr -d ' ')
if [ "$PTR" -lt $((FULL / 3)) ]; then
  printf '  ok   pointer %s chars vs full %s chars (>3x smaller)\n' "$PTR" "$FULL"; PASS=$((PASS + 1))
else
  printf '  FAIL pointer %s chars is not <1/3 of full %s chars\n' "$PTR" "$FULL"; FAIL=$((FAIL + 1))
fi

echo "[3b] the pointer carries the irreducible core, not just a reference"
# A summarised conversation can drop the turn that held the full text, so the
# pointer must stand alone. It quotes the file's own bolded bullet leads.
DIGEST=$(prompt sess-digest-a | "$HOOK" "$RULES" | ctx)
DIGEST=$(prompt sess-digest-a | "$HOOK" "$RULES" | ctx)
expect "pointer states the caps" "$DIGEST" "Core, still binding in full:"
expect "pointer carries the function-size cap" "$DIGEST" "40 lines"
expect "pointer carries the file-size cap" "$DIGEST" "500 lines"
expect "pointer carries the suppression ban" "$DIGEST" "0 lint suppressions"
expect "pointer survives losing the original" "$DIGEST" "no longer"

echo "[3c] the digest keeps each cap's subject and covers numbered rule files"
# A digest of bare bold leads reads "40 lines; 500 lines", which cannot tell a
# function cap from a file cap once the full text is gone.
expect "function cap keeps its subject" "$DIGEST" "40 lines per function/method"
expect "file cap keeps its subject" "$DIGEST" "500 lines per file"
# perf-guardrails numbers its rules instead of bulleting them; a bullet-only
# digest would leave that file with a bare reference and nothing else.
PERF="$ROOT/rules/perf-guardrails.md"
P1=$(prompt sess-perf | "$HOOK" "$PERF" | ctx)
P2=$(prompt sess-perf | "$HOOK" "$PERF" | ctx)
expect "numbered rules digest too" "$P2" "Never query or call per loop item"
expect "numbered digest reaches the last rule" "$P2" "Measure before optimizing"
expect_not "digest drops split-mid-token noise" "$P2" "No \`Promise;"

echo "[4] every Nth prompt re-injects the full text"
export HACKIFY_CTX_REFRESH_EVERY=3
prompt sess-r | "$HOOK" "$RULES" >/dev/null   # turn 1, full
prompt sess-r | "$HOOK" "$RULES" >/dev/null   # turn 2, pointer
OUT=$(prompt sess-r | "$HOOK" "$RULES" | ctx) # turn 3, refresh
expect "turn 3 with refresh=3 is a full re-injection" "$OUT" "## Size caps"
unset HACKIFY_CTX_REFRESH_EVERY

echo "[5] a different session starts its own count"
OUT=$(prompt sess-b | "$HOOK" "$RULES" | ctx)
expect "new session gets the full text" "$OUT" "## Size caps"

echo "[6] no session identity degrades to a full injection"
OUT=$(printf '%s' '{"hook_event_name":"UserPromptSubmit"}' | "$HOOK" "$RULES" | ctx)
expect "missing session_id injects in full" "$OUT" "## Size caps"

echo "[7] unparseable stdin degrades to a full injection"
OUT=$(printf '%s' 'not json at all' | "$HOOK" "$RULES" | ctx)
expect "garbage stdin injects in full" "$OUT" "## Size caps"

echo "[8] the hook never blocks the prompt"
for bad in "" "/nonexistent/rules.md"; do
  printf '%s' "$(prompt sess-z)" | "$HOOK" $bad >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    printf '  ok   exits 0 for arg %s\n' "'${bad:-<empty>}'"; PASS=$((PASS + 1))
  else
    printf '  FAIL non-zero exit for arg %s\n' "'${bad:-<empty>}'"; FAIL=$((FAIL + 1))
  fi
done

echo "[9] all four always-on files count independently"
prompt sess-c | "$HOOK" "$ROOT/rules/hard-caps.md" >/dev/null
OUT=$(prompt sess-c | "$HOOK" "$ROOT/rules/expert-mindset.md" | ctx)
expect "expert-mindset still gets its own turn 1" "$OUT" "## The stakes"
OUT=$(prompt sess-c | "$HOOK" "$ROOT/rules/perf-guardrails.md" | ctx)
expect "perf-guardrails still gets its own turn 1" "$OUT" "## The twelve guardrails"
OUT=$(prompt sess-c | "$HOOK" "$ROOT/rules/phase-discipline.md" | ctx)
expect "phase-discipline still gets its own turn 1" "$OUT" "## The five laws"

echo "[10] the phase-discipline laws survive into the turn-2 pointer"
# Two turns against one session id, asserting on the SECOND output. A static
# grep of rules/phase-discipline.md proves a bullet sits in the file; it never
# proves that bullet reaches turn 2, and every prompt after the first of a
# session sees the digest and nothing else.
#
# The carve-out assertion is the load-bearing one. "unless it is trivial or
# read-only" is 33 chars against QUALIFIER_MAX_CHARS = 34 in inject_context.py,
# and qualifier() returns EMPTY rather than truncating when the clause runs
# long. So a two-word reword silently deletes the scope carve-out from every
# prompt after the first, the ledger law quietly becomes absolute, and nothing
# anywhere else fails. A grep of the rules file cannot catch that, because the
# sentence would still be sitting in the file. Only a digest-output assertion
# catches it. Do not simplify this back into a grep.
PD="$ROOT/rules/phase-discipline.md"
prompt sess-pd | "$HOOK" "$PD" >/dev/null      # turn 1, full text
PD_PTR=$(prompt sess-pd | "$HOOK" "$PD" | ctx) # turn 2, pointer
expect "turn 2 is the pointer" "$PD_PTR" "[hackify always-on]"
expect_not "turn 2 does not repeat the full laws" "$PD_PTR" "## The five laws"
expect "wizard mandate survives the digest" "$PD_PTR" "Every question goes through the wizard tool"
expect "scope carve-out survives the digest" "$PD_PTR" "unless it is trivial or read-only"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

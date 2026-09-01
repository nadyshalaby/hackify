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
  if [[ "$haystack" == *"$needle"* ]]; then
    printf '  ok   %s\n' "$label"; PASS=$((PASS + 1))
  else
    printf '  FAIL %s (missing: %s)\n' "$label" "$needle"; FAIL=$((FAIL + 1))
  fi
}

expect_not() {
  local label="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
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
# The recovery instruction is UNCONDITIONAL, and the whole clause is asserted
# rather than the bare path. A pointer that only mentions its file has told the
# model nothing to do with it; the imperative plus the scope ("any detail not in
# that list") is what keeps the digest from being read as the whole law. Both
# halves are load-bearing, so neither is worth asserting on its own.
expect "pointer says to re-read, and for what" "$DIGEST" \
  "Re-read $RULES for any detail not in that list"

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

echo "[9] all five always-on files count independently"
prompt sess-c | "$HOOK" "$ROOT/rules/hard-caps.md" >/dev/null
OUT=$(prompt sess-c | "$HOOK" "$ROOT/rules/expert-mindset.md" | ctx)
expect "expert-mindset still gets its own turn 1" "$OUT" "## The stakes"
OUT=$(prompt sess-c | "$HOOK" "$ROOT/rules/perf-guardrails.md" | ctx)
expect "perf-guardrails still gets its own turn 1" "$OUT" "## The twelve guardrails"
OUT=$(prompt sess-c | "$HOOK" "$ROOT/rules/phase-discipline.md" | ctx)
expect "phase-discipline still gets its own turn 1" "$OUT" "## The five laws"
OUT=$(prompt sess-c | "$HOOK" "$ROOT/rules/claim-integrity.md" | ctx)
expect "claim-integrity still gets its own turn 1" "$OUT" "## The golden rule"

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

echo "[11] the claim-integrity laws survive into the turn-2 pointer"
# Same distinction [76e] was built on, and the whole point of this block: a grep
# of rules/claim-integrity.md proves a law sits in the file, never that it reaches
# a single prompt after the first of a session. This rule bans exactly that move,
# so testing it by presence would be the defect on display inside its own suite.
#
# The truncation assertion is the one nobody would think to write. digest_of()
# stops at DIGEST_MAX_CHARS = 900 and returns what it had plus "; ...", so a file
# that grows past the cap loses its TAIL laws with no error anywhere: hooks.json
# is still wired, the file is still complete on disk, turn 1 still carries
# everything, and every prompt after it is quietly missing the end of the list.
# Two assertions are needed, not one. The "; ..." check catches an overrun, and
# the last-law check catches a law de-bolded, reworded into a duplicate of an
# earlier lead (leads are de-duplicated) or dropped outright.
CI="$ROOT/rules/claim-integrity.md"
prompt sess-ci | "$HOOK" "$CI" >/dev/null      # turn 1, full text
CI_PTR=$(prompt sess-ci | "$HOOK" "$CI" | ctx) # turn 2, pointer
expect "turn 2 is the pointer" "$CI_PTR" "[hackify always-on]"
expect_not "turn 2 does not repeat the full laws" "$CI_PTR" "## The golden rule"
expect "golden rule survives the digest" "$CI_PTR" "Code is the only source of truth"
expect "the re-derive law survives the digest" "$CI_PTR" "re-derive every fact from the code"
expect "claiming without proving survives" "$CI_PTR" "Prove every claim with fresh output"
expect "the stale-number law survives" "$CI_PTR" "A number you did not just count is already wrong"
expect "the citation law survives" "$CI_PTR" "Open every citation you write"
expect "the one-site-of-a-family law survives" "$CI_PTR" "Fixing the filed site is not fixing the defect"
expect "the rationale-drift law survives" "$CI_PTR" "A comment's reason may no longer be the only one"
expect "the speed law survives" "$CI_PTR" "Hand agents your facts and permission to refute them"
expect "the silent-verification law survives" "$CI_PTR" "can fail silently is not a verification"
expect "the clean-result law survives" "$CI_PTR" "ability to have returned a dirty one"
expect "the absence law survives" "$CI_PTR" "ability to have found the thing present"
expect_not "the digest is not truncated at DIGEST_MAX_CHARS" "$CI_PTR" "; ..."
# Deliberately the LAST law in the file. If the digest ever overruns, this is the
# first assertion to fail, which is what turns a silent tail-drop into a red.
expect "the last law still reaches turn 2" "$CI_PTR" "Say what the checks do not reach"

echo "[12] one dead entry cannot reach the other four"
# hooks.json lists each always-on file as its OWN UserPromptSubmit entry, in its
# own process. That split IS the safety property: one file going unreadable
# costs that file and nothing else. Two halves here, and the second is the one
# worth having.
#
# The turn-1 half is the failure contract as inject-context.sh's header states
# it: a dead path exits 0, injects nothing, and never blocks the prompt, while
# every other entry still delivers its FULL text.
#
# The turn-2 half is the one nobody would think to write, and it is the reason
# this block is not just the turn-1 check. Hoisting the pointer's shared wording
# into a single designated "preamble" entry is a real token saving that changes
# NOTHING on turn 1, so a full-text assertion passes identically before and
# after it. The loss shows up only in POINTER mode, where the four survivors
# would quietly start arriving with no binding statement and no re-read path,
# having borrowed both from an entry that is gone. So each survivor is driven to
# turn 2 and required to carry its own title, its own path, its own digest and
# its own binding sentence, with nothing borrowed from a sibling. Do not fold
# this back into a turn-1 check.
DEAD_ENTRY="$ROOT/rules/hard-caps.md.gone"
DEAD_OUT=$(prompt sess-iso | "$HOOK" "$DEAD_ENTRY" 2>/dev/null)
DEAD_RC=$?
if [ "$DEAD_RC" -eq 0 ] && [ -z "$DEAD_OUT" ]; then
  printf '  ok   the dead entry exits 0 and injects nothing\n'; PASS=$((PASS + 1))
else
  printf '  FAIL dead entry rc=%s output=%s (must exit 0 and emit nothing)\n' \
    "$DEAD_RC" "${DEAD_OUT:-<empty>}"; FAIL=$((FAIL + 1))
fi

# name:full-text anchor:literal from that file's own digest
for row in \
  "expert-mindset:## The stakes:Prove, do not claim" \
  "perf-guardrails:## The twelve guardrails:Never query or call per loop item" \
  "phase-discipline:## The five laws:Every question goes through the wizard tool" \
  "claim-integrity:## The golden rule:Code is the only source of truth"; do
  NAME="${row%%:*}"; REST="${row#*:}"
  ANCHOR="${REST%%:*}"; OWN_LAW="${REST#*:}"
  RF="$ROOT/rules/$NAME.md"
  ISO_FULL=$(prompt sess-iso | "$HOOK" "$RF" | ctx) # turn 1, full text
  ISO_PTR=$(prompt sess-iso | "$HOOK" "$RF" | ctx)  # turn 2, pointer
  expect "$NAME still delivers its full text beside a dead entry" "$ISO_FULL" "$ANCHOR"
  expect "$NAME's pointer names its own file" "$ISO_PTR" "rules/$NAME.md"
  expect "$NAME's pointer carries its own binding sentence" "$ISO_PTR" "is binding verbatim"
  expect "$NAME's pointer carries its own re-read path" "$ISO_PTR" "Re-read $RF"
  expect "$NAME's pointer carries its own core" "$ISO_PTR" "$OWN_LAW"
done

echo "[13] the SessionStart branch injects the orientation map, once and in full"
# The map is a different kind of document from the five laws, and the branch it
# takes is different in every way that can go wrong silently.
#
# THE ENVELOPE IS THE FIRST THING ASSERTED, because it is the one that fails
# without a symptom. The harness reads hookEventName to decide which event this
# output belongs to; a SessionStart hook answering "UserPromptSubmit" is a hook
# that runs, exits 0, prints valid JSON and delivers nothing. That is exactly
# the defect this whole task exists to fix, one layer down, so it is checked
# before anything about the text.
#
# SECOND, THAT NO PER-TURN MACHINERY REACHED IT. The session-aware path is right
# for a law that must not fade and wrong for a map: its pointer asserts "is
# binding verbatim", which a map is not, and its counter would turn the second
# fire of a resumed session into a digest of a document the model has never
# seen. So the branch is driven three times under ONE session id and required to
# return the identical full text every time, with no pointer wording and no
# counter file left behind.
MAP="$ROOT/rules/plugin-map.md"
MAP_H1="# hackify, what ships and where to go"
session_start() { jq -nc --arg s "$1" --arg src "$2" \
  '{session_id:$s, hook_event_name:"SessionStart", source:$src}'; }

SS_RAW=$(session_start sess-map startup | "$HOOK" --event SessionStart "$MAP")
SS_EVENT=$(printf '%s' "$SS_RAW" | jq -r '.hookSpecificOutput.hookEventName // ""')
if [ "$SS_EVENT" = "SessionStart" ]; then
  printf '  ok   the envelope names the event that fired (SessionStart)\n'; PASS=$((PASS + 1))
else
  printf '  FAIL the envelope named %s, so the harness would not treat this as SessionStart context\n' \
    "${SS_EVENT:-<none>}"; FAIL=$((FAIL + 1))
fi

SS_ONE=$(printf '%s' "$SS_RAW" | ctx)
expect "session start carries the map's own H1" "$SS_ONE" "$MAP_H1"
expect "session start carries the entry-point table" "$SS_ONE" "## Entry points"
expect "session start carries the law table" "$SS_ONE" "## The law, injected on every prompt"
expect_not "session start is never the always-on pointer" "$SS_ONE" "[hackify always-on]"

SS_TWO=$(session_start sess-map resume | "$HOOK" --event SessionStart "$MAP" | ctx)
SS_THREE=$(session_start sess-map clear | "$HOOK" --event SessionStart "$MAP" | ctx)
if [ "$SS_ONE" = "$SS_TWO" ] && [ "$SS_TWO" = "$SS_THREE" ]; then
  printf '  ok   every fire of one session id returns the identical full map (no counter, no pointer)\n'
  PASS=$((PASS + 1))
else
  printf '  FAIL repeated SessionStart fires diverged, so per-prompt machinery reached the map branch\n'
  FAIL=$((FAIL + 1))
fi

MAP_STATE=$(find "${TMPDIR%/}/hackify-ctx" -name '*plugin-map*' 2> /dev/null)
if [ -z "$MAP_STATE" ]; then
  printf '  ok   the map branch writes no counter into the state dir\n'; PASS=$((PASS + 1))
else
  printf '  FAIL the map branch left state behind: %s\n' "$MAP_STATE"; FAIL=$((FAIL + 1))
fi

echo "[13b] the default branch is untouched, and the map is not on the per-prompt chain"
# The saving this design claims is "zero cost on every prompt after the first",
# and a claim about cost is worth what the thing that would catch its loss is
# worth. Two ways it is lost: the flag stops being honoured, so a map dispatch
# falls through to the session-aware path; or somebody adds the map to the
# UserPromptSubmit array, where it would ride the pointer chain forever. The
# first is caught by driving the default branch with no flag, the second by
# reading the wiring rather than trusting it.
DEF_EVENT=$(prompt sess-default | "$HOOK" "$RULES" \
  | jq -r '.hookSpecificOutput.hookEventName // ""')
if [ "$DEF_EVENT" = "UserPromptSubmit" ]; then
  printf '  ok   no flag still means UserPromptSubmit, so the five laws are unaffected\n'
  PASS=$((PASS + 1))
else
  printf '  FAIL the default branch named %s instead of UserPromptSubmit\n' \
    "${DEF_EVENT:-<none>}"; FAIL=$((FAIL + 1))
fi

UPS_CMDS=$(jq -r '.hooks.UserPromptSubmit[].hooks[].command' "$ROOT/hooks/hooks.json" 2> /dev/null)
SS_CMDS=$(jq -r '.hooks.SessionStart[].hooks[].command' "$ROOT/hooks/hooks.json" 2> /dev/null)
expect "hooks.json wires the map on SessionStart" "$SS_CMDS" "rules/plugin-map.md"
expect_not "hooks.json keeps the map off the per-prompt chain" "$UPS_CMDS" "rules/plugin-map.md"

echo "[13c] a dead map never blocks a session"
# Same failure contract the five laws get, on the event where blocking is worse:
# a UserPromptSubmit hook that hangs costs one prompt, a SessionStart hook that
# fails loudly greets every new session with an error.
DEAD_MAP_OUT=$(session_start sess-map-dead startup | "$HOOK" --event SessionStart "$MAP.gone" 2>/dev/null)
DEAD_MAP_RC=$?
if [ "$DEAD_MAP_RC" -eq 0 ] && [ -z "$DEAD_MAP_OUT" ]; then
  printf '  ok   a missing map exits 0 and injects nothing\n'; PASS=$((PASS + 1))
else
  printf '  FAIL missing map rc=%s output=%s (must exit 0 and emit nothing)\n' \
    "$DEAD_MAP_RC" "${DEAD_MAP_OUT:-<empty>}"; FAIL=$((FAIL + 1))
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

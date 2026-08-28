# shellcheck shell=bash

# [75] Ship-bar wiring, the v0.9.0 always-on contract.
#
# Four mechanisms became mandatory in EVERY mode and take no user opt-in:
# the law-scout (bundled lawkeeper scanner scoped to touched files), the ship
# gate (build/boot/smoke), Reviewer F (cross-module coherence), and the
# refute-before-fix step with a settled-diff exit condition.
#
# Prose rules drift. These checks make a mode that quietly drops one of the
# four fail loudly, which is the same failure mode check [38] was written for
# after the perf-guardrails hook injection went missing.

SHIP_BAR_MODES="skills/hackify/SKILL.md skills/quick/SKILL.md"
LAW_SCOUT_REF="skills/hackify/references/law-scout.md"
SHIP_GATE_REF="skills/hackify/references/ship-gate.md"
COHERENCE_TPL="skills/hackify/references/parallel-agents/phase-5-multi-review-f-coherence.md"
REFUTE_TPL="skills/hackify/references/parallel-agents/phase-5-refute.md"

yellow "[75] ship-bar protocol files exist and are non-empty"
for f in "$LAW_SCOUT_REF" "$SHIP_GATE_REF" "$COHERENCE_TPL" "$REFUTE_TPL"; do
  if [ ! -s "$f" ]; then
    red "  FAIL $f missing or empty"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f exists and non-empty"
  fi
done

yellow "[75b] every mode wires all four always-on mechanisms"
# One token per mechanism, chosen to be the reference path each mode must
# cite, so a mode that mentions the idea without wiring the protocol fails.
for m in $SHIP_BAR_MODES; do
  # Every token is a file path on purpose: a bare word like "coherence" would
  # pass on a mode file that merely mentions the idea in prose, including one
  # explaining why it skips the lens.
  for tok in 'law-scout.md' 'ship-gate.md' 'phase-5-refute.md' 'phase-5-multi-review-f-coherence.md'; do
    if grep -qF -- "$tok" "$m"; then
      green "  ok   $m wires '$tok'"
    else
      red "  FAIL $m does not wire '$tok' (ship-bar mechanism missing from this mode)"
      FAILED=$((FAILED + 1))
    fi
  done
done

yellow "[75c] ship gate names its three ledger rows in every mode"
for m in $SHIP_BAR_MODES; do
  for row in 'ship.build' 'ship.boot' 'ship.smoke'; do
    if grep -qF -- "$row" "$m"; then
      green "  ok   $m names ledger row '$row'"
    else
      red "  FAIL $m missing ship-gate ledger row '$row'"
      FAILED=$((FAILED + 1))
    fi
  done
done

yellow "[75d] law-scout invokes the bundled scanner by path with a scoped run"
# The law-scout's whole premise is that it runs a file inside this plugin
# rather than calling the lawkeeper skill. If the invocation or the scoping
# flag disappears, the protocol silently becomes a whole-tree sweep (or a
# skill call, which SKILL.md forbids).
for tok in 'skills/lawkeeper/scripts/audit_scan.py' '--paths-from'; do
  if grep -qF -- "$tok" "$LAW_SCOUT_REF"; then
    green "  ok   $LAW_SCOUT_REF invokes '$tok'"
  else
    red "  FAIL $LAW_SCOUT_REF missing '$tok' (scoped bundled-scanner invocation)"
    FAILED=$((FAILED + 1))
  fi
done
if grep -qF -- 'paths-from' skills/lawkeeper/scripts/audit_scan.py; then
  green "  ok   audit_scan.py implements --paths-from"
else
  red "  FAIL audit_scan.py does not implement --paths-from (law-scout cannot scope its run)"
  FAILED=$((FAILED + 1))
fi

yellow "[75e] SKILL.md carves out bundled-script execution from the skill-call rule"
# SKILL.md's three-tier skill-call rule (v0.9.4, formerly a blanket "Never
# call other skills") bans third-party plugin skills. Running the bundled
# lawkeeper scanner by path is not a skill call at all, and the exemption
# must be stated where the rule is, or a future reader resolves the conflict
# by dropping the scout.
if grep -qF 'is not a skill call' skills/hackify/SKILL.md; then
  green "  ok   skills/hackify/SKILL.md states the bundled-script carve-out"
else
  red "  FAIL skills/hackify/SKILL.md does not carve bundled-script execution out of the three-tier skill-call rule"
  FAILED=$((FAILED + 1))
fi

yellow "[75f] Phase 5 closes once, and the clause that says so is intact"
# Was: the settled-diff exit condition, which policed a review LOOP. The 0.16.0
# round cap removed the loop, so that premise is gone and writing the old phrase
# back would leave a pin green over a doc asserting the opposite. What still
# needs guarding is the cap's hard edge: soften "no second panel" and the loop
# quietly returns with nothing to notice.
RAV="skills/hackify/references/review-and-verify.md"
if grep -qF 'no second panel, no second refuter and no re-scan' "$RAV"; then
  green "  ok   $RAV states the one-panel cap without an escape hatch"
else
  red "  FAIL $RAV missing the no-second-panel clause (softening it silently restores the review loop the cap replaced)"
  FAILED=$((FAILED + 1))
fi

yellow "[75g] refuter defaults to keeping the finding (the shipping-code asymmetry)"
# A refuter tuned to 'default refuted' is right for generated content
# and wrong for shipping code: dropping a real defect costs more than fixing
# a phantom. If this bias inverts, the refuter becomes a finding shredder.
if grep -qiF 'default to keeping the finding' "$REFUTE_TPL"; then
  green "  ok   $REFUTE_TPL defaults to keeping the finding"
else
  red "  FAIL $REFUTE_TPL missing the keep-by-default asymmetry"
  FAILED=$((FAILED + 1))
fi

yellow "[75h] agent mirrors are byte-identical to the canonical source they claim to mirror"
# Every agent file in agents/ asserts "mirrors its fenced block byte-for-byte".
# It said FOUR here for four releases after the set reached nine, and the ninth
# file did not carry the sentence at all until this sprint gave it one. Until
# v0.9.0 the claim was verified by hand (the 0.8.1 release notes say so). A claim
# nothing checks is a claim that drifts, and the mirrors just multiplied.
#
# Extraction: the outer fence is a line of exactly three backticks; the
# OUTPUT report skeletons inside use four, so they never terminate the block.
extract_fenced() {
  awk '/^```$/{n++} n>=1 && n<=2 {print} n==2{exit}' "$1"
}
# "<agent file>|<canonical source>" pairs, read from the sync script so the set
# lives in exactly one place. A second hand-maintained copy here would be the
# very duplication this check exists to catch.
MIRROR_PAIRS=$(python3 scripts/sync_agent_mirrors.py --list 2>/dev/null)
# EMPTINESS WAS THE ONLY THING GUARDED, AND FIVE OF NINE IS NOT EMPTY. Measured:
# drop four tuples from MIRROR_PAIRS and this loop prints five greens, the tail
# branch prints its own, and the whole validator exits 0 on ALL CHECKS PASSED
# with four mirrors covered by neither half.
#
# THE FLOOR COMES FROM agents/ AND THAT IS THE POINT, not a tidier way to write
# 9. A number beside the list is edited by the same hand that shortens the list,
# in the same file, in the same minute. agents/ is a second source: the sync
# script's own docstring says the pair list and the contents of agents/ are the
# same things, so a tuple dropped there leaves a file behind here and the two
# stop agreeing. Adding a tenth agent moves both, and moving only one reds,
# which is the whole behaviour being bought.
#
# Both counts are captured as their own statement. `grep -c` exits 1 on zero
# matches, so folding either into `x=$(...) && ...` reports a real zero as the
# assignment failing. `wc -l` pads on macOS, so the digits are stripped before
# the arithmetic compare rather than after it.
MIRROR_PAIR_TOTAL=$(printf '%s\n' "$MIRROR_PAIRS" | grep -cF '|')
AGENT_FILE_TOTAL=$(find agents -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
if [ -z "$MIRROR_PAIRS" ]; then
  red "  FAIL scripts/sync_agent_mirrors.py --list produced no pairs"
  FAILED=$((FAILED + 1))
elif [ "$MIRROR_PAIR_TOTAL" -ne "$AGENT_FILE_TOTAL" ]; then
  red "  FAIL the mirror pair list covers $MIRROR_PAIR_TOTAL pair(s) against $AGENT_FILE_TOTAL file(s) in agents/; every agent file is a mirror, so the difference is covered by neither half of [75h] and both halves stay green over it"
  FAILED=$((FAILED + 1))
else
  green "  ok   the mirror pair list covers all $AGENT_FILE_TOTAL file(s) in agents/"
fi
while IFS='|' read -r mirror canonical; do
  [ -n "$mirror" ] || continue
  if [ ! -f "$mirror" ] || [ ! -f "$canonical" ]; then
    red "  FAIL mirror pair missing a side: $mirror <-> $canonical"
    FAILED=$((FAILED + 1))
    continue
  fi
  if diff -q <(extract_fenced "$mirror") <(extract_fenced "$canonical") > /dev/null 2>&1; then
    green "  ok   $(basename "$mirror") is byte-identical to $(basename "$canonical")"
  else
    red "  FAIL $mirror drifted from $canonical (the file claims byte-for-byte mirroring)"
    diff <(extract_fenced "$mirror") <(extract_fenced "$canonical") | head -6 | sed 's/^/         /'
    FAILED=$((FAILED + 1))
  fi
done <<MIRROR_EOF
$MIRROR_PAIRS
MIRROR_EOF

# THE FENCED BLOCK IS ONLY HALF OF WHAT A MIRROR CARRIES. Everything after it,
# the OUTPUT skeleton and whatever follows, is hand-maintained on BOTH sides and
# the sync script never copies it, so the loop above is blind to it: a tail could
# drift on both sides and this check still printed nine greens. A planted
# regression proved it.
#
# WHY THIS IS NOT A SECOND diff LOOP. Part of a template's tail is parent-side by
# design (a dispatcher's round procedure, a `## See also` block), so full
# equality reds on a healthy tree, and a bare prefix test passes a mirror that
# lost its whole tail because eight of the nine mirrors carry an empty tail
# legitimately. The template marks where its mirrored region ends and the
# comparison lives in scripts/sync_agent_mirrors.py, over the same split this
# check already reads its pair list from. One implementation, read here rather
# than rewritten in awk.
#
# A CRASH IS NOT DRIFT, AND THIS BRANCH USED TO CALL IT ONE. Delete a fence from
# any mirror and the comparison raises; the traceback landed in $TAIL_REPORT, the
# FAIL grep matched nothing, and the operator was told a tail had drifted and the
# sync script could not fix it, with no detail under it. It failed safe, so the
# cost was only debugging time, but a confident wrong diagnosis spends that time
# in the wrong file. rc alone cannot tell the two apart, since an uncaught Python
# exception also exits 1, so the discriminator is whether the report named any
# drift at all.
#
# AND THE GREEN NAMED NINE MATCHES OVER ONE COMPARISON. Eight of the nine pairs
# owe their mirror an EMPTY tail region, so "every mirror tail matches its
# template up to the parent-side marker" was a ninefold claim with content on one
# pair. The script now prints `none` for a pair it did not compare and ends on a
# summary counting the two kinds apart; this branch quotes that summary instead
# of restating a claim, and counts the verdict lines so a short list cannot exit
# 0 over a comparison that never ran.
#
# The exit code is its own statement, for the reason the pair-count block above
# gives. `grep -F 'FAIL'` carries no `--` guard here and neither does [75e] four
# blocks up: the house rule in this file is that a `--` guard goes on a pattern
# read out of a variable, where a leading `-` is possible, and a literal spelled
# in place cannot be read as an option.
TAIL_REPORT=$(python3 scripts/sync_agent_mirrors.py --check-tails 2>&1)
TAIL_RC=$?
TAIL_VERDICTS=$(printf '%s\n' "$TAIL_REPORT" | grep -cE '^  (ok|none|FAIL) ')
TAIL_FAILS=$(printf '%s\n' "$TAIL_REPORT" | grep -cE '^  FAIL ')
if [ "$TAIL_RC" -ne 0 ] && [ "$TAIL_FAILS" -eq 0 ]; then
  red "  FAIL the mirror tail comparison CRASHED (exit $TAIL_RC) without reporting drift on any pair, so nothing was compared; this is a broken comparison rather than a drifted tail, and hand-carrying text between the mirrors will not fix it"
  printf '%s\n' "$TAIL_REPORT" | tail -6 | sed 's/^/         /'
  FAILED=$((FAILED + 1))
elif [ "$TAIL_RC" -ne 0 ]; then
  red "  FAIL a mirror tail drifted from the canonical tail it must carry (hand-maintained on both sides, the sync script cannot fix it)"
  printf '%s\n' "$TAIL_REPORT" | grep -F 'FAIL' | head -6 | sed 's/^/         /'
  FAILED=$((FAILED + 1))
elif [ "$TAIL_VERDICTS" -ne "$AGENT_FILE_TOTAL" ]; then
  red "  FAIL the mirror tail comparison returned a verdict for $TAIL_VERDICTS pair(s) against $AGENT_FILE_TOTAL file(s) in agents/; it exited 0 over a list shorter than the set it covers, which is a green nobody measured"
  FAILED=$((FAILED + 1))
else
  green "  ok   $TAIL_VERDICTS mirror tail verdict(s) over $AGENT_FILE_TOTAL agent file(s): $(printf '%s\n' "$TAIL_REPORT" | tail -1 | sed 's/^ *//')"
fi

# AND THE HEAD IS THE THIRD REGION, HAND-DUPLICATED PROSE ON ONE PAIR. Above the
# fence each side is its own document, a mirror opening with YAML frontmatter and
# a template with an H1, so there is no mirrored region for a marker to bound and
# both branches above are silent there by construction
# (scripts/sync_agent_mirrors.py, "WHAT THE HEAD IS NOT"). That silence cost
# nothing until the implementer pair began restating the SAME dispatch rule
# in both heads. Measured before this block existed: 1230 characters on the
# mirror against 1276 on the template, already divergent, compared by nothing.
#
# WHY CLAUSES AND NOT A BYTE COMPARE. The two copies differ ON PURPOSE in exactly
# two spans, and both are pointers aimed at different readers: the agent file
# names the runtime agent type it is dispatched by, the template links the
# sibling file a reader opens next. Byte equality would hand one audience the
# other's pointer. So what is pinned is the RULE the duplication exists to state,
# on both sides, and a clause dropped or reworded on either side reds.
#
# HEAD-SCOPED, BECAUSE A WHOLE-FILE GREP WOULD LET THE BLOCK MASK THE HEAD. That
# is the same masking [38d] guards against in the skill descriptions, and one
# clause here already fails that way: "reports which task IDs landed and which
# did not" appears in the mirror's frontmatter too, so it is deliberately NOT in
# the list below. Every clause that IS below was measured at exactly one
# occurrence per file, in the head, on both sides.
head_above_fence() { awk '/^```$/{exit} {print}' "$1"; }
WI_HEAD_FILES='agents/implementer.md
skills/hackify/references/parallel-agents/phase-3-implementation.md'
WI_HEAD_CLAUSES='One agent takes a wave whose tasks share a read surface
no task is ever split off by a module hunch
that test is the only thing that may split a wave
cannot contradict itself across the halves of one feature
the agent stops at the first task it cannot finish
The price is a wider blast radius when a wave stops early'
WI_CLAUSE_TOTAL=$(printf '%s\n' "$WI_HEAD_CLAUSES" | grep -c .)
while IFS= read -r wi_file; do
  [ -n "$wi_file" ] || continue
  if [ ! -f "$wi_file" ]; then
    red "  FAIL $wi_file missing, so the duplicated head prose was never compared"
    FAILED=$((FAILED + 1))
    continue
  fi
  wi_head=$(head_above_fence "$wi_file")
  wi_missing=0
  while IFS= read -r wi_clause; do
    [ -n "$wi_clause" ] || continue
    if ! grep -qF -- "$wi_clause" <<<"$wi_head"; then
      red "  FAIL $wi_file lost the duplicated head clause '$wi_clause'; this pair states the dispatch rule in BOTH heads and nothing else compares them"
      FAILED=$((FAILED + 1))
      wi_missing=1
    fi
  done <<<"$WI_HEAD_CLAUSES"
  if [ "$wi_missing" = "0" ]; then
    green "  ok   $(basename "$wi_file") head carries all $WI_CLAUSE_TOTAL duplicated dispatch-rule clauses"
  fi
done <<<"$WI_HEAD_FILES"

yellow "[75i] orchestration tier + iteration driver + completion sentinel are wired as defaults in every mode"
# `ultracode` and `/loop` became workflow DEFAULTS in v0.9.0, `/goal` joined
# them in v0.9.4. All three are Claude-Code-native tokens, so they live behind
# abstract primitives in runtime-adapters.md rather than in the workflow body.
# Four ways this can silently rot: a mode stops citing the contract, the
# runtime mapping loses one of the native tokens, the standing authorization
# loses its opt-out (which would make a default grant unrevocable), or the
# sentinel drifts from "print a line the user presses" into a claim that the
# workflow sets the goal itself (it cannot, ProposeGoal is absent from most
# sessions and throws in agent contexts).
ORCH_REF="skills/hackify/references/orchestration.md"
ADAPTERS_REF="skills/hackify/references/runtime-adapters.md"

if [ ! -s "$ORCH_REF" ]; then
  red "  FAIL $ORCH_REF missing or empty"
  FAILED=$((FAILED + 1))
else
  green "  ok   $ORCH_REF exists and non-empty"
fi

for m in $SHIP_BAR_MODES; do
  if grep -qF -- 'orchestration.md' "$m"; then
    green "  ok   $m wires the orchestration contract"
  else
    red "  FAIL $m does not cite orchestration.md (tier + iteration driver missing from this mode)"
    FAILED=$((FAILED + 1))
  fi
done

# The native tokens must resolve through the adapter table, not float free.
for tok in 'ultracode' '/loop' '/goal <condition>'; do
  if grep -qF -- "$tok" "$ADAPTERS_REF"; then
    green "  ok   $ADAPTERS_REF maps '$tok' to a primitive"
  else
    red "  FAIL $ADAPTERS_REF does not map '$tok' (Claude Code native token has no primitive home)"
    FAILED=$((FAILED + 1))
  fi
done
for prim in 'orchestration tier' 'iteration driver' 'completion sentinel'; do
  if grep -qF -- "$prim" "$ADAPTERS_REF"; then
    green "  ok   $ADAPTERS_REF declares the '$prim' primitive"
  else
    red "  FAIL $ADAPTERS_REF missing the '$prim' primitive row"
    FAILED=$((FAILED + 1))
  fi
done

# A standing default grant that cannot be revoked is not a default, it is a
# lock-in. Every mode must name at least one opt-out phrase.
for m in $SHIP_BAR_MODES; do
  if grep -qF -- 'light mode' "$m"; then
    green "  ok   $m names the orchestration opt-out"
  else
    red "  FAIL $m does not name an opt-out for the standing ultracode grant"
    FAILED=$((FAILED + 1))
  fi
done

# The completion sentinel must appear in EVERY mode, and it must appear as a
# line the parent PRINTS for the user, never as something the workflow claims
# to set. 'paste-ready' is the honesty token; 'from a subagent' is the
# parent-only fence the runtime enforces by throwing.
for m in $SHIP_BAR_MODES; do
  for tok in '/goal <condition>' 'paste-ready' 'from a subagent'; do
    if grep -qF -- "$tok" "$m"; then
      green "  ok   $m carries the completion sentinel token '$tok'"
    else
      red "  FAIL $m missing '$tok' (completion sentinel not wired, or wired as a claim the parent sets the goal)"
      FAILED=$((FAILED + 1))
    fi
  done
done

# Anchor the instruction to the turn that actually runs it: Phase 2.5, the
# first turn after the Phase 2 gate. It must NOT live under the gate's numbered
# steps, a step placed after a blocking wait is never reached. Matching on
# '/goal <condition>' rather than a bare '/goal' is load-bearing twice over: a
# bare match is satisfied by the file-map row (green on a workflow that never
# prints the line) and by 'references/goal-anchor.md', which is linked twice
# inside this very region and contains that substring.
SENTINEL_REGION="$(awk '/^## Phase 2.5,/{f=1} /^## Phase 3, Implement/{f=0} f' skills/hackify/SKILL.md)"
if printf '%s' "$SENTINEL_REGION" | grep -qF -- '/goal <condition>'; then
  green "  ok   skills/hackify/SKILL.md prints the sentinel inside Phase 2.5 (the post-gate turn)"
else
  red "  FAIL skills/hackify/SKILL.md does not print the '/goal <condition>' line in Phase 2.5; a sentinel placed under the Phase 2 gate's numbered steps is never reached"
  FAILED=$((FAILED + 1))
fi

# Sentinel and iteration driver can disagree; without a stated precedence they
# fight and the token budget loses. The contract must settle it explicitly.
if grep -qF -- 'Precedence, when the sentinel and the driver disagree' "$ORCH_REF"; then
  green "  ok   $ORCH_REF settles sentinel-vs-driver precedence"
else
  red "  FAIL $ORCH_REF does not settle precedence between the completion sentinel and the iteration driver"
  FAILED=$((FAILED + 1))
fi

# The iteration driver must never be pointed at an intra-phase loop.
if grep -qF 'never the iteration driver' "$ORCH_REF"; then
  green "  ok   $ORCH_REF fences the iteration driver out of intra-phase loops"
else
  red "  FAIL $ORCH_REF missing the layer fence (a /loop inside Phase 5 breaks the ledger)"
  FAILED=$((FAILED + 1))
fi

yellow "[75j] question banks obey the wizard-contract Clarity law"
# The banks kept shipping questions the user could not answer without knowing
# hackify's internals (task IDs, phase numbers, DoD, sub-agent). The checker
# splits each bank by audience and polices only the user-facing half, so
# `Why-this-matters` keeps every internal word it needs.
if python3 scripts/check_question_clarity.py > /tmp/hackify-clarity.$$ 2>&1; then
  green "  ok   $(tail -1 /tmp/hackify-clarity.$$)"
else
  red "  FAIL question banks violate the Clarity law:"
  sed 's/^/         /' /tmp/hackify-clarity.$$
  FAILED=$((FAILED + 1))
fi
rm -f /tmp/hackify-clarity.$$

yellow "[75k] wizard contract states the always-wizard rule and the clarity law"
WIZ="skills/hackify/references/clarify-questions/wizard-contract.md"
for tok in 'Clarity law' 'every phase' 'Banned from user-facing text' 'What happens'; do
  if grep -qF -- "$tok" "$WIZ"; then
    green "  ok   $WIZ states '$tok'"
  else
    red "  FAIL $WIZ missing '$tok'"
    FAILED=$((FAILED + 1))
  fi
done

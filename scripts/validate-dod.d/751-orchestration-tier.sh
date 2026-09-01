# shellcheck shell=bash

# [75i] THE ORCHESTRATION-TIER DEFAULTS, split out of 75-ship-bar.sh at the
# 500-LOC cap check [80] enforces, with the check id unmoved.
#
# THE ID STAYED PUT ON THE STANDING RULE, the one 96-review-scope-sites.sh
# followed with [76g]-[76h], 72-diff-slicing-pins.sh with [38e] and [38h], and
# 99-work-doc-status-claims.sh with its two assertion letters: a check id is
# cited from live files and a work-doc, and renumbering it on a file move turns
# every one of those citations into a lie for the sake of a tidier filename.
# Check [91] would catch a citation pointing at an id nothing declares; nothing
# catches one pointing at the WRONG live id, which is what renumbering buys.
#
# WHY THE CUT IS HERE AND NOT SOMEWHERE ELSE IN 75. That file opens by naming
# what [75] is about: FOUR mechanisms that became mandatory in every mode in
# v0.9.0, the law-scout, the ship gate, the coherence reviewer and the refute
# step. This block is about three DIFFERENT primitives, the orchestration tier,
# the iteration driver and the completion sentinel, which became defaults in the
# same release and were filed beside them because they arrived together. Shared
# release, separate responsibility.
#
# WHAT COULD NOT MOVE WITH IT, measured rather than assumed:
# scripts/test_tamper_mirror_tails.py:60 sources 00-helpers.sh plus
# 75-ship-bar.sh ALONE and tampers literals inside [75h], so the agent-mirror
# block is frozen in that file the way the isolation surface freezes symbols in
# 00-helpers.sh. Moving it is a CI break whose message names a missing verdict
# line and not this split.
#
# THE FILE LIST IS WRITTEN OUT HERE rather than read from 75-ship-bar.sh's
# SHIP_BAR_MODES. A fragment reaching into a sibling's variable is a dependency
# no check guards: [0] and [76f] both police the SOURCE LIST and neither knows
# what a fragment reads out of the shell it inherits, so a reordered source line
# would leave this block scanning an empty list under `set -u` or, worse, a stale
# one. Two paths written twice is the cheaper half of that trade.
ORCH_MODES="skills/hackify/SKILL.md skills/quick/SKILL.md"

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

for m in $ORCH_MODES; do
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
for m in $ORCH_MODES; do
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
for m in $ORCH_MODES; do
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

# `[[ == ]]` AND NOT A PIPE INTO `grep -q`, which is what check [84] bans and
# what this line used to be. $SENTINEL_REGION is an awk region rather than a
# whole file, so it never grew past the smallest pipe buffer and never actually
# flaked; it is converted anyway so the ban has nothing to except and no reader
# copies the shape from here. The marker is newline-free, so a whole-string
# substring test and grep -F's per-line one agree on every input.
if [[ "$SENTINEL_REGION" == *'/goal <condition>'* ]]; then
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

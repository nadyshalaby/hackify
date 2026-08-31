# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [83] TESTING-STAGE SHAPE. The stage-shape rule three comments already cited
# before it was written. 00-helpers.sh and 82-throughput-and-routing.sh both
# pointed at an id `[82h]`, and no fragment ever declared one: fragment 82
# declares [82] and [82b] through [82g] and stops. Check [91] resolves a claim
# only when the literal word `check` or `checks` plus one space precedes the
# bracket (91-claim-resolvers.sh:48), and all three sites wrote a bare `[82h]`,
# so the fabricated id sat in the tree with the resolver looking straight past
# it. This file is the check those comments promised; the citations now name
# `check [83]` so [91] reads them.
#
# WHY IT IS NOT LINES IN 82. 82-throughput-and-routing.sh sits at 495 lines
# against the 500-LOC cap [80] enforces, which is room for neither these blocks
# nor the comments that make them readable, and its own header gives that same
# reason for existing apart from 71. THE NUMBER IN THE FILENAME MATTERS for the
# reason 82's header records: [0] in scripts/validate-dod.sh and [76f]/[76i] in
# 76-phase-ledger-substrate.sh all parse a fragment name with `[0-9]+-`, so a
# letter suffix is safe in a CHECK id and fatal in a FRAGMENT name. AND THE
# CHECK IS NAMED [83] AND NOT [82h] for a second reason on top: [76i] requires a
# fragment's header row to open at its lowest declared id and close at its
# highest, so an `[82h]` living in a file named 83- would either break 82's row
# or claim a range 83 does not hold.
#
# WHAT ROTS, AND IT ALREADY DID ONCE. The testing stage is SPLITTABLE: a stage
# whose count exceeds the per-agent budget dispatches as concurrent testing
# waves, one agent each, judged by the same partition test every other stage
# takes. The implementer contract nevertheless told a `test-authoring` wave it
# was "dispatched once", that "the tree is quiet with nothing else writing it",
# and that its subject was "the round's whole diff rather than one module". All
# three are false under a split stage, and the middle one is the dangerous one:
# clauses (a) and (b) of that same contract REQUIRE breaking a production line
# to manufacture a watched red, and a break is only safe while nothing else is
# reading that file. A wave handed that permission and a sibling at the same
# time corrupts the sibling's tree with nothing at either end noticing.
#
# IT SURVIVED THE SPRINT'S OWN PINS, which is why this block exists rather than
# a token added to an existing list. [82c]'s batched screen bans the literal
# `solo testing wave` over nine documents; this paragraph said exactly that in
# different words and every check in the tree stayed green over it.
#
# BOTH MIRROR COPIES OR NEITHER. The contract ships twice: the canonical
# template every non-Claude-Code runtime dispatches from, and agents/
# implementer.md, the copy Claude Code registers and actually runs. [75h]
# already proves the two fenced blocks are byte-identical, so pinning one side
# would in practice reach both; the pair is written out anyway, because [75h]
# proving they AGREE says nothing about what they agree ON, and a rewrite that
# lands in both copies at once is exactly the drift this pins.
#
# EVERY MATCH HERE IS FLATTENED FIRST, ON BOTH SIDES, and that is the whole
# design of this file. The pinned prose is markdown wrapped to a column, so
# every sentence below straddles a line break in the file that carries it and
# every line-oriented matcher in this validator returns a confident zero on it.
# 00-helpers.sh's check_flowed_token_present covers the PRESENCE half and is
# used as-is. It has no ABSENCE twin, and its comment explains why: on the
# presence side a wrapped token is a false RED, which is loud, while on the
# absence side it is a false GREEN, which is silent. That trade is acceptable
# for a short literal and unacceptable here, where every banned string is a full
# retired sentence and would straddle a wrap the moment it came back. So the
# absence half is flattened too, by tss_absent below.
yellow "[83] the testing wave's tree assumption is conditional on {{sibling_tracks}}, on both mirror copies"

TSS_CANON="skills/hackify/references/parallel-agents/phase-3-implementation.md"
TSS_MIRROR="agents/implementer.md"
TSS_CONTENTION="skills/hackify/references/contention-dispatch.md"

# 0 the token is present, 1 it is absent, 2 the path could not be read. The
# status is RETURNED rather than judged, because two callers want opposite
# verdicts from it and one of them is a control that must not move FAILED.
#
# NO PIPE INTO grep, for the reason check_flowed_token_present states about the
# same construct: callers run under `set -o pipefail`, `grep -q` exits on the
# first match, and the pipeline would report tr's SIGPIPE instead of grep's own
# status. The flattening lands in a variable and the match is a herestring.
# /usr/bin/grep and not `grep`, on this repo's standing rule that a shimmed
# matcher on PATH can silently skip paths.
tss_flowed_hit() {
  local token="$1"
  local path="$2"
  local flat
  [ -r "$path" ] || return 2
  flat=$(tr -s '[:space:]' ' ' < "$path")
  /usr/bin/grep -qF -- "$token" <<<"$flat"
}

# THE CONSEQUENCE IS A PARAMETER AND NOT A CONSTANT, because this function
# screens two different documents. Baking the mirror pair's consequence into the
# message made the contention-dispatch finding read as a claim about the
# implementer contract, which is a red that misnames its own defect.
tss_absent() {
  local token="$1"
  local path="$2"
  local why="$3"
  tss_flowed_hit "$token" "$path"
  case $? in
    1) green "  ok   retired wording '$token' has 0 occurrences in $path, line wrapping flattened first" ;;
    0) red "  FAIL retired wording '$token' is back in $path: $why"
       FAILED=$((FAILED + 1)) ;;
    *) red "  FAIL '$token' was never screened, $path is missing or unreadable; a miss here would be a miss of nothing"
       FAILED=$((FAILED + 1)) ;;
  esac
}

# THE TWO CONTROLS RUN BEFORE ANY VERDICT, on the tie-break 55, 73 and 91 all
# make: a scan that cannot be trusted names itself and says nothing about what
# it read. A matcher that finds nothing prints the whole ban list green having
# measured nothing, and a matcher that cannot tell a missing file from a clean
# one prints the same wall after a rename. Neither control moves FAILED through
# tss_absent, so a broken matcher reddens here once instead of lying below.
TSS_CONTROL_TOKEN='What you may assume about the tree is set by'
tss_flowed_hit "$TSS_CONTROL_TOKEN" "$TSS_CANON"
if [ $? -eq 0 ]; then
  green "  ok   [83] positive control, the flattened matcher finds a phrase that is really in $TSS_CANON"
else
  red "  FAIL [83] positive control, the flattened matcher found nothing in $TSS_CANON; either the matcher broke, in which case every absence below was measured by a matcher that finds nothing, or the conditional sentence was removed, which the pin below names"
  FAILED=$((FAILED + 1))
fi
tss_flowed_hit 'anything at all' "$TSS_CANON.no-such-file"
if [ $? -eq 2 ]; then
  green "  ok   [83] fail-closed control, an unreadable path is reported rather than read as a clean file"
else
  red "  FAIL [83] fail-closed control, an unreadable path did not report status 2, so a renamed or deleted file would print every ban green"
  FAILED=$((FAILED + 1))
fi

# THE LIVE HALF. Four sentences, and each one is a different half of the rule,
# so losing any one of them is a different regression:
#   1. the assumption is CONDITIONAL and the input that decides it is named;
#   2. the `none` branch still grants the quiet tree and the whole-round subject;
#   3. the split branch names the siblings and narrows the subject to a slice;
#   4. the mutation window is bounded by the wave's own allowlist, which is what
#      makes clause (a)'s manufactured red safe on a stage that split.
TSS_SHAPE_PINS=('What you may assume about the tree is set by')
TSS_SHAPE_PINS+=('nothing else is writing it and your subject is the round')
TSS_SHAPE_PINS+=('Named IDs mean the stage SPLIT: sibling testing waves are writing it now')
TSS_SHAPE_PINS+=('a line you break must be in YOUR allowlist or you leave it alone.')
check_list_size "${#TSS_SHAPE_PINS[@]}" 4 "the [83] conditional-assumption pin list"

# THE DEAD HALF, on 82's own two-sided rule: a pin alone goes green on a file
# that carries the live wording and the retired wording at once, which is the
# state this repo has actually shipped. Four sentences: the retired identity,
# the retired dispatch cadence, the retired quiet tree, the retired subject.
TSS_SHAPE_BANS=('dispatched once, after every implementation wave in the round has landed')
TSS_SHAPE_BANS+=('the tree is quiet with nothing else writing it')
TSS_SHAPE_BANS+=('whole diff rather than one module')
TSS_SHAPE_BANS+=('You are THE TESTING WAVE')
check_list_size "${#TSS_SHAPE_BANS[@]}" 4 "the [83] retired solo-assumption ban list"

TSS_MIRROR_PAIR=("$TSS_CANON" "$TSS_MIRROR")
check_list_size "${#TSS_MIRROR_PAIR[@]}" 2 "the [83] implementer mirror-pair list"
for tss_f in "${TSS_MIRROR_PAIR[@]}"; do
  for tss_t in "${TSS_SHAPE_PINS[@]}"; do
    check_flowed_token_present "$tss_t" "$tss_f"
  done
  for tss_t in "${TSS_SHAPE_BANS[@]}"; do
    tss_absent "$tss_t" "$tss_f" "the testing wave is told again that it owns the tree, so a wave on a stage that split would break a production line a sibling is reading"
  done
done

# THE PARTITION THE SPLIT IS DRAWN OVER, pinned here rather than in its own
# check because it is the same rule seen from the dispatcher's end. A testing
# wave writes its test files AND every production file it mutates for a watched
# red, so a union drawn over test files alone calls two subsets partitionable
# while they collide on a shared production file. The ban is the retired
# sentence's own tail, which read `the stage would write. There is no fourth`;
# the live text now continues `... would write AND the production files ...`,
# so the two cannot both be true of one file.
check_flowed_token_present 'the production files it would mutate for a watched red' "$TSS_CONTENTION"
tss_absent 'the stage would write. There is no fourth' "$TSS_CONTENTION" "the partition is drawn over test files alone again, so two testing waves that share a production file would be declared partitionable"

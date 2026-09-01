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
# 01-presence-matchers.sh's flowed pair covers the PRESENCE half, and
# check_no_flowed_token now covers the ABSENCE half it once declined to build.
# THIS FILE USED TO CARRY ITS OWN COPY OF BOTH, because neither shared twin
# existed when it shipped; the local flattener is gone and the local verdict is
# a two-line annotation over the shared one. That is what makes the control
# below worth running at all: it now exercises the matcher the whole validator
# bans with, not a private copy that could pass while the real one broke.
yellow "[83] the testing wave's tree assumption is conditional on {{sibling_tracks}}, on both mirror copies"

TSS_CANON="skills/hackify/references/parallel-agents/phase-3-implementation.md"
TSS_MIRROR="agents/implementer.md"
TSS_CONTENTION="skills/hackify/references/contention-dispatch.md"

# A CONTROL MUST NOT MOVE FAILED, and check_no_flowed_token judges rather than
# reports: it prints a verdict and raises FAILED on a hit. That is precisely the
# behaviour a control needs to OBSERVE and precisely what it must not leave
# behind. So the counter is read, the shared matcher is called with its printing
# swallowed, and the counter is restored whatever happened. Returns 0 when the
# shared matcher reddened and 1 when it did not.
#
# THE SHIPPED MATCHER IS WHAT IS UNDER TEST, which is the whole reason the
# control is routed through it. The control this replaces drove a local
# flattener, so it could only ever prove the local copy worked, and a break in
# the matcher the bans actually run would have left it printing green. Only the
# printing is swallowed: FAILED is put back from a value read before the call, so
# this can neither raise a red of its own nor mask one raised anywhere else.
#
# THE READ, SWALLOW, RESTORE SHAPE IS control_delta IN 00-helpers.sh, written once
# for the three fragments that each had a copy of it. This one wants a yes/no
# rather than a count, so it reads CONTROL_DELTA and returns; [87] and [88] keep
# the number because their plants owe a known one.
tss_control_red() {
  local token="$1"
  local path="$2"
  control_delta check_no_flowed_token "$token" "$path"
  [ "$CONTROL_DELTA" -gt 0 ]
}

# THE CONSEQUENCE IS A PARAMETER AND NOT A CONSTANT, because this function
# screens two different documents. Baking the mirror pair's consequence into the
# message made the contention-dispatch finding read as a claim about the
# implementer contract, which is a red that misnames its own defect. THAT, AND
# ONLY THAT, IS WHY THIS WRAPPER OUTLIVED THE SHARED MATCHER LANDING. The
# flattening, the matching, the verdict wording and the fail-closed branch are
# all check_no_flowed_token's now; the two lines below add the one thing a
# generic helper cannot know, which is what breaks when THIS token comes back.
tss_absent() {
  local token="$1"
  local path="$2"
  local why="$3"
  local before="$FAILED"
  check_no_flowed_token "$token" "$path"
  [ "$FAILED" -gt "$before" ] && red "         consequence: $why"
  return 0
}

# THE TWO CONTROLS RUN BEFORE ANY VERDICT, on the tie-break 55, 73 and 91 all
# make: a scan that cannot be trusted names itself and says nothing about what
# it read. A matcher that finds nothing prints the whole ban list green having
# measured nothing, and a matcher that cannot tell a missing file from a clean
# one prints the same wall after a rename. Neither control moves FAILED, so a
# broken matcher reddens here once instead of lying below.
TSS_CONTROL_TOKEN='What you may assume about the tree is set by'
if tss_control_red "$TSS_CONTROL_TOKEN" "$TSS_CANON"; then
  green "  ok   [83] positive control, the shared flattened matcher finds a phrase that is really in $TSS_CANON"
else
  red "  FAIL [83] positive control, the shared flattened matcher found nothing in $TSS_CANON; either the matcher broke, in which case every absence below was measured by a matcher that finds nothing, or the conditional sentence was removed, which the pin below names"
  FAILED=$((FAILED + 1))
fi
if tss_control_red 'anything at all' "$TSS_CANON.no-such-file"; then
  green "  ok   [83] fail-closed control, an unreadable path is reported rather than read as a clean file"
else
  red "  FAIL [83] fail-closed control, an unreadable path did not redden, so a renamed or deleted file would print every ban green"
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
  check_flowed_tokens_present_in "$tss_f" "${TSS_SHAPE_PINS[@]}"
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

# THE OTHER END OF THAT SAME PARTITION, AND IT IS WHERE THE ROUND'S ONLY CRITICAL
# LIVED. contention-dispatch.md states the rule; the spec reviewer is what draws
# the union in practice, and its step 10(iv) drew it over the test files ALONE.
# Two testing waves whose test files are disjoint still collide on a production
# file they each break for a watched red, so that union called a colliding pair
# partitionable and the dispatcher would have run them side by side. The fix
# landed in both copies and NOTHING SCREENED EITHER OF THEM: the pair is named by
# [82f], for one token, and by nothing else in the validator, so the same edit
# could be reverted tomorrow with the whole bar green over it.
#
# THE RETIRED TAIL IS THE BAN, NOT THE WHOLE SENTENCE. What was removed read
# `the union of the test files it would write. Under`, wrapped across two physical
# lines in both copies. The live text continues `... it would write AND the
# production files ...`, so the ban and the pin cannot both hold of one file: a
# revert restores that tail and reddens, and a half-revert that keeps the pin
# while restoring the tail reddens too, which is the state a pin alone misses.
#
# BOTH COPIES, for the reason the mirror pair above gives. [75h] proves the two
# fenced blocks agree; it says nothing about what they agree ON, and this defect
# shipped identically in both.
TSS_SPEC_REVIEWERS=("agents/spec-reviewer.md")
TSS_SPEC_REVIEWERS+=("skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md")
check_list_size "${#TSS_SPEC_REVIEWERS[@]}" 2 "the [83] spec-reviewer copy list"
for tss_f in "${TSS_SPEC_REVIEWERS[@]}"; do
  check_flowed_token_present 'the production files it would mutate for a watched red' "$tss_f"
  tss_absent 'the union of the test files it would write. Under' "$tss_f" "the spec reviewer draws the testing-stage partition over test files alone again, so it would report two testing waves partitionable while they collide on a production file each one breaks for a watched red"
done

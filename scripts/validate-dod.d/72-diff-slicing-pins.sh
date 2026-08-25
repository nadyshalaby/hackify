# shellcheck shell=bash

# DIFF-SLICING AND SETTLE-ECHO PINS, split out of 71-release-mechanism-pins.sh
# in the sprint that file reached 497 lines against the 500-LOC hard cap that
# check [80] enforces. [38e] and [38h] came across whole and kept their check
# IDs, the way [38c], [38d], [38g], [38f] and [38e] kept theirs when 71 was
# itself carved out of 70-invariants-and-new.sh. A fragment is free to move; a
# check ID that CHANGELOG.md, a work-doc or another block cites is not.
#
# THE SEAM IS THE SAVING BEING GUARDED. 71 keeps the pins on the v0.11.0 token
# reduction, on the routing triggers, and on the v0.13.0 agent merge. Both
# blocks here guard ONE saving, the v0.11.0 diff slicing and the carry-over that
# rides on it: [38e] pins the mechanism, and [38h] pins the FILE SET that
# mechanism is stated over, so a new site cannot join the settle-echo contract
# unnoticed. [38h]'s own comment already said it sat beside [38e] because that
# is the block it guards, so the two travelled together.
#
# THE CUT POINT WAS CHOSEN, NOT TAKEN AT THE MIDPOINT. 91-claim-resolvers.sh
# cites 71-release-mechanism-pins.sh:287 and reads lines 283 to 293 of that file
# as a comment block, and [57] opens a cited file and checks that the line is
# really there. Cutting at [38f] would have left 71 at 269 lines and turned a
# live citation into a dangling one. Cutting at [38e] instead leaves every line
# 71 keeps at the number it already had.
#
# THREE PATHS ARE RE-DECLARED HERE, NOT INHERITED, and 71 makes the argument for
# that above its own INJECT_PY. Today's source order would carry P5_REVIEW,
# WORK_DOC_TPL and PA across from 71, and leaning on it would make this file
# depend on the ORDER of two lines in validate-dod.sh, which is the thing the
# next split reorders. Three assignments cost less than an undeclared
# cross-fragment dependency that nothing pins.
P5_REVIEW="skills/hackify/references/phases/phase-5-review.md"
WORK_DOC_TPL="skills/hackify/references/work-doc-template.md"
PA="skills/hackify/references/parallel-agents"

yellow "[38e] the v0.11.0 diff-slicing and carry-over changes keep their mechanism"
# Same discipline as [38c]. Each of these is a token saving that becomes a
# silent LOSS of review coverage the moment its mechanism drifts out while the
# prose promising it stays. Pin every one to the artifact that carries it.

SCOPE_REF="skills/hackify/references/review-scope.md"
RAV_REF="skills/hackify/references/review-and-verify.md"

# (1) The four sliced reviewers take {{review_scope}}, in BOTH copies of each
# prompt. A reviewer that never learned to scope its diff silently ignores the
# input, which costs tokens but keeps coverage; the real risk is the reverse,
# so the pairing is what is checked. It was five until v0.13.0 folded Reviewer C
# into B, and C's lens gave up slicing in the move because B is never sliced.
for f in "agents/code-reviewer-security.md" \
         "agents/code-reviewer-performance.md" "agents/design-conformance-reviewer.md" \
         "agents/code-reviewer-coherence.md" \
         "$PA/phase-5-multi-review-a-security.md" "$PA/phase-5-multi-review-d-performance.md" \
         "$PA/phase-5-multi-review-e-design.md" "$PA/phase-5-multi-review-f-coherence.md"; do
  check_token_present '{{review_scope}}' "$f"
done

# (2) Reviewer B is NEVER sliced. B applies the semantic tier to every touched
# file and re-judges every law-scout row, so any subset withheld from B is
# coverage deleted outright. Both copies of B's prompt must stay scope-free.
for f in "agents/code-reviewer-quality-plan.md" "$PA/phase-5-multi-review-b-quality-plan.md"; do
  if grep -qF '{{review_scope}}' "$f" 2>/dev/null; then
    red "  FAIL $f takes {{review_scope}}, Reviewer B must never be sliced"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f is not sliced (correct, B reads every touched file)"
  fi
  check_token_present '{{metrics_table}}' "$f"
done

# (3) The scope grammar and the carry-over rules live in ONE file, so the A
# block and the C block cannot drift apart on what `settle ` means.
check_file "$SCOPE_REF"
check_token_present 'settle all' "$SCOPE_REF"
check_token_present 'F never carries over' "$SCOPE_REF"

# (4) Carry-over is keyed on the BLOB HASH, never the path. A path-keyed ledger
# would carry a verdict across a file that changed twice in one sprint, which
# is a clean round over content no reviewer ever read.
check_token_present 'git rev-parse' "$SCOPE_REF"
check_token_present 'git rev-parse HEAD:<path>' "$P5_REVIEW"

# (5) An unclassifiable file defaults to B, so slicing can never leave a path
# uncovered, and a lens with an empty slice is a written-down gate decision.
check_token_present 'goes to B' "$P5_REVIEW"
check_token_present 'B is never sliced' "$P5_REVIEW"

# (6) A FULL round is now "every byte covered by a live verdict", not "the
# panel re-read everything". The settle prefix is what makes a carried-over
# round distinguishable from one the dispatcher never scoped at all.
check_token_present 'settle ' "$P5_REVIEW"
check_token_present 'settle all' "$RAV_REF"

# (6b) BOTH new dispatcher inputs have a PRODUCER, not just a consumer. This is
# the defect class the {{repo_brief}} work hit in 0.11.0: prose requires an
# artifact, every reviewer is told to read it, and nothing anywhere builds it.
# {{review_scope}}'s producer is the work-doc's scope ledger; {{metrics_table}}'s
# is the recipe in the dispatcher protocol. Without them the saving never fires
# (metrics, which degrades to `unavailable`) or the carry-over rule becomes
# uncheckable (scope, which is coverage).
check_token_present '### Scope ledger (Phase 5)' "$WORK_DOC_TPL"
check_token_present 'git rev-parse HEAD:<path>' "$WORK_DOC_TPL"
check_token_present 'Build `{{metrics_table}}` before you dispatch B' "$P5_REVIEW"
check_token_present 'max-lines-per-function' "$P5_REVIEW"
check_token_present 'unavailable' "$P5_REVIEW"

# (7) The Phase 6 report is rendered from JSON, never typed out by hand.
check_file "skills/hackify/scripts/render-report.py"
check_token_present 'Do not hand-write the HTML' "skills/hackify/references/html-report.md"
check_token_present 'render-report.py' "skills/hackify/references/finish.md"

yellow "[38h] the settle-echo contract's FILE SET, so a new site cannot join it unnoticed"
# WHAT THIS CATCHES AND WHAT IT DOES NOT, stated first, because a check whose comment
# overstates its reach is the defect class this sprint spent itself on.
#
# [76h] pins the FULL-round gate sentence BYTE FOR BYTE at the four files that state it,
# so those four cannot drift apart. It is blind to a FIFTH file stating the same rule in
# NEW WORDS, and that blindness is not hypothetical: three sites carried the pre-amendment
# rule in three different phrasings, a grep on the literal found four of the six sites
# that existed, and a person reading the file found the other two.
#
# THIS CLOSES ONE HALF OF THAT GAP AND ONLY ONE HALF. It counts the FILES under skills/
# and agents/ mentioning the settle prefix at all, so a NEW FILE joining the contract
# reddens until someone consciously adds it to the total. It does NOT catch a second,
# differently worded statement inside a file ALREADY in the set. Both sites that broke
# this sprint were of that second kind: review-scope.md and phases/phase-5-review.md were
# already in the set and neither offending sentence carried the marker, so this number
# would not have moved by one. Nothing mechanical catches that case at a cost worth
# paying; a reader catches it, and saying so here is cheaper than a later maintainer
# assuming it was covered.
#
# IT LIVES BESIDE [38e] BECAUSE THAT IS THE BLOCK IT GUARDS. [38e] pins the diff-slicing
# and carry-over mechanism, `settle all` and `F never carries over` included, in these
# same files. This is the same saving's file set, one layer out.
#
# THE MARKER WAS CHOSEN BY MEASUREMENT, not taste. The backticked prefix discovers
# exactly the twelve files in the contract: four sliced reviewer prompts, their four
# agents/ mirrors, and the four docs that state the rule. The obvious alternative, the
# `Scope: ` echo token, is worse at both ends, dragging in
# skills/lawkeeper/assets/report-template.md while missing all three docs that went stale.
#
# THE FILE COUNT FAILS, THE OCCURRENCE COUNT ONLY NOTES, and that asymmetry is the design
# rather than an oversight to tidy into a second hard pin. The file count moves only when
# a file joins or leaves the contract, which always deserves a human decision. The
# occurrence total moves whenever anyone rewords a prompt and happens to say the prefix
# once more, which is noise, and a check that cries wolf gets its expected number bumped
# without thought. Two pins in this repo went vacuous exactly that way earlier in this
# sprint. KNOWN HOLE, left open on purpose and written down: a site deleted INSIDE a file
# that keeps its other mentions passes here, because the file total does not move and the
# occurrence total only notes.
#
# A SECOND HOLE SITS BESIDE IT, and neither half of this check is a backstop for it. The
# echo contract has two halves: the INSTRUCTION half, carrying both marks this check
# counts, in the INPUTS block; and the SKELETON half, the `Scope: ` line in the OUTPUT
# block the echo lands on, carrying NO mark, in all eight files that state it, the four
# sliced prompts and their four agents/ mirrors. Deleting a skeleton line therefore moves
# NEITHER number: the file keeps its two instruction marks so the file count stays 12 and
# never reddens, and the deleted line held no mark so the occurrence total stays 25 and
# does not even note. Nothing in this validator pins that line today, so it would vanish
# green. Closing it wants its own pin on the skeleton line, the both-halves shape [76h]
# already argues for and applies to B's round marker, not a hard total here, and that
# decision has not been taken.
#
# grep -oF and -rlIF, never -c and never -E, and absolute /usr/bin/grep: the three reasons
# argued above [76g] all bite here. -c counts LINES, and phase-5-review.md carries two
# occurrences on one line today, so -c reads this set as 24 rather than 25.
RSE_MARK='`settle `'
RSE_ROOTS="skills agents"
# Hand-written beside the check and independent of the list it polices, per the argument
# above check_list_size in 00-helpers.sh. Today: 12 files, 25 occurrences (eight prompt
# files at 2 each, phase-5-review.md 4, review-scope.md 3, SKILL.md and
# review-and-verify.md 1 each).
RSE_FILES_EXPECTED=12
RSE_OCCUR_TODAY=25
rse_files=$(/usr/bin/grep -rlIF -- "$RSE_MARK" $RSE_ROOTS 2>/dev/null); rse_rcf=$?
rse_occs=$(/usr/bin/grep -roIF -- "$RSE_MARK" $RSE_ROOTS 2>/dev/null); rse_rco=$?
if [ "$rse_rcf" -gt 1 ] || [ "$rse_rco" -gt 1 ]; then
  red "  FAIL [38h] could not scan $RSE_ROOTS for '$RSE_MARK' (grep exited $rse_rcf then $rse_rco), so a count of 0 here would be a count of nothing"
  FAILED=$((FAILED + 1))
else
  rse_nf=0; rse_no=0
  [ -n "$rse_files" ] && rse_nf=$(printf '%s\n' "$rse_files" | wc -l | tr -d ' ')
  [ -n "$rse_occs" ] && rse_no=$(printf '%s\n' "$rse_occs" | wc -l | tr -d ' ')
  check_list_size "$rse_nf" "$RSE_FILES_EXPECTED" "the files under $RSE_ROOTS in the settle-echo contract"
  if [ "$rse_no" -eq "$RSE_OCCUR_TODAY" ]; then
    green "  ok   '$RSE_MARK' sits at $rse_no occurrences, unchanged (advisory, this half never fails)"
  else
    yellow "  note '$RSE_MARK' moved to $rse_no occurrences from the $RSE_OCCUR_TODAY recorded here; advisory by design, update it once you have looked at why"
  fi
  if [ "$rse_nf" -ne "$RSE_FILES_EXPECTED" ]; then
    red "  ---- the $rse_nf discovered file(s) were:"
    printf '%s\n' "$rse_files" | sed 's/^/        /'
  fi
fi

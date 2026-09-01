# shellcheck shell=bash

# DIFF-SLICING, SETTLE-ECHO AND PUBLISH-CONTRACT PINS, split out of
# 71-release-mechanism-pins.sh in the sprint that file reached 497 lines against
# the 500-LOC hard cap that check [80] enforces. [38e] and [38h] came across
# whole and kept their check IDs, the way [38c], [38d], [38g], [38f] and [38e]
# kept theirs when 71 was itself carved out of 70-invariants-and-new.sh. A
# fragment is free to move; a check ID that CHANGELOG.md, a work-doc or another
# block cites is not.
#
# THE SEAM IS THE SAVING BEING GUARDED. 71 keeps the pins on the v0.11.0 token
# reduction, on the routing triggers, and on the v0.13.0 agent merge. [38e] and
# [38h] guard ONE saving between them, the v0.11.0 diff slicing and the
# carry-over that rides on it: [38e] pins the mechanism, and [38h] pins the FILE
# SET that mechanism is stated over, so a new site cannot join the settle-echo
# contract unnoticed. [38h]'s own comment already said it sat beside [38e]
# because that is the block it guards, so the two travelled together.
#
# [38j] IS THE SECOND SAVING, AND IT USED TO BE FILED UNDER THE FIRST. The Phase
# 6 hand-off pins landed inside [38e] as its block (7), where the transcript line
# a reader actually sees announced "the v0.11.0 diff-slicing and carry-over
# changes" over four pins about publishing the work-doc as a page. Both index
# rows, scripts/validate-dod.sh and scripts/validate-dod.d/README.md, described
# this fragment as diff-slicing plus settle-echo and were right about the
# fragment while [38e] was wrong about itself. Giving the publish contract its own
# id fixes the half a reader reads, and the rows then only had to gain a third
# name rather than a third subject. A SEPARATE FRAGMENT WAS THE OTHER CANDIDATE
# and was refused on a measured cost, not a taste: scripts/test_ban_tokens.d/
# 40-fragment-coverage.sh pins the directory total by hand at 47, deliberately as
# an equality and not a floor, so a 48th fragment reddens the ban-token suite
# until that number is bumped in the same change. A check id costs nothing there
# and buys the same honesty in the transcript.
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
for f in "agents/reviewer-security.md" \
         "agents/reviewer-performance.md" "agents/reviewer-design.md" \
         "agents/reviewer-coherence.md" \
         "$PA/phase-5-multi-review-a-security.md" "$PA/phase-5-multi-review-d-performance.md" \
         "$PA/phase-5-multi-review-e-design.md" "$PA/phase-5-multi-review-f-coherence.md"; do
  check_token_present '{{review_scope}}' "$f"
done

# (2) Reviewer B is NEVER sliced. B applies the semantic tier to every touched
# file and re-judges every law-scout row, so any subset withheld from B is
# coverage deleted outright. Both copies of B's prompt must stay scope-free.
#
# /usr/bin/grep BY ABSOLUTE PATH, and this is the direction where it is load
# bearing rather than tidy. THIS TEST IS AN ABSENCE CHECK WEARING A PRESENCE
# CHECK'S SHAPE: the green branch is the one grep takes when it finds NOTHING, so
# a matcher that skipped the file entirely would print "is not sliced (correct)"
# over a prompt it never opened, which is the false pass check_no_token's own
# comment in 00-helpers.sh was written about. It reads bare `grep` for the whole
# life of this block by inheritance from a presence-shaped idiom, and under the
# bash the validator runs in that resolved to the same binary, so nothing was ever
# wrong on this machine. Under the interactive zsh here, bare `grep` is a function
# honouring ignore files, and this is the one call site in this fragment where that
# buys a clear verdict instead of a loud red.
for f in "agents/reviewer-quality-plan.md" "$PA/phase-5-multi-review-b-quality-plan.md"; do
  if /usr/bin/grep -qF '{{review_scope}}' "$f" 2>/dev/null; then
    red "  FAIL $f takes {{review_scope}}, Reviewer B must never be sliced"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f is not sliced (correct, B reads every touched file)"
  fi
  check_token_present '{{metrics_table}}' "$f"
done

# (3) The scope grammar lives in ONE file, so no two reviewer prompts can drift
# apart on what a scope value means. The carry-over half of this pin retired in
# 0.16.0 with the round cap: nothing carries when the panel runs once. What is
# pinned instead is the half that is still coverage rather than cost, the
# unconditional exclusion append. A resolver that treats it as optional hands a
# lens the work-doc to grade, which is the loop [76g] exists to refuse.
check_file "$SCOPE_REF"
check_token_present 'It is one of two forms' "$SCOPE_REF"
check_token_present 'the append is never optional' "$SCOPE_REF"

# (4) The scope ledger is ONE ROW PER CHANGED PATH, in both files that state
# it. It used to be keyed on a blob hash as well, because a verdict could carry
# from one round into the next; the round cap removed the carry and the hash
# with it. The row-per-path shape is what survives, and it is the whole of what
# makes "every file was covered" checkable rather than asserted.
check_token_present 'One row per changed path' "$SCOPE_REF"
check_token_present 'One row per changed path' "$WORK_DOC_TPL"

# (5) An unclassifiable file defaults to B, so slicing can never leave a path
# uncovered, and a lens with an empty slice is a written-down gate decision.
check_token_present 'goes to B' "$P5_REVIEW"
check_token_present 'B is never sliced' "$P5_REVIEW"

# (6) The address-all loop's exit lives in review-and-verify.md and is stated in
# the phase file too. Both used to describe a settle round; both now describe the
# cap. [76h] pins the cap sentence itself across all four sites, so what is
# pinned here is that this file's own loop still HAS a closing step rather than
# trailing off after the fixes.
check_token_present 'Close the phase, once.' "$RAV_REF"

# (6b) BOTH new dispatcher inputs have a PRODUCER, not just a consumer. This is
# the defect class the {{repo_brief}} work hit in 0.11.0: prose requires an
# artifact, every reviewer is told to read it, and nothing anywhere builds it.
# {{review_scope}}'s producer is the work-doc's scope ledger; {{metrics_table}}'s
# is the recipe in the dispatcher protocol. Without them the saving never fires
# (metrics, which degrades to `unavailable`) or coverage becomes uncheckable
# (scope, whose ledger is the only record of which lens read which path).
check_token_present '### Scope ledger (Phase 5)' "$WORK_DOC_TPL"
check_token_present 'Build `{{metrics_table}}` before you dispatch B' "$P5_REVIEW"
check_token_present 'max-lines-per-function' "$P5_REVIEW"
check_token_present 'unavailable' "$P5_REVIEW"

yellow "[38h] the retired round vocabulary is gone, proved against a positive control"
# WHAT THIS CATCHES AND WHAT IT DOES NOT, stated first, because a check whose comment
# overstates its reach is the defect class the sprint before this one spent itself on.
#
# WHAT IT REPLACED. Until 0.16.0 this block counted the FILES under skills/ and agents/
# carrying the settle-echo marker and reddened when that total moved, so a new site could
# not join the contract unnoticed. The round cap deleted the contract outright: one panel,
# one refuter, no settle round, nothing to echo a round prefix into. A count pinned at 12
# would have had to become a count pinned at 0, and `check_list_size 0 0` passes over an
# empty set while measuring nothing, which is the vacuous pass every block in this
# directory refuses. So the count became a BAN, and the ban brought the vacuous-pass
# problem with it: a ban that matches nothing looks identical to a ban whose scan never
# ran. That is what the positive control below is for.
#
# THE SHAPE. Two scans, same roots, same grep. The BANNED set must come back empty. The
# CONTROL, a literal known to be present because [76h] pins it at four sites, must come
# back non-empty. A broken scan fails the control and reddens; only a scan that provably
# reaches the tree is allowed to report the ban clean.
#
# WHAT IT STILL DOES NOT CATCH, unchanged from the block it replaces: a SECOND, differently
# worded statement of the round rule inside a file already in the tree. Both sites that
# broke in the sprint before this one were of that kind, and nothing mechanical catches it
# at a cost worth paying. A reader catches it, and saying so here is cheaper than a later
# maintainer assuming it was covered.
#
# grep -rlIF and never -E: `Round: settle` and `settle all` are literals, -I skips binaries
# so a __pycache__ blob cannot be counted, and /usr/bin/grep by absolute path because this
# scan RECURSES a tree, which is exactly where the interactive zsh's ignore-file-honouring
# grep wrapper would silently shrink the discovered set. Both reasons are argued in full
# above [76g] in 96-review-scope-sites.sh and above check_no_token in 00-helpers.sh.
RSE_ROOTS="skills agents"
RSE_CONTROL='Phase 5 dispatches exactly ONE review and ONE refuter'
# MECHANISM MARKERS ONLY, deliberately. An earlier draft of this list also banned
# the loose prose forms ('settle round', 'FULL round', 'live verdict') and that was
# a mistake in both directions: it reddens a file explaining what the cap RETIRED,
# which is exactly the paragraph the cap most needs, and it guards wording that
# [76h]'s cap-sentence pin already guards better by requiring one agreed phrasing.
# What is left is the three markers that are machinery and nothing else: a dispatch
# prefix, a reserved scope value, and a report line. None of the three can appear in
# correct text, which is the bar a ban has to clear.
#
# Its LENGTH is written a second time, the shape every ban list in this directory
# uses and the reason is argued above check_list_size in 00-helpers.sh: a bound read
# back out of the list it polices cannot police that list, and a whole ban could
# vanish while every line below still printed green.
RSE_DEAD=('`settle `' 'settle all' 'Round: settle')
check_list_size "${#RSE_DEAD[@]}" 3 "the [38h] retired-round-vocabulary ban list"

#
# THE CONTROL PRINTS NO COUNT ANY MORE, and that is the fix rather than a loss. It used
# to end on "the scan reaches N file(s)", counted off the control hit list and checked
# by nothing, so the number read as evidence while the branch it sat in was a plain
# non-emptiness test. Measured: break the cap sentence at ONE of the four sites and this
# line printed "the scan reaches 3 file(s)" and passed. The count belongs to [76h] in
# 96-review-scope-sites.sh, which pins it at four files and four occurrences over these
# same roots and reds on exactly that break. Pinning it a second time here would put two
# hand-written bounds over one fact in two fragments, each free to go stale on its own
# and each needing an edit for one legitimate reword; the argument [76g] makes about a
# number copied into prose applies to a number copied into a second check. So this line
# now claims only what the branch establishes, that the scan provably reached the tree,
# and names where the count lives instead of restating it.
rse_ctl=$(/usr/bin/grep -rlIF -- "$RSE_CONTROL" $RSE_ROOTS 2>/dev/null); rse_ctl_rc=$?
if [ "$rse_ctl_rc" -gt 1 ] || [ -z "$rse_ctl" ]; then
  red "  FAIL [38h] the positive control '$RSE_CONTROL' matched nothing under $RSE_ROOTS (grep exited $rse_ctl_rc), so the ban below would report clean over a scan that never reached the tree"
  FAILED=$((FAILED + 1))
else
  green "  ok   the [38h] positive control found the round-cap sentence under $RSE_ROOTS, so the ban scan below provably reaches the tree; how MANY files carry it is [76h]'s pin and is deliberately not restated here"
  for rse_t in ${RSE_DEAD[@]+"${RSE_DEAD[@]}"}; do
    rse_hits=$(/usr/bin/grep -rlIF -- "$rse_t" $RSE_ROOTS 2>/dev/null); rse_rc=$?
    if [ "$rse_rc" -gt 1 ]; then
      red "  FAIL [38h] could not scan $RSE_ROOTS for '$rse_t' (grep exited $rse_rc), so an empty result here would be a scan that never happened"
      FAILED=$((FAILED + 1))
    elif [ -z "$rse_hits" ]; then
      green "  ok   '$rse_t' appears nowhere under $RSE_ROOTS (retired with the round cap in 0.16.0)"
    else
      red "  FAIL [38h] '$rse_t' is retired vocabulary and still appears under $RSE_ROOTS:"
      FAILED=$((FAILED + 1))
      printf '%s\n' "$rse_hits" | sed 's/^/        /'
    fi
  done
fi

yellow "[38j] the Phase 6 publish contract keeps its rules, the temp-directory one included"
WDA_REF="skills/hackify/references/work-doc-artifact.md"

# (1) THE HAND-OFF IS THE WORK-DOC ITSELF, published as a page, and nothing
# renders a second copy of the sprint beside it. The renderer, its template, its
# doctrine file and its test suite were deleted outright, so the three pins that
# named them are REPLACED here rather than dropped. A doctrine saying "publish the
# doc, never build a second representation of it" rots the moment nobody checks
# that it still says so, and deleting a pin quietly weakens this gate by exactly
# one check, which is the trade every block in this directory refuses.
#
# WHY THESE PHRASES AND NOT NEARBY ONES. Each is a RULE stated in the imperative,
# not a description of one, so it cannot be reworded in passing without the rule
# going with it; that is the bar a pin has to clear, and it is why none of the
# section headings above them was taken instead. The hand-written-markup ban is
# the direct successor of the pin that used to guard the same rule for the
# rendered report, and it is what reddens if somebody reintroduces a rendered
# report by typing the markup out. The hard-require ban is the never-load-bearing
# rule: it is the one sentence a runtime with no publish tool depends on, and
# dropping it turns an enhancement into the portability bug runtime-adapters.md
# forbids.
#
# THE FINISH.MD PIN IS THE LINK, NOT A SENTENCE, and that is deliberate. What it
# asks is whether Step F still loads the contract at all, which is the rot the
# retired call-site pin caught; a sentence there belongs to the phase file's own
# prose and is reworded every time that prose is tightened, while the link is
# either present or the contract is orphaned.
check_file "$WDA_REF"
check_token_present 'do not hand-write markup to stand in for it' "$WDA_REF"
check_token_present 'no phase may hard-require it' "$WDA_REF"
check_token_present '[work-doc-artifact.md](work-doc-artifact.md)' "skills/hackify/references/finish.md"

# (2) THE TEMP-DIRECTORY RULE, WHICH LOST ITS ONLY ENFORCEMENT AND GOT NO
# REPLACEMENT. It used to be executable: the deleted renderer opened both of its
# output paths with O_NOFOLLOW, two tests exercised that, and a named CI step ran
# them. All three went with the renderer, legitimately, and what was left behind
# was prose with nothing under it, so the rule could be edited away with no check
# anywhere going red. THERE IS NO LIVE VULNERABILITY HERE and this block does not
# claim one: `mktemp -d` picks an unguessable name and creates it mode 0700, which
# closes the case on its own. The defect is the missing gate, and a gate is what
# this is.
#
# WHAT IS PINNED IS THE MITIGATION AND ITS REASON, not the paragraph around them.
# The call is machinery and cannot be reworded into something else; the fixed-name
# ban is the rule in the imperative; the mode is the second half of why the
# mitigation works, since an unguessable name nobody else can write into is what
# makes the pre-planted symlink unreachable rather than merely unlikely; and the
# CWE ids are identifiers rather than prose, so they survive every tightening pass
# that a sentence about symlinks would not.
check_token_present '$(mktemp -d)' "$WDA_REF"
check_token_present 'never a fixed name in the shared temp directory' "$WDA_REF"
check_token_present 'mode `0700`' "$WDA_REF"
check_token_present 'CWE-59, CWE-377' "$WDA_REF"

# (3) AND THE ONE OTHER SITE POINTS AT IT RATHER THAN RESTATING IT. quick mode
# publishes a page too and used to carry its own copy of the temp-directory
# sentence; it now defers to the section above instead, which is the better shape
# and also a fragile one, because a delegation that quietly stops delegating
# leaves quick with no rule at all and nothing to notice. Two sites name it, so
# both halves of the arrangement are pinned: the rule lives in exactly one file,
# and the file that gave up its copy still sends the reader there.
# BOTH ENDS OF THE DELEGATION, which is what makes it a pin rather than a hope:
# quick names the rule and names the heading it now lives under, and that heading
# has to still be there in the file it points at.
QUICK_SKILL="skills/quick/SKILL.md"
check_token_present 'temp-directory rule' "$QUICK_SKILL"
check_token_present 'under `## Quick mode`' "$QUICK_SKILL"
check_token_present '## Quick mode' "$WDA_REF"

# (4) THE PROJECT-RELATIVE-PATH RULE AND ITS ENFORCEMENT HALF, pinned together
# because they are worth exactly nothing apart. [6b] in 10-required-files.sh
# screens every live work-doc for an absolute home-directory path, and it is the
# machinery behind this section rather than a second opinion about it. A pin on
# the section alone would let the screen be deleted in silence; the screen alone
# would enforce a rule the doctrine no longer states, which is how a check becomes
# something a later reader deletes as unexplained.
check_token_present '## Project-relative paths only' "$WDA_REF"
# THE DECLARATION LINE AND NOT THE BARE ID, because '[6b]' on its own is
# satisfied by any passing mention in a comment, while the header is the one line
# whose disappearance IS the check's disappearance.
check_token_present '[6b] no live work-doc leaks an absolute home-directory path' "scripts/validate-dod.d/10-required-files.sh"

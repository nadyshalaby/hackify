# shellcheck shell=bash

# DISCOVERED-SITE REVIEW-SCOPE PINS, split out of 76-phase-ledger-substrate.sh
# in the sprint that file reached exactly 500 LOC and could not take another
# line. [76g] and [76h] came across whole and kept their check IDs, the same way
# [38c] through [38h] kept theirs when 71-release-mechanism-pins.sh was carved
# out of 70-invariants-and-new.sh. A fragment is free to move; a check ID that
# CHANGELOG.md, a work-doc or another block cites is not.
#
# THE SEAM IS RESPONSIBILITY, NOT SIZE. 76 keeps the phase-ledger substrate,
# where the ledger lives and what keeps it ticking, and it keeps [76i], the
# validator's check on its own header manifest. The two blocks here ask a third
# question: is ONE review-scope rule stated the same way at every site that
# states it, over a file set the check DISCOVERS rather than lists. [76g] asks it
# of the docs/work/ exclusion on the reviewed diff, [76h] of the FULL-round gate
# and Reviewer B's round marker.
#
# NOTHING CROSSES THE SEAM, which is why the move needed no re-declaration at the
# top of this file the way 71-release-mechanism-pins.sh needed one for INJECT_PY.
# Both blocks read pls_x_assert and the PLS_X* variables, all of them defined
# below, and nothing outside this file reads any of them. The check ran off its
# own state before the move and runs off its own state after it.
#
# THE MOVE SETTLES WHAT [76g]'s OWN COMMENT LEFT OPEN. It said the block sat in a
# fragment named for the phase ledger, that a reviewer was right about it, and
# that it stayed put because the hand-maintained manifest row, [76f] and the
# wiring guard [0] would all have to move with it. All three were paid here.

yellow "[76g] the reviewed diff excludes docs/work/, at every site that builds it and in the prose that says why"
# The work-doc is a changed path in the sprint diff AND the authority Reviewer B
# measures that diff against. Writing a round's result into it changes its bytes,
# which kills its own verdict, which mandates another round whose result is
# written into it again. One sprint rewrote its work-doc 25 times before the loop
# was proven unclosable. The fix is the exclusion pathspec pinned below.
#
# THE REASON IS PINNED BESIDE THE MECHANISM, on purpose. An exclusion nobody can
# see is indistinguishable from a silent drop, and the sprint that shipped this
# exists to kill silent drops. A pathspec surviving with its justification gone is
# the shape that gets "cleaned up" by the next reader who cannot tell why it is
# there. So both halves are counted, and either one going missing reddens.
#
# THE FILE SET IS DISCOVERED, NOT LISTED, and that changed here. It shipped as four
# hardcoded paths. Twelve more files picked the literal up in the two waves after,
# the eight that matter being the four sliced reviewer prompts and their four
# agents/ mirrors, which is where the executing review contract now lives, and the
# hand-written list saw none of them: an editor could have stripped the exclusion
# from every sliced reviewer with this check still green. Discovery is the [79]
# argument, a hand-kept list is the next thing to go stale.
#
# TWO NUMBERS, NOT SEVENTEEN. The four paths carried a per-file expected count each.
# At seventeen files that is seventeen hand-written numbers, seventeen chances to
# write the wrong one, and a rewrite of this block every time a reviewer prompt is
# reworded, which is a pin that breaks on progress. It is also the shape that made a
# previous wave restructure a doc to satisfy PLS_XSITES_EXPECTED. What the pin has
# to catch is a SITE DISAPPEARING, and the discovered file count plus the grand
# occurrence total catch strictly more of that than the per-file counts did: a file
# losing the literal entirely drops out of discovery and moves the file count, a
# single site deleted anywhere moves the total, and a NEW file that picks the
# literal up without anyone noticing, the failure that actually happened, moves the
# file count the other way. Both numbers are written by hand beside the check, per
# the argument above check_list_size in 00-helpers.sh.
#
# grep -oF, never -c and never -E. -c counts LINES, so two sites sharing one line
# would read as one site. -E would treat the pathspec's own `*` and `(` as regex
# metacharacters, and that literal is very nearly nothing but metacharacters. -I
# skips binaries so a stray __pycache__ blob cannot be counted as a site.
#
# /usr/bin/grep by absolute path HERE and bare `grep` in the rest of this fragment,
# for the reason spelled out above check_no_token in 00-helpers.sh: this is the only
# scan in the file that RECURSES a directory tree, which is precisely where a grep
# honouring ignore files would silently shrink the discovered set. The other greps
# here read one named file each, where the distinction cannot bite.
#
# SCAN ROOTS ARE skills AND agents, which is the whole of where the review contract
# ships. docs/ is deliberately not among them, so the work-doc excludes itself from
# the check about excluding the work-doc; scripts/ is not either, so this fragment's
# own PLS_XDIFF assignment does not count itself as a site.
#
# check_no_tokens_in is deliberately NOT used here. test_ban_tokens.sh pins the number
# of batched ban calls shipping across the trees TB_CALL_SITE_DIRS names, this fragment's
# own directory among them, so adding one here would redden a file this block has no
# business making me touch.
#
# THE VALUE IS DELIBERATELY NOT RESTATED, AND THIS PARAGRAPH USED TO RESTATE IT ANYWAY.
# It carried a copy reading 3 for two releases after the pin had stopped saying 3, and
# the copy that replaced it was stale again inside the release that wrote it. Both times
# in the very sentence arguing that a number copied into prose rots in silence while the
# pin itself cannot. So the copy is gone rather than corrected, and what is left is the
# address:
#
#   grep '^TB_EXPECT_CALLS=' scripts/test_ban_tokens.sh
#
# That assignment is the only place the value is allowed to live. The address is safe to
# point at where a copy was not: 30-inventory-pins.sh reads TB_EXPECT_CALLS with `set -u`
# in force, so renaming or deleting it takes that suite down loudly rather than leaving
# this pointer aimed at nothing. Which is also why nothing guards this paragraph. There
# is no number left here for a guard to be about.
#
# WHERE THIS BELONGS, SETTLED. Reviewer B was right that [76g] pinned a Phase 5
# rule inside a fragment named for the phase ledger, and the answer used to be
# that it stayed put because the move was not free: the manifest comment at
# scripts/validate-dod.sh is hand-maintained, [76f] checks that every SOURCED
# fragment is named there, and [0] checks both directions of the wiring. All
# three were paid when 76 hit the 500-LOC cap and this file was carved out.
PLS_XDIFF="':(exclude)docs/work/*'"
PLS_XRULE='the ruler the diff is measured against and cannot also be'
PLS_XROOTS="skills agents"
# Hand-written, and independent of the lists they police. THE VALUES ARE NOT
# RESTATED HERE, on the same argument this file already makes above about
# TB_EXPECT_CALLS: the four assignments below are the only place they live, they
# sit a dozen lines down, and the copy that used to open this paragraph is what
# rotted. It read 50 occurrences and 7, against pins of 49 and 6, in the one file
# whose own header argues that a number copied into prose rots in silence while
# the pin cannot. Second time in this fragment, so the copy goes rather than
# getting corrected into place for a third.
#
# MEASURE ALL FOUR TOGETHER, from one run, with the literals read out of the two
# variables above rather than retyped. Every one of these moved by exactly +1 when
# SKILL.md:189 gained the exclusion, and the +1 is what composes: a later wave that
# closes another site moves them again by the same step. That happened: finish.md's
# class (f) block gained the exclusion in the claim-integrity sprint, because it and
# phases/phase-6-finish.md:42 gave the same audit two different commands, and these
# two pins moved 18 to 19 and 49 to 50 in that same edit. The first attempt to
# re-derive them by hand searched for "the ruler" as a prefix and got 15 files and
# 16 occurrences, because PLS_XRULE is a full sentence, not its opening words. A
# prefix that is not the pinned literal measures a different thing and agrees with
# nothing.
# 0.16.0 moved both occurrence totals down by one and left both file totals
# alone, which is the composition working as described: the round cap deleted
# the FULL-round paragraph from phases/phase-5-review.md and the carry-over
# section from review-scope.md, each of which restated both literals, and the
# cap's replacement paragraph put the pathspec back once in the phase file.
# Re-measured with the two greps below, not reasoned about.
#
# THE RENDERED-REPORT RETIREMENT moved these two pins 19 to 18 and 49 to 47 and
# left the rule pair alone, which is the same composition running the other way.
# references/html-report.md was deleted outright and it carried the pathspec
# TWICE, on the `git diff --stat` and `git diff --numstat` rows of the table
# that told the renderer where each of its numbers came from. One file dropping
# out of discovery is the file total's step; that file's two sites are the
# occurrence total's. The rule pair could not move on this edit, because that
# file stated the two commands and never the reason for the exclusion.
# Re-derived over the live tree with the two greps below, then cross-checked by
# running the same pair through `git grep` at HEAD, where html-report.md is
# still present: that read 19 files and 49 occurrences, and the deleted copy
# carried the literal exactly twice, so the whole delta is that one file and
# nothing else drifted underneath it.
PLS_XFILES_EXPECTED=18
PLS_XOCCUR_EXPECTED=47
PLS_XRULE_FILES_EXPECTED=6
PLS_XRULE_OCCUR_EXPECTED=6

# $1 the literal, $2 expected files, $3 expected occurrences.
#
# STATUS IS GREP'S ALONE. Both greps sit in a plain command substitution with no
# pipe inside it. Under `pipefail` a `grep ... | wc -l` hands back wc's status and
# wc succeeds on empty input, so a grep that exited 2 on an unreadable root would
# arrive here as a tidy 0 and print a red about missing sites rather than about a
# scan that never happened. rc 1 is the honest "no match" and counts as 0.
#
# THE SCAN RUNS IN THIS FUNCTION, not in one called through `$(...)`. The first
# draft of this block returned the two counts through a command substitution and
# set the discovered path list in a variable beside them. A command substitution
# is a SUBSHELL, so that variable never came back, and the actionable half of the
# red line rendered as one blank line under a heading promising a file list. Found
# by tampering, not by reading, which is the argument for tampering.
#
# The list prints on the FAILURE path only: naming seventeen files that are all
# fine is noise, naming them the moment the count moves is the whole diagnosis.
pls_x_assert() {
  local lit="$1" want_f="$2" want_o="$3"
  local files occs rc_f rc_o n_files=0 n_occs=0
  files=$(/usr/bin/grep -rlIF -- "$lit" $PLS_XROOTS 2>/dev/null)
  rc_f=$?
  occs=$(/usr/bin/grep -roIF -- "$lit" $PLS_XROOTS 2>/dev/null)
  rc_o=$?
  if [ "$rc_f" -gt 1 ] || [ "$rc_o" -gt 1 ]; then
    red "  FAIL [76g] could not scan $PLS_XROOTS for '$lit' (grep exited $rc_f then $rc_o), so a count of 0 here would be a count of nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  [ -n "$files" ] && n_files=$(printf '%s\n' "$files" | wc -l | tr -d ' ')
  [ -n "$occs" ] && n_occs=$(printf '%s\n' "$occs" | wc -l | tr -d ' ')
  check_list_size "$n_files" "$want_f" "the files under $PLS_XROOTS carrying '$lit'"
  check_list_size "$n_occs" "$want_o" "the occurrences of '$lit' under $PLS_XROOTS"
  [ "$n_files" -eq "$want_f" ] && return
  red "  ---- the $n_files discovered file(s) were:"
  printf '%s\n' "$files" | sed 's/^/        /'
}

pls_x_assert "$PLS_XDIFF" "$PLS_XFILES_EXPECTED" "$PLS_XOCCUR_EXPECTED"
pls_x_assert "$PLS_XRULE" "$PLS_XRULE_FILES_EXPECTED" "$PLS_XRULE_OCCUR_EXPECTED"

# B is the one reviewer that both READS the work-doc as its authority and diffs
# the whole thing unsliced, so the exclusion has to live in its own prompt. These
# two sentences are what keep those roles apart: drop them and a later editor
# reads the exclusion as permission to stop reading the work-doc at all, which
# deletes steps 14 to 19 outright and turns a scoping fix into lost coverage.
#
# Each is pinned WHOLE, closing `**` included, because the paragraph hard-wraps.
# The earlier draft of this sentence spanned two lines, which would have made any
# pin on it a prefix that stays green while the claim's second half is deleted,
# the exact failure [76] and [76d] were both bitten by. The sentence was reflowed
# to fit the pin rather than the pin trimmed to fit the sentence.
for pls_bf in "skills/hackify/references/parallel-agents/phase-5-multi-review-b-quality-plan.md" \
              "agents/reviewer-quality-plan.md"; do
  check_token_present '**You still READ the work-doc in full at step 2.**' "$pls_bf"
  check_token_present '**It stays your authority for steps 14 to 19.**' "$pls_bf"
done

yellow "[76h] the Phase 5 round cap is worded identically at every site that states it"
# ONE RULE, FOUR SITES, AND THE DEFECT THIS PINS ALREADY HAPPENED. The rule this
# block guards changed in 0.16.0 and the mechanism did not: what used to be pinned
# here was the FULL-round exit gate, and it was pinned because that gate had been
# amended at one site and left standing at three, in wording that no dispatch could
# then satisfy. The round cap replaced the gate. The four sites did not change, and
# neither did the reason they have to agree byte for byte.
#
# DISCOVERED, NOT LISTED, for [76g]'s reason: a hand-kept list of the sites stating
# this rule is the next thing to go stale, and the site that goes stale is the one
# nobody remembered to list. Discovery also catches a NEW file picking the wording up.
#
# WORDED IDENTICALLY IS THE POINT, not merely present. Four paraphrases of one rule
# are four rules a reader must reconcile, and the reconciling is where the last
# amendment got lost. Pinning ONE literal forces the four to agree byte for byte or
# redden, the only version of "they agree" a script can check.
#
# WHAT LEFT WITH THE GATE. B's round marker was pinned here in both halves, the
# instruction and the report skeleton, because either alone left the other deletable
# while this stayed green. The marker named which round a dispatch was, and with one
# round per phase it has no referent, so both halves went. The both-halves argument
# did not go with them: it is why [76h] pins B's completeness section the same way,
# below, and that section is the one thing in B's OUTPUT contract nothing else guards.
#
# grep -oF, never -c and never -E, and /usr/bin/grep by absolute path: pls_x_assert is
# the same function and all three reasons are spelled out above [76g], unchanged here.
PLS_CAP='Phase 5 dispatches exactly ONE review and ONE refuter, and the phase ends when the surviving findings are fixed'
# Hand-written beside the check and independent of the list it polices, per the
# argument above check_list_size in 00-helpers.sh. Today: 4 occurrences over 4 files
# (SKILL.md, phases/phase-5-review.md, review-and-verify.md, review-scope.md), the
# same four that carried the gate wording this replaced.
PLS_CAP_FILES_EXPECTED=4
PLS_CAP_OCCUR_EXPECTED=4

pls_x_assert "$PLS_CAP" "$PLS_CAP_FILES_EXPECTED" "$PLS_CAP_OCCUR_EXPECTED"

# B'S COMPLETENESS SECTION, PINNED IN BOTH HALVES, the instruction and the report
# skeleton, because either alone leaves the other deletable while this stays green.
# The instruction with no skeleton heading is a rule with nowhere to write the answer;
# the skeleton heading with no instruction is a blank B fills in however it likes.
# That is the same argument the retired round-marker pins made, and it applies harder
# here: this section exists because a completeness critic running beside the panel
# found nine findings none of the four lenses had, two of them severe, a shell
# variable used but assigned nowhere in the tree and a new validator check that could
# never go red in CI. It is a SECTION of B rather than a tenth agent, so nothing else
# in the panel would notice its absence.
#
# Both numbers are 2 and stay 2: B's canonical prompt plus its agents/ byte-mirror. A
# third copy of B's prompt is a roster change, not a wording change, and it should
# redden here.
PLS_BDNR='## What the review did not reach'
# Pinned WHOLE and on ONE line. The first draft of this literal spanned two lines
# of the hard-wrapped prompt, so the pin matched nothing and reddened at 0 of 2. The
# sentence was reflowed to fit the pin rather than the pin trimmed to fit the
# sentence, which is the same call [76g] records making one paragraph up.
PLS_BCMP='A check that cannot fail passed for the wrong reason'
PLS_BDNR_FILES_EXPECTED=2
PLS_BDNR_OCCUR_EXPECTED=2

pls_x_assert "$PLS_BDNR" "$PLS_BDNR_FILES_EXPECTED" "$PLS_BDNR_OCCUR_EXPECTED"
pls_x_assert "$PLS_BCMP" "$PLS_BDNR_FILES_EXPECTED" "$PLS_BDNR_OCCUR_EXPECTED"

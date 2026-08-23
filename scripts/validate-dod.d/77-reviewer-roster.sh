# shellcheck shell=bash

# [77] Reviewer-roster drift, in COUNT grammar. Panel counts, spec-reviewer
# counts, dispatch counts and the adjudication reviewer's report input are all
# banned over a six-file set. Two of the six are banned over NOWHERE else in the
# validator; on the other four this block bans a wider token set than [70] does.
# All of it is spelled out with numbers under COVERAGE below, because the banner
# used to claim only the first of those and that claim was two thirds false.
#
# THE OTHER GRAMMAR LIVES IN 79-standing-member-invariant.sh. This block used to
# carry both. ROSTER-CLAIM grammar, which letter a sentence asserts to be the
# panel's standing member, is a different question over a file set discovered
# rather than listed, with a matcher that locates a subject instead of matching
# a substring, and it moved out whole when this file reached 499 of 500 LOC. The
# two never shared a line of code. Every paragraph arguing for that half went
# with it; nothing was summarised and nothing was dropped.
#
# WHERE "[70]" POINTS NOW. Every reference below to [70]'s ban loop means the
# P5_FILES / P5_BANS loop under check [38g]. It lived in
# 70-invariants-and-new.sh when these paragraphs were written and moved to
# 71-release-mechanism-pins.sh when that file was split at the same 500-LOC cap.
# The check ID never changed, so [38g] is the durable name. The four citations
# that carried 70's LINE NUMBERS were false the moment it moved and are re-cited
# by symbol below: a line number is the part of a citation that rots first.
#
# WHY THIS EXISTS: the Phase 5 panel stopped being a fixed number in v0.13.0.
# B (quality and plan) is the standing floor and always runs. A (security),
# D (performance) and F (coherence) are gated on evidence. E (design) joins on
# UI-bearing diffs. So the true floor is 1 and the ceiling is 5, and ANY
# hardcoded lower bound is wrong: it denies the gate and tells an orchestrator
# to dispatch reviewers the evidence does not justify. Phase 2.5 is the same
# story from the other side, it dispatches exactly ONE spec reviewer carrying
# three lenses (agents/spec-reviewer.md, "Dispatch exactly one"), so a plural
# spec-reviewer count is stale for the same reason.
#
# The prose describing all of that has now gone stale three releases running.
# [70]'s loop catches the sites its own file list enumerates, but that list grew
# by hand around the hackify skill, and NO ban token anywhere matched the three
# sites fixed this sprint. One of the three sat inside a file [70]'s loop
# already reads, which is the sharper lesson: covering a file is not covering a
# claim. That is why all three survived every earlier sweep with the validator
# fully green:
#   skills/yolo/SKILL.md:114                   "4-to-5 parallel reviewers"
#   parallel-agents/phase-5-aggregation.md:5   "2 spec reviewers", "the 5-to-6 reviewer panel"
#   references/review-scope.md:9               "The panel is five now"
#
# COVERAGE, STATED HONESTLY. This block did THREE different jobs while it still
# carried both grammars, and not one of them is "the files [70] does not cover",
# which is what it used to say. The third, PATHLESS, moved to
# 79-standing-member-invariant.sh with the check it describes. The two below are
# what this file covers now.
#
#   NET-NEW, two files. skills/hackify/references/review-scope.md and
#   parallel-agents/phase-5-aggregation.md are banned over nowhere else: no
#   check_no_token in scripts/validate-dod.d/ names either path. [70] does read
#   review-scope.md, but only for presence pins ([38e]'s SCOPE_REF block), and a
#   presence pin cannot catch a wrong number. phase-5-aggregation.md is in no ban
#   list at all. Lose these two and this block's unique reach is gone.
#
#   DEEPER, four files. skills/yolo/SKILL.md, skills/quick/SKILL.md,
#   phases/phase-5-review.md and references/review-and-verify.md are ALREADY in
#   [70]'s ban loop (its P5_FILES set). This block is not redundant on them, it
#   is mostly wider: the loop below runs 60 tokens per file against [70]'s 23.
#   Direction first, because it reads backwards easily: these are substring
#   bans, so the SHORTER token is the BROADER one. Hence '5-to-6' reaches
#   '5-to-6-reviewer', '5-to-6 panel' and '5-to-6 spec reviewers' alike where
#   [70]'s fixed phrases reach only their own wording.
#
#   The overlap, MEASURED against [38g]'s P5_BANS rather than asserted: 2 exact
#   duplicates ('5-6 reviewers', '3 parallel reviewers'); 6 pairs where a token
#   HERE is broader (4 of these 60 over 4 of [70]'s 23, e.g. '5-to-6' over
#   '5-to-6-reviewer'); and 2 pairs where a token THERE is broader, [70]'s
#   '2 reviewers' and '3 reviewers' subsuming this block's '2 reviewers in
#   parallel' and '3 reviewers in parallel'.
#
#   That last pair is a CORRECTION. This paragraph used to end "the reverse
#   never occurs, no [70] token subsumes one of the 60", and the sprint that
#   added the ten '<count> reviewers in parallel' tokens below is the sprint
#   that falsified it, by writing them without re-measuring [70]'s bare
#   count-plus-noun pair. Both are KEPT anyway: [70]'s loop covers neither
#   review-scope.md nor phase-5-aggregation.md, so on those two files nothing
#   else bans either phrase and dropping them would lose coverage outright. The
#   six report-input bans at the bottom are scoped to one file and counted
#   separately from those 60.
#
#   Exactly two tokens are literal duplicates of [38g]'s P5_BANS, '5-6 reviewers'
#   and '3 parallel reviewers'. Both are KEPT deliberately. Dropping them on the
#   four shared files would make this block's coverage depend on [70]'s
#   hand-kept token list, an undeclared cross-fragment dependency that nothing
#   pins, so an edit over there would silently shrink coverage over here. [70]
#   also covers only four of these six files, so the tokens are load-bearing on
#   the other two regardless. The price of keeping them is two grep calls over
#   four small markdown files.
#
# Why a text scan is the right tool for all three jobs: the defect is a literal
# sentence a human types into an executable instruction. There is no structure to
# parse and no runtime to observe, the wrong number or the wrong letter simply
# reads as fact to the next agent. For the count grammar, a substring ban over a
# named file set fires on the exact words a future author would reach for. For
# the roster claim, no substring exists to ban (see THE STANDING-MEMBER INVARIANT
# in 79-standing-member-invariant.sh), so a few lines of awk locate the claim's
# subject instead. Both cost milliseconds and neither carries a count of its own
# to rot.
#
# WHAT IS BANNED, AND WHAT DELIBERATELY IS NOT. Every token below is CLAIM
# grammar: a range ("4 to 5"), a dispatch count in either word order ("five
# parallel reviewers", "five reviewers in parallel"), a panel identity ("the
# panel is five"), or a spec-reviewer plural. The bare count-plus-noun form
# ("two reviewers", "six reviewers") is NOT banned, because that is where
# legitimate prose lives. Proven by two hits inside this very file
# set: review-and-verify.md:141 says "Two reviewers consume a deterministic
# scout run", a correct statement about B and D, and review-scope.md:9 says
# "Six reviewers each ran `git diff`", the historical cost that motivated
# slicing. A ban that reddens on correct text gets deleted, so it is not bought.
# Anchor-free word ranges ("four or five") are skipped for the same reason, they
# read as ordinary quantities. Every token here was verified absent from all six
# files before being added.
#
# WORD ORDER IS PART OF THE CLAIM. "<count> parallel reviewers" was banned and
# "<count> reviewers in parallel" was not, so the same wrong claim walked back in
# at review-and-verify.md:384 through the other ordering. Both orders are now
# banned at every count, word and digit. What is NOT banned is the UNCOUNTED
# phrase "reviewers in parallel": review-and-verify.md:139 correctly reads
# "dispatches the panel as foreground reviewers in parallel in a single message",
# which asserts the dispatch shape and no width at all. That is the sentence the
# gate wants written, so a ban on it would redden correct prose and get deleted.
# Note the deliberate asymmetry with 'spec reviewers in parallel' in the loop
# below, which IS banned uncounted: Phase 2.5 dispatches exactly ONE spec
# reviewer, so a plural there is drift whatever the count, while the panel is
# legitimately plural at an unstated width.
#
# THE ADJUDICATION REVIEWER'S REPORT INPUT is pinned at the bottom of this
# block. It is the same defect one layer down: a roster hardcoded as INPUT slots
# rather than as a sentence. The prompt at review-and-verify.md:191 enumerated
# {{reviewer_a_report}}, {{reviewer_b_report}} and {{reviewer_d_report}}, so the
# adjudication reviewer structurally could not read a finding from E or F, the
# two the gate adds most often. It was fixed by collapsing all three into one
# count-agnostic {{reviewer_reports}}. Nothing pinned that fix, so the
# enumeration could walk straight back in under any letter while every token
# above guarded mere prose counts.
#
# Named as the adjudication reviewer, never as "the escalation prompt". This
# sprint renamed that template (review-and-verify.md:191,193) and the old name
# now misdirects: parallel-agents/phase-5-escalation.md is a DIFFERENT prompt
# that "never receives a reviewer report" (phase-5-escalation.md:7). The word
# escalation stays correct for the escalation PATH and for that file's own name.
#
# Documented bias: source only. dist/ is regenerated from these files, so a
# stale count in a built tree is a sync problem rather than this block's. [70]
# is source-only for the same reason.
#
# THE VACUOUS-PASS GUARD IS THE POINT OF THIS BLOCK. check_no_token runs
# `grep -rcFiI` and a path that does not exist produces no output, which sums to
# 0, which prints green. One typo in the list below and the entire check
# silently measures nothing, which is the trap this repo has already been bitten
# by. So: every path is asserted to exist and be non-empty BEFORE a single token
# is banned over it, a bad path fails loudly and is then SKIPPED so it cannot
# contribute fake greens, the parsed-path count is asserted EQUAL to an
# independently written expected size so a quiet deletion cannot pass, and the
# two files whose coverage is unique are pinned by name so a substitution cannot
# pass either. check_token_present 'reviewer' per file is the relevance pin: a
# covered file that no longer discusses reviewers is either the wrong path or a
# file whose ban list needs rethinking.

yellow "[77] reviewer-roster drift: count grammar over 6 files (2 no other check reaches, a wider token set on the 4 shared with [38g]) plus the adjudication reviewer's report input"

RR_PA="skills/hackify/references/parallel-agents"
RR_FILES="skills/yolo/SKILL.md skills/quick/SKILL.md"
RR_FILES="$RR_FILES skills/hackify/references/review-scope.md"
RR_FILES="$RR_FILES $RR_PA/phase-5-aggregation.md"
RR_FILES="$RR_FILES skills/hackify/references/phases/phase-5-review.md"
RR_FILES="$RR_FILES skills/hackify/references/review-and-verify.md"

# The set's SIZE, written a SECOND time. Why a hand-written number beats a bound
# derived from the list is argued above check_list_size in 00-helpers.sh; this is
# the set that taught it, a floor of 4 under a set of 6 printing "ok all 4 files
# exist" while two of them had quietly left coverage.
RR_EXPECTED=6

# Existence gate. Runs to completion before any ban, see the header.
RR_PARSED=0
RR_BAD=0
for f in $RR_FILES; do
  RR_PARSED=$((RR_PARSED + 1))
  [ -s "$f" ] && continue
  red "  FAIL $f is in the [77] file set but is missing or empty, every ban over it would report 0 hits and measure nothing"
  FAILED=$((FAILED + 1))
  RR_BAD=$((RR_BAD + 1))
done
check_list_size "$RR_PARSED" "$RR_EXPECTED" "the [77] file set"
[ "$RR_BAD" -eq 0 ] && green "  ok   all $RR_PARSED files in the [77] set exist and are non-empty"

# Size alone cannot see a SUBSTITUTION: swap one path for another and 6 is still
# 6. These two carry ban coverage that exists nowhere else in the validator, so
# losing either deletes this block's net-new reach outright while the count
# stays green. Named as literals rather than read back out of RR_FILES, because
# a guard spelled from the thing it guards cannot see that thing change.
for f in "skills/hackify/references/review-scope.md" \
         "skills/hackify/references/parallel-agents/phase-5-aggregation.md"; do
  case " $RR_FILES " in
    *" $f "*)
      green "  ok   $f, banned over by no other check, is still in the [77] set" ;;
    *)
      red "  FAIL $f carries ban coverage no other check has and has left the [77] file set"
      FAILED=$((FAILED + 1)) ;;
  esac
done

# The ban list, built ONCE and then screened with one grep per file rather
# than re-read once per token. The tokens and their order are unchanged, and
# so is every verdict line: see check_no_tokens_in in 00-helpers.sh for why a
# file that matches anything still falls back to the per-token scan.
# Panel width written as a range. Wrong at every spelling, because the gate
# makes the floor 1 and a range denies it.
RR_BANS=('4-to-5' '4 to 5' 'four-to-five' 'four to five' '5-to-6' '5 to 6' 'five-to-six' 'five to six')
RR_BANS+=('4-5 reviewers' '5-6 reviewers' '4 or 5 reviewers' '5 or 6 reviewers')
# The same claim in adjectival form, "the 5-to-6 reviewer panel" was one of
# the three sites fixed this sprint.
RR_BANS+=('4-reviewer' '5-reviewer' '6-reviewer' 'four-reviewer' 'five-reviewer' 'six-reviewer')
# Dispatch counts. "4-to-5 parallel reviewers" was the yolo defect, these are
# the grammars a rewrite of it would land on.
RR_BANS+=('2 parallel reviewers' '3 parallel reviewers' '4 parallel reviewers' '5 parallel reviewers' '6 parallel reviewers')
RR_BANS+=('two parallel reviewers' 'three parallel reviewers' 'four parallel reviewers' 'five parallel reviewers' 'six parallel reviewers')
# The same dispatch count with its words in the other order, which is how the
# claim walked back into review-and-verify.md:384 past the two loops above.
# The UNCOUNTED phrase 'reviewers in parallel' is deliberately not banned, see
# WORD ORDER IS PART OF THE CLAIM in the header.
RR_BANS+=('2 reviewers in parallel' '3 reviewers in parallel' '4 reviewers in parallel' '5 reviewers in parallel' '6 reviewers in parallel')
RR_BANS+=('two reviewers in parallel' 'three reviewers in parallel' 'four reviewers in parallel' 'five reviewers in parallel' 'six reviewers in parallel')
# Panel identity. "The panel is five now" was the review-scope defect.
RR_BANS+=('panel is 4' 'panel is 5' 'panel is 6' 'panel is four' 'panel is five' 'panel is six')
RR_BANS+=('panel is now four' 'panel is now five' 'panel is now six' 'panel of four' 'panel of five' 'panel of six')
# Claims that deny the gate outright.
RR_BANS+=('all four reviewers' 'all five reviewers' 'all six reviewers' 'reviewers always run')
# Phase 2.5 dispatches exactly one spec reviewer, so any count is drift.
RR_BANS+=('2 spec reviewers' '3 spec reviewers' 'two spec reviewers' 'three spec reviewers' 'both spec reviewers' 'spec reviewers in parallel')

# The list's LENGTH, written a SECOND time, same argument as RR_EXPECTED above.
# Nothing else here counts what it bans, so a whole ban group could vanish and
# every check still print green. TB_EXPECT_77 in test_ban_tokens.sh mirrors it.
RR_BANS_EXPECTED=60
check_list_size "${#RR_BANS[@]}" "$RR_BANS_EXPECTED" "the [77] count-grammar ban list"

for f in $RR_FILES; do
  # A path that failed the gate above is skipped, never banned over.
  [ -s "$f" ] || continue
  # Relevance pin, not a matcher control: this file still talks about reviewers.
  check_token_present 'reviewer' "$f"
  check_no_tokens_in "$f" "${RR_BANS[@]}"
done

# The adjudication reviewer takes ONE count-agnostic report input, never a slot
# per letter. See the header for what the enumerated form broke. Scoped to this
# single file rather than the six-file loop above for two reasons: the presence
# pin is only TRUE here, so running it over all six would redden five correct
# files, and splitting a pin from the bans that complete it puts one guard in
# two places. Verified before adding: reviewer_[a-f]_report appears nowhere
# under skills/, only in CHANGELOG.md and docs/work/, which this set never reads.
# These six carry their OWN count now; they were counted NOWHERE, so the header's
# "counted separately from those 60" was true of the intent and false of the code.
# Covered: test_ban_tokens.sh parses RR_RPT too and plants every token in it.
RR_RAV="skills/hackify/references/review-and-verify.md"
RR_RPT=(reviewer_a_report reviewer_b_report reviewer_c_report reviewer_d_report reviewer_e_report reviewer_f_report)
RR_RPT_EXPECTED=6
check_list_size "${#RR_RPT[@]}" "$RR_RPT_EXPECTED" "the [77] report-input ban list"
if [ -s "$RR_RAV" ]; then
  check_token_present '{{reviewer_reports}}' "$RR_RAV"
  check_no_tokens_in "$RR_RAV" "${RR_RPT[@]}"
fi

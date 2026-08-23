# shellcheck shell=bash

# [77] Reviewer-roster drift, in TWO grammars. COUNT grammar (panel counts,
# spec-reviewer counts, dispatch counts, and the adjudication reviewer's report
# input) is banned over a six-file set. ROSTER-CLAIM grammar (which letter a
# sentence asserts to be the panel's standing member) is checked over a set this
# block discovers for itself, with no path list at all. Two of the six files are
# banned over NOWHERE else in the validator; on the other four this block bans a
# wider token set than [70] does. All of it is spelled out with numbers under
# COVERAGE below, because the banner used to claim only the first of those and
# that claim was two thirds false.
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
# The settle round after that found three MORE, and not one of them was a count
# defect, which is exactly why every token in the loop below was blind to all
# three:
#   phase-5-multi-review-f-coherence.md:205  "**Standing member.** F runs on
#                                             every non-trivial diff"
#   phase-5-multi-review-a-security.md:174   "Reviewers D ... and F ... **are
#                                             standing members of every wave**"
#   references/review-and-verify.md:384      "dispatch two reviewers in parallel"
# The first two name the wrong LETTER, not the wrong number, so no count ban
# could ever have reached them. The third is a claim this block already bans
# ("two parallel reviewers") with its words in the other order. So the block
# widened past count grammar into roster-claim grammar and into phrase order.
#
# AUTHORIZATION, stated honestly. The standing decision behind this fragment
# authorized guarding stale reviewer COUNT drift, so extending it to
# standing-member grammar is a WIDENING of an approved decision, not a defect in
# the guard as that decision approved it.
#
# COVERAGE, STATED HONESTLY. This block does THREE different jobs and not one of
# them is "the files [70] does not cover", which is what it used to say.
#
#   NET-NEW, two files. skills/hackify/references/review-scope.md and
#   parallel-agents/phase-5-aggregation.md are banned over nowhere else: no
#   check_no_token in scripts/validate-dod.d/ names either path. [70] does read
#   review-scope.md, but only for presence pins ([70]:461-468), and a presence
#   pin cannot catch a wrong number. phase-5-aggregation.md is in no ban list at
#   all. Lose these two and this block's unique reach is gone.
#
#   DEEPER, four files. skills/yolo/SKILL.md, skills/quick/SKILL.md,
#   phases/phase-5-review.md and references/review-and-verify.md are ALREADY in
#   [70]'s ban loop ([70]:309). This block is not redundant on them, it is
#   mostly wider: the loop below runs 60 tokens per file against [70]'s 23.
#   Direction first, because it reads backwards easily: these are substring
#   bans, so the SHORTER token is the BROADER one. Hence '5-to-6' reaches
#   '5-to-6-reviewer', '5-to-6 panel' and '5-to-6 spec reviewers' alike where
#   [70]'s fixed phrases reach only their own wording.
#
#   The overlap, MEASURED against [70]:310 rather than asserted: 2 exact
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
#   PATHLESS, one invariant. The standing-member check names no file at all. It
#   discovers its own set with grep -rl over skills/ agents/ rules/ commands/
#   and README.md, which today is 13 files: 7 under skills/, 5 under agents/
#   and the README. rules/ and commands/ are scanned too and currently match
#   nothing; they are in the root list because a roster claim can land there,
#   not because one has. A hand-kept list would have been worse than useless
#   here: BOTH roster defects lived in files the six-file list does not name,
#   so a list-scoped version of this check would have run green over the two
#   sentences it exists to catch. The list is not the unit of coverage, the
#   claim is.
#
#   README.md is a FILE root, not a directory one, and it is here because
#   README.md:103 carries a live standing-member claim about B that nothing
#   guarded: the roots were four directories and the repo's most-read document
#   sat outside all of them. CHANGELOG.md and docs/ are deliberately NOT roots,
#   measured rather than assumed: the awk below reads CHANGELOG.md:102 as F and
#   :198 as A, both correct release text about the roster as it stood when
#   written, and the work-doc under docs/work/ quotes the defect sentences
#   verbatim eight times to record them. History that says what used to be true
#   is not drift, and a ban that reddens on it gets deleted rather than obeyed.
#
#   Exactly two tokens are literal duplicates of [70]:310, '5-6 reviewers' and
#   '3 parallel reviewers'. Both are KEPT deliberately. Dropping them on the
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
# below), so a few lines of awk locate the claim's subject instead. Both cost
# milliseconds and neither carries a count of its own to rot.
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
# THE STANDING-MEMBER INVARIANT, and why it is not a token ban. There is exactly
# one standing member of the Phase 5 panel and it is B. Every other letter
# asserted as standing is wrong in any phrasing, so the defect is not a word,
# it is a subject. The two sites found this sprint share no surface form at all:
# one is plural mid-sentence ("Reviewers D ... and F ... are standing members of
# every wave"), the other opens a line as a bare "**Standing member.**" heading
# with no subject before it, and THAT one also carries a perfectly legitimate
# bare "B" later in the line ("as A, B and D"). So the obvious "does the line
# contain B" discriminator false-negatives on the second defect, and any regex
# fitted to both fits neither. A subject has to be located, not matched.
#
# THE ALGORITHM. For every occurrence of "standing member" (case-insensitive),
# take the text preceding THAT occurrence, delete parenthetical spans from it,
# then take the LAST standalone capital A-F left standing. That letter is the
# claim's subject and it MUST be B. Any other letter fails, and so does no
# letter at all. "Standalone" means the character has no ASCII letter on either
# side, so it never matches a letter inside a word.
#
# Stripping parentheticals is LOAD-BEARING and was not in the first draft.
# skills/yolo/SKILL.md:67 legitimately reads "B (... v0.13.0 merged Reviewer C
# into it) is the standing member", and a raw backward scan reads the subject as
# C out of that aside and reddens a correct sentence. Parentheses name other
# reviewers incidentally and are never the subject of the claim. Verified that
# stripping costs no catch: both defect sentences still fail with it in place.
#
# Every occurrence on a line is judged, not just the first. These files carry
# single lines hundreds of characters long (yolo/SKILL.md:67 is one whole table
# cell), so a second claim appended to a line that already carries a correct one
# is a live way back in. Verified before adding the loop: no line in the current
# set mentions "standing member" twice, so the loop cannot fire on today's prose.
#
# A SUBJECT-FREE MENTION IS TREATED AS A DEFECT, deliberately, and this is the
# one rule here that can redden prose an author believes is fine. The class is
# wider than the mild case this used to quote: the subject is only ever looked
# for BEFORE the phrase, so ANY sentence putting it AFTER reads as subject-free
# and reddens, however correct the claim is. Verified with the awk below rather
# than reasoned about, "The panel's standing member is B." reports `names no
# reviewer`, and so do "Our standing member: B." and "the panel has exactly one
# standing member". None of those shapes exists in the scanned set today, which
# is the only reason the rule is affordable. It is bought because subject-free
# is the exact shape of the f-coherence defect: a "**Standing member.**" heading
# whose body then names the wrong reviewer. The fix an author owes is one word
# in one place, put the letter in front of the phrase. Teaching the algorithm to
# read a subject that FOLLOWS the phrase is a real change to it and is
# deliberately not made here; disclosing what it actually refuses is.
#
# NO PATH LIST, ON PURPOSE, and one relevance anchor instead. See PATHLESS
# above for why a list would have run green over both defects. That leaves the
# vacuous-pass problem this block otherwise solves by asserting its paths, so it
# is solved two other ways: the discovery is asserted to actually reach a file
# known to contain the phrase, and the canonical correct sentence "B is the
# standing member" is pinned present in phases/phase-5-review.md. If that
# sentence ever leaves, the invariant has lost the authority it is enforcing and
# this check must go red rather than keep policing a rule the docs dropped.
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

yellow "[77] reviewer-roster drift: count grammar over 6 files (2 no other check reaches, a wider token set on the 4 shared with [70]) plus the adjudication reviewer's report input, and the standing-member-is-B invariant over every file that claims one"

RR_PA="skills/hackify/references/parallel-agents"
RR_FILES="skills/yolo/SKILL.md skills/quick/SKILL.md"
RR_FILES="$RR_FILES skills/hackify/references/review-scope.md"
RR_FILES="$RR_FILES $RR_PA/phase-5-aggregation.md"
RR_FILES="$RR_FILES skills/hackify/references/phases/phase-5-review.md"
RR_FILES="$RR_FILES skills/hackify/references/review-and-verify.md"

# The set's SIZE, written a SECOND time and on purpose. A bound derived from the
# list cannot police the list: delete an entry and a `wc -w` bound drops with it
# and stays green. That is precisely how a floor of 4 sat under a set of 6 and
# guarded nothing, printing "ok all 4 files exist" while two files quietly left
# coverage. Equality against an independently written number is the cheapest
# thing that reddens on BOTH a deletion and an addition, so the list and its
# expected size cannot drift apart again. A seventh file must bump this in the
# same commit, and that edit is loud and deliberate, which is the whole point.
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
if [ "$RR_PARSED" -ne "$RR_EXPECTED" ]; then
  red "  FAIL $RR_PARSED path(s) parsed from the [77] file set, expected exactly $RR_EXPECTED (a file was added or dropped without updating RR_EXPECTED, or the list is mangled)"
  FAILED=$((FAILED + 1))
elif [ "$RR_BAD" -eq 0 ]; then
  green "  ok   all $RR_PARSED files in the [77] set exist and are non-empty"
fi

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

# The list's LENGTH, written a SECOND time, for exactly the reason RR_EXPECTED
# is written next to RR_FILES: a bound derived from the list cannot police the
# list. Nothing else here counts what it bans, so a whole ban group could be
# deleted and every check in this fragment still printed green; the only thing
# that noticed was scripts/test_ban_tokens.sh, which the validator does not run.
# Equality against an independently written number reddens on BOTH a deletion
# and an addition. TB_EXPECT_77 over there holds the same number, also written
# independently, and a token added or dropped updates both in the same commit.
RR_BANS_EXPECTED=60
if [ "${#RR_BANS[@]}" -eq "$RR_BANS_EXPECTED" ]; then
  green "  ok   the [77] ban list carries all $RR_BANS_EXPECTED tokens"
else
  red "  FAIL ${#RR_BANS[@]} token(s) in the [77] ban list, expected exactly $RR_BANS_EXPECTED (a ban group was added or dropped without updating RR_BANS_EXPECTED)"
  FAILED=$((FAILED + 1))
fi

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
RR_RAV="skills/hackify/references/review-and-verify.md"
if [ -s "$RR_RAV" ]; then
  check_token_present '{{reviewer_reports}}' "$RR_RAV"
  check_no_tokens_in "$RR_RAV" reviewer_a_report reviewer_b_report reviewer_c_report \
    reviewer_d_report reviewer_e_report reviewer_f_report
fi

# The standing-member invariant. Deliberately pathless: it discovers its own set
# rather than reading one, because both defects it exists to catch lived outside
# the six-file list above. See THE STANDING-MEMBER INVARIANT in the header for
# the algorithm, for why parenthetical spans are stripped before the subject is
# located, and for why a subject-free mention counts as a defect.
#
# /usr/bin/grep by absolute path, never bare grep. Shells in this environment
# wrap grep in a function that honours ignore files, and such a wrapper returns
# nothing and exits 0, which is exactly the vacuous pass this block guards
# against. The absolute path costs nothing and makes the scan independent of
# whatever grep the sourcing shell resolves.
RR_SM_ANCHOR="skills/hackify/references/phases/phase-5-review.md"

# Vacuous-pass guard, part one: the roots, which come in two kinds and are
# checked as two kinds. grep -r over a missing DIRECTORY writes to stderr,
# suppressed here, and contributes no files, so renaming a tree would take every
# roster claim under it out of coverage while the scan below stayed green. All
# four directory roots are asserted, not just the one the anchor lives in,
# because agents/ alone carries 5 of the 13 covered files. README.md is a FILE
# root and is asserted with -s: it must exist AND be non-empty, since an empty
# file matches nothing and reads as a clean scan. The two gates stay separate on
# purpose, -d has to keep biting on a directory root typed wrong and a single -e
# over both would answer a weaker question.
RR_SM_DIRS=(skills agents rules commands)
RR_SM_FILES=(README.md)

RR_SM_ROOTBAD=0
for rr_d in "${RR_SM_DIRS[@]}"; do
  [ -d "$rr_d" ] && continue
  red "  FAIL [77] standing-member scan root '$rr_d' is not a directory, so every roster claim under it has silently left coverage"
  FAILED=$((FAILED + 1))
  RR_SM_ROOTBAD=1
done
if [ "$RR_SM_ROOTBAD" -eq 0 ]; then
  green "  ok   all ${#RR_SM_DIRS[@]} [77] standing-member scan directory roots resolve"
fi

RR_SM_FILEBAD=0
for rr_d in "${RR_SM_FILES[@]}"; do
  [ -s "$rr_d" ] && continue
  red "  FAIL [77] standing-member scan file root '$rr_d' is missing or empty, so the roster claim it carries has silently left coverage"
  FAILED=$((FAILED + 1))
  RR_SM_FILEBAD=1
done
if [ "$RR_SM_FILEBAD" -eq 0 ]; then
  green "  ok   the [77] standing-member scan file root(s) ${RR_SM_FILES[*]} exist and are non-empty"
fi

# NUL-DELIMITED, and spelled --null rather than -Z. A path comes out of grep and
# goes into awk, and grep's default newline delimiter cannot carry a path that
# CONTAINS one: the path splits in two, awk fails on both halves to stderr, the
# bad-list stays empty and FAILED never moves. That is a file silently skipped by
# the block whose entire purpose is refusing silent skips, and it inflates the
# scanned count the green line reports as well. NUL is the one byte a path
# cannot hold. The long spelling is load-bearing, not style: this repo's
# /usr/bin/grep is BSD grep 2.6.0 (FreeBSD), where -Z is --decompress, accepted
# in silence and emitting no NUL at all, so -Z here would read as the fix and be
# none. Process substitution rather than a pipe so the loop runs in THIS shell,
# a piped loop is a subshell that discards every count it keeps.
RR_SM_N=0
RR_SM_HITANCHOR=0
RR_SM_BAD=""
while IFS= read -r -d '' rr_f; do
  RR_SM_N=$((RR_SM_N + 1))
  [ "$rr_f" = "$RR_SM_ANCHOR" ] && RR_SM_HITANCHOR=1
  # awk exits 2 on a path it cannot open, so that status is CHECKED. Closes the
  # whole unreadable-path class, not just the newline that exposed it: a file
  # discovered and not read is a file never judged, and that has to be loud.
  if ! rr_out=$(awk '
    {
      low = tolower($0); base = 0
      while (1) {
        idx = index(substr(low, base + 1), "standing member")
        if (idx == 0) break
        # 14 = length("standing member") - 1, so the next search starts just
        # past this match and a second claim on the same line is still judged.
        abs = base + idx; base = abs + 14
        before = substr($0, 1, abs - 1)
        # Parentheses name other reviewers incidentally and are never the
        # subject of the claim, so drop them before locating it.
        while (match(before, /\([^()]*\)/)) before = substr(before, 1, RSTART - 1) substr(before, RSTART + RLENGTH)
        # The subject is the LAST standalone capital A-F still standing.
        subj = ""; n = length(before)
        for (i = 1; i <= n; i++) {
          c = substr(before, i, 1)
          if (c !~ /^[A-F]$/) continue
          p = (i > 1) ? substr(before, i - 1, 1) : " "
          q = (i < n) ? substr(before, i + 1, 1) : " "
          if (p !~ /[A-Za-z]/ && q !~ /[A-Za-z]/) subj = c
        }
        if (subj != "B") printf("%s:%d names %s\n", FILENAME, FNR, (subj == "" ? "no reviewer" : subj))
      }
    }
  ' "$rr_f" 2>/dev/null); then
    red "  FAIL the [77] standing-member scan discovered a file it could not then read, so its roster claim was never judged: $rr_f"
    FAILED=$((FAILED + 1))
    continue
  fi
  [ -n "$rr_out" ] && RR_SM_BAD="$RR_SM_BAD$rr_out
"
done < <(/usr/bin/grep -rlIi --null -- 'standing member' "${RR_SM_DIRS[@]}" "${RR_SM_FILES[@]}" 2>/dev/null)

# Vacuous-pass guard, part two: the discovery itself. A root can exist and still
# be the wrong root, so the scan is required to actually reach a file already
# known to carry the phrase. This asserts the MECHANISM, not a file set. Matched
# inside the loop above rather than against a captured list, because that list is
# NUL-delimited now and a command substitution drops NUL bytes outright.
if [ "$RR_SM_HITANCHOR" -eq 1 ]; then
  green "  ok   the [77] standing-member scan reaches $RR_SM_ANCHOR, so its discovery still resolves"
else
  red "  FAIL the [77] standing-member scan found no 'standing member' claim in $RR_SM_ANCHOR, so its discovery is broken and the scan below measures nothing"
  FAILED=$((FAILED + 1))
fi

# Vacuous-pass guard, part three: the invariant's authority. A pin that outlives
# the rule it enforces is worse than no pin, so if the canonical sentence leaves
# the docs this check goes red instead of policing a dropped rule.
check_token_present 'B is the standing member' "$RR_SM_ANCHOR"

if [ "$RR_SM_N" -eq 0 ]; then
  # A clean verdict over an empty set is the vacuous pass this block exists to
  # refuse, so it is reported as a failure rather than printed as a green.
  red "  FAIL the [77] standing-member scan matched no file at all under ${RR_SM_DIRS[*]} ${RR_SM_FILES[*]}, so its clean verdict measured nothing"
  FAILED=$((FAILED + 1))
elif [ -z "$RR_SM_BAD" ]; then
  green "  ok   every 'standing member' claim names B ($RR_SM_N files scanned under ${RR_SM_DIRS[*]} ${RR_SM_FILES[*]})"
else
  # Read from a here-doc rather than a pipe: a piped loop runs in a subshell and
  # its FAILED increments would be discarded, printing red and exiting 0.
  while IFS= read -r rr_l; do
    [ -n "$rr_l" ] || continue
    red "  FAIL $rr_l as the panel's standing member; B is the only standing member (A, D and F are evidence-gated, E joins on UI-bearing diffs)"
    FAILED=$((FAILED + 1))
  done <<RR_SM_EOF
$RR_SM_BAD
RR_SM_EOF
fi

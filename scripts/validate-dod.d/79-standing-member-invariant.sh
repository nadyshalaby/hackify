# shellcheck shell=bash

# [79] THE CONDITIONAL-LENS INVARIANT, split out of 77-reviewer-roster.sh in the
# sprint that file reached 499 of 500 LOC and could not take another line, and
# re-aimed in 0.16.0 when the rule it enforced was retired.
#
# WHAT CHANGED AND WHY THIS FILE DID NOT GO WITH IT. Until 0.16.0 the Phase 5
# panel had exactly one standing member, B, and A, D and F were gated on evidence.
# This block located the SUBJECT of every 'standing member' claim in the tree and
# required it to be B. Un-gating the panel deleted that rule outright: A, B, D and
# F all run now. The block's own header said a check whose authority leaves must go
# RED rather than keep policing a dropped rule, so the honest options were to
# delete it or to re-aim it, and deleting the FILE is not one of them: validate-dod.sh
# sources fragments by name and [76f] and [0] check that wiring both ways.
#
# IT WAS RE-AIMED, NOT RETIRED, because the defect CLASS survived the rule. There
# is still exactly one conditional lens on that panel and it is E, and a sentence
# naming any other letter as conditional is wrong in any phrasing. The subject is
# still what has to be located, so every paragraph below about locating one, about
# stripping parentheticals, and about a subject-free mention counting as a defect,
# holds unchanged. Only the phrase and the required letter moved.
#
# THE SEAM IS THE GRAMMAR, and [77] named it before there were two files: that
# block did its work in TWO grammars, over two disjoint file sets, with two
# different matchers. COUNT grammar, which bans stale reviewer arithmetic over a
# hand-written six-file set, stays in 77-reviewer-roster.sh. ROSTER-CLAIM
# grammar, which asks which LETTER a sentence asserts to be the panel's standing
# member over a set this block discovers for itself, is here. The two never
# shared a line of code, and every paragraph arguing for this half moved with
# it, whole and unsummarised.
#
# WHICH NUMBER MEANS WHICH. Every verdict this block prints says [79], because
# a red line that names the check you have to open is the whole point of the
# label. The comments still say [77] wherever they point at the sibling that
# kept that ID, which is a reference and not a self-description. The RR_SM_
# variable prefix is left alone: it is a namespace, and renaming it would churn
# every line of an algorithm this split deliberately did not touch.
#
# THE AUTHORITY BOTH HALVES ENFORCE is written once, under WHY THIS EXISTS in
# 77-reviewer-roster.sh: the Phase 5 panel stopped being a fixed number in
# v0.13.0. It is not copied here, because two copies of a rationale are two
# things that drift apart, which is the defect class both blocks exist to
# refuse. The short form is the sentence this block pins as its own authority,
# 'E is the only conditional lens'.
#
# The settle round after that found three MORE, and not one of them was a count
# defect, which is exactly why every token in [77]'s ban loop was blind to all
# three:
#   phase-5-multi-review-f-coherence.md:205  "**Standing member.** F runs on
#                                             every non-trivial diff"
#   phase-5-multi-review-a-security.md:174   "Reviewers D ... and F ... **are
#                                             standing members of every wave**"
#   references/review-and-verify.md:384      "dispatch two reviewers in parallel"
# The first two name the wrong LETTER, not the wrong number, so no count ban
# could ever have reached them. The third is a claim [77] already bans
# ("two parallel reviewers") with its words in the other order. So the guard
# widened past count grammar into roster-claim grammar and into phrase order.
#
# AUTHORIZATION, stated honestly. The standing decision behind this guard
# authorized guarding stale reviewer COUNT drift, so extending it to
# standing-member grammar is a WIDENING of an approved decision, not a defect in
# the guard as that decision approved it.
#
# COVERAGE, STATED HONESTLY. [77]'s header counts this half as one of the three
# jobs the roster guard did while both grammars still shared a file. Those two
# paragraphs moved here whole, their indentation included, so the words below
# are the ones that were reviewed rather than a retelling of them.
#
#   PATHLESS, one invariant. The check names no file at all. It discovers its own
#   set with grep -rl over skills/ agents/ rules/ commands/ and README.md. The file
#   total is deliberately not written down here: the green line below reports what
#   the scan actually reached, and the count moves whenever anyone rewords a roster
#   sentence, which is noise a hand-pinned number would only invite bumping. rules/ and commands/ are scanned too and currently match
#   nothing; they are in the root list because a roster claim can land there,
#   not because one has. A hand-kept list would have been worse than useless
#   here: BOTH roster defects lived in files the six-file list does not name,
#   so a list-scoped version of this check would have run green over the two
#   sentences it exists to catch. The list is not the unit of coverage, the
#   claim is.
#
#   README.md is a FILE root because it carries a live roster claim that nothing
#   guarded, the roots being four directories with the
#   repo's most-read document outside all of them. CHANGELOG.md and docs/ are
#   deliberately NOT roots, on the SHAPE of what the awk finds there and never a
#   census of it: every CHANGELOG.md hit is release text correct for the roster
#   as it stood when written, so older entries name F and A legitimately, and
#   every docs/work/ hit quotes a defect sentence to record it. History is not
#   drift. No line numbers or counts here on purpose: the version that cited two
#   CHANGELOG.md hits as "measured rather than assumed" had both moved in-sprint.
#
# THE CONDITIONAL-LENS INVARIANT, and why it is not a token ban. There is exactly
# one conditional lens on the Phase 5 panel and it is E. Every other letter
# asserted as conditional is wrong in any phrasing, so the defect is not a word,
# it is a subject. The two sites found this sprint share no surface form at all:
# one is plural mid-sentence ("Reviewers D ... and F ... are standing members of
# every wave"), the other opens a line as a bare "**Standing member.**" heading
# with no subject before it, and THAT one also carries a perfectly legitimate
# bare "B" later in the line ("as A, B and D"). So the obvious "does the line
# contain B" discriminator false-negatives on the second defect, and any regex
# fitted to both fits neither. A subject has to be located, not matched.
#
# THE ALGORITHM. For every occurrence of "conditional lens" (case-insensitive),
# take the text preceding THAT occurrence, delete parenthetical spans from it,
# then take the LAST standalone capital A-F left standing. That letter is the
# claim's subject and it MUST be E. Any other letter fails, and so does no
# letter at all. "Standalone" means the character has no ASCII letter on either
# side, so it never matches a letter inside a word.
#
# Stripping parentheticals is LOAD-BEARING and was not in the first draft. Under
# the retired rule, skills/yolo/SKILL.md legitimately read "B (... v0.13.0 merged
# Reviewer C into it) is the standing member", and a raw backward scan read the
# subject as C out of that aside and reddened a correct sentence. It bites the same
# way on the rule that replaced it: "E (design conformance) is the one conditional
# lens" reads as D without the strip. Parentheses name other reviewers incidentally
# and are never the subject of the claim.
#
# Every occurrence on a line is judged, not just the first. These files carry
# single lines hundreds of characters long (one yolo/SKILL.md table cell is a whole
# paragraph), so a second claim appended to a line that already carries a correct
# one is a live way back in. No line in the current set states the phrase twice, so
# the loop does not fire on today's prose; it exists for the line that will.
#
# A SUBJECT-FREE MENTION IS TREATED AS A DEFECT, deliberately, and this is the
# one rule here that can redden prose an author believes is fine. The class is
# wider than the mild case this used to quote: the subject is only ever looked
# for BEFORE the phrase, so ANY sentence putting it AFTER reads as subject-free
# and reddens, however correct the claim is. Verified with the awk below rather
# than reasoned about under the retired rule, and the shapes carry over unchanged:
# "The panel's conditional lens is E." reports `names no reviewer`, and so does
# "the panel has exactly one conditional lens". None of those shapes exists in the
# scanned set today, which is the only reason the rule is affordable. It is bought
# because subject-free is the exact shape of the f-coherence defect that motivated
# it: a bare "**Standing member.**" heading whose body then named the wrong lens. The fix an author owes is one word
# in one place, put the letter in front of the phrase. Teaching the algorithm to
# read a subject that FOLLOWS the phrase is a real change to it and is
# deliberately not made here; disclosing what it actually refuses is.
#
# NO PATH LIST, ON PURPOSE, and one relevance anchor instead. See PATHLESS
# above for why a list would have run green over both defects. That leaves the
# vacuous-pass problem this block otherwise solves by asserting its paths, so it
# is solved two other ways: the discovery is asserted to actually reach a file
# known to contain the phrase, and the canonical correct sentence "E is the only
# conditional lens" is pinned present in phases/phase-5-review.md. If that
# sentence ever leaves, the invariant has lost the authority it is enforcing and
# this check must go red rather than keep policing a rule the docs dropped. That
# is not hypothetical: it is what happened to this block's first rule, and the pin
# is what made the retirement visible instead of silent.

yellow "[79] the conditional-lens-is-E invariant, over every file that claims one"

# The conditional-lens invariant. Deliberately pathless: it discovers its own set
# rather than reading one, because both defects it exists to catch lived outside
# the six-file list above. See THE CONDITIONAL-LENS INVARIANT in the header for
# the algorithm, for why parenthetical spans are stripped before the subject is
# located, and for why a subject-free mention counts as a defect.
#
# /usr/bin/grep by absolute path, and WHICH SHELL is the whole question. Under the
# BASH this validator runs in, bare grep already IS /usr/bin/grep; the interactive
# ZSH here wraps grep in a function honouring ignore files, returning nothing and
# exiting 0, the exact vacuous pass this block guards. check_no_token now names the
# path too, so this scan, the batched screen and its fallback are one binary.
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
  red "  FAIL [79] conditional-lens scan root '$rr_d' is not a directory, so every roster claim under it has silently left coverage"
  FAILED=$((FAILED + 1))
  RR_SM_ROOTBAD=1
done
if [ "$RR_SM_ROOTBAD" -eq 0 ]; then
  green "  ok   all ${#RR_SM_DIRS[@]} [79] conditional-lens scan directory roots resolve"
fi

RR_SM_FILEBAD=0
for rr_d in "${RR_SM_FILES[@]}"; do
  [ -s "$rr_d" ] && continue
  red "  FAIL [79] conditional-lens scan file root '$rr_d' is missing or empty, so the roster claim it carries has silently left coverage"
  FAILED=$((FAILED + 1))
  RR_SM_FILEBAD=1
done
if [ "$RR_SM_FILEBAD" -eq 0 ]; then
  green "  ok   the [79] conditional-lens scan file root(s) ${RR_SM_FILES[*]} exist and are non-empty"
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
# a piped loop is a subshell that discards every count it keeps. It discards
# grep's own status too, so that rides the stream as a last 'rc:N' record no real
# path can collide with; RR_SM_RC starts at 2, so one that never arrives fails.
RR_SM_N=0
RR_SM_RC=2
RR_SM_HITANCHOR=0
RR_SM_BAD=""
while IFS= read -r -d '' rr_f; do
  case $rr_f in rc:*) RR_SM_RC=${rr_f#rc:}; continue ;; esac
  RR_SM_N=$((RR_SM_N + 1))
  [ "$rr_f" = "$RR_SM_ANCHOR" ] && RR_SM_HITANCHOR=1
  # awk exits 2 on a path it cannot open, so that status is CHECKED. Closes the
  # whole unreadable-path class, not just the newline that exposed it: a file
  # discovered and not read is a file never judged, and that has to be loud.
  if ! rr_out=$(awk '
    {
      low = tolower($0); base = 0
      while (1) {
        idx = index(substr(low, base + 1), "conditional lens")
        if (idx == 0) break
        # 15 = length("conditional lens") - 1, so the next search starts just
        # past this match and a second claim on the same line is still judged.
        abs = base + idx; base = abs + 15
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
        if (subj != "E") printf("%s:%d names %s\n", FILENAME, FNR, (subj == "" ? "no reviewer" : subj))
      }
    }
  ' "$rr_f" 2>/dev/null); then
    red "  FAIL the [79] conditional-lens scan discovered a file it could not then read, so its roster claim was never judged: $rr_f"
    FAILED=$((FAILED + 1))
    continue
  fi
  [ -n "$rr_out" ] && RR_SM_BAD="$RR_SM_BAD$rr_out
"
done < <(/usr/bin/grep -rlIi --null -- 'conditional lens' "${RR_SM_DIRS[@]}" "${RR_SM_FILES[@]}" 2>/dev/null; printf 'rc:%d\0' "$?")

# Vacuous-pass guard, part two: the discovery itself. A root can exist and still
# be the wrong root, so the scan is required to actually reach a file already
# known to carry the phrase. This asserts the MECHANISM, not a file set. Matched
# inside the loop above rather than against a captured list, because that list is
# NUL-delimited now and a command substitution drops NUL bytes outright.
if [ "$RR_SM_HITANCHOR" -eq 1 ]; then
  green "  ok   the [79] conditional-lens scan reaches $RR_SM_ANCHOR, so its discovery still resolves"
else
  red "  FAIL the [79] conditional-lens scan found no 'conditional lens' claim in $RR_SM_ANCHOR, so its discovery is broken and the scan below measures nothing"
  FAILED=$((FAILED + 1))
fi

# Vacuous-pass guard, part three: the invariant's authority. A pin that outlives
# the rule it enforces is worse than no pin, and this block is now its own proof:
# when the gate retired, the pin standing here went red and said so, which sent a
# reader to this file instead of letting it police a rule the docs had dropped.
# [70] pins the POSITIVE half over this same file, the four-lens roster sentence.
# Pinned here is the EXCLUSIVITY half, pinned nowhere else, and deliberately not a
# prefix of [70]'s literal so it can redden first. Cited by token, not by line.
check_token_present 'E is the only conditional lens' "$RR_SM_ANCHOR"

# Vacuous-pass guard, part four: the discovery's OWN exit status, discarded until
# now. grep exits 1 on "matched nothing" (the RR_SM_N gate below judges that) and
# 2+ on a root it could not read while still printing the roots it COULD, leaving
# that root's files unjudged with RR_SM_N non-zero and the anchor still hit.
if [ "$RR_SM_RC" -gt 1 ]; then
  red "  FAIL the [79] conditional-lens discovery exited $RR_SM_RC, so a root under ${RR_SM_DIRS[*]} ${RR_SM_FILES[*]} was unreadable and every roster claim inside it went unjudged"
  FAILED=$((FAILED + 1))
fi

if [ "$RR_SM_N" -eq 0 ]; then
  # A clean verdict over an empty set is the vacuous pass this block exists to
  # refuse, so it is reported as a failure rather than printed as a green.
  red "  FAIL the [79] conditional-lens scan matched no file at all under ${RR_SM_DIRS[*]} ${RR_SM_FILES[*]}, so its clean verdict measured nothing"
  FAILED=$((FAILED + 1))
elif [ -z "$RR_SM_BAD" ]; then
  green "  ok   every 'conditional lens' claim names E ($RR_SM_N files scanned under ${RR_SM_DIRS[*]} ${RR_SM_FILES[*]})"
else
  # Read from a here-doc rather than a pipe: a piped loop runs in a subshell and
  # its FAILED increments would be discarded, printing red and exiting 0.
  while IFS= read -r rr_l; do
    [ -n "$rr_l" ] || continue
    red "  FAIL $rr_l as a conditional lens; E is the only conditional lens (A, B, D and F each run on every non-trivial diff)"
    FAILED=$((FAILED + 1))
  done <<RR_SM_EOF
$RR_SM_BAD
RR_SM_EOF
fi

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

yellow "[75f] Phase 5 closes once, and the clause that says so is intact AND unqualified at every site that states it"
# Was: the settled-diff exit condition, which policed a review LOOP. The 0.16.0
# round cap removed the loop, so that premise is gone and writing the old phrase
# back would leave a pin green over a doc asserting the opposite. What still
# needs guarding is the cap's hard edge: soften "no second review" and the loop
# quietly returns with nothing to notice.
#
# AND THE CLAUSE NAMES A DISPATCH, NOT A ROUTE, WHICH IS WHY IT MOVED OFF "panel".
# The panel stopped being what a round dispatches when the merged all-lens reviewer
# became the default in every mode, so a cap worded "no second panel" capped a route
# the default no longer takes and said nothing at all about the one it does. The
# counted unit is a whole dispatch: five panel lenses are ONE review and the merged
# reviewer is ONE review, so "no second review" holds both routes at the same cap
# and matches the sentence above it verbatim ("exactly ONE review and ONE refuter").
#
# THE SUBSTRING PIN COULD NOT SEE THE SOFTENING IT NAMED, measured rather than argued.
# Reword the sentence as "There is normally no second review, no second refuter and no
# re-scan, unless the fixes changed enough to warrant one" and the pinned run of words
# survives untouched between the two qualifiers; the pin printed green and its own ok
# line called that "without an escape hatch", so the cap was a default rather than a cap.
#
# THREE HALVES NOW. The pin is unchanged, a fixed-string test on the clause, because a
# longer literal breaks on the next legitimate reword of the tail and a pin that reds on
# correct edits gets weakened later, which is how a check dies. Beside it is a SOFTENER
# BAN over the sentence carrying the clause, EXTRACTED from the file rather than written
# down here, so a qualifier on either side of the clause is in scope. Both now run over
# every site rather than one, and the third half discovers what the sites are.
#
# WHAT IT DOES NOT REACH, said here rather than found out later, since a comment that
# overstates its check is the defect this block has now twice fixed in itself. The scope
# is ONE sentence: a softening written as a NEIGHBOURING sentence sits outside it, and
# widening to the whole numbered step would put the ban over the paragraph that
# legitimately argues what the cap gives up. The bare word if stays off the list below
# for the same trade pointed the other way, since "even if the fixes changed everything"
# is a correct absolute reword. And a file that states the cap in its OWN words, the
# phase-ledger exit row and the refuter template, carries no clause for either half to
# read; those two point at the canonical text rather than restating it, which is why the
# guarded set is the files that state the cap in full.
#
# EVERY COPY IS GUARDED, NOT THE CANONICAL ONE, and that half is a correction. Both
# halves used to run over review-and-verify.md alone, which is the file that says the
# reasoning is canonical SOMEWHERE ELSE, so the ban sat on the derivative statement and
# left the canonical one open: reword the cap in phases/phase-5-review.md and the whole
# bar printed green, measured. Canonical-only was the wrong shape whichever file it had
# picked. A hackify run never loads one canonical doc, it loads whichever reference the
# phase in hand needs, so the copy a reader reaches IS the instruction governing that
# run, and a softener planted in it ships. Guarding all four costs one grep each, so no
# budget argument chooses between them, and the argument that a copy is a summary free
# to paraphrase is exactly what produced three wordings of one rule.
#
# NO COUNT IS WRITTEN INTO THIS COMMENT ANY MORE. It read "the clause is worded this way
# in exactly one live file, measured", and phases/phase-5-review.md falsified it while
# the pin below sat on the other copy: a check written to police claim rot shipped a
# rotted claim as its own scope justification. The convention it broke is the one
# 98-work-doc-ledger-sync.sh states beside its floors and scripts/tamper_harness.py
# states above its fragment map, that an unpinned number in a comment is a rotting claim
# and the fix is to stop writing the number rather than to refresh it. So the scope is
# the SB_CAP_SITES list, whose size is asserted against a hand-written bound, and the
# live answer prints on the pass lines below instead of sitting up here going stale.
#
# A PIN MAY FREEZE WORDING; IT MAY NOT ALSO CARRY THE SCOPE CLAIM IN PROSE BESIDE IT.
# That seam is the answer to the objection that a verbatim pin cannot tell "this sentence
# must stay true" from "this sentence must stay verbatim". No shell check evaluates
# truth. Where a measurement exists, measure: the softener scan EXTRACTS the sentence
# rather than restating it, and the site set is DISCOVERED from the tree rather than
# written down. Where none exists a literal is what is left, and loosening it buys
# nothing, because a fuzzy pin passes the reword that changed the meaning, which is the
# failure it was bought to stop. A verbatim pin fails LOUDLY on a correct edit and the
# editor moves the pin in the same commit; a loose one fails SILENTLY on a wrong edit and
# ships. What resisted the correction here was never the literal, it was the scope claim
# frozen in a comment nothing re-derives.
RAV="skills/hackify/references/review-and-verify.md"
SB_CAP_CLAUSE='no second review, no second refuter and no re-scan'
SB_CAP_SITES=("$RAV" 'skills/hackify/references/phases/phase-5-review.md')
SB_CAP_SITES+=('skills/hackify/references/review-scope.md' 'skills/hackify/SKILL.md')
# Hand-written beside the list, the shape [40], [77], [80] and [89] use: a bound read
# out of the list cannot police it. It is also the number the discovery scan below
# compares against, so this line is what keeps that comparison from grading itself.
check_list_size "${#SB_CAP_SITES[@]}" 4 "the [75f] cap-site list"

# Every entry is a word that cannot appear in an absolute statement of the cap, so a hit
# is a qualifier rather than a wording choice. The size is hand-written beside the list,
# the shape [40], [77], [80] and [89] use: a bound read out of the list cannot police it.
SB_HEDGES=('unless' 'except' 'normally' 'usually' 'typically')
SB_HEDGES+=('generally' 'ordinarily' 'by default' 'discretion' 'warrant')
check_list_size "${#SB_HEDGES[@]}" 10 "the [75f] cap-softener list"

# NO PIPE ANYWHERE, what check [84] bans: the here-string hands tr a whole value.
sb_softened() {
  local hay h
  hay=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  for h in ${SB_HEDGES[@]+"${SB_HEDGES[@]}"}; do
    case "$hay" in *"$h"*) printf '%s' "$h"; return 0 ;; esac
  done
  return 1
}

# THE POSITIVE CONTROL, AND IT IS THE MEASURED EVASION ITSELF. Everything the ban can
# print on success is an absence, worth what the scan could have found. So the sentence
# that defeated the old pin goes through the same matcher first, and this block refuses
# unless it comes back dirty. ONE control for the four sites, not four: the matcher is a
# single function over a string, so a control per site would prove one fact four times.
sb_ctl='There is normally no second review, no second refuter and no re-scan, unless the fixes changed enough to warrant one.'
if sb_hit=$(sb_softened "$sb_ctl"); then
  green "  ok   the [75f] softener scan catches its own planted control on '$sb_hit', so a clean verdict from it is a measurement"
else
  red "  FAIL [75f] the softener scan missed the qualifier in its own planted control, so a clean verdict on the real clause would mean nothing"
  FAILED=$((FAILED + 1))
fi

# rc IS READ BEFORE THE OUTPUT, the contract check_no_token states in 00-helpers.sh:
# grep says 1 for a clean sweep and above 1 for a scan that never ran, and an empty
# extraction would clear all ten hedges having read nothing. Periods bound the sentence.
sb_cap_site() {
  local f="$1" sent rc hit
  if ! grep -qF -- "$SB_CAP_CLAUSE" "$f"; then
    red "  FAIL $f missing the no-second-review clause (deleting it silently restores the review loop the cap replaced)"
    FAILED=$((FAILED + 1))
    return
  fi
  green "  ok   $f states the one-review cap clause"
  sent=$(/usr/bin/grep -oE "[^.]*${SB_CAP_CLAUSE}[^.]*\." "$f" 2>/dev/null)
  rc=$?
  if [ "$rc" -gt 1 ] || [ -z "$sent" ]; then
    red "  FAIL [75f] could not extract the sentence carrying '$SB_CAP_CLAUSE' from $f (grep exited $rc), so the softener scan would have cleared it having read nothing"
    FAILED=$((FAILED + 1))
  elif hit=$(sb_softened "$sent"); then
    red "  FAIL [75f] the cap sentence in $f is qualified by '$hit', so the cap is a default rather than a cap and the review loop is back:"
    printf '%s\n' "$sent" | sed 's/^/         /'
    FAILED=$((FAILED + 1))
  else
    green "  ok   the cap sentence in $f carries none of the ${#SB_HEDGES[@]} softeners"
  fi
}
for sb_f in ${SB_CAP_SITES[@]+"${SB_CAP_SITES[@]}"}; do sb_cap_site "$sb_f"; done

# THE SET IS PINNED IN BOTH DIRECTIONS, which is what turns review-scope.md's claim that
# the wording is held identical into a measurement rather than an assertion. The four
# pins above prove every LISTED site carries the clause; this proves no UNLISTED one
# does, discovering the carriers over the same two roots 96-review-scope-sites.sh
# discovers the cap's opening sentence over. Discovery is the half a hand-kept list
# cannot do, for that check's reason: the site that goes stale is the one nobody
# remembered to list. The expected number is the list's own length, which is only
# legitimate because check_list_size above already pinned that length to a hand-written
# 4, so the chain ends on a number no edit to the list can move.
sb_cap_found=$(/usr/bin/grep -rlIF -- "$SB_CAP_CLAUSE" skills agents 2>/dev/null)
sb_cap_rc=$?
sb_cap_n=0
[ -n "$sb_cap_found" ] && sb_cap_n=$(printf '%s\n' "$sb_cap_found" | wc -l | tr -d ' ')
if [ "$sb_cap_rc" -gt 1 ]; then
  red "  FAIL [75f] could not scan skills and agents for the cap clause (grep exited $sb_cap_rc), so a count of 0 here would be a count of nothing"
  FAILED=$((FAILED + 1))
else
  check_list_size "$sb_cap_n" "${#SB_CAP_SITES[@]}" "the files under skills and agents carrying the cap clause"
fi
if [ "$sb_cap_rc" -le 1 ] && [ "$sb_cap_n" -ne "${#SB_CAP_SITES[@]}" ]; then
  red "  ---- the $sb_cap_n discovered file(s) were:"
  printf '%s\n' "$sb_cap_found" | sed 's/^/        /'
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
    green "  ok   ${mirror##*/} is byte-identical to ${canonical##*/}"
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
  printf '%s\n' "$TAIL_REPORT" | grep -F 'FAIL' | awk 'NR<=6' | sed 's/^/         /'
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
    green "  ok   ${wi_file##*/} head carries all $WI_CLAUSE_TOTAL duplicated dispatch-rule clauses"
  fi
done <<<"$WI_HEAD_FILES"

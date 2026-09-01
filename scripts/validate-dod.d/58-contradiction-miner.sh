# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [58] THE CONTRADICTION MINER, over a hand-written table of routing predicates.
#
# THE GAP THIS WAS BUILT FOR, MEASURED RATHER THAN ARGUED. The fragment count that
# used to sit in the sentence below is gone rather than refreshed, for the reason
# 88-plugin-map.sh gives beside the same measurement: it read 35 against a directory
# of 47, and a number nothing pins is a claim that rots.
#
# [88] reads the orientation map from both ends, and BOTH ends are about
# EXISTENCE: every row it names resolves to a file on disk, and every entry point
# the tree ships carries exactly one row. Measured on this tree: a wave falsified
# two agent descriptions without touching a single token, ran EVERY fragment the
# validator sources plus the mirror check, and nothing moved. Breaking one token
# in the same cell raised five reds. So the tree detects a RENAMED thing and is
# blind to a LYING one, and the two findings that proved it were both routing
# claims:
#   (a) the map said the full workflow fires when the size test in quick
#       escalates, while skills/quick/SKILL.md says in as many words that no
#       diff-size, file-count, attempt-counter or path-pattern check ever
#       auto-promotes;
#   (b) an agent description said the all-lens reviewer was for quick mode and
#       for that round alone, while phase-5-review.md already said Phase 5
#       dispatches it in every mode.
# In both cases the negation was ALREADY WRITTEN DOWN somewhere a check could
# read it. That is the whole opening this fragment works in, and it is a small
# one on purpose.
#
# WHAT IT DOES NOT ASK. Not "is this description true". That needs a reader, and
# a check that pretends otherwise is a check that cannot fail. What it asks is
# narrower and mechanical: does a file ASSERT not-X where a named authority
# asserts X, for a routing predicate that has both a polarity and a place the
# opposite polarity would be written. The predicate kinds that work are the ones
# with two sides and nothing in between: auto-fires versus never auto-fires,
# escalates versus never escalates, default route versus on request, one mode
# only versus every mode.
#
# THE SIMILARITY-SCORING VERSION IS REFUSED. Comparing a description against the
# file it describes and reporting a distance is the same check-that-cannot-fail
# in a disguise: the number is always producible, it never resolves to a defect,
# and nobody can say what value should redden. If a predicate cannot be made
# mechanical it is LEFT OUT and PRINTED AS UNCOVERED, which is a worse-looking
# report and a more honest one.
#
# BOTH HALVES ARE PRINTED, WHAT WAS COVERED AND WHAT HAD NO PREDICATE. A miner
# that silently examines four of nineteen entry points and reports clean is
# precisely the shape this sprint has now found six of. So the routing surface
# is DISCOVERED per run from skills/, commands/ and agents/, every entry the
# table covers is named, and every entry it does not is listed by path. The
# uncovered list is a note and not a red, deliberately: reddening on it would
# make the only honest way to a green bar a table that claims predicates it does
# not have. What it is instead is the gap, stated, every run.
#
# THE TABLE AND ITS BOUND ARE BOTH HAND-WRITTEN, per the argument above
# check_list_size in 00-helpers.sh: a bound read back out of the list it polices
# drops with the list and stays green. MINE_EXPECT below is the number a reviewer
# reads; the row-alignment guard beside it is a different question and is allowed
# to be derived, because parallel arrays that fall out of step corrupt every row
# after the seam rather than shortening the table.
#
# THE NEGATOR SUBTRACTION IS SENTENCE-SCOPED, AND IT HAD TO BE. Every one of
# these files talks about the rule as often as it states it, so a deny matcher
# alone reddens on "quick mode never auto-promotes" as readily as on the
# contradiction. A hit is therefore cleared when the sentence carrying it also
# carries a negator from the shared vocabulary below.
#
# THE FIRST VERSION OF THIS CLEARED PER LINE, AND THE REAL DEFECT PROVED IT
# WRONG. Finding (a) shipped as one markdown table cell reading "The full
# workflow. On request, or when quick's own size test escalates. Never
# auto-fires." Three sentences, one line: the contradiction sits in the second
# and the word "Never" sits in the third, so a line-scoped clear swallowed the
# very defect this fragment was written for and printed green. Measured on the
# committed text, not imagined. So a line is split on sentence boundaries first
# and each unit is judged alone.
#
# What survives that fix is a narrower limitation, and it is real: a
# contradiction and a negator inside ONE sentence still cancel. The cleared count
# is PRINTED per predicate rather than dropped silently, so the subtraction is
# auditable instead of invisible, and a cleared count that collapses to zero
# means the corpus stopped talking about the rule at all, which is worth seeing.
#
# EVERY PREDICATE CARRIES ITS OWN PLANT, and the plant is what makes the green
# below mean anything. The deny matcher must match that predicate's planted
# contradiction, and the negator vocabulary must NOT clear it. Without that pair
# a matcher that had quietly stopped matching anything would print the same clean
# verdict as one that works, which is the failure every control in this validator
# exists to refuse.
#
# THE AUTHORITY IS RE-READ EVERY RUN, NOT TRUSTED. Each row names the file and
# the verbatim sentence that makes the predicate law. If that sentence is gone,
# the row is stale and the check reddens rather than going on policing a rule the
# repo may have abandoned: the table has no standing of its own and is not
# allowed to become a second, quieter source of routing law.
#
# ONE ID AND NOT A RANGE, for the reason the 83, 86, 87, 88 and 99 rows in
# scripts/validate-dod.d/README.md give: this fragment declares exactly one check
# and a range endpoint would assert a maximum it does not have.
yellow "[58] no routing file asserts not-X where a named authority asserts X, and every entry point with no predicate is printed"

# THE NEGATOR VOCABULARY, SHARED BY EVERY ROW ON PURPOSE. One vocabulary is
# printed once, reviewed once and cannot be tuned per predicate to make an
# inconvenient hit disappear, which a per-row clear matcher invites.
MINE_CLEAR='never|not |n.t |no |none|nothing|cannot|ruled out|refus|only when the user|user-initiated|stopped being|is not|neither'

# A newline, so a membership test can fence its haystack and match a WHOLE line.
MINE_NL=$'\n'

# THE SENTINEL mine_units PRINTS FROM ITS `END` BLOCK. Status alone does not
# settle whether awk read the file: on awk 20200816 a mode-000 file gives rc 2
# plus stderr, a DIRECTORY rc 0 with both empty. `END` runs only when awk read to
# the end, and cannot collide with a `number<TAB>text` record.
MINE_UNITS_END='#MINE-UNITS-END'

# The routing surface floor. Nineteen entry points ship today; a discovery that
# collapses below this measured nothing, and says so rather than printing a clean
# coverage table over an empty set.
MINE_SURFACE_FLOOR=15

# --- the predicate table, hand-written, one index per row --------------------
MINE_ID=()
MINE_CLAIM=()
MINE_AUTH_FILE=()
MINE_AUTH_TOK=()
MINE_DENY=()
MINE_SITES=()
MINE_COVERS=()
MINE_PLANT=()

# P1. Finding (a) above. The authority sentence is quick's own, and it is the
# strongest wording in the repo on this: a named list of the four signals that
# do NOT promote. The deny matcher takes two shapes, because the contradiction
# that actually shipped carried neither the word "auto" nor the word "promote":
# it asserted a CONDITION ("when the size test in quick escalates"), which is
# the same claim spelled as a trigger.
MINE_ID+=('P1')
MINE_CLAIM+=('full mode never auto-fires, and nothing about a diff promotes quick into it')
MINE_AUTH_FILE+=('skills/quick/SKILL.md')
MINE_AUTH_TOK+=('No diff-size, file-count, attempt-counter, or path-pattern check ever auto-promotes.')
MINE_DENY+=('auto-?(fire|promot|escalat)[a-z]*|(size|diff|file[- ]count|attempt|sensitiv|scope)[^.|]{0,40}(escalat|promot)[a-z]*')
MINE_SITES+=($'rules/plugin-map.md\nskills/quick/SKILL.md\nskills/hackify/SKILL.md\nskills/groom/SKILL.md\nREADME.md')
MINE_COVERS+=($'skills/hackify/SKILL.md\nskills/quick/SKILL.md\nskills/groom/SKILL.md')
MINE_PLANT+=('The full workflow. On request, or when the size test in quick escalates. Never auto-fires.')

# P2. Finding (b) above. One mode only versus every mode, which is the kind that
# rots the moment a route widens and the description it widened past is not
# reopened.
MINE_ID+=('P2')
MINE_CLAIM+=('the all-lens reviewer is the default route in every mode, not in quick alone')
MINE_AUTH_FILE+=('skills/hackify/references/phases/phase-5-review.md')
MINE_AUTH_TOK+=('That is the route in full mode and in quick mode alike.')
MINE_DENY+=('(quick[ -](mode )?(only|alone)|only in quick|quick-only|that round alone)')
MINE_SITES+=($'agents/reviewer.md\nrules/plugin-map.md\nskills/hackify/references/phases/phase-5-review.md\nskills/hackify/references/parallel-agents/phase-5-multi-review-merged.md\nskills/hackify/references/parallel-agents/README.md')
MINE_COVERS+=($'agents/reviewer.md')
MINE_PLANT+=('Phase 5 all-lens reviewer, for quick mode and for that round alone.')

# P3. Default route versus on request, the other half of the same rename. The
# five panel agents stay registered and are dispatched when a user asks for the
# panel by name; a file that puts them back on the default route contradicts the
# authority sentence without renaming anything.
#
# THE SITES ARE THE FIVE AGENT FILES, and they were missing; see the run block
# below, whose second invariant now refuses a row covering what it never scans.
#
# A THIRD DENY SHAPE, for the reason P1 carries two: the contradiction that
# shipped in those five files spelled the default-route claim as an unconditional
# imperative plus a universal frequency, carrying none of the three keywords
# above. The anchor is the whole matcher and carries mine_units' own `FNR<TAB>`
# prefix; unanchored it took six hits over 147 files, all six honest prose and
# this row's own authority among them, the honest ones being CONDITIONAL where
# this is an IMPERATIVE.
MINE_ID+=('P3')
MINE_CLAIM+=('the five-agent panel is dispatched on request by name, never as the default route')
MINE_AUTH_FILE+=('skills/hackify/references/phases/phase-5-review.md')
MINE_AUTH_TOK+=('The panel is what a user can ask for instead')
MINE_DENY+=('panel[^.]{0,40}(by default|is the default|the default route)|(dispatch|route)[a-z]{0,3} [^.]{0,25}panel by default|^[0-9]+[[:blank:]]+[-*_ >]*(dispatch|run|send)[a-z]* the panel[^.]{0,80}(on|in) (every|each|all)')
MINE_SITES+=($'rules/plugin-map.md\nagents/reviewer.md\nskills/hackify/references/phases/phase-5-review.md\nskills/hackify/references/parallel-agents/README.md\nagents/reviewer-security.md\nagents/reviewer-quality-plan.md\nagents/reviewer-performance.md\nagents/reviewer-coherence.md\nagents/reviewer-design.md')
MINE_COVERS+=($'agents/reviewer-security.md\nagents/reviewer-quality-plan.md\nagents/reviewer-performance.md\nagents/reviewer-coherence.md\nagents/reviewer-design.md')
MINE_PLANT+=($'Phase 5 dispatches the five-agent panel by default in both modes.\nDispatch the panel in a single parent assistant message: A, B, D and F each run on every non-trivial diff')

# The bound a reviewer actually reads, written beside the table rather than
# counted off it.
MINE_EXPECT=3
check_list_size "${#MINE_ID[@]}" "$MINE_EXPECT" "the [58] routing-predicate table"

# ROW ALIGNMENT, the one bound here that is allowed to be derived. Parallel
# arrays that fall out of step do not shorten the table, they silently pair one
# row's matcher with another row's authority, and every verdict after the seam is
# then about a predicate nobody wrote.
MINE_ALIGNED=0
for mine_n in "${#MINE_CLAIM[@]}" "${#MINE_AUTH_FILE[@]}" "${#MINE_AUTH_TOK[@]}" \
              "${#MINE_DENY[@]}" "${#MINE_SITES[@]}" "${#MINE_COVERS[@]}" "${#MINE_PLANT[@]}"; do
  [ "$mine_n" -eq "${#MINE_ID[@]}" ] && continue
  MINE_ALIGNED=$((MINE_ALIGNED + 1))
done
if [ "$MINE_ALIGNED" -eq 0 ]; then
  green "  ok   [58] all 8 columns of the predicate table carry ${#MINE_ID[@]} rows, so no row's matcher is paired with another row's authority"
else
  red "  FAIL [58] $MINE_ALIGNED of the 7 non-id columns disagree with MINE_ID's ${#MINE_ID[@]} rows; the parallel arrays are out of step and every verdict past the seam is about a predicate nobody wrote"
  FAILED=$((FAILED + 1))
fi

# ---------------------------------------------------------------------------
# One record per line for the predicate at index $1:
#   DENY<TAB>path:line<TAB>sentence    an assertion of not-X no negator cleared
#   CLEAR<TAB>path:line<TAB>sentence   a hit the negator vocabulary cleared
#   GONE<TAB>path              a site the table names that is not on disk
#   ERR<TAB>path               a read or search that screened nothing
# Exit codes are read rather than swallowed, on the rule check_no_token states in
# 00-helpers.sh: grep says 0 for a hit, 1 for a clean sweep and 2 or more for a
# failure, and a count of zero from a search that errored is a count of nothing.
#
# THAT RULE USED TO BE APPLIED TO THE WRONG PROCESS. Only grep's status was read
# while mine_units is the awk that OPENS the file, whose status died in a nested
# substitution, so ERR was unreachable for the one failure mode it existed for.
# ---------------------------------------------------------------------------
# One SENTENCE per line, each prefixed with the line number it came from, so a
# markdown table cell holding three sentences is judged as three units rather
# than as one line where any negator anywhere clears everything. Split on `.`,
# `;` and the cell pipe, which is where these files actually end a claim.
mine_units() {
  awk -v mu_end="$MINE_UNITS_END" '{
    mu_n = split($0, mu_u, /[.;|]/)
    for (mu_i = 1; mu_i <= mu_n; mu_i++) {
      mu_t = mu_u[mu_i]
      gsub(/^[ \t]+|[ \t]+$/, "", mu_t)
      if (mu_t != "") printf "%d\t%s\n", FNR, mu_t
    }
  }
  END { print mu_end }' "$1"
}

# ONE CLASSIFIER, RUN OVER THE LIVE SITES AND OVER THE PLANT. DRY is not the
# point, IDENTITY is: a positive control that runs a different matcher, or splits
# sentences differently, proves nothing about the real search. $1 is the file, $2
# the predicate index.
# THREE INDEPENDENT SIGNALS THAT THE READ HAPPENED, none covering the set alone:
# `mrc` catches the awk that died, `-s` on the capture the awk that failed with
# no status, the missing sentinel the awk that did neither. Stderr goes to its
# OWN file, never `2>&1`, per 89-reviewer-rename.sh (a warning folded into stdout
# reads as a matched line), and `mrc=$?` stays the next statement after each.
mine_classify() {
  local mf="$1" mi="$2" munits mrows mline mrc
  munits=$(mine_units "$mf" 2> "$MINE_ERR") && mrc=0 || mrc=$?
  if [ "$mrc" -ne 0 ] || [ -s "$MINE_ERR" ]; then printf 'ERR\t%s\n' "$mf"; return 0; fi
  case "$munits" in
    "$MINE_UNITS_END") munits='' ;;
    *"$MINE_NL$MINE_UNITS_END") munits=${munits%"$MINE_NL$MINE_UNITS_END"} ;;
    *) printf 'ERR\t%s\n' "$mf"; return 0 ;;
  esac
  [ -n "$munits" ] || return 0
  mrows=$(grep -iE -- "${MINE_DENY[$mi]}" <<< "$munits") && mrc=0 || mrc=$?
  if [ "$mrc" -gt 1 ]; then printf 'ERR\t%s\n' "$mf"; return 0; fi
  while IFS= read -r mline; do
    [ -n "$mline" ] || continue
    if grep -qiE -- "$MINE_CLEAR" <<< "${mline#*$'\t'}"; then
      printf 'CLEAR\t%s:%s\n' "$mf" "$mline"
    else
      printf 'DENY\t%s:%s\n' "$mf" "$mline"
    fi
  done <<MINE_CLASSIFY_EOF
$mrows
MINE_CLASSIFY_EOF
}

mine_hits() {
  local mi="$1" mf
  while IFS= read -r mf; do
    [ -n "$mf" ] || continue
    if [ ! -f "$mf" ]; then printf 'GONE\t%s\n' "$mf"; continue; fi
    mine_classify "$mf" "$mi"
  done <<MINE_SITES_EOF
${MINE_SITES[$mi]}
MINE_SITES_EOF
}

# The live verdict for one predicate. Counts land in globals rather than on
# stdout, because a `while` on the right of a pipe runs in a subshell and every
# count it made would be discarded at the closing `done`.
MINE_N_DENY=0
MINE_N_CLEAR=0
MINE_N_SITE=0
mine_verdict() {
  local mi="$1" mrec mkind mrest
  MINE_N_DENY=0
  MINE_N_CLEAR=0
  MINE_N_SITE=0
  while IFS= read -r mrec; do
    [ -n "$mrec" ] || continue
    mkind=${mrec%%$'\t'*}
    mrest=${mrec#*$'\t'}
    case "$mkind" in
      CLEAR) MINE_N_CLEAR=$((MINE_N_CLEAR + 1)) ;;
      DENY)
        red "  FAIL [58] ${MINE_ID[$mi]}: $mrest"
        red "       contradicts ${MINE_AUTH_FILE[$mi]}, which states: ${MINE_AUTH_TOK[$mi]}"
        MINE_N_DENY=$((MINE_N_DENY + 1))
        FAILED=$((FAILED + 1)) ;;
      *)
        red "  FAIL [58] ${MINE_ID[$mi]}: the site $mrest is unreadable or its search errored, so this predicate screened less than the table says it did"
        MINE_N_SITE=$((MINE_N_SITE + 1))
        FAILED=$((FAILED + 1)) ;;
    esac
  done <<MINE_VERDICT_EOF
$(mine_hits "$mi")
MINE_VERDICT_EOF
}

# The authority half. A row whose authority sentence has left the tree is stale,
# and a stale row policing a rule the repo may have dropped is worse than no row.
mine_authority() {
  local mi="$1"
  if grep -qF -- "${MINE_AUTH_TOK[$mi]}" "${MINE_AUTH_FILE[$mi]}" 2> /dev/null; then
    green "  ok   [58] ${MINE_ID[$mi]}'s authority still states it, verbatim, in ${MINE_AUTH_FILE[$mi]}"
    return 0
  fi
  red "  FAIL [58] ${MINE_ID[$mi]} cites ${MINE_AUTH_FILE[$mi]} for '${MINE_AUTH_TOK[$mi]}', and that sentence is not there any more; the row is stale, so re-derive the predicate from what the file says now rather than leaving this table as a second source of routing law"
  FAILED=$((FAILED + 1))
  return 1
}

# THE PLANT, RUN THROUGH THE REAL CLASSIFIER. Everything a clean predicate prints
# is a zero, and a zero is worth exactly what the matcher's ability to return
# non-zero is worth. Two ways this goes blind with no error at either end: a deny
# matcher that has stopped matching, and a negator vocabulary grown wide enough to
# clear the contradiction along with the correct text. Both land here as a record
# that is not a DENY.
#
# ONE PLANT LINE PER DENY SHAPE, EACH JUDGED ALONE. One plant against a matcher
# of two or three alternations proves only the shape it hits; the rest could rot
# unseen. The DENY record is SEARCHED FOR, not required first: which record leads
# is grep's line order, never anything this check asserts.
mine_control() {
  local mi="$1" mtmp mout mline mn=0 mbad=0
  mtmp=$(mktemp 2> /dev/null) || mtmp=''
  if [ -z "$mtmp" ]; then
    red "  FAIL [58] ${MINE_ID[$mi]} positive control could not be built (mktemp failed), so the live verdict below was never measured against a known-bad file"
    FAILED=$((FAILED + 1))
    return 1
  fi
  while IFS= read -r mline; do
    [ -n "$mline" ] || continue
    mn=$((mn + 1))
    printf '%s\n' "$mline" > "$mtmp"
    mout=$(mine_classify "$mtmp" "$mi")
    case "$MINE_NL$mout" in
      *"${MINE_NL}DENY"$'\t'*) continue ;;
    esac
    mbad=$((mbad + 1))
    red "  FAIL [58] ${MINE_ID[$mi]} positive control, the classifier returned '$mout' over its planted contradiction '$mline' instead of a DENY; either that deny shape has stopped matching or the negator vocabulary now clears the defect along with the correct text, and the clean verdict below was measured by whichever it is"
    FAILED=$((FAILED + 1))
  done <<MINE_CONTROL_EOF
${MINE_PLANT[$mi]}
MINE_CONTROL_EOF
  rm -f "$mtmp"
  if [ "$mn" -eq 0 ]; then
    red "  FAIL [58] ${MINE_ID[$mi]} plants no contradiction at all, so nothing measured whether its deny matcher can still fire and its clean verdict below is worth nothing"
    FAILED=$((FAILED + 1))
    return 1
  fi
  [ "$mbad" -eq 0 ] || return 1
  green "  ok   [58] ${MINE_ID[$mi]} positive control, the classifier reports each of its $mn planted contradiction(s) as a DENY and no negator in a plant clears it"
  return 0
}

# The routing surface, DISCOVERED per run and never listed here, for the reason
# [86], [87] and [88] all give at their own rosters: a list written into this file
# is a second copy of the tree that rots on the same schedule as the thing it
# describes.
mine_surface() {
  local mp
  for mp in skills/*/SKILL.md commands/*.md agents/*.md; do
    [ -f "$mp" ] || continue
    printf '%s\n' "$mp"
  done
}

# Every path the table claims to cover, one per line.
mine_covered() {
  local mi=0
  while [ "$mi" -lt "${#MINE_COVERS[@]}" ]; do
    printf '%s\n' "${MINE_COVERS[$mi]}"
    mi=$((mi + 1))
  done
}

# ---------------------------------------------------------------------------
# THE COVERAGE REPORT, which is half of what this check is for. It prints the
# entry points a predicate reaches and, by name, every one it does not.
# ---------------------------------------------------------------------------
mine_coverage() {
  local msurf mcov mp mn=0 mhit=0
  local mgap=()
  msurf=$(mine_surface)
  # FENCED BOTH ENDS SO THE MATCH IS AN EXACT WHOLE LINE (the tb_fragment_swept
  # shape); unfenced, `agents/reviewer.md` would satisfy a test for `reviewer.md`.
  mcov="$MINE_NL$(mine_covered)$MINE_NL"
  while IFS= read -r mp; do
    [ -n "$mp" ] || continue
    mn=$((mn + 1))
    # A BUILTIN AND NOT A grep: perf.process.fork-for-builtin in
    # rules/performance.md, a fork doing work the interpreter does inline, over a
    # DISCOVERED surface that grows with the plugin. Best of three through
    # mine_coverage, 760 forks took 1.373s against 0.115s.
    if [ "${mcov#*"$MINE_NL$mp$MINE_NL"}" != "$mcov" ]; then
      mhit=$((mhit + 1))
    else
      # AN ARRAY AND NOT A GROWING STRING, per perf.algorithmic.string-concat-loop
      # in rules/performance.md: the driver here is the discovered surface, so it
      # grows with the tree, and the catalog's fix for that shape is an append to
      # an array plus one printf after the loop.
      mgap+=("$mp")
    fi
  done <<MINE_COVER_EOF
$msurf
MINE_COVER_EOF
  if [ "$mn" -lt "$MINE_SURFACE_FLOOR" ]; then
    red "  FAIL [58] the routing-surface discovery found only $mn entry point(s) across skills/, commands/ and agents/, expected at least $MINE_SURFACE_FLOOR; the discovery collapsed rather than the tree shrinking, so this coverage table was written over nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  green "  ok   [58] $mhit of $mn shipped entry point(s) are reached by a predicate in the table"
  yellow "  note [58] ${#mgap[@]} entry point(s) have NO predicate and were NOT examined by this check:"
  # THE GUARD IS LOAD-BEARING UNDER `set -u`. Expanding an EMPTY array as
  # "${a[@]}" is an unbound-variable error in bash 3.2, which is what the
  # orchestrator and every CI runtime here use, so a table that grew to cover
  # everything would abort the run instead of printing an empty gap.
  [ "${#mgap[@]}" -gt 0 ] && printf '  %s\n' "${mgap[@]}"
  yellow "  note [58] that list is the gap, printed rather than implied; a predicate that cannot be made mechanical belongs there and not in the table"
}

# ---------------------------------------------------------------------------
# The run. TWO INVARIANTS OVER EVERY COVERED PATH, in one pass over the rows.
# The first was here already: a row covering something that does not ship
# inflates the numerator of the coverage line and understates the real gap. The
# second is the half nothing used to ask, since mine_covered feeds that census
# alone: a path a row claims to COVER must be one that row actually SCANS, or it
# is credited with no byte of it ever read. P3 did exactly that, so the census
# read nine of nineteen when four was honest. Over the table, not the row.
# ---------------------------------------------------------------------------
MINE_SURF="$MINE_NL$(mine_surface)$MINE_NL"
MINE_BOGUS=0
MINE_UNSCANNED=0
mine_j=0
while [ "$mine_j" -lt "${#MINE_ID[@]}" ]; do
  # Both fenced both ends so a strip is an exact whole-line match, both builtins.
  mine_sites="$MINE_NL${MINE_SITES[$mine_j]}$MINE_NL"
  while IFS= read -r mine_p; do
    [ -n "$mine_p" ] || continue
    if [ "${MINE_SURF#*"$MINE_NL$mine_p$MINE_NL"}" = "$MINE_SURF" ]; then
      red "  FAIL [58] ${MINE_ID[$mine_j]} claims to cover $mine_p, which the routing-surface discovery does not ship; a row covering something that is not there overstates the coverage line below"
      FAILED=$((FAILED + 1))
      MINE_BOGUS=$((MINE_BOGUS + 1))
    fi
    if [ "${mine_sites#*"$MINE_NL$mine_p$MINE_NL"}" = "$mine_sites" ]; then
      red "  FAIL [58] ${MINE_ID[$mine_j]} claims to cover $mine_p but does not name it as one of its own sites, so the coverage line below credits a file this predicate never opens and the gap list omits it too"
      FAILED=$((FAILED + 1))
      MINE_UNSCANNED=$((MINE_UNSCANNED + 1))
    fi
  done <<MINE_COVERS_EOF
${MINE_COVERS[$mine_j]}
MINE_COVERS_EOF
  mine_j=$((mine_j + 1))
done
[ "$MINE_BOGUS" -eq 0 ] && green "  ok   [58] every path the table claims to cover is one the routing-surface discovery ships"
[ "$MINE_UNSCANNED" -eq 0 ] && green "  ok   [58] every path the table claims to cover is one its own row also scans, so the coverage line below counts only files this check opened"

# THE STDERR CAPTURE mine_classify's TIE-BREAKER READS, one file for the whole
# fragment and not one per site, which would be the fork-per-row cost the loops
# above were rewritten to stop paying. Every `2>` truncates it. THE mktemp IS
# CHECKED and the degraded path is LOUD: unchecked, an empty path kills the
# redirection BEFORE awk runs and bash returns a status awk itself returns, so
# the failure wears a clean read's face. This reddens, then falls back to
# /dev/null, keeping the exit status and the sentinel as the two live signals.
MINE_ERR=$(mktemp 2> /dev/null) || MINE_ERR=''
if [ -z "$MINE_ERR" ]; then
  red "  FAIL [58] mktemp failed, so the classifier's stderr tie-breaker is unavailable and every site below is screened on its exit status and end sentinel alone"
  FAILED=$((FAILED + 1))
  MINE_ERR=/dev/null
fi

mine_i=0
while [ "$mine_i" -lt "${#MINE_ID[@]}" ]; do
  yellow "  note [58] ${MINE_ID[$mine_i]}, ${MINE_CLAIM[$mine_i]}"
  mine_authority "$mine_i"
  mine_control "$mine_i"
  mine_verdict "$mine_i"
  if [ "$MINE_N_DENY" -eq 0 ] && [ "$MINE_N_SITE" -eq 0 ]; then
    green "  ok   [58] ${MINE_ID[$mine_i]} clean across its sites, $MINE_N_CLEAR sentence(s) matched the deny matcher and were cleared by a negator inside that same sentence"
  fi
  mine_i=$((mine_i + 1))
done

mine_coverage

# Removed rather than trapped: a sourced fragment shares one trap table, so an
# EXIT trap here would replace the next fragment's (89-reviewer-rename.sh).
[ "$MINE_ERR" = /dev/null ] || rm -f "$MINE_ERR"

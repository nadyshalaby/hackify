# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [87] THE DISPATCH ROSTER, READ FROM BOTH ENDS.
#
# WHAT WAS UNCHECKED, AND IT WAS MEASURED RATHER THAN FEARED. The table in
# skills/hackify/references/parallel-agents/README.md is what a dispatching agent
# reads instead of opening a template: one row per agent type, carrying that
# type's INPUTS list and the template a registry-less runtime pastes from. The
# wave that registered the merged all-lens reviewer replaced a live agent type in
# that table with the literal `UNREGISTERED-ROW`, re-ran the mirror sync and ran
# the whole bar, and the bar printed ALL CHECKS PASSED. So a wrong row misroutes
# a whole panel, a missing row leaves a registered agent undispatchable, and the
# tree said nothing in either direction.
#
# WHY IT IS NOT LINES IN AN EXISTING FRAGMENT, and three were candidates.
# 77-reviewer-roster.sh is named for a roster but asks a different question in a
# different grammar: it BANS stale count prose over a listed set of documents,
# and it has no parser, no agents/ census and no notion of a table row. check [30]
# in 60-primitives.sh already counts agents/ against a list, but that list is the
# fragment's own array, so it answers "is the census the size we wrote down" and
# never "does the DISPATCH table name these files". check [75h] in 75-ship-bar.sh
# reads agents/ against the mirror pair list, which is the sync script's list and
# not the README's. All three would go green on a roster that names nothing real.
#
# THE TYPE IS RESOLVED AGAINST THE NAME AN AGENT FILE DECLARES, never against the
# path it happens to sit at. The runtime registry dispatches on the frontmatter
# `name:` key, so a file whose basename and declared name disagree is a type that
# resolves from the roster and not from the runtime; only the declared side can
# see that, and a basename glob would call it registered.
#
# BOTH DIRECTIONS, because each one is a different outage. A row naming a type
# nobody registers sends a dispatch at nothing. A registered agent with no row is
# invisible to the dispatcher that reads this file instead of the directory. And
# a type carrying TWO rows leaves two INPUTS lists disagreeing with no tie-break,
# which is why the agent side asserts exactly one rather than at least one.
#
# THE TEMPLATE COLUMN IS A THIRD OUTAGE AND NOT A TIDINESS RULE. Every runtime
# without an agent registry takes the paste path, which opens exactly the file
# that column names, so a column pointing at a moved or misspelled template is a
# dead end for every one of those runtimes while Claude Code stays green.
yellow "[87] every dispatch-roster row names a registered agent type and an existing template, and every registered agent has exactly one row"

AGR_README="skills/hackify/references/parallel-agents/README.md"
AGR_TPL_DIR="skills/hackify/references/parallel-agents"
AGR_AGENTS_DIR="agents"

# One roster row per line, as `type<TAB>template`, and ONLY from the dispatch
# roster. A row qualifies when its FIRST cell is a backticked `hackify:<type>`
# and nothing else, which is what keeps the wave table further down the same file
# out of the set: that table names agent types too, in its SECOND cell, and has
# no template column for this check to read.
agr_rows() {
  awk -F'|' '
    /^\|/ {
      agr_type = $2
      agr_tpl = ($NF == "" ? $(NF - 1) : $NF)
      gsub(/^[ \t]+|[ \t]+$/, "", agr_type)
      gsub(/^[ \t]+|[ \t]+$/, "", agr_tpl)
      if (agr_type !~ /^`hackify:[A-Za-z0-9._-]+`$/) next
      gsub(/`/, "", agr_type)
      gsub(/`/, "", agr_tpl)
      print substr(agr_type, 9) "\t" agr_tpl
    }' "$1" 2> /dev/null
}

# THE WHOLE agents/ FRONTMATTER IN ONE READ, and it was one awk per file rebuilt
# on every pass before this. Three judges and the census called the registry seven
# times over ten files, so seventy awks answered a question that cannot change
# inside one run: the roster under judgement varies, the directory does not. That
# is `perf.process.spawn-per-item`, rules/performance.md:174, and it grows with the
# plugin because the driver is a discovered glob rather than a written list.
#
# ONE ROW PER FILE, FLUSHED AT THE FILE BOUNDARY. BWK awk, which is the macOS
# default, has no ENDFILE, so the flush happens on the next file's FNR == 1 and
# once more at END. The type is still read out of frontmatter and still stops at
# the closing delimiter, so a `name:` in the body cannot stand in for a missing
# key; a file with no frontmatter at all, or one whose frontmatter closes before
# the key, still emits its row carrying the loud placeholder rather than an empty
# string that would match every row.
agr_scan() {
  awk '
    function agr_flush() {
      if (agr_file != "")
        print (agr_name == "" ? "(no name: key in frontmatter)" : agr_name) "\t" agr_file
    }
    FNR == 1 { agr_flush(); agr_file = FILENAME; agr_name = ""; agr_shut = ($0 != "---") }
    agr_shut { next }
    FNR > 1 && $0 == "---" { agr_shut = 1; next }
    FNR > 1 && /^name:[ \t]*/ {
      agr_name = $0
      sub(/^name:[ \t]*/, "", agr_name)
      agr_shut = 1
    }
    END { agr_flush() }' "$@" 2> /dev/null
}

# THE MEMBERSHIP AND THE COUNT ARE ANSWERED IN THE SHELL. Both judges below forked
# a grep per element against a list already sitting in a variable, which is the
# same catalog entry as the read above and the larger half of it: thirty greps a
# run. The newline fencing is the shape 80-file-size-caps.sh uses at CAP_NL, and it
# is what keeps one type name from matching another's prefix. The stripped match
# consumes its own trailing newline, so the loop puts one back before going round
# again; without that, two adjacent equal entries would be counted as one.
AGR_NL='
'
AGR_COUNT=0
agr_count_in() {
  local agr_pat="$AGR_NL$1$AGR_NL" agr_rest="$AGR_NL$2$AGR_NL"
  AGR_COUNT=0
  while [ "$agr_rest" != "${agr_rest#*"$agr_pat"}" ]; do
    AGR_COUNT=$((AGR_COUNT + 1))
    agr_rest="$AGR_NL${agr_rest#*"$agr_pat"}"
  done
}

# THE REGISTRY IS BUILT ONCE, AND THE BATCH IS RECONCILED AGAINST THE GLOB IT WAS
# BUILT FROM. That reconcile is 80-file-size-caps.sh's rule at its own batched
# read, and it is not decoration: batching moved the open out of the loop and took
# with it the guarantee that every listed file was actually opened, because awk
# reports an unreadable operand on stderr and carries on with the rest. A short
# batch would otherwise print a confident green over a set nobody read, which is
# the exact defect this sprint has spent the day removing. Silent when the two
# agree, so a healthy tree's output is byte-for-byte what it always was.
AGR_FILES=()
for agr_f in "$AGR_AGENTS_DIR"/*.md; do
  [ -f "$agr_f" ] && AGR_FILES+=("$agr_f")
done
AGR_REGISTRY=''
[ "${#AGR_FILES[@]}" -gt 0 ] && AGR_REGISTRY=$(agr_scan "${AGR_FILES[@]}")
AGR_REG_NAMES=''
[ -n "$AGR_REGISTRY" ] && AGR_REG_NAMES=$(cut -f1 <<< "$AGR_REGISTRY")
AGR_REG_N=0
[ -n "$AGR_REGISTRY" ] && AGR_REG_N=$(grep -c . <<< "$AGR_REGISTRY")
if [ "${#AGR_FILES[@]}" -lt 1 ]; then
  red "  FAIL [87] the $AGR_AGENTS_DIR/ glob matched no agent definition at all, so both directions below would reconcile the roster against an empty registry and print the whole table green having read nothing"
  FAILED=$((FAILED + 1))
elif [ "$AGR_REG_N" -ne "${#AGR_FILES[@]}" ]; then
  red "  FAIL [87] the batched frontmatter read returned $AGR_REG_N row(s) for the ${#AGR_FILES[@]} file(s) in $AGR_AGENTS_DIR/, so an agent definition was never opened and every verdict below is about a set that was not fully read"
  FAILED=$((FAILED + 1))
fi

# Direction one: every row resolves, on both of its columns. The parsed rows
# arrive as text rather than as a path, so one awk per judge answers what three
# separate calls used to.
agr_judge_rows() {
  local agr_label="$1" agr_rowtext="$2" agr_type agr_tpl
  while IFS=$'\t' read -r agr_type agr_tpl; do
    [ -n "$agr_type" ] || continue
    agr_count_in "$agr_type" "$AGR_REG_NAMES"
    if [ "$AGR_COUNT" -lt 1 ]; then
      red "  FAIL [87] $agr_label row \`hackify:$agr_type\` names a type no file in $AGR_AGENTS_DIR/ declares, so a dispatch read off that row reaches nothing"
      FAILED=$((FAILED + 1))
    fi
    if [ ! -f "$AGR_TPL_DIR/$agr_tpl" ]; then
      red "  FAIL [87] $agr_label row \`hackify:$agr_type\` names template '$agr_tpl', which is not a file under $AGR_TPL_DIR/, so every runtime without an agent registry has nothing to open"
      FAILED=$((FAILED + 1))
    fi
  done <<< "$agr_rowtext"
}

# Direction two: every registered agent is named exactly once. The COUNT and not
# mere membership, which is why this side reads AGR_COUNT rather than testing it
# against zero: two rows for one type is as much an outage as none.
agr_judge_agents() {
  local agr_label="$1" agr_rowtext="$2" agr_types agr_name agr_file
  agr_types=$(cut -f1 <<< "$agr_rowtext")
  while IFS=$'\t' read -r agr_name agr_file; do
    [ -n "$agr_file" ] || continue
    agr_count_in "$agr_name" "$agr_types"
    [ "$AGR_COUNT" -eq 1 ] && continue
    red "  FAIL [87] $agr_label carries $AGR_COUNT row(s) for the registered type \`hackify:$agr_name\` ($agr_file), expected exactly 1; a dispatcher reads that table instead of the directory, so no row makes the agent unreachable and two leave its INPUTS lists disagreeing"
    FAILED=$((FAILED + 1))
  done <<< "$AGR_REGISTRY"
}

# THE FLOOR IS THE FAIL-CLOSED BRANCH and it is why the parse count is read before
# anything is judged. A moved README, a renamed directory or a table reformatted
# past the row pattern all leave the parser returning nothing, and both loops above
# iterate zero times over that and print a wall of nothing. A roster check over an
# empty set has measured nothing, so it reddens instead.
agr_judge() {
  local agr_readme="$1" agr_label="$2" agr_rowtext agr_n=0
  agr_rowtext=$(agr_rows "$agr_readme")
  [ -n "$agr_rowtext" ] && agr_n=$(grep -c . <<< "$agr_rowtext")
  if [ "$agr_n" -lt 1 ]; then
    red "  FAIL [87] parsed 0 dispatch-roster rows out of $agr_label; a roster read over an empty set measures nothing, so either the file moved or the table's row shape changed"
    FAILED=$((FAILED + 1))
    return 0
  fi
  agr_judge_rows "$agr_label" "$agr_rowtext"
  agr_judge_agents "$agr_label" "$agr_rowtext"
}

# A CONTROL MUST NOT MOVE FAILED, on the rule 83-testing-stage-shape.sh states at
# its own control: agr_judge judges rather than reports, printing a verdict and
# raising FAILED on a hit, which is exactly the behaviour a control has to OBSERVE
# and exactly what it must not leave behind. THE MECHANISM IS control_delta IN
# 00-helpers.sh NOW, written once for the three fragments that each had a copy of
# it; what is left here is the one thing a shared helper cannot know, which judge
# to run and under what label. The DELTA is published rather than a yes/no, because
# the plant below is built to raise a known number of reds and a bare "something
# moved" would pass on one of the three.
AGR_DELTA=0
agr_control_delta() {
  control_delta agr_judge "$1" 'the [87] control roster'
  AGR_DELTA="$CONTROL_DELTA"
}

# THE PLANT IS THE EXACT TAMPER THAT USED TO SHIP GREEN, run on every validator
# run rather than recorded in a wave report as a proof that never runs again. It
# is built from the live roster's own first two rows, so nothing here is a name
# this file would have to be edited to keep current: the first row's TYPE becomes
# a literal nobody registers, and the second row's TEMPLATE becomes a file that is
# not there. THREE REDS ARE OWED, and the count is what makes the control mean
# something, since each one comes from a different branch: the unresolvable type,
# the missing template, and the agent the rewritten row left with no row at all.
# A difference of two would mean one of the three branches is dead.
#
# THE DIFFERENCE, NEVER THE PLANTED TOTAL, and that correction was measured rather
# than reasoned about. Reading the plant's own count asserts something about the
# LIVE roster as well: run over a tree whose roster is genuinely broken the plant
# inherits those reds too, and the control announced a dead branch over a check
# whose branches were all working and whose live verdict was about to name the real
# defect three lines down. Measuring the live roster first and subtracting makes
# this the plant's worth and nothing else, which is what a control is for.
AGR_PLANT_REDS=3
AGR_PLANT=$(mktemp 2> /dev/null) || AGR_PLANT=''
AGR_ROWTEXT=$(agr_rows "$AGR_README")
AGR_TAMPER_TYPE=$(awk -F'\t' 'NR == 1 { print $1 }' <<< "$AGR_ROWTEXT")
AGR_TAMPER_TPL=$(awk -F'\t' 'NR == 2 { print $2 }' <<< "$AGR_ROWTEXT")
agr_control_delta "$AGR_README"
AGR_LIVE_DELTA="$AGR_DELTA"

if [ -z "$AGR_PLANT" ] || [ -z "$AGR_TAMPER_TYPE" ] || [ -z "$AGR_TAMPER_TPL" ]; then
  red "  FAIL [87] the positive control could not be built (mktemp failed, or the roster's first two rows did not parse), so the live verdict below was never measured against a known-bad roster"
  FAILED=$((FAILED + 1))
else
  sed -e "s/\`hackify:$AGR_TAMPER_TYPE\`/\`hackify:UNREGISTERED-ROW\`/g" \
      -e "s/\`$AGR_TAMPER_TPL\`/\`zzq-no-such-template.md\`/g" \
      "$AGR_README" > "$AGR_PLANT"
  agr_control_delta "$AGR_PLANT"
  if [ "$((AGR_DELTA - AGR_LIVE_DELTA))" -eq "$AGR_PLANT_REDS" ]; then
    green "  ok   [87] positive control, planting an unregistered type and a missing template on the roster raised all $AGR_PLANT_REDS owed reds, one per branch"
  else
    red "  FAIL [87] positive control, the plant raised $((AGR_DELTA - AGR_LIVE_DELTA)) red(s) over the live roster's $AGR_LIVE_DELTA against the $AGR_PLANT_REDS owed; either a branch of this check is dead, in which case the verdict below was measured by it, or the roster already carries the very defect this plant adds and the verdict below names it"
    FAILED=$((FAILED + 1))
  fi
  rm -f "$AGR_PLANT"
fi

agr_control_delta "$AGR_README.no-such-file"
if [ "$AGR_DELTA" -gt 0 ]; then
  green "  ok   [87] fail-closed control, an unreadable roster is reported rather than read as a clean one"
else
  red "  FAIL [87] fail-closed control, an unreadable roster did not redden, so a renamed or moved README would print every row green"
  FAILED=$((FAILED + 1))
fi

# THE LIVE HALF, and the green line counts both sides rather than announcing a
# pass: a verdict that names how many rows and how many agent files it reconciled
# is the one thing that separates this check from one that read nothing.
AGR_BEFORE="$FAILED"
AGR_ROW_N=$(grep -c . <<< "$AGR_ROWTEXT")
AGR_AGENT_N="$AGR_REG_N"
agr_judge "$AGR_README" "$AGR_README"
if [ "$FAILED" -eq "$AGR_BEFORE" ]; then
  green "  ok   [87] all $AGR_ROW_N dispatch-roster row(s) name a type declared in $AGR_AGENTS_DIR/ and a template that exists, and each of the $AGR_AGENT_N registered agent(s) carries exactly one row"
fi

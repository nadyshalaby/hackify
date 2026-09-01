# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [88] THE ORIENTATION MAP, READ FROM BOTH ENDS.
#
# WHAT THE MAP IS. rules/plugin-map.md is injected once per session by the
# SessionStart hook, and it is the only thing that tells a fresh session what
# this plugin ships: which entry points exist, and which rule files are law. A
# model that never reads it cannot route a user to one skill over another,
# because it does not know the others are there.
#
# WHY IT IS CHECKED RATHER THAN TRUSTED. A map is a document that describes a
# tree which changes every week, and the failure mode is not that it goes
# missing. It rots in place, keeps its authoritative shape, and sends a reader
# at a skill that was renamed three sprints ago. "Remember to update the map"
# is the instruction this sprint has now watched fail twice on rules that were
# already written down and unenforced, which is why the map ships with a check
# instead of a reminder.
#
# BOTH DIRECTIONS, AND THE SECOND IS THE LOAD-BEARING ONE.
#   (a) RESOLUTION. Every entry the map names is really there: a
#       `/hackify:<name>` resolving to skills/<name>/SKILL.md or
#       commands/<name>.md, and a `rules/<name>.md` that both exists AND is
#       actually wired on the UserPromptSubmit chain in hooks/hooks.json. This
#       catches a deletion or a rename.
#   (b) COVERAGE. Every entry point the tree ships has a row. This is the half
#       a naive check omits, because (a) is a lookup while (b) has to discover
#       the true set and diff against it. It is also the half that rots on
#       EXTENSION: a skill added next month with no row is invisible to every
#       session that reads the map instead of the directory, and (a) would
#       print green over it having found no token to resolve.
#
# BOTH HALVES ARE ABOUT EXISTENCE, AND NEITHER IS ABOUT TRUTH. That is worth
# writing down because it is not obvious from the two paragraphs above: (a) asks
# whether a named thing is there and (b) asks whether a thing that is there is
# named, and a row can pass both while every word in its right-hand column is
# false. Measured rather than reasoned about, and the count that used to sit in
# this sentence is gone rather than refreshed, on the rule 98-work-doc-ledger-sync.sh
# states at its floors: an unpinned number in a comment is a rotting claim, and this
# one read 35 against a directory of 47. A wave falsified two entry descriptions on
# this tree without touching a single token, ran EVERY fragment the validator
# sources plus the mirror check, and NOTHING moved; breaking one token in the same
# cell raised five reds. So this check detects a renamed thing and is blind to a lying
# one, and a map whose rows all resolve can still misroute a session for the
# whole session.
#
# WHAT COVERS PART OF THE REST IS check [58], scripts/validate-dod.d/58-contradiction-miner.sh.
# It does not ask whether a description is TRUE, which needs a reader. It asks
# the mechanical half of that question over a hand-written table of routing
# predicates: does a file assert not-X where a named authority asserts X, for a
# predicate with two sides and nothing in between (auto-fires versus never
# auto-fires, default route versus on request, one mode only versus every mode).
# Both of today's findings sit inside that opening, because in each case the
# negation was already written down where a check could read it. It closes only
# as much of the gap as a table of predicates reaches, and it prints the entry
# points it has NO predicate for on every run rather than leaving the remainder
# implied.
#
# THE ROSTER IS DISCOVERED PER RUN AND NEVER LISTED HERE, for the reason [86]
# gives at its own roster: a list written into this file is a second copy of
# the tree that rots on the same schedule as the map, and it would go stale in
# the same silence.
#
# THE RULE SIDE READS UserPromptSubmit ONLY, not every event array. The map
# itself is wired on SessionStart, so a whole-file read would put the map in
# its own registry and demand it carry a row about itself. The map's rule table
# is a table of the PER-PROMPT law, and that is exactly the set this discovers.
#
# EXACTLY ONE ROW PER ENTRY, never at least one. Two rows for one entry leave
# two descriptions of the same thing with no tie-break, and a token that
# appears twice will not redden when one of the two is broken, which is the
# trap this repo hit twice today. Counting rows rather than file occurrences is
# what keeps prose free: only a table row whose FIRST cell is a lone backticked
# token is a row here, so the map can name a skill in a sentence as often as it
# needs to.
#
# ONE ID AND NOT A RANGE, for the reason the 83, 86, 98 and 99 rows in
# scripts/validate-dod.d/README.md give: this fragment declares exactly one check
# and a range endpoint would assert a maximum it does not have.
yellow "[88] every orientation-map entry resolves on disk, and every shipped entry point has exactly one map row"

PMAP_FILE="rules/plugin-map.md"
PMAP_HOOKS="hooks/hooks.json"

# THIS FILE CARRIES NO LITERAL PLUGIN COMMAND, for the reason
# 86-skill-command-namespace.sh gives about itself: check [86] scans every
# tracked file, this one included, so the plant's fake command written out as
# literal text is read by that scan and reported as a command naming a skill
# that does not exist. Measured rather than feared, it reddened [86] on this
# fragment's first run. The token is built from $PMAP_S at run time instead, so
# the matcher below sees the same bytes it would see in a real map while the
# file on disk holds none of them. Exempting this file from [86] would hide a
# genuinely wrong command advertised here and is refused.
PMAP_S='/'

# One entry token per line, and ONLY from a table row whose first cell is a
# lone backticked token of one of the two shapes. Anything else on the line,
# and every mention in prose, is invisible here.
pmap_rows() {
  awk -F'|' '
    /^\|/ {
      pmap_cell = $2
      gsub(/^[ \t]+|[ \t]+$/, "", pmap_cell)
      if (pmap_cell !~ "^`(" pmap_s "hackify:[A-Za-z0-9._-]+|rules/[A-Za-z0-9._-]+[.]md)`$") next
      gsub(/`/, "", pmap_cell)
      print pmap_cell
    }' pmap_s="$PMAP_S" "$1" 2> /dev/null
}

# The command surface as the runtime resolves it: a skill directory counts only
# when it holds a SKILL.md, and commands/ counts because designify and summary
# ship as command bodies with no skill directory at all.
pmap_disk_commands() {
  local pmap_d pmap_c
  for pmap_d in skills/*/; do
    [ -f "${pmap_d}SKILL.md" ] || continue
    pmap_d=${pmap_d#skills/}
    printf '%shackify:%s\n' "$PMAP_S" "${pmap_d%/}"
  done
  for pmap_c in commands/*.md; do
    [ -f "$pmap_c" ] || continue
    pmap_c=${pmap_c#commands/}
    printf '%shackify:%s\n' "$PMAP_S" "${pmap_c%.md}"
  done
}

# The per-prompt law, read out of the wiring rather than out of rules/. A file
# sitting in rules/ that nothing injects is not always-on and does not belong
# in the map's law table; what makes it law is the hook entry.
pmap_disk_rules() {
  jq -r '.hooks.UserPromptSubmit[].hooks[].command' "$PMAP_HOOKS" 2> /dev/null \
    | tr ' ' '\n' | sed -n 's|.*\(rules/[A-Za-z0-9._-]*\.md\).*|\1|p' | sort -u
}

pmap_registry() {
  pmap_disk_commands
  pmap_disk_rules
}

# Direction (a). One red per row at most, naming the first reason it fails, so
# the plant below can own a countable number of them.
pmap_judge_rows() {
  local pmap_label="$1" pmap_map="$2" pmap_wired pmap_tok pmap_n
  pmap_wired=$(pmap_disk_rules)
  while IFS= read -r pmap_tok; do
    [ -n "$pmap_tok" ] || continue
    case "$pmap_tok" in
      "$PMAP_S"hackify:*)
        pmap_n=${pmap_tok#"$PMAP_S"hackify:}
        [ -f "skills/$pmap_n/SKILL.md" ] && continue
        [ -f "commands/$pmap_n.md" ] && continue
        red "  FAIL [88] $pmap_label names the entry point \`$pmap_tok\`, but neither skills/$pmap_n/SKILL.md nor commands/$pmap_n.md exists, so a session routed off that row reaches nothing"
        FAILED=$((FAILED + 1)) ;;
      *)
        if [ ! -f "$pmap_tok" ]; then
          red "  FAIL [88] $pmap_label names the rule file \`$pmap_tok\`, which is not on disk, so the map advertises a law that was deleted or renamed"
          FAILED=$((FAILED + 1))
        elif ! grep -qxF -- "$pmap_tok" <<< "$pmap_wired"; then
          red "  FAIL [88] $pmap_label names \`$pmap_tok\` as always-on law, but no UserPromptSubmit entry in $PMAP_HOOKS injects it, so the map calls a file binding that never reaches a prompt"
          FAILED=$((FAILED + 1))
        fi ;;
    esac
  done <<< "$(pmap_rows "$pmap_map")"
}

# Direction (b). The half that reddens on EXTENSION.
#
# THE COUNT IS TAKEN IN THE SHELL, NOT BY A GREP PER ENTRY. The rows are already in
# a variable, so asking `grep -cxF` for each discovered entry point forked one
# process per element to search text this shell is holding: 42 of them per validator
# run, counted with a shell function shadowing grep, because the control below runs
# this judge three times. count_in_list answers the same question with no fork and
# the same newline-fenced whole-entry match grep -x makes; it lives in
# 01-presence-matchers.sh, where [87] can reach it too.
pmap_judge_registry() {
  local pmap_label="$1" pmap_map="$2" pmap_have pmap_tok
  pmap_have=$(pmap_rows "$pmap_map")
  while IFS= read -r pmap_tok; do
    [ -n "$pmap_tok" ] || continue
    count_in_list "$pmap_tok" "$pmap_have"
    [ "$LIST_COUNT" -eq 1 ] && continue
    red "  FAIL [88] $pmap_label carries $LIST_COUNT row(s) for \`$pmap_tok\`, expected exactly 1; a session reads that map instead of the tree, so no row makes the entry point invisible and two leave it described twice with no tie-break"
    FAILED=$((FAILED + 1))
  done <<< "$(pmap_registry)"
}

# THE FLOORS ARE THE FAIL-CLOSED BRANCH, and they are read before anything is
# judged. A moved map, a reformatted table or a jq that returned nothing all
# leave a parser producing an empty list, and both loops above iterate zero
# times over that and print nothing at all. A map check over an empty set has
# measured nothing, so it reddens instead. Same tie-break [55], [86] and [87]
# make at their own set boundaries.
pmap_judge() {
  local pmap_label="$1" pmap_map="$2" pmap_rn pmap_gn
  pmap_rn=$(pmap_rows "$pmap_map" | grep -c .)
  pmap_gn=$(pmap_registry | grep -c .)
  if [ "$pmap_rn" -lt 1 ]; then
    red "  FAIL [88] parsed 0 entry rows out of $pmap_label; a map read over an empty set measures nothing, so either the file moved or the table's row shape changed"
    FAILED=$((FAILED + 1))
    return 0
  fi
  if [ "$pmap_gn" -lt 6 ]; then
    red "  FAIL [88] discovered only $pmap_gn shipped entry point(s) across skills/, commands/ and the UserPromptSubmit chain, expected at least 6; the discovery collapsed rather than the map going right, so nothing was compared against the tree"
    FAILED=$((FAILED + 1))
    return 0
  fi
  pmap_judge_rows "$pmap_label" "$pmap_map"
  pmap_judge_registry "$pmap_label" "$pmap_map"
}

# A CONTROL MUST NOT MOVE FAILED, on the rule [83] and [87] both state at their
# own controls: pmap_judge judges rather than reports, so the counter is read,
# the judge is called with its printing swallowed, and the counter is put back
# whatever happened. THAT MECHANISM IS control_delta IN 00-helpers.sh NOW, written
# once for the three fragments that each carried a copy of it; what stays here is
# the one thing a shared helper cannot know, which judge to run and under what
# label. The DELTA is published rather than a yes/no, because the plant is built to
# raise a known number of reds and a bare "something moved" would pass on one of
# the four.
PMAP_DELTA=0
pmap_control_delta() {
  control_delta pmap_judge 'the [88] control map' "$1"
  PMAP_DELTA="$CONTROL_DELTA"
}

# THE PLANT IS BOTH DIRECTIONS AT ONCE, and the count is what makes it worth
# running. One command token and one rule token are rewritten to names nothing
# ships, which owes FOUR reds from four different branches: the unresolvable
# command (a), the real skill left with no row (b), the missing rule file (a),
# and the real rule left with no row (b). A delta of two would mean direction
# (b) is dead, which is precisely the failure a resolution-only check ships
# with and the one the map cannot survive.
#
# THE DIFFERENCE, NEVER THE PLANTED TOTAL, for the reason [87] records: over a
# tree whose map is genuinely broken the plant inherits those reds too, and the
# control would announce a dead branch over a check whose branches all work.
PMAP_PLANT_REDS=4
PMAP_PLANT=$(mktemp 2> /dev/null) || PMAP_PLANT=''
# NO SHORT-CIRCUITING READER ON THE RIGHT OF A PIPE, per check [84]: grep's
# max-count family and head both stop before their input ends, which closes the
# pipe under the orchestrator's `set -o pipefail` and turns a present marker
# into a missing one. `sed -n '1p'` reads to EOF and takes the first line.
PMAP_TAMPER_CMD=$(pmap_rows "$PMAP_FILE" | grep "^${PMAP_S}hackify:" | sed -n '1p')
PMAP_TAMPER_RULE=$(pmap_rows "$PMAP_FILE" | grep '^rules/' | sed -n '1p')
pmap_control_delta "$PMAP_FILE"
PMAP_LIVE_DELTA="$PMAP_DELTA"

if [ -z "$PMAP_PLANT" ] || [ -z "$PMAP_TAMPER_CMD" ] || [ -z "$PMAP_TAMPER_RULE" ]; then
  red "  FAIL [88] the positive control could not be built (mktemp failed, or the map's first command row and first rule row did not parse), so the live verdict below was never measured against a known-bad map"
  FAILED=$((FAILED + 1))
else
  sed -e "s|\`$PMAP_TAMPER_CMD\`|\`${PMAP_S}hackify:zzq-no-such-skill\`|g" \
      -e "s|\`$PMAP_TAMPER_RULE\`|\`rules/zzq-no-such-rule.md\`|g" \
      "$PMAP_FILE" > "$PMAP_PLANT"
  pmap_control_delta "$PMAP_PLANT"
  if [ "$((PMAP_DELTA - PMAP_LIVE_DELTA))" -eq "$PMAP_PLANT_REDS" ]; then
    green "  ok   [88] positive control, renaming one entry point and one rule file on the map raised all $PMAP_PLANT_REDS owed reds, both directions and one per branch"
  else
    red "  FAIL [88] positive control, the plant raised $((PMAP_DELTA - PMAP_LIVE_DELTA)) red(s) over the live map's $PMAP_LIVE_DELTA against the $PMAP_PLANT_REDS owed; either a branch of this check is dead, in which case the verdict below was measured by it, or the map already carries the defect this plant adds and the verdict below names it"
    FAILED=$((FAILED + 1))
  fi
  rm -f "$PMAP_PLANT"
fi

pmap_control_delta "$PMAP_FILE.no-such-file"
if [ "$PMAP_DELTA" -gt 0 ]; then
  green "  ok   [88] fail-closed control, an unreadable map is reported rather than read as a clean one"
else
  red "  FAIL [88] fail-closed control, an unreadable map did not redden, so a renamed or deleted map would print every entry green"
  FAILED=$((FAILED + 1))
fi

# THE MAP IS WIRED AT ALL, checked separately from its contents. A map nothing
# injects is a document no session ever sees, and every verdict above would
# stay green over it.
PMAP_SS_CMDS=$(jq -r '.hooks.SessionStart[].hooks[].command' "$PMAP_HOOKS" 2> /dev/null)
if grep -qF -- "$PMAP_FILE" <<< "$PMAP_SS_CMDS"; then
  green "  ok   [88] $PMAP_FILE is injected by a SessionStart entry in $PMAP_HOOKS"
else
  red "  FAIL [88] no SessionStart entry in $PMAP_HOOKS injects $PMAP_FILE, so the map is a file nothing ever reads to a session"
  FAILED=$((FAILED + 1))
fi

# THE LIVE HALF. The green line counts both sides rather than announcing a
# pass: a verdict naming how many rows and how many shipped entry points it
# reconciled is what separates this from a check that read nothing.
PMAP_BEFORE="$FAILED"
PMAP_ROW_N=$(pmap_rows "$PMAP_FILE" | grep -c .)
PMAP_REG_N=$(pmap_registry | grep -c .)
pmap_judge "$PMAP_FILE" "$PMAP_FILE"
if [ "$FAILED" -eq "$PMAP_BEFORE" ]; then
  green "  ok   [88] all $PMAP_ROW_N map row(s) resolve on disk, and each of the $PMAP_REG_N shipped entry point(s) carries exactly one row"
fi

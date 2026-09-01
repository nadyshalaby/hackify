# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [76j] THE INDEX AND THE RECORD NAME THE SAME FRAGMENTS.
#
# THE RULE WAS STATED AND NOT ENFORCED, WHICH IS WHY THIS EXISTS. When the
# manifest prose moved out of scripts/validate-dod.sh into
# scripts/validate-dod.d/README.md, a one-line index stayed behind and the
# orchestrator's header wrote the rule down: "a row added here needs its
# paragraph added there". Nothing read that sentence. The very next fragment to
# land, 58-contradiction-miner.sh, got its index row and no paragraph, and the
# whole bar stayed green over a map that did not know it existed. A rule a
# reader has to remember is a rule that holds until the first busy wave.
#
# WHAT ALREADY GUARDED THE NEIGHBOURING HALVES, AND WHY NEITHER REACHED THIS.
# [0] compares the fragment DIRECTORY against the SOURCE LIST, both directions.
# [76f] compares the source list against the INDEX, one direction. [76i] parses
# the check-id RANGE inside an index row. scripts/test_ban_tokens.d/40-fragment-
# coverage.sh sweeps the directory against the source list and the index. Not one
# of them opens README.md, so the record could describe a tree that no longer
# exists and the index could name a fragment the record never heard of, in
# silence, forever.
#
# BOTH DIRECTIONS, because each one alone leaves the hole the other covers. An
# index row with no README row is the [58] defect: a fragment the map a reader
# consults does not describe. A README row with no index row is its mirror, a
# record of something that left, which is worse than absence because it reads as
# current. AND EVERY NAME EITHER SIDE CARRIES MUST BE A FILE, which catches the
# rename that updated one document and not the other.
#
# A FLOOR AND NOT AN EXACT COUNT, for [76f]'s reason: this polices two
# hand-edited lists that legitimately grow every wave, so an equality would be
# bumped on reflex without being read. What a floor still catches is the failure
# that actually hides a loss, a reformat that stops the rows parsing and leaves
# this printing a confident green over nothing. FIFTEEN ON EACH SIDE, the number
# [0] already uses for the same job over the same directory.
#
# AND THE READERS TELL "FOUND NONE" FROM "COULD NOT LOOK". grep exits 1 on a
# clean miss and above 1 on a path it cannot read, and a count of zero taken off
# the second is a count of nothing. Both statuses are read before the output is,
# the rule 00-helpers.sh states above check_no_token.
#
# NO PIPE INTO A SHORT-CIRCUITING READER ANYWHERE BELOW, which check [84] bans
# across scripts/ under the `set -uo pipefail` the orchestrator runs with. Every
# membership test is a shell `case` over a haystack fenced with a newline on both
# ends, so `9-x.sh` cannot satisfy `89-x.sh`, and the trailing fence is written by
# hand because `$( )` strips the newline a reader ends its output with.
#
# WHY ITS OWN FILE. The natural home is 76-phase-ledger-substrate.sh beside [76f]
# and [76i], and that file is one of the ten the tamper harness runs in isolation
# against 00-helpers.sh alone. Everything added there is one more thing that
# isolation contract has to keep working, for a check that has nothing to do with
# the phase ledger. The id stayed in the 76 family because that is what the check
# is about; the file did not, on the rule 96-review-scope-sites.sh followed when
# it took [76g] and [76h] out of the same fragment.
yellow "[76j] the orchestrator's fragment index and scripts/validate-dod.d/README.md name the same fragments"

MRS_INDEX="scripts/validate-dod.sh"
MRS_README="scripts/validate-dod.d/README.md"
MRS_DIR="scripts/validate-dod.d"
MRS_FLOOR=15
# The index rows are comments, the README rows sit inside a fenced block at two
# spaces. Written out rather than shared, because the two anchors are the whole
# difference between the two documents and folding them into one pattern would
# make a row in either shape count in both.
MRS_INDEX_ROW='^#[[:space:]]+[0-9]+-[A-Za-z0-9._-]+\.sh,'
MRS_README_ROW='^  [0-9]+-[A-Za-z0-9._-]+\.sh,'

# One fragment basename per line, off the rows of $1 that match $2. Returns 2 when
# the read itself failed and 1 when it parsed nothing, so a caller can tell the two
# apart from each other and from a clean result.
mrs_names() {
  local line rows rc n=0
  local -a names=()
  rows=$(/usr/bin/grep -oE "$2" "$1" 2>/dev/null)
  rc=$?
  [ "$rc" -le 1 ] || return 2
  while IFS= read -r line; do
    line=${line#\#}
    line=${line#"${line%%[![:space:]]*}"}
    [ -n "$line" ] || continue
    names[n]=${line%,}
    n=$((n + 1))
  done <<<"$rows"
  [ "$n" -gt 0 ] || return 1
  printf '%s\n' "${names[@]}"
}

# Every name in $1 that the newline-fenced haystack $2 does not carry.
mrs_missing() {
  local name
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    case "$2" in
      *$'\n'"$name"$'\n'*) ;;
      *) printf '%s\n' "$name" ;;
    esac
  done <<<"$1"
}

mrs_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

# One direction, reported per missing name. $3 is the sentence that says what the
# absence MEANS, because a bare "not found" is a diff and not a finding.
mrs_report() {
  local gone name bad=0
  gone=$(mrs_missing "$1" "$2")
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    mrs_fail "[76j] $name $3"
    bad=$((bad + 1))
  done <<<"$gone"
  [ "$bad" -eq 0 ]
}

mrs_on_disk() {
  local name bad=0
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    [ -r "$MRS_DIR/$name" ] && continue
    mrs_fail "[76j] $2 names $name, but $MRS_DIR/$name is missing or unreadable, so one of the two maps describes a fragment that is not there"
    bad=$((bad + 1))
  done <<<"$1"
  [ "$bad" -eq 0 ]
}

mrs_count() {
  local line n=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$((n + 1))
  done <<<"$1"
  printf '%s' "$n"
}

# THE CONTROL, AND IT IS THE ONE THING HERE THAT COULD NOT BE SKIPPED. On a tree
# where both documents agree, every comparison above reports nothing, and that
# silence is the SAME OUTPUT a reader that had stopped parsing would print. So a
# COPY of the README is built with its first row deleted, read back through the
# SAME reader, and the check refuses unless the count moved by exactly one AND the
# comparison names the row that left. Nothing is written into the repository: the
# copy lives under the temp directory and the real file is only ever read.
mrs_control() {
  local tmp copy short victim gone n m
  tmp=$(mktemp -d 2>/dev/null) || tmp=''
  if [ -z "$tmp" ]; then
    mrs_fail "[76j] the positive control could not create a temp directory, so this run's silence was never earned"
    return
  fi
  copy="$tmp/README.md"
  victim=${1%%$'\n'*}
  /usr/bin/grep -v "^  $victim," "$MRS_README" > "$copy" 2>/dev/null
  short=$(mrs_names "$copy" "$MRS_README_ROW")
  rm -rf "$tmp"
  n=$(mrs_count "$1")
  m=$(mrs_count "$short")
  if [ "$m" -ne "$((n - 1))" ]; then
    mrs_fail "[76j] the control deleted the $victim row from a copy of the README and the reader still counted $m row(s) against the $((n - 1)) it was built to hold, so the reader this check compares with cannot see a deleted row"
    return
  fi
  gone=$(mrs_missing "$1" $'\n'"$short"$'\n')
  if [ "$gone" != "$victim" ]; then
    mrs_fail "[76j] the control deleted the $victim row and the comparison reported '${gone:-nothing}' instead, so a row missing from the README would not be named"
    return
  fi
  green "  ok   [76j] the control drops the $victim row from a copy of the README, the count moves from $n to $m and the comparison names exactly that row, so this check can fail"
}

mrs_idx=$(mrs_names "$MRS_INDEX" "$MRS_INDEX_ROW")
mrs_idx_rc=$?
mrs_rme=$(mrs_names "$MRS_README" "$MRS_README_ROW")
mrs_rme_rc=$?

if [ "$mrs_idx_rc" -ne 0 ] || [ "$mrs_rme_rc" -ne 0 ]; then
  mrs_fail "[76j] the row scan came back empty or unreadable (index rc $mrs_idx_rc, README rc $mrs_rme_rc); a comparison over nothing agrees perfectly and proves nothing"
else
  mrs_idx_n=$(mrs_count "$mrs_idx")
  mrs_rme_n=$(mrs_count "$mrs_rme")
  if [ "$mrs_idx_n" -lt "$MRS_FLOOR" ] || [ "$mrs_rme_n" -lt "$MRS_FLOOR" ]; then
    mrs_fail "[76j] parsed $mrs_idx_n index row(s) and $mrs_rme_n README row(s), expected at least $MRS_FLOOR of each; a reformat that stops the rows parsing must redden here, not pass vacuously"
  else
    mrs_bad=0
    mrs_report "$mrs_idx" $'\n'"$mrs_rme"$'\n' \
      "has a row in $MRS_INDEX and no row in $MRS_README, so the map a reader consults does not describe it; a row added to the index needs its paragraph added to the record" \
      || mrs_bad=1
    mrs_report "$mrs_rme" $'\n'"$mrs_idx"$'\n' \
      "has a row in $MRS_README and no row in $MRS_INDEX, so the record describes a fragment the orchestrator does not name; a retired fragment leaves both documents together" \
      || mrs_bad=1
    mrs_on_disk "$mrs_idx" "$MRS_INDEX" || mrs_bad=1
    mrs_on_disk "$mrs_rme" "$MRS_README" || mrs_bad=1
    mrs_control "$mrs_rme"
    [ "$mrs_bad" -eq 0 ] && green "  ok   all $mrs_idx_n rows of the $MRS_INDEX index carry a row in $MRS_README and back, and every name either one carries is a fragment on disk"
  fi
fi

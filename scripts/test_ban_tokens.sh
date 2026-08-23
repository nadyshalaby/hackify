#!/usr/bin/env bash
# Tamper test for the batched token ban (check_no_tokens_in / ban_patternfile_ok
# in scripts/validate-dod.d/00-helpers.sh).
#
# WHY THIS FILE EXISTS. [70] and [77] used to re-read every covered file once per
# banned token. Batching that into one grep per file is a rewrite of the matching
# engine those two checks are built on, and the proofs for the checks around it
# are prose records of manual runs. A prose proof cannot be re-run after the next
# edit, so the rewrite ships with an executable one instead.
#
# WHAT IT REFUSES TO LET THROUGH. Every failure mode below is one this repo has
# already shipped at least once:
#   1. a banned token that stops being banned, checked one token at a time over
#      the REAL lists parsed out of the two fragments, not a sample
#   2. a pattern file that silently changes what grep matches (blank line, empty
#      file, wrong length), which is the vacuous-pass surface batching adds
#   3. a check that prints red and exits 0, verified as a real process exit
#      status in BOTH directions, not as printed output
#   4. a green path that is green because it measured nothing
#
# Standalone: bash scripts/test_ban_tokens.sh, exits non-zero on any failure.
# Reads the repo, writes only under its own temp directory, mutates nothing.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

FAILED=0
source "scripts/validate-dod.d/00-helpers.sh"

TB_TMP=$(mktemp -d "${TMPDIR:-/tmp}/hackify-bantest.XXXXXX") || exit 1
trap 'rm -rf "$TB_TMP"' EXIT
TB_OUT="$TB_TMP/out.txt"
TB_PASS=0
TB_BAD=0
TB_LIST=()
# Moved by tb_plant_case and by nothing else, so it counts plants that actually
# happened rather than plants the run order implies. Read twice: tb_plant_every_token
# takes a delta across its own loop, tb_check_plant_total takes the grand total.
TB_PLANTED=0

# Counts written a SECOND time, on purpose, the same way [77] writes RR_EXPECTED
# next to its file list. A bound derived from the list cannot police the list: if
# a ban group is deleted the parsed count drops with it and a `wc`-style bound
# stays green while coverage quietly shrinks.
TB_EXPECT_70=23
TB_EXPECT_77=60
# A THIRD list, and the one this suite used to miss entirely. [77] enforces it
# against one named file instead of the six-file sweep, so it is counted apart
# from the 60 above and pinned apart from them too.
TB_EXPECT_RPT=6

# The two files whose ban lists this test re-reads on every run, so it always
# tests what ships rather than a copy that can drift away from it.
TB_SRC_70="scripts/validate-dod.d/70-invariants-and-new.sh"
TB_SRC_77="scripts/validate-dod.d/77-reviewer-roster.sh"

tb_ok()  { TB_PASS=$((TB_PASS + 1)); printf '  pass %s\n' "$1"; }
tb_bad() { TB_BAD=$((TB_BAD + 1)); printf '  BAD  %s\n' "$1"; }

# ---------------------------------------------------------------------------
# Token-list extraction. shlex parses the shell single-quoting exactly, so a
# token containing spaces survives, and newline-delimited output is safe because
# a token carrying a newline is itself a defect the pattern-file guard reddens.
# ---------------------------------------------------------------------------
tb_extract_lists() {
  python3 - "$TB_SRC_70" "$TB_SRC_77" "$TB_TMP" <<'PY'
import io, re, shlex, sys, os
src70, src77, tmp = sys.argv[1], sys.argv[2], sys.argv[3]

# Exactly one batched call, not merely a first one. Taking the first match would
# start testing the wrong list the moment a second batched call is added above
# it, and the token-count pin cannot see a wrong list of the same length.
hits70 = [m.group(1) for m in
          (re.match(r'^\s*check_no_tokens_in "\$f" (.+?)\s*$', line)
           for line in io.open(src70, encoding="utf-8")) if m]
if len(hits70) != 1:
    sys.exit("expected exactly 1 batched ban call in %s, found %d" % (src70, len(hits70)))
toks70 = shlex.split(hits70[0])

# Both [77] arrays live in the same file, so one parser serves both, and it reads
# bare words and quoted words alike. An empty parse exits non-zero right here
# instead of writing an empty list, because a section handed nothing to plant
# prints nothing and passes, which is the exact bug this suite exists to refuse.
def parse_array(path, name):
    pat = re.compile(r'^%s\+?=\((.*)\)\s*$' % name)
    toks = []
    for line in io.open(path, encoding="utf-8"):
        m = pat.match(line)
        if m:
            toks.extend(shlex.split(m.group(1)))
    if not toks:
        sys.exit("no %s group parsed from %s" % (name, path))
    return toks

lists = (("tokens70.txt", toks70),
         ("tokens77.txt", parse_array(src77, "RR_BANS")),
         ("tokens77rpt.txt", parse_array(src77, "RR_RPT")))
for name, toks in lists:
    with io.open(os.path.join(tmp, name), "w", encoding="utf-8") as fh:
        fh.write("".join(t + "\n" for t in toks))
PY
}

# Load one newline-delimited token file into TB_LIST, the array every ban call
# below is made with. Read into a global rather than echoed back, because a
# command substitution would flatten the tokens that contain spaces.
tb_load_list() {
  local listfile="$1"
  local t
  TB_LIST=()
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    TB_LIST+=("$t")
  done < "$listfile"
}

# ---------------------------------------------------------------------------
# Assertions. Every one checks the FAILED counter as well as the printed text,
# because "prints red, exits 0" is the specific bug 77-reviewer-roster.sh
# documents against itself and the bug a subshell increment reintroduces.
# Redirection on a function call does not fork, so FAILED survives the capture.
# ---------------------------------------------------------------------------
tb_expect_red() {
  local label="$1"
  local before="$2"
  if [ "$FAILED" -le "$before" ]; then
    tb_bad "$label: printed its verdict but FAILED did not move ($before -> $FAILED)"
    return
  fi
  if ! /usr/bin/grep -q 'FAIL' "$TB_OUT"; then
    tb_bad "$label: FAILED moved but no FAIL line was printed"
    return
  fi
  tb_ok "$label"
}

tb_expect_green() {
  local label="$1"
  local before="$2"
  if [ "$FAILED" -ne "$before" ]; then
    tb_bad "$label: clean input still moved FAILED ($before -> $FAILED)"
    return
  fi
  if /usr/bin/grep -q 'FAIL' "$TB_OUT"; then
    tb_bad "$label: clean input printed a FAIL line"
    return
  fi
  tb_ok "$label"
}

# ---------------------------------------------------------------------------
# 1. Every banned token, one at a time, over the real lists.
# ---------------------------------------------------------------------------
tb_plant_case() {
  local token="$1"
  local before="$FAILED"
  local planted="$TB_TMP/planted.md"
  TB_PLANTED=$((TB_PLANTED + 1))
  printf 'Reviewer prose above the plant.\n%s\nReviewer prose below it.\n' "$token" > "$planted"
  check_no_tokens_in "$planted" "${TB_LIST[@]}" > "$TB_OUT" 2>&1
  if [ "$FAILED" -le "$before" ]; then
    tb_bad "planted [$token] did not move FAILED, so the batched screen missed it"
    return
  fi
  if ! /usr/bin/grep -qF "FAIL '$token' has" "$TB_OUT"; then
    tb_bad "planted [$token] reddened, but no FAIL line names that token"
    return
  fi
  tb_ok "planted [$token] reddens and is named"
}

# Every sweep proves its OWN coverage: this list, this many tokens, actually
# screened. A grand total alone is permutation-blind, because swapping two sweeps'
# lists leaves the sum unchanged while one list gets screened by the wrong array,
# and the list-size pins cannot see it either since they measure the parsed files
# rather than which array each sweep screens against. The bound is a delta on
# TB_PLANTED, which only tb_plant_case moves. Deriving it from ${#TB_LIST[@]}
# instead would pass by construction: that length stays 23 whether the loop below
# ran 23 times or broke after five.
tb_plant_every_token() {
  local listfile="$1"
  local want="$2"
  local label="$3"
  local before="$TB_PLANTED"
  local t moved
  tb_load_list "$listfile"
  if [ "${#TB_LIST[@]}" -eq 0 ]; then
    tb_bad "$label: no tokens parsed, so this whole section would have measured nothing"
    return
  fi
  for t in "${TB_LIST[@]}"; do
    tb_plant_case "$t"
  done
  moved=$((TB_PLANTED - before))
  if [ "$moved" -eq "$want" ]; then
    tb_ok "$label: $moved tokens actually planted, matching the expected $want"
    return
  fi
  tb_bad "$label: $moved tokens actually planted, expected $want (this sweep is screening another list, or its loop stopped early)"
}

# ---------------------------------------------------------------------------
# 2. The green path, and the proof it is not green by measuring nothing.
# ---------------------------------------------------------------------------
tb_case_green_path() {
  local before="$FAILED"
  local clean="$TB_TMP/clean.md"
  local n
  printf 'The panel is evidence-gated. B is the standing member of every wave.\n' > "$clean"
  check_no_tokens_in "$clean" "${TB_LIST[@]}" > "$TB_OUT" 2>&1
  tb_expect_green "green path: a clean file over ${#TB_LIST[@]} tokens stays green" "$before"
  n=$(/usr/bin/grep -c "has 0 occurrences in $clean" "$TB_OUT")
  if [ "$n" -eq "${#TB_LIST[@]}" ]; then
    tb_ok "green path: printed ${#TB_LIST[@]} verdict lines, one per token, none skipped"
  else
    tb_bad "green path: printed $n verdict lines for ${#TB_LIST[@]} tokens"
  fi
}

# A real covered file carries multibyte characters, and grep -I skips anything it
# decides is binary. If the locale ever made it decide that about UTF-8 markdown,
# every ban over that file would report zero and print green forever.
tb_case_real_file_plant() {
  local token="$1"
  local before="$FAILED"
  local real="skills/hackify/references/review-and-verify.md"
  local copy="$TB_TMP/real-copy.md"
  local nonascii
  cp "$real" "$copy" || { tb_bad "real-file plant: could not copy $real"; return; }
  nonascii=$(/usr/bin/grep -c '[^ -~	]' "$copy")
  if [ "$nonascii" -eq 0 ]; then
    tb_bad "real-file plant: $real no longer carries multibyte text, pick another fixture"
    return
  fi
  printf '%s\n' "$token" >> "$copy"
  check_no_tokens_in "$copy" "${TB_LIST[@]}" > "$TB_OUT" 2>&1
  tb_expect_red "real-file plant: [$token] in a $nonascii-line multibyte file still reddens" "$before"
}

# ---------------------------------------------------------------------------
# 3. Pattern-file corruption, the surface batching adds.
#
# Direction matters and is easy to get backwards. An EMPTY pattern file matches
# NOTHING and grep exits 1, which without the guard prints every token green
# having measured nothing: that is the dangerous direction. A BLANK LINE matches
# EVERY line, which is loud rather than silent. Both are refused, and both are
# asserted here against the guard's own red line, never against the matching.
# ---------------------------------------------------------------------------
tb_case_patternfile_guard() {
  local label="$1"
  local want="$2"
  local pf="$TB_TMP/pattern.txt"
  if ban_patternfile_ok "$pf" "$want"; then
    tb_bad "pattern guard: $label was accepted"
  else
    tb_ok "pattern guard: $label is refused"
  fi
}

tb_run_patternfile_guards() {
  printf 'alpha\n\nbeta\n' > "$TB_TMP/pattern.txt"
  tb_case_patternfile_guard "a blank line (would match every line of every file)" 3
  printf 'alpha\n   \nbeta\n' > "$TB_TMP/pattern.txt"
  tb_case_patternfile_guard "a whitespace-only line" 3
  : > "$TB_TMP/pattern.txt"
  tb_case_patternfile_guard "an empty file (would match nothing and print all green)" 3
  printf 'alpha\nbeta\n' > "$TB_TMP/pattern.txt"
  tb_case_patternfile_guard "a short file (a token silently dropped)" 3
  printf 'alpha\nbeta\ngamma\n' > "$TB_TMP/pattern.txt"
  if ban_patternfile_ok "$TB_TMP/pattern.txt" 3; then
    tb_ok "pattern guard: an intact 3-line file is accepted"
  else
    tb_bad "pattern guard: an intact 3-line file was refused"
  fi
  rm -f "$TB_TMP/pattern.txt"
  tb_case_patternfile_guard "a missing file" 3
}

# End to end: a token that would write a blank line into the pattern file must
# redden AND must still ban every token the slow way, so the corruption costs
# speed and never coverage.
tb_case_blank_token_end_to_end() {
  local before="$FAILED"
  local clean="$TB_TMP/clean.md"
  local n
  printf 'Nothing banned lives in this line.\n' > "$clean"
  check_no_tokens_in "$clean" 'panel is five' '' 'panel is six' > "$TB_OUT" 2>&1
  tb_expect_red "blank token: a pattern file that would match every line reddens" "$before"
  if ! /usr/bin/grep -q 'pattern file' "$TB_OUT"; then
    tb_bad "blank token: reddened for some other reason than the pattern file"
    return
  fi
  # Verdict lines, not green lines: the empty token matches every line by
  # definition, so it correctly reports a hit rather than a clean scan. What
  # this proves is that all three were still SCANNED once the guard fired.
  n=$(/usr/bin/grep -c "occurrences in $clean" "$TB_OUT")
  if [ "$n" -eq 3 ]; then
    tb_ok "blank token: all 3 tokens were still scanned the slow way, coverage intact"
  else
    tb_bad "blank token: only $n of 3 tokens were still scanned after the guard fired"
  fi
}

# Zero tokens is the other empty-pattern-file route into a silent pass: with no
# tokens the clean path prints nothing at all, so the guard has to be in front of
# it rather than inside it.
tb_case_zero_tokens() {
  local before="$FAILED"
  local clean="$TB_TMP/clean.md"
  printf 'Nothing banned lives in this line.\n' > "$clean"
  check_no_tokens_in "$clean" > "$TB_OUT" 2>&1
  tb_expect_red "zero tokens: an empty ban list reddens instead of passing silently" "$before"
}

# ---------------------------------------------------------------------------
# 4. Exit-status wiring, as a real process status in both directions. A subshell
# increment prints exactly the same red text and exits 0, so printed output
# cannot tell these two apart and only the status can.
# ---------------------------------------------------------------------------
tb_write_wiring_fragment() {
  cat > "$TB_TMP/wiring.sh" <<'WIRING'
#!/usr/bin/env bash
# Mirrors validate-dod.sh's shape: source the helpers, accumulate into FAILED,
# exit non-zero if anything failed. $1 repo root, $2 path to scan, $3 token.
set -uo pipefail
cd "$1" || exit 3
FAILED=0
source "scripts/validate-dod.d/00-helpers.sh"
check_no_tokens_in "$2" "$3" > /dev/null 2>&1
if [ "$FAILED" -eq 0 ]; then exit 0; fi
exit 1
WIRING
}

tb_case_exit_wiring() {
  local dirty="$TB_TMP/wire-dirty.md"
  local clean="$TB_TMP/wire-clean.md"
  local rc
  printf 'The panel is five now.\n' > "$dirty"
  printf 'The panel is evidence-gated.\n' > "$clean"
  tb_write_wiring_fragment
  bash "$TB_TMP/wiring.sh" "$REPO_ROOT" "$dirty" 'panel is five'
  rc=$?
  if [ "$rc" -eq 1 ]; then
    tb_ok "exit wiring: a dirty file exits 1, FAILED is not lost to a subshell"
  else
    tb_bad "exit wiring: a dirty file exited $rc, expected 1 (prints red, exits 0)"
  fi
  bash "$TB_TMP/wiring.sh" "$REPO_ROOT" "$clean" 'panel is five'
  rc=$?
  if [ "$rc" -eq 0 ]; then
    tb_ok "exit wiring: a clean file exits 0"
  else
    tb_bad "exit wiring: a clean file exited $rc, expected 0"
  fi
}

# ---------------------------------------------------------------------------
# Run order: list integrity first, because every section after it is only
# meaningful if the lists it parsed are the lists that ship.
# ---------------------------------------------------------------------------
tb_check_list_size() {
  local listfile="$1"
  local want="$2"
  local label="$3"
  local got
  got=$(/usr/bin/grep -c '' "$listfile" 2>/dev/null) || got=0
  if [ "$got" -eq "$want" ]; then
    tb_ok "$label: $got tokens parsed, matching the expected $want"
  else
    tb_bad "$label: $got tokens parsed, expected $want (a ban group was added or dropped)"
  fi
}

# Kept alongside the per-sweep deltas, because exactly two tampers walk past them
# and this catches both. A sweep that runs TWICE passes its own delta each time,
# 23 against 23, and only the grand total moves. And an exit taken part way down
# the run order skips whole sweeps, taking their deltas out of the run with them,
# so a total firing from the EXIT trap is the last assertion still standing.
# TB_PLANTED is moved by tb_plant_case alone, so this counts what the run really
# screened rather than what the run order implies.
tb_check_plant_total() {
  local want=$((TB_EXPECT_70 + TB_EXPECT_77 + TB_EXPECT_RPT))
  if [ "$TB_PLANTED" -eq "$want" ]; then
    tb_ok "plant total: $TB_PLANTED tokens actually planted, one per token in all three lists"
    return
  fi
  tb_bad "plant total: $TB_PLANTED tokens actually planted, expected $want (a plant section is pointed at the wrong list, planted twice, or not running at all)"
}

# The verdict runs from the EXIT trap, not from the foot of the script, so no
# exit path reaches the shell without it. An early exit is exactly what would
# skip the pin above, and a suite that leaves without printing a verdict is
# itself the silent pass. $? is read first, on one line, because `local` on its
# own line would overwrite it: a completed run arrives here as 0 and anything
# else means the suite died on the way.
tb_finish() {
  local rc=$?
  tb_check_plant_total
  printf '\n[test_ban_tokens] %s passed, %s failed\n' "$TB_PASS" "$TB_BAD"
  rm -rf "$TB_TMP"
  if [ "$TB_BAD" -eq 0 ] && [ "$TB_PASS" -gt 0 ] && [ "$rc" -eq 0 ]; then
    green "ALL BAN-TOKEN TAMPER TESTS PASSED"
    exit 0
  fi
  red "$TB_BAD BAN-TOKEN TAMPER TEST(S) FAILED"
  exit 1
}

# Armed here rather than beside mktemp because every function it calls has to
# exist by the time it fires. Above this line the plain cleanup trap still runs.
trap tb_finish EXIT

printf '[test_ban_tokens] batched token ban, tamper tests\n'

tb_extract_lists
tb_check_list_size "$TB_TMP/tokens70.txt" "$TB_EXPECT_70" "[70] ban list"
tb_check_list_size "$TB_TMP/tokens77.txt" "$TB_EXPECT_77" "[77] ban list"
tb_check_list_size "$TB_TMP/tokens77rpt.txt" "$TB_EXPECT_RPT" "[77] report-input ban list"

tb_load_list "$TB_TMP/tokens70.txt"
tb_case_green_path

# review-and-verify.md is covered by [77], so it is planted with a [77] token,
# and 'panel is five' is the exact wording of the review-scope defect this
# sprint fixed. Scanning it with the [70] list would prove nothing.
tb_load_list "$TB_TMP/tokens77.txt"
tb_case_real_file_plant 'panel is five'

tb_run_patternfile_guards
tb_case_blank_token_end_to_end
tb_case_zero_tokens
tb_case_exit_wiring

tb_plant_every_token "$TB_TMP/tokens70.txt" "$TB_EXPECT_70" "[70] ban list"
tb_plant_every_token "$TB_TMP/tokens77.txt" "$TB_EXPECT_77" "[77] ban list"

# The report-input bans, screened the way [77] screens them: check_no_tokens_in
# takes one path and the whole array at both call sites, so the only thing that
# differs between this section and the one above it is which array screens the
# plant. Planting these with the RR_BANS array would prove nothing about them.
tb_plant_every_token "$TB_TMP/tokens77rpt.txt" "$TB_EXPECT_RPT" "[77] report-input ban list"

# Ran to completion. tb_finish reads this status, so a finished run is
# distinguishable from an exit taken anywhere above rather than being whatever
# the last plant call happened to return.
exit 0

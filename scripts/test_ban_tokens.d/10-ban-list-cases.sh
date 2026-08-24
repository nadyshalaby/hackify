# shellcheck shell=bash

# CASES OVER THE REAL SHIPPED BAN LISTS, parsed out of the two validator
# fragments on every run rather than copied here. These are the cases that
# answer "does the ban actually find the token it bans", one token at a time,
# plus the green path and the proof that green is not green-by-measuring-nothing.
# Split out of test_ban_tokens.sh when that file reached the 500-LOC hard cap.

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
  tb_run_fail_closed_cases
  tb_check_wi_failclosed_total
  tb_case_colon_filename
}

# ---------------------------------------------------------------------------
# 2b. THE FAIL-CLOSED PROOFS, and why they belong to the section above.
#
# A path grep could not open is the same defect as a green that measured nothing,
# one layer down: grep exits 2, prints no counts, and a check that reads the
# number without reading the STATUS prints green over content it never opened. A
# leak sitting behind a permission bit is invisible to it. That is why the green
# path calls these rather than a section of their own.
#
# BOTH FAIL-CLOSED BRANCHES ARE PINNED SEPARATELY, which is the whole difficulty.
# check_no_tokens_in's batched screen falls through to a per-token check_no_token
# loop, so reverting the batched branch alone STILL reddens through the fallback,
# and an assertion that only watches FAILED stays green on that revert. So the
# batched case asserts the batched red's own wording and the single-path case
# calls check_no_token directly with nothing underneath it to cover for it.
# Measured against all three reverts: each one alone turns one of these red.
#
# UNREADABLE AND MISSING ARE BOTH REAL, and they are not the same input. A
# renamed or moved scan target is the cheaper mistake by far, and it reaches the
# same branch without depending on a permission bit taking effect, so it keeps one
# proof standing wherever `chmod 000` is a no-op.
# ---------------------------------------------------------------------------
tb_run_fail_closed_cases() {
  tb_case_unreadable_single
  tb_case_unreadable_batched
  tb_case_missing_path
  tb_run_wi_absent_cases
}

tb_case_unreadable_single() {
  local before="$FAILED"
  local dir="$TB_TMP/sealed-single"
  TB_FAILCLOSED=$((TB_FAILCLOSED + 1))
  if ! tb_make_unreadable "$dir"; then
    tb_bad "fail-closed (single): nothing could be made unreadable here, so the rc>1 branch was never exercised"
    tb_drop_unreadable "$dir"
    return
  fi
  # The sealed file DOES carry the token, so a green here is not a conservative
  # verdict, it is a live hit reported as a clean scan.
  check_no_token 'panel is five' "$dir" > "$TB_OUT" 2>&1
  tb_expect_red "fail-closed (single): an unreadable path reddens instead of counting 0" "$before"
  if /usr/bin/grep -q 'was never screened' "$TB_OUT"; then
    tb_ok "fail-closed (single): the red says the token was never screened, not that it was screened and clean"
  else
    tb_bad "fail-closed (single): reddened for some reason other than the never-screened branch"
  fi
  tb_drop_unreadable "$dir"
}

tb_case_unreadable_batched() {
  local before="$FAILED"
  local dir="$TB_TMP/sealed-batched"
  local n
  TB_FAILCLOSED=$((TB_FAILCLOSED + 1))
  if ! tb_make_unreadable "$dir"; then
    tb_bad "fail-closed (batched): nothing could be made unreadable here, so the rc>1 branch was never exercised"
    tb_drop_unreadable "$dir"
    return
  fi
  check_no_tokens_in "$dir" 'panel is five' 'panel is six' > "$TB_OUT" 2>&1
  tb_expect_red "fail-closed (batched): an unreadable path reddens instead of printing every token green" "$before"
  # The batched red in its OWN words. Matching 'FAIL' alone would pass on a
  # reverted batched branch, because the per-token fallback reddens underneath it.
  if /usr/bin/grep -q 'batched screen could not read' "$TB_OUT"; then
    tb_ok "fail-closed (batched): the batched screen reds in its own words, not only through the fallback"
  else
    tb_bad "fail-closed (batched): the batched screen printed no red of its own, only the per-token fallback failed closed"
  fi
  n=$(/usr/bin/grep -c 'was never screened' "$TB_OUT")
  if [ "$n" -eq 2 ]; then
    tb_ok "fail-closed (batched): both tokens still went through the fallback, and both failed closed there too"
  else
    tb_bad "fail-closed (batched): $n of 2 tokens reported never-screened by the fallback"
  fi
  if /usr/bin/grep -q 'has 0 occurrences' "$TB_OUT"; then
    tb_bad "fail-closed (batched): a token printed 'has 0 occurrences' over a path grep never opened"
  else
    tb_ok "fail-closed (batched): no token claimed 0 occurrences in a path that was never read"
  fi
  tb_drop_unreadable "$dir"
}

# A scan target that is not there at all, the cheaper half of the same branch: a
# renamed directory leaves the check pointed at nothing, and counting without
# reading the status prints green for every token forever after.
tb_case_missing_path() {
  local before="$FAILED"
  TB_FAILCLOSED=$((TB_FAILCLOSED + 1))
  check_no_token 'panel is five' "$TB_TMP/no-such-directory" > "$TB_OUT" 2>&1
  tb_expect_red "fail-closed (missing): a path that does not exist reddens instead of counting 0" "$before"
  if /usr/bin/grep -q 'was never screened' "$TB_OUT"; then
    tb_ok "fail-closed (missing): the red names the never-screened branch"
  else
    tb_bad "fail-closed (missing): reddened for some reason other than the never-screened branch"
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
# 2c. A MISREAD COUNT, the other way a green happens over content the check
# never actually cleared. Not fail-closed: here grep runs, reads the file, and
# reports the hit, and the SUM throws it away.
#
# `grep -rc` emits `path:count`, so a colon inside the path adds a field. The sum
# used to read `$2`, and on `weird:name.md:1` that field is `name.md`, which awk
# coerces to 0 and the check prints green over a live hit. `$NF` is the last field
# whatever the filename holds.
#
# THE DIRECTORY IS THE ARGUMENT, NOT THE FILE, and that is the entire case. Handed
# the file itself, check_no_token takes the `${out##*:}` branch, which strips to
# the last colon and passes whether the sum reads `$2` or `$NF`, so the case would
# be a tautology that proves nothing about the branch it is named for. Only a
# directory reaches awk.
#
# THE FIXTURE SUPPLIES THE FILENAME because the scanned trees hold none, which is
# exactly why this went unnoticed: latent, not absent.
# ---------------------------------------------------------------------------
tb_case_colon_filename() {
  local before="$FAILED"
  local dir="$TB_TMP/colon-name"
  TB_MISCOUNT=$((TB_MISCOUNT + 1))
  rm -rf "$dir"
  mkdir -p "$dir"
  printf 'panel is five\n' > "$dir/weird:name.md"
  check_no_token 'panel is five' "$dir" > "$TB_OUT" 2>&1
  tb_expect_red "miscount: a hit inside a colon-carrying filename reddens instead of summing to 0" "$before"
  if /usr/bin/grep -q 'has 1 occurrences' "$TB_OUT"; then
    tb_ok "miscount: the count reads 1, so the sum took the last field and not the filename"
  else
    tb_bad "miscount: reddened without reporting the real count of 1"
  fi
  rm -rf "$dir"
}

# ---------------------------------------------------------------------------
# 3. THE [40] ABSENCE SCAN'S FAIL-CLOSED BRANCHES, and why they live in this
# suite rather than beside the check they cover.
#
# wi_absent() in scripts/validate-dod.d/70-invariants-and-new.sh asks the same
# question section 2b asks of the batched ban: did the scan actually run. It is
# the harsher shape of it. An absence check has no hit to print when it fails
# open, so a scan that never ran and a tree that is genuinely clean come out of
# it as the identical green line, and there is nothing in the output to tell
# them apart. This suite is the only executable harness in the repo for a
# validator internal, so the cases go here rather than growing a second one.
#
# THE FUNCTION IS PARSED OUT OF THE SHIPPED FRAGMENT, never copied, the same
# bargain tb_extract_lists makes with the ban lists: a copy kept here would go
# on passing long after the real one regressed. Sourcing the whole fragment is
# not an option, it runs its forty top-level checks and moves FAILED on its own,
# which is the counter every assertion in this suite reads.
#
# TWO CASES, NOT ONE, and the split is structural rather than tidy.
#   (a) git grep itself exits above 1. That branch already worked before this
#       case existed, so it would never have caught the mktemp defect. It is a
#       regression pin on the branch the mktemp fix restructures around it.
#   (b) mktemp fails, so 2>"$err" dies in the shell before git ever runs and
#       bash hands back 1, which is git grep's honest no-match. All four calls
#       then fail open together and [40] cannot fail at all. This is the case
#       that reds before the fix and greens after it, and the reason the whole
#       section was written.
# ---------------------------------------------------------------------------

# Counted the way the fail-closed cases are counted, and counted APART from them.
# TB_FAILCLOSED is scoped to the batched ban screen, and 30-inventory-pins.sh
# writes that scope into TB_EXPECT_FAILCLOSED's own comment, one case per
# check_no_token / check_no_tokens_in branch plus the missing-path route into the
# first. Folding another function's branches into that total would leave the
# constant's stated reason false while the number still added up, which is the
# stale-rationale defect this repo keeps finding and no check can see.
#
# THE PIN FIRES FROM tb_case_green_path rather than from the EXIT trap, because
# the trap-side totals live in a fragment this change does not own. So it catches
# a case that stopped being called and a case that is called twice, and it does
# not catch an exit taken above it. That is the smaller guarantee and it is worth
# naming: tb_case_green_path is itself a line in the driver's run order, so its
# absence is visible where these two cases' absence is not. The wiring gate
# cannot see them either, for the reason 30-inventory-pins.sh already gives about
# its four-name row for this fragment.
TB_WI_FAILCLOSED=0
TB_EXPECT_WI_FAILCLOSED=2

# The shipped source, read fresh on every run.
TB_WI_SRC="scripts/validate-dod.d/70-invariants-and-new.sh"

# The literal every case below scans for REALLY occurs in a tracked file that no
# WI_LIVE_PATHS exclusion covers: it is the live implementer type [40] pins as
# present. A literal that was genuinely absent would make the pre-fix green
# correct instead of fail-open, and the cases would prove nothing about the
# branch they are named for. Same reason tb_case_unreadable_single seals a file
# that carries its token instead of an empty one.
TB_WI_LIT='hackify:wave-implementer'

tb_load_wi_absent() {
  local body
  body=$(sed -n '/^wi_absent() {$/,/^}$/p' "$TB_WI_SRC")
  if [ -z "$body" ]; then
    tb_bad "wi_absent: nothing parsed out of $TB_WI_SRC, so both cases below would have measured nothing"
    return 1
  fi
  eval "$body"
  if declare -F wi_absent > /dev/null 2>&1; then
    tb_ok "wi_absent: the shipped definition parsed out of $TB_WI_SRC and is callable"
    return 0
  fi
  tb_bad "wi_absent: the parsed text left no wi_absent defined, so both cases below would have measured nothing"
  return 1
}

tb_run_wi_absent_cases() {
  tb_load_wi_absent || return
  tb_wi_fixture_ready || return
  tb_case_wi_scan_failed
  tb_case_wi_mktemp_failed
}

# THE FIXTURE LITERAL IS PROVED PRESENT, not assumed, and neither case below can
# prove it for itself: (a) dies on the pathspec and (b) dies in the shell, so both
# reach their verdict without git ever opening a file. Let the literal fall out of
# the tree, which is exactly what the next rename does, and both go on passing over
# a fixture that can no longer tell a fail-open apart from an honestly clean tree.
# The scope checked here is ':(top)', which is the scope case (b) hands wi_absent.
# Same move tb_case_real_file_plant makes when its multibyte fixture goes plain.
tb_wi_fixture_ready() {
  # THIS FRAGMENT EXCLUDES ITSELF, for the reason WI_LIVE_PATHS excludes
  # 70-invariants-and-new.sh: the TB_WI_LIT assignment above is itself a tracked
  # occurrence, so a scan that counted it would report the literal present no
  # matter what became of the rest of the tree, and the guard could never fire.
  # MEASURED, not feared: without this exclusion, pointing TB_WI_LIT at a string
  # that exists nowhere else in the repo still passed.
  if git grep -qF -e "$TB_WI_LIT" -- ':(top)' ':(top,exclude)scripts/test_ban_tokens.d/10-ban-list-cases.sh'; then
    tb_ok "wi_absent: the fixture literal [$TB_WI_LIT] still occurs in a live file, so a green below would be a fail-open rather than a clean tree"
    return 0
  fi
  tb_bad "wi_absent: [$TB_WI_LIT] no longer occurs in any live file, pick another fixture (both cases below would pass over one that proves nothing)"
  return 1
}

# THE SCOPE IS PROVED, NOT ASSUMED, the same discipline tb_make_unreadable applies
# to its permission bit. Each case sets WI_LIVE_PATHS because that is the global
# wi_absent reads, and an empty one would drop the pathspec entirely and scan the
# whole tree, leaving the case testing something other than what it is named for.
# This is also the read shellcheck cannot see for itself, since wi_absent arrives
# through eval rather than through a definition it can follow.
tb_wi_scope_ready() {
  [ "${#WI_LIVE_PATHS[@]}" -gt 0 ] && return 0
  tb_bad "$1: WI_LIVE_PATHS came out empty, so the call below would have scanned the whole tree instead of the fixture"
  return 1
}

tb_case_wi_scan_failed() {
  local before="$FAILED"
  TB_WI_FAILCLOSED=$((TB_WI_FAILCLOSED + 1))
  # An unknown pathspec magic is rejected by git before it opens a single file,
  # measured at 128 here, which reaches the branch without leaning on a
  # permission bit taking effect the way the sealed-file fixtures do.
  WI_LIVE_PATHS=(':(bogusmagic)no-such-path')
  tb_wi_scope_ready "wi_absent (scan failed)" || return
  wi_absent "$TB_WI_LIT" > "$TB_OUT" 2>&1
  tb_expect_red "wi_absent (scan failed): a git grep exiting above 1 reddens instead of reporting the literal gone" "$before"
  if /usr/bin/grep -q 'finding nothing here would be finding nothing at all' "$TB_OUT"; then
    tb_ok "wi_absent (scan failed): the red says the scan never ran, not that the literal survives nowhere"
  else
    tb_bad "wi_absent (scan failed): reddened for some reason other than the scan-never-ran branch"
  fi
}

tb_case_wi_mktemp_failed() {
  local before="$FAILED"
  local shim="$TB_TMP/mktemp-shim"
  local saved="$PATH"
  TB_WI_FAILCLOSED=$((TB_WI_FAILCLOSED + 1))
  WI_LIVE_PATHS=(':(top)')
  tb_wi_scope_ready "wi_absent (no temp file)" || return
  mkdir -p "$shim" || { tb_bad "wi_absent (no temp file): the mktemp shim could not be built, so this branch was never exercised"; return; }
  printf '#!/bin/sh\nexit 1\n' > "$shim/mktemp"
  chmod 755 "$shim/mktemp"
  # NOT a subshell. tb_expect_red reads FAILED, and 00-harness.sh spells out why
  # only a redirection on the call itself preserves it: a fork would take the
  # counter with it and the assertion would blame the wrong thing.
  PATH="$shim:$PATH"
  wi_absent "$TB_WI_LIT" > "$TB_OUT" 2>&1
  PATH="$saved"
  tb_expect_red "wi_absent (no temp file): a failed mktemp reddens instead of routing into the clean-tree green" "$before"
  if /usr/bin/grep -q 'could not create the stderr capture file' "$TB_OUT"; then
    tb_ok "wi_absent (no temp file): the red names the capture file it could not create, so the git-exited branch is not answering for it"
  else
    tb_bad "wi_absent (no temp file): reddened for some reason other than the missing-capture-file branch"
  fi
  rm -rf "$shim"
}

tb_check_wi_failclosed_total() {
  if [ "$TB_WI_FAILCLOSED" -eq "$TB_EXPECT_WI_FAILCLOSED" ]; then
    tb_ok "wi_absent fail-closed total: $TB_WI_FAILCLOSED cases actually ran, matching the expected $TB_EXPECT_WI_FAILCLOSED"
    return
  fi
  tb_bad "wi_absent fail-closed total: $TB_WI_FAILCLOSED case(s) actually ran, expected $TB_EXPECT_WI_FAILCLOSED (a case is no longer being called, or is being called twice)"
}

# shellcheck shell=bash

# CASES OVER THE REAL SHIPPED BAN LISTS, parsed out of the two validator
# fragments on every run rather than copied here. These are the cases that
# answer "does the ban actually find the token it bans", one token at a time,
# plus the green path and the proof that green is not green-by-measuring-nothing.
# Split out of test_ban_tokens.sh when that file reached the 500-LOC hard cap.

# ---------------------------------------------------------------------------
# 1. Every banned token, one at a time, over the real lists.
# ---------------------------------------------------------------------------
# THE MATCHER IS TB_MATCHER AND NOT A LITERAL, because six of the seven shipped
# batched calls moved to check_no_flowed_tokens_in and a sweep hard-wired to the
# other one would prove a matcher the validator no longer runs on that list. Each
# sweep in test_ban_tokens.sh sets it to what its own list ships under, and the
# split pin in 30-inventory-pins.sh reddens if a call site moves without it.
#
# THE RED WORDING DIFFERS BETWEEN THE TWO, so it is derived rather than pinned to
# one form. The line-oriented matcher reports a COUNT of matching lines ("has 3
# occurrences"); the flattened one leaves one line per file, where a line count
# would read as an occurrence count while being neither, so it NAMES the files
# instead ("is present in ... in: a.md, b.md"). Asserting the shared prefix alone
# would let a matcher that prints the token and no verdict pass, so each form is
# matched in full up to the token.
tb_plant_case() {
  local token="$1"
  local before="$FAILED"
  local planted="$TB_TMP/planted.md"
  local hit="has"
  case "$TB_MATCHER" in *_flowed_*) hit="is present in" ;; esac
  TB_PLANTED=$((TB_PLANTED + 1))
  printf 'Reviewer prose above the plant.\n%s\nReviewer prose below it.\n' "$token" > "$planted"
  "$TB_MATCHER" "$planted" "${TB_LIST[@]}" > "$TB_OUT" 2>&1
  if [ "$FAILED" -le "$before" ]; then
    tb_bad "planted [$token] did not move FAILED, so $TB_MATCHER's batched screen missed it"
    return
  fi
  if ! /usr/bin/grep -qF "FAIL '$token' $hit" "$TB_OUT"; then
    tb_bad "planted [$token] reddened under $TB_MATCHER, but no FAIL line names that token"
    return
  fi
  tb_ok "planted [$token] reddens under $TB_MATCHER and is named"
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
# DELIBERATELY NOT TB_MATCHER. This case and the fail-closed cases it calls assert
# check_no_tokens_in's and check_no_token's own verdict wording, and both still
# ship: the line-oriented batched matcher runs [77]'s report-input bans and
# check_no_token runs every single-token ban in the validator. Pointing this at
# the flattened twin would assert wording that twin never prints.
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
  tb_case_two_hits_one_line
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
# 2c. A MISREAD COUNT, the other way a green happens over content the check never
# actually cleared. Not fail-closed: here grep runs, reads the file, and reports
# the hit, and the COUNT throws it away. Two cases, one per way that has happened.
#
# THE COLON CASE. `grep -rc` emitted `path:count`, so a colon in the path added a
# field. The sum read `$2`, which on `weird:name.md:1` is `name.md`, which awk
# coerced to 0, and the check printed green over a live hit. `$NF` repaired it,
# and check_no_token has since stopped parsing fields at all: it counts the lines
# `grep -o` prints, so there is no field left to misread and no directory-only
# branch to reach. The case is a REGRESSION GUARD now rather than a live repair,
# and it is kept because the way back in is an edit that reintroduces parsing,
# which nothing else in either suite would notice.
#
# THE TWO-HITS-ON-ONE-LINE CASE. `grep -c` counts matching LINES, so two
# occurrences on one line reported 1: detection was right and the number was not,
# and a red understated the regression it had correctly found. `-o` prints one
# line per occurrence, so the count is the occurrence count. THIS CASE EXISTS
# BECAUSE NOTHING ELSE PINNED IT. Reverting the matcher to -c was planted while
# this case was being written and left both this suite and the whole tamper
# battery at 0 failures, so the repair shipped guarded by nothing at all.
#
# THE FIXTURE SUPPLIES BOTH SHAPES because the scanned trees hold neither, which
# is exactly why both went unnoticed: latent, not absent.
# ---------------------------------------------------------------------------
tb_case_colon_filename() {
  local before="$FAILED"
  local dir="$TB_TMP/colon-name"
  TB_MISCOUNT=$((TB_MISCOUNT + 1))
  rm -rf "$dir"
  mkdir -p "$dir"
  printf 'panel is five\n' > "$dir/weird:name.md"
  check_no_token 'panel is five' "$dir" > "$TB_OUT" 2>&1
  tb_expect_red "miscount: a hit inside a colon-carrying filename reddens instead of counting 0" "$before"
  if /usr/bin/grep -q 'has 1 occurrences' "$TB_OUT"; then
    tb_ok "miscount: the count reads 1, so no part of the path was read as a count"
  else
    tb_bad "miscount: reddened without reporting the real count of 1"
  fi
  rm -rf "$dir"
}

# Two occurrences on ONE physical line, which is the whole case: any fixture that
# spreads them over two lines passes under a line counter and a hit counter
# alike, and would prove nothing about which one is running.
tb_case_two_hits_one_line() {
  local before="$FAILED"
  local dir="$TB_TMP/two-hits"
  TB_MISCOUNT=$((TB_MISCOUNT + 1))
  rm -rf "$dir"
  mkdir -p "$dir"
  printf 'panel is five and then panel is five again\n' > "$dir/a.md"
  check_no_token 'panel is five' "$dir/a.md" > "$TB_OUT" 2>&1
  tb_expect_red "miscount: two hits on one line redden" "$before"
  if /usr/bin/grep -q 'has 2 occurrences' "$TB_OUT"; then
    tb_ok "miscount: the count reads 2, so occurrences are counted and not matching lines"
  else
    tb_bad "miscount: two hits on one line did not report 2 occurrences, so the count is reading matching lines again"
  fi
  rm -rf "$dir"
}

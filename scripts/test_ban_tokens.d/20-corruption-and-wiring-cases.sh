# shellcheck shell=bash

# CASES OVER THE FAILURE SURFACE BATCHING ADDS. A batched screen reads one
# pattern per LINE, so a corrupt token list is a way to match nothing and print
# green, and a counter incremented in a subshell is a way to print red and exit
# 0. Neither failure exists in the per-token form these cases exist because of.
# Split out of test_ban_tokens.sh when that file reached the 500-LOC hard cap.

# ---------------------------------------------------------------------------
# 3. Token-list corruption, the surface batching adds.
#
# Direction matters and is easy to get backwards. An EMPTY list gives grep no
# patterns, which matches NOTHING and exits 1, which without the guard prints every
# token green having measured nothing: that is the dangerous direction. A BLANK pattern
# line matches EVERY line, which is loud rather than silent. Both are refused, and both
# are asserted against the guard's own verdict, never against the matching.
#
# The POSITIVE case is load-bearing: if the guard is ever renamed or deleted, every
# negative case still "refuses" (a missing function exits 127) and the intact list is
# the only assertion left that reddens. Do not drop it.
# ---------------------------------------------------------------------------
tb_case_token_guard() {
  local label="$1"
  shift
  if ban_tokens_ok "$@"; then
    tb_bad "token guard: $label was accepted"
  else
    tb_ok "token guard: $label is refused"
  fi
}

tb_run_token_guards() {
  tb_case_token_guard "a blank token (would match every line of every file)" 'alpha' '' 'beta'
  tb_case_token_guard "a whitespace-only token" 'alpha' '   ' 'beta'
  tb_case_token_guard "a token carrying a newline (splits into a blank pattern line)" \
    'alpha' "$(printf 'be\nta')" 'beta'
  tb_case_token_guard "an empty list (would match nothing and print all green)"
  if ban_tokens_ok 'alpha' 'beta' 'gamma'; then
    tb_ok "token guard: an intact 3-token list is accepted"
  else
    tb_bad "token guard: an intact 3-token list was refused"
  fi
}

# End to end: a token that would become a blank pattern line must redden AND must still
# ban every token the slow way, so the corruption costs speed and never coverage. The red
# line is matched on 'pattern list', the guard's own wording, so a red from anywhere else
# cannot be mistaken for this one.
tb_case_blank_token_end_to_end() {
  local before="$FAILED"
  local clean="$TB_TMP/clean.md"
  local n
  printf 'Nothing banned lives in this line.\n' > "$clean"
  check_no_tokens_in "$clean" 'panel is five' '' 'panel is six' > "$TB_OUT" 2>&1
  tb_expect_red "blank token: a token list that would match every line reddens" "$before"
  if ! /usr/bin/grep -q 'pattern list' "$TB_OUT"; then
    tb_bad "blank token: reddened for some other reason than the token guard"
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
  # Section 5 hangs off this call rather than off its own line in the run order,
  # for the reason spelled out above tb_run_dod_wiring_cases below.
  tb_run_dod_wiring_cases
}

# ---------------------------------------------------------------------------
# 5. THE ORCHESTRATOR'S OWN WIRING GUARDS, [0] and [0b] in scripts/validate-dod.sh.
#
# WHY THEY ARE TESTED FROM HERE. Both are written out in the orchestrator instead
# of living in a fragment, because a check that guards the source list cannot be
# reached through the source list: delete the line that sources it and the guard
# leaves with the thing it was guarding. That placement is what makes them
# undeletable, and it is also what left them untested. They shipped with a manual
# probe recorded in their own comments and nothing that re-runs it, and a prose
# proof cannot be re-run after the next edit, which is the argument this whole
# suite was built on.
#
# THE FIXTURE IS ALWAYS A COPY. Every case builds a throwaway validator under
# TB_TMP out of a COPY of scripts/validate-dod.sh, replaces every fragment it
# sources with an empty stub, and mutates only the copy. The real orchestrator and
# the real fragment directory are read and never written, so a case that dies half
# way through cannot leave the repo's own gate tampered with.
#
# STUBS RATHER THAN THE REAL FRAGMENTS, and that is what makes [0b] testable at
# all. [0b] is a floor on a COUNT, and against the real fragments the count is
# whatever the repo happens to print that day, which is reachable from neither
# side of the floor. With empty stubs the only ok line in the run is [0]'s own, so
# DOD_OK_COUNT is exactly what the stubbed helpers say it is and both sides of the
# floor are one assignment apart. It also keeps each case at about a second.
#
# CALLED FROM tb_case_exit_wiring, NOT FROM THE RUN ORDER, the same bargain the
# fail-closed cases in 10-ban-list-cases.sh make. The run order and the TB_WIRING
# pin both live in scripts/test_ban_tokens.sh, so nothing in the run order can
# show these cases happened. TB_DOD_CASES below is what tells "ran and passed"
# apart from "was never called".
# ---------------------------------------------------------------------------

# Moved by the four case functions below and by nothing else, then read once at
# the foot of the driver.
TB_DOD_CASES=0
TB_DOD_EXPECTED=4

# The floor [0b] polices, read out of the real orchestrator rather than written
# down a second time here, so raising it moves the cases with it. An unreadable
# or renamed assignment comes back empty and the driver refuses to run.
tb_dod_floor() {
  /usr/bin/grep -oE '^DOD_OK_FLOOR=[0-9]+' "$REPO_ROOT/scripts/validate-dod.sh" 2>/dev/null \
    | head -1 | cut -d= -f2
}

# The stubbed 00-helpers.sh, at $1, reporting $2 as the run's ok-line total.
# Written LAST and unconditionally, so a trimmed fixture cannot lose the helpers
# to source-line order and die on a missing green().
#
# THE ASSIGNMENT IS BARE WHERE THE REAL ONE IS ${DOD_OK_COUNT:-0}, on purpose.
# The real helpers preserve the increment [0] makes before they are sourced; this
# stub overwrites it, because these cases drive [0b]'s THRESHOLD rather than the
# accumulation, and a fixture whose total depended on how many greens ran ahead of
# it could not be placed exactly on the floor.
tb_dod_helpers() {
  local root="$1" okcount="$2"
  cat > "$root/scripts/validate-dod.d/00-helpers.sh" <<HELPERS
green() { printf '%s\n' "\$*"; }
red()   { printf '%s\n' "\$*"; }
DOD_OK_COUNT=$okcount
HELPERS
}

# Build the fixture at $1, with $2 as the stubbed DOD_OK_COUNT. $3 caps how many
# source lines the copied orchestrator keeps, 0 meaning all of them, which is how
# the empty-set case shrinks the fixture without touching the real file.
tb_dod_fixture() {
  local root="$1" keep="${3:-0}" name
  rm -rf "$root"
  mkdir -p "$root/scripts/validate-dod.d" || return 1
  cp "$REPO_ROOT/scripts/validate-dod.sh" "$root/scripts/validate-dod.sh" || return 1
  if [ "$keep" -gt 0 ]; then
    awk -v k="$keep" '/^source /{n++; if (n > k) next} {print}' \
      "$root/scripts/validate-dod.sh" > "$root/trimmed" || return 1
    mv "$root/trimmed" "$root/scripts/validate-dod.sh" || return 1
  fi
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    : > "$root/scripts/validate-dod.d/$name"
  done < <(tb_dod_sourced "$root")
  # The helpers stub is useless if the trim dropped the line that sources it, and
  # the run would die on a missing green() rather than on the thing being tested.
  tb_dod_sourced "$root" | /usr/bin/grep -qxF '00-helpers.sh' || return 1
  tb_dod_helpers "$root" "$2"
}

tb_dod_sourced() {
  /usr/bin/grep -E '^source ' "$1/scripts/validate-dod.sh" 2>/dev/null \
    | /usr/bin/grep -oE '[0-9]+-[A-Za-z0-9._-]+\.sh' | sort -u
}

# Run the fixture at $1, assert it exits $2, label the assertion $3. The output
# lands in TB_OUT for the text assertions below.
tb_dod_run() {
  local root="$1" want="$2" rc
  bash "$root/scripts/validate-dod.sh" > "$TB_OUT" 2>&1
  rc=$?
  if [ "$rc" -eq "$want" ]; then
    tb_ok "$3: exits $want"
  else
    tb_bad "$3: exited $rc, expected $want"
  fi
}

# $1 labels the assertion, $2 is the literal that must appear in TB_OUT.
tb_dod_says() {
  if /usr/bin/grep -qF -- "$2" "$TB_OUT"; then
    tb_ok "$1"
  else
    tb_bad "$1 (nothing in the run's output carried '$2')"
  fi
}

# The mirror of tb_dod_says, and never used alone. An absence assertion passes
# over silence, so every case that makes one also asserts a POSITIVE marker: a
# fixture that failed to build produces no output at all, which contains no FAIL
# line either and would otherwise read as a clean run.
tb_dod_silent_on() {
  if /usr/bin/grep -qF -- "$2" "$TB_OUT"; then
    tb_bad "$1 (the run's output carried '$2')"
  else
    tb_ok "$1"
  fi
}

# [0b], both sides of the floor. The at-the-floor run doubles as [0]'s control:
# an untampered fixture has to pass both guards and exit 0, or every red below it
# is just a fixture that never worked.
tb_case_dod_ok_floor() {
  local floor="$1"
  local root="$TB_TMP/dod-floor"
  tb_dod_fixture "$root" "$floor" || { tb_bad "[0b] fixture: could not build a throwaway validator at the floor"; return; }
  tb_dod_run "$root" 0 "[0b] a run sitting exactly on the floor is at it, not under it"
  tb_dod_says "[0b] at the floor: prints the note that names the count and the floor" \
    "ok lines counted through the shell printers, at or above the floor of $floor"
  tb_dod_silent_on "[0] control: an intact fixture reddens nothing" "FAIL"
  tb_dod_fixture "$root" "$((floor - 1))" || { tb_bad "[0b] fixture: could not build a throwaway validator below the floor"; return; }
  tb_dod_run "$root" 1 "[0b] one ok line below the floor"
  tb_dod_says "[0b] below the floor: names the shortfall and the floor" \
    "printed only $((floor - 1)) ok lines against a floor of $floor"
  TB_DOD_CASES=$((TB_DOD_CASES + 1))
}

# [0] direction one, the tamper the guard was written for: a fragment still on
# disk that nothing sources. Its checks do not fail, they never happen.
# 90-collisions.sh is the smallest possible tamper, one soft check on the last
# source line, and it still has to be caught.
tb_case_dod_unsourced() {
  local floor="$1"
  local root="$TB_TMP/dod-unsourced"
  local frag="90-collisions.sh"
  tb_dod_fixture "$root" "$floor" || { tb_bad "[0] fixture: could not build a throwaway validator for the unsourced case"; return; }
  if ! /usr/bin/grep -v "^source .*$frag" "$root/scripts/validate-dod.sh" > "$root/tampered"; then
    tb_bad "[0] fixture: could not drop the $frag source line from the copied orchestrator"
    return
  fi
  mv "$root/tampered" "$root/scripts/validate-dod.sh"
  tb_dod_run "$root" 1 "[0] a fragment on disk that nothing sources"
  tb_dod_says "[0] names the orphaned fragment and what its absence costs" "$frag exists but"
  tb_dod_says "[0] the run still reached its end, so the red came from [0] and not from a broken fixture" \
    "ok lines counted through the shell printers"
  TB_DOD_CASES=$((TB_DOD_CASES + 1))
}

# [0] direction two: a source line naming a fragment that is not there. `source`
# on a missing file returns 1, and with -e deliberately omitted the run carries on
# with that fragment's checks silently gone. Direction one cannot see this one,
# the basename is right there in the text.
tb_case_dod_missing() {
  local floor="$1"
  local root="$TB_TMP/dod-missing"
  local frag="90-collisions.sh"
  tb_dod_fixture "$root" "$floor" || { tb_bad "[0] fixture: could not build a throwaway validator for the missing-file case"; return; }
  rm -f "$root/scripts/validate-dod.d/$frag"
  tb_dod_run "$root" 1 "[0] a source line naming a fragment that is not there"
  tb_dod_says "[0] names the fragment the source line cannot reach" "sources $frag but"
  tb_dod_says "[0] the run still reached its end, so the red came from [0] and not from a broken fixture" \
    "ok lines counted through the shell printers"
  TB_DOD_CASES=$((TB_DOD_CASES + 1))
}

# [0]'s own floor. An empty directory compared against an empty source list agrees
# perfectly and proves nothing, so a set that has collapsed has to redden even
# though both directions are clean. Three fragments against three source lines is
# that collapse: they agree, DOD_WIRING_BAD stays 0, and the floor is the only
# thing standing between that and a green line.
tb_case_dod_empty_set() {
  local floor="$1"
  local root="$TB_TMP/dod-emptyset"
  tb_dod_fixture "$root" "$floor" 3 || { tb_bad "[0] fixture: could not build a three-fragment throwaway validator"; return; }
  tb_dod_run "$root" 1 "[0] a wiring scan over a set that has collapsed"
  tb_dod_says "[0] names both counts and the floor they missed" "expected at least 15 of each"
  tb_dod_silent_on "[0] the collapsed set agreed with itself, so no per-fragment red was printed" "exists but"
  TB_DOD_CASES=$((TB_DOD_CASES + 1))
}

tb_run_dod_wiring_cases() {
  local floor
  floor=$(tb_dod_floor)
  if [ -z "$floor" ]; then
    tb_bad "[0]/[0b]: no 'DOD_OK_FLOOR=<n>' assignment found in scripts/validate-dod.sh, so the wiring cases cannot run"
    return
  fi
  tb_case_dod_ok_floor "$floor"
  tb_case_dod_unsourced "$floor"
  tb_case_dod_missing "$floor"
  tb_case_dod_empty_set "$floor"
  if [ "$TB_DOD_CASES" -eq "$TB_DOD_EXPECTED" ]; then
    tb_ok "[0]/[0b]: all $TB_DOD_EXPECTED wiring cases ran to completion"
  else
    tb_bad "[0]/[0b]: $TB_DOD_CASES of $TB_DOD_EXPECTED wiring cases ran, the rest were never called or left early"
  fi
}

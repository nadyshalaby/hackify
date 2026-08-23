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
}

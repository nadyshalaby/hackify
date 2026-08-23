# shellcheck shell=bash

# Validate the hackify plugin against its shipping Definition of Done.
# Run from repo root. Exits 0 if all checks pass, non-zero on any failure.

# Note: -e is intentionally omitted, this script accumulates failures into
# FAILED and exits non-zero at the end. -e would abort on the first failed
# check and hide the rest.
# This module defines shared helpers and is sourced first by the validate-dod.sh orchestrator. No check groups live here.

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

# Every printed pass is tallied here so the orchestrator can assert a FLOOR on
# the run's total at the end, which is [0b] in scripts/validate-dod.sh. Only
# lines carrying the "  ok   " verdict prefix count: "ALL CHECKS PASSED" is a
# summary, not a check, and must not pad the number that polices the summary.
#
# IT IS THE SHELL-SIDE TOTAL, AND THAT IS THREE BELOW THE TRANSCRIPT. [57] and
# [85] delegate to scripts/check_doc_links.py and scripts/check_design_specs.py,
# which print their own ok lines in validator format without passing through
# here, so a `grep -c` over the output reads three higher than this counter.
# Measured, not assumed: 1401 ok lines in the transcript against 1398 here. The
# gap is safe to leave because both fragments test the checker's EXIT STATUS and
# raise FAILED themselves, so a delegated check that stops running fails loudly
# rather than quietly shrinking the run. Counting their stdout instead would mean
# parsing a child process's output to police a number, which is a worse bargain.
#
# ASSIGNED ONLY IF UNSET. [0] in the orchestrator runs BEFORE this file is
# sourced and tallies its own ok line into the same variable. A plain
# DOD_OK_COUNT=0 here would reset that to zero and lose it, which is a counter
# under-reporting the run it exists to police.
DOD_OK_COUNT=${DOD_OK_COUNT:-0}
green() {
  case "${1:-}" in
    '  ok   '*) DOD_OK_COUNT=$((DOD_OK_COUNT + 1)) ;;
  esac
  printf '\033[32m%s\033[0m\n' "$*"
}

check_file() {
  if [ -f "$1" ]; then
    green "  ok   $1"
  else
    red "  MISS $1"
    FAILED=$((FAILED + 1))
  fi
}

check_jq() {
  if jq -e . "$1" > /dev/null 2>&1; then
    green "  ok   $1 parses as valid JSON"
  else
    red "  FAIL $1 is not valid JSON"
    FAILED=$((FAILED + 1))
  fi
}

# FAIL CLOSED ON A GREP THAT NEVER RAN. grep's status used to be thrown away: it
# was the head of a pipe, so under `set -o pipefail` the substitution read back
# awk's status, and awk succeeds on empty input. grep exiting 2 on a path it
# cannot read, or 127 when there is no matcher at all, both arrived here as
# count=0 and printed green having screened nothing. check_no_tokens_in below
# already reds on rc > 1 and states why ("a screen that never ran must never be
# the reason a token prints green"), then falls back to THIS function for every
# token, so the two halves disagreed: one honest red followed by N unearned
# greens. Same rule now holds on both sides of that call.
#
# The status is grep's alone because a command substitution carries the status of
# the command inside it, and there is no pipe left inside it to launder. `local
# out` is declared apart from the assignment: `local out=$(...)` reports the
# status of the `local` builtin, which is the original bug in a new place.
#
# The rationale sits above the function rather than inside it, matching
# check_list_size, ban_tokens_ok and check_no_tokens_in below, and keeping the
# body inside the 40-line cap it would otherwise breach by one.
check_no_token() {
  local token="$1"
  local path="$2"
  local count out rc
  # -I skips binary files: Python bytecode (__pycache__/*.pyc) embeds absolute
  # source paths that would otherwise be counted as personal-handle/leaked-path hits.
  # /usr/bin/grep by absolute path, matching check_no_tokens_in below: this
  # function IS that function's fallback, so the two must be one binary and not
  # two resolutions. See the comment above check_no_tokens_in for which shell
  # resolves bare grep to what.
  #
  # THE ABSOLUTE PATH IS SCOPED TO THIS PAIR, and the rest of this file uses bare
  # `grep` on purpose. The claim used to read as if it covered the whole file,
  # which it never did (check_token_present and check_role below are both bare).
  # The line is WHICH WAY A WRAPPER FAILS YOU. Here a grep that honours ignore
  # files skips a file and the ban prints GREEN over content it never read, so the
  # matcher has to be pinned. In a presence check a skipped file makes a token that
  # IS there look missing, which is a RED, loud and immediately investigated. Pin
  # the matcher where a wrapper buys a false pass, not where it buys a false alarm.
  out=$(/usr/bin/grep -rcFiI -- "$token" "$path" 2>/dev/null)
  rc=$?
  if [ "$rc" -gt 1 ]; then
    red "  FAIL '$token' was never screened in $path, grep exited $rc (unreadable path, or no matcher); a count of 0 here would be a count of nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  count=$(printf '%s\n' "$out" | awk -F: '{s+=$2} END {print s+0}')
  if [ "$count" -eq 0 ]; then
    green "  ok   '$token' has 0 occurrences in $path"
  else
    red "  FAIL '$token' has $count occurrences in $path"
    FAILED=$((FAILED + 1))
  fi
}

check_token_present() {
  local token="$1"
  local path="$2"
  if grep -qF -- "$token" "$path" 2>/dev/null; then
    green "  ok   '$token' present in $path"
  else
    red "  FAIL '$token' missing from $path"
    FAILED=$((FAILED + 1))
  fi
}

check_line_range() {
  local file="$1"
  local min="$2"
  local max="$3"
  local lines
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -ge "$min" ] && [ "$lines" -le "$max" ]; then
    green "  ok   $file has $lines lines (range $min..$max)"
  else
    red "  FAIL $file has $lines lines, expected $min..$max"
    FAILED=$((FAILED + 1))
  fi
}

# A list's own length asserted against an expected size the caller wrote by hand
# next to the list. A bound DERIVED from the list cannot police the list: delete
# an entry and a `wc`-style bound drops with it and stays green, which is how a
# floor of 4 once sat under a set of 6 and guarded nothing. Equality against an
# independently written number is the cheapest thing that reddens on BOTH a
# deletion and an addition. Three parameters, at the project cap, so the "what
# went wrong" hint in the red line is generic rather than a fourth argument
# repeated at every call site.
check_list_size() {
  local got="$1"
  local want="$2"
  local label="$3"
  if [ "$got" -eq "$want" ]; then
    green "  ok   $label carries all $want entries"
  else
    red "  FAIL $label carries $got entries, expected exactly $want (an entry was added or dropped without updating the expected size written beside the list)"
    FAILED=$((FAILED + 1))
  fi
}

section_body() {
  awk -v h="$1" '$0 == h {flag=1; next} flag && (/^### / || /^## /) {flag=0} flag' "$2"
}

check_role() {
  local body="$1"
  local label="$2"
  local ok=1
  for marker in "You are " "You reject" "Bias to:" "Bias against:"; do
    if ! echo "$body" | grep -qF "$marker"; then
      red "  FAIL $label missing '$marker'"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  if ! echo "$body" | grep -qE "$ALLOWLIST"; then
    red "  FAIL $label missing framework-allowlist token"
    FAILED=$((FAILED + 1)); ok=0
  fi
  [ "$ok" = "1" ] && green "  ok   $label ROLE 5-element check"
}

# Token-list integrity guard for check_no_tokens_in below. `grep -f` reads one
# pattern per LINE, and that is a vacuous-pass surface failing in two OPPOSITE
# directions, so one guard cannot be a count of non-empty entries. An EMPTY list
# gives grep nothing, which matches nothing and exits 1, which would print every
# token green having measured nothing. A token with no non-space character, or
# one carrying a newline, becomes a BLANK pattern line, and a blank pattern
# matches every line of every file, which quietly destroys the batching. Both are
# refused here, before grep is handed anything.
#
# This used to guard the temp FILE the tokens were written to and count its
# lines, catching the same two shapes at one remove. The temp file is gone, so
# the tokens are screened directly. Same coverage: the file-shaped failures it
# also caught (unwritable, short, truncated) were failures OF THE FILE, and there
# is no longer a file to fail.
ban_tokens_ok() {
  local t
  [ "$#" -gt 0 ] || return 1
  for t in "$@"; do
    case "$t" in
      *$'\n'*) return 1 ;;
      *[![:space:]]*) ;;
      *) return 1 ;;
    esac
  done
  return 0
}

# Ban a whole token list over one path with ONE grep instead of one grep plus one
# awk per token. Same file set, same matcher and the same verdict lines as
# calling check_no_token in a loop, which is what it still does whenever the
# answer is anything other than "clean".
#
# WHY A SCREEN AND NOT A COUNTER. check_no_token reports how many LINES matched,
# and `grep -f` cannot attribute a match back to the token that caused it without
# giving that number up (`grep -o` counts occurrences, not lines, and does not
# re-report overlapping tokens). So the batched grep decides ONLY the yes/no
# question "does anything in this list appear in this path", and the moment the
# answer is yes the original per-token loop re-runs over that path and words the
# failure exactly as before. The common case is a clean path, which now costs one
# grep rather than one per token; a dirty path costs what it always cost, plus
# the screen. No diagnostic detail is traded away for the speed.
#
# The matcher is /usr/bin/grep by absolute path. WHICH SHELL is the whole of the
# question and this used to leave it out. Under the BASH that validate-dod.sh and
# scripts/test_ban_tokens.sh run in, bare `grep` already resolves to
# /usr/bin/grep, so naming it changes nothing today; under the interactive ZSH in
# this environment `grep` is a shell function honouring ignore files, which is the
# premise 77-reviewer-roster.sh hardens its own scan on. Both are true and the
# fragments used to read as if only one could be. check_no_token above now names
# the same absolute path, so the batched screen and the per-token fallback are
# provably one binary instead of one binary and one shell lookup. That also keeps
# the property the asymmetry used to buy by accident: the screen was the stricter
# matcher, seeing every file a wrapper would have skipped, so a screen-negative
# was trustworthy. Identical matchers keep it trivially rather than by luck.
check_no_tokens_in() {
  local path="$1"
  shift
  local rc=0 t
  if [ "$#" -eq 0 ]; then
    red "  FAIL [ban] check_no_tokens_in was called for $path with an empty token list, so it would ban nothing while printing nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  if ban_tokens_ok "$@"; then
    # Process substitution, not a temp file and not a pipe. A temp file cost an
    # mktemp and an rm on every call, about 25 of each per validator run. A pipe
    # would work too, but callers run under `set -o pipefail`, where the status
    # read back is the whole pipeline's rather than grep's, and grep's three
    # distinct statuses (0 match, 1 clean, 2 unreadable) are the entire contract
    # below. A plain command keeps $? grep's alone.
    /usr/bin/grep -qrFiI -f <(printf '%s\n' "$@") -- "$path" 2>/dev/null
    rc=$?
  else
    red "  FAIL [ban] the $#-token pattern list for $path is corrupt (a token that is blank, whitespace-only, or carrying a newline would become a blank pattern line and match every line), so the batched screen cannot be trusted"
    FAILED=$((FAILED + 1))
  fi
  if [ "$rc" -eq 1 ]; then
    for t in "$@"; do green "  ok   '$t' has 0 occurrences in $path"; done
    return
  fi
  # rc 0 is a match. rc 2 or more means grep could not read the path, which is
  # reported rather than swallowed: a screen that never ran must never be the
  # reason a token prints green.
  if [ "$rc" -gt 1 ]; then
    red "  FAIL [ban] the batched screen could not read $path, so its $# token(s) were never screened"
    FAILED=$((FAILED + 1))
  fi
  # A corrupt pattern file leaves rc at 0 on purpose, so it lands here and every
  # token is still banned the slow way. Loud, and never a loss of coverage.
  for t in "$@"; do check_no_token "$t" "$path"; done
}

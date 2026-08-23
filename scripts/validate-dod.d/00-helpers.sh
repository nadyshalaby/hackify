# shellcheck shell=bash

# Validate the hackify plugin against its shipping Definition of Done.
# Run from repo root. Exits 0 if all checks pass, non-zero on any failure.

# Note: -e is intentionally omitted, this script accumulates failures into
# FAILED and exits non-zero at the end. -e would abort on the first failed
# check and hide the rest.
# This module defines shared helpers and is sourced first by the validate-dod.sh orchestrator. No check groups live here.

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

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

check_no_token() {
  local token="$1"
  local path="$2"
  local count
  # -I skips binary files: Python bytecode (__pycache__/*.pyc) embeds absolute
  # source paths that would otherwise be counted as personal-handle/leaked-path hits.
  count=$(grep -rcFiI -- "$token" "$path" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
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

# Pattern-file integrity guard for check_no_tokens_in below. A `grep -f` pattern
# file is a new vacuous-pass surface and it fails in two OPPOSITE directions, so
# one guard cannot be a count of non-empty lines. An EMPTY pattern file matches
# nothing and exits 1, which would print every token green having measured
# nothing. A blank or whitespace-only line matches every line of every file,
# which quietly destroys the batching. So the line total is asserted EQUAL to the
# number of tokens the caller meant to write, which reddens on a token that was
# dropped or one that split itself across two lines, and every line is required
# to carry at least one non-space character.
ban_patternfile_ok() {
  local pf="$1"
  local want="$2"
  local n=0
  local line
  [ -r "$pf" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    case "$line" in
      *[![:space:]]*) ;;
      *) return 1 ;;
    esac
  done < "$pf"
  [ "$n" -eq "$want" ]
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
# The matcher is /usr/bin/grep by absolute path, which is what bare `grep`
# already resolves to under the bash this validator runs in. Naming it makes the
# screen and the per-token fallback provably the same matcher, rather than
# leaving it to whatever a sourcing shell has wrapped grep with.
check_no_tokens_in() {
  local path="$1"
  shift
  local pf="" rc=0 t
  if [ "$#" -eq 0 ]; then
    red "  FAIL [ban] check_no_tokens_in was called for $path with an empty token list, so it would ban nothing while printing nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  pf=$(mktemp "${TMPDIR:-/tmp}/hackify-ban.XXXXXX" 2>/dev/null) || pf=""
  if [ -n "$pf" ] && printf '%s\n' "$@" > "$pf" 2>/dev/null && ban_patternfile_ok "$pf" "$#"; then
    /usr/bin/grep -qrFiI -f "$pf" -- "$path" 2>/dev/null
    rc=$?
  else
    red "  FAIL [ban] the $#-token pattern file for $path is unwritable or corrupt (empty, wrong length, or carrying a blank line that would match every line), so the batched screen cannot be trusted"
    FAILED=$((FAILED + 1))
  fi
  if [ -n "$pf" ]; then rm -f "$pf"; fi
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

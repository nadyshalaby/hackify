# shellcheck shell=bash

# Validate the hackify plugin against its shipping Definition of Done.
# Run from repo root. Exits 0 if all checks pass, non-zero on any failure.

# Note: -e is intentionally omitted — this script accumulates failures into
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
  count=$(grep -rcFi -- "$token" "$path" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
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

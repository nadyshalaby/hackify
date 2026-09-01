# shellcheck shell=bash

# THE WHOLE-FILE SHAPE ASSERTIONS, WHICH ARE THE HELPERS NO ISOLATION RUN
# REACHES. Sourced after 00-helpers.sh and 01-presence-matchers.sh, before every
# check fragment. Definitions only; no check group lives here, exactly like the
# two files above it.
#
# THE SEAM IS THE ONE 01-presence-matchers.sh ALREADY CUT, applied a second time
# and for the same measured reason. FIVE CONSUMERS OUTSIDE THIS DIRECTORY source
# 00-helpers.sh BY NAME and hand it at most one fragment, so every symbol any of
# those runs can call is FROZEN over there and cannot move. That list is written
# out, with how it was measured, at the head of 01-presence-matchers.sh; it is not
# restated here, because two copies of a rationale drift apart.
#
# WHAT IS LEFT OVER IS WHAT IS HERE, and the two of them share a real property
# rather than a leftover bin: both assert something about a WHOLE FILE'S SHAPE
# (does it parse as JSON, is its line count inside a range) rather than about a
# token inside one. Neither is on the isolation surface, checked rather than
# assumed: check_jq is called from 10-required-files.sh:26-28 and nowhere else,
# check_line_range from 20-templates.sh:4 and nowhere else, and neither of those
# fragments is one any isolation consumer sources.
#
# WHY THEY LEFT AT ALL. 00-helpers.sh stood at exactly 500 of the 500-LOC hard cap
# check [80] enforces, so a wave that needed to ADD a helper there could not, and a
# split was the only move left. The frozen set is most of that file, so this is
# small headroom bought honestly rather than the large headroom a reader might
# expect: the change that would actually free 00-helpers.sh is two lines in each of
# the five consumers, sourcing the helper files as a set instead of by name.
#
# THE 02 PREFIX IS THE WHOLE JOB OF THIS FILE'S POSITION, the same way 01's is.
# Definitions must land before the first fragment that calls them, and 10 is the
# first.

check_jq() {
  if jq -e . "$1" > /dev/null 2>&1; then
    green "  ok   $1 parses as valid JSON"
  else
    red "  FAIL $1 is not valid JSON"
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

# shellcheck shell=bash

# [80] File-size cap — every primitive ≤ 500 LOC.
# Enforces the project-agnostic ≤500 LOC hard cap from rules/hard-caps.md
# across the primitive directories. Closes the gap where rules said one
# thing and the validator enforced another (v0.2.7 retrospective).
#
# Portable across bash 3.2 (macOS default) — uses a while-read loop, not mapfile.

CAP_MAX_LOC=500
CAP_SEARCH_PATHS="skills agents rules scripts hooks commands"

yellow "[80] File-size cap — every tracked primitive file ≤ ${CAP_MAX_LOC} LOC"

cap_total=0
cap_oversize=0
while IFS= read -r f; do
  cap_total=$((cap_total + 1))
  loc=$(wc -l < "$f" | tr -d ' ')
  if [ "$loc" -gt "$CAP_MAX_LOC" ]; then
    red "  FAIL ${f} is ${loc} LOC (cap: ${CAP_MAX_LOC})"
    FAILED=$((FAILED + 1))
    cap_oversize=$((cap_oversize + 1))
  fi
done < <(find $CAP_SEARCH_PATHS -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) 2>/dev/null | sort)

if [ "$cap_total" -eq 0 ]; then
  red "  FAIL no files matched the cap search paths — refusing to declare green"
  FAILED=$((FAILED + 1))
elif [ "$cap_oversize" -eq 0 ]; then
  green "  ok   ${cap_total} files scanned; all ≤ ${CAP_MAX_LOC} LOC"
fi

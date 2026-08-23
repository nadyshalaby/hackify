# shellcheck shell=bash

# [80] File-size cap, every primitive ≤ 500 LOC.
# Enforces the project-agnostic ≤500 LOC hard cap from rules/hard-caps.md
# across the primitive directories. Closes the gap where rules said one
# thing and the validator enforced another (v0.2.7 retrospective).
#
# Python joined the scanned extensions in v0.11.0, when render-report.py became
# the first plugin file carrying real logic that the cap could not see.
# Portable across bash 3.2 (macOS default), uses a while-read loop, not mapfile.

CAP_MAX_LOC=500
CAP_SEARCH_PATHS="skills agents rules scripts hooks commands"

yellow "[80] File-size cap, every tracked primitive file ≤ ${CAP_MAX_LOC} LOC"

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
done < <(find $CAP_SEARCH_PATHS -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' -o -name '*.py' \) 2>/dev/null | sort)

if [ "$cap_total" -eq 0 ]; then
  red "  FAIL no files matched the cap search paths, refusing to declare green"
  FAILED=$((FAILED + 1))
elif [ "$cap_oversize" -eq 0 ]; then
  green "  ok   ${cap_total} files scanned; all ≤ ${CAP_MAX_LOC} LOC"
fi

# ---------------------------------------------------------------------------
# [80b] The two 500-LOC counters agree on a real file.
#
# WHY THIS EXISTS: two things in this repo enforce the same 500-line cap and
# they had drifted apart by one. [80] above counts with `wc -l`; the lawkeeper
# scanner (skills/lawkeeper/scripts/checks.py) counts its own lines. The
# scanner used to split on newlines and keep the phantom empty element that
# every POSIX-terminated file produces, so 70-invariants-and-new.sh sat at
# exactly 500, passed [80], and was flagged by the scanner anyway. The
# agreement between the two was prose. This makes it a check.
#
# PROBED AT THE CAP BOUNDARY, IN BOTH DIRECTIONS, which is the only place an
# off-by-one is visible. The cap is set to the probe's own length minus one,
# where the scanner must flag it AND name the real count, then to its exact
# length, where the scanner must go quiet. A count that reads one high fails
# the first assertion; one that reads one low fails the second.
#
# THE PROBE IS THIS FILE. A fragment pinned by name is a path that dies the day
# it is split, and the two fragments sitting at the cap are already queued for
# exactly that. This file cannot go missing while the check that reads it runs.
#
# NEWLINE-TERMINATION IS ASSERTED FIRST. `wc -l` counts newline characters, the
# scanner counts real lines, and those two agree only on a terminated file. On
# a file missing its final newline they legitimately differ by one, so without
# this gate a stripped terminator would redden here and blame the scanner for a
# bug it does not have.
#
# files_scanned IS ASSERTED BEFORE ANY VERDICT IS READ. A scan that never
# reached the probe reports zero findings, which is byte-identical to a clean
# result, and this repo has already been handed one false conclusion by exactly
# that shape.
CAP_SCANNER="skills/lawkeeper/scripts/audit_scan.py"
CAP_PROBE="scripts/validate-dod.d/80-file-size-caps.sh"
CAP_PROBE_LIST=""

yellow "[80b] the two ${CAP_MAX_LOC}-LOC counters agree, wc -l and the lawkeeper scanner"

# Echo "<scoped_paths> <files_scanned> <reported_loc>" for one scan of $CAP_PROBE
# at cap $1. reported_loc is 0 when the probe raised no cap.file-lines finding.
#
# All three numbers are echoed because only the third is the answer and the first
# two are what make it readable. An empty or unwritten path list makes
# audit_scan.py fall back to WALKING THE WHOLE TREE, which scans hundreds of
# unrelated .sh files and would hand a verdict built on some other file's length
# back as if it were the probe's. scoped_paths pins that the scan was scoped at
# all, files_scanned pins that it reached exactly one file, and the finding is
# filtered to the probe's own path rather than max()'d across whatever turned up.
# A scanner that errors prints nothing, which fails all three.
cap_scan_probe() {
  python3 "$CAP_SCANNER" . --paths-from "$CAP_PROBE_LIST" \
    --text-only-ext .sh --max-file-lines "$1" 2>/dev/null | python3 -c '
import json, sys
report = json.load(sys.stdin)
probe = sys.argv[1]
hits = [f["end_line"] for f in report["findings"]
        if f["rule_id"] == "cap.file-lines" and f["file"] == probe]
print(report["config"]["scoped_paths"], report["stats"]["files_scanned"],
      hits[0] if len(hits) == 1 else 0)
' "$CAP_PROBE" 2>/dev/null
}

cap_agree_ready() {
  [ -f "$CAP_SCANNER" ] || { red "  FAIL $CAP_SCANNER missing, cannot cross-check the two counters"; return 1; }
  [ -f "$CAP_PROBE" ] || { red "  FAIL probe $CAP_PROBE missing, cannot cross-check the two counters"; return 1; }
  command -v python3 > /dev/null 2>&1 || { red "  FAIL python3 not available, cannot cross-check the two counters"; return 1; }
  [ "$(tail -c 1 "$CAP_PROBE" | wc -l | tr -d ' ')" = "1" ] || { red "  FAIL probe $CAP_PROBE is not newline-terminated, so wc -l and the scanner do not measure the same thing on it"; return 1; }
  return 0
}

# $1 is the probe's wc -l count. Reads the scanner at both sides of that cap.
cap_agree_verdict() {
  local loc="$1" over under
  over=$(cap_scan_probe $((loc - 1)))
  under=$(cap_scan_probe "$loc")
  if [ "${over% *}" != "1 1" ] || [ "${under% *}" != "1 1" ]; then
    red "  FAIL the scan did not land on $CAP_PROBE alone (scoped_paths/files_scanned were '${over% *}' and '${under% *}', expected '1 1' each), so its verdict is about some other file or about nothing"
    FAILED=$((FAILED + 1))
  elif [ "${over##* }" = "0" ]; then
    red "  FAIL the lawkeeper scanner did not flag $CAP_PROBE at a cap of $((loc - 1)), so it counts the file at fewer than the $loc lines wc -l counts, the two ${CAP_MAX_LOC}-LOC enforcers disagree"
    FAILED=$((FAILED + 1))
  elif [ "${over##* }" != "$loc" ]; then
    red "  FAIL wc -l reads $CAP_PROBE as $loc LOC, the lawkeeper scanner reads it as ${over##* }, the two ${CAP_MAX_LOC}-LOC enforcers disagree"
    FAILED=$((FAILED + 1))
  elif [ "${under##* }" != "0" ]; then
    red "  FAIL the lawkeeper scanner flags $CAP_PROBE at a cap of $loc, but a file of exactly $loc lines is AT the cap, not over it"
    FAILED=$((FAILED + 1))
  else
    green "  ok   both counters read $CAP_PROBE as $loc LOC, and agree at the cap boundary"
  fi
}

if ! cap_agree_ready; then
  FAILED=$((FAILED + 1))
else
  CAP_PROBE_LIST=$(mktemp)
  printf '%s\n' "$CAP_PROBE" > "$CAP_PROBE_LIST"
  if [ ! -s "$CAP_PROBE_LIST" ]; then
    red "  FAIL could not write the scoped path list, and an empty one silently widens the scan to the whole tree"
    FAILED=$((FAILED + 1))
  else
    cap_agree_verdict "$(wc -l < "$CAP_PROBE" | tr -d ' ')"
  fi
  rm -f "$CAP_PROBE_LIST"
fi

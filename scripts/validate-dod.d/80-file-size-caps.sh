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

# THE REPO ROOT WAS NEVER IN THIS SCAN. CAP_SEARCH_PATHS is six DIRECTORIES, and
# `find` on a directory never climbs out of it, so CHANGELOG.md and README.md,
# the two longest markdown files this repo ships, sat outside the only mechanism
# enforcing the 500-line cap for the whole life of this check. The cap was not
# being relaxed for them, it had never been applied to them at all, which is the
# same coverage-shaped hole every other block in this fragment exists to refuse.
#
# `-maxdepth 1` and no deeper. Everything below the root either already lives in
# one of the six directories above or is generated output (dist/ is gitignored
# and rebuilt by scripts/sync-runtimes.sh), which this cap has never claimed.
#
# THE `./` PREFIX IS STRIPPED HERE, not at each use. `find .` emits `./README.md`
# while `find skills` emits `skills/...`, and every consumer below (the exemption
# set membership, the root-witness comparison, the FAIL line a reader has to
# paste into an editor) compares against a repo-relative path. Normalising once
# at the source is what stops a file being scanned under one spelling and
# exempted under another, which would leave README.md unenforced while the check
# still printed a count that included it.
cap_file_list() {
  find $CAP_SEARCH_PATHS -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' -o -name '*.py' \) 2>/dev/null
  find . -maxdepth 1 -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' -o -name '*.py' \) 2>/dev/null | sed 's|^\./||'
}

# APPEND-ONLY EXEMPTION, and the only class of file that gets one. A changelog
# grows by one entry per release and never by a refactor, so "split it by
# responsibility", the remedy the 500-line cap exists to force, has no meaning
# here: there is no second responsibility to split out, and the file is read by
# jumping to a heading rather than end to end. The rationale ships beside the
# other carve-outs in skills/lawkeeper/references/carve-outs.md; this list is the
# mechanical half of it, and neither half is any use alone. An exemption written
# down with no scan behind it leaves README.md silently unenforced while looking
# like coverage, and a scan with no exemption reddens on a file nobody intends to
# split.
#
# EXEMPTION IS FROM THE CAP, NEVER FROM THE SCAN. An exempt file is still opened,
# still counted in cap_total, and still reported through cap_exempt, so it cannot
# quietly leave the set the way a `find`-level exclusion would let it.
CAP_APPEND_ONLY="CHANGELOG.md"

# The list's LENGTH, written a SECOND time, per the argument above
# check_list_size in 00-helpers.sh and the same pin [27d] carries over
# MRP_KNOWN_UNTAGGED. Appending a file here to silence a cap failure cannot land
# without also editing this number, which is the line a reviewer actually reads.
CAP_APPEND_ONLY_EXPECTED=1

# THE SCANNER CARRIES THE SAME LIST, AND THE TWO ARE CHECKED RATHER THAN TRUSTED TO
# MATCH. skills/lawkeeper/scripts/exemptions.py waives `cap.file-lines` on the same
# basenames, so a `/lawkeeper` run stops reporting the one file this check stops failing
# on. Two enforcers of one 500-line cap have already drifted apart by one in this repo,
# which is the whole reason [80b] below exists; an exemption list is the same shape of
# agreement and earns the same treatment, a check instead of prose. python3 is not a new
# requirement here, [80b] already reddens without it.
#
# The two do NOT match on scope, and that is deliberate rather than drift: this list is
# compared against a repo-relative path and so waives the ROOT changelog alone, while the
# scanner compares basenames because it is pointed at arbitrary roots. They coincide at a
# repo root, which is the only place this check runs. Only the CONTENTS are cross-checked.
CAP_EXEMPTIONS="skills/lawkeeper/scripts/exemptions.py"

# The one root file this check actually ENFORCES, named rather than counted. With
# CHANGELOG.md exempt, a bare "the root scan found N files" floor is satisfied by
# the exempt file alone, so the scan could reach the root, enforce nothing, and
# still print a confident count. Naming the witness is what makes the root half
# of this check non-vacuous. It costs a visible edit the day README.md is renamed,
# which is the trade every hand-written pin in this validator makes on purpose.
CAP_ROOT_WITNESS="README.md"

CAP_NL='
'

yellow "[80] File-size cap, every tracked primitive file ≤ ${CAP_MAX_LOC} LOC"

cap_total=0
cap_root=0
cap_oversize=0
cap_exempt=0
cap_witness=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  cap_total=$((cap_total + 1))
  case "$f" in */*) ;; *) cap_root=$((cap_root + 1)) ;; esac
  [ "$f" = "$CAP_ROOT_WITNESS" ] && cap_witness=1
  loc=$(wc -l < "$f" | tr -d ' ')
  [ "$loc" -gt "$CAP_MAX_LOC" ] || continue
  case "$CAP_NL$CAP_APPEND_ONLY$CAP_NL" in
    *"${CAP_NL}${f}${CAP_NL}"*) cap_exempt=$((cap_exempt + 1)); continue ;;
  esac
  red "  FAIL ${f} is ${loc} LOC (cap: ${CAP_MAX_LOC})"
  FAILED=$((FAILED + 1))
  cap_oversize=$((cap_oversize + 1))
done < <(cap_file_list | sort)

# An exemption whose file has been split, or renamed, or deleted takes no branch
# above and would outlive its reason in silence. Same shape as [27d]'s mrp_stale.
cap_known_total=0
cap_stale=""
while IFS= read -r cap_x; do
  [ -n "$cap_x" ] || continue
  cap_known_total=$((cap_known_total + 1))
  [ -f "$cap_x" ] || { cap_stale="$cap_stale $cap_x(gone)"; continue; }
  [ "$(wc -l < "$cap_x" | tr -d ' ')" -gt "$CAP_MAX_LOC" ] || cap_stale="$cap_stale $cap_x(now under the cap)"
done <<CAP_EXEMPT_EOF
$CAP_APPEND_ONLY
CAP_EXEMPT_EOF
check_list_size "$cap_known_total" "$CAP_APPEND_ONLY_EXPECTED" "the [80] CAP_APPEND_ONLY exemption list"

cap_scanner_exempt() {
  python3 -c '
import sys
sys.path.insert(0, sys.argv[1])
from exemptions import APPEND_ONLY_BASENAMES
print("\n".join(sorted(APPEND_ONLY_BASENAMES)))
' "${CAP_EXEMPTIONS%/*}" 2> /dev/null
}

cap_one_line() { echo "$1" | tr '\n' ' '; }

cap_scanner_list=$(cap_scanner_exempt)
cap_shell_list=$(printf '%s\n' "$CAP_APPEND_ONLY" | sort)
if [ ! -f "$CAP_EXEMPTIONS" ]; then
  red "  FAIL $CAP_EXEMPTIONS is missing, so nothing cross-checks this exemption list against the scanner's and the two can drift unobserved"
  FAILED=$((FAILED + 1))
elif [ -z "$cap_scanner_list" ]; then
  red "  FAIL could not read APPEND_ONLY_BASENAMES out of $CAP_EXEMPTIONS; a list that cannot be read is not a list that agrees"
  FAILED=$((FAILED + 1))
elif [ "$cap_scanner_list" != "$cap_shell_list" ]; then
  red "  FAIL this check waives [$(cap_one_line "$cap_shell_list")] from the ${CAP_MAX_LOC}-LOC cap and $CAP_EXEMPTIONS waives [$(cap_one_line "$cap_scanner_list")]; the two enforcers of one cap would exempt different files"
  FAILED=$((FAILED + 1))
else
  green "  ok   CAP_APPEND_ONLY and $CAP_EXEMPTIONS waive the same ${CAP_APPEND_ONLY_EXPECTED} file(s) from the ${CAP_MAX_LOC}-LOC cap"
fi

if [ "$cap_total" -eq 0 ]; then
  red "  FAIL no files matched the cap search paths, refusing to declare green"
  FAILED=$((FAILED + 1))
elif [ "$cap_witness" -eq 0 ]; then
  red "  FAIL the cap scan never reached $CAP_ROOT_WITNESS, so the repo root went unenforced while $cap_total files were counted; the root half of this scan is measuring nothing"
  FAILED=$((FAILED + 1))
elif [ "$cap_oversize" -eq 0 ]; then
  green "  ok   ${cap_total} files scanned (${cap_root} at the repo root, ${CAP_ROOT_WITNESS} among them); all ≤ ${CAP_MAX_LOC} LOC bar ${cap_exempt} append-only exemption(s)"
fi

if [ -n "$cap_stale" ]; then
  yellow "  note CAP_APPEND_ONLY still exempts$cap_stale, prune the entry and drop CAP_APPEND_ONLY_EXPECTED to match so the list keeps shrinking"
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
# THE PROBE IS THIS FILE, AND THE PATH IS DERIVED FROM ${BASH_SOURCE[0]}, NOT
# TYPED. That second half is the correction. This block shipped in v0.14.2 saying
# the probe survives the day the fragment is split or renamed, while CAP_PROBE was
# a string literal naming this exact path, so the code did not have the property
# the prose claimed and a rename would have reddened the check rather than moved
# it. ${BASH_SOURCE[0]} is the mechanism the claim describes, it is available in a
# sourced fragment, and the orchestrator already uses it two levels up.
#
# MADE RELATIVE TO REPO_ROOT, never used bare. DOD_MODULES_DIR is absolute, so bare
# BASH_SOURCE hands back an absolute path, and audit_scan.py tests EVERY component
# of a listed path against its skipped-directory set. `dist`, `build`, `out`,
# `vendor` and `.cache` are all in that set, so a checkout living under any of them
# (a CI temp path, a worktree) would land the probe in paths_in_skipped_dir,
# files_scanned would read 0, and the check would redden on a perfectly correct
# repo purely because of where it was cloned. The relative form cannot do that.
# The guard below refuses an absolute CAP_PROBE outright rather than scanning with
# it, because a REPO_ROOT that did not match would otherwise reopen this silently.
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
CAP_PROBE="${BASH_SOURCE[0]#"${REPO_ROOT:-}"/}"
CAP_PROBE_LIST=""

yellow "[80b] the two ${CAP_MAX_LOC}-LOC counters agree, wc -l and the lawkeeper scanner"

# Echo "<listed_lines> <scoped_paths> <files_scanned> <lines_unaccounted> <reported_loc>"
# for one scan of $CAP_PROBE at cap $1. reported_loc is 0 when the probe raised no
# cap.file-lines finding.
#
# ONLY THE LAST NUMBER IS THE ANSWER. The four ahead of it are what make it
# readable, and each one refuses a different way of getting a confident verdict
# about the wrong thing:
#   listed_lines      how many lines the parse stage READ out of the path list
#   scoped_paths      how many paths it got OUT of them
#   files_scanned     how many files the scan actually opened
#   lines_unaccounted lines that reached no counter at all, which must be 0
# THE WHOLE-TREE FALLBACK THESE FOUR ONCE GUARDED AGAINST IS GONE, and this prose
# outlived it by a wave. audit_scan.py now scopes on whether the FLAG was supplied,
# so an empty list scans nothing rather than widening to the tree, and a
# `--paths-from` naming a file that was never written exits 2. What the four still
# refuse is everything that fix does not cover: a list the parse stage quietly ate a
# line from, a probe that resolved to no file or to more than one, and a verdict read
# off some other file's length. The finding is filtered to the probe's own path
# rather than max()'d across whatever turned up. A scanner that errors prints
# nothing, which fails all five.
#
# listed_lines IS THE ONE THAT CATCHES A LOSSY LIST, and lines_unaccounted is not
# a substitute for it. audit_scan.py drops a blank, a `#` comment and a repeated
# path at parse time, on purpose, and BUCKETS each drop, so lines_unaccounted stays
# 0 through all three. MEASURED: a list of the probe plus a blank, a duplicate and
# a comment reports listed_lines 4, scoped_paths 1, lines_unaccounted 0. Reading
# only the reconcile would have called that clean. Asserting listed_lines ==
# scoped_paths == 1 is what says every line the list carried became the one path
# the probe needs, with nothing eaten quietly on the way in.
cap_scan_probe() {
  python3 "$CAP_SCANNER" . --paths-from "$CAP_PROBE_LIST" \
    --text-only-ext .sh --max-file-lines "$1" 2>/dev/null | python3 -c '
import json, sys
report = json.load(sys.stdin)
probe = sys.argv[1]
hits = [f["end_line"] for f in report["findings"]
        if f["rule_id"] == "cap.file-lines" and f["file"] == probe]
print(report["config"]["listed_lines"], report["config"]["scoped_paths"],
      report["stats"]["files_scanned"], report["stats"]["lines_unaccounted"],
      hits[0] if len(hits) == 1 else 0)
' "$CAP_PROBE" 2>/dev/null
}

cap_agree_ready() {
  [ -f "$CAP_SCANNER" ] || { red "  FAIL $CAP_SCANNER missing, cannot cross-check the two counters"; return 1; }
  [ -f "$CAP_PROBE" ] || { red "  FAIL probe $CAP_PROBE missing, cannot cross-check the two counters"; return 1; }
  case "$CAP_PROBE" in
    /*) red "  FAIL probe path '$CAP_PROBE' is absolute, so REPO_ROOT did not match \${BASH_SOURCE[0]}; audit_scan.py would test every leading directory against its skip set and could drop the probe into paths_in_skipped_dir"; return 1 ;;
  esac
  command -v python3 > /dev/null 2>&1 || { red "  FAIL python3 not available, cannot cross-check the two counters"; return 1; }
  [ "$(tail -c 1 "$CAP_PROBE" | wc -l | tr -d ' ')" = "1" ] || { red "  FAIL probe $CAP_PROBE is not newline-terminated, so wc -l and the scanner do not measure the same thing on it"; return 1; }
  return 0
}

# $1 is the probe's wc -l count. Reads the scanner at both sides of that cap.
cap_agree_verdict() {
  local loc="$1" over under
  local want="1 1 1 0"
  over=$(cap_scan_probe $((loc - 1)))
  under=$(cap_scan_probe "$loc")
  if [ "${over% *}" != "$want" ] || [ "${under% *}" != "$want" ]; then
    red "  FAIL the scan did not land on $CAP_PROBE alone and whole (listed_lines/scoped_paths/files_scanned/lines_unaccounted were '${over% *}' and '${under% *}', expected '$want' each), so its verdict is about some other file, about nothing, or about a list the parse stage quietly ate a line from"
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
  # EXIT trap, matching scripts/test_ban_tokens.sh. The `rm -f` below is on the
  # happy path only, so anything that leaves between the mktemp above and it, a
  # Ctrl-C during either python3 call being the realistic one, strands the file.
  # MEASURED, not assumed: an `exit` planted inside that window leaks one temp file
  # without this line and zero with it.
  #
  # Armed and cleared around the window rather than left standing. A sourced
  # fragment shares one trap table with the whole run, so a standing EXIT trap here
  # would silently replace the next fragment's if one is ever added, and there is
  # nothing left to clean up once `rm -f` has run. Nothing else in the validator
  # traps EXIT today, which is what makes the clearing cheap rather than lossy.
  trap 'rm -f "$CAP_PROBE_LIST"' EXIT
  printf '%s\n' "$CAP_PROBE" > "$CAP_PROBE_LIST"
  if [ ! -s "$CAP_PROBE_LIST" ]; then
    red "  FAIL could not write the scoped path list, and an empty one scopes the scan to zero files, so the verdict below would be about nothing at all"
    FAILED=$((FAILED + 1))
  else
    cap_agree_verdict "$(wc -l < "$CAP_PROBE" | tr -d ' ')"
  fi
  rm -f "$CAP_PROBE_LIST"
  trap - EXIT
fi

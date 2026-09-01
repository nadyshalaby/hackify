# shellcheck shell=bash

# Validate the hackify plugin against its shipping Definition of Done.
# Run from repo root. Exits 0 if all checks pass, non-zero on any failure.

# Note: -e is intentionally omitted, this script accumulates failures into
# FAILED and exits non-zero at the end. -e would abort on the first failed
# check and hide the rest.
# Sourced first by the validate-dod.sh orchestrator. Printers, the ok counter,
# the line-oriented absence family, one presence check and the rename-absence
# scanner. No check groups live here.
#
# THIS FILE IS THE ENTRY POINT TO THE HELPER SET, WHICH IS NOT THE SAME CONTRACT
# IT USED TO BE. Sourcing it also sources every other `0*.sh` beside it, and the
# loop that does so is at the foot of this file with the argument for it. Nothing
# outside scripts/validate-dod.d/ names a second helper file, so a consumer that
# sources this one has the whole set and a helper may live in whichever fragment
# it belongs in. WHAT THAT RETIRES is the frozen list this header used to carry:
# a symbol reachable from an isolation run no longer has to be defined HERE, and
# moving one out is a refactor again rather than a CI break.
#
# WHERE THE REST OF THE SET LIVES. 01-presence-matchers.sh holds the presence
# matchers and both flattened matchers, ban side and presence side, plus the
# shared membership count; 02-file-shape-checks.sh holds the whole-file shape
# assertions. Which file a helper sits in is a question of what it is, not of
# who can reach it.
#
# ONE HELPER LEFT WITHOUT MOVING. section_body() was deleted rather than split
# out: it had ONE definition and ZERO callers anywhere in the tree, dist/
# included, which a Phase 5 refuter had already recorded as an upheld Minor
# against the tree at dabc333:73 without anyone acting on it.

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

# Every printed pass is tallied here so the orchestrator can assert a FLOOR on
# the run's total at the end, which is [0b] in scripts/validate-dod.sh. Only
# lines carrying the "  ok   " verdict prefix count: "ALL CHECKS PASSED" is a
# summary, not a check, and must not pad the number that polices the summary.
#
# IT IS THE SHELL-SIDE TOTAL, and it sits below the transcript by the number of
# delegated INVOCATIONS rather than of checkers, which is a property of the tree
# and not a constant. [0b] in scripts/validate-dod.sh states that gap in full,
# names which invocations make it up, and says why it is 3 on a built tree and 2
# without dist/. It is not restated here, and NO ABSOLUTE TOTAL IS RECORDED HERE
# EITHER: six separate figures were reported for this one pair inside a single
# review round, each measuring a different tree state and each quoting the last
# rather than counting, so writing today's total here just schedules the seventh.
#
# TAKE BOTH HALVES FROM ONE RUN OF YOUR OWN if you need them, and never adjust one
# against a number quoted from somewhere else. The floor in [0b] is what actually
# guards the run; it is a floor precisely so it does not need editing per wave. The
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
# check_list_size, ban_tokens_ok and check_no_tokens_in below, and keeping the body
# inside the 40-line cap it would otherwise breach by one.
#
# -I SKIPS BINARY FILES: Python bytecode (__pycache__/*.pyc) embeds absolute
# source paths that would otherwise be counted as personal-handle or leaked-path
# hits.
#
# /usr/bin/grep BY ABSOLUTE PATH, matching check_no_tokens_in below, whose comment
# carries which shell resolves bare grep to what: this function IS that function's
# fallback, so the two must be one binary and not two resolutions.
#
# WHICH WAY A WRAPPER FAILS YOU is still the whole of why this side was pinned
# FIRST and why it is the side that must never be unpinned: here a grep honouring
# ignore files skips a file and the ban prints GREEN over content it never read,
# while in a presence check a skipped file makes a present token look missing, a
# RED, loud and investigated at once. That asymmetry is real, it is why this was
# never urgent on the presence side, and it is a rule about where pinning is
# REQUIRED rather than a reason to leave the other side unpinned.
#
# THE ASYMMETRY IS RETIRED ANYWAY, AND check_token_present NAMES THE SAME BINARY.
# It used to be argued for here in a paragraph, which was the entire cost of
# keeping it: under the bash both validate-dod.sh and scripts/test_ban_tokens.sh run
# in, bare `grep` already resolves to /usr/bin/grep, so the difference bought
# nothing at any call site and cost one explanation forever, plus a false RED
# waiting in any shell where it did not. One binary across the whole file is
# cheaper to hold in the head than a correct argument for two.
#
# OCCURRENCES, NOT MATCHING LINES, which is what -o buys. `grep -c` reports how
# many LINES matched, so two hits on one line reported 1 and the red understated a
# regression it had otherwise detected. `-o` prints one line per occurrence and the
# count is how many lines it printed, which also retires the colon-in-a-filename
# hazard by construction: nothing parses a `file:count` field any more, and the
# single-file / directory split that existed only to sum those fields is gone with
# it. THE COUNT IS TAKEN BY PARAMETER EXPANSION AND NO FORK, so the awk that sum
# needed is off the hot path this function sits on.
#
# rc IS READ BEFORE THE OUTPUT, and that ordering is the fail-closed part. grep
# says 1 for "nothing matched", the only green here, and above 1 for "never
# looked"; inferring either from an empty stream would collapse them into one
# verdict. It also catches the case -o introduces that -c did not have: a
# ZERO-LENGTH pattern, which an empty or whitespace-only token is, matches
# everywhere and prints nothing, so grep reports 0 with no output to count. Under
# -c that token counted every line and reported a hit. Under -o it would report a
# clean scan, the exact false green this helper exists to refuse, so it reds.
check_no_token() {
  local token="$1"
  local path="$2"
  local count newlines out rc
  out=$(/usr/bin/grep -roFiI -- "$token" "$path" 2>/dev/null)
  rc=$?
  if [ "$rc" -gt 1 ]; then
    red "  FAIL '$token' was never screened in $path, grep exited $rc (unreadable path, or no matcher); a count of 0 here would be a count of nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  if [ "$rc" -eq 1 ]; then
    green "  ok   '$token' has 0 occurrences in $path"
    return
  fi
  if [ -z "$out" ]; then
    red "  FAIL '$token' matched but yielded no countable occurrences in $path; a zero-length pattern, which an empty or whitespace-only token is, matches everywhere and prints nothing, so a count of 0 here would be a count of nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  newlines=${out//[^$'\n']/}
  count=$(( ${#newlines} + 1 ))
  red "  FAIL '$token' has $count occurrences in $path"
  FAILED=$((FAILED + 1))
}

# ONE TOKEN, ONE GREP, AND IT STAYS THAT WAY: grep -qF stops at the first match
# and never reads the rest of the file, which beats reading the whole thing into a
# variable. For a RUN of pins over ONE path the trade inverts, and that is
# check_tokens_present_in in 01-presence-matchers.sh; the two print the same
# verdict lines, so a call site moves between them without moving the transcript.
# THIS ONE STAYS HERE because 81-no-claude-attribution.sh calls it seven times and
# the tamper battery runs that fragment against this file alone.
check_token_present() {
  local token="$1"
  local path="$2"
  if /usr/bin/grep -qF -- "$token" "$path" 2>/dev/null; then
    green "  ok   '$token' present in $path"
  else
    red "  FAIL '$token' missing from $path"
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

# Token-list integrity guard for check_no_tokens_in below. `grep -f` reads one
# pattern per LINE, a vacuous-pass surface failing in two OPPOSITE directions, so
# one guard cannot be a count of non-empty entries. An EMPTY list gives grep
# nothing, which matches nothing and exits 1, which would print every token green
# having measured nothing. A token with no non-space character, or one carrying a
# newline, becomes a BLANK pattern line, and a blank pattern matches every line of
# every file, which quietly destroys the batching. Both are refused here, before
# grep is handed anything. This used to guard the temp FILE the tokens were written
# to and count its lines, catching the same two shapes at one remove; the temp file
# is gone, and its own failures (unwritable, short, truncated) went with it.
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

# Ban a whole token list over one path with ONE grep instead of one per token.
# Same file set, same matcher and the same verdict lines as calling
# check_no_token in a loop, which is what it still does whenever the answer is
# anything other than "clean".
#
# WHY A SCREEN AND NOT A COUNTER. `grep -f` takes the whole list in one pass but
# cannot attribute a hit back to the token that caused it, and a per-token count
# is exactly what the verdict lines report. So the batched grep decides ONLY the
# yes/no question "does anything in this list appear in this path", and the
# moment the answer is yes the original per-token loop re-runs over that path and
# words the failure exactly as before. The common case is a clean path, which now
# costs one grep rather than one per token; a dirty path costs what it always
# cost, plus the screen. No diagnostic detail is traded away for the speed.
#
# The matcher is /usr/bin/grep by absolute path, and WHICH SHELL is the whole of
# the question. Under the BASH that validate-dod.sh and scripts/test_ban_tokens.sh
# run in, bare `grep` already resolves to /usr/bin/grep, so naming it changes
# nothing today; under the interactive ZSH in this environment `grep` is a shell
# function honouring ignore files, the premise 77-reviewer-roster.sh hardens its own
# scan on. check_no_token above names the same absolute path, so the batched screen
# and the per-token fallback are provably one binary rather than one binary and one
# shell lookup, which keeps the property the asymmetry used to buy by accident: the
# screen saw every file a wrapper would have skipped, so a screen-negative was
# trustworthy. Identical matchers keep that trivially rather than by luck.
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

# THE RENAME-ABSENCE SCAN, generalized on its SECOND use and not before: [40] in
# 73-implementer-rename.sh built it, [89] copied it, and the copies were 21
# identical lines out of 31. EVERY BRANCH BELOW IS ARGUED CANONICALLY AT THE HEAD
# OF [40] and is not restated here, and WHAT DIFFERS BETWEEN THE CALLERS IS A
# PARAMETER measured beside each wrapper rather than a behaviour smoothed into one.
#
# THE MODE NAME IS THE GIT FLAG, which is what lets one dispatcher serve both:
# `worktree` means no flag, anything else is `--<mode>`. It is also the word the
# verdicts print, and a single-mode caller prints none, because that word says
# WHICH HALF of a union spoke and one half is no union.
#
# THE PROFILE, set by the caller's wrapper immediately before it delegates: RN_ID,
# the check id every verdict names; RN_NOUN, what the literal is in the caller's
# words; RN_LIST, what an empty argument list would have been; RN_MODES, the halves
# to union, in order; RN_PATHS, the pathspec bounding the scan. Written inline in
# BOTH wrappers rather than by a shared setter, because
# scripts/test_ban_tokens.d/15-wi-absent-cases.sh sed-lifts wi_absent and
# wi_absent_all out of their fragment by name and evals the text, and a wrapper
# calling a third function would eval into a reference that suite cannot resolve.
rename_git() {
  local f=''
  [ "$1" = worktree ] || f="--$1"
  git grep ${f:+"$f"} "$2" "${RN_PATS[@]}" -- "${RN_PATHS[@]}"
}

rename_absent() {
  local lit="$1" mode hits rc err errtxt prev ph found=''
  local -a RN_PATS=(-e "$lit")
  err=$(mktemp 2>/dev/null) || err=''
  if [ -z "$err" ]; then
    red "  FAIL $RN_ID could not create the stderr capture file, so the scan for '$lit' never ran"
    FAILED=$((FAILED + 1))
    return
  fi
  prev=$(trap -p EXIT)
  trap 'rm -f "$err"' EXIT
  for mode in ${RN_MODES[@]+"${RN_MODES[@]}"}; do
    hits=$(rename_git "$mode" -nF 2>"$err")
    rc=$?
    errtxt=$(cat "$err")
    { [ "$rc" -gt 1 ] || [ -n "$errtxt" ] || [ -n "$hits" ]; } && break
  done
  rm -f "$err"
  if [ -n "$prev" ]; then eval "$prev"; else trap - EXIT; fi
  if [ "$rc" -le 1 ] && [ -z "$errtxt" ] && [ -z "$hits" ]; then
    green "  ok   $RN_NOUN '$lit' survives in no live file"
    return
  fi
  ph=scan
  [ "${#RN_MODES[@]}" -gt 1 ] && { ph="$mode scan"; found=", found by the $mode scan"; }
  FAILED=$((FAILED + 1))
  if [ "$rc" -gt 1 ]; then
    red "  FAIL $RN_ID the $ph for '$lit' exited $rc, so finding nothing here would be finding nothing at all"
  elif [ -n "$errtxt" ]; then
    red "  FAIL $RN_ID the $ph for '$lit' exited $rc but wrote to stderr, so a file it could not read is being counted as a file with nothing in it"
  else
    red "  FAIL $RN_ID $RN_NOUN '$lit' survives in a live file$found:"
    printf '%s\n' "$hits" | sed 's/^/         - /'
    return
  fi
  printf '%s\n' "${errtxt:-exited $rc without writing anything to stderr}" | sed 's/^/         git: /'
}

rename_absent_all() {
  local mode rc err errtxt prev lit
  local -a RN_PATS=()
  if [ "$#" -eq 0 ]; then
    red "  FAIL $RN_ID the batched screen was handed an empty $RN_LIST, so it would ban nothing while printing nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  for lit in "$@"; do RN_PATS+=(-e "$lit"); done
  err=$(mktemp 2>/dev/null) || err=''
  if [ -n "$err" ]; then
    prev=$(trap -p EXIT)
    trap 'rm -f "$err"' EXIT
    for mode in ${RN_MODES[@]+"${RN_MODES[@]}"}; do
      rename_git "$mode" -qF 2>"$err"
      rc=$?
      errtxt=$(cat "$err")
      { [ "$rc" -ne 1 ] || [ -n "$errtxt" ]; } && break
    done
    rm -f "$err"
    if [ -n "$prev" ]; then eval "$prev"; else trap - EXIT; fi
    if [ "$rc" -eq 1 ] && [ -z "$errtxt" ]; then
      for lit in "$@"; do green "  ok   $RN_NOUN '$lit' survives in no live file"; done
      return
    fi
  fi
  for lit in "$@"; do rename_absent "$lit"; done
}

# THE SELF-CHECK EVERY CONTROL RUNS, WRITTEN ONCE. Three fragments carried their
# own copy of this shape: read FAILED, run a judge with its printing swallowed,
# publish the delta, put FAILED back whatever happened. A control has to OBSERVE a
# judge's verdict and must not leave it behind. THE DELTA AND NOT A YES/NO, because
# a plant built to raise a known NUMBER of reds cannot check itself against a
# boolean; CONTROL_DELTA is a global for the reason RN_ID is one, a return code
# carrying one byte where this is a count. The judge runs as "$@" in THIS shell and
# never a subshell, since what is being measured is a global it mutates.
CONTROL_DELTA=0
control_delta() {
  local cd_before="$FAILED"
  "$@" > /dev/null 2>&1
  CONTROL_DELTA=$((FAILED - cd_before))
  FAILED="$cd_before"
}

# ---------------------------------------------------------------------------
# THE HELPER SET, AND WHY SOURCING THIS FILE LOADS THE REST OF IT.
#
# WHAT THIS REPLACES. Five CI commands sourced this file BY NAME and handed the
# shell at most one check fragment beside it, with no second helper file, so every
# symbol any of those runs could reach had to be defined HERE. That froze most of
# this file in place. It stood at 496 of the 500-LOC cap check [80] enforces, two
# fixes were blocked on the four lines that were left, and the two splits cut
# before this one each bought about one helper of headroom because the frozen set
# was most of what was in the file.
#
# WHAT THE SET IS, DEFINED ONCE AND ONLY HERE. Every `0*.sh` beside this file is a
# definition-only helper fragment, and the loop below sources all of them. So a
# helper may live in ANY of those files and every consumer still finds it, and no
# consumer names a second helper file or holds a list that can go stale. The glob
# is the rule rather than a list, so a helper fragment added tomorrow is in the set
# with no consumer edit at all.
#
# IT CANNOT SILENTLY GO SHORT, which is the whole point of the floor. A glob that
# matches nothing leaves the pattern itself in the array and no file to read, and a
# consumer that copied one helper into a scratch tree resolves fewer files than the
# floor. Either one stops the run with a message on stderr rather than leaving a
# shell that quietly lacks every helper it is about to call, because a shell missing
# its matchers prints a confident nothing. A FLOOR AND NOT AN EQUALITY, on the
# reasoning [0b] gives for its own: ordinary growth must never need an edit here,
# and lowering it takes a stated reason in the same change.
#
# THE ORCHESTRATOR STILL SOURCES EACH HELPER BY NAME AS WELL, and those lines stay.
# Check [0] in scripts/validate-dod.sh and the whole-directory sweep in
# scripts/test_ban_tokens.d/40-fragment-coverage.sh both read one `^source ` line
# per fragment, and a fragment nothing sources by name is exactly the tamper they
# exist to catch. Re-sourcing a definition-only fragment redefines its functions and
# touches no counter, so a full validator run pays two extra file reads for that
# and nothing else.
DOD_HELPER_FLOOR=3
DOD_HELPER_DIR=${BASH_SOURCE[0]%/*}
[ "$DOD_HELPER_DIR" = "${BASH_SOURCE[0]}" ] && DOD_HELPER_DIR=.
DOD_HELPER_SET=("$DOD_HELPER_DIR"/0*.sh)
if [ "${#DOD_HELPER_SET[@]}" -lt "$DOD_HELPER_FLOOR" ] || [ ! -f "${DOD_HELPER_SET[0]}" ]; then
  printf '\033[31m%s\033[0m\n' "  FAIL the helper set beside ${BASH_SOURCE[0]} resolved to ${#DOD_HELPER_SET[@]} entry/entries against a floor of $DOD_HELPER_FLOOR; sourcing it would leave this shell without matchers it is about to call, and a shell missing its matchers prints a confident nothing, so the run stops here" >&2
  exit 1
fi
for dod_helper in "${DOD_HELPER_SET[@]}"; do
  [ "${dod_helper##*/}" = "${BASH_SOURCE[0]##*/}" ] && continue
  source "$dod_helper"
done
unset dod_helper

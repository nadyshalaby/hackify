# shellcheck shell=bash

# THE MATCHERS THAT DO NOT LIVE IN 00-helpers.sh. Definitions only; no check
# group lives here, exactly like the two files either side of it.
#
# WHAT THIS FILE USED TO BE, AND WHY THAT IS OVER. It was carved out of
# 00-helpers.sh when that file hit its 500-LOC cap, and what could move was decided
# by a measured FROZEN LIST rather than by which grouping read best: five CI
# commands outside this directory sourced 00-helpers.sh BY NAME and handed the
# shell at most one check fragment, so every symbol any of those runs could reach
# had to stay over there. The list was longer than any reading of the source lines
# suggested. It included the whole rename family, reached only through
# scripts/test_ban_tokens.d/15-wi-absent-cases.sh, which sed-lifts two wrappers out
# of 73-implementer-rename.sh and evals them into a shell that had sourced the
# helpers alone; both wrappers delegate to rename_absent and rename_absent_all, and
# no source line anywhere shows that path. Taking the list from a run rather than
# from a reading is the only reason it was right.
#
# THE FROZEN LIST IS RETIRED, and this file is what it bought. 00-helpers.sh now
# sources every `0*.sh` beside it, so a consumer that sources that one file has the
# whole set and a symbol reachable from an isolation run may live in any fragment
# of it. The argument, the floor that stops the set going short, and why the
# orchestrator still names each fragment in a `source` line, are all at the foot of
# 00-helpers.sh and are not restated here: two copies of a rationale drift apart.
#
# WHAT IS HERE NOW. The presence matchers 00-helpers.sh had no room for, BOTH
# flattened matchers rather than only the presence one, and the shared membership
# count. The two flowed families sat in different files while the frozen list
# decided where a helper lived; they are twins over one flattening and they belong
# together, which is what the seam can finally be cut on.
#
# NO NUMBER FOR WHAT A SPLIT BUYS IS WRITTEN HERE ANY MORE. This header carried
# one, in lines that read "from 500 to 480", and it was wrong at the moment anyone
# read it because the file it described changes under every wave that touches it.
# An unpinned number in a comment is a rotting claim, which is the rule
# 57-doc-links.sh and 98-work-doc-ledger-sync.sh both state at their own floors.
# Count it if you need it.
#
# SOURCED AFTER 00-helpers.sh AND BEFORE EVERY CHECK FRAGMENT, which is the whole
# job of the 01 prefix: the matchers below call ban_tokens_ok and the printers,
# which 00-helpers.sh defines, and 20-templates.sh onward call what is defined
# here.

# A WHOLE PIN LIST OVER ONE PATH, READ ONCE. The presence side had no batched
# twin while the ban side had check_no_tokens_in, so a fragment pinning fifteen
# sentences in one document forked fifteen greps and opened that document fifteen
# times. 82-throughput-and-routing.sh did exactly that over a 27,531-byte file it
# already opens for ten other pins.
#
# NOT A SCREEN, WHICH IS WHERE THIS DIVERGES FROM THE BAN SIDE. check_no_tokens_in
# runs one batched grep to answer "is ANYTHING here" and falls back to a per-token
# loop the moment the answer is yes, because grep -f cannot attribute a hit to the
# token that caused it. A presence run needs the opposite answer, per token, every
# time, so there is nothing to screen for: the file is read once and each token is
# tested against the text in the shell. No fallback exists because none is needed,
# and no diagnostic is traded for the speed.
#
# THE SUBSTRING TEST IS EXACTLY grep -F's ANSWER, for the reason check_role states
# further down about its own markers: grep -F asks whether the token is a
# substring of some LINE, `[[ == * * ]]` asks whether it is a substring of the
# whole file, and the two answers can only differ for a token that carries a
# newline. ban_tokens_ok refuses that token before the loop runs, along with the
# blank and whitespace-only ones that would otherwise be a substring of every file
# and print an unearned green. It is named for the ban side because that is where
# it was written, and what it guards is the pattern list, not the verdict.
#
# FAIL CLOSED ON A PATH THAT YIELDED NO TEXT, which is check_no_token's rule about
# a grep that never ran, restated for a read. An empty body is indistinguishable
# from a read that failed, so neither one is allowed to be the reason fifteen pins
# print green.
check_tokens_present_in() {
  local path="$1"
  shift
  local t body rc
  if [ "$#" -eq 0 ]; then
    red "  FAIL [pin] check_tokens_present_in was called for $path with an empty token list, so it would assert nothing while printing nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  if ! ban_tokens_ok "$@"; then
    red "  FAIL [pin] the $#-token pin list for $path is corrupt (a blank or whitespace-only token is a substring of every file, and one carrying a newline cannot be a substring of a single line), so the one-read screen cannot be trusted"
    FAILED=$((FAILED + 1))
    return
  fi
  body=$(cat -- "$path" 2>/dev/null)
  rc=$?
  if [ "$rc" -ne 0 ] || [ -z "$body" ]; then
    red "  FAIL [pin] $path yielded no text to read (cat exited $rc), so its $# pin(s) were never looked for; a miss here would be a miss of nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  for t in "$@"; do
    if [[ "$body" == *"$t"* ]]; then
      green "  ok   '$t' present in $path"
    else
      red "  FAIL '$t' missing from $path"
      FAILED=$((FAILED + 1))
    fi
  done
}

# PRESENCE OF A TOKEN AFTER LINE WRAPPING IS FLATTENED, and the reason it had to
# exist. check_token_present above is line-oriented, and the files this validator
# pins are markdown wrapped to a column, so a sentence a reviewer quotes as one
# phrase routinely sits across two physical lines. Asked for such a phrase, grep
# returns a confident zero and check_token_present reds on a file that says
# exactly what it was asked about.
#
# MEASURED BEFORE THIS WAS WRITTEN, not assumed. The phrase `a testing stage that
# runs as one wave` is in skills/hackify/references/sibling-track-rules.md, and
# `/usr/bin/grep -F` for it there returns nothing: `one` ends one line and `wave`
# opens the next. The same is true of `A testing stage that SPLITS is not on that
# list`, which breaks after `stage`. Both are pinned by check [82b].
#
# WHY NOT PIN A SHORTER FRAGMENT THAT FITS ON ONE LINE. Because the fragment that
# fits is chosen by where the paragraph happens to wrap today, so the pin reds the
# next time anyone reflows the file without changing a word of it. A pin that reds
# on a reflow trains the next reader to delete it, which is worse than no pin.
#
# WHAT THE FLATTENING DOES AND DOES NOT DO. Every whitespace run in the file,
# newlines included, becomes ONE space; nothing else changes, so the comparison is
# still a literal one over the file's own words. It reads the whole file into one
# shell variable, which is why it was the PRESENCE side only for as long as it
# was: a token spanning a line break is a false RED here, and a false red is loud.
# THAT IS NO LONGER THE WHOLE STORY and this block used to say it was. The ban
# side has a flattened twin of its own, flowed_flatten and its two callers, which
# sit below in this same file and argue the trade the other way for a spaced token
# over wrapped prose. The two matchers flatten identically; what differs is which
# way each one's mistake points.
#
# ONE FLATTEN PER PATH, NOT PER TOKEN. Every call re-read and re-flattened the
# whole file, so the four-pin loop in 83-testing-stage-shape.sh flattened two
# ~38KB documents eight times between them. The list form below flattens once and
# tests every token against the result, and the single-token form is a two-line
# forward to it, so there is one flattening implementation and not two that can
# drift.
#
# NO PIPE ANYWHERE, which check [84] enforces across scripts/ and this pair
# learned the hard way. Callers run under `set -uo pipefail` and a short-circuiting
# reader exits on its first match, which leaves `tr` killed by SIGPIPE and the
# pipeline reporting 141 instead of the reader's 0. The flattening lands in a
# variable and the tokens are tested in the shell, so there is no pipeline left to
# misreport.
#
# FAIL CLOSED ON A FLATTENING THAT PRODUCED NOTHING, and this is the guard the
# `[ -r "$path" ]` it replaces could not be. A DIRECTORY is readable, so it walked
# straight past that test; `tr` then printed `tr: Is a directory`, the flattened
# text came back empty, and every pin reddened with "the file does not carry that
# sentence at all", which is a true verdict with a false diagnosis. Same red, but
# it now names the real fault, and it also catches an unreadable file and an empty
# one, neither of which the old test could see either.
check_flowed_tokens_present_in() {
  local path="$1"
  shift
  local t flat
  if [ "$#" -eq 0 ]; then
    red "  FAIL [pin] check_flowed_tokens_present_in was called for $path with an empty token list, so it would assert nothing while printing nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  if ! ban_tokens_ok "$@"; then
    red "  FAIL [pin] the $#-token pin list for $path is corrupt (a blank or whitespace-only token is a substring of every file, and one carrying a newline cannot survive into a stream the flattening has already stripped of newlines), so the one-flatten screen cannot be trusted"
    FAILED=$((FAILED + 1))
    return
  fi
  flat=$(tr -s '[:space:]' ' ' < "$path" 2>/dev/null)
  if [ -z "$flat" ]; then
    red "  FAIL [pin] $path flattened to nothing, so its $# pin(s) were never looked for; a directory is readable and flattens to exactly this, and a miss here would be a miss of nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  for t in "$@"; do
    if [[ "$flat" == *"$t"* ]]; then
      green "  ok   '$t' present in $path, with line wrapping flattened first"
    else
      red "  FAIL '$t' missing from $path even with line wrapping flattened, so the file does not carry that sentence at all"
      FAILED=$((FAILED + 1))
    fi
  done
}

# TOKEN FIRST, PATH SECOND, which is the argument order every call site of this
# function already uses and the opposite of the list form's. The list form takes
# the path first because a variadic token list has to be last, and
# check_no_tokens_in established that order on the ban side. Rather than flip
# dozens of live call sites to buy consistency nobody reads, the single-token form
# keeps its order and forwards.
check_flowed_token_present() {
  check_flowed_tokens_present_in "$2" "$1"
}

# NO PIPE INTO `grep -q`, for the reason the flowed pair above spells out and this
# function learned the hard way. `$body` is a whole template or agent file, up to
# 40KB, and a macOS pipe starts at 16KB and only grows to 64KB when the kernel can
# spare the space. Under the process load of a full validator run that growth
# sometimes does not happen, `echo` blocks mid-write, `grep -q` exits the instant
# it matches, and `echo` dies of SIGPIPE. The orchestrator runs under
# scripts/validate-dod.sh's `set -uo pipefail` line, so the pipeline hands back
# 141 rather than grep's 0 and a marker that is present reads as missing.
#
# THE FLAKE NUMBER IS A DATED ONE-TIME MEASUREMENT AND NOTHING IN THIS TREE
# RE-ESTABLISHES IT: 3 red runs in 30 on a clean tree, each naming a different
# marker, recorded by hand before this function stopped piping. That is the
# SECOND of the two batches 84-no-pipe-into-grep-q.sh records from the same
# harness on the same day, the first being 3 in 25, and the pair is named here so
# a reader meeting one number beside the other cannot read them as one
# measurement that disagrees with itself. Read either as the reason the pipe went
# away, never as a standing fact anything here re-proves. The harness was never
# committed and no CI command runs one, on the
# argument 84-no-pipe-into-grep-q.sh makes at length about its own twin claim: a
# flake rate is a SAMPLE of a race that only appears under fork pressure, so
# re-establishing it costs a hundred full validator runs and a clean hundred is
# still consistent with a true rate of 1 in 200. What a check can own is the
# property those runs were evidence FOR, that no such pipeline is in the tree, and
# [84] owns exactly that on every run. Anyone wanting the number itself drives
# `bash scripts/validate-dod.sh` in a loop and counts the non-zero exits.
#
# The fixed-string tests are substring tests, so bash's own `==` does them with no
# subprocess and no pipe to break. Every marker is newline-free, which is what
# makes whole-string matching identical to grep -F's per-line matching. The regex
# test keeps grep, on a here-string: `$ALLOWLIST` is an ERE and a here-string is
# written through a temp file, which has no writer to signal.
check_role() {
  local body="$1"
  local label="$2"
  local ok=1
  for marker in "You are " "You reject" "Bias to:" "Bias against:"; do
    if [[ "$body" != *"$marker"* ]]; then
      red "  FAIL $label missing '$marker'"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  if ! grep -qE "$ALLOWLIST" <<<"$body"; then
    red "  FAIL $label missing framework-allowlist token"
    FAILED=$((FAILED + 1)); ok=0
  fi
  [ "$ok" = "1" ] && green "  ok   $label ROLE 5-element check"
}

# ABSENCE AFTER LINE WRAPPING IS FLATTENED, the twin the presence side named and
# declined to build: "The ban side keeps the line-oriented matcher, where a missed
# hit would be a false green", quoted from the flowed presence block above,
# which records the same reversal from the other end. That trade was struck when
# the flowed matcher pinned short literals only, and it does not survive today's
# ban lists, counted rather than assumed: P5_BANS in 71-release-mechanism-pins.sh
# holds 21 tokens of which 18 carry a space, RR_BANS in 77-reviewer-roster.sh 60 of
# which 50 do, and every one is screened over wrapped markdown where a spaced token
# can straddle a break and pass. So the flattened matcher sits BESIDE the
# line-oriented one, never instead of it, and check_no_token and check_no_tokens_in
# keep their contract and every call site they have.
#
# STRICTLY MORE SENSITIVE, THE RIGHT DIRECTION HERE. Every hit grep -F finds on one
# physical line survives the join, so flattening finds more, never less; what it
# adds where two joined lines were never one phrase is a false RED, loud and
# settled in a minute, against a false GREEN silent for a sprint. Pay the loud one.
#
# NO PIPE ANYWHERE, for the reason the flowed presence pair above gives and
# check [84] enforces across scripts/: under `set -uo pipefail`, `grep -q` exits on
# its first match and the writer dies of SIGPIPE, so the pipeline reports 141
# instead of grep's 0. Every flattening lands in a variable, every match takes a
# here-string.

# One line per readable TEXT file under $1: path, TAB, then that file's content
# with every whitespace run, newlines included, collapsed to one space. FLATTENED
# PER FILE AND NOT PER PATH, which is what makes a directory safe to ban over:
# joining a tree into one blob would manufacture matches across a file boundary
# that exist in neither file. THE FILE LIST COMES FROM ONE grep, NOT find, so
# binaries drop out the way check_no_token drops them, and an empty file that falls
# out of `grep -rlI -e ''` carries no token to miss. AWK JOINS RATHER THAN ONE tr
# PER FILE: byte-identical to the `tr -s '[:space:]' ' '` that
# check_flowed_tokens_present_in still runs above, compared
# file by file over all 142 files under skills/ before this shipped, at 1 fork
# instead of 142 and differing only in the leading and trailing space, which no
# substring verdict can see. STATUS 2 WHEN NOTHING COULD BE FLATTENED, read by both
# callers as a red and never as a clean tree, the rule check_no_token states about
# grep exiting above 1; a filename carrying a newline fails closed the same way.
flowed_flatten() {
  local path="$1"
  local f n=0
  local files
  files=()
  while IFS= read -r f; do files[n]="$f"; n=$((n + 1)); done \
    < <(/usr/bin/grep -rlI -e '' -- "$path" 2>/dev/null)
  [ "$n" -gt 0 ] || return 2
  awk 'function flush() { if (f != "") { gsub(/[[:space:]]+/, " ", s); print f "\t" s } f = ""; s = "" }
       FNR == 1 { flush(); f = FILENAME }
       { s = s " " $0 }
       END { flush() }' "${files[@]}"
}

# The flattened twin of check_no_token, differing from it twice on purpose. It
# NAMES THE FILES a token turned up in rather than counting them: its sibling
# counts occurrences off `grep -o`, which a flattened stream cannot, since one
# line there is one FILE and a count off it would be neither files nor hits. And it screens the CONTENT column only,
# through awk's index() on $2, so a token that appears in a PATH cannot redden a
# file whose text is clean. THE TOKEN REACHES awk THROUGH THE ENVIRONMENT AND NOT
# THROUGH -v, which processes backslash escapes in the value it is handed and
# would screen a token carrying one as something other than itself.
check_no_flowed_token() {
  local token="$1"
  local path="$2"
  local stream hits
  if ! stream=$(flowed_flatten "$path") || [ -z "$stream" ]; then
    red "  FAIL '$token' was never screened in $path, no readable text file could be flattened; a count of 0 here would be a count of nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  hits=$(FLOWED_TOKEN="$token" awk -F'\t' \
    'BEGIN { t = tolower(ENVIRON["FLOWED_TOKEN"]) } index(tolower($2), t) { print $1 }' \
    <<<"$stream")
  if [ -z "$hits" ]; then
    green "  ok   '$token' has 0 occurrences in $path, line wrapping flattened first"
  else
    red "  FAIL '$token' is present in $path once line wrapping is flattened, in: ${hits//$'\n'/, }"
    FAILED=$((FAILED + 1))
  fi
}

# The flattened twin of check_no_tokens_in: same argument order, same fallback and
# same verdict lines, so converting a call site is an edit to the name and nothing
# else, and everything the block above that function argues holds here unchanged.
# THE SCREEN READS THE WHOLE STREAM LINE, PATH COLUMN INCLUDED, safe in the only
# direction that matters: a token matching a FILENAME drops this into the per-token
# loop, which reads the content column alone and prints every token green, a wasted
# pass and never a wrong verdict. Over-sensitivity in a screen whose only job is
# "is anything here" costs time; under-sensitivity would cost the check.
check_no_flowed_tokens_in() {
  local path="$1"
  shift
  local rc=0 t stream
  if [ "$#" -eq 0 ]; then
    red "  FAIL [ban] check_no_flowed_tokens_in was called for $path with an empty token list, so it would ban nothing while printing nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  if ! ban_tokens_ok "$@"; then
    red "  FAIL [ban] the $#-token pattern list for $path is corrupt (a token that is blank, whitespace-only, or carrying a newline would become a blank pattern line and match every line), so the batched flattened screen cannot be trusted"
    FAILED=$((FAILED + 1))
  elif ! stream=$(flowed_flatten "$path") || [ -z "$stream" ]; then
    rc=2
  else
    /usr/bin/grep -qFi -f <(printf '%s\n' "$@") <<<"$stream"
    rc=$?
  fi
  if [ "$rc" -eq 1 ]; then
    for t in "$@"; do green "  ok   '$t' has 0 occurrences in $path, line wrapping flattened first"; done
    return
  fi
  if [ "$rc" -gt 1 ]; then
    red "  FAIL [ban] the flattened screen could not read $path, so its $# token(s) were never screened"
    FAILED=$((FAILED + 1))
  fi
  for t in "$@"; do check_no_flowed_token "$t" "$path"; done
}

# HOW MANY TIMES ONE ENTRY APPEARS IN A NEWLINE-SEPARATED LIST, ANSWERED IN THE
# SHELL. Two fragments reconcile a hand-written table against a discovered set by
# asking that question once per element, and both forked a grep to ask it against a
# list already sitting in a shell variable. That is perf.process.fork-for-builtin in
# rules/performance.md, and it is the larger half of the catalog entry here because
# the loop runs the judge more than once: [88] alone forked 42 of them per validator
# run, measured with a shell function shadowing grep and counting its calls.
#
# THE COUNT AND NOT MERE MEMBERSHIP, which is why this sets a number rather than
# returning a status. Both callers red on TWO rows for one entry exactly as loudly
# as on none: a table naming a thing twice leaves two descriptions with no tie-break,
# and a token that appears twice will not redden when one of the two is broken.
#
# A GLOBAL AND NOT AN ECHO, on the argument CONTROL_DELTA makes above its own: a
# command substitution to read the answer back would fork the subshell this exists
# to remove, and a return code carries one byte where this carries a count.
#
# THE NEWLINE FENCING IS WHAT MAKES IT AN EXACT WHOLE-ENTRY MATCH, the same shape
# 80-file-size-caps.sh uses at CAP_NL, and it is what keeps one entry from matching
# another's prefix. The stripped match consumes its own trailing newline, so the loop
# puts one back before going round again; without that, two adjacent equal entries
# would be counted as one.
LIST_NL='
'
LIST_COUNT=0
count_in_list() {
  local ci_pat="$LIST_NL$1$LIST_NL" ci_rest="$LIST_NL$2$LIST_NL"
  LIST_COUNT=0
  while [ "$ci_rest" != "${ci_rest#*"$ci_pat"}" ]; do
    LIST_COUNT=$((LIST_COUNT + 1))
    ci_rest="$LIST_NL${ci_rest#*"$ci_pat"}"
  done
}

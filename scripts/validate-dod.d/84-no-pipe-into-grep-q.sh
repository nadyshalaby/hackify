# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [84] NO WRITER PIPED INTO A SHORT-CIRCUITING READER, anywhere in scripts/ or
# hooks/, nor in the shell an agent prompt ships inside a fenced block.
#
# THE DEFECT, MEASURED RATHER THAN FEARED. A pipeline whose left side is `echo`
# or `printf` and whose right side is `grep -q` is a race. `grep -q` exits the
# instant it matches, which closes the pipe while the writer is still pushing
# bytes into it; the writer takes SIGPIPE and dies with status 141. Every caller
# in this validator runs under `set -uo pipefail` (scripts/validate-dod.sh:186),
# so the pipeline hands back 141 rather than grep's 0, and the check reads any
# non-zero as "the marker is missing". A marker that is plainly present reddens.
#
# WHY IT IS LOAD-DEPENDENT, WHICH IS WHY NOBODY SEES IT IN REVIEW. A macOS pipe
# starts at 16KB and grows to 64KB when the kernel can spare the pages. A body
# under 16KB always fits in one write() and can never be signalled, so the bug
# is invisible at small sizes. A ~40KB body sits between the two: idle, the pipe
# grows and the write completes; under the fork pressure of a full validator run
# the growth sometimes does not happen, the writer blocks mid-write, and the
# early-exiting reader kills it. Measured on this repo: 3 red runs in 25 and 3
# in 30, naming a DIFFERENT marker each time, with a captured probe reading
# `bodylen=40107 rc=141 retry=1`, so the body was whole and the marker was there.
# After the eight reachable sites were converted: 0 failures in 100 runs.
#
# WHY A CHECK AND NOT A COMMENT. The shape is correct-looking, it is the obvious
# way to test a variable against a pattern, and it behaves perfectly on every
# small input anyone would write a test around. Three fragments already carry
# comments explaining the trap and it still got copied. Prose loses to a habit;
# a red does not.
#
# THE TWO SAFE FORMS, and this file does not add a third. A FIXED-STRING test
# uses bash's own `[[ "$x" == *"$lit"* ]]`, which forks nothing and has no pipe
# to break. A REGEX test stays on grep and takes its input from a here-string,
# which bash writes through a temp file, so there is no writer process left to
# signal. CONVERTING A REGEX TO `[[ =~ ]]` IS NOT ON THAT LIST and must not be
# done to satisfy this check: BSD `grep -E` reads `\s` as whitespace while bash's
# `[[ =~ ]]` reads it as a literal `s`, so the rewrite silently retires whichever
# alternation contained it and the check goes on printing green. That is a real
# trap this repo walked into, not a hypothetical.
#
# SCOPE IS scripts/ AND hooks/, PLUS THE SHELL THAT SHIPS INSIDE AN AGENT PROMPT.
# hooks/ was added in the same change that converted its seven sites, which is
# the order the previous scope note demanded: a ban widened onto code the wave
# may not touch only reddens on somebody else's file.
#
# WHY THOSE SEVEN WERE NOT LIVE DEFECTS, and the reason is not the one that gets
# guessed. It is NOT that their bodies are small. `block-ai-attribution.sh` caps
# a message body at MAX_BODY_BYTES=65536 and screens it at line 106, and the
# `$cmd` both blockers screen carries whole heredocs, so those bodies cross the
# 16KB floor comfortably and sit in exactly the size class that reddens the
# validator. What saved them is that NEITHER HOOK SETS pipefail: each opens with
# a bare `set -u`, so the pipeline reports grep's status and the writer's SIGPIPE
# never reaches the caller. That is one `set -o pipefail` away from being the
# validator's own bug, in a file that runs on every prompt the user submits, so
# they were converted rather than excepted.
yellow "[84] no line in scripts/ or hooks/, and none in an agent prompt's fenced shell, pipes an echo or printf into a short-circuiting reader"

# THE MATCHER IS ASSEMBLED FROM PIECES SO THAT THIS FILE CANNOT MATCH ITSELF, and
# that is the whole reason for the three lines instead of one. 73-implementer-rename.sh
# solves the same problem by excluding itself from its own scan, which costs it
# coverage of the one file most likely to be edited next. Split across two
# variables, neither source line carries a writer and a reader together, so this
# fragment is scanned exactly like every other and a real offending pipeline
# added here in future reddens here.
PG_WRITER='(echo|printf)'
PG_READER='\| *grep -q'
PG_RX="$PG_WRITER.*$PG_READER"

# `grep -q` as a prefix, so -qF, -qE, -qiE and `-q --` are all caught by the one
# pattern. `.*` between the halves, so an intermediate stage does not launder it:
# a writer piped through `tr` and then into a short-circuiting reader is the same
# race with one more process in it.
#
# THE WRITER SIDE IS THE TWO COMMANDS THAT ACTUALLY SHOW UP, and that is a scope
# choice rather than a claim about the kernel. `cat`, `awk`, `jq` and any other
# producer take SIGPIPE from the same early exit; none of them is piped into a
# short-circuiting reader anywhere in this tree today, and a writer list that
# names commands the repo does not use is a pattern nobody can verify by reading
# it. Add one here the day one appears, and the probe pair below keeps working
# because it drives whatever the pattern currently says.
PG_PATHS=(scripts hooks)

# The tree must actually have been read. If a path were wrong, empty, or
# unreadable the scan below would find nothing and print a confident green over
# a file set it never opened. Counted with the SAME binary over the SAME paths, so
# it is the scan's own reach being reported and not a second opinion about the
# filesystem. A floor rather than an equality: these directories grow every wave,
# and 40 against the 99 this run reports leaves room to retire plenty without an edit.
PG_FILE_FLOOR=40

# THE PATH LIST IS FLOORED SEPARATELY, because the file floor cannot see a path
# being dropped. Delete `hooks` from PG_PATHS and the scan falls from 99 files to
# 89, still far above 40, and half the ban goes quiet under a green. A count is
# the instrument that notices, and `-d` on each entry is what notices a typo:
# grep with one good path and one bad one still exits 0 the moment the good one
# matches, so its return code cannot be trusted to report the bad one.
PG_PATH_FLOOR=2
if [ "${#PG_PATHS[@]}" -lt "$PG_PATH_FLOOR" ]; then
  red "  FAIL [84] PG_PATHS names ${#PG_PATHS[@]} path(s), below the floor of $PG_PATH_FLOOR; a path has been dropped and the ban is silent over whatever it held"
  FAILED=$((FAILED + 1))
fi
for pg_p in "${PG_PATHS[@]}"; do
  [ -d "$pg_p" ] && continue
  red "  FAIL [84] PG_PATHS names '$pg_p', which is not a directory; the scan below cannot read it and would report a green it never earned"
  FAILED=$((FAILED + 1))
done

pg_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

# CODE OR COMMENT, DECIDED STRUCTURALLY AND NEVER ON WORDING. A line whose first
# non-blank character is `#` is a comment and is skipped; every other line is
# code and is scanned. Three comments in this repo deliberately quote the banned
# shape to explain why it is banned, and a ban that reds on its own documentation
# gets deleted by the next reader.
#
# WHY THIS RULE CANNOT DRIFT. It keys on shell syntax rather than on what the
# comment says, so rewording, translating or reflowing a comment cannot change
# the verdict, and there is no phrase list for a future edit to fall outside of.
# In the direction that matters it cannot be dodged at all: shell has no way to
# put executable code on a line that opens with `#`, so nothing can hide behind
# the exclusion.
#
# THE ONE FALSE POSITIVE IT ACCEPTS, stated rather than discovered later. A
# TRAILING comment on a code line is classified as code, because the line's first
# non-blank character is not `#` and no line-level rule can tell a `#` that opens
# a comment from one inside a string without parsing the shell. So an explanation
# of this ban has to sit on its own line. Measured: zero lines in scripts/ are
# affected today. The bias is deliberate and points the safe way, toward a loud
# red on prose rather than a silent green over a real pipeline.
pg_is_comment() {
  local text="$1"
  local lead=${text%%[![:space:]]*}
  case "${text#"$lead"}" in
    '#'*) return 0 ;;
  esac
  return 1
}

# THE PROBE PAIR, which is what stops this check passing while measuring nothing.
# Two synthetic lines, identical but for the leading `#`, are driven through both
# halves on every run. The matcher must recognise BOTH, which proves the pattern
# above still describes the shape it bans; the classifier must call one a comment
# and the other code, which proves the exclusion still separates them. Without
# this, a pattern edited into something that matches nothing would print a
# perfect green forever, and so would a classifier that called everything a
# comment. Both are the exact vacuous-pass shape [0b] exists to refuse one layer
# up, and neither is reachable by looking at real files, because the repo is
# clean by the time this ships.
#
# ASSEMBLED FROM A TAIL VARIABLE for the reason the matcher is: written out
# whole, the probe's own source line would be a live violation sitting in the
# scanned tree. Neither line below carries a writer and a reader together.
PG_TAIL='| grep -q x'
PG_PROBE_CODE="  if echo \"\$v\" $PG_TAIL; then"
PG_PROBE_NOTE="  # never write echo \"\$v\" $PG_TAIL here"

pg_probe_bad=0
/usr/bin/grep -qE -- "$PG_RX" <<<"$PG_PROBE_CODE" || {
  pg_fail "[84] the matcher no longer recognises a plain offending line, so the scan below would clear the whole tree without reading a violation it met"
  pg_probe_bad=1
}
/usr/bin/grep -qE -- "$PG_RX" <<<"$PG_PROBE_NOTE" || {
  pg_fail "[84] the matcher missed the commented probe, so the comment exclusion below is never exercised and its correctness is untested"
  pg_probe_bad=1
}
if ! pg_is_comment "$PG_PROBE_NOTE"; then
  pg_fail "[84] the classifier called a commented line code, so this check now reds on the three comments that document it"
  pg_probe_bad=1
fi
if pg_is_comment "$PG_PROBE_CODE"; then
  pg_fail "[84] the classifier called a code line a comment, so every real violation would be skipped and this check would pass on anything"
  pg_probe_bad=1
fi
[ "$pg_probe_bad" -eq 0 ] && green "  ok   [84] matcher and comment classifier both agree on the code/comment probe pair"

# Same binary as the scan, by absolute path, for the reason 00-helpers.sh gives
# above check_no_tokens_in: the interactive shell in this environment resolves a
# bare `grep` to a function that honours ignore files, and a ban whose matcher
# skips a file prints green over content it never read.
pg_seen=$(/usr/bin/grep -rlIE -e '' -- "${PG_PATHS[@]}" 2>/dev/null | wc -l | tr -d ' ')
pg_hits=$(/usr/bin/grep -rnIE -- "$PG_RX" "${PG_PATHS[@]}" 2>/dev/null)
pg_rc=$?

# -I SKIPS BINARIES so that Python bytecode under scripts/__pycache__ is not
# scanned as text. rc 0 is a hit, 1 is a clean tree, and 2 or more means grep
# could not run: an unreadable path, or no matcher at all. That last case is
# reported on its own and never alongside a verdict, because a screen that did
# not finish says nothing trustworthy about what it did manage to read.
pg_code=0
pg_note=0
if [ "$pg_rc" -gt 1 ]; then
  pg_fail "[84] the scan of ${PG_PATHS[*]} did not run (grep exited $pg_rc), so a clean result here would be a result about nothing"
elif [ "$pg_seen" -lt "$PG_FILE_FLOOR" ]; then
  pg_fail "[84] the scan reached only $pg_seen readable text file(s) under ${PG_PATHS[*]}, against a floor of $PG_FILE_FLOOR; the path or the matcher stopped resolving and a ban over an empty set is green forever"
else
  # path:line:text, split on the first two colons. No path under the scanned
  # directories carries a colon; one that did would land in the text field and
  # could only cost a verdict a false red, never a false green.
  while IFS= read -r pg_hit; do
    [ -n "$pg_hit" ] || continue
    pg_rest=${pg_hit#*:}
    pg_loc="${pg_hit%%:*}:${pg_rest%%:*}"
    if pg_is_comment "${pg_rest#*:}"; then
      pg_note=$((pg_note + 1))
      continue
    fi
    pg_code=$((pg_code + 1))
    pg_fail "[84] $pg_loc pipes an echo or printf into a short-circuiting reader; the reader exits on its first match and the writer dies of SIGPIPE mid-write, which pipefail reports as 141 and the caller reads as 'not found'. Use [[ \"\$x\" == *\"\$literal\"* ]] for a fixed string, or keep grep and feed it a here-string for a regex; do NOT convert the regex to [[ =~ ]]"
  done <<PG_HITS_EOF
$pg_hits
PG_HITS_EOF
  if [ "$pg_code" -eq 0 ]; then
    green "  ok   [84] no line in $pg_seen scanned file(s) under ${PG_PATHS[*]} pipes a writer into a short-circuiting reader ($pg_note documenting comment(s) matched the shape and were skipped)"
  fi
fi

# ---------------------------------------------------------------------------
# THE SECOND SURFACE: SHELL THAT SHIPS INSIDE A MARKDOWN PROMPT.
#
# WHY A .md FILE IS IN A SHELL BAN AT ALL. An agent template's VERIFICATION
# section is runnable shell that the dispatched sub-agent executes as its own
# pass/fail gate, and phase-3-implementation.md's copy is handed to EVERY Phase 3
# implementer this plugin dispatches. A banned pipeline sitting there is not one
# defect, it is a worked example every future agent copies, and the body it gets
# pasted onto next is nobody's to bound. The directory scan above cannot reach it:
# these are markdown files, and running the matcher over markdown PROSE would
# redden the several places in docs/work/ that quote the shape to explain it,
# while the `#` classifier would silently reclassify every markdown heading as a
# comment. So the fenced block is extracted first and only its shell is scanned.
#
# THE MATCHER AND THE CLASSIFIER ARE THE ONES ABOVE, deliberately. A second
# regex for the same ban is a second thing to keep in step, and the probe pair
# that proves this one still works has already run by the time we get here.
# What IS duplicated is the fence extraction, one awk line that
# 74-agent-shell-blocks.sh also carries. That is accepted rather than shared:
# 74 is sourced BEFORE this fragment, so it cannot see PG_RX, and moving the ban
# there would mean defining the matcher twice, which is the trade the wrong way
# round. One matcher, two extractions.
#
# GLOBBED RATHER THAN LISTED, which is the opposite of the choice 74 makes next
# door, and the reason is that the two checks want opposite failure modes. 74
# asks "is this specific template present and parsing", so a file dropping off
# its list is the bug. A BAN wants maximum reach, so a template added tomorrow
# must be covered without anyone remembering to list it. The glob also picked up
# phase-4-cross-package-verification.md, which carries a fenced block and is not
# on 74's list at all.
PG_MD_GLOBS=(agents/*.md skills/hackify/references/parallel-agents/*.md)
PG_FENCE_OPEN='^```bash$'
PG_FENCE_CLOSE='^```$'

# THE EXTRACTION IS ITS OWN PROBE, via this floor. The awk below is the only
# untested moving part in this half: break its fence patterns and it yields
# nothing, every file is skipped as blockless, and a ban over zero lines prints
# a perfect green. Counting the shell lines actually read is what refuses that,
# and it is a stronger floor than counting files, because a file whose block
# collapsed to one line still counts as a file. 100 against the 204 this run
# reads leaves room for a template to retire its block without an edit here.
PG_MD_LINE_FLOOR=100

pg_md_files=0
pg_md_lines=0
pg_md_code=0
pg_md_note=0
for pg_md_f in "${PG_MD_GLOBS[@]}"; do
  [ -f "$pg_md_f" ] || continue
  # Line numbers are carried out of the block so a finding cites the markdown
  # file's own line, which is the only number a reader can act on.
  pg_md_block=$(awk -v o="$PG_FENCE_OPEN" -v c="$PG_FENCE_CLOSE" \
    '$0 ~ o {inb = 1; next} $0 ~ c {inb = 0; next} inb {printf "%d:%s\n", NR, $0}' \
    "$pg_md_f" 2>/dev/null)
  [ -n "$pg_md_block" ] || continue
  pg_md_files=$((pg_md_files + 1))
  pg_md_lines=$((pg_md_lines + $(wc -l <<<"$pg_md_block")))

  # THE MATCHER RUNS ONCE PER FILE, NOT ONCE PER LINE, which is the same shape
  # the directory scan above uses and is not merely a tidiness preference: the
  # per-line form forked a grep for each of the 204 extracted lines on every
  # validator run, and this file is read 40+ times in a flake hunt.
  pg_md_hits=$(/usr/bin/grep -E -- "$PG_RX" <<<"$pg_md_block")
  [ -n "$pg_md_hits" ] || continue
  while IFS= read -r pg_md_hit; do
    [ -n "$pg_md_hit" ] || continue
    pg_md_text=${pg_md_hit#*:}
    if pg_is_comment "$pg_md_text"; then
      pg_md_note=$((pg_md_note + 1))
      continue
    fi
    pg_md_code=$((pg_md_code + 1))
    pg_fail "[84] $pg_md_f:${pg_md_hit%%:*} ships a writer piped into a short-circuiting reader inside a fenced shell block; this text is handed to a dispatched sub-agent as its own gate and is copied from by every agent that reads it. Use [[ \"\$x\" == *\"\$literal\"* ]] for a fixed string, or keep grep and feed it a here-string for a regex; do NOT convert the regex to [[ =~ ]]"
  done <<PG_MD_EOF
$pg_md_hits
PG_MD_EOF
done

if [ "$pg_md_lines" -lt "$PG_MD_LINE_FLOOR" ]; then
  pg_fail "[84] the fenced-shell scan read only $pg_md_lines line(s) across $pg_md_files file(s), against a floor of $PG_MD_LINE_FLOOR; the fence patterns stopped matching and a ban over an empty extraction is green forever"
elif [ "$pg_md_code" -eq 0 ]; then
  green "  ok   [84] no line of the $pg_md_lines fenced shell line(s) in $pg_md_files agent prompt(s) pipes a writer into a short-circuiting reader ($pg_md_note documenting comment(s) matched the shape and were skipped)"
fi

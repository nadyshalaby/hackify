# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [84] NO WRITER PIPED INTO A SHORT-CIRCUITING READER, anywhere in scripts/ or
# hooks/, nor in the shell an agent prompt ships inside a fenced block.
#
# THE DEFECT, MEASURED RATHER THAN FEARED. A pipeline whose left side is `echo`
# or `printf` and whose right side stops reading before its input ends is a race.
# `grep -q` exits the instant it matches and `head` exits at its line count,
# either of which closes the pipe while the writer is still pushing bytes into
# it; the writer takes SIGPIPE and dies with status 141. Every caller in this
# validator runs under scripts/validate-dod.sh's `set -uo pipefail` line, so
# the pipeline hands back 141 rather than grep's 0, and the check reads any
# non-zero as "the marker is missing". A marker that is plainly present reddens.
#
# WHY IT IS LOAD-DEPENDENT, WHICH IS WHY NOBODY SEES IT IN REVIEW. A macOS pipe
# starts at 16KB and grows to 64KB when the kernel can spare the pages. A body
# under 16KB always fits in one write() and can never be signalled, so the bug
# is invisible at small sizes. A ~40KB body sits between the two: idle, the pipe
# grows and the write completes; under the fork pressure of a full validator run
# the growth sometimes does not happen, the writer blocks mid-write, and the
# early-exiting reader kills it.
#
# THE FLAKE NUMBERS BELOW ARE A DATED ONE-TIME MEASUREMENT AND NOTHING IN THIS
# TREE RE-ESTABLISHES THEM. Read them as the reason the ban was written, never as
# a standing fact this check re-proves. On 2026-08-29, before the eight reachable
# sites were converted, a repeat-run harness driven by hand recorded 3 red runs in
# 25 and 3 in 30, naming a DIFFERENT marker each time, with a captured probe
# reading `bodylen=40107 rc=141 retry=1`, so the body was whole and the marker was
# there; after the conversion the same harness recorded 0 failures in 100 runs.
# The harness was never committed and no CI command runs one.
#
# THAT IS A DECISION RATHER THAN AN OMISSION, and it is worth arguing because the
# obvious repair is to commit the harness. A flake rate is a SAMPLE of a race that
# only appears under fork pressure, so re-establishing "0 in 100" costs 100 full
# validator runs, would be by a wide margin the slowest thing in the bar, and
# still would not be a proof: a clean 100 is consistent with a true rate of 1 in
# 200. What a check CAN own is the property those runs were evidence FOR, that no
# such pipeline is in the tree, and that is exactly what the scan below does on
# every run. Anyone wanting the numbers again drives `bash scripts/validate-dod.sh`
# in a loop and counts the non-zero exits. The standing control below covers the
# MATCHER and claims nothing about a flake rate.
#
# WHY A CHECK AND NOT A COMMENT. The shape is correct-looking, it is the obvious
# way to test a variable against a pattern, and it behaves perfectly on every
# small input anyone would write a test around. Three fragments already carry
# comments explaining the trap and it still got copied. Prose loses to a habit;
# a red does not.
#
# THE THREE SAFE FORMS, and the third one arrived after this file first said
# there were two. A FIXED-STRING test uses bash's own `[[ "$x" == *"$lit"* ]]`,
# which forks nothing and has no pipe to break. A REGEX test over ORDINARY
# content stays on grep and takes its input from a here-string, which bash writes
# through a temp file, so there is no writer process left to signal. A REGEX test
# over SENSITIVE content takes its input from a redirected process substitution
# instead, and there that form is REQUIRED rather than merely permitted:
#
#     grep -qE "$rx" < <(printf '%s\n' "$var")
#
# WHY THE THIRD FORM IS NOT OPTIONAL THERE, measured on this machine rather than
# reasoned about. bash 3.2.57, which `/usr/bin/env bash` resolves to on macOS,
# backs EVERY here-string with a real file, and it does not put it in the
# per-user $TMPDIR: lsof named the backing file `/private/var/tmp/sh-thd-<n>`
# with TMPDIR set, with it unset, and with it pointed at a path that does not
# exist, so the location is not redirectable by the caller. /private/var/tmp is
# mode 1777 and shared by every user on the box.
#
# THE FILE ITSELF IS NOT READABLE BY THEM, and overstating that is how this
# argument gets dismissed. bash creates it 0600 and unlinks it before the reader
# runs, so it cannot be opened by name for long and it does not survive the
# command, let alone a reboot. A directory poll across ten 200KB here-strings
# caught it linked at 0 bytes and once at the full 200001, which is the window,
# short and real. What matters is that the bytes reach a shared filesystem at
# all: screening content is not a licence to persist it, and the hooks screen
# commit bodies up to 65536 bytes and whole Bash commands with their heredocs
# inline, which routinely carry credentials. CWE-226 names that transit. A
# process substitution is a pipe, so nothing is written down anywhere.
#
# IT IS NOT A DODGE AROUND THIS BAN, it is strictly safer than the pipe this ban
# exists to stop. The writer is not a pipeline stage, so its status never reaches
# `$?` and `set -o pipefail` cannot surface its SIGPIPE. Measured with the match
# on line 1 of a 244008-byte body, five runs each: the pipe form returns 0 with
# pipefail off and 141 with it on, while this form returns 0 under both.
# `printf '%s\n'` reproduces the trailing newline `<<<` appends, so grep reads
# md5-identical bytes on every payload tried, the empty string included, and no
# matcher semantics move. The safe-form table below asserts on every run that
# this check stays off it.
#
# CONVERTING A REGEX TO `[[ =~ ]]` IS ON NO PART OF THAT LIST and must not be
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
# that is the whole reason for the four lines instead of one. 73-implementer-rename.sh
# solves the same problem by excluding itself from its own scan, which costs it
# coverage of the one file most likely to be edited next. Split across a writer
# variable and two reader clauses, no source line here carries a writer and a
# reader together, so this fragment is scanned exactly like every other and a
# real offending pipeline added here in future reddens here.
PG_WRITER='(echo|printf)'

# THE READER HALF IS A FAMILY, NOT A SPELLING, and its predecessor was one
# spelling. `\| *grep -q` recognised exactly three of the nineteen spellings the
# probe table below now drives, and missed the other sixteen ways of writing the
# same command. Two of the sixteen were live in this tree when the
# widening landed: five `| head` sites, and a `| grep -Eq` in this very
# directory, which the old pattern could not see only because the `q` was not the
# first letter of its cluster. The sharpest miss was `/usr/bin/grep -q`, the
# absolute-path form this file MANDATES further down for its own scan, so the ban
# could not see the shape its own author is told to write. A ban that a flag
# rename walks out of is a ban on a habit of typing rather than on a defect.
#
# CLAUSE ONE, GREP'S EARLY-EXIT FLAGS. The binary may carry a path (`/usr/bin/`,
# `/bin/`) or an e/f/z prefix, and the flag may sit anywhere in the argument
# list: clustered in any order (`-q`, `-qF`, `-Eq`, `-iqE`), split out (`-F -q`),
# spelled long (`--quiet`, `--silent`), or bounded by a count (`-m1`, `-m 1`,
# `--max-count=1`). `-([a-zA-Z]*[qm]|-(quiet|silent|max-count))` is that whole
# family in one token: a dash-word whose short cluster ends in `q` or `m`, or one
# of the three long forms. No other flag in grep's set ends a cluster in q or m,
# so the family cannot be widened by accident into `-c`, `-v` or `-l`, and the
# safe-form table below asserts exactly that on every run.
#
# CLAUSE TWO, head, which needs no flag at all. `head` stops at its line count
# and has no option that makes it drain, so every `| head` is this defect by
# construction, and it is the clause that found five of the six live sites. Its
# remedy is not the here-string the grep clause prescribes: three of those five
# carry a `grep` stage between the writer and the `head`, so moving the writer's
# output into a here-string just moves which process takes the signal. Swap the
# `head -N` for `awk 'NR<=N'` instead, which prints the same first N lines and
# then keeps reading to EOF, so no stage upstream of it is ever signalled.
#
# WHAT THIS DELIBERATELY DOES NOT MATCH, stated here so the greens below can be
# honest about it. `sed '1q'`, `awk '...; exit'` and the `read` builtin
# short-circuit exactly as hard. All three declare the early exit inside a
# PROGRAM rather than in an argument, and no line-level matcher can tell
# `sed -n '1p;q'` from `sed 's/q/x/'` without parsing the script; a matcher that
# guessed would red on the `sed` stage that three converted sites still end with.
# Measured on this tree against the writer half above: zero sed, awk or read
# stages sit downstream of an echo or a printf today. So this ban covers the
# readers whose short circuit is declared in their arguments, and the greens say
# that rather than claiming the whole class.
#
# THE WRITER SIDE IS STILL THE TWO COMMANDS THAT ACTUALLY SHOW UP, and that is a
# scope choice rather than a claim about the kernel. `cat`, `awk`, `jq` and any
# other producer take SIGPIPE from the same early exit; none of them is piped
# into a short-circuiting reader anywhere in this tree today, and a writer list
# that names commands the repo does not use is a pattern nobody can verify by
# reading it. Add one here the day one appears, and the probe table below keeps
# working because it drives whatever the pattern currently says.
#
# `.*` BETWEEN THE HALVES, so an intermediate stage does not launder it. A writer
# piped through `tr` and then into a short-circuiting reader is the same race
# with one more process in it, and that is not hypothetical here: three of the
# five `head` sites carry a `grep` stage in the middle, and it is that grep, not
# the writer, that takes the signal.
PG_READ_GREP='\| *([^ |]*/)?(e|f|z)?grep( +[^ |]+)* +-([a-zA-Z]*[qm]|-(quiet|silent|max-count))'
PG_READ_HEAD='\| *([^ |]*/)?head([^A-Za-z0-9_-]|$)'
PG_READER="($PG_READ_GREP|$PG_READ_HEAD)"
PG_RX="$PG_WRITER.*$PG_READER"
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

# THE PROBE TABLE, which is what stops this check passing while measuring nothing.
# Every spelling below is driven through the matcher on every run, so a pattern
# narrowed by a later edit reds HERE, naming the spelling it stopped seeing,
# instead of going quiet over the tree. Its predecessor carried ONE probe for ONE
# spelling and was therefore proof of exactly the coverage it already had: the
# five live re-spellings it missed were not absent from the probe, they were
# absent from the idea of what the probe was for. A control that only asserts the
# case you thought of is the unfalsifiable shape [0b] refuses one layer up.
#
# THE SECOND TABLE IS THE HALF THAT USUALLY GETS LEFT OUT, and it guards the
# other direction of failure. Narrowed, a matcher clears the tree quietly.
# Widened past the defect, it reds on the very conversions this check PRESCRIBES,
# and the next reader deletes the check rather than obeying it. So the safe forms
# are asserted NOT to match, `| tail` and the `| awk 'NR<=6'` the five converted
# sites now read first among them, and so are the grep flags that do not
# short-circuit, because `-c`, `-v` and `-l` sit one letter away from the family
# clause one matches.
#
# THE LAST ENTRY IS THE THIRD SAFE FORM, and it is the only row in that table
# carrying a reader the grep clause would otherwise recognise on sight. Its whole
# safety is that no pipe stands between the writer and that reader, which makes
# it the one probe that can notice the pipe requirement itself being relaxed:
# measured, changing `\| *` to `\|? *` in the grep clause slips past all nine
# rows above it and reds only on this one. Without the row, that one-character
# widening would red on every hook screening sensitive content, and the reader
# who "fixed" the red by reverting those hooks to a here-string would put the
# bytes back on a shared filesystem with the scan still green.
#
# ASSEMBLED FROM TAIL VARIABLES for the reason the matcher is: written out whole,
# a probe's own source line would be a live violation sitting in the scanned
# tree. No line below carries a writer and a reader together, and the third safe
# form takes its writer through PG_WRITER_WORD for exactly that reason: spelled
# out, its row would be the first line in this file to carry both.
PG_WRITER_WORD='printf'
PG_PROBE_TAILS=(
  '| grep -q x'
  '| grep -qF x'
  '| grep -Eq x'
  '| grep -iqE x'
  '| /usr/bin/grep -q x'
  '| /bin/grep -qF x'
  '| grep -F -q x'
  '| grep --quiet x'
  '| grep --silent x'
  '| grep -m1 x'
  '| grep -m 1 x'
  '| grep --max-count=1 x'
  '| egrep -q x'
  '| tr -d " " | grep -qE x'
  '| head'
  '| head -5'
  '| head -n 5'
  '| /usr/bin/head -5'
  '| grep -F x | head -6 | sed "s/^/ /"'
)
PG_SAFE_TAILS=(
  '| tail -6'
  "| awk 'NR<=6'"
  "| sed 's/^/ /'"
  '| grep -c x'
  '| grep -vF x'
  '| grep -l x'
  '| sort -u'
  '| tr -d " "'
  '| wc -l'
  "&& /usr/bin/grep -qE x < <(${PG_WRITER_WORD} '%s\\n' \"\$v\")"
)

# FLOORS ON BOTH TABLES, because an emptied array is a control that passes on
# nothing: a `for` over zero entries reports no failure and the green below would
# still print. Deliberately a few under the counts shipped today, so a spelling
# can be retired without an edit here while a gutted table cannot go quiet.
PG_PROBE_FLOOR=15
PG_SAFE_FLOOR=7

pg_probe_bad=0
if [ "${#PG_PROBE_TAILS[@]}" -lt "$PG_PROBE_FLOOR" ]; then
  pg_fail "[84] the probe table lists ${#PG_PROBE_TAILS[@]} banned spelling(s), below the floor of $PG_PROBE_FLOOR; spellings have been deleted and the matcher's reach is no longer measured"
  pg_probe_bad=1
fi
if [ "${#PG_SAFE_TAILS[@]}" -lt "$PG_SAFE_FLOOR" ]; then
  pg_fail "[84] the safe-form table lists ${#PG_SAFE_TAILS[@]} form(s), below the floor of $PG_SAFE_FLOOR; nothing is left proving the matcher stays off the conversions this check prescribes"
  pg_probe_bad=1
fi
for pg_t in "${PG_PROBE_TAILS[@]}"; do
  /usr/bin/grep -qE -- "$PG_RX" <<<"  if echo \"\$v\" $pg_t; then" && continue
  pg_fail "[84] the matcher no longer recognises '$pg_t', so a real pipeline written that way would clear the scan below unread"
  pg_probe_bad=1
done
for pg_t in "${PG_SAFE_TAILS[@]}"; do
  /usr/bin/grep -qE -- "$PG_RX" <<<"  if echo \"\$v\" $pg_t; then" || continue
  pg_fail "[84] the matcher now calls the SAFE form '$pg_t' a violation; a ban that reds on the conversion it prescribes gets deleted rather than obeyed"
  pg_probe_bad=1
done

# THE CLASSIFIER PROBE PAIR, unchanged in intent and now driven off the table's
# first entry. Two synthetic lines identical but for the leading `#`: the matcher
# must recognise BOTH, which proves the comment exclusion is actually exercised
# rather than merely present, and the classifier must call one a comment and the
# other code, which proves it still separates them. A classifier that called
# everything a comment would skip every real violation and print a perfect green.
PG_PROBE_CODE="  if echo \"\$v\" ${PG_PROBE_TAILS[0]}; then"
PG_PROBE_NOTE="  # never write echo \"\$v\" ${PG_PROBE_TAILS[0]} here"
/usr/bin/grep -qE -- "$PG_RX" <<<"$PG_PROBE_NOTE" || {
  pg_fail "[84] the matcher missed the commented probe, so the comment exclusion below is never exercised and its correctness is untested"
  pg_probe_bad=1
}
if ! pg_is_comment "$PG_PROBE_NOTE"; then
  pg_fail "[84] the classifier called a commented line code, so this check now reds on the comments that document it"
  pg_probe_bad=1
fi
if pg_is_comment "$PG_PROBE_CODE"; then
  pg_fail "[84] the classifier called a code line a comment, so every real violation would be skipped and this check would pass on anything"
  pg_probe_bad=1
fi
[ "$pg_probe_bad" -eq 0 ] && green "  ok   [84] the matcher recognises all ${#PG_PROBE_TAILS[@]} banned reader spelling(s), stays off all ${#PG_SAFE_TAILS[@]} prescribed safe form(s), and the classifier separates the code/comment probe pair"

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
    pg_fail "[84] $pg_loc pipes an echo or printf into a short-circuiting reader; the reader stops early and whatever is filling the pipe dies of SIGPIPE mid-write, which pipefail reports as 141 and the caller reads as 'not found'. For a grep test: use [[ \"\$x\" == *\"\$literal\"* ]] on a fixed string, or keep grep and feed it a here-string for a regex, or a redirected process substitution \`< <(printf '%s\\n' \"\$var\")\` for a regex over content worth protecting, since bash 3.2 backs a here-string with a real file under /private/var/tmp; and do NOT convert the regex to [[ =~ ]]. For a head, swap it for awk 'NR<=N', which prints the same first N lines but drains its input so nothing upstream is ever signalled"
  done <<PG_HITS_EOF
$pg_hits
PG_HITS_EOF
  if [ "$pg_code" -eq 0 ]; then
    green "  ok   [84] no code line in $pg_seen scanned file(s) under ${PG_PATHS[*]} pipes an echo or a printf into any of the ${#PG_PROBE_TAILS[@]} reader spellings the table above proves this matcher sees, which is grep's quiet and max-count family plus head; a sed or awk program that exits early is not decidable from one line and is not claimed ($pg_note documenting comment(s) matched the shape and were skipped)"
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
    pg_fail "[84] $pg_md_f:${pg_md_hit%%:*} ships a writer piped into a short-circuiting reader inside a fenced shell block; this text is handed to a dispatched sub-agent as its own gate and is copied from by every agent that reads it. For a grep test: use [[ \"\$x\" == *\"\$literal\"* ]] on a fixed string, or keep grep and feed it a here-string for a regex, or a redirected process substitution \`< <(printf '%s\\n' \"\$var\")\` for a regex over content worth protecting, since bash 3.2 backs a here-string with a real file under /private/var/tmp; and do NOT convert the regex to [[ =~ ]]. For a head, swap it for awk 'NR<=N', which drains its input"
  done <<PG_MD_EOF
$pg_md_hits
PG_MD_EOF
done

if [ "$pg_md_lines" -lt "$PG_MD_LINE_FLOOR" ]; then
  pg_fail "[84] the fenced-shell scan read only $pg_md_lines line(s) across $pg_md_files file(s), against a floor of $PG_MD_LINE_FLOOR; the fence patterns stopped matching and a ban over an empty extraction is green forever"
elif [ "$pg_md_code" -eq 0 ]; then
  green "  ok   [84] no code line of the $pg_md_lines fenced shell line(s) in $pg_md_files agent prompt(s) pipes an echo or a printf into any of the ${#PG_PROBE_TAILS[@]} reader spellings the table above proves this matcher sees, which is grep's quiet and max-count family plus head; a sed or awk program that exits early is not decidable from one line and is not claimed ($pg_md_note documenting comment(s) matched the shape and were skipped)"
fi

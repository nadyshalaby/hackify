# shellcheck shell=bash

# THE PHASE 3 IMPLEMENTER RENAME, split out of 70-invariants-and-new.sh in the
# sprint that file reached 480 lines against the 500-LOC hard cap that check
# [80] enforces. [40] came across whole and kept its check ID, the way [38c],
# [38d], [38g], [38f] and [38e] kept theirs when 71-release-mechanism-pins.sh
# was carved out of the same file. A fragment is free to move; a check ID that
# CHANGELOG.md, a work-doc or another block cites is not.
#
# THE SEAM IS RESPONSIBILITY, NOT SIZE, the same seam 71's header argues for. 70
# keeps the STRUCTURAL invariants, every one of them asking whether some piece
# of plumbing still exists and still resolves. This block asks whether ONE
# rename was applied everywhere: the live agent type present at every site that
# dispatches it, and the dead type absent from every file a reader could still
# follow. That question needs a scan of the whole tracked tree, which is why the
# block is 334 of the 480 lines it came out of.
#
# NOTHING CROSSED THE SEAM. Every WI_ variable and both wi_absent helpers are
# declared inside the block and read nowhere else, so this file needed no
# re-declaration at its head the way 71 needed one for INJECT_PY. What DID have
# to travel is the self-exclusion in WI_LIVE_PATHS below, which now names this
# file rather than 70: the block bans literals it necessarily contains, so a
# [40] that moved house while that path stayed behind would redden on its own
# text in the middle of the move. Its own comment said so before the move.
#
# scripts/test_ban_tokens.d/15-wi-absent-cases.sh sed-lifts wi_absent and
# wi_absent_all out of this file by path to exercise their fail-closed branches,
# so TB_WI_SRC there moved with them.

yellow "[40] the Phase 3 implementer rename, live name present and dead name absent"
# NOTHING IN THIS REPO USED TO GREP AN AGENT-TYPE STRING. Commit dabc333
# renamed the implementer agent and left every dispatch site naming a type that
# no longer existed. The tree stayed fully green and the release was tagged,
# because a type is resolved by the harness at DISPATCH time, long after the
# validator has had its say. So the rename is pinned from both ends: the live
# name must be present at every site that dispatches it, and the dead name must
# be absent from every file a reader could still follow.
#
# WIDER ROOTS THAN [38g]'s RETIRED_TYPES SCAN, DELIBERATELY. That block reads
# skills/, commands/ and agents/, which is where a reviewer type gets named. An
# implementer type is also named in prose that teaches the dispatch, so this one
# reads the whole tracked tree minus the paths allowed to carry the old words.
# Its roots are a strict superset, which is why the retired implementer types are
# banned here instead of being added to that regex.
#
# WHICH RENAME IS POLICED NOW. 0.17.1 merged `hackify:wave-implementer` and
# `hackify:module-implementer` into the one `hackify:implementer`, so the live
# name below is that one and BOTH merged types joined the dead list. The block's
# job did not change with them: it is still one rename pinned from both ends, and
# the 0.15.0 incident recorded above is still why it exists.

# BOTH LISTS IN THIS BLOCK ARE ARRAYS, never space-separated strings looped
# unquoted. That shape word-splits on any path carrying a space and leaves
# globbing live on every entry, so one stray character in a filename quietly
# changes which files get checked. WI_LIVE_PATHS below and WI_DEAD_WORDS at the
# foot of the block are both arrays already, so this is the shape the rest of
# [40] follows and these two were the odd pair out.
WI_TYPE_SITES=('skills/hackify/SKILL.md' 'skills/quick/SKILL.md')
WI_TYPE_SITES+=('skills/hackify/references/parallel-agents/README.md')
# FOUR MORE SITES, and they were named unpinned for a release. The three above
# are where a dispatcher is TOLD which type to use; these four TEACH the same
# dispatch, and a rename that reached the first group while missing the second
# leaves a reader following prose to a type that no longer resolves, which is
# the 0.15.0 incident this block was built for. Each was measured to carry the
# literal before it was added, rather than assumed to: 1 occurrence each in the
# three references and 4 in the spec reviewer, which names the type in its own
# wave-plan skeleton.
WI_TYPE_SITES+=('skills/hackify/references/phases/phase-3-implement.md')
WI_TYPE_SITES+=('skills/hackify/references/contention-dispatch.md')
WI_TYPE_SITES+=('skills/hackify/references/work-doc-template.md')
WI_TYPE_SITES+=('agents/spec-reviewer.md')
# The size is hand-written beside the list, the shape [77] and [80] both use: a
# bound read back out of a list cannot police that list. Drop a site from the
# array and the element count drops with it, so that site's own check leaves the
# run and the run stays green one check shorter, which is the failure this whole
# block exists to stop.
check_list_size "${#WI_TYPE_SITES[@]}" 7 "the [40] dispatch-site file set"
for f in "${WI_TYPE_SITES[@]}"; do check_token_present 'hackify:implementer' "$f"; done

# THE #11-A REPORTING HALF, ON BOTH MIRROR SIDES. [38f](2) already pins the
# STOPPING half, 'STOP there'. The half that says what to REPORT after the stop
# was unpinned, and it is the mitigation that bought one-agent-per-wave its
# wider blast radius. This sprint spent it: two implementers died mid-wave, and
# a report naming which task IDs were already on disk is what made the
# re-dispatch a handful of tasks instead of the whole wave over again.
#
# THE PARENT SIDE MOVED IN 0.17.1 and the template side did not. The merge
# rewrote `phase-3-implementation.md` in place, since there is exactly one Phase
# 3 implementation prompt again, and gave it a new mirror at
# `agents/implementer.md`. Both pinned phrases were checked in the merged text
# rather than assumed to have survived it.
WI_MIRRORS=('agents/implementer.md')
WI_MIRRORS+=('skills/hackify/references/parallel-agents/phase-3-implementation.md')
check_list_size "${#WI_MIRRORS[@]}" 2 "the [40] implementer mirror pair"
for f in "${WI_MIRRORS[@]}"; do
  check_token_present 'KEEP everything that already landed on disk' "$f"
  check_token_present 'which task IDs landed, which task IDs did not' "$f"
done

# THE EXCLUDED PATHS ARE THE ONES ALLOWED TO SAY THE OLD WORDS. dist/ is
# generated, docs/work/ is the sprint record that quotes the rename it carried
# out, CHANGELOG.md is release history that has to name what was renamed, and
# this fragment holds the very literals it bans. THE CHANGELOG ROW WAIVES A
# REAL OCCURRENCE, deliberately: 0.15.0's own release note has to quote the
# retired type verbatim, prefix and all, to describe what the rename replaced,
# and a release note that cannot name the old name cannot describe the change.
# 0.17.1's entry does the same for the two types that merged, so the row waives
# more occurrences now than when it was written and the argument is unchanged.
# This comment used to claim the row waived nothing and was pure
# future-proofing, and the release note written later in the SAME sprint
# falsified it. That is the recurring defect this fragment exists to catch, so
# it is recorded here rather than quietly corrected.
#
# THE parallel-agents README IS NOT EXCLUDED, and for one release it was. That
# row went in because line 54 of that file is the retirement note recording which
# agent types were retired in which version, and it wrote both merged types with
# their `hackify:` prefix, which is the exact form this block bans. The row was
# defended here as the narrower of two costs, weighed against rewording the note
# and deleting the record to protect the instrument guarding it. That was a false
# choice: a THIRD option was narrower than either, and this same tree already
# demonstrated it at scripts/test_ban_tokens.d/15-wi-absent-cases.sh:135, which
# writes a retired type with the `hackify:` prefix left off precisely so a file
# can name one without carrying the literal. WI_BANNED pins the prefixed forms
# only, so the unprefixed name is a legal way to write the history down.
#
# WHAT THE EXCLUSION ACTUALLY COST, measured rather than estimated. A pathspec
# exclusion is WHOLE-FILE: `git ls-files -- "${WI_LIVE_PATHS[@]}"` returned that
# README in none of its rows, so all 13 literals below were waived across the
# whole file to license the 2 that were really in it. Worse, that file is also a
# WI_TYPE_SITES presence pin above, which made it the only dispatch-teaching file
# in the tree with its presence pinned and its absence unguarded, the one
# combination the WI_BANNED comment at the foot of this block says a presence pin
# cannot cover. The note now drops the prefix, the record still says what was
# retired and when, and the file is back under the scan with nothing waived.
#
# THE SELF-EXCLUSION TRAVELS WITH THIS BLOCK, and whoever moves it next has to
# carry it again: 70 was split twice at the 500-LOC cap and this block was the
# second thing to leave, so the path below names THIS file. A [40] that moves
# house while that path stays behind would red on its own literals in the middle
# of the move. git grep reads TRACKED files, which keeps an unsynced dist/
# working tree out of the scan for free; [55] already reds on an uncommitted file
# under skills/, agents/ and hooks/, so scanning untracked paths here would buy
# no coverage and add false alarms.
#
# ':(top)' IS THE POSITIVE HALF AND IT IS NOT DECORATION. A pathspec list made
# of nothing but exclusions is one reading away from resolving to no files at
# all, and a scan over no files prints green forever. 'top' also anchors every
# entry to the repo root rather than to the caller's working directory.
WI_LIVE_PATHS=(':(top)' ':(top,exclude)dist/*' ':(top,exclude)docs/work/*')
WI_LIVE_PATHS+=(':(top,exclude)CHANGELOG.md')
WI_LIVE_PATHS+=(':(top,exclude)scripts/validate-dod.d/73-implementer-rename.sh')

# STATUS IS GIT GREP'S ALONE: a plain command substitution with no pipe inside
# it, so `pipefail` has nothing to launder. rc 0 is a hit and anything above 1
# is a scan that never ran. rc 1 DOES NOT settle the question by itself, and
# this comment used to say it did: it read rc 1 as the honest clean tree, which
# is what let the check green over a file it could not open. git grep returns 1
# for a tree with no match AND for a scan that could not stat a tracked file.
# Measured on git 2.50.1, one tracked file at mode 000 with the pathspec scoped
# to it: rc 1, empty stdout, and 'failed to stat ... Permission denied' on
# stderr, printed twice. The control, the same file at mode 644, is rc 1 with
# stderr EMPTY. So stderr is the tie-breaker rc alone cannot be, and rc 1 with
# anything on stderr is a scan that never ran and must never be the reason a
# dead phrase prints green. The failure prints file and line, because the
# actionable half of an absence check is WHERE the ghost survived.
#
# STDERR GOES TO ITS OWN FILE AND NEVER INTO `hits`. The rc > 1 branch reports a
# scan that did not run, and reporting only the number while discarding the one
# sentence that says WHY leaves the reader with the least actionable half. It is
# captured to a temp file rather than merged with `2>&1` on purpose: git grep can
# write a warning and still exit 0 or 1, and merged text would then be read as a
# matched line, turning a clean tree into a phantom hit. `rc=$?` stays the very
# next statement after the substitution, so nothing in between can overwrite the
# status this whole check rests on.
#
# THE mktemp IS CHECKED, and it is checked because the unchecked version routed
# every call in this block into the green branch. A failed mktemp leaves `err`
# empty, `2>"$err"` then dies in the shell BEFORE git runs, and bash hands back
# 1. That is a status git grep itself returns, and with no capture file there is
# no stderr for the tie-breaker above to read either, so the failure arrives
# wearing a clean tree's exact face. All four calls failed open together and
# [40] could not fail at all. The contract this now matches is the one
# 00-helpers.sh:302-307 already states for the batched screen, a scan that never
# ran must never be the reason a token prints green, and the comment above has
# said the same thing about this block since the day it was written. The red
# names the capture file rather than the exit status, so it stays tellable apart
# from the rc > 1 red underneath it. Pinned by
# scripts/test_ban_tokens.d/15-wi-absent-cases.sh section 3.
#
# THE TEMP FILE IS TRAPPED AROUND ITS OWN WINDOW, not for the life of the
# fragment. `rm -f` sits on the happy path, so a Ctrl-C between the mktemp and it
# strands the file. 80-file-size-caps.sh:326-340 solves this the same way and
# explains why a STANDING trap would be worse than none: a sourced fragment
# shares one trap table with the whole run, so an EXIT trap left armed here would
# silently replace whatever the next fragment installs. The clear is a RESTORE
# rather than a bare `trap - EXIT`, which is where this diverges from that block:
# nothing in the validator traps EXIT, but the tamper suite that now calls this
# function does, and a bare clear would delete the verdict trap that suite exits
# through.
# TWO SCANS, NOT ONE, AND THE WORKTREE GOES FIRST. git grep silently skips any
# tracked path it cannot open as a readable regular file, and it only writes to
# stderr when stat() fails with an errno other than ENOENT. So the tie-breaker
# above catches the sealed file and nothing else. Measured on git 2.50.1 with one
# tracked file holding the literal: deleted and not staged, replaced by a
# directory, and marked skip-worktree all return rc 1 with empty stdout AND empty
# stderr, which is a clean tree's exact face, while the blob in the index still
# carries the literal. The everyday trigger is a mid-rename `rm <file>` that was
# never staged: the check greens, and `git commit` without -a then ships the index
# that still has it. A --cached scan finds the literal in all three.
#
# --cached ALONE WOULD BE WORSE, which is why this is a union and not a swap. Over
# an unmerged path it returns rc 1 with empty stdout and empty stderr, the same
# fail-open face, in the exact state a half-finished rename lives in; and it
# cannot see a literal typed into the worktree and never staged, which is the
# state this validator runs in, since it runs BEFORE the commit. Each half is
# fail-closed on its own and the loop stops at the first half with anything to
# report, so the union is strictly stronger than either one. In CI the index and
# the worktree are identical, so the second scan costs one process and changes no
# verdict.
#
# THE SCAN ORDER IS LOAD-BEARING, not stylistic. Exactly one red prints per call,
# so whichever half reports first owns the message, and the sealed file is where
# the two halves disagree about which message that should be: the worktree half
# returns rc 1 with a stat error, the cached half returns a plain hit. Worktree
# first is what keeps that case reporting the file nothing could read rather than
# reporting a hit, and scripts/test_ban_tokens.d/15-wi-absent-cases.sh asserts on
# that wording.
#
# A FAIL-CLOSED BRANCH OUTRANKS A HIT REPORT, which rc > 1 already did and stderr
# on rc 1 now does too. A scan that could not finish tells the reader nothing
# trustworthy about the hits it did manage to print, so naming the broken scan is
# the more actionable of the two. Every red carries the mode that produced it, so
# the reader knows which half of the union spoke.
wi_absent() {
  local lit="$1" mode hits rc err errtxt prev
  err=$(mktemp 2>/dev/null) || err=''
  if [ -z "$err" ]; then
    red "  FAIL [40] could not create the stderr capture file, so the scan for '$lit' never ran"
    FAILED=$((FAILED + 1))
    return
  fi
  prev=$(trap -p EXIT)
  trap 'rm -f "$err"' EXIT
  for mode in worktree cached; do
    if [ "$mode" = cached ]; then
      hits=$(git grep --cached -nF -e "$lit" -- "${WI_LIVE_PATHS[@]}" 2>"$err")
    else
      hits=$(git grep -nF -e "$lit" -- "${WI_LIVE_PATHS[@]}" 2>"$err")
    fi
    rc=$?
    errtxt=$(cat "$err")
    { [ "$rc" -gt 1 ] || [ -n "$errtxt" ] || [ -n "$hits" ]; } && break
  done
  rm -f "$err"
  if [ -n "$prev" ]; then eval "$prev"; else trap - EXIT; fi
  if [ "$rc" -le 1 ] && [ -z "$errtxt" ] && [ -z "$hits" ]; then
    green "  ok   '$lit' survives in no live file"
    return
  fi
  FAILED=$((FAILED + 1))
  if [ "$rc" -gt 1 ]; then
    red "  FAIL [40] the $mode scan for '$lit' exited $rc, so finding nothing here would be finding nothing at all"
  elif [ -n "$errtxt" ]; then
    red "  FAIL [40] the $mode scan for '$lit' exited $rc but wrote to stderr, so a file it could not read is being counted as a file with nothing in it"
  else
    red "  FAIL [40] retired Phase 3 wording '$lit' survives in a live file, found by the $mode scan:"
    printf '%s\n' "$hits" | sed 's/^/         - /'
    return
  fi
  printf '%s\n' "${errtxt:-exited $rc without writing anything to stderr}" | sed 's/^/         git: /'
}

# ONE SCAN PER MODE FOR THE WHOLE WORDING SET, with the per-literal loop above
# kept as the fallback. This is the shape check_no_tokens_in already uses in
# 00-helpers.sh:270-311 and the reasoning carries over unchanged: the batched
# grep answers ONLY the yes/no question "does anything in this list survive in
# this scope", and the moment the answer is anything other than a clean no, the
# original per-literal loop re-runs and words the verdict exactly as before. No
# diagnostic detail is traded for the speed. Every red this block can print is
# still printed by wi_absent, still names WHICH literal survived, in WHICH file,
# and found by WHICH half of the union.
#
# WHAT IT COSTS AND WHAT IT SAVES, measured rather than asserted. Four literals
# times two modes was eight full walks of the 248 tracked files. Mean over 20
# iterations on this tree: 113.7ms for the eight walks, 29.6ms for the two. The
# saving is the walks, not the forks: at one pattern against four patterns a
# single walk measures flat, so batching the PATTERNS into one walk is the whole
# of it. That is why rules/performance.md's spawn-per-item row applies here and
# why the fork-price exemption in perf-scout.md does not.
#
# THE SCREEN IS FAIL-CLOSED TOWARD THE SLOW PATH, never toward a green. Only rc
# 1 with empty stderr, from BOTH modes, is read as clean. A hit, a scan that
# exited above 1, a scan that wrote to stderr, and an mktemp that could not
# produce a capture file all fall through to the loop, which then reaches its own
# verdict with its own capture file. So the screen can cost a repeat of the scan
# but it cannot be the reason a dead phrase prints green, which is the contract
# the whole of [40] rests on.
#
# -q RATHER THAN -n, and it is checked rather than assumed: measured on git
# 2.50.1, a sealed tracked file returns rc 1 with the stat error on stderr under
# -qF exactly as it does under -nF, 106 bytes either way. So the stderr
# tie-breaker the union depends on survives the quiet flag, and the screen never
# has to materialise output it would only discard.
#
# The trap is saved and restored around its own window for the reason wi_absent
# states above, and the restore happens BEFORE the fallback loop so wi_absent's
# own save-and-restore nests inside a table this function has already put back.
wi_absent_all() {
  local mode rc err errtxt prev lit
  local -a pats=()
  if [ "$#" -eq 0 ]; then
    red "  FAIL [40] the batched screen was handed an empty wording list, so it would ban nothing while printing nothing"
    FAILED=$((FAILED + 1))
    return
  fi
  for lit in "$@"; do pats+=(-e "$lit"); done
  err=$(mktemp 2>/dev/null) || err=''
  if [ -n "$err" ]; then
    prev=$(trap -p EXIT)
    trap 'rm -f "$err"' EXIT
    for mode in worktree cached; do
      if [ "$mode" = cached ]; then
        git grep --cached -qF "${pats[@]}" -- "${WI_LIVE_PATHS[@]}" 2>"$err"
      else
        git grep -qF "${pats[@]}" -- "${WI_LIVE_PATHS[@]}" 2>"$err"
      fi
      rc=$?
      errtxt=$(cat "$err")
      { [ "$rc" -ne 1 ] || [ -n "$errtxt" ]; } && break
    done
    rm -f "$err"
    if [ -n "$prev" ]; then eval "$prev"; else trap - EXIT; fi
    if [ "$rc" -eq 1 ] && [ -z "$errtxt" ]; then
      for lit in "$@"; do green "  ok   '$lit' survives in no live file"; done
      return
    fi
  fi
  for lit in "$@"; do wi_absent "$lit"; done
}

# The retired batching vocabulary. One implementer now takes a whole wave, so a
# file still telling the orchestrator to cap or group batches sends it back to
# the per-task fan-out the wave plan replaced. THE BARE WORD 'batch' IS NOT
# BANNED, on purpose: a batched wizard questionnaire and a flat batch of
# parallel subagents are a different sense of the word and both still ship.
# These three phrases only ever carried the retired one.
WI_DEAD_WORDS=('Cap a batch at 3 tasks' 'per task BATCH' 'Group by module, never by count')
check_list_size "${#WI_DEAD_WORDS[@]}" 3 "the [40] retired Phase 3 vocabulary list"

# THE RETIRED DISPATCH INPUT NAMES. A separate list from the batching phrases
# above, because each hand-written size bound should police a list whose meaning
# does not shift under it. Both are class C5, retired vocabulary surviving in a
# live file; that list polices a replaced fan-out, this one polices INPUT names
# a dispatcher builds a call out of. CHANGELOG.md:19 retires `{{assigned_lens}}`
# as an input and records the refuter row naming `finding_verbatim` where the
# template's real name is `findings_batch`. A stale INPUT name is the sharpest
# shape here: an agent asked to fill a placeholder nothing declares receives
# literal text, the dispatch bug [93] resolves from the other end.
#
# WHY THIS CLASS NEEDS NO ALLOWLIST, which is the line dividing it from the
# section-name class. Everything here must be absent from every live file with
# no exception, so it rides the existing absent scan unchanged. Vocabulary some
# file keeps DELIBERATELY, the way six back-compat sites keep the retired
# work-doc section labels, cannot be banned outright and belongs to a different
# instrument; putting it here would red on text that is correct on purpose.
#
# Measured before feeding, under the pathspec the scan uses: every entry returns
# git grep rc 1 with empty stdout AND empty stderr, the clean tree's face rather
# than a scan that could not run. rc alone would not have settled it.
#
# THE FIVE 0.17.1 ENTRIES ARE THE INPUTS THE MERGE COLLAPSED. `folder_allowlist`
# folded into `file_allowlist`, `gate_commands` split back into the three scoped
# commands, `module_plan_path` folded into `work_doc_path` plus
# `task_descriptions`, `module_id` became `track_id`, and `framing` became
# `sibling_tracks`. Each one is a name a dispatcher could still build a call out
# of, which is precisely the shape this list polices.
#
# ONE OF THE FIVE IS PINNED WITH ITS BRACES AND THE OTHER FOUR ARE NOT, and the
# asymmetry is deliberate rather than sloppy. The bare form is the stricter pin,
# because it also catches the name written into an INPUTS list without
# placeholder syntax, and four of these names are coinages that appear nowhere in
# ordinary prose. `framing` is an ordinary English word: measured under the
# pathspec the scan uses, it survives in 10 live lines that have nothing to do
# with a dispatch input, from a work-doc frontmatter description to a wizard
# contract. Banning it bare would red on correct text and the fix would be to
# delete the ban, so the placeholder form is pinned instead. That is the narrower
# claim this list can honestly make about that name, and `{{framing}}` is what a
# stale dispatch actually carries.
WI_DEAD_INPUTS=('assigned_lens' 'finding_verbatim' 'module_id' 'module_plan_path')
WI_DEAD_INPUTS+=('folder_allowlist' 'gate_commands' '{{framing}}')
check_list_size "${#WI_DEAD_INPUTS[@]}" 7 "the [40] retired dispatch INPUT name list"

# THE DEAD TYPES ARE BANNED, not merely left unpinned. A presence pin alone
# cannot see a stale dispatch site sitting beside a corrected one, and one
# corrected site beside one stale site is exactly the shape a half-applied rename
# leaves. They ride in the same screen as the wording list rather than in a call
# of their own, because the screen batches its patterns into one walk and three
# type literals cost it nothing over one.
#
# THREE TYPES NOW, NOT ONE. `hackify:wave-task-implementer` died in 0.15.0;
# 0.17.1 merged `hackify:wave-implementer` and `hackify:module-implementer` into
# the live `hackify:implementer` above and both joined this list. A type is
# resolved at DISPATCH time, so a saved dispatch naming either of them fails long
# after the validator has had its say, which is the whole reason the dead half of
# this check exists.
#
# The size is hand-written beside the list, for the reason WI_TYPE_SITES gives
# above: drop a literal and the element count drops with it, so the literal
# leaves the run and the run stays green one check shorter. It is written as 13
# rather than as an expression over WI_DEAD_WORDS and WI_DEAD_INPUTS, because a
# bound derived from the lists it polices cannot police those lists. It moves
# when a list gains or loses an entry, and moving it is the deliberate act that
# records the change.
WI_BANNED=('hackify:wave-task-implementer' 'hackify:wave-implementer')
WI_BANNED+=('hackify:module-implementer')
WI_BANNED+=("${WI_DEAD_WORDS[@]}" "${WI_DEAD_INPUTS[@]}")
check_list_size "${#WI_BANNED[@]}" 13 "the [40] banned-wording set"

# THE SCOPE ITSELF IS FLOORED, which the WI_LIVE_PATHS comment above argues for and
# nothing until now measured. Measured, not feared: `git grep -qF -e hackify --
# ':(top)' ':(top,exclude)*'` returns rc 1 with empty stderr, this block's clean-tree
# face exactly, so a scope resolving to no file clears every literal green having read
# nothing. Status is git ls-files' alone, no pipe inside the substitution for pipefail
# to launder and rc read next, the contract wi_absent states above; no stderr capture,
# because git ls-files has no ambiguous rc 1 to break a tie on and its own message is
# left to print rather than swallowed. A floor and not an exact count, at roughly half
# of what the tree measured when it was written, since live files come and go.
WI_SCOPE_FLOOR=120
wi_scope_out=$(git ls-files -- "${WI_LIVE_PATHS[@]}")
wi_scope_rc=$?
wi_scope_n=0
while IFS= read -r wi_scope_f; do
  [ -n "$wi_scope_f" ] || continue
  wi_scope_n=$((wi_scope_n + 1))
done <<WI_SCOPE_EOF
$wi_scope_out
WI_SCOPE_EOF
if [ "$wi_scope_rc" -ne 0 ] || [ "$wi_scope_n" -lt "$WI_SCOPE_FLOOR" ]; then
  red "  FAIL [40] WI_LIVE_PATHS resolved to $wi_scope_n live file(s) at rc $wi_scope_rc, against a floor of $WI_SCOPE_FLOOR; the scope collapsed rather than the tree shrinking, so the ban scan below would have cleared all ${#WI_BANNED[@]} literals against no file at all"
  FAILED=$((FAILED + 1))
else
  wi_absent_all "${WI_BANNED[@]}"
fi

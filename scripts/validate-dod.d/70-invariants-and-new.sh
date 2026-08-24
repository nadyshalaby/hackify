# shellcheck shell=bash

# STRUCTURAL INVARIANTS. Every block here asks the same question: does the
# plumbing this plugin is wired through still exist and still resolve. A file
# that was deleted stays deleted, a skill file carries the frontmatter its
# loader reads, every hook command target is a real path on disk, the always-on
# rules reach the model, the performance review surfaces are registered.
#
# The release-mechanism pins that used to live at the foot of this file, [38c],
# [38d], [38g], [38f] and [38e], moved to 71-release-mechanism-pins.sh when this
# file hit exactly 500 LOC. They ask a different question (did a shipped
# saving's guard rail drift out) and they kept their check IDs on the way, so a
# CHANGELOG entry or a work-doc citing [38g] still points at a live block.

yellow "[33] smart-router reference fully removed (router-excision invariant)"
if [ -f "skills/hackify/references/smart-router.md" ]; then
  red "  FAIL skills/hackify/references/smart-router.md still exists (should be deleted in v0.2.2)"
  FAILED=$((FAILED + 1))
else
  green "  ok   skills/hackify/references/smart-router.md deleted"
fi
for f in "skills/hackify/SKILL.md" "skills/quick/SKILL.md"; do
  if grep -qF '(/skills/hackify/references/smart-router.md)' "$f"; then
    red "  FAIL $f still links to deleted smart-router.md"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f has no link to smart-router.md"
  fi
done

yellow "[34] skills/yolo/SKILL.md exists with name + description frontmatter and required body tokens"
check_file "skills/yolo/SKILL.md"
if [ -f "skills/yolo/SKILL.md" ]; then
  if grep -q "^name: yolo$" "skills/yolo/SKILL.md"; then
    green "  ok   skills/yolo/SKILL.md has name: yolo"
  else
    red "  FAIL skills/yolo/SKILL.md missing 'name: yolo' frontmatter"
    FAILED=$((FAILED + 1))
  fi
  if echo "yolo" | grep -Eq '^[a-z0-9-]{1,64}$'; then
    green "  ok   skills/yolo/SKILL.md slug 'yolo' matches regex ^[a-z0-9-]{1,64}\$"
  else
    red "  FAIL skills/yolo/SKILL.md slug 'yolo' fails slug regex"
    FAILED=$((FAILED + 1))
  fi
  if grep -q "^description:" "skills/yolo/SKILL.md"; then
    green "  ok   skills/yolo/SKILL.md has description: frontmatter"
  else
    red "  FAIL skills/yolo/SKILL.md missing 'description:' frontmatter"
    FAILED=$((FAILED + 1))
  fi
  check_token_present "Phase 1" "skills/yolo/SKILL.md"
  check_token_present "Phase 2.5" "skills/yolo/SKILL.md"
  check_token_present "Phase 3" "skills/yolo/SKILL.md"
  check_token_present "Phase 4" "skills/yolo/SKILL.md"
  check_token_present "Phase 5" "skills/yolo/SKILL.md"
  check_token_present "Phase 6" "skills/yolo/SKILL.md"
  check_token_present "in-chat plan" "skills/yolo/SKILL.md"
  check_token_present "auto-pass" "skills/yolo/SKILL.md"
  check_token_present "commit to current branch locally" "skills/yolo/SKILL.md"
  check_token_present "no work-doc" "skills/yolo/SKILL.md"
fi

yellow "[37] hooks/hooks.json command targets exist on disk (.sh targets executable)"
# Every ${CLAUDE_PLUGIN_ROOT}/-prefixed token in every hook command, the
# script AND its file arguments, across ALL event arrays (UserPromptSubmit,
# PreToolUse, and any added later), must resolve to a file in this repo.
# Tokens are shell-quoted inside the JSON string (so install paths with
# spaces survive word-splitting), so strip one leading/trailing quote
# before the prefix match. Iteration is a while-read over the
# newline-separated list, no unquoted word-splitting (bash 3.2 safe).
# jq path: .hooks.<event>[] (matcher groups) → .hooks[] (entries) → .command.
HOOK_TARGETS=$(jq -r '.hooks[][].hooks[].command' hooks/hooks.json 2>/dev/null \
  | tr ' ' '\n' | sed -e "s/^['\"]//" -e "s/['\"]\$//" \
  | sed -n 's|^\${CLAUDE_PLUGIN_ROOT}/||p' | sort -u)
if [ -z "$HOOK_TARGETS" ]; then
  red "  FAIL no \${CLAUDE_PLUGIN_ROOT}/ paths parsed from hooks/hooks.json (malformed JSON or empty hook arrays)"
  FAILED=$((FAILED + 1))
fi
while IFS= read -r t; do
  [ -n "$t" ] || continue
  if [ -f "$t" ]; then
    green "  ok   hooks.json target $t exists"
  else
    red "  FAIL hooks.json target $t missing on disk"
    FAILED=$((FAILED + 1))
  fi
  case "$t" in
    *.sh)
      if [ -x "$t" ]; then
        green "  ok   hooks.json target $t is executable"
      else
        red "  FAIL hooks.json target $t is not executable"
        FAILED=$((FAILED + 1))
      fi
      ;;
  esac
done <<<"$HOOK_TARGETS"

yellow "[38] all four always-on rules files are injected via UserPromptSubmit"
# Here-string, not `jq | grep -q`: grep -q short-circuits and can SIGPIPE the
# producer under pipefail (see the [24] comment in 50-runtimes-and-companions.sh).
# All four entries are checked, not just one: v0.14.0 made phase discipline
# always-on, and an entry dropped from hooks.json is that whole law gone silently.
UPS_HOOK_CMDS=$(jq -r '.hooks.UserPromptSubmit[].hooks[].command' hooks/hooks.json 2>/dev/null)
for r in hard-caps expert-mindset perf-guardrails phase-discipline; do
  if grep -qF "rules/$r.md" <<<"$UPS_HOOK_CMDS"; then
    green "  ok   hooks.json UserPromptSubmit injects rules/$r.md"
  else
    red "  FAIL hooks.json UserPromptSubmit does not inject rules/$r.md"
    FAILED=$((FAILED + 1))
  fi
done
# inject-context.sh's header enumerates the always-on files BY NAME and ships to
# dist/claude-code/; the carve-out is 33 chars against QUALIFIER_MAX_CHARS = 34 and
# qualifier() drops rather than truncates, so a reword deletes it after prompt one.
check_token_present 'rules/phase-discipline.md' "hooks/inject-context.sh"
check_token_present 'unless it is trivial or read-only' "rules/phase-discipline.md"

yellow "[38b] the always-on injector is session-aware, not per-prompt"
# v0.11.0. additionalContext persists in the transcript, so re-injecting the
# same rules text every prompt cost ~64k tokens over a long session and bought
# nothing. The injector now sends the full text on the first prompt, a pointer
# after, and a full refresh every Nth prompt. Two ways this rots: the companion
# disappears (silently reverting to per-prompt injection via the jq degrade
# path), or a failure path starts emitting NOTHING instead of the full text.
INJECT_PY="hooks/inject_context.py"
check_file "$INJECT_PY"
for tok in 'session_id' 'is_refresh_turn' 'pointer_text'; do
  check_token_present "$tok" "$INJECT_PY"
done
check_token_present "inject_context.py" "hooks/inject-context.sh"
# The degrade contract: no session identity, unreadable state, or unparseable
# stdin must fall back to the FULL body, never to an empty injection.
if grep -qF 'return body' "$INJECT_PY"; then
  green "  ok   $INJECT_PY degrades to the full rules body"
else
  red "  FAIL $INJECT_PY has no full-body degrade path (a failure would drop the law)"
  FAILED=$((FAILED + 1))
fi
check_file "hooks/test_inject_context.sh"

yellow "[39] performance review surfaces registered (Reviewer D agent + perf-scout wiring)"
check_file "agents/code-reviewer-performance.md"
check_token_present "perf-scout.md" "skills/hackify/SKILL.md"

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
# Its roots are a strict superset, which is why the retired implementer type is
# banned here instead of being added to that regex.

# BOTH LISTS IN THIS BLOCK ARE ARRAYS, never space-separated strings looped
# unquoted. That shape word-splits on any path carrying a space and leaves
# globbing live on every entry, so one stray character in a filename quietly
# changes which files get checked. WI_LIVE_PATHS below and WI_DEAD_WORDS at the
# foot of the block are both arrays already, so this is the shape the rest of
# [40] follows and these two were the odd pair out.
WI_TYPE_SITES=('skills/hackify/SKILL.md' 'skills/quick/SKILL.md' 'skills/yolo/SKILL.md')
WI_TYPE_SITES+=('skills/hackify/references/parallel-agents/README.md')
# The size is hand-written beside the list, the shape [77] and [80] both use: a
# bound read back out of a list cannot police that list. Drop a site from the
# array and the element count drops with it, so that site's own check leaves the
# run and the run stays green one check shorter, which is the failure this whole
# block exists to stop.
check_list_size "${#WI_TYPE_SITES[@]}" 4 "the [40] dispatch-site file set"
for f in "${WI_TYPE_SITES[@]}"; do check_token_present 'hackify:wave-implementer' "$f"; done

# THE #11-A REPORTING HALF, ON BOTH MIRROR SIDES. [38f](2) already pins the
# STOPPING half, 'STOP there'. The half that says what to REPORT after the stop
# was unpinned, and it is the mitigation that bought one-agent-per-wave its
# wider blast radius. This sprint spent it: two implementers died mid-wave, and
# a report naming which task IDs were already on disk is what made the
# re-dispatch a handful of tasks instead of the whole wave over again.
WI_MIRRORS=('agents/wave-implementer.md')
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
# This comment used to claim the row waived nothing and was pure
# future-proofing, and the release note written later in the SAME sprint
# falsified it. That is the recurring defect this fragment exists to catch, so
# it is recorded here rather than quietly corrected. THE SELF-EXCLUSION TRAVELS
# WITH THIS BLOCK, and whoever splits this fragment next has to carry it: 70 was
# split once already at the 500-LOC cap, and a [40] that moves house while that
# path stays behind would red on its own literals in the middle of the move.
# git grep reads TRACKED files,
# which keeps an unsynced dist/ working tree out of the scan for free; [55]
# already reds on an uncommitted file under skills/, agents/ and hooks/, so
# scanning untracked paths here would buy no coverage and add false alarms.
#
# ':(top)' IS THE POSITIVE HALF AND IT IS NOT DECORATION. A pathspec list made
# of nothing but exclusions is one reading away from resolving to no files at
# all, and a scan over no files prints green forever. 'top' also anchors every
# entry to the repo root rather than to the caller's working directory.
WI_LIVE_PATHS=(':(top)' ':(top,exclude)dist/*' ':(top,exclude)docs/work/*')
WI_LIVE_PATHS+=(':(top,exclude)CHANGELOG.md')
WI_LIVE_PATHS+=(':(top,exclude)scripts/validate-dod.d/70-invariants-and-new.sh')

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
# Measured before feeding, under the pathspec the scan uses: both return git
# grep rc 1 with empty stdout AND empty stderr, the clean tree's face rather
# than a scan that could not run. rc alone would not have settled it.
WI_DEAD_INPUTS=('assigned_lens' 'finding_verbatim')
check_list_size "${#WI_DEAD_INPUTS[@]}" 2 "the [40] retired dispatch INPUT name list"

# THE DEAD TYPE IS BANNED, not merely left unpinned. A presence pin alone cannot
# see a stale dispatch site sitting beside a corrected one, and one corrected
# site beside one stale site is exactly the shape a half-applied rename leaves.
# It rides in the same screen as the wording list rather than in a call of its
# own, because a screen over one literal is just the scan it was meant to save.
#
# The size is hand-written beside the list, for the reason WI_TYPE_SITES gives
# above: drop a literal and the element count drops with it, so the literal
# leaves the run and the run stays green one check shorter. It is written as 6
# rather than as an expression over WI_DEAD_WORDS and WI_DEAD_INPUTS, because a
# bound derived from the lists it polices cannot police those lists. It moves
# when a list gains or loses an entry, and moving it is the deliberate act that
# records the change.
WI_BANNED=('hackify:wave-task-implementer' "${WI_DEAD_WORDS[@]}" "${WI_DEAD_INPUTS[@]}")
check_list_size "${#WI_BANNED[@]}" 6 "the [40] banned-wording set"

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

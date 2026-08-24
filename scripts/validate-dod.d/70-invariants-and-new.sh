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
# scripts/test_ban_tokens.d/10-ban-list-cases.sh section 3.
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
wi_absent() {
  local lit="$1" hits rc err errtxt prev
  err=$(mktemp 2>/dev/null) || err=''
  if [ -z "$err" ]; then
    red "  FAIL [40] could not create the stderr capture file, so the scan for '$lit' never ran"
    FAILED=$((FAILED + 1))
    return
  fi
  prev=$(trap -p EXIT)
  trap 'rm -f "$err"' EXIT
  hits=$(git grep -nF -e "$lit" -- "${WI_LIVE_PATHS[@]}" 2>"$err")
  rc=$?
  errtxt=$(cat "$err")
  rm -f "$err"
  trap - EXIT
  [ -n "$prev" ] && eval "$prev"
  if [ "$rc" -gt 1 ]; then
    red "  FAIL [40] git grep exited $rc scanning for '$lit', so finding nothing here would be finding nothing at all"
    if [ -n "$errtxt" ]; then
      printf '%s\n' "$errtxt" | sed 's/^/         git: /'
    else
      printf '%s\n' "         git: exited $rc without writing anything to stderr"
    fi
    FAILED=$((FAILED + 1))
    return
  fi
  if [ "$rc" -eq 1 ] && [ -n "$errtxt" ]; then
    red "  FAIL [40] git grep exited 1 scanning for '$lit' but wrote to stderr, so a file it could not read is being counted as a file with nothing in it"
    printf '%s\n' "$errtxt" | sed 's/^/         git: /'
    FAILED=$((FAILED + 1))
    return
  fi
  if [ -z "$hits" ]; then
    green "  ok   '$lit' survives in no live file"
    return
  fi
  red "  FAIL [40] retired Phase 3 wording '$lit' survives in a live file:"
  printf '%s\n' "$hits" | sed 's/^/         - /'
  FAILED=$((FAILED + 1))
}

# The dead type is BANNED, not merely left unpinned. A presence pin alone cannot
# see a stale dispatch site sitting beside a corrected one, and one corrected
# site beside one stale site is exactly the shape a half-applied rename leaves.
wi_absent 'hackify:wave-task-implementer'

# The retired batching vocabulary. One implementer now takes a whole wave, so a
# file still telling the orchestrator to cap or group batches sends it back to
# the per-task fan-out the wave plan replaced. THE BARE WORD 'batch' IS NOT
# BANNED, on purpose: a batched wizard questionnaire and a flat batch of
# parallel subagents are a different sense of the word and both still ship.
# These three phrases only ever carried the retired one.
WI_DEAD_WORDS=('Cap a batch at 3 tasks' 'per task BATCH' 'Group by module, never by count')
check_list_size "${#WI_DEAD_WORDS[@]}" 3 "the [40] retired Phase 3 vocabulary list"
for dead in "${WI_DEAD_WORDS[@]}"; do wi_absent "$dead"; done

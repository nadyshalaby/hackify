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
#
# [40] LEFT THE SAME WAY, the second time this file came up against the cap. It
# is now in 73-implementer-rename.sh, still under its own ID, and it asks a
# third question again: was one rename applied at every site, the live agent
# type present and the dead one gone from the whole tracked tree. It was 334 of
# this file's 480 lines on its own, and it took every WI_ variable and both
# wi_absent helpers with it, because nothing here ever read them.

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

yellow "[34] the plugin ships exactly two build modes, hackify and quick, and yolo stays deleted"
# 0.17.0 retired yolo and folded contention-first dispatch into full hackify, so
# this block was REWRITTEN rather than repointed at a new file. It used to assert
# that skills/yolo/SKILL.md existed and carried four body tokens: 'in-chat plan',
# 'auto-pass', 'commit to current branch locally' and 'no work-doc'. All four are
# FALSE of gated hackify, which keeps a work-doc on disk, waits at its Phase 2
# gate, and does not commit to the current branch without asking. Carrying those
# tokens across to a new subject would have forced a choice between a red and a
# lie, which is why the subject moved and the tokens did not come with it.
#
# What is worth pinning now is the MODE SET itself. Two skills are build modes,
# each carries the frontmatter its loader reads, and the third one stays gone. A
# revert that restored skills/yolo/ would otherwise put a third build mode back
# on disk, and the collision scan stops listing a slug the moment it leaves
# HACKIFY_SLUGS, so nothing else in CI would say a word about it.
for mode_slug in hackify quick; do
  mode_file="skills/$mode_slug/SKILL.md"
  check_file "$mode_file"
  [ -f "$mode_file" ] || continue
  if grep -q "^name: $mode_slug\$" "$mode_file"; then
    green "  ok   $mode_file has name: $mode_slug"
  else
    red "  FAIL $mode_file missing 'name: $mode_slug' frontmatter"
    FAILED=$((FAILED + 1))
  fi
  # Read the slug OUT OF THE FILE. The predecessor tested the loop variable,
  # a literal typed two lines above, against the slug regex: a tautology that
  # printed a green nobody could ever turn red. What the loader actually reads
  # is the frontmatter value, so that is the string worth validating.
  mode_declared="$(awk -F': ' '/^name: /{print $2; exit}' "$mode_file")"
  if printf '%s' "$mode_declared" | grep -Eq '^[a-z0-9-]{1,64}$'; then
    green "  ok   $mode_file declares slug '$mode_declared', which matches ^[a-z0-9-]{1,64}\$"
  else
    red "  FAIL $mode_file declares slug '$mode_declared', which fails the slug regex the loader requires"
    FAILED=$((FAILED + 1))
  fi
  if grep -q "^description:" "$mode_file"; then
    green "  ok   $mode_file has description: frontmatter"
  else
    red "  FAIL $mode_file missing 'description:' frontmatter"
    FAILED=$((FAILED + 1))
  fi
done
if [ -e "skills/yolo" ]; then
  red "  FAIL skills/yolo/ is back on disk; 0.17.0 retired it and the plugin ships two build modes"
  FAILED=$((FAILED + 1))
else
  green "  ok   skills/yolo/ stays deleted, so the build-mode set is exactly hackify + quick"
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

yellow "[38] all five always-on rules files are injected via UserPromptSubmit"
# Here-string, not `jq | grep -q`: grep -q short-circuits and can SIGPIPE the
# producer under pipefail (see the [24] comment in 50-runtimes-and-companions.sh).
# All five entries are checked, not just one: v0.14.0 made phase discipline
# always-on and claim integrity joined as the fifth, and an entry dropped from
# hooks.json is that whole law gone silently.
UPS_HOOK_CMDS=$(jq -r '.hooks.UserPromptSubmit[].hooks[].command' hooks/hooks.json 2>/dev/null)
for r in hard-caps expert-mindset perf-guardrails phase-discipline claim-integrity; do
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
check_token_present 'rules/claim-integrity.md' "hooks/inject-context.sh"
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

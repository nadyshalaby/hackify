# shellcheck shell=bash

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
# Every ${CLAUDE_PLUGIN_ROOT}/-prefixed token in every hook command — the
# script AND its file arguments, across ALL event arrays (UserPromptSubmit,
# PreToolUse, and any added later) — must resolve to a file in this repo.
# Tokens are shell-quoted inside the JSON string (so install paths with
# spaces survive word-splitting), so strip one leading/trailing quote
# before the prefix match. Iteration is a while-read over the
# newline-separated list — no unquoted word-splitting (bash 3.2 safe).
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

yellow "[38] rules/perf-guardrails.md injected via UserPromptSubmit"
# Here-string, not `jq | grep -q`: grep -q short-circuits and can SIGPIPE the
# producer under pipefail (see the [24] comment in 50-runtimes-and-companions.sh).
UPS_HOOK_CMDS=$(jq -r '.hooks.UserPromptSubmit[].hooks[].command' hooks/hooks.json 2>/dev/null)
if grep -qF 'rules/perf-guardrails.md' <<<"$UPS_HOOK_CMDS"; then
  green "  ok   hooks.json UserPromptSubmit injects rules/perf-guardrails.md"
else
  red "  FAIL hooks.json UserPromptSubmit does not inject rules/perf-guardrails.md"
  FAILED=$((FAILED + 1))
fi

yellow "[39] performance review surfaces registered (Reviewer D agent + perf-scout wiring)"
check_file "agents/code-reviewer-performance.md"
check_token_present "perf-scout.md" "skills/hackify/SKILL.md"

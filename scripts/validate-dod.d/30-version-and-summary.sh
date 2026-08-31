# shellcheck shell=bash

yellow "[16] version consistency (plugin.json .version == marketplace.json .plugins[0].version)"
PLUGIN_VER=$(jq -r '.version' .claude-plugin/plugin.json 2>/dev/null)
MARKET_VER=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json 2>/dev/null)
if [ -n "$PLUGIN_VER" ] && [ "$PLUGIN_VER" = "$MARKET_VER" ]; then
  green "  ok   plugin.json and marketplace.json plugin version both '$PLUGIN_VER'"
else
  red "  FAIL plugin version mismatch: plugin.json='$PLUGIN_VER' vs marketplace.json='$MARKET_VER'"
  FAILED=$((FAILED + 1))
fi

yellow "[16b] README version badge matches plugin.json .version"
# The shields.io badge is unstructured prose jq cannot reach, so it silently
# drifted (badge stayed at 0.3.3 through the entire 0.4.0 release). Grep it.
BADGE_VER=$(grep -oE 'badge/version-[0-9]+\.[0-9]+\.[0-9]+' README.md | head -1 | sed 's#badge/version-##')
if [ -n "$BADGE_VER" ] && [ "$BADGE_VER" = "$PLUGIN_VER" ]; then
  green "  ok   README version badge and plugin.json both '$PLUGIN_VER'"
else
  red "  FAIL README badge version '$BADGE_VER' != plugin.json '$PLUGIN_VER' (update the shields.io badge in README.md)"
  FAILED=$((FAILED + 1))
fi

yellow "[17] SKILL.md cross-refs to the two contracts"
if grep -qF 'Template Contract' skills/hackify/SKILL.md; then
  green "  ok   SKILL.md references 'Template Contract'"
else
  red "  FAIL SKILL.md missing 'Template Contract' cross-reference"
  FAILED=$((FAILED + 1))
fi
if grep -qF 'Wizard Contract' skills/hackify/SKILL.md; then
  green "  ok   SKILL.md references 'Wizard Contract'"
else
  red "  FAIL SKILL.md missing 'Wizard Contract' cross-reference"
  FAILED=$((FAILED + 1))
fi

# === v0.1.4. Summary command + Quick mode skill ===

SUMMARY_CMD="commands/summary.md"
QUICK_SKILL="skills/quick/SKILL.md"
FINISH_REF="skills/hackify/references/finish.md"

yellow "[18] commands/summary.md exists + frontmatter + update-log field tokens"
if [ -f "$SUMMARY_CMD" ]; then
  green "  ok   $SUMMARY_CMD exists"
  if head -10 "$SUMMARY_CMD" | grep -qE '^description:'; then
    green "  ok   $SUMMARY_CMD has description: frontmatter"
  else
    red "  FAIL $SUMMARY_CMD missing description: frontmatter"
    FAILED=$((FAILED + 1))
  fi
  for tok in 'Problem' 'Root cause' 'Solution' 'Verification evidence' 'Deployment status'; do
    if grep -qF "$tok" "$SUMMARY_CMD"; then
      green "  ok   $SUMMARY_CMD body contains '$tok'"
    else
      red "  FAIL $SUMMARY_CMD body missing '$tok'"
      FAILED=$((FAILED + 1))
    fi
  done
else
  red "  FAIL $SUMMARY_CMD missing"
  FAILED=$((FAILED + 1))
fi

yellow "[19] SKILL.md Phase 6 mentions the update log + /hackify:summary"
phase6_body=$(awk '/^## Phase 6/{flag=1; next} flag && /^## /{flag=0} flag' skills/hackify/SKILL.md)
# `[[ == ]]` and not a pipe into `grep -q`, per check [84]. 'Update log' is
# newline-free, so whole-string and per-line matching agree on every input.
if [[ "$phase6_body" == *'Update log'* ]]; then
  green "  ok   SKILL.md Phase 6 contains 'Update log'"
else
  red "  FAIL SKILL.md Phase 6 missing 'Update log'"
  FAILED=$((FAILED + 1))
fi
if grep -qF '/hackify:summary' skills/hackify/SKILL.md; then
  green "  ok   SKILL.md references '/hackify:summary'"
else
  red "  FAIL SKILL.md missing '/hackify:summary' reference"
  FAILED=$((FAILED + 1))
fi

yellow "[20] finish.md update-log authoring subsection (5 fields + the ---- separator)"
# The five field headings are the format contract; a missing one silently
# drops a section the user asked for (root cause and evidence most often).
for tok in '**Problem**' '**Root cause**' '**Solution**' '**Verification evidence**' '**Deployment status**'; do
  if grep -qF -- "$tok" "$FINISH_REF"; then
    green "  ok   $FINISH_REF documents the '$tok' field"
  else
    red "  FAIL $FINISH_REF missing the '$tok' update-log field"
    FAILED=$((FAILED + 1))
  fi
done
if grep -qE '^----$' "$FINISH_REF"; then
  green "  ok   $FINISH_REF shows the '----' block separator"
else
  red "  FAIL $FINISH_REF missing the '----' block separator"
  FAILED=$((FAILED + 1))
fi


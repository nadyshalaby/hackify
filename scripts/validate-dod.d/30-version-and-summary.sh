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

# === v0.1.4 — Summary command + Quick mode skill ===

SUMMARY_CMD="commands/summary.md"
QUICK_SKILL="skills/quick/SKILL.md"
FINISH_REF="skills/hackify/references/finish.md"

yellow "[18] commands/summary.md exists + frontmatter + Area/Change tokens"
if [ -f "$SUMMARY_CMD" ]; then
  green "  ok   $SUMMARY_CMD exists"
  if head -10 "$SUMMARY_CMD" | grep -qE '^description:'; then
    green "  ok   $SUMMARY_CMD has description: frontmatter"
  else
    red "  FAIL $SUMMARY_CMD missing description: frontmatter"
    FAILED=$((FAILED + 1))
  fi
  for tok in 'Area' 'Change'; do
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

yellow "[19] SKILL.md Phase 6 mentions Summary table + /hackify:summary"
phase6_body=$(awk '/^## Phase 6/{flag=1; next} flag && /^## /{flag=0} flag' skills/hackify/SKILL.md)
if echo "$phase6_body" | grep -qF 'Summary table'; then
  green "  ok   SKILL.md Phase 6 contains 'Summary table'"
else
  red "  FAIL SKILL.md Phase 6 missing 'Summary table'"
  FAILED=$((FAILED + 1))
fi
if grep -qF '/hackify:summary' skills/hackify/SKILL.md; then
  green "  ok   SKILL.md references '/hackify:summary'"
else
  red "  FAIL SKILL.md missing '/hackify:summary' reference"
  FAILED=$((FAILED + 1))
fi

yellow "[20] finish.md Summary-table authoring subsection"
if grep -qF 'Summary table' "$FINISH_REF"; then
  green "  ok   $FINISH_REF contains 'Summary table'"
else
  red "  FAIL $FINISH_REF missing 'Summary table' subsection"
  FAILED=$((FAILED + 1))
fi
if grep -qF '| Area |' "$FINISH_REF"; then
  green "  ok   $FINISH_REF contains '| Area |' worked-example header"
else
  red "  FAIL $FINISH_REF missing '| Area |' worked-example header"
  FAILED=$((FAILED + 1))
fi


# shellcheck shell=bash

yellow "[21] skills/quick/SKILL.md exists + name regex + description"
if [ -f "$QUICK_SKILL" ]; then
  green "  ok   $QUICK_SKILL exists"
  if head -10 "$QUICK_SKILL" | grep -qE '^name: [a-z0-9-]{1,64}$'; then
    green "  ok   $QUICK_SKILL has valid name: (regex ^[a-z0-9-]{1,64}$)"
  else
    red "  FAIL $QUICK_SKILL name: field missing or fails regex"
    FAILED=$((FAILED + 1))
  fi
  if head -10 "$QUICK_SKILL" | grep -qE '^description:'; then
    green "  ok   $QUICK_SKILL has description: frontmatter"
  else
    red "  FAIL $QUICK_SKILL missing description: frontmatter"
    FAILED=$((FAILED + 1))
  fi
else
  red "  FAIL $QUICK_SKILL missing"
  FAILED=$((FAILED + 1))
fi

yellow "[22] quick SKILL.md lists the 4 skipped phases"
if grep -qF 'Skipped phases' "$QUICK_SKILL" 2>/dev/null; then
  green "  ok   $QUICK_SKILL contains 'Skipped phases'"
else
  red "  FAIL $QUICK_SKILL missing 'Skipped phases'"
  FAILED=$((FAILED + 1))
fi
for tok in 'Phase 2' 'Phase 2.5' 'Phase 5' 'four-options'; do
  if grep -qF "$tok" "$QUICK_SKILL" 2>/dev/null; then
    green "  ok   $QUICK_SKILL contains '$tok'"
  else
    red "  FAIL $QUICK_SKILL missing '$tok'"
    FAILED=$((FAILED + 1))
  fi
done

yellow "[23] quick SKILL.md documents mandatory Summary table"
if grep -qF 'Summary table' "$QUICK_SKILL" 2>/dev/null; then
  green "  ok   $QUICK_SKILL contains 'Summary table'"
else
  red "  FAIL $QUICK_SKILL missing 'Summary table'"
  FAILED=$((FAILED + 1))
fi

yellow "[35] skills/quick/SKILL.md Phase 1 contains the exploration nudge sentence"
check_token_present "read it end-to-end before judging ambiguity" "skills/quick/SKILL.md"

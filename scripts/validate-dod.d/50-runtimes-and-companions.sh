# shellcheck shell=bash

yellow "[24] sync-runtimes.sh --dry-run covers all 7 runtime targets"
DRY_OUT=$(bash scripts/sync-runtimes.sh --dry-run 2>/dev/null | grep '\[dry-run\] WOULD WRITE: dist/')
DRY_COUNT=$(printf '%s\n' "$DRY_OUT" | grep -c '\[dry-run\] WOULD WRITE: dist/')
if [ "$DRY_COUNT" -ge 7 ]; then
  green "  ok   sync-runtimes --dry-run produced $DRY_COUNT WOULD WRITE lines (>= 7)"
else
  red "  FAIL sync-runtimes --dry-run produced only $DRY_COUNT WOULD WRITE lines (expected >= 7)"
  FAILED=$((FAILED + 1))
fi
for target in 'dist/claude-code/' 'dist/codex-cli/' 'dist/codex-app/' 'dist/gemini-cli/' 'dist/opencode/' 'dist/cursor/' 'dist/copilot-cli/'; do
  if printf '%s\n' "$DRY_OUT" | grep -qF -- "$target"; then
    green "  ok   sync-runtimes --dry-run includes $target"
  else
    red "  FAIL sync-runtimes --dry-run missing $target"
    FAILED=$((FAILED + 1))
  fi
done

yellow "[25] v0.2.0 new skill SKILL.md presence + frontmatter + name regex"
NEW_SKILL_FILES="skills/brainstorm/SKILL.md skills/writing-skills/SKILL.md skills/receiving-code-review/SKILL.md"
NEW_SKILL_SLUGS="brainstorm writing-skills receiving-code-review"
# Bash 3.2-safe parallel iteration via positional split
set -- $NEW_SKILL_FILES
NEW_FILES_LIST="$*"
set -- $NEW_SKILL_SLUGS
NEW_SLUGS_LIST="$*"
i=1
for f in $NEW_FILES_LIST; do
  slug=$(echo "$NEW_SLUGS_LIST" | awk -v n="$i" '{print $n}')
  check_file "$f"
  if [ -f "$f" ]; then
    if head -10 "$f" | grep -qE "^name: ${slug}\$"; then
      green "  ok   $f has name: $slug"
    else
      red "  FAIL $f missing name: $slug"
      FAILED=$((FAILED + 1))
    fi
    if [ -n "$slug" ] && echo "$slug" | grep -qE '^[a-z0-9-]{1,64}$'; then
      green "  ok   $f slug '$slug' matches regex ^[a-z0-9-]{1,64}\$"
    else
      red "  FAIL $f slug '$slug' fails regex ^[a-z0-9-]{1,64}\$"
      FAILED=$((FAILED + 1))
    fi
    if head -10 "$f" | grep -qE '^description:'; then
      green "  ok   $f has description: frontmatter"
    else
      red "  FAIL $f missing description: frontmatter"
      FAILED=$((FAILED + 1))
    fi
  fi
  i=$((i + 1))
done

yellow "[26] sprint vocabulary in references/work-doc-template.md"
WDT_FILE="skills/hackify/references/work-doc-template.md"
SPRINT_HEADINGS_NUM="## 3. Acceptance Criteria|## 5. Sprint Backlog|## 6. Daily Updates|## 7. Sprint Review|## 8. Retrospective"
SPRINT_HEADINGS_BARE="## Acceptance Criteria|## Sprint Backlog|## Daily Updates|## Sprint Review|## Retrospective"
old_ifs="$IFS"
IFS='|'
set -- $SPRINT_HEADINGS_NUM
nums="$@"
set -- $SPRINT_HEADINGS_BARE
bares="$@"
IFS="$old_ifs"
# Iterate by index via awk on a delimited string (Bash 3.2-safe).
idx=1
while [ "$idx" -le 5 ]; do
  num_h=$(printf '%s' "$SPRINT_HEADINGS_NUM" | awk -F'|' -v i="$idx" '{print $i}')
  bare_h=$(printf '%s' "$SPRINT_HEADINGS_BARE" | awk -F'|' -v i="$idx" '{print $i}')
  if grep -qF "$num_h" "$WDT_FILE"; then
    green "  ok   $WDT_FILE contains '$num_h'"
  elif grep -qF "$bare_h" "$WDT_FILE"; then
    green "  ok   $WDT_FILE contains '$bare_h' (fallback, unnumbered)"
  else
    red "  FAIL $WDT_FILE missing '$num_h' (and unnumbered fallback)"
    FAILED=$((FAILED + 1))
  fi
  idx=$((idx + 1))
done

yellow "[28] pause-keyword list in hackify/SKILL.md (scoped to Pause-checkpoint section)"
HACKIFY_SKILL="skills/hackify/SKILL.md"
# Extract just the body of the `### Pause checkpoint (mid-wave exit)` section
# (between that heading and the next ## or ### heading), so common English
# words like `stop`/`exit` are only counted as keywords if they appear inside
# the pause-checkpoint block.
PAUSE_BODY=$(awk '/^### Pause checkpoint \(mid-wave exit\)/ {flag=1; next} flag && /^(##|### )/ {flag=0} flag' "$HACKIFY_SKILL")
if printf '%s\n' "$PAUSE_BODY" | grep -qF 'pause-keyword list'; then
  green "  ok   $HACKIFY_SKILL Pause-checkpoint section contains 'pause-keyword list' phrase"
else
  red "  FAIL $HACKIFY_SKILL Pause-checkpoint section missing 'pause-keyword list' phrase"
  FAILED=$((FAILED + 1))
fi
for kw in 'pause' 'stop' 'exit' 'later' 'tomorrow' 'come back' 'pick this up later'; do
  if printf '%s\n' "$PAUSE_BODY" | grep -qF -- "$kw"; then
    green "  ok   Pause-checkpoint section contains pause-keyword '$kw'"
  else
    red "  FAIL Pause-checkpoint section missing pause-keyword '$kw'"
    FAILED=$((FAILED + 1))
  fi
done

# === v0.2.2 — plugin primitives (rules/, agents/, hooks/) ===


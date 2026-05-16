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

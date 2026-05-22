# shellcheck shell=bash

# [90] Skill-slug collision scan (soft warning).
# Invokes scripts/check-collisions.sh against any installed Claude Code
# plugins under ~/.claude/plugins/. Substring overlaps with hackify's
# slugs are reported as warnings — NEVER fail the build, because a
# hostile sibling plugin must not be able to break our CI.

yellow "[90] Sibling-plugin slug collision scan (soft warning, never fails)"

if [ ! -x scripts/check-collisions.sh ]; then
  red "  FAIL scripts/check-collisions.sh missing or not executable"
  FAILED=$((FAILED + 1))
else
  collision_output=$(bash scripts/check-collisions.sh 2>&1 || true)
  if printf '%s\n' "$collision_output" | grep -qE 'EXACT MATCH|SUBSTRING OVERLAP'; then
    yellow "  WARN sibling-plugin collisions detected (non-fatal):"
    printf '%s\n' "$collision_output" | grep -E 'WARN|EXACT MATCH|SUBSTRING OVERLAP' | sed 's/^/  /'
  else
    green "  ok   no sibling-plugin collisions"
  fi
fi

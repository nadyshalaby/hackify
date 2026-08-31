# shellcheck shell=bash

# [90] Skill-slug collision scan (soft warning).
# Invokes scripts/check-collisions.sh against any installed Claude Code
# plugins under ~/.claude/plugins/. Substring overlaps with hackify's
# slugs are reported as warnings. NEVER fail the build, because a
# hostile sibling plugin must not be able to break our CI.

yellow "[90] Sibling-plugin slug collision scan (soft warning, never fails)"

if [ ! -x scripts/check-collisions.sh ]; then
  red "  FAIL scripts/check-collisions.sh missing or not executable"
  FAILED=$((FAILED + 1))
else
  collision_output=$(bash scripts/check-collisions.sh 2>&1 || true)
  # A HERE-STRING AND NOT A PIPE, per check [84]. This one stays on grep rather
  # than moving to `[[ == ]]`: the pattern is an ERE alternation, and rewriting a
  # regex as a shell pattern is how an alternation gets silently retired. The
  # `grep -E` on the next line keeps its pipe on purpose, it has no -q, so it
  # drains its input and there is no early reader to close the pipe.
  if grep -qE 'EXACT MATCH|SUBSTRING OVERLAP' <<<"$collision_output"; then
    yellow "  WARN sibling-plugin collisions detected (non-fatal):"
    printf '%s\n' "$collision_output" | grep -E 'WARN|EXACT MATCH|SUBSTRING OVERLAP' | sed 's/^/  /'
  else
    green "  ok   no sibling-plugin collisions"
  fi
fi

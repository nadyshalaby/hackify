#!/usr/bin/env bash
# Scan installed Claude Code plugins for skill-slug collisions against hackify.
#
# Reports per-hackify-slug status: EXACT MATCH (same name), SUBSTRING OVERLAP
# (one is contained in the other), or OK (no conflict).
#
# Always exits 0 — soft warning only. A hostile sibling plugin should never
# break our CI.

set -uo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/lib/colors.sh"

HACKIFY_SLUGS=(hackify quick yolo groom skillsmith review-triage codewalk)
PLUGINS_ROOT="${CLAUDE_PLUGINS_ROOT:-$HOME/.claude/plugins}"

# --- empty-state handling ---------------------------------------------------
if [ ! -d "$PLUGINS_ROOT" ]; then
  yellow "INFO: $PLUGINS_ROOT does not exist — no installed plugins to scan."
  exit 0
fi

CACHE_ROOT="$PLUGINS_ROOT/cache"
if [ ! -d "$CACHE_ROOT" ] || [ -z "$(find "$CACHE_ROOT" -mindepth 1 -maxdepth 1 -type d -print -quit 2>/dev/null)" ]; then
  yellow "INFO: $CACHE_ROOT is empty — no installed plugins to scan."
  exit 0
fi

# --- collect every sibling SKILL.md name field ------------------------------
SIBLING_NAMES_FILE="$(mktemp)"
trap 'rm -f "$SIBLING_NAMES_FILE"' EXIT

skill_files_found=0
while IFS= read -r -d '' skill_file; do
  # Skip hackify's own skills under the cached hackify plugin tree.
  case "$skill_file" in
    *"/hackify/"*"/skills/"*) continue ;;
  esac
  skill_files_found=$((skill_files_found + 1))
  name="$(grep -E '^name:[[:space:]]*' "$skill_file" 2>/dev/null | head -1 | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]*$//')"
  if [ -n "$name" ]; then
    printf '%s\t%s\n' "$name" "$skill_file" >> "$SIBLING_NAMES_FILE"
  fi
done < <(find "$CACHE_ROOT" -type f -name 'SKILL.md' -print0 2>/dev/null)

if [ "$skill_files_found" -eq 0 ]; then
  yellow "INFO: $CACHE_ROOT contains plugin dirs but no SKILL.md files were found."
  exit 0
fi

malformed=$((skill_files_found - $(wc -l < "$SIBLING_NAMES_FILE" | tr -d ' ')))
if [ "$malformed" -gt 0 ]; then
  yellow "INFO: $malformed SKILL.md file(s) had no 'name:' frontmatter and were skipped."
fi

# --- compare each hackify slug against every sibling name -------------------
cyan "Collision scan: ${#HACKIFY_SLUGS[@]} hackify slugs vs $(wc -l < "$SIBLING_NAMES_FILE" | tr -d ' ') sibling skill(s)"
echo

exact_count=0
overlap_count=0
ok_count=0

for slug in "${HACKIFY_SLUGS[@]}"; do
  matches=""
  while IFS=$'\t' read -r sibling_name sibling_path; do
    if [ "$slug" = "$sibling_name" ]; then
      matches="${matches}    EXACT MATCH: $sibling_name (at $sibling_path)\n"
      exact_count=$((exact_count + 1))
    elif printf '%s' "$sibling_name" | grep -qF "$slug" || printf '%s' "$slug" | grep -qF "$sibling_name"; then
      matches="${matches}    SUBSTRING OVERLAP: $sibling_name (at $sibling_path)\n"
      overlap_count=$((overlap_count + 1))
    fi
  done < "$SIBLING_NAMES_FILE"

  if [ -z "$matches" ]; then
    green "  OK $slug — no collisions"
    ok_count=$((ok_count + 1))
  else
    yellow "  WARN $slug:"
    printf '%b' "$matches"
  fi
done

echo
cyan "Summary: $ok_count OK | $overlap_count substring overlap(s) | $exact_count exact match(es)"
exit 0

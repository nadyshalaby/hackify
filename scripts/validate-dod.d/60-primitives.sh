# shellcheck shell=bash

yellow "[29] rules/ directory exists with hard-caps.md + code-quality.md (non-empty)"
for f in "rules/hard-caps.md" "rules/code-quality.md"; do
  if [ ! -f "$f" ]; then
    red "  FAIL $f missing"
    FAILED=$((FAILED + 1))
  elif [ ! -s "$f" ]; then
    red "  FAIL $f empty"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f exists and non-empty"
  fi
done

yellow "[30] agents/ directory contains the 7 hackify v0.2.2 agent definitions"
AGENTS_EXPECTED=(
  "spec-reviewer-consistency"
  "spec-reviewer-rules"
  "spec-reviewer-dependencies"
  "code-reviewer-security"
  "code-reviewer-quality"
  "code-reviewer-plan-consistency"
  "wave-task-implementer"
)
for name in "${AGENTS_EXPECTED[@]}"; do
  f="agents/${name}.md"
  if [ ! -f "$f" ]; then
    red "  FAIL $f missing"
    FAILED=$((FAILED + 1))
    continue
  fi
  if ! head -5 "$f" | grep -qF "name: $name"; then
    red "  FAIL $f frontmatter 'name:' does not match '$name'"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $f present with matching frontmatter name"
  fi
done
agent_count=$(find agents -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$agent_count" -ne 7 ]; then
  red "  FAIL agents/ contains $agent_count *.md files; expected 7"
  FAILED=$((FAILED + 1))
else
  green "  ok   agents/ contains exactly 7 *.md files"
fi

yellow "[31] hooks/hooks.json is valid JSON and declares UserPromptSubmit"
HOOKS_JSON="hooks/hooks.json"
if [ ! -f "$HOOKS_JSON" ]; then
  red "  FAIL $HOOKS_JSON missing"
  FAILED=$((FAILED + 1))
else
  if python3 -m json.tool "$HOOKS_JSON" >/dev/null 2>&1; then
    green "  ok   $HOOKS_JSON parses as JSON"
  else
    red "  FAIL $HOOKS_JSON is not valid JSON"
    FAILED=$((FAILED + 1))
  fi
  if grep -qF '"UserPromptSubmit"' "$HOOKS_JSON"; then
    green "  ok   $HOOKS_JSON declares UserPromptSubmit"
  else
    red "  FAIL $HOOKS_JSON missing UserPromptSubmit event"
    FAILED=$((FAILED + 1))
  fi
fi

yellow "[32] hooks/inject-hard-caps.sh exists and is executable"
HOOK_SH="hooks/inject-hard-caps.sh"
if [ ! -f "$HOOK_SH" ]; then
  red "  FAIL $HOOK_SH missing"
  FAILED=$((FAILED + 1))
elif [ ! -x "$HOOK_SH" ]; then
  red "  FAIL $HOOK_SH not executable (chmod +x)"
  FAILED=$((FAILED + 1))
else
  green "  ok   $HOOK_SH exists and is executable"
fi

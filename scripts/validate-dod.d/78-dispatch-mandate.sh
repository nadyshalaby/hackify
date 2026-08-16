# shellcheck shell=bash

# [78] The dispatch mandate, v0.9.3.
#
# WHY THIS EXISTS: two separate prose-only contracts both failed silently.
#
#   (a) Parallel dispatch was described as "the default, not the exception"
#       while the skill simultaneously carved out "one-line typo fixes
#       (overhead exceeds value)" and told quick mode to "write inline for
#       1-3-line single-file edits". Nothing forbade the parent from simply
#       editing files itself, so the cheapest reading always won.
#
#   (b) The orchestration defaults claimed the `ultracode` keyword was "in
#       scope for the turn" and that `/loop` was the iteration driver. A skill
#       cannot put a user-typed keyword in scope, and describing a slash
#       command is not invoking one, so neither ever fired in practice. The
#       fix replaced both with things a model can actually DO: call the
#       Workflow tool, invoke the `loop` skill.
#
# Prose that nothing checks is prose that drifts back. These checks pin the
# law's presence, the carve-outs' absence, and the two actuation verbs.

yellow "[78] dispatch mandate, no parent-authored diffs + actionable orchestration"

MAIN_SKILL="skills/hackify/SKILL.md"
QUICK_SKILL="skills/quick/SKILL.md"
YOLO_SKILL="skills/yolo/SKILL.md"
ORCH_REF="skills/hackify/references/orchestration.md"

# [78a] The law itself, stated where each mode's reader will hit it.
check_token_present "The parent never authors a diff" "$MAIN_SKILL"
check_token_present "no-parent-authored-diff" "$QUICK_SKILL"
check_token_present "no-parent-authored-diff" "$YOLO_SKILL"

# [78b] The law binds the three phases that change code, not just Phase 3.
for ref in \
  "skills/hackify/references/review-and-verify.md" \
  "skills/hackify/references/finish.md" \
  "skills/hackify/references/debug-when-stuck.md"; do
  check_token_present "no-parent-authored-diff" "$ref"
done

# [78c] The carve-outs that made the law optional must stay deleted. These are
# the exact strings that shipped through 0.9.2; a re-introduction is drift.
for pair in \
  "one-line typo fixes (overhead exceeds value)|$MAIN_SKILL" \
  "or write inline for 1-3-line single-file edits|$QUICK_SKILL"; do
  tok="${pair%%|*}"
  path="${pair##*|}"
  if grep -qF -- "$tok" "$path" 2>/dev/null; then
    red "  FAIL $path re-introduced the dispatch carve-out '$tok'"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $path carries no '$tok' carve-out"
  fi
done

# [78d] The single permitted exception is the runtime with no subagent
# primitive, and it must degrade the machinery rather than the discipline.
check_token_present "only carve-out to the no-parent-authored-diff law" "$MAIN_SKILL"

# [78e] Orchestration must name the tool call, not the mood. "ultracode is in
# scope" was the fiction; "call the Workflow tool" is the instruction.
check_token_present "Call the Workflow tool" "$ORCH_REF"
check_token_present "invoke the \`loop\` skill" "$ORCH_REF"
check_token_present "invokes the \`loop\` skill" "$MAIN_SKILL"

# [78f] The Workflow tool refuses to run without an explicit opt-in, and a
# model that cannot find one falls back to a flat batch. The skill must state
# that invoking hackify IS the opt-in, or the ceiling is unreachable.
check_token_present "opt-in is satisfied here" "$ORCH_REF"

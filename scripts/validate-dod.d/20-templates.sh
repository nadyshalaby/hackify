# shellcheck shell=bash

yellow "[7] README line bounds"
check_line_range "README.md" 250 450

yellow "[8] SKILL.md frontmatter"
if head -10 skills/hackify/SKILL.md | grep -q '^name: hackify' && \
   head -10 skills/hackify/SKILL.md | grep -q '^description:'; then
  green "  ok   SKILL.md has name + description frontmatter"
else
  red "  FAIL SKILL.md missing required frontmatter (name, description)"
  FAILED=$((FAILED + 1))
fi

# === Template Contract conformance (added v0.1.3) ===
PA_FILE="skills/hackify/references/parallel-agents.md"
RAV_FILE="skills/hackify/references/review-and-verify.md"
CQ_FILE="skills/hackify/references/clarify-questions.md"

ALL_TEMPLATES=(
  "### Phase 1 — Research"
  "### Phase 2.5 — Spec-review A (internal consistency)"
  "### Phase 2.5 — Spec-review B (architectural / cross-cutting risks)"
  "### Phase 2.5 — Spec-review C (dependency / ordering / parallelism)"
  "### Phase 3 — Implementation wave"
  "### Phase 3b — Debug evidence gathering"
  "### Phase 4 — Cross-package verification"
  "### Phase 5 — Multi-reviewer A (security & correctness)"
  "### Phase 5 — Multi-reviewer B (quality & layering)"
  "### Phase 5 — Multi-reviewer C (plan consistency & scope)"
  "### Phase 5 — Code-review escalation"
)
REVIEW_TEMPLATES=(
  "### Phase 2.5 — Spec-review A (internal consistency)"
  "### Phase 2.5 — Spec-review B (architectural / cross-cutting risks)"
  "### Phase 2.5 — Spec-review C (dependency / ordering / parallelism)"
  "### Phase 5 — Multi-reviewer A (security & correctness)"
  "### Phase 5 — Multi-reviewer B (quality & layering)"
  "### Phase 5 — Multi-reviewer C (plan consistency & scope)"
  "### Phase 5 — Code-review escalation"
)
BUILD_TEMPLATES=(
  "### Phase 1 — Research"
  "### Phase 3 — Implementation wave"
  "### Phase 3b — Debug evidence gathering"
  "### Phase 4 — Cross-package verification"
)
WIZARD_BANKS=(
  "## Universal preamble"
  "## Type: \`feature\`"
  "## Type: \`fix\`"
  "## Type: \`refactor\`"
  "## Type: \`revamp\` or \`redesign\`"
  "## Type: \`debug\`"
  "## Type: \`research\`"
)
CANONICAL_SEVERITY='If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important.'
ALLOWLIST='OWASP|SANS|NIST|RFC|WCAG|ARIA|Clean Code|SOLID|12-Factor|Conventional Commits|Semantic Versioning|Keep a Changelog|ISO 8601|Postel|expand-then-contract'

yellow "[9] template structural conformance (parallel-agents.md)"
for h in "${ALL_TEMPLATES[@]}"; do
  body=$(section_body "$h" "$PA_FILE")
  ok=1
  for req in "**ROLE**" "**INPUTS**" "**OBJECTIVE**" "**METHOD**" "**VERIFICATION**" "**OUTPUT**"; do
    if ! echo "$body" | grep -qF "$req"; then
      red "  FAIL $h missing $req"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  [ "$ok" = "1" ] && green "  ok   $h conforms (ROLE/INPUTS/OBJECTIVE/METHOD/VERIFICATION/OUTPUT)"
done

yellow "[10] SEVERITY conditional (review templates have it; build/research don't)"
for h in "${REVIEW_TEMPLATES[@]}"; do
  body=$(section_body "$h" "$PA_FILE")
  if echo "$body" | grep -qF "**SEVERITY**"; then
    green "  ok   $h has SEVERITY (review template)"
  else
    red "  FAIL $h is review-type but missing SEVERITY"
    FAILED=$((FAILED + 1))
  fi
done
for h in "${BUILD_TEMPLATES[@]}"; do
  body=$(section_body "$h" "$PA_FILE")
  if echo "$body" | grep -qF "**SEVERITY**"; then
    red "  FAIL $h is build/research but has SEVERITY (should be omitted)"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $h correctly omits SEVERITY"
  fi
done
# Also the escalation reviewer in review-and-verify.md
for req in "**ROLE**" "**INPUTS**" "**OBJECTIVE**" "**METHOD**" "**VERIFICATION**" "**SEVERITY**" "**OUTPUT**"; do
  if grep -qF "$req" "$RAV_FILE"; then
    green "  ok   review-and-verify.md has $req"
  else
    red "  FAIL review-and-verify.md missing $req"
    FAILED=$((FAILED + 1))
  fi
done

yellow "[11] canonical SEVERITY phrase in every review template"
for h in "${REVIEW_TEMPLATES[@]}"; do
  body=$(section_body "$h" "$PA_FILE")
  if echo "$body" | grep -qF -- "$CANONICAL_SEVERITY"; then
    green "  ok   $h has canonical SEVERITY line"
  else
    red "  FAIL $h missing canonical SEVERITY line"
    FAILED=$((FAILED + 1))
  fi
done
if grep -qF -- "$CANONICAL_SEVERITY" "$RAV_FILE"; then
  green "  ok   review-and-verify.md has canonical SEVERITY line"
else
  red "  FAIL review-and-verify.md missing canonical SEVERITY line"
  FAILED=$((FAILED + 1))
fi

yellow "[12] ROLE substance check (5 elements per template)"
for h in "${ALL_TEMPLATES[@]}"; do
  body=$(section_body "$h" "$PA_FILE")
  check_role "$body" "$h"
done
rav_body=$(cat "$RAV_FILE")
check_role "$rav_body" "review-and-verify.md"

yellow "[13] no leaked absolute paths in template bodies (parallel-agents.md, clarify-questions.md, review-and-verify.md)"
for path in '/Users/' '/home/' '/tmp/'; do
  # parallel-agents.md template bodies only (Per-task templates section)
  hits=$(awk '/^## Per-task templates/{flag=1; next} /^## /{flag=0} flag' "$PA_FILE" | grep -c -- "$path")
  if [ "$hits" -eq 0 ]; then
    green "  ok   no '$path' in parallel-agents.md template bodies"
  else
    red "  FAIL '$path' appeared $hits time(s) in parallel-agents.md template bodies"
    FAILED=$((FAILED + 1))
  fi
  # clarify-questions.md full file (banks should never embed absolute paths)
  hits=$(grep -c -- "$path" "$CQ_FILE")
  if [ "$hits" -eq 0 ]; then
    green "  ok   no '$path' in clarify-questions.md"
  else
    red "  FAIL '$path' appeared $hits time(s) in clarify-questions.md"
    FAILED=$((FAILED + 1))
  fi
  # review-and-verify.md full file (escalation template should never embed absolute paths)
  hits=$(grep -c -- "$path" "$RAV_FILE")
  if [ "$hits" -eq 0 ]; then
    green "  ok   no '$path' in review-and-verify.md"
  else
    red "  FAIL '$path' appeared $hits time(s) in review-and-verify.md"
    FAILED=$((FAILED + 1))
  fi
done

yellow "[15] OUTPUT word cap presence in every sub-agent template"
WORD_CAP_RX='≤[0-9]+\s*word|≤\s*`?\{\{[a-z_]+\}\}`?\s*word|word cap|Total cap|Cap response at'
for h in "${ALL_TEMPLATES[@]}"; do
  body=$(section_body "$h" "$PA_FILE")
  # Restrict to the OUTPUT subsection
  out=$(echo "$body" | awk '/\*\*OUTPUT\*\*/{flag=1; next} flag && /^\*\*/ {flag=0} flag')
  if echo "$out" | grep -qE -- "$WORD_CAP_RX"; then
    green "  ok   $h OUTPUT has word cap"
  else
    red "  FAIL $h OUTPUT missing word cap (looked for: ≤NN words / word cap / Total cap)"
    FAILED=$((FAILED + 1))
  fi
done
# review-and-verify.md escalation reviewer too
out=$(awk '/\*\*OUTPUT\*\*/{flag=1; next} flag && /^\*\*/ {flag=0} flag' "$RAV_FILE")
if echo "$out" | grep -qE -- "$WORD_CAP_RX"; then
  green "  ok   review-and-verify.md escalation OUTPUT has word cap"
else
  red "  FAIL review-and-verify.md escalation OUTPUT missing word cap"
  FAILED=$((FAILED + 1))
fi

yellow "[14] wizard structural conformance (clarify-questions.md)"
for h in "${WIZARD_BANKS[@]}"; do
  body=$(section_body "$h" "$CQ_FILE")
  ok=1
  for req in "**SCENARIO**" "**COMPOSITION**" "**QUESTIONS**" "**EXIT CRITERIA**"; do
    if ! echo "$body" | grep -qF "$req"; then
      red "  FAIL $h missing $req"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  [ "$ok" = "1" ] && green "  ok   $h wizard structure conforms"
done

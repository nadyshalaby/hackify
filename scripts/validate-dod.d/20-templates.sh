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

# === Template Contract conformance (v0.2.x subdir layout) ===
PA_DIR="skills/hackify/references/parallel-agents"
CQ_DIR="skills/hackify/references/clarify-questions"
RAV_FILE="skills/hackify/references/review-and-verify.md"

# Files inside PA_DIR that are NOT dispatchable sub-agent templates and so
# are excluded from checks [9]/[10]/[11]/[12]/[15].
PA_NON_TEMPLATE=(README.md template-contract.md phase-5-aggregation.md)

# Single-template files: each file body IS one sub-agent template.
PA_BUILD_FILES=(
  "$PA_DIR/phase-1-research.md"
  "$PA_DIR/phase-3-implementation.md"
  "$PA_DIR/phase-3b-debug-evidence.md"
  "$PA_DIR/phase-4-cross-package-verification.md"
)
PA_REVIEW_SINGLE_FILES=(
  "$PA_DIR/phase-2.5-spec-review-a-consistency.md"
  "$PA_DIR/phase-2.5-spec-review-b-rules.md"
  "$PA_DIR/phase-2.5-spec-review-c-dependencies.md"
  "$PA_DIR/phase-5-escalation.md"
)

# Multi-template file: holds 3 sub-agent templates under h2 headings.
PA_MULTI_REVIEW="$PA_DIR/phase-5-multi-review.md"
PA_MULTI_REVIEW_HEADINGS=(
  "## Phase 5 — Multi-reviewer A (security & correctness)"
  "## Phase 5 — Multi-reviewer B (quality & layering)"
  "## Phase 5 — Multi-reviewer C (plan consistency & scope)"
)

# Wizard bank files in CQ_DIR (exclude README + contract + picking guide).
CQ_BANK_FILES=(
  "$CQ_DIR/universal-preamble.md"
  "$CQ_DIR/feature.md"
  "$CQ_DIR/fix.md"
  "$CQ_DIR/refactor.md"
  "$CQ_DIR/revamp-redesign.md"
  "$CQ_DIR/debug.md"
  "$CQ_DIR/research.md"
)

CANONICAL_SEVERITY='If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important.'
ALLOWLIST='OWASP|SANS|NIST|RFC|WCAG|ARIA|Clean Code|SOLID|12-Factor|Conventional Commits|Semantic Versioning|Keep a Changelog|ISO 8601|Postel|expand-then-contract'

# Extract one sub-template body from the multi-template file by h2 heading.
# Boundary is the NEXT h2 heading starting with the multi-review prefix —
# this avoids prematurely terminating at `## Critical` lines inside the
# OUTPUT report skeleton.
multi_review_body() {
  awk -v h="$1" '$0 == h {flag=1; next} flag && /^## Phase 5 — Multi-reviewer/ {flag=0} flag' "$PA_MULTI_REVIEW"
}

# Extract the OUTPUT subsection out of a template body. Terminates on the
# next bolded section header (`**SOMETHING**`).
output_subsection() {
  echo "$1" | awk '/\*\*OUTPUT\*\*/{flag=1; next} flag && /^\*\*/ {flag=0} flag'
}

# Verify a template body carries the 6 always-required anchors.
check_template_anchors() {
  local body="$1"
  local label="$2"
  local ok=1
  for req in "**ROLE**" "**INPUTS**" "**OBJECTIVE**" "**METHOD**" "**VERIFICATION**" "**OUTPUT**"; do
    if ! echo "$body" | grep -qF "$req"; then
      red "  FAIL $label missing $req"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  [ "$ok" = "1" ] && green "  ok   $label conforms (ROLE/INPUTS/OBJECTIVE/METHOD/VERIFICATION/OUTPUT)"
}

# Assert SEVERITY presence (review template) or absence (build/research).
check_severity_presence() {
  local body="$1"
  local label="$2"
  local mode="$3"  # "review" or "build"
  if echo "$body" | grep -qF "**SEVERITY**"; then
    if [ "$mode" = "review" ]; then
      green "  ok   $label has SEVERITY (review template)"
    else
      red "  FAIL $label is build/research but has SEVERITY (should be omitted)"
      FAILED=$((FAILED + 1))
    fi
  else
    if [ "$mode" = "review" ]; then
      red "  FAIL $label is review-type but missing SEVERITY"
      FAILED=$((FAILED + 1))
    else
      green "  ok   $label correctly omits SEVERITY"
    fi
  fi
}

yellow "[9] template structural conformance (per-file in $PA_DIR)"
for f in "${PA_BUILD_FILES[@]}" "${PA_REVIEW_SINGLE_FILES[@]}"; do
  check_template_anchors "$(cat "$f")" "$(basename "$f")"
done
for h in "${PA_MULTI_REVIEW_HEADINGS[@]}"; do
  check_template_anchors "$(multi_review_body "$h")" "$(basename "$PA_MULTI_REVIEW"):$h"
done

yellow "[10] SEVERITY conditional (review templates have it; build/research don't)"
for f in "${PA_REVIEW_SINGLE_FILES[@]}"; do
  check_severity_presence "$(cat "$f")" "$(basename "$f")" "review"
done
for h in "${PA_MULTI_REVIEW_HEADINGS[@]}"; do
  check_severity_presence "$(multi_review_body "$h")" "$(basename "$PA_MULTI_REVIEW"):$h" "review"
done
for f in "${PA_BUILD_FILES[@]}"; do
  check_severity_presence "$(cat "$f")" "$(basename "$f")" "build"
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
for f in "${PA_REVIEW_SINGLE_FILES[@]}"; do
  if grep -qF -- "$CANONICAL_SEVERITY" "$f"; then
    green "  ok   $(basename "$f") has canonical SEVERITY line"
  else
    red "  FAIL $(basename "$f") missing canonical SEVERITY line"
    FAILED=$((FAILED + 1))
  fi
done
for h in "${PA_MULTI_REVIEW_HEADINGS[@]}"; do
  if multi_review_body "$h" | grep -qF -- "$CANONICAL_SEVERITY"; then
    green "  ok   $(basename "$PA_MULTI_REVIEW"):$h has canonical SEVERITY line"
  else
    red "  FAIL $(basename "$PA_MULTI_REVIEW"):$h missing canonical SEVERITY line"
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
for f in "${PA_BUILD_FILES[@]}" "${PA_REVIEW_SINGLE_FILES[@]}"; do
  check_role "$(cat "$f")" "$(basename "$f")"
done
for h in "${PA_MULTI_REVIEW_HEADINGS[@]}"; do
  check_role "$(multi_review_body "$h")" "$(basename "$PA_MULTI_REVIEW"):$h"
done
check_role "$(cat "$RAV_FILE")" "review-and-verify.md"

yellow "[13] no leaked absolute paths in template/bank bodies (PA_DIR/*.md, CQ_DIR/*.md, review-and-verify.md)"
# Skip non-template files (README, the contract itself, aggregation guidance) —
# the contract document literally lists `/Users/` etc. as forbidden tokens.
is_pa_non_template() {
  local base="$1"
  for skip in "${PA_NON_TEMPLATE[@]}"; do
    [ "$base" = "$skip" ] && return 0
  done
  return 1
}
for path in '/Users/' '/home/' '/tmp/'; do
  for f in "$PA_DIR"/*.md; do
    is_pa_non_template "$(basename "$f")" && continue
    hits=$(grep -c -- "$path" "$f")
    if [ "$hits" -eq 0 ]; then
      green "  ok   no '$path' in $(basename "$f")"
    else
      red "  FAIL '$path' appeared $hits time(s) in $(basename "$f")"
      FAILED=$((FAILED + 1))
    fi
  done
  for f in "$CQ_DIR"/*.md; do
    [ "$(basename "$f")" = "README.md" ] && continue
    hits=$(grep -c -- "$path" "$f")
    if [ "$hits" -eq 0 ]; then
      green "  ok   no '$path' in $(basename "$f")"
    else
      red "  FAIL '$path' appeared $hits time(s) in $(basename "$f")"
      FAILED=$((FAILED + 1))
    fi
  done
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
for f in "${PA_BUILD_FILES[@]}" "${PA_REVIEW_SINGLE_FILES[@]}"; do
  out=$(output_subsection "$(cat "$f")")
  if echo "$out" | grep -qE -- "$WORD_CAP_RX"; then
    green "  ok   $(basename "$f") OUTPUT has word cap"
  else
    red "  FAIL $(basename "$f") OUTPUT missing word cap (looked for: ≤NN words / word cap / Total cap)"
    FAILED=$((FAILED + 1))
  fi
done
for h in "${PA_MULTI_REVIEW_HEADINGS[@]}"; do
  out=$(output_subsection "$(multi_review_body "$h")")
  if echo "$out" | grep -qE -- "$WORD_CAP_RX"; then
    green "  ok   $(basename "$PA_MULTI_REVIEW"):$h OUTPUT has word cap"
  else
    red "  FAIL $(basename "$PA_MULTI_REVIEW"):$h OUTPUT missing word cap"
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

yellow "[14] wizard structural conformance (per-file in $CQ_DIR)"
for f in "${CQ_BANK_FILES[@]}"; do
  ok=1
  for req in "**SCENARIO**" "**COMPOSITION**" "**QUESTIONS**" "**EXIT CRITERIA**"; do
    if ! grep -qF "$req" "$f"; then
      red "  FAIL $(basename "$f") missing $req"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  [ "$ok" = "1" ] && green "  ok   $(basename "$f") wizard structure conforms"
done

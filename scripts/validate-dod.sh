#!/usr/bin/env bash
# Validate the hackify plugin against its shipping Definition of Done.
# Run from repo root. Exits 0 if all checks pass, non-zero on any failure.

# Note: -e is intentionally omitted — this script accumulates failures into
# FAILED and exits non-zero at the end. -e would abort on the first failed
# check and hide the rest.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

check_file() {
  if [ -f "$1" ]; then
    green "  ok   $1"
  else
    red "  MISS $1"
    FAILED=$((FAILED + 1))
  fi
}

check_jq() {
  if jq -e . "$1" > /dev/null 2>&1; then
    green "  ok   $1 parses as valid JSON"
  else
    red "  FAIL $1 is not valid JSON"
    FAILED=$((FAILED + 1))
  fi
}

check_no_token() {
  local token="$1"
  local path="$2"
  local count
  count=$(grep -rci -- "$token" "$path" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
  if [ "$count" -eq 0 ]; then
    green "  ok   '$token' has 0 occurrences in $path"
  else
    red "  FAIL '$token' has $count occurrences in $path"
    FAILED=$((FAILED + 1))
  fi
}

check_line_range() {
  local file="$1"
  local min="$2"
  local max="$3"
  local lines
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -ge "$min" ] && [ "$lines" -le "$max" ]; then
    green "  ok   $file has $lines lines (range $min..$max)"
  else
    red "  FAIL $file has $lines lines, expected $min..$max"
    FAILED=$((FAILED + 1))
  fi
}

cd "$REPO_ROOT"

yellow "[1] required files exist"
check_file ".claude-plugin/plugin.json"
check_file ".claude-plugin/marketplace.json"
check_file "skills/hackify/SKILL.md"
check_file "skills/hackify/evals/evals.json"
check_file "README.md"
check_file "LICENSE"
check_file "CHANGELOG.md"
check_file ".gitignore"

yellow "[2] reference files (expect ≥10)"
ref_count=$(find skills/hackify/references -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$ref_count" -ge 10 ]; then
  green "  ok   skills/hackify/references/ has $ref_count markdown files (≥10)"
else
  red "  FAIL skills/hackify/references/ has $ref_count markdown files (expected ≥10)"
  FAILED=$((FAILED + 1))
fi

yellow "[3] JSON files parse"
check_jq ".claude-plugin/plugin.json"
check_jq ".claude-plugin/marketplace.json"
check_jq "skills/hackify/evals/evals.json"

yellow "[4] plugin.json required fields"
for field in name version description author repository homepage license keywords; do
  if jq -e ".${field}" .claude-plugin/plugin.json > /dev/null 2>&1; then
    green "  ok   plugin.json has .$field"
  else
    red "  FAIL plugin.json missing .$field"
    FAILED=$((FAILED + 1))
  fi
done

yellow "[5] marketplace.json required fields"
for field in name owner plugins; do
  if jq -e ".${field}" .claude-plugin/marketplace.json > /dev/null 2>&1; then
    green "  ok   marketplace.json has .$field"
  else
    red "  FAIL marketplace.json missing .$field"
    FAILED=$((FAILED + 1))
  fi
done
if jq -e '.owner.name' .claude-plugin/marketplace.json > /dev/null 2>&1; then
  green "  ok   marketplace.json has .owner.name"
else
  red "  FAIL marketplace.json missing .owner.name"
  FAILED=$((FAILED + 1))
fi

yellow "[6] token scrub — no personal/workspace leaks in plugin content"
# nadyshalaby is the author's GitHub handle — legitimate in plugin.json /
# marketplace.json / CHANGELOG / README (install snippets, repo URLs) but
# must NOT appear inside the shipped skill content.
for token in Syanat SyanatBackend SyanatFrontend graphify corecave nadyshalaby; do
  check_no_token "$token" "skills/"
done
for token in Syanat SyanatBackend SyanatFrontend graphify corecave; do
  check_no_token "$token" "README.md"
done
# evals.json is a per-file check since it lives under skills/ but is a single
# JSON document worth verifying explicitly.
for token in Syanat SyanatBackend SyanatFrontend graphify corecave nadyshalaby; do
  check_no_token "$token" "skills/hackify/evals/evals.json"
done
# Absolute /Users/corecave/ paths in shipped content (not docs/work/)
abs=$(grep -rc '/Users/corecave/' skills/ README.md CHANGELOG.md .claude-plugin/ 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
if [ "$abs" -eq 0 ]; then
  green "  ok   0 absolute /Users/corecave/ paths in shipped content"
else
  red "  FAIL $abs absolute /Users/corecave/ paths found"
  FAILED=$((FAILED + 1))
fi

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

section_body() {
  awk -v h="$1" '$0 == h {flag=1; next} flag && (/^### / || /^## /) {flag=0} flag' "$2"
}

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
check_role() {
  local body="$1"
  local label="$2"
  local ok=1
  for marker in "You are " "You reject" "Bias to:" "Bias against:"; do
    if ! echo "$body" | grep -qF "$marker"; then
      red "  FAIL $label missing '$marker'"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  if ! echo "$body" | grep -qE "$ALLOWLIST"; then
    red "  FAIL $label missing framework-allowlist token"
    FAILED=$((FAILED + 1)); ok=0
  fi
  [ "$ok" = "1" ] && green "  ok   $label ROLE 5-element check"
}
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

yellow "[16] version consistency (plugin.json .version == marketplace.json .plugins[0].version)"
PLUGIN_VER=$(jq -r '.version' .claude-plugin/plugin.json 2>/dev/null)
MARKET_VER=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json 2>/dev/null)
if [ -n "$PLUGIN_VER" ] && [ "$PLUGIN_VER" = "$MARKET_VER" ]; then
  green "  ok   plugin.json and marketplace.json plugin version both '$PLUGIN_VER'"
else
  red "  FAIL plugin version mismatch: plugin.json='$PLUGIN_VER' vs marketplace.json='$MARKET_VER'"
  FAILED=$((FAILED + 1))
fi

yellow "[17] SKILL.md cross-refs to the two contracts"
if grep -qF 'Template Contract' skills/hackify/SKILL.md; then
  green "  ok   SKILL.md references 'Template Contract'"
else
  red "  FAIL SKILL.md missing 'Template Contract' cross-reference"
  FAILED=$((FAILED + 1))
fi
if grep -qF 'Wizard Contract' skills/hackify/SKILL.md; then
  green "  ok   SKILL.md references 'Wizard Contract'"
else
  red "  FAIL SKILL.md missing 'Wizard Contract' cross-reference"
  FAILED=$((FAILED + 1))
fi

# === v0.1.4 — Summary command + Quick mode skill ===

SUMMARY_CMD="commands/summary.md"
QUICK_SKILL="skills/quick/SKILL.md"
FINISH_REF="skills/hackify/references/finish.md"

yellow "[18] commands/summary.md exists + frontmatter + Area/Change tokens"
if [ -f "$SUMMARY_CMD" ]; then
  green "  ok   $SUMMARY_CMD exists"
  if head -10 "$SUMMARY_CMD" | grep -qE '^description:'; then
    green "  ok   $SUMMARY_CMD has description: frontmatter"
  else
    red "  FAIL $SUMMARY_CMD missing description: frontmatter"
    FAILED=$((FAILED + 1))
  fi
  for tok in 'Area' 'Change'; do
    if grep -qF "$tok" "$SUMMARY_CMD"; then
      green "  ok   $SUMMARY_CMD body contains '$tok'"
    else
      red "  FAIL $SUMMARY_CMD body missing '$tok'"
      FAILED=$((FAILED + 1))
    fi
  done
else
  red "  FAIL $SUMMARY_CMD missing"
  FAILED=$((FAILED + 1))
fi

yellow "[19] SKILL.md Phase 6 mentions Summary table + /hackify:summary"
phase6_body=$(awk '/^## Phase 6/{flag=1; next} flag && /^## /{flag=0} flag' skills/hackify/SKILL.md)
if echo "$phase6_body" | grep -qF 'Summary table'; then
  green "  ok   SKILL.md Phase 6 contains 'Summary table'"
else
  red "  FAIL SKILL.md Phase 6 missing 'Summary table'"
  FAILED=$((FAILED + 1))
fi
if grep -qF '/hackify:summary' skills/hackify/SKILL.md; then
  green "  ok   SKILL.md references '/hackify:summary'"
else
  red "  FAIL SKILL.md missing '/hackify:summary' reference"
  FAILED=$((FAILED + 1))
fi

yellow "[20] finish.md Summary-table authoring subsection"
if grep -qF 'Summary table' "$FINISH_REF"; then
  green "  ok   $FINISH_REF contains 'Summary table'"
else
  red "  FAIL $FINISH_REF missing 'Summary table' subsection"
  FAILED=$((FAILED + 1))
fi
if grep -qF '| Area |' "$FINISH_REF"; then
  green "  ok   $FINISH_REF contains '| Area |' worked-example header"
else
  red "  FAIL $FINISH_REF missing '| Area |' worked-example header"
  FAILED=$((FAILED + 1))
fi

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

# === v0.2.0 — sync-runtimes, new skills, sprint vocab, router, pause keywords ===

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

echo
if [ "$FAILED" -eq 0 ]; then
  green "ALL CHECKS PASSED"
  exit 0
else
  red "$FAILED CHECK(S) FAILED"
  exit 1
fi

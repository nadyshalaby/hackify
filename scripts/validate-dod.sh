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

yellow "[2] reference files (expect 9)"
ref_count=$(find skills/hackify/references -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$ref_count" -eq 9 ]; then
  green "  ok   skills/hackify/references/ has 9 markdown files"
else
  red "  FAIL skills/hackify/references/ has $ref_count markdown files (expected 9)"
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

echo
if [ "$FAILED" -eq 0 ]; then
  green "ALL CHECKS PASSED"
  exit 0
else
  red "$FAILED CHECK(S) FAILED"
  exit 1
fi

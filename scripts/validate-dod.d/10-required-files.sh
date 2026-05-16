# shellcheck shell=bash

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


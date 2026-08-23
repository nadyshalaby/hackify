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

yellow "[2] reference files (expect ≥20 across references/ tree)"
# Recursive count so the per-topic subdirs (parallel-agents/, clarify-questions/)
# introduced in v0.2.7 are included. Pre-v0.2.7 layout had all references at
# maxdepth 1; v0.2.7 split two oversized files into per-topic subdirs.
ref_count=$(find skills/hackify/references -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$ref_count" -ge 20 ]; then
  green "  ok   skills/hackify/references/ has $ref_count markdown files (≥20)"
else
  red "  FAIL skills/hackify/references/ has $ref_count markdown files (expected ≥20)"
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

yellow "[6] token scrub, no personal/workspace leaks in plugin content"
# nadyshalaby is the author's GitHub handle, legitimate in plugin.json /
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
# Absolute /Users/corecave/ paths in shipped content (not docs/work/).
#
# ONE CALL PER PATH, THROUGH check_no_token, and neither half of that is
# cosmetic. The bare grep this replaced read its number out of an awk pipeline and
# never tested grep's own status, so an unreadable file under any of these four
# trees made grep exit 2, print no counts, land the sum on 0 and print this line
# GREEN over content it had not opened. Reproduced end to end: a real
# /Users/corecave/ path planted in .claude-plugin/ and chmod 000'd carried the
# WHOLE run to ALL CHECKS PASSED with zero red lines, while the same file readable
# correctly reddened. check_no_token reds when grep exits above 1, which is the
# repaired matcher the personal-handle loops above already screen through; this
# was the last copy of the old pattern in the file.
#
# SINGULAR, NOT THE BATCHED check_no_tokens_in. The batched form takes MANY TOKENS
# over ONE path; this is ONE token over four paths, the opposite shape, so there is
# nothing here to batch and nothing the batched form would save.
for abs_path in skills/ README.md CHANGELOG.md .claude-plugin/; do
  check_no_token '/Users/corecave/' "$abs_path"
done


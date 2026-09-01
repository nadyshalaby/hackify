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

yellow "[6b] no live work-doc leaks an absolute home-directory path"
# THE WORK-DOC BECAME A PUBLISHING SURFACE, AND THE RULE FOR IT HAD NOTHING BEHIND
# IT. skills/hackify/references/work-doc-artifact.md carries a `## Project-relative
# paths only` section, Phase 6 publishes the live work-doc as a page, and that page
# travels to whoever the user sends it to. A work-doc accumulates absolute paths
# readily: task file allowlists, evidence-ledger rows quoting commands, dispatch
# records. Until this block, that section was an instruction a reader had to
# remember, which is the shape [76j] and [58] were both written about.
#
# THE SCREEN IS A SHAPE, NOT ONE HOME DIRECTORY, and that is a decision rather than
# a widening for its own sake. The loop above bans the literal '/Users/corecave/'
# out of shipped content, which is right there because that tree is the author's own
# and a second contributor's path in it would be a different defect. Here the rule
# being enforced is that a PUBLISHED page carries no path out of anybody's home
# directory, and that rule is about the shape: pinned to one home directory this
# would print green on a contributor's '/Users/dana/', on every '/home/<name>/' a
# Linux or CI run pastes in, and on the author's own machine after a rename. A
# screen that only sees the one case a reader would recognise unaided is not worth
# the transcript line.
#
# AND NO WIDER THAN THAT. The pattern requires a NAME COMPONENT after the root and a
# closing slash, so a doc that writes the bare word '/Users/' while explaining this
# very rule stays green, and so does '$HOME/'. Case-sensitive, deliberately and
# unlike check_no_token above: '/Users' is capitalised on macOS and '/home' is not on
# Linux, so folding case buys '/USERS/' and nothing a real path ever spells.
WD_LIVE_DIR="docs/work"
WD_HOME_RE='(/Users/|/home/)[^/[:space:]]+/'

# ARCHIVED DOCS ARE OUT, AND THE CARVE-OUT IS PERMANENT RATHER THAN GRANDFATHERED.
# Not because the 25 docs under docs/work/done/ carrying 26 such paths would be
# tedious to scrub, which would be the grandfathering answer, but because they are
# the frozen sprint record and are not on the publishing path at all: Phase 6
# publishes the LIVE doc and archives it afterwards, so nothing under done/ is ever
# rendered into a page again. Rewriting them would edit history to satisfy a screen
# aimed at a surface they do not sit on, and this repo already refuses that trade
# once, in [93]'s pathspec, which excludes docs/work/ so the sprint record can quote
# the broken prompt it was written to describe. WHAT WOULD RETIRE THE CARVE-OUT: an
# archived doc becoming a publish target again. Scrubbing the 26 paths would not,
# on its own, be a reason to start scanning done/.
#
# THE GLOB IS THE EXCLUSION, and it is structural rather than a flag. A live doc is a
# '*.md' directly under docs/work/, so done/ is not reachable from this loop at all
# and there is no --exclude-dir whose portability anyone has to trust. An unmatched
# glob leaves the pattern itself, which the -f test drops.
#
# WHY A CONTROL AT ALL, AND WHY THIS ONE. Today the live set is EMPTY: all 25 tracked
# work-docs are archived and the sprint running as this landed is quick mode, which
# writes none. So on a normal run this block reads zero files, and "found no leak"
# and "never looked" print the same silence, which is the vacuous pass every block in
# this directory refuses. The control is two-sided and built from literals HERE: a
# sample that must match and a sample that must not. An emptied or broken pattern
# fails the first, a pattern widened until it matches anything fails the second, and
# both fail whether or not a live doc exists to scan, which is the property the
# archived corpus could not give. THE ARCHIVE WAS THE OTHER CANDIDATE, 26 real hits
# on disk proving the reader reaches files and not just that a regex compiles, and it
# was refused because it pins "the archive still contains a leak" and would red on
# the day somebody scrubbed it, which is a check reddening on a good deed.
WD_CTL_HIT='an allowlist row reading /Users/dana/Code/proj/src/a.ts and a log line from /home/runner/work/p'
WD_CTL_MISS='an allowlist row reading scripts/validate-dod.d/10-required-files.sh, and the bare root /Users/ named in prose'
if ! /usr/bin/grep -qE -- "$WD_HOME_RE" <<<"$WD_CTL_HIT"; then
  red "  FAIL [6b] the home-path pattern did not match its own positive control, so every doc below would report clean against a pattern that matches nothing"
  FAILED=$((FAILED + 1))
elif /usr/bin/grep -qE -- "$WD_HOME_RE" <<<"$WD_CTL_MISS"; then
  red "  FAIL [6b] the home-path pattern matched its negative control, a project-relative path and a bare '/Users/' written in prose, so it has widened past the shape it screens for"
  FAILED=$((FAILED + 1))
else
  green "  ok   the [6b] home-path pattern separates an absolute home path from a project-relative one, so a clean verdict below is a verdict"
  wd_n=0
  for wd_doc in "$WD_LIVE_DIR"/*.md; do
    [ -f "$wd_doc" ] || continue
    wd_n=$((wd_n + 1))
    wd_hits=$(/usr/bin/grep -noEI -- "$WD_HOME_RE" "$wd_doc" 2>/dev/null); wd_rc=$?
    if [ "$wd_rc" -gt 1 ]; then
      red "  FAIL [6b] $wd_doc was never screened, grep exited $wd_rc, so a clean result here would be a scan that never ran"
      FAILED=$((FAILED + 1))
    elif [ "$wd_rc" -eq 1 ]; then
      green "  ok   $wd_doc carries no absolute home-directory path"
    else
      red "  FAIL [6b] $wd_doc carries an absolute home-directory path, and this doc is published as a page:"
      FAILED=$((FAILED + 1))
      printf '%s\n' "$wd_hits" | sed 's/^/         - /'
    fi
  done
  if [ "$wd_n" -eq 0 ]; then
    yellow "  note [6b] no live work-doc sits directly under $WD_LIVE_DIR/, so nothing was screened; the archived docs under $WD_LIVE_DIR/done/ are carved out above and are not a publishing surface"
  fi
fi

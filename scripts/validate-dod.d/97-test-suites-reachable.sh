# shellcheck shell=bash

# [97] Every tracked test suite is reachable from CI, directly or by import.
#
# Check [0] in scripts/validate-dod.sh holds that a validator fragment sitting on
# disk which nothing sources is a FAIL, on the grounds that its checks do not run
# and therefore cannot fail the run. A test file on disk that no CI step reaches is
# the same shape one layer up, at a layer where no check was looking. Two of them
# appeared inside a single sprint: scripts/test_section_exists.py (15 tests) and
# scripts/test_literal_absent_claims.py (14 tests) were both green when a human
# remembered to type their names and absent from every automated run. Two in one
# sprint is a pattern rather than an accident, so the answer is a guard and not two
# more run: lines.
#
# THREE CLAUSES, AND THE THIRD IS THE ONE THAT KEEPS THIS OFF A CORRECT FILE. A
# suite is reachable if ci.yml names it directly, OR if a file ci.yml names imports
# it. skills/lawkeeper/scripts/test_scoping.py has no __main__ and prints nothing
# when run on its own, and it is still not an orphan: test_audit.py imports it and
# its _all_tests() collects the test_* callables out of vars(test_scoping) beside
# its own globals, so the one CI step reports 56 tests, 34 of its own and 22 from
# the imported half. That split is deliberate and test_audit.py's header says why
# (it reached the 500-line cap the scanner it tests exists to enforce). A
# two-clause version of this check would redden that file, which would be a guard
# punishing the correct structure.
#
# TRACKED FILES ONLY, WHICH IS THE OPPOSITE CALL FROM [55], ON PURPOSE. [55] asks
# whether a file will SHIP in dist/ and so reads untracked-but-not-ignored files
# too, because a canonical file is new content the moment it is written. This asks
# whether CI will RUN a suite, and CI runs the committed tree. A working-tree file
# no commit carries is a question CI never gets asked, so folding it in here would
# redden the validator for anyone with a half-written test open in an editor, and
# would assert a property no CI run has ever had.
#
# ONE DIRECTION ONLY, stated the way [76f] states its own. This catches a suite on
# disk that CI never reaches. It does NOT catch the reverse, a ci.yml step naming
# a path that has since been deleted. That direction needs no guard here for a
# reason [76f] cannot claim about its own: a step pointing at a missing file fails
# the CI run out loud the first time it executes, so it cannot rot quietly.
#
# NOTHING READ OUT OF A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN. Module
# names are derived from filenames on disk, which makes them data, and every match
# against them below is a fixed-string grep -F. A file named test_a.b.py would
# otherwise put regex metacharacters into the matcher.

yellow "[97] every tracked test suite is reachable from CI, directly or by import"

TSR_CI='.github/workflows/ci.yml'

# THE FLOORS ARE THE POINT, and both sides need one. An empty entrypoint list walks
# the classification loop zero times and prints a confident green having examined
# nothing, which is the exact vacuous pass 55-mirror-completeness.sh describes at its
# own floor. An empty CI list is louder but no better: it makes every suite look
# unreachable and names a list of files when the defect is in the parse. Floors rather
# than exact counts, because suites are added and retired most waves and only a
# collapse toward zero means the discovery broke. NO LIVE PAIR IS WRITTEN HERE ANY
# MORE: the two numbers this paragraph carried were the ones true when the floors
# were set and both had drifted upward since, which is the rotting-comment shape
# 57-doc-links.sh:20-26 answers by carrying the command instead of the count. Both
# sides re-derive with
#   git ls-files | grep -E '(^|/)test_[^/]*\.(py|sh)$' | grep -v '\.d/' | wc -l
#   grep -E '^[[:space:]]*run:' .github/workflows/ci.yml \
#     | grep -oE '[A-Za-z0-9_./-]+\.(py|sh)' | sort -u | wc -l
# and both are printed live on this check's own pass line.
TSR_ENTRY_FLOOR=5
TSR_CI_FLOOR=6

tsr_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

# `printf '%s\n' "" | wc -l` reports 1, and an empty set reading as one entry is the
# single value a floor must never see. Counted with a loop instead, matching how
# 55-mirror-completeness.sh counts its own tracked set and for that same reason.
tsr_count() {
  local n=0 line
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$((n + 1))
  done
  printf '%s\n' "$n"
}

# git's status is read on its own line rather than off the end of a pipe. Under
# `set -o pipefail` a pipeline reports the RIGHTMOST non-zero status, so a git that
# exits 128 followed by a grep exiting 1 over the empty result arrives as 1, and the
# tooling failure is laundered into "no matches". 00-helpers.sh records the same trap
# above check_no_token, where grep's status used to be read back through awk.
TSR_TRACKED=$(git ls-files 2>/dev/null)
TSR_GIT_RC=$?

# Helper directories are excluded because a *.d/ tree holds sourced fragments rather
# than entrypoints. This pattern is authored here, not read out of a file.
TSR_ENTRIES=$(printf '%s\n' "$TSR_TRACKED" | grep -E '(^|/)test_[^/]*\.(py|sh)$' | grep -v '\.d/')

# grep's three statuses are the whole contract, so this one is also read alone: 0 is
# a match, 1 is a file with no run: steps (which the floor below judges), and anything
# above 1 is grep unable to read the workflow at all, which must never be the reason a
# suite prints green.
TSR_CI_RUN=$(grep -E '^[[:space:]]*run:' "$TSR_CI" 2>/dev/null)
TSR_CI_RC=$?
TSR_CI_PATHS=$(printf '%s\n' "$TSR_CI_RUN" | grep -oE '[A-Za-z0-9_./-]+\.(py|sh)' | sort -u)

TSR_N=$(printf '%s\n' "$TSR_ENTRIES" | tsr_count)
TSR_CI_N=$(printf '%s\n' "$TSR_CI_PATHS" | tsr_count)
TSR_READY=1

if [ "$TSR_GIT_RC" -ne 0 ]; then
  tsr_fail "[97] git ls-files exited $TSR_GIT_RC, so the suite scan never ran and this run says nothing about whether any test suite reaches CI"
  TSR_READY=0
fi

if [ ! -r "$TSR_CI" ]; then
  tsr_fail "[97] $TSR_CI is missing or unreadable, so the suite scan never ran; with no workflow to read, every suite would look unreachable for a reason that is not about the suites"
  TSR_READY=0
elif [ "$TSR_CI_RC" -gt 1 ]; then
  tsr_fail "[97] grep exited $TSR_CI_RC reading $TSR_CI, so its run: steps were never parsed and the suite scan never ran"
  TSR_READY=0
fi

# THE FLOORS ARE JUDGED BEFORE THE CLASSIFICATION RUNS, and the order is load-bearing
# rather than tidy, the same call 55-mirror-completeness.sh makes at its own floor. A
# loop over a collapsed set has nothing to say, so letting it speak first would print
# a verdict about CI wiring when the defect is in the discovery.
if [ "$TSR_READY" -eq 1 ] && [ "$TSR_N" -lt "$TSR_ENTRY_FLOOR" ]; then
  tsr_fail "[97] discovered only $TSR_N tracked test entrypoint(s) against a floor of $TSR_ENTRY_FLOOR; the discovery collapsed rather than the tree losing its suites, so nothing was compared against $TSR_CI"
  TSR_READY=0
fi

if [ "$TSR_READY" -eq 1 ] && [ "$TSR_CI_N" -lt "$TSR_CI_FLOOR" ]; then
  tsr_fail "[97] parsed only $TSR_CI_N command path(s) out of $TSR_CI against a floor of $TSR_CI_FLOOR; the workflow parse collapsed, so every suite would read as unreachable for a reason that is not about the suites"
  TSR_READY=0
fi

# Clause 2, resolved literally. The module name is a filename off disk, so it is data
# and it is matched as a fixed string. ONE HOP, not a transitive walk: the live case is
# a suite imported straight by a file CI names, and a chain deeper than that is a shape
# this repo does not have. Two biases, both pointed the same way and both toward
# accepting a file rather than reddening a correct one: a match inside a comment or
# a string counts, and the module is resolved from the BASENAME, so two suites
# sharing a basename in different directories are both accepted by one import in
# one CI-named file. The live tree has no such collision.
tsr_imported_by_ci() {
  local mod="$1" f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || continue
    grep -qF -e "import $mod" -e "from $mod import" -- "$f" 2>/dev/null && return 0
  done <<TSR_IMP_EOF
$TSR_CI_PATHS
TSR_IMP_EOF
  return 1
}

TSR_DIRECT=0
TSR_IMPORT=0
TSR_ORPHAN=0

# Split out of the loop below so the loop keeps one level of nesting rather than three.
tsr_classify() {
  local entry="$1" mod
  if grep -qxF -- "$entry" <<<"$TSR_CI_PATHS"; then
    TSR_DIRECT=$((TSR_DIRECT + 1))
    return
  fi
  mod=${entry##*/}
  mod=${mod%.py}
  if tsr_imported_by_ci "$mod"; then
    TSR_IMPORT=$((TSR_IMPORT + 1))
    return
  fi
  tsr_fail "$entry is a test suite that no step in $TSR_CI runs and no CI-named file imports, so every test it holds is absent from each automated run and cannot fail one"
  TSR_ORPHAN=$((TSR_ORPHAN + 1))
}

if [ "$TSR_READY" -eq 1 ]; then
  while IFS= read -r tsr_entry; do
    [ -n "$tsr_entry" ] || continue
    tsr_classify "$tsr_entry"
  done <<TSR_ENTRY_EOF
$TSR_ENTRIES
TSR_ENTRY_EOF

  # THE PASS LINE CARRIES ITS NUMBERS. A green with no count reads identically whether
  # the scan examined every suite in the tree or none of them, which is the failure
  # mode the floors above exist to prevent and the one this line has to make visible.
  if [ "$TSR_ORPHAN" -eq 0 ]; then
    green "  ok   all $TSR_N tracked test suite(s) reach CI, $TSR_DIRECT named directly in $TSR_CI and $TSR_IMPORT reached by import from a file it names"
  fi
fi

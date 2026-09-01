# shellcheck shell=bash

# [57] Documentation pointers resolve (since v0.13.0).
#
# WHY THIS EXISTS: nothing checked that a cited .md file still exists, and the
# v0.13.0 agent merges proved what that costs. Four pointers to a deleted
# template survived a fully green validator, in two sibling prompts and in
# review-triage/SKILL.md. On Claude Code a prompt is executable text, so an
# agent told to read a file that is gone is a silently degraded agent, not a
# docs typo. All four were bare backticked paths, not markdown links, which is
# why this checks both forms and why a link-only check would have been useless.
#
# WHAT WAS STILL UNCHECKED, AND IS NOW. A citation carries two claims, that the
# file exists and that the line does, and only the first was ever read. The
# second rots faster, because a file survives a refactor that moves every line in
# it. `some/file.md:42` now has its `:42` opened and counted for real. Where the
# path resolves nowhere the line half stays quiet, since that is already the
# finding above and one defect should not print twice.
#
# THE SCAN SURFACE IS NOT ONLY MARKDOWN, and that was measured rather than
# assumed. The large majority of live citations sit in shell comments under
# scripts/ rather than in shipped markdown, so the citation half reads .sh and
# .py as well. No count is written here, deliberately: an unpinned number in a
# comment is the rotting claim this check exists to catch, and the checker's own
# docstring carries the command to re-derive it. The pointer half above is a
# markdown rule and keeps its own narrower roots.
#
# Delegates to scripts/check_doc_links.py; inline-code spans, multi-base
# resolution, hard-wrapped citations and reading a cited file to its real length
# are not a job for grep. The Python script is standalone-runnable and exits
# non-zero on any finding. Its docstring carries every pointer form, the
# resolution rules and the two documented exemption sets, and no count of those
# forms, which have already grown once. scripts/test_doc_link_lines.py, both
# off-by-one edges included, and scripts/test_doc_anchors.py are its suites.
#
# ONE ok LINE PER INVOCATION, and it must stay that way. 00-helpers.sh and
# scripts/validate-dod.sh both describe the shell-to-transcript ok-line gap as a
# count of delegated INVOCATIONS; a checker that printed a second pass line would
# make that prose wrong in two files at once. The citation total rides on the
# line that was already printed.

yellow "[57] documentation pointers, every cited .md link and prose path resolves, and every line, heading, construct or phrase a pointer names inside it is really there"

LINK_CHECKER="scripts/check_doc_links.py"

if [ ! -f "$LINK_CHECKER" ]; then
  red "  FAIL $LINK_CHECKER missing, cannot verify documentation pointers"
  FAILED=$((FAILED + 1))
elif ! command -v python3 > /dev/null 2>&1; then
  red "  FAIL python3 not available, cannot verify documentation pointers"
  FAILED=$((FAILED + 1))
else
  # The checker prints its own "  ok" / "  FAIL" lines in validator format.
  if ! python3 "$LINK_CHECKER" .; then
    FAILED=$((FAILED + 1))
  fi

  # Source passing does not prove the built runtime passes. dist/claude-code is
  # the one tree that registers what it ships, so a pointer that dies in the
  # copy degrades a real agent there. Skipped when dist is absent, it is
  # gitignored and a fresh clone validates before it ever syncs.
  CC_DIST="dist/claude-code"
  if [ ! -d "$CC_DIST" ]; then
    yellow "  skip $CC_DIST not built yet, run scripts/sync-runtimes.sh to cover the built tree"
  elif ! python3 "$LINK_CHECKER" "$CC_DIST"; then
    red "  FAIL pointers above resolve in source but not in the built $CC_DIST tree"
    FAILED=$((FAILED + 1))
  fi
fi

# WHAT THE `:42` NOW HAS TO SURVIVE, AND WHY THIS PARAGRAPH SITS AT THE BOTTOM.
# Proving the line EXISTS was never the claim a citation makes. Reproduced end to
# end before this was written: retarget a live citation from `:38` to `:1`, which
# points it at a shebang, and the whole bar stayed green. The checker now opens
# the cited location, refuses one that is blank or a shebang, and where the
# citing text quotes the line behind a verb ("`x.md:9` says \"...\"") it matches
# that quote against what is really there. A citation nothing pins is UNPINNED,
# counted on the ok line rather than passed as verified, because a checker that
# reads two locations of sixty-six and prints a clean line is the defect being
# removed rather than a smaller version of the fix.
#
# EVERY COVERAGE COUNTER ON THAT LINE NOW HAS A FLOOR, hand-written beside the
# table in check_doc_links.py and never derived from the scan it guards, for the
# reason 00-helpers.sh's check_list_size gives. Without one a regressed glob or
# resolver prints a clean count of nothing. The floors bind the source-tree pass
# only; a built runtime is a subset and would redden for being one.
#
# THE PLACEMENT IS THE POINT. Five live citations elsewhere in this repo pin
# lines 20-26 and line 54 of THIS file by number, so a paragraph inserted above
# either would shift all five and redden the very check it documents. Appending
# is what keeps them true, and needing to know that is the argument for the
# anchor forms over line numbers.

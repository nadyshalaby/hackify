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
# non-zero on any finding. Its docstring carries the three pointer forms, the
# resolution rules and the two documented exemption sets, and
# scripts/test_doc_link_lines.py is its unit suite, both off-by-one edges
# included.
#
# ONE ok LINE PER INVOCATION, and it must stay that way. 00-helpers.sh and
# scripts/validate-dod.sh both describe the shell-to-transcript ok-line gap as a
# count of delegated INVOCATIONS; a checker that printed a second pass line would
# make that prose wrong in two files at once. The citation total rides on the
# line that was already printed.

yellow "[57] documentation pointers, every cited .md link and prose path resolves, and every cited line number exists"

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

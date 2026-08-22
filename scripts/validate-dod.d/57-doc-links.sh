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
# Delegates to scripts/check_doc_links.py; correct handling of fenced blocks,
# inline-code spans and multi-base resolution is not a job for grep. The Python
# script is standalone-runnable and exits non-zero on any finding. Its docstring
# carries the resolution rules and the two documented exemption sets.

yellow "[57] documentation pointers, every cited .md link and prose path resolves"

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

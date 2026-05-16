#!/usr/bin/env bash
# Validate the hackify plugin against its shipping Definition of Done.
# Run from repo root. Exits 0 if all checks pass, non-zero on any failure.
#
# Thin orchestrator. Helper functions and check groups live in
# scripts/validate-dod.d/*.sh and are sourced in order:
#   00-helpers.sh                     — color printers + check_* helpers
#   10-required-files.sh              — checks [1]-[6]
#   20-templates.sh                   — checks [7]-[15] (template contracts)
#   30-version-and-summary.sh         — checks [16]-[20]
#   40-quick-skill.sh                 — checks [21]-[23], [35]
#   50-runtimes-and-companions.sh     — checks [24]-[26], [28]
#   60-primitives.sh                  — checks [29]-[32]
#   70-invariants-and-new.sh          — checks [33]-[34]
#
# Note: -e is intentionally omitted — modules accumulate failures into
# FAILED and the orchestrator exits non-zero at the end. -e would abort
# on the first failed check and hide the rest.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0
DOD_MODULES_DIR="$REPO_ROOT/scripts/validate-dod.d"

cd "$REPO_ROOT"

source "$DOD_MODULES_DIR/00-helpers.sh"
source "$DOD_MODULES_DIR/10-required-files.sh"
source "$DOD_MODULES_DIR/20-templates.sh"
source "$DOD_MODULES_DIR/30-version-and-summary.sh"
source "$DOD_MODULES_DIR/40-quick-skill.sh"
source "$DOD_MODULES_DIR/50-runtimes-and-companions.sh"
source "$DOD_MODULES_DIR/60-primitives.sh"
source "$DOD_MODULES_DIR/70-invariants-and-new.sh"

if [ "$FAILED" -eq 0 ]; then
  green "ALL CHECKS PASSED"
  exit 0
else
  red "$FAILED CHECK(S) FAILED"
  exit 1
fi

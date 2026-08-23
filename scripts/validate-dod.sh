#!/usr/bin/env bash
# Validate the hackify plugin against its shipping Definition of Done.
# Run from repo root. Exits 0 if all checks pass, non-zero on any failure.
#
# Thin orchestrator. Helper functions and check groups live in
# scripts/validate-dod.d/*.sh and are sourced in order:
#   00-helpers.sh, color printers + check_* helpers
#   10-required-files.sh, checks [1]-[6]
#   20-templates.sh, checks [7]-[15], [36] (template contracts incl. agents/)
#   27-marketplace-ref-pin.sh, check [27], marketplace channel pins match
#                   plugin.json (stable ref, edge ref, versions)
#   30-version-and-summary.sh, checks [16]-[20]
#   40-quick-skill.sh, checks [21]-[23], [35]
#   50-runtimes-and-companions.sh, checks [24]-[26], [28]
#   55-mirror-completeness.sh, check [55], sync manifest covers every tracked canonical file
#   57-doc-links.sh, check [57], every cited .md link and prose path resolves to a real file
#   60-primitives.sh, checks [29]-[32]
#   70-invariants-and-new.sh, checks [33]-[34], [37]-[39] (hook targets, perf invariants)
#   75-ship-bar.sh, check [75], the always-on ship bar (law-scout, ship gate,
#                   coherence reviewer, refute + settled-diff exit) wired in every mode
#   76-phase-ledger-substrate.sh, check [76], where the phase ledger lives, the
#                   per-phase tick lines, and the always-on phase laws
#   77-reviewer-roster.sh, check [77], reviewer-roster drift, count bans over six
#                   files (two no other check reaches, a wider token set on the
#                   four shared with [70]) plus the standing-member-is-B invariant
#   78-dispatch-mandate.sh, check [78], no parent-authored diffs + orchestration
#                   that is a tool call rather than a description
#   80-file-size-caps.sh, check [80], file-size ≤ 500 LOC across primitives
#   85-design-spec-conformance.sh, check [85], design-spec catalog conformance
#                   (contract + WCAG AA contrast)
#   90-collisions.sh, check [90], sibling-plugin slug collision (soft)
#
# Note: -e is intentionally omitted, modules accumulate failures into
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
source "$DOD_MODULES_DIR/27-marketplace-ref-pin.sh"
source "$DOD_MODULES_DIR/30-version-and-summary.sh"
source "$DOD_MODULES_DIR/40-quick-skill.sh"
source "$DOD_MODULES_DIR/50-runtimes-and-companions.sh"
source "$DOD_MODULES_DIR/55-mirror-completeness.sh"
source "$DOD_MODULES_DIR/57-doc-links.sh"
source "$DOD_MODULES_DIR/60-primitives.sh"
source "$DOD_MODULES_DIR/70-invariants-and-new.sh"
source "$DOD_MODULES_DIR/75-ship-bar.sh"
source "$DOD_MODULES_DIR/76-phase-ledger-substrate.sh"
source "$DOD_MODULES_DIR/77-reviewer-roster.sh"
source "$DOD_MODULES_DIR/78-dispatch-mandate.sh"
source "$DOD_MODULES_DIR/80-file-size-caps.sh"
source "$DOD_MODULES_DIR/85-design-spec-conformance.sh"
source "$DOD_MODULES_DIR/90-collisions.sh"

if [ "$FAILED" -eq 0 ]; then
  green "ALL CHECKS PASSED"
  exit 0
else
  red "$FAILED CHECK(S) FAILED"
  exit 1
fi

# shellcheck shell=bash

# [85] Design-spec catalog conformance (since v0.8.1).
#
# WHY THIS EXISTS: the twelve catalog specs under
# skills/hackify/references/design-spec/catalog/ are the worked examples an
# agent copies into a real project. A spec that drifts from its own contract
# teaches the drift. Four of them shipped in v0.8.0 with semantic colors below
# WCAG AA as text; that was caught by computing the ratios by hand at authoring
# time, which is exactly the kind of check that does not survive contact with a
# future edit. This makes it permanent.
#
# Delegates to scripts/check_design_specs.py, contrast needs real floating
# point, which bash does not have. The Python script is standalone-runnable and
# exits non-zero on any finding.

yellow "[85] design-spec catalog conformance (contract + WCAG AA contrast)"

CHECKER="scripts/check_design_specs.py"
CATALOG="skills/hackify/references/design-spec/catalog"

if [ ! -f "$CHECKER" ]; then
  red "  FAIL $CHECKER missing, cannot verify catalog conformance"
  FAILED=$((FAILED + 1))
elif [ ! -d "$CATALOG" ]; then
  red "  FAIL $CATALOG missing, design-spec package not installed"
  FAILED=$((FAILED + 1))
elif ! command -v python3 > /dev/null 2>&1; then
  red "  FAIL python3 not available, cannot verify catalog conformance"
  FAILED=$((FAILED + 1))
else
  # The checker prints its own "  ok" / "  FAIL" lines in validator format.
  if ! python3 "$CHECKER" "$CATALOG"; then
    FAILED=$((FAILED + 1))
  fi
fi

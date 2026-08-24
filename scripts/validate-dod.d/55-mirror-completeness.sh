# shellcheck shell=bash

# [55] Mirror-completeness, every tracked canonical file under skills/,
# commands/, rules/, agents/, and hooks/ MUST appear in the sync manifest
# (MIRROR_SOURCES or CLAUDE_CODE_EXTRA). Both manifests are hand-maintained
# enumerations; a file forgotten there ships silently absent from the
# dist/<runtime>/ trees (bit the project in v0.2.6, again in v0.4.1 when 5
# companion-skill evals.json were found unmirrored, and agents/ + hooks/
# were a blind spot until v0.7.0). This check makes that failure mode loud.

yellow "[55] mirror-completeness, tracked skills/ commands/ rules/ agents/ hooks/ files are all in the sync manifest"

# Single source of truth: read the manifest arrays straight from the sync
# helper, in a command-substitution subshell so its function/var definitions
# (red/green/yellow, write_*, RUNTIMES) cannot clobber this validator's own.
MANIFEST_LIST=$(
  set +u
  . scripts/sync-runtimes.d/00-helpers.sh >/dev/null 2>&1
  printf '%s\n' "${MIRROR_SOURCES[@]}" "${CLAUDE_CODE_EXTRA[@]}"
)

# The canonical source set is the git-tracked set PLUS untracked-but-not-ignored
# files, using git ls-files (not find) excludes __pycache__/*.pyc for free, so
# build artifacts can never masquerade as unmirrored canonical files.
#
# --others --exclude-standard is what makes this check useful BEFORE the commit.
# Tracked-only, a brand-new reference file is invisible here and the validator
# goes green, then CI fails the moment it is committed. That is exactly how
# references/review-scope.md shipped absent from all six runtime distributions
# in v0.11.0. .gitignore still governs, so ignored artifacts stay excluded.
#
# Exclusions, tracked files that legitimately never ship:
#   */evals/corpus/*, the lawkeeper recall corpus is a synthetic
#                                       set of DELIBERATELY-violating fixtures used
#                                       only to score the scanner in CI. Mirroring
#                                       deliberately-broken code (incl. a planted
#                                       hardcoded secret) into dist/ would be wrong.
#   hooks/test_*.sh,                   dev-only test harnesses for the hook
#                                       scripts. The claude-code
#                                       emitter copies only the explicit
#                                       CLAUDE_CODE_EXTRA enumeration, which omits
#                                       test files by design, no runtime ships it.
TRACKED_SORTED=$( { git ls-files skills/ commands/ rules/ agents/ hooks/ 2>/dev/null; \
    git ls-files --others --exclude-standard skills/ commands/ rules/ agents/ hooks/ 2>/dev/null; } \
  | grep -v -e '/evals/corpus/' -e '^hooks/test_[a-z_]*\.sh$' \
  | sort -u)
MANIFEST_SORTED=$(printf '%s\n' "$MANIFEST_LIST" | sort -u)

# THE FLOOR IS WHAT STOPS A VACUOUS PASS, the same one 91-claim-resolvers.sh:84-88
# carries and for its stated reason. The two sides of the comparison below are not
# symmetric: an empty MANIFEST_SORTED leaves every canonical file unmirrored and
# this block shouts, while an empty TRACKED_SORTED leaves `comm -23` nothing on its
# left and prints "ok every ... file is in MIRROR_SOURCES/CLAUDE_CODE_EXTRA" over a
# set nothing was ever compared. Measured, not feared: with TRACKED_SORTED forced
# empty, `comm -23` returns nothing and that green prints unchanged.
#
# AND THE DISCOVERY REALLY CAN GO QUIET. Both git ls-files calls above route stderr
# to /dev/null and neither status is read, so a run outside a repository, a git that
# is not on PATH, and a canonical root that has been renamed all arrive here as an
# empty list wearing a clean tree's face. A floor rather than an exact count,
# because the canonical set gains and loses files every wave; only a collapse means
# the discovery broke. Set at roughly half of what the tree measured when this floor
# was written, so a whole runtime's worth of files can retire without a red. The
# live total is PRINTED on the pass line rather than restated here, for the reason
# 93-token-declarations.sh:105-108 gives: a count written into a comment goes stale
# on the next wave that adds a file.
MC_TRACKED_FLOOR=70

# Counted with a here-doc loop rather than `wc -l`, matching the stale-entry loop
# below. `printf '%s\n' "$TRACKED_SORTED" | wc -l` reports 1 for an empty string,
# which is the one value this floor must never read as a file.
MC_TRACKED_N=0
while IFS= read -r mc_f; do
  [ -n "$mc_f" ] || continue
  MC_TRACKED_N=$((MC_TRACKED_N + 1))
done <<MC_TRACKED_EOF
$TRACKED_SORTED
MC_TRACKED_EOF

# THE FLOOR IS JUDGED BEFORE THE COMPARISON RUNS, not after it, and the order is
# load-bearing rather than tidy. `comm` over a collapsed left side has nothing to
# say, so letting it speak first would print a verdict about the manifest when the
# defect is in the discovery. Same tie-break 91-claim-resolvers.sh:98-104 makes: a
# scan that cannot be trusted names itself and says nothing about what it read.
if [ "$MC_TRACKED_N" -lt "$MC_TRACKED_FLOOR" ]; then
  red "  FAIL [55] discovered only $MC_TRACKED_N canonical file(s) under skills/ commands/ rules/ agents/ hooks/ against a floor of $MC_TRACKED_FLOOR; the discovery collapsed rather than the manifest going right, so nothing below was ever compared against the sync manifest"
  FAILED=$((FAILED + 1))
else
  UNMIRRORED=$(comm -23 <(printf '%s\n' "$TRACKED_SORTED") <(printf '%s\n' "$MANIFEST_SORTED"))
  if [ -z "$UNMIRRORED" ]; then
    green "  ok   every skills/ commands/ rules/ agents/ hooks/ file (tracked + untracked, gitignore respected) is in MIRROR_SOURCES/CLAUDE_CODE_EXTRA, $MC_TRACKED_N compared against the manifest"
  else
    red "  FAIL canonical files absent from the sync manifest (would ship missing from dist/):"
    printf '%s\n' "$UNMIRRORED" | sed 's/^/         - /'
    FAILED=$((FAILED + 1))
  fi
fi

# Inverse direction: a manifest entry whose file no longer exists is a stale
# reference that would log a MISS during sync.
STALE=0
while IFS= read -r mf; do
  [ -n "$mf" ] || continue
  [ -f "$mf" ] || { red "  FAIL stale manifest entry (file not on disk): $mf"; STALE=$((STALE + 1)); }
done <<MANIFEST_EOF
$MANIFEST_LIST
MANIFEST_EOF
if [ "$STALE" -eq 0 ]; then
  green "  ok   no stale manifest entries (every MIRROR_SOURCES/CLAUDE_CODE_EXTRA path exists)"
else
  FAILED=$((FAILED + STALE))
fi

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

UNMIRRORED=$(comm -23 <(printf '%s\n' "$TRACKED_SORTED") <(printf '%s\n' "$MANIFEST_SORTED"))
if [ -z "$UNMIRRORED" ]; then
  green "  ok   every skills/ commands/ rules/ agents/ hooks/ file (tracked + untracked, gitignore respected) is in MIRROR_SOURCES/CLAUDE_CODE_EXTRA"
else
  red "  FAIL canonical files absent from the sync manifest (would ship missing from dist/):"
  printf '%s\n' "$UNMIRRORED" | sed 's/^/         - /'
  FAILED=$((FAILED + 1))
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

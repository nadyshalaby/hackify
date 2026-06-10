# shellcheck shell=bash

# [55] Mirror-completeness — every tracked canonical file under skills/,
# commands/, and rules/ MUST appear in the sync manifest (MIRROR_SOURCES or
# CLAUDE_CODE_EXTRA). MIRROR_SOURCES is a hand-maintained enumeration; a file
# forgotten there ships silently absent from every dist/<runtime>/ tree (bit
# the project in v0.2.6, and again in v0.4.1 when 5 companion-skill evals.json
# were found unmirrored). This check makes that failure mode loud.

yellow "[55] mirror-completeness — tracked skills/ commands/ rules/ files are all in the sync manifest"

# Single source of truth: read the manifest arrays straight from the sync
# helper, in a command-substitution subshell so its function/var definitions
# (red/green/yellow, write_*, RUNTIMES) cannot clobber this validator's own.
MANIFEST_LIST=$(
  set +u
  . scripts/sync-runtimes.d/00-helpers.sh >/dev/null 2>&1
  printf '%s\n' "${MIRROR_SOURCES[@]}" "${CLAUDE_CODE_EXTRA[@]}"
)

# The canonical source set IS the git-tracked set — using git ls-files (not
# find) excludes dist/ and __pycache__/*.pyc for free, so build artifacts can
# never masquerade as unmirrored canonical files.
#
# Exclusion: the lawkeeper recall corpus (*/evals/corpus/*) is a synthetic set of
# DELIBERATELY-violating fixtures used only to score the scanner in CI. It is a
# dev/CI artifact, never shipped — mirroring deliberately-broken code (incl. a
# planted hardcoded secret) into every dist/<runtime>/ tree would be wrong. So
# it is exempt from the must-be-mirrored invariant.
TRACKED_SORTED=$(git ls-files skills/ commands/ rules/ 2>/dev/null | grep -v '/evals/corpus/' | sort -u)
MANIFEST_SORTED=$(printf '%s\n' "$MANIFEST_LIST" | sort -u)

UNMIRRORED=$(comm -23 <(printf '%s\n' "$TRACKED_SORTED") <(printf '%s\n' "$MANIFEST_SORTED"))
if [ -z "$UNMIRRORED" ]; then
  green "  ok   every tracked skills/ commands/ rules/ file is in MIRROR_SOURCES/CLAUDE_CODE_EXTRA"
else
  red "  FAIL tracked canonical files absent from the sync manifest (would ship missing from dist/):"
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

#!/usr/bin/env bash
# Cut a tagged release: read version from plugin.json, create annotated tag,
# push main + tag. Refuses on dirty tree, missing version, or existing tag.
#
# Flags:
#   --dry-run   Print the planned tag + push commands; touch nothing.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      cat <<'USAGE'
Usage: scripts/release.sh [--dry-run]

Reads version from .claude-plugin/plugin.json, creates an annotated git tag
v<version> at HEAD, then pushes main + the tag to origin.

Refuses if:
  - working tree is dirty (git status --porcelain non-empty)
  - version field is missing or empty in plugin.json
  - tag v<version> already exists locally or on origin

  --dry-run   Print planned commands without executing.
USAGE
      exit 0
      ;;
    *)
      printf '\033[31mUnknown argument: %s\033[0m\n' "$arg" >&2
      exit 2
      ;;
  esac
done

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

PLUGIN_JSON=".claude-plugin/plugin.json"

# --- preflight checks --------------------------------------------------------
if [ ! -f "$PLUGIN_JSON" ]; then
  red "FATAL: $PLUGIN_JSON not found at repo root"
  exit 2
fi

# Extract version field — prefer jq, fall back to grep-cut for portability.
if command -v jq >/dev/null 2>&1; then
  VERSION="$(jq -r '.version // ""' "$PLUGIN_JSON")"
else
  VERSION="$(grep -E '^[[:space:]]*"version"[[:space:]]*:' "$PLUGIN_JSON" | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
fi

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  red "FATAL: version field is missing or empty in $PLUGIN_JSON"
  exit 2
fi

TAG="v$VERSION"

# Dirty working tree?
DIRTY="$(git status --porcelain)"
if [ -n "$DIRTY" ]; then
  red "FATAL: working tree is dirty. Commit or stash first."
  printf '%s\n' "$DIRTY" | head -5
  exit 2
fi

# Tag already exists locally?
if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
  red "FATAL: tag $TAG already exists locally. Bump version in $PLUGIN_JSON or delete the tag (git tag -d $TAG)."
  exit 2
fi

# Tag already exists on origin?
if git ls-remote --tags origin "$TAG" 2>/dev/null | grep -q "refs/tags/$TAG$"; then
  red "FATAL: tag $TAG already exists on origin. Bump version in $PLUGIN_JSON."
  exit 2
fi

# --- plan --------------------------------------------------------------------
yellow "Plan: tag $TAG at HEAD ($(git rev-parse --short HEAD)), then push main + tag to origin."
echo
echo "  git tag -a $TAG -m \"Release $TAG\""
echo "  git push origin main"
echo "  git push origin $TAG"
echo

if [ "$DRY_RUN" -eq 1 ]; then
  green "Dry-run complete. No tag created, no push attempted."
  exit 0
fi

# --- prompt + execute --------------------------------------------------------
printf 'Proceed? [y/N] '
read -r answer
case "$answer" in
  y|Y|yes|YES) ;;
  *)
    yellow "Aborted by user. No tag created."
    exit 0
    ;;
esac

git tag -a "$TAG" -m "Release $TAG"
green "Created tag $TAG locally."

if ! git push origin main; then
  red "FAILED: git push origin main"
  red "Local tag $TAG is still in place. Rollback with: git tag -d $TAG"
  exit 1
fi

if ! git push origin "$TAG"; then
  red "FAILED: git push origin $TAG"
  red "Local tag $TAG is still in place. Rollback with: git tag -d $TAG"
  exit 1
fi

green "Released $TAG. main + tag pushed to origin."

#!/usr/bin/env bash
# Sync canonical hackify sources into runtime-specific plugin packages.
#
# Canonical-source invariant:
#   The single source of truth is `skills/` + `commands/` + `.claude-plugin/`
#   under the repo root. This script READS ONLY from those paths and WRITES
#   ONLY under `dist/<runtime>/`. It never modifies or deletes anything in
#   the canonical source tree.
#
# Idempotency contract:
#   Running this script twice in a row must produce identical contents in
#   `dist/<runtime>/`. Each per-runtime emitter calls `prune_runtime_dist`
#   first to remove any stale skill dirs left behind by source-side renames,
#   then mirrors the canonical files fresh.
#
# Layout (since v0.3.0):
#   scripts/sync-runtimes.sh           — orchestrator (this file)
#   scripts/sync-runtimes.d/
#     00-helpers.sh                    — shared helpers + manifests
#     <runtime>.sh                     — one emitter per runtime
#
# Flags:
#   --dry-run   Print files that WOULD be written; touch no files. Used by
#               scripts/validate-dod.sh to check runtime coverage.
#
# Note: -e is intentionally omitted — like validate-dod.sh, this script
# accumulates failures into FAILED and exits non-zero at the end.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0
DRY_RUN=0
FILE_COUNT=0

# --- arg parsing -------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      cat <<'USAGE'
Usage: scripts/sync-runtimes.sh [--dry-run]

Syncs canonical hackify sources (skills/, commands/, .claude-plugin/) into
runtime-specific packages under dist/<runtime>/ for the seven supported
runtimes: claude-code, codex-cli, codex-app, gemini-cli, opencode, cursor,
copilot-cli.

  --dry-run   Print what WOULD be written; touch no files.
USAGE
      exit 0
      ;;
    *)
      printf '\033[31mUnknown argument: %s\033[0m\n' "$arg" >&2
      exit 2
      ;;
  esac
done

cd "$REPO_ROOT"

# --- source helpers + per-runtime emitters ----------------------------------
SYNC_D="$REPO_ROOT/scripts/sync-runtimes.d"
if [ ! -f "$SYNC_D/00-helpers.sh" ]; then
  printf '\033[31mFATAL: missing %s/00-helpers.sh\033[0m\n' "$SYNC_D" >&2
  exit 2
fi
# shellcheck source=scripts/sync-runtimes.d/00-helpers.sh
. "$SYNC_D/00-helpers.sh"

for runtime in "${RUNTIMES[@]}"; do
  emitter="$SYNC_D/${runtime}.sh"
  if [ ! -f "$emitter" ]; then
    red "FATAL: missing per-runtime emitter $emitter"
    exit 2
  fi
  # shellcheck source=/dev/null
  . "$emitter"
done

# --- dispatch ---------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
  yellow "Syncing canonical hackify -> dist/<runtime>/ for ${#RUNTIMES[@]} runtimes"
fi

emit_claude_code
emit_codex_cli
emit_codex_app
emit_gemini_cli
emit_opencode
emit_cursor
emit_copilot_cli

print_runtime_summary

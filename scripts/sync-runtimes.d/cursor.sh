#!/usr/bin/env bash
# Per-runtime emitter: cursor.
# Sourced by scripts/sync-runtimes.sh. Helpers come from 00-helpers.sh.

emit_cursor() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[cursor] mirror + .mdc porting notes"
  prune_runtime_dist "cursor"
  mirror_canonical_files "cursor"
  write_or_announce_heredoc "dist/cursor/MANIFEST.md" < "$SYNC_D/templates/cursor-manifest.md"
}

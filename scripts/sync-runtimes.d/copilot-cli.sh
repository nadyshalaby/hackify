#!/usr/bin/env bash
# Per-runtime emitter: copilot-cli (MANIFEST-only — no plugin model).
# Sourced by scripts/sync-runtimes.sh. Helpers come from 00-helpers.sh.

emit_copilot_cli() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[copilot-cli] MANIFEST.md only — no plugin model"
  prune_runtime_dist "copilot-cli"
  if [ ! -f "skills/hackify/SKILL.md" ]; then
    red "  MISS skills/hackify/SKILL.md — cannot build copilot-cli MANIFEST.md"
    FAILED=$((FAILED + 1))
    return 1
  fi
  write_or_announce_heredoc "dist/copilot-cli/MANIFEST.md" < <(
    cat "$SYNC_D/templates/copilot-cli-header.md" \
        skills/hackify/SKILL.md \
        "$SYNC_D/templates/copilot-cli-footer.md"
  )
}

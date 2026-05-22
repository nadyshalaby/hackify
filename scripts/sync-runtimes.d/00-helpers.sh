#!/usr/bin/env bash
# Shared helpers + canonical source manifest for sync-runtimes.sh.
#
# Sourced by the orchestrator (`scripts/sync-runtimes.sh`) AND by each
# per-runtime emitter module under `scripts/sync-runtimes.d/<runtime>.sh`.
#
# Globals this file reads (must be set by the orchestrator BEFORE sourcing
# the per-runtime modules):
#   DRY_RUN     0 or 1
#   FILE_COUNT  integer, incremented by write_*
#   FAILED      integer, incremented on errors
#
# Globals this file exports:
#   MIRROR_SOURCES       array — canonical files mirrored into every full-mirror runtime
#   CLAUDE_CODE_EXTRA    array — files only claude-code mirrors
#   RUNTIMES             array — all supported runtime names
# Functions this file exports:
#   red / green / yellow
#   write_or_announce_copy <src> <dst>
#   write_or_announce_heredoc <dst>  (reads body from stdin)
#   mirror_canonical_files <runtime>
#   prune_runtime_dist <runtime>
#   print_runtime_summary

# --- color helpers (match validate-dod.sh style) -----------------------------
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

# --- canonical source manifest ----------------------------------------------
# ATTENTION future maintainers:
#   MIRROR_SOURCES is an EXPLICIT ENUMERATION, not a glob. When you add a
#   NEW canonical source file under skills/, commands/, .claude-plugin/, or
#   rules/, you MUST add an explicit entry to MIRROR_SOURCES below — otherwise
#   the dist/<runtime>/ trees will silently ship without it. Same goes for
#   CLAUDE_CODE_EXTRA (only mirrored into dist/claude-code/).
#   This was discovered the hard way in v0.2.6 when rules/four-principles.md
#   and skills/hackify/references/anti-patterns.md were authored but
#   forgotten in MIRROR_SOURCES until the spot-check in T23.
MIRROR_SOURCES=(
  "skills/hackify/SKILL.md"
  "skills/hackify/references/anti-patterns.md"
  "skills/hackify/references/clarify-questions/README.md"
  "skills/hackify/references/clarify-questions/debug.md"
  "skills/hackify/references/clarify-questions/feature.md"
  "skills/hackify/references/clarify-questions/fix.md"
  "skills/hackify/references/clarify-questions/picking-and-combining.md"
  "skills/hackify/references/clarify-questions/refactor.md"
  "skills/hackify/references/clarify-questions/research.md"
  "skills/hackify/references/clarify-questions/revamp-redesign.md"
  "skills/hackify/references/clarify-questions/universal-preamble.md"
  "skills/hackify/references/clarify-questions/wizard-contract.md"
  "skills/hackify/references/code-rules.md"
  "skills/hackify/references/debug-when-stuck.md"
  "skills/hackify/references/finish.md"
  "skills/hackify/references/frontend-design.md"
  "skills/hackify/references/implement-and-test.md"
  "skills/hackify/references/parallel-agents/README.md"
  "skills/hackify/references/parallel-agents/phase-1-research.md"
  "skills/hackify/references/parallel-agents/phase-2.5-spec-review-a-consistency.md"
  "skills/hackify/references/parallel-agents/phase-2.5-spec-review-b-rules.md"
  "skills/hackify/references/parallel-agents/phase-2.5-spec-review-c-dependencies.md"
  "skills/hackify/references/parallel-agents/phase-3-implementation.md"
  "skills/hackify/references/parallel-agents/phase-3b-debug-evidence.md"
  "skills/hackify/references/parallel-agents/phase-4-cross-package-verification.md"
  "skills/hackify/references/parallel-agents/phase-5-aggregation.md"
  "skills/hackify/references/parallel-agents/phase-5-escalation.md"
  "skills/hackify/references/parallel-agents/phase-5-multi-review.md"
  "skills/hackify/references/parallel-agents/template-contract.md"
  "skills/hackify/references/review-and-verify.md"
  "skills/hackify/references/runtime-adapters.md"
  "skills/hackify/references/work-doc-template.md"
  "skills/hackify/evals/evals.json"
  "skills/groom/SKILL.md"
  "skills/skillsmith/SKILL.md"
  "skills/review-triage/SKILL.md"
  "skills/quick/SKILL.md"
  "skills/yolo/SKILL.md"
  "commands/summary.md"
  "rules/hard-caps.md"
  "rules/code-quality.md"
  "rules/four-principles.md"
)

# claude-code additionally mirrors the plugin manifests + the claude-code-native
# primitive directories (agents/, hooks/) so the entire repo layout is
# reproducible inside dist/claude-code/. Other runtimes never see agents/ or
# hooks/ — they fall back to the inline templates in
# `skills/hackify/references/parallel-agents/` (already in MIRROR_SOURCES).
CLAUDE_CODE_EXTRA=(
  ".claude-plugin/plugin.json"
  ".claude-plugin/marketplace.json"
  "agents/spec-reviewer-consistency.md"
  "agents/spec-reviewer-rules.md"
  "agents/spec-reviewer-dependencies.md"
  "agents/code-reviewer-security.md"
  "agents/code-reviewer-quality.md"
  "agents/code-reviewer-plan-consistency.md"
  "agents/wave-task-implementer.md"
  "hooks/hooks.json"
  "hooks/inject-hard-caps.sh"
)

# Runtime list — these substrings MUST each appear at least once in --dry-run
# output for validate-dod.sh check (a) to pass.
RUNTIMES=(claude-code codex-cli codex-app gemini-cli opencode cursor copilot-cli)

# --- file ops ---------------------------------------------------------------
write_or_announce_copy() {
  local src="$1"
  local dst="$2"
  if [ ! -f "$src" ]; then
    red "  MISS source $src (skipping)"
    FAILED=$((FAILED + 1))
    return 1
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] WOULD WRITE: %s\n' "$dst"
    FILE_COUNT=$((FILE_COUNT + 1))
    return 0
  fi
  local dst_dir
  dst_dir="$(dirname "$dst")"
  if ! mkdir -p "$dst_dir"; then
    red "  FAIL mkdir -p $dst_dir"
    FAILED=$((FAILED + 1))
    return 1
  fi
  if cp -f "$src" "$dst"; then
    FILE_COUNT=$((FILE_COUNT + 1))
  else
    red "  FAIL cp $src -> $dst"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

write_or_announce_heredoc() {
  local dst="$1"
  local content
  content="$(cat)"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] WOULD WRITE: %s\n' "$dst"
    FILE_COUNT=$((FILE_COUNT + 1))
    return 0
  fi
  local dst_dir
  dst_dir="$(dirname "$dst")"
  if ! mkdir -p "$dst_dir"; then
    red "  FAIL mkdir -p $dst_dir"
    FAILED=$((FAILED + 1))
    return 1
  fi
  if printf '%s\n' "$content" > "$dst"; then
    FILE_COUNT=$((FILE_COUNT + 1))
  else
    red "  FAIL write $dst"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

# --- mirror + prune ---------------------------------------------------------
mirror_canonical_files() {
  local runtime="$1"
  local src dst
  for src in "${MIRROR_SOURCES[@]}"; do
    dst="dist/${runtime}/${src}"
    write_or_announce_copy "$src" "$dst"
  done
}

prune_runtime_dist() {
  # Remove stale skill directories before mirroring so renamed/deleted
  # source slugs do not leave orphaned destinations.
  local runtime="$1"
  [ "$DRY_RUN" -eq 1 ] && return 0
  if [ -d "dist/${runtime}/skills" ]; then
    rm -rf "dist/${runtime}/skills"
  fi
}

# --- summary -----------------------------------------------------------------
print_runtime_summary() {
  echo
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %d runtimes, %d files total\n' "${#RUNTIMES[@]}" "$FILE_COUNT"
    [ "$FAILED" -eq 0 ] && exit 0
    red "FAILED — $FAILED errors during dry-run planning"
    exit 1
  fi
  if [ "$FAILED" -eq 0 ]; then
    green "OK — synced $FILE_COUNT files across ${#RUNTIMES[@]} runtimes"
    exit 0
  else
    red "FAILED — $FAILED errors"
    exit 1
  fi
}

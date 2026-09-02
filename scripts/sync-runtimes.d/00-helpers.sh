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
#   MIRROR_SOURCES       array, canonical files mirrored into every full-mirror runtime
#   CLAUDE_CODE_EXTRA    array, files only claude-code mirrors
#   RUNTIMES             array, all supported runtime names
# Functions this file exports:
#   red / green / yellow
#   write_or_announce_copy <src> <dst>
#   write_or_announce_heredoc <dst>  (reads body from stdin)
#   mirror_canonical_files <runtime>
#   prune_runtime_dist <runtime>
#   print_runtime_summary

# --- color helpers (canonical home: scripts/lib/colors.sh) ------------------
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/lib/colors.sh"

# --- canonical source manifest ----------------------------------------------
# ATTENTION future maintainers:
#   MIRROR_SOURCES is an EXPLICIT ENUMERATION, not a glob. When you add a
#   NEW canonical source file under skills/, commands/, .claude-plugin/, or
#   rules/, you MUST add an explicit entry to MIRROR_SOURCES below, otherwise
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
  "skills/hackify/references/clarify-questions/domain-mechanisms.md"
  "skills/hackify/references/clarify-questions/feature.md"
  "skills/hackify/references/clarify-questions/fix.md"
  "skills/hackify/references/clarify-questions/picking-and-combining.md"
  "skills/hackify/references/clarify-questions/refactor.md"
  "skills/hackify/references/clarify-questions/research.md"
  "skills/hackify/references/clarify-questions/revamp-redesign.md"
  "skills/hackify/references/clarify-questions/universal-preamble.md"
  "skills/hackify/references/clarify-questions/wizard-contract.md"
  "skills/hackify/references/code-rules.md"
  "skills/hackify/references/communication-voice.md"
  "skills/hackify/references/contention-dispatch.md"
  "skills/hackify/references/debug-when-stuck.md"
  "skills/hackify/references/design-spec/README.md"
  "skills/hackify/references/design-spec/spec-contract.md"
  "skills/hackify/references/design-spec/direction-library.md"
  "skills/hackify/references/design-spec/directions/industrial-precision.md"
  "skills/hackify/references/design-spec/directions/editorial-print.md"
  "skills/hackify/references/design-spec/directions/retro-terminal.md"
  "skills/hackify/references/design-spec/directions/warm-organic.md"
  "skills/hackify/references/design-spec/directions/brutalist-mono.md"
  "skills/hackify/references/design-spec/directions/neo-luxury.md"
  "skills/hackify/references/design-spec/directions/swiss-grid.md"
  "skills/hackify/references/design-spec/directions/data-dense.md"
  "skills/hackify/references/design-spec/directions/playful-pop.md"
  "skills/hackify/references/design-spec/directions/nordic-calm.md"
  "skills/hackify/references/design-spec/directions/cyber-neon.md"
  "skills/hackify/references/design-spec/directions/soft-depth.md"
  "skills/hackify/references/design-spec/extract-protocol.md"
  "skills/hackify/references/design-spec/catalog/README.md"
  "skills/hackify/references/design-spec/catalog/brutalist-mono.md"
  "skills/hackify/references/design-spec/catalog/cyber-neon.md"
  "skills/hackify/references/design-spec/catalog/data-dense.md"
  "skills/hackify/references/design-spec/catalog/editorial-print.md"
  "skills/hackify/references/design-spec/catalog/industrial-precision.md"
  "skills/hackify/references/design-spec/catalog/neo-luxury.md"
  "skills/hackify/references/design-spec/catalog/nordic-calm.md"
  "skills/hackify/references/design-spec/catalog/playful-pop.md"
  "skills/hackify/references/design-spec/catalog/retro-terminal.md"
  "skills/hackify/references/design-spec/catalog/soft-depth.md"
  "skills/hackify/references/design-spec/catalog/swiss-grid.md"
  "skills/hackify/references/design-spec/catalog/warm-organic.md"
  "skills/hackify/references/expert-mindset.md"
  "skills/hackify/references/finish.md"
  "skills/hackify/references/frontend-design.md"
  "skills/hackify/references/implement-and-test.md"
  "skills/hackify/references/repo-brief.md"
  "skills/hackify/references/phases/phase-1-clarify.md"
  "skills/hackify/references/phases/phase-2.5-spec-review.md"
  "skills/hackify/references/phases/phase-3-implement.md"
  "skills/hackify/references/phases/phase-4-verify.md"
  "skills/hackify/references/phases/phase-5-review.md"
  "skills/hackify/references/phases/phase-6-finish.md"
  "skills/hackify/references/parallel-agents/README.md"
  "skills/hackify/references/parallel-agents/investigation.md"
  "skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md"
  "skills/hackify/references/parallel-agents/phase-3-implementation.md"
  "skills/hackify/references/parallel-agents/phase-4-cross-package-verification.md"
  "skills/hackify/references/parallel-agents/phase-5-aggregation.md"
  "skills/hackify/references/parallel-agents/phase-5-escalation.md"
  "skills/hackify/references/parallel-agents/phase-5-multi-review-a-security.md"
  "skills/hackify/references/parallel-agents/phase-5-multi-review-b-quality-plan.md"
  "skills/hackify/references/parallel-agents/phase-5-multi-review-d-performance.md"
  "skills/hackify/references/parallel-agents/phase-5-multi-review-e-design.md"
  "skills/hackify/references/parallel-agents/phase-5-multi-review-f-coherence.md"
  "skills/hackify/references/parallel-agents/phase-5-multi-review-merged.md"
  "skills/hackify/references/parallel-agents/phase-5-refute.md"
  "skills/hackify/references/parallel-agents/template-contract.md"
  "skills/hackify/references/perf-scout.md"
  "skills/hackify/references/law-scout.md"
  "skills/hackify/references/sibling-track-rules.md"
  "skills/hackify/references/ship-gate.md"
  "skills/hackify/references/orchestration.md"
  "skills/hackify/references/phase-ledger.md"
  "skills/hackify/references/review-and-verify.md"
  "skills/hackify/references/review-scope.md"
  "skills/hackify/references/runtime-adapters.md"
  "skills/hackify/references/work-doc-artifact.md"
  "skills/hackify/references/work-doc-template.md"
  "skills/hackify/references/goal-anchor.md"
  "skills/hackify/assets/design-preview-template.html"
  "skills/hackify/evals/evals.json"
  "skills/groom/SKILL.md"
  "skills/groom/evals/evals.json"
  "skills/skillsmith/SKILL.md"
  "skills/skillsmith/evals/evals.json"
  "skills/review-triage/SKILL.md"
  "skills/review-triage/evals/evals.json"
  "skills/quick/SKILL.md"
  "skills/quick/evals/evals.json"
  "skills/codewalk/SKILL.md"
  "skills/codewalk/references/data-schema.md"
  "skills/codewalk/references/trace-rubric.md"
  "skills/codewalk/assets/viewer.html"
  "skills/codewalk/assets/viewer.js"
  "skills/codewalk/assets/viewer.css"
  "skills/codewalk/assets/serve.js"
  "skills/codewalk/assets/playbook.html"
  "skills/codewalk/assets/playbook.js"
  "skills/codewalk/assets/playbook.css"
  "skills/codewalk/assets/build-playbook.mjs"
  "skills/codewalk/evals/evals.json"
  "skills/lawkeeper/SKILL.md"
  "skills/lawkeeper/references/rule-catalog.md"
  "skills/lawkeeper/references/carve-outs.md"
  "skills/lawkeeper/references/semantic-pass.md"
  "skills/lawkeeper/references/porting-scanner.md"
  "skills/lawkeeper/assets/report-template.md"
  "skills/lawkeeper/scripts/audit_scan.py"
  "skills/lawkeeper/scripts/checks.py"
  "skills/lawkeeper/scripts/exemptions.py"
  "skills/lawkeeper/scripts/lexer.py"
  "skills/lawkeeper/scripts/test_audit.py"
  "skills/lawkeeper/scripts/test_scoping.py"
  "skills/lawkeeper/evals/evals.json"
  "commands/summary.md"
  "commands/designify.md"
  "rules/hard-caps.md"
  "rules/expert-mindset.md"
  "rules/perf-guardrails.md"
  "rules/phase-discipline.md"
  "rules/claim-integrity.md"
  "rules/code-quality.md"
  "rules/performance.md"
  "rules/test-scenarios.md"
  "rules/four-principles.md"
  "rules/plugin-map.md"
)

# claude-code additionally mirrors the plugin manifests + the claude-code-native
# primitive directories (agents/, hooks/) so the entire repo layout is
# reproducible inside dist/claude-code/. Other runtimes never see agents/ or
# hooks/, they fall back to the inline templates in
# `skills/hackify/references/parallel-agents/` (already in MIRROR_SOURCES).
CLAUDE_CODE_EXTRA=(
  ".claude-plugin/plugin.json"
  ".claude-plugin/marketplace.json"
  "agents/codebase-investigator.md"
  "agents/spec-reviewer.md"
  "agents/reviewer-security.md"
  "agents/reviewer-quality-plan.md"
  "agents/reviewer-performance.md"
  "agents/reviewer-coherence.md"
  "agents/reviewer-design.md"
  "agents/finding-refuter.md"
  "agents/reviewer.md"
  "agents/implementer.md"
  "hooks/hooks.json"
  "hooks/inject-context.sh"
  "hooks/inject_context.py"
  "hooks/block-banned-tokens.sh"
  "hooks/block-ai-attribution.sh"
  "hooks/scan_edit.py"
  "hooks/scan_bash.py"
)

# Runtime list, these substrings MUST each appear at least once in --dry-run
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
  # Remove every subtree the sync writes into, before mirroring, so a renamed or
  # deleted source leaves no orphan behind in the shipped tree.
  #
  # agents/ is pruned for a sharper reason than the rest. A leftover agent file
  # in dist/claude-code/agents/ is not dead weight, it is a REGISTERED AGENT
  # TYPE: the runtime loads whatever sits in that directory, so a retired agent
  # keeps being dispatchable for anyone installing from dist long after the
  # source stopped shipping it. v0.13.0 retired three spec reviewers and all
  # three survived the resync here until this line existed.
  #
  # THE LIST READ `skills agents` WHILE THE SYNC WROTE SIX SUBTREES. commands/,
  # hooks/, rules/ and .claude-plugin/ were mirrored fresh on every run and never
  # pruned, so a retired rule or command sat in dist/<runtime>/ indefinitely.
  # Check [56] cannot see that class of defect either, and says so in its own
  # scope line: it compares the files the sync PLANS, and an orphan is by
  # definition absent from the plan. Pruning is the only thing that reaches it.
  #
  # DERIVED FROM THE MANIFEST, NEVER RE-LISTED HERE. The set is the top-level path
  # component of every MIRROR_SOURCES and CLAUDE_CODE_EXTRA entry, so a manifest
  # that grows a seventh top-level directory is pruned without anyone editing this
  # function. A second hand-kept list is precisely how the first one went stale.
  #
  # PRUNED FOR EVERY RUNTIME, not only the one that writes a given subtree. Only
  # claude-code mirrors agents/, hooks/ and .claude-plugin/, so for the other six
  # this is a no-op on a healthy tree and a cleanup on one where something leaked
  # in. copilot-cli writes MANIFEST.md and nothing else, so every subtree under
  # dist/copilot-cli/ is an orphan by construction and all of them go.
  #
  # A manifest entry with no directory part names a file at the runtime ROOT
  # rather than a subtree, and is skipped: MANIFEST.md and GEMINI.md are rewritten
  # on every run, so they cannot go stale, and nothing here should be deleting
  # files a runtime places beside them. `.`, `..` and absolute forms are refused
  # outright, because this is an rm -rf driven by a list a human edits.
  local runtime="$1"
  [ "$DRY_RUN" -eq 1 ] && return 0
  local src top seen=" "
  for src in ${MIRROR_SOURCES[@]+"${MIRROR_SOURCES[@]}"} ${CLAUDE_CODE_EXTRA[@]+"${CLAUDE_CODE_EXTRA[@]}"}; do
    top="${src%%/*}"
    [ "$top" = "$src" ] && continue
    case "$top" in ''|.|..|/*) continue ;; esac
    case "$seen" in *" $top "*) continue ;; esac
    seen="$seen$top "
    if [ -d "dist/${runtime}/${top}" ]; then
      rm -rf "dist/${runtime}/${top}"
    fi
  done
}

# --- summary -----------------------------------------------------------------
print_runtime_summary() {
  echo
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %d runtimes, %d files total\n' "${#RUNTIMES[@]}" "$FILE_COUNT"
    [ "$FAILED" -eq 0 ] && exit 0
    red "FAILED, $FAILED errors during dry-run planning"
    exit 1
  fi
  if [ "$FAILED" -eq 0 ]; then
    green "OK, synced $FILE_COUNT files across ${#RUNTIMES[@]} runtimes"
    exit 0
  else
    red "FAILED, $FAILED errors"
    exit 1
  fi
}

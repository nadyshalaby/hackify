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
#   `dist/<runtime>/`. We use `cp -f` to overwrite and we do NOT delete any
#   user-added files in `dist/` (users may add `.DS_Store`, local notes, etc.).
#   The `dist/.gitignore` keeps everything except itself out of git.
#
# Flags:
#   --dry-run   Print the files that WOULD be written, prefixed with
#               `[dry-run] WOULD WRITE: `, plus a final summary line. Used by
#               `scripts/validate-dod.sh` to check runtime coverage without
#               touching the filesystem.
#
# Note: -e is intentionally omitted — like validate-dod.sh, this script
# accumulates failures into FAILED and exits non-zero at the end. -e would
# abort on the first non-zero command and hide the rest.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0
DRY_RUN=0

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

# --- color helpers (match validate-dod.sh style) -----------------------------
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

cd "$REPO_ROOT"

# --- canonical source manifest ----------------------------------------------
# Files we mirror into every "full mirror" runtime (everything except
# copilot-cli, which gets MANIFEST.md only). Each entry is a path relative to
# the repo root; the same relative path is used inside dist/<runtime>/.
MIRROR_SOURCES=(
  "skills/hackify/SKILL.md"
  "skills/hackify/references/clarify-questions.md"
  "skills/hackify/references/code-rules.md"
  "skills/hackify/references/debug-when-stuck.md"
  "skills/hackify/references/finish.md"
  "skills/hackify/references/frontend-design.md"
  "skills/hackify/references/implement-and-test.md"
  "skills/hackify/references/parallel-agents.md"
  "skills/hackify/references/review-and-verify.md"
  "skills/hackify/references/runtime-adapters.md"
  "skills/hackify/references/work-doc-template.md"
  "skills/hackify/evals/evals.json"
  "skills/brainstorm/SKILL.md"
  "skills/writing-skills/SKILL.md"
  "skills/receiving-code-review/SKILL.md"
  "skills/quick/SKILL.md"
  "commands/summary.md"
)

# claude-code additionally mirrors the plugin manifests so the entire repo
# layout is reproducible inside dist/claude-code/.
CLAUDE_CODE_EXTRA=(
  ".claude-plugin/plugin.json"
  ".claude-plugin/marketplace.json"
)

# Runtime list — these substrings MUST each appear at least once in --dry-run
# output for validate-dod.sh check (a) to pass.
RUNTIMES=(claude-code codex-cli codex-app gemini-cli opencode cursor copilot-cli)

# --- counters ---------------------------------------------------------------
FILE_COUNT=0

# --- file ops ---------------------------------------------------------------
write_or_announce_copy() {
  # $1 = source path (relative to REPO_ROOT)
  # $2 = destination path (relative to REPO_ROOT, always under dist/<runtime>/)
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
  # $1 = destination path (relative to REPO_ROOT)
  # stdin = content
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

# --- per-runtime sync routines ----------------------------------------------

sync_mirror() {
  # $1 = runtime name (used as dist/<runtime>/)
  local runtime="$1"
  local src dst
  for src in "${MIRROR_SOURCES[@]}"; do
    dst="dist/${runtime}/${src}"
    write_or_announce_copy "$src" "$dst"
  done
}

sync_claude_code() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[claude-code] direct mirror of skills/ + commands/ + .claude-plugin/"
  sync_mirror "claude-code"
  local src dst
  for src in "${CLAUDE_CODE_EXTRA[@]}"; do
    dst="dist/claude-code/${src}"
    write_or_announce_copy "$src" "$dst"
  done
  write_or_announce_heredoc "dist/claude-code/MANIFEST.md" <<'EOF'
# hackify — Claude Code package

This directory is a direct mirror of the canonical hackify sources, structured
exactly as Claude Code expects a plugin to be laid out.

## Install

1. Copy this directory into your project's `.claude/` directory, OR install
   the plugin via the marketplace described in `.claude-plugin/marketplace.json`.
2. Claude Code auto-discovers skills under `skills/` and slash commands under
   `commands/` on session start.

## Contents

- `skills/hackify/` — the full hackify workflow (SKILL.md + references/ + evals/)
- `skills/brainstorm/`, `skills/writing-skills/`, `skills/receiving-code-review/`,
  `skills/quick/` — companion skills referenced by the hackify workflow.
- `commands/summary.md` — the `/hackify:summary` slash command body.
- `.claude-plugin/plugin.json` + `marketplace.json` — plugin manifests.

## Source of truth

Do not edit files in this directory directly — they are regenerated by
`scripts/sync-runtimes.sh` from the canonical sources in the repo root.
EOF
}

sync_codex_cli() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[codex-cli] mirror of skills/ + commands/ with Codex CLI install notes"
  sync_mirror "codex-cli"
  write_or_announce_heredoc "dist/codex-cli/MANIFEST.md" <<'EOF'
# hackify — Codex CLI package

Codex CLI loads prompts from `~/.codex/prompts/`. Hackify is shipped as a
collection of skill markdown files plus a slash-command body.

## Install

1. Copy the contents of this directory's `skills/` and `commands/` into
   `~/.codex/prompts/hackify/` (preserve subdirectory structure).
2. Restart Codex CLI so the prompt index is rebuilt.
3. Invoke the workflow by referencing `hackify/SKILL.md` (or the per-skill
   SKILL.md for `quick`, `brainstorm`, etc.) in your prompt.

## Contents

- `skills/hackify/SKILL.md` — the universal end-to-end dev workflow.
- `skills/hackify/references/` — sub-agent and wizard prompt templates.
- `skills/hackify/evals/evals.json` — eval cases.
- `skills/brainstorm/SKILL.md`, `skills/writing-skills/SKILL.md`,
  `skills/receiving-code-review/SKILL.md`, `skills/quick/SKILL.md` — companions.
- `commands/summary.md` — body for the `/hackify:summary` shortcut (Codex CLI
  has no native slash-command registry; paste the body when needed).

## Source of truth

Regenerated by `scripts/sync-runtimes.sh` from the canonical repo sources.
EOF
}

sync_codex_app() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[codex-app] mirror of skills/ + commands/ with Codex App upload notes"
  sync_mirror "codex-app"
  write_or_announce_heredoc "dist/codex-app/MANIFEST.md" <<'EOF'
# hackify — Codex App (web) package

The Codex App accepts custom instructions and uploaded reference documents.
Hackify is shipped here as a set of markdown files you upload as project
context.

## Install

1. Open your project in the Codex App and go to Settings -> Custom
   Instructions / Project Files.
2. Upload `skills/hackify/SKILL.md` as the primary instruction set.
3. Upload everything under `skills/hackify/references/` as supporting
   reference documents (Codex App will let the model retrieve them by name).
4. Optionally upload the companion skill files (`brainstorm`,
   `writing-skills`, `receiving-code-review`, `quick`) the same way.
5. Paste the body of `commands/summary.md` into a Codex App "saved prompt"
   slot if you want a one-click summary trigger.

## Contents

Same as `dist/codex-cli/` — the canonical hackify file tree.

## Source of truth

Regenerated by `scripts/sync-runtimes.sh` from the canonical repo sources.
EOF
}

sync_gemini_cli() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[gemini-cli] mirror + root GEMINI.md pointer"
  sync_mirror "gemini-cli"
  write_or_announce_heredoc "dist/gemini-cli/GEMINI.md" <<'EOF'
# hackify — Gemini CLI entry point

Gemini CLI reads `GEMINI.md` from the project root as its primary instruction
file. This file points at the full hackify workflow and companion skills.

## Workflow

For any non-trivial task, follow `skills/hackify/SKILL.md`. It is the single
source of truth for clarification, planning, implementation, verification,
and review.

## Skills available in this package

- `skills/hackify/SKILL.md` — the universal end-to-end dev workflow.
- `skills/hackify/references/` — sub-agent templates and the wizard.
- `skills/hackify/evals/evals.json` — eval cases.
- `skills/brainstorm/SKILL.md` — early-stage idea shaping.
- `skills/writing-skills/SKILL.md` — guidance for authoring new skills.
- `skills/receiving-code-review/SKILL.md` — protocol for handling review
  feedback.
- `skills/quick/SKILL.md` — compressed-flow companion for small fixes.
- `commands/summary.md` — body of the `/hackify:summary` summary command.

## Source of truth

Regenerated by `scripts/sync-runtimes.sh` from the canonical repo sources.
Do not edit files in this directory directly.
EOF
}

sync_opencode() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[opencode] mirror + custom-mode install notes"
  sync_mirror "opencode"
  write_or_announce_heredoc "dist/opencode/MANIFEST.md" <<'EOF'
# hackify — OpenCode package

OpenCode supports custom modes via markdown files. Hackify is shipped here
as a set of mode-style markdown files plus reference documents.

## Install (custom mode)

1. Open OpenCode -> Modes -> New custom mode (or edit `~/.opencode/modes/`).
2. Create a mode named `hackify` and paste the body of
   `skills/hackify/SKILL.md` as the mode prompt.
3. Add the reference files from `skills/hackify/references/` as attachments
   or auxiliary context (OpenCode will load them on demand when the mode
   prompt references them).
4. Repeat for the companion skills (`quick`, `brainstorm`,
   `writing-skills`, `receiving-code-review`) if you want them available as
   separate modes.

## Contents

Mirror of the canonical hackify file tree (same as codex-cli).

## Source of truth

Regenerated by `scripts/sync-runtimes.sh` from the canonical repo sources.
EOF
}

sync_cursor() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[cursor] mirror + .mdc porting notes"
  sync_mirror "cursor"
  write_or_announce_heredoc "dist/cursor/MANIFEST.md" <<'EOF'
# hackify — Cursor package

Cursor rules live under `.cursor/rules/` as `.mdc` files. v0.2.0 does NOT
ship an automatic markdown -> `.mdc` adapter; the markdown files here are
copy-paste-ready bodies you can wrap in a minimal `.mdc` frontmatter.

## Install (manual port)

1. For each skill SKILL.md you want to use, create a corresponding `.mdc`
   under `.cursor/rules/`, for example `.cursor/rules/hackify.mdc`.
2. Add minimal Cursor rule frontmatter at the top of each `.mdc`:

       ---
       description: hackify — universal end-to-end dev workflow
       globs: "**/*"
       alwaysApply: false
       ---

3. Paste the full body of the corresponding `SKILL.md` below the
   frontmatter.
4. Repeat for any references under `skills/hackify/references/` that you
   want Cursor to load eagerly (most can stay markdown and be referenced on
   demand from the main rule).

## Why no auto-adapter

Cursor's `.mdc` schema is small but version-sensitive and globs require
project-specific tuning. v0.2.0 keeps the port manual to avoid shipping a
brittle adapter that breaks on Cursor schema updates. A scripted adapter is
a candidate for a future minor version.

## Contents

Mirror of the canonical hackify file tree, ready for manual porting.

## Source of truth

Regenerated by `scripts/sync-runtimes.sh` from the canonical repo sources.
EOF
}

sync_copilot_cli() {
  [ "$DRY_RUN" -eq 0 ] && yellow "[copilot-cli] MANIFEST.md only — no plugin model"
  # Copilot CLI gets MANIFEST.md only, with a copy of the hackify SKILL.md
  # body embedded so users can paste it manually.
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] WOULD WRITE: %s\n' "dist/copilot-cli/MANIFEST.md"
    FILE_COUNT=$((FILE_COUNT + 1))
    return 0
  fi
  if [ ! -f "skills/hackify/SKILL.md" ]; then
    red "  MISS skills/hackify/SKILL.md — cannot build copilot-cli MANIFEST.md"
    FAILED=$((FAILED + 1))
    return 1
  fi
  if ! mkdir -p "dist/copilot-cli"; then
    red "  FAIL mkdir -p dist/copilot-cli"
    FAILED=$((FAILED + 1))
    return 1
  fi
  {
    cat <<'HEADER'
# hackify — GitHub Copilot CLI package

GitHub Copilot CLI has NO plugin / skill / custom-instruction model as of
hackify v0.2.0. You cannot register hackify as a reusable workflow; the
only integration path is to paste the SKILL.md body into a Copilot CLI
prompt manually each time you start a task.

## Disclaimer

This runtime is supported on a best-effort basis. If GitHub ships a plugin
or persistent-instructions model in the future, hackify will add proper
integration; until then, treat this MANIFEST.md as the only deliverable for
copilot-cli and copy the body below into your Copilot CLI session as
needed.

## How to use

1. Open a Copilot CLI session in your project.
2. Paste everything between the `===== BEGIN SKILL.md =====` and
   `===== END SKILL.md =====` markers below as your initial prompt.
3. Follow the workflow steps the SKILL.md prescribes (clarification gate,
   plan gate, implementation, verification, review).
4. For the companion skills (`quick`, `brainstorm`, etc.) repeat the same
   paste-on-demand pattern with their SKILL.md bodies from the canonical
   `skills/<name>/SKILL.md`.

===== BEGIN SKILL.md =====
HEADER
    cat skills/hackify/SKILL.md
    cat <<'FOOTER'
===== END SKILL.md =====

## Source of truth

Regenerated by `scripts/sync-runtimes.sh` from the canonical repo sources.
FOOTER
  } > "dist/copilot-cli/MANIFEST.md"
  if [ $? -eq 0 ]; then
    FILE_COUNT=$((FILE_COUNT + 1))
  else
    red "  FAIL write dist/copilot-cli/MANIFEST.md"
    FAILED=$((FAILED + 1))
  fi
}

# --- main -------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
  yellow "Syncing canonical hackify -> dist/<runtime>/ for ${#RUNTIMES[@]} runtimes"
fi

sync_claude_code
sync_codex_cli
sync_codex_app
sync_gemini_cli
sync_opencode
sync_cursor
sync_copilot_cli

echo
if [ "$DRY_RUN" -eq 1 ]; then
  printf '[dry-run] %d runtimes, %d files total\n' "${#RUNTIMES[@]}" "$FILE_COUNT"
  if [ "$FAILED" -eq 0 ]; then
    exit 0
  else
    red "FAILED — $FAILED errors during dry-run planning"
    exit 1
  fi
fi

if [ "$FAILED" -eq 0 ]; then
  green "OK — synced $FILE_COUNT files across ${#RUNTIMES[@]} runtimes"
  exit 0
else
  red "FAILED — $FAILED errors"
  exit 1
fi

#!/usr/bin/env bash
# hackify v0.4.2 — PreToolUse (Write|Edit|MultiEdit) ban-blocker.
#
# Blocks edits that INTRODUCE zero-tolerance banned tokens into JS/TS source:
#   - lint/type suppressions (@ts-ignore, @ts-nocheck, eslint-disable,
#     biome-ignore; @ts-expect-error outside test files)
#   - non-null `!` assertions, empty `catch {}`, bare `throw new Error(`
#
# Net-new only: a banned line already present in the file (Write) or in the
# replaced old_string (Edit/MultiEdit) is grandfathered — the hook blocks what
# you ADD, not pre-existing violations on lines you carry past untouched.
#
# Detection delegates to hooks/scan_edit.py, which reuses lawkeeper's tested
# lexer + check regexes — so a token inside a string or comment never
# false-fires. Scope is JS/TS files only.
#
# Per-path escape hatch: list a path (literal or glob, repo-relative or
# absolute) in <project-root>/.claude/hooks/ban-allowlist to exempt it.
#
# Block contract: exit 2 + reason on stderr blocks the tool call.
# Fail-open contract: any INTERNAL failure (no jq/python3, unparseable input,
# missing detector) exits 0 — a hook bug must never wedge the user's editing.
# `set -e` is intentionally NOT used.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
INPUT=''
TOOL=''
FILE=''
BASE_TMP=''
trap 'rm -f "$BASE_TMP" 2>/dev/null' EXIT

is_jsts() {
  case "$1" in
    *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.mts | *.cts) return 0 ;;
    *) return 1 ;;
  esac
}

is_test() {
  case "$1" in
    *.test.* | *.spec.* | */__tests__/* | */test/* | */tests/*) return 0 ;;
    *) return 1 ;;
  esac
}

allowlisted() {
  local f="$1" root allow rel line
  root="$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null)" || return 1
  allow="$root/.claude/hooks/ban-allowlist"
  [ -f "$allow" ] || return 1
  rel="${f#"$root"/}"
  while IFS= read -r line; do
    case "$line" in '' | \#*) continue ;; esac
    # allowlist lines are glob patterns matched against the path, so $line is
    # intentionally left unquoted here
    case "$rel" in $line) return 0 ;; esac
    case "$f" in $line) return 0 ;; esac
  done <"$allow"
  return 1
}

# Candidate text being written, by tool (reads globals INPUT/TOOL).
extract_candidate() {
  case "$TOOL" in
    Write) printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null ;;
    Edit) printf '%s' "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null ;;
    MultiEdit) printf '%s' "$INPUT" | jq -r '[.tool_input.edits[]?.new_string] | join("\n")' 2>/dev/null ;;
  esac
}

# Prior text to grandfather against: replaced old_string(s) for Edit/MultiEdit.
extract_old_text() {
  case "$TOOL" in
    Edit) printf '%s' "$INPUT" | jq -r '.tool_input.old_string // empty' 2>/dev/null ;;
    MultiEdit) printf '%s' "$INPUT" | jq -r '[.tool_input.edits[]?.old_string] | join("\n")' 2>/dev/null ;;
    *) printf '' ;;
  esac
}

message_for() {
  case "$1" in
    suppression.eslint | suppression.biome) printf 'lint suppression — fix the root cause' ;;
    suppression.ts-ignore | suppression.ts-nocheck) printf 'type suppression — fix the type error' ;;
    suppression.ts-expect-error) printf '@ts-expect-error outside a test file' ;;
    ban.empty-catch) printf 'empty catch block — handle or rethrow' ;;
    ban.non-null) printf 'non-null `!` assertion in production code' ;;
    ban.bare-error) printf 'bare `throw new Error(` — use a domain exception (or allowlist this path)' ;;
    *) printf 'banned token' ;;
  esac
}

# Filter detector findings through the file-level carve-outs, building the
# human-readable block report. Echoes the report (empty = nothing to block).
build_report() {
  local file="$1" findings="$2" rule lineno report=''
  while IFS=$'\t' read -r rule lineno; do
    [ -n "$rule" ] || continue
    if [ "$rule" = 'suppression.ts-expect-error' ] && is_test "$file"; then
      continue
    fi
    report="${report}  - $(message_for "$rule") (line ${lineno})"$'\n'
  done <<EOF
$findings
EOF
  printf '%s' "$report"
}

main() {
  command -v jq >/dev/null 2>&1 || exit 0
  [ -n "$PLUGIN_ROOT" ] || exit 0
  command -v python3 >/dev/null 2>&1 || exit 0

  INPUT="$(cat)"
  TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
  case "$TOOL" in Write | Edit | MultiEdit) ;; *) exit 0 ;; esac
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
  { [ -n "$FILE" ] && is_jsts "$FILE"; } || exit 0
  allowlisted "$FILE" && exit 0

  local text base='' findings report
  text="$(extract_candidate)"
  [ -n "$text" ] || exit 0
  if [ "$TOOL" = 'Write' ]; then
    [ -f "$FILE" ] && base="$FILE"
  elif BASE_TMP="$(mktemp 2>/dev/null)"; then
    extract_old_text >"$BASE_TMP"
    base="$BASE_TMP"
  fi

  findings="$(printf '%s' "$text" | python3 "$PLUGIN_ROOT/hooks/scan_edit.py" "$PLUGIN_ROOT/skills/lawkeeper/scripts" "$base" 2>/dev/null)" || exit 0
  [ -n "$findings" ] || exit 0
  report="$(build_report "$FILE" "$findings")"
  [ -n "$report" ] || exit 0

  printf 'hackify ban-blocker blocked this edit to %s:\n%s\nFix the above, or add the path to .claude/hooks/ban-allowlist for an intentional exception.\n' "$FILE" "$report" >&2
  exit 2
}

main

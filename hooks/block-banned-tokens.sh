#!/usr/bin/env bash
# hackify v0.4.2 — PreToolUse (Write|Edit|Bash) ban-blocker.
#
# Blocks edits that INTRODUCE zero-tolerance banned tokens into JS/TS source:
#   - lint/type suppressions (@ts-ignore, @ts-nocheck, eslint-disable,
#     biome-ignore; @ts-expect-error outside test files)
#   - non-null `!` assertions, empty `catch {}`, bare `throw new Error(`
#
# Write/Edit: net-new only — a banned line already present in the file (Write)
# or the replaced old_string (Edit) is grandfathered.
# Bash: also scans source written via a heredoc or echo/printf redirect to a
# JS/TS file (the shell path that would otherwise bypass Write/Edit). It does
# NOT see content produced by cp/mv/sed/awk — those are not statically
# knowable and fall through.
#
# Detection delegates to scan_edit.py / scan_bash.py, which reuse lawkeeper's
# tested lexer + check regexes — so a token inside a string or comment never
# false-fires. Scope is JS/TS files only.
#
# Per-path escape hatch: list a path (literal or glob) in
# <project-root>/.claude/hooks/ban-allowlist to exempt it.
#
# Block contract: exit 2 + reason on stderr blocks the tool call.
# Fail-open contract: any INTERNAL failure (no jq/python3, unparseable input)
# exits 0 — a hook bug must never wedge the user's editing.
# `set -e` is intentionally NOT used.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
SCANNER_DIR="${PLUGIN_ROOT}/skills/lawkeeper/scripts"
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

emit_block() {
  printf 'hackify ban-blocker blocked %s:\n%s\nFix the above, or add the path to .claude/hooks/ban-allowlist for an intentional exception.\n' "$1" "$2" >&2
  exit 2
}

# Write/Edit: scan the candidate text, grandfathering lines already present.
handle_file_edit() {
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
  { [ -n "$FILE" ] && is_jsts "$FILE"; } || exit 0
  allowlisted "$FILE" && exit 0

  local text base='' findings rule lineno report_body=''
  if [ "$TOOL" = 'Write' ]; then
    text="$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)"
    [ -f "$FILE" ] && base="$FILE"
  else
    text="$(printf '%s' "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null)"
    BASE_TMP="$(mktemp 2>/dev/null)" && printf '%s' "$INPUT" | jq -r '.tool_input.old_string // empty' 2>/dev/null >"$BASE_TMP" && base="$BASE_TMP"
  fi
  [ -n "$text" ] || exit 0

  findings="$(printf '%s' "$text" | python3 "$PLUGIN_ROOT/hooks/scan_edit.py" "$SCANNER_DIR" "$base" 2>/dev/null)" || exit 0
  [ -n "$findings" ] || exit 0
  while IFS=$'\t' read -r rule lineno; do
    [ -n "$rule" ] || continue
    [ "$rule" = 'suppression.ts-expect-error' ] && is_test "$FILE" && continue
    report_body="${report_body}  - $(message_for "$rule") (line ${lineno})"$'\n'
  done <<EOF
$findings
EOF
  [ -n "$report_body" ] || exit 0
  emit_block "this edit to $FILE" "$report_body"
}

# Bash: scan source written via heredoc / echo / printf to a JS/TS file.
handle_bash() {
  local cmd findings rule target report_body=''
  cmd="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
  [ -n "$cmd" ] || exit 0
  printf '%s' "$cmd" | grep -qE '(>>?|\btee\b)[^|;&]*\.(ts|tsx|js|jsx|mjs|cjs|mts|cts)' || exit 0

  findings="$(printf '%s' "$cmd" | python3 "$PLUGIN_ROOT/hooks/scan_bash.py" "$SCANNER_DIR" 2>/dev/null)" || exit 0
  [ -n "$findings" ] || exit 0
  while IFS=$'\t' read -r rule target; do
    [ -n "$rule" ] || continue
    allowlisted "$target" && continue
    [ "$rule" = 'suppression.ts-expect-error' ] && is_test "$target" && continue
    report_body="${report_body}  - $(message_for "$rule") in ${target}"$'\n'
  done <<EOF
$findings
EOF
  [ -n "$report_body" ] || exit 0
  emit_block "this Bash write" "$report_body"
}

main() {
  command -v jq >/dev/null 2>&1 || exit 0
  [ -n "$PLUGIN_ROOT" ] || exit 0
  command -v python3 >/dev/null 2>&1 || exit 0

  INPUT="$(cat)"
  TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
  case "$TOOL" in
    Write | Edit) handle_file_edit ;;
    Bash) handle_bash ;;
    *) exit 0 ;;
  esac
}

main

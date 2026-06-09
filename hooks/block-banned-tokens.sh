#!/usr/bin/env bash
# hackify v0.5.0 — PreToolUse (Write|Edit) ban-blocker.
#
# Blocks edits that introduce zero-tolerance banned tokens into JS/TS source:
#   - lint/type suppressions (@ts-ignore, @ts-nocheck, eslint-disable,
#     biome-ignore; @ts-expect-error outside test files)
#   - non-null `!` assertions, empty `catch {}`, bare `throw new Error(`
#
# Detection delegates to hooks/scan_edit.py, which reuses lawkeeper's tested
# lexer + check regexes — so a token inside a string or comment never
# false-fires. Scope is JS/TS files only.
#
# Per-path escape hatch: list a path (literal or glob, repo-relative or
# absolute) in <project-root>/.claude/hooks/ban-allowlist to exempt it (e.g.
# standalone browser assets where a bare `Error` is acceptable).
#
# Block contract: exit 2 + reason on stderr blocks the tool call.
# Fail-open contract: any INTERNAL failure (no jq/python3, unparseable input,
# missing detector) exits 0 — a hook bug must never wedge the user's editing.
# `set -e` is intentionally NOT used.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

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
    # intentionally unquoted here
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

# Filter raw detector findings through the file-level carve-outs, building the
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

  local input tool file text findings report
  input="$(cat)"
  tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
  case "$tool" in Write | Edit) ;; *) exit 0 ;; esac

  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
  text="$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)"
  { [ -n "$file" ] && is_jsts "$file"; } || exit 0
  [ -n "$text" ] || exit 0
  allowlisted "$file" && exit 0

  findings="$(printf '%s' "$text" | python3 "$PLUGIN_ROOT/hooks/scan_edit.py" "$PLUGIN_ROOT/skills/lawkeeper/scripts" 2>/dev/null)" || exit 0
  [ -n "$findings" ] || exit 0

  report="$(build_report "$file" "$findings")"
  [ -n "$report" ] || exit 0

  printf 'hackify ban-blocker blocked this edit to %s:\n%s\nFix the above, or add the path to .claude/hooks/ban-allowlist for an intentional exception.\n' "$file" "$report" >&2
  exit 2
}

main

#!/usr/bin/env bash
# hackify v0.4.2. PreToolUse (Write|Edit|Bash) ban-blocker.
#
# Blocks edits that INTRODUCE zero-tolerance banned tokens into JS/TS source:
#   - lint/type suppressions (@ts-ignore, @ts-nocheck, eslint-disable,
#     biome-ignore; @ts-expect-error outside test files)
#   - non-null `!` assertions, empty `catch {}`, bare `throw new Error(`
#   - hardcoded secrets/credentials (AWS/GitHub/Slack/Google keys, PEM private
#     keys, assigned api-key/password/token literals), the only critical-
#     severity rule, so blocking it before it reaches disk matters most
#
# Write/Edit: net-new only, a banned line already present in the file (Write)
# or the replaced old_string (Edit) is grandfathered.
# Bash: also scans content written via a heredoc or echo/printf redirect to a
# screened file (the shell path that would otherwise bypass Write/Edit). It
# does NOT see content produced by cp/mv/sed/awk, those are not statically
# knowable and fall through.
#
# TWO SCOPES, TWO LENSES.
#   JS/TS files get the full rule set above.
#   MARKDOWN files get the hardcoded-secret rule ALONE. hackify publishes the
#   work-doc at docs/work/<slug>.md as a shareable page, so a credential pasted
#   into one becomes a hosted link; that is the exposure this half screens.
#   The other two families are deliberately NOT applied to prose. Suppression
#   tokens are spelled literally in doctrine on purpose, so the full set reports
#   a document for DESCRIBING the ban: measured over this repo's 25 archived
#   work-docs, it produced 26 findings, all of that shape and none a secret. And
#   the semantic bans read lexer-masked text, where the mask is a JS/TS lexer
#   with nothing meaningful to say about prose. The reasoning is argued once, on
#   scan_edit.detect_secrets.
#
# NOT screened: the publish itself. The exposure is the moment the page is
# hosted, and no PreToolUse matcher covers that on the six runtimes with no hook
# facility, so this screens the WRITE instead, on every path hackify itself uses
# to put content in the doc. A credential that arrives some other way (a human's
# own editor, cp/mv/sed) reaches the page unscreened by this hook.
#
# Detection delegates to scan_edit.py / scan_bash.py, which reuse lawkeeper's
# tested lexer + check regexes, so a token inside a string or comment never
# false-fires.
#
# Per-path escape hatch: list a path (literal or glob) in
# <project-root>/.claude/hooks/ban-allowlist to exempt it.
#
# Block contract: exit 2 + reason on stderr blocks the tool call.
# Fail-open contract: any INTERNAL failure (no jq/python3, unparseable input)
# exits 0, a hook bug must never wedge the user's editing.
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

is_markdown() {
  case "$1" in
    *.md | *.markdown) return 0 ;;
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
    suppression.eslint | suppression.biome) printf 'lint suppression, fix the root cause' ;;
    suppression.ts-ignore | suppression.ts-nocheck) printf 'type suppression, fix the type error' ;;
    suppression.ts-expect-error) printf '@ts-expect-error outside a test file' ;;
    ban.empty-catch) printf 'empty catch block, handle or rethrow' ;;
    ban.non-null) printf 'non-null `!` assertion in production code' ;;
    ban.bare-error) printf 'bare `throw new Error(`, use a domain exception (or allowlist this path)' ;;
    sec.hardcoded-secret) printf 'hardcoded secret/credential, move it to an env var or secret store' ;;
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
  [ -n "$FILE" ] || exit 0

  # A lens is ALWAYS passed, never an empty shell array: bash 3.2 ships on macOS
  # and cannot expand `"${arr[@]}"` for an empty array under `set -u`.
  local lens='--all-rules'
  if is_markdown "$FILE"; then
    lens='--secrets-only'
  elif ! is_jsts "$FILE"; then
    exit 0
  fi
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

  findings="$(printf '%s' "$text" | python3 "$PLUGIN_ROOT/hooks/scan_edit.py" "$SCANNER_DIR" "$base" "$lens" 2>/dev/null)" || exit 0
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
  # Cheap pre-filter before invoking python. Portable ERE only: `\b` is a GNU
  # extension that BSD/macOS grep -E does not guarantee, so `tee` gets explicit
  # word boundaries (line start or a non-word char on each side) instead.
  #
  # FED BY REDIRECTION FROM A PROCESS SUBSTITUTION, NOT BY `<<<`. $cmd is a whole
  # Bash command with its heredocs inline and routinely carries credentials, and
  # bash 3.2 backs a here-string with a real file under /var/tmp (mode 1777,
  # shared, kept across reboots). This form puts nothing on disk and, unlike the
  # pipe that stood here before 51ecd00, cannot hand grep's SIGPIPE back as the
  # hook's exit status if anyone ever adds `set -o pipefail` above. The long note
  # over creates_a_commit in block-ai-attribution.sh carries the measurements.
  #
  # `md|markdown` is here so the shell is not a way round the Write-side
  # markdown screen. No right boundary, so `.mdx` also reaches python and finds
  # nothing; over-triggering a cheap pre-filter is the safe direction.
  grep -qE '(>>?|(^|[^[:alnum:]_])tee([^[:alnum:]_]|$))[^|;&]*\.(ts|tsx|js|jsx|mjs|cjs|mts|cts|md|markdown)' \
    < <(printf '%s\n' "$cmd") || exit 0

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

#!/usr/bin/env bash
# Tests for hooks/block-banned-tokens.sh + hooks/scan_edit.py.
# Exit 0 if all cases pass. Run: bash hooks/test_block_banned_tokens.sh
#
# Convention: expected exit 2 = the edit is BLOCKED; 0 = ALLOWED.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/hooks/block-banned-tokens.sh"
export CLAUDE_PLUGIN_ROOT="$ROOT"
PASS=0
FAIL=0

mkjson() {
  # $1 tool (Write|Edit), $2 file_path, $3 text. Emits a PreToolUse payload.
  local key='content'
  [ "$1" = 'Edit' ] && key='new_string'
  jq -nc --arg tn "$1" --arg fp "$2" --arg t "$3" --arg k "$key" \
    '{tool_name:$tn, tool_input:({file_path:$fp} + {($k):$t})}'
}

check() {
  # $1 name, $2 expected exit, $3 JSON payload.
  local got
  printf '%s' "$3" | bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$2" ]; then
    PASS=$((PASS + 1))
    printf 'ok   %s (exit %s)\n' "$1" "$got"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL %s: want %s got %s\n' "$1" "$2" "$got"
  fi
}

check 'clean ts allowed'              0 "$(mkjson Write /tmp/x/clean.ts 'const a: number = 1')"
check 'eslint-disable blocked'        2 "$(mkjson Write /tmp/x/a.js '// eslint-disable-next-line')"
check 'biome-ignore blocked'          2 "$(mkjson Write /tmp/x/a.ts '// biome-ignore lint: x')"
check 'ts-ignore blocked'             2 "$(mkjson Write /tmp/x/a.ts '// @ts-ignore')"
check 'bare error blocked'            2 "$(mkjson Write /tmp/x/a.js 'throw new Error("x")')"
check 'bare error in string allowed'  0 "$(mkjson Write /tmp/x/a.js 'const m = "throw new Error(x)"')"
check 'bare error in comment allowed' 0 "$(mkjson Write /tmp/x/a.js '// throw new Error(x)')"
check 'non-null blocked'              2 "$(mkjson Write /tmp/x/a.ts 'const y = obj!.prop')"
check 'prefix negation allowed'       0 "$(mkjson Write /tmp/x/a.js 'if (!res.ok) doThing()')"
check 'empty catch blocked'           2 "$(mkjson Write /tmp/x/a.ts 'try { f() } catch (e) {}')"
check 'py scope-skip allowed'         0 "$(mkjson Write /tmp/x/a.py '# eslint-disable')"
check 'md scope-skip allowed'         0 "$(mkjson Write /tmp/x/a.md '@ts-ignore')"
check 'expect-error in test allowed'  0 "$(mkjson Write /tmp/x/a.test.ts '// @ts-expect-error bad')"
check 'expect-error non-test blocked' 2 "$(mkjson Write /tmp/x/a.ts '// @ts-expect-error')"
check 'edit new_string blocked'       2 "$(mkjson Edit /tmp/x/a.ts 'const y = obj!.prop')"
check 'allowlisted path allowed'      0 "$(mkjson Write "$ROOT/skills/codewalk/assets/viewer.js" 'throw new Error("x")')"

printf '\n%s/%s passed\n' "$PASS" "$((PASS + FAIL))"
[ "$FAIL" -eq 0 ]

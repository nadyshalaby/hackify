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

# On-disk fixture for the Write net-new (grandfathering) cases. The bare Error
# on the last line is "pre-existing"; a Write that keeps it must be allowed.
TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
EXISTING=$'export const NAME = "app"\nfunction load(d) {\n  if (!d) throw new Error("missing")\n}'
printf '%s' "$EXISTING" >"$TMPD/existing.js"

mkwrite() { jq -nc --arg fp "$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}'; }
mkedit() { jq -nc --arg fp "$1" --arg o "$2" --arg n "$3" '{tool_name:"Edit", tool_input:{file_path:$fp, old_string:$o, new_string:$n}}'; }
mkmulti() { jq -nc --arg fp "$1" --arg o "$2" --arg n "$3" '{tool_name:"MultiEdit", tool_input:{file_path:$fp, edits:[{old_string:$o, new_string:$n}]}}'; }

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

# --- suppressions (raw text) ---
check 'eslint-disable blocked'        2 "$(mkwrite /tmp/x/a.js '// eslint-disable-next-line')"
check 'biome-ignore blocked'          2 "$(mkwrite /tmp/x/a.ts '// biome-ignore lint: x')"
check 'ts-ignore blocked'             2 "$(mkwrite /tmp/x/a.ts '// @ts-ignore')"
check 'expect-error in test allowed'  0 "$(mkwrite /tmp/x/a.test.ts '// @ts-expect-error bad')"
check 'expect-error non-test blocked' 2 "$(mkwrite /tmp/x/a.ts '// @ts-expect-error')"

# --- semantic bans (lexer-masked) ---
check 'clean ts allowed'              0 "$(mkwrite /tmp/x/clean.ts 'const a: number = 1')"
check 'bare error blocked'            2 "$(mkwrite /tmp/x/a.js 'throw new Error("x")')"
check 'bare error in string allowed'  0 "$(mkwrite /tmp/x/a.js 'const m = "throw new Error(x)"')"
check 'bare error in comment allowed' 0 "$(mkwrite /tmp/x/a.js '// throw new Error(x)')"
check 'non-null blocked'              2 "$(mkwrite /tmp/x/a.ts 'const y = obj!.prop')"
check 'prefix negation allowed'       0 "$(mkwrite /tmp/x/a.js 'if (!res.ok) doThing()')"
check 'empty catch blocked'           2 "$(mkwrite /tmp/x/a.ts 'try { f() } catch (e) {}')"

# --- scope + allowlist ---
check 'py scope-skip allowed'         0 "$(mkwrite /tmp/x/a.py '# eslint-disable')"
check 'md scope-skip allowed'         0 "$(mkwrite /tmp/x/a.md '@ts-ignore')"
check 'allowlisted path allowed'      0 "$(mkwrite "$ROOT/skills/codewalk/assets/viewer.js" 'throw new Error("x")')"

# --- net-new only (#7): grandfather pre-existing tokens ---
check 'write keeps pre-existing allowed' 0 "$(mkwrite "$TMPD/existing.js" "$(printf 'export const NAME = "renamed"\nfunction load(d) {\n  if (!d) throw new Error("missing")\n}')")"
check 'write introduces new blocked'     2 "$(mkwrite "$TMPD/existing.js" "$(printf 'export const NAME = "app"\nfunction load(d) {\n  if (!d) throw new Error("missing")\n  throw new Error("brand new")\n}')")"
check 'edit new_string blocked'          2 "$(mkedit /tmp/x/a.ts 'const z = 1' 'const y = obj!.prop')"
check 'edit carryover allowed'           0 "$(mkedit /tmp/x/a.ts 'const y = obj!.prop' "$(printf 'const y = obj!.prop\nconst z = 1')")"

# --- MultiEdit (#8): intercepted, with carryover grandfathering ---
check 'multiedit introduces blocked'  2 "$(mkmulti /tmp/x/a.ts 'const z = 1' 'throw new Error("x")')"
check 'multiedit carryover allowed'   0 "$(mkmulti /tmp/x/a.ts 'throw new Error("x")' 'throw new Error("x")')"

printf '\n%s/%s passed\n' "$PASS" "$((PASS + FAIL))"
[ "$FAIL" -eq 0 ]

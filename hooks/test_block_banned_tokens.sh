#!/usr/bin/env bash
# Tests for hooks/block-banned-tokens.sh + hooks/scan_edit.py + hooks/scan_bash.py.
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
mkbash() { jq -nc --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}'; }

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

# --- hardcoded secrets (#3): edit-time reuse of lawkeeper's check_secrets ---
check 'secret in ts blocked'          2 "$(mkwrite /tmp/x/a.ts 'const k = "AKIA1234567890ABCDEF"')"
check 'env-name not a secret allowed' 0 "$(mkwrite /tmp/x/a.ts 'const apiKey = "MY_PUBLIC_ENV_VAR"')"
check 'secret via heredoc blocked'    2 "$(mkbash "$(printf 'cat > cfg.ts <<EOF\nconst k = "AKIA1234567890ABCDEF"\nEOF')")"
check 'secret on allowlisted allowed' 0 "$(mkwrite "$ROOT/skills/codewalk/assets/viewer.js" 'const k = "AKIA1234567890ABCDEF"')"

# --- scope + allowlist ---
check 'py scope-skip allowed'         0 "$(mkwrite /tmp/x/a.py '# eslint-disable')"
check 'md scope-skip allowed'         0 "$(mkwrite /tmp/x/a.md '@ts-ignore')"
check 'allowlisted path allowed'      0 "$(mkwrite "$ROOT/skills/codewalk/assets/viewer.js" 'throw new Error("x")')"

# --- net-new only (#7): grandfather pre-existing tokens ---
check 'write keeps pre-existing allowed' 0 "$(mkwrite "$TMPD/existing.js" "$(printf 'export const NAME = "renamed"\nfunction load(d) {\n  if (!d) throw new Error("missing")\n}')")"
check 'write introduces new blocked'     2 "$(mkwrite "$TMPD/existing.js" "$(printf 'export const NAME = "app"\nfunction load(d) {\n  if (!d) throw new Error("missing")\n  throw new Error("brand new")\n}')")"
check 'edit new_string blocked'          2 "$(mkedit /tmp/x/a.ts 'const z = 1' 'const y = obj!.prop')"
check 'edit carryover allowed'           0 "$(mkedit /tmp/x/a.ts 'const y = obj!.prop' "$(printf 'const y = obj!.prop\nconst z = 1')")"

# --- Bash (#10): source written via heredoc / echo / printf to a JS/TS file ---
check 'bash heredoc to ts blocked'    2 "$(mkbash "$(printf 'cat > app.ts <<EOF\nthrow new Error("x")\nEOF')")"
check 'bash heredoc clean allowed'    0 "$(mkbash "$(printf 'cat > app.ts <<EOF\nexport const a = 1\nEOF')")"
check 'bash heredoc to non-js allowed' 0 "$(mkbash "$(printf 'cat > notes.md <<EOF\nthrow new Error("x")\nEOF')")"
check 'bash echo redirect blocked'    2 "$(mkbash "echo 'const y = obj!.prop' > a.ts")"
check 'bash heredoc to allowlisted ok' 0 "$(mkbash "$(printf 'cat > %s/skills/codewalk/assets/viewer.js <<EOF\nthrow new Error("x")\nEOF' "$ROOT")")"
check 'bash non-write allowed'        0 "$(mkbash 'grep "throw new Error" app.ts')"

# --- Bash tee pre-filter: portable ERE (no `\b` GNU-ism), tee writes seen ---
check 'bash tee at start blocked'     2 "$(mkbash "$(printf 'tee app.ts <<EOF\nthrow new Error("x")\nEOF')")"
check 'bash piped tee blocked'        2 "$(mkbash "$(printf 'printf x | tee app.ts <<EOF\nthrow new Error("x")\nEOF')")"
check 'bash latee.ts not a tee write' 0 "$(mkbash 'cat latee.ts')"

# --- multi-heredoc: each body pairs with its OWN redirect target ---
# Banned token only in the SECOND heredoc; that target is allowlisted, so the
# hook must allow. Misattributing the finding to the first (non-allowlisted)
# target would wrongly block.
check 'bash 2nd heredoc owns finding (allowlisted) ok' 0 "$(mkbash "$(printf 'cat > /tmp/x/first.ts <<EOF\nexport const ok = 1\nEOF\ncat > %s/skills/codewalk/assets/viewer.js <<TAG\nthrow new Error("x")\nTAG' "$ROOT")")"

# --- superset pairing (Q1-A): a redirect AFTER the heredoc body must block ---
# Brace group / subshell / loop place the JS/TS redirect behind the body; the
# body count no longer matches a target seen BEFORE it, so the scanner must
# check every body against ALL candidate targets instead of bypassing.
check 'bash brace-group redirect-after-body blocked' 2 "$(mkbash "$(printf '{ cat <<EOF\nthrow new Error("x")\nEOF\n} > app.ts')")"
check 'bash subshell redirect-after-body blocked'    2 "$(mkbash "$(printf '( cat <<EOF\nthrow new Error("x")\nEOF\n) > app.ts')")"
check 'bash loop redirect-after-body blocked'        2 "$(mkbash "$(printf 'while read x; do cat <<EOF\nthrow new Error("x")\nEOF\ndone > app.ts')")"

# --- direct scanner checks: heredoc attribution + the exit-0 fail-open contract ---
SCANNER_DIR="$ROOT/skills/lawkeeper/scripts"
# Deterministic decode strictness regardless of host locale (a C locale would
# give stdin surrogateescape and hide the undecodable-stdin case).
export PYTHONIOENCODING=utf-8:strict

# The finding must cite the second target, the one whose heredoc carries the token.
MULTI_CMD="$(printf 'cat > two-a.ts <<EOF\nexport const ok = 1\nEOF\ncat > two-b.ts <<TAG\nthrow new Error("x")\nTAG')"
MULTI_OUT="$(printf '%s' "$MULTI_CMD" | python3 "$ROOT/hooks/scan_bash.py" "$SCANNER_DIR" 2>/dev/null)"
if printf '%s\n' "$MULTI_OUT" | grep -q 'two-b\.ts$' && ! printf '%s\n' "$MULTI_OUT" | grep -q 'two-a\.ts'; then
  PASS=$((PASS + 1)); printf 'ok   multi-heredoc finding cites its own target\n'
else
  FAIL=$((FAIL + 1)); printf 'FAIL multi-heredoc finding cites its own target: got [%s]\n' "$MULTI_OUT"
fi

# Scanner dir whose modules import fine but whose detector raises at call
# time: an internal detector bug must fail OPEN (exit 0, no output), per the
# scanners' "Exit 0 always" contract.
BADSCAN="$TMPD/badscan"
mkdir -p "$BADSCAN"
cat >"$BADSCAN/lexer.py" <<'PY'
def mask_source(text):
    raise RuntimeError('synthetic detector bug: fail-open probe')
PY
cat >"$BADSCAN/checks.py" <<'PY'
import re

EMPTY_CATCH_RE = BARE_ERROR_RE = NON_NULL_RE = re.compile('x^')


class FileContext:
    def __init__(self, name, text):
        pass

    def check_secrets(self):
        return []
PY

expect_silent_zero() {
  # $1 name, $2 scanner basename, $3 scanner-dir arg. Feed scanner stdin via
  # redirection (`< <(printf …)`), NOT a pipe, a pipe would run this function
  # in a subshell and lose the PASS/FAIL counters.
  # Fail-open contract: exit 0 AND empty stdout.
  local out rc
  out="$(python3 "$ROOT/hooks/$2" "$3" 2>/dev/null)"
  rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
    PASS=$((PASS + 1)); printf 'ok   %s (exit 0, silent)\n' "$1"
  else
    FAIL=$((FAIL + 1)); printf 'FAIL %s: want exit 0 + empty stdout, got exit %s out [%s]\n' "$1" "$rc" "$out"
  fi
}

expect_silent_zero 'scan_edit fail-open on detector bug' scan_edit.py "$BADSCAN" < <(printf 'const a = 1')
expect_silent_zero 'scan_bash fail-open on detector bug' scan_bash.py "$BADSCAN" < <(printf 'cat > a.ts <<EOF\nconst a = 1\nEOF')
expect_silent_zero 'scan_edit fail-open on undecodable stdin' scan_edit.py "$SCANNER_DIR" < <(printf '\377\376 const x = 1')
expect_silent_zero 'scan_edit fail-open on missing scanner dir' scan_edit.py "$TMPD/no-such-dir" < <(printf 'const a = 1')

printf '\n%s/%s passed\n' "$PASS" "$((PASS + FAIL))"
[ "$FAIL" -eq 0 ]

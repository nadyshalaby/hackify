#!/usr/bin/env bash
# Tests for hooks/block-ai-attribution.sh.
# Exit 0 if all cases pass. Run: bash hooks/test_block_ai_attribution.sh
#
# Convention, same as test_block_banned_tokens.sh: expected exit 2 = the
# command is BLOCKED; 0 = ALLOWED.
#
# THE TRAILERS ARE ASSEMBLED FROM PARTS, never spelled out. Check [81] scans
# hooks/ for those exact strings, so a test that writes one literally reds the
# validator for quoting the thing it tests. Same reason the hook's own patterns
# are split around their separators. Do not "clean these up".

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/hooks/block-ai-attribution.sh"
export CLAUDE_PLUGIN_ROOT="$ROOT"
PASS=0
FAIL=0

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

CO='Co-Authored-By:'
SESSION='Claude-Session:'
GEN='Generated with'

co_trailer() { printf '%s Claude <noreply@%s.com>' "$CO" 'anthropic'; }
session_line() { printf '%s https://claude.ai/code/session_01ABC' "$SESSION"; }
gen_footer() { printf '%s [Claude Code](https://claude.com/claude-code)' "$GEN"; }

# A message file the hook has to open to see, which is the whole point of the
# -F branch: the trailer never appears in the command text at all.
printf 'fix: thing\n\n%s\n' "$(co_trailer)" >"$TMPD/dirty-msg.txt"
printf 'fix: thing\n\nJust a normal message.\n' >"$TMPD/clean-msg.txt"

mkbash() { jq -nc --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}'; }
mkwrite() { jq -nc --arg c "$1" '{tool_name:"Write", tool_input:{file_path:"/tmp/x.txt", content:$c}}'; }

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

# --- blocked: the trailer in the command text ---
check 'co-author trailer via -m' 2 \
  "$(mkbash "git commit -m \"fix: thing

$(co_trailer)\"")"
check 'co-author trailer lower-cased' 2 \
  "$(mkbash "git commit -m 'fix: thing

$(printf '%s claude <x@y.z>' 'co-authored-by:')'")"
check 'session link' 2 "$(mkbash "git commit -m \"fix

$(session_line)\"")"
check 'generated-with footer' 2 "$(mkbash "git commit -m \"fix

$(gen_footer)\"")"
check 'co-authored by AI phrasing' 2 "$(mkbash 'git commit -m "fix

Co-authored by AI"')"
check 'robot emoji' 2 "$(mkbash 'git commit -m "fix

🤖 shipped"')"
check 'heredoc fed to -F -' 2 \
  "$(mkbash "git commit -F - <<'MSG'
fix: thing

$(co_trailer)
MSG")"

# --- blocked: the other commit-creating verbs ---
check 'annotated tag' 2 "$(mkbash "git tag -a v1.0.0 -m \"Release

$(co_trailer)\"")"
check 'gh pr create body' 2 "$(mkbash "gh pr create --title x --body \"does a thing

$(gen_footer)\"")"
check 'gh pr edit body' 2 "$(mkbash "gh pr edit 4 --body \"$(session_line)\"")"
check 'gh release create notes' 2 "$(mkbash "gh release create v1 --notes \"$(co_trailer)\"")"

# --- blocked: the trailer only on disk, never in the command ---
check 'message file carries it' 2 "$(mkbash "git commit -F $TMPD/dirty-msg.txt")"

# --- blocked: a global option sitting between the program and its verb ---
check 'git -C <dir> commit' 2 \
  "$(mkbash "git -C /srv/app commit -m \"fix

$(co_trailer)\"")"
check 'git --no-pager commit' 2 \
  "$(mkbash "git --no-pager commit -m \"fix

$(co_trailer)\"")"
check 'gh -R owner/name pr create' 2 \
  "$(mkbash "gh -R owner/name pr create --title x --body \"$(gen_footer)\"")"
check 'commit after a && in a chain' 2 \
  "$(mkbash "cd /srv/app && git commit -m \"fix

$(co_trailer)\"")"

# --- allowed: ordinary work ---
check 'plain commit' 0 "$(mkbash 'git commit -m "fix: reject expired tokens"')"
check 'amend with a clean message' 0 "$(mkbash 'git commit --amend -m "fix: clearer wording"')"
check 'clean message file' 0 "$(mkbash "git commit -F $TMPD/clean-msg.txt")"
check 'human co-author' 0 \
  "$(mkbash "git commit -m \"fix

$CO Jane Doe <jane@example.com>\"")"
check 'git status' 0 "$(mkbash 'git status --porcelain')"
check 'tag listing' 0 "$(mkbash "git tag --list 'v0.1*'")"

# --- allowed: the read-only audit, which is how you FIND the thing ---
check 'log piped to grep' 0 "$(mkbash "git log --format='%B' | grep -i 'co-author'")"
check 'grep the tree for trailers' 0 "$(mkbash "grep -rn '$CO' .")"
check 'log searched for the trailer itself' 0 \
  "$(mkbash "git log --all --grep '$(co_trailer)'")"
check 'show a commit that already carries one' 0 \
  "$(mkbash "git show HEAD | grep -i '$CO'")"

# --- allowed: out of scope by design ---
check 'not a commit verb' 0 "$(mkbash "echo '$(co_trailer)' > $TMPD/notes.txt")"
check 'wrong tool' 0 "$(mkwrite "$(co_trailer)")"

# --- the block must SAY what it found, or the user cannot act on it ---
REASON="$(printf '%s' "$(mkbash "git commit -m \"x

$(co_trailer)\"")" | bash "$HOOK" 2>&1 >/dev/null)"
if printf '%s' "$REASON" | grep -q 'co-author trailer naming an AI assistant'; then
  PASS=$((PASS + 1)); printf 'ok   block message names the finding\n'
else
  FAIL=$((FAIL + 1)); printf 'FAIL block message did not name the finding: %s\n' "$REASON"
fi

printf '\n[test_block_ai_attribution] %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

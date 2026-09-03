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
if [[ "$REASON" == *'co-author trailer naming an AI assistant'* ]]; then
  PASS=$((PASS + 1)); printf 'ok   block message names the finding\n'
else
  FAIL=$((FAIL + 1)); printf 'FAIL block message did not name the finding: %s\n' "$REASON"
fi


# --- the screened text must never transit a file on disk (T44) --------------
# These hooks screen a commit or PR body and a whole Bash command with its
# heredocs inline. Under a bash that backs a here-string with a REAL FILE, and
# `/usr/bin/env bash` on macOS is bash 3.2, which backs one under /var/tmp at
# mode 1777, shared by every user on the box and kept across reboots, a
# `grep ... <<<"$body"` writes exactly the content worth protecting onto a shared
# filesystem, while `< <(printf ...)` writes nothing. No validator check can tell
# those two spellings apart, and [84] actively prescribes the here-string, so
# THIS CASE IS THE ONLY THING IN THE TREE that reddens if the hook is "tidied"
# back. A later bash backs a short here-string with a pipe instead, which is why
# the positive control below redirects from a real file and not from a
# here-string: the probe's ability to SEE disk must not depend on the platform,
# or the whole case passes for free wherever it does not.
#
# It shadows `grep` on PATH with a stub reporting whether its OWN stdin is a
# regular file, which a real file is and a pipe or /dev/fd is not.
DISK_LOG="$TMPD/stdin-kind.log"
STUB="$TMPD/stub"
export DISK_LOG
mkdir -p "$STUB"
cat >"$STUB/grep" <<'STUBEOF'
#!/usr/bin/env bash
[ -f /dev/stdin ] && printf 'DISK\n' >>"$DISK_LOG"
exec /usr/bin/grep "$@"
STUBEOF
chmod +x "$STUB/grep"

saw_disk() { [ -s "$DISK_LOG" ] && printf 'disk' || printf 'clean'; }
probe() { : >"$DISK_LOG"; PATH="$STUB:$PATH" bash -c "$1" >/dev/null 2>&1; }
say_eq() {
  # $1 name, $2 want, $3 got.
  if [ "$2" = "$3" ]; then
    PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"
  else
    FAIL=$((FAIL + 1)); printf 'FAIL %s: want %s got %s\n' "$1" "$2" "$3"
  fi
}

# THE CONTROLS RUN FIRST, because a probe that cannot report `disk` would pass
# this case no matter what the hook does, which is the unfalsifiable shape the
# validator's own [0b] refuses one layer up. The positive control redirects from
# a REAL FILE, which is a regular file on stdin under every bash. A here-string
# is NOT that control: asserting one outcome for it asserts the platform rather
# than the probe, and every Linux run then loses the control it depends on.
PROBE_FILE="$TMPD/probe-on-disk"
export PROBE_FILE
printf 'probe body\n' >"$PROBE_FILE"
probe 'grep -q x < "$PROBE_FILE"'
say_eq 'stdin probe control: a redirect from a real file IS on disk' disk "$(saw_disk)"
probe 'grep -q x < <(printf "probe body\n")'
say_eq 'stdin probe control: a redirected process substitution is NOT' clean "$(saw_disk)"

# Which spelling leaks is a property of the bash running the hook, so this one is
# CLASSIFIED and never asserted. Where a here-string is file-backed the hook's
# `< <(printf ...)` is load-bearing; where it is pipe-backed that hazard is
# dormant on this platform. The assertion further down holds either way.
probe 'grep -q x <<<"probe body"'
case "$(saw_disk)" in
  disk) printf 'note here-strings are FILE-backed under this bash, the <<< hazard is live\n' ;;
  *)    printf 'note here-strings are PIPE-backed under this bash, the <<< hazard is dormant\n' ;;
esac

# The hook on a payload it MUST refuse, so one run asserts both halves: the ban
# still fires, and nothing it read to decide that reached a file.
: >"$DISK_LOG"
DISK_PAYLOAD="$(mkbash "git commit -m \"fix: thing

$(co_trailer)\"")"
printf '%s' "$DISK_PAYLOAD" | PATH="$STUB:$PATH" bash "$HOOK" >/dev/null 2>&1
DISK_RC=$?
DISK_SAW="$(saw_disk)"
say_eq 'trailer still BLOCKED while the stdin probe watches' 2 "$DISK_RC"
say_eq 'no screened commit body reached a file on disk' clean "$DISK_SAW"

printf '\n[test_block_ai_attribution] %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

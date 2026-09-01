#!/usr/bin/env bash
# hackify. PreToolUse (Bash) attribution-blocker.
#
# Refuses a Bash command that would CREATE a commit, tag, PR or release whose
# message carries AI attribution: a co-author trailer naming an assistant, a
# session link back to a chat, a generated-with footer, a robot emoji.
#
# WHY THIS IS A HOOK AND NOT PROSE. The rule it guards is one the runtime
# harness actively pushes the other way: Claude Code ships a standing
# instruction to end every commit message with a co-author trailer and a
# session link. So the failure mode is not a careless edit, it is a default
# reasserting itself at the exact moment a commit is written, and the model
# gets to decide which instruction wins. Check [81] catches the rule walking
# out of this plugin's own text; it cannot see your repository. Prose lost this
# argument in real projects, repeatedly, which is what put this file here.
# A hook does not have to be persuaded.
#
# SCOPE, deliberately narrow. Only commands that CREATE something: git commit,
# git tag, gh pr create, gh pr edit, gh release create. A read-only audit such
# as `git log | grep -i co-author` is untouched, which matters because that is
# how you check an existing repository for the very thing this blocks.
#
# The message text is taken from the command itself (covering -m, --message=,
# and a heredoc fed to `-F -`) and from any file named by -F / --file /
# --body-file, read off disk, which is the route a message written to a file
# first would otherwise take. NOT covered: a path held in a shell variable,
# which is not statically knowable, so it falls through. Fail-open by design.
#
# KNOWN FALSE POSITIVE, stated rather than hidden: a human co-author genuinely
# named Claude, or a PR body that legitimately links a chat transcript, is
# refused too. Land that one from your own terminal, outside the agent.
#
# Block contract: exit 2 + reason on stderr blocks the tool call.
# Fail-open contract: any INTERNAL failure (no jq, unparseable input, an
# unreadable file) exits 0. A hook bug must never wedge the user's work.
# `set -e` is intentionally NOT used, for the same reason.

set -u

# A commit message is prose, not a payload. Anything past this is not a message
# and reading it whole would make a git hook the slowest thing in the session.
MAX_BODY_BYTES=65536

# One `<extended-regex><TAB><reason>` per line, screened case-insensitively.
# EVERY REGEX IS SPLIT AROUND ITS OWN SEPARATOR ON PURPOSE, so this file never
# contains the literal trailer it bans. Check [81] scans hooks/ for those exact
# strings, and a blocker that reds the validator for quoting what it blocks is
# the same self-defeating shape [81]'s own header warns about. Do not "tidy"
# a bracket class or a `[[:space:]]+` back into a plain space.
PATTERNS=$(
  cat <<'PATEOF'
co-authored-by:[^[:cntrl:]]*(claude|anthropic|openai|chatgpt|copilot|gemini|codeium|codex|cursor|assistant)	a co-author trailer naming an AI assistant
claude-session:[[:space:]]*http	a session link back to a chat
generated[[:space:]]+with[[:space:]]+\[?(claude|chatgpt|copilot|cursor|codex)	a generated-with footer
co-authored[[:space:]]+by[[:space:]]+ai	a co-authored-by-AI line
https?://claude\.ai/	a link back to a chat session
🤖	a robot emoji
PATEOF
)

# Global options between the program and its verb, so `git -C repo commit` and
# `gh -R owner/name pr create` are recognised. An intermediate word must be
# option-shaped, optionally followed by one value. THAT RESTRICTION IS THE WHOLE
# SAFETY MARGIN: allow any word here and `git log --grep <trailer>` starts
# matching, which would refuse the one command you would run to audit a repo for
# a trailer that already landed. `log` does not begin with a dash, so it cannot
# be skipped, and the audit stays out of scope.
OPTS='([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*'

# WHY EVERY SCREENED STRING GOES IN THROUGH `< <(printf ...)` AND NEVER A
# HERE-STRING. Both forms exist to keep a writer's SIGPIPE out of the reader's
# exit status, the race check [84] bans, and the here-string is the form [84]
# prescribes. It is the wrong form HERE, because of WHAT these hooks screen.
#
# `/usr/bin/env bash` resolves to bash 3.2.57 on macOS, which backs every
# here-string with a REAL FILE. Measured on this machine: `[ -f /dev/stdin ]` is
# true under `<<<` and false under a pipe, and lsof named the backing file
# /private/var/tmp/sh-thd-<n>. That is /var/tmp, mode 1777, shared by every user
# on the box and kept across reboots, not the per-user $TMPDIR. bash opens it
# 0600 and unlinks it before the reader runs, so it cannot be opened by name for
# long, but the bytes reach a shared filesystem either way.
#
# THE BYTES ARE THE PART THAT MATTERS. This hook screens a commit or PR body up
# to MAX_BODY_BYTES, and both hooks screen a whole Bash command with its
# heredocs inline; a command line routinely carries credentials. Screening
# content is not a licence to persist it. CWE-377 names the insecure-temp-file
# class, though bash's own 0600-and-unlink creation is not the insecure part
# here; the transit is, which is nearer CWE-226.
#
# PROCESS SUBSTITUTION HAS BOTH SAFE PROPERTIES AT ONCE, and it is not a dodge
# around [84]. The writer is not a pipeline stage, so its status never reaches
# `$?` and `set -o pipefail` cannot surface its SIGPIPE. Measured on a 106KB
# body: the pipe form returns 0 with pipefail off and 141 with it on, while this
# form returns 0 under both, so it is strictly safer than the pipe these lines
# carried before 51ecd00. `printf '%s\n'` reproduces the newline `<<<` appends,
# so grep reads md5-identical bytes and no matcher semantics move.
# test_block_banned_tokens.sh:139 already reaches for this form, for the sibling
# reason that a pipe would run its caller in a subshell.
#
# DO NOT "TIDY" THIS BACK TO `<<<`. [84] lists two safe forms and says it does
# not add a third; this is that third, [84] cannot see the difference, and the
# grep-stub case at the end of this hook's test suite is the only thing that
# reddens if it is reverted.

# Only the verbs that write history or publish. `git tag` is here whether or not
# it carries -m: an annotated tag with no -m opens an editor, which this cannot
# see anyway, and a `git tag --list` carries no attribution so it never trips.
creates_a_commit() {
  grep -qE \
    "(^|[^[:alnum:]_-])(git${OPTS}[[:space:]]+(commit|tag)|gh${OPTS}[[:space:]]+(pr[[:space:]]+(create|edit)|release[[:space:]]+create))([^[:alnum:]_-]|\$)" \
    < <(printf '%s\n' "$1")
}

# Paths named by -F / --file / --body-file, so a message written to a file is
# read rather than waved through. A bare `-` is stdin, whose content is already
# inside the command text as a heredoc, so it is dropped here.
message_files() {
  printf '%s' "$1" \
    | grep -oE '(-F|--file|--body-file)[=[:space:]]+[^[:space:];|&]+' \
    | sed -E 's/^(-F|--file|--body-file)[=[:space:]]+//' \
    | grep -v '^-$'
}

# The command plus every message file it names, as one screenable blob.
gather_text() {
  local cmd="$1" path
  printf '%s\n' "$cmd"
  while IFS= read -r path; do
    [ -n "$path" ] && [ -f "$path" ] || continue
    head -c "$MAX_BODY_BYTES" -- "$path" 2>/dev/null
    printf '\n'
  done <<EOF
$(message_files "$cmd")
EOF
}

# One report line per pattern that fires, so the reason names what to remove.
findings_for() {
  local text="$1" regex reason report=''
  while IFS=$'\t' read -r regex reason; do
    [ -n "$regex" ] || continue
    # Redirected from a process substitution, never a here-string: see the
    # note above creates_a_commit. This is the body, and it is the largest
    # thing either hook screens.
    grep -qiE -- "$regex" < <(printf '%s\n' "$text") 2>/dev/null \
      && report="${report}  - ${reason}"$'\n'
  done <<EOF
$PATTERNS
EOF
  printf '%s' "$report"
}

main() {
  command -v jq >/dev/null 2>&1 || exit 0
  local input tool cmd report
  input="$(cat)"
  tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
  [ "$tool" = 'Bash' ] || exit 0
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
  [ -n "$cmd" ] || exit 0
  creates_a_commit "$cmd" || exit 0

  report="$(findings_for "$(gather_text "$cmd")")"
  [ -n "$report" ] || exit 0
  printf 'hackify attribution-blocker refused this command:\n%sThe git author field already records who wrote it, and a chat link is a dead link to everyone but you. Strip it and run the command again.\n' \
    "$report" >&2
  exit 2
}

main

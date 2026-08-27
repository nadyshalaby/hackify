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

# Only the verbs that write history or publish. `git tag` is here whether or not
# it carries -m: an annotated tag with no -m opens an editor, which this cannot
# see anyway, and a `git tag --list` carries no attribution so it never trips.
creates_a_commit() {
  printf '%s' "$1" | grep -qE \
    "(^|[^[:alnum:]_-])(git${OPTS}[[:space:]]+(commit|tag)|gh${OPTS}[[:space:]]+(pr[[:space:]]+(create|edit)|release[[:space:]]+create))([^[:alnum:]_-]|\$)"
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
    printf '%s' "$text" | grep -qiE -- "$regex" 2>/dev/null \
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

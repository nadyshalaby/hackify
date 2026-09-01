# shellcheck shell=bash

yellow "[7] README line bounds"
check_line_range "README.md" 250 450

yellow "[8] SKILL.md frontmatter"
if head -10 skills/hackify/SKILL.md | grep -q '^name: hackify' && \
   head -10 skills/hackify/SKILL.md | grep -q '^description:'; then
  green "  ok   SKILL.md has name + description frontmatter"
else
  red "  FAIL SKILL.md missing required frontmatter (name, description)"
  FAILED=$((FAILED + 1))
fi

# === Template Contract conformance (v0.2.x subdir layout) ===
PA_DIR="skills/hackify/references/parallel-agents"
CQ_DIR="skills/hackify/references/clarify-questions"
RAV_FILE="skills/hackify/references/review-and-verify.md"

# Files inside PA_DIR that are NOT dispatchable sub-agent templates and so
# are excluded from checks [9]/[10]/[11]/[12]/[15].
PA_NON_TEMPLATE=(README.md template-contract.md phase-5-aggregation.md)

# Single-template files: each file body IS one sub-agent template. Both lists
# below carry a hand-written size bound under the [9] header, for the reason
# argued there; add or retire a template here and that number moves with it.
PA_BUILD_FILES=(
  "$PA_DIR/investigation.md"
  "$PA_DIR/phase-3-implementation.md"
  "$PA_DIR/phase-4-cross-package-verification.md"
)
PA_REVIEW_SINGLE_FILES=(
  "$PA_DIR/phase-2.5-spec-reviewer.md"
  "$PA_DIR/phase-5-escalation.md"
  "$PA_DIR/phase-5-multi-review-a-security.md"
  "$PA_DIR/phase-5-multi-review-b-quality-plan.md"
  "$PA_DIR/phase-5-multi-review-d-performance.md"
  "$PA_DIR/phase-5-multi-review-e-design.md"
  "$PA_DIR/phase-5-multi-review-f-coherence.md"
  "$PA_DIR/phase-5-multi-review-merged.md"
  "$PA_DIR/phase-5-refute.md"
)

# There is no multi-template file any more. phase-5-multi-review.md carried A, B
# and C under h2 headings and needed its own extractor here, plus a matching
# blind spot in scripts/sync_agent_mirrors.py, which splits on the FIRST fenced
# block and so could never enforce a file holding three. D moved out in v0.9.0
# and B in v0.11.0, both times because a new input pushed the file past the
# 500-LOC cap; v0.13.0 folded C into B and gave A its own file, which retired
# the extractor and made every agent mirror enforceable at once.

# Wizard bank files in CQ_DIR (exclude README + contract + picking guide).
CQ_BANK_FILES=(
  "$CQ_DIR/universal-preamble.md"
  "$CQ_DIR/feature.md"
  "$CQ_DIR/fix.md"
  "$CQ_DIR/refactor.md"
  "$CQ_DIR/revamp-redesign.md"
  "$CQ_DIR/debug.md"
  "$CQ_DIR/research.md"
)

CANONICAL_SEVERITY='If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important.'
ALLOWLIST='OWASP|SANS|NIST|RFC|WCAG|ARIA|Clean Code|SOLID|12-Factor|Conventional Commits|Semantic Versioning|Keep a Changelog|ISO 8601|Postel|expand-then-contract'

# Extract the OUTPUT subsection out of a template body. Terminates on the
# next bolded section header (`**SOMETHING**`).
output_subsection() {
  echo "$1" | awk '/\*\*OUTPUT\*\*/{flag=1; next} flag && /^\*\*/ {flag=0} flag'
}

# Verify a template body carries the 6 always-required anchors.
#
# `[[ == ]]` AND NOT `echo "$body" | grep -qF`, the whole reason this file stopped
# flaking. See the long note above check_role in 00-helpers.sh for the mechanism;
# the short version is that `$body` is up to 40KB, a macOS pipe is not always big
# enough to swallow it in one write, and `grep -q` exiting on the first match
# leaves `echo` dead of SIGPIPE with `pipefail` reporting 141 as the pipeline's
# status. Every anchor here is a newline-free literal, so a whole-string substring
# test and grep -F's per-line one agree on every input.
check_template_anchors() {
  local body="$1"
  local label="$2"
  local ok=1
  for req in "**ROLE**" "**INPUTS**" "**OBJECTIVE**" "**METHOD**" "**VERIFICATION**" "**OUTPUT**"; do
    if [[ "$body" != *"$req"* ]]; then
      red "  FAIL $label missing $req"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  [ "$ok" = "1" ] && green "  ok   $label conforms (ROLE/INPUTS/OBJECTIVE/METHOD/VERIFICATION/OUTPUT)"
}

# Assert SEVERITY presence (review template) or absence (build/research).
#
# THE PIPE WAS WORSE HERE THAN ANYWHERE ELSE IN THIS FILE, and it is worth saying
# why rather than just copying the fix. Everywhere else a SIGPIPE turns a present
# marker into a false RED, which is loud and gets looked at. This predicate reads
# the SAME status to decide an assertion that in `build` mode expects the marker
# to be ABSENT, so a 141 lands in the `else` branch and prints "correctly omits
# SEVERITY". The only input that can trigger it is a build template that really
# does carry `**SEVERITY**`, which is precisely the defect this check exists to
# catch: the check could intermittently green over the one thing it is for. A
# substring test has no second process and so no second exit status to confuse
# with grep's.
check_severity_presence() {
  local body="$1"
  local label="$2"
  local mode="$3"  # "review" or "build"
  if [[ "$body" == *"**SEVERITY**"* ]]; then
    if [ "$mode" = "review" ]; then
      green "  ok   $label has SEVERITY (review template)"
    else
      red "  FAIL $label is build/research but has SEVERITY (should be omitted)"
      FAILED=$((FAILED + 1))
    fi
  else
    if [ "$mode" = "review" ]; then
      red "  FAIL $label is review-type but missing SEVERITY"
      FAILED=$((FAILED + 1))
    else
      green "  ok   $label correctly omits SEVERITY"
    fi
  fi
}

yellow "[9] template structural conformance (per-file in $PA_DIR)"

# THE SIZES ARE HAND-WRITTEN BESIDE THE LISTS, the shape [40], [74], [77] and
# [80] all use and the one this file was the odd one out on: a bound read back
# out of a list cannot police that list, so the number is written a SECOND time
# and moving it is the deliberate act that records a template arriving or
# retiring. THIS FILE IS WHY THE CONVENTION EXISTS RATHER THAN AN ILLUSTRATION
# OF IT. 0.17.1 dropped one entry from PA_BUILD_FILES, correctly, because the
# template had been deleted, and FOUR checks left the run with it: every one of
# [9], [10], [12] and [15] iterates these arrays, so a file that stops being
# listed stops being checked by all four at once. The [0b] ok-line total went
# 1377 to 1371 and only the floor's slack absorbed the drop, which is exactly
# what a WRONG deletion would have looked like from the outside.
#
# THE COUNTS SIT UNDER THIS HEADER RATHER THAN AT THE ARRAYS, which is the one
# place this diverges from [74]. Nothing prints a per-fragment banner, so an ok
# line emitted where the arrays are defined would file itself under [8], the
# SKILL.md frontmatter check, and a reader chasing a red would look in the wrong
# block. The arrays carry a pointer comment instead.
check_list_size "${#PA_BUILD_FILES[@]}" 3 "the [9]/[10]/[12]/[15] build-template set"
check_list_size "${#PA_REVIEW_SINGLE_FILES[@]}" 9 "the [9]/[10]/[11]/[12]/[15] review-template set"
# `$(<"$f")` AND `${f##*/}`, NOT `cat` AND `basename`, which is the rule [13]
# already records at its own globs further down and the reason it is worth
# repeating here: these four loops run over the same two arrays, so every element
# added to them costs two more forks in each. Both spellings are bash's own and
# both sit on the same line the fork sat on, so nothing here trades a line of the
# 500-LOC budget for the saving. Catalog `perf.process.fork-for-builtin`,
# rules/performance.md:175.
for f in "${PA_BUILD_FILES[@]}" "${PA_REVIEW_SINGLE_FILES[@]}"; do
  check_template_anchors "$(<"$f")" "${f##*/}"
done

yellow "[10] SEVERITY conditional (review templates have it; build/research don't)"
for f in "${PA_REVIEW_SINGLE_FILES[@]}"; do
  check_severity_presence "$(<"$f")" "${f##*/}" "review"
done
for f in "${PA_BUILD_FILES[@]}"; do
  check_severity_presence "$(<"$f")" "${f##*/}" "build"
done
# Also the adjudication reviewer in review-and-verify.md
for req in "**ROLE**" "**INPUTS**" "**OBJECTIVE**" "**METHOD**" "**VERIFICATION**" "**SEVERITY**" "**OUTPUT**"; do
  if grep -qF "$req" "$RAV_FILE"; then
    green "  ok   review-and-verify.md has $req"
  else
    red "  FAIL review-and-verify.md missing $req"
    FAILED=$((FAILED + 1))
  fi
done

yellow "[11] canonical SEVERITY phrase in every review template"
for f in "${PA_REVIEW_SINGLE_FILES[@]}"; do
  if grep -qF -- "$CANONICAL_SEVERITY" "$f"; then
    green "  ok   ${f##*/} has canonical SEVERITY line"
  else
    red "  FAIL ${f##*/} missing canonical SEVERITY line"
    FAILED=$((FAILED + 1))
  fi
done
if grep -qF -- "$CANONICAL_SEVERITY" "$RAV_FILE"; then
  green "  ok   review-and-verify.md has canonical SEVERITY line"
else
  red "  FAIL review-and-verify.md missing canonical SEVERITY line"
  FAILED=$((FAILED + 1))
fi

yellow "[12] ROLE substance check (5 elements per template)"
for f in "${PA_BUILD_FILES[@]}" "${PA_REVIEW_SINGLE_FILES[@]}"; do
  check_role "$(<"$f")" "${f##*/}"
done
check_role "$(<"$RAV_FILE")" "review-and-verify.md"

yellow "[13] no leaked absolute paths in template/bank bodies (PA_DIR/*.md, CQ_DIR/*.md, review-and-verify.md)"
# Skip non-template files (README, the contract itself, aggregation guidance)
# the contract document literally lists `/Users/` etc. as forbidden tokens.
is_pa_non_template() {
  local base="$1"
  for skip in "${PA_NON_TEMPLATE[@]}"; do
    [ "$base" = "$skip" ] && return 0
  done
  return 1
}

# THE FILE SET, BUILT ONCE. It used to be re-globbed and re-filtered once per
# banned path, and `basename` was a fork per file per path. Globs and ${f##*/} are
# shell builtins; the two together were 72 of the ~130 processes this block spent.
TPL_LEAK_FILES=()
for f in "$PA_DIR"/*.md; do
  is_pa_non_template "${f##*/}" && continue
  TPL_LEAK_FILES+=("$f")
done
for f in "$CQ_DIR"/*.md; do
  [ "${f##*/}" = "README.md" ] && continue
  TPL_LEAK_FILES+=("$f")
done
TPL_LEAK_FILES+=("$RAV_FILE")

# One verdict line for one (banned path, file) pair, worded exactly as before.
# Two parameters and a global for the path, at the 3-parameter cap with room to
# spare, so the slow path below stays a plain double loop.
tpl_leak_verdict() {
  local path="$1" file="$2" hits rc
  hits=$(/usr/bin/grep -cF -- "$path" "$file" 2>/dev/null)
  rc=$?
  # rc 2 or more is grep failing to read, not a clean file. It used to arrive here
  # as an empty $hits, which `[ "" -eq 0 ]` rejects, so it reddened by accident with
  # a blank count in the message. It reddens on purpose now, and says which it is.
  if [ "$rc" -gt 1 ]; then
    red "  FAIL '$path' was never screened in ${file##*/}, grep exited $rc (unreadable file); a count of 0 here would be a count of nothing"
    FAILED=$((FAILED + 1))
  elif [ "$hits" -eq 0 ]; then
    green "  ok   no '$path' in ${file##*/}"
  else
    red "  FAIL '$path' appeared $hits time(s) in ${file##*/}"
    FAILED=$((FAILED + 1))
  fi
}

# BATCHED SCREEN THEN FALLBACK, the shape check_no_tokens_in in 00-helpers.sh
# already uses for [70] and [77] and for the same reason. This block ran one grep
# per (banned path x file), 3 x 21 = 63 greps, rescanning the whole template corpus
# three times to answer a question one pass can answer. Measured at 0.19s of a
# 4.72s pre-commit gate, against 0.00s for the single screen.
#
# The screen decides ONLY "does any banned path appear anywhere in this set". The
# moment the answer is yes, the original per-pair loop re-runs and words every
# failure exactly as it did before, so no diagnostic detail is traded for the
# speed. The common case is a clean set, which now costs one process.
#
# rc 2 OR MORE FALLS THROUGH TO THE SLOW PATH, it does not print green. A screen
# that could not read its files must never be the reason 63 lines print clean;
# the slow path then reddens per file with grep's own status behind it.
#
# -F because every banned path is a literal, and /usr/bin/grep by absolute path
# for the reason spelled out above check_no_tokens_in: under the interactive zsh
# in this environment bare `grep` is a shell function honouring ignore files, and
# a screen that skips a file is a screen that clears it.
/usr/bin/grep -qF -e '/Users/' -e '/home/' -e '/tmp/' -- "${TPL_LEAK_FILES[@]}" 2>/dev/null
tpl_leak_rc=$?
for path in '/Users/' '/home/' '/tmp/'; do
  for f in "${TPL_LEAK_FILES[@]}"; do
    if [ "$tpl_leak_rc" -eq 1 ]; then
      green "  ok   no '$path' in ${f##*/}"
    else
      tpl_leak_verdict "$path" "$f"
    fi
  done
done
yellow "[15] OUTPUT word cap presence in every sub-agent template"
WORD_CAP_RX='≤[0-9]+\s*word|≤\s*`?\{\{[a-z_]+\}\}`?\s*word|word cap|Total cap|Cap response at'
# THE THREE TESTS BELOW STAY ON grep, ON A HERE-STRING, and do not become
# `[[ "$out" =~ $WORD_CAP_RX ]]` like the fixed-string checks above did. This
# pattern uses `\s`, which BSD grep -E reads as whitespace but bash's own `=~`
# (regcomp, POSIX ERE) reads as a literal `s`. MEASURED on `- Cap: ≤200 words per
# task`: grep matches, `[[ =~ ]]` does not. Switching engines here would quietly
# retire the first two alternations and reduce this to a "word cap"/"Total cap"
# substring check. A here-string is written through a temp file, so it kills the
# SIGPIPE the pipe carried without touching which engine reads the pattern.
for f in "${PA_BUILD_FILES[@]}" "${PA_REVIEW_SINGLE_FILES[@]}"; do
  out=$(output_subsection "$(<"$f")")
  if grep -qE -- "$WORD_CAP_RX" <<<"$out"; then
    green "  ok   ${f##*/} OUTPUT has word cap"
  else
    red "  FAIL ${f##*/} OUTPUT missing word cap (looked for: ≤NN words / word cap / Total cap)"
    FAILED=$((FAILED + 1))
  fi
done
# review-and-verify.md adjudication reviewer too
out=$(awk '/\*\*OUTPUT\*\*/{flag=1; next} flag && /^\*\*/ {flag=0} flag' "$RAV_FILE")
if grep -qE -- "$WORD_CAP_RX" <<<"$out"; then
  green "  ok   review-and-verify.md adjudication reviewer OUTPUT has word cap"
else
  red "  FAIL review-and-verify.md adjudication reviewer OUTPUT missing word cap"
  FAILED=$((FAILED + 1))
fi

yellow "[14] wizard structural conformance (per-file in $CQ_DIR)"
for f in "${CQ_BANK_FILES[@]}"; do
  ok=1
  for req in "**SCENARIO**" "**COMPOSITION**" "**QUESTIONS**" "**EXIT CRITERIA**"; do
    if ! grep -qF "$req" "$f"; then
      red "  FAIL ${f##*/} missing $req"
      FAILED=$((FAILED + 1)); ok=0
    fi
  done
  [ "$ok" = "1" ] && green "  ok   ${f##*/} wizard structure conforms"
done

# === Agent-catalog contract conformance (agents/*.md) ===

yellow "[36] agents/*.md template contract (anchors + ROLE substance + OUTPUT word cap; SEVERITY on reviewer.md and reviewer-*)"
# Agent files carry YAML frontmatter before **ROLE**, the anchor checks grep
# the whole body, so frontmatter passes through harmlessly. The file list is
# the live glob: a new agent is contract-checked the moment it lands, and an
# empty glob is itself a FAIL (never a silent pass).
AGENT_FILES_FOUND=0
for f in agents/*.md; do
  [ -f "$f" ] || continue
  AGENT_FILES_FOUND=$((AGENT_FILES_FOUND + 1))
  agent_body=$(<"$f")
  agent_label="agents/${f##*/}"
  check_template_anchors "$agent_body" "$agent_label"
  check_role "$agent_body" "$agent_label"
  # SEVERITY is required on reviewer-role agents only; spec-reviewer.md,
  # finding-refuter.md, codebase-investigator.md and implementer.md are governed by
  # their own template files' [10] modes.
  #
  # THE PATTERN IS THE LIVE FAMILY AND WAS NOT. It read `code-reviewer-*` from
  # v0.9.0 until this wave, and the 0.18.0 rename moved all six reviewer agents onto
  # the bare `reviewer` stem, so from that commit the arm matched NOTHING while the
  # banner above still advertised it: six review templates could drop their SEVERITY
  # section and [36] would print its OUTPUT-cap green over every one of them. [89]
  # bans the six retired NAMES from every live file and cannot see a retired GLOB,
  # which is how this survived the rename that made it dead.
  #
  # BOTH HALVES ARE NEEDED, and `reviewer*` is not the answer to that: it would also
  # swallow nothing today but would silently start judging any future `reviewer`-
  # prefixed file, while `reviewer-*` alone misses agents/reviewer.md, the merged
  # all-lens reviewer that is Phase 5's default route. Counted rather than assumed:
  # the two patterns together match exactly the 6 files on disk that carry a
  # **SEVERITY** section, and the four they skip carry none.
  case "${f##*/}" in
    reviewer.md|reviewer-*) check_severity_presence "$agent_body" "$agent_label" "review" ;;
  esac
  out=$(output_subsection "$agent_body")
  if grep -qE -- "$WORD_CAP_RX" <<<"$out"; then
    green "  ok   $agent_label OUTPUT has word cap"
  else
    red "  FAIL $agent_label OUTPUT missing word cap"
    FAILED=$((FAILED + 1))
  fi
done
if [ "$AGENT_FILES_FOUND" -eq 0 ]; then
  red "  FAIL agents/*.md glob matched no files"
  FAILED=$((FAILED + 1))
fi

yellow "[36b] agents/*.md frontmatter 'tools:' names are real, and read-only agents stay read-only"
# NOTHING else validates these strings, not the plugin loader and not any other
# check here. A typo or a retired name does not error, it silently changes what
# the agent may do, and the failure is invisible because the agent still runs.
# v0.13.0 shipped 'NotebookRead' in two agents before this check existed; that
# name does not exist (Read handles notebooks), so it was doing nothing while
# looking deliberate. An allowlist is the only thing between a one-character
# slip and an agent with the wrong reach. When Claude Code adds a tool, add the
# name here; that edit IS the review.
KNOWN_TOOLS=" Agent Bash BashOutput Edit ExitPlanMode Glob Grep KillShell NotebookEdit Read SlashCommand Task TodoWrite WebFetch WebSearch Write "
TOOLS_DECLARED=0
for f in agents/*.md; do
  [ -f "$f" ] || continue
  tools_line=$(grep -m1 '^tools:' "$f" 2>/dev/null | sed 's/^tools:[[:space:]]*//')
  [ -n "$tools_line" ] || continue
  TOOLS_DECLARED=$((TOOLS_DECLARED + 1))
  unknown=""
  for t in $(printf '%s' "$tools_line" | tr ',' ' '); do
    case "$KNOWN_TOOLS" in
      *" $t "*) ;;
      *) unknown="$unknown $t" ;;
    esac
  done
  if [ -z "$unknown" ]; then
    green "  ok   ${f##*/} declares only known tools"
  else
    red "  FAIL ${f##*/} declares unknown tool(s):$unknown"
    FAILED=$((FAILED + 1))
  fi
done
# THE FLOOR IS ON THE PARSE, NOT ON THE GLOB, and that is what keeps it from being a
# second copy of [36]'s. [36] above already reds when agents/*.md matches no file, so
# an empty directory is covered. What is not covered is the glob resolving to every
# agent while `^tools:` stops yielding one, which a frontmatter key rename or a single
# leading space does on its own: [36] stays green, every file takes the `continue`
# above in silence, and this line prints "ok 0 agent file(s) declare a tools: line"
# having measured no tool name against the allowlist at all.
#
# A ZERO-GUARD RATHER THAN A HALF-OF-LIVE FLOOR, and the choice was forced rather
# than lazy. When this floor was written the set was small enough that half of it
# rounded to nothing, so the only floor it can carry is the one that refuses a clean
# verdict over an empty set, the shape [27c] and [79] already use rather than the one
# [91] and [93] carry over sets big enough to shrink. The live total is PRINTED on
# the pass line every run instead of written down here, for the reason
# 93-token-declarations.sh's "the defect wearing the uniform" sentence gives: a count
# in a comment goes stale, and this file has neighbours whose job is catching that.
TOOLS_DECLARED_FLOOR=1
if [ "$TOOLS_DECLARED" -lt "$TOOLS_DECLARED_FLOOR" ]; then
  red "  FAIL [36b] parsed a 'tools:' line out of only $TOOLS_DECLARED agent file(s), against a floor of $TOOLS_DECLARED_FLOOR; the frontmatter key stopped matching rather than the agents losing their tools, so every declared tool went unscreened against the allowlist and this check found nothing to object to because it read nothing"
  FAILED=$((FAILED + 1))
else
  green "  ok   $TOOLS_DECLARED agent file(s) declare a tools: line"
fi

# The investigator exists to gather evidence, never to change it, in either of
# its two modes. The tool list cannot enforce that on its own (Bash can write,
# and the prompt needs it for `git grep`), but it CAN keep the file-editing
# tools off the surface entirely, which is the half a check can hold.
INVESTIGATOR="agents/codebase-investigator.md"
if [ ! -f "$INVESTIGATOR" ]; then
  red "  FAIL $INVESTIGATOR missing, the read-oriented tool surface cannot be checked"
  FAILED=$((FAILED + 1))
elif grep -m1 '^tools:' "$INVESTIGATOR" | grep -qE '(^|[ ,:])(Edit|Write|NotebookEdit)([ ,]|$)'; then
  red "  FAIL ${INVESTIGATOR##*/} is read-oriented but declares a file-writing tool"
  FAILED=$((FAILED + 1))
else
  green "  ok   ${INVESTIGATOR##*/} declares no file-writing tool"
fi

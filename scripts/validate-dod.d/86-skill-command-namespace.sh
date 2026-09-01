# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [86] SKILL-COMMAND NAMESPACE. Every slash command this repo writes in prose is
# read from both ends: a namespaced command must name a skill that really
# exists, and a skill that really exists must never be written in the bare,
# un-namespaced spelling.
#
# WHY IT EXISTS. This sprint renamed the codewalk command across 25 sites. Every
# one of those sites was correct the day it was written and wrong the day the
# plugin namespace became mandatory, and no check in this validator could tell
# the difference, so the rename was done by hand and nothing stopped the same
# drift starting again the next morning. A rename that has to be repeated is a
# missing check, not a chore.
#
# TWO HALVES, BOTH BUILT, AND THE SECOND IS THE LOAD-BEARING ONE.
#   (a) RESOLUTION. A namespaced command must name a real skill. This catches a
#       command that points nowhere: a skill renamed, deleted, or mistyped.
#   (b) NAMESPACE. A real skill must not be advertised bare. This is the half
#       that would have prevented the rename, and (a) on its own would not have
#       come close: all 25 stale sites were BARE, so the resolution half never
#       saw a token on any of them and would have printed green over the lot. A
#       check that reads only the namespaced form is blind to exactly the defect
#       that produced this rule, which is why both halves ship or neither is
#       worth having.
#
# THE ROSTER IS TWO DIRECTORIES AND NOT ONE, measured rather than assumed. A
# command resolves against `skills/<name>/SKILL.md` OR `commands/<name>.md`,
# because designify and summary ship as command bodies with no skill directory
# at all. A resolution half reading only the skills/ side would have condemned
# every live mention of those two, which is a check that reds on correct text.
# The roster is DISCOVERED from those two directories on every run and never
# listed here, so a new skill is covered the moment it lands.
#
# WHAT IS EXCLUDED, AND WHY IT IS ARGUED HERE RATHER THAN LEFT SILENT. Two
# surfaces are frozen records of what was true then, and both are skipped:
#   - CHANGELOG.md. A release entry describing the 0.4.0 lawkeeper launch names
#     the command as it was spelled in 0.4.0. Correcting it would falsify the
#     record.
#   - docs/work/. The archived half (docs/work/done/) is the same frozen record:
#     one bare codewalk mention survives in the 2026-08-23 phase-ledger doc and
#     is deliberately left alone. The ACTIVE half is skipped for a second reason
#     of its own, which is that a work-doc quotes the defect it is closing. This
#     very sprint's doc discusses the bare spelling in order to retire it, and a
#     checker that reds on a sprint describing its own fix teaches people to
#     stop describing fixes. Measured before it was granted: the active docs
#     carry no bare command today, so this exclusion hides nothing that exists.
# scripts/check_doc_links.py already draws this exact line for the same reason,
# EXCLUDE_DIRS covering docs/work whole and USER_REPO_POINTERS covering
# CHANGELOG.md, so this is one convention rather than a second one.
#
# THE SURFACE IS EVERY TEXT FILE AND NOT ONLY MARKDOWN, and that too was
# measured. This repo's own rename moved a JavaScript comment in
# skills/codewalk/assets/build-playbook.mjs, a fenced block in
# skills/codewalk/assets/playbook.html and five shell files under scripts/, so a
# markdown-only scan would read straight past the surfaces this repo actually
# renames.
#
# THE SCAN SET IS TRACKED PLUS UNTRACKED, AND THE UNTRACKED HALF IS THE ONE THIS
# CHECK WAS BLIND TO. It read `git ls-files` alone, which is the INDEX, so every
# file a sprint had written and not yet committed was outside the scan while the
# check reported a clean tree over the whole repository. Measured on the sprint
# that found it: 16 untracked files, the eleven this sprint added among them, and
# a bare command planted in any of them left this bar at exit 0 while the
# identical line in a tracked file reddened. A rename lives its whole life in the
# pre-commit window, which is exactly the window a bare command is written in and
# exactly the window this check has to be able to see; [89] made the same
# correction to its own scan for the same reason and argues it at length under
# "THE SCAN READS UNTRACKED FILES TOO".
#
# `--others --exclude-standard` AND NOT `--others` ALONE, which is what keeps
# dist/ and every other build artefact out: the whole of dist/ is gitignored and
# rebuilt by scripts/sync-runtimes.sh, and a scan that read it would report every
# generated copy of a defect a second time and red on a stale build that check
# [56] is the instrument for. `--exclude-standard` is also what leaves a local
# scratch file alone. Measured here: 855 ignored paths, 819 of them under dist/,
# and none of them reaches the set below.
#
# LINE-ORIENTED MATCHING IS CORRECT HERE, stated because the rest of this
# validator is moving to flowed matchers and a reader is entitled to ask why
# this one did not. The flowed pair exists because a wrapped SENTENCE straddles
# a newline and a line-oriented matcher returns a confident zero on it. A
# command is a single unbroken token: markdown wraps at spaces, so the token
# never splits, and flattening would buy nothing while making every finding's
# line number a lie.
#
# THIS FILE CARRIES NO LITERAL BARE COMMAND, and that is deliberate rather than
# stylistic. The scan reads every tracked file, this file included, so a control
# row written out as literal text would be found by the live scan and reported
# as a defect in the check that reports defects. The rows below build their
# tokens from $NSC_S at run time, so the matcher sees the same bytes it would
# see in a real document while the file on disk holds none of them. The
# alternative, exempting this file from its own scan, would hide a genuinely
# wrong command advertised here and is refused.
#
# ONE ID AND NOT A RANGE, for the reason the 83, 98 and 99 rows in
# scripts/validate-dod.d/README.md give: this fragment declares exactly one check
# and a range endpoint would assert a maximum it does not have. Confirmed against
# [76i]'s parser, which compares an endpoint only when a row's first or last
# item is a range, so a single-id row is skipped by construction.
yellow "[86] every namespaced slash command names a real skill, and no live file advertises a skill in the bare form"

NSC_S='/'

# THE ROSTER, discovered from both command surfaces. A skill directory counts
# only when it actually holds a SKILL.md, so a stray directory cannot inflate
# the alternation and quietly widen the ban.
NSC_ROSTER=$(
  {
    for nsc_d in skills/*/; do
      [ -f "${nsc_d}SKILL.md" ] || continue
      nsc_n=${nsc_d#skills/}
      printf '%s\n' "${nsc_n%/}"
    done
    for nsc_c in commands/*.md; do
      [ -f "$nsc_c" ] || continue
      nsc_n=${nsc_c#commands/}
      printf '%s\n' "${nsc_n%.md}"
    done
  } | sort -u
)
NSC_ROSTER_N=$(printf '%s\n' "$NSC_ROSTER" | grep -c '[a-z]')
NSC_ALT=$(printf '%s\n' "$NSC_ROSTER" | tr '\n' '|' | sed 's/|$//')

# THE TWO REGEXES, written once and shared by the live scan and by every control
# below, so a control can never pass against a matcher the scan does not use.
#
# The bare form is bounded on both sides. On the left, anything that could make
# the slash part of a PATH is excluded, which is what keeps `skills/hackify/` and
# a glob like the one in scripts/check-collisions.sh out of the findings. On the
# right the same class plus the colon, because the colon is precisely what makes
# a namespaced command namespaced and matching it here would report every
# correct site as a defect.
NSC_BARE_RE="(^|[^A-Za-z0-9_./:-])${NSC_S}(${NSC_ALT})([^A-Za-z0-9_./:-]|$)"
NSC_NS_RE="${NSC_S}hackify:[A-Za-z0-9-]+"

# THE ONE MATCHER. `-` reads stdin, which is how the control rows reach exactly
# the grep the live scan runs, and an unreadable path returns 2 rather than the
# empty output grep would hand back for a clean file. That distinction is the
# whole fail-closed contract: without it a renamed or deleted file prints as a
# file with nothing wrong in it.
#
# EVERY FILE IN ONE CALL, NOT ONE CALL PER FILE, and this is most of the check's
# runtime. The first draft looped the whole tracked tree twice with a grep per
# file per regex, which is 540 processes for 270 files and measured 1.7s of a
# 9.2s validator, one fifth of the run for two greps' worth of work.
# rules/performance.md files that shape as perf.algorithmic, remedy "batch".
# `-H` is what makes the batch safe: with a single path grep omits the filename
# and every finding below would be attributed to whatever the parser found
# first, so the flag is load-bearing rather than cosmetic. `-o` prints the
# matched token instead of the line, which is the only part any caller here
# reads and saves a second pass per finding to pull the name back out.
nsc_scan() {
  local nsc_re="$1"
  shift
  if [ "${1:-}" = "-" ]; then
    grep -nIHoE "$nsc_re"
    return
  fi
  local nsc_p
  for nsc_p in "$@"; do
    [ -r "$nsc_p" ] || return 2
  done
  grep -nIHoE "$nsc_re" -- "$@"
}

# CONTROLS FIRST, on the tie-break 55, 73, 83 and 91 all make: a scan that cannot
# be trusted says so before it says anything about the tree. A matcher that finds
# nothing prints the whole tree clean having measured nothing, which is the exact
# false green this sprint exists to retire, and it is not hypothetical here: an
# early draft of this scan lost every file to an unsupported xargs flag and
# reported a spotless repo over six live defects.
if [ "$NSC_ROSTER_N" -ge 6 ]; then
  green "  ok   [86] roster control, $NSC_ROSTER_N skills discovered across skills/*/SKILL.md and commands/*.md"
else
  red "  FAIL [86] roster control, only $NSC_ROSTER_N skill name(s) discovered, expected at least 6; the alternation collapsed and every ban below would be measured against almost nothing"
  FAILED=$((FAILED + 1))
fi

# POSITIVE CONTROL ON A REAL FILE, 83's shape: the namespaced matcher is pointed
# at a document that certainly carries namespaced commands, and a zero here means
# the matcher broke rather than that the tree is clean.
NSC_CONTROL_FILE="README.md"
NSC_CONTROL_HITS=$(nsc_scan "$NSC_NS_RE" "$NSC_CONTROL_FILE" | grep -c ':')
if [ "$NSC_CONTROL_HITS" -ge 1 ]; then
  green "  ok   [86] positive control, the namespaced matcher finds $NSC_CONTROL_HITS command line(s) really present in $NSC_CONTROL_FILE"
else
  red "  FAIL [86] positive control, the namespaced matcher found nothing in $NSC_CONTROL_FILE; either the matcher broke, in which case every verdict below was measured by a matcher that finds nothing, or the command table was removed"
  FAILED=$((FAILED + 1))
fi

nsc_scan "$NSC_NS_RE" "$NSC_CONTROL_FILE.no-such-file" > /dev/null 2>&1
if [ "$?" -eq 2 ]; then
  green "  ok   [86] fail-closed control, an unreadable path is reported rather than read as a clean file"
else
  red "  FAIL [86] fail-closed control, an unreadable path did not report, so a renamed or deleted file would count as one with nothing wrong in it"
  FAILED=$((FAILED + 1))
fi

# THE PLANTED CONTROLS, 84's shape. Two tables, one the matcher must catch and
# one it must not, because a matcher that catches everything is as useless as one
# that catches nothing and only the pair pins both edges. Every row is assembled
# from $NSC_S for the reason the header gives.
NSC_MUST_CATCH=()
NSC_MUST_CATCH+=("- **\`${NSC_S}lawkeeper\`** *(since v0.4.0)*, full-codebase auditor")
NSC_MUST_CATCH+=("The user resumes later via \`${NSC_S}hackify resume <slug>\`.")
NSC_MUST_CATCH+=("run ${NSC_S}quick when the change is small")
NSC_MUST_CATCH+=("| \`${NSC_S}codewalk\` | Interactive call-stack viewer. |")
check_list_size "${#NSC_MUST_CATCH[@]}" 4 "the [86] must-catch control table"

NSC_MUST_MISS=()
NSC_MUST_MISS+=("\`${NSC_S}hackify:codewalk\` is the namespaced spelling")
NSC_MUST_MISS+=("see skills${NSC_S}hackify${NSC_S}references${NSC_S}finish.md for the rule")
NSC_MUST_MISS+=("    *\"${NSC_S}hackify${NSC_S}\"*\"${NSC_S}skills${NSC_S}\"*) continue ;;")
NSC_MUST_MISS+=("NOT a per-PR diff review (use \`${NSC_S}code-review\`)")
NSC_MUST_MISS+=("cut a ${NSC_S}quick-fix branch off main")
check_list_size "${#NSC_MUST_MISS[@]}" 5 "the [86] must-miss control table"

NSC_CTRL_BAD=0
for nsc_row in "${NSC_MUST_CATCH[@]}"; do
  nsc_got=$(nsc_scan "$NSC_BARE_RE" - <<NSC_ROW_EOF
$nsc_row
NSC_ROW_EOF
)
  [ -n "$nsc_got" ] && continue
  red "  FAIL [86] planted control, the bare-form matcher missed a line it must catch: $nsc_row"
  FAILED=$((FAILED + 1))
  NSC_CTRL_BAD=$((NSC_CTRL_BAD + 1))
done
for nsc_row in "${NSC_MUST_MISS[@]}"; do
  nsc_got=$(nsc_scan "$NSC_BARE_RE" - <<NSC_ROW_EOF
$nsc_row
NSC_ROW_EOF
)
  [ -z "$nsc_got" ] && continue
  red "  FAIL [86] planted control, the bare-form matcher fired on a line it must leave alone: $nsc_row"
  FAILED=$((FAILED + 1))
  NSC_CTRL_BAD=$((NSC_CTRL_BAD + 1))
done
if [ "$NSC_CTRL_BAD" -eq 0 ]; then
  green "  ok   [86] planted controls, the bare-form matcher caught all ${#NSC_MUST_CATCH[@]} advertised commands and left all ${#NSC_MUST_MISS[@]} paths, namespaced forms and non-plugin commands alone"
fi

# THE SCANNED SET. Tracked and untracked files, minus the two frozen records the
# header argues for. The floor is the same guard [55], [56] and [97] all write at
# their own set boundaries: a comparison over a collapsed set has nothing to say
# and must redden rather than print a clean verdict over nothing.
#
# THE ENUMERATION'S OWN STATUS IS READ, AND IT IS READ SEPARATELY FROM THE COUNT,
# because those are two different answers and the retired form gave one line for
# both. It ran `git ls-files 2> /dev/null | grep -v ... || true`, which sent git's
# error to /dev/null, took the PIPE's status rather than git's, and then laundered
# even that with `|| true`. An enumeration that could not run therefore arrived
# here as an empty set and left through the same floor a genuinely shrunken
# repository would, wearing the same words. FOUND NONE AND COULD NOT LOOK ARE NOW
# SEPARATE REDS: the substitution below holds git alone with no pipe inside it, so
# `$?` on the next line is git's own, and the filter runs afterwards where its own
# rc 1 (nothing survived the exclusions) cannot be mistaken for git's.
NSC_LS=$(git ls-files --cached --others --exclude-standard)
NSC_LS_RC=$?
if [ "$NSC_LS_RC" -ne 0 ]; then
  red "  FAIL [86] git ls-files exited $NSC_LS_RC, so the scan set was never enumerated; every verdict below would have been measured against whatever it managed to print, and a clean count from a scan that could not look is a count of nothing"
  FAILED=$((FAILED + 1))
fi
NSC_FILES=$(printf '%s\n' "$NSC_LS" | grep -vE '^(CHANGELOG\.md|docs/work/)')
NSC_FILE_N=$(printf '%s\n' "$NSC_FILES" | grep -c '[a-z]')
if [ "$NSC_FILE_N" -lt 100 ]; then
  red "  FAIL [86] the scan set collapsed to $NSC_FILE_N file(s), expected at least 100; the enumeration returned nothing usable and the verdicts below would be vacuous"
  FAILED=$((FAILED + 1))
fi

# READABILITY IS PROBED IN THE SHELL, so an unreadable path is NAMED rather than
# taking the whole batch down with the matcher's fail-closed return. Both halves
# are wanted: the loop says which file, the matcher's own guard is what the
# control above exercises, and neither costs a process.
NSC_READABLE=()
NSC_UNREADABLE=0
while IFS= read -r nsc_f; do
  [ -n "$nsc_f" ] || continue
  if [ -r "$nsc_f" ]; then
    NSC_READABLE+=("$nsc_f")
    continue
  fi
  red "  FAIL [86] $nsc_f is in the scan set but unreadable, so it was never scanned"
  FAILED=$((FAILED + 1))
  NSC_UNREADABLE=$((NSC_UNREADABLE + 1))
done <<NSC_FILES_EOF
$NSC_FILES
NSC_FILES_EOF

# ${arr[@]+"${arr[@]}"} on every expansion, for the reason 56-dist-integrity.sh
# records at length: bash 3.2 is the floor, the orchestrator sets `-u` in its
# `set -uo pipefail` line, and "${arr[@]}" on an EMPTY array is a fatal
# unbound-variable error there rather than an empty expansion.
NSC_BARE_HITS=$(nsc_scan "$NSC_BARE_RE" ${NSC_READABLE[@]+"${NSC_READABLE[@]}"})
NSC_NS_HITS=$(nsc_scan "$NSC_NS_RE" ${NSC_READABLE[@]+"${NSC_READABLE[@]}"})

# HALF (b), the namespace half. A skill that exists, written bare.
NSC_BARE_N=0
while IFS= read -r nsc_hit; do
  [ -n "$nsc_hit" ] || continue
  nsc_where=${nsc_hit%:*}
  nsc_tok=${nsc_hit##*:}
  nsc_name=$(printf '%s\n' "$nsc_tok" | sed "s|^[^${NSC_S}]*${NSC_S}||;s|[^A-Za-z0-9-]*$||")
  red "  FAIL [86] $nsc_where advertises the plugin skill $nsc_name in the bare form; a plugin command only resolves namespaced, so spell it ${NSC_S}hackify:$nsc_name"
  FAILED=$((FAILED + 1))
  NSC_BARE_N=$((NSC_BARE_N + 1))
done <<NSC_BARE_EOF
$NSC_BARE_HITS
NSC_BARE_EOF

# HALF (a), the resolution half. A namespaced command naming nothing on disk.
NSC_NS_N=0
NSC_UNRESOLVED=0
while IFS= read -r nsc_hit; do
  [ -n "$nsc_hit" ] || continue
  # THE TOKEN CARRIES A COLON OF ITS OWN, so the path:line prefix is cut at the
  # token rather than at the last colon. `${hit%:*}` reads the colon INSIDE
  # `hackify:<name>` as the field separator and reports `file:line:/hackify` as
  # the location, which is a finding that misstates where it found itself. The
  # bare half above has no such colon and needs no such care.
  nsc_where=${nsc_hit%:${NSC_S}hackify:*}
  nsc_t=${nsc_hit##*hackify:}
  NSC_NS_N=$((NSC_NS_N + 1))
  [ -f "skills/$nsc_t/SKILL.md" ] && continue
  [ -f "commands/$nsc_t.md" ] && continue
  red "  FAIL [86] $nsc_where cites the command hackify:$nsc_t, but neither skills/$nsc_t/SKILL.md nor commands/$nsc_t.md exists"
  FAILED=$((FAILED + 1))
  NSC_UNRESOLVED=$((NSC_UNRESOLVED + 1))
done <<NSC_NS_EOF
$NSC_NS_HITS
NSC_NS_EOF

# THE NAMESPACED FLOOR sits beside the verdict rather than above it, because it
# needs the count the scan produced. Only a collapse toward zero means the
# extraction broke; ordinary growth never touches it.
if [ "$NSC_NS_N" -lt 40 ]; then
  red "  FAIL [86] only $NSC_NS_N namespaced command mention(s) were resolved across $NSC_FILE_N files, expected at least 40; the extraction stopped reaching the tree and the resolution half proved nothing"
  FAILED=$((FAILED + 1))
elif [ "$NSC_UNRESOLVED" -eq 0 ]; then
  green "  ok   [86] all $NSC_NS_N namespaced command mentions resolve to a skills/<name>/SKILL.md or commands/<name>.md"
fi

if [ "$NSC_BARE_N" -eq 0 ] && [ "$NSC_UNREADABLE" -eq 0 ]; then
  green "  ok   [86] no bare plugin command in $NSC_FILE_N tracked and untracked file(s), across a roster of $NSC_ROSTER_N skills (CHANGELOG.md, docs/work/ and every gitignored path excluded)"
fi

# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [99] WORK-DOC STATUS CLAIMS, split out of 98-work-doc-ledger-sync.sh in the wave
# that file reached 498 of a 500-LOC cap and could not take the created-date rule
# assertion (d) adds. Two assertions came across whole and KEPT THEIR LETTERS, the
# way [76g] and [76h] kept their ids when 96-review-scope-sites.sh was carved out of
# 76-phase-ledger-substrate.sh. Both are decidable by reading the tree, and each reds
# when it stops being true.
#
#   (a) STATUS VOCABULARY. A work-doc's frontmatter status must be a value the
#       template declares. skills/hackify/references/work-doc-template.md is the
#       DECLARING site and each work-doc a CLAIMING site, the shape [93] resolves
#       for prompt inputs. The list is READ OUT of that template at runtime, from the
#       one frontmatter-reference row whose first cell names the status field, so
#       retiring a value there retires it here with no second copy to keep.
#
#   (c) A LIVE DOC IS NOT ARCHIVED. A doc that is NOT under docs/work/done/ must
#       not carry the archived status value. Directory and frontmatter have to
#       agree, and this half catches a doc marked finished and left where it was.
#
# THE LETTERS DID NOT MOVE AND THE ID DID, which is the opposite of what a split
# usually does, for a reason worth reading before renaming either. Assertion (c) is
# cited BY LETTER from skills/hackify/references/phase-ledger.md and from
# skills/hackify/references/finish.md, so the letters had to survive. The id could
# not: [98] is a single check, and CHANGELOG.md:54 binds it to the filename
# 98-work-doc-ledger-sync.sh and to the archived-sprint behaviour that stayed there,
# so moving either would leave that line pointing at nothing. The ledger half kept
# [98] and this half took a new id.
#
# THAT CHANGELOG ENTRY IS NOW STALE IN ONE SENTENCE, written down here because
# nobody else is going to find it. It calls [98] three assertions; after this split
# it has two, and the third is (a) in this file. The entry sits under 0.15.1, which
# is written up but carries no git tag while every earlier version has one, so it is
# still editable rather than frozen. CHANGELOG.md is outside this task's file
# allowlist, so the correction is reported as a follow-up instead of made here.
#
# THE SEAM IS WHICH PART OF A DOC IS READ. Everything here resolves a FRONTMATTER
# VALUE against something outside the doc, the template's declared list for (a) and
# the doc's own directory for (c), and both share the template vocabulary parse.
# Everything in 98 reads the SECTION 0 BLOCK and shares ledger_start() and the fence
# mask under it. Nothing crosses: this file has no fence mask and no ledger reader,
# 98 has no vocabulary parse, and no floor or control is shared. WHAT IT COSTS,
# stated rather than hidden: four plumbing readers appear in both fragments, the file
# read, the symlink refusal, the tracked-doc list and the column-0 frontmatter
# reader. A sourced shell fragment has nowhere to import a shared module from.
#
# WHAT ASSERTION (a) DOES NOT REACH. A status that is spelled correctly says nothing
# about whether it is TRUE. A doc stalled for a week still reads implementing, and
# nothing here can tell that from a doc that is genuinely mid-flight. A GREEN HERE
# MEANS EVERY STATUS IS A DECLARED WORD IN THE RIGHT DIRECTORY, never that the word
# describes what actually happened.
#
# NOTHING SOURCED FROM A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN. The
# template's values are shape-gated against a pattern that is a literal in this file
# and then compared with `==`, never anything else. A validator building its matcher
# out of a document's
# contents would be arbitrary code execution by editing that document, the guardrail
# this whole sprint is written around. Reading obeys the same rule: no path is opened
# until it resolves to itself under the repository root, so a tracked symlink is
# refused and REPORTED rather than followed out of the tree.
#
# WHY A POSITIVE CONTROL. On a truthful tree both assertions report nothing, and that
# silence is the SAME OUTPUT this check would print if its judging had quietly
# stopped. So it is earned before it is trusted: a synthetic five-doc corpus, built
# from source literals here and never read off disk, goes through the SAME judge the
# live scan uses, in BOTH directions. Three docs MUST be reported and two MUST NOT;
# [94] and [95] each state this at their own control. THE CONTROL TAKES ITS GOOD
# STATUS OUT OF THE PARSED VOCABULARY rather than writing one here, so it cannot
# become the second copy of the values (a) exists to avoid.
yellow "[99] every work-doc's status is one the template declares, and it agrees with the directory the doc sits in"
# WHY docs/work/ AND NOT THE LIVE PATHSPEC THE NEIGHBOURS USE. [91], [93], [94] and
# [95] all scan with a three-part pathspec that EXCLUDES docs/work/, because for them
# the sprint record has to be able to quote a broken doc. This check is one of the
# two whose subjects ARE the work-docs, so copying that pathspec would collapse the
# subject set to zero and print a confident green over nothing. Tracked files only,
# so a half-written doc open in an editor is never judged.
#
# THE FLOORS ARE WHAT STOP A VACUOUS PASS, judged before any per-doc red prints, the
# order [91], [93], [94] and [95] all argue for: a collapsed vocabulary makes every
# doc look wrong, and replaying the reds first would bury the line explaining them.
# HOW EACH WAS DERIVED, and the command that re-derives it:
#
#   WS_DOC_FLOOR, half the work-docs tracked on 2026-08-25. Half, because docs are
#   added most waves and none has ever been deleted, so only a collapse toward zero
#   means the pathspec stopped matching.
#     git ls-files -- 'docs/work/*.md' | wc -l
#
#   WS_VOCAB_FLOOR, half the values the template row declares today. Half, for the
#   same reason [94] floors the template's heading count at 12 against 23: the list
#   legitimately gains and loses a value, and only a collapse means the row grammar
#   stopped matching. The command splits the SAME cell this check reads and counts
#   the pieces, rather than counting lines that happen to carry the word.
#     awk -F'|' '$2 ~ /`status`/ {print split($3, v, "/")}' \
#       skills/hackify/references/work-doc-template.md
#
# NO COUNT IS WRITTEN INTO A COMMENT HERE. The live totals print on the pass line and
# every floor carries the command that re-derives it, the convention
# 57-doc-links.sh:20-26 states: an unpinned number in a comment is a rotting claim.
WS_DOC_FLOOR=10
WS_VOCAB_FLOOR=4

WS_DOCS=0
WS_VOCAB=0
WS_CONTROL=none

ws_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

ws_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r WS_DOCS WS_VOCAB <<<"${line#SIZE }" ;;
      'CONTROL '*) WS_CONTROL=${line#CONTROL } ;;
    esac
  done <<<"$1"
}

# The vocabulary floor is judged FIRST, being reference data and not corpus: when it
# collapses every status resolves to nothing and a docs-side diagnosis misleads.
ws_floors_hold() {
  if [ "$WS_VOCAB" -lt "$WS_VOCAB_FLOOR" ]; then
    ws_fail "[99] the template parse read $WS_VOCAB status value(s) against a floor of $WS_VOCAB_FLOOR; the frontmatter-reference row or the template path stopped matching, and every work-doc's status would resolve against an empty vocabulary"
    return 1
  fi
  if [ "$WS_DOCS" -lt "$WS_DOC_FLOOR" ]; then
    ws_fail "[99] the work-doc scan read $WS_DOCS tracked doc(s) under docs/work/ against a floor of $WS_DOC_FLOOR; the pathspec stopped matching, and a scan over nothing measures nothing"
    return 1
  fi
  return 0
}

# THE CONTROL IS JUDGED AFTER THE FLOORS AND BEFORE THE GREEN, never instead of the
# per-doc walk, the order [94] and [95] both take. A real finding must still be
# reported on a run whose control has broken, so a failed control counts as a finding
# like any other: it prints, it bumps the status, and it takes the pass line with it.
# WS_CONTROL starts at `none`, so a control that never ran cannot look like one that
# held.
ws_control_holds() {
  [ "$WS_CONTROL" = ok ] && return 0
  ws_fail "[99] the positive control did not hold (control verdict: $WS_CONTROL). A synthetic five-doc corpus built from literals in this fragment must report exactly the three docs that break something, one carrying a status value no template row declares, one sitting outside the archive while claiming it was archived, and one carrying no status field at all, and must report neither of the two clean docs beside them, a live doc with a declared status and an archived doc that says so. Until that separates, this run's silence is not evidence of anything: a judge that had stopped discriminating would print the same nothing"
  return 1
}

# AND NO GREEN PRINTS BESIDE A RED, [91]'s rule verbatim: a summary contradicting the
# failure above it is the fail-open shape this fragment refuses, so the pass line is
# reached only when nothing failed.
ws_verdict() {
  local line bad=0
  ws_read_size "$1"
  ws_floors_hold || return
  ws_control_holds || bad=$((bad + 1))
  while IFS= read -r line; do
    case "$line" in
      'FAIL '*) ws_fail "${line#FAIL }"; bad=$((bad + 1)) ;;
    esac
  done <<<"$1"
  [ "$bad" -eq 0 ] || return
  green "  ok   all $WS_DOCS tracked work-doc(s) carry a status the template's $WS_VOCAB declared value(s) allow and sit in the directory that status implies, and the positive control separated its reported docs from its clean ones before that silence was trusted"
}

if ! command -v python3 > /dev/null 2>&1; then
  ws_fail "[99] needs python3 to parse work-doc frontmatter, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, per the tie-breaker at
  # 73-implementer-rename.sh:174-195. A python traceback exits non-zero and writes to
  # stderr, and a bare $(...) capture swallows both, leaving this block to read an
  # empty result as "no work-doc is out of step". A FAIL-CLOSED BRANCH OUTRANKS A HIT
  # REPORT: a scan that could not finish says nothing trustworthy about what it did
  # print.
  ws_err=$(mktemp 2>/dev/null) || ws_err=''
  if [ -z "$ws_err" ]; then
    ws_fail "[99] could not create the stderr capture file, so the work-doc scan never ran"
  else
    ws_out=$(python3 - 2>"$ws_err" <<'WS_PY'
import io, os, re, subprocess, sys

# Every pattern here is a literal in this file. See the header.
#
# THE BACKTICK IS SPELLED chr(96) AND THE APOSTROPHE chr(39), NEITHER OF THEM AN
# AFFECTATION. This block is a heredoc inside a $(...) substitution, and bash
# parses a backtick in there as a legacy command substitution even when the heredoc
# is quoted, while a lone apostrophe inside a double-quoted python string is one more
# quote for the shell to count. [93] and [95] both record the trap and the same fix:
# a literal one here is a parse error, a check that cannot run at all.
TICK = chr(96)
QUOTE = chr(39)
TEMPLATE = 'skills/hackify/references/work-doc-template.md'
WORKDOCS = 'docs/work/*.md'
ARCHIVE = 'docs/work/done/'
FENCE = '---'
STATUS_KEY = 'status:'
STATUS_CELL = '%sstatus%s' % (TICK, TICK)
ARCHIVED_STATUS = 'done'
# The repository root, resolved once, so every work-doc path can be required to
# resolve back to itself underneath it. Taken from the working directory rather than
# a second git call: this fragment already runs from the repo root, which the
# template read below depends on too.
ROOT = os.path.realpath(os.getcwd())
# The shape gate on a parsed value. A cell that stops looking like a vocabulary
# entry is dropped rather than admitted, so a reformatted table collapses the
# count into the floor instead of widening what any document may claim.
VALUE = re.compile(r'^[a-z][a-z0-9_-]*$')
# The control's bad status. Deliberately a string no template row could carry, so
# the synthetic corpus and the live tree can never reach into one another.
CONTROL_BAD = 'zzq-control-not-a-status'


def read(path):
    with io.open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace')


def refuse_read(path):
    """The finding saying why this path was not opened, or None. os.path.isfile
    FOLLOWS a symlink, so a tracked symlink under docs/work/ would be opened and
    whatever it points at quoted into a finding. Resolve first, read only what
    resolves to itself under ROOT, and REPORT the refusal rather than skip it: a doc
    this check declines to read is not a doc that passed."""
    full = os.path.join(ROOT, path)
    real = os.path.realpath(full)
    if real == full and real.startswith(ROOT + os.sep) and not os.path.islink(full):
        return None
    return ('%s does not resolve to a plain file under the repository root (it '
            'reaches %s), so this check refused to follow it rather than read '
            'what it points at' % (path, real))


def cells(line):
    """The pipe-separated cells of one markdown table row, trimmed."""
    return [part.strip() for part in line.strip().strip('|').split('|')]


def vocabulary():
    """The status values the template declares, read out of its own table row.

    STRUCTURAL, never a substring hunt. The row is the one whose FIRST cell names the
    status field, the values are its SECOND cell split on the slash, each stripped of
    backticks, shape-gated, then only ever compared with `==`. A value in prose
    declares nothing, the reading [94] applies to its headings. An empty set is
    returned rather than raised, so the shell floor names the collapse, not python."""
    found = set()
    if not os.path.isfile(TEMPLATE):
        return found
    for line in read(TEMPLATE).split('\n'):
        row = cells(line) if line.strip().startswith('|') else []
        if len(row) < 2 or row[0] != STATUS_CELL:
            continue
        for piece in row[1].split('/'):
            value = piece.strip().strip(TICK).strip()
            if VALUE.match(value):
                found.add(value)
    return found


def frontmatter_field(lines, key):
    """(value, line number) for one frontmatter key, or (None, 0).

    The block is the text between the first two fences at the top of the file; a key
    written below that is body prose and declares nothing. THE KEY IS REQUIRED AT
    COLUMN 0 OF THE RAW LINE, because indentation carries meaning in YAML: a status
    line indented inside a sprint_goal block scalar is a line of that scalar, not the
    document status, and stripping before the test would read it as the status."""
    if not lines or lines[0].strip() != FENCE:
        return (None, 0)
    for num in range(1, len(lines)):
        if lines[num].strip() == FENCE:
            return (None, 0)
        if not lines[num].startswith(key):
            continue
        value = lines[num][len(key):].strip().strip(TICK).strip('"').strip(QUOTE)
        return (value, num + 1)
    return (None, 0)


def judge_status(path, found, allowed):
    """Assertions (a) and (c) for one doc. `found` is (value, line number).

    The tuple keeps this inside the three-parameter cap, the grouping [93] and [94]
    both use. An EMPTY `allowed` suppresses the
    vocabulary sentence and nothing else: the shell floor reports a collapsed
    template parse, and accusing every doc too would bury the line explaining it."""
    value, line = found
    out = []
    if value is None:
        return ['%s carries no %s field in its frontmatter, so it states no phase '
                'and nothing can be resolved against the template vocabulary'
                % (path, STATUS_KEY.rstrip(':'))]
    if allowed and value not in allowed:
        out.append('%s:%d sets %s %s%s%s, which is none of the %d value(s) the row at '
                   '%s declares: %s' % (path, line, STATUS_KEY, QUOTE, value, QUOTE,
                                        len(allowed), TEMPLATE, ', '.join(sorted(allowed))))
    if value == ARCHIVED_STATUS and not path.startswith(ARCHIVE):
        out.append('%s:%d sets %s %s while the file sits outside %s, so a doc that '
                   'says the sprint is finished was never moved to the archive'
                   % (path, line, STATUS_KEY, ARCHIVED_STATUS, ARCHIVE))
    return out


def judge(path, lines, allowed):
    """Every finding for one doc, through both assertions.

    NO FENCE MASK IS APPLIED HERE, unlike 98-work-doc-ledger-sync.sh, and that is a
    measured difference rather than an omission: the frontmatter is the text between
    the first two `---` lines of a file, neither of which is a code fence, so nothing
    a document writes inside a fenced block can reach the value read below."""
    return judge_status(path, frontmatter_field(lines, STATUS_KEY), allowed)


def control_docs(good):
    """The five synthetic work-docs the control judges, as (path, body, reported).

    Source literals only, none read off disk, so no document can change what this
    proves. `good` comes from the PARSED vocabulary rather than being written here,
    which keeps this from becoming the second copy of the values (a) reads out."""
    head = FENCE + '\nslug: zzq-control\nstatus: %s\n' + FENCE + '\n\nbody\n'
    bare = '# zzq-control\n\nbody with no frontmatter at all\n'
    return (('docs/work/zzq-bad-status.md', head % CONTROL_BAD, True),
            ('docs/work/zzq-live-archived.md', head % ARCHIVED_STATUS, True),
            ('docs/work/zzq-no-status.md', bare, True),
            ('docs/work/zzq-clean.md', head % good, False),
            ('docs/work/done/zzq-archived.md', head % ARCHIVED_STATUS, False))


def control(allowed):
    """True when a corpus whose verdicts are known is judged exactly that way.

    BOTH DIRECTIONS, for the reason the header gives: three docs MUST be reported and
    two MUST NOT, so a judge degraded to always-pass and one degraded to always-fail
    both show up. Every case runs the SAME judge() the live scan uses; a control
    exercising a copy would stay green while the shipped path rotted."""
    good = None
    for value in sorted(allowed):
        if value != ARCHIVED_STATUS:
            good = value
            break
    if good is None:
        return False
    for path, body, reported in control_docs(good):
        if bool(judge(path, body.split('\n'), allowed)) != reported:
            return False
    return True


def work_docs():
    """Tracked work-docs, by argv list and never through a shell.

    docs/work/ is deliberately IN scope; see the header. -z AND SPLIT ON NUL, never
    newline: under git's default core.quotePath a path holding a non-ASCII byte, a double
    quote or a backslash comes back C-quoted and wrapped in quote marks, so it no
    longer ends in .md, the filter below drops it, and the doc leaves the corpus with
    nothing said about it. A NUL record is never quoted and never escaped."""
    proc = subprocess.run(['git', 'ls-files', '-z', '--', WORKDOCS],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode('utf-8', 'replace'))
        raise SystemExit('git ls-files failed with rc %d' % proc.returncode)
    names = proc.stdout.decode('utf-8', 'replace').split('\0')
    return [p for p in names if p.endswith('.md')]


def scan(paths, allowed):
    """Judge every doc, report what it found, then print CONTROL and SIZE."""
    docs = 0
    findings = []
    for path in paths:
        refusal = refuse_read(path)
        if refusal:
            findings.append(refusal)
            continue
        if not os.path.isfile(path):
            continue
        docs += 1
        findings.extend(judge(path, read(path).split('\n'), allowed))
    for line in findings:
        print('FAIL %s' % line)
    print('CONTROL %s' % ('ok' if control(allowed) else 'fail'))
    print('SIZE %d %d' % (docs, len(allowed)))


ALLOWED = vocabulary()
scan(work_docs(), ALLOWED)
WS_PY
)
    ws_rc=$?
    ws_errtxt=$(cat "$ws_err")
    rm -f "$ws_err"
    if [ "$ws_rc" -ne 0 ] || [ -n "$ws_errtxt" ]; then
      ws_fail "[99] the work-doc scan did not finish (rc $ws_rc), so its silence is not a verdict: ${ws_errtxt:-no stderr, non-zero exit}"
    else
      ws_verdict "$ws_out"
    fi
  fi
fi

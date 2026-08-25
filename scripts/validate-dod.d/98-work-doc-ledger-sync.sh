# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [98] WORK-DOC LEDGER SYNC. A work-doc's frontmatter and its phase ledger are both
# statements about where the work stands, and each is decidable by reading the tree.
# A doc under docs/work/done/ says the sprint finished; an open row in its section 0
# says a phase never closed. Both cannot be true. This block resolves THREE SUCH
# STATEMENTS, each decidable by reading the tree, and reds when one stops being true.
#
#   (a) STATUS VOCABULARY. A work-doc's frontmatter status must be a value the
#       template declares. skills/hackify/references/work-doc-template.md is the
#       DECLARING site and each work-doc a CLAIMING site, the shape [93] resolves
#       for prompt inputs. The list is READ OUT of that template at runtime, from the
#       one frontmatter-reference row whose first cell names the status field, so
#       retiring a value there retires it here with no second copy to keep.
#
#   (b) AN ARCHIVED DOC IS FINISHED. A doc under docs/work/done/ carrying a section
#       0 phase ledger must show no open row in that block. An open row there is a
#       phase nobody closed, behind a filename saying the sprint is over.
#
#   (c) A LIVE DOC IS NOT ARCHIVED. A doc that is NOT under docs/work/done/ must
#       not carry the archived status value. Directory and frontmatter have to
#       agree, and this half catches a doc marked finished and left where it was.
#
# WHAT ASSERTION (b) DOES NOT REACH, because silence gets read as a guarantee. A
# closed `- [x]` row cannot be told apart from a phase
# that was dropped and ticked anyway; nothing in the file separates them.
# docs/work/done/2026-08-23-phase-ledger-substrate.md:29 is a live example, a closed
# Phase 6d row with the words "never ran" beside it. A GREEN HERE MEANS NO ROW IS
# OPEN, never that an archived sprint ran the phases it ticked.
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
# THE LEDGER BLOCK IS FOUND AND ENDED OUTSIDE FENCED CODE, and it ends at the next
# `## ` heading of any name, never at `## 1.`. Both halves are measured rather than
# tidy. The groom path inserts a `## Groom Provenance` section between section 0 and
# section 1, instructed at skills/groom/SKILL.md:59 and pinned by the section-order
# law at skills/hackify/references/work-doc-template.md:42, so a terminator keyed to
# the section-1 heading would swallow it on every groomed doc; a doc quoting the
# ledger heading in a code block would shadow its own real ledger; a heading quoted
# inside the block would end it early and hide every row
# below. ROWS OUTSIDE THE BLOCK ARE NOT SUBJECTS either: the Sprint Backlog writes
# its tasks in the identical `- [ ]` grammar and every archived doc carries one.
#
# WHY A POSITIVE CONTROL. On a truthful tree all three assertions report nothing, and
# that silence is the SAME OUTPUT this check would print if its judging had quietly
# stopped. So it is earned before it is trusted: a synthetic seven-doc corpus, built
# from source literals here and never read off disk, goes through the SAME judge the
# live scan uses, in BOTH directions. Five docs MUST be reported, one per assertion
# plus one per open-row marker and one hiding its row behind a fence, and two MUST
# NOT; [94] and [95] each state this at their own control. THE CONTROL TAKES ITS GOOD
# STATUS OUT OF THE PARSED VOCABULARY rather than writing one here, so it cannot
# become the second copy of the values (a) exists to avoid.
yellow "[98] every work-doc's status is one the template declares, and an archived doc's phase ledger is closed"
# WHY docs/work/ AND NOT THE LIVE PATHSPEC THE NEIGHBOURS USE. [91], [93], [94] and
# [95] all scan with a three-part pathspec that EXCLUDES docs/work/, because for them
# the sprint record has to be able to quote a broken doc. This check is the one whose
# subjects ARE the work-docs, so copying that pathspec would collapse the subject set
# to zero and print a confident green over nothing. Tracked files only, so a
# half-written doc open in an editor is never judged.
#
# THE FLOORS ARE WHAT STOP A VACUOUS PASS, judged before any per-doc red prints, the
# order [91], [93], [94] and [95] all argue for: a collapsed vocabulary makes every
# doc look wrong, and replaying the reds first would bury the line explaining them.
# HOW EACH WAS DERIVED, and the command that re-derives it:
#
#   WL_DOC_FLOOR, half the work-docs tracked on 2026-08-25. Half, because docs are
#   added most waves and none has ever been deleted, so only a collapse toward zero
#   means the pathspec stopped matching.
#     git ls-files -- 'docs/work/*.md' | wc -l
#
#   WL_VOCAB_FLOOR, half the values the template row declares today. Half, for the
#   same reason [94] floors the template's heading count at 12 against 23: the list
#   legitimately gains and loses a value, and only a collapse means the row grammar
#   stopped matching. The command splits the SAME cell this check reads and counts
#   the pieces, rather than counting lines that happen to carry the word.
#     awk -F'|' '$2 ~ /`status`/ {print split($3, v, "/")}' \
#       skills/hackify/references/work-doc-template.md
#
#   WL_LEDGER_FLOOR, the exact count of assertion (b)'s subjects today. THE FLOOR IS
#   ON THE ARCHIVED SUBSET AND NOT ON THE TOTAL, deliberately: a floor over the total
#   would sit under a grammar break that lost only the archived doc, the half (b)
#   actually judges. NO HEADROOM, because docs enter done/ and never leave, so the
#   count can only rise. THE REASON IS NOT that every doc written since the ledger
#   shipped carries one: section 0 became a work-doc section on 2026-08-23 and the
#   archived docs written since do not all have it, so this floor sits close under a
#   small count and any wave archiving another ledger-bearing doc must raise it.
#     git grep -l '^## 0\. Phase ledger' -- 'docs/work/done/*.md' | wc -l
#
# NO COUNT IS WRITTEN INTO A COMMENT HERE. The live totals print on the pass line and
# every floor carries the command that re-derives it, the convention
# 57-doc-links.sh:20-26 states: an unpinned number in a comment is a rotting claim.
WL_DOC_FLOOR=10
WL_VOCAB_FLOOR=4
WL_LEDGER_FLOOR=1

WL_DOCS=0
WL_VOCAB=0
WL_LEDGERS=0
WL_ARCHIVED=0
WL_CONTROL=none

wl_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

wl_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r WL_DOCS WL_VOCAB WL_LEDGERS WL_ARCHIVED <<<"${line#SIZE }" ;;
      'CONTROL '*) WL_CONTROL=${line#CONTROL } ;;
    esac
  done <<<"$1"
}

# The vocabulary floor is judged FIRST, being reference data and not corpus: when it
# collapses every status resolves to nothing and a docs-side diagnosis misleads.
wl_floors_hold() {
  if [ "$WL_VOCAB" -lt "$WL_VOCAB_FLOOR" ]; then
    wl_fail "[98] the template parse read $WL_VOCAB status value(s) against a floor of $WL_VOCAB_FLOOR; the frontmatter-reference row or the template path stopped matching, and every work-doc's status would resolve against an empty vocabulary"
    return 1
  fi
  if [ "$WL_DOCS" -lt "$WL_DOC_FLOOR" ]; then
    wl_fail "[98] the work-doc scan read $WL_DOCS tracked doc(s) under docs/work/ against a floor of $WL_DOC_FLOOR; the pathspec stopped matching, and a scan over nothing measures nothing"
    return 1
  fi
  if [ "$WL_ARCHIVED" -lt "$WL_LEDGER_FLOOR" ]; then
    wl_fail "[98] the scan found $WL_ARCHIVED archived doc(s) carrying a section 0 phase ledger against a floor of $WL_LEDGER_FLOOR; the ledger heading stopped matching, so assertion (b) judged nothing and its silence means nothing"
    return 1
  fi
  return 0
}

# THE CONTROL IS JUDGED AFTER THE FLOORS AND BEFORE THE GREEN, never instead of the
# per-doc walk, the order [94] and [95] both take. A real finding must still be
# reported on a run whose control has broken, so a failed control counts as a finding
# like any other: it prints, it bumps the status, and it takes the pass line with it.
# WL_CONTROL starts at `none`, so a control that never ran cannot look like one that
# held.
wl_control_holds() {
  [ "$WL_CONTROL" = ok ] && return 0
  wl_fail "[98] the positive control did not hold (control verdict: $WL_CONTROL). A synthetic seven-doc corpus built from literals in this fragment must report exactly the five docs that break something, a bad status value, a live doc claiming it was archived, an archived doc holding each of the two open ledger markers, and one hiding its open row behind a fenced heading, and must report neither of the two clean docs beside them. Until that separates, this run's silence is not evidence of anything: a judge that had stopped discriminating would print the same nothing"
  return 1
}

# AND NO GREEN PRINTS BESIDE A RED, [91]'s rule verbatim: a summary contradicting the
# failure above it is the fail-open shape this fragment refuses, so the pass line is
# reached only when nothing failed.
wl_verdict() {
  local line bad=0
  wl_read_size "$1"
  wl_floors_hold || return
  wl_control_holds || bad=$((bad + 1))
  while IFS= read -r line; do
    case "$line" in
      'FAIL '*) wl_fail "${line#FAIL }"; bad=$((bad + 1)) ;;
    esac
  done <<<"$1"
  [ "$bad" -eq 0 ] || return
  green "  ok   all $WL_DOCS tracked work-doc(s) carry a status the template's $WL_VOCAB declared value(s) allow, sit in the directory that status implies, and close every phase-ledger row before archiving ($WL_LEDGERS section 0 ledger(s) found, $WL_ARCHIVED of them archived and judged), and the positive control separated its reported docs from its clean ones before that silence was trusted"
}

if ! command -v python3 > /dev/null 2>&1; then
  wl_fail "[98] needs python3 to parse work-doc frontmatter, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, per the tie-breaker at
  # 73-implementer-rename.sh:174-195. A python traceback exits non-zero and writes to
  # stderr, and a bare $(...) capture swallows both, leaving this block to read an
  # empty result as "no work-doc is out of step". A FAIL-CLOSED BRANCH OUTRANKS A HIT
  # REPORT: a scan that could not finish says nothing trustworthy about what it did
  # print.
  wl_err=$(mktemp 2>/dev/null) || wl_err=''
  if [ -z "$wl_err" ]; then
    wl_fail "[98] could not create the stderr capture file, so the work-doc scan never ran"
  else
    wl_out=$(python3 - 2>"$wl_err" <<'WL_PY'
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
LEDGER_HEAD = '## 0. Phase ledger'
HEADING = '## '
FENCE = '---'
STATUS_KEY = 'status:'
STATUS_CELL = '%sstatus%s' % (TICK, TICK)
ARCHIVED_STATUS = 'done'
OPEN_ROWS = ('- [ ]', '- [>]')
CODE_FENCE = TICK * 3
FENCES = (CODE_FENCE, '~~~')
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


def first_prefix(line, options):
    """The first entry of `options` this line opens with, or None. One helper for
    the fence tracker and the open-row walk, so neither grows a nesting level and
    neither carries a second copy of the same scan."""
    for option in options:
        if line.startswith(option):
            return option
    return None


def unfenced(lines):
    """A copy of `lines` with every line inside a fenced code block blanked, so a
    quoted heading cannot shadow the real ledger or end its block early.

    COVERED: a fence opening on a line starting with three backtick characters or
    three tildes, closing on the next line starting with the SAME marker. NOT COVERED:
    fence length, a fence indented into a list, a marker inside an info string; a doc
    written those ways is judged as if the fence were not there. BLANKED AND NOT
    DROPPED, so every index still equals its line number and a finding cites the line
    the reader opens. The frontmatter is untouched: its opening fence marker is
    not a code fence."""
    out = []
    marker = None
    for line in lines:
        if marker is not None:
            marker = None if line.startswith(marker) else marker
            out.append('')
            continue
        marker = first_prefix(line, FENCES)
        out.append('' if marker else line)
    return out


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


def ledger_start(lines):
    """The index of the section 0 heading, or None when the doc carries none. Reads
    the fence-masked copy, so a heading quoted in a code block above the real ledger
    cannot become the block that gets judged."""
    for num, line in enumerate(lines):
        if line.startswith(LEDGER_HEAD):
            return num
    return None


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


def judge_ledger(path, lines):
    """Assertion (b) for one doc. Returns (findings, whether it was a subject).

    A doc outside the archive is not a subject, and neither is an archived doc with
    no section 0. The block runs from that heading to the NEXT heading of any name,
    for the reason the header gives about the groom path."""
    if not path.startswith(ARCHIVE):
        return ([], False)
    low = ledger_start(lines)
    if low is None:
        return ([], False)
    out = []
    for num in range(low + 1, len(lines)):
        if lines[num].startswith(HEADING):
            break
        mark = first_prefix(lines[num].strip(), OPEN_ROWS)
        if mark:
            out.append('%s:%d carries an open %s row inside its %s block while the '
                       'file sits under %s, so an archived work-doc still shows a '
                       'phase nobody closed: %s'
                       % (path, num + 1, mark, LEDGER_HEAD, ARCHIVE,
                          lines[num].strip()[:70]))
    return (out, True)


def judge(path, lines, allowed):
    """Every finding for one doc, through the three assertions. Returns
    (findings, carries a ledger, is an assertion (b) subject).

    THE FENCE MASK IS APPLIED ONCE, HERE, and every reader below judges that same
    copy, so a doc reaches WL_ARCHIVED only when its real ledger was judged."""
    body = unfenced(lines)
    out = judge_status(path, frontmatter_field(body, STATUS_KEY), allowed)
    rows, subject = judge_ledger(path, body)
    out.extend(rows)
    return (out, ledger_start(body) is not None, subject)


def control_docs(good):
    """The seven synthetic work-docs the control judges, as (path, body, reported).

    Source literals only, none read off disk, so no document can change what this
    proves. `good` comes from the PARSED vocabulary rather than being written here,
    which keeps this from becoming the second copy of the values (a) reads out."""
    head = FENCE + '\nslug: zzq-control\nstatus: %s\n' + FENCE + '\n\nbody\n'
    ledger = (FENCE + '\nslug: zzq-control\nstatus: ' + ARCHIVED_STATUS + '\n' + FENCE
              + '\n\n' + LEDGER_HEAD + '\n\n%s Phase 1. Clarify\n\n'
              + '## Groom Provenance\n\nnotes\n\n## 1. Original ask\n\nbody\n')
    # BOTH OPEN MARKERS GET A CASE; exercising one left (b)'s other half with no
    # control. The rows are WRITTEN OUT, not read from OPEN_ROWS: a control built from
    # the constant it tests moves with a tamper on it and stays green while the judge
    # goes blind, so a marker added there owes a case here. The decoy separates only
    # while the fence mask works: shadow the heading search and the walk breaks at
    # once, blind the terminator and its fenced heading ends the block above the row.
    decoy = (FENCE + '\nslug: zzq-control\nstatus: ' + ARCHIVED_STATUS + '\n' + FENCE
             + '\n\n' + CODE_FENCE + '\n' + LEDGER_HEAD + '\n' + CODE_FENCE + '\n\n'
             + LEDGER_HEAD + '\n\n' + CODE_FENCE + '\n' + HEADING + 'fenced\n'
             + CODE_FENCE + '\n\n%s Phase 1. Clarify\n\n## 1. Original ask\n\nbody\n')
    return (('docs/work/zzq-bad-status.md', head % CONTROL_BAD, True),
            ('docs/work/zzq-live-archived.md', head % ARCHIVED_STATUS, True),
            ('docs/work/done/zzq-open-ledger.md', ledger % '- [>]', True),
            ('docs/work/done/zzq-todo-ledger.md', ledger % '- [ ]', True),
            ('docs/work/done/zzq-fenced-decoy.md', decoy % '- [ ]', True),
            ('docs/work/zzq-clean.md', head % good, False),
            ('docs/work/done/zzq-closed-ledger.md', ledger % '- [x]', False))


def control(allowed):
    """True when a corpus whose verdicts are known is judged exactly that way.

    BOTH DIRECTIONS, for the reason the header gives: five docs MUST be reported and
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
        found = judge(path, body.split('\n'), allowed)[0]
        if bool(found) != reported:
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
    docs = ledgers = subjects = 0
    findings = []
    for path in paths:
        refusal = refuse_read(path)
        if refusal:
            findings.append(refusal)
            continue
        if not os.path.isfile(path):
            continue
        docs += 1
        out, has_ledger, subject = judge(path, read(path).split('\n'), allowed)
        findings.extend(out)
        ledgers += 1 if has_ledger else 0
        subjects += 1 if subject else 0
    for line in findings:
        print('FAIL %s' % line)
    print('CONTROL %s' % ('ok' if control(allowed) else 'fail'))
    print('SIZE %d %d %d %d' % (docs, len(allowed), ledgers, subjects))


ALLOWED = vocabulary()
scan(work_docs(), ALLOWED)
WL_PY
)
    wl_rc=$?
    wl_errtxt=$(cat "$wl_err")
    rm -f "$wl_err"
    if [ "$wl_rc" -ne 0 ] || [ -n "$wl_errtxt" ]; then
      wl_fail "[98] the work-doc scan did not finish (rc $wl_rc), so its silence is not a verdict: ${wl_errtxt:-no stderr, non-zero exit}"
    else
      wl_verdict "$wl_out"
    fi
  fi
fi

# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [98] WORK-DOC LEDGER SYNC. A work-doc's section 0 phase ledger is a statement about
# where the work stands, and it is decidable by reading the tree. A doc under
# docs/work/done/ says the sprint finished; an open row in its section 0 says a phase
# never closed. Both cannot be true. This block resolves TWO SUCH STATEMENTS, each
# about the section 0 BLOCK, and reds when one stops being true.
#
#   (b) AN ARCHIVED DOC IS FINISHED. A doc under docs/work/done/ carrying a section
#       0 phase ledger must show no open row in that block. An open row there is a
#       phase nobody closed, behind a filename saying the sprint is over.
#
#   (d) AN ARCHIVED DOC WRITTEN SINCE THE LEDGER SHIPPED HAS ONE. Assertion (b)
#       judges the rows of a block and says nothing about a doc carrying no block at
#       all, which made DELETING section 0 a way to turn a red green. So a doc under
#       docs/work/done/ that resolves to the day section 0 became a work-doc section,
#       or later, MUST carry the heading. Older docs predate the mechanism and are
#       not subjects.
#
# WHAT RESOLVES A DOC TO A DATE, AND THE TWO LEVERS THAT STAY OPEN. The date is read
# off the FILENAME first, the YYYY-MM-DD prefix every work-doc is opened under per the
# `Create the work-doc` step of skills/hackify/SKILL.md, NAMED BY STEP AND NOT BY LINE
# because [57] proves only that a cited line exists, never that it still says what
# cites it. It reads the frontmatter created field only when the name carries no
# prefix. It was the created field alone until a reviewer changed one digit and
# watched an archived doc with no section 0 go green: a value a document writes about
# itself is a value it can choose, and letting it decide whether the document is a
# subject at all is CWE-807. Where both exist and disagree, the disagreement is itself
# reported. NEITHER LEVER BELOW IS CLOSED. RENAMING the file to a pre-pin prefix moves
# the date. DROPPING the prefix falls back to the frontmatter value. No other fragment
# reads the work-doc naming convention, so nothing else catches either one. What the
# change buys is that both levers surface in a diff as a rename or a new path, which
# an edit inside a file does not. A doc whose created field is missing or unreadable
# is REPORTED, never dropped, since deleting that field would be the same escape one
# level up.
#
# THE LETTERS ARE (b) AND (d), WITH NO (a) OR (c) IN THIS FILE, and that is a
# reference and not a gap. This fragment reached 498 of a 500-LOC cap and could not
# take assertion (d), so the two assertions that read FRONTMATTER moved to
# 99-work-doc-status-claims.sh and kept their letters, the way [76g] and [76h] kept
# theirs when 96-review-scope-sites.sh was carved out of 76. (a) is the status
# vocabulary, (c) is a live doc claiming it was archived, and ONLY (c) is cited by
# letter, from skills/hackify/references/phase-ledger.md and finish.md. A sweep of
# skills/ finds no citation of (a) at all, which this header used to claim there was.
#
# WHY THE SEAM IS HERE, AND WHAT IT COSTS, is written once at the top of
# 99-work-doc-status-claims.sh and not repeated here: two copies of a rationale drift
# apart, the reason 79-standing-member-invariant.sh:24 gives for making the same choice.
#
# [98] KEEPS THIS ID AND THIS FILENAME, since (b) and (d) are the two ledger assertions
# and the CHANGELOG bullet that opens "[98] and [99]" names this filename for the
# archived-sprint behaviour (b) carries. IT IS ANCHORED ON THAT NAME AND NOT ON A LINE
# NUMBER: the line this header used to cite was wrong the day it was written and turned
# right by accident a commit later, which is worse than plain rot because nothing about
# it looks broken.
#
# WHAT ASSERTION (b) DOES NOT REACH, because silence gets read as a guarantee. A
# closed `- [x]` row cannot be told apart from a phase dropped and ticked anyway.
# docs/work/done/2026-08-23-phase-ledger-substrate.md:29 is a live example, a closed
# Phase 6d row with the words "never ran" beside it. A GREEN HERE MEANS NO ROW IS
# OPEN, never that an archived sprint ran the phases it ticked.
#
# NOTHING SOURCED FROM A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN. Every
# pattern below is a literal in this file; a date is shape-gated against one of those
# literals and then compared with `<` against a literal date, never anything else. A
# validator building its matcher out of a document's contents would be arbitrary code
# execution by editing that document, the guardrail this whole sprint is written
# around. Reading obeys the same rule: no path is opened until it resolves to itself
# under the repository root, so a tracked symlink is refused and REPORTED rather than
# followed out of the tree.
#
# THE LEDGER BLOCK IS FOUND AND ENDED OUTSIDE FENCED CODE, and it ends at the next
# `## ` heading of any name, never at `## 1.`. Both halves are measured. The groom
# path inserts a `## Groom Provenance` section between section 0 and section 1,
# instructed by the full-mode branch at skills/groom/SKILL.md:67 and pinned by the
# section-order law at skills/hackify/references/work-doc-template.md:43, so a
# terminator keyed to the section-1 heading would swallow it on every groomed doc,
# a fenced heading above the real one would shadow it, and one inside the block
# would end it early. ROWS OUTSIDE THE BLOCK ARE NOT SUBJECTS: the Sprint Backlog
# writes its tasks in the identical `- [ ]` grammar and every archived doc carries one.
#
# WHY A POSITIVE CONTROL. On a truthful tree both assertions report nothing, and that
# silence is the SAME OUTPUT this check would print if its judging had quietly
# stopped. So it is earned first: a synthetic ten-doc corpus, built from source
# literals here and never read off disk, goes through the SAME judge the live scan
# uses, in BOTH directions. Six docs MUST be reported and four MUST NOT; [94] and
# [95] each state this at their own control.
yellow "[98] an archived work-doc closes every phase-ledger row, and one written since the ledger shipped has a section 0 at all"
# WHY docs/work/ AND NOT THE LIVE PATHSPEC THE NEIGHBOURS USE. [91], [93], [94] and
# [95] all scan with a three-part pathspec that EXCLUDES docs/work/, because for them
# the sprint record has to be able to quote a broken doc. This check's subjects ARE
# the work-docs, so copying that pathspec would collapse the subject set to zero and
# print a confident green over nothing. Tracked files only.
#
# THE FLOORS ARE WHAT STOP A VACUOUS PASS, judged before any per-doc red prints, the
# order [91], [93], [94] and [95] argue for. NEITHER SUBJECT BOUND TAKES THE INVERSION
# 92-work-doc-structure.sh takes at its WS_UNSECTIONED_MAX bullet, named by construct
# for the reason above; what differs is what they count. That bound was the ONLY one
# that could see its own collapse, where here (d) and the unreadable-date branch name a
# doc that lost its block or date first, and an unparseable date joins neither set a
# ceiling could be pinned on. HOW EACH WAS DERIVED, with the re-deriving command:
#
#   WL_DOC_FLOOR, half the work-docs tracked on 2026-08-25. Half, because docs are
#   added most waves and none has ever been deleted, so only a collapse toward zero
#   means the pathspec stopped matching.
#     git ls-files -- 'docs/work/*.md' | wc -l
#
#   WL_LEDGER_FLOOR, a RATCHET at assertion (b)'s subject count the day it was
#   derived, not "the exact count" this line promised over a `-lt`. It needs no raise:
#   docs enter done/ and never leave, so another archived ledger leaves it looser, and
#   the convention that demanded one per such doc is deleted, unobeyed. ON THE
#   ARCHIVED SUBSET, NOT THE TOTAL, which would sit under a grammar break that lost
#   only the archived doc, the half (b) judges; the pre-pin archives are exempt.
#     git grep -l '^## 0\. Phase ledger' -- 'docs/work/done/*.md' | wc -l
#
#   WL_CREATED_FLOOR, the same ratchet over assertion (d)'s subjects, a DIFFERENT SET
#   from the line above: (b) counts archived docs that HAVE a block, (d) counts archived
#   docs that OWE one, and the point of (d) is the second set. Counted off the filename,
#   which is what the judge resolves against.
#     git ls-files -- 'docs/work/done/*.md' | awk -F/ '$NF >= "2026-08-23"' | wc -l
#
# NO COUNT IS WRITTEN INTO A COMMENT HERE. The live totals print on the pass line and
# every floor carries the command that re-derives it, the convention
# 57-doc-links.sh:20-26 states: an unpinned number in a comment is a rotting claim.
WL_DOC_FLOOR=10
WL_LEDGER_FLOOR=7
WL_CREATED_FLOOR=7

WL_DOCS=0
WL_ARCHIVED=0
WL_DATED=0
WL_CONTROL=none

wl_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

wl_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r WL_DOCS WL_ARCHIVED WL_DATED <<<"${line#SIZE }" ;;
      'CONTROL '*) WL_CONTROL=${line#CONTROL } ;;
    esac
  done <<<"$1"
}

# The corpus floor is judged FIRST: both subject floors collapse with the doc scan.
wl_floors_hold() {
  if [ "$WL_DOCS" -lt "$WL_DOC_FLOOR" ]; then
    wl_fail "[98] the work-doc scan read $WL_DOCS tracked doc(s) under docs/work/ against a floor of $WL_DOC_FLOOR; the pathspec stopped matching, and a scan over nothing measures nothing"
    return 1
  fi
  if [ "$WL_ARCHIVED" -lt "$WL_LEDGER_FLOOR" ]; then
    wl_fail "[98] the scan found $WL_ARCHIVED archived doc(s) carrying a section 0 phase ledger against a floor of $WL_LEDGER_FLOOR; the ledger heading stopped matching, so assertion (b) judged nothing and its silence means nothing"
    return 1
  fi
  if [ "$WL_DATED" -lt "$WL_CREATED_FLOOR" ]; then
    wl_fail "[98] the scan resolved $WL_DATED archived doc(s) against the day section 0 became a work-doc section, against a floor of $WL_CREATED_FLOOR; the created-date read stopped matching, so assertion (d) judged nothing and a doc could drop its section 0 unseen"
    return 1
  fi
  return 0
}

# THE CONTROL IS JUDGED AFTER THE FLOORS AND BEFORE THE GREEN, never instead of the
# per-doc walk, the order [94] and [95] both take. A failed control counts as a
# finding like any other: it prints, it bumps the status, it takes the pass line with
# it. WL_CONTROL starts at `none`, so one that never ran cannot look like one that held.
wl_control_holds() {
  [ "$WL_CONTROL" = ok ] && return 0
  wl_fail "[98] the positive control did not hold (control verdict: $WL_CONTROL). A synthetic ten-doc corpus built from literals in this fragment must report exactly the six docs that break something, an archived doc holding each of the two open ledger markers, one hiding its open row behind a fenced heading, one dated after the ledger shipped with no section 0 at all, one whose created date cannot be read, and one filed under a post-pin filename while its frontmatter backdates itself under the pin; and it must report none of the four beside them, a closed ledger, a doc dated before the ledger shipped, one filed under a pre-pin filename that agrees with its frontmatter, and a live doc whose ledger is still open. Until that separates, this run's silence is not evidence of anything: a judge that had stopped discriminating would print the same nothing"
  return 1
}

# AND NO GREEN PRINTS BESIDE A RED, [91]'s rule verbatim: the pass line is reached
# only when nothing failed.
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
  green "  ok   all $WL_DOCS tracked work-doc(s) under docs/work/ close every phase-ledger row before archiving, and every archived doc written since section 0 shipped carries one ($WL_ARCHIVED archived ledger(s) judged, $WL_DATED archived doc(s) resolved against the pin date), and the positive control separated its reported docs from its clean ones before that silence was trusted"
}

if ! command -v python3 > /dev/null 2>&1; then
  wl_fail "[98] needs python3 to parse work-doc frontmatter, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, per the tie-breaker at
  # 73-implementer-rename.sh's wi_absent. A bare $(...) capture swallows a
  # traceback and leaves this block reading an empty result as "no work-doc is
  # out of step". A FAIL-CLOSED BRANCH OUTRANKS A HIT REPORT.
  wl_err=$(mktemp 2>/dev/null) || wl_err=''
  if [ -z "$wl_err" ]; then
    wl_fail "[98] could not create the stderr capture file, so the work-doc scan never ran"
  else
    wl_out=$(python3 - 2>"$wl_err" <<'WL_PY'
import io, os, re, subprocess, sys

# Every pattern here is a literal in this file. See the header.
#
# THE BACKTICK IS SPELLED chr(96) AND THE APOSTROPHE chr(39). This block is a
# heredoc inside a $(...) substitution, and bash parses a backtick in there as a
# legacy command substitution even when the heredoc is quoted, while a lone
# apostrophe is one more quote for the shell to count. [93] and [95] record the same
# trap: a literal one here is a parse error, a check that cannot run at all.
TICK = chr(96)
QUOTE = chr(39)
WORKDOCS = 'docs/work/*.md'
ARCHIVE = 'docs/work/done/'
LEDGER_HEAD = '## 0. Phase ledger'
HEADING = '## '
FENCE = '---'
CREATED_KEY = 'created:'
OPEN_ROWS = ('- [ ]', '- [>]')
CODE_FENCE = TICK * 3
FENCES = (CODE_FENCE, '~~~')
# The repository root, resolved once, so every work-doc path can be required to
# resolve back to itself underneath it. This fragment already runs from that root.
ROOT = os.path.realpath(os.getcwd())
# THE DAY SECTION 0 BECAME A WORK-DOC SECTION: commit b96d2db of 2026-08-23 11:13
# put LEDGER_HEAD into skills/hackify/references/work-doc-template.md, and 8fa8d58 of
# 13:02 that day gave it validator coverage. One date, so no doc can straddle it.
LEDGER_EPOCH = '2026-08-23'
# The shape gate on a date. An ISO date compares correctly with `<` once it has this
# exact shape, and a created value that fails the gate is REPORTED, never dropped.
DATE = re.compile(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
# The rule assertion (d) enforces, NAMED BY BULLET AND NOT BY LINE (header, on [57]).
LEDGER_LAW = ('the "No silent skip" bullet of the ordering law in '
              'skills/hackify/references/phase-ledger.md')


def read(path):
    with io.open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace')


def refuse_read(path):
    """The finding saying why this path was not opened, or None. os.path.isfile
    FOLLOWS a symlink, so a tracked symlink would be opened and whatever it points at
    quoted into a finding. Resolve first, then REPORT the refusal rather than skip
    it: a doc this check declines to read is not a doc that passed."""
    full = os.path.join(ROOT, path)
    real = os.path.realpath(full)
    if real == full and real.startswith(ROOT + os.sep) and not os.path.islink(full):
        return None
    return ('%s does not resolve to a plain file under the repository root (it '
            'reaches %s), so this check refused to follow it rather than read '
            'what it points at' % (path, real))


def first_prefix(line, options):
    """The first entry of `options` this line opens with, or None. One helper for
    the fence tracker and the open-row walk, so neither grows a nesting level."""
    for option in options:
        if line.startswith(option):
            return option
    return None


def unfenced(lines):
    """A copy of `lines` with every line inside a fenced code block blanked, so a
    quoted heading cannot shadow the real ledger or end its block early.

    COVERED: a fence opening on three backticks or three tildes, closing on the next
    line starting with the SAME marker. NOT COVERED: fence length, a fence indented
    into a list, a marker inside an info string. BLANKED AND NOT DROPPED, so every
    index still equals its line number. The frontmatter fence is not a code fence."""
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


def frontmatter_field(lines, key):
    """(value, line number) for one frontmatter key, or (None, 0).

    The block is the text between the first two fences at the top of the file. THE KEY
    IS REQUIRED AT COLUMN 0 OF THE RAW LINE: a created line indented inside a
    sprint_goal block scalar is a line of that scalar, not the document date."""
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


def filename_date(path):
    """The YYYY-MM-DD prefix of a work-doc's basename, or None when it has none.
    Sliced off the name and shape-gated against the DATE literal above."""
    stamp = path.rsplit('/', 1)[-1][:10]
    return stamp if DATE.match(stamp) else None


def ledger_start(lines):
    """The index of the section 0 heading, or None. Reads the fence-masked copy, so a
    heading quoted in a code block above the real one cannot become what is judged."""
    for num, line in enumerate(lines):
        if line.startswith(LEDGER_HEAD):
            return num
    return None


def judge_ledger(path, lines, low):
    """Assertion (b) for one doc. Returns (findings, whether it was a subject).

    A doc outside the archive is not a subject, and neither is an archived doc with no
    section 0, the hole assertion (d) closes. The block ends at the next heading."""
    if not path.startswith(ARCHIVE) or low is None:
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


def judge_created(path, found, has_ledger):
    """Assertion (d) for one doc. `found` is (value, line number) for the created
    key, the tuple grouping that keeps this inside the three-parameter cap.

    THE FILENAME DATE OUTRANKS THE FRONTMATTER ONE, for the reason the header gives.
    An unreadable date is a finding but NOT a subject, since counting it would let a
    tree of undated archives satisfy the floor while nothing was resolved."""
    if not path.startswith(ARCHIVE):
        return ([], False)
    value = found[0]
    if value is None or not DATE.match(value):
        return (['%s sits under %s and its frontmatter carries no %s field reading '
                 'as a YYYY-MM-DD date at column 0, so it cannot be resolved against '
                 '%s, the day section 0 became a work-doc section; removing that '
                 'field is not a way out of the section 0 rule'
                 % (path, ARCHIVE, CREATED_KEY.rstrip(':'), LEDGER_EPOCH)], False)
    stamp = filename_date(path)
    out = [] if stamp is None or stamp == value else [
        '%s:%d says %s %s while the filename it is filed under says %s, and the '
        'filename is what this doc is resolved against; a frontmatter date '
        'disagreeing with the name is the shape a backdated doc takes'
        % (path, found[1], CREATED_KEY.rstrip(':'), value, stamp)]
    resolved = stamp or value
    if resolved < LEDGER_EPOCH:
        return (out, False)
    if has_ledger:
        return (out, True)
    out.append('%s is archived and resolves to %s, on or after the day section 0 '
               'became a work-doc section, yet it carries no %s block; a phase that '
               'does not apply is marked completed with a skipped reason, never '
               'deleted, per %s' % (path, resolved, LEDGER_HEAD, LEDGER_LAW))
    return (out, True)


def judge(path, lines):
    """Every finding for one doc, through both assertions. Returns
    (findings, is an assertion (b) subject, is an assertion (d) subject).

    THE FENCE MASK IS APPLIED ONCE, HERE, so a doc counts toward either subject total
    only when the block actually judged is its real one."""
    body = unfenced(lines)
    low = ledger_start(body)
    out, subject_b = judge_ledger(path, body, low)
    rows, subject_d = judge_created(path, frontmatter_field(body, CREATED_KEY),
                                    low is not None)
    out.extend(rows)
    return (out, subject_b, subject_d)


# The control shapes, as source literals. THE OPEN MARKERS AND THE DATES ARE WRITTEN
# OUT rather than read from OPEN_ROWS or LEDGER_EPOCH: a control built from the
# constant it tests moves with a tamper on it and stays green while the judge blinds.
CTL_HEAD = FENCE + '\nslug: zzq-control\ncreated: %s\n' + FENCE + '\n\n'
# A ledger doc, with the groom section the block terminator has to survive.
CTL_LEDGER = (CTL_HEAD + LEDGER_HEAD + '\n\n%s Phase 1. Clarify\n\n'
              + '## Groom Provenance\n\nnotes\n\n## 1. Original ask\n\nbody\n')
# No section 0 at all, which is what assertion (d) reads the created date for.
CTL_PLAIN = CTL_HEAD + '## 1. Original ask\n\nbody\n'
# A closed ledger under frontmatter carrying no created key whatsoever.
CTL_UNDATED = (FENCE + '\nslug: zzq-control\n' + FENCE + '\n\n' + LEDGER_HEAD
               + '\n\n- [x] Phase 1. Clarify\n\n## 1. Original ask\n\nbody\n')
# The decoy separates only while both halves of the fence mask work.
CTL_DECOY = (CTL_HEAD + CODE_FENCE + '\n' + LEDGER_HEAD + '\n' + CODE_FENCE + '\n\n'
             + LEDGER_HEAD + '\n\n' + CODE_FENCE + '\n' + HEADING + 'fenced\n'
             + CODE_FENCE + '\n\n%s Phase 1. Clarify\n\n## 1. Original ask\n\nbody\n')
# Written out for the same reason the markers are: AFTER is past the pin, BEFORE under.
CTL_AFTER = '2026-08-24'
CTL_BEFORE = '2026-05-11'


def control_docs():
    """The ten synthetic work-docs the control judges, as (path, body, reported).

    Source literals only, so no document can change what this proves. BOTH OPEN
    MARKERS GET A CASE, and so does each direction of the date rule, filename half
    included: exercising one side of either left the other with no control at all."""
    return (('docs/work/done/zzq-open-ledger.md', CTL_LEDGER % (CTL_AFTER, '- [>]'), True),
            ('docs/work/done/zzq-todo-ledger.md', CTL_LEDGER % (CTL_AFTER, '- [ ]'), True),
            ('docs/work/done/zzq-fenced-decoy.md', CTL_DECOY % (CTL_AFTER, '- [ ]'), True),
            ('docs/work/done/zzq-no-ledger.md', CTL_PLAIN % CTL_AFTER, True),
            ('docs/work/done/zzq-undated.md', CTL_UNDATED, True),
            ('docs/work/done/zzq-closed-ledger.md', CTL_LEDGER % (CTL_AFTER, '- [x]'), False),
            ('docs/work/done/zzq-predates.md', CTL_PLAIN % CTL_BEFORE, False),
            ('docs/work/done/2026-08-24-zzq-backdated.md', CTL_PLAIN % CTL_BEFORE, True),
            ('docs/work/done/2026-05-11-zzq-early.md', CTL_PLAIN % CTL_BEFORE, False),
            ('docs/work/zzq-live-open.md', CTL_LEDGER % (CTL_AFTER, '- [>]'), False))


def control():
    """True when a corpus whose verdicts are known is judged exactly that way.

    BOTH DIRECTIONS: six docs MUST be reported and four MUST NOT, so always-pass and
    always-fail both show up. Every case runs the SAME judge() the live scan uses."""
    for path, body, reported in control_docs():
        found = judge(path, body.split('\n'))[0]
        if bool(found) != reported:
            return False
    return True


def work_docs():
    """Tracked work-docs, by argv list and never through a shell.

    docs/work/ is deliberately IN scope; see the header. -z AND SPLIT ON NUL: under
    git's default core.quotePath a path holding a non-ASCII byte, a double quote or a
    backslash comes back C-quoted, stops ending in .md and drops out of the corpus
    unseen. A NUL record is never quoted and never escaped."""
    proc = subprocess.run(['git', 'ls-files', '-z', '--', WORKDOCS],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode('utf-8', 'replace'))
        raise SystemExit('git ls-files failed with rc %d' % proc.returncode)
    names = proc.stdout.decode('utf-8', 'replace').split('\0')
    return [p for p in names if p.endswith('.md')]


def one_line(text):
    """A finding, flattened to one physical line. git ls-files can legitimately
    return a path holding a newline, and the shell above reads this output line by
    line, so an unescaped one would split a finding and drop its reason."""
    return text.replace(chr(10), '\\n').replace(chr(13), '\\r')


def scan(paths):
    """Judge every doc, report what it found, then print CONTROL and SIZE."""
    docs = archived = dated = 0
    findings = []
    for path in paths:
        refusal = refuse_read(path)
        if refusal:
            findings.append(refusal)
            continue
        if not os.path.isfile(path):
            continue
        docs += 1
        out, subject_b, subject_d = judge(path, read(path).split('\n'))
        findings.extend(out)
        archived += 1 if subject_b else 0
        dated += 1 if subject_d else 0
    for line in findings:
        print('FAIL %s' % one_line(line))
    print('CONTROL %s' % ('ok' if control() else 'fail'))
    print('SIZE %d %d %d' % (docs, archived, dated))


scan(work_docs())
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

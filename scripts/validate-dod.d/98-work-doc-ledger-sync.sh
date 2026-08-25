# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [98] WORK-DOC LEDGER SYNC. A work-doc's frontmatter and its phase ledger are
# both statements about where the work stands, and each one is decidable by
# reading the tree. A doc filed under docs/work/done/ says the sprint finished;
# an open row in its section 0 says a phase never closed. Both cannot be true.
# This block resolves three such statements and reds when one of them stops
# being true.
#
# THE THREE ASSERTIONS, AND WHY EACH IS DECIDABLE.
#
#   (a) STATUS VOCABULARY. Every work-doc's frontmatter status value must be one
#       the template declares. skills/hackify/references/work-doc-template.md is
#       the DECLARING site and each work-doc is a CLAIMING site, the same shape
#       [93] resolves for prompt inputs. The allowed list is READ OUT of the
#       template at runtime, from the one frontmatter-reference row whose first
#       cell names the status field, so retiring a value there retires it here
#       with no second copy to keep in step.
#
#   (b) AN ARCHIVED DOC IS FINISHED. A doc under docs/work/done/ carrying a
#       section 0 phase ledger must show no open row in that block. An open row
#       in an archived doc is a phase the writer never closed, sitting behind a
#       filename that says the sprint is over.
#
#   (c) A LIVE DOC IS NOT ARCHIVED. A doc that is NOT under docs/work/done/ must
#       not carry the archived status value. The directory and the frontmatter
#       have to agree, and this is the half that catches a doc marked finished
#       and then left where it was.
#
# THE VOCABULARY IS PARSED STRUCTURALLY AND COMPARED BY STRING EQUALITY. The
# template row lists its values inside backticks with a slash between them. Each
# one is split out, stripped of its backticks, and shape-gated against a pattern
# that is a literal in this file. What comes back is compared to a document's
# status with `==` and nothing else. NOTHING SOURCED FROM A REPO FILE IS
# EXECUTED OR COMPILED INTO A PATTERN. A validator that built its matcher out of
# a document's contents would be arbitrary code execution by editing that
# document, which is the guardrail this whole sprint is written around.
#
# THE LEDGER BLOCK ENDS AT THE NEXT `## ` HEADING OF ANY NAME, NEVER AT `## 1.`,
# and that is measured rather than tidy. The groom path inserts a
# `## Groom Provenance` section between section 0 and section 1, documented at
# skills/hackify/references/phase-ledger.md:43 and again at
# skills/hackify/references/work-doc-template.md:42. A terminator keyed to the
# section-1 heading swallows that block on every groomed doc, so an open row
# written under Groom Provenance would be read as a ledger row and an ordinary
# groomed doc would red for a reason that is not about its ledger.
#
# ROWS OUTSIDE THE BLOCK ARE NOT SUBJECTS, and this is the other half of the same
# rule. The Sprint Backlog writes its tasks in the identical `- [ ]` grammar, and
# every archived doc carries one. A scan that counted open rows file-wide would
# red on all of them, which is the fabrication this sprint exists to refuse.
#
# WHY A POSITIVE CONTROL. On a truthful tree all three assertions report nothing,
# and that silence is the SAME OUTPUT this check would print if its judging had
# quietly stopped working: a vocabulary that parsed to nothing, a frontmatter
# reader that stopped finding the field, a block finder that stopped matching the
# heading. So the silence is earned before it is trusted. A synthetic five-doc
# corpus, built from source literals in this file and never read off disk, goes
# through the SAME judge the live scan uses, and it carries BOTH directions: three
# docs that MUST be reported, one per assertion, and two that MUST NOT. A
# one-sided control would catch a comparison that degraded to always-pass and miss
# one that degraded to always-fail. [94] states the same reasoning at its own
# control and [95] at its own, and both are the precedent for this shape.
#
# THE CONTROL TAKES ITS GOOD STATUS OUT OF THE PARSED VOCABULARY rather than
# writing one here, so the control cannot become the second copy of the eight
# values that assertion (a) exists to avoid.
yellow "[98] every work-doc's status is one the template declares, and an archived doc's phase ledger is closed"

# WHY docs/work/ AND NOT THE LIVE PATHSPEC THE NEIGHBOURS USE. [91], [93], [94]
# and [95] all scan with a three-part pathspec that EXCLUDES docs/work/, because
# for them the sprint record is a place that has to be able to quote a broken
# doc. This check is the one whose subjects ARE the work-docs, so copying that
# pathspec here would collapse the subject set to zero and print a confident
# green over nothing. Tracked files only, through git ls-files with an argv list
# and no shell, so a half-written doc open in an editor is not judged and no
# path is ever handed to a command line.
#
# THE FLOORS ARE WHAT STOP A VACUOUS PASS, and they are judged before any per-doc
# red prints, the order [91], [93], [94] and [95] all argue for. A vocabulary that
# collapsed makes every doc in the tree look wrong, so replaying the per-doc reds
# first would bury the one line that explains them under twenty false accusations.
#
# HOW EACH FLOOR WAS DERIVED, and the command that re-derives it.
#
#   WL_DOC_FLOOR, half of the 20 work-docs tracked on 2026-08-25. Half, because
#   docs are added most waves and none has ever been deleted, so only a collapse
#   toward zero means the pathspec stopped matching.
#     git ls-files -- 'docs/work/*.md' | wc -l
#
#   WL_VOCAB_FLOOR, half of the 8 values the template row declares today. Half,
#   for the same reason [94] floors the template's heading count at 12 against 23:
#   the list legitimately gains and loses a value, and only a collapse means the
#   row grammar stopped matching. The command below splits the SAME cell this
#   check reads and counts the pieces, so it re-derives the figure rather than
#   counting lines that happen to carry the word.
#     awk -F'|' '$2 ~ /`status`/ {print split($3, v, "/")}' \
#       skills/hackify/references/work-doc-template.md
#
#   WL_LEDGER_FLOOR, the exact count of assertion (b)'s subjects today, which is
#   1. Two work-docs carry a section 0 ledger, since the ledger shipped on
#   2026-08-23, and exactly ONE of the two sits under docs/work/done/. THE FLOOR
#   IS ON THE ARCHIVED SUBSET AND NOT ON THE TOTAL, deliberately: a floor of 1
#   over the total of 2 would sit under a grammar break that lost only the
#   archived doc, which is the half assertion (b) actually judges. No headroom is
#   needed because the count cannot shrink, docs enter done/ and never leave, and
#   every doc created since 2026-08-23 carries a ledger.
#     git grep -l '^## 0\. Phase ledger' -- 'docs/work/done/*.md' | wc -l
#
# The live totals are PRINTED on the pass line every run rather than restated
# here. A count written into a comment goes stale the first wave that adds a
# doc, and a stale count inside the check built to catch stale counts is the
# defect wearing the uniform. 57-doc-links.sh:20-26 sets this convention.
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

# The vocabulary floor is judged FIRST, because it is this check's reference data
# rather than part of the corpus. When it collapses, every status in the tree
# resolves to nothing and a docs-side diagnosis would name the wrong cause.
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

# THE CONTROL IS JUDGED AFTER THE FLOORS AND BEFORE THE GREEN, never instead of
# the per-doc walk, the order [94] and [95] both take. A real finding must still
# be reported on a run whose control has broken, so a failed control counts as a
# finding like any other: it prints, it bumps the status, and it takes the pass
# line with it. WL_CONTROL starts at `none` so a control that never ran at all
# cannot be mistaken for one that held.
wl_control_holds() {
  [ "$WL_CONTROL" = ok ] && return 0
  wl_fail "[98] the positive control did not hold (control verdict: $WL_CONTROL). A synthetic five-doc corpus built from literals in this fragment must report exactly the three docs that break one assertion each, a bad status value, a live doc claiming it was archived, and an archived doc with an open ledger row, and must report neither of the two clean docs beside them. Until that separates, this run's silence is not evidence of anything: a judge that had stopped discriminating would print the same nothing"
  return 1
}

# AND NO GREEN PRINTS BESIDE A RED, [91]'s rule verbatim. A summary that
# contradicts the failure above it is the fail-open shape this fragment exists to
# refuse, so the pass line is reached only when nothing failed.
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
  # 73-implementer-rename.sh:174-195. A python traceback exits non-zero and writes
  # to stderr, and a bare $(...) capture swallows both, leaving this block to read
  # an empty result as "no work-doc is out of step". A FAIL-CLOSED BRANCH OUTRANKS
  # A HIT REPORT: a scan that could not finish tells the reader nothing trustworthy
  # about what it did manage to print.
  wl_err=$(mktemp 2>/dev/null) || wl_err=''
  if [ -z "$wl_err" ]; then
    wl_fail "[98] could not create the stderr capture file, so the work-doc scan never ran"
  else
    wl_out=$(python3 - 2>"$wl_err" <<'WL_PY'
import io, os, re, subprocess, sys

# Every pattern here is a literal in this file. See the header.
#
# THE BACKTICK IS SPELLED chr(96) AND THE APOSTROPHE chr(39), AND NEITHER IS AN
# AFFECTATION. This block is a heredoc inside a $(...) command substitution, and
# bash parses a backtick in there as a legacy command substitution even when the
# heredoc is quoted, while a lone apostrophe inside a double-quoted python string
# is one more quote for the shell to count across the whole substitution. [93] and
# [95] both record the backtick trap and the same fix: a literal one in this source
# is a parse error in the fragment, which is a check that cannot run at all rather
# than one that runs wrong.
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


def cells(line):
    """The pipe-separated cells of one markdown table row, trimmed."""
    return [part.strip() for part in line.strip().strip('|').split('|')]


def vocabulary():
    """The status values the template declares, read out of its own table row.

    STRUCTURAL, never a substring hunt. The row is the one whose FIRST cell names
    the status field, and the values are its SECOND cell split on the slash. Every
    piece is stripped of backticks and then shape-gated, and what survives is only
    ever compared with `==`. A value mentioned in the template's prose declares
    nothing, the same reading [94] applies to that file's headings.

    An empty set is returned rather than raised, so the shell floor reports the
    collapse in its own words instead of a traceback naming a line number."""
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


def frontmatter_status(lines):
    """(value, line number) out of the frontmatter block, or (None, 0).

    The block is the text between the first two fences at the top of the file. A
    status line written below that is body prose and declares nothing."""
    if not lines or lines[0].strip() != FENCE:
        return (None, 0)
    for num in range(1, len(lines)):
        body = lines[num].strip()
        if body == FENCE:
            return (None, 0)
        if not body.startswith(STATUS_KEY):
            continue
        value = body[len(STATUS_KEY):].strip().strip(TICK).strip('"').strip(QUOTE)
        return (value, num + 1)
    return (None, 0)


def ledger_start(lines):
    """The index of the section 0 heading, or None when the doc carries none."""
    for num, line in enumerate(lines):
        if line.startswith(LEDGER_HEAD):
            return num
    return None


def open_mark(body):
    """The open-row marker this line opens with, or None. Split out of the walk
    below so that walk keeps one level of nesting rather than two."""
    for mark in OPEN_ROWS:
        if body.startswith(mark):
            return mark
    return None


def judge_status(path, found, allowed):
    """Assertions (a) and (c) for one doc. `found` is (value, line number).

    The tuple keeps this inside the three-parameter cap, the same grouping [93]'s
    _report_uses and [94]'s scan() both use.

    An EMPTY `allowed` suppresses the vocabulary sentence and nothing else. The
    template parse having collapsed is reported by the shell floor, and accusing
    every doc in the tree on top of it would bury the one line that explains the
    run under twenty that do not."""
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

    A doc outside the archive is not a subject, and neither is an archived doc
    carrying no section 0. The block runs from that heading to the NEXT heading of
    any name, for the reason the header gives about the groom path."""
    if not path.startswith(ARCHIVE):
        return ([], False)
    low = ledger_start(lines)
    if low is None:
        return ([], False)
    out = []
    for num in range(low + 1, len(lines)):
        if lines[num].startswith(HEADING):
            break
        mark = open_mark(lines[num].strip())
        if mark:
            out.append('%s:%d carries an open %s row inside its %s block while the '
                       'file sits under %s, so an archived work-doc still shows a '
                       'phase nobody closed: %s'
                       % (path, num + 1, mark, LEDGER_HEAD, ARCHIVE,
                          lines[num].strip()[:70]))
    return (out, True)


def judge(path, lines, allowed):
    """Every finding for one doc, through the three assertions. Returns
    (findings, carries a ledger, is an assertion (b) subject)."""
    out = judge_status(path, frontmatter_status(lines), allowed)
    rows, subject = judge_ledger(path, lines)
    out.extend(rows)
    return (out, ledger_start(lines) is not None, subject)


def control_docs(good):
    """The five synthetic work-docs the control judges, as (path, body, reported).

    Source literals only, and none of it is read off disk, so no document can
    change what this proves. `good` is taken from the PARSED vocabulary rather
    than written here, which is what keeps this from becoming the second copy of
    the values assertion (a) exists to read out of one place."""
    head = FENCE + '\nslug: zzq-control\nstatus: %s\n' + FENCE + '\n\nbody\n'
    ledger = (FENCE + '\nslug: zzq-control\nstatus: ' + ARCHIVED_STATUS + '\n' + FENCE
              + '\n\n' + LEDGER_HEAD + '\n\n%s Phase 1. Clarify\n\n'
              + '## Groom Provenance\n\nnotes\n\n## 1. Original ask\n\nbody\n')
    return (('docs/work/zzq-bad-status.md', head % CONTROL_BAD, True),
            ('docs/work/zzq-live-archived.md', head % ARCHIVED_STATUS, True),
            ('docs/work/done/zzq-open-ledger.md', ledger % OPEN_ROWS[1], True),
            ('docs/work/zzq-clean.md', head % good, False),
            ('docs/work/done/zzq-closed-ledger.md', ledger % '- [x]', False))


def control(allowed):
    """True when a corpus whose verdicts are known is judged exactly that way.

    BOTH DIRECTIONS, for the reason the header gives. Three docs MUST be reported,
    one per assertion, and two MUST NOT, so a judge that degraded to always-pass
    and one that degraded to always-fail both show up here. Every case goes through
    the SAME judge() the live scan uses; a control exercising a copy would stay
    green while the shipped path rotted."""
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

    docs/work/ is deliberately IN scope here, which is the opposite call from the
    pathspec [91], [93], [94] and [95] share. See the header."""
    proc = subprocess.run(['git', 'ls-files', '--', WORKDOCS],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode('utf-8', 'replace'))
        raise SystemExit('git ls-files failed with rc %d' % proc.returncode)
    names = proc.stdout.decode('utf-8', 'replace').split('\n')
    return [p for p in names if p.endswith('.md')]


def scan(paths, allowed):
    """Judge every doc, report what it found, then print CONTROL and SIZE."""
    docs = ledgers = subjects = 0
    findings = []
    for path in paths:
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

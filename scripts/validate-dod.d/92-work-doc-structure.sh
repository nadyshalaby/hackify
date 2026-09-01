# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [92] WORK-DOC SECTION STRUCTURE. NOTHING IN THIS VALIDATOR HAD EVER READ THE
# SHAPE OF A WORK-DOC, and the hole was proved twice in one sprint. The full bar
# stayed green over a work-doc carrying a duplicate Sprint Backlog and a duplicate
# `## 6. Daily Updates` heading, and an adversarial refuter re-proved it by
# injecting two headings and getting ALL CHECKS PASSED. [98] says so in its "ROWS
# OUTSIDE THE BLOCK ARE NOT SUBJECTS" paragraph, named and not numbered for [56]'s
# reason: it judges the rows inside section 0, never the section headings around
# them. [94] reads the TEMPLATE's headings to resolve instructions that name a
# section. Neither one opens a work-doc and asks whether its sections make sense.
#
# WHY THIS COSTS SOMETHING REAL. A work-doc is the single source of truth a
# sprint resumes from, and two sections numbered the same is not a cosmetic
# defect: an agent told to append to `## 6. Daily Updates` appends to whichever
# one its reader finds first, so half a round's evidence lands in a section
# nobody reads again, and a duplicated Sprint Backlog means two task lists with
# two different sets of ticks and no way to tell which one the round ran.
#
# AN EXACT-DUPLICATE-HEADING CHECK WOULD HAVE CAUGHT NEITHER CASE, which is the
# design constraint and the reason this is keyed on the NUMBER. Both injected
# headings carried trailing prose, so `## 6. Daily Updates` and
# `## 6. Daily Updates (round 2)` are different strings and a string-equality
# check separates them happily. The section NUMBER is what identifies a section
# to every reader and every instruction in this plugin, so the number is what
# must be unique. Everything after the number is free text and stays free.
#
# TWO ASSERTIONS, AND THEY FAIL APART:
#
#   (a) NO NUMBER TWICE. Within one doc, `## <n>.` appears at most once for each
#       n. This is the injected-heading case in both directions.
#
#   (b) NUMBERS ONLY GO UP. Within one doc, the numbered headings appear in
#       strictly ascending order. A section spliced in at the wrong place under a
#       FRESH number satisfies (a) completely while the doc reads out of order for
#       everyone after you, so (b) reaches an edit (a) cannot see.
#
# (a) AND (b) ARE NOT INDEPENDENT FOR DETECTION, AND PRETENDING OTHERWISE COST THIS
# CHECK ITS FIRST CONTROL. Any repeated number also breaks strict ascending order,
# adjacent or not, so every doc (a) reports is a doc (b) reports too. The first
# control asked only "was this doc reported", which meant killing (a) outright
# changed nothing it could see: the judge was blinded and the control held. They are
# independent for DIAGNOSIS, which is the half that matters to a reader, because (a)
# names the number and every line carrying it while (b) names one step. So the
# control below asserts WHICH assertion fired, never merely that something did.
#
# NO VOCABULARY ASSERTION, DELIBERATELY, and it was measured before it was
# dropped rather than skipped on taste. A check that every number is one the
# template declares reds today on
# docs/work/done/2026-08-27-contention-first-hackify.md, which carries sections 9,
# 10 and 11 legitimately, so it would have shipped red or shipped with that doc
# carved out, and a carve-out written on day one is a check nobody trusts on day
# two. Section numbering beyond the template is a real shape this repo uses.
#
# SUBJECTS ARE docs/work/*.md, TRACKED OR NOT, ARCHIVE INCLUDED. A good half of
# them predate the numbered-section convention entirely and carry no `## <n>.`
# heading at all; they are not subjects and are not findings, and the ceiling
# below is pinned on exactly that set, which is what keeps the distinction honest.
#
# THE UNTRACKED HALF ARRIVED LATE AND IS THE HALF THAT MATTERED. This scan read
# `git ls-files`, the INDEX, for its whole life, so an uncommitted work-doc was
# never opened while the pass line counted the committed ones and called them all.
# Measured on the sprint that found it: this check printed "all 24 tracked
# work-doc(s)" on a green run without once opening the document authorizing that
# very run, because that document had not been committed. A duplicated section
# heading is written while a doc is being edited and is repaired, if ever, before
# anyone commits it, so the pre-commit window is not a gap in the coverage, it is
# where the whole defect class lives. [89] made the same correction to its own
# scan and argues it under "THE SCAN READS UNTRACKED FILES TOO".
#
# NOTHING SOURCED FROM A REPO FILE BECOMES A PATTERN, [98]'s rule verbatim: every
# pattern here is a literal in this file, and no path is opened until it resolves
# to itself under the repository root, so a tracked symlink is refused and
# reported rather than followed out of the tree.
#
# WHY A POSITIVE CONTROL. On a truthful tree both assertions report nothing, and
# that silence is byte-identical to the silence of a judge that has stopped
# judging. So it is earned first: a synthetic eight-doc corpus built from source
# literals here goes through the SAME judge the live scan uses, in BOTH
# directions, four reported and four not.
yellow "[92] no work-doc numbers two sections the same, and its numbered sections only go up"
# THE BOUNDS, judged before any per-doc red prints, the order [91], [94], [95] and
# [98] all argue for. Each carries the command that re-derives it and writes no live
# count, per 57-doc-links.sh's "No count is written here, deliberately" sentence.
#
# TWO FLOORS AND A CEILING, AND THE CEILING IS THE ARGUMENT. A floor over a count
# that only grows cannot see a drop of one, so it has to be re-derived every wave to
# stay tight, and that maintenance convention had already failed inside this very
# file: two of these bounds went stale within one sprint of being written, each
# sitting a few short of the count it was derived from, under comments calling a
# `-lt` bound "the exact count" so the shortfall read as an equality nobody owed an
# edit. A count that only a REGRESSION can move needs no such maintenance, so the
# subject-set bound is inverted onto the docs that FAIL to carry a numbered section
# and compared as a ceiling.
#
#   WS_DOC_FLOOR, a floor at half the work-docs tracked today. Half, because docs
#   are added most waves and none has ever been deleted, so only a collapse toward
#   zero means the pathspec stopped matching.
#     git ls-files --cached --others --exclude-standard -- 'docs/work/*.md' | wc -l
#
#   WS_UNSECTIONED_MAX, a CEILING on the docs carrying NO numbered section, derived
#   as the count of them today. Those are the legacy docs above, nothing since has
#   been written without numbered sections and none of them grows one back, so this
#   number is stable where the sectioned count is not. A grammar break empties the
#   subject set and lands every doc here, one doc losing its headings lands one
#   here, and both red; a doc ADDED leaves it alone and a legacy doc retro-fitted
#   with sections lowers it, so neither reds. It replaced a floor on the sectioned
#   count, which could only see a grammar break wide enough to push that count under
#   the floor, and went blind to one the moment the corpus grew past it.
#     git ls-files --cached --others --exclude-standard -- 'docs/work/*.md' \
#       | xargs grep -LE '^## [0-9]+\.' | wc -l
#
#   WS_HEADING_FLOOR, A FLOOR AT THE TRACKED HEADING COUNT, AND DELIBERATELY NOT AT
#   THE LIVE ONE. The corpus now includes uncommitted docs, whose heading totals
#   move while a sprint is running: an author splits section 6 in two and the count
#   jumps, a round folds two sections together and it falls. Pinning this floor on a
#   number a live document can lower would make it red on ordinary authoring, which
#   is how a check gets deleted. So it is derived over --cached alone, 113 against a
#   live total of 122 at the time of writing, and the 9 headings of the uncommitted
#   doc are slack rather than coverage. The command below is the one that re-derives
#   it, and it is the only bound in this file whose pathspec deliberately differs
#   from the scan's.
#   A floor is all it can
#   be: headings only accumulate and there is no inverse set to pin, so any bound
#   here is a ratchet, tightest the day it is derived and looser every wave after. A
#   per-doc multiple was measured and rejected: a short work-doc with two numbered
#   sections is legitimate, and a check that reds on a correct document is how a
#   check gets deleted. The ratchet is tolerable because this is not what stands
#   under a fence mask blanking whole documents, the case the ceiling above catches
#   exactly; what is left to this floor is the PARTIAL mask that thins a doc's
#   headings without emptying it.
#     git ls-files -- 'docs/work/*.md' \
#       | xargs grep -cE '^## [0-9]+\.' | awk -F: '{s+=$NF} END {print s}'
#
# THE PASS LINE PRINTS ALL FOUR LIVE TOTALS, and those are what to re-derive from:
# the greps above do not mask fenced code, so a heading quoted in a fence makes them
# over-count where the scan does not.
WS_DOC_FLOOR=12
WS_UNSECTIONED_MAX=11
WS_HEADING_FLOOR=113

WS_DOCS=0
WS_SECTIONED=0
WS_UNSECTIONED=0
WS_HEADINGS=0
WS_CONTROL=none

ws_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

ws_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r WS_DOCS WS_SECTIONED WS_HEADINGS <<<"${line#SIZE }" ;;
      'CONTROL '*) WS_CONTROL=${line#CONTROL } ;;
    esac
  done <<<"$1"
  # DERIVED, NEVER COUNTED A SECOND TIME. The scan already separates the docs it
  # read from the docs that carried a section, and a second walk to count the
  # difference is a second grammar that could disagree with the judge's.
  WS_UNSECTIONED=$((WS_DOCS - WS_SECTIONED))
}

ws_floors_hold() {
  if [ "$WS_DOCS" -lt "$WS_DOC_FLOOR" ]; then
    ws_fail "[92] the work-doc scan read $WS_DOCS doc(s) under docs/work/ against a floor of $WS_DOC_FLOOR; the pathspec stopped matching, and a scan over nothing measures nothing"
    return 1
  fi
  if [ "$WS_UNSECTIONED" -gt "$WS_UNSECTIONED_MAX" ]; then
    ws_fail "[92] the scan read $WS_DOCS doc(s) of which $WS_UNSECTIONED carry no numbered section at all, against a ceiling of $WS_UNSECTIONED_MAX; a doc that had sections has left the subject set both assertions judge, so their silence over it means nothing. If a work-doc was legitimately written without numbered sections, raise the ceiling; if the heading grammar stopped matching, this is the red it exists for"
    return 1
  fi
  if [ "$WS_HEADINGS" -lt "$WS_HEADING_FLOOR" ]; then
    ws_fail "[92] the scan judged $WS_HEADINGS numbered heading(s) against a floor of $WS_HEADING_FLOOR; headings only accumulate here, so a total that fell is a fence mask thinning documents it should not have touched, and it thinned them without emptying any, which is the one shape the unsectioned ceiling above cannot see"
    return 1
  fi
  return 0
}

# JUDGED AFTER THE FLOORS AND BEFORE THE GREEN, never instead of the per-doc walk.
# WS_CONTROL starts at `none`, so a control that never ran cannot look like one
# that held.
ws_control_holds() {
  [ "$WS_CONTROL" = ok ] && return 0
  ws_fail "[92] the positive control did not hold (control verdict: $WS_CONTROL). A synthetic eight-doc corpus built from literals in this fragment must report exactly the four docs that break something AND must report each through the right assertion: one repeating a section number with trailing prose on the second heading, one repeating it exactly, and one whose real duplicate sits below a fenced decoy, all three through both assertions; one whose numbered sections run backwards, through the ordering assertion ALONE. And it must report none of the four beside it, a clean run of sections, one with gaps in the numbering, one whose only repeat is quoted inside a code fence, and one carrying no numbered section at all. The which-assertion half is not decoration: every repeat also breaks the ordering rule, so a control asking only whether a doc was reported held perfectly over a duplicate judge that had been deleted. Until that separates, this run's silence is not evidence"
  return 1
}

# AND NO GREEN PRINTS BESIDE A RED, [91]'s rule verbatim.
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
  green "  ok   all $WS_DOCS tracked and untracked work-doc(s) under docs/work/ number each section once and number them in ascending order ($WS_SECTIONED sectioned doc(s), $WS_UNSECTIONED carrying no numbered section, $WS_HEADINGS numbered heading(s) judged), and the positive control separated its reported docs from its clean ones before that silence was trusted"
}

if ! command -v python3 > /dev/null 2>&1; then
  ws_fail "[92] needs python3 to walk work-doc headings, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, per the tie-breaker [98] and
  # 73-implementer-rename.sh both take. A bare $(...) capture swallows a traceback
  # and leaves this block reading an empty result as "no work-doc is malformed".
  ws_err=$(mktemp 2>/dev/null) || ws_err=''
  if [ -z "$ws_err" ]; then
    ws_fail "[92] could not create the stderr capture file, so the work-doc scan never ran"
  else
    ws_out=$(python3 - 2>"$ws_err" <<'WS_PY'
import io, os, re, subprocess, sys

TICK = chr(96)
WORKDOCS = 'docs/work/*.md'
CODE_FENCE = TICK * 3
FENCES = (CODE_FENCE, '~~~')
# The heading grammar, and the only pattern this check has. `## ` then digits then
# a dot: everything after the dot is free text and is never compared.
NUM = re.compile(r'^## ([0-9]+)\.')
ROOT = os.path.realpath(os.getcwd())


def read(path):
    with io.open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace')


def refuse_read(path):
    """The finding saying why this path was not opened, or None. os.path.isfile
    FOLLOWS a symlink, so a tracked symlink would be opened and whatever it points
    at quoted into a finding. Resolve first, then REPORT the refusal rather than
    skip it: a doc this check declines to read is not a doc that passed."""
    full = os.path.join(ROOT, path)
    real = os.path.realpath(full)
    if real == full and real.startswith(ROOT + os.sep) and not os.path.islink(full):
        return None
    return ('%s does not resolve to a plain file under the repository root (it '
            'reaches %s), so this check refused to follow it rather than read '
            'what it points at' % (path, real))


def unfenced(lines):
    """A copy of `lines` with every line inside a fenced code block blanked, so a
    heading quoted in a code block is not judged as a heading. A work-doc quotes
    its own skeleton in fences routinely, and counting those would make this check
    red on correct documents, which is how a check gets deleted.

    BLANKED AND NOT DROPPED, so every index still equals its line number."""
    out = []
    marker = None
    for line in lines:
        if marker is not None:
            marker = None if line.startswith(marker) else marker
            out.append('')
            continue
        marker = None
        for fence in FENCES:
            if line.startswith(fence):
                marker = fence
                break
        out.append('' if marker else line)
    return out


def headings(lines):
    """(number, line number) for every numbered section heading, in file order."""
    found = []
    for num, line in enumerate(unfenced(lines)):
        hit = NUM.match(line)
        if hit:
            found.append((int(hit.group(1)), num + 1))
    return found


def judge_repeats(path, found):
    """Assertion (a). One finding per number that appears more than once."""
    seen = {}
    for number, line in found:
        seen.setdefault(number, []).append(line)
    out = []
    for number in sorted(seen):
        if len(seen[number]) < 2:
            continue
        out.append('%s numbers section %d at %d separate headings (lines %s), so '
                   'two sections carry one number and an agent told to append to '
                   'that section appends to whichever its reader finds first; the '
                   'text after the number is free and the number is not'
                   % (path, number, len(seen[number]),
                      ', '.join(str(n) for n in seen[number])))
    return out


def judge_order(path, found):
    """Assertion (b). One finding per heading that does not increase."""
    out = []
    for before, after in zip(found, found[1:]):
        if after[0] > before[0]:
            continue
        out.append('%s:%d opens section %d after section %d at line %d, so its '
                   'numbered sections do not run in ascending order and a section '
                   'has been spliced in at the wrong place'
                   % (path, after[1], after[0], before[0], before[1]))
    return out


def judge(path, lines):
    """Every finding for one doc, plus what it contributed to the floors."""
    found = headings(lines)
    out = judge_repeats(path, found)
    out.extend(judge_order(path, found))
    return (out, bool(found), len(found))


# The control shapes, as source literals. Written out rather than built from NUM
# or FENCES: a control built from the constant it tests moves with a tamper on it
# and stays green while the judge blinds.
CTL_CLEAN = '# t\n\n## 0. Phase ledger\n\n## 5. Sprint Backlog\n\n## 6. Daily Updates\n'
CTL_GAPS = '# t\n\n## 1. Original ask\n\n## 4. Approach\n\n## 8. Retrospective\n'
CTL_NONE = '# t\n\n## Primary Goal\n\nbody\n\n## Update log\n\nbody\n'
# The trailing prose on the second heading is the whole point: an equality check
# on the heading TEXT separates these two and reports nothing.
CTL_PROSE = ('# t\n\n## 5. Sprint Backlog\n\n## 6. Daily Updates\n\n'
             '## 6. Daily Updates (round 2)\n')
CTL_EXACT = '# t\n\n## 5. Sprint Backlog\n\n## 6. Daily\n\n## 5. Sprint Backlog\n'
CTL_ORDER = '# t\n\n## 1. Original ask\n\n## 5. Sprint Backlog\n\n## 3. Acceptance\n'
# The fenced decoy separates only while both halves of the fence mask work: the
# quoted heading must not count, and the real one below the fence must.
CTL_FENCED = ('# t\n\n' + CODE_FENCE + '\n## 6. Daily Updates\n' + CODE_FENCE
              + '\n\n## 6. Daily Updates\n')
CTL_UNFENCED_DUP = ('# t\n\n' + CODE_FENCE + '\n## 2. Q and A\n' + CODE_FENCE
                    + '\n\n## 6. Daily Updates\n\n## 6. Daily Updates now\n')


# The two assertions, as the words only their own findings carry. A tag read off
# the finding TEXT is what lets the control below say which assertion fired, and
# these two literals are the seam: change a finding's wording without changing
# these and the control reds rather than going quietly blind.
REPEAT_MARK = 'numbers section'
ORDER_MARK = 'do not run in ascending order'


def tags(findings):
    """The set of assertions that actually fired, read off the findings."""
    out = set()
    for line in findings:
        if REPEAT_MARK in line:
            out.add('repeat')
        if ORDER_MARK in line:
            out.add('order')
    return out


def control_docs():
    """The eight synthetic work-docs the control judges, as (path, body, wanted),
    where `wanted` is the exact set of assertions that must fire on that doc.

    Source literals only, so no document can change what this proves. Both
    assertions get a case where they fire ALONE, which is the whole point: an
    expectation of "reported or not" cannot tell a live (a) from a dead one,
    because every repeat also breaks the order rule. zzs-backwards is the case
    where (b) fires with (a) silent, and the three repeat docs are the cases where
    (a) must fire beside it rather than instead of it."""
    return (('docs/work/zzs-prose-dup.md', CTL_PROSE, {'repeat', 'order'}),
            ('docs/work/zzs-exact-dup.md', CTL_EXACT, {'repeat', 'order'}),
            ('docs/work/zzs-backwards.md', CTL_ORDER, {'order'}),
            ('docs/work/zzs-below-fence.md', CTL_UNFENCED_DUP, {'repeat', 'order'}),
            ('docs/work/zzs-clean.md', CTL_CLEAN, set()),
            ('docs/work/zzs-gaps.md', CTL_GAPS, set()),
            ('docs/work/zzs-fenced-decoy.md', CTL_FENCED, set()),
            ('docs/work/zzs-unsectioned.md', CTL_NONE, set()))


def control():
    """True when a corpus whose verdicts are known is judged exactly that way.

    BOTH DIRECTIONS AND BOTH ASSERTIONS: four docs must report and four must stay
    silent, and each of the four that report must report through the assertions
    named beside it. Every case runs the SAME judge() the live scan uses."""
    for path, body, wanted in control_docs():
        if tags(judge(path, body.split('\n'))[0]) != wanted:
            return False
    return True


def work_docs():
    """Work-docs tracked OR untracked, by argv list and never through a shell.

    --cached --others --exclude-standard, never --cached alone. This read was the
    index for its whole life, so a work-doc that had not been committed yet was
    outside the corpus while the pass line below counted the ones that were and
    called them all. The doc authorizing the sprint that found this was itself
    untracked, so this check had never once opened the document it was running
    under. --exclude-standard keeps a gitignored path out; nothing under
    docs/work/ is ignored today, and the flag is what keeps that true if one ever
    is.

    DEDUPED, ORDER KEPT. --cached and --others are disjoint for a clean index but
    not for an unmerged one, where a conflicted path is listed once per stage, and
    a doc counted twice would inflate the SIZE total the floors below are read
    against. That inflation runs toward a floor that passes, which is the wrong
    direction for a bound whose whole job is to refuse a collapsed corpus.

    -z AND SPLIT ON NUL: under git's default core.quotePath a path holding a
    non-ASCII byte, a double quote or a backslash comes back C-quoted, stops
    ending in .md and drops out of the corpus unseen."""
    proc = subprocess.run(['git', 'ls-files', '-z', '--cached', '--others',
                           '--exclude-standard', '--', WORKDOCS],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode('utf-8', 'replace'))
        raise SystemExit('git ls-files failed with rc %d' % proc.returncode)
    names = proc.stdout.decode('utf-8', 'replace').split('\0')
    seen, out = set(), []
    for p in names:
        if p.endswith('.md') and p not in seen:
            seen.add(p)
            out.append(p)
    return out


def one_line(text):
    """A finding, flattened to one physical line. git ls-files can legitimately
    return a path holding a newline, and the shell above reads this output line by
    line, so an unescaped one would split a finding and drop its reason."""
    return text.replace(chr(10), '\\n').replace(chr(13), '\\r')


def scan(paths):
    """Judge every doc, report what it found, then print CONTROL and SIZE."""
    docs = sectioned = marks = 0
    findings = []
    for path in paths:
        refusal = refuse_read(path)
        if refusal:
            findings.append(refusal)
            continue
        if not os.path.isfile(path):
            continue
        docs += 1
        out, has_sections, count = judge(path, read(path).split('\n'))
        findings.extend(out)
        sectioned += 1 if has_sections else 0
        marks += count
    for line in findings:
        print('FAIL %s' % one_line(line))
    print('CONTROL %s' % ('ok' if control() else 'fail'))
    print('SIZE %d %d %d' % (docs, sectioned, marks))


scan(work_docs())
WS_PY
)
    ws_rc=$?
    ws_errtxt=$(cat "$ws_err")
    rm -f "$ws_err"
    if [ "$ws_rc" -ne 0 ] || [ -n "$ws_errtxt" ]; then
      ws_fail "[92] the work-doc structure scan did not finish (rc $ws_rc), so its silence is not a verdict: ${ws_errtxt:-no stderr, non-zero exit}"
    else
      ws_verdict "$ws_out"
    fi
  fi
fi

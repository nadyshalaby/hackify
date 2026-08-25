# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [94] SECTION EXISTS. A doc that tells a writer to put something into a named
# work-doc section is claiming that section is one the template has. When the
# template retires a name, every instruction still naming it points a writer at
# a heading that is not there, and the writer either invents the section or
# silently drops the content. This block resolves every such instruction against
# the template's own headings and reds on any that resolves to nothing.
#
# THE DEFECT IT WAS WRITTEN FOR IS THIS REPO'S OWN, and it is finding I2 in
# scripts/claim_corpus.json. skills/hackify/references/implement-and-test.md:34
# told a writer to append an entry to the Implementation Log, a section the
# template retired in favour of Daily Updates. It was fixed at ab5cb74, so the
# FILED site is not live at HEAD; scripts/claim_fixtures.json pins the blob it
# was live in, and scripts/test_section_exists.py replays that blob through THIS
# fragment rather than through a copy of it.
#
# THE RULE IS "THE NAME IS ONE OF THE TEMPLATE'S HEADINGS", NEVER "THE NAME
# APPEARS IN THE TEMPLATE", and the difference is the whole check. The retired
# name DOES appear in work-doc-template.md, once, at line 5, inside a
# back-compat note listing the prior section names. Under an appears-in rule I2
# reads clean, because the string is right there. So the template is parsed
# STRUCTURALLY for its headings, and a name mentioned in its prose declares
# nothing. Measured on the live template: 23 headings, and Implementation Log is
# not among them.
#
# THE POLICED NAMES ARE A LITERAL LIST HERE, NOT READ OUT OF THE TEMPLATE. The
# template's back-compat note happens to enumerate the retired names, and
# harvesting that line at runtime would be building this check's matcher out of
# a document's contents, which is the arbitrary-code-execution shape the whole
# sprint refuses. The list below was transcribed by hand from that note and is
# guarded from the other side instead: a policed name that turns UP in the
# heading set reds, because the check's premise would have died.
#
# ONLY ONE NAME IS POLICED, AND THE OTHER FOUR ARE DELIBERATELY LEFT OUT.
# The note retires five names. Measured over live files, three of them are
# ordinary English that this repo uses in a non-section sense far more often
# than as a section: 'Definition of Done' names the plugin's own shipping
# contract in scripts/validate-dod.sh:2 and 00-helpers.sh:3, 'Tasks' and
# 'Verification' are section headers in half the agent prompts in the tree. A
# rule over those would fire on correct text, which is the fabrication this
# sprint exists to refuse, so this check polices the one name that only ever
# meant the retired section. Narrow and right beats wide and wrong.
#
# THE MATCH UNIT IS A NORMALISED PARAGRAPH AND THE CITATION UNIT IS A PHYSICAL
# LINE. Corpus finding M2 is precisely that a literal split across a hard line
# break is invisible to a line-based scan, and this tree hard-wraps prose at
# about 80 columns, so an instruction can arrive with its verb on one line and
# its section name on the next. Matching a paragraph survives that. Reporting a
# paragraph would not: a citation of file.md:11 for a defect at file.md:34 is a
# pointer that does not resolve, which is corpus class C2 committed by the check
# built to catch its neighbours. So the paragraph decides, and the physical line
# carrying the name is what gets printed.
#
# HOW BACK-COMPAT PROSE IS EXCUSED, and it is the boundary the whole check turns
# on. Six live sites name the retired label ON PURPOSE, because resume mode has
# to keep reading archived work-docs that still use it. Every one of them sits
# in a paragraph that is ABOUT the rename: it says back-compat, or legacy, or
# quotes the arrow from the old name to the new. The instruction sites this
# check was written for did not, and the I2 blob replayed out of
# scripts/claim_fixtures.json still does not. So the discriminator is a marker
# in the surrounding paragraph, and it is prose that tells a reader to READ
# either label versus prose that tells a writer to WRITE into one.
#
# 'was ' IS NOT A MARKER, AND LEAVING IT OUT IS MEASURED RATHER THAN TIDY. It
# was in the first draft and it excused a debug-when-stuck.md bullet, because
# three lines above that bullet an unrelated one reads 'if this was the last
# task' and the paragraph is shared. One over-wide marker took a real finding
# off the board silently. That bullet has since been rewritten to name the live
# section, so the site is no longer live; the narrower '(was ' stays, since that
# parenthetical only ever introduces a rename.
#
# NOTHING SOURCED FROM A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN. Every
# pattern below is a literal in this file. Headings parsed out of the template
# are compared by exact string equality against that literal list, never
# interpolated into a regex and never handed to a shell.
yellow "[94] every instruction naming a work-doc section names one the template actually has"

# WHY LIVE PATHS AND NOT THE WHOLE TREE. The same three-part pathspec [91] and
# [93] use, for their stated reasons: dist/ is generated, and docs/work/ is the
# sprint record, which has to be able to quote the broken instruction it was
# written to describe.
#
# TWO MORE FILES ARE EXCLUDED, ON THE PRINCIPLE [91]'s HEADER ALREADY ARGUES: a
# record describing a defect is not committing one. scripts/claim_corpus.json is
# the frozen answer key for this very finding and quotes its text; scripts/
# claim_fixtures.json pins the blob and quotes the literal it must contain. Both
# are read-only evidence about I2, and a check that reddened on the file
# documenting why it exists would be unusable. scripts/test_claim_fixtures.py is
# out for the same reason: it asserts the historical content byte for byte.
#
# THIS FRAGMENT AND ITS OWN TEST FILE COME OUT TOO, and that exclusion is
# load-bearing rather than convenient. Neither can document the rule without
# quoting the thing the rule bans: the I2 paragraph at the top of this file
# retells the instruction that finding IS, and scripts/test_section_exists.py
# asserts the caught text byte for byte in its own fixtures. That is measured
# and not argued, both files were replayed under SE_REPLAY_ROOT against a copy
# of themselves and both red. Without this, committing these two files reddens
# the check on itself the first time it runs, which is a defect that hides
# until the wave lands rather than while it is being built.
#
# THE PRECEDENT IS IN THIS DIRECTORY, BOTH WAYS. 70-invariants-and-new.sh:218
# takes the identical way out for the identical cause, a banned-wording scanner
# that must hold the banned wording. 91-claim-resolvers.sh deliberately does NOT
# self-exclude, and the difference is the whole test: every `check [NN]` it
# names resolves to a real declared id, so naming them commits no defect. These
# two files do commit one, in the literal sense the check measures.
#
# THE COST IS REAL, SO IT IS NAMED RATHER THAN GLOSSED: a genuine bad
# instruction written into either file is invisible to this check. That is
# precisely why the test file drives the REAL fragment through a replay root
# instead of asserting against a copy of the scanner.
#
# THE FLOORS ARE WHAT STOP A VACUOUS PASS. If the pathspec resolves to nothing,
# if the template's heading grammar stops matching, or if the paragraph splitter
# stops finding text, every count collapses toward zero and this reds instead of
# printing a confident green. Floors and not exact counts, because prose gains
# and loses these mentions every wave; only a collapse means the scan broke.
SE_FILE_FLOOR=100
SE_HEADING_FLOOR=12
SE_MENTION_FLOOR=4

SE_FILES=0
SE_HEADINGS=0
SE_MENTIONS=0
SE_EXCUSED=0
SE_MODE=none

se_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

se_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r SE_FILES SE_HEADINGS SE_MENTIONS SE_EXCUSED SE_MODE \
        <<<"${line#SIZE }" ;;
    esac
  done <<<"$1"
}

# THE FLOORS ARE JUDGED BEFORE ANY PER-SITE RED PRINTS, the same order [91] and
# [93] argue for and for the same reason: a collapsed heading set makes every
# instruction in the repo resolve to nothing, so replaying the per-site reds
# first would bury the one line that explains them under a wall of false
# accusations.
#
# REPLAY MODE TRADES THE DISCOVERY FLOORS FOR A DIFFERENT ONE. The floors above
# police DISCOVERY, which is the thing that can silently return nothing; a
# replay scope holds exactly the files a fixture materialised, so there is no
# discovery to collapse. What can still go wrong is a replay that finds no
# mention at all, which would print no failures and read exactly like a clean
# scan, so that is the floor replay mode carries instead. The heading floor
# stays in both modes, because the template is read from the repository in both.
se_floors_hold() {
  if [ "$SE_HEADINGS" -lt "$SE_HEADING_FLOOR" ]; then
    se_fail "[94] the template parse found $SE_HEADINGS heading(s) against a floor of $SE_HEADING_FLOOR; the heading grammar or the template path stopped matching, and every instruction would resolve to nothing"
    return 1
  fi
  if [ "$SE_MODE" = replay ]; then
    [ "$SE_MENTIONS" -ge 1 ] && return 0
    se_fail "[94] the replay scan found 0 mention(s) of a policed section name across $SE_FILES file(s), so it examined nothing and its silence means nothing"
    return 1
  fi
  if [ "$SE_FILES" -lt "$SE_FILE_FLOOR" ]; then
    se_fail "[94] the section scan read $SE_FILES live file(s) against a floor of $SE_FILE_FLOOR; the pathspec stopped matching, and a scan over nothing measures nothing"
    return 1
  fi
  if [ "$SE_MENTIONS" -lt "$SE_MENTION_FLOOR" ]; then
    se_fail "[94] the scan found only $SE_MENTIONS mention(s) of a policed section name against a floor of $SE_MENTION_FLOOR; the paragraph splitter or the name list stopped matching, and this check would go quiet without going green for a reason"
    return 1
  fi
  return 0
}

# AND NO GREEN PRINTS BESIDE A RED, [91]'s rule verbatim. A summary that
# contradicts the failure above it is the fail-open shape this fragment exists
# to refuse, so the pass line is reached only when nothing failed.
se_verdict() {
  local line bad=0
  se_read_size "$1"
  se_floors_hold || return
  while IFS= read -r line; do
    case "$line" in
      'FAIL '*) se_fail "${line#FAIL }"; bad=$((bad + 1)) ;;
    esac
  done <<<"$1"
  [ "$bad" -eq 0 ] || return
  green "  ok   all instruction site(s) naming a work-doc section across $SE_FILES live file(s) name one of the template's $SE_HEADINGS heading(s) ($SE_MENTIONS mention(s) examined, $SE_EXCUSED excused as back-compat prose)"
}

if ! command -v python3 > /dev/null 2>&1; then
  se_fail "[94] needs python3 to parse the template's headings, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, per the tie-breaker at
  # 70-invariants-and-new.sh:290-311. A python traceback exits non-zero and
  # writes to stderr, and a bare $(...) capture swallows both, leaving this
  # block to read an empty result as "no unresolved instructions". A FAIL-CLOSED
  # BRANCH OUTRANKS A HIT REPORT: a scan that could not finish tells the reader
  # nothing trustworthy about what it did manage to print.
  se_err=$(mktemp 2>/dev/null) || se_err=''
  if [ -z "$se_err" ]; then
    se_fail "[94] could not create the stderr capture file, so the section scan never ran"
  else
    se_out=$(python3 - 2>"$se_err" <<'SE_PY'
import io, os, re, subprocess, sys, tempfile

# Every pattern here is a literal in this file. See the header.
TEMPLATE = 'skills/hackify/references/work-doc-template.md'
HEADING = re.compile(r'^#{2,}\s+(.+?)\s*$')
NUMBER = re.compile(r'^\d+[a-z]?\.\s+')
POLICED = ('Implementation Log',)
BACKCOMPAT = ('Back-compat', 'back-compat', 'Legacy', 'legacy', 'LEGACY',
              'prior section names', 'renamed', 'relabeled', 'relabelled',
              'was renamed', '(was ', 'arrow', 'sprint vocabulary')
LIVE = [':(top)', ':(top,exclude)dist/*', ':(top,exclude)docs/work/*']
EXCLUDE = ('scripts/claim_corpus.json', 'scripts/claim_fixtures.json',
           'scripts/test_claim_fixtures.py',
           'scripts/validate-dod.d/94-section-exists.sh',
           'scripts/test_section_exists.py')


def read(path):
    with io.open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace')


def headings():
    """Section names the template actually has, numbering stripped.

    Read from the repository in BOTH modes. The template is this check's
    reference data, not part of the corpus being scanned, and a replay scope
    holds only the files a fixture materialised. Today's template gives the same
    answer for the pinned blob besides: the name was retired before the blob's
    own commit, which is what made the blob a finding."""
    names = set()
    for line in read(TEMPLATE).split('\n'):
        found = HEADING.match(line)
        if found:
            names.add(NUMBER.sub('', found.group(1)).strip())
    return names


def paragraphs(text):
    """(line_no, normalised_text, [(line_no, raw)]) per blank-line-separated block.

    Comment markers are stripped so a shell or python comment block reads as one
    paragraph, which is where several of these instructions live."""
    out, buf, start = [], [], 1
    for num, raw in enumerate(text.split('\n'), 1):
        body = raw.strip()
        if body.startswith('#'):
            body = body.lstrip('#').strip()
        if not body:
            if buf:
                out.append((start, ' '.join(b for _, b in buf), list(buf)))
            buf = []
            continue
        if not buf:
            start = num
        buf.append((num, body))
    if buf:
        out.append((start, ' '.join(b for _, b in buf), list(buf)))
    return out


def cite(rows, name):
    """The physical line carrying the name. See the header on citation units."""
    for num, body in rows:
        if name in body:
            return num
    return rows[0][0]


def judge(para):
    """Classify one paragraph that mentions a policed name. Returns a tag."""
    _start, text, rows = para
    for name in POLICED:
        if name not in text:
            continue
        if any(mark in text for mark in BACKCOMPAT):
            return ('excused', name, cite(rows, name))
        return ('fail', name, cite(rows, name))
    return None


def live_files():
    """Tracked paths under the same pathspec 70-invariants-and-new.sh:216 scans."""
    proc = subprocess.run(['git', 'ls-files', '--'] + LIVE,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode('utf-8', 'replace'))
        raise SystemExit('git ls-files failed with rc %d' % proc.returncode)
    names = proc.stdout.decode('utf-8', 'replace').split('\n')
    return [p for p in names if p and p not in EXCLUDE]


def replay_files(root):
    """Every text file a fixture materialised, relative to the replay root."""
    found = []
    for base, _dirs, names in os.walk(root):
        found.extend(os.path.relpath(os.path.join(base, n), root) for n in names)
    return sorted(found)


def replay_root():
    """Validate the replay hook or REFUSE it. Never falls back to the live scan.

    Same contract [93] states for TD_REPLAY_ROOT and for the same reason: an
    exported variable that quietly replaced the repo-wide scan with one clean
    file would print green having read nothing."""
    raw = os.environ.get('SE_REPLAY_ROOT', '')
    if not raw:
        return None
    root, tmp = os.path.realpath(raw), os.path.realpath(tempfile.gettempdir())
    if not os.path.isdir(root):
        raise SystemExit('SE_REPLAY_ROOT %r is not a directory' % raw)
    if root == os.path.realpath('.') or not root.startswith(tmp + os.sep):
        raise SystemExit('SE_REPLAY_ROOT %r is not a fixture temp dir under %s' % (raw, tmp))
    if os.path.exists(os.path.join(root, '.git')):
        raise SystemExit('SE_REPLAY_ROOT %r holds a .git, so it is a real tree' % raw)
    return root


def guard_premise(names):
    """A policed name that IS a template heading kills this check's premise.

    Returns True when the premise still holds. It has to be a RETURN and not
    just a print, because the scan below reports every site with the sentence
    'declares no such heading'. Once the name IS a heading that sentence is
    false, and a check that prints a false claim about the tree is committing
    the very defect this fragment was written to catch. So the premise dying
    stops the scan rather than decorating it with accusations that no longer
    hold."""
    alive = True
    for name in POLICED:
        if name in names:
            alive = False
            print('FAIL the template at %s now carries a heading named %r, so this '
                  'check is policing a section that exists and every site it '
                  'reports would be a false accusation; retire the entry'
                  % (TEMPLATE, name))
    return alive


def scan(paths, root, setup):
    """Walk every candidate path, report, then print the one SIZE line.

    `setup` groups (mode, headings, premise_alive) rather than taking them as
    three more parameters, the same tuple-grouping [93]'s _report_uses uses to
    stay inside the three-parameter cap.

    WHEN THE PREMISE IS DEAD THE WALK STILL RUNS AND ONLY THE ACCUSATIONS STOP.
    Every per-site sentence below asserts the template declares no such heading,
    and once it does declare one that sentence is false, so it must not print.
    The walk itself cannot be skipped: the floors are computed from these counts
    and a skipped walk reports 0 headings against a floor of 12, which reds with
    a diagnosis blaming the heading grammar when the real cause is the retired
    name coming back. A wrong reason for a red is the defect this fragment
    exists to catch, so the counts stay real and the premise FAIL stands alone."""
    mode, names, alive = setup
    files = mentions = excused = 0
    for path in paths:
        full = os.path.join(root, path)
        if not os.path.isfile(full):
            continue
        files += 1
        for para in paragraphs(read(full)):
            got = judge(para)
            if got is None:
                continue
            tag, name, line = got
            mentions += 1
            if tag == 'excused':
                excused += 1
            elif alive:
                print('FAIL %s:%d instructs a writer to use a work-doc section named '
                      '%r, and %s declares no such heading (searched every ## heading, '
                      '%d found)' % (path, line, name, TEMPLATE, len(names)))
    print('SIZE %d %d %d %d %s' % (files, len(names), mentions, excused, mode))


NAMES = headings()
ALIVE = guard_premise(NAMES)
ROOT = replay_root()
if ROOT is None:
    scan(live_files(), '.', ('live', NAMES, ALIVE))
else:
    scan(replay_files(ROOT), ROOT, ('replay', NAMES, ALIVE))
SE_PY
)
    se_rc=$?
    se_errtxt=$(cat "$se_err")
    rm -f "$se_err"
    if [ "$se_rc" -ne 0 ] || [ -n "$se_errtxt" ]; then
      se_fail "[94] the section scan did not finish (rc $se_rc), so its silence is not a verdict: ${se_errtxt:-no stderr, non-zero exit}"
    else
      se_verdict "$se_out"
    fi
  fi
fi

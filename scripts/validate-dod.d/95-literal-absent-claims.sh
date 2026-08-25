# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [95] LITERAL-ABSENT CLAIMS. A sentence that quotes a phrase and says it is not
# pinned, not enforced or not guarded has made a statement whose truth is
# decidable by looking for that phrase. This block extracts the quoted phrase,
# looks for it, and reds when the phrase the sentence calls unpinned is sitting
# in another fragment's pin or ban list.
#
# THE DEFECT IT WAS WRITTEN FOR IS THIS REPO'S OWN, and it is finding I4 in
# scripts/claim_corpus.json. 71-release-mechanism-pins.sh used to say orchestration
# .md's "4-5 reviewers" row was deliberately NOT pinned, while 77-reviewer-roster
# .sh:216 has that exact phrase in RR_BANS. Sprint decision #16-C fixed that
# sentence, so I4 is no longer on the live tree: it replays from the blob
# scripts/claim_fixtures.json pins for it.
#
# THE MATCH UNIT IS A NORMALISED PARAGRAPH, NEVER A RAW LINE. Corpus note n8
# says I4's reachability rests on the claim and its quoted literal sharing one
# physical line today, and corpus finding M2 is the proof that line-based
# matching goes blind the moment text wraps. This tree hard-wraps at about 80
# columns and that comment sits three characters from the margin, so the wrap is
# one edit from moving. Paragraph normalisation is what makes this check survive
# that edit. The CITATION stays a physical line, for the reason [94] gives.
#
# ONLY THE PINNING VERBS ARE IN CLASS, AND THAT IS MEASURED RATHER THAN
# CAUTIOUS. The first draft also took 'is absent', 'not present' and 'does not
# appear'. Over the live tree that draft formed 9 claim/subject pairs, of which
# 8 were false and every one of the 8 failed the same way: the sentence was
# about RUNTIME absence, not text absence. 'when python3 is absent' is a tool
# missing from PATH, 'when the ProposeGoal tool is absent' is a capability the
# harness did not offer, and lawkeeper's own suite asserts a finding id is
# absent from a scan RESULT. None of those is decidable by grepping the tree,
# and a check that treats them as if they were is fabricating. Restricting the
# vocabulary to pinned / enforced / guarded, which in this repo are terms of art
# for what a validator asserts, takes the live tree from 8 false positives to 0.
#
# THE QUOTED PHRASE MUST BE THE SUBJECT OF THE CLAIM, NOT MERELY NEARBY. A
# paragraph-wide pairing was the other half of that first draft, and it formed
# 352 pairs over the live tree by matching one claim phrase against every quoted
# string in its paragraph. The CHANGELOG bullet that says the retired agent type
# must be absent from every live file carries a dozen other backticked names in
# the same paragraph, and all of them were accused. So the phrase has to be the
# nearest quote BEFORE the claim, within a short window carrying no other quote.
# That single rule is what takes 352 down to 1.
#
# THE PRESENT-POLARITY HALF IS NOT BUILT, AND THIS IS THE REASON RATHER THAN AN
# OMISSION. Sprint decision #13-A widened this class to both directions so it
# would also reach corpus finding M4, a CHANGELOG bullet claiming a token was
# carried into sites it never reached. Measured before writing any code: that
# bullet contains no file path at all, so resolving the sites it names, 'the
# template, its agent mirror, the Phase 5 protocol and the two mode skills',
# needs a hand-written map from English to paths. And the scope-wide reading
# that avoids such a map is an artifact of the fixture: at the pinned commit the
# token lives in 9 files, and adding any ONE of the other 8 to the replay scope
# flips the verdict from caught to clean. A half that passes only because of
# which three blobs were pinned is not a check, so it is refused here and
# reported instead.
#
# NOTHING SOURCED FROM A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN. Every
# pattern below is a literal in this file. A phrase parsed out of a document is
# used only as a needle for an exact substring search, never interpolated into a
# regex and never handed to a shell. A validator that built its matcher from a
# document's contents would be arbitrary code execution by editing that
# document, which is the guardrail this whole sprint is written around.
yellow "[95] every claim that a quoted phrase is not pinned is true when the phrase is looked for"

# WHY LIVE PATHS AND NOT THE WHOLE TREE, and why two more files come out. Same
# reasoning [94] states: dist/ is generated, docs/work/ is the sprint record,
# and the answer key plus its fixture manifest are read-only EVIDENCE about
# these findings. scripts/claim_corpus.json quotes the phrase 'deliberately NOT
# pinned' because it is the document that describes I4, and scripts/
# claim_fixtures.json pins the literal this check hunts. A check that reddened
# on the file explaining why it exists would be unusable, and there is no honest
# way around that other than naming the exclusion and its reason.
#
# THIS FRAGMENT AND ITS OWN TEST FILE COME OUT ON THE SAME PRINCIPLE. Both state
# I4 in the exact grammar this check hunts, because neither can document the
# finding without putting the claim and its quoted phrase in one paragraph: the
# header above does it, and scripts/test_literal_absent_claims.py builds the
# wrapped claim as fixture text so the paragraph unit can be tested at all. Left
# in, they turn this check red against itself.
#
# BOTH PRECEDENTS SIT IN THIS DIRECTORY. 73-implementer-rename.sh:102
# self-excludes for the identical cause. 91-claim-resolvers.sh does not, and the
# difference is that it holds no fabricated id, only ids that resolve.
#
# THE COST, NAMED RATHER THAN GLOSSED: a genuine stale pinning claim written
# into either file is invisible here. The test file drives the REAL fragment
# through a replay root for exactly that reason.
#
# THE FLOORS ARE WHAT STOP A VACUOUS PASS. Measured after #16-C fixed I4: 234
# live files, 10 paragraphs carrying a pinning claim phrase. Floors sit near
# half of each, so ordinary prose churn never reddens this and a collapse still
# does. If the claim vocabulary stops matching, this check goes silent, and a
# silent check that prints green is the exact shape the sprint exists to refuse.
LA_FILE_FLOOR=100
LA_CLAIM_FLOOR=5

LA_FILES=0
LA_CLAIMS=0
LA_PAIRS=0
LA_MODE=none

la_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

la_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r LA_FILES LA_CLAIMS LA_PAIRS LA_MODE <<<"${line#SIZE }" ;;
    esac
  done <<<"$1"
}

# THE FLOORS ARE JUDGED BEFORE ANY PER-CLAIM RED PRINTS, the order [91], [93]
# and [94] all argue for: a collapsed corpus makes every quoted phrase resolve
# to nothing, so replaying the per-claim reds first would bury the one line that
# explains them.
#
# REPLAY MODE TRADES THE DISCOVERY FLOORS FOR A DIFFERENT ONE, for the reason
# [93] states: a replay scope holds exactly what a fixture materialised, so
# there is no discovery to collapse, and what can still go wrong is a replay
# that forms no claim at all and reads exactly like a clean scan.
la_floors_hold() {
  if [ "$LA_MODE" = replay ]; then
    [ "$LA_CLAIMS" -ge 1 ] && return 0
    la_fail "[95] the replay scan found 0 pinning claim(s) across $LA_FILES file(s), so it judged nothing and its silence means nothing"
    return 1
  fi
  if [ "$LA_FILES" -lt "$LA_FILE_FLOOR" ]; then
    la_fail "[95] the claim scan read $LA_FILES live file(s) against a floor of $LA_FILE_FLOOR; the pathspec stopped matching, and a scan over nothing measures nothing"
    return 1
  fi
  if [ "$LA_CLAIMS" -lt "$LA_CLAIM_FLOOR" ]; then
    la_fail "[95] the scan found only $LA_CLAIMS paragraph(s) carrying a pinning claim against a floor of $LA_CLAIM_FLOOR; the claim vocabulary stopped matching, and this check would go quiet without going green for a reason"
    return 1
  fi
  return 0
}

# AND NO GREEN PRINTS BESIDE A RED, [91]'s rule verbatim.
la_verdict() {
  local line bad=0
  la_read_size "$1"
  la_floors_hold || return
  while IFS= read -r line; do
    case "$line" in
      'FAIL '*) la_fail "${line#FAIL }"; bad=$((bad + 1)) ;;
    esac
  done <<<"$1"
  [ "$bad" -eq 0 ] || return
  green "  ok   all $LA_PAIRS quoted phrase(s) called unpinned across $LA_FILES live file(s) are genuinely unpinned ($LA_CLAIMS pinning claim(s) examined)"
}

if ! command -v python3 > /dev/null 2>&1; then
  la_fail "[95] needs python3 to normalise paragraphs, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, per the tie-breaker at
  # 73-implementer-rename.sh:174-195. A FAIL-CLOSED BRANCH OUTRANKS A HIT
  # REPORT: a scan that could not finish tells the reader nothing trustworthy
  # about what it did manage to print.
  la_err=$(mktemp 2>/dev/null) || la_err=''
  if [ -z "$la_err" ]; then
    la_fail "[95] could not create the stderr capture file, so the claim scan never ran"
  else
    la_out=$(python3 - 2>"$la_err" <<'LA_PY'
import io, os, re, subprocess, sys, tempfile

# THE QUOTE CHARACTER IS SPELLED chr(96) AND THAT IS NOT AN AFFECTATION. This
# block is a heredoc inside a $(...) command substitution, and bash parses a
# backtick in there as a legacy command substitution even when the heredoc is
# quoted. [93] records the same trap and the same fix: a literal backtick in
# this source is a parse error in the fragment, which is a check that cannot run
# at all rather than one that runs wrong.
TICK = chr(96)
QUOTED = re.compile('%s([^%s\n]{3,80})%s|"([^"\n]{3,80})"' % (TICK, TICK, TICK))
CLAIMS = ('NOT pinned', 'not pinned', 'is not pinned', 'never pinned', 'unpinned',
          'nothing pins', 'not enforced', 'nothing enforces', 'not guarded',
          'nothing guards')
# The subject window. Measured: I4 puts 20 characters between the closing quote
# and the claim. Widening this to 40 formed no additional pair on the live tree,
# so the bound is not load-bearing, it is just tight enough to mean 'the subject
# of this sentence' rather than 'somewhere in this paragraph'.
WINDOW = 30
LIVE = [':(top)', ':(top,exclude)dist/*', ':(top,exclude)docs/work/*']
EXCLUDE = ('scripts/claim_corpus.json', 'scripts/claim_fixtures.json',
           'scripts/test_claim_fixtures.py',
           'scripts/validate-dod.d/95-literal-absent-claims.sh',
           'scripts/test_literal_absent_claims.py')


def read(path):
    with io.open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace')


def paragraphs(text):
    """(normalised_text, [(line_no, raw)]) per blank-line-separated block.

    Comment markers are stripped so a shell comment block reads as one
    paragraph, which is exactly where I4 lives."""
    out, buf = [], []
    for num, raw in enumerate(text.split('\n'), 1):
        body = raw.strip()
        if body.startswith('#'):
            body = body.lstrip('#').strip()
        if not body:
            if buf:
                out.append((' '.join(b for _, b in buf), list(buf)))
            buf = []
            continue
        buf.append((num, body))
    if buf:
        out.append((' '.join(b for _, b in buf), list(buf)))
    return out


def subjects(para):
    """(phrase, claim) pairs where the phrase is the nearest quote before it."""
    quotes = [(m.end(), m.group(1) or m.group(2)) for m in QUOTED.finditer(para)]
    found = []
    for claim in CLAIMS:
        at = para.find(claim)
        while at != -1:
            for end, phrase in quotes:
                gap = para[end:at]
                if end <= at and len(gap) <= WINDOW and TICK not in gap and '"' not in gap:
                    found.append((phrase, claim))
            at = para.find(claim, at + 1)
    return found


def cite(rows, needle):
    """The physical line carrying the needle. See the header on citation units."""
    for num, body in rows:
        if needle in body:
            return num
    return rows[0][0]


def elsewhere(corpus, path, phrase):
    """Files other than the claiming one that carry the phrase, exactly."""
    return sorted(q for q, text in corpus.items() if q != path and phrase in text)


def live_files():
    """Tracked paths under the same pathspec 73-implementer-rename.sh:100 scans."""
    proc = subprocess.run(['git', 'ls-files', '--'] + LIVE,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode('utf-8', 'replace'))
        raise SystemExit('git ls-files failed with rc %d' % proc.returncode)
    names = proc.stdout.decode('utf-8', 'replace').split('\n')
    return [p for p in names if p and p not in EXCLUDE]


def replay_files(root):
    """Every file a fixture materialised, relative to the replay root."""
    found = []
    for base, _dirs, names in os.walk(root):
        found.extend(os.path.relpath(os.path.join(base, n), root) for n in names)
    return sorted(found)


def replay_root():
    """Validate the replay hook or REFUSE it. Never falls back to the live scan.

    Same contract [93] states for TD_REPLAY_ROOT and for the same reason: an
    exported variable that quietly replaced the repo-wide scan with one clean
    file would print green having read nothing."""
    raw = os.environ.get('LA_REPLAY_ROOT', '')
    if not raw:
        return None
    root, tmp = os.path.realpath(raw), os.path.realpath(tempfile.gettempdir())
    if not os.path.isdir(root):
        raise SystemExit('LA_REPLAY_ROOT %r is not a directory' % raw)
    if root == os.path.realpath('.') or not root.startswith(tmp + os.sep):
        raise SystemExit('LA_REPLAY_ROOT %r is not a fixture temp dir under %s' % (raw, tmp))
    if os.path.exists(os.path.join(root, '.git')):
        raise SystemExit('LA_REPLAY_ROOT %r holds a .git, so it is a real tree' % raw)
    return root


def load(paths, root):
    """Read the whole corpus once. Every later lookup is an exact substring test."""
    corpus = {}
    for path in paths:
        full = os.path.join(root, path)
        if os.path.isfile(full):
            corpus[path] = read(full)
    return corpus


def report(path, rows, hit):
    """One judged pair, failed with the files that carry the phrase named.

    `hit` groups (phrase, claim, where) rather than taking three more
    parameters, the same tuple-grouping [93]'s _report_uses uses to stay inside
    the three-parameter cap."""
    phrase, claim, where = hit
    line = cite(rows, claim)
    print('FAIL %s:%d says %r is %s, and that phrase is present in %d other live '
          'file(s): %s' % (path, line, phrase, claim, len(where), ', '.join(where)))


def scan(corpus, mode):
    """Judge every claim/subject pair, then print the one SIZE line."""
    claims = pairs = 0
    for path in sorted(corpus):
        for para, rows in paragraphs(corpus[path]):
            if not any(c in para for c in CLAIMS):
                continue
            claims += 1
            for phrase, claim in subjects(para):
                pairs += 1
                where = elsewhere(corpus, path, phrase)
                if not where:
                    continue
                report(path, rows, (phrase, claim, where))
    print('SIZE %d %d %d %s' % (len(corpus), claims, pairs, mode))


ROOT = replay_root()
if ROOT is None:
    scan(load(live_files(), '.'), 'live')
else:
    scan(load(replay_files(ROOT), ROOT), 'replay')
LA_PY
)
    la_rc=$?
    la_errtxt=$(cat "$la_err")
    rm -f "$la_err"
    if [ "$la_rc" -ne 0 ] || [ -n "$la_errtxt" ]; then
      la_fail "[95] the claim scan did not finish (rc $la_rc), so its silence is not a verdict: ${la_errtxt:-no stderr, non-zero exit}"
    else
      la_verdict "$la_out"
    fi
  fi
fi

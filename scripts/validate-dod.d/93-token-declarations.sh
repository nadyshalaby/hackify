# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [93] DECLARED VERSUS USED. A `{{token}}` written into a sub-agent prompt is a
# claim that the dispatching parent will substitute a value for it. If the
# prompt's own INPUTS list never declares that name, nothing tells the parent to
# fill it, and the sub-agent receives literal `{{...}}` text. The template
# contract calls that a dispatch bug in as many words
# (parallel-agents/template-contract.md, "Placeholder convention"). This block
# resolves every use against that prompt's declarations and reds on any use that
# resolves to nothing.
#
# THE DEFECT IT WAS WRITTEN FOR IS THIS REPO'S OWN, and it is finding M3 in
# scripts/claim_corpus.json. The Phase 3 implementer mirror, then
# agents/wave-implementer.md, carried `{{test_file_path}}` while declaring it in
# no INPUTS list. It was fixed at ab5cb74, so it is not live at HEAD;
# scripts/claim_fixtures.json pins the blob it was live in, and
# scripts/test_token_declarations.py replays that blob through THIS fragment
# rather than through a copy of it. 0.17.1 merged that mirror into
# agents/implementer.md, which retires the path and not the fixture: the pinned
# blob is addressed by commit, so it survives the delete and that suite still
# replays it.
#
# WHERE M3 ACTUALLY SAT, because it decides the whole design. The token was NOT
# loose in the prompt body. It sat INSIDE the INPUTS block, on the continuation
# line of input 6, as part of an example string for `{{test_command}}`:
#
#     6. `{{test_command}}`, file-scoped test command template (e.g.
#        `<test runner command> {{test_file_path}}`).
#
# So "is the token somewhere inside the INPUTS section" answers YES for M3 and
# misses it. A window-based reading of the INPUTS section, of any width, cannot
# catch this finding at all. DECLARATION HAS TO BE STRUCTURAL: the contract says
# "Numbered list. Each input names a `{{placeholder}}` and the type", so the
# declared name is the FIRST token on a numbered item's own line, and a token
# quoted inside a description declares nothing. That reading catches M3 and is
# also the only reading the contract sentence supports.
#
# WHAT COUNTS AS A PROMPT, discovered rather than listed, the way [79] builds its
# file set. A live file is scanned when a line STARTS with `**INPUTS**`, which is
# the contract's own section anchor and the same grammar [9] and [36] already
# trust. Measured on the live tree: 23 files carry that anchor, 21 of them inside
# a fenced block and 2 (commands/designify.md, commands/summary.md) with the
# prompt as the whole file. Nothing else in the tree carries it, so the anchor is
# the discovery rule and there is no hand-maintained list to go stale.
#
# THE PROMPT REGION IS THE FENCED BLOCK, NESTING INCLUDED. A prompt lives inside
# a ``` block, and the OUTPUT report skeleton nests a ```` block inside it while
# the VERIFICATION script nests a ```bash block. scripts/sync_agent_mirrors.py
# takes the FIRST line of exactly three backticks and the SECOND, which stops at
# the bash block's closing fence and leaves the rest of the prompt outside what
# it copies. That is the landmine behind four defects in this repo, and it is why
# this block does NOT reuse that rule: the fence stack here is nesting-aware, so
# a bare fence closes the innermost block of matching width and anything else
# opens one. Measured on the Phase 3 implementer mirror as it stood when this was
# written, then agents/wave-implementer.md: the mirror rule bounds the prompt at
# lines 9..175 and this one at 9..236, and the OUTPUT skeleton's token uses live
# in the 61 lines between. The file is agents/implementer.md since the 0.17.1
# merge and the numbers moved with it; they are kept as the measurement that
# settled the design rather than re-taken, because what they demonstrate is the
# GAP between the two rules, not either bound.
#
# WHERE THE ANCHOR IS NOT FENCED the prompt is the whole file, but only when the
# file also carries `**ROLE**`, `**OBJECTIVE**` and `**OUTPUT**` at line start.
# Without that gate the first long reference doc to grow a bold INPUTS line would
# have every token in it measured against one prompt's list, which is a wall of
# false positives. Two files qualify today and both are single-prompt command
# bodies. An anchor that qualifies for neither reading is COUNTED and reported
# rather than failed: a doc is allowed to write that heading in prose, and
# reddening on it would be the fabrication this sprint exists to refuse.
#
# BOTH MIRROR HALVES ARE SCANNED, DELIBERATELY. agents/*.md and
# parallel-agents/*.md carry byte-identical prompt bodies, so most findings will
# print twice. That is worth one duplicate line: the mirror check only compares
# the block it copies, so a hand edit to an agents/*.md prompt outside that block
# is invisible to it, and a check that trusted the mirror would inherit the blind
# spot instead of covering it. ab5cb74 had to touch both halves for exactly this
# reason.
#
# ONE CARVE-OUT, NAMED, AND IT GUARDS ITSELF. Four prompts open with a
# "Placeholder convention" paragraph that writes `{{snake_case}}` to teach the
# token SHAPE. That is prose about the notation, not a runtime value, and no
# prompt can declare it. It is skipped by name, the skip count is printed in the
# pass line so it cannot grow unseen, and a prompt that ever DECLARES an input by
# that name reds here, because the carve-out would otherwise take that input's
# check away with it.
#
# ONLY snake_case TOKENS ARE IN CLASS. The contract says "All runtime values use
# `{{snake_case}}` placeholders", so `{{UPDATE_LOG}}` in commands/summary.md is
# not a dispatch input at all; it is a fill slot in
# skills/hackify/assets/report-template.html and belongs to a different
# namespace. Keying on lowercase is the contract's own rule rather than an
# exception list, and it is what keeps that file out without naming it.
#
# NOTHING SOURCED FROM A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN. Every
# pattern below is a literal in this file. Token names parsed out of a prompt are
# compared by exact string equality against a set, never interpolated into a
# regex and never handed to a shell. A validator that built its matcher from a
# document's contents would be arbitrary code execution by editing that document.
yellow "[93] every {{token}} used in a sub-agent prompt is declared in that prompt's INPUTS list"

# WHY LIVE PATHS AND NOT THE WHOLE TREE. The same three-part pathspec [91] uses, ':(top)'
# minus dist/ and docs/work/, for the reasons 73-implementer-rename.sh's WI_LIVE_PATHS states
# about those two directories: dist/ is generated, and docs/work/ is the sprint record, which
# has to be able to quote the broken prompt it was written to describe. WI_LIVE_PATHS itself is
# WIDER than three parts, since [40] also excludes files that must carry the literals it bans,
# so this is the same pathspec as [91] and a SUBSET of that one.
#
# THE FLOORS ARE WHAT STOP A VACUOUS PASS. If the pathspec resolves to nothing,
# if the anchor grammar stops matching, or if the fence tokenizer stops finding
# regions, every count collapses toward zero and this reds instead of printing a
# confident green. Floors and not exact counts, because prompts legitimately gain
# and lose inputs every wave; only a collapse means the scan broke. Each floor
# was set at roughly half of what the tree measured when this check was written,
# so several prompts can retire without a red. The live totals are PRINTED on the
# pass line every run rather than restated here: a count written into a comment
# goes stale the first time a sibling wave edits a prompt, and a stale count in
# the check that exists to catch stale counts is the defect wearing the uniform.
TD_PROMPT_FLOOR=15
TD_FILE_FLOOR=15
TD_DECL_FLOOR=100
TD_USE_FLOOR=350

TD_PROMPTS=0
TD_FILES=0
TD_DECLS=0
TD_USES=0
TD_SKIPPED=0
TD_LOOSE=0
TD_MODE=none

td_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

td_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r TD_PROMPTS TD_FILES TD_DECLS TD_USES TD_SKIPPED TD_LOOSE TD_MODE \
        <<<"${line#SIZE }" ;;
    esac
  done <<<"$1"
}

# THE FLOORS ARE JUDGED BEFORE ANY PER-USE RED PRINTS, the same order [91] argues
# for and for the same reason: a collapsed declaration set makes every use in the
# repo resolve to nothing, so replaying the per-use reds first would bury the one
# line that explains them under hundreds of false accusations.
#
# REPLAY MODE TRADES THE DISCOVERY FLOORS FOR A DIFFERENT ONE, and the swap is
# principled rather than a test exemption. The floors above police DISCOVERY,
# which is the thing that can silently return nothing; a replay scope holds
# exactly the files a fixture materialised, so there is no discovery to collapse.
# What can still go wrong there is a replay that parses no prompt at all, which
# would print no failures and read exactly like a clean scan, so that is the
# floor replay mode carries instead.
td_floors_hold() {
  if [ "$TD_MODE" = replay ]; then
    [ "$TD_PROMPTS" -ge 1 ] && return 0
    td_fail "[93] the replay scan parsed 0 prompt(s) out of $TD_FILES file(s), so it found no INPUTS list to resolve anything against and its silence means nothing"
    return 1
  fi
  if [ "$TD_PROMPTS" -lt "$TD_PROMPT_FLOOR" ] || [ "$TD_FILES" -lt "$TD_FILE_FLOOR" ]; then
    td_fail "[93] the prompt scan found $TD_PROMPTS prompt(s) in $TD_FILES live file(s), against floors of $TD_PROMPT_FLOOR and $TD_FILE_FLOOR; the anchor grammar or the pathspec stopped matching, and a resolver over nothing measures nothing"
    return 1
  fi
  if [ "$TD_DECLS" -lt "$TD_DECL_FLOOR" ] || [ "$TD_USES" -lt "$TD_USE_FLOOR" ]; then
    td_fail "[93] the scan read $TD_DECLS declared input(s) and $TD_USES token use(s), against floors of $TD_DECL_FLOOR and $TD_USE_FLOOR; the declaration or the token grammar stopped matching, and this check would red on correct prompts"
    return 1
  fi
  return 0
}

# AND NO GREEN PRINTS BESIDE A RED, [91]'s rule verbatim. A summary that
# contradicts the failure above it is the fail-open shape this fragment exists to
# refuse, so the pass line is reached only when nothing failed.
td_verdict() {
  local line bad=0
  td_read_size "$1"
  td_floors_hold || return
  while IFS= read -r line; do
    case "$line" in
      'FAIL '*) td_fail "${line#FAIL }"; bad=$((bad + 1)) ;;
    esac
  done <<<"$1"
  [ "$bad" -eq 0 ] || return
  green "  ok   all $TD_USES {{token}} use(s) across $TD_PROMPTS prompt(s) in $TD_FILES live file(s) resolve against the $TD_DECLS declared INPUTS entr(ies) ($TD_SKIPPED convention example(s) skipped by name, $TD_LOOSE anchor(s) outside a readable prompt)"
}

if ! command -v python3 > /dev/null 2>&1; then
  td_fail "[93] needs python3 to parse prompt regions, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, per the tie-breaker at
  # 73-implementer-rename.sh's wi_absent. A python traceback exits non-zero and
  # writes to stderr, and a bare $(...) capture swallows both, leaving this block
  # to read an empty result as "no undeclared tokens". A FAIL-CLOSED BRANCH
  # OUTRANKS A HIT REPORT: a scan that could not finish tells the reader nothing
  # trustworthy about what it did manage to print.
  td_err=$(mktemp 2>/dev/null) || td_err=''
  if [ -z "$td_err" ]; then
    td_fail "[93] could not create the stderr capture file, so the token scan never ran"
  else
    td_out=$(python3 - 2>"$td_err" <<'TD_PY'
import io, os, re, subprocess, sys, tempfile

# Every pattern here is a literal in this file. See the header.
#
# THE FENCE CHARACTER IS SPELLED chr(96) AND THAT IS NOT AN AFFECTATION. This
# whole block is a heredoc inside a $(...) command substitution, and bash parses
# a backtick in there as a legacy command substitution even when the heredoc is
# quoted. A literal fence character in this source is a parse error in the
# fragment, which is a check that cannot run at all rather than one that runs
# wrong. Measured: it took the fragment from a clean run to two syntax errors.
TICK = chr(96)
TOKEN = re.compile(r'\{\{([a-z][a-z0-9_]*)\}\}')
ITEM = re.compile(r'^ {0,3}\d{1,2}\. ')
FENCE = re.compile('^(%s{3,})(.*)$' % TICK)
MARKER = '**INPUTS**'
ANCHORS = ('**ROLE**', '**OBJECTIVE**', '**OUTPUT**')
CONVENTION = 'snake_case'
LIVE = [':(top)', ':(top,exclude)dist/*', ':(top,exclude)docs/work/*']


def read(path):
    with io.open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace')


def fenced_spans(lines):
    """Half-open spans of the top-level fenced blocks, plus whether the stack closed.

    Nesting-aware on purpose. A bare fence closes the innermost block of matching
    width; a wider or narrower bare fence, and any fence carrying an info string,
    opens one. See THE PROMPT REGION IS THE FENCED BLOCK in the header for the
    measured difference against the mirror's simpler rule."""
    spans, stack, start = [], [], 0
    for num, line in enumerate(lines):
        found = FENCE.match(line.rstrip())
        if not found:
            continue
        width, info = len(found.group(1)), found.group(2).strip()
        if stack and not info and stack[-1] == width:
            stack.pop()
            if not stack:
                spans.append((start + 1, num))
            continue
        if not stack:
            start = num
        stack.append(width)
    return spans, not stack


def region_for(lines, spans, mark):
    """The prompt an INPUTS anchor belongs to, or None when it belongs to none."""
    for low, high in spans:
        if low <= mark < high:
            return (low, high, 'fenced block')
    for anchor in ANCHORS:
        if not any(line.startswith(anchor) for line in lines):
            return None
    return (0, len(lines), 'whole file')


def inputs_end(lines, mark, high):
    """The INPUTS list runs to the next bolded section header, never a fixed window."""
    for num in range(mark + 1, high):
        if lines[num].startswith('**'):
            return num
    return high


def declared(lines, mark, end):
    """The name heading each numbered item. A token quoted in a description is not one."""
    names = set()
    for num in range(mark + 1, end):
        if not ITEM.match(lines[num]):
            continue
        found = TOKEN.search(lines[num])
        if found:
            names.add(found.group(1))
    return names


def report_prompt(path, lines, mark):
    """Print every unresolved use in one prompt. Returns its counters, or None."""
    spans, _closed = fenced_spans(lines)
    region = region_for(lines, spans, mark)
    if region is None:
        return None
    low, high, kind = region
    names = declared(lines, mark, inputs_end(lines, mark, high))
    if CONVENTION in names:
        # NO BACKSLASH-ESCAPED APOSTROPHE IN THIS BLOCK, EVER. bash counts quotes
        # across the whole $(...) and does not know what a python escape is, so
        # one \' silently closes the shell string here and reopens it three lines
        # later. Measured: it turned this fragment into a syntax error.
        print('FAIL %s:%d declares an input named {{%s}}, a name this check skips as '
              'the placeholder convention own example, so that input would silently '
              'lose its check; rename it' % (path, mark + 1, CONVENTION))
    where = '%s region lines %d..%d, %d declared: %s' % (
        kind, low + 1, high, len(names), ', '.join(sorted(names)) or 'none')
    return _report_uses(path, lines, (low, high, mark, names, where))


def _report_uses(path, lines, scope):
    """The use loop, split out only to keep both halves inside the 40-line cap."""
    low, high, mark, names, where = scope
    uses = skipped = 0
    for num in range(low, high):
        for found in TOKEN.finditer(lines[num]):
            name = found.group(1)
            if name == CONVENTION:
                skipped += 1
            elif name in names:
                uses += 1
            else:
                uses += 1
                print('FAIL %s:%d uses {{%s}}, which the INPUTS list at line %d does '
                      'not declare (%s)' % (path, num + 1, name, mark + 1, where))
    return (len(names), uses, skipped)


def scan(paths, root, mode):
    """Walk every candidate path, report, then print the one SIZE line the shell reads."""
    prompts = files = decls = uses = skipped = loose = 0
    for path in paths:
        full = os.path.join(root, path)
        if not os.path.isfile(full):
            continue
        lines = read(full).split('\n')
        marks = [n for n, line in enumerate(lines) if line.startswith(MARKER)]
        if not marks:
            continue
        files += 1
        _spans, closed = fenced_spans(lines)
        if not closed:
            print('FAIL %s leaves a %s fence open at end of file, so no prompt region '
                  'in it can be bounded and a token scan over it would be guesswork'
                  % (path, TICK * 3))
        for mark in marks:
            got = report_prompt(path, lines, mark)
            if got is None:
                loose += 1
                continue
            prompts += 1
            decls, uses, skipped = decls + got[0], uses + got[1], skipped + got[2]
    print('SIZE %d %d %d %d %d %d %s' % (prompts, files, decls, uses, skipped, loose, mode))


def live_files():
    """Tracked markdown under LIVE, the same pathspec [91] scans."""
    proc = subprocess.run(['git', 'ls-files', '--'] + LIVE,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode('utf-8', 'replace'))
        raise SystemExit('git ls-files failed with rc %d' % proc.returncode)
    names = proc.stdout.decode('utf-8', 'replace').split('\n')
    return [p for p in names if p.endswith('.md')]


def replay_files(root):
    """Every markdown file a fixture materialised, relative to the replay root."""
    found = []
    for base, _dirs, names in os.walk(root):
        found.extend(os.path.relpath(os.path.join(base, n), root)
                     for n in names if n.endswith('.md'))
    return sorted(found)


def replay_root():
    """Validate the replay hook or REFUSE it. Never falls back to the live scan.

    The hook exists so scripts/test_token_declarations.py can drive THIS fragment
    against a pinned fixture instead of a copy of it. That makes it a fail-open
    surface: an exported variable that quietly replaced the repo-wide scan with
    one clean file would print green having read nothing. So the root must be a
    directory, must not be the tree this validator is running in, must live under
    the system temp prefix a replay scope's mkdtemp uses, and must hold no .git.
    Anything else raises, which the shell reports as a scan that never ran."""
    raw = os.environ.get('TD_REPLAY_ROOT', '')
    if not raw:
        return None
    root, tmp = os.path.realpath(raw), os.path.realpath(tempfile.gettempdir())
    if not os.path.isdir(root):
        raise SystemExit('TD_REPLAY_ROOT %r is not a directory' % raw)
    if root == os.path.realpath('.') or not root.startswith(tmp + os.sep):
        raise SystemExit('TD_REPLAY_ROOT %r is not a fixture temp dir under %s' % (raw, tmp))
    if os.path.exists(os.path.join(root, '.git')):
        raise SystemExit('TD_REPLAY_ROOT %r holds a .git, so it is a real tree' % raw)
    return root


ROOT = replay_root()
if ROOT is None:
    scan(live_files(), '.', 'live')
else:
    scan(replay_files(ROOT), ROOT, 'replay')
TD_PY
)
    td_rc=$?
    td_errtxt=$(cat "$td_err")
    rm -f "$td_err"
    if [ "$td_rc" -ne 0 ] || [ -n "$td_errtxt" ]; then
      td_fail "[93] the token scan did not finish (rc $td_rc), so its silence is not a verdict: ${td_errtxt:-no stderr, non-zero exit}"
    else
      td_verdict "$td_out"
    fi
  fi
fi

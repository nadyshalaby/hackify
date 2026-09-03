# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [41] THE REQUIRED READING CONTRACT, FORWARD: EVERY TEMPLATE'S OWN LIST.
#
# WHAT WENT WRONG. Sub-agent prompts cited plugin files they were never told to
# open and mostly could not have opened. Nothing injects hackify's rules into a
# dispatched agent: the always-on hook fires on a USER prompt and a dispatch is not
# one, so a rule file reaches an agent only because a REQUIRED READING entry names
# it. A citation with no entry behind it is a rule the agent was never handed.
#
# THE BLIND SPOT THIS CHECK IS SHAPED AROUND, in one line because the obvious
# implementation reproduces it: [57] resolves a backticked path against any
# ancestor dir, the REPO AUTHOR's vantage, which proves a file exists SOMEWHERE in
# this repo and never that a dispatched agent, whose working directory is the
# USER's project, could open it. So this asserts ANCHORING, not existence.
#
# FORWARD, over every dispatchable template in parallel-agents/ PLUS the one that lives outside it, review-and-verify.md, which carries a fenced prompt with an INPUTS section and a REQUIRED READING list and so conforms only because a person made it; it is named as a LITERAL path and never globbed, so if it is renamed the scan reds loudly (by construction: read() raises on a missing path and the rr_fail below reports "the contract scan did not finish") instead of quietly covering one file less:
#   (a) the `**REQUIRED READING**.` header is present inside the fenced prompt
#   (b) it sits between `**INPUTS**` and `**OBJECTIVE**`, the contract's position
#   (c) the prompt declares `{{plugin_root}}` as a numbered INPUTS entry
#   (d) every numbered entry carries a `{{plugin_root}}`-anchored path
#   (e) every anchored path resolves once `{{plugin_root}}` becomes the repo root,
#       and resolves UNDER it, never to an absolute or parent-escaping path
#   (f) the closing two paragraphs are verbatim
#   (g) IS NOW CHECK [43], 43-verification-grammar.sh, whose header carries the
#       seam: everything left here is a question about the LIST ITSELF, while (g)
#       asks whether a sentence in a DIFFERENT section agrees with that list
#   (h) no `{{plugin_root}}`-anchored path is CITED elsewhere in the fenced prompt
#       while absent from the list, the contract's dangling-citation rule
#
# A GATED template may bind entries to a named pass instead of METHOD step 1, so
# nothing here asserts on paragraph 1's WORDING or on an entry's clause; only the
# four invariants holding across EVERY template are pinned, and a control plants a
# pass-bound entry and requires it to PASS. That tolerance and the two rules held
# back on a measured reason are argued in scripts/validate-dod.d/README.md under
# "What check [41] deliberately does not enforce". How the backward direction [42]
# divides from this is argued in 42-reader-declarations.sh's own header, beside the
# parser it leans on. Each is needed once and re-applied nowhere, which is why
# validate-dod.sh sends its own manifest prose to that file rather than cutting it.
#
# NOTHING PARSED OUT OF A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN,
# 93-token-declarations.sh's rule verbatim. Every pattern is a literal here; text
# read out of a template is compared by string equality, never interpolated into a
# regex or handed to a shell.
yellow "[41] every sub-agent template carries a REQUIRED READING list whose every path is plugin_root-anchored and resolves"

# THE FLOORS ARE THE SECOND LINE OF DEFENCE, NOT THE FIRST, and the paragraph retired
# from here claimed otherwise: it said they "stop exactly this", and at 6 against a
# live 13 templates SEVEN could vanish before the floor noticed, which is a number
# that always passes. The FIRST line is spans() returning whether its stack closed.
#
# SO A FLOOR CATCHES A TOTAL COLLAPSE AND NOTHING FINER. If ITEM stops matching every
# list reads empty, each template reds and its entry count is 0, so the floors fire too;
# if ANCHORED stops matching, check_entries reds on every row directly and the floors
# never see it, rows being counted whether or not a path was found in them. Neither
# floor sees ONE template leaving the corpus: the closure flag reds on that, and the
# 'closing fence broken' control proves that branch reachable every run.
#
# PINNED BY HAND, on check_list_size's argument in 00-helpers.sh: a bound computed off
# the scan it polices cannot police it. Raised to sit just under the live corpus, which
# is PRINTED on the pass line rather than restated here, a count in a comment rotting.
RR_TPL_FLOOR=11
RR_ENTRY_FLOOR=60

RR_TPLS=0
RR_EXEMPT=0
RR_ENTRIES=0
RR_CTRL=0
RR_CTRL_WANT=12

rr_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

rr_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r RR_TPLS RR_EXEMPT RR_ENTRIES RR_CTRL <<<"${line#SIZE }" ;;
    esac
  done <<<"$1"
}

# THE FLOORS AND CONTROLS ARE JUDGED BEFORE ANY PER-TEMPLATE RED PRINTS, the order
# 91 and 93 both argue for: a collapsed scan makes every template resolve to
# nothing, and replaying the false accusations first buries the line explaining
# them. THE CONTROL COUNT IS AN EQUALITY, the only one here: everything this check
# prints on a healthy tree is a zero, and a zero is worth what the scan's ability
# to have returned non-zero is worth (rules/claim-integrity.md, "a clean result is
# only as good as the method's ability to have returned a dirty one"). The
# controls ARE that ability, so one going missing is as loud as a real failure.
rr_floors_hold() {
  if [ "$RR_CTRL" -ne "$RR_CTRL_WANT" ]; then
    rr_fail "[41] $RR_CTRL of $RR_CTRL_WANT planted controls behaved as required, so this check has not shown it can return a dirty result and its clean lines below mean nothing"
    return 1
  fi
  if [ "$RR_TPLS" -lt "$RR_TPL_FLOOR" ]; then
    rr_fail "[41] the scan found $RR_TPLS dispatchable template(s) against a floor of $RR_TPL_FLOOR; the fence tokenizer or the INPUTS anchor stopped matching, and a contract check over nothing measures nothing"
    return 1
  fi
  if [ "$RR_ENTRIES" -lt "$RR_ENTRY_FLOOR" ]; then
    rr_fail "[41] the scan read $RR_ENTRIES required-reading entr(ies) against a floor of $RR_ENTRY_FLOOR; the entry grammar stopped matching, and this check would red on correct templates"
    return 1
  fi
  return 0
}

# AND NO GREEN PRINTS BESIDE A RED, 91's rule verbatim. A summary contradicting
# the failure above it is the fail-open shape this fragment exists to refuse.
rr_verdict() {
  local line bad=0
  rr_read_size "$1"
  rr_floors_hold || return
  while IFS= read -r line; do
    case "$line" in
      'FAIL '*) rr_fail "${line#FAIL }"; bad=$((bad + 1)) ;;
      'NOTE '*) yellow "  note ${line#NOTE }" ;;
    esac
  done <<<"$1"
  [ "$bad" -eq 0 ] || return
  green "  ok   all $RR_ENTRIES REQUIRED READING entr(ies) across $RR_TPLS template(s) are plugin_root-anchored and resolve, and $RR_EXEMPT non-dispatchable file(s) carried no fenced prompt ($RR_CTRL/$RR_CTRL_WANT controls fired)"
}

if ! command -v python3 > /dev/null 2>&1; then
  rr_fail "[41] needs python3 to parse prompt regions, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, 73-implementer-rename.sh's tie-breaker. A
  # traceback exits non-zero and writes to stderr, and a bare $(...) swallows
  # both, leaving this block to read an empty result as "no findings". A scan
  # that could not finish tells the reader nothing about what it did print.
  rr_err=$(mktemp 2>/dev/null) || rr_err=''
  if [ -z "$rr_err" ]; then
    rr_fail "[41] could not create the stderr capture file, so the contract scan never ran"
  else
    rr_out=$(python3 - 2>"$rr_err" <<'RR_PY'
import glob, os, re, sys
from collections import namedtuple

# TWO GROUPED VALUES, HOLDING THIS FILE INSIDE THE 3-PARAMETER HARD CAP
# (rules/hard-caps.md, "group into a named interface/DTO if more"): (lines, low,
# high) had pushed three helpers to 4, 5 and 7 parameters, and (mark, end) the
# fourth. Neither is a wrapper: a Region IS one fenced prompt and a Listing IS that
# prompt's required-reading section, so each name says what the value is.
Region = namedtuple('Region', 'lines low high')
Listing = namedtuple('Listing', 'mark end listed')

# THE FENCE CHARACTER IS SPELLED chr(96), 93's rule and for its measured reason:
# this block is a heredoc inside a $(...), and bash reads a literal backtick in
# there as a legacy command substitution even when the heredoc is quoted. Every
# literal below that needs one builds it from TICK for the same reason.
TICK = chr(96)
FENCE = re.compile('^(%s{3,})(.*)$' % TICK)
ITEM = re.compile(r'^ {0,4}\d{1,2}\. ')
TOKEN = re.compile(r'\{\{([a-z][a-z0-9_]*)\}\}')
ANCHORED = re.compile(r'%s\{\{plugin_root\}\}/([^%s\s]+)%s' % (TICK, TICK, TICK))

PA, RV = 'skills/hackify/references/parallel-agents', 'skills/hackify/references/review-and-verify.md'
INPUTS = '**INPUTS**'
HEADER = '**REQUIRED READING**'
OBJECTIVE = '**OBJECTIVE**'
ANCHOR_INPUT = 'plugin_root'
CLOSING = (
    'This list is EXHAUSTIVE and CLOSED.',
    'A path above that does not resolve is a dispatch bug and never a file to route',
)
def read(path):
    with open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace').split('\n')

def spans(lines):
    """Half-open spans of top-level fenced blocks, plus whether the stack closed.

    A bare fence closes the innermost block of matching width; a wider or narrower
    bare fence, and any fence carrying an info string, opens one. Copied in behaviour
    from 93-token-declarations.sh, whose header records why the mirror script's
    simpler two-fence rule bounds a prompt wrongly.

    THE SECOND RETURN VALUE IS THE HALF THAT WAS MISSING. An unclosed block is never
    appended, so the file produced NO prompt and scan() counted it EXEMPT with a
    confident note. Measured with a real violation planted: breaking the closing fence
    took [41] from a FAIL naming the unresolved path to an `ok` line with FAILED=0.
    93 has carried this flag since it was written and only this copy dropped it, which
    is what a hand-copied tokenizer costs."""
    out, stack, start = [], [], 0
    for num, line in enumerate(lines):
        found = FENCE.match(line.rstrip())
        if not found:
            continue
        width, info = len(found.group(1)), found.group(2).strip()
        if stack and not info and stack[-1] == width:
            stack.pop()
            if not stack:
                out.append((start + 1, num))
            continue
        if not stack:
            start = num
        stack.append(width)
    return out, not stack

def prompts(lines):
    """Every fenced span holding an INPUTS anchor. Empty means not dispatchable.
    This DERIVES the exemption instead of naming a file: README.md, the contract
    itself and phase-5-aggregation.md carry no fenced prompt, so they are not
    templates here and never have to be listed as exceptions."""
    found, closed = spans(lines)
    return [Region(lines, low, high) for low, high in found
            if any(lines[n].startswith(INPUTS) for n in range(low, high))], closed

def first(reg, anchor):
    for num in range(reg.low, reg.high):
        if reg.lines[num].startswith(anchor):
            return num
    return None

def section_end(reg, mark):
    """A section runs to the next bolded header, never a fixed window."""
    for num in range(mark + 1, reg.high):
        if reg.lines[num].startswith('**'):
            return num
    return reg.high

def declared(reg, mark, end):
    """The name heading each numbered INPUTS item, 93's structural reading."""
    names = set()
    for num in range(mark + 1, end):
        if ITEM.match(reg.lines[num]):
            found = TOKEN.search(reg.lines[num])
            if found:
                names.add(found.group(1))
    return names

def entries(body):
    """Group the list body into entries: a numbered line plus its continuations."""
    out = []
    for line in body:
        if ITEM.match(line):
            out.append([line])
        elif out:
            out[-1].append(line)
    return out

def check_position(label, reg, mark):
    """(b), the contract's position rule. Returns 0 or 1 failures."""
    i_in = first(reg, INPUTS)
    i_ob = first(reg, OBJECTIVE)
    if i_ob is None:
        print('FAIL %s has a REQUIRED READING section and no **OBJECTIVE**, so the '
              'contract position it must sit before does not exist' % label)
        return 1
    if not (i_in < mark < i_ob):
        print('FAIL %s puts REQUIRED READING at line %d, outside **INPUTS** (line %d) '
              'and **OBJECTIVE** (line %d); it binds before any work starts, so it sits '
              'between them' % (label, mark + 1, i_in + 1, i_ob + 1))
        return 1
    return 0

def check_path(label, rel):
    """(e) for ONE anchored entry path. Returns 0 or 1 failures.

    CONTAINMENT BEFORE EXISTENCE, and the order is the whole fix, because isfile
    answers about THIS machine and not about the plugin. Measured:
    `{{plugin_root}}//etc/hosts` yields rel='/etc/hosts' and
    `{{plugin_root}}/../../../../etc/hosts` normalises above the root, and isfile
    returned True for BOTH, so an entry naming a system file passed (e), whose own
    words are "resolves UNDER it", while the agent joining it to the REAL root
    resolves nothing and STOPs on missing canon. isabs and normpath are string
    operations on parsed text, per the header's last rule."""
    if os.path.isabs(rel) or os.path.normpath(rel).startswith('..'):
        print('FAIL %s requires {{plugin_root}}/%s, which does not resolve UNDER the '
              'plugin root; an absolute or parent-escaping path is read against this '
              'machine rather than against the plugin, so it can pass here and STOP '
              'the dispatched agent on missing canon' % (label, rel))
        return 1
    if not os.path.isfile(rel):
        print('FAIL %s requires {{plugin_root}}/%s, which is not a file in this '
              'plugin; the agent is told to STOP on a path that does not resolve'
              % (label, rel))
        return 1
    return 0

def check_entries(label, body):
    """(d) and (e). Returns (failures, entry count, anchored paths on the list)."""
    bad, listed = 0, set()
    rows = entries(body)
    if not rows:
        print('FAIL %s has a REQUIRED READING section carrying no numbered entry, so '
              'it binds its agent to nothing at all' % label)
        return 1, 0, listed
    for row in rows:
        found = ANCHORED.findall('\n'.join(row))
        if not found:
            print('FAIL %s required-reading entry %s carries no {{plugin_root}}-anchored '
                  'path; an unanchored entry resolves against the USER project a '
                  'dispatched agent runs in, never against the plugin'
                  % (label, row[0].strip()[:60]))
            bad += 1
            continue
        for rel in found:
            listed.add(rel)
            bad += check_path(label, rel)
    return bad, len(rows), listed

def check_dangling(label, reg, listing):
    """(h), the anchored half of the dangling-citation rule. See the header."""
    rest = '\n'.join(reg.lines[reg.low:listing.mark]
                     + reg.lines[listing.end:reg.high])
    bad = 0
    for rel in sorted(set(ANCHORED.findall(rest)) - listing.listed):
        print('FAIL %s cites {{plugin_root}}/%s inside its fenced prompt while its '
              'REQUIRED READING list does not name it; bind the file or drop the '
              'citation, the contract allows no third repair' % (label, rel))
        bad += 1
    return bad

def check_prompt(label, reg):
    """One prompt against the forward contract. Returns (failures, entries, listed)."""
    mark = first(reg, HEADER)
    if mark is None:
        print('FAIL %s carries a dispatchable prompt with no %s. section, so every '
              'plugin file it cites is one its agent was never told to open'
              % (label, HEADER))
        return 1, 0, set()
    bad = check_position(label, reg, mark)
    i_in = first(reg, INPUTS)
    if ANCHOR_INPUT not in declared(reg, i_in, section_end(reg, i_in)):
        print('FAIL %s anchors its REQUIRED READING paths on {{%s}} without declaring it '
              'as a numbered INPUTS entry, so nothing tells the parent to fill the one '
              'value every path is built from' % (label, ANCHOR_INPUT))
        bad += 1
    end = section_end(reg, mark)
    hurt, count, listed = check_entries(label, reg.lines[mark + 1:end])
    bad += hurt
    body = '\n'.join(reg.lines[mark:end])
    for text in CLOSING:
        if text not in body:
            print('FAIL %s REQUIRED READING section is missing its closing paragraph '
                  'opening %r; those two paragraphs are what make the list binding '
                  'rather than advisory' % (label, text[:44]))
            bad += 1
    return bad + check_dangling(label, reg, Listing(mark, end, listed)), count, listed

# @BT@ RATHER THAN A LITERAL BACKTICK, for the reason recorded at TICK above: the
# probe must carry backticked paths, and none can be typed here.
#
# ROLE, VERIFICATION and OUTPUT ARE ABSENT ON PURPOSE. [41] asserts on none of the
# three now that the VERIFICATION wording is check [43]'s, and a probe carrying
# sections this check never reads would invite a later edit to assert on them here.
BT = TICK
PROBE = '''**INPUTS**.
1. @BT@{{plugin_root}}@BT@, absolute path to the installed plugin root.
2. @BT@{{task_id}}@BT@, the task.

**REQUIRED READING**.
Open every file below IN FULL before METHOD step 1.
1. @BT@{{plugin_root}}/rules/hard-caps.md@BT@, the caps.

THE_CLOSING_ONE Every plugin file hackify requires of this role is on it.

THE_CLOSING_TWO around. STOP before METHOD step 1.

**OBJECTIVE**.
A thing.

**METHOD**.
1. Do it.
'''

def probe(edit=None):
    """The healthy synthetic template, then one planted defect. Returns its lines."""
    text = (PROBE.replace('THE_CLOSING_ONE', CLOSING[0])
            .replace('THE_CLOSING_TWO', CLOSING[1])
            .replace('@BT@', BT))
    text = '%s\n%s\n%s\n' % (TICK * 3, text, TICK * 3)
    if edit:
        text = edit(text)
    return text.split('\n')

def judge(label, lines):
    """One FILE against the forward contract. Returns (failures, prompts, entries).
    The live scan and every control come through here, so a control exercises the
    same unclosed-fence branch the corpus does."""
    found, closed = prompts(lines)
    if not closed:
        print('FAIL %s leaves a fenced block unclosed, so the tokenizer bounds no '
              'prompt in it and every assertion this check makes would be made about '
              'nothing; a file that cannot be tokenized reds here and is never counted '
              'exempt' % label)
        return 1, 0, 0
    bad = ents = 0
    for reg in found:
        hurt, count, _ = check_prompt(label, reg)
        bad += hurt
        ents += count
    return bad, len(found), ents

def run_probe(edit=None):
    """Run the REAL forward check over a probe. Identity matters, not DRY."""
    lines = probe(edit)
    out, sys.stdout = sys.stdout, open(os.devnull, 'w')
    try:
        bad, count, _ = judge('probe', lines)
        return bad if (bad or count) else -1
    finally:
        sys.stdout.close()
        sys.stdout = out

def _cut(text, start, stop):
    head, _, rest = text.partition(start)
    _, _, tail = rest.partition(stop)
    return head + stop + tail

def _reorder(text):
    head, _, rest = text.partition(HEADER)
    body, _, tail = rest.partition('**OBJECTIVE**.\nA thing.\n')
    return '%s**OBJECTIVE**.\nA thing.\n\n%s%s%s' % (head, HEADER, body, tail)

# THE CASE TABLE IS DATA AND LIVES AT MODULE SCOPE, which is what holds controls()
# inside the 40-line hard cap (rules/hard-caps.md); nested, it was rebuilt on every
# call and read as if it were logic. It sits after _cut and _reorder because the
# 'section after OBJECTIVE' row names _reorder at construction time. EACH ROW IS
# (name, edit, wanted-failure-count): the healthy baseline must PASS or every red
# below proves only that the probe was broken to start with, and each contract-legal
# variant must PASS because reddening on one would be wrong rather than strict. NO
# TEMP DIRECTORY, since (e) reads the real plugin tree, so the probe is held in
# memory and scanned in place and nothing reaches a tree a sibling is writing.
CONTROL_CASES = (
    ('healthy baseline', None, 0),
    ('pass-bound entry, contract-legal', lambda t: t.replace(
        'before METHOD step 1.', 'at pass 1 (A), not before it.'), 0),
    ('section deleted', lambda t: _cut(t, HEADER, '**OBJECTIVE**'), 1),
    ('section after OBJECTIVE', _reorder, 1),
    ('entry not anchored', lambda t: t.replace(
        '%s{{plugin_root}}/rules/hard-caps.md%s' % (TICK, TICK),
        '%srules/hard-caps.md%s' % (TICK, TICK)), 1),
    ('anchored path does not resolve', lambda t: t.replace(
        'rules/hard-caps.md', 'rules/no-such-rule.md'), 1),
    ('plugin_root used, never declared', lambda t: t.replace(
        '1. %s{{plugin_root}}%s, absolute path to the installed plugin root.\n'
        % (TICK, TICK), ''), 1),
    # BOTH CONTAINMENT CONTROLS POINT AT A FILE THAT REALLY EXISTS, which is what makes
    # them prove containment rather than existence: aimed at a MISSING file each would
    # red on the isfile branch and go on doing so with the containment check deleted.
    ('entry path is absolute', lambda t: t.replace(
        'rules/hard-caps.md', os.path.abspath('rules/hard-caps.md')), 1),
    ('entry path escapes the plugin root', lambda t: t.replace(
        'rules/hard-caps.md',
        '../%s/rules/hard-caps.md' % os.path.basename(os.getcwd())), 1),
    ('closing paragraph deleted', lambda t: t.replace(CLOSING[0], ''), 1),
    ('anchored path cited outside the list', lambda t: t.replace(
        '1. Do it.', '1. Do it, per %s{{plugin_root}}/rules/security.md%s.'
        % (TICK, TICK)), 1),
    # THE ONE THAT USED TO TURN A PLANTED RED INTO A GREEN: before spans() returned its
    # closure flag this read as "not dispatchable" rather than as a defect.
    ('closing fence broken', lambda t: t.rsplit(TICK * 3, 1)[0], 1),
)

def controls():
    """Plant each defect, require the real check to red on it. Returns how many fired."""
    fired = 0
    for name, edit, want in CONTROL_CASES:
        got = run_probe(edit)
        if (got == 0) == (want == 0) and got >= 0:
            fired += 1
        else:
            print('FAIL [41] control %r returned %d failure(s) where %s was '
                  'required, so this check does not behave as its header claims'
                  % (name, got, 'a clean pass' if want == 0 else 'at least one red'))
    return fired

def scan():
    tpls = exempt = ents = 0
    for path in sorted(glob.glob(os.path.join(PA, '*.md'))) + [RV]:
        label = os.path.basename(path)
        bad, count, seen = judge(label, read(path))
        if not bad and not count:
            exempt += 1
            print('NOTE %s carries no fenced sub-agent prompt, so the contract does not '
                  'reach it' % label)
            continue
        tpls += count
        ents += seen
    print('SIZE %d %d %d %d' % (tpls, exempt, ents, controls()))

scan()
RR_PY
)
    rr_rc=$?
    rr_errtxt=$(cat "$rr_err")
    rm -f "$rr_err"
    if [ "$rr_rc" -ne 0 ] || [ -n "$rr_errtxt" ]; then
      rr_fail "[41] the contract scan did not finish (rc $rr_rc), so its silence is not a verdict: ${rr_errtxt:-no stderr, non-zero exit}"
    else
      rr_verdict "$rr_out"
    fi
  fi
fi

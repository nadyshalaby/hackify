# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [43] THE VERIFICATION LINE MATCHES THE GRAMMAR OF ITS OWN REQUIRED READING LIST.
#
# WHAT WENT WRONG. template-contract.md §3 grew a THIRD entry form, CONDITIONAL,
# for a file a whole class of dispatch must not open, and §6 grew a third
# VERIFICATION sentence to go with it. Which sentence a template carries is not a
# preference: it is READ OFF the list the template actually carries, a plain list
# taking the universal line, a list with any step-bound entry the gated variant,
# a list with any CONDITIONAL entry the conditional variant. The forward check
# [41] asked only whether SOME line named REQUIRED READING and carried
# `(yes / no)`, which the universal line does even over a conditional list, so the
# live defect passed in silence. §6 traces what that costs the agent: the
# universal line asks whether EVERY listed path was opened, an agent that
# correctly SKIPPED a conditional entry must answer no, and a template that loops
# on a no buys termination only by lying, by opening the file its list told it to
# skip, or by quietly rereading "every path" as "every path that applied to me".
# Each of the three is a defect and the template offering only those three is the
# bug.
#
# THE SPECIFICATION IS WRITTEN DOWN AND THIS FRAGMENT IS BUILT AGAINST IT, not
# against anybody's memory of the round that found the gap: template-contract.md,
# "What the forward validator must recognise, check `[41]`". It names the check
# [41] because it was written while all of this still lived there; the split below
# is why the picker it specifies answers here instead.
#
# FOUR ASSERTIONS, over the same corpus [41] reads:
#   (i)   the prompt carries EXACTLY ONE of the three canonical sentences, and it
#         is compared VERBATIM, never by stem-and-shape
#   (ii)  that sentence is the one this list's own grammar demands
#   (iii) a list mixing step-bound with CONDITIONAL entries is out of contract
#   (iv)  every CONDITIONAL predicate names a {{token}} the same prompt declares
#         as a numbered INPUTS entry
#
# (iv) IS THE ONE THAT KEEPS A CONDITION A FACT RATHER THAN A JUDGMENT. §3 sets
# three constraints on a conditional entry and this is the only one shaped like a
# check: "read WHEN a task touches auth" names no input and is a judgment the
# agent makes for itself, "read WHEN `{{test_mode}}` is `test-authoring`" names one
# the parent already filled and is a fact two agents handed the same dispatch
# resolve identically. §3's other two constraints are review-time obligations on a
# template's author, and asserting on them would mean guessing at prose.
#
# WHY VERBATIM NOW, WHEN [41] DELIBERATELY REFUSED TO PIN A SENTENCE. Its header
# argued that a check must not encode a wording it would have to GUESS, because a
# wrong guess reds a correct file. That reason is spent: §6 states all three
# sentences word for word, so these are quoted from the contract rather than
# guessed at, and the three literals below are the whole of what (i) compares
# against. An approximation of the gated wording is now a red, and a control
# plants exactly that so the pinning is proven strict rather than described.
#
# THE SPLIT FROM [41], ON A REAL SEAM AND NOT AT A LINE COUNT. [41] asks whether
# the LIST is well formed: header present, positioned, anchored, resolving, closed
# by its two paragraphs, not citing past its own edge. Every one of those is a
# question about the list itself. This asks whether a sentence in a DIFFERENT
# section of the prompt agrees with that list's grammar, which is a question about
# the two together and is answered by neither alone. Its old home also had it
# checking `(yes / no)` and a stem, which is not the check §6 describes.
#
# NO FENCE TOKENIZER HERE, DELIBERATELY, and the equivalence that buys is ASSERTED
# rather than assumed. [41] and 93-token-declarations.sh each carry one, and
# 42-reader-declarations.sh already records why a third copy is the wrong answer:
# a duplicated tokenizer is two things to keep in step, and it went to a grep
# leaning on [41] instead. The same trade is taken here. What makes a WHOLE-FILE
# read equivalent to a per-prompt read is that a dispatchable template carries
# exactly ONE `**INPUTS**` anchor and exactly ONE `**REQUIRED READING**` header, so
# there is only one prompt for a fact to belong to. That is not left as a hope:
# vg_anchors below counts both and reds when either is not exactly one, naming the
# equivalence it just lost. A template that grows a second prompt makes this check
# weaker, and it goes red at that moment rather than quietly widening.
#
# NOTHING PARSED OUT OF A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN,
# 93-token-declarations.sh's rule verbatim. Every pattern is a literal here; text
# read out of a template is compared by string equality.
yellow "[43] every template carries exactly one of the three canonical VERIFICATION sentences, and it is the one its own REQUIRED READING grammar demands"

# THE FLOORS, on [41]'s reasoning and set against the same corpus. A grammar that
# stops matching takes the template count to zero rather than to a number just
# under the bound, so a floor sitting just below the live corpus is a collapse
# detector; one sitting at half of it is a number that always passes. Pinned by
# hand and never derived, per check_list_size in 00-helpers.sh: a bound computed
# off the scan it polices collapses with that scan.
VG_TPL_FLOOR=11
VG_CTRL_WANT=11

VG_TPLS=0
VG_EXEMPT=0
VG_CTRL=0

vg_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

vg_read_size() {
  local line
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r VG_TPLS VG_EXEMPT VG_CTRL <<<"${line#SIZE }" ;;
    esac
  done <<<"$1"
}

# CONTROLS AND FLOORS ARE JUDGED BEFORE ANY PER-TEMPLATE RED PRINTS, the order 91,
# 93 and [41] all argue for: a collapsed scan makes every template resolve to
# nothing and replaying the false accusations first buries the line explaining
# them. THE CONTROL COUNT IS AN EQUALITY, the only one here, on
# rules/claim-integrity.md's rule that a clean result is only as good as the
# method's ability to have returned a dirty one.
vg_floors_hold() {
  if [ "$VG_CTRL" -ne "$VG_CTRL_WANT" ]; then
    vg_fail "[43] $VG_CTRL of $VG_CTRL_WANT planted controls behaved as required, so this check has not shown it can return a dirty result and its clean lines below mean nothing"
    return 1
  fi
  if [ "$VG_TPLS" -lt "$VG_TPL_FLOOR" ]; then
    vg_fail "[43] the scan judged $VG_TPLS dispatchable template(s) against a floor of $VG_TPL_FLOOR; the INPUTS anchor or the entry grammar stopped matching, and a picker run over nothing measures nothing"
    return 1
  fi
  return 0
}

# NO GREEN BESIDE A RED, 91's rule verbatim.
vg_verdict() {
  local line bad=0
  vg_read_size "$1"
  vg_floors_hold || return
  while IFS= read -r line; do
    case "$line" in
      'FAIL '*) vg_fail "${line#FAIL }"; bad=$((bad + 1)) ;;
      'NOTE '*) yellow "  note ${line#NOTE }" ;;
    esac
  done <<<"$1"
  [ "$bad" -eq 0 ] || return
  green "  ok   all $VG_TPLS template(s) carry exactly one canonical VERIFICATION sentence matching their own list's grammar, and every CONDITIONAL predicate names a declared input ($VG_EXEMPT non-dispatchable file(s) skipped, $VG_CTRL/$VG_CTRL_WANT controls fired)"
}

if ! command -v python3 > /dev/null 2>&1; then
  vg_fail "[43] needs python3 to parse prompt sections, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, 73-implementer-rename.sh's tie-breaker and
  # [41]'s. A traceback exits non-zero and writes to stderr, and a bare $(...)
  # swallows both, leaving this block to read an empty result as "no findings".
  vg_err=$(mktemp 2>/dev/null) || vg_err=''
  if [ -z "$vg_err" ]; then
    vg_fail "[43] could not create the stderr capture file, so the grammar scan never ran"
  else
    vg_out=$(python3 - 2>"$vg_err" <<'VG_PY'
import glob, os, re, sys

# THE FENCE CHARACTER IS SPELLED chr(96), 93's rule and for its measured reason:
# this block is a heredoc inside a $(...), and bash reads a literal backtick in
# there as a legacy command substitution even when the heredoc is quoted.
TICK = chr(96)
ITEM = re.compile(r'^ {0,4}\d{1,2}\. ')
TOKEN = re.compile(r'\{\{([a-z][a-z0-9_]*)\}\}')

# STEP-BOUND IS RECOGNISED LENIENTLY, AND THE DIRECTION IS THE POINT. §3 writes the
# form as `path`, at <named step>; <clause>, but four live entries in
# phase-5-multi-review-merged.md stop at `path`, at pass 2 (D). with no clause, and
# [41]'s header is explicit that nothing asserts on an entry's CLAUSE. Both ways of
# being wrong here are loud rather than silent, so the choice is which false red to
# risk: reading a step-bound entry as plain would demand the universal line over a
# gated list, and this form cannot do that. It anchors immediately after the
# closing backtick of an anchored path, so a plain entry's prose clause cannot
# reach it.
STEPBOUND = re.compile(r'^ {0,4}\d{1,2}\. %s\{\{plugin_root\}\}/[^%s]*%s, (at |before step 1;)'
                       % (TICK, TICK, TICK))
COND = re.compile(r'^ {0,4}\d{1,2}\. CONDITIONAL, read WHEN ')

PA = 'skills/hackify/references/parallel-agents'
RV = 'skills/hackify/references/review-and-verify.md'
INPUTS = '**INPUTS**'
HEADER = '**REQUIRED READING**'

# THE THREE CANONICAL SENTENCES, QUOTED FROM template-contract.md §6 AND COMPARED
# VERBATIM. The order is the order the picker resolves in and the names are the
# names §6 uses.
UNIVERSAL = ('Did you open every REQUIRED READING path in full before METHOD step 1?'
             ' (yes / no)')
GATED = ('Did every REQUIRED READING path resolve before METHOD step 1, and did you'
         ' open every entry in full at the step its own entry names? (yes / no)')
CONDITIONAL = ('Did every REQUIRED READING path resolve before METHOD step 1, and did'
               ' you open in full, before METHOD step 1, every entry whose condition'
               ' your dispatch met? (yes / no)')
SENTENCES = (('universal', UNIVERSAL), ('gated', GATED), ('conditional', CONDITIONAL))


def read(path):
    with open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace').split('\n')


def first(lines, anchor):
    for num, line in enumerate(lines):
        if line.startswith(anchor):
            return num
    return None


def section_end(lines, mark):
    """A section runs to the next bolded header, never a fixed window."""
    for num in range(mark + 1, len(lines)):
        if lines[num].startswith('**'):
            return num
    return len(lines)


def entries(body):
    """Group a list body into entries: a numbered line plus its continuations."""
    out = []
    for line in body:
        if ITEM.match(line):
            out.append([line])
        elif out:
            out[-1].append(line)
    return out


def declared(lines):
    """The {{name}} heading each numbered INPUTS item, [41]'s structural reading."""
    mark = first(lines, INPUTS)
    names = set()
    if mark is None:
        return names
    for num in range(mark + 1, section_end(lines, mark)):
        if ITEM.match(lines[num]):
            found = TOKEN.search(lines[num])
            if found:
                names.add(found.group(1))
    return names


def vg_anchors(label, lines):
    """The equivalence this check's whole-file read rests on. See the header."""
    bad = 0
    for anchor in (INPUTS, HEADER):
        seen = sum(1 for line in lines if line.startswith(anchor))
        if seen != 1:
            print('FAIL %s carries %d %s anchor(s) and this check reads the whole file, '
                  'which is equivalent to reading one prompt only while there IS one '
                  'prompt; with %d there is no single list for a verification line to '
                  'be about' % (label, seen, anchor, seen))
            bad += 1
    return bad


def forms(rows):
    """Which entry grammars this list carries. §3's three forms, no fourth."""
    seen = set()
    for row in rows:
        head = row[0]
        if COND.match(head):
            seen.add('conditional')
        elif STEPBOUND.match(head):
            seen.add('gated')
        else:
            seen.add('universal')
    return seen


def wanted(seen):
    """§6's picker, read off the list rather than off preference."""
    if 'conditional' in seen:
        return 'conditional'
    if 'gated' in seen:
        return 'gated'
    return 'universal'


def check_predicates(label, rows, inputs):
    """(iv). A predicate names an input the parent filled, never a judgment."""
    bad = 0
    for row in rows:
        if not COND.match(row[0]):
            continue
        text = '\n'.join(row)
        head, sep, _ = text.partition(':')
        if not sep:
            print('FAIL %s conditional entry %r never closes its predicate with a colon, '
                  'so nothing separates the condition from the path it guards'
                  % (label, row[0].strip()[:60]))
            bad += 1
            continue
        named = set(TOKEN.findall(head)) & inputs
        if not named:
            print('FAIL %s conditional entry %r has a predicate naming no {{token}} this '
                  'prompt declares as a numbered INPUTS entry, so its condition is a '
                  'judgment the agent makes rather than a fact the parent decided, and '
                  'two agents on one dispatch can skip different entries'
                  % (label, row[0].strip()[:60]))
            bad += 1
    return bad


def check_sentence(label, lines, want):
    """(i) and (ii). Verbatim, exactly one, and the one the list demands."""
    carried = [name for name, text in SENTENCES
               if any(text in line for line in lines)]
    if len(carried) > 1:
        print('FAIL %s carries the %s VERIFICATION sentences at once; §6 allows EXACTLY '
              'ONE, never two and never none' % (label, ' and '.join(carried)))
        return 1
    if not carried:
        print('FAIL %s carries none of the three canonical VERIFICATION sentences '
              'verbatim on one unwrapped line; its list demands the %s wording, which '
              'template-contract.md §6 states word for word' % (label, want))
        return 1
    if carried[0] != want:
        print('FAIL %s carries the %s VERIFICATION sentence while its REQUIRED READING '
              'list demands the %s one; a line that does not match its own list either '
              'demands a read the template forbids or widens its own bar into one it '
              'passes by construction' % (label, carried[0], want))
        return 1
    return 0


def check_file(label, lines):
    """One template against §6's picker. Returns (failures, judged)."""
    if first(lines, INPUTS) is None:
        return 0, 0
    bad = vg_anchors(label, lines)
    mark = first(lines, HEADER)
    # NEITHER EARLY RETURN ADDS A FAILURE OF ITS OWN, and that is deliberate rather
    # than an omission. With no list there is no grammar for a sentence to match, so
    # this check has nothing to say and says nothing; both conditions are ALREADY
    # reported, and reporting them twice would put two reds on one defect. A missing
    # header is vg_anchors' red just above (it requires exactly one and saw none). An
    # empty list is [41] assertion (d)'s red, "carrying no numbered entry". The count
    # returned here is only read as `judged` by scan(), so an increment nothing prints
    # would have raised a number no line explains.
    if mark is None:
        return bad, 1
    rows = entries(lines[mark + 1:section_end(lines, mark)])
    if not rows:
        return bad, 1
    seen = forms(rows)
    if 'gated' in seen and 'conditional' in seen:
        print('FAIL %s mixes step-bound and CONDITIONAL entries on one list, which §6 '
              'places out of contract; the two variants cannot be merged into one '
              'honest sentence, so the repair is to pick one shape' % label)
        bad += 1
    bad += check_sentence(label, lines, wanted(seen))
    return bad + check_predicates(label, rows, declared(lines)), 1


# NOT ONE LITERAL BACKTICK IN THIS PROBE, and TICK is why: the whole python block
# is a heredoc inside a $(...), where bash tokenizes a backtick as a legacy command
# substitution even though the heredoc delimiter is quoted. NOTHING REACHES DISK
# either, so nothing is left in a tree a sibling track is writing.
BT = TICK
PROBE = '''**ROLE**.
You are a senior engineer.

**INPUTS**.
1. @BT@{{plugin_root}}@BT@, absolute path to the installed plugin root.
2. @BT@{{test_mode}}@BT@, the mode this dispatch runs in.

**REQUIRED READING**.
Open every file below IN FULL before METHOD step 1.
1. @BT@{{plugin_root}}/rules/hard-caps.md@BT@, the caps.

**OBJECTIVE**.
A thing.

**VERIFICATION**.
1. THE_VLINE

**OUTPUT**.
- Report.
'''

PLAIN = '1. @BT@{{plugin_root}}/rules/hard-caps.md@BT@, the caps.'.replace('@BT@', BT)
STEP = ('1. %s{{plugin_root}}/rules/hard-caps.md%s, at pass 2; the caps.'
        % (TICK, TICK))
COND_OK = ('1. CONDITIONAL, read WHEN %s{{test_mode}}%s is %stest-authoring%s:\n'
           '   %s{{plugin_root}}/rules/hard-caps.md%s, the caps.'
           % (TICK, TICK, TICK, TICK, TICK, TICK))
COND_JUDGED = ('1. CONDITIONAL, read WHEN a task touches auth:\n'
               '   %s{{plugin_root}}/rules/hard-caps.md%s, the caps.'
               % (TICK, TICK))


def probe(entry=PLAIN, line=UNIVERSAL):
    text = PROBE.replace('@BT@', BT).replace('THE_VLINE', line)
    return text.replace(PLAIN, entry).split('\n')


def run_probe(entry=PLAIN, line=UNIVERSAL):
    """Run the REAL picker over a probe. Identity matters, not DRY."""
    out, sys.stdout = sys.stdout, open(os.devnull, 'w')
    try:
        return check_file('probe', probe(entry, line))[0]
    finally:
        sys.stdout.close()
        sys.stdout = out


# EACH ROW IS (name, entry, verification line, wanted-failure-count). At module
# scope because it is DATA, which is what holds controls() inside the 40-line hard
# cap. The healthy rows matter as much as the reddening ones: a check that reds on
# a contract-legal template is wrong rather than strict, and without them every red
# below would prove only that the probe was broken to start with.
CONTROL_CASES = (
    ('plain list, universal line', PLAIN, UNIVERSAL, 0),
    ('step-bound list, canonical gated line', STEP, GATED, 0),
    ('conditional list, canonical conditional line', COND_OK, CONDITIONAL, 0),
    # THE LIVE DEFECT THIS FRAGMENT EXISTS FOR. [41] passed this in silence.
    ('conditional list beside the universal line', COND_OK, UNIVERSAL, 1),
    ('conditional predicate naming no declared input', COND_JUDGED, CONDITIONAL, 1),
    ('step-bound list beside the universal line', STEP, UNIVERSAL, 1),
    ('plain list beside the gated line', PLAIN, GATED, 1),
    # WHAT VERBATIM PINNING BUYS, planted so it is proven rather than described.
    # This wording is the approximation [41]'s control carried while the gated
    # sentence was deliberately unpinned; §6 now states it word for word, so an
    # approximation of it is a defect.
    ('approximation of the gated wording', STEP,
     'Did every REQUIRED READING path resolve before step 1, and did you open each'
     ' at the step its entry names? (yes / no)', 1),
    ('verification line hard-wrapped', PLAIN,
     'Did you open every REQUIRED READING path in full before\n   METHOD step 1?'
     ' (yes / no)', 1),
    ('no verification line at all', PLAIN, 'Did you do the work? (yes / no)', 1),
    ('two canonical sentences at once', PLAIN, UNIVERSAL + '\n2. ' + GATED, 1),
)


def controls():
    fired = 0
    for name, entry, line, want in CONTROL_CASES:
        got = run_probe(entry, line)
        if (got == 0) == (want == 0):
            fired += 1
        else:
            print('FAIL [43] control %r returned %d failure(s) where %s was required, '
                  'so this check does not behave as its header claims'
                  % (name, got, 'a clean pass' if want == 0 else 'at least one red'))
    return fired


def scan():
    tpls = exempt = 0
    for path in sorted(glob.glob(os.path.join(PA, '*.md'))) + [RV]:
        bad, judged = check_file(os.path.basename(path), read(path))
        if not judged:
            exempt += 1
            continue
        tpls += 1
    print('SIZE %d %d %d' % (tpls, exempt, controls()))


scan()
VG_PY
)
    vg_rc=$?
    vg_errtxt=$(cat "$vg_err")
    rm -f "$vg_err"
    if [ "$vg_rc" -ne 0 ] || [ -n "$vg_errtxt" ]; then
      vg_fail "[43] the grammar scan did not finish (rc $vg_rc), so its silence is not a verdict: ${vg_errtxt:-no stderr, non-zero exit}"
    else
      vg_verdict "$vg_out"
    fi
  fi
fi

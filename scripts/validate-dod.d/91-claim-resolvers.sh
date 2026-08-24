# shellcheck shell=bash

# ---------------------------------------------------------------------------
# [91] CLAIM RESOLVERS. A sentence that says "check [NN]" is a claim that there
# is executable code behind that id. This block resolves every such claim in a
# live file against the ids the validator actually declares, and reds on any
# claim that resolves to nothing.
#
# THE DEFECT IT WAS WRITTEN FOR IS THIS REPO'S OWN. A previous sprint recorded
# that scripts/validate-dod.d/71-release-mechanism-pins.sh:287 enforced a
# CHANGELOG.md line pointer, called that verified green state, and told a
# downstream agent that breaking it would redden the id `[71]`. Lines 283 to 293
# of that file are a comment block, no fragment declares an id `[71]` at all
# (71-release-mechanism-pins.sh declares [38c] through [38h]), and no fragment
# reads CHANGELOG.md by line number anywhere. The agent caught it by reading the
# code instead of the claim. This block is the reader that does not have to.
#
# WHAT COUNTS AS A DECLARATION, and it is the same grammar [76i] already trusts.
# A check is declared where it prints its own header: `yellow "[NN]"` at line
# start in a fragment. Two checks cannot live in a fragment at all, [0] and [0b],
# for the reasons scripts/validate-dod.sh gives above each of them, so that
# file's own "checks that do NOT live in a fragment" manifest is read as the
# second declaration source. THAT SECOND SOURCE IS THE WEAKER OF THE TWO, and it
# is worth knowing where its edge is: it reads a hand-maintained comment block,
# so an id could in principle be legitimised by adding a line there rather than
# by writing a check. The floor below catches that block collapsing, never a
# forged entry in it. It is two ids wide today and it stays readable by hand,
# which is the only reason that edge is acceptable.
#
# WHY NOT EVERY [NN] TOKEN IN THE FRAGMENTS. A bare-token sweep over
# scripts/validate-dod.d/*.sh returns 88 ids where only 81 are declared. The
# seven extras are `[70]`, which names a check FAMILY rather than a printed
# check (77-reviewer-roster.sh:18 says so in as many words), and `[78a]` through
# `[78f]`, which label comment blocks INSIDE check [78]. Building the known set
# from the token sweep would have made a fabricated `[78c]` resolve, which is
# the whole failure this block exists to refuse.
#
# HOW THE MARKDOWN REFERENCE-LINK COLLISION IS EXCLUDED. Live markdown carries
# 136 bare `[NN]` tokens, almost all of them reference-link syntax: `[label][12]`
# at the use site and `[12]: https://...` at the definition. Keying on the bare
# token would drown this check in false positives. THE EXCLUSION RULE IS THAT
# THE LITERAL WORD "check" OR "checks" PLUS ONE SPACE MUST IMMEDIATELY PRECEDE
# THE BRACKET. Neither markdown reference form can produce that, so all 136 are
# out by construction rather than by an exception list, and what is left is 31
# sentences that really do assert a check exists.
#
# THE RANGE-ENDPOINT CARVE-OUT CANNOT TRIP THIS, BY CONSTRUCTION.
# 76-phase-ledger-substrate.sh:379 argues that `check [75]` claims nothing about
# how many checks 75 holds, and it is right. This block resolves EXISTENCE and
# nothing else: never how many checks an id covers, never where a range ends,
# never which fragment holds it. A sentence about range endpoints is therefore
# outside what is measured here, and [75] is a declared id besides. Range
# endpoints stay [76i]'s job.
#
# THE `is pinned by` HALF IS DELIBERATELY ABSENT. Measured before it was
# dropped: `(is|are) (pinned|enforced|guarded|checked) by ` matches 7 live lines,
# and not one names a check id in its "by" clause. They name a reviewer, a file
# allowlist, a matcher and the Phase 4 evidence rule. A rule on that grammar
# would be 7 false positives out of 7, which is the same fabrication defect this
# sprint targets, pointed the other way. Its sharp form, "X is pinned by check
# [NN]", is already inside the grammar above.
#
# NO SELF-EXCLUSION, DELIBERATELY. 70-invariants-and-new.sh has to exclude
# itself because it holds the literals it bans. This file holds no fabricated
# ids, so it is scanned like every other, and a future edit that invents one
# here reddens here.
#
# NOTHING SOURCED FROM A REPO FILE IS EXECUTED OR COMPILED INTO A PATTERN. Every
# pattern below is a literal in this file. Ids parsed out of the repo are
# compared by exact string equality against a set, never interpolated into a
# regex and never handed to a shell. A validator that built its matcher from a
# document's contents would be arbitrary code execution by editing that document.
yellow "[91] every 'check [NN]' claim in a live file names a check id the validator declares"

# WHY LIVE PATHS AND NOT THE WHOLE TREE. Same three-part pathspec
# 70-invariants-and-new.sh:216 uses, and for its stated reasons. dist/ is
# generated. docs/work/ is the sprint record, and a record has to be able to
# quote the wrong claim it was written to describe; this sprint's own
# retrospective has to name the id that did not exist, and a check that reddens
# on the document explaining why it exists is unusable. ':(top)' is the positive
# half and is not decoration: an exclusion-only pathspec is one reading away from
# resolving to no files, and a scan over no files is green forever.
#
# THE FLOOR IS WHAT STOPS A VACUOUS PASS. If the pathspec resolves to nothing, if
# the reference grammar stops matching, or if git ls-files fails, the reference
# count collapses toward zero and this reds instead of printing a confident
# green. A floor and not an exact count, because ordinary prose adds and removes
# these sentences every wave; only a collapse means the scan broke.
CR_REF_FLOOR=20
CR_FRAG_ID_FLOOR=60
CR_ORCH_ID_FLOOR=2

cr_fail() {
  red "  FAIL $*"
  FAILED=$((FAILED + 1))
}

# THE FLOORS ARE JUDGED BEFORE ANY PER-CLAIM RED PRINTS, and the order is
# load-bearing rather than tidy. A collapsed known set makes every claim in the
# repo resolve to nothing, so replaying the per-claim reds first would bury the
# one line that explains them under 32 false accusations. Measured, not feared:
# the first draft printed the whole wall. A scan that cannot be trusted names
# itself and says nothing about the claims it read, which is the same tie-break
# 70-invariants-and-new.sh:290-311 makes between a broken scan and its hits.
#
# AND NO GREEN PRINTS BESIDE A RED. The first tamper run reported one unresolved
# claim and then said all 33 resolved, on adjacent lines. A summary that
# contradicts the failure above it is the fail-open shape this fragment exists to
# refuse, so the pass line is reached only when nothing failed.
cr_verdict() {
  local out="$1" line refs=0 frag=0 orch=0 files=0 bad=0
  while IFS= read -r line; do
    case "$line" in
      'SIZE '*) read -r refs frag orch files <<<"${line#SIZE }" ;;
    esac
  done <<<"$out"
  if [ "$refs" -lt "$CR_REF_FLOOR" ]; then
    cr_fail "[91] the claim scan read $files live file(s) and found only $refs 'check [NN]' claim(s) against a floor of $CR_REF_FLOOR; the grammar or the pathspec stopped matching, and a resolver over nothing measures nothing"
    return
  fi
  if [ "$frag" -lt "$CR_FRAG_ID_FLOOR" ] || [ "$orch" -lt "$CR_ORCH_ID_FLOOR" ]; then
    cr_fail "[91] the known-id set collapsed to $frag fragment id(s) and $orch orchestrator id(s), against floors of $CR_FRAG_ID_FLOOR and $CR_ORCH_ID_FLOOR; every claim would resolve to nothing and this check would red on correct text"
    return
  fi
  while IFS= read -r line; do
    case "$line" in
      'FAIL '*) cr_fail "${line#FAIL }"; bad=$((bad + 1)) ;;
    esac
  done <<<"$out"
  [ "$bad" -eq 0 ] || return
  green "  ok   all $refs 'check [NN]' claim(s) across $files live file(s) resolve against the $((frag + orch)) declared check ids"
}

if ! command -v python3 > /dev/null 2>&1; then
  cr_fail "[91] needs python3 to resolve check-id claims, and it is not on PATH"
else
  # STDERR IS CAPTURED AND WEIGHED, per the tie-breaker at
  # 70-invariants-and-new.sh:290-311. A python traceback exits non-zero and
  # writes to stderr, and a bare $(...) capture swallows both, leaving this block
  # to read an empty result as "no unresolved claims". A FAIL-CLOSED BRANCH
  # OUTRANKS A HIT REPORT: a scan that could not finish tells the reader nothing
  # trustworthy about what it did manage to print, so rc or stderr is reported
  # on its own and never alongside a verdict.
  cr_err=$(mktemp 2>/dev/null) || cr_err=''
  if [ -z "$cr_err" ]; then
    cr_fail "[91] could not create the stderr capture file, so the claim scan never ran"
  else
    cr_out=$(python3 - 2>"$cr_err" <<'CR_PY'
import io, os, re, subprocess, sys

FRAGDIR = "scripts/validate-dod.d"
ORCH = "scripts/validate-dod.sh"
# A fragment declares a check by printing its header. The orchestrator's two
# non-fragment checks never print their id, so their only declaration site is
# the manifest comment block at the top of the orchestrator.
FRAG_DECL = re.compile(r'^yellow "\[(\d+[a-z]?)\]', re.M)
ORCH_DECL = re.compile(r'^#\s+\[(\d+[a-z]?)\]', re.M)
# The word, one space, the bracket. See the exclusion rule above.
CLAIM = re.compile(r'(?i)\bchecks? \[(\d+[a-z]?)\]')
LIVE = [':(top)', ':(top,exclude)dist/*', ':(top,exclude)docs/work/*']


def read(path):
    with io.open(path, 'rb') as handle:
        return handle.read().decode('utf-8', 'replace')


def declared_ids():
    """Every check id with a printed header behind it, plus the orchestrator's two."""
    frag = set()
    for name in sorted(os.listdir(FRAGDIR)):
        if name.endswith('.sh'):
            frag.update(FRAG_DECL.findall(read(os.path.join(FRAGDIR, name))))
    return frag, set(ORCH_DECL.findall(read(ORCH)))


def live_files():
    """Tracked paths under the same pathspec 70-invariants-and-new.sh:216 scans."""
    proc = subprocess.run(['git', 'ls-files', '--'] + LIVE,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode('utf-8', 'replace'))
        raise SystemExit('git ls-files failed with rc %d' % proc.returncode)
    return [p for p in proc.stdout.decode('utf-8', 'replace').split('\n') if p]


def claims(paths):
    """Every (path, line, id) a live file asserts. Ids are compared, never compiled."""
    found = []
    for path in paths:
        if not os.path.isfile(path):
            continue
        for num, line in enumerate(read(path).split('\n'), 1):
            found.extend((path, num, m.group(1)) for m in CLAIM.finditer(line))
    return found


frag_ids, orch_ids = declared_ids()
known = frag_ids | orch_ids
paths = live_files()
found = claims(paths)
searched = ('searched `yellow "[NN]"` at line start across %s/*.sh (%d ids) and the '
            'non-fragment ids named in %s (%d ids)'
            % (FRAGDIR, len(frag_ids), ORCH, len(orch_ids)))
for path, num, ident in found:
    if ident in known:
        continue
    print('FAIL %s:%d asserts a check [%s] that no fragment declares, %s'
          % (path, num, ident, searched))
print('SIZE %d %d %d %d' % (len(found), len(frag_ids), len(orch_ids), len(paths)))
CR_PY
)
    cr_rc=$?
    cr_errtxt=$(cat "$cr_err")
    rm -f "$cr_err"
    if [ "$cr_rc" -ne 0 ] || [ -n "$cr_errtxt" ]; then
      cr_fail "[91] the claim scan did not finish (rc $cr_rc), so its silence is not a verdict: ${cr_errtxt:-no stderr, non-zero exit}"
    else
      cr_verdict "$cr_out"
    fi
  fi
fi

# shellcheck shell=bash

# [76] Phase-ledger substrate + always-on phase discipline (v0.14.0).
#
# The ledger vanished on Claude Code for one reason: runtime-adapters.md mapped
# the `todo tracker` primitive to a bare `TodoWrite`, while all six other
# runtimes spelled out a degrade inside their own cell. A model reading that
# table found a tool name that is frequently absent from the session and no
# instruction for what to do instead, so the tracker disappeared with nothing
# saying it should have fallen back to anything.
#
# Everything pinned below is a promise some file now makes about where the
# ledger LIVES, plus the discipline that keeps it ticking. None of it had any
# validator coverage before this block existed, which is exactly how the
# contract rotted the first time. Two of the phase files pinned here had never
# contained the word "ledger" at any commit before this sprint.
#
# Split out of 70-invariants-and-new.sh, which sits at 498 lines against the
# 500-LOC hard cap that check [80] enforces. Compacting unrelated blocks there
# to buy room would trade a real invariant for a cosmetic one.
#
# THIS FILE THEN HIT THE SAME CAP, at exactly 500 LOC, and [76g] and [76h] moved
# to 96-review-scope-sites.sh with their check IDs. They asked a different
# question from the rest of this file, whether one review-scope rule is stated
# the same way at every site that states it, and they read none of the PLS_
# variables declared below, so the seam cost no shared state. [76i] stayed,
# because a check on this validator's own header manifest belongs beside the
# fragment enumeration check [76f] that guards the neighbouring half of it.
#
# Own variables, own prefix: 70 and 75 are still in scope when this fragment is
# sourced, and reusing their names would couple the fragments so that a rename
# in either one kills the whole validator under `set -u`.

PLS_ADAPTERS="skills/hackify/references/runtime-adapters.md"
PLS_LEDGER_REF="skills/hackify/references/phase-ledger.md"
PLS_SKILL="skills/hackify/SKILL.md"
PLS_WORK_DOC_TPL="skills/hackify/references/work-doc-template.md"
PLS_PHASE_RULES="rules/phase-discipline.md"
PLS_PHASES_DIR="skills/hackify/references/phases"

yellow "[76] the canonical ledger sentence is stated whole in both files that carry it"
# Two files promise the same thing about where a full-mode ledger lives, and the
# entire value of that promise is that they say it in the SAME words. Pinning
# only the bolded clause would match by construction in each file separately and
# would stay green while the two sentences drifted apart around it, so the pin
# carries the WHOLE sentence. `phase-ledger.md` is the contract and `SKILL.md` is
# the file a model reads first; a reader who consults one of them must never get
# a different answer from the other.
PLS_CANON='The ledger opens at task start in every mode as a printed block, and in full hackify it is **written into the work-doc as section 0 at Phase 2 step 1**.'
check_token_present "$PLS_CANON" "$PLS_LEDGER_REF"
check_token_present "$PLS_CANON" "$PLS_SKILL"

# That sentence points at a section which has to exist somewhere. Without the
# template block there is nothing for Phase 2 step 1 to instantiate, and the
# durable half of the substrate is a promise with no home.
#
# Anchored to a whole line, NOT a fixed substring. This same file also names
# `## 0. Phase ledger` inside its section-order law comment fifteen lines below,
# so a plain substring pin stays green while the real heading is renamed out from
# under it. Caught by tampering: renaming the heading left the substring pin
# passing. Only a line that IS the heading counts.
if grep -qE '^## 0\. Phase ledger[[:space:]]*$' "$PLS_WORK_DOC_TPL"; then
  green "  ok   $PLS_WORK_DOC_TPL opens a real '## 0. Phase ledger' section"
else
  red "  FAIL $PLS_WORK_DOC_TPL has no '## 0. Phase ledger' heading; the canonical sentence points at a section that does not exist"
  FAILED=$((FAILED + 1))
fi

yellow "[76b] every per-phase protocol file names the ledger at its open and at its exit"
# The two longest phase files, phase-3-implement.md and phase-2.5-spec-review.md,
# had never contained the word "ledger" at any commit before v0.14.0. That is the
# drift this pin stops: a phase whose protocol never says to tick anything is a
# phase that quietly stops being ticked.
#
# Globbed, never hand-listed. A fixed list of six goes stale the day a seventh
# phase file lands, and that new file would join the set with no ledger lines and
# nothing complaining. The count guard is what stops the glob passing vacuously
# if the directory is ever moved or renamed.
PLS_PHASE_FILES=$(find "$PLS_PHASES_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
PLS_PHASE_COUNT=0
while IFS= read -r pf; do
  [ -n "$pf" ] || continue
  PLS_PHASE_COUNT=$((PLS_PHASE_COUNT + 1))
  check_token_present 'Ledger, at phase open' "$pf"
  check_token_present 'Ledger, at phase exit' "$pf"
done <<PLS_PHASES_EOF
$PLS_PHASE_FILES
PLS_PHASES_EOF
if [ "$PLS_PHASE_COUNT" -ge 6 ]; then
  green "  ok   $PLS_PHASE_COUNT per-phase protocol files scanned for ledger open + exit lines"
else
  red "  FAIL only $PLS_PHASE_COUNT files found under $PLS_PHASES_DIR, expected at least 6 (a moved or renamed directory must redden here, not pass vacuously)"
  FAILED=$((FAILED + 1))
fi

yellow "[76c] the Claude Code todo-tracker cell carries a degrade, not just a tool name"
# Pin the DEGRADE CLAUSE, never the tool name. A check on `TodoWrite` would have
# passed on every commit throughout the bug, because the bare tool name IS what
# the broken cell said. The clause is matched inside the EXTRACTED ROW, so moving
# it up into the prose bullet above the table fails here, which is the point: a
# model reading the table has to learn the degrade from the table.
# Here-string, not a pipe into `grep -q`: the orchestrator runs under `pipefail`
# and `grep -q` short-circuits, which can SIGPIPE the producer (see [38]).
PLS_TODO_ROW=$(grep -F -- '| todo tracker |' "$PLS_ADAPTERS" 2>/dev/null || true)
if [ -z "$PLS_TODO_ROW" ]; then
  red "  FAIL $PLS_ADAPTERS has no '| todo tracker |' table row at all"
  FAILED=$((FAILED + 1))
elif grep -qF -- 'gated and frequently absent, so fall back to' <<<"$PLS_TODO_ROW"; then
  green "  ok   the todo tracker row states its degrade inside the Claude Code cell"
else
  red "  FAIL the '| todo tracker |' row names a tool with no degrade; the ledger vanishes and nothing in the table tells the model to fall back"
  FAILED=$((FAILED + 1))
fi

yellow "[76d] the always-on injection primitive is a real table row, and SKILL.md names it"
# Pin the ROW NAME, not a per-cell string: two of this row's cells use the file's
# own `n/a, same as Codex CLI` shorthand, so a per-cell pin would snap the moment
# a neighbouring cell was reworded while saying nothing about the row surviving.
# The leading pipe is load-bearing, the bare words also appear in the primitive
# count sentence and in the prose bullet, both of which outlive a deleted row.
check_token_present '| always-on injection |' "$PLS_ADAPTERS"
# SKILL.md keeps its own copy of the primitive list, and that copy sat at 11 for
# two waves after the adapter table moved to 12. Nothing caught it, because
# nothing was looking at this file's list.
#
# Matched with its LIST NEIGHBOUR, never as a bare phrase. SKILL.md also talks
# about always-on injection in prose (the rules-files sentence, the file
# map, the always-on list), and this sprint keeps adding more of it, so a bare
# substring goes green on prose alone while the primitive list quietly drops back
# to 11. Proven by tampering: stripping the list and leaving one prose mention
# passed the bare pin. Only the list carries this ordering.
check_token_present 'completion sentinel / always-on injection' "$PLS_SKILL"

yellow "[76e] the load-bearing phase laws survive the post-turn-1 digest"
# Every pin here carries the leading `- ` and both pairs of asterisks on purpose. The
# injector's BULLET_LEAD regex keeps ONLY bold bullet leads after the first
# prompt of a session, so a law demoted to body prose is still in the file, still
# greps clean on its own words, and is gone from every prompt after the first.
# Matching the bullet form is what makes these guard REACH rather than presence.
#
# ALL FIVE LEADS, IN FILE ORDER, AND THE COUNT AT THE BOTTOM IS WHAT KEEPS THAT
# TRUE. This block pinned three of the file's five bullets while its banner named
# the load-bearing laws as a set, so the banner over-claimed by two laws and
# nothing said so. Laws 1 and 5 are pinned here now for the reason the other three
# already were, and neither was ever special enough to have earned the omission.
#
# WHAT [38] COVERS FOR LAW 1, AND WHAT IT DOES NOT. [38] pins `unless it is
# trivial or read-only`, which is law 1's carve-out CLAUSE and sits OUTSIDE the
# bold; hooks/test_inject_context.sh then drives the real digest and asserts that
# same clause reaches turn 2, because it is 33 chars against the injector's
# QUALIFIER_MAX_CHARS of 34 and a two-word reword deletes it. Both guard the
# QUALIFIER. Neither one looks at law 1's own lead, so the mandate inside the
# asterisks could be rewritten wholesale with the carve-out untouched and both
# checks staying green. That is the hole the first pin below closes, and the
# carve-out stays where it is rather than being restated here.
check_token_present '- **Every task that edits code opens the step ledger**' "$PLS_PHASE_RULES"
check_token_present '- **Phases run in order, one open at a time.**' "$PLS_PHASE_RULES"
# The no-silent-skip law is the most direct statement of what this sprint was
# asked for, and it was the law this block was left without. Same bullet form,
# same reason: de-bolded it still greps clean on its own words while reaching
# nothing after turn 1. The trailing period sits INSIDE the asterisks in the
# source line, so it belongs inside them here too.
check_token_present '- **No phase is ever silently skipped.**' "$PLS_PHASE_RULES"
check_token_present '- **Every question goes through the wizard tool.**' "$PLS_PHASE_RULES"
# THE LONGEST LEAD IN THE FILE, AND THE ONLY ONE CARRYING TWO RULES AT ONCE. A
# wave folded the per-returning-agent write rule and the archive-immediately rule
# into this single bold run, so one reword takes BOTH out of every prompt after
# the first while the body prose underneath still greps clean on their words.
# Pinned WHOLE for that reason: a pin on a fragment of this lead leaves whichever
# rule sits outside the fragment free to be reworded around it.
check_token_present '- **A tick with no reflection is an untrusted tick, and a deferred write is no tick at all: checkbox and written entry land together as each agent returns, and the archive move follows the closing edit.**' "$PLS_PHASE_RULES"
# A CLAIM ABOUT A SET IS WORTH THE COUNT WRITTEN BESIDE IT AND NOT A LINE MORE.
# Five pins name five laws today. A SIXTH law lands in the digest with nothing
# pinning its bullet form, this banner goes back to over-claiming in silence, and
# the three-of-five state above is exactly what that looks like after it has sat
# for a while. `5` is written HERE, by hand, next to the five named pins: a bound
# READ OFF the file it polices drops with a deleted law and stays green, the
# failure 00-helpers.sh argues above check_list_size in the words that a floor of
# 4 once sat under a set of 6 and guarded nothing.
#
# THE COUNTER MATCHES THE INJECTOR'S OWN BULLET_LEAD SHAPE, not a narrower
# `- **`. A law rewritten as `* **...**` or `1. **...**` still reaches the digest,
# so it still has to be counted here; a narrower matcher would drop it from the
# count and from the pins at once, and the two reds would cancel into a green.
PLS_LAW_LEADS=$(grep -cE '^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]+\*\*' "$PLS_PHASE_RULES" 2>/dev/null) || PLS_LAW_LEADS=0
check_list_size "$PLS_LAW_LEADS" 5 "${PLS_PHASE_RULES}'s bolded law leads, each pinned above by name"

yellow "[76f] validate-dod.sh's own fragment enumeration names every fragment it sources"
# The orchestrator's header comment is the map anyone reads to find which fragment
# owns which check. It is hand-maintained, it is a comment, and NOTHING was looking
# at it: three fragments (27, 76, 85) were sourced and running while the map never
# mentioned them. The triad stayed green the whole time. Same silent-rot class this
# block exists to close, sitting inside the validator itself.
#
# Scoped to the HEADER, never to the whole file. Every basename also appears on its
# own `source` line, so a file-scoped grep matches that line and passes on a header
# that names nothing. Proven by tampering: the whole-file form went GREEN with the
# `76` row deleted.
#
# Presence of the basename only. Asserting each row's check RANGE would fail on
# correct text the day a `[76g]` lands, which is a pin that breaks on progress.
#
# One-directional on purpose. It catches sourced-but-not-named, which is the
# rot that actually happened. It does NOT catch named-but-not-sourced: a row
# left behind for a deleted or renamed fragment stays green forever. The
# reverse direction needs its own floor guard and is not bought here.
#
# Documented bias: a wave that adds a fragment without adding its header row
# reddens here. That is the intent, not a stale constant.
PLS_ORCH="scripts/validate-dod.sh"
PLS_ENUM_HEADER=$(awk '/^set -uo pipefail/{exit} /^#/' "$PLS_ORCH")
PLS_ENUM_FRAGS=$(grep -E '^source ' "$PLS_ORCH" | grep -oE '[0-9]+-[A-Za-z0-9._-]+\.sh' | sort -u || true)
PLS_ENUM_COUNT=0
PLS_ENUM_MISSING=0
while IFS= read -r frag; do
  [ -n "$frag" ] || continue
  PLS_ENUM_COUNT=$((PLS_ENUM_COUNT + 1))
  grep -qF -- "$frag" <<<"$PLS_ENUM_HEADER" && continue
  red "  FAIL $PLS_ORCH sources $frag but its header enumeration never names it"
  FAILED=$((FAILED + 1))
  PLS_ENUM_MISSING=$((PLS_ENUM_MISSING + 1))
done <<PLS_ENUM_EOF
$PLS_ENUM_FRAGS
PLS_ENUM_EOF
# Floor, not an exact count: a legitimately retired fragment must not redden this.
# Deliberately looser than [76b]'s floor of 6, which guards a directory that only
# grows; this one guards a hand-edited list that can also shrink.
if [ "$PLS_ENUM_COUNT" -lt 10 ]; then
  red "  FAIL only $PLS_ENUM_COUNT source lines parsed from $PLS_ORCH, expected at least 10 (a changed source-line format must redden here, not pass vacuously)"
  FAILED=$((FAILED + 1))
elif [ "$PLS_ENUM_MISSING" -eq 0 ]; then
  green "  ok   all $PLS_ENUM_COUNT sourced fragments are named in $PLS_ORCH's header enumeration"
fi

yellow "[76i] the header manifest's check-id RANGES agree with the fragments they describe"
# THE ONLY MANIFEST ROW SHAPE THAT CAN GO POSITIVELY WRONG. scripts/validate-dod.sh opens
# with a hand-written row per fragment. Most under-describe theirs and that is fine:
# `check [75]` claims nothing about how many checks 75 holds. A RANGE ENDPOINT is
# different, because it asserts a MAXIMUM. `checks [76]-[76g]` went false the day [76h]
# shipped, silently, in the same commit that made it stale.
#
# [76f] GUARDS THE NEIGHBOURING HALF, that every sourced fragment is named in the header
# by basename, and argues against pinning each row's range because that "would fail on
# correct text the day a [76g] lands". Right about a HARDCODED range, wrong about a
# DERIVED one: this reads both ends off the fragment, so it reddens on a stale row and
# goes green once the row is updated, which is what that comment actually wanted.
#
# CHECKED ONLY WHERE THE ROW MAKES A CLAIM A FRAGMENT CAN CONTRADICT. If the row's FIRST
# item is a range its start must be the fragment's LOWEST declared check; if the LAST item
# is a range its end must be the HIGHEST. Everything else is skipped BY CONSTRUCTION, not
# by exception list: a gloss row naming one id claims no bound, and `[7]-[15], [36]` gets
# its start checked and its end skipped because [36], not [15], is the last thing it
# names. That is what keeps this off the two deliberate gloss rows.
#
# DECLARED MEANS `yellow "[..]"` AT LINE START, never a mention anywhere in the file.
# 71-release-mechanism-pins.sh names [38b] twice in its own comments while [38b] is
# DECLARED in 70-invariants-and-new.sh, so a whole-file grep reads 71's minimum as [38b]
# and reddens a correct row. Not foreseen: a live wrong premise, caught by measuring.
#
# THE FLOOR STOPS THIS PASSING VACUOUSLY. Reformat the header past the row pattern and
# every row stops parsing (empty parser output included), and it prints a confident zero.
# A floor rather than an exact count, for [76f]'s reason on its own: this polices a
# hand-edited list that legitimately shrinks when a row changes style, and only a collapse
# toward zero means the parser broke.
PLS_RANGE_FLOOR=12
if ! command -v python3 > /dev/null 2>&1; then
  red "  FAIL [76i] needs python3 to parse the header manifest, and it is not on PATH"
  FAILED=$((FAILED + 1))
else
pls_range_out=$(python3 - <<'PLS_RANGE_PY'
import io, os, re

ORCH = "scripts/validate-dod.sh"
FRAGDIR = "scripts/validate-dod.d"
def key(tok):
    m = re.match(r'^(\d+)([a-z]?)$', tok)
    return (int(m.group(1)), m.group(2))
head = []
for line in io.open(ORCH, encoding='utf-8'):
    if line.startswith('set -uo pipefail'):
        break
    head.append(line.rstrip('\n'))
ROW = re.compile(r'^#\s{2,}(\d+-[A-Za-z0-9._-]+\.sh),\s+checks?\s+(.*)$')
CONT = re.compile(r'^#\s{4,}(\S.*)$')
rows = []
for line in head:
    m = ROW.match(line)
    if m:
        rows.append([m.group(1), m.group(2)])
        continue
    c = CONT.match(line) if rows else None
    if c:
        rows[-1][1] += ' ' + c.group(1)

ITEM = re.compile(r'^\[(\d+[a-z]?)\](?:\s*-\s*\[(\d+[a-z]?)\])?')
SEP = re.compile(r'^\s*(?:,\s*(?:and\s+)?|\s+and\s+)')
def parse_run(text):
    items, rest = [], text
    while True:
        m = ITEM.match(rest)
        if not m:
            break
        items.append((m.group(1), m.group(2)))
        rest = rest[m.end():]
        sep = SEP.match(rest)
        if not sep:
            break
        rest = rest[sep.end():]
    return items
checked = 0
for frag, text in rows:
    path = os.path.join(FRAGDIR, frag)
    if not os.path.isfile(path):
        print("NOTE %s is named in the header manifest but is not a file under %s, no range compared" % (frag, FRAGDIR))
        continue
    body = io.open(path, encoding='utf-8').read()
    declared = re.findall(r'^yellow "\[(\d+[a-z]?)\]', body, re.M)
    items = parse_run(text)
    if not declared:
        print('NOTE %s declares no `yellow "[..]"` check id at line start, no range compared' % frag)
        continue
    if not items:
        print("FAIL %s names no parseable check id in its header row" % frag)
        continue
    lo, hi = min(declared, key=key), max(declared, key=key)
    first, last = items[0], items[-1]
    if first[1]:
        checked += 1
        if first[0] != lo:
            print("FAIL %s header row opens its range at [%s], but the fragment's lowest declared check is [%s]" % (frag, first[0], lo))
        else:
            print("OK   %s header range opens at [%s], the fragment's lowest declared check" % (frag, first[0]))
    if last[1]:
        checked += 1
        if last[1] != hi:
            print("FAIL %s header row closes its range at [%s], but the fragment's highest declared check is [%s]" % (frag, last[1], hi))
        else:
            print("OK   %s header range closes at [%s], the fragment's highest declared check" % (frag, last[1]))
print("COUNT %d" % checked)
PLS_RANGE_PY
)
  pls_range_n=0
  while IFS= read -r pls_line; do
    case "$pls_line" in
      'OK   '*) green "  ok   ${pls_line#OK   }" ;;
      'FAIL '*) red "  FAIL ${pls_line#FAIL }"; FAILED=$((FAILED + 1)) ;;
      'NOTE '*) yellow "  note ${pls_line#NOTE }" ;;
      'COUNT '*) pls_range_n=${pls_line#COUNT } ;;
    esac
  done <<PLS_RANGE_EOF
$pls_range_out
PLS_RANGE_EOF
  if [ "$pls_range_n" -lt "$PLS_RANGE_FLOOR" ]; then
    red "  FAIL [76i] only $pls_range_n range endpoints were compared, expected at least $PLS_RANGE_FLOOR (a changed header format stops the rows parsing and this check would pass on nothing)"
    FAILED=$((FAILED + 1))
  else
    green "  ok   $pls_range_n header-manifest range endpoints compared against their fragments"
  fi
fi

yellow "[76j] quick's review-phase name is the SAME name at all three sites that state it"
# ONE PHASE, THREE SITES, AND A RENAME THAT LANDED WITH NOTHING WATCHING IT. Quick's
# Phase 5 review step was called `Single-lens` until a wave renamed it, because ONE
# reviewer carrying EVERY lens is close to the opposite of what the old name said. The
# rename is coherent at all three sites today and nothing in scripts/ or hooks/ was
# looking at any of them, so a reword in ONE file would strand the other two, leave one
# phase called two things, and move no check. That is the defect the rename repaired,
# which makes shipping the rename unpinned shipping it with a fuse in it.
#
# THE NAME IS DERIVED FROM EACH SITE AND IS NEVER WRITTEN DOWN HERE, which is exactly
# what a presence pin does not buy. Three `check_token_present` pins on the literal name
# do redden on a partial reword, but the obvious repair for that red is to UPDATE THE
# LITERAL: a wave renaming the two clauses inside skills/quick/SKILL.md sees two reds
# naming that one file, fixes the two pins, and leaves the ledger row in phase-ledger.md
# saying the old name with the whole gate green. The pin becomes a fourth site that has
# to agree. So each row below carries a name-AGNOSTIC anchor, the fixed frame its clause
# is built from with the name left as its only variable run, and the check compares what
# it lifts out of the three. A COHERENT rename passes here with no edit, which is right:
# what is guarded is disagreement between the sites, not the vocabulary they agree on.
#
# ONE ANCHOR PER SITE, BECAUSE THE NAME OCCURS TWICE IN ONE FILE. skills/quick/SKILL.md
# states it in its frontmatter description AND again as its flow-table step heading, so
# a file-scoped pin on the bare name greens on either one alone and says nothing when
# the other breaks. Each row is anchored on prose unique to its own site and demands
# EXACTLY ONE match in that file, so a single break reddens and names the file it is in.
#
# CASE-FOLDED, DELIBERATELY. The frontmatter states the name mid-sentence in lower case
# while the other two open a heading with it, so the three cannot agree byte for byte
# and an exact-case comparison would redden on correct prose.
#
# `5-lite` IS LOAD-BEARING IN TWO OF THE THREE ANCHORS and stays that way. It is quick's
# canonical phase name at eleven sites with nothing pinning it either, so anchoring on it
# makes a `5-lite` rename LOUDER, two extra reds naming exactly the two files that have to
# change, and no harder: those two are already among the eleven such a rename edits.
#
# /usr/bin/grep BY ABSOLUTE PATH and every exit code read, for the reasons 00-helpers.sh
# gives above check_no_token: a bare `grep` is a shell function in at least one agent
# harness, and a count of 0 from a search that errored is a count of nothing.
# Written HERE, by hand, beside the three rows it stands over, never counted off them:
# a bound read off the list it polices drops with a deleted row and stays green, the
# failure 00-helpers.sh records above check_list_size in the words that a floor of 4
# once sat under a set of 6 and guarded nothing.
PLS_LENS_SITES_EXPECTED=3
pls_lens_n=0
pls_lens_seen=''
# One row per site: path | extended regex whose only variable run is the name | literal
# prefix to strip | literal suffix to strip | what the site is called in a red line.
# Quoted heredoc delimiter so nothing in the table expands, and `read -r` so the regex
# backslashes arrive exactly as written.
while IFS='|' read -r pls_lp pls_lrx pls_lpre pls_lsuf pls_llabel; do
  [ -n "$pls_lp" ] || continue
  pls_lhit=$(/usr/bin/grep -oE -- "$pls_lrx" "$pls_lp" 2>/dev/null)
  pls_lrc=$?
  if [ "$pls_lrc" -gt 1 ]; then
    red "  FAIL [76j] could not scan $pls_lp for its $pls_llabel (grep exited $pls_lrc), so a count of 0 here would be a count of nothing"
    FAILED=$((FAILED + 1))
    continue
  fi
  if [ -z "$pls_lhit" ]; then
    red "  FAIL [76j] $pls_lp carries no $pls_llabel matching the review-phase-name anchor; the clause was reworded past its own frame, or the site is gone"
    FAILED=$((FAILED + 1))
    continue
  fi
  pls_lnl=${pls_lhit//[^$'\n']/}
  pls_lcount=$(( ${#pls_lnl} + 1 ))
  if [ "$pls_lcount" -ne 1 ]; then
    red "  FAIL [76j] $pls_lp carries $pls_lcount $pls_llabel clauses, expected exactly 1; an anchor matching more than one site cannot redden when one of them breaks"
    FAILED=$((FAILED + 1))
    continue
  fi
  pls_lname=${pls_lhit#"$pls_lpre"}
  pls_lname=${pls_lname%"$pls_lsuf"}
  case "$pls_lname" in
    ''|*[!A-Za-z-]*)
      red "  FAIL [76j] $pls_lp's $pls_llabel matched as '$pls_lhit' but no single-word name came out of it; the fixed frame around the name has drifted"
      FAILED=$((FAILED + 1))
      continue ;;
  esac
  pls_lfold=$(printf '%s' "$pls_lname" | tr '[:upper:]' '[:lower:]')
  pls_lens_n=$((pls_lens_n + 1))
  pls_lens_seen="$pls_lens_seen$pls_lfold|$pls_lp's $pls_llabel
"
  green "  ok   $pls_lp names quick's review phase '$pls_lname' in its $pls_llabel"
done <<'PLS_LENS_EOF'
skills/quick/SKILL.md|[A-Za-z][A-Za-z-]* address-all review still closes before finish|| address-all review still closes before finish|frontmatter clause
skills/quick/SKILL.md|\*\*5-lite\. [A-Za-z][A-Za-z-]* review\*\*|**5-lite. | review**|flow-table step heading
skills/hackify/references/phase-ledger.md|Phase 5-lite\. [A-Za-z][A-Za-z-]* address-all review|Phase 5-lite. | address-all review|quick ledger row
PLS_LENS_EOF
# The floor that stops the comparison below passing on nothing. Two rows that both
# failed to resolve leave one name, one name agrees with itself, and the agreement
# green would print with total confidence over a single surviving site.
check_list_size "$pls_lens_n" "$PLS_LENS_SITES_EXPECTED" "the sites stating quick's review-phase name, each anchored above by its own clause"

# THE FIRST RESOLVED SITE IS THE REFERENCE AND THE RED NAMES BOTH SIDES, rather than
# adjudicating one of them wrong. Which site is the stale one is not a thing this check
# can know: at two sites there is no majority to read it off, and a majority rule that
# works only at three breaks the day a fourth site picks the name up.
pls_lens_first=''
pls_lens_ref=''
pls_lens_bad=0
while IFS= read -r pls_lrow; do
  [ -n "$pls_lrow" ] || continue
  pls_lfold=${pls_lrow%%|*}
  pls_lwhere=${pls_lrow#*|}
  if [ -z "$pls_lens_first" ]; then
    pls_lens_first=$pls_lfold
    pls_lens_ref=$pls_lwhere
  elif [ "$pls_lfold" != "$pls_lens_first" ]; then
    red "  FAIL [76j] $pls_lwhere calls quick's review phase '$pls_lfold', while $pls_lens_ref calls it '$pls_lens_first'; one phase with two names is a reword that stranded the sites it did not reach"
    FAILED=$((FAILED + 1))
    pls_lens_bad=$((pls_lens_bad + 1))
  fi
done <<PLS_LENS_CMP_EOF
$pls_lens_seen
PLS_LENS_CMP_EOF
if [ "$pls_lens_n" -gt 1 ] && [ "$pls_lens_bad" -eq 0 ]; then
  green "  ok   all $pls_lens_n sites call quick's review phase '$pls_lens_first' (compared case-folded)"
fi

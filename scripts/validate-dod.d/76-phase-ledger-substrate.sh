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
# about always-on injection in prose (the four-rules-files sentence, the file
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
# The scope carve-out and the injector registration are pinned at [38] already
# and are deliberately not repeated here.
check_token_present '- **Phases run in order, one open at a time.**' "$PLS_PHASE_RULES"
check_token_present '- **Every question goes through the wizard tool.**' "$PLS_PHASE_RULES"
# The no-silent-skip law is the most direct statement of what this sprint was
# asked for, and it was the law this block was left without. Same bullet form,
# same reason: de-bolded it still greps clean on its own words while reaching
# nothing after turn 1. The trailing period sits INSIDE the asterisks in the
# source line, so it belongs inside them here too.
check_token_present '- **No phase is ever silently skipped.**' "$PLS_PHASE_RULES"

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

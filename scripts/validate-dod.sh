#!/usr/bin/env bash
# Validate the hackify plugin against its shipping Definition of Done.
# Run from repo root. Exits 0 if all checks pass, non-zero on any failure.
#
# Thin orchestrator. Helper functions and check groups live in
# scripts/validate-dod.d/*.sh and are sourced in the order indexed below.
#
# THE MANIFEST MOVED; ONLY THE INDEX STAYED. Every row's prose now lives in
# scripts/validate-dod.d/README.md, word for word: what each fragment holds, why
# a split was cut at one check rather than its neighbour, and the corrections
# several rows exist to record. It left because 267 of this file's 487 lines
# were that prose, against the 500-LOC cap check [80] enforces, and two more
# fragments would have breached it.
#
# WHAT STAYED, AND WHY IT COULD NOT ALL GO. Three checks read this index here
# rather than reading the README: [76f] requires every sourced fragment to be
# NAMED in this header, [76i] parses each row's check-id range and compares both
# endpoints against that fragment's own declarations, and
# scripts/test_ban_tokens.d/40-fragment-coverage.sh matches the literal
# `<fragment>, check [NN],` for the four fragments nothing else outside this
# file names. So a row here is a LOOKUP, one line, never a record. The record is
# the README, and a row added here needs its paragraph added there.
#
#   00-helpers.sh, color printers, the ok counter, the line-oriented absence family, and the loop that sources every other helper fragment beside it
#   01-presence-matchers.sh, the presence matchers, both flattened matchers and the shared membership count
#   02-file-shape-checks.sh, the whole-file shape assertions
#   10-required-files.sh, checks [1]-[6b], required files, JSON shape, and the leak screens over shipped content and over the live work-doc that Phase 6 publishes
#   20-templates.sh, checks [7]-[15], [36] (template contracts incl. agents/)
#   27-marketplace-ref-pin.sh, check [27], marketplace channel pins match plugin.json
#   30-version-and-summary.sh, checks [16]-[20]
#   40-quick-skill.sh, checks [21]-[23], [35]
#   41-required-reading.sh, check [41], every sub-agent template carries a REQUIRED READING list whose every path is plugin_root-anchored and resolves
#   42-reader-declarations.sh, check [42], every file that declares a hackify agent loads it is named by that agent's REQUIRED READING list
#   43-verification-grammar.sh, check [43], every template carries exactly one of the three canonical VERIFICATION sentences and it is the one its own REQUIRED READING grammar demands
#   50-runtimes-and-companions.sh, checks [24]-[26], [28]
#   55-mirror-completeness.sh, check [55], sync manifest covers every tracked canonical file
#   56-dist-integrity.sh, check [56], every file the sync COPIES into dist/<runtime>/ is byte-identical to the canonical source
#   57-doc-links.sh, check [57], every cited .md link and prose path resolves to a real file
#   58-contradiction-miner.sh, check [58], a routing predicate table mined for a file asserting not-X where a named authority asserts X
#   60-primitives.sh, checks [29]-[32]
#   70-invariants-and-new.sh, checks [33]-[34], [37], [38], [38b], [39], the structural invariants
#   71-release-mechanism-pins.sh, checks [38c]-[38d] and [38f]-[38g], one block per shipped saving
#   72-diff-slicing-pins.sh, checks [38e], [38h] and [38j], the diff-slicing and carry-over mechanism, the settle-echo file set, and the Phase 6 publish contract with its temp-directory rule
#   73-implementer-rename.sh, check [40], the Phase 3 implementer rename pinned from both ends
#   74-agent-shell-blocks.sh, check [74], every fenced shell block in a dispatchable agent template parses under /bin/bash
#   75-ship-bar.sh, check [75], the always-on ship bar wired in every mode
#   751-orchestration-tier.sh, check [75i], the orchestration tier, iteration driver and completion sentinel wired as defaults in every mode
#   752-wizard-contract.sh, checks [75j]-[75k], the wizard contract and the question banks it governs
#   76-phase-ledger-substrate.sh, checks [76]-[76f], [76i], the phase-ledger substrate and this header's own rows
#   761-manifest-readme-sync.sh, check [76j], the index above and scripts/validate-dod.d/README.md name the same fragments, in both directions
#   77-reviewer-roster.sh, check [77], reviewer-roster drift in COUNT grammar
#   78-dispatch-mandate.sh, check [78], no parent-authored diffs, and orchestration that is a tool call rather than a description
#   79-standing-member-invariant.sh, check [79], the ROSTER-CLAIM half of the roster guard
#   80-file-size-caps.sh, checks [80] and [80b], file-size ≤ 500 LOC across primitives, and the two counters agreeing at the cap boundary
#   801-cap-enforcer-agreement.sh, check [80c], this validator and the lawkeeper scanner waive and raise that cap over the same files
#   81-no-claude-attribution.sh, check [81], no Co-Authored-By trailer, Claude-Session line or generated-with footer
#   82-throughput-and-routing.sh, checks [82]-[82g], the throughput and routing doctrine of the 0.18.x sprint
#   83-testing-stage-shape.sh, check [83], the testing stage's shape
#   84-no-pipe-into-grep-q.sh, check [84], nothing in scripts/, in hooks/, or in a fenced shell block in an agent template pipes into a short-circuiting reader
#   85-design-spec-conformance.sh, check [85], design-spec catalog conformance (contract + WCAG AA contrast)
#   86-skill-command-namespace.sh, check [86], every slash command written in prose is read from both ends
#   87-agent-roster-rows.sh, check [87], the dispatch roster in parallel-agents/README.md read from both ends against agents/
#   88-plugin-map.sh, check [88], the orientation map rules/plugin-map.md read from both ends against the tree it describes
#   89-reviewer-rename.sh, check [89], the 0.18.0 Phase 5 reviewer rename pinned from both ends
#   90-collisions.sh, check [90], sibling-plugin slug collision (soft)
#   91-claim-resolvers.sh, check [91], every 'check [NN]' claim in a live file resolves to a check the validator declares
#   92-work-doc-structure.sh, check [92], no tracked work-doc numbers two sections the same
#   93-token-declarations.sh, check [93], every {{token}} in a sub-agent prompt is declared by that prompt's own INPUTS list
#   94-section-exists.sh, check [94], every instruction naming a work-doc section names one the template declares
#   95-literal-absent-claims.sh, check [95], every claim that a quoted phrase is not pinned is checked by looking the phrase up
#   96-review-scope-sites.sh, checks [76g]-[76h], the docs/work/ exclusion on the reviewed diff and the FULL-round gate wording
#   97-test-suites-reachable.sh, check [97], every tracked test suite is reachable from .github/workflows/ci.yml
#   98-work-doc-ledger-sync.sh, check [98], an archived work-doc closes every row of its section 0 phase ledger
#   99-work-doc-status-claims.sh, check [99], every tracked work-doc's frontmatter status is one the template's own row declares
#
# Two checks do NOT live in a fragment and are written out below instead:
#   [0]  the wiring guard, disk and source list must agree in both directions
#   [0b] a floor on the run's own ok-line total
# Both are here because a check that guards the source list cannot be reached
# through the source list. See the comment above each one.
#
# Note: -e is intentionally omitted, modules accumulate failures into
# FAILED and the orchestrator exits non-zero at the end. -e would abort
# on the first failed check and hide the rest.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0
DOD_MODULES_DIR="$REPO_ROOT/scripts/validate-dod.d"

cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# [0] WIRING GUARD. Every fragment on disk is sourced below, and every source
# line below names a fragment that is actually there. Both directions, because
# each one alone leaves the hole the other covers.
#
# WHY IT LIVES HERE AND NOT IN A FRAGMENT. [76f] in 76-phase-ledger-substrate.sh
# guards the neighbouring half of this, sourced-but-not-named-in-the-header, and
# says in its own comment that it is one-directional and cannot catch
# named-but-not-sourced. That missing direction cannot be bought by adding
# another fragment: deleting the source line for THAT fragment takes the check
# away with it, which is exactly the tamper it exists to catch. A guard whose own
# disappearance is the thing it guards against is not a guard. This file is the
# only one that cannot be un-sourced, because running it IS the run, so the check
# lives here. Same reasoning [80b] gives for making itself its own probe.
#
# WHY printf AND NOT red()/green(). 00-helpers.sh is a fragment like any other
# and its source line can go too. With no helpers loaded, red() is a missing
# command, the failure message prints nothing at all, and the run still walks
# into `exit 0`. FAILED is a plain shell variable that needs no helper, so the
# printf form reddens and exits 1 whether or not 00-helpers.sh was sourced.
#
# MEASURED, not feared: deleting the single source line for
# 71-release-mechanism-pins.sh dropped the run from 1400 ok lines to 851, with
# 0 FAIL, "ALL CHECKS PASSED" printed, and exit 0.
printf '\033[33m%s\033[0m\n' "[0] every fragment on disk is sourced, and every source line names a fragment that exists"
DOD_SELF="$REPO_ROOT/scripts/validate-dod.sh"
DOD_SOURCED=$(grep -E '^source ' "$DOD_SELF" 2>/dev/null | grep -oE '[0-9]+-[A-Za-z0-9._-]+\.sh' | sort -u)
DOD_DISK_N=0
DOD_LINE_N=0
DOD_WIRING_BAD=0

# Direction one, the tamper this guard was written for: a fragment sitting on
# disk that nothing sources. Its checks do not fail, they simply never happen.
for dod_frag in "$DOD_MODULES_DIR"/*.sh; do
  [ -f "$dod_frag" ] || continue
  DOD_DISK_N=$((DOD_DISK_N + 1))
  dod_base=${dod_frag##*/}
  grep -qxF -- "$dod_base" <<<"$DOD_SOURCED" && continue
  printf '\033[31m%s\033[0m\n' "  FAIL scripts/validate-dod.d/$dod_base exists but $DOD_SELF never sources it, so every check it holds is absent from this run and cannot fail it"
  FAILED=$((FAILED + 1))
  DOD_WIRING_BAD=$((DOD_WIRING_BAD + 1))
done

# Direction two: a source line naming a fragment that is not there. `source` on a
# missing file returns 1, and with -e deliberately omitted the run carries on
# with that fragment's checks silently gone. A rename or a typo lands here, and
# direction one cannot see it because the basename is right there in the text.
while IFS= read -r dod_name; do
  [ -n "$dod_name" ] || continue
  DOD_LINE_N=$((DOD_LINE_N + 1))
  [ -r "$DOD_MODULES_DIR/$dod_name" ] && continue
  printf '\033[31m%s\033[0m\n' "  FAIL $DOD_SELF sources $dod_name but scripts/validate-dod.d/$dod_name is missing or unreadable, so that source line is a no-op and its checks never run"
  FAILED=$((FAILED + 1))
  DOD_WIRING_BAD=$((DOD_WIRING_BAD + 1))
done <<DOD_WIRING_EOF
$DOD_SOURCED
DOD_WIRING_EOF

# BOTH SIDES FLOORED. An empty directory compared against an empty source list
# agrees perfectly and proves nothing. A clean verdict over an empty set is the
# vacuous pass this guard exists to refuse, so it is reported as a failure rather
# than printed as a green. Floors and not an exact count, because a legitimately
# retired fragment must not redden this; 15 against today's 20 leaves room to
# retire several and still refuses a set that has collapsed.
if [ "$DOD_DISK_N" -lt 15 ] || [ "$DOD_LINE_N" -lt 15 ]; then
  printf '\033[31m%s\033[0m\n' "  FAIL the [0] wiring scan found $DOD_DISK_N fragment(s) on disk and $DOD_LINE_N source line(s), expected at least 15 of each; a wiring check over an empty set measures nothing"
  FAILED=$((FAILED + 1))
elif [ "$DOD_WIRING_BAD" -eq 0 ]; then
  # Counted by hand here rather than through green(), which is not defined yet.
  DOD_OK_COUNT=$((${DOD_OK_COUNT:-0} + 1))
  printf '\033[32m%s\033[0m\n' "  ok   all $DOD_DISK_N fragments in scripts/validate-dod.d/ are sourced, and all $DOD_LINE_N source lines name a readable fragment"
fi

# THE THREE HELPER LINES ARE THE WIRING [0] READS, and they stay named one per
# line for that reason. Sourcing 00-helpers.sh also sources the other two through
# the loop at the foot of that file, which is what lets a fragment run in isolation
# outside this orchestrator reach every helper from one source line; the argument is
# written there. Re-sourcing a definition-only fragment redefines its functions and
# touches no counter, so what the redundancy costs a full run is two file reads.
source "$DOD_MODULES_DIR/00-helpers.sh"
source "$DOD_MODULES_DIR/01-presence-matchers.sh"
source "$DOD_MODULES_DIR/02-file-shape-checks.sh"
source "$DOD_MODULES_DIR/10-required-files.sh"
source "$DOD_MODULES_DIR/20-templates.sh"
source "$DOD_MODULES_DIR/27-marketplace-ref-pin.sh"
source "$DOD_MODULES_DIR/30-version-and-summary.sh"
source "$DOD_MODULES_DIR/40-quick-skill.sh"
source "$DOD_MODULES_DIR/41-required-reading.sh"
source "$DOD_MODULES_DIR/42-reader-declarations.sh"
source "$DOD_MODULES_DIR/43-verification-grammar.sh"
source "$DOD_MODULES_DIR/50-runtimes-and-companions.sh"
source "$DOD_MODULES_DIR/55-mirror-completeness.sh"
source "$DOD_MODULES_DIR/56-dist-integrity.sh"
source "$DOD_MODULES_DIR/57-doc-links.sh"
source "$DOD_MODULES_DIR/58-contradiction-miner.sh"
source "$DOD_MODULES_DIR/60-primitives.sh"
source "$DOD_MODULES_DIR/70-invariants-and-new.sh"
source "$DOD_MODULES_DIR/71-release-mechanism-pins.sh"
source "$DOD_MODULES_DIR/72-diff-slicing-pins.sh"
source "$DOD_MODULES_DIR/73-implementer-rename.sh"
source "$DOD_MODULES_DIR/74-agent-shell-blocks.sh"
source "$DOD_MODULES_DIR/75-ship-bar.sh"
source "$DOD_MODULES_DIR/751-orchestration-tier.sh"
source "$DOD_MODULES_DIR/752-wizard-contract.sh"
source "$DOD_MODULES_DIR/76-phase-ledger-substrate.sh"
source "$DOD_MODULES_DIR/761-manifest-readme-sync.sh"
source "$DOD_MODULES_DIR/77-reviewer-roster.sh"
source "$DOD_MODULES_DIR/78-dispatch-mandate.sh"
source "$DOD_MODULES_DIR/79-standing-member-invariant.sh"
source "$DOD_MODULES_DIR/80-file-size-caps.sh"
# AFTER 80 AND NEVER BEFORE IT: [80c] compares against the sets 80 measured, so it
# reads what enforcement actually used rather than re-scanning and risking a second,
# different answer. It reds by name if that producer did not run.
source "$DOD_MODULES_DIR/801-cap-enforcer-agreement.sh"
source "$DOD_MODULES_DIR/81-no-claude-attribution.sh"
source "$DOD_MODULES_DIR/82-throughput-and-routing.sh"
source "$DOD_MODULES_DIR/83-testing-stage-shape.sh"
source "$DOD_MODULES_DIR/84-no-pipe-into-grep-q.sh"
source "$DOD_MODULES_DIR/85-design-spec-conformance.sh"
source "$DOD_MODULES_DIR/86-skill-command-namespace.sh"
source "$DOD_MODULES_DIR/87-agent-roster-rows.sh"
source "$DOD_MODULES_DIR/88-plugin-map.sh"
source "$DOD_MODULES_DIR/89-reviewer-rename.sh"
source "$DOD_MODULES_DIR/90-collisions.sh"
source "$DOD_MODULES_DIR/91-claim-resolvers.sh"
source "$DOD_MODULES_DIR/92-work-doc-structure.sh"
source "$DOD_MODULES_DIR/93-token-declarations.sh"
source "$DOD_MODULES_DIR/94-section-exists.sh"
source "$DOD_MODULES_DIR/95-literal-absent-claims.sh"
source "$DOD_MODULES_DIR/96-review-scope-sites.sh"
source "$DOD_MODULES_DIR/97-test-suites-reachable.sh"
source "$DOD_MODULES_DIR/98-work-doc-ledger-sync.sh"
source "$DOD_MODULES_DIR/99-work-doc-status-claims.sh"

# ---------------------------------------------------------------------------
# [0b] FLOOR ON THE RUN'S OWN SIZE. [0] above catches a fragment that stops being
# sourced. It cannot catch a fragment that is still sourced while its contents
# stop checking anything: an early return, a deleted block, a loop over a set
# that went empty. This repo has catalogued twelve separate instances of a check
# that passes while measuring nothing, and the one property all twelve share is
# that the run got quietly smaller.
#
# DELIBERATELY A FLOOR, NOT AN EQUALITY. Every wave adds checks, so an exact
# count would redden on every commit and be bumped without being read, which is
# how a bound becomes noise. A floor only moves when the run SHRINKS, which is
# the only direction that hides a loss. Lowering it is allowed and must carry a
# stated reason in the same commit, the way a retired fragment does.
#
# Complementary to [0] and weaker on purpose: dropping 90-collisions.sh costs one
# ok line and sails over this floor, which is why [0] does the per-fragment work.
# What this catches instead is the wholesale gutting [0] is blind to.
#
# THE NUMBER IS THE SHELL-SIDE TOTAL, and it sits below a `grep -c` over the
# transcript, because [57] and [85] delegate to Python checkers that print their
# own ok lines without passing through green(). See the comment above
# DOD_OK_COUNT in 00-helpers.sh for why that gap is safe to leave.
#
# THE GAP IS PER INVOCATION, NOT PER CHECKER, and reading it the other way is
# what has had this number quoted wrong three times. Two checkers print three
# delegated ok lines: [57] runs scripts/check_doc_links.py TWICE, once over the
# source tree and once over dist/claude-code, and [85] runs
# scripts/check_design_specs.py once. It is not a constant either. dist/ is
# gitignored, so on a tree that has never run scripts/sync-runtimes.sh [57]
# prints `skip` for the second invocation and the gap is 2.
#
# The floor is set against THIS counter, so compare like with like before moving
# it. THE GAP, NOT THE TOTAL, IS THE DURABLE FACT: the transcript reads 3 higher
# on a built tree and 2 with dist/ absent, because the gap counts delegated
# INVOCATIONS rather than delegated checkers ([57] runs the doc-link checker
# twice, once over the source tree and once over dist/claude-code).
#
# No absolute total is written here any more, and that is the fix rather than an
# omission. This line has carried a wrong number in six different versions, every
# one of them quoted from somewhere else instead of counted, and each correction
# went stale on the next wave that added a check. The floor below is a floor so
# that ordinary growth never needs an edit here. When you genuinely need the two
# halves, take BOTH from one run of your own rather than adjusting one of
# them against the other. Every wrong version of this line so far was quoted from
# whoever wrote it last.
#
# IT PRINTS ITS OWN ID, like every other check and for the same reason. [0] does
# it at line start above; this block did not, so `[0b]` was enumerated in the
# manifest, labelled in this comment, and then absent from every line the run
# emitted. A reader grepping a transcript for the id that the manifest told them
# to expect found nothing and had no way to tell a check that passed from one
# that never ran. printf rather than yellow(), on [0]'s reasoning: this is the
# one file whose checks must still speak when 00-helpers.sh is not loaded.
printf '\033[33m%s\033[0m\n' "[0b] the run's own ok-line total is at or above its floor"
DOD_OK_FLOOR=1350
if [ "${DOD_OK_COUNT:-0}" -lt "$DOD_OK_FLOOR" ]; then
  printf '\033[31m%s\033[0m\n' "  FAIL [0b] this run printed only ${DOD_OK_COUNT:-0} ok lines against a floor of $DOD_OK_FLOOR; checks did not fail, they stopped running, so find what went quiet before trusting this verdict"
  FAILED=$((FAILED + 1))
else
  printf '\033[33m%s\033[0m\n' "  note [0b] $DOD_OK_COUNT ok lines counted through the shell printers, at or above the floor of $DOD_OK_FLOOR (the transcript carries more from the delegated Python checkers, 3 on a built tree and 2 where dist/ has never been synced)"
fi

if [ "$FAILED" -eq 0 ]; then
  green "ALL CHECKS PASSED"
  exit 0
else
  red "$FAILED CHECK(S) FAILED"
  exit 1
fi

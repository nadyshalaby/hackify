#!/usr/bin/env python3
"""Regenerate the agent files that mirror a parallel-agents template block.

EVERY agent definition in agents/ promises byte-for-byte identity with the
fenced prompt block of a canonical template, and check [75h] in
scripts/validate-dod.sh enforces that promise. Editing one side by hand and
forgetting the other is a build break, so this script copies canonical ->
mirror for every pair. As of v0.13.0 there are no exceptions left: the list
below and the contents of agents/ are the same ten things.

Getting to zero exceptions took splitting one file. phase-5-multi-review.md
used to carry Reviewers A, B and C in three fenced blocks, and this script
splits on the FIRST block, so neither A nor C could ever be enforced against
it. v0.13.0 folded C into B and moved A into its own
phase-5-multi-review-a-security.md, which left every canonical file with
exactly one prompt in it.

Both of those long-unenforced pairs had drifted, in both directions, which is
the argument for the check rather than against it:

  - Reviewer A's agent copy held two instructions its template never got (skip
    the Execution waves block when reading Approach, and the {{...}} vs <...>
    placeholder explainer). Its template held a broader phrasing of two ROLE
    clauses. Neither side was uniformly newer, so the merge took the union by
    hand instead of letting this script pick a winner.
  - Reviewer C's agent copy had gained the Execution-waves clause and LOST the
    goal-anchor pointer sentence its template still carried. Same treatment.

The earlier lesson still stands and is worth keeping: code-reviewer-quality's
agent copy had drifted BEHIND its template, having lost the step that loads
rules/code-quality.md, so that reviewer was auditing without the doctrine file
SKILL.md says it loads. It LOOKED like the newer side because its file was
longer, but the extra length was hard-wrapping plus three suppression-grep
steps the template had consolidated into one pointer step. Size never settles
drift direction; reading both sides does.

THE TAIL IS THE OTHER HALF, AND IT IS HAND-MAINTAINED ON BOTH SIDES. The block
above is copied; everything after it is not. So an OUTPUT skeleton could drift on
both sides while --check reported nine of nine and exited 0, and check [75h]
asserted byte-identity over the same block and inherited the same blind spot. A
reviewer found it when a planted regression printed a false green.

FULL EQUALITY IS THE WRONG FIX, AND THE REASON IS MEASURABLE. Five of the ten
template tails carry MORE than their mirror BY DESIGN: a dispatcher's round
procedure, a reference file's `## See also`, panel-roster prose a reviewer never
reads. Requiring equality reds on a healthy tree. A bare prefix test is worse:
four of those five mirrors carry a tail of ZERO lines, and the empty tail is a
prefix of every tail there is, so a mirror that had lost its whole tail would
pass. A template therefore marks the point where its mirrored region ENDS:

    <!-- parent-side: not mirrored -->

The mirror's tail must equal the template's tail up to that line and must STOP
there. A template carrying no marker mirrors its whole tail. The tail is never
copied, in either mode, because both sides are written by hand: this script
reports the disagreement and a person carries the text across.

THE MARKER'S POSITION IS PINNED TOO, and it has to be, because a comparison
between two editable files cannot see a coordinated move. Slide the marker up to
the first line of a template's tail and truncate the mirror to meet it, and the
two sides agree again with the whole mirrored region gone. What pins it is the
split above: the block ends at the SECOND bare fence, which on the
implementer pair is the VERIFICATION script's closing fence, in the MIDDLE
of the prompt. So the prompt's own closing fence sits in the tail, and a marker
above it would cut the prompt in half and let a mirror drop the OUTPUT skeleton
with this check still reporting a match. The rule: no bare fence may sit below
the marker. It constrains exactly one pair today and is silent on the other
nine rather than printing a verdict it did not reach, and a parent-side region
that ever needs a fenced example must open it with four backticks.

WHAT THE HEAD IS NOT, measured before it was left out. No mirror head is a prefix
of its template head, on any of the ten: a mirror opens with YAML frontmatter, a
template with an H1 title. They are different documents rather than drifted
copies, so there is no mirrored region for a marker to bound and the rule above
cannot be stated for the head at all.

TWO THINGS LIVE IN THE HEAD ANYWAY, and neither is this script's to compare, so
both are written down here instead of being rediscovered a third time.

  - DUPLICATED PROSE, on one pair. The implementer pair states the same
    dispatch rule in BOTH heads, 1230 characters against 1276 and already
    divergent when that was measured on the wave template this pair grew out of. Check [75h] now pins that rule clause by
    clause over both heads, scoped to the head so the fenced block cannot satisfy
    a clause deleted from the prose above it. Clause-level rather than byte-level
    on purpose: the two copies differ in exactly two pointer spans, one naming the
    runtime agent type and one linking a sibling file, written for different
    readers.

  - THE `description:` FIELD, on all ten, and this gap is DELIBERATE rather than
    unnoticed. It is the text the runtime dispatcher matches on, so it is
    load-bearing prose, and nothing compares it to anything. The exposure is real
    and was measured: rewriting the gating clause in the security reviewer's
    description, from "Gated on the diff touching auth ... folds into Reviewer B
    when it does not" to the opposite, leaves both the validator and --check at
    rc 0. No check is added HERE because a description has no second copy to
    compare against, the template side carrying no frontmatter at all. It is a
    single-copy ROUTING surface, which is the thing [38d] in
    scripts/validate-dod.d/71-release-mechanism-pins.sh already pins phrase by
    phrase for the eight skill descriptions. The ten agent descriptions belong in
    that block, beside the skills, and not in a mirror contract that has no second
    copy to hold them against.

    python3 scripts/sync_agent_mirrors.py                # rewrite drifted mirrors
    python3 scripts/sync_agent_mirrors.py --check        # report drift, change nothing
    python3 scripts/sync_agent_mirrors.py --check-tails  # report tail drift alone
    python3 scripts/sync_agent_mirrors.py --list         # emit "mirror|canonical" pairs

--list exists so the validator reads the pair set from here instead of keeping
its own copy. One list, one place. --check-tails exists for the same reason
pointed at the tail: check [75h] reads its verdict instead of growing a second
comparison in shell.

A PAIR WITH NOTHING TO COMPARE NO LONGER PRINTS A PASSED COMPARISON. Measured
over the list below, NINE of the ten templates owe their mirror an EMPTY tail
region, five because neither side carries a tail and four because the marker
sits on the tail's first line, so "ok ... tail matches" was one real comparison
wearing ten pass lines. Those pairs now print `none` and say what was actually
asserted, which is only that the mirror carries no tail of its own, and the run
ends on a summary counting the two kinds apart. A caller wanting a green can
then quote a number instead of inheriting a claim.

EVERY MODE EXITS NON-ZERO ON A TAIL IT CANNOT FIX, WRITE MODE INCLUDED, which is
a change from a version that always exited 0 when it wrote. The sync cannot fix a
tail, so "the blocks are synced and the tail still needs a hand" is the honest
status, and a caller chaining this under && now stops there rather than reporting
a clean run. TAIL DRIFT IS NOT THE ONLY CASE, and the earlier wording said it was:
check_one returns a problem for a MISSING side and for a misplaced marker as well,
in every mode, so write mode reds on all three. Two of the three are things a
resync could never repair either, which is the same argument, not an exception.

AN UNRECOGNISED ARGUMENT REFUSES. Write mode is the no-flag case, so `--chekc`
used to resync all nine mirrors and exit 0 while the operator read the word
check. This script now runs from the validator, where that would be a validator
editing the tree it audits.
"""

import os
import sys

PA = "skills/hackify/references/parallel-agents"

MIRROR_PAIRS = (
    ("agents/codebase-investigator.md", f"{PA}/investigation.md"),
    ("agents/spec-reviewer.md", f"{PA}/phase-2.5-spec-reviewer.md"),
    ("agents/implementer.md", f"{PA}/phase-3-implementation.md"),
    ("agents/reviewer-security.md", f"{PA}/phase-5-multi-review-a-security.md"),
    ("agents/reviewer-quality-plan.md", f"{PA}/phase-5-multi-review-b-quality-plan.md"),
    ("agents/reviewer-performance.md", f"{PA}/phase-5-multi-review-d-performance.md"),
    ("agents/reviewer-design.md", f"{PA}/phase-5-multi-review-e-design.md"),
    ("agents/reviewer-coherence.md", f"{PA}/phase-5-multi-review-f-coherence.md"),
    ("agents/finding-refuter.md", f"{PA}/phase-5-refute.md"),
    ("agents/reviewer.md", f"{PA}/phase-5-multi-review-merged.md"),
)

FENCE = "```"

# The line a template puts where its mirrored region ends. An HTML comment, so it
# is invisible in every renderer and inert to every other check, which is the
# whole reason this marker is spelled the way it is rather than as prose.
TAIL_MARKER = "<!-- parent-side: not mirrored -->"

KNOWN_FLAGS = ("--check", "--check-tails", "--list")

USAGE = (
    "usage: sync_agent_mirrors.py [--check | --check-tails | --list]\n"
    "  (no flag)      rewrite drifted mirror blocks\n"
    "  --check        report block and tail drift, change nothing\n"
    "  --check-tails  report tail drift alone, change nothing\n"
    "  --list         emit \"mirror|canonical\" pairs"
)


def split_on_fence(path):
    """Return (head, fenced_block, tail) around the file's first ``` ... ``` block.

    The outer fence is a line of exactly three backticks. OUTPUT report
    skeletons nested inside use four, so they never terminate the block. This
    matches the validator's extraction exactly.
    """
    lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
    bounds = [i for i, line in enumerate(lines) if line.rstrip("\n") == FENCE]
    if len(bounds) < 2:
        raise ValueError(f"{path} has no complete ``` fenced block")
    start, end = bounds[0], bounds[1]
    return lines[:start], lines[start : end + 1], lines[end + 1 :]


def sync_pair(mirror, canonical, check_only):
    """Copy the canonical fenced block into the mirror. Return True if it differed."""
    _, canonical_block, _ = split_on_fence(canonical)
    head, mirror_block, tail = split_on_fence(mirror)
    if mirror_block == canonical_block:
        return False
    if not check_only:
        with open(mirror, "w", encoding="utf-8") as handle:
            handle.writelines(head + canonical_block + tail)
    return True


def marker_index(canonical_tail):
    """0-based index of the parent-side marker in a template tail, or None."""
    for index, line in enumerate(canonical_tail):
        if line.strip() == TAIL_MARKER:
            return index
    return None


def mirrored_tail(canonical_tail):
    """The slice of a template's tail its mirror is required to carry.

    Everything from the marker line down is parent-side and stops being the
    mirror's business. No marker means the whole tail is mirrored.
    """
    index = marker_index(canonical_tail)
    return canonical_tail if index is None else canonical_tail[:index]


def marker_misplaced(canonical_tail):
    """One line saying the marker cuts the prompt in half, or None when it does not.

    THE ONE THING A CROSS-FILE COMPARISON CANNOT SEE is both files moving
    together, and this is that move: the marker slides up, the mirror truncates
    to meet it, and the tails agree with the mirrored region deleted. Re-measured
    on a copy of HEAD, that plant takes the whole of agents/implementer.md's tail
    out of it, and with this rule blinded --check-tails reports every pair owing an
    empty tail and exits 0.

    THE LINE COUNT USED TO BE WRITTEN OUT HERE AND USED TO BE WRONG, recorded
    rather than quietly corrected. It said 80, which was the tail length at the
    base commit and was already stale in the commit that wrote it; the tail
    measured 89 there. It is not restated now, because a tail length written into
    a comment goes stale the first time a wave edits the prompt above it. Beside
    it, "printed nine pass lines" predated the `none` verdict below. The rule is
    argued in the module docstring under THE MARKER'S POSITION IS PINNED TOO.
    """
    index = marker_index(canonical_tail)
    if index is None:
        return None
    below = [i for i, line in enumerate(canonical_tail[index + 1:], index + 1)
             if line.rstrip("\n") == FENCE]
    if not below:
        return None
    return (f"parent-side marker misplaced: it sits at tail line {index + 1}, "
            f"above the fence at tail line {below[0] + 1} that closes the "
            "prompt, so it cuts the prompt in half and stops requiring the "
            "mirror to carry the rest of it")


def first_difference(left, right):
    """1-based index of the first line that differs, or one past the shorter."""
    for index, (one, other) in enumerate(zip(left, right)):
        if one != other:
            return index + 1
    return min(len(left), len(right)) + 1


def tail_drift(mirror, canonical):
    """One line saying how the mirror's tail is wrong, or None when it is right."""
    _, _, canonical_tail = split_on_fence(canonical)
    _, _, mirror_tail = split_on_fence(mirror)
    expected = mirrored_tail(canonical_tail)
    if mirror_tail == expected:
        return None
    scope = ("the whole template tail (no parent-side marker)"
             if expected == canonical_tail
             else "the template tail above its parent-side marker")
    return (f"tail drifted: the mirror carries {len(mirror_tail)} tail line(s), "
            f"{scope} carries {len(expected)}; first difference at tail line "
            f"{first_difference(mirror_tail, expected)}")


def pair_ready(mirror, canonical):
    """True when both sides are on disk. Reports the failure itself when not."""
    if os.path.isfile(mirror) and os.path.isfile(canonical):
        return True
    print(f"  FAIL missing side: {mirror} <-> {canonical}")
    return False


def check_one(mirror, canonical, check_only):
    """Sync or check one pair, print its verdict, return True on a problem."""
    if not pair_ready(mirror, canonical):
        return True
    block_moved = sync_pair(mirror, canonical, check_only)
    if block_moved:
        verb = "drifted from" if check_only else "resynced from"
        print(f"  {'FAIL' if check_only else 'sync'} {mirror} {verb} {canonical}")
    misplaced = marker_misplaced(split_on_fence(canonical)[2])
    if misplaced is not None:
        print(f"  FAIL {canonical} {misplaced}")
        return True
    drift = tail_drift(mirror, canonical)
    if drift is not None:
        print(f"  FAIL {mirror} {drift}")
        return True
    if not block_moved:
        print(f"  ok   {mirror} matches {os.path.basename(canonical)}")
    return check_only and block_moved


def run(check_only):
    """Sync or check every pair. Return a process exit code."""
    drifted = sum(check_one(m, c, check_only) for m, c in MIRROR_PAIRS)
    if drifted:
        print(f"\n{drifted} mirror(s) drifted. `python3 scripts/sync_agent_mirrors.py`"
              " fixes a block; a tail is hand-carried, this script never copies one.")
        return 1
    return 0


def tail_verdict(mirror, canonical):
    """One (line, ok) verdict for one pair, saying what was actually compared."""
    canonical_tail = split_on_fence(canonical)[2]
    misplaced = marker_misplaced(canonical_tail)
    if misplaced is not None:
        return f"  FAIL {canonical} {misplaced}", False
    drift = tail_drift(mirror, canonical)
    if drift is not None:
        return f"  FAIL {mirror} {drift}", False
    expected = mirrored_tail(canonical_tail)
    name = os.path.basename(canonical)
    if expected:
        return (f"  ok   {mirror} tail matches all {len(expected)} mirrored "
                f"line(s) of {name}"), True
    return (f"  none {mirror} has no mirrored tail region to compare; {name} "
            "owes it an empty tail and it carries one"), True


def run_tails():
    """Check the hand-maintained tails alone. Return a process exit code.

    Check [75h] reads this, so the comparison lives here once instead of a
    second time in shell. It reads the SUMMARY line too, which is why the two
    kinds of pass are counted apart rather than added up: see the module
    docstring under A PAIR WITH NOTHING TO COMPARE.
    """
    drifted = compared = empty = 0
    for mirror, canonical in MIRROR_PAIRS:
        if not pair_ready(mirror, canonical):
            drifted += 1
            continue
        line, ok = tail_verdict(mirror, canonical)
        print(line)
        if not ok:
            drifted += 1
        elif line.startswith("  ok"):
            compared += 1
        else:
            empty += 1
    print(f"  {compared} pair(s) compared a non-empty mirrored tail, {empty} "
          f"asserted an empty one, {drifted} failed")
    return 1 if drifted else 0


def main(argv):
    """Route the run. An unrecognised argument REFUSES rather than falling through.

    Write mode is the no-flag case, so a typo used to be indistinguishable from
    it. See the last paragraph of the module docstring.
    """
    unknown = [arg for arg in argv if arg not in KNOWN_FLAGS]
    if unknown:
        print(f"refusing: unrecognised argument(s) {' '.join(unknown)}")
        print(USAGE)
        return 2
    if "--list" in argv:
        for mirror, canonical in MIRROR_PAIRS:
            print(f"{mirror}|{canonical}")
        return 0
    if "--check-tails" in argv:
        return run_tails()
    return run(check_only="--check" in argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

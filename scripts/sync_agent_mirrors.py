#!/usr/bin/env python3
"""Regenerate the agent files that mirror a parallel-agents template block.

Four agent definitions promise byte-for-byte identity with the fenced prompt
block of a canonical template, and check [75h] in scripts/validate-dod.sh
enforces that promise. Editing one side by hand and forgetting the other is a
build break, so this script copies canonical -> mirror for every pair.

    python3 scripts/sync_agent_mirrors.py           # rewrite drifted mirrors
    python3 scripts/sync_agent_mirrors.py --check   # report drift, change nothing
    python3 scripts/sync_agent_mirrors.py --list    # emit "mirror|canonical" pairs

--list exists so the validator reads the pair set from here instead of keeping
its own copy. One list, one place.
"""

import os
import sys

PA = "skills/hackify/references/parallel-agents"

MIRROR_PAIRS = (
    ("agents/code-reviewer-performance.md", f"{PA}/phase-5-multi-review-d-performance.md"),
    ("agents/design-conformance-reviewer.md", f"{PA}/phase-5-multi-review-e-design.md"),
    ("agents/code-reviewer-coherence.md", f"{PA}/phase-5-multi-review-f-coherence.md"),
    ("agents/finding-refuter.md", f"{PA}/phase-5-refute.md"),
)

FENCE = "```"


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


def run(check_only):
    """Sync or check every pair. Return a process exit code."""
    drifted = 0
    for mirror, canonical in MIRROR_PAIRS:
        if not os.path.isfile(mirror) or not os.path.isfile(canonical):
            print(f"  FAIL missing side: {mirror} <-> {canonical}")
            drifted += 1
            continue
        if sync_pair(mirror, canonical, check_only):
            drifted += 1
            verb = "drifted from" if check_only else "resynced from"
            print(f"  {'FAIL' if check_only else 'sync'} {mirror} {verb} {canonical}")
        else:
            print(f"  ok   {mirror} matches {os.path.basename(canonical)}")
    if check_only and drifted:
        print(f"\n{drifted} mirror(s) drifted. Run: python3 scripts/sync_agent_mirrors.py")
        return 1
    return 0


def main(argv):
    if "--list" in argv:
        for mirror, canonical in MIRROR_PAIRS:
            print(f"{mirror}|{canonical}")
        return 0
    return run(check_only="--check" in argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

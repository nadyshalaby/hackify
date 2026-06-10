#!/usr/bin/env python3
"""Score a semantic-pass run against the corpus EXPECT-SEMANTIC oracle.

The judgment tier (DRY, layering, security beyond secrets, ...) is found by
subagents, not the deterministic scanner, so it is scored on demand: dispatch the
semantic concerns over project/ (see semantic-runner.md), collect their findings
into one JSON file in the shared shape, then run this. Matching is by
(file basename, rule_id) — a subagent reliably names the file and rule, but not
the exact line, so exact-line matching would be misleadingly strict.

Usage: python3 score_semantic.py <findings.json>
Exit 0 always — this reports a recall measurement, it does not gate (the semantic
pass is non-deterministic; one run is illustrative, not a threshold).
"""
import json
import os
import sys

from run_corpus import collect_markers


def _oracle():
    """Unique (basename, rule_id) pairs the semantic pass is expected to find."""
    _deterministic, semantic = collect_markers()
    return {(os.path.basename(rel), rule) for rel, _line, rule in semantic}


def _load_findings(path):
    with open(path, encoding='utf-8') as handle:
        data = json.load(handle)
    items = data['findings'] if isinstance(data, dict) else data
    return {(os.path.basename(f['file']), f['rule_id']) for f in items}


def main(argv):
    if len(argv) < 1:
        print('usage: score_semantic.py <findings.json>')
        return 2
    oracle = _oracle()
    found = _load_findings(argv[0])
    hit = oracle & found
    print(f'semantic recall: {len(hit)}/{len(oracle)} (file, rule) pairs found')
    for pair in sorted(oracle):
        print(f'  {"ok  " if pair in found else "MISS"} {pair[0]}: {pair[1]}')
    for pair in sorted(found - oracle):
        print(f'  EXTRA {pair[0]}: {pair[1]} (not in oracle — confirm before trusting)')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

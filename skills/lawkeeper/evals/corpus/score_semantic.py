#!/usr/bin/env python3
"""Score a semantic-pass run against the corpus EXPECT-SEMANTIC oracle.

The judgment tier (DRY, layering, security beyond secrets, ...) is found by
subagents, not the deterministic scanner, so it is scored on demand: dispatch the
semantic concerns over project/ (see semantic-runner.md), collect their findings
into one JSON file in the shared shape, then run this. Matching is by
(file basename, rule_id) — a subagent reliably names the file and rule, but not
the exact line, so exact-line matching would be misleadingly strict.

Pass ONE findings file for a single illustrative run, or SEVERAL (one per round)
for a variance-aware number — each oracle pair reports a hit-rate (e.g. 2/3 runs).

Usage: python3 score_semantic.py <findings.json> [findings2.json ...]
Exit 0 always — this reports a recall measurement, it does not gate (the semantic
pass is non-deterministic; treat a single run as illustrative, not a threshold).
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


def _mark(hits, total):
    if hits == total:
        return 'ok  '
    return 'part' if hits else 'MISS'


def main(argv):
    if len(argv) < 1:
        print('usage: score_semantic.py <findings.json> [findings2.json ...]')
        return 2
    oracle = _oracle()
    runs = [_load_findings(path) for path in argv]
    n = len(runs)
    print(f'semantic recall over {n} run(s), {len(oracle)} oracle (file, rule) pairs:')
    pair_runs_hit = 0
    for pair in sorted(oracle):
        hits = sum(1 for run in runs if pair in run)
        pair_runs_hit += hits
        print(f'  {_mark(hits, n)} {pair[0]}: {pair[1]} — {hits}/{n}')
    denom = len(oracle) * n
    print(f'mean recall: {pair_runs_hit}/{denom} pair-runs ({100 * pair_runs_hit // denom}%)')
    for pair in sorted(set().union(*runs) - oracle):
        seen = sum(1 for run in runs if pair in run)
        print(f'  EXTRA {pair[0]}: {pair[1]} — {seen}/{n} (not in oracle; confirm before trusting)')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

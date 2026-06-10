#!/usr/bin/env python3
"""Score the lawkeeper deterministic scanner against the recall corpus.

`project/` is a synthetic codebase whose every planted violation carries an
inline EXPECT-marker naming the rule_id it must trigger. This script turns the
markers into an oracle, runs `audit_scan.py` over the project, and asserts the
scanner's findings match the oracle EXACTLY — every `EXPECT:` line caught
(recall) and nothing extra (precision; `EXPECT-CLEAN:` carve-out lines must stay
silent, which exact-match enforces for free).

`EXPECT-SEMANTIC:` markers name the judgment-tier oracle; they are written to
ground-truth.json for the on-demand semantic runner and are NOT scored here
(scoring them needs a model — see semantic-runner.md).

Exit 0 on exact match, 1 on any miss/extra. Run: `python3 run_corpus.py [--emit]`.
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.join(HERE, 'project')
SCANNER = os.path.normpath(os.path.join(HERE, '..', '..', 'scripts', 'audit_scan.py'))
RULE = r'[a-z]+\.[a-z][a-z0-9-]*'
EXPECT_RE = re.compile(r'EXPECT:\s*(' + RULE + r')')
SEMANTIC_RE = re.compile(r'EXPECT-SEMANTIC:\s*(' + RULE + r')')


def _iter_fixture_lines():
    """Yield (rel_path, line_no, text) for every line of every fixture file."""
    for root, _dirs, files in os.walk(PROJECT):
        for name in sorted(files):
            abs_path = os.path.join(root, name)
            rel = os.path.relpath(abs_path, PROJECT).replace(os.sep, '/')
            with open(abs_path, encoding='utf-8', errors='replace') as handle:
                for num, text in enumerate(handle.read().split('\n'), 1):
                    yield rel, num, text


def collect_markers():
    """(expected, semantic) sets keyed (file, line, rule_id) parsed from EXPECT markers."""
    expected, semantic = set(), set()
    for rel, num, text in _iter_fixture_lines():
        for rule in EXPECT_RE.findall(text):
            expected.add((rel, num, rule))
        for rule in SEMANTIC_RE.findall(text):
            semantic.add((rel, num, rule))
    return expected, semantic


def run_scanner():
    """(file, line, rule_id) set of deterministic findings from audit_scan.py."""
    proc = subprocess.run([sys.executable, SCANNER, PROJECT],
                          capture_output=True, text=True, check=True)
    report = json.loads(proc.stdout)
    return {(f['file'], f['line'], f['rule_id']) for f in report['findings']}


def per_rule_report(expected, actual):
    """Print a per-rule recall/precision line; return (missed, extra) sets."""
    for rule in sorted({r for _f, _l, r in expected | actual}):
        exp = {t for t in expected if t[2] == rule}
        act = {t for t in actual if t[2] == rule}
        extra = len(act - exp)
        status = 'ok  ' if exp <= act and not extra else 'FAIL'
        tail = f', {extra} false-positive' if extra else ''
        print(f'  {status} {rule}: {len(exp & act)}/{len(exp)} caught{tail}')
    return expected - actual, actual - expected


GROUND_TRUTH = os.path.join(HERE, 'ground-truth.json')


def _payload(expected, semantic):
    return {'deterministic': sorted(list(t) for t in expected),
            'semantic': sorted(list(t) for t in semantic)}


def emit_ground_truth(expected, semantic):
    with open(GROUND_TRUTH, 'w', encoding='utf-8') as handle:
        json.dump(_payload(expected, semantic), handle, indent=2)
        handle.write('\n')
    return os.path.relpath(GROUND_TRUTH, HERE)


def ground_truth_fresh(expected, semantic):
    """True when the committed ground-truth.json matches the current markers."""
    try:
        with open(GROUND_TRUTH, encoding='utf-8') as handle:
            return json.load(handle) == _payload(expected, semantic)
    except (OSError, ValueError):
        return False


def main(argv):
    expected, semantic = collect_markers()
    actual = run_scanner()
    print(f'corpus: {len(expected)} deterministic markers, {len(semantic)} semantic markers, '
          f'{len(actual)} scanner findings')
    missed, extra = per_rule_report(expected, actual)
    failed = bool(missed or extra)
    if '--emit' in argv:
        print(f'wrote {emit_ground_truth(expected, semantic)}')
    elif not ground_truth_fresh(expected, semantic):
        print('  FAIL ground-truth.json is stale — regenerate with: python3 run_corpus.py --emit')
        failed = True
    for tag, items in (('MISSED', missed), ('EXTRA', extra)):
        for rel, line, rule in sorted(items):
            print(f'  {tag} {rel}:{line} {rule}')
    if failed:
        return 1
    print('PASS: scanner findings match the corpus oracle exactly')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

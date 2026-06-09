#!/usr/bin/env python3
"""Detect hackify-banned tokens introduced by one edit's candidate text.

Single source of truth: reuses lawkeeper's tested lexer + check regexes rather
than reimplementing them. Suppressions are matched on RAW text (they live in
comments by design); semantic bans (non-null `!`, empty catch, bare `Error`)
are matched on lexer-MASKED text so a token inside a string or comment never
false-fires.

Net-new only: a finding whose offending line already exists verbatim in the
baseline (the file's prior contents for a Write, or `old_string` for an Edit)
is grandfathered — the hook blocks tokens you INTRODUCE, not ones you merely
carry past on an untouched line.

`load_detectors` and `detect` are the public API reused by scan_bash.py.

Usage: `scan_edit.py <lawkeeper-scripts-dir> [baseline-file]` with candidate
text on stdin. Prints one `<rule>\\t<line>` per net-new finding. Exit 0 always
— this is a detector; the calling hook decides whether to block.
"""
import sys

SUPPRESSIONS = (
    ('suppression.eslint', 'eslint-disable'),
    ('suppression.biome', 'biome-ignore'),
    ('suppression.ts-ignore', '@ts-ignore'),
    ('suppression.ts-nocheck', '@ts-nocheck'),
    ('suppression.ts-expect-error', '@ts-expect-error'),
)


def load_detectors(scripts_dir):
    """Return (mask_source, semantic-rules) from lawkeeper's scripts dir."""
    sys.path.insert(0, scripts_dir)
    from lexer import mask_source
    from checks import EMPTY_CATCH_RE, BARE_ERROR_RE, NON_NULL_RE
    semantic = (
        ('ban.empty-catch', EMPTY_CATCH_RE),
        ('ban.bare-error', BARE_ERROR_RE),
        ('ban.non-null', NON_NULL_RE),
    )
    return mask_source, semantic


def _scan_suppressions(raw_lines):
    out = []
    for num, line in enumerate(raw_lines, 1):
        for rule, token in SUPPRESSIONS:
            if token in line:
                out.append((rule, num))
    return out


def _scan_semantic(masked_lines, semantic):
    out = []
    for num, line in enumerate(masked_lines, 1):
        for rule, regex in semantic:
            if regex.search(line):
                out.append((rule, num))
    return out


def detect(text, mask_source, semantic):
    """All (rule, line) findings in `text` — suppressions raw, semantic masked."""
    return _scan_suppressions(text.splitlines()) + _scan_semantic(mask_source(text), semantic)


def _baseline_lines(baseline_path):
    if not baseline_path:
        return None
    try:
        with open(baseline_path, encoding='utf-8', errors='replace') as handle:
            return set(handle.read().splitlines())
    except OSError:
        return None


def _net_new(findings, raw_lines, baseline):
    if baseline is None:
        return findings
    return [(rule, num) for rule, num in findings if raw_lines[num - 1] not in baseline]


def main():
    if len(sys.argv) < 2:
        return 0
    text = sys.stdin.read()
    baseline_path = sys.argv[2] if len(sys.argv) > 2 else ''
    try:
        mask_source, semantic = load_detectors(sys.argv[1])
    except Exception:
        return 0  # lexer/checks unavailable -> detect nothing (fail open)
    findings = _net_new(detect(text, mask_source, semantic), text.splitlines(), _baseline_lines(baseline_path))
    for rule, num in findings:
        print(f'{rule}\t{num}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""Detect hackify-banned tokens introduced by one edit's candidate text.

Single source of truth: reuses lawkeeper's tested lexer + check regexes (and
FileContext.check_secrets) rather than reimplementing them. Suppressions and
hardcoded secrets are matched on RAW text (they live in comments / string
literals by design); semantic bans (non-null `!`, empty catch, bare `Error`)
are matched on lexer-MASKED text so a token inside a string or comment never
false-fires.

Net-new only: a finding whose offending line already exists verbatim in the
baseline (the file's prior contents for a Write, or `old_string` for an Edit)
is grandfathered, the hook blocks tokens you INTRODUCE, not ones you merely
carry past on an untouched line.

Two lenses. `detect` is the full set above, for JS/TS source. `detect_secrets`
is the hardcoded-secret half alone, for PROSE files, and the reasoning for the
split is on that function.

`load_detectors`, `detect` and `detect_secrets` are the public API reused by
scan_bash.py; `load_detectors` returns a Detectors bundle.

Usage: `scan_edit.py <lawkeeper-scripts-dir> [baseline-file] [--all-rules |
--secrets-only]` with candidate text on stdin. The lens flag is optional and
order-independent, the default is `--all-rules`; any `--` argument is filtered
out of the positionals, so a caller may always pass one rather than building an
empty shell array, which bash 3.2 cannot expand under `set -u`. Prints one
`<rule>\\t<line>` per net-new finding. Exit 0 always
, this is a detector; the calling hook decides whether to block. ANY internal
failure (detectors unavailable, undecodable stdin, a detector bug) exits 0
with no findings: fail open, a hook bug must never wedge editing.
"""
import sys
from collections import namedtuple

# The three lawkeeper detector pieces a scan needs, bundled so detect() stays
# within the argument cap and scan_bash can pass it through unchanged.
Detectors = namedtuple('Detectors', ('mask_source', 'semantic', 'file_context'))

SUPPRESSIONS = (
    ('suppression.eslint', 'eslint-disable'),
    ('suppression.biome', 'biome-ignore'),
    ('suppression.ts-ignore', '@ts-ignore'),
    ('suppression.ts-nocheck', '@ts-nocheck'),
    ('suppression.ts-expect-error', '@ts-expect-error'),
)

SECRETS_ONLY_FLAG = '--secrets-only'


def load_detectors(scripts_dir):
    """Return a Detectors bundle (mask_source, semantic rules, FileContext) from
    lawkeeper's scripts dir, its tested lexer + checks are the single source of truth."""
    sys.path.insert(0, scripts_dir)
    from lexer import mask_source
    from checks import EMPTY_CATCH_RE, BARE_ERROR_RE, NON_NULL_RE, FileContext
    semantic = (
        ('ban.empty-catch', EMPTY_CATCH_RE),
        ('ban.bare-error', BARE_ERROR_RE),
        ('ban.non-null', NON_NULL_RE),
    )
    return Detectors(mask_source, semantic, FileContext)


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


def _scan_secrets(text, file_context):
    """Hardcoded-secret findings via FileContext.check_secrets so the provider
    patterns, the env-name carve-out, and redaction stay in one tested place. Only
    (rule, line) is returned, the secret value never leaves the scanner."""
    return [(f['rule_id'], f['line']) for f in file_context('<candidate>', text).check_secrets()]


def detect(text, detectors):
    """All (rule, line) findings in `text`: suppressions + secrets on RAW lines
    (they live in comments / string literals), semantic bans on lexer-MASKED lines."""
    return (_scan_suppressions(text.splitlines())
            + _scan_semantic(detectors.mask_source(text), detectors.semantic)
            + _scan_secrets(text, detectors.file_context))


def detect_secrets(text, detectors):
    """Hardcoded secrets alone, the lens for PROSE files such as markdown.

    A secret in a document is the same defect it is in source, and worse once
    that document is published as a page. The other two rule families are not,
    and both are dropped deliberately rather than for cheapness.

    Suppressions would report a document for DISCUSSING the ban. The tokens are
    spelled literally on purpose (rules/hard-caps.md: "These specific tokens
    stay literal because they ARE the strings linters and reviewers grep for"),
    so any doc that writes the rule down trips it. Measured over the 25 archived
    work-docs in this repo before this lens existed, the full set produced 26
    findings, every one of them a doc naming a suppression token while writing
    about the ban on it, and not one a secret. A screen that blocks a project
    from documenting its own rules is a screen somebody turns off.

    The semantic bans go for a second, independent reason: they read
    lexer-MASKED text, and the mask is a JS/TS lexer. Over prose it is not
    conservative, it is meaningless, so its verdict carries no information
    either way.
    """
    return _scan_secrets(text, detectors.file_context)


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


def _run():
    """Read candidate text from stdin, print one net-new finding per line."""
    # Any `--` argument is a lens flag, never a positional. Filtering by prefix
    # rather than by exact value lets a shell caller pass an explicit
    # `--all-rules` instead of an empty array, which bash 3.2 cannot expand
    # under `set -u`.
    args = [arg for arg in sys.argv[1:] if not arg.startswith('--')]
    if not args:
        return 0
    scan = detect_secrets if SECRETS_ONLY_FLAG in sys.argv else detect
    text = sys.stdin.read()
    baseline_path = args[1] if len(args) > 1 else ''
    detectors = load_detectors(args[0])
    findings = _net_new(scan(text, detectors), text.splitlines(), _baseline_lines(baseline_path))
    for rule, num in findings:
        print(f'{rule}\t{num}')
    return 0


def main():
    # Fail-open contract (module docstring: "Exit 0 always"): ANY internal
    # failure, detectors unavailable, undecodable stdin, a detector bug
    # must end in exit 0 with a finding-free stdout so a hook bug never
    # wedges editing. Exiting 0 with no findings IS the documented handling,
    # not a swallow. One stderr line names the error class so manual runs and
    # future callers can observe the failure (the calling hook currently
    # discards stderr).
    try:
        return _run()
    except Exception as exc:
        print(f'scan_edit: internal error, failing open: {type(exc).__name__}', file=sys.stderr)
        return 0


if __name__ == '__main__':
    sys.exit(main())

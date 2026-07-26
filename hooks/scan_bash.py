#!/usr/bin/env python3
"""Detect hackify-banned tokens in JS/TS source written by a Bash command.

The Write/Edit hook can't see source written through the shell (a `cat`
heredoc, an `echo`/`printf` redirect). This closes that bypass for the two
common patterns by extracting the written content and scanning it with the
SAME detector as scan_edit (lexer-masked semantic bans, raw suppressions and
hardcoded secrets).

Covered: a heredoc redirected to a JS/TS file, the redirect may sit on the
opening line (`cmd > file.ts <<TAG … TAG`) or after the body (`{ … } > f.ts`,
`( … ) > f.ts`, `while …; done > f.ts`; superset pairing, see
_heredoc_blocks), and `echo`/`printf` redirected to a JS/TS file. NOT
covered: content produced by `cp`/`mv`/`sed`/`awk` or any other program, not
statically knowable, so it falls through (fail-open). The hook documents this
scope.

Usage: `scan_bash.py <lawkeeper-scripts-dir>` with the command on stdin.
Prints one `<rule>\\t<target-path>` per finding. Exit 0 always. ANY internal
failure (detectors unavailable, undecodable stdin, a detector bug) exits 0
with no findings: fail open, a hook bug must never wedge editing.
"""
import re
import sys

JS_EXT = r'\.(?:ts|tsx|js|jsx|mjs|cjs|mts|cts)(?=[\s\'"<>|;&]|$)'
REDIR_TARGET = re.compile(r'(?:>>?|\btee\s+(?:-a\s+)?)\s*[\'"]?([^\s\'"<>|;&]+' + JS_EXT + r')')
HEREDOC = re.compile(r'<<-?\s*[\'"]?(\w+)[\'"]?\n(.*?)\n[ \t]*\1\b', re.DOTALL)
ECHO_REDIR = re.compile(
    r'\b(?:echo|printf)\b\s+(.*?)\s*>>?\s*[\'"]?([^\s\'"<>|;&]+' + JS_EXT + r')',
    re.DOTALL,
)


def _unquote(text):
    """Strip one matching wrapping shell-quote so echo's arg scans as JS, not
    as one big quoted string the lexer would mask away."""
    stripped = text.strip()
    if len(stripped) >= 2 and stripped[0] == stripped[-1] and stripped[0] in ('"', "'"):
        return stripped[1:-1]
    return stripped


def _heredoc_blocks(cmd):
    """(target, body) pairs under superset pairing: when the heredoc-body
    count equals the JS/TS redirect-target count, pair them positionally
    each `cmd > file.ts <<TAG` keeps per-heredoc attribution. On ANY
    mismatch (e.g. the redirect follows the body: `{ … } > f.ts`,
    `( … ) > f.ts`, `while …; done > f.ts`) every body is checked against
    EVERY candidate target, so no arrangement bypasses. Zero JS/TS targets
    means nothing is written to a JS/TS file, no pairs."""
    bodies = [heredoc.group(2) for heredoc in HEREDOC.finditer(cmd)]
    targets = [target.group(1) for target in REDIR_TARGET.finditer(cmd)]
    if len(bodies) == len(targets):
        return list(zip(targets, bodies))
    return [(target, body) for body in bodies for target in targets]


def _written_blocks(cmd):
    """(target, content) pairs we can statically extract from the command."""
    blocks = _heredoc_blocks(cmd)
    for echo in ECHO_REDIR.finditer(cmd):
        blocks.append((echo.group(2), _unquote(echo.group(1))))
    return blocks


def _run():
    """Read the command from stdin, print one finding per line."""
    import scan_edit  # sibling module, reuse the detector (single source of truth)
    if len(sys.argv) < 2:
        return 0
    cmd = sys.stdin.read()
    detectors = scan_edit.load_detectors(sys.argv[1])
    seen = set()
    for target, content in _written_blocks(cmd):
        for rule, _line in scan_edit.detect(content, detectors):
            key = (rule, target)
            if key not in seen:
                seen.add(key)
                print(f'{rule}\t{target}')
    return 0


def main():
    # Fail-open contract (module docstring: "Exit 0 always"): ANY internal
    # failure must end in exit 0 with a finding-free stdout, same wrapper as
    # scan_edit.main; exiting 0 with no findings IS the documented handling.
    # One stderr line names the error class so manual runs and future callers
    # can observe the failure (the calling hook currently discards stderr).
    try:
        return _run()
    except Exception as exc:
        print(f'scan_bash: internal error, failing open: {type(exc).__name__}', file=sys.stderr)
        return 0


if __name__ == '__main__':
    sys.exit(main())

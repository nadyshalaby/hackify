#!/usr/bin/env python3
"""Detect hackify-banned tokens in JS/TS source written by a Bash command.

The Write/Edit hook can't see source written through the shell (a `cat`
heredoc, an `echo`/`printf` redirect). This closes that bypass for the two
common patterns by extracting the written content and scanning it with the
SAME detector as scan_edit (lexer-masked semantic bans, raw suppressions).

Covered: a heredoc redirected to a JS/TS file (`cmd > file.ts <<TAG … TAG`)
and `echo`/`printf` redirected to a JS/TS file. NOT covered: content produced
by `cp`/`mv`/`sed`/`awk` or any other program — not statically knowable, so it
falls through (fail-open). The hook documents this scope.

Usage: `scan_bash.py <lawkeeper-scripts-dir>` with the command on stdin.
Prints one `<rule>\\t<target-path>` per finding. Exit 0 always.
"""
import re
import sys

import scan_edit  # sibling module — reuse the detector (single source of truth)

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


def _written_blocks(cmd):
    """(target, content) pairs we can statically extract from the command."""
    blocks = []
    targets = REDIR_TARGET.findall(cmd)
    if targets:
        for body in HEREDOC.finditer(cmd):
            blocks.append((targets[0], body.group(2)))
    for echo in ECHO_REDIR.finditer(cmd):
        blocks.append((echo.group(2), _unquote(echo.group(1))))
    return blocks


def main():
    if len(sys.argv) < 2:
        return 0
    cmd = sys.stdin.read()
    try:
        mask_source, semantic = scan_edit.load_detectors(sys.argv[1])
    except Exception:
        return 0  # detector unavailable -> fail open
    seen = set()
    for target, content in _written_blocks(cmd):
        for rule, _line in scan_edit.detect(content, mask_source, semantic):
            key = (rule, target)
            if key not in seen:
                seen.add(key)
                print(f'{rule}\t{target}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

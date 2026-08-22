#!/usr/bin/env python3
"""Resolve every documentation pointer in the shipped docs to a real file.

Invoked by scripts/validate-dod.d/57-doc-links.sh. Also runnable standalone:
python3 scripts/check_doc_links.py [repo_root]

Two pointer forms are checked, because both have gone stale here and only one
of them is a markdown link:

  1. Markdown link     [text](path.md)     resolved FILE-RELATIVE, strictly
  2. Backticked path   `path.md`           resolved against any ancestor dir

Form 2 is the load-bearing one. Agent prompt templates cite sibling references
as bare backticked paths, and a prompt telling an agent to read a file that no
longer exists is a silently degraded agent, not a docs typo. Every stale
pointer found by hand during the v0.13.0 agent merges was form 2; a link-only
checker would have passed all of them.

The two forms get different resolution rules on purpose. A markdown link is
followed by a renderer, so only the file-relative reading is correct, and eight
links written skill-root-relative from references/phases/ were silently broken
until this check was added. Prose is ambiguous by long-standing convention: the
same reference is cited as `references/goal-anchor.md` from one depth and
`goal-anchor.md` from another, and both read fine. Rather than force one
convention onto prose that does not need it, form 2 resolves against any
ancestor directory up to the repo root, and a slashless pointer resolves if a
file of that name exists anywhere. That still catches the case this check is
for: a file that was deleted or renamed and left citations behind.

Out of scope, deliberately:
  - Anchor fragments (#heading). references/finish.md describes anchor checking
    as Phase 6 work on the USER's repo; it is not a validator concern here.
  - docs/work/ and CHANGELOG.md, both frozen records of what was true then. The
    v0.13.0 entry names the very files that release deleted, correctly.
  - dist/ as a whole, because the runtime trees are deliberate subsets, not
    copies. Only claude-code ships agents/, so a template that says its fenced
    block is mirrored into `agents/…` names a real file there and nothing at all
    under gemini-cli, and copilot-cli ships a MANIFEST and no docs. Flagging
    that would flag the subsetting itself. The one tree where a dead pointer
    actually degrades a running agent is dist/claude-code, which registers what
    it ships, so 57-doc-links.sh checks that tree separately when it exists.

Exit 0 when every pointer resolves, 1 otherwise. Findings print one per line.
"""
import pathlib
import re
import sys
from typing import NamedTuple

SCAN_ROOTS = ('skills', 'agents', 'rules', 'commands', 'hooks', 'docs')
SCAN_FILES = ('README.md',)
EXCLUDE_DIRS = ('docs/work', 'dist', 'node_modules', '__pycache__')

# Pointers into the USER's repository, not this one. Prose names them as roles
# ("your project's CLAUDE.md"), so they can never resolve here and their absence
# is not a defect. Adding a name here is a deliberate call, not a silencer.
USER_REPO_POINTERS = frozenset({
    'CLAUDE.md', 'AGENTS.md', 'GEMINI.md', '.github/copilot-instructions.md',
    'DESIGN.md', 'docs/design/DESIGN.md',
    'ARCHITECTURE.md', 'architecture.md', 'CONTRIBUTING.md',
    'docs/work/.groom-scratch.md',
    # Reviewer B's INPUTS say "the project's CHANGELOG.md", meaning the one in
    # the repo under review. It resolved against this repo's own changelog by
    # pure coincidence; running the check over a built runtime, which ships no
    # changelog, is what exposed that.
    'CHANGELOG.md',
})

# Filenames invented for worked examples inside prompt templates. They describe
# a hypothetical finding, so they name no real file by design.
EXAMPLE_POINTERS = frozenset({'parallel-agents.md'})

# A pointer carrying any of these is a template or a glob, not a path on disk.
PLACEHOLDER_CHARS = '<>{}*?|$'

MD_LINK = re.compile(r'\[[^\]]*\]\(\s*([^)\s]+?\.md)(?:#[^)\s]*)?\s*\)')
INLINE_CODE = re.compile(r'`([^`\n]+?)`')
# A backticked span is a pointer only when the whole span is one path token.
CODE_PATH = re.compile(r'^[\w./-]+\.md$')


class Finding(NamedTuple):
    """One pointer that resolved against no accepted base."""

    file: pathlib.Path
    line: int
    pointer: str
    form: str


class Resolver(NamedTuple):
    """Repo-wide knowledge needed to judge whether a pointer resolves."""

    repo: pathlib.Path
    basenames: frozenset
    skill_roots: tuple

    def bases(self, source: pathlib.Path) -> list:
        """Every directory a prose path may sensibly be written against.

        The ancestor walk covers same-directory and skill-root-relative prose.
        The skill roots cover the rest: an agent prompt under agents/ that says
        `references/law-scout.md` means the file the agent loads at runtime from
        its own skill, and no ancestor of agents/ ever reaches it.
        """
        walked, current = [], source.parent
        while current != self.repo and self.repo in current.parents:
            walked.append(current)
            current = current.parent
        return walked + [self.repo] + list(self.skill_roots)

    def resolves(self, pointer: str, source: pathlib.Path) -> bool:
        """Prose rule: any accepted base, or any file of that name anywhere."""
        if '/' not in pointer and pointer in self.basenames:
            return True
        return any((base / pointer).is_file() for base in self.bases(source))


def resolves_link(pointer: str, source: pathlib.Path) -> bool:
    """Link rule: only the file-relative reading, which is what a click does."""
    return (source.parent / pointer).is_file()


def is_exempt(pointer: str) -> bool:
    """True for placeholders, user-repo roles, and worked-example filenames."""
    if any(char in pointer for char in PLACEHOLDER_CHARS):
        return True
    return pointer in USER_REPO_POINTERS or pointer in EXAMPLE_POINTERS


def pointers_in_line(line: str) -> list:
    """Extract (pointer, form) pairs from one line of markdown."""
    blanked = INLINE_CODE.sub(lambda m: ' ' * len(m.group(0)), line)
    found = [(m.group(1), 'link') for m in MD_LINK.finditer(blanked)]
    for match in INLINE_CODE.finditer(line):
        span = match.group(1).strip()
        if CODE_PATH.match(span):
            found.append((span, 'prose path'))
    return found


def scan_file(path: pathlib.Path, resolver: Resolver) -> list:
    """Collect every unresolvable pointer in one markdown file."""
    findings = []
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        for pointer, form in pointers_in_line(line):
            if is_exempt(pointer):
                continue
            ok = resolves_link(pointer, path) if form == 'link' else resolver.resolves(pointer, path)
            if not ok:
                findings.append(Finding(path.relative_to(resolver.repo), number, pointer, form))
    return findings


def is_excluded(path: pathlib.Path, repo: pathlib.Path) -> bool:
    """True for frozen records and generated trees."""
    rel = path.relative_to(repo).as_posix()
    return any(rel == name or rel.startswith(f'{name}/') for name in EXCLUDE_DIRS)


def collect_files(repo: pathlib.Path) -> list:
    """Every scanned markdown file, excluded trees removed."""
    files = [repo / name for name in SCAN_FILES if (repo / name).is_file()]
    for root in SCAN_ROOTS:
        if (repo / root).is_dir():
            files.extend(sorted((repo / root).rglob('*.md')))
    return [f for f in files if not is_excluded(f, repo)]


def build_resolver(repo: pathlib.Path) -> Resolver:
    """Index live .md basenames and skill roots so pointers can be judged."""
    live = {p.name for p in repo.rglob('*.md') if not is_excluded(p, repo)}
    roots = tuple(sorted(p for p in (repo / 'skills').iterdir() if p.is_dir())) \
        if (repo / 'skills').is_dir() else ()
    return Resolver(repo=repo, basenames=frozenset(live), skill_roots=roots)


def main(argv: list) -> int:
    """Print validator-format lines and return the process exit code."""
    target = argv[1] if len(argv) > 1 else '.'
    repo = pathlib.Path(target).resolve()
    label = 'source tree' if target in ('.', './') else target
    resolver = build_resolver(repo)
    files = collect_files(repo)
    findings = [f for path in files for f in scan_file(path, resolver)]
    if findings:
        print(f'  FAIL {len(findings)} pointer(s) in {label} resolve to no file:')
        for finding in findings:
            print(f'         - {finding.file}:{finding.line} '
                  f'({finding.form}) -> {finding.pointer}')
        return 1
    print(f'  ok   {label}, every .md link and prose path in '
          f'{len(files)} files resolves')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

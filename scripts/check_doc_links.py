#!/usr/bin/env python3
"""Resolve every documentation pointer in the shipped docs to a real file.

Invoked by scripts/validate-dod.d/57-doc-links.sh. Also runnable standalone:
python3 scripts/check_doc_links.py [repo_root]

Three pointer forms are checked, because all three have gone stale here and
only one of them is a markdown link:

  1. Markdown link      [text](path.md)     resolved FILE-RELATIVE, strictly
  2. Backticked path    `path.md`           resolved against any ancestor dir
  3. Line citation      path.md:42          the path resolved as form 2, then
                                            line 42 read for real

Form 2 is the load-bearing one. Agent prompt templates cite sibling references
as bare backticked paths, and a prompt telling an agent to read a file that no
longer exists is a silently degraded agent, not a docs typo. Every stale
pointer found by hand during the v0.13.0 agent merges was form 2; a link-only
checker would have passed all of them.

Forms 1 and 2 get different resolution rules on purpose. A markdown link is
followed by a renderer, so only the file-relative reading is correct, and eight
links written skill-root-relative from references/phases/ were silently broken
until this check was added. Prose is ambiguous by long-standing convention: the
same reference is cited as `references/goal-anchor.md` from one depth and
`goal-anchor.md` from another, and both read fine. Rather than force one
convention onto prose that does not need it, form 2 resolves against any
ancestor directory up to the repo root, and a slashless pointer resolves if a
file of that name exists anywhere. That still catches the case this check is
for: a file that was deleted or renamed and left citations behind.

Form 3 is the newest and answers a different question. A citation carries two
claims, that the file exists and that the line does, and only the first was ever
read. The second rots faster: a file survives a refactor that moves every line
in it. Form 3 checks the line number ONLY. When the path does not resolve, form
2 owns that finding and this half stays quiet rather than printing the same
pointer twice.

Every form is held to one containment rule: a pointer resolves only to a file
INSIDE the repo root. `..` is in the path class of all three forms, so before
this rule a citation like `../secret/private.py:99` was resolved through the
repo-root base, opened, and its length printed in the finding. Candidates that
escape are dropped before they are opened, which costs nothing real: a pointer
out of the tree could never be followed by a reader of the tree either.

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

Exit 0 when every pointer resolves and every cited line exists, 1 otherwise.
Findings print one per line.
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

# Directories a built runtime tree may legitimately not ship. The module
# docstring already argues both halves of this: docs/work is a frozen record, and
# a dist tree is a deliberate subset rather than a copy. Both arguments were
# applied to what gets SCANNED and never to what gets pointed AT, so a prose path
# into docs/work resolved on the source tree and failed on the built one for a
# reason that IS the subsetting. Adding a directory here is a deliberate call.
SUBSET_DIRS = ('docs/work/',)

# Filenames invented for worked examples inside prompt templates. They describe
# a hypothetical finding, so they name no real file by design.
EXAMPLE_POINTERS = frozenset({'parallel-agents.md'})

# A pointer carrying any of these is a template or a glob, not a path on disk.
PLACEHOLDER_CHARS = '<>{}*?|$'

MD_LINK = re.compile(r'\[[^\]]*\]\(\s*([^)\s]+?\.md)(?:#[^)\s]*)?\s*\)')
INLINE_CODE = re.compile(r'`([^`\n]+?)`')
# A backticked span is a pointer only when the whole span is one path token.
CODE_PATH = re.compile(r'^[\w./-]+\.md$')

# FORM 3. `some/file.md:42` claims line 42 of that file exists, and `:302-307`
# makes the same claim about a range, whose LAST line is the one that has to be
# there. Nothing before this read the number half at all.
LINE_CITE = re.compile(r'([A-Za-z0-9_./-]+\.(?:md|sh|py|json)):(\d+)(?:-(\d+))?')

# WHERE CITATIONS ACTUALLY LIVE, WHICH IS NOT WHERE MARKDOWN LIVES. Measured
# rather than assumed, and the large majority sit in shell comments under
# scripts/ rather than in shipped markdown, so a markdown-only scan would read
# past most of them. No count is written here on purpose: an unpinned number in a
# comment is the rotting claim this check exists to catch. Re-derive it with
#
#   git ls-files '*.md' '*.sh' '*.py' | grep -v '^docs/work/' \
#     | xargs grep -ohE '[A-Za-z0-9_./-]+\.(md|sh|py|json):[0-9]+' | sort | uniq -c
#
# SCAN_ROOTS is left alone on purpose, since forms 1 and 2 are markdown rules and
# widening them would change a check that is green for reasons of its own.
CITE_SCAN_ROOTS = SCAN_ROOTS + ('scripts',)
CITE_SCAN_PATTERNS = ('*.md', '*.sh', '*.py')

# Resolution needs the non-markdown names too, since a citation into a shell
# file is the common case here. Widening the basename index cannot move a form-2
# verdict:
# CODE_PATH anchors those pointers to `.md`, so no `.sh` name the index gains can
# ever match one.
INDEX_PATTERNS = ('*.md', '*.sh', '*.py', '*.json')

# The characters a hard wrap can plausibly break a path token at.
WRAP_BREAK = ('/', '-', '.')

# A continuation line's own comment or quote marker, dropped before a wrapped
# citation is rejoined. Load-bearing, see wrapped_cites.
CONTINUATION_MARKER = re.compile(r'^[\s#>]+')


class Finding(NamedTuple):
    """One pointer that did not check out, and where it was written."""

    file: pathlib.Path
    line: int
    pointer: str
    form: str
    # What the code found instead, for the forms that can say. A stale line
    # citation is unarguable only when the real line count is printed beside it.
    detail: str = ''


class Citation(NamedTuple):
    """One `path:line` claim, as written and as a range of claimed lines."""

    pointer: str
    text: str
    first: int
    last: int


class Resolver(NamedTuple):
    """Repo-wide knowledge needed to judge whether a pointer resolves."""

    repo: pathlib.Path
    # Basename to every live file carrying it. A list rather than a set of names
    # because form 3 has to OPEN the file, and a slashless pointer can name more
    # than one.
    by_name: dict
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

    def inside(self, candidate: pathlib.Path) -> bool:
        """True when `candidate` really lands inside the repo, symlinks resolved.

        A pointer is text a document chose, and `..` sits inside the path
        character class of every form read here. Joined onto a base, and the
        repo root is one of the bases, `../secret/private.py` names a file no
        checkout contains. Nothing stopped that: the candidate was opened and
        counted, and `FAIL ... ../secret/private.py has 3 lines` was a real run
        of this checker. That is an existence-and-length oracle for the
        filesystem AROUND the repo, reachable by committing a citation, and an
        unbounded read besides.

        So containment is judged BEFORE anything is opened and a candidate that
        escapes is dropped rather than read. RESOLVED, NOT SPELLED: a lexical
        `..` test would reject `../sibling.md` written from a subdirectory,
        which is an ordinary correct pointer that stays well inside the tree,
        and would still be fooled by `a/../../b`. Only the resolved path knows.

        The residual hole, named rather than glossed: a symlink INSIDE the repo
        that points out of it resolves outside and is refused, which is right,
        but a symlink outside that points back in would be accepted. This tree
        has neither, and the check is a containment rule rather than a sandbox.
        """
        try:
            resolved = candidate.resolve()
        except (OSError, RuntimeError):
            return False
        root = self.repo.resolve()
        return resolved == root or root in resolved.parents

    def locate(self, pointer: str, source: pathlib.Path) -> list:
        """Every real file a pointer could name, nearest accepted base first.

        Returns ALL of them rather than picking one. A slashless pointer names
        no single file by construction, and guessing which `SKILL.md` was meant
        is how a check invents a finding nobody can act on.

        Containment is tested first and existence second, so a pointer that
        escapes the repo is never even stat-ed, let alone read.
        """
        hits = [base / pointer for base in self.bases(source)
                if self.inside(base / pointer) and (base / pointer).is_file()]
        if hits or '/' in pointer:
            return hits
        return [hit for hit in self.by_name.get(pointer, ()) if self.inside(hit)]

    def subset_target(self, pointer: str) -> bool:
        """True when a pointer names a directory THIS checkout does not ship.

        Judged structurally, by whether the directory is here at all, rather than
        by which pass is running. That keeps the source tree strict: docs/work
        exists there, so this returns False and a genuinely dead pointer is still
        a finding. It only ever fires on a tree that never carried the directory,
        where the absence proves nothing about the pointer.
        """
        return any(pointer.startswith(name) and not (self.repo / name).is_dir()
                   for name in SUBSET_DIRS)

    def resolves(self, pointer: str, source: pathlib.Path) -> bool:
        """Prose rule: any accepted base, or any file of that name anywhere."""
        return bool(self.locate(pointer, source))

    def resolves_link(self, pointer: str, source: pathlib.Path) -> bool:
        """Link rule: only the file-relative reading, which is what a click does.

        Held to the same containment rule as everything else. A link out of the
        repo cannot be followed by a reader of this repo, so calling it resolved
        would be asserting something no checkout can honour.
        """
        target = source.parent / pointer
        return self.inside(target) and target.is_file()


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
            if is_exempt(pointer) or resolver.subset_target(pointer):
                continue
            ok = (resolver.resolves_link(pointer, path) if form == 'link'
                  else resolver.resolves(pointer, path))
            if not ok:
                findings.append(Finding(path.relative_to(resolver.repo), number, pointer, form))
    return findings


def cite_at(match) -> Citation:
    """One LINE_CITE match read as a claim about a file's lines."""
    first = int(match.group(2))
    last = int(match.group(3)) if match.group(3) else first
    return Citation(match.group(1), match.group(0), first, max(first, last))


def cites_in_line(text: str) -> list:
    """Every citation written wholly inside one line."""
    return [cite_at(m) for m in LINE_CITE.finditer(text)]


def wrapped_cites(line: str, following: str) -> list:
    """Every citation a hard line wrap split across the boundary below `line`.

    THE CHOICE, WRITTEN DOWN. Line matching plus a join step, NOT matching on a
    normalised paragraph. Line matching is what lets a finding name the line it
    was written on, and normalising a paragraph throws that away for the one
    thing the reader needs to go fix it. The join buys back the only shape a
    wrap can produce, a path token broken after a `/`, `-` or `.` with the rest
    carried to the next line.

    WHY IT IS NOT OPTIONAL. Markdown here hard-wraps near 100 columns, and a
    purely line-based scan is blind to anything a wrap splits. That exact blind
    spot is a recorded finding in this sprint's own corpus (M2, a line-based
    scan missing a phrase broken by a wrap), and it is silent rather than loud.
    Shipping it again inside the check built to stop it would be the same defect
    wearing this check's badge.

    THE CONTINUATION'S MARKER COMES OFF FIRST, and that is load-bearing rather
    than tidy. Most citations here sit in shell comments, so a continuation line
    starts `# ` far more often than not. `#` is outside the path character
    class, so joining without stripping it wedges the marker into the middle of
    the very token the join exists to repair, and the wrap case that actually
    occurs in this repo would go on being missed while a markdown fixture went
    green. test_doc_link_lines.py asserts the stripped join directly for that
    reason, not only its outcome.

    Only a match STRADDLING the boundary is returned. One that fits inside
    either line is already that line's own business, so nothing is reported
    twice. A join that fuses two ordinary words is harmless: the result still
    has to end in `.md:N` and still has to resolve to a file on disk, and the
    resolution step below is what throws the accidents away.
    """
    stem = line.rstrip()
    if not stem.endswith(WRAP_BREAK):
        return []
    joined = stem + CONTINUATION_MARKER.sub('', following)
    edge = len(stem)
    return [cite_at(m) for m in LINE_CITE.finditer(joined)
            if m.start() < edge < m.end()]


def cites_in_file(lines: list) -> list:
    """(line number, Citation) for every citation in a file, wraps included."""
    found = []
    for index, line in enumerate(lines):
        following = lines[index + 1] if index + 1 < len(lines) else ''
        for cite in cites_in_line(line) + wrapped_cites(line, following):
            found.append((index + 1, cite))
    return found


def line_count(path: pathlib.Path) -> int:
    """Lines in a file, counted the way `file:N` is read by a reader."""
    return len(path.read_text().splitlines())


def check_citation(cite: Citation, candidates: list, repo: pathlib.Path) -> str:
    """Empty when the cited lines exist, else what the code says instead.

    A file that cannot be read is a FINDING, never a pass. Treating an
    unreadable file as fine would make deleting a file's readability the way to
    silence every citation into it, which is a check that greens when broken.

    Any candidate satisfying the claim is enough. A slashless pointer names
    several real files and this check cannot know which was meant, so it asks
    only that the claim be true of one of them. THE LIMIT THAT BUYS: a bare
    `SKILL.md` citation goes stale in the file it meant and stays green while
    some other `SKILL.md` is long enough. Reporting the ambiguity instead would
    put a red on a per-commit validator for a pointer nobody can act on, which
    costs more than the miss. Write the path out to get the stronger check.
    """
    counts = []
    for candidate in candidates:
        try:
            counts.append((line_count(candidate), candidate))
        except (OSError, UnicodeDecodeError) as unreadable:
            return (f', {candidate.relative_to(repo)} could not be read '
                    f'({type(unreadable).__name__})')
    if cite.first >= 1 and any(count >= cite.last for count, _ in counts):
        return ''
    count, candidate = max(counts, key=lambda pair: pair[0])
    where = f'{candidate.relative_to(repo)} has {count} lines'
    # Counted first even here, so every finding carries the real length rather
    # than making the reader go and get it.
    return f', a file has no line 0, and {where}' if cite.first < 1 else f', {where}'


def scan_citations(path: pathlib.Path, resolver: Resolver) -> tuple:
    """(findings, citations checked) for one file's line citations."""
    try:
        lines = path.read_text().splitlines()
    except (OSError, UnicodeDecodeError) as unreadable:
        rel = path.relative_to(resolver.repo)
        detail = f', {type(unreadable).__name__}'
        return [Finding(rel, 1, rel.as_posix(), 'unreadable source', detail)], 0
    findings, checked = [], 0
    for number, cite in cites_in_file(lines):
        # A path that resolves nowhere is form 2's finding. Reporting it here
        # too would print one pointer twice and blame two checks for one defect.
        # It is also what absorbs an accidental join, see wrapped_cites.
        #
        # is_exempt is NOT consulted here, and that is deliberate on both halves.
        # PLACEHOLDER_CHARS cannot occur inside a citation at all, since none of
        # them are in LINE_CITE's path class. USER_REPO_POINTERS is about prose
        # naming a ROLE, "your project's CLAUDE.md", and a line number is never a
        # role: it names one concrete file at one concrete line. Where the file
        # really is the reader's rather than ours, it resolves to nothing here
        # and the guard below drops it anyway.
        candidates = resolver.locate(cite.pointer, path)
        if not candidates:
            continue
        checked += 1
        detail = check_citation(cite, candidates, resolver.repo)
        if detail:
            rel = path.relative_to(resolver.repo)
            findings.append(Finding(rel, number, cite.text, 'line number', detail))
    return findings, checked


def scan_all_citations(files: list, resolver: Resolver) -> tuple:
    """(findings, citations checked) across every scanned file."""
    findings, checked = [], 0
    for path in files:
        found, count = scan_citations(path, resolver)
        findings.extend(found)
        checked += count
    return findings, checked


def is_excluded(path: pathlib.Path, repo: pathlib.Path) -> bool:
    """True for frozen records and generated trees."""
    rel = path.relative_to(repo).as_posix()
    return any(rel == name or rel.startswith(f'{name}/') for name in EXCLUDE_DIRS)


def collect_files(repo: pathlib.Path, roots: tuple, patterns: tuple) -> list:
    """Every scanned file under the given roots, excluded trees removed.

    A root naming a FILE rather than a directory is taken as it stands, which is
    how README.md joins a scan whose other roots are all directories. It is
    passed in rather than added here on the quiet, so a caller asking for one
    root gets one root.
    """
    named = [repo / name for name in roots if (repo / name).is_file()]
    dirs = [repo / name for name in roots if (repo / name).is_dir()]
    found = [path for root in dirs for pattern in patterns
             for path in root.rglob(pattern)]
    return sorted(f for f in named + found if not is_excluded(f, repo))


def build_resolver(repo: pathlib.Path) -> Resolver:
    """Index live files by basename and skill roots so pointers can be judged."""
    by_name = {}
    for pattern in INDEX_PATTERNS:
        for path in repo.rglob(pattern):
            if not is_excluded(path, repo):
                by_name.setdefault(path.name, []).append(path)
    roots = tuple(sorted(p for p in (repo / 'skills').iterdir() if p.is_dir())) \
        if (repo / 'skills').is_dir() else ()
    return Resolver(repo=repo, by_name=by_name, skill_roots=roots)


def main(argv: list) -> int:
    """Print validator-format lines and return the process exit code."""
    target = argv[1] if len(argv) > 1 else '.'
    repo = pathlib.Path(target).resolve()
    label = 'source tree' if target in ('.', './') else target
    resolver = build_resolver(repo)
    files = collect_files(repo, SCAN_ROOTS + SCAN_FILES, ('*.md',))
    findings = [f for path in files for f in scan_file(path, resolver)]
    # ONE ok line per invocation, deliberately. 00-helpers.sh and validate-dod.sh
    # both document the shell-to-transcript ok-line gap as a count of delegated
    # INVOCATIONS; a second printed pass here would make that prose wrong in two
    # files, so the citation total rides on the line that was already printed.
    cited = collect_files(repo, CITE_SCAN_ROOTS + SCAN_FILES, CITE_SCAN_PATTERNS)
    stale, checked = scan_all_citations(cited, resolver)
    findings += stale
    if findings:
        print(f'  FAIL {len(findings)} pointer(s) in {label} do not check out:')
        for finding in findings:
            print(f'         - {finding.file}:{finding.line} '
                  f'({finding.form}) -> {finding.pointer}{finding.detail}')
        return 1
    print(f'  ok   {label}, every .md link and prose path in {len(files)} files '
          f'resolves, and {checked} line citation(s) name a line that exists')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

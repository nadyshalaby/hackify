#!/usr/bin/env python3
"""Resolve every documentation pointer in the shipped docs to a real file.

Invoked by scripts/validate-dod.d/57-doc-links.sh. Also runnable standalone:
python3 scripts/check_doc_links.py [repo_root]

Five pointer forms are checked, because all of them have gone stale here or can,
and only two of them are markdown links:

  1. Markdown link      [text](path.md)      resolved FILE-RELATIVE, strictly
  2. Backticked path    `path.md`            resolved against any ancestor dir
  3. Line citation      path.md:42           the path resolved as form 2, then
                                             line 42 read for real, and what it
                                             SAYS judged against the claim
  4. Anchor fragment    [t](path.md#a-head)  the path resolved as form 1, then
                                             the fragment resolved to a heading
  5. Prose anchor       path.sh's wi_absent  the path resolved as form 2, then
                                             the construct or quoted phrase
                                             found inside the file it cites

THIS FILE OWNS FORMS 1 AND 2 AND NOTHING ELSE. Form 3 lives in
check_doc_cites.py and forms 4 and 5 in check_doc_anchors.py, split out when
this file stood at 491 of the 500-LOC cap check [80] enforces; each of those
headers names its own seam. This file stayed the single entry point, so [57]
runs one command and reads one `ok` line, and no check ID moved.

Form 2 is the load-bearing one. Agent prompt templates cite sibling references
as bare backticked paths, and a prompt telling an agent to read a file that no
longer exists is a silently degraded agent, not a docs typo. Every stale pointer
found by hand during the v0.13.0 agent merges was form 2; a link-only checker
would have passed all of them.

Forms 1 and 2 get different resolution rules on purpose. A markdown link is
followed by a renderer, so only the file-relative reading is correct, and eight
links written skill-root-relative from references/phases/ were silently broken
until this check was added. Prose is ambiguous by long-standing convention: the
same reference is cited as `references/goal-anchor.md` from one depth and
`goal-anchor.md` from another, and both read fine. So form 2 resolves against
any ancestor directory up to the repo root, and a slashless pointer resolves if
a file of that name exists anywhere. That still catches the case this check is
for: a file deleted or renamed with citations left behind.

Form 3 answers a different question. A citation carries three claims, that the
file exists, that the line does, and that the line still says what cites it. The
third rots fastest and went unread for the whole first life of this check:
retargeting a live citation from `:38` to `:1` left the entire bar green. Form 3
now opens the cited location, refuses one that is blank or a shebang, and where
the citing text quotes the line behind a verb it matches that quote against what
is really there; where nothing pins the content the citation is UNPINNED and
says so on the coverage line. check_doc_cites.py carries the grammar, the
reproduction and the reason the verb is required. When the path does not
resolve, form 2 owns that finding and this half stays quiet.

Form 5 is the one with the most live work to do. It reads prose that cites a
file possessively and then names a construct or quotes a phrase inside it, the
spelling eight repairs in one sprint produced when they stopped citing line
numbers that rot. Those anchors were checked by nothing: [57] proved only that
the PATH resolved. Its scope is form 3's citation surface, and its coverage,
what it read and what it could not, prints on the `ok` line.

Form 4 is PROSPECTIVE. It resolves the half after the `#`, which forms 1 to 3
all discarded, against the headings of the file the link points into, using
GitHub's own slug rules. Its scope is exactly the links form 1 already accepted,
so one defect prints once. Measured on 2026-09-01 this repo contains ZERO anchor
links, so it guards against the first one rotting rather than repairing
anything, and it is the one counter the floors below deliberately omit.

Every form is held to one containment rule: a pointer resolves only to a file
INSIDE the repo root, judged before anything is opened. Resolver.inside carries
the oracle that rule closes and the residual it does not.

Out of scope, deliberately:
  - Anchors on non-`.md` targets. `source.py#L10` is GitHub's line-anchor
    mechanism, not a heading reference, and this checker's link scope has always
    been `.md`.
  - docs/work/ and CHANGELOG.md, both frozen records of what was true then. The
    v0.13.0 entry names the very files that release deleted, correctly.
  - dist/ as a whole, because the runtime trees are deliberate subsets, not
    copies. Only claude-code ships agents/, so a template saying its fenced
    block is mirrored into `agents/…` names a real file there and nothing under
    gemini-cli, and copilot-cli ships a MANIFEST and no docs. Flagging that
    would flag the subsetting itself. The one tree where a dead pointer degrades
    a running agent is dist/claude-code, which registers what it ships, so
    57-doc-links.sh checks it separately when it exists.

Exit 0 when every pointer resolves, every cited line exists and carries the
content claimed of it, every anchor still names something in the file it cites,
and every coverage counter clears its floor; 1 otherwise. One finding per line.
"""
import importlib.util
import pathlib
import re
import sys
from typing import NamedTuple


def _sibling(name: str):
    """Load a split-out half by path, since scripts/ is not a package.

    A plain `import` resolves only from this directory, and the suite loads THIS
    file by path too, so by name both halves would be unreachable from the tests.
    """
    spec = importlib.util.spec_from_file_location(
        name, pathlib.Path(__file__).resolve().parent / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# FORM 3 lives next door, FORMS 4 AND 5 in the other half. Each names its seam.
CITES = _sibling('check_doc_cites')
ANCHORS = _sibling('check_doc_anchors')

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
    # Reviewer B's INPUTS say "the project's CHANGELOG.md", the repo under
    # review. It resolved against this repo's own by coincidence; the built
    # runtime, which ships no changelog, is what exposed that.
    'CHANGELOG.md',
})

# Directories a built runtime tree may legitimately not ship. Both scan-side
# arguments above were applied to what gets SCANNED and never to what gets
# pointed AT, so a prose path into docs/work resolved on the source tree and
# failed on the built one for a reason that IS the subsetting. Adding a
# directory here is a deliberate call.
SUBSET_DIRS = ('docs/work/',)

# Filenames invented for worked examples, naming no real file by design.
# `path.sh` is this file's own docstring naming form 5's shape. Deliberate.
EXAMPLE_POINTERS = frozenset({'parallel-agents.md', 'path.sh'})

# The prefix both suites declare, in their own headers, for a name that exists
# in no fixture-free tree. THE EXEMPTION IS SELF-DECLARING, which is why it beats
# a list of paths: a list goes stale in silence and the next fixture is invisible
# again, while a fixture saying so in its own name is screened with no edit.
FIXTURE_PREFIX = 'probe-'

# WRITTEN DOWN BY HAND, NEVER DERIVED FROM THE SCAN THEY GUARD. Every counter on
# the coverage line can fall to zero on a green line: a regressed glob, resolver
# or exclusion each stop the scan finding anything and then print a clean count
# of nothing. 00-helpers.sh's check_list_size argues the general form, that a
# bound taken from the list it polices guards nothing.
#
# THE NUMBERS ARE ROUND AND SIT WELL UNDER THE LIVE COUNTS, by choice rather
# than slack. Measured on 2026-09-01: 121 files, 70 line citations, 25 prose
# anchors. A floor catches a COLLAPSE, not churn, and this repo repaired eight
# citations out of existence in one sprint, so a floor just under today's count
# would redden correct work and then get raised until it guarded nothing.
#
# FORM 4 IS DELIBERATELY ABSENT. check_doc_anchors.py's header records that this
# tree carries ZERO heading-slug anchor links, so its honest count is nought: a
# floor of 0 is not a floor, and any floor above it reddens an honest tree.
SOURCE_TREE_FLOORS = (('files scanned for pointers', 100),
                      ('line citations opened at the cited location', 40),
                      ('prose anchors resolved into the file they cite', 12))

# A pointer carrying any of these is a template or a glob, not a path on disk.
PLACEHOLDER_CHARS = '<>{}*?|$'

# The fragment is CAPTURED now rather than matched and dropped, which is what
# form 4 reads. Group 1 is unchanged, so forms 1 and 2 see exactly what they saw.
MD_LINK = re.compile(r'\[[^\]]*\]\(\s*([^)\s]+?\.md)(?:#([^)\s]*))?\s*\)')
# A link whose whole target is a fragment, naming its own file's headings: the
# form finish.md's Class (b) grep lists first, and the one MD_LINK cannot match.
SELF_LINK = re.compile(r'\[[^\]]*\]\(\s*#([^)\s]+?)\s*\)')
INLINE_CODE = re.compile(r'`([^`\n]+?)`')
# A backticked span is a pointer only when the whole span is one path token.
CODE_PATH = re.compile(r'^[\w./-]+\.md$')

# FORM 3's own constants moved to check_doc_cites.py with the block that reads
# them. Only the composition stays, because SCAN_ROOTS is form 1 and 2's.
CITE_SCAN_ROOTS = SCAN_ROOTS + CITES.EXTRA_CITE_ROOTS

# Resolution needs the non-markdown names too, since a citation into a shell
# file is the common case here. Widening the basename index cannot move a form-2
# verdict: CODE_PATH anchors those pointers to `.md`, so no `.sh` name it gains
# can ever match one.
INDEX_PATTERNS = ('*.md', '*.sh', '*.py', '*.json')

class Finding(NamedTuple):
    """One pointer that did not check out, and where it was written."""

    file: pathlib.Path
    line: int
    pointer: str
    form: str
    # What the code found instead, for the forms that can say. A stale line
    # citation is unarguable only when the real line count is printed beside it.
    detail: str = ''


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
        The skill roots cover the rest: an agent prompt under agents/ saying
        `references/law-scout.md` means the file that agent loads from its own
        skill, and no ancestor of agents/ ever reaches it.
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
        pointing out of it resolves outside and is refused, which is right, but
        one outside pointing back in would be accepted. This tree has neither,
        and the check is a containment rule rather than a sandbox.
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
        is how a check invents a finding nobody can act on. Containment is
        tested first, so a pointer that escapes is never even stat-ed.
        """
        hits = [base / pointer for base in self.bases(source)
                if self.inside(base / pointer) and (base / pointer).is_file()]
        if hits or '/' in pointer:
            return hits
        return [hit for hit in self.by_name.get(pointer, ()) if self.inside(hit)]

    def subset_target(self, pointer: str) -> bool:
        """True when a pointer names a directory THIS checkout does not ship.

        Judged structurally, by whether the directory is here at all, rather
        than by which pass is running. That keeps the source tree strict:
        docs/work exists there, so a genuinely dead pointer is still a finding.
        It fires only on a tree that never carried the directory, where the
        absence proves nothing about the pointer.
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


class Coverage(NamedTuple):
    """Everything the coverage line reports, and what the floors judge.

    Grouped rather than passed as four arguments, over the three-parameter cap,
    and so a counter added later reaches both without a third edit site.
    """

    label: str
    files: int
    # CiteTally and AnchorTally, both NamedTuples and so both really tuples.
    cites: tuple
    anchors: tuple


def is_exempt(pointer: str) -> bool:
    """True for placeholders, user-repo roles, and worked-example filenames."""
    if any(char in pointer for char in PLACEHOLDER_CHARS):
        return True
    return pointer in USER_REPO_POINTERS or pointer in EXAMPLE_POINTERS


def is_fixture(pointer: str) -> bool:
    """True for a pointer that DECLARES itself invented rather than dead."""
    return (pointer.rsplit('/', 1)[-1].startswith(FIXTURE_PREFIX)
            or pointer in EXAMPLE_POINTERS)


def undeclared_anchors(anchors) -> list:
    """A finding per prose anchor whose path nobody declared invented.

    All eight that exist today are declared fixtures, which is why the rule is
    affordable now and why waiting until one of them is real would be the
    expensive order to do it in. AnchorTally.missing carries the rest.
    """
    return [Finding(row[0], row[1], f"{row[2]}'s {row[3]}", 'prose anchor',
                    ', which names no file in this tree and declares itself '
                    'neither a fixture nor a worked example')
            for row in anchors.missing if not is_fixture(row[2])]


def collapsed_floors(coverage: Coverage) -> list:
    """Every coverage counter that fell below its hand-written floor.

    SOURCE TREE ONLY. A built runtime is a deliberate subset and the suites
    drive this entry point over two-file fixture repos, so a floor written for
    this repo would redden both for being what they are. [57] passes `.` for
    the pass these numbers were counted against.
    """
    if coverage.label != 'source tree':
        return []
    counts = (coverage.files, coverage.cites.checked, coverage.anchors.checked)
    return [f'{name} is {count}, under the floor of {floor} written beside it'
            for (name, floor), count in zip(SOURCE_TREE_FLOORS, counts)
            if count < floor]


def coverage_line(coverage: Coverage) -> str:
    """The one ok line, carrying what was read AND what was not.

    A checker that examines four citations of twelve and prints a clean line is
    the defect this was built to remove, so what went unread is counted beside
    what was read.
    """
    cites, anchors = coverage.cites, coverage.anchors
    return (f'  ok   {coverage.label}, every .md link and prose path in '
            f'{coverage.files} files resolves, {cites.checked} line citation(s) '
            f'name a line that exists and carries content ({cites.pinned} '
            f'pinned to a phrase the citing text quotes, {cites.unpinned} '
            'unpinned, whose content nothing in the citing text names), and '
            f'{anchors.checked} prose anchor(s) resolve into the file they cite '
            f'({anchors.unparsed} named no construct or phrase and '
            f'{anchors.unresolved} named a path that resolves nowhere, '
            'neither checked)')


def print_findings(findings: list, label: str) -> None:
    """Every finding in validator format, one per line."""
    print(f'  FAIL {len(findings)} pointer(s) in {label} do not check out:')
    for finding in findings:
        print(f'         - {finding.file}:{finding.line} '
              f'({finding.form}) -> {finding.pointer}{finding.detail}')


def pointers_in_line(line: str) -> list:
    """Extract (pointer, form, fragment) triples from one line of markdown."""
    blanked = INLINE_CODE.sub(lambda m: ' ' * len(m.group(0)), line)
    found = [(m.group(1), 'link', m.group(2) or '') for m in MD_LINK.finditer(blanked)]
    for match in INLINE_CODE.finditer(line):
        span = match.group(1).strip()
        if CODE_PATH.match(span):
            found.append((span, 'prose path', ''))
    return found


def scan_file(path: pathlib.Path, resolver: Resolver) -> list:
    """Collect every unresolvable pointer and dead anchor in one markdown file.

    THE READ IS GUARDED, and it was not always. A `.md` file that is not valid
    UTF-8 under any scan root used to raise out of here and kill the process
    with a traceback, where scan_citations next door had turned the same failure
    into a finding since the day it was written. [57] still went red, so nothing
    shipped broken; the operator simply got a stack trace where every other
    failure prints one validator-format line. The suite's own row for this could
    never have caught it: its fixture is a `.sh` file, which only the citation
    scan opens.
    """
    try:
        lines = path.read_text().splitlines()
    except (OSError, UnicodeDecodeError) as unreadable:
        rel = path.relative_to(resolver.repo)
        return [Finding(rel, 1, rel.as_posix(), 'unreadable source',
                        f', {type(unreadable).__name__}')]
    findings = []
    for number, line in enumerate(lines, start=1):
        for pointer, form, fragment in pointers_in_line(line):
            if is_exempt(pointer) or resolver.subset_target(pointer):
                continue
            ok = (resolver.resolves_link(pointer, path) if form == 'link'
                  else resolver.resolves(pointer, path))
            if not ok:
                findings.append(Finding(path.relative_to(resolver.repo), number, pointer, form))
            elif fragment and not ANCHORS.resolves(path.parent / pointer, fragment):
                findings.append(Finding(path.relative_to(resolver.repo), number,
                                        f'{pointer}#{fragment}', 'anchor'))
        for fragment in SELF_LINK.findall(INLINE_CODE.sub(' ', line)):
            if not ANCHORS.resolves(path, fragment):
                findings.append(Finding(path.relative_to(resolver.repo), number,
                                        f'#{fragment}', 'anchor'))
    return findings


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
    # files, so every other total rides on the line that was already printed.
    cited = collect_files(repo, CITE_SCAN_ROOTS + SCAN_FILES, CITES.CITE_SCAN_PATTERNS)
    # ANCHORS is handed to form 3 because its content tier reads form 5's anchor
    # grammar and scripts/ is not a package, so the composition lives here.
    stale, cites = CITES.scan_all_citations(cited, resolver, ANCHORS)
    findings += [Finding(*row) for row in stale]
    # Form 5 shares form 3's file list, not form 4's: a possessive citation is
    # prose, and most of this repo's prose about its own code sits in shell
    # comments under scripts/, which a markdown-only surface reads straight past.
    rotted, anchors = ANCHORS.scan_all_prose_anchors(cited, resolver)
    findings += [Finding(*row) for row in rotted] + undeclared_anchors(anchors)
    if findings:
        print_findings(findings, label)
        return 1
    coverage = Coverage(label, len(files), cites, anchors)
    collapsed = collapsed_floors(coverage)
    if collapsed:
        print(f'  FAIL coverage collapsed in {label}; a clean line from a scan '
              'that found nothing is a count of nothing:')
        for line in collapsed:
            print(f'         - {line}')
        return 1
    print(coverage_line(coverage))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

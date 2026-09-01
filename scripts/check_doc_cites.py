#!/usr/bin/env python3
"""FORM 3, the `:42` in `some/file.md:42`, opened and counted for real.

Split out of scripts/check_doc_links.py in the sprint that file stood at 491 of
the 500-LOC hard cap that check [80] enforces, and could not take form 4. Two
halves came out at once: this one and check_doc_anchors.py. Neither move changed
a check ID, an exit code or the single `ok` line [57] reads, because
check_doc_links.py is still the only entry point and still prints it.

THE SEAM IS THE QUESTION EACH FORM ASKS. Forms 1 and 2 next door ask whether a
PATH resolves, and from which base. Form 3 asks a second, independent question
about a pointer whose path already resolved: does the LINE exist. It runs over a
wider surface than forms 1 and 2 (`.sh` and `.py` as well as `.md`, since that is
where citations actually live), it owns the hard-wrap join that nothing else
needs, and it opens files to count them, which nothing else does. It shares no
state with the pointer half and never did.

WHY THIS HALF AND NOT ANOTHER. It is the largest self-contained block in the
file and the only one whose entire dependency on its parent is two names it is
handed as arguments, a Resolver and a list of files. Cutting at forms 1 and 2
instead would have split `Resolver` from `is_exempt` from `scan_file`, three
things that read each other on every line.

FINDINGS LEAVE HERE AS PLAIN TUPLES, in Finding's field order, and
check_doc_links.py maps them. That is what keeps the dependency one-way. Defining
Finding here so both files could share it would have put the record type in the
half that does not print it, and importing it back from there would be a cycle;
a third module for one NamedTuple would be worse than either.

Every paragraph arguing for this half came across whole. Nothing was summarised
and nothing was dropped.
"""
import pathlib
import re
from typing import NamedTuple


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
# SCAN_ROOTS itself stays next door, so the composition does too; this is the
# widening, named here where the argument for it lives.
EXTRA_CITE_ROOTS = ('scripts',)
CITE_SCAN_PATTERNS = ('*.md', '*.sh', '*.py')

# The characters a hard wrap can plausibly break a path token at.
WRAP_BREAK = ('/', '-', '.')

# A continuation line's own comment or quote marker, dropped before a wrapped
# citation is rejoined. Load-bearing, see wrapped_cites.
CONTINUATION_MARKER = re.compile(r'^[\s#>]+')


class Citation(NamedTuple):
    """One `path:line` claim, as written and as a range of claimed lines.

    THE TAIL IS CARRIED FROM THE POINT OF EXTRACTION, not re-derived later.
    Only the extractor knows where the citation ended, and a wrapped citation
    ended on a line the finding is not even blamed on, so re-finding the text
    downstream would silently read the tail of the wrong one on any line
    carrying two citations.
    """

    pointer: str
    text: str
    first: int
    last: int
    # Whatever the writer put after the citation, wrap-joined. cite_anchor
    # reads it; nothing else does.
    tail: str = ''


class CiteTally(NamedTuple):
    """What form 3 judged at each cited location, and what it could not.

    Both halves ride on the coverage line for the reason the unparsed count
    next door already does: a checker that reads the content of two citations
    of sixty-six and prints a clean line is the defect this file exists to
    remove, not a smaller version of the fix.
    """

    checked: int = 0
    # The citing text QUOTED the line it names, so the quote was matched
    # against the content really at that location.
    pinned: int = 0
    # Nothing in the citing text names the content, so the location was judged
    # for existence and for vacancy and no further. Counted, never silent.
    unpinned: int = 0

    def plus(self, other) -> 'CiteTally':
        """Two scans' tallies added, so the fold never unpacks three names."""
        return CiteTally(self.checked + other.checked,
                         self.pinned + other.pinned,
                         self.unpinned + other.unpinned)


def cite_at(match, joined: str = '') -> Citation:
    """One LINE_CITE match read as a claim about a file's lines."""
    first = int(match.group(2))
    last = int(match.group(3)) if match.group(3) else first
    tail = (joined or match.string)[match.end():]
    return Citation(match.group(1), match.group(0), first, max(first, last), tail)


def cites_in_line(text: str, following: str = '') -> list:
    """Every citation written wholly inside one line, tails wrap-joined.

    The MATCHING stays on one line, and only the TAIL reaches into the line
    below. A citation is found where it was written, so a finding still names
    that line, but the phrase a writer quotes of it routinely wraps, opening the
    quote beside the citation and closing it on the next line. A tail stopping
    at the line end reads that as an unterminated quote and checks nothing.
    The live example is 77-reviewer-roster.sh's "Two reviewers consume a
    deterministic scout run" citation, named rather than copied here: a second
    copy of a live claim is a second thing to go stale.
    """
    joined = f'{text} {CONTINUATION_MARKER.sub("", following)}'
    return [cite_at(m, joined) for m in LINE_CITE.finditer(text)]


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
        for cite in cites_in_line(line, following) + wrapped_cites(line, following):
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

# --- THE CONTENT TIER, a citation checked against what is really there --------
#
# WHAT THIS CLOSES, MEASURED RATHER THAN ARGUED. Everything above proves a cited
# line EXISTS. It never proved the line still SAYS what cites it, and since files
# grow, "the cited line is still there and now says something else" is the
# dominant staleness mode: it is the mode this repo hit eight times in one
# sprint. The gap was reproducible end to end. Retarget
# `scripts/tamper_harness.py:38,177` in 01-presence-matchers.sh to `:1,177`,
# which points the claim at a shebang, and the whole bar went green.
#
# NO NEW CITATION CONVENTION IS INVENTED HERE, and that constraint shaped the
# whole tier. Form 5 next door already reads an anchor written as a quoted phrase
# or a named construct, and `cite_anchor` reads THAT grammar through the module
# it is handed rather than a second copy of it. Where a writer wrote no anchor at
# all the citation is UNPINNED, which is reported on the coverage line and never
# quietly counted as verified.
#
# THE VERB IS WHAT MAKES A QUOTE A CLAIM ABOUT THAT LINE, and it is the whole
# false-positive floor. Measured over this tree's 66 live citations, twice.
# Reading any quotation sitting straight AFTER a citation as a claim about it
# gives SEVEN reds and not one green pin, because this repo keeps defect ledgers
# pairing a line number with what that site said BEFORE it was repaired, in
# aligned columns and with no verb (77-reviewer-roster.sh's "a since-retired
# mode SKILL.md" table is one, and four of the seven are that shape). Requiring
# the verb gives one green pin and one genuine red, and no false alarms:
# `<cite> says "<phrase>"` is a claim about the line now, while a column of
# prose beside a line number is a claim about the past.

# `:38,177` names two lines and `:12-14,20` a range and a line. Every number
# after the first is part of the CLAIM, so it comes off before the tail is read
# as prose. Without this the tail of the live citation above begins `,177` and no
# verb can ever follow it.
MORE_LINES = re.compile(r'^(?:\s*,\s*:?\d+(?:-\d+)?)*')

# The verbs this repo puts between a citation and a quotation of it. A closing
# bracket may sit in between, since `(some.md:9)` is a written form here.
CITE_VERB = re.compile(r'^[\s)]*'
                       r'(?:says|said|reads|states|stated|carries|argues|names|'
                       r'records|asserts)\s+')

# A line carrying no claim: blank, or nothing but the comment, quote and table
# markers this repo's prose is written behind.
VACANT_LINE = re.compile(r'^(?:[\s>#*|]|//|--)*$')

# A file's first line when it addresses the loader rather than the reader.
SHEBANG = '#!'


def claim_lines(lines: list, cite: Citation) -> list:
    """The cited lines that carry a readable claim, of the range as written.

    A SHEBANG IS NOT ONE. A sentence about what a file says is never about line
    1 of a file that opens `#!`, which addresses the interpreter and no reader.
    That is not a convenience: it is the line the reproduction above retargets
    to, and the cheapest honest way to say a citation now names nothing.

    A range keeps its verdict as a whole. `:302-307` claims a block, so one
    line of real content anywhere inside it is a block that still says
    something, and only a range that is vacant end to end names nothing.
    """
    window = lines[max(cite.first - 1, 0):cite.last]
    return [line for offset, line in enumerate(window, start=max(cite.first, 1))
            if not VACANT_LINE.match(line)
            and not (offset == 1 and line.startswith(SHEBANG))]


def cite_anchor(tail: str, anchors) -> str:
    """The phrase a citation QUOTES of the line it names, `''` when none.

    `anchors` is check_doc_anchors, handed in rather than imported. scripts/ is
    not a package, so this module cannot import its sibling by name at all, and
    the composition of the two halves has lived next door in check_doc_links.py
    since they were split. Passing the module keeps that one-way and keeps form
    5's grammar in exactly one place.
    """
    verb = CITE_VERB.match(MORE_LINES.sub('', tail))
    return anchors.anchor_at(verb.string[verb.end():]) if verb else ''


def check_cite_content(cite: Citation, candidates: list, anchors) -> tuple:
    """(detail, pinned) for the content at a cited location.

    `detail` is empty when the location backs the claim made about it. `pinned`
    says whether the citing text pinned that content at all, which the coverage
    line reports rather than passing over in silence.

    UNREADABLE IS NOT JUDGED HERE, and that is not a pass. check_citation above
    already returns a finding naming the file and the error, and one defect
    should print once.

    Any candidate satisfying the claim is enough, the rule check_citation set
    for a slashless pointer, and for the same reason: this half cannot know
    which `SKILL.md` was meant, so it asks that the claim be true of one.
    """
    anchor = cite_anchor(cite.tail, anchors)
    bodies = []
    for candidate in candidates:
        # anchors.anchor_text, not a second read_text: it is cached on content
        # identity, and this runs inside a per-citation loop where several live
        # citations name one file. An uncached read here would be the
        # query-in-loop shape rules/performance.md bans, in the file that
        # already solved it.
        text = anchors.anchor_text(candidate)
        if text is None:
            return '', bool(anchor)
        bodies.append(claim_lines(text.splitlines(), cite))
    if not any(bodies):
        return ', and every line it names is blank, a bare marker or a shebang', False
    if not anchor:
        return '', False
    if any(anchors.locate_anchor('\n'.join(body) + '\n', anchor) for body in bodies):
        return '', True
    return f', which no longer says "{anchor}"', True


# A path that resolves nowhere is form 2's finding. Reporting it in scan_citations
# too would print one pointer twice and blame two checks for one defect. It is
# also what absorbs an accidental join, see wrapped_cites.
#
# is_exempt is NOT consulted there, and that is deliberate on both halves.
# PLACEHOLDER_CHARS cannot occur inside a citation at all, since none of them are
# in LINE_CITE's path class. USER_REPO_POINTERS is about prose naming a ROLE,
# "your project's CLAUDE.md", and a line number is never a role: it names one
# concrete file at one concrete line. Where the file really is the reader's
# rather than ours, it resolves to nothing and the guard drops it anyway.
def scan_citations(path: pathlib.Path, resolver, anchors) -> tuple:
    """(finding rows, tally) for one file's line citations.

    Rows are plain tuples in Finding's field order, per the module docstring:
    (relative path, line, pointer text, form, detail). check_doc_links.py maps
    them, which is what keeps this module free of any import from it.
    """
    try:
        lines = path.read_text().splitlines()
    except (OSError, UnicodeDecodeError) as unreadable:
        rel = path.relative_to(resolver.repo)
        detail = f', {type(unreadable).__name__}'
        return [(rel, 1, rel.as_posix(), 'unreadable source', detail)], CiteTally()
    findings, tally = [], CiteTally()
    for number, cite in cites_in_file(lines):
        candidates = resolver.locate(cite.pointer, path)
        if not candidates:
            continue
        rel = path.relative_to(resolver.repo)
        detail = check_citation(cite, candidates, resolver.repo)
        if detail:
            tally = tally.plus(CiteTally(checked=1, unpinned=1))
            findings.append((rel, number, cite.text, 'line number', detail))
            continue
        # THE CONTENT TIER RUNS ONLY ON A CITATION WHOSE LINE IS REALLY THERE.
        # Asking what a line past the end of a file says would print two
        # findings for one defect and name the second one wrongly.
        detail, pinned = check_cite_content(cite, candidates, anchors)
        tally = tally.plus(CiteTally(checked=1, pinned=int(pinned),
                                     unpinned=int(not pinned)))
        if detail:
            findings.append((rel, number, cite.text, 'line content', detail))
    return findings, tally


def scan_all_citations(files: list, resolver, anchors) -> tuple:
    """(finding rows, tally) across every scanned file."""
    findings, tally = [], CiteTally()
    for path in files:
        found, count = scan_citations(path, resolver, anchors)
        findings.extend(found)
        tally = tally.plus(count)
    return findings, tally

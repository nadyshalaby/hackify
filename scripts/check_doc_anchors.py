#!/usr/bin/env python3
"""The two ANCHOR forms, a citation resolved by NAME rather than by line.

FORM 4 is the `#fragment` half of a markdown link, resolved to a real heading.
FORM 5 is the prose spelling this repo reaches for far more often, a file cited
possessively and then a construct or a quoted phrase named inside it. Both ask
one question, does the named thing still exist in the file that is cited, and
both survive a line shift, which is the whole reason the repairs that produced
them stopped citing line numbers. Form 5 sits at the bottom of this file behind
its own banner; everything above it is form 4.

Split out of scripts/check_doc_links.py in the sprint that file stood at 491 of
the 500-LOC hard cap that check [80] enforces. Imported by it and run as forms 4
and 5; there is no `main` here and no exit code, because this module answers one
question about one citation and the caller decides what a false answer costs.

THE SEAM IS THE RENDERER. Forms 1 to 3 next door ask filesystem questions: does
this path resolve, from which base, and is line 42 really there. Form 4 asks a
MARKDOWN question, what anchor does GitHub mint for this heading, and the answer
comes from a slug algorithm and a fence tracker that share no state and no line
of code with the other three. Nothing here needs a Resolver, a Finding or a scan
root, and nothing there needs a heading. Cutting anywhere else would have left
one half reaching into the other.

THIS GUARD HAS NEVER FIRED, AND WAS BUILT KNOWING THAT. Measured on 2026-09-01
over the 121 files in the scan surface: 362 markdown links to `.md` files, and
ZERO of them carry a fragment of any spelling. The whole tracked tree holds two
anchor-bearing strings, both on skills/hackify/references/finish.md:133, and
both are backticked syntax examples inside a sentence describing the anchor rule
itself. So the live count of anchor links in this repo is zero, and this check
is PROSPECTIVE: it exists so the first anchor written here cannot rot silently,
not because anything is rotting now. A future reader finding a check that has
never once reddened should know it was built that way on purpose. Re-derive the
count rather than trusting this paragraph:

  git ls-files '*.md' | xargs grep -ohE '\\]\\([^)[:space:]]*#[^)[:space:]]*\\)'

THE SLUG RULES ARE GITHUB'S, because GitHub is the renderer these links are
written for. A heading becomes an anchor by rendering its inline markup away,
downcasing, DELETING every character that is not a word character, a hyphen or a
space, turning each remaining space into a hyphen, and disambiguating a repeat
inside one document with `-1`, `-2` and so on. Deleting rather than replacing is
the half that surprises: `Foo & Bar` is `foo--bar` with two hyphens, because the
`&` vanishes and both spaces survive it. Approximately right is worse than not
shipping, since a slugger that is subtly wrong prints false reds on a per-commit
doc gate, and a false red is how a gate gets quietly weakened later.

FENCED CODE HOLDS NO HEADINGS, and that is load-bearing rather than tidy.
Measured on the same pass: 1254 real heading slugs across the scan surface and
238 ATX-shaped lines sitting INSIDE fenced blocks. Every one of those would have
been a phantom anchor a dead link could resolve against. It is not hypothetical.
finish.md carries `## Test plan` inside the fenced `gh pr create` body template,
so `#test-plan` is a dead anchor even though a `grep '^## '` says otherwise, and
the fence tracker is the only reason this check says so.

TWO HEADING SPELLINGS ARE NOT READ, named rather than left silent: setext
headings (text underlined with `=` or `-`) and explicit HTML anchors
(`<a id="x">`). Both mint real anchors on GitHub, so a link into one would be
reported here as dead. Checked before the omission was accepted: this tree
carries zero of each.
"""
import re
from typing import NamedTuple

# The path half may be empty, which is a same-file anchor, and the fragment half
# may be empty, which anchors_in_line reads as no anchor at all.
ANCHOR_LINK = re.compile(r'\[[^\]]*\]\(\s*([^)\s#]*)#([^)\s]*?)\s*\)')

# ATX only, closing hashes dropped. A `#` with no space after it is not a
# heading in CommonMark and is not one here either.
ATX_HEADING = re.compile(r'^ {0,3}#{1,6}[ \t]+(.*?)(?:[ \t]+#+)?[ \t]*$')
CODE_FENCE = re.compile(r'^ {0,3}(`{3,}|~{3,})')

# A link or image inside a heading collapses to its own text. Without this the
# URL's word characters leak into the slug and every anchor into that heading
# reads as dead.
INLINE_LINK = re.compile(r'!?\[([^\]]*)\]\([^)]*\)')

# `_` is the one emphasis marker that is also a slug character, so it cannot be
# deleted outright. Intraword it is literal and GitHub keeps it, so `snake_case`
# stays `snake_case`; at a word boundary it is emphasis and the renderer eats
# it, so `_em_` is `em`. The residual, named rather than glossed: a heading
# ENDING in a literal `_` loses it here and keeps it on GitHub. Zero headings in
# this tree end that way.
EMPHASIS_UNDERSCORE = re.compile(r'(?<!\w)_+|_+(?!\w)')

# Everything else GitHub deletes. Ruby's `\p{Word}` is letters, marks, decimal
# digits and `_`; Python's `\w` is that set plus a few non-decimal numerals such
# as `½`, which no heading here carries.
NOT_IN_SLUG = re.compile(r'[^\w\- ]', re.UNICODE)

# Every marker that is not `_` (`*`, backtick, `~`) needs no stripping rule of
# its own: none of them is a word character, a hyphen or a space, so the
# deletion above already removes them. A second rule would be dead code.

# One parse per file rather than one per anchor. resolves() is called inside the
# scan's per-link loop, so a table of contents with thirty entries would read
# and re-parse its target thirty times, which is the query-in-loop shape
# rules/performance.md bans outright.
#
# KEYED ON CONTENT IDENTITY, NOT ON PATH. The suite drives main() many times in
# one process, and a path-only key would serve a stale heading set to a later
# run that happened to reuse a name. Folding mtime and size into the key means a
# changed file simply misses. Bounded by construction: one entry per distinct
# markdown file the scan actually opens, which is the scan's own size.
_SLUG_CACHE = {}


def slugify(heading: str) -> str:
    """One heading's text as GitHub turns it into an anchor."""
    plain = EMPHASIS_UNDERSCORE.sub('', INLINE_LINK.sub(r'\1', heading))
    return NOT_IN_SLUG.sub('', plain.lower()).replace(' ', '-')


def heading_slugs(text: str) -> frozenset:
    """Every anchor a markdown document offers, fenced code excluded.

    The fence tracker follows CommonMark closely enough for the shapes here: a
    run of three or more backticks or tildes opens, and only a run of the same
    character at least as long closes it. The length half matters in this repo,
    whose report skeletons are fenced with four backticks and carry
    three-backtick fences of their own inside.
    """
    slugs, seen, fence = [], {}, None
    for line in text.splitlines():
        opener = CODE_FENCE.match(line)
        if opener:
            mark = opener.group(1)
            if fence is None:
                fence = mark
            elif mark[0] == fence[0] and len(mark) >= len(fence):
                fence = None
            continue
        head = None if fence is not None else ATX_HEADING.match(line)
        if head is None:
            continue
        base = slugify(head.group(1))
        seen[base] = seen.get(base, 0) + 1
        slugs.append(base if seen[base] == 1 else f'{base}-{seen[base] - 1}')
    return frozenset(slugs)


def anchors_in_line(line: str) -> list:
    """(path, fragment) for every markdown link on one line carrying a `#`.

    An EMPTY fragment is dropped here rather than downstream. `page.md#` puts a
    reader at the top of the file, the same place `page.md` does, so there is no
    heading it can be wrong about and resolving it would redden a link that
    works. The tree could not settle this, since it carries neither spelling, so
    the renderer's behaviour did.
    """
    return [(m.group(1), m.group(2))
            for m in ANCHOR_LINK.finditer(line) if m.group(2)]


def resolves(target, fragment: str) -> bool:
    """True when `target` really offers a heading slugging to `fragment`.

    A target that cannot be read is FALSE, never a pass, on the precedent
    check_citation set next door: if unreadable meant fine, making a file
    unreadable would silence every anchor into it, which is a check that greens
    exactly when it has stopped working.
    """
    try:
        stat = target.stat()
        key = (str(target), stat.st_mtime_ns, stat.st_size)
        slugs = _SLUG_CACHE.get(key)
        if slugs is None:
            slugs = _SLUG_CACHE[key] = heading_slugs(target.read_text())
    except (OSError, UnicodeDecodeError):
        return False
    return fragment in slugs


# --- FORM 5, an anchor written as prose ---------------------------------------
#
# WHY THIS EXISTS, AND WHY IT DID NOT BEFORE. Citations here used to be written
# `some-file.sh:105-108`, and a line citation rots the moment the cited file
# gains or loses a line above it. Form 3 next door proves the line EXISTS; it has
# never been able to prove the line still says what the citing sentence claims,
# and one citation in this tree had drifted twelve lines while three separate
# mechanisms reported healthy. The repair, taken eight times in one sprint, was
# to stop citing a number and name the CONSTRUCT instead, so the reference
# resolves by grep and survives any shift. That repair is strictly better and it
# is not a verification: nothing read the new anchors either, and shipping them
# as if something did would be the same overclaim, one layer up.
#
# THE FORM WAS DERIVED FROM THE TREE, NOT DESIGNED. Every possessive citation
# was read before this was written. Re-derive the shape rather than trusting
# this paragraph, and re-derive the split between what is read and what is not:
#
#   git ls-files '*.md' '*.sh' '*.py' | grep -v '^docs/work/' \
#     | xargs grep -nE "[A-Za-z0-9_./-]+\.(md|sh|py|json)'s "
#
# WHAT IS READ, three spellings, all of them live in this tree:
#   a quoted phrase     93-token-declarations.sh's "the defect wearing the uniform"
#   a backticked span   validate-dod.sh's `set -uo pipefail` line
#   a snake_case name   73-implementer-rename.sh's wi_absent
#
# WHAT IS NOT READ, and is COUNTED AND PRINTED rather than passed over. A tail
# naming an ordinary noun ("its header", "its shape", "its version") points at
# no greppable thing, and a construct spelled without an underscore is
# indistinguishable from an English word in the same position. Both land in the
# unparsed tally, which rides on the same `ok` line as the checked count. That
# is deliberate and it is the standard this sprint set: a checker that examines
# four citations of twelve and prints a clean line is the defect being removed,
# not a smaller version of the fix.
#
# THE UNDERSCORE RULE IS THE FALSE-POSITIVE FLOOR. A bare token is taken as a
# construct only when it carries an `_`. Without that rule the first English
# word after the apostrophe is grepped into the target and every prose tail
# becomes a red the writer can only clear by rewording correct prose. This tree
# is bash and python, where constructs are snake_case, so the rule costs
# nothing here and its cost elsewhere is visible in the unparsed count.

# The path half, and the apostrophe. The TAIL is sliced from the match end
# rather than captured, so a line carrying two citations yields two: a greedy
# `(.*)` capture would swallow the second into the first's tail.
POSSESSIVE_CITE = re.compile(r"([A-Za-z0-9_./-]+\.(?:md|sh|py|json))'s[ \t]+")

# The two delimiters a quoted anchor is written with here.
QUOTE_MARKS = ('"', '`')

# A bare token, judged by the underscore rule above.
BARE_TOKEN = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')

# A line's own comment or quote marker, dropped before the file is read as
# flowing prose. Same character class as check_doc_cites.CONTINUATION_MARKER and
# deliberately not shared with it: that one strips ONE continuation line so a
# wrapped path token can be rejoined, this one strips EVERY line so a whole file
# can be searched across its wraps. Importing it would give this module a second
# loaded copy of its sibling, which check_doc_links already holds, to borrow four
# characters.
LINE_LEAD = re.compile(r'^[\s#>]+')
WHITESPACE = re.compile(r'\s+')

# Raw file text, keyed on content identity exactly as _SLUG_CACHE is and for the
# same two reasons. check_prose_anchor runs inside a per-citation loop and eight
# live citations name one file, so an uncached read would open it eight times,
# the query-in-loop shape rules/performance.md bans outright. Keying on the path
# alone would then serve a later run a body the file no longer has, which the
# suite drives directly.
_TEXT_CACHE = {}


class AnchorTally(NamedTuple):
    """What form 5 read, and what it could not, over one scan."""

    checked: int = 0
    # A tail naming no construct and no quoted phrase.
    unparsed: int = 0
    # A pointer resolving to no file in this tree. Nothing else covers these
    # either: form 2 reads only `.md` pointers, so a possessive citation naming a
    # deleted `.sh` is invisible to every other form and is counted here.
    unresolved: int = 0
    # WHICH pointers resolved nowhere, not merely how many. A count alone was
    # the whole defect: eight of these sat on a green line for the life of this
    # check, every one of them skipped without being examined and none of them
    # nameable without re-running the scan by hand. A reader who cannot see the
    # names cannot tell a corpus of test fixtures from a genuinely dead pointer,
    # and the caller cannot judge them either. check_doc_links.py holds the
    # exemption policy, as it does for forms 1 and 2, so the rows leave here as
    # plain data and it decides which are declared fixtures.
    #
    # Rows are (source path, line, pointer, anchor), the order a finding wants.
    missing: tuple = ()

    def plus(self, other) -> 'AnchorTally':
        """Two scans' tallies added, so the fold never unpacks four names."""
        return AnchorTally(self.checked + other.checked,
                           self.unparsed + other.unparsed,
                           self.unresolved + other.unresolved,
                           self.missing + other.missing)


def anchor_at(tail: str) -> str:
    """The construct or phrase a possessive citation names, `''` when neither.

    AN UNTERMINATED QUOTE RETURNS NOTHING rather than the rest of the line.
    Taking the remainder would invent a phrase nobody wrote, which is then
    almost never present in the target, so the check would manufacture a red out
    of its own parse failure. Unparsed is the honest verdict and it is counted
    where a reader can see it.
    """
    for mark in QUOTE_MARKS:
        if tail.startswith(mark):
            close = tail.find(mark, 1)
            return tail[1:close] if close > 1 else ''
    word = BARE_TOKEN.match(tail)
    return word.group(0) if word and '_' in word.group(0) else ''


def anchor_cites_in_line(line: str) -> list:
    """(pointer, anchor) for every possessive citation written on one line.

    A citation the writer hard-wrapped between the apostrophe and its anchor
    yields an empty tail and so an empty anchor, which lands in the unparsed
    count. That is the same answer as an unreadable tail and it is the right
    one: the anchor cannot be read from this line, and saying so beats guessing
    at the line below.
    """
    return [(m.group(1), anchor_at(line[m.end():]))
            for m in POSSESSIVE_CITE.finditer(line)]


def flowed(text: str) -> str:
    """One file read as a reader reads it: markers off, wraps joined."""
    return WHITESPACE.sub(' ', ' '.join(
        LINE_LEAD.sub('', line) for line in text.splitlines()))


def anchor_text(path):
    """One target's raw text, or None when it cannot be read."""
    try:
        stat = path.stat()
        key = (str(path), stat.st_mtime_ns, stat.st_size)
        text = _TEXT_CACHE.get(key)
        if text is None:
            text = _TEXT_CACHE[key] = path.read_text()
        return text
    except (OSError, UnicodeDecodeError):
        return None


def locate_anchor(text: str, anchor: str) -> str:
    """`'line'`, `'wrapped'` or `''`, and the three are not interchangeable.

    THE TRAP THIS CLOSES. grep is line-based and this repo hard-wraps near 100
    columns, so a quoted phrase split across two lines of the TARGET resolves to
    zero hits while being perfectly present. A line-only check would report that
    as a rewording that never happened. The two want opposite fixes, one
    repoints the citation and the other changes nothing at all, so they are told
    apart rather than collapsed into a single miss.

    The flowed search runs ONLY after the line search misses, which keeps the
    join off the common path. Its residual, named rather than glossed: joining
    every line means a phrase could match across a boundary that no single
    sentence spans. It would still have to read exactly as the citation quotes
    it, so the file really does say that, and the direction of the error is a
    green on a phrase that is there rather than a red on one that is not.
    """
    if anchor in text:
        return 'line'
    return 'wrapped' if WHITESPACE.sub(' ', anchor.strip()) in flowed(text) else ''


def check_prose_anchor(anchor: str, candidates: list, repo) -> str:
    """Empty when exactly one cited file carries the anchor, else what is wrong.

    AMBIGUITY IS A FINDING HERE, WHERE FORM 3 LIVES WITH IT. A slashless pointer
    names several real files and form 3 asks only that its claim be true of one,
    because a line number nobody can act on is not worth a red on a per-commit
    gate. An anchor is different in the way that matters: when two candidates
    both carry it, a rot in the INTENDED one stays hidden because the other goes
    on answering, and that is a check which greens exactly when it has stopped
    working. The fix is one edit, write the path out, so the red is actionable.

    A file that cannot be read is a finding, never a pass, on the rule
    check_citation already set: were it one, making a file unreadable would
    silence every anchor into it.
    """
    carriers, unread = [], []
    for candidate in candidates:
        text = anchor_text(candidate)
        if text is None:
            unread.append(str(candidate.relative_to(repo)))
        elif locate_anchor(text, anchor):
            carriers.append(str(candidate.relative_to(repo)))
    if unread:
        return f", {', '.join(unread)} could not be read"
    if len(carriers) == 1:
        return ''
    if not carriers:
        listed = ', '.join(str(c.relative_to(repo)) for c in candidates)
        return f', no such construct or phrase in {listed}'
    return (f", named in {len(carriers)} files ({', '.join(carriers)}); a rot in "
            'the intended one would stay hidden, so write the path out')


def scan_prose_anchors(path, resolver) -> tuple:
    """(finding rows, tally) for one file's possessive citations.

    Rows are plain tuples in Finding's field order, the convention
    check_doc_cites.py set, and check_doc_links.py maps them. An unreadable
    SOURCE returns nothing at all: the citation scan reads the same file list
    and already reports it, and one defect should print once.
    """
    text = anchor_text(path)
    if text is None:
        return [], AnchorTally()
    findings, tally = [], AnchorTally()
    for number, line in enumerate(text.splitlines(), start=1):
        for pointer, anchor in anchor_cites_in_line(line):
            if not anchor:
                tally = tally.plus(AnchorTally(unparsed=1))
                continue
            # A path that resolves nowhere is form 2's finding where form 2 can
            # see it, and NOBODY'S where it cannot: form 2 reads only `.md`
            # pointers, so a possessive citation naming a deleted `.sh` was
            # invisible to every form and merely counted here. It is now NAMED,
            # and check_doc_links.py rules on the name.
            candidates = resolver.locate(pointer, path)
            if not candidates:
                row = (path.relative_to(resolver.repo), number, pointer, anchor)
                tally = tally.plus(AnchorTally(unresolved=1, missing=(row,)))
                continue
            tally = tally.plus(AnchorTally(checked=1))
            detail = check_prose_anchor(anchor, candidates, resolver.repo)
            if detail:
                findings.append((path.relative_to(resolver.repo), number,
                                 f"{pointer}'s {anchor}", 'prose anchor', detail))
    return findings, tally


def scan_all_prose_anchors(files: list, resolver) -> tuple:
    """(finding rows, tally) across every scanned file."""
    findings, tally = [], AnchorTally()
    for path in files:
        found, count = scan_prose_anchors(path, resolver)
        findings.extend(found)
        tally = tally.plus(count)
    return findings, tally

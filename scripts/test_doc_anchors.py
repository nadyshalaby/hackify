#!/usr/bin/env python3
"""Unit tests for the anchor half of check_doc_links.py, forms 4 and 5.

Run: python3 scripts/test_doc_anchors.py

Form 4 reads the `#fragment` of a markdown link and asks whether the file it
points into really offers a heading by that name, using GitHub's slug rules.
Form 5 reads the prose spelling, a file cited possessively and then a construct
or a quoted phrase named inside it. The rules for both live in
check_doc_anchors.py, and FORM 3'S CONTENT TIER reads form 5's grammar through
it, so its pinning rows are here too, behind their own banner.

SPLIT FROM test_doc_link_lines.py, which stood at 452 of the 500-LOC cap check
[80] enforces and could not take these rows.

THE HARNESS IS IMPORTED, NOT COPIED. `_build` and `_run` come from the sibling
suite, so both drive the SAME loaded checker through the same entry point. A
second copy would be free to drift, which is the quietest way for two green
suites to disagree about one checker.

EVERY ROW HERE HAS BEEN SEEN TO FAIL. Each was watched red against the checker
before the form it covers existed, then weakened deliberately and watched stop
detecting. Eleven mutations were taken for form 4 and fourteen for form 5 when
they landed, and twelve more for form 3's content tier, the floors and the
unresolved-anchor rule; every one was killed by a row below.

A GREEN ROW ASSERTS THE TALLY, NEVER THE EXIT CODE ALONE. `code == 0` is what a
checker prints when it has never looked at a single anchor: measured, five
form-5 rows passed against a tree with no form 5 in it at all. They read the
`ok` line's counts as well, which is the difference between a row that proves
something and a row that cannot fail.

Fixtures go to a tempdir, never into this repo, and every literal names a
`probe-` file that exists in no real tree, so this file cannot redden the live
check on its own text. It is scanned by the check it tests.
"""

import importlib.util
import pathlib
import sys

SIBLING = pathlib.Path(__file__).resolve().parent / 'test_doc_link_lines.py'


def _load_harness():
    """Load the sibling suite by path, since scripts/ is not a package."""
    spec = importlib.util.spec_from_file_location('test_doc_link_lines', SIBLING)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


HARNESS = _load_harness()
CDL = HARNESS.CDL
_build = HARNESS._build
_run = HARNESS._run

# One `# Top`, one heading exercising every transformation at once, and a
# deliberate duplicate pair so the `-1` suffix has something to disambiguate.
HEADINGS = '# Top\n\n## Form 3: The "hard" wrap, & why\n\n## Same\n\n## Same\n'


def _anchored(link: str, target: str = HEADINGS) -> dict:
    """A target carrying real headings plus one note linking into it."""
    return {'docs/probe-target.md': target,
            'docs/note.md': f'see [it]({link}) for the rule\n'}


# --- the fragment resolves, or it does not ------------------------------------


def test_an_anchor_that_names_a_real_heading_stays_green():
    code, out = _run(_anchored('probe-target.md#top'))
    assert code == 0, out


def test_an_anchor_that_names_no_heading_is_caught():
    code, out = _run(_anchored('probe-target.md#nowhere'))
    assert code == 1, out
    assert 'probe-target.md#nowhere' in out, out


# --- GitHub's slug rules ------------------------------------------------------


def test_the_slug_transformation_is_applied_not_the_raw_heading():
    """Punctuation deleted, case folded, spaces hyphenated. `&` DELETED rather
    than replaced surprises: both spaces survive, so the slug carries two
    hyphens where the `&` was."""
    code, out = _run(_anchored('probe-target.md#form-3-the-hard-wrap--why'))
    assert code == 0, out


def test_the_raw_heading_text_is_not_accepted_as_an_anchor():
    """Case and punctuation carried through verbatim is a dead anchor. The
    spelling a writer reaches for is the heading with its spaces hyphenated and
    nothing else changed, and GitHub deletes the rest."""
    code, out = _run(_anchored('probe-target.md#Form-3:-The-"hard"-wrap,-&-why'))
    assert code == 1, out


def test_a_repeated_heading_takes_the_github_suffix():
    """Two `## Same` headings mint `same` and `same-1`. `same-2` is nobody."""
    ok, _ = _run(_anchored('probe-target.md#same-1'))
    bad, out = _run(_anchored('probe-target.md#same-2'))
    assert ok == 0
    assert bad == 1, out


def test_the_slugger_is_asserted_directly():
    """Pins the transformation itself, not only its outcome, which would pass
    if some other path reached the same verdict. The underscore line is the
    subtle one: intraword literal, at a word boundary emphasis."""
    slug = CDL.ANCHORS.slugify
    assert slug('Form 3: The "hard" wrap, & why') == 'form-3-the-hard-wrap--why'
    assert slug('**Bold** and `code`') == 'bold-and-code'
    assert slug('_em_ and snake_case') == 'em-and-snake_case'
    assert slug('[a link](http://example.com) here') == 'a-link-here'
    assert slug('Trailing hashes') == 'trailing-hashes'


# --- what form 4 must NOT do --------------------------------------------------


def test_a_link_with_no_fragment_is_untouched():
    code, out = _run(_anchored('probe-target.md'))
    assert code == 0, out


def test_an_empty_fragment_is_the_same_case_as_no_fragment():
    """`page.md#` lands a reader where `page.md` does, so there is no heading it
    can be wrong about and resolving it would redden a link that works."""
    code, out = _run(_anchored('probe-target.md#'))
    assert code == 0, out


def test_a_link_into_a_missing_file_still_reds_through_the_path_check():
    """Form 1 owns a dead file and form 4 must not swallow its finding."""
    code, out = _run(_anchored('probe-gone.md#top'))
    assert code == 1, out
    assert 'probe-gone.md' in out, out
    assert '(link)' in out, 'form 1 no longer owns a dead file:\n%s' % out


# --- fenced code holds no headings --------------------------------------------


def test_a_heading_inside_a_fenced_block_is_not_an_anchor():
    """The case this repo actually contains, and why the tracker exists.

    Agent prompts carry report skeletons inside fences opening `## Wave status`,
    and counting those hands a dead anchor a target. finish.md is the live
    example: `## Test plan` sits inside a fenced body, so `#test-plan` is dead
    even though `grep '^## '` says otherwise.
    """
    fenced = '# Top\n\n```\n## Wave status\n```\n'
    code, out = _run(_anchored('probe-target.md#wave-status', fenced))
    assert code == 1, out


# --- the same-file form -------------------------------------------------------


def test_a_same_file_anchor_is_checked_against_its_own_headings():
    """`[t](#frag)`, the form finish.md's own Class (b) grep names first."""
    files = {'docs/note.md': '# Real Heading\n\nsee [it](#real-heading) and [no](#gone)\n'}
    code, out = _run(files)
    assert code == 1, out
    assert '#gone' in out, out
    assert '#real-heading' not in out, out


# --- reading failures must be loud --------------------------------------------


def test_an_anchor_into_an_unreadable_file_fails_loudly():
    """Unreadable is never a pass: were it one, making a file unreadable would
    silence every anchor into it. The target sits outside the scan roots, so
    this tests form 4's guard rather than the markdown scan's."""
    files = {'lib/probe-target.md': b'\xff\xfe # Top\n',
             'docs/note.md': 'see [it](../lib/probe-target.md#top) for the rule\n'}
    code, out = _run(files)
    assert code == 1, out
    assert '(anchor) -> ../lib/probe-target.md#top' in out, out


# --- the cache may not answer for a file it no longer describes ---------------


def test_the_slug_cache_never_serves_a_stale_heading_set():
    """One parse per file, keyed on content identity rather than on path.

    resolves() runs in the per-link loop, so an uncached read re-parses one
    target per anchor, the query-in-loop shape rules/performance.md bans; a
    path-only key then serves a later run a heading set the file no longer has.
    """
    root = _build({'docs/probe-target.md': '# First Heading\n'})
    target = root / 'docs' / 'probe-target.md'
    assert CDL.ANCHORS.resolves(target, 'first-heading')
    assert not CDL.ANCHORS.resolves(target, 'second-heading')
    target.write_text('# Second Heading\n')
    assert CDL.ANCHORS.resolves(target, 'second-heading'), 'the cache went stale'
    assert not CDL.ANCHORS.resolves(target, 'first-heading'), 'the cache went stale'


# --- FORM 5, an anchor that is a construct name or a quoted phrase ------------
#
# Form 4 above resolves a `#fragment` against a heading. Form 5 resolves the
# spelling this repo uses far more: prose citing a file possessively and then
# naming something inside it. Two live spellings, one line each because form 5
# reads a line at a time: `73-implementer-rename.sh's wi_absent`, and
# `93-token-declarations.sh's "the defect wearing the uniform" sentence`. Both
# survive a line shift, and until this suite neither was checked by anything.
#
# Every fixture path below is a `probe-` name, so the live scan cannot resolve
# one and this suite cannot redden [57] on its own text.

# A target carrying one greppable construct and one quotable sentence.
PROBE_TARGET = ('# the "no count is kept here" sentence, quoted whole\n'
                'probe_absent() {\n'
                '  return 1\n'
                '}\n')


def _cited(citation: str, target: str = PROBE_TARGET) -> dict:
    """A target file plus one shell comment citing something inside it."""
    return {'scripts/probe-target.sh': target,
            'scripts/probe-note.sh': f'# {citation}\n'}


def test_a_construct_anchor_that_still_exists_stays_green():
    """Green AND counted: a row reading only `code == 0` passes against a
    checker that has never looked at a single anchor."""
    code, out = _run(_cited("probe-target.sh's probe_absent, which returns 1"))
    assert code == 0, out
    assert '1 prose anchor(s) resolve into the file they cite' in out, out


def test_a_construct_anchor_that_no_longer_exists_is_caught():
    """The rename case. Nothing before form 5 read the name half at all."""
    code, out = _run(_cited("probe-target.sh's probe_renamed, which returns 1"))
    assert code == 1, out
    assert 'probe_renamed' in out, out
    assert 'probe-target.sh' in out, 'the finding names one side only:\n%s' % out


def test_a_quoted_phrase_still_in_the_target_stays_green():
    code, out = _run(_cited('probe-target.sh\'s "no count is kept here" sentence'))
    assert code == 0, out
    assert '1 prose anchor(s) resolve into the file they cite' in out, out


def test_a_quoted_phrase_reworded_out_of_the_target_is_caught():
    """The rewording case: citing prose unchanged, target still there, only
    the phrase moved, so forms 1 to 4 all stay green."""
    code, out = _run(_cited('probe-target.sh\'s "no count is written here" sentence'))
    assert code == 1, out
    assert 'no count is written here' in out, out


def test_a_backticked_anchor_reads_the_same_as_a_quoted_one():
    """`validate-dod.sh's `set -uo pipefail` line` is the live spelling."""
    body = 'set -uo pipefail\n'
    ok, ok_out = _run(_cited("probe-target.sh's `set -uo pipefail` line", body))
    bad, out = _run(_cited("probe-target.sh's `set -eo pipefail` line", body))
    assert ok == 0
    assert '1 prose anchor(s) resolve into the file they cite' in ok_out, ok_out
    assert bad == 1, out


# --- the phrase moved, or the phrase merely wrapped ---------------------------


def test_a_phrase_the_target_hard_wraps_is_not_called_rot():
    """grep is line-based and this repo hard-wraps near 100 columns, so a
    phrase split across two lines resolves to zero hits while being perfectly
    present. The two want opposite fixes, so form 5 tells them apart."""
    wrapped = '# the "no count is kept\n# here" sentence, wrapped\n'
    code, out = _run(_cited('probe-target.sh\'s "no count is kept here" sentence',
                            wrapped))
    assert code == 0, out
    assert '1 prose anchor(s) resolve into the file they cite' in out, out


def test_the_two_ways_a_phrase_can_be_missing_are_told_apart_directly():
    """Pins the distinction, not the exit code both share: `wrapped` is a pass
    whose fix is nothing, `''` is a pass nobody gets."""
    find = CDL.ANCHORS.locate_anchor
    assert find('alpha beta gamma\n', 'beta gamma') == 'line'
    assert find('# alpha beta\n# gamma delta\n', 'beta gamma') == 'wrapped'
    assert find('alpha beta gamma\n', 'beta omega') == ''


# --- an anchor two files answer to ---------------------------------------------


def test_an_anchor_two_candidate_files_both_carry_is_reported_ambiguous():
    """A slashless pointer names no single file and form 3 lives with that;
    form 5 cannot, because when two candidates carry the anchor a rot in the
    INTENDED one is invisible while the other keeps answering."""
    files = {'scripts/one/probe-dup.sh': 'probe_absent() { return 1; }\n',
             'scripts/two/probe-dup.sh': 'probe_absent() { return 0; }\n',
             'scripts/probe-note.sh': "# probe-dup.sh's probe_absent decides\n"}
    code, out = _run(files)
    assert code == 1, out
    assert 'probe_absent' in out, out
    assert '2 file' in out, 'the finding does not say what is ambiguous:\n%s' % out


def test_an_anchor_only_one_of_two_candidates_carries_is_not_ambiguous():
    """The anchor is what disambiguates a pointer a line number could not."""
    files = {'scripts/one/probe-dup.sh': 'probe_absent() { return 1; }\n',
             'scripts/two/probe-dup.sh': 'nothing here\n',
             'scripts/probe-note.sh': "# probe-dup.sh's probe_absent decides\n"}
    code, out = _run(files)
    assert code == 0, out
    assert '1 prose anchor(s) resolve into the file they cite' in out, out


# --- what form 5 does NOT parse is printed, never passed silently -------------


def test_a_prose_tail_is_counted_unchecked_rather_than_passed():
    """`inject-context.sh's header states` names no construct and no phrase, and
    a checker reading only the parsable ones prints a clean line about four
    citations of twelve, so what was NOT read rides on that line too."""
    code, out = _run(_cited("probe-target.sh's header states the contract"))
    assert code == 0, out
    assert '1 named no construct or phrase' in out, out
    assert '0 prose anchor(s) resolve' in out, 'it was counted as checked:\n%s' % out


def test_an_unterminated_quote_is_not_read_as_an_anchor():
    """Taking the rest of the line would invent a phrase nobody wrote, then
    find it absent and manufacture a red out of its own parse failure."""
    code, out = _run(_cited('probe-target.sh\'s "no closing quote on this line'))
    assert code == 0, out
    assert '1 named no construct or phrase' in out, out


def test_a_pointer_that_resolves_nowhere_is_not_form_5s_finding():
    """Form 2 owns a dead path, and one defect prints once."""
    files = {'scripts/probe-note.sh': "# probe-vanished.sh's probe_absent decides\n"}
    code, out = _run(files)
    assert code == 0, out
    assert 'probe-vanished' not in out, out
    assert '1 named a path that resolves nowhere' in out, \
        'the citation was dropped without being counted:\n%s' % out


# --- the text cache may not answer for a file it no longer describes ----------


def test_the_anchor_text_cache_never_serves_a_stale_file():
    """Same rule as the slug cache: check_prose_anchor runs in a per-citation
    loop and eight live citations name one file, so a path-only key answers a
    later run with a body the file no longer has."""
    read, find = CDL.ANCHORS.anchor_text, CDL.ANCHORS.locate_anchor
    root = _build({'scripts/probe-target.sh': 'probe_absent() { return 1; }\n'})
    target = root / 'scripts' / 'probe-target.sh'
    assert find(read(target), 'probe_absent') == 'line'
    target.write_text('probe_renamed() { return 1; }\n')
    assert find(read(target), 'probe_absent') == '', 'the cache went stale'
    assert find(read(target), 'probe_renamed') == 'line', 'the cache went stale'


# --- FORM 3'S CONTENT TIER, which reads THIS file's anchor grammar ------------
#
# These rows sit here rather than beside form 3's own because what they exercise
# is form 5's grammar: check_doc_cites.cite_anchor is handed this module, reads
# the quoted or backticked phrase with anchor_at and matches it with
# locate_anchor. Rows in the other suite would test this file at a distance. The
# vacancy half of the tier carries no anchor and stays there.

PINNED = 'alpha\nthe defect wearing the uniform\ngamma\n'


def test_a_quoted_phrase_is_matched_against_the_line_the_citation_names():
    """The staleness mode form 3 could never see, and the one this repo hit:
    the line still exists, so every earlier check passed it, and it simply no
    longer says what cites it. Line 2 carries the phrase, line 3 does not."""
    say = 'probe-target.sh:%d says "the defect wearing the uniform"'
    ok, ok_out = _run(_cited(say % 2, PINNED))
    bad, out = _run(_cited(say % 3, PINNED))
    assert ok == 0, ok_out
    assert '1 pinned to a phrase the citing text quotes' in ok_out, ok_out
    assert bad == 1, out
    assert 'no longer says "the defect wearing the uniform"' in out, out


def test_a_quote_with_no_verb_before_it_is_not_read_as_a_pin():
    """The false-positive floor, load-bearing rather than cautious.

    This repo keeps defect ledgers pairing a line number with what that site
    said BEFORE it was repaired, in aligned columns and with no verb. Measured
    over the 66 live citations, dropping the verb gives seven reds and not one
    green pin: `<cite> says "<phrase>"` is a claim about the line now, and a
    column beside it is one about the past.
    """
    code, out = _run(_cited('probe-target.sh:3   "the defect wearing the uniform"',
                            PINNED))
    assert code == 0, out
    assert '0 pinned' in out, 'a ledger column was read as a claim:\n%s' % out


def test_a_backticked_pin_reads_the_same_as_a_quoted_one():
    """One grammar, form 5's, not a second copy of it.

    Both citations carry a second line number, `:2,9`, which is a live spelling
    here. The numbers after the first are part of the claim, so the tail reader
    steps over them; if it did not, no verb could ever follow one of these.
    """
    body = 'alpha\nset -uo pipefail\n'
    ok, ok_out = _run(_cited('probe-target.sh:2,9 states `set -uo pipefail`', body))
    bad, out = _run(_cited('probe-target.sh:1,9 states `set -uo pipefail`', body))
    assert ok == 0, ok_out
    assert '1 pinned' in ok_out, 'the second line number ate the verb:\n%s' % ok_out
    assert bad == 1, out


# --- an unresolved anchor is NAMED, or declares itself invented ---------------


def test_an_unresolved_anchor_that_declares_nothing_is_a_finding():
    """The other half of the row above, and the defect it closes.

    An unresolved anchor was counted and skipped, so a possessive citation
    naming a deleted `.sh` was invisible to every form: form 2 reads only `.md`.
    A fixture declares itself with the `probe-` prefix both suites document.

    DEAD is composed rather than written whole, and that is this row paying its
    own bill: the one pointer it needs is one declaring itself no fixture, which
    is precisely what the live scan of THIS file would report against it. Split
    across a `+` there is no `.sh's` for form 5 to find, and the fixture the
    checker is handed is identical.
    """
    dead = 'vanished-' + 'helpers.sh'
    code, out = _run({'scripts/probe-note.sh': f"# {dead}'s wi_absent decides\n"})
    assert code == 1, out
    assert f"{dead}'s wi_absent" in out, out
    assert 'declares itself neither a fixture nor a worked example' in out, out


# --- the coverage counters have a floor, and it is written down ---------------


def test_a_collapsed_coverage_counter_is_a_finding_not_a_clean_line():
    """Every counter on the ok line could fall to zero on a green line.

    A regressed glob, resolver or exclusion each stop the scan finding anything
    and print a clean count of nothing. The floors are hand-written beside the
    code, never derived from the scan they guard, and only the source-tree pass
    is held to them: a fixture repo and a built runtime are smaller by design.
    """
    floors = CDL.collapsed_floors
    empty = CDL.Coverage('source tree', 0, CDL.CITES.CiteTally(),
                         CDL.ANCHORS.AnchorTally())
    collapsed = floors(empty)
    assert len(collapsed) == 3, collapsed
    assert 'files scanned for pointers is 0' in collapsed[0], collapsed
    assert floors(empty._replace(label='dist/claude-code')) == [], 'a subset tree'
    full = CDL.Coverage('source tree', 999, CDL.CITES.CiteTally(checked=999),
                        CDL.ANCHORS.AnchorTally(checked=999))
    assert floors(full) == [], 'an honest tree was reddened'


def test_form_4_is_left_out_of_the_floor_table_on_purpose():
    """M13's disclosure, machine-checked rather than asserted in prose.

    This tree carries ZERO heading-slug anchor links, so form 4's honest count
    is nought: a floor of 0 is not a floor and any above it reddens an honest
    tree. The equality is check_list_size's rule, so no floor arrives unread.
    """
    assert len(CDL.SOURCE_TREE_FLOORS) == 3, CDL.SOURCE_TREE_FLOORS


def _all_tests() -> list:
    """Every test_ function in this module, in source order."""
    return [value for name, value in sorted(globals().items())
            if name.startswith('test_') and callable(value)]


def main() -> int:
    """Run the suite and report, matching test_doc_link_lines.py's shape."""
    tests = _all_tests()
    failures = []
    for test in tests:
        try:
            test()
        except AssertionError as err:
            failures.append(f'{test.__name__}: {err or "assertion failed"}')
    for line in failures:
        print(f'FAIL  {line}')
    print(f'{len(tests) - len(failures)}/{len(tests)} passed')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""Unit tests for the pointer and line-citation halves of check_doc_links.py.

Run: python3 scripts/test_doc_link_lines.py

Forms 1 and 2 resolve a PATH; form 3 reads the `:42` in `some/file.md:42`, asks
whether line 42 is really there, and then asks what it says. This suite drives
`main` end to end rather than the internals, because the exit code is what the
validator reads and a helper returning the right list while `main` returns 0 is
a green that means nothing.

FORMS 4 AND 5 ARE NOT HERE. They moved to test_doc_anchors.py when this file
stood at 452 of the 500-LOC cap check [80] enforces, the same seam the code
took, and both are still reached through the one entry point every row below
drives. Rows asserting on form 3's units reach them as `CDL.CITES.<name>`, the
only visible trace of that move. Form 3's CONTENT tier is split the same way:
its vacancy rows are here and its anchor-pinning rows sit beside the grammar
they exercise, which is form 5's.

THE HARNESS BELOW IS SHARED. test_doc_anchors.py imports `_build` and `_run`
rather than copying them, so both suites drive the same loaded checker the same
way; a second copy would be free to drift.

Fixtures go to a tempdir, never into this repo. Every citation-shaped literal
below names a `probe-` file that exists in no fixture-free tree, so this file
cannot redden the live check on its own text. It is scanned by that check.
"""

import contextlib
import importlib.util
import io
import pathlib
import shutil
import sys
import tempfile

CHECKER_PATH = pathlib.Path(__file__).resolve().parent / 'check_doc_links.py'


def _load_checker():
    """Import the checker by path, since scripts/ is not an importable package."""
    spec = importlib.util.spec_from_file_location('check_doc_links', CHECKER_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CDL = _load_checker()

# Five lines exactly, so 5 is the last valid line and 6 the first invalid one.
# Both edges are asserted below: "the file has N lines" and "line N exists"
# differ by exactly the off-by-one this check is here to get right.
FIVE_LINES = 'one\ntwo\nthree\nfour\nfive\n'


def _build(files: dict) -> pathlib.Path:
    """Write a throwaway repo and return its root."""
    root = pathlib.Path(tempfile.mkdtemp(prefix='doclinks-'))
    for name, body in files.items():
        target = root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(body, bytes):
            target.write_bytes(body)
        else:
            target.write_text(body)
    return root


def _run(files: dict) -> tuple:
    """(exit code, stdout) from one full checker run over a fixture repo."""
    root = _build(files)
    buffer = io.StringIO()
    try:
        with contextlib.redirect_stdout(buffer):
            code = CDL.main(['check_doc_links.py', str(root)])
    finally:
        shutil.rmtree(root, ignore_errors=True)
    return code, buffer.getvalue()


def _cited(comment: str) -> dict:
    """A five-line target plus one shell comment citing it."""
    return {'scripts/probe-target.md': FIVE_LINES,
            'scripts/probe.sh': f'# {comment}\n'}


def _run_beside(files: dict, outside: dict) -> tuple:
    """(exit code, stdout) for a fixture repo with a SIBLING tree beside it.

    The containment rows need a real file the repo does not contain, reachable
    only by climbing above the root. `_build` gives one directory, so this
    builds two: the repo and a sibling the pointers below try to reach.
    """
    parent = pathlib.Path(tempfile.mkdtemp(prefix='doclinks-pair-'))
    for base, group in ((parent / 'repo', files), (parent, outside)):
        for name, body in group.items():
            target = base / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(body)
    buffer = io.StringIO()
    try:
        with contextlib.redirect_stdout(buffer):
            code = CDL.main(['check_doc_links.py', str(parent / 'repo')])
    finally:
        shutil.rmtree(parent, ignore_errors=True)
    return code, buffer.getvalue()


# --- pointers may not resolve outside the repo root ---------------------------


def test_a_citation_that_escapes_the_repo_root_is_never_opened():
    """The oracle this rule closes, measured rather than argued.

    `..` is inside LINE_CITE's path class and the repo root is one of the bases,
    so `../outside/x.py:99` named a real file no checkout contains, and the
    checker opened it and printed its length: an existence-and-length oracle
    plus an unbounded read, reachable by committing a citation.
    """
    code, out = _run_beside(
        {'scripts/probe.sh': '# see ../outside/probe-secret.py:99 for the rule\n'},
        {'outside/probe-secret.py': 'one\ntwo\nthree\n'})
    assert code == 0, out
    assert 'probe-secret' not in out, 'the escaping pointer was still read:\n%s' % out
    assert 'has 3 lines' not in out, 'the file length leaked into a finding:\n%s' % out


def test_a_markdown_link_out_of_the_repo_does_not_resolve():
    """Form 1 is held to the same rule. A link a reader of this repo cannot
    follow is not a link that resolves, whatever sits at the other end."""
    code, out = _run_beside(
        {'docs/note.md': '[gone](../../outside/probe-secret.md)\n'},
        {'outside/probe-secret.md': FIVE_LINES})
    assert code == 1, 'a link out of the repository was accepted:\n%s' % out
    assert 'probe-secret.md' in out, out


def test_a_prose_path_out_of_the_repo_does_not_resolve():
    """Form 2, same rule."""
    code, out = _run_beside(
        {'docs/note.md': 'read `../../outside/probe-secret.md` for the rule\n'},
        {'outside/probe-secret.md': FIVE_LINES})
    assert code == 1, 'a prose path out of the repository was accepted:\n%s' % out


def test_a_dotdot_pointer_that_stays_inside_the_repo_still_resolves():
    """The rule is CONTAINMENT, not a ban on `..`. A sibling reference from a
    subdirectory is ordinary correct prose and has to keep resolving, which is
    why the path is resolved rather than read: a lexical test reddens it.
    """
    files = {'docs/sub/probe-target.md': FIVE_LINES,
             'docs/sub/deep/note.md': 'see [it](../probe-target.md), '
                                      'and `../probe-target.md:5` states it\n'}
    code, out = _run(files)
    assert code == 0, out


def test_the_containment_predicate_is_asserted_directly():
    """Pins the mechanism, not only its outcome. An outcome test would pass if
    some other path dropped the pointer; containment is what must hold.
    """
    root = _build({'docs/probe-target.md': FIVE_LINES})
    try:
        resolver = CDL.build_resolver(root.resolve())
        assert resolver.inside(root / 'docs' / 'probe-target.md')
        assert resolver.inside(root)
        assert not resolver.inside(root / '..' / 'probe-elsewhere.md')
        assert resolver.inside(root / 'docs' / '..' / 'probe-target.md')
    finally:
        shutil.rmtree(root, ignore_errors=True)


# --- the two off-by-one edges -------------------------------------------------


def test_last_line_of_the_file_is_valid():
    code, out = _run(_cited('see probe-target.md:5 for the rule'))
    assert code == 0, out


def test_one_line_past_the_end_is_caught():
    code, out = _run(_cited('see probe-target.md:6 for the rule'))
    assert code == 1, out
    assert 'probe-target.md:6' in out, out


def test_the_finding_names_the_file_and_the_real_line_count():
    _, out = _run(_cited('see probe-target.md:6 for the rule'))
    assert 'scripts/probe-target.md has 5 lines' in out, out
    assert 'scripts/probe.sh:1' in out, out


def test_line_zero_is_caught():
    code, out = _run(_cited('see probe-target.md:0 for the rule'))
    assert code == 1, out
    assert 'no line 0' in out, out
    assert 'has 5 lines' in out, out


# --- ranges -------------------------------------------------------------------


def test_range_inside_the_file_is_valid():
    code, out = _run(_cited('see probe-target.md:1-5 for the rule'))
    assert code == 0, out


def test_range_ending_past_the_file_is_caught():
    code, out = _run(_cited('see probe-target.md:1-6 for the rule'))
    assert code == 1, out
    assert 'has 5 lines' in out, out


# --- the hard-wrap blind spot -------------------------------------------------


def test_wrapped_citation_in_a_shell_comment_is_caught():
    """The shape that actually occurs here: a `#` opens the continuation. Most
    live citations sit in shell comments, so a markdown-only wrap test would go
    green while the real surface stayed uncovered.
    """
    files = {'scripts/sub/probe-tar-get.md': FIVE_LINES,
             'scripts/probe.sh': '# the rule in sub/probe-tar-\n'
                                 '# get.md:6 already states it\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'sub/probe-tar-get.md:6' in out, out


def test_wrapped_citation_is_blamed_on_the_line_it_starts_on():
    files = {'scripts/sub/probe-tar-get.md': FIVE_LINES,
             'scripts/probe.sh': '# filler\n'
                                 '# the rule in sub/probe-tar-\n'
                                 '# get.md:6 already states it\n'}
    _, out = _run(files)
    assert 'scripts/probe.sh:2' in out, out


def test_wrapped_citation_in_markdown_is_caught():
    files = {'docs/probe-tar-get.md': FIVE_LINES,
             'docs/note.md': 'the rule in probe-tar-\nget.md:6 already states it\n'}
    code, out = _run(files)
    assert code == 1, out


def test_a_valid_wrapped_citation_stays_green():
    files = {'scripts/sub/probe-tar-get.md': FIVE_LINES,
             'scripts/probe.sh': '# the rule in sub/probe-tar-\n'
                                 '# get.md:5 already states it\n'}
    code, out = _run(files)
    assert code == 0, out


def test_the_marker_strip_is_what_makes_the_shell_case_work():
    """Pins the mechanism, not just the outcome.

    Without dropping the continuation's `#` the two halves join as
    `sub/probe-tar-#get.md:6`, which matches nothing and is silently missed. The
    outcome tests above would still pass if some other path caught the citation,
    so the unit is asserted directly, through CDL.CITES since form 3 moved.
    """
    got = CDL.CITES.wrapped_cites('# the rule in sub/probe-tar-', '# get.md:6 states it')
    assert [c.pointer for c in got] == ['sub/probe-tar-get.md'], got
    assert [c.last for c in got] == [6], got


def test_a_citation_wholly_on_one_line_is_not_reported_twice():
    got = CDL.CITES.wrapped_cites('# see sub/probe-tar-', '# get.md:6 and probe-other.md:3')
    assert [c.pointer for c in got] == ['sub/probe-tar-get.md'], got


def test_an_accidental_join_across_a_sentence_end_resolves_to_nothing():
    """A prose line ending in `.` joins to the next, and that is fine: the join
    is loose and resolution throws the accidents away. The real shape from
    79-standing-member-invariant.sh, where "first draft." meets a citation.
    """
    files = {'scripts/probe-target.md': FIVE_LINES,
             'scripts/probe.sh': '# not in the first draft.\n'
                                 '# probe-target.md:5 legitimately reads\n'}
    code, out = _run(files)
    assert code == 0, out


# --- reading failures must be loud --------------------------------------------


def test_an_unreadable_cited_file_fails_loudly():
    """A file we cannot read is never a pass: were it one, making a file
    unreadable would silence every citation into it.
    """
    files = {'scripts/probe-broken.json': b'\xff\xfe not valid utf-8\n',
             'scripts/probe.sh': '# see probe-broken.json:1 for the rule\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'could not be read' in out, out
    assert 'UnicodeDecodeError' in out, out


def test_an_unreadable_file_in_the_citation_scan_fails_loudly():
    files = {'scripts/probe-bad.sh': b'# \xff\xfe not valid utf-8\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'unreadable source' in out, out


def test_an_unreadable_file_in_the_markdown_scan_fails_loudly():
    """The half the row above could never reach, and why it is separate.

    A `.sh` fixture is opened only by the citation scan. The pointer scan opens
    `.md` files and had no guard, so a non-UTF-8 markdown file produced a
    traceback rather than a finding. A row whose fixture cannot reach the code
    it names is this check's own defect wearing its badge.
    """
    files = {'docs/probe-bad.md': b'# \xff\xfe not valid utf-8\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'unreadable source' in out, out
    assert 'docs/probe-bad.md' in out, out


# --- staying in this half's lane ----------------------------------------------


def test_a_path_that_resolves_nowhere_is_not_reported_here():
    """Form 2 owns a missing file. Reporting it here would double-print it."""
    code, out = _run({'scripts/probe.sh': '# see probe-nowhere.md:9999 today\n'})
    assert code == 0, out
    assert 'probe-nowhere.md' not in out, out


def test_an_ambiguous_basename_passes_when_any_candidate_is_long_enough():
    """The documented limit of the ambiguity rule, pinned so it stays a choice."""
    files = {'a/probe-same.md': FIVE_LINES,
             'skills/b/probe-same.md': FIVE_LINES + 'six\nseven\n',
             'scripts/probe.sh': '# see probe-same.md:7 for the rule\n'}
    code, out = _run(files)
    assert code == 0, out


def test_a_citation_resolved_through_a_skill_root_is_checked():
    """The branch several live citations depend on, and nothing else covers.
    `references/x.md:N` under scripts/ carries a slash, so the basename index is
    off and no ancestor reaches it; only skill_roots does.
    """
    files = {'skills/x/references/probe-target.md': FIVE_LINES,
             'agents/prompt.md': 'the rule in references/probe-target.md:6 says\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'references/probe-target.md:6' in out, out


def test_a_skill_root_citation_that_is_in_range_stays_green():
    files = {'skills/x/references/probe-target.md': FIVE_LINES,
             'agents/prompt.md': 'the rule in references/probe-target.md:5 says\n'}
    code, out = _run(files)
    assert code == 0, out


def test_a_citation_under_docs_work_is_not_scanned():
    """Archived work-docs are frozen records of what was true then."""
    files = {'docs/probe-target.md': FIVE_LINES,
             'docs/work/old.md': 'see probe-target.md:9999 as it was\n'}
    code, out = _run(files)
    assert code == 0, out


def test_a_stale_citation_into_a_shell_file_is_caught():
    """The scan surface is .sh and .py, not only markdown."""
    files = {'scripts/probe-helpers.sh': FIVE_LINES,
             'scripts/probe.sh': '# see probe-helpers.sh:9 for the contract\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'probe-helpers.sh:9' in out, out


def test_the_pointer_half_still_catches_a_dead_markdown_link():
    """Form 1 is untouched by this wave, and this is the guard that says so."""
    files = {'docs/note.md': '[gone](probe-deleted.md)\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'probe-deleted.md' in out, out


def test_exactly_one_ok_line_is_printed_per_run():
    """00-helpers.sh and validate-dod.sh both document the ok-line gap as a
    count of delegated INVOCATIONS; a second pass here makes that prose wrong
    in two files."""
    _, out = _run(_cited('see probe-target.md:5 for the rule'))
    assert len([ln for ln in out.splitlines() if ln.startswith('  ok   ')]) == 1, out


# --- the content at the cited location, not merely its existence -------------

# Line 1 addresses the loader, line 2 is blank, line 3 is the claim. One target
# reaching all three verdicts is what keeps the row below a discriminator.
VACANCY_TARGET = '#!/usr/bin/env python3\n\nHELPERS = 1\n'


def _points_at(line: int) -> dict:
    """The three-line target plus a comment citing one of its lines."""
    return {'scripts/probe-target.py': VACANCY_TARGET,
            'scripts/probe.sh': f'#  probe-target.py:{line},177  HELPERS + more\n'}


def test_a_citation_naming_a_shebang_or_a_blank_line_is_caught():
    """The reproduction this whole tier was built from.

    Retargeting the live `scripts/tamper_harness.py:38,177` to `:1,177` pointed
    the claim at a shebang and the bar stayed green, existence being the only
    thing ever read. The `,177` matters too: the tail reader steps over it, or
    no verb can follow a multi-line citation.
    """
    shebang, out = _run(_points_at(1))
    blank, blank_out = _run(_points_at(2))
    real, real_out = _run(_points_at(3))
    assert shebang == 1, out
    assert 'blank, a bare marker or a shebang' in out, out
    assert blank == 1, blank_out
    assert real == 0, 'the content line was reddened too:\n%s' % real_out


def test_a_range_holding_one_line_of_content_is_not_vacant():
    """A range claims a block, so one real line inside it is a block that still
    says something. Only a range vacant end to end names nothing at all."""
    files = {'scripts/probe-target.md': 'one\n\n\nfour\n',
             'scripts/probe.sh': '# see probe-target.md:2-4 for the rule\n'}
    assert _run(files)[0] == 0
    files['scripts/probe.sh'] = '# see probe-target.md:2-3 for the rule\n'
    assert _run(files)[0] == 1


def test_the_unpinned_count_rides_on_the_coverage_line():
    """A citation nothing pins is judged for existence and vacancy and no
    further, and says so rather than counting as verified."""
    _, out = _run(_cited('see probe-target.md:5 for the rule'))
    assert '0 pinned' in out, out
    assert '1 unpinned, whose content nothing in the citing text names' in out, out


# --- subset targets, the exemption and the strictness it must not cost -------

DEAD_WORK_POINTER = ('skills/hackify/references/note.md',
                     'see `docs/work/done/2026-08-23-nothing-here.md` for the case\n')


def test_a_dead_docs_work_pointer_is_still_a_finding_where_that_tree_exists():
    """The half the exemption must NOT cost. A tree that ships docs/work can
    prove a pointer into it dead, so it still has to; a green here means the
    exemption became a silencer for the whole directory.
    """
    code, out = _run({DEAD_WORK_POINTER[0]: DEAD_WORK_POINTER[1],
                      'docs/work/done/something-else.md': 'body\n'})
    assert code == 1, 'a dead docs/work pointer passed on a tree that has it:\n%s' % out
    assert '2026-08-23-nothing-here.md' in out, out


def test_the_same_pointer_is_exempt_where_the_tree_ships_no_docs_work():
    """The half the exemption buys, the built runtime trees. dist/claude-code
    ships skills but no docs, so a prose path into docs/work can never resolve
    there; that absence is the subsetting, and the source pass judges it.
    """
    code, out = _run({DEAD_WORK_POINTER[0]: DEAD_WORK_POINTER[1]})
    assert code == 0, 'the subset tree reported a pointer it cannot judge:\n%s' % out
    assert '2026-08-23-nothing-here.md' not in out, out


def test_the_subset_predicate_is_asserted_directly():
    """Structural, not pass-keyed. Same pointer, two trees, opposite verdicts."""
    with_docs = CDL.build_resolver(_build({'docs/work/done/x.md': 'body\n'}))
    without = CDL.build_resolver(_build({'skills/a.md': 'body\n'}))
    pointer = 'docs/work/done/2026-08-23-nothing-here.md'
    assert not with_docs.subset_target(pointer), 'exempted a tree that ships docs/work'
    assert without.subset_target(pointer), 'judged a tree that ships no docs/work'
    assert not without.subset_target('skills/a.md'), 'exempted a path outside SUBSET_DIRS'


def _all_tests() -> list:
    """Every test_ function in this module, in source order."""
    return [value for name, value in sorted(globals().items())
            if name.startswith('test_') and callable(value)]


def main() -> int:
    """Run the suite and report, matching test_audit.py's output shape."""
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

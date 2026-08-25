#!/usr/bin/env python3
"""Unit tests for the line-citation half of check_doc_links.py.

Run: python3 scripts/test_doc_link_lines.py

Form 3 of that checker reads the `:42` in `some/file.md:42` and asks whether
line 42 is really there. This suite covers the cases most likely to regress, and
it drives `main` end to end rather than the internals, because the exit code is
what the validator reads and a helper returning the right list while `main`
returns 0 is a green that means nothing.

Fixtures are written into a tempdir, never into this repo, so the live scan
never walks them. Every citation-shaped literal below names a `probe-` file that
exists in no fixture-free tree, so this file's own text can never turn the live
check red on itself. That is not a nicety: this file is scanned by the very
check it tests.
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

# Five lines exactly, which makes 5 the last valid line and 6 the first invalid
# one. Both edges are asserted below, because "the file has N lines" and "line N
# exists" differ by exactly the off-by-one this check is here to get right.
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
    only by climbing above the repo root. `_build` gives one directory, so this
    builds two: the repo, and a sibling the pointers below try to reach.
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

    `..` is inside LINE_CITE's path class, and the repo root is one of the bases
    a pointer is resolved against, so `../outside/x.py:99` named a real file no
    checkout contains. The checker opened it and printed its length: the finding
    `-> ../outside/probe-secret.py:99, ../outside/probe-secret.py has 3 lines`
    is an existence-and-length oracle for the filesystem around the repo, plus
    an unbounded read, both reachable by committing a citation. The pointer now
    resolves to nothing and the file is never opened.
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
    """The rule is CONTAINMENT, not a ban on `..`.

    A sibling reference written from a subdirectory is ordinary correct prose
    and has to keep resolving. That is the whole reason the check resolves the
    path rather than inspecting its spelling: a lexical `..` test would redden
    this file, which is a guard punishing correct text.
    """
    files = {'docs/sub/probe-target.md': FIVE_LINES,
             'docs/sub/deep/note.md': 'see [it](../probe-target.md), '
                                      'and `../probe-target.md:5` states it\n'}
    code, out = _run(files)
    assert code == 0, out


def test_the_containment_predicate_is_asserted_directly():
    """Pins the mechanism and not only its outcome, the way
    test_the_marker_strip_is_what_makes_the_shell_case_work does for the join.
    An outcome test would still pass if some other path happened to drop the
    pointer, and the containment rule is the thing that must hold.
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
    """The shape that actually occurs here: a `#` opens the continuation.

    25 of this repo's 30 live citations sit in shell comments, so a wrap test
    written only against markdown would go green while the real surface stayed
    uncovered. Line one ends mid-token after a hyphen; line two carries the rest
    behind a comment marker that has to come off before the halves can meet.
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
    outcome tests above would still pass if this were broken and some other path
    happened to catch the citation, so the unit is asserted directly.
    """
    got = CDL.wrapped_cites('# the rule in sub/probe-tar-', '# get.md:6 states it')
    assert [c.pointer for c in got] == ['sub/probe-tar-get.md'], got
    assert [c.last for c in got] == [6], got


def test_a_citation_wholly_on_one_line_is_not_reported_twice():
    got = CDL.wrapped_cites('# see sub/probe-tar-', '# get.md:6 and probe-other.md:3')
    assert [c.pointer for c in got] == ['sub/probe-tar-get.md'], got


def test_an_accidental_join_across_a_sentence_end_resolves_to_nothing():
    """A prose line ending in `.` joins to the next, and that is fine.

    The join is deliberately loose; resolution is what throws the accidents
    away. This is the real shape from 79-standing-member-invariant.sh, where
    "first draft." meets a citation on the following line.
    """
    files = {'scripts/probe-target.md': FIVE_LINES,
             'scripts/probe.sh': '# not in the first draft.\n'
                                 '# probe-target.md:5 legitimately reads\n'}
    code, out = _run(files)
    assert code == 0, out


# --- reading failures must be loud --------------------------------------------


def test_an_unreadable_cited_file_fails_loudly():
    """A file we cannot read is never a pass.

    If it were, making a file unreadable would silence every citation into it,
    which is a check that greens exactly when it has stopped working.
    """
    files = {'scripts/probe-broken.json': b'\xff\xfe not valid utf-8\n',
             'scripts/probe.sh': '# see probe-broken.json:1 for the rule\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'could not be read' in out, out
    assert 'UnicodeDecodeError' in out, out


def test_an_unreadable_scanned_file_fails_loudly():
    files = {'scripts/probe-bad.sh': b'# \xff\xfe not valid utf-8\n'}
    code, out = _run(files)
    assert code == 1, out
    assert 'unreadable source' in out, out


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

    `references/x.md:N` written under scripts/ or agents/ resolves through no
    ancestor directory and carries a slash, so the basename index is off too. It
    reaches its file only through skill_roots. If that branch regressed the live
    tree would print a smaller count and stay green, because the ok line is
    printed and never floored.
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
    count of delegated INVOCATIONS, and a second pass here would make that
    prose wrong in two files this wave may not touch."""
    _, out = _run(_cited('see probe-target.md:5 for the rule'))
    assert len([ln for ln in out.splitlines() if ln.startswith('  ok   ')]) == 1, out




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

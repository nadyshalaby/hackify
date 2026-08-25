#!/usr/bin/env python3
"""Tests for check [97]. python3 scripts/test_ci_suite_coverage.py

Every test here drives the REAL fragment, scripts/validate-dod.d/97-test-suites-reachable.sh,
by sourcing it the way scripts/validate-dod.sh does. Nothing in this file
re-implements the scan. A suite that tested a copy would go green while the
shipped check rotted, which is the defect class this whole sprint is about.

The fragment reads its inputs relative to the working directory (git ls-files,
and .github/workflows/ci.yml), so the negative cases point it at a throwaway git
tree instead of at a test-only environment variable. That is deliberate: an env
hook that swapped the repo-wide scan for one clean fixture would be a fail-open
surface needing a whole test section of its own to defend, and there is no need
for one when a different cwd does the same job with no shipped code path.

The suite is organised around the four ways this check could be worse than
useless rather than merely broken:

  1. IT MISSES THE ORPHAN IT WAS WRITTEN FOR. A test file that no CI step runs
     and no CI-named file imports must redden, for both extensions.
  2. IT FABRICATES. A file reachable only by import is correctly wired, and
     reddening it would punish the structure test_audit.py chose on purpose.
  3. IT GREENS WHILE MEASURING NOTHING. An empty entrypoint set, an empty CI
     command set, a git that could not run, a workflow that could not be read.
  4. ITS PASS LINE CANNOT BE AUDITED. A green with no numbers reads the same
     whether the scan examined every suite in the tree or none of them.
"""

import io
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HELPERS = REPO_ROOT / 'scripts' / 'validate-dod.d' / '00-helpers.sh'
FRAGMENT = REPO_ROOT / 'scripts' / 'validate-dod.d' / '97-test-suites-reachable.sh'
ORCHESTRATOR = REPO_ROOT / 'scripts' / 'validate-dod.sh'
CI_YML = '.github/workflows/ci.yml'

# The pass line, matched as a whole sentence rather than read positionally, for
# the reason scripts/test_token_declarations.py gives at its own OK_LINE: a
# word-index read can drift onto a WRONG number when the wording changes and
# still land above a floor, which is a test passing without measuring what it
# names. Anchored to the shape, a reworded line stops matching and reds instead.
OK_LINE = re.compile(r'ok\s+all (\d+) tracked test suite\(s\) reach CI, '
                     r'(\d+) named directly in (\S+) and '
                     r'(\d+) reached by import from a file it names')

# Enough wired suites in a scratch tree to clear BOTH of the fragment's floors
# (5 entrypoints, 6 command paths) with one to spare, so a planted orphan reds
# on being an orphan rather than on a floor. Raising a floor without raising
# this reds every scratch case and says so in the floor's own words.
SCRATCH_SUITES = 7

SUITE_BODY = '#!/usr/bin/env python3\nprint("ok")\n'


def run_fragment(cwd):
    """Source the shipped fragment the way the orchestrator does, including its
    `set -uo pipefail`, since the status handling inside it is written against
    exactly that. Returns (rc, text)."""
    script = ('set -uo pipefail; FAILED=0; source %s; source %s; exit $FAILED'
              % (HELPERS, FRAGMENT))
    done = subprocess.run(['bash', '-c', script], cwd=str(cwd),
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return done.returncode, done.stdout.decode('utf-8', 'replace')


def write(root, rel, body):
    path = Path(root) / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding='utf-8')
    return path


def git(root, *args):
    subprocess.run(['git'] + list(args), cwd=str(root),
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)


def ci_step(path):
    runner = 'python3' if path.endswith('.py') else 'bash'
    return '      - name: %s\n        run: %s %s\n' % (path, runner, path)


def scratch(steps=()):
    """A throwaway git tree carrying SCRATCH_SUITES wired suites plus whatever
    extra CI steps the caller asks for. Files are staged, never committed: the
    fragment reads git ls-files, which reads the INDEX, so `git add` is the whole
    of what tracking means here and no user identity has to be configured."""
    root = Path(tempfile.mkdtemp(prefix='tsr-check-'))
    git(root, 'init', '-q')
    lines = []
    for n in range(SCRATCH_SUITES):
        rel = 'scripts/test_wired_%d.py' % n
        write(root, rel, SUITE_BODY)
        lines.append(ci_step(rel))
    write(root, CI_YML, 'jobs:\n  validate:\n    steps:\n' + '\n'.join(lines + list(steps)))
    git(root, 'add', '-A')
    return root


def ok_line(out):
    match = OK_LINE.search(out)
    assert match is not None, 'no parseable pass line in:\n%s' % out
    return [int(match.group(i)) for i in (1, 2, 4)]


def tracked_entrypoints():
    """The live tracked entrypoint set, computed here independently of the
    fragment so the pass line's total is checked against a second opinion rather
    than against itself."""
    out = subprocess.check_output(['git', 'ls-files'], cwd=str(REPO_ROOT))
    keep = []
    for line in out.decode('utf-8', 'replace').splitlines():
        base = line.rsplit('/', 1)[-1]
        if not base.startswith('test_') or '.d/' in line:
            continue
        if base.endswith('.py') or base.endswith('.sh'):
            keep.append(line)
    return keep


# --- 1. the orphan it was written for -----------------------------------------

def test_a_planted_python_orphan_reds():
    root = scratch()
    write(root, 'scripts/test_orphan.py', SUITE_BODY)
    git(root, 'add', '-A')
    rc, out = run_fragment(root)
    assert rc != 0, 'the planted orphan printed no failure:\n%s' % out
    assert 'scripts/test_orphan.py is a test suite that no step in' in out, out


def test_a_planted_shell_orphan_reds():
    root = scratch()
    write(root, 'hooks/test_orphan.sh', 'echo ok\n')
    git(root, 'add', '-A')
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'hooks/test_orphan.sh is a test suite that no step in' in out, out


def test_an_orphan_suppresses_the_pass_line_entirely():
    """A green beside a red would let a reader take the count as the verdict."""
    root = scratch()
    write(root, 'scripts/test_orphan.py', SUITE_BODY)
    git(root, 'add', '-A')
    _, out = run_fragment(root)
    assert OK_LINE.search(out) is None, out


def test_an_untracked_orphan_is_not_judged():
    """CI runs the committed tree, so a file no commit carries is a question CI
    never gets asked. The opposite call from [55], which reads untracked files
    because it asks whether a file will SHIP rather than whether CI will run it."""
    root = scratch()
    write(root, 'scripts/test_never_staged.py', SUITE_BODY)
    rc, out = run_fragment(root)
    assert rc == 0, out
    assert 'test_never_staged' not in out, out


# --- 2. it must not fabricate -------------------------------------------------

def test_a_suite_reachable_only_by_import_is_accepted():
    """This is skills/lawkeeper/scripts/test_scoping.py's exact shape, proven
    rather than assumed: no CI step names the imported half, and the step naming
    its importer is the whole of what makes it reachable. A two-clause version of
    this check would redden a file whose split was deliberate."""
    root = scratch([ci_step('scripts/test_importer.py')])
    write(root, 'scripts/test_imported_half.py', SUITE_BODY)
    write(root, 'scripts/test_importer.py', 'import test_imported_half\nprint("ok")\n')
    git(root, 'add', '-A')
    rc, out = run_fragment(root)
    assert rc == 0, out
    assert 'test_imported_half' not in out, out
    total, direct, imported = ok_line(out)
    assert (total, direct, imported) == (SCRATCH_SUITES + 2, SCRATCH_SUITES + 1, 1), out


def test_an_import_from_an_unwired_file_confers_nothing():
    """Clause 2 reads imports out of the files CI NAMES, one hop. An importer
    that is itself an orphan reaches no CI run, so being imported by it is not
    reachability, and BOTH files have to redden. Without this the check could
    walk a chain of orphans and call the far end wired."""
    root = scratch()
    write(root, 'scripts/test_imported_half.py', SUITE_BODY)
    write(root, 'scripts/test_importer.py', 'import test_imported_half\nprint("ok")\n')
    git(root, 'add', '-A')
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'scripts/test_imported_half.py is a test suite' in out, out
    assert 'scripts/test_importer.py is a test suite' in out, out


def test_the_from_form_of_the_import_is_accepted_too():
    root = scratch([ci_step('scripts/test_importer.py')])
    write(root, 'scripts/test_imported_half.py', SUITE_BODY)
    write(root, 'scripts/test_importer.py',
          'from test_imported_half import thing\nprint("ok")\n')
    git(root, 'add', '-A')
    rc, out = run_fragment(root)
    assert rc == 0, out
    total, direct, imported = ok_line(out)
    assert (total, direct, imported) == (SCRATCH_SUITES + 2, SCRATCH_SUITES + 1, 1), out


def test_a_helper_directory_suite_is_out_of_scope():
    """A *.d/ tree holds sourced fragments rather than entrypoints, so a test
    helper living in one is never something CI was meant to name."""
    root = scratch()
    write(root, 'scripts/thing.d/test_helper.sh', 'echo ok\n')
    git(root, 'add', '-A')
    rc, out = run_fragment(root)
    assert rc == 0, out
    assert 'test_helper' not in out, out


def test_the_live_tree_is_clean_now_that_the_two_orphans_are_wired():
    rc, out = run_fragment(REPO_ROOT)
    assert rc == 0, 'the live tree reds:\n%s' % out


# --- 3. it must never green while measuring nothing ---------------------------

def test_an_empty_entrypoint_set_reds_rather_than_passing():
    """The whole point of the floors. With no suites to examine the loop runs
    zero times, and without a floor the fragment prints a confident green over a
    set nothing was ever compared."""
    root = Path(tempfile.mkdtemp(prefix='tsr-check-'))
    git(root, 'init', '-q')
    steps = [ci_step('scripts/run_%d.py' % n) for n in range(SCRATCH_SUITES)]
    write(root, CI_YML, 'jobs:\n    steps:\n' + '\n'.join(steps))
    git(root, 'add', '-A')
    rc, out = run_fragment(root)
    assert rc != 0, 'an empty entrypoint set printed no failure:\n%s' % out
    assert 'discovered only 0 tracked test entrypoint(s) against a floor of' in out, out
    assert OK_LINE.search(out) is None, out


def test_an_empty_ci_command_set_reds_rather_than_passing():
    root = scratch()
    write(root, CI_YML, 'jobs:\n  validate:\n    steps: []\n')
    git(root, 'add', '-A')
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'parsed only 0 command path(s) out of' in out, out
    assert OK_LINE.search(out) is None, out


def test_a_missing_ci_file_reds_and_says_the_scan_never_ran():
    root = scratch()
    (root / CI_YML).unlink()
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'is missing or unreadable, so the suite scan never ran' in out, out
    assert OK_LINE.search(out) is None, out


def test_an_unreadable_ci_file_reds_and_says_the_scan_never_ran():
    """Permission-denied rather than absent. Skipped under a uid that bypasses
    the mode bits, because there the file IS readable and asserting otherwise
    would test the runner rather than the check."""
    if os.geteuid() == 0:
        return
    root = scratch()
    (root / CI_YML).chmod(0o000)
    try:
        rc, out = run_fragment(root)
    finally:
        (root / CI_YML).chmod(0o644)
    assert rc != 0, out
    assert 'the suite scan never ran' in out, out
    assert OK_LINE.search(out) is None, out


def test_a_tree_that_is_not_a_git_repository_reds():
    """Fail closed on tooling. A git that cannot run must never hand back an
    empty set wearing a clean tree's face."""
    root = Path(tempfile.mkdtemp(prefix='tsr-check-'))
    write(root, CI_YML, 'jobs:\n')
    rc, out = run_fragment(root)
    assert rc != 0, 'a non-repository printed no failure:\n%s' % out
    assert 'git ls-files exited' in out, out
    assert OK_LINE.search(out) is None, out


# --- 4. the pass line has to be auditable -------------------------------------

def test_the_pass_line_counts_match_what_was_actually_examined():
    rc, out = run_fragment(REPO_ROOT)
    assert rc == 0, out
    total, direct, imported = ok_line(out)
    expected = tracked_entrypoints()
    assert total == len(expected), (
        'the pass line claims %d suite(s), git ls-files finds %d: %s'
        % (total, len(expected), expected))
    assert direct + imported == total, out
    assert imported >= 1, (
        'no suite counted as import-reachable, yet test_scoping.py is one:\n%s' % out)


def test_the_pass_line_names_the_workflow_it_read():
    _, out = run_fragment(REPO_ROOT)
    match = OK_LINE.search(out)
    assert match is not None, out
    assert match.group(3) == CI_YML, match.group(3)


def test_the_counts_track_a_tree_of_a_known_size():
    """The live tree grows, so its numbers are checked against a second opinion
    above. Here the tree's size is fixed by construction, which pins the counting
    itself rather than the agreement of two counters."""
    rc, out = run_fragment(scratch())
    assert rc == 0, out
    total, direct, imported = ok_line(out)
    assert (total, direct, imported) == (SCRATCH_SUITES, SCRATCH_SUITES, 0), out


# --- 5. the two ex-orphans, and the fragment's own wiring ---------------------

def test_both_sprint_orphans_are_now_named_by_a_ci_step():
    text = io.open(REPO_ROOT / CI_YML, encoding='utf-8').read()
    for suite in ('scripts/test_section_exists.py', 'scripts/test_literal_absent_claims.py'):
        assert 'run: python3 %s' % suite in text, '%s has no CI step' % suite


def test_this_suite_names_itself_in_ci():
    """A reachability guard whose own test suite is its first violation would be
    the joke it sounds like."""
    text = io.open(REPO_ROOT / CI_YML, encoding='utf-8').read()
    assert 'run: python3 scripts/test_ci_suite_coverage.py' in text, text


def test_the_orchestrator_sources_the_fragment_and_names_it_in_the_header():
    """A fragment on disk that nothing sources is a [0] FAIL, and one that is
    sourced without a header row is a [76f] FAIL. Both are asserted here so the
    wiring cannot rot separately from the check."""
    text = ORCHESTRATOR.read_text(encoding='utf-8')
    assert 'source "$DOD_MODULES_DIR/97-test-suites-reachable.sh"' in text
    assert '#   97-test-suites-reachable.sh, check [97],' in text


def _all_tests():
    return [(name, fn) for name, fn in sorted(globals().items())
            if name.startswith('test_') and callable(fn)]


def main():
    failed = []
    for name, fn in _all_tests():
        try:
            fn()
            print('ok   %s' % name)
        except AssertionError as exc:
            failed.append(name)
            print('FAIL %s: %s' % (name, exc))
    print('\n%d passed, %d failed' % (len(_all_tests()) - len(failed), len(failed)))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())

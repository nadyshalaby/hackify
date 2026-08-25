#!/usr/bin/env python3
"""Tests for the measured replay. python3 scripts/test_replay_claim_checks.py

Every test here drives the REAL runner and the REAL fragments. Nothing in this
file re-implements a check or hand-writes what one found, because a hand-written
result is precisely the defect scripts/replay_claim_checks.py was built to
remove from the scoring path.

The suite is organised around the four ways this runner could be worse than
useless rather than merely broken:

  1. IT REPORTS A VERDICT NOBODY MEASURED. Each of the four must_catch findings
     has to come back with the verdict the shipped fragment actually produces,
     and for the reason the fixture pins, which means naming the witness literal
     the check quoted back.
  2. IT EARNS A FALSE WITHOUT RUNNING. An unmapped class, a finding with no
     fixture, an empty set, a fixture pinning no files, a red run naming none of
     the fixture's own files: every one raises here, because a `caught: false`
     that no run produced is indistinguishable in a score from one that did.
  3. IT TAKES ITS COMMAND FROM A DOCUMENT. The fragment paths and replay-root
     variables live in CLASS_CHECKS as source literals. Neither JSON document in
     this mechanism carries one, so a commit to an answer key cannot redirect
     what gets executed.
  4. THE SCORER FAILS OPEN AGAIN. No-arg used to print a full report over an
     empty result set and exit 0. No-arg must now BE the replay, byte for byte,
     and an authored file must announce itself as authored.

M4 gets its own test and its own paragraph. It is the finding the shipped check
does NOT catch, accepted by sprint decision #15-A, and the danger with an
accepted miss is that it quietly stops being measured. So the assertion is not
just that M4 is false: it is that the check ran, printed a measured pass line,
and named none of M4's witness literals while doing it.
"""

import contextlib
import io
import json
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import replay_claim_checks as runner
import score_claim_corpus as scorer
from claim_fixture_manifest import load_manifest
from claim_fixture_types import FixtureSpec, Witness

REPO_ROOT = Path(__file__).resolve().parent.parent
SCORER = 'scripts/score_claim_corpus.py'
RUNNER = 'scripts/replay_claim_checks.py'

# The bash line the fragments are sourced through, and the shell mode inside it.
# Both runners in this repo must use the SAME line, and it must be the one
# scripts/validate-dod.sh sets, or a replay measures a shell the validator does
# not ship. Written out here so a change to either runner reds rather than
# quietly re-measuring everything under different rules.
MODE = 'set -uo pipefail'
SHELL_LINE = "'%s; FAILED=0; source %%s; source %%s; exit $FAILED'" % MODE

# The measured verdicts, recorded so a change in what the shipped checks do reds
# here instead of being absorbed into a moving headline. matched_literal is the
# FIRST witness literal the fragment quoted back, in manifest order, which for I2
# and I4 is the shorter of their two witnesses.
EXPECTED = {
    'I2': (3, True, 'Implementation Log'),
    'M3': (1, True, '{{test_file_path}}'),
    'M4': (0, False, None),
    'I4': (1, True, '4-5 reviewers'),
}

# M4's clean run, quoted from the fragment. This is the evidence that the check
# LOOKED and did not fire, as opposed to never having looked, and it is the only
# thing separating an accepted miss from an unnoticed regression.
M4_PASS_LINE = ('all 0 quoted phrase(s) called unpinned across 3 live file(s) are '
                'genuinely unpinned (1 pinning claim(s) examined)')

_CACHE = []


def report():
    """Replay once, reuse everywhere. The fragments only read, so a second run
    would produce the same bytes at the cost of another four bash processes."""
    if not _CACHE:
        _CACHE.append(runner.replay_all(runner.load_must_catch()))
    return _CACHE[0]


def row(ident):
    results = report()['results']
    assert ident in results, 'the replay never ran %s: %s' % (ident, sorted(results))
    return results[ident]


def spec_for(ident):
    for spec in load_manifest():
        if spec.ident == ident:
            return spec
    raise AssertionError('the fixture manifest carries no %s' % ident)


def run_cli(script, *args):
    """Run one of the two scripts as the user would. Returns (rc, stdout, stderr)."""
    done = subprocess.run([sys.executable, script, *args], cwd=str(REPO_ROOT),
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return (done.returncode, done.stdout.decode('utf-8', 'replace'),
            done.stderr.decode('utf-8', 'replace'))


def caught_because(ident):
    """Assert one finding was caught for the reason its fixture pins."""
    expected_rc, expected_caught, expected_literal = EXPECTED[ident]
    found = row(ident)
    assert found['caught'] is expected_caught, found
    assert found['rc'] == expected_rc, 'rc %d, expected %d' % (found['rc'], expected_rc)
    assert found['matched_literal'] == expected_literal, found['matched_literal']
    assert found['matched_path'] in [f.path for f in spec_for(ident).files], found
    assert expected_literal in found['output'], found['output']


# --- 1. the verdicts the shipped checks actually produce -----------------------

def test_every_must_catch_finding_replays_to_its_measured_verdict():
    """The deliverable, in one table. Every must_catch finding in the corpus is
    replayed through its class's fragment, and the verdict is the one the check
    produced rather than one the corpus, the fixture or this file asserted."""
    results = report()['results']
    assert sorted(results) == sorted(EXPECTED), sorted(results)
    for ident, (rc, caught, literal) in EXPECTED.items():
        found = results[ident]
        assert (found['rc'], found['caught'], found['matched_literal']) == (rc, caught, literal), \
            '%s came back %r' % (ident, (found['rc'], found['caught'], found['matched_literal']))


def test_i2_is_caught_because_the_check_quoted_its_witness_literal():
    """rc alone cannot tell 'red on this finding' from 'red somewhere in these
    files'. The witness literal is what discriminates, and it is fixture data."""
    caught_because('I2')


def test_m3_is_caught_because_the_check_quoted_its_witness_literal():
    caught_because('M3')


def test_i4_is_caught_because_the_check_quoted_its_witness_literal():
    caught_because('I4')


def test_m4_misses_and_the_miss_is_measured_rather_than_assumed():
    """The accepted refusal, proven. Sprint decision #15-A accepted that the
    shipped C7 check does not reach M4, which is why counts.must_catch stays 4
    while must_catch_buildable is 3. An accepted miss is one step from an
    unnoticed one, so this asserts the check RAN: it exited clean, printed its
    measured pass line, and named none of M4's witness literals while doing it."""
    found = row('M4')
    assert found['rc'] == 0, found
    assert found['caught'] is False, found
    assert found['matched_path'] is None, found['matched_path']
    assert found['matched_literal'] is None, found['matched_literal']
    assert M4_PASS_LINE in found['output'], found['output']
    for witness in spec_for('M4').witnesses:
        assert witness.literal not in found['output'], \
            'the output carries %r, so this miss is not the clean run it claims' % witness.literal


# --- 2. a false has to be earned by a run that happened ------------------------

def test_a_class_with_no_entry_in_the_table_raises():
    """I2 has a fixture, so this clears the missing-fixture guard and lands on the
    branch it means. An unmapped class ran no check at all."""
    try:
        runner.replay_all({'I2': 'C99_not_a_class'})
    except runner.UnmappedClassError as exc:
        assert 'C99_not_a_class' in str(exc), exc
        return
    raise AssertionError('an unmapped class scored instead of raising')


def test_a_must_catch_finding_with_no_fixture_raises():
    try:
        runner.replay_all({'ZZ9': 'C6_section_exists'})
    except runner.MissingFixtureError as exc:
        assert 'ZZ9' in str(exc), exc
        return
    raise AssertionError('a finding with no fixture scored instead of raising')


def test_an_empty_finding_set_raises():
    """An empty run reports a confident score over nothing at all, which is the
    exact shape this whole mechanism exists to refuse."""
    try:
        runner.replay_all({})
    except runner.MissingFixtureError:
        return
    raise AssertionError('an empty set scored instead of raising')


def test_a_fixture_that_pins_no_files_raises():
    """No pinned files means no path to match a red run against, so caught could
    only ever come back false. Built from the record type directly, because the
    manifest validator refuses this shape on the way in."""
    spec = FixtureSpec('SYN', 'worktree', 'synthetic', (),
                       (Witness('doc.md', 'present', 'anything'),))
    try:
        runner.replay_one(spec, 'C6_section_exists')
    except runner.MissingFixtureError as exc:
        assert 'SYN' in str(exc), exc
        return
    raise AssertionError('a fixture pinning no files scored instead of raising')


def test_a_red_run_that_names_no_pinned_file_is_refused_rather_than_scored_false():
    """Every fragment's replay hook REFUSES a root that is not a fixture temp dir
    by exiting non-zero. That is a check that never ran, and it looks exactly like
    a catch by return code and exactly like nothing by content. Reading it as a
    miss would record 'never looked' as 'looked and found nothing'."""
    refusal = "SE_REPLAY_ROOT '/etc' is not a fixture temp dir under /var/folders\n"
    try:
        runner.verdict(1, refusal, spec_for('I2'))
    except runner.UnscorableRunError as exc:
        assert 'I2' in str(exc), exc
        return
    raise AssertionError('a red run naming no pinned file was scored instead of raising')


def test_a_red_run_that_names_a_pinned_file_but_no_witness_literal_is_not_caught():
    """The discriminating rule, and the reason rc is not enough on its own. A
    fragment can red about a file the fixture materialised without the failure
    being THIS finding, because a replay scope holds whole files and a check
    reports every site in them. The witness literal is what separates 'red on
    this finding' from 'red somewhere in these files', and it is pure fixture
    data, so nothing on this path is an authored expectation of the answer.

    Measured with a synthetic output rather than a real run, because all four
    live findings happen to red and quote their literal together, so on today's
    corpus the two conditions are indistinguishable. A rule the current data
    cannot separate is exactly the rule that rots unnoticed."""
    spec = spec_for('I2')
    output = 'FAIL %s:900 something else entirely went wrong\n' % spec.files[0].path
    for witness in spec.witnesses:
        assert witness.literal not in output, 'the synthetic output leaked a witness'
    caught, matched_path, matched_literal = runner.verdict(1, output, spec)
    assert caught is False, 'a red run that never named the finding scored as a catch'
    assert matched_path == spec.files[0].path, matched_path
    assert matched_literal is None, matched_literal


def test_a_missing_fragment_is_refused_rather_than_run_green():
    """`source missing.sh` writes to stderr and carries on, leaving FAILED at 0,
    so the run would exit clean and be recorded as a check that found nothing."""
    absent = runner.ClassCheck('scripts/validate-dod.d/00-there-is-no-such-check.sh', 'SE_REPLAY_ROOT')
    try:
        runner.run_fragment(absent, tempfile.gettempdir())
    except runner.UnscorableRunError as exc:
        assert '00-there-is-no-such-check.sh' in str(exc), exc
        return
    raise AssertionError('a missing fragment ran instead of raising')


def test_the_replay_shell_mode_is_the_one_the_validator_ships():
  """The fragments are written against `set -uo pipefail` and were replayed
  without it.

  Several of them read git's or grep's status on its own line rather than off
  the end of a pipe, and say in their comments that this is because pipefail
  reports the RIGHTMOST non-zero status. Running them under a different shell
  mode measures something the orchestrator never runs, and the sprint's headline
  number came out of exactly that run.

  Asserted as SOURCE TEXT on all three sides rather than inferred from a passing
  replay, because a replay under the wrong mode passes too. That is the whole
  reason the gap survived: nothing about the output looked different."""
  runner_src = (REPO_ROOT / RUNNER).read_text(encoding='utf-8')
  harness_src = (REPO_ROOT / 'scripts/tamper_harness.py').read_text(encoding='utf-8')
  orchestrator = (REPO_ROOT / 'scripts/validate-dod.sh').read_text(encoding='utf-8')
  assert SHELL_LINE in runner_src, 'the runner no longer sources under %r' % MODE
  assert SHELL_LINE in harness_src, (
      'the runner and scripts/tamper_harness.py no longer drive the fragments '
      'through the same bash line, so the two disagree about what was measured')
  assert '\n%s\n' % MODE in orchestrator, (
      'scripts/validate-dod.sh no longer sets %r, so the line the two runners '
      'copy is no longer the one that ships' % MODE)


def test_a_red_run_about_the_wrong_thing_is_the_second_shape_of_a_measured_miss():
  """The branch the module docstring used to contradict.

  It said a `caught: false` is only ever produced by a run that happened AND
  CAME BACK CLEAN. verdict() also returns false when rc != 0, a pinned path
  matched, and no witness literal did, which is a run that came back RED. The
  DOCSTRING was the half that changed, because the branch is right and is
  asserted directly above: a red run about the right file is not a red run about
  the right finding, and scoring it as a catch would credit the check with work
  the witnesses say it did not do.

  Behaviour and prose are pinned together here on purpose. Either one alone can
  drift away from the other silently, which is what happened."""
  spec = spec_for('I2')
  output = 'FAIL %s:900 something else entirely went wrong\n' % spec.files[0].path
  caught, matched_path, matched_literal = runner.verdict(1, output, spec)
  assert caught is False and matched_path is not None and matched_literal is None
  doc = ' '.join(runner.__doc__.split())
  assert 'a run that HAPPENED, and there are two shapes of it' in doc, doc
  assert 'never named the thing the finding is about' in doc, doc
  assert 'came back clean' in doc, doc


# --- 3. the command never comes out of a document -----------------------------

def test_every_fragment_in_the_table_exists_on_disk():
    """A table entry pointing at nothing would fail open on the source line."""
    assert runner.CLASS_CHECKS, 'the table is empty'
    for class_name, check in runner.CLASS_CHECKS.items():
        target = REPO_ROOT / check.fragment
        assert target.is_file(), '%s maps to %s, which is not on disk' % (class_name, target)
    helpers = REPO_ROOT / runner.HELPERS
    assert helpers.is_file(), '%s is not on disk' % helpers


def test_no_fragment_path_or_replay_variable_is_reachable_from_a_repo_document():
    """The guardrail, measured rather than argued. Both JSON documents in this
    mechanism are answer keys that the runner is graded against, so if either
    carried a fragment path or a replay-root variable, a commit to a document
    could redirect what gets executed. Neither does, and this reds if that
    changes."""
    documents = ('scripts/claim_corpus.json', 'scripts/claim_fixtures.json')
    for relative in documents:
        text = (REPO_ROOT / relative).read_text(encoding='utf-8')
        for check in runner.CLASS_CHECKS.values():
            assert check.fragment not in text, '%s names %s' % (relative, check.fragment)
            assert check.replay_var not in text, '%s names %s' % (relative, check.replay_var)


def test_the_provenance_names_every_fragment_that_ran():
    """A results object nobody can audit without rerunning it is half a result."""
    provenance = report()['provenance']
    assert provenance['mode'] == 'measured replay', provenance
    assert sorted(provenance['findings_replayed']) == sorted(EXPECTED), provenance
    ran = sorted({runner.CLASS_CHECKS[c].fragment
                  for c in runner.load_must_catch().values()})
    assert provenance['fragments_run'] == ran, provenance['fragments_run']


def test_the_runner_prints_its_report_when_run_standalone():
    rc, out, err = run_cli(RUNNER)
    assert rc == 0, err
    payload = json.loads(out)
    assert sorted(payload['results']) == sorted(EXPECTED), sorted(payload['results'])
    assert payload['results']['M4']['caught'] is False, payload['results']['M4']


# --- 4. the scorer no longer scores what it never read ------------------------

def test_the_scorer_with_no_argument_is_the_replay_rather_than_an_empty_set():
    """The fail-open this task closed. No-arg used to print a full report over an
    empty result set and exit 0. Asserted as byte-for-byte equality with the
    explicit flag, because that proves no-arg IS the replay, where asserting the
    absence of the old wording would also pass on a run that printed nothing."""
    bare_rc, bare_out, bare_err = run_cli(SCORER)
    flag_rc, flag_out, _ = run_cli(SCORER, '--replay')
    assert bare_rc == 0, bare_err
    assert flag_rc == 0
    assert bare_out == flag_out, 'no-arg and --replay printed different reports'
    assert 'default empty result set' not in bare_out, bare_out
    assert 'must_catch caught                    3 of 4' in bare_out, bare_out


def test_the_scorer_replay_says_which_half_of_the_table_it_did_not_measure():
    """The replay only runs must_catch fixtures, so every out_of_class zero is an
    unexamined default. Unsaid, those zeros sit under a line reading 'measured
    replay' and get read as checks that looked and stayed silent, which is the
    same fail-open moved to the other half of the table."""
    rc, out, err = run_cli(SCORER, '--replay')
    assert rc == 0, err
    assert 'NOT MEASURED' in out, out
    assert 'results read from: measured replay' in out, out
    for check in runner.CLASS_CHECKS.values():
        assert check.fragment in out, '%s is not named in the provenance' % check.fragment


def test_a_replay_that_raises_prints_no_score_at_all():
    """A half-measured report is worse than none. If the runner raises, the score
    block must not print, because a reader skimming a transcript for the headline
    number would find one sitting above an error they did not scroll to.

    Driven in process by replacing the runner the scorer imported, which is the
    only way to reach this branch without breaking the fixtures on disk."""
    original = scorer.replay_all
    captured = io.StringIO()
    try:
        scorer.replay_all = _always_raises
        with contextlib.redirect_stdout(captured), contextlib.redirect_stderr(io.StringIO()) as err:
            rc = scorer.main(['score_claim_corpus.py'])
    finally:
        scorer.replay_all = original
    assert rc == scorer.EXIT_REPLAY, 'expected exit %d, got %d' % (scorer.EXIT_REPLAY, rc)
    assert captured.getvalue() == '', 'a failed replay still printed:\n%s' % captured.getvalue()
    assert 'the fragment went missing' in err.getvalue(), err.getvalue()


def _always_raises(*_args, **_kwargs):
    raise runner.UnscorableRunError('the fragment went missing')


def test_the_replay_labels_rows_it_never_examined_instead_of_calling_them_silent():
    """The score block's caveat covers the totals; a reader working down the page
    meets the rows first. The replay only has fixtures for the must_catch half, so
    an out_of_class row saying 'ok, stayed silent' would be a claim that a check
    looked and found nothing, printed nine times under a provenance line reading
    'measured replay'. An authored file scores the whole table, so there the same
    rows keep saying silent, and that half is asserted too so the label cannot
    quietly become unconditional."""
    rc, out, err = run_cli(SCORER, '--replay')
    assert rc == 0, err
    assert 'stayed silent' not in out, out
    assert out.count('not measured by this run') == 9, out

    handle = tempfile.NamedTemporaryFile('w', suffix='.json', delete=False)
    handle.write(json.dumps({'I2': True}))
    handle.close()
    rc, authored, err = run_cli(SCORER, handle.name)
    assert rc == 0, err
    assert 'not measured by this run' not in authored, authored
    assert authored.count('ok, stayed silent') == 9, authored


def test_an_authored_results_file_says_authored_on_its_provenance_line():
    """The file path stays available behind an explicit argument, and a report
    built from one has to announce itself, so a number lifted out of a transcript
    weeks later cannot be mistaken for a measured one."""
    handle = tempfile.NamedTemporaryFile('w', suffix='.json', delete=False)
    handle.write(json.dumps({'I2': True, 'M3': True, 'M4': True, 'I4': True}))
    handle.close()
    rc, out, err = run_cli(SCORER, handle.name)
    assert rc == 0, err
    assert 'AUTHORED' in out, out
    assert 'not measured by running any check' in out, out
    assert 'must_catch caught                    4 of 4' in out, out


def test_the_scorer_still_refuses_results_naming_a_finding_the_corpus_lacks():
    """The unknown-id rejection predates this change and has to survive it."""
    handle = tempfile.NamedTemporaryFile('w', suffix='.json', delete=False)
    handle.write(json.dumps({'NOPE': True}))
    handle.close()
    rc, out, err = run_cli(SCORER, handle.name)
    assert rc == 3, 'expected exit 3, got %d: %s%s' % (rc, out, err)
    assert 'NOPE' in err, err
    assert 'Score' not in out, out


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

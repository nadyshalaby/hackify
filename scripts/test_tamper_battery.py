#!/usr/bin/env python3
"""The tamper battery. python3 scripts/test_tamper_battery.py

This is task T7 of the claim-integrity sprint, and it answers two acceptance
criteria that ask for different things.

AC4 ASKS FOR EVERY CHECK BRANCH TO BE TAMPER-TESTED FAIL-CLOSED, with each row
asserting the EXPECTED FAILURE MESSAGE rather than a non-zero exit. Those rows
live in scripts/test_tamper_fragments.py, one section per fragment, and this file
runs them. The bar is the message because a branch that reds in another branch's
words is a branch nobody can debug, and because the two failures a validator must
never confuse, "the check looked and found the defect" and "the check never ran",
both arrive as a non-zero status.

AC3 ASKS FOR PROOF THAT NOTHING SOURCED FROM A REPO FILE IS EXECUTED. Those rows
live in scripts/test_tamper_hostile.py. That AC was written for a design that was
never built, so its first half has no referent and its second half turned out to
be wrong about the code twice. The measurements are in the hostile suite and the
write-up is in the sprint work-doc under 2026-08-25.

WHAT IS IN THIS FILE. The rows for scripts/replay_claim_checks.py, the scorer's
measuring instrument, plus the collector and the runner. The runner rows sit here
rather than with the fragment rows because they are not about a fragment at all:
they are about what the replay runner does with a fragment's OUTPUT, and the most
interesting result this sprint produced is a run it refuses to score in either
direction.

WHY THE SUITE IS SPLIT ACROSS SEVERAL FILES. The hard cap is 500 lines and the
battery does not fit one file under it, so splitting was the instruction rather
than trimming coverage to fit. NO FILE COUNT IS STATED IN THIS SENTENCE, because
the number moves every time a fragment gains a suite: the rows for check [98] took
a part of their own once scripts/test_tamper_fragments.py was 465 lines against
that cap, and the next fragment will do the same. The row count is printed on the
last line of every run rather than restated here, for the reason check [93] gives
in its own header: a stale count inside the machinery built to catch stale counts
is the defect wearing the uniform. The parts are imported rather than sourced out
of a numbered directory, which is the shape check [97] recognises as reachable: a
suite reached by import from a file CI names is wired, and
skills/lawkeeper/scripts/test_scoping.py is the existing precedent. scripts/tamper_harness.py holds the shared runners and carries
no test of its own, so it is not an entrypoint and needs no wiring.

Standalone, exits non-zero on any failure. Reads the repository and writes only
under its own temporary directories. It mutates nothing tracked, ever: a fragment
is tampered by editing a COPY in a temp file, so there is no restore step and no
checksum to verify afterwards.
"""

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import test_tamper_fragments
import test_tamper_hostile
import test_tamper_ledger_sync
from claim_fixture_manifest import load_manifest
from claim_fixtures import replay_scope
from replay_claim_checks import (ClassCheck, MissingFixtureError, UnscorableRunError,
                                 load_must_catch, run_fragment, verdict)
from tamper_harness import (COUNT_BUMP, RED_CALL, REPO_ROOT, TEMPLATE, apply_edits,
                            clean_scratch, expect, temp_dir)

PARTS = (test_tamper_fragments, test_tamper_hostile, test_tamper_ledger_sync)

HELPERS_REL = 'scripts/validate-dod.d/00-helpers.sh'
SECTION_FRAGMENT = 'scripts/validate-dod.d/94-section-exists.sh'


def _fake_repo_root(*edits):
  """A tree the replay runner can be pointed at, holding a tampered check [94].

  The runner takes repo_root as an argument and resolves the helper script, the
  fragment and the working directory from it, so a copy is all that is needed to
  run a tampered fragment through the REAL scoring path. Kept a sibling of the
  replay scope under the temp prefix and never nested inside it, because the
  fragment's replay hook refuses a root equal to the working directory.

  The work-doc template comes along because check [94] reads it from the working
  directory in replay mode as well as in live mode. It is this check's reference
  data rather than part of the corpus being scanned."""
  root = temp_dir('fake-root-')
  source = REPO_ROOT / SECTION_FRAGMENT
  target = root / SECTION_FRAGMENT
  target.parent.mkdir(parents=True, exist_ok=True)
  target.write_text(apply_edits(source.read_text(encoding='utf-8'), edits),
                    encoding='utf-8')
  (root / HELPERS_REL).write_bytes((REPO_ROOT / HELPERS_REL).read_bytes())
  template = root / TEMPLATE
  template.parent.mkdir(parents=True, exist_ok=True)
  template.write_bytes((REPO_ROOT / TEMPLATE).read_bytes())
  return root


def _i2_spec():
  for spec in load_manifest():
    if spec.ident == 'I2':
      return spec
  raise AssertionError('the fixture manifest carries no I2')


def _replay_tampered(*edits):
  """Run a tampered check [94] over I2's pinned fixture through the real runner."""
  check = ClassCheck(SECTION_FRAGMENT, 'SE_REPLAY_ROOT')
  spec = _i2_spec()
  root = _fake_repo_root(*edits)
  with replay_scope(spec, REPO_ROOT) as scope:
    rc, out = run_fragment(check, scope.root, root)
  return spec, rc, out


# --- the replay runner, and the run it refuses to score ------------------------

def test_a_blinded_red_that_keeps_its_status_is_scored_as_neither_catch_nor_miss():
  """The regression row for the tamper the parent of this task ran by hand.

  Blinding check [94]'s printed red while leaving its status bump alone produces a
  run that exits 3 and names nothing. By return code it looks exactly like a
  catch; by content it looks exactly like a clean miss. The runner refuses both
  readings, and that refusal is the single most load-bearing behaviour in the
  scoring path, because everything else it reports is a number derived from it."""
  spec, rc, out = _replay_tampered((RED_CALL, ':'))
  assert rc == 3, 'expected the status bump to survive, got rc %d:\n%s' % (rc, out)
  try:
    verdict(rc, out, spec)
  except UnscorableRunError as exc:
    assert 'I2 exited 3 without naming any file it pinned' in str(exc), str(exc)
    assert 'cannot be read as a catch or as a miss' in str(exc), str(exc)
    return
  raise AssertionError('a run naming no pinned file was scored:\n%s' % out)


def test_blinding_the_status_bump_as_well_turns_the_catch_into_a_measured_miss():
  """The other half of the same tamper, and the reason the row above matters.

  With both halves blinded the run is silent AND exits 0, which the runner reads
  as a miss. That is the honest reading of it, and it is what drops the sprint
  score. The pair is the whole point: an ambiguous run must raise and a clean run
  must score false, and a scorer that collapsed the two would report the same
  number for a broken check and a working one."""
  spec, rc, out = _replay_tampered((RED_CALL, ':'), (COUNT_BUMP, ':'))
  assert rc == 0, 'expected a silent clean exit, got rc %d:\n%s' % (rc, out)
  caught, matched_path, matched_literal = verdict(rc, out, spec)
  assert caught is False, 'a silent run was scored as a catch'
  assert matched_path is None and matched_literal is None, (matched_path,
                                                            matched_literal)


def test_the_untampered_fragment_still_catches_i2_through_the_same_path():
  """The baseline the two rows above are measured against. Without it a red could
  be the fake repository root rather than the tamper."""
  check = ClassCheck(SECTION_FRAGMENT, 'SE_REPLAY_ROOT')
  spec = _i2_spec()
  root = _fake_repo_root((RED_CALL, RED_CALL))
  with replay_scope(spec, REPO_ROOT) as scope:
    rc, out = run_fragment(check, scope.root, root)
  caught, matched_path, matched_literal = verdict(rc, out, spec)
  assert caught is True, 'the untampered fragment missed I2:\n%s' % out
  assert matched_path and matched_literal, (matched_path, matched_literal)


def test_a_bash_that_cannot_start_is_refused_rather_than_scored():
  """The last of the runner's three unscorable shapes. It builds its environment
  from the current process, so the only way to take the shell away from it is to
  take it away from this one. Restored in a finally, because a row that leaves
  PATH broken breaks every row after it and the failure would look unrelated."""
  saved = os.environ['PATH']
  os.environ['PATH'] = '/nonexistent'
  try:
    run_fragment(ClassCheck(SECTION_FRAGMENT, 'SE_REPLAY_ROOT'), temp_dir('empty-'),
                 REPO_ROOT)
  except UnscorableRunError as exc:
    expect(str(exc), 'could not run bash for %s' % SECTION_FRAGMENT)
    return
  finally:
    os.environ['PATH'] = saved
  raise AssertionError('a shell started with no PATH')


# --- the answer key the runner reads, and every way it can be unreadable -------

def _corpus(body):
  """Write `body` to a throwaway corpus file and return its path."""
  path = temp_dir('corpus-') / 'claim_corpus.json'
  path.write_text(body, encoding='utf-8')
  return path


def _corpus_refused(body, needle):
  """load_must_catch must raise on `body`, in the named words.

  Every branch here is one where the corpus is UNREADABLE rather than empty. The
  distinction is the whole runner: a score computed over a corpus nobody could
  parse is a confident number over nothing, which is what the fixtures, the
  manifest and this loader all raise rather than return."""
  try:
    load_must_catch(_corpus(body))
  except MissingFixtureError as exc:
    expect(str(exc), needle)
    return
  raise AssertionError('the loader accepted %r' % body[:80])


def test_a_corpus_that_is_not_on_disk_is_refused():
  missing = temp_dir('corpus-') / 'claim_corpus.json'
  try:
    load_must_catch(missing)
  except MissingFixtureError as exc:
    expect(str(exc), 'corpus file not found at')
    return
  raise AssertionError('a corpus that is not there was read')


def test_a_corpus_that_will_not_parse_is_refused():
  _corpus_refused('{not json', 'cannot read')


def test_a_corpus_that_is_not_shaped_like_an_answer_key_is_refused():
  _corpus_refused('[]', 'must hold an object carrying a findings list')


def test_a_finding_that_is_not_an_object_is_refused():
  _corpus_refused(json.dumps({'findings': ['I2']}),
                  'carries a finding that is not an object')


def test_a_must_catch_finding_with_no_reaching_class_is_refused():
  """Scoring it would credit the corpus with an examination that never happened,
  because nothing would say which check to run for it."""
  _corpus_refused(json.dumps({'findings': [{'id': 'I2', 'bucket': 'must_catch'}]}),
                  'so nothing says which check to run for it')


def test_a_corpus_with_no_must_catch_findings_is_refused():
  _corpus_refused(json.dumps({'findings': [{'id': 'I2', 'bucket': 'out_of_class'}]}),
                  'a replay over it would report a confident score having run nothing')


# --- this suite is wired into CI ----------------------------------------------

def test_this_suite_names_itself_in_ci():
  """A suite CI never runs is the defect check [97] exists to catch, and this file
  is a tracked test entrypoint the moment it lands. Asserted here rather than by
  staging the file, because staging the real index during a shared session is a
  side effect a test has no business having."""
  text = (REPO_ROOT / '.github' / 'workflows' / 'ci.yml').read_text(encoding='utf-8')
  assert 'scripts/test_tamper_battery.py' in text, 'no CI step runs this suite'


def test_the_imported_parts_are_reachable_the_way_check_97_resolves_them():
  """Check [97] accepts a suite reached by import from a file CI names, and the
  import has to be spelled the way its matcher reads. This asserts the spelling
  rather than trusting it, since a refactor to a relative or aliased import would
  keep this file working and quietly orphan both parts."""
  text = Path(__file__).read_text(encoding='utf-8')
  for part in PARTS:
    assert 'import %s' % part.__name__ in text, part.__name__


def _all_tests():
  """Every row in this file and in each imported part, collected by introspection.

  Deduplicated by name and totalled, because a part that shadowed a name from
  another part would silently take one row out of the run, and a battery quietly
  one row short is the failure it was written to refuse."""
  found = {}
  for namespace in [globals()] + [vars(part) for part in PARTS]:
    for name, fn in namespace.items():
      if name.startswith('test_') and callable(fn):
        assert name not in found, 'two parts both define %s' % name
        found[name] = fn
  return sorted(found.items())


def main():
  failed = []
  rows = _all_tests()
  try:
    for name, fn in rows:
      try:
        fn()
        print('ok   %s' % name)
      except AssertionError as exc:
        failed.append(name)
        print('FAIL %s: %s' % (name, exc))
  finally:
    clean_scratch()
  print('\n%d passed, %d failed' % (len(rows) - len(failed), len(failed)))
  return 1 if failed else 0


if __name__ == '__main__':
  sys.exit(main())

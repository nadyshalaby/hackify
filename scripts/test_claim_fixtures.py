#!/usr/bin/env python3
"""Tests for the claim-fixture replay set. python3 scripts/test_claim_fixtures.py

Covers all four modules from one entry point: claim_fixture_types (records and
exceptions), claim_fixture_git (pins in, bytes out), claim_fixture_manifest
(validation rules) and claim_fixtures (replay, verification, CLI). One suite
rather than four because every test here exercises a path that crosses at least
two of them, and splitting it would mostly duplicate the manifest fixtures.

The suite is organised around the four things that would make the fixture
mechanism worse than useless rather than merely broken:

  1. A REPLAY THAT SILENTLY PRODUCES NOTHING. A missing or renamed path, an
     unreadable blob, a file that materialises empty. Every one of those reads
     exactly like "the defect is absent", which is the wrong answer this whole
     sprint exists to stop. Tested by asserting each one RAISES.
  2. A PIN THAT IS NOT A PIN. A malformed sha, a tree instead of a blob, an
     abbreviated commit, a number frozen against content that is free to move.
  3. CLEANUP THAT REACHES TOO FAR. The worktree scope yields the repository root,
     so a cleanup path with the wrong guard deletes the repo.
  4. A LITERAL THAT IS NOT LITERAL. If manifest text ever reached a regex engine
     or a shell, editing a doc would become code execution.
"""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# Imported from the module that OWNS each name, never re-exported through
# claim_fixtures. The four-module split is only worth having if the seams are real,
# and an import list that pulls everything from one façade hides which module owns
# what the moment somebody moves a function.
from claim_fixture_git import (REPO_ROOT, blob_sha_of, is_sha, read_blob,
                               resolve_historical_blob)
from claim_fixture_manifest import load_manifest
from claim_fixture_types import (BlobPinError, HistoricalPathError, ManifestError,
                                 WitnessError)
from claim_fixtures import (check_provenance, check_witnesses, count_literal,
                            literal_lines, replay_scope, verify)

# Pins this suite asserts against directly. Each was measured with git, not copied
# from prose, and each is a content hash, so none of them can drift.
I2_BLOB = 'a4b2960d294290c037ce8bc29261690398cc5843'
M3_BLOB = '16a167089b89773632ae96700c40c05420be7eb1'
FIX_COMMIT = '6495b2b23450d5257e999716d15a00565888f44f'
RENAMED_AWAY = 'agents/wave-task-implementer.md'
STILL_THERE = 'agents/wave-implementer.md'
ABSENT_BLOB = '0' * 40


def _specs():
  """The real manifest, parsed. Every test that touches it treats it as read-only."""
  return load_manifest()


def _by_id(ident):
  for spec in _specs():
    if spec.ident == ident:
      return spec
  raise AssertionError('the manifest carries no fixture %s' % ident)


def _write_manifest(fixtures):
  """A throwaway manifest for the rejection cases, in a temp file, never the repo."""
  handle = tempfile.NamedTemporaryFile('w', suffix='.json', delete=False)
  json.dump({'schema_version': 1, 'fixtures': fixtures}, handle)
  handle.close()
  return Path(handle.name)


def _rejects(fixtures, fragment):
  """Assert load_manifest refuses this manifest, and says why in a readable way."""
  path = _write_manifest(fixtures)
  try:
    load_manifest(path)
  except ManifestError as exc:
    assert fragment in str(exc), 'wanted %r in the refusal, got: %s' % (fragment, exc)
    return
  finally:
    path.unlink()
  raise AssertionError('load_manifest accepted a manifest it should have refused')


def _blob_fixture(**overrides):
  """A minimal valid blobs fixture, so each rejection test changes exactly one thing."""
  entry = {
      'id': 'X1', 'kind': 'blobs',
      'scored_as': 'a site, named as the corpus requires',
      'files': [{'path': 'a.md', 'blob': I2_BLOB, 'size': 13032, 'commit': FIX_COMMIT}],
      'witnesses': [{'path': 'a.md', 'polarity': 'present', 'literal': 'Implementation Log'}],
  }
  entry.update(overrides)
  return [entry]


# --- 1. the real manifest actually replays ------------------------------------

def test_every_fixture_materialises_and_holds_its_defect():
  failures = verify(_specs())
  assert failures == [], 'fixtures do not hold their defects: %s' % failures


def test_the_three_fixed_findings_are_pinned_and_the_live_one_is_not():
  kinds = {spec.ident: spec.kind for spec in _specs()}
  assert kinds == {'I2': 'blobs', 'M3': 'blobs', 'M4': 'blobs', 'I4': 'worktree'}


def test_i2_replays_the_filed_site_at_line_34():
  spec = _by_id('I2')
  with replay_scope(spec) as scope:
    data = (scope.root / 'skills/hackify/references/implement-and-test.md').read_bytes()
  assert literal_lines(data, 'Implementation Log') == [34, 57, 223]
  assert count_literal(data, 'Append one Implementation Log entry per landed task.') == 1


def test_m3_replays_a_token_used_at_55_and_undeclared_at_37():
  spec = _by_id('M3')
  with replay_scope(spec) as scope:
    data = (scope.root / STILL_THERE).read_bytes()
  assert literal_lines(data, '{{test_file_path}}') == [55]
  assert literal_lines(data, '**INPUTS**.') == [37]


def test_m4_replays_a_claim_plus_both_files_that_falsify_it():
  spec = _by_id('M4')
  with replay_scope(spec) as scope:
    claim = (scope.root / 'CHANGELOG.md').read_bytes()
    quick = (scope.root / 'skills/quick/SKILL.md').read_bytes()
    yolo = (scope.root / 'skills/yolo/SKILL.md').read_bytes()
  # The full sentence, not a short prefix of it: 'the two mode skills' alone lands on
  # lines 20 and 27, and a witness that matches a neighbour is not pinning the claim.
  assert literal_lines(claim, 'across the template, its agent mirror, the Phase 5 '
                              'protocol and the two mode skills') == [20]
  assert count_literal(quick, 'task_file_index') == 0
  assert count_literal(yolo, 'task_file_index') == 0
  assert len(quick) == 18970 and len(yolo) == 17267, 'a zero here would be the false zero'


def test_provenance_still_resolves_from_the_commits_the_manifest_claims():
  for spec in _specs():
    assert check_provenance(spec) == [], 'a pin drifted from its recorded origin'


# --- 2. the no-fixture-needed path is first class -----------------------------

def test_i4_scores_against_the_worktree_with_no_temp_dir():
  spec = _by_id('I4')
  with replay_scope(spec) as scope:
    assert scope.kind == 'worktree'
    assert scope.root == REPO_ROOT
    assert check_witnesses(scope, spec) == []


def test_the_worktree_scope_survives_its_own_cleanup():
  """The highest-severity bug available here: cleanup gated on anything other than
  'I made this temp dir myself' deletes the repository on the worktree path."""
  spec = _by_id('I4')
  with replay_scope(spec) as scope:
    root = scope.root
  assert root.is_dir(), 'the worktree scope deleted the repository root'
  assert (root / 'scripts' / 'claim_fixtures.py').is_file()
  assert (root / 'scripts' / 'claim_corpus.json').is_file()


def test_a_blob_scope_is_a_temp_dir_and_is_removed_afterwards():
  spec = _by_id('M4')
  with replay_scope(spec) as scope:
    root = scope.root
    assert root.is_dir() and len(scope.paths) == 3
    assert REPO_ROOT not in root.parents and root != REPO_ROOT, 'materialised in the worktree'
  assert not root.exists(), 'the temp dir outlived its scope'


# --- 3. a missing or renamed path fails loudly --------------------------------

def test_a_renamed_path_raises_instead_of_returning_nothing():
  """The trap. agents/wave-task-implementer.md was renamed at 58c1118, so at this
  later commit the old name resolves to nothing at all, and nothing is not empty."""
  try:
    resolve_historical_blob(FIX_COMMIT, RENAMED_AWAY)
  except HistoricalPathError as exc:
    assert 'does not resolve' in str(exc)
    return
  raise AssertionError('a renamed path resolved instead of raising')


def test_the_renamed_path_really_would_have_read_as_a_clean_zero():
  """Proves the trap is real rather than hypothetical: piping the same request
  through git and counting gives 0 hits, which is exactly what 'fixed' looks like."""
  done = subprocess.run(['git', '-C', str(REPO_ROOT), 'cat-file', 'blob',
                         '%s:%s' % (FIX_COMMIT, RENAMED_AWAY)],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
  assert done.stdout == b'', 'expected the empty stdout that reads like a clean scan'
  assert count_literal(done.stdout, '{{test_file_path}}') == 0
  assert resolve_historical_blob(FIX_COMMIT, STILL_THERE) == M3_BLOB


def test_a_path_missing_at_a_commit_raises():
  try:
    resolve_historical_blob(FIX_COMMIT, 'no/such/file.md')
  except HistoricalPathError:
    return
  raise AssertionError('a missing path resolved instead of raising')


def test_an_abbreviated_commit_is_refused_as_a_pin():
  try:
    resolve_historical_blob(FIX_COMMIT[:7], STILL_THERE)
  except HistoricalPathError as exc:
    assert 'not a full 40-char' in str(exc)
    return
  raise AssertionError('an abbreviated commit was accepted as a pin')


def test_rev_parse_echoing_its_own_argument_is_not_mistaken_for_a_sha():
  """Plain `git rev-parse` prints its argument back on stdout when it fails, so the
  resolver shape-checks the result rather than trusting the return code alone."""
  done = subprocess.run(['git', '-C', str(REPO_ROOT), 'rev-parse',
                         '%s:%s' % (FIX_COMMIT, RENAMED_AWAY)],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
  echoed = done.stdout.decode().strip()
  assert echoed and not is_sha(echoed), 'expected a non-sha echo, got %r' % echoed


# --- 4. a bad pin is refused --------------------------------------------------

def _read_blob_rejects(sha, fragment):
  try:
    read_blob(sha)
  except BlobPinError as exc:
    assert fragment in str(exc), 'wanted %r in the refusal, got: %s' % (fragment, exc)
    return
  raise AssertionError('read_blob accepted the pin %r' % (sha,))


def test_a_malformed_sha_is_refused():
  for bad in ('', 'deadbeef', I2_BLOB.upper(), I2_BLOB + '0', I2_BLOB[:-1] + 'z', None, 42):
    _read_blob_rejects(bad, 'not a 40-char lowercase hex sha')


def test_a_tree_is_refused_because_only_a_blob_pins_content():
  done = subprocess.run(['git', '-C', str(REPO_ROOT), 'rev-parse', 'HEAD^{tree}'],
                        stdout=subprocess.PIPE, check=True)
  _read_blob_rejects(done.stdout.decode().strip(), 'is a tree, not a blob')


def test_a_well_formed_sha_naming_no_object_is_refused():
  _read_blob_rejects(ABSENT_BLOB, 'cannot read object')


def test_a_good_blob_reads_back_to_its_own_hash():
  data = read_blob(I2_BLOB)
  assert blob_sha_of(data) == I2_BLOB and len(data) == 13032


def test_a_wrong_size_is_caught_even_though_the_hash_would_pass():
  """Size is the second, independent proof. It is what an absent-polarity witness
  cannot supply for itself, because absent passes against an empty file."""
  fixtures = _blob_fixture()
  fixtures[0]['files'][0]['size'] = 999
  path = _write_manifest(fixtures)
  try:
    spec = load_manifest(path)[0]
    with replay_scope(spec):
      raise AssertionError('a wrong size materialised without complaint')
  except BlobPinError as exc:
    assert 'the manifest pins 999' in str(exc)
  finally:
    path.unlink()


# --- 5. manifest rules --------------------------------------------------------

def test_a_worktree_witness_may_not_freeze_a_line_or_a_count():
  for numeric in ({'lines': [1]}, {'count': 1}):
    witness = {'path': 'a.md', 'polarity': 'present', 'literal': 'x'}
    witness.update(numeric)
    _rejects([{'id': 'X1', 'kind': 'worktree', 'scored_as': 'somewhere',
               'witnesses': [witness]}], 'against worktree content')


def test_a_pinned_file_without_a_size_is_refused():
  fixtures = _blob_fixture()
  del fixtures[0]['files'][0]['size']
  _rejects(fixtures, 'must record a byte size')


def test_a_path_escaping_the_scope_is_refused():
  for escape in ('../evil.md', '/etc/passwd', 'a/../../evil.md'):
    fixtures = _blob_fixture()
    fixtures[0]['files'][0]['path'] = escape
    fixtures[0]['witnesses'][0]['path'] = escape
    _rejects(fixtures, 'escapes the replay scope')


def test_a_fixture_that_does_not_say_what_it_scores_is_refused():
  fixtures = _blob_fixture()
  fixtures[0]['scored_as'] = '   '
  _rejects(fixtures, 'which site it scores')


def test_a_witness_on_an_unpinned_path_is_refused():
  fixtures = _blob_fixture()
  fixtures[0]['witnesses'][0]['path'] = 'b.md'
  _rejects(fixtures, 'which it does not pin')


def test_a_worktree_fixture_may_not_pin_files():
  fixtures = _blob_fixture(kind='worktree')
  _rejects(fixtures, 'must pin no files')


def test_a_blobs_fixture_with_no_files_is_refused():
  _rejects(_blob_fixture(files=[]), 'pins no files')


def test_a_fixture_with_no_witnesses_is_refused():
  _rejects(_blob_fixture(witnesses=[]), 'carries no witnesses')


def test_an_unknown_kind_is_refused():
  _rejects(_blob_fixture(kind='snapshot'), 'expected one of')


def test_a_duplicate_id_is_refused():
  _rejects(_blob_fixture() + _blob_fixture(), 'appears more than once')


def test_a_duplicate_path_is_refused():
  fixtures = _blob_fixture()
  fixtures[0]['files'].append(dict(fixtures[0]['files'][0]))
  _rejects(fixtures, 'twice')


def test_an_unknown_polarity_is_refused():
  fixtures = _blob_fixture()
  fixtures[0]['witnesses'][0]['polarity'] = 'maybe'
  _rejects(fixtures, 'expected one of')


# --- 6. literals stay literal -------------------------------------------------

def test_a_literal_with_regex_metacharacters_matches_only_itself():
  """If manifest text ever reached a regex engine, editing a doc would become code
  execution. `a.c` matching `abc` is the first symptom that it did."""
  assert count_literal(b'abc a.c abc', 'a.c') == 1
  assert count_literal(b'abc', 'a.c') == 0
  assert count_literal(b'aaa', '.*') == 0
  assert count_literal(b'x $(rm -rf /) y', '$(rm -rf /)') == 1


def test_matching_is_byte_wise_and_survives_odd_encodings():
  data = 'naïve café\nplain\n'.encode('utf-8')
  assert count_literal(data, 'café') == 1
  assert literal_lines(data, 'plain') == [2]
  assert count_literal(b'\xff\xfe raw bytes', 'raw bytes') == 1


def test_an_empty_literal_is_refused_rather_than_matching_everywhere():
  try:
    count_literal(b'anything', '')
  except WitnessError:
    return
  raise AssertionError('an empty literal was accepted')


def test_a_witness_on_a_file_the_scope_lacks_is_a_failure_not_a_silent_zero():
  """This is the only test that MUTATES a scope, so it proves it is standing in a
  temp dir before it deletes anything. Without that guard, flipping M4 to kind
  worktree in the manifest would turn this line into `rm CHANGELOG.md` against the
  repository. Cleanup is not the only path that can reach the worktree root."""
  spec = _by_id('M4')
  with replay_scope(spec) as scope:
    assert spec.kind == 'blobs', 'refusing to mutate a scope that is not a temp dir'
    assert scope.root != REPO_ROOT and REPO_ROOT not in scope.root.parents
    (scope.root / 'CHANGELOG.md').unlink()
    failures = check_witnesses(scope, spec)
  assert any('is not in the replay scope' in line for line in failures)


def test_each_module_imports_standalone_so_the_split_has_no_cycles():
  """The four-module split is only safe if the dependency graph stays a fan-in.
  Importing each module first, in a fresh interpreter, is the cheapest proof that
  none of them needs a sibling to be loaded before it."""
  for module in ('claim_fixture_types', 'claim_fixture_git',
                 'claim_fixture_manifest', 'claim_fixtures'):
    done = subprocess.run([sys.executable, '-c', 'import %s' % module],
                          cwd=str(Path(__file__).resolve().parent),
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    assert done.returncode == 0, '%s does not import alone: %s' % (module, done.stderr)


def test_no_module_in_the_set_imports_re():
  """A regex built from manifest data would turn editing a doc into code execution.
  The cheapest guard against drifting there is to keep `re` out of the package, so
  no later edit can reach for it without deliberately adding the import first."""
  here = Path(__file__).resolve().parent
  for name in ('claim_fixture_types', 'claim_fixture_git',
               'claim_fixture_manifest', 'claim_fixtures'):
    text = (here / ('%s.py' % name)).read_text(encoding='utf-8')
    for line in text.splitlines():
      stripped = line.strip()
      assert stripped != 'import re' and not stripped.startswith('import re,'), \
          '%s imports re' % name
      assert not stripped.startswith('from re import'), '%s imports from re' % name


def _all_tests():
  return [(name, fn) for name, fn in sorted(globals().items())
          if name.startswith('test_') and callable(fn)]


def main():
  """Run every test, report, and exit non-zero on the first sign of trouble."""
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

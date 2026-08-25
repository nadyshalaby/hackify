#!/usr/bin/env python3
"""AC3 hostile-argument rows. Imported and run by scripts/test_tamper_battery.py.

AC3 ASKS FOR SOMETHING THAT IS ONLY HALF THERE, AND SAYING SO IS PART OF THE JOB.
Its clause (a) asks for a fixed verb enum shown in code. There is no verb, no enum
and no annotation anywhere in this sprint: the class that would have introduced
them was task T4 and T4 was declined, with its reasoning recorded in the backlog.
Clause (a) has no referent, and inventing one so it could pass would be the exact
move this sprint exists to stop. The write-up is in the work-doc under 2026-08-25.

SO THESE ROWS GO AFTER THE DATA PATHS THAT ACTUALLY EXIST. Every place a value
read out of a repository file reaches a check:

  scripts/claim_fixtures.json    files[].path, files[].blob, files[].commit,
                                 witnesses[].literal, witnesses[].path
  scripts/claim_corpus.json      reaching_class, a dict key into CLASS_CHECKS
  .github/workflows/ci.yml       the run: command paths check [97] parses and opens
  any scanned file body          text that becomes a value [91], [93], [94] and
                                 [95] compare, cite, or print

Each one is fed the hostile set AC3 names: traversal, an absolute path, three glob
forms, command substitution in both spellings, and a pattern that is catastrophic
to backtrack. Each row proves the value was REJECTED, or was used as a literal and
nothing happened. "Nothing happened" is measured rather than asserted: every
hostile string is built around a canary path that only a real execution could
bring into being, and the row checks that path afterwards.

TWO OF AC3's OWN CLAIMS ABOUT THE CODE TURNED OUT TO BE FALSE, and two rows below
are the measurements. It says a path "must resolve inside the repo and be
git-tracked". No path on any of these routes is checked for either property. A
fixture path is checked for escaping the scope and nothing else; the workflow
parser in check [97] will open a file outside the repository and use its contents.
Neither is a code-execution hole, and both are recorded rather than fixed, since
fixing them is outside this task's file allowlist.
"""

import json
import subprocess

import test_ci_suite_coverage as ci_cov
from claim_fixture_git import REPO_ROOT
from claim_fixture_manifest import load_manifest
from claim_fixture_types import ManifestError
from claim_fixtures import count_literal, replay_scope
from replay_claim_checks import UnmappedClassError, check_for
from tamper_harness import (canary, declaration_tree, expect, hostile_values, run_check,
                            run_check_replay, temp_dir, write)

TICK = chr(96)
FABRICATED_ID = 'check [%s]' % '999'
RETIRED_LABEL = 'Implementation' + chr(32) + 'Log'
PINNING_CLAIM = 'not ' + 'pinned'


def _git_out(*args):
  """One git read, argv list, no shell. Values are measured rather than typed."""
  return subprocess.check_output(['git', '-C', str(REPO_ROOT)] + list(args)).decode(
      'utf-8').strip()


def _baseline():
  """A fixture entry that loads and materialises cleanly. Rows mutate one field.

  The pins are read from the live repository so this file carries no hand-typed
  sha, which is the provenance rule the fixture mechanism itself is built on."""
  blob = _git_out('rev-parse', 'HEAD:README.md')
  return {'id': 'X', 'kind': 'blobs', 'scored_as': 'the AC3 hostile-argument probe',
          'files': [{'path': 'README.md', 'blob': blob,
                     'size': int(_git_out('cat-file', '-s', blob)),
                     'commit': _git_out('rev-parse', 'HEAD')}],
          'witnesses': [{'path': 'README.md', 'polarity': 'present',
                         'literal': 'hackify'}]}


def _load(entry):
  """Write one entry to a throwaway manifest and load it through the validator."""
  path = temp_dir('hostile-manifest-') / 'claim_fixtures.json'
  path.write_text(json.dumps({'fixtures': [entry]}), encoding='utf-8')
  return load_manifest(path)


def _refused(entry, needle):
  """Load `entry` and require the validator to refuse it in the named words."""
  try:
    _load(entry)
  except ManifestError as exc:
    expect(str(exc), needle)
    return
  raise AssertionError('the manifest accepted %r' % entry)


def _materialise_path(value):
  """Pin one hostile path, materialise it, and report what landed on disk."""
  entry = _baseline()
  entry['files'][0]['path'] = value
  entry['witnesses'][0]['path'] = value
  with replay_scope(_load(entry)[0], REPO_ROOT) as scope:
    written = sorted(p.relative_to(scope.root).as_posix()
                     for p in scope.root.rglob('*') if p.is_file())
    return written, (scope.root / value).is_file()


# --- claim_fixtures.json, files[].path ----------------------------------------

def test_a_pinned_path_that_is_absolute_is_refused_before_anything_is_written():
  entry = _baseline()
  entry['files'][0]['path'] = hostile_values('unused')['absolute']
  _refused(entry, 'which escapes the replay scope')


def test_a_pinned_path_that_walks_out_of_the_scope_is_refused():
  entry = _baseline()
  entry['files'][0]['path'] = hostile_values('unused')['traversal']
  _refused(entry, 'A pinned path is repo-relative and stays inside the temp dir')


def test_a_pinned_path_carrying_command_substitution_becomes_a_filename():
  """Accepted, not rejected, and that is the honest result. The value is joined
  onto a temp directory by pathlib and written with write_bytes, so it can only
  ever be a name. The canary is what turns that from an argument into a proof."""
  mark = canary()
  value = hostile_values(mark)['substitution']
  written, landed = _materialise_path(value)
  assert landed, 'the literal path did not materialise: %s' % written
  assert not mark.exists(), 'the substitution ran and created %s' % mark


def test_a_pinned_path_carrying_a_backtick_becomes_a_filename():
  mark = canary()
  written, landed = _materialise_path(hostile_values(mark)['backtick'])
  assert landed, written
  assert not mark.exists(), 'the backtick form ran and created %s' % mark


def test_a_pinned_path_that_is_a_glob_is_written_as_one_literal_name():
  """Three glob forms, one file each. A wildcard that had been expanded anywhere
  on this route would have produced a different count or a different name."""
  for form in ('glob_star', 'glob_question', 'glob_class'):
    value = hostile_values('unused')[form]
    written, landed = _materialise_path(value)
    assert landed and written == [value], (form, written)


def test_a_pinned_path_that_is_a_redos_pattern_is_written_as_one_literal_name():
  value = hostile_values('unused')['redos']
  written, landed = _materialise_path(value)
  assert landed and written == [value], written


# --- claim_fixtures.json, files[].blob and files[].commit ---------------------

def test_every_hostile_blob_pin_is_refused_before_git_is_asked_anything():
  """The shape gate is a set-membership test over hex digits with no regex in the
  module at all, so no hostile spelling reaches a git call or a pattern compiler."""
  mark = canary()
  for value in hostile_values(mark).values():
    entry = _baseline()
    entry['files'][0]['blob'] = value
    _refused(entry, 'which is not a 40-char lowercase hex blob sha')
  assert not mark.exists(), 'a blob pin was executed'


def test_every_hostile_commit_pin_is_refused_before_git_is_asked_anything():
  mark = canary()
  for value in hostile_values(mark).values():
    entry = _baseline()
    entry['files'][0]['commit'] = value
    _refused(entry, 'which is not a full 40-char sha')
  assert not mark.exists(), 'a commit pin was executed'


# --- claim_fixtures.json, witnesses[] -----------------------------------------

def test_a_witness_literal_that_is_a_redos_pattern_is_counted_as_plain_bytes():
  """A pattern is only catastrophic if something compiles it. count_literal
  encodes and calls bytes.count, so the same input that would hang a backtracking
  engine is a two-occurrence answer over four thousand characters of filler."""
  filler = b'a' * 4000
  data = b'head (a+)+$ middle ' + filler + b' (a+)+$ tail'
  assert count_literal(data, '(a+)+$') == 2


def test_a_witness_literal_that_is_a_glob_counts_only_itself():
  assert count_literal(b'a*b*c', '*') == 2
  assert count_literal(b'abc', '*') == 0
  assert count_literal(b'abc', '?') == 0


def test_a_witness_naming_a_file_its_fixture_does_not_pin_is_refused():
  entry = _baseline()
  entry['witnesses'][0]['path'] = hostile_values('unused')['traversal']
  _refused(entry, 'which it does not pin, and a check can only read what the '
           'replay materialises')


# --- claim_corpus.json, reaching_class ----------------------------------------

def test_a_hostile_reaching_class_is_refused_and_echoed_rather_than_run():
  """The class string is a dict key into a table of source literals and is never
  anything else. The refusal quotes it back, which is the proof it stayed text."""
  mark = canary()
  hostile = hostile_values(mark)['substitution']
  try:
    check_for(hostile)
  except UnmappedClassError as exc:
    expect(str(exc), hostile, 'has no fragment in CLASS_CHECKS')
    assert not mark.exists(), 'the class string was executed'
    return
  raise AssertionError('an unmapped class was resolved')


# --- .github/workflows/ci.yml, the paths check [97] parses and opens ----------

def test_a_hostile_ci_command_never_becomes_a_shell_word():
  """Every hostile spelling is filtered out by the path grammar before it reaches
  the file tests below it, so the scan reads the same seven wired suites it would
  have read without them and the workflow stays green."""
  mark = canary()
  hostile = hostile_values(mark)
  root = ci_cov.scratch()
  workflow = root / '.github' / 'workflows' / 'ci.yml'
  extra = ''.join('\n      - name: probe %s\n        run: python3 %s.py\n' % (key, value)
                  for key, value in hostile.items() if key != 'absolute')
  workflow.write_text(workflow.read_text(encoding='utf-8') + extra, encoding='utf-8')
  ci_cov.git(root, 'add', '-A')
  rc, out = run_check('97', cwd=root)
  assert rc == 0, out
  assert ci_cov.ok_line(out) == [ci_cov.SCRATCH_SUITES, ci_cov.SCRATCH_SUITES, 0], out
  assert not mark.exists(), 'a workflow command was executed'


def test_check_97_opens_a_workflow_path_that_escapes_the_repository():
  """AC3's clause (b) says a path must resolve inside the repo and be git-tracked.
  Neither holds here, and this row measures it rather than reasoning about it.

  The path grammar admits both dots and slashes, so a run: line naming ../ reaches
  outside the tree, and the import clause then opens that file and trusts what it
  says. The file planted below is outside the scratch repository and is tracked by
  no git anywhere, and its contents are still what makes an orphaned suite read as
  wired. Nothing is executed, so this is a read rather than a hole, and it is
  recorded here because the acceptance criterion asserts a guard that is not
  written."""
  root = ci_cov.scratch()
  outside = temp_dir('outside-')
  (outside / 'probe.sh').write_text('# import test_lonely\n', encoding='utf-8')
  workflow = root / '.github' / 'workflows' / 'ci.yml'
  workflow.write_text(workflow.read_text(encoding='utf-8')
                      + '\n      - name: outside\n        run: bash ../%s/probe.sh\n'
                      % outside.name, encoding='utf-8')
  write(root, 'scripts/test_lonely.py', 'print("ok")\n')
  ci_cov.git(root, 'add', '-A')
  rc, out = run_check('97', cwd=root)
  assert rc == 0, 'the outside file stopped being read, so this row is stale:\n%s' % out
  assert ci_cov.ok_line(out)[2] == 1, (
      'a suite was declared reachable by a file outside the repository, and the '
      'import count no longer shows it:\n%s' % out)


# --- file bodies that become values a check compares --------------------------

def test_a_hostile_filename_reaches_the_claim_report_as_text():
  """Check [91] prints the path it read. A filename carrying a substitution is
  quoted straight into that sentence and nothing runs, because the path is only
  ever a git ls-files row and an open."""
  root = declaration_tree()
  hostile = hostile_values('fired')['substitution']
  write(root, 'docs/%s.md' % hostile, 'notes\n\nProved by %s today.\n' % FABRICATED_ID)
  ci_cov.git(root, 'add', '-A')
  rc, out = run_check('91', cwd=root)
  assert rc != 0, out
  expect(out, 'docs/%s.md:3 asserts a %s' % (hostile, FABRICATED_ID))
  assert not (root / 'fired').exists(), 'the filename was executed'


def test_a_prompt_token_cannot_carry_a_shell_metacharacter_at_all():
  """The token grammar is lowercase letters, digits and underscores, so no hostile
  spelling is in class in the first place. The declared token beside it still
  resolves, which is how this row proves the scan ran rather than died."""
  mark = canary()
  hostile = hostile_values(mark)
  body = ('**ROLE**. a worker.\n\n**OBJECTIVE**. one diff.\n\n**INPUTS**.\n'
          '1. {{alpha}}, the declared input.\n\n**OUTPUT**. %s uses {{alpha}}\n'
          % ' '.join('{{%s}}' % v for v in hostile.values()))
  root = temp_dir('hostile-td-')
  write(root, 'prompt.md', body)
  rc, out = run_check_replay('93', 'TD_REPLAY_ROOT', root)
  assert rc == 0, out
  expect(out, '2 {{token}} use(s) across 1 prompt(s)')
  assert not mark.exists(), 'a token was executed'


def test_a_hostile_document_body_is_inert_to_the_section_scan():
  """Check [94] compares a document's text against literals in its own source, so
  the document contributes a substring test and a citation and nothing else."""
  mark = canary()
  hostile = ' '.join(hostile_values(mark).values())
  root = temp_dir('hostile-se-')
  write(root, 'doc.md', 'notes %s\n\nAppend one %s entry per landed task.\n'
        % (hostile, RETIRED_LABEL))
  rc, out = run_check_replay('94', 'SE_REPLAY_ROOT', root)
  assert rc != 0, out
  expect(out, 'doc.md:3 instructs a writer to use a work-doc section named')
  assert not mark.exists(), 'a document body was executed'


def test_a_hostile_quoted_phrase_is_a_needle_and_never_a_pattern():
  """Check [95] takes a phrase straight out of a document and looks for it in every
  other file. That is the sharpest of these routes, because the value really does
  become the check's search term. It stays a substring test, so the phrase comes
  back quoted in the report and the glob next to it matches nothing."""
  mark = canary()
  hostile = hostile_values(mark)['substitution']
  claim = 'notes\n\nThe %s%s%s row is %s in this tree.\n' % (TICK, hostile, TICK,
                                                             PINNING_CLAIM)
  root = temp_dir('hostile-la-')
  write(root, 'claim.md', claim)
  write(root, 'other.md', 'notes\n\nSomewhere: %s%s%s\n' % (TICK, hostile, TICK))
  rc, out = run_check_replay('95', 'LA_REPLAY_ROOT', root)
  assert rc != 0, out
  expect(out, "claim.md:3 says '%s' is" % hostile, 'other.md')
  assert not mark.exists(), 'a quoted phrase was executed'


def test_a_redos_phrase_completes_because_the_search_is_a_substring_test():
  """The same route, fed the pattern AC3 names. A backtracking engine handed this
  against four thousand characters does not return; a substring test does, and the
  report proves it looked rather than gave up."""
  phrase = hostile_values('unused')['redos']
  filler = 'a' * 4000
  root = temp_dir('hostile-redos-')
  write(root, 'claim.md', 'notes\n\nThe %s%s%s row is %s here.\n'
        % (TICK, phrase, TICK, PINNING_CLAIM))
  write(root, 'other.md', 'notes\n\n%s %s%s%s\n' % (filler, TICK, phrase, TICK))
  rc, out = run_check_replay('95', 'LA_REPLAY_ROOT', root)
  assert rc != 0, out
  expect(out, "claim.md:3 says '%s' is" % phrase, 'other.md')

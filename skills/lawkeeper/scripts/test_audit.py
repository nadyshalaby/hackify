#!/usr/bin/env python3
"""Unit tests for the lawkeeper scanner. No external deps, run: python3 test_audit.py

Covers the cases most likely to regress: lexer masking (a ban hiding in a string / comment /
multi-line template must NOT match), each token ban, the path carve-outs, and secret
redaction. Each test is a function that asserts; `main` runs them all and reports.
"""

import os
import shutil
import sys
import tempfile

import re
from types import SimpleNamespace

from audit_scan import load_paths_from
from checks import FileContext
from exemptions import is_generated, is_scannable, is_test, rule_exempt, scan_mode


def _rules(src):
  ctx = FileContext('src/users/users.service.ts', src)
  return [f['rule_id'] for f in ctx.run_all(500)]


def test_empty_catch_in_code_matches():
  assert 'ban.empty-catch' in _rules('try { x() } catch (e) {}\n')


def test_empty_catch_in_string_is_masked():
  src = 'const s = "danger catch (e) {} here"\n'
  assert 'ban.empty-catch' not in _rules(src)


def test_ban_in_block_comment_is_masked():
  src = '/* example: throw new Error( and catch (e) {} */\nconst x = 1\n'
  rules = _rules(src)
  assert 'ban.bare-error' not in rules and 'ban.empty-catch' not in rules


def test_ban_in_multiline_template_is_masked():
  src = 'const t = `line one\ncatch (e) {} still template`\n'
  assert 'ban.empty-catch' not in _rules(src)


def test_bare_error_matches():
  assert 'ban.bare-error' in _rules("throw new Error('boom')\n")


def test_non_null_matches_postfix_not_logical_not():
  assert 'ban.non-null' in _rules('const a = b.get()!\n')
  assert 'ban.non-null' not in _rules('const a = !flag\n')
  assert 'ban.non-null' not in _rules('if (a !== b) return\n')


def test_suppression_in_comment_matches():
  assert 'ban.suppression' in _rules('// @ts-ignore legacy\nconst x = 1\n')


def test_inline_type_in_scoped_file_matches():
  assert 'ban.inline-type' in _rules('interface Foo { a: number; b: number }\n')


def test_secret_detected_and_redacted():
  ctx = FileContext('src/a.ts', 'const k = "AKIA1234567890ABCDEF"\n')
  hits = [f for f in ctx.check_secrets()]
  assert len(hits) == 1
  assert 'AKIA1234567890ABCDEF' not in hits[0]['snippet']
  assert 'REDACTED' in hits[0]['snippet']


def test_env_var_name_not_flagged_as_secret():
  ctx = FileContext('src/a.ts', 'const k = apiKey == "VITE_API_KEY"\n')
  assert ctx.check_secrets() == []


def test_file_lines_cap():
  ctx = FileContext('src/a.ts', '\n'.join(str(i) for i in range(10)))
  hits = ctx.check_file_lines(5)
  assert len(hits) == 1 and hits[0]['rule_id'] == 'cap.file-lines'


def _cap_hits(src, cap=500):
  """cap.file-lines findings for `src`, through the text-only path (no JS lexer needed)."""
  ctx = FileContext('src/a.ts', src)
  return [f for f in ctx.run_text_only(cap, []) if f['rule_id'] == 'cap.file-lines']


def test_file_lines_at_cap_is_clean():
  """A file of exactly `cap` real lines is AT the cap, not over it."""
  assert _cap_hits('x\n' * 500) == []


def test_file_lines_ignores_the_trailing_newline():
  """Phantom-element proof: a terminated file counts the same as an unterminated one."""
  assert _cap_hits('x\n' * 499 + 'x') == []
  assert _cap_hits('x\n' * 500 + 'x') == _cap_hits('x\n' * 501)


def test_file_lines_one_over_cap_reports_the_real_count():
  """One real line over is flagged, and the count it reports is the real one."""
  hits = _cap_hits('x\n' * 501)
  assert len(hits) == 1, f'expected one cap.file-lines finding, got {len(hits)}'
  assert hits[0]['end_line'] == 501, f"end_line {hits[0]['end_line']}, expected 501"
  assert '501 lines' in hits[0]['message'], hits[0]['message']


def test_exemptions_paths():
  assert is_test('src/users/users.test.ts')
  assert is_generated('src/routeTree.gen.ts')
  assert not is_scannable('src/migrations/0001_init.ts')
  assert not is_scannable('README.md')
  assert is_scannable('src/users/users.service.ts')


def test_recall_corpus_exempt_from_self_audit():
  # A repo-root audit sees the corpus under skills/...; it must be exempt so a
  # `/lawkeeper` run on this repo does not flag its own planted fixtures.
  assert is_generated('skills/lawkeeper/evals/corpus/project/backend/config.ts')
  # run_corpus.py roots its scan inside project/, so that rel-path stays scannable.
  assert is_scannable('backend/config.ts')


def test_confidence_tiers_are_honest():
  from checks import RULE_META
  # bare-error and inline-type cannot be confirmed by regex alone (domain scope /
  # 2+ props), so they are flagged 'syntactic', not 'exact', see RULE_META.
  assert RULE_META['ban.bare-error'][2] == 'syntactic'
  assert RULE_META['ban.inline-type'][2] == 'syntactic'
  # the genuinely exact ones stay 'exact'.
  assert RULE_META['ban.suppression'][2] == 'exact'
  assert RULE_META['ban.empty-catch'][2] == 'exact'
  assert RULE_META['sec.hardcoded-secret'][2] == 'exact'


def test_rule_exempt_carve_outs():
  assert rule_exempt('ban.inline-type', 'src/users/users.repository.ts')
  assert not rule_exempt('ban.inline-type', 'src/users/users.service.ts')
  assert rule_exempt('ban.non-null', 'src/users/users.test.ts')
  assert not rule_exempt('ban.non-null', 'src/users/users.service.ts')


def test_removed_comment_flagged():
  assert 'clean.removed-comment' in _rules('// removed: old handler\nconst x = 1\n')
  assert 'clean.removed-comment' in _rules('# removed: dead path\n')


def test_debt_marker_without_owner_flagged():
  assert 'clean.debt-marker' in _rules('// TODO fix this later\n')
  assert 'clean.debt-marker' in _rules('const x = 1 // FIXME\n')


def test_debt_marker_with_owner_or_ticket_ignored():
  assert 'clean.debt-marker' not in _rules('// TODO(alice): refactor\n')
  assert 'clean.debt-marker' not in _rules('// TODO: PROJ-1234 refactor\n')
  assert 'clean.debt-marker' not in _rules('// FIXME ABC-42 broken edge\n')


def test_debt_marker_in_string_not_flagged():
  assert 'clean.debt-marker' not in _rules('const label = "your TODO list is empty"\n')
  assert 'clean.debt-marker' not in _rules('const e = throwError("FIXME the API")\n')


def test_debt_marker_jsdoc_continuation():
  assert 'clean.debt-marker' in _rules('/**\n * TODO finish the docs\n */\n')


def test_hygiene_markers_run_in_text_only():
  ctx = FileContext('src/app.py', 'def f():\n    pass  # TODO clean up\n')
  rules = [f['rule_id'] for f in ctx.run_text_only(500, [])]
  assert 'clean.debt-marker' in rules


def test_posix_class_translation():
  from audit_scan import _posix_to_python
  assert _posix_to_python(r'[[:space:]]*type') == r'[\s]*type'
  assert _posix_to_python(r'[[:alnum:]_]+') == r'[A-Za-z0-9_]+'
  bans = [(re.compile(_posix_to_python(r'[#][[:space:]]*noqa')), 'blanket noqa')]
  ctx = FileContext('src/app.py', 'x = 1  # noqa\n')
  assert len(ctx.run_text_only(500, bans)) == 1


def test_scan_mode_classifies():
  assert scan_mode('src/a.ts') == 'full'
  assert scan_mode('src/a.py', text_exts=('.py',)) == 'text'
  assert scan_mode('src/a.py') is None
  assert scan_mode('src/routeTree.gen.ts') is None


def test_text_only_skips_js_construct_checks():
  ctx = FileContext('src/app.py', 'def f():\n    pass  # comment with ! and catch (e) {}\n')
  bans = [(re.compile(r'#\s*type:\s*ignore'), 'type: ignore in production')]
  rules = [f['rule_id'] for f in ctx.run_text_only(500, bans)]
  assert rules == []  # no JS bans misfire, no type:ignore present


def test_text_only_honors_project_ban():
  ctx = FileContext('src/app.py', 'x = 1  # type: ignore\n')
  bans = [(re.compile(r'#\s*type:\s*ignore'), 'type: ignore in production')]
  hits = ctx.run_text_only(500, bans)
  assert len(hits) == 1 and hits[0]['rule_id'] == 'ban.custom'


def _scoped_tree(extra=()):
  """Throwaway project: one touched and one untouched violating file, plus `extra` rel-paths."""
  root = tempfile.mkdtemp()
  for rel in ('src/touched.ts', 'src/untouched.ts', *extra):
    abs_path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(abs_path), exist_ok=True)
    with open(abs_path, 'w', encoding='utf-8') as handle:
      handle.write('try { x() } catch (e) {}\n')
  return root


def _write_list(root, listed):
  """Write a path list the way a `git diff --name-only` dump arrives; return its path."""
  list_path = os.path.join(root, 'paths.txt')
  with open(list_path, 'w', encoding='utf-8') as handle:
    handle.write('\n'.join(listed))
  return list_path


def _scoped_report(root, listed):
  """Full report dict for a scoped run, so tests can assert on stats as well as findings."""
  from audit_scan import build_config, build_report, run_scan
  args = SimpleNamespace(max_file_lines=500, ban_patterns=None, extra_generated=[],
                         text_only_ext=[], paths_from=_write_list(root, listed))
  config = build_config(args)
  return build_report(root, config, run_scan(root, config))


def _accounted(stats):
  """scanned + skipped + every drop bucket; discovers new `paths_*` buckets on its own."""
  dropped = sum(value for key, value in stats.items()
                if key.startswith('paths_') and key != 'paths_unaccounted')
  return stats['files_scanned'] + stats['files_skipped'] + dropped


def _scan_scoped(root, listed):
  return sorted({f['file'] for f in _scoped_report(root, listed)['findings']})


def test_paths_from_scopes_the_scan():
  root = _scoped_tree()
  try:
    assert _scan_scoped(root, ['src/touched.ts']) == ['src/touched.ts']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_paths_from_ignores_deleted_and_skipped_paths():
  root = _scoped_tree()
  try:
    listed = ['src/touched.ts', 'src/gone.ts', 'node_modules/dep/index.ts']
    assert _scan_scoped(root, listed) == ['src/touched.ts']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_no_paths_from_walks_whole_tree():
  from audit_scan import build_config, run_scan
  root = _scoped_tree()
  try:
    args = SimpleNamespace(max_file_lines=500, ban_patterns=None, extra_generated=[],
                           text_only_ext=[], paths_from=None)
    findings, _tally = run_scan(root, build_config(args))
    assert sorted({f['file'] for f in findings}) == ['src/touched.ts', 'src/untouched.ts']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_load_paths_from_preserves_leading_dots():
  """`str.lstrip` takes a character set, so it ate the dot off every dot-path. It must not."""
  root = tempfile.mkdtemp()
  try:
    listed = ['.github/workflows/ci.yml', '.env', './src/a.ts', 'src/b.ts']
    parsed = load_paths_from(_write_list(root, listed))
    assert parsed == frozenset({'.github/workflows/ci.yml', '.env', 'src/a.ts', 'src/b.ts'})
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_paths_from_keeps_dot_directory():
  root = _scoped_tree(extra=('.github/actions/run.ts',))
  try:
    assert _scan_scoped(root, ['.github/actions/run.ts']) == ['.github/actions/run.ts']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_paths_from_keeps_bare_dotfile():
  root = _scoped_tree(extra=('.eslintrc.ts',))
  try:
    assert _scan_scoped(root, ['.eslintrc.ts']) == ['.eslintrc.ts']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_paths_from_strips_one_leading_dot_slash():
  root = _scoped_tree()
  try:
    assert _scan_scoped(root, ['./src/touched.ts']) == ['src/touched.ts']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_scoped_stats_reconcile_against_handed_paths():
  """The regression guard: every handed path lands in exactly one counter, none vanish."""
  root = _scoped_tree(extra=('.github/actions/run.ts', 'docs/notes.md'))
  listed = ['.github/actions/run.ts', 'src/touched.ts', 'src/gone.ts',
            'node_modules/dep/index.ts', 'docs/notes.md']
  try:
    report = _scoped_report(root, listed)
    stats = report['stats']
    assert 'paths_unaccounted' in stats, f'no reconciliation counters in stats: {sorted(stats)}'
    assert stats['files_scanned'] == 2
    assert stats['paths_not_found'] == 1
    assert stats['paths_in_skipped_dir'] == 1
    assert stats['paths_unsupported'] == 1
    assert stats['paths_unaccounted'] == 0
    assert report['config']['scoped_paths'] == len(listed)
    assert _accounted(stats) == report['config']['scoped_paths']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_paths_from_counts_paths_outside_root():
  """A listed path that escapes the scan root is contained AND counted, never scanned."""
  root = _scoped_tree(extra=('sub/inner.ts', 'escape.ts'))
  try:
    scan_root = os.path.join(root, 'sub')
    listed = ['inner.ts', '../escape.ts', os.path.join(root, 'escape.ts')]
    stats = _scoped_report(scan_root, listed)['stats']
    assert 'paths_outside_root' in stats, f'no containment counter in stats: {sorted(stats)}'
    assert stats['paths_outside_root'] == 2
    assert stats['files_scanned'] == 1
    assert _accounted(stats) == len(listed)
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_unaccounted_reports_a_path_that_left_uncounted():
  """The guard must BITE. A drop path that forgets its bucket has to surface, not read 0."""
  from audit_scan import ScanTally, build_stats
  tally = ScanTally()
  tally.scanned = 1
  config = SimpleNamespace(only_paths=frozenset({'a.ts', 'b.ts', 'c.ts'}))
  stats = build_stats(config, tally, 0)
  assert stats['paths_unaccounted'] == 2
  assert _accounted(stats) == 1


def test_walked_scan_reports_zero_drop_buckets():
  """Whole-tree mode hands the scanner no path list, so every drop bucket stays empty."""
  from audit_scan import build_config, build_report, run_scan
  root = _scoped_tree()
  try:
    args = SimpleNamespace(max_file_lines=500, ban_patterns=None, extra_generated=[],
                           text_only_ext=[], paths_from=None)
    config = build_config(args)
    stats = build_report(root, config, run_scan(root, config))['stats']
    assert 'paths_unaccounted' in stats, f'no reconciliation counters in stats: {sorted(stats)}'
    assert stats['files_scanned'] == 2 and stats['paths_unaccounted'] == 0
    assert _accounted(stats) == stats['files_scanned']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def _all_tests():
  return [value for name, value in sorted(globals().items())
          if name.startswith('test_') and callable(value)]


def main():
  failures = []
  for test in _all_tests():
    try:
      test()
    except AssertionError as err:
      failures.append(f'{test.__name__}: {err or "assertion failed"}')
  total = len(_all_tests())
  for line in failures:
    print(f'FAIL  {line}')
  print(f'{total - len(failures)}/{total} passed')
  return 1 if failures else 0


if __name__ == '__main__':
  sys.exit(main())

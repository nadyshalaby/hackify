#!/usr/bin/env python3
"""Unit tests for the lawkeeper scanner. No external deps — run: python3 test_audit.py

Covers the cases most likely to regress: lexer masking (a ban hiding in a string / comment /
multi-line template must NOT match), each token ban, the path carve-outs, and secret
redaction. Each test is a function that asserts; `main` runs them all and reports.
"""

import sys

import re

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

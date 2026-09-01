#!/usr/bin/env python3
"""Unit tests for the lawkeeper scanner. No external deps, run: python3 test_audit.py

Covers the cases most likely to regress: lexer masking (a ban hiding in a string / comment /
multi-line template must NOT match), each token ban, the path carve-outs, and secret
redaction. Each test is a function that asserts; `main` runs them all and reports.

THE SUITE IS TWO FILES AND ONE ENTRY POINT. The scoped-scan half (path-list parsing,
the scoped iterator, the three counter families) lives in test_scoping.py, which this
file imports and `_all_tests` collects from, so `python3 test_audit.py` still runs
everything CI and the docs already point at. It was split when this file reached the
500-line cap the scanner it tests exists to enforce; growing past that cap to hold
tests for a cap check would have been the joke it sounds like.
"""

import sys

import re

import test_scoping
from checks import FileContext
from exemptions import (APPEND_ONLY_BASENAMES, is_append_only, is_generated, is_prose,
                        is_scannable, is_test, rule_exempt, scan_mode)


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
  # `/hackify:lawkeeper` run on this repo does not flag its own planted fixtures.
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


def test_detection_fixtures_in_tests_are_waived():
  """A fixture proving the scanner detects a marker has to CONTAIN that marker.

  The two hygiene rules landed after the four doctrine bans and nobody revisited the
  test row, so the scanner flagged the exact strings above that prove it works.
  """
  for rule_id in ('clean.removed-comment', 'clean.debt-marker'):
    assert rule_exempt(rule_id, 'skills/lawkeeper/scripts/test_audit.py'), rule_id
    assert rule_exempt(rule_id, 'src/users/users.test.ts'), rule_id
    # and ordinary source keeps both rules, the waiver is the test glob, not the rule.
    assert not rule_exempt(rule_id, 'src/users/users.service.ts'), rule_id


def test_prose_waives_the_hygiene_markers_only():
  """Markdown has no comment openers: `#` is a heading, a leading `*` is a bullet."""
  for rule_id in ('clean.removed-comment', 'clean.debt-marker'):
    assert rule_exempt(rule_id, 'README.md'), rule_id
    assert rule_exempt(rule_id, 'skills/hackify/references/law-scout.md'), rule_id
    assert rule_exempt(rule_id, 'docs/guide.mdx'), rule_id
  assert is_prose('CHANGELOG.md') and not is_prose('scripts/build.sh')
  # The cap is NOT waived by prose; only the append-only list does that.
  assert not rule_exempt('cap.file-lines', 'README.md')


def test_hygiene_markers_still_fire_in_non_prose_text_files():
  """`# TODO` in a real script IS debt. The waiver is markdown, never text-only mode."""
  for path in ('scripts/deploy.sh', 'src/app.py', 'config.yml'):
    assert not rule_exempt('clean.debt-marker', path), path
    assert not rule_exempt('clean.removed-comment', path), path
  ctx = FileContext('scripts/deploy.sh', '# TODO wire the rollback\n')
  assert [f['rule_id'] for f in ctx.run_text_only(500, [])] == ['clean.debt-marker']


def test_suppression_ban_cannot_reach_a_prose_file():
  """Why `ban.suppression` is absent from the prose waiver: nothing could take that branch.

  `.md` is never in SCAN_EXTS, so scan_mode can only ever call it 'text', and
  check_suppression runs only in `run_all`. Waiving it would be a dead branch.
  """
  assert scan_mode('README.md', text_exts=('.md',)) == 'text'
  ctx = FileContext('README.md', 'the hook blocks `@' + 'ts-ignore` on sight\n')
  assert 'ban.suppression' not in [f['rule_id'] for f in ctx.run_text_only(500, [])]
  assert not rule_exempt('ban.suppression', 'README.md')


def test_append_only_is_waived_from_the_cap_and_nothing_else():
  """Exact basenames, never a pattern, and only `cap.file-lines`."""
  assert is_append_only('CHANGELOG.md')
  assert is_append_only('packages/api/CHANGELOG.md')
  assert rule_exempt('cap.file-lines', 'CHANGELOG.md')
  assert not rule_exempt('cap.file-lines', 'README.md')
  # `*.md` would have taken every doc with it; the list is basenames, so `.mdx` is out.
  assert not rule_exempt('cap.file-lines', 'docs/CHANGELOG.mdx')
  # Waived from the CAP and from that rule alone: a project ban still binds the changelog.
  assert not rule_exempt('ban.custom', 'CHANGELOG.md')
  assert APPEND_ONLY_BASENAMES == frozenset({'CHANGELOG.md'})


def test_append_only_file_is_exempt_from_the_cap_never_from_the_scan():
  """The check still RUNS and the file is still read; only the finding is dropped.

  A `find`-level exclusion would let the file leave the scanned set in silence, which
  is indistinguishable from coverage. This asserts both halves in one place.
  """
  from audit_scan import _finalize
  raw = FileContext('CHANGELOG.md', 'x\n' * 501).run_text_only(500, [])
  assert [f['rule_id'] for f in raw] == ['cap.file-lines'], 'the cap check must still run'
  assert raw[0]['end_line'] == 501, 'and still count the real lines'
  assert _finalize(raw, 'CHANGELOG.md') == [], 'the finding is dropped at the last step'
  kept = FileContext('README.md', 'x\n' * 501).run_text_only(500, [])
  assert _finalize(kept, 'README.md') == kept, 'and no other file loses its cap finding'


def _all_tests():
  """Every `test_*` callable in this module and in test_scoping, the suite's other half.

  Two pools, one runner, so the split costs the caller nothing. `test_scoping` is
  imported as a MODULE rather than star-imported: nothing lands in this namespace by
  accident, and the module object's own `test_` prefix is filtered by `callable`.
  """
  pools = (globals(), vars(test_scoping))
  return [value for pool in pools for name, value in sorted(pool.items())
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

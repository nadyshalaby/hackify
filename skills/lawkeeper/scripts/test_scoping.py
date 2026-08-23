#!/usr/bin/env python3
"""Scoped-scan tests: the `--paths-from` list, the scoped iterator, the reconciles.

Split out of test_audit.py the day that file hit the 500-line cap it exists to help
enforce. One responsibility per file: this half owns path-list parsing, the scoped
iterator's drop buckets, and the three counter families (`lines_*`, `unread_*`,
`paths_*`); test_audit.py keeps the lexer, the rule checks and the carve-outs.

NOT A SECOND ENTRY POINT. `python3 test_audit.py` still runs everything, it imports
this module and collects both pools, so the command CI and the docs already name does
not change.
"""

import os
import shutil
import tempfile
from types import SimpleNamespace

from audit_scan import load_paths_from


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


def _paths_drops(stats):
  """The `paths_*` drop sum a consumer computes BY PREFIX.

  This is the idiom the unread family has to stay out of: a bucket that joins this
  sum is read as covered, which is how a 2MB file used to vanish behind a balanced
  reconcile. Asserting this reads 0 while a file went unread is the regression guard.
  """
  return sum(value for key, value in stats.items()
             if key.startswith('paths_') and key != 'paths_unaccounted')


def _unread(stats):
  """Every `unread_*` bucket: the files the scan located but could NOT read."""
  return sum(value for key, value in stats.items() if key.startswith('unread_'))


def _accounted(stats):
  """scanned + unread + every drop bucket; discovers new buckets in both families."""
  return stats['files_scanned'] + _unread(stats) + _paths_drops(stats)


def _line_accounted(stats, config):
  """scoped_paths + every lines_* drop bucket; the parse step's half of the reconcile."""
  dropped = sum(value for key, value in stats.items()
                if key.startswith('lines_') and key != 'lines_unaccounted')
  return config['scoped_paths'] + dropped


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
    parsed = load_paths_from(_write_list(root, listed)).paths
    assert parsed == {'.github/workflows/ci.yml', '.env', 'src/a.ts', 'src/b.ts'}
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
  # path_lines is built EXPLICITLY rather than defaulted inside build_stats. A
  # getattr fallback there would let a caller that never parsed a list publish a
  # tidy zero, which is the "check that passes while measuring nothing" shape this
  # whole counter family exists to refuse.
  listing = load_paths_from(None)
  listing.paths.update({'a.ts', 'b.ts', 'c.ts'})
  listing.lines_read = 3
  # `supplied` is set EXPLICITLY for the same reason `path_lines` is: the scan-stage
  # subtraction is published only for a run that was handed a list, so a listing that
  # says it was handed none would make this guard read a tidy 0 and stop biting.
  listing.supplied = True
  config = SimpleNamespace(only_paths=frozenset(listing.paths), path_lines=listing)
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
    report = build_report(root, config, run_scan(root, config))
    stats = report['stats']
    assert 'paths_unaccounted' in stats, f'no reconciliation counters in stats: {sorted(stats)}'
    assert stats['files_scanned'] == 2 and stats['paths_unaccounted'] == 0
    assert _accounted(stats) == stats['files_scanned']
    assert report['config']['path_list_supplied'] is False, report['config']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_paths_from_accounts_for_every_input_line():
  """T64 regression: the PARSE step used to discard lines with no bucket behind it.

  Seven lines in, two paths out, and the four lines that vanished (one empty, one
  whitespace-only, one comment, one duplicate) moved no counter at all. The scan
  loop had reconciled since v0.14.2; the parse step in front of it had not, so the
  loss happened BEFORE the number everything downstream reconciles against.
  """
  root = tempfile.mkdtemp()
  try:
    listed = ['src/a.ts', '', '   ', '#comment.ts', 'src/a.ts', './src/b.ts', 'src/b.ts']
    listing = load_paths_from(_write_list(root, listed))
    assert listing.lines_read == 7, listing.lines_read
    assert set(listing.paths) == {'src/a.ts', 'src/b.ts'}, sorted(listing.paths)
    assert listing.dropped['blank'] == 2, listing.dropped
    assert listing.dropped['comment'] == 1, listing.dropped
    assert listing.dropped['duplicate'] == 2, listing.dropped
    assert listing.accounted() == 7, listing.accounted()
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_scoped_stats_publish_the_line_level_reconcile():
  """The parse buckets reach the REPORT, not just the parser. A counter nobody can
  read from the JSON is the same silence, one layer further in."""
  root = _scoped_tree()
  try:
    listed = ['src/touched.ts', '', '#note', 'src/touched.ts', 'src/untouched.ts']
    report = _scoped_report(root, listed)
    stats, config = report['stats'], report['config']
    assert config['listed_lines'] == 5, config
    assert config['scoped_paths'] == 2, config
    assert stats['lines_blank'] == 1 and stats['lines_comment'] == 1, stats
    assert stats['lines_duplicate'] == 1, stats
    assert stats['lines_unaccounted'] == 0, stats
    assert _line_accounted(stats, config) == config['listed_lines']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_lines_unaccounted_reports_a_line_that_left_uncounted():
  """The line-level guard must BITE, the same way paths_unaccounted does.

  A future parse branch added without its own bucket has to surface here rather
  than read 0. Built by hand because the point is a parser that HAS lost lines.
  """
  from audit_scan import ScanTally, build_stats
  listing = load_paths_from(None)
  listing.lines_read = 9
  listing.paths.update({'a.ts', 'b.ts'})
  listing.dropped['blank'] = 1
  config = SimpleNamespace(only_paths=frozenset(listing.paths), path_lines=listing)
  stats = build_stats(config, ScanTally(), 0)
  assert stats['lines_unaccounted'] == 6, stats


def test_paths_from_dot_slash_escapes_the_comment_rule():
  """`#foo.ts` is a legal POSIX filename, so the comment rule needs a way out.

  The `#` test runs BEFORE the `./` prefix strip, which makes `./#foo.ts` name the
  real file `#foo.ts`. Without this the only two options were "lose comments" or
  "lose the file", and this repo does not accept losing the file.
  """
  root = tempfile.mkdtemp()
  try:
    listing = load_paths_from(_write_list(root, ['./#foo.ts', '#foo.ts']))
    assert set(listing.paths) == {'#foo.ts'}, sorted(listing.paths)
    assert listing.dropped['comment'] == 1, listing.dropped
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_nul_separated_input_is_contained_not_fatal():
  """T71: `git diff --name-only -z` is NUL-separated, so the whole dump arrives as ONE
  line carrying NUL bytes. `os.path.realpath` raises ValueError on those, unguarded,
  on the FIRST caller-supplied string the scan touched, and aborted the entire run.
  It is a containment refusal now, counted like every other one."""
  root = _scoped_tree()
  try:
    report = _scoped_report(root, ['src/touched.ts\x00src/untouched.ts\x00'])
    stats = report['stats']
    assert stats['paths_outside_root'] == 1, stats
    assert stats['files_scanned'] == 0, stats
    assert stats['paths_unaccounted'] == 0, stats
    assert _accounted(stats) == report['config']['scoped_paths']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_oversized_file_is_unread_never_covered():
  """T-G1-1: a readable file over `MAX_BYTES` was dropped into `files_skipped`, and
  the documented reconcile ADDED that bucket into `covered`. A 2.3MB / 200k-line file
  against a cap of 500 reported `files_scanned 0, findings 0, paths_unaccounted 0`,
  a 400x cap break published as a balanced, clean scan. Unread now has its own family,
  outside the `paths_*` prefix consumers sum, so the arithmetic still closes while the
  file reads as what it is: located, not covered.
  """
  from audit_scan import MAX_BYTES
  root = _scoped_tree()
  try:
    with open(os.path.join(root, 'src/huge.ts'), 'w', encoding='utf-8') as handle:
      handle.write('x\n' * (MAX_BYTES // 2 + 1))
    report = _scoped_report(root, ['src/huge.ts'])
    stats = report['stats']
    assert stats['files_scanned'] == 0, stats
    assert stats['unread_too_large'] == 1, stats
    assert _paths_drops(stats) == 0, stats
    assert _unread(stats) == 1, stats
    assert stats['paths_unaccounted'] == 0, stats
    assert _accounted(stats) == report['config']['scoped_paths'], stats
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_undecodable_file_is_unread_never_covered():
  """Same silence, other door: a non-UTF-8 file takes the identical unread path."""
  root = _scoped_tree()
  try:
    with open(os.path.join(root, 'src/binary.ts'), 'wb') as handle:
      handle.write(b'const flag = "\xff\xfe\x00" \n')
    report = _scoped_report(root, ['src/binary.ts'])
    stats = report['stats']
    assert stats['files_scanned'] == 0, stats
    assert stats['unread_unreadable'] == 1, stats
    assert _paths_drops(stats) == 0, stats
    assert _accounted(stats) == report['config']['scoped_paths'], stats
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_supplied_but_empty_list_scans_nothing():
  """T-G1-2: `--paths-from` handed an EMPTY list means scan nothing.

  It used to collapse into "no `--paths-from`" and walk the whole tree: 0 paths in,
  4 files scanned, 7 findings out, and `paths_unaccounted` hardcodes 0 in exactly
  that mode, so no reconcile could see it. The branch is on whether the flag was
  supplied now, never on whether the list came out empty.
  """
  root = _scoped_tree()
  try:
    report = _scoped_report(root, [])
    stats, config = report['stats'], report['config']
    assert config['path_list_supplied'] is True, config
    assert config['listed_lines'] == 0 and config['scoped_paths'] == 0, config
    assert stats['files_scanned'] == 0, stats
    assert report['findings'] == [], report['findings']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_supplied_list_of_only_dropped_lines_scans_nothing():
  """The same collapse one step later: a list whose every line the parser drops.

  Branching on `only_paths` emptiness could not tell this from a tree walk either,
  and this shape is the likelier one in the field, a list of comments and blanks.
  """
  root = _scoped_tree()
  try:
    report = _scoped_report(root, ['', '   ', '#src/touched.ts'])
    stats, config = report['stats'], report['config']
    assert config['listed_lines'] == 3 and config['scoped_paths'] == 0, config
    assert stats['files_scanned'] == 0 and stats['lines_unaccounted'] == 0, stats
    assert report['findings'] == [], report['findings']
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_listed_symlink_is_resolved_once_before_it_is_opened():
  """T-G1-3 (CWE-367): containment resolved the symlink, `isfile` and `open` did not.

  Two paths answered two questions about one entry, which is the check-then-use
  window. The iterator yields the RESOLVED path now, so the path proved contained is
  the same one that gets opened. `rel_path` stays the listed name, it is what findings
  and carve-outs are keyed on.
  """
  from audit_scan import ScanTally, build_config, iter_source_files
  root = _scoped_tree()
  try:
    os.symlink(os.path.join(root, 'src/touched.ts'), os.path.join(root, 'src/link.ts'))
    args = SimpleNamespace(max_file_lines=500, ban_patterns=None, extra_generated=[],
                           text_only_ext=[], paths_from=_write_list(root, ['src/link.ts']))
    config = build_config(args)
    located = list(iter_source_files(root, config, ScanTally()))
    assert len(located) == 1, located
    abs_path, rel_path, _mode = located[0]
    assert abs_path == os.path.realpath(os.path.join(root, 'src/touched.ts')), abs_path
    assert rel_path == 'src/link.ts', rel_path
  finally:
    shutil.rmtree(root, ignore_errors=True)


def test_dot_lines_are_malformed_not_admitted_paths():
  """T-G1-4: `./` normalizes to `''` and was ADMITTED, so it reached the scan stage
  and landed in `paths_not_found`, a bucket whose whole meaning is "the diff deleted
  this file". A bare `.` is the same shape and is reachable from the very format the
  parser names: `find .` emits it as its first line. Neither carries a path, so both
  are a parse-stage malformation.
  """
  root = _scoped_tree()
  try:
    listed = ['./', '.', './src/touched.ts']
    listing = load_paths_from(_write_list(root, listed))
    assert set(listing.paths) == {'src/touched.ts'}, sorted(listing.paths)
    assert listing.dropped['malformed'] == 2, listing.dropped
    assert listing.accounted() == 3, listing.accounted()
    stats = _scoped_report(root, listed)['stats']
    assert stats['lines_malformed'] == 2, stats
    assert stats['paths_not_found'] == 0, stats
    assert stats['files_scanned'] == 1 and stats['lines_unaccounted'] == 0, stats
  finally:
    shutil.rmtree(root, ignore_errors=True)


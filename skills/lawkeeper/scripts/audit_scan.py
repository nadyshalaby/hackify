#!/usr/bin/env python3
"""lawkeeper deterministic scanner, walk a project, emit exact rule violations as JSON.

This is the mechanical half of the audit. It reports ONLY high-confidence findings (see
checks.py for why). The semantic half, function caps, DRY, layering, naming, folder
structure, is run by the skill's subagent pass, which reads this script's JSON as its
starting map. Run it directly:

    python3 audit_scan.py <root> [--max-file-lines 500] [--ban-patterns PATH]
                                  [--text-only-ext .py] [--extra-generated GLOB]
                                  [--paths-from PATH]

`--paths-from` narrows the scan to a newline-delimited list of root-relative paths (a
`git diff --name-only` dump), so a caller auditing one sprint's touched files pays for
those files instead of a whole-tree walk. Every line handed in lands in exactly one
counter, across TWO reconciles that chain:

  parse: `config.listed_lines` == `config.scoped_paths` + every `stats.lines_*` bucket
          (blank, comment, duplicate), and `stats.lines_unaccounted` is the remainder.
  scan:  `config.scoped_paths`  == files_scanned + files_skipped + every `stats.paths_*`
          bucket, and `stats.paths_unaccounted` is the remainder.

Both remainders read 0 on a healthy run. They are two families and not one because both
this file's consumers sum drop buckets by NAME PREFIX; a parse bucket named `paths_*`
would inflate the scan total past `scoped_paths` and report a surplus that is not real.
A path that no longer exists is dropped into `paths_not_found`, which is EXPECTED, not
an error, a diff list names deleted files too. Without `--paths-from` the whole tree is
walked, the default sweep, and every bucket reads 0.

The full JS/TS check suite runs on the ECMAScript family. `--text-only-ext` adds extensions
that get ONLY the language-agnostic checks (file-line cap + project ban-patterns), so a
non-JS project still gets caps and its own bans without the JS lexer misfiring. Deep
deterministic coverage of another stack is done by an on-demand scanner the skill generates
per session (references/porting-scanner.md). Project bans come from the project's own
ban-patterns.txt (grep-ERE format), never a hardcoded duplicate. Output: one JSON
object on stdout.
"""

import argparse
import json
import os
import re
import sys
from types import SimpleNamespace

from checks import FileContext
from exemptions import is_skipped_dir, is_test, rule_exempt, scan_mode

MAX_BYTES = 2_000_000


def load_extra_bans(path):
  """Parse a grep-ERE ban-patterns.txt into (compiled_regex, message) pairs."""
  if not path or not os.path.isfile(path):
    return []
  out = []
  with open(path, encoding='utf-8', errors='replace') as handle:
    for raw in handle:
      line = raw.rstrip('\n')
      if not line.strip() or line.lstrip().startswith('#'):
        continue
      regex, _, message = line.partition('\t')
      out.extend(_compile_ban(regex.strip(), message.strip()))
  return out


# ban-patterns.txt is written in grep-ERE (POSIX `grep -E`). Python's re has no
# POSIX bracket classes, so translate the common ones to keep the project's bans faithful.
_POSIX_CLASS = {
  'space': r'\s', 'digit': r'\d', 'alpha': 'A-Za-z', 'alnum': 'A-Za-z0-9',
  'upper': 'A-Z', 'lower': 'a-z', 'xdigit': '0-9A-Fa-f', 'blank': r' \t',
}


def _posix_to_python(regex):
  return re.sub(r'\[:(\w+):\]', lambda m: _POSIX_CLASS.get(m.group(1), m.group(0)), regex)


def _compile_ban(regex, message):
  if not regex:
    return []
  try:
    return [(re.compile(_posix_to_python(regex)), message or 'project-defined banned pattern')]
  except re.error:
    return []


def _norm_exts(exts):
  return tuple(ext if ext.startswith('.') else '.' + ext for ext in exts)


# Why an input LINE never becomes a path. Every one of these is a `stats.lines_*`
# key, so a line can leave the parser only through a counter, never through silence.
# Separate family from DROP_REASONS below, and deliberately so: `paths_*` answers
# "what happened to a parsed path", `lines_*` answers "what happened to an input
# line". Both the law-scout's reconcile snippet and this suite's own `_accounted`
# helper sum the drop buckets BY NAME PREFIX, so a fourth `paths_*` key here would
# inflate their total past `config.scoped_paths` and print a surplus that is not real.
PARSE_DROPS = ('blank', 'comment', 'duplicate')


class PathListing:
  """One parsed `--paths-from` file: the unique paths, plus why every other line went."""

  def __init__(self):
    self.paths = set()
    self.lines_read = 0
    self.dropped = dict.fromkeys(PARSE_DROPS, 0)

  def accounted(self):
    return len(self.paths) + sum(self.dropped.values())


def _classify_line(raw, seen):
  """One input line to `(rel_path, drop_reason)`, with exactly one of the two set."""
  entry = raw.strip().replace(os.sep, '/')
  if not entry:
    return None, 'blank'
  # `#` LEADS A COMMENT, NOT A FILENAME, and that is a deliberate lossy choice.
  # `#foo.ts` is a legal POSIX name and `git diff --name-only` emits it unquoted, so
  # this rule really can eat a real file. It is kept because the same rule has meant
  # "comment" in this repo's other list format (ban-patterns.txt, `load_extra_bans`
  # above) since it shipped, and silently changing what `#` means is a worse trade
  # than the case it costs. What changes is that the loss stops being invisible:
  # the line lands in `lines_comment`, and the ESCAPE HATCH is real, because this
  # test runs BEFORE the `./` strip below, so `./#foo.ts` names the file `#foo.ts`.
  if entry.startswith('#'):
    return None, 'comment'
  # A single leading `./`, the only prefix a `find .` or hand-written dump adds on
  # top of git's already-relative output. PREFIX removal, not `lstrip('./')`, which
  # takes a character SET and so ate the dot off every `.github/...` and bare `.env`.
  rel = entry.removeprefix('./')
  return (None, 'duplicate') if rel in seen else (rel, None)


def load_paths_from(path):
  """Parse a newline-delimited path list (git diff --name-only shape) into a PathListing.

  EVERY LINE READ LANDS IN EXACTLY ONE COUNTER. It becomes a path or it lands in a
  `lines_*` bucket saying why not, and `stats.lines_unaccounted` is the subtraction
  that proves the two still add up. This step used to drop blank, whitespace-only,
  commented and duplicate lines through a bare condition with no counter behind it:
  seven lines in, two paths out, and nothing anywhere in the report said so. That is
  the same defect the scan loop below was fixed for in v0.14.2, sitting one stage
  earlier, in front of the very number the whole chain reconciles against.

  Whether a path is reachable, contained, or scannable is still decided later, where
  it can be counted by the `paths_*` family.
  """
  listing = PathListing()
  if not path or not os.path.isfile(path):
    return listing
  with open(path, encoding='utf-8', errors='replace') as handle:
    for raw in handle:
      listing.lines_read += 1
      rel, reason = _classify_line(raw, listing.paths)
      if reason:
        listing.dropped[reason] += 1
      else:
        listing.paths.add(rel)
  return listing


# Why a listed path never reaches the scanner. Every one of these is a `stats.paths_*`
# key, so a path can leave the iterator only through a counter, never through silence.
DROP_REASONS = ('outside_root', 'in_skipped_dir', 'not_found', 'unsupported')


class ScanTally:
  """Reconciling counters for one scan: every handed path lands in exactly one bucket."""

  def __init__(self):
    self.scanned = 0
    self.skipped = 0
    self.dropped = dict.fromkeys(DROP_REASONS, 0)

  def drop(self, reason):
    self.dropped[reason] += 1

  def accounted(self):
    return self.scanned + self.skipped + sum(self.dropped.values())


def _in_skipped_dir(rel_path):
  return any(is_skipped_dir(part) for part in rel_path.split('/')[:-1])


def _escapes_root(root_prefix, abs_path):
  """True when a listed path is not PROVABLY inside the scan root.

  Absolute entries and `..` segments are the ordinary cases. The guard is there for
  a third: `os.path.realpath` raises ValueError on an embedded NUL byte, and that is
  REACHABLE, because `git diff --name-only -z` is NUL-separated, so its whole dump
  arrives as one read line carrying NULs. Unguarded, that killed the entire scan on
  the first caller-supplied string it touched. A string the OS refuses to resolve
  cannot be shown to be contained, so it fails CLOSED into `paths_outside_root`
  alongside every other containment refusal rather than opening a fifth bucket.

  THIS GUARD MUST STAY AHEAD OF THE `os.path.isfile` CALL in `_iter_listed_files`.
  isfile swallows the same ValueError and answers False, so putting it first would
  move the abort to `paths_not_found` rather than remove it.
  """
  try:
    return not (os.path.realpath(abs_path) + os.sep).startswith(root_prefix)
  except ValueError:
    return True


def _iter_listed_files(root, config, tally):
  """Yield the listed paths that can be scanned; every other one lands in a drop bucket."""
  root_prefix = os.path.realpath(root) + os.sep
  for rel_path in sorted(config.only_paths):
    abs_path = os.path.join(root, rel_path)
    if _escapes_root(root_prefix, abs_path):
      tally.drop('outside_root')
      continue
    if _in_skipped_dir(rel_path):
      tally.drop('in_skipped_dir')
      continue
    if not os.path.isfile(abs_path):
      tally.drop('not_found')
      continue
    mode = scan_mode(rel_path, config.extra_generated, config.text_exts)
    if not mode:
      tally.drop('unsupported')
      continue
    yield abs_path, rel_path, mode


def _iter_walked_files(root, config):
  for current, dirs, files in os.walk(root):
    dirs[:] = [d for d in dirs if not is_skipped_dir(d)]
    for name in files:
      abs_path = os.path.join(current, name)
      rel_path = os.path.relpath(abs_path, root).replace(os.sep, '/')
      mode = scan_mode(rel_path, config.extra_generated, config.text_exts)
      if mode:
        yield abs_path, rel_path, mode


def iter_source_files(root, config, tally):
  if config.only_paths:
    return _iter_listed_files(root, config, tally)
  return _iter_walked_files(root, config)


def read_text(abs_path):
  try:
    if os.path.getsize(abs_path) > MAX_BYTES:
      return None
    with open(abs_path, encoding='utf-8', errors='strict') as handle:
      return handle.read()
  except (OSError, UnicodeDecodeError):
    return None


def _finalize(raw, rel_path):
  return [f for f in raw if not rule_exempt(f['rule_id'], rel_path)]


def scan_file(located, config):
  abs_path, rel_path, mode = located
  src = read_text(abs_path)
  if src is None:
    return None
  ctx = FileContext(rel_path, src)
  bans = config.extra_bans if not is_test(rel_path) else []
  if mode == 'text':
    return _finalize(ctx.run_text_only(config.max_file_lines, bans), rel_path)
  raw = ctx.run_all(config.max_file_lines)
  if bans:
    raw.extend(ctx.check_extra_bans(bans))
  return _finalize(raw, rel_path)


def run_scan(root, config):
  findings, tally = [], ScanTally()
  for located in iter_source_files(root, config, tally):
    result = scan_file(located, config)
    if result is None:
      tally.skipped += 1
      continue
    tally.scanned += 1
    findings.extend(result)
  return findings, tally


def build_stats(config, tally, finding_count):
  """Two reconciles, one per stage, each published as a subtraction rather than asserted.

  SCAN STAGE: `files_scanned + files_skipped + every paths_* bucket` MUST equal
  `config.scoped_paths`, and `paths_unaccounted` is that subtraction.

  PARSE STAGE: `config.scoped_paths + every lines_* bucket` MUST equal
  `config.listed_lines`, and `lines_unaccounted` is that one. The parse stage runs in
  FRONT of the scan stage, so a line lost here never reaches `scoped_paths` and the
  scan-stage reconcile reads a clean 0 over a list that had already shrunk.

  Both read 0 on a healthy run, and any future drop path added without its own bucket
  makes its stage non-zero, so the report says the scan lost inputs instead of quietly
  under-covering.
  """
  listing = config.path_lines
  stats = {'files_scanned': tally.scanned, 'files_skipped': tally.skipped}
  stats.update({f'paths_{reason}': tally.dropped[reason] for reason in DROP_REASONS})
  handed = len(config.only_paths)
  stats['paths_unaccounted'] = handed - tally.accounted() if handed else 0
  stats.update({f'lines_{reason}': listing.dropped[reason] for reason in PARSE_DROPS})
  stats['lines_unaccounted'] = listing.lines_read - listing.accounted()
  stats['findings'] = finding_count
  return stats


def build_report(root, config, result):
  findings, tally = result
  return {
    'schema_version': 1,
    'root': os.path.abspath(root),
    'config': {'max_file_lines': config.max_file_lines,
               'extra_bans': len(config.extra_bans),
               'text_only_exts': list(config.text_exts),
               'scoped_paths': len(config.only_paths),
               'listed_lines': config.path_lines.lines_read},
    'stats': build_stats(config, tally, len(findings)),
    'findings': sorted(findings, key=lambda f: (f['file'], f['line'])),
  }


def parse_args(argv):
  parser = argparse.ArgumentParser(description='lawkeeper deterministic scanner')
  parser.add_argument('root')
  parser.add_argument('--max-file-lines', type=int, default=500)
  parser.add_argument('--ban-patterns', default=None)
  parser.add_argument('--extra-generated', action='append', default=[])
  parser.add_argument('--text-only-ext', action='append', default=[])
  parser.add_argument('--paths-from', default=None)
  return parser.parse_args(argv)


def build_config(args):
  # `path_lines` is carried beside `only_paths`, not folded into it: `only_paths` is
  # the set the iterator walks and every caller reads it as one, while the parse
  # counters have to survive as far as build_stats to be reconciled at all.
  listing = load_paths_from(args.paths_from)
  return SimpleNamespace(
    max_file_lines=args.max_file_lines,
    extra_generated=tuple(args.extra_generated),
    extra_bans=load_extra_bans(args.ban_patterns),
    text_exts=_norm_exts(args.text_only_ext),
    only_paths=frozenset(listing.paths),
    path_lines=listing,
  )


def main(argv):
  args = parse_args(argv)
  if not os.path.isdir(args.root):
    print(f'lawkeeper: not a directory: {args.root}', file=sys.stderr)
    return 2
  config = build_config(args)
  report = build_report(args.root, config, run_scan(args.root, config))
  print(json.dumps(report, indent=2))
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))

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
those files instead of a whole-tree walk. SUPPLYING THE FLAG IS WHAT SCOPES THE RUN,
never the size of the list it points at. An empty list, or one whose every line the
parser drops, scans nothing; collapsing either into "no `--paths-from`" turned a
zero-path scope into a whole-tree walk that reported findings nobody asked for, over a
reconcile that was hardcoded to 0 in exactly that mode.

Every line handed in lands in exactly one counter, across TWO reconciles that chain:

  parse: `config.listed_lines` == `config.scoped_paths` + every `stats.lines_*` bucket
          (blank, comment, duplicate, malformed), and `stats.lines_unaccounted` is the
          remainder.
  scan:  `config.scoped_paths`  == files_scanned + every `stats.unread_*` bucket + every
          `stats.paths_*` bucket, and `stats.paths_unaccounted` is the remainder.

Both remainders read 0 on a healthy run. These are THREE families and not one because
this file's consumers sum drop buckets by NAME PREFIX. A parse bucket named `paths_*`
would inflate the scan total past `scoped_paths` and report a surplus that is not real,
and an unread file folded under `paths_*` gets summed into "covered" by every caller
that does it, which is how a 2.3MB file 400x over the line cap once passed for a clean
scan. A path that no longer exists is dropped into `paths_not_found`, which is EXPECTED,
not an error, a diff list names deleted files too; an `unread_*` file never is, it was
located and in scope and nothing in it was checked. Without `--paths-from` the whole
tree is walked, the default sweep, and every `paths_*` and `lines_*` bucket reads 0,
while `unread_*` still counts, because a file that could not be read is missing coverage
in every mode.

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
# helper sum the drop buckets BY NAME PREFIX, so a `paths_*` key here would inflate
# their total past `config.scoped_paths` and print a surplus that is not real.
PARSE_DROPS = ('blank', 'comment', 'duplicate', 'malformed')


class PathListing:
  """One parsed `--paths-from` file: the unique paths, plus why every other line went.

  `supplied` records whether the FLAG was given, which is a different question from
  whether the list produced any paths, and it is the one that decides scoped-vs-walk.
  """

  def __init__(self, supplied=False):
    self.supplied = supplied
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
  # A line that carries no path once normalized. `./` strips to `''`, which used to be
  # ADMITTED as a path, join to the root itself, fail `isfile`, and land in
  # `paths_not_found`, a bucket that means "the diff deleted this file" and so read as
  # expected. A bare `.` is the same shape from the same source: `find .`, named above
  # as a producer of this format, emits it as its very first line. Neither is a path,
  # so both are a PARSE-stage malformation and are counted as one.
  if rel in ('', '.'):
    return None, 'malformed'
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
  # `path is not None`, never truthiness: `--paths-from ''` (an unset shell variable
  # expanding to nothing) is a SUPPLIED flag pointing at no list, and must scan
  # nothing rather than quietly reverting to a whole-tree walk.
  listing = PathListing(supplied=path is not None)
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

# Why a located file yields no findings even though it WAS in scope. A THIRD family,
# `stats.unread_*`, for the same prefix-summing reason `lines_*` is a second one: these
# used to share one `files_skipped` counter that the documented reconcile added straight
# into `covered`, so a 2.3MB file 400x over the line cap reported as a balanced, clean
# scan. A `paths_*` name here would rejoin that sum and recreate it. Unlike a `paths_*`
# drop, a non-zero bucket here is NEVER expected: the file was found, in scope, and not
# one rule ran against it, which is missing coverage in scoped and whole-tree mode alike.
UNREAD_REASONS = ('too_large', 'unreadable')


class ScanTally:
  """Reconciling counters for one scan: every handed path lands in exactly one bucket."""

  def __init__(self):
    self.scanned = 0
    self.unread = dict.fromkeys(UNREAD_REASONS, 0)
    self.dropped = dict.fromkeys(DROP_REASONS, 0)

  def drop(self, reason):
    self.dropped[reason] += 1

  def accounted(self):
    return self.scanned + sum(self.unread.values()) + sum(self.dropped.values())


def _in_skipped_dir(rel_path):
  return any(is_skipped_dir(part) for part in rel_path.split('/')[:-1])


def _contained_path(root_prefix, abs_path):
  """The RESOLVED path when it is provably inside the scan root, else None.

  It hands back the resolved string rather than a yes/no because containment was
  decided on `os.path.realpath(abs_path)` while `os.path.isfile` and `open` then ran
  on the unresolved one. Two paths answering two questions about one entry is the
  check-then-use window of CWE-367: swap the symlink between the two and the file
  that was proved contained is not the file that gets read. Resolving ONCE and
  carrying that result forward closes it, and makes the ordering rule below
  structural instead of a comment somebody has to obey.

  Absolute entries and `..` segments are the ordinary refusals. The try is there for
  a third: `os.path.realpath` raises ValueError on an embedded NUL byte, and that is
  REACHABLE, because `git diff --name-only -z` is NUL-separated, so its whole dump
  arrives as one read line carrying NULs. Unguarded, that killed the entire scan on
  the first caller-supplied string it touched. A string the OS refuses to resolve
  cannot be shown to be contained, so it fails CLOSED into `paths_outside_root`
  alongside every other containment refusal rather than opening a fifth bucket.

  THIS RESOLUTION MUST STAY AHEAD OF THE `os.path.isfile` CALL in `_iter_listed_files`.
  isfile swallows the same ValueError and answers False, so putting it first would
  move the abort to `paths_not_found` rather than remove it. It now feeds isfile its
  argument, so the order cannot be reversed by accident.
  """
  try:
    real = os.path.realpath(abs_path)
  except ValueError:
    return None
  return real if (real + os.sep).startswith(root_prefix) else None


def _iter_listed_files(root, config, tally):
  """Yield the listed paths that can be scanned; every other one lands in a drop bucket."""
  root_prefix = os.path.realpath(root) + os.sep
  for rel_path in sorted(config.only_paths):
    # `rel_path` stays the LISTED name past this point: findings, carve-outs and the
    # caller's own diff list are all keyed on it, not on wherever a link resolved to.
    abs_path = _contained_path(root_prefix, os.path.join(root, rel_path))
    if abs_path is None:
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
  # BRANCH ON WHETHER THE FLAG WAS SUPPLIED, never on whether the list came out
  # non-empty. `--paths-from` pointing at an empty list, or at one whose every line
  # the parser dropped, is a scope of zero paths and must scan zero files; reading
  # it as "no list given" silently widened it to the whole tree.
  if config.path_lines.supplied:
    return _iter_listed_files(root, config, tally)
  return _iter_walked_files(root, config)


def read_text(abs_path):
  """`(source, None)` when the file was read, or `(None, reason)` naming why it was not.

  The reason is carried out rather than collapsed into a bare None because these two
  cases used to share one counter with no way to tell them apart: a file over the size
  ceiling (which the caller can fix by raising it, and which very often IS the cap
  finding) and a file the decoder refused (permissions, binary, non-UTF-8).
  """
  try:
    if os.path.getsize(abs_path) > MAX_BYTES:
      return None, 'too_large'
    with open(abs_path, encoding='utf-8', errors='strict') as handle:
      return handle.read(), None
  except (OSError, UnicodeDecodeError):
    return None, 'unreadable'


def _finalize(raw, rel_path):
  return [f for f in raw if not rule_exempt(f['rule_id'], rel_path)]


def scan_file(located, config):
  """`(findings, None)` for a file that was read, `(None, reason)` for one that was not."""
  abs_path, rel_path, mode = located
  src, unread = read_text(abs_path)
  if unread:
    return None, unread
  ctx = FileContext(rel_path, src)
  bans = config.extra_bans if not is_test(rel_path) else []
  if mode == 'text':
    return _finalize(ctx.run_text_only(config.max_file_lines, bans), rel_path), None
  raw = ctx.run_all(config.max_file_lines)
  if bans:
    raw.extend(ctx.check_extra_bans(bans))
  return _finalize(raw, rel_path), None


def run_scan(root, config):
  findings, tally = [], ScanTally()
  for located in iter_source_files(root, config, tally):
    result, unread = scan_file(located, config)
    if unread:
      tally.unread[unread] += 1
      continue
    tally.scanned += 1
    findings.extend(result)
  return findings, tally


def build_stats(config, tally, finding_count):
  """Two reconciles, one per stage, each published as a subtraction rather than asserted.

  SCAN STAGE: `files_scanned + every unread_* bucket + every paths_* bucket` MUST equal
  `config.scoped_paths`, and `paths_unaccounted` is that subtraction. Balancing is not
  the same as covering: an `unread_*` file balances the arithmetic and was checked by
  nothing, which is why it is counted apart from both `files_scanned` and `paths_*`.

  PARSE STAGE: `config.scoped_paths + every lines_* bucket` MUST equal
  `config.listed_lines`, and `lines_unaccounted` is that one. The parse stage runs in
  FRONT of the scan stage, so a line lost here never reaches `scoped_paths` and the
  scan-stage reconcile reads a clean 0 over a list that had already shrunk.

  Both read 0 on a healthy run, and any future drop path added without its own bucket
  makes its stage non-zero, so the report says the scan lost inputs instead of quietly
  under-covering.
  """
  listing = config.path_lines
  stats = {'files_scanned': tally.scanned}
  stats.update({f'unread_{reason}': tally.unread[reason] for reason in UNREAD_REASONS})
  stats.update({f'paths_{reason}': tally.dropped[reason] for reason in DROP_REASONS})
  handed = len(config.only_paths)
  # Published only for a run that WAS handed a list. A whole-tree sweep hands none, so
  # the subtraction would read negative rather than 0; the guard is on `supplied` and
  # not on `handed` because a supplied-but-empty list is a real scope of zero paths,
  # and hardcoding its reconcile to 0 is what hid the tree walk it used to become.
  stats['paths_unaccounted'] = handed - tally.accounted() if listing.supplied else 0
  stats.update({f'lines_{reason}': listing.dropped[reason] for reason in PARSE_DROPS})
  stats['lines_unaccounted'] = listing.lines_read - listing.accounted()
  stats['findings'] = finding_count
  return stats


def build_report(root, config, result):
  findings, tally = result
  return {
    'schema_version': 1,
    'root': os.path.abspath(root),
    # `path_list_supplied` is published because `scoped_paths: 0` alone cannot tell a
    # whole-tree sweep from a scoped run handed an empty list, and a reader that guesses
    # gets the two backwards: the first covers everything, the second covers nothing.
    'config': {'max_file_lines': config.max_file_lines,
               'extra_bans': len(config.extra_bans),
               'text_only_exts': list(config.text_exts),
               'path_list_supplied': config.path_lines.supplied,
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
  # A supplied `--paths-from` whose file is not there is the same silence as the empty
  # list one line over: the run would scope to zero paths, scan nothing, and print a
  # report indistinguishable from a clean one. Every real caller writes the list first.
  if args.paths_from is not None and not os.path.isfile(args.paths_from):
    print(f'lawkeeper: no such path list: {args.paths_from}', file=sys.stderr)
    return 2
  config = build_config(args)
  report = build_report(args.root, config, run_scan(args.root, config))
  print(json.dumps(report, indent=2))
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))

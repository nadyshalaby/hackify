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
those files instead of a whole-tree walk. Paths that no longer exist are ignored, a diff
list names deleted files too. Without it the whole tree is walked, the default sweep.

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


def load_paths_from(path):
  """Parse a newline-delimited path list (git diff --name-only shape) into a rel-path set."""
  if not path or not os.path.isfile(path):
    return frozenset()
  out = set()
  with open(path, encoding='utf-8', errors='replace') as handle:
    for raw in handle:
      rel = raw.strip().replace(os.sep, '/').lstrip('./')
      if rel and not rel.startswith('#'):
        out.add(rel)
  return frozenset(out)


def _in_skipped_dir(rel_path):
  return any(is_skipped_dir(part) for part in rel_path.split('/')[:-1])


def _iter_listed_files(root, config):
  """Yield only the explicitly listed paths, no tree walk. Missing paths are dropped."""
  for rel_path in sorted(config.only_paths):
    if _in_skipped_dir(rel_path):
      continue
    abs_path = os.path.join(root, rel_path)
    if not os.path.isfile(abs_path):
      continue
    mode = scan_mode(rel_path, config.extra_generated, config.text_exts)
    if mode:
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


def iter_source_files(root, config):
  if config.only_paths:
    return _iter_listed_files(root, config)
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
  findings, scanned, skipped = [], 0, 0
  for located in iter_source_files(root, config):
    result = scan_file(located, config)
    if result is None:
      skipped += 1
      continue
    scanned += 1
    findings.extend(result)
  return findings, scanned, skipped


def build_report(root, config, result):
  findings, scanned, skipped = result
  return {
    'schema_version': 1,
    'root': os.path.abspath(root),
    'config': {'max_file_lines': config.max_file_lines,
               'extra_bans': len(config.extra_bans),
               'text_only_exts': list(config.text_exts),
               'scoped_paths': len(config.only_paths)},
    'stats': {'files_scanned': scanned, 'files_skipped': skipped,
              'findings': len(findings)},
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
  return SimpleNamespace(
    max_file_lines=args.max_file_lines,
    extra_generated=tuple(args.extra_generated),
    extra_bans=load_extra_bans(args.ban_patterns),
    text_exts=_norm_exts(args.text_only_ext),
    only_paths=load_paths_from(args.paths_from),
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

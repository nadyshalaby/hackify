#!/usr/bin/env python3
"""Enforce the wizard-contract Clarity law on every question bank.

The rule the banks kept breaking: a question the user cannot answer without
knowing how hackify works internally. Task IDs, phase numbers, and internal
artifact names (DoD, work-doc, wave, sub-agent, Reviewer B) leaked into the
text the USER reads, while `Why-this-matters` is model-facing and may keep
every one of those words.

So this checker splits each bank by audience and only polices the
user-facing half:

  user-facing   `- Text:` lines, option label lines, `- What happens:` lines
  model-facing  `- Why-this-matters:`, SCENARIO, COMPOSITION, EXIT CRITERIA

Checks per question: no banned token in user-facing text, every option
carries a `What happens:` description, and that description is not just the
label restated.

Usage: python3 scripts/check_question_clarity.py [bank-dir]
Exit 0 when every bank conforms, 1 otherwise. Prints one line per defect.
"""

import os
import re
import sys

DEFAULT_DIR = 'skills/hackify/references/clarify-questions'
NON_BANKS = frozenset({'README.md', 'wizard-contract.md', 'picking-and-combining.md'})

# Tokens that must never reach the user. Word-boundary anchored so "Taskbar"
# and "phased" do not false-fire.
BANNED = (
  (r'\b[TDQW]\d+\b', 'work-doc identifier'),
  (r'\bAC\d+\b', 'acceptance-criteria identifier'),
  (r'\bPhase\s+\d', 'phase reference'),
  (r'\bWave\s+\d', 'wave reference'),
  (r'\bDoD\b', 'internal artifact name'),
  (r'\bwork-doc\b', 'internal artifact name'),
  (r'\bSprint Backlog\b', 'internal artifact name'),
  (r'\bDaily Updates\b', 'internal artifact name'),
  (r'\bgoal anchor\b', 'internal artifact name'),
  (r'\bsub-?agents?\b', 'internal machinery'),
  (r'\bperf-scout\b', 'internal machinery'),
  (r'\blaw-scout\b', 'internal machinery'),
  (r'\bship gate\b', 'internal machinery'),
  (r'\bphase ledger\b', 'internal machinery'),
  (r'\bdecision table\b', 'internal machinery'),
  (r'\bReviewer [A-F]\b', 'internal machinery'),
)

TEXT_RE = re.compile(r'^- Text:\s*(.+)$')
OPTION_RE = re.compile(r'^  - ([A-D])\.\s*(.+?)\s*(?:\(Recommended\))?\s*$')
HAPPENS_RE = re.compile(r'^    - What happens:\s*(.+)$')
QUESTION_RE = re.compile(r'^Q\d+[a-z]?\.\s', re.M)


def user_facing_lines(path):
  """Yield (lineno, kind, payload) for every line the USER reads."""
  with open(path, encoding='utf-8') as handle:
    for lineno, raw in enumerate(handle, 1):
      line = raw.rstrip('\n')
      for kind, regex in (('text', TEXT_RE), ('option', OPTION_RE), ('happens', HAPPENS_RE)):
        match = regex.match(line)
        if match:
          yield lineno, kind, match.groups()[-1]
          break


def check_banned(path, defects):
  for lineno, _, payload in user_facing_lines(path):
    for pattern, why in BANNED:
      hit = re.search(pattern, payload)
      if hit:
        defects.append(f'{path}:{lineno}: user-facing text contains {why} "{hit.group(0)}"')


def _iter_option_blocks(lines):
  """Yield (lineno, label, description_or_None) for every option in the file."""
  pending = None
  for lineno, raw in enumerate(lines, 1):
    line = raw.rstrip('\n')
    option = OPTION_RE.match(line)
    if option:
      if pending:
        yield pending[0], pending[1], None
      pending = (lineno, option.group(2))
      continue
    happens = HAPPENS_RE.match(line)
    if happens and pending:
      yield pending[0], pending[1], happens.group(1)
      pending = None
      continue
    if line.strip() and not line.startswith('    ') and pending:
      yield pending[0], pending[1], None
      pending = None
  if pending:
    yield pending[0], pending[1], None


def _normalize(text):
  return re.sub(r'[^a-z0-9 ]', '', text.lower()).strip()


def check_descriptions(path, defects):
  with open(path, encoding='utf-8') as handle:
    lines = handle.readlines()
  for lineno, label, description in _iter_option_blocks(lines):
    if description is None:
      defects.append(f'{path}:{lineno}: option "{label}" has no "What happens:" description')
      continue
    if _normalize(description) == _normalize(label):
      defects.append(f'{path}:{lineno}: option "{label}" description restates the label')


DEFINED_RE = re.compile(r'^(Q\d+[a-z]?)\.\s', re.M)
REFERENCED_RE = re.compile(r'\b(Q\d+[a-z]?)\b')


def check_dangling_refs(path, body, defects):
  """COMPOSITION and EXIT CRITERIA must not cite a question the bank dropped."""
  defined = set(DEFINED_RE.findall(body))
  prose = re.sub(r'^Q\d+[a-z]?\..*?(?=^Q\d+[a-z]?\.|\Z)', '', body, flags=re.M | re.S)
  for ref in sorted(set(REFERENCED_RE.findall(prose)) - defined):
    defects.append(f'{path}: COMPOSITION/EXIT cites "{ref}" but no such question is defined')


def check_bank(path, defects):
  with open(path, encoding='utf-8') as handle:
    body = handle.read()
  if not QUESTION_RE.search(body):
    defects.append(f'{path}: no Q<n>. questions found (not a conforming bank)')
    return
  check_banned(path, defects)
  check_descriptions(path, defects)
  check_dangling_refs(path, body, defects)


def main(argv):
  bank_dir = argv[0] if argv else DEFAULT_DIR
  if not os.path.isdir(bank_dir):
    print(f'not a directory: {bank_dir}', file=sys.stderr)
    return 2
  banks = sorted(f for f in os.listdir(bank_dir)
                 if f.endswith('.md') and f not in NON_BANKS)
  if not banks:
    print(f'no bank files found in {bank_dir}', file=sys.stderr)
    return 2
  defects = []
  for name in banks:
    check_bank(os.path.join(bank_dir, name), defects)
  for line in defects:
    print(line)
  print(f'{len(banks)} banks checked, {len(defects)} defect(s)')
  return 1 if defects else 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))

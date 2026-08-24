#!/usr/bin/env python3
"""Loading, parsing and validation for scripts/claim_fixtures.json.

Every rule enforced here exists because there is a way for a fixture to look
healthy while proving nothing, and each rule closes one of them. That is worth
saying up front, because read cold, several of these look like schema pedantry.
They are not. In order of how badly each one bites:

  A PINNED FILE MUST RECORD ITS BYTE SIZE. Three witnesses in the manifest assert
  that a literal occurs ZERO times. An absent-polarity witness passes perfectly
  against a file that materialised EMPTY, so absence alone can never prove the
  replay worked. Size is the independent second proof, and _materialise asserts
  it alongside the content hash.

  A WORKTREE WITNESS MAY NOT FREEZE A COUNT OR A LINE NUMBER. Blob-pinned content
  cannot drift, so a line number against it is permanent and gets asserted
  exactly. Worktree content is free to move under you, and this is not
  theoretical: while this mechanism was being written,
  scripts/validate-dod.d/71-release-mechanism-pins.sh had uncommitted edits at
  the start of the session and none by the end. A number frozen against that is a
  stale claim in waiting, which is precisely the defect class these fixtures
  serve to catch. Refusing it in the validator makes the argument executable
  instead of a comment somebody can talk themselves out of.

  A FIXTURE MUST SAY WHICH SITE IT SCORES. Corpus note n5: I2's filed site was
  fixed while three same-class siblings stayed live, so counting a sibling as the
  filed finding is a judgement, not an accident. `scored_as` may not be blank.

  A PINNED PATH MAY NOT ESCAPE THE SCOPE. The manifest is data that gets joined
  onto a temp dir and written to disk. `../` in that data writes outside it.

  A WITNESS MUST NAME A FILE ITS FIXTURE PINS. A check can only read what the
  replay materialises, and a witness pointing anywhere else would be silently
  skipped, or worse, silently satisfied by whatever happens to be at that path.

ONE DELIBERATE OMISSION, RECORDED SO IT IS NOT REDISCOVERED AS A BUG. I2 pins
only the instruction site. A C6 section-exists check also wants the work-doc
template to compare against, which at that same commit is blob
befddaeed2116a95c6cbffb33b58337b89affe7a
(6495b2b23450d5257e999716d15a00565888f44f:skills/hackify/references/work-doc-template.md).
It is left out because the fixture set was specified with one blob for I2, and
quietly widening a pinned set so a later check scores better is the exact move
this sprint exists to catch. Adding it is a one-line manifest edit and needs no
code change here.
"""

import json
from pathlib import Path

from claim_fixture_git import is_sha
from claim_fixture_types import FixtureSpec, ManifestError, PinnedFile, Witness

MANIFEST_PATH = Path(__file__).resolve().parent / 'claim_fixtures.json'

# `blobs` replays pinned history. `worktree` scores the files on disk now. The
# second is a full member of this set, not a fallback: I4 was re-routed out of
# the previous sprint unfixed, so it needs no fixture and never will.
KINDS = ('blobs', 'worktree')

# Both directions matter. C7 was widened to both polarities by decision 13-A, and
# M4 is the absent direction: a CHANGELOG bullet claiming a token reached two
# files it never reached.
POLARITIES = ('present', 'absent')


def load_manifest(path=MANIFEST_PATH):
  """Read and validate the manifest. Returns a tuple of FixtureSpec."""
  if not path.is_file():
    raise ManifestError('manifest not found at %s' % path)
  try:
    raw = json.loads(path.read_text(encoding='utf-8'))
  except (OSError, ValueError) as exc:
    raise ManifestError('cannot read %s: %s' % (path, exc)) from exc
  if not isinstance(raw, dict) or not isinstance(raw.get('fixtures'), list):
    raise ManifestError('%s must hold an object carrying a fixtures list' % path)
  specs = tuple(_parse_fixture(entry) for entry in raw['fixtures'])
  # An empty list parses fine and then verifies fine, reporting a confident green
  # over nothing at all. Same failure shape as the ok-line floor in validate-dod.
  if not specs:
    raise ManifestError('%s carries no fixtures' % path)
  _reject_duplicate_ids(specs)
  return specs


def _parse_fixture(entry):
  """One manifest entry to a validated FixtureSpec."""
  if not isinstance(entry, dict):
    raise ManifestError('a fixtures entry is not an object')
  ident = entry.get('id')
  if not isinstance(ident, str) or not ident:
    raise ManifestError('a fixtures entry has no id')
  kind = entry.get('kind')
  if kind not in KINDS:
    raise ManifestError('fixture %s has kind %r, expected one of %s'
                        % (ident, kind, ', '.join(KINDS)))
  scored = entry.get('scored_as')
  if not isinstance(scored, str) or not scored.strip():
    raise ManifestError('fixture %s must say which site it scores. Corpus note n5 requires '
                        'that call written down: a sibling hit is not the filed finding' % ident)
  spec = FixtureSpec(ident, kind, scored,
                     tuple(_parse_file(ident, f) for f in entry.get('files', ())),
                     tuple(_parse_witness(ident, kind, w)
                           for w in entry.get('witnesses', ())))
  _check_kind_rules(spec)
  return spec


def _parse_file(ident, raw):
  """One pinned file. Every field is mandatory, size included."""
  if not isinstance(raw, dict):
    raise ManifestError('fixture %s has a files entry that is not an object' % ident)
  path, blob = raw.get('path'), raw.get('blob')
  size, commit = raw.get('size'), raw.get('commit')
  if not isinstance(path, str) or not path:
    raise ManifestError('fixture %s has a files entry with no path' % ident)
  # This path is joined onto a temp dir and written. Absolute or `..` writes out.
  if path.startswith('/') or '..' in Path(path).parts:
    raise ManifestError('fixture %s pins %r, which escapes the replay scope. A pinned path '
                        'is repo-relative and stays inside the temp dir' % (ident, path))
  if not is_sha(blob):
    raise ManifestError('fixture %s pins %s with %r, which is not a 40-char lowercase '
                        'hex blob sha' % (ident, path, blob))
  if not is_sha(commit):
    raise ManifestError('fixture %s records commit %r for %s, which is not a full '
                        '40-char sha' % (ident, commit, path))
  if not _is_size(size):
    raise ManifestError('fixture %s must record a byte size for %s. It is the second, '
                        'independent proof that materialisation produced real content, and '
                        'an absent witness passes happily against an empty file' % (ident, path))
  return PinnedFile(path, blob, size, commit, str(raw.get('origin_note', '')))


def _is_size(value):
  """A non-negative int. bool is an int in Python, so it is excluded on purpose:
  `True` would otherwise sail through as the size 1 and pin nothing useful."""
  return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def _parse_witness(ident, kind, raw):
  """One witness, with the numeric fields governed by the kind it belongs to."""
  if not isinstance(raw, dict):
    raise ManifestError('fixture %s has a witness that is not an object' % ident)
  path, polarity = raw.get('path'), raw.get('polarity')
  literal = raw.get('literal')
  if not isinstance(path, str) or not path:
    raise ManifestError('fixture %s has a witness with no path' % ident)
  if polarity not in POLARITIES:
    raise ManifestError('fixture %s witness on %s has polarity %r, expected one of %s'
                        % (ident, path, polarity, ', '.join(POLARITIES)))
  if not isinstance(literal, str) or not literal:
    raise ManifestError('fixture %s witness on %s has no literal' % (ident, path))
  return Witness(path, polarity, literal, *_witness_numbers(ident, kind, raw))


def _witness_numbers(ident, kind, raw):
  """The count and lines pair, refused outright on worktree content.

  See the module docstring for the argument. Short version: blob-pinned content
  is hashed, so a number against it is permanent and gets asserted exactly.
  Worktree content moved under this very session, so a number against it is a
  stale claim waiting to happen."""
  count, lines = raw.get('count'), raw.get('lines')
  where = 'fixture %s witness on %s' % (ident, raw.get('path'))
  if kind == 'worktree' and (count is not None or lines is not None):
    raise ManifestError('%s freezes a count or line number against worktree content, and '
                        'only a blob pin makes those safe to record' % where)
  if count is not None and not _is_size(count):
    raise ManifestError('%s has count %r, expected a non-negative integer' % (where, count))
  if lines is not None and not _is_line_list(lines):
    raise ManifestError('%s has lines %r, expected a non-empty list of positive integers'
                        % (where, lines))
  return count, tuple(lines) if lines is not None else None


def _is_line_list(values):
  """A non-empty list of 1-based line numbers, and nothing else. Empty would assert
  that the literal appears on no line, which `polarity: absent` already says."""
  return (isinstance(values, list) and bool(values)
          and all(_is_size(v) and v > 0 for v in values))


def _check_kind_rules(spec):
  """Cross-field rules that can only be decided once the whole entry is parsed."""
  if spec.kind == 'blobs' and not spec.files:
    raise ManifestError('fixture %s is kind blobs but pins no files' % spec.ident)
  if spec.kind == 'worktree' and spec.files:
    raise ManifestError('fixture %s is kind worktree, so the worktree is its source and it '
                        'must pin no files' % spec.ident)
  # A fixture with no witnesses materialises, reports success, and proves nothing.
  if not spec.witnesses:
    raise ManifestError('fixture %s carries no witnesses, so nothing proves it holds the '
                        'defect it claims' % spec.ident)
  _reject_duplicate_paths(spec)
  if spec.kind != 'blobs':
    return
  declared = {f.path for f in spec.files}
  stray = sorted({w.path for w in spec.witnesses} - declared)
  if stray:
    raise ManifestError('fixture %s witnesses %s, which it does not pin, and a check can '
                        'only read what the replay materialises' % (spec.ident, ', '.join(stray)))


def _reject_duplicate_paths(spec):
  """Two pins on one path would make the replayed content depend on write order,
  so the fixture would hold whichever blob happened to be listed second."""
  seen = set()
  for pinned in spec.files:
    if pinned.path in seen:
      raise ManifestError('fixture %s pins %s twice' % (spec.ident, pinned.path))
    seen.add(pinned.path)


def _reject_duplicate_ids(specs):
  """One entry per finding id. Two entries for one finding means a scorer reads
  whichever it hit first, and the corpus is an answer key with one answer."""
  seen = set()
  for spec in specs:
    if spec.ident in seen:
      raise ManifestError('fixture id %s appears more than once' % spec.ident)
    seen.add(spec.ident)

#!/usr/bin/env python3
"""Replay sources for the claim-integrity check, pinned by git blob SHA.

Three of the four must_catch findings in claim_corpus.json were FIXED before this
sprint opened, so a check run over the tree as it stands cannot score them. This
package materialises the historical content each defect was live in, from a
pinned blob. The fourth finding is still on disk and is scored against the
worktree instead, which is a first-class kind here and not a special case.

    python3 scripts/claim_fixtures.py     # prove every fixture holds its defect
    from claim_fixtures import replay_scope                  # or, from a check
    from claim_fixture_manifest import load_manifest
    for spec in load_manifest():
      with replay_scope(spec) as scope:
        run_the_check(scope.root, scope.paths)

The set is four modules, split by concern:

    claim_fixture_types.py      exceptions and records
    claim_fixture_git.py        pins in, bytes out, fail-closed
    claim_fixture_manifest.py   loading, parsing, validation rules
    claim_fixtures.py           this file: replay, verification, CLI

WHY A BLOB SHA AND NOT A COPIED SNAPSHOT, since this is the decision everything
else rests on. The obvious way to build fixtures is to copy the old file content
into the repo under a fixtures/ directory. That copy is itself an unverifiable
claim about history: nothing in the tree can tell you it matches what was really
there, and the moment someone tidies it, nothing tells you it stopped matching.
Unverifiable claims about the past are the precise defect this whole sprint
exists to catch, so building the catcher out of one would have been absurd. A
blob SHA is a hash of the content, so "this is what was live at that commit" is
checkable rather than asserted, and the pin cannot drift because changing the
content changes the name.

WHY WITNESSES ARE PROVED TWICE. Every materialised file must hash back to its
pinned blob AND match a recorded byte size. Belt and braces looks redundant until
you notice that three witnesses in claim_fixtures.json assert a literal occurs
ZERO times. An empty file satisfies every one of them, instantly and silently.
So absence can never be self-certifying here: something independent has to prove
the replay actually produced content, and that is what the size assertion is for.

Nothing here writes into the worktree, and nothing here writes claim_corpus.json.

Exit codes: 0 every fixture holds its defect, 1 a witness or provenance check
failed, 2 the manifest is missing or malformed, 3 a blob or path could not be read.
"""

import shutil
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

from claim_fixture_git import REPO_ROOT, blob_sha_of, read_blob, resolve_historical_blob
from claim_fixture_manifest import MANIFEST_PATH, load_manifest
from claim_fixture_types import (BlobPinError, FixtureError, ManifestError, ReplayScope,
                                 WitnessError)

EXIT_OK = 0
EXIT_WITNESS = 1
EXIT_MANIFEST = 2
EXIT_REPLAY = 3


def count_literal(data, literal):
  """Occurrences of `literal` in `data`, matched as raw BYTES.

  LITERAL, ALWAYS. Nothing from the manifest is compiled to a regex, interpolated
  into a shell command, or evaluated, and this function is where that would
  otherwise begin. The failure being designed out is not subtle: a validator that
  builds its patterns from text it reads out of markdown lets anyone with commit
  access to a doc run code inside the validator. `str.count` cannot be talked into
  that, and it is also faster than the alternative.

  Bytes rather than str removes the decode step entirely, so no file with an odd
  encoding can throw a UnicodeDecodeError out of the middle of a scan wearing no
  label. There is nothing here that needs to know what a character is."""
  needle = literal.encode('utf-8')
  if not needle:
    raise WitnessError('an empty literal matches everywhere and proves nothing')
  return data.count(needle)


def literal_lines(data, literal):
  """1-based numbers of the lines carrying `literal`. Byte-wise, as above.

  Line-based, which is a known limitation rather than an oversight: corpus finding
  M2 is precisely that a literal split across a hard line break is invisible to a
  line-based scan. Every literal pinned in the manifest was measured to sit on one
  physical line, and corpus note n8 records that I4's reachability depends on that
  wrap holding."""
  needle = literal.encode('utf-8')
  return [n for n, line in enumerate(data.splitlines(), 1) if needle in line]


@contextmanager
def replay_scope(spec, repo_root=REPO_ROOT):
  """Yield a ReplayScope a check can run against, then clean up after it.

  A blobs fixture materialises into a fresh temp dir, never into the worktree. A
  worktree fixture yields the repository root untouched. Same type, same fields,
  so a consumer never branches on kind.

  DELETION AUTHORITY LIVES IN ONE LOCAL AND NOWHERE ELSE. Read that again with the
  worktree branch in mind: on that path, `scope.root` IS the repository root. Any
  cleanup rule phrased as "remove scope.root" or "remove it unless root equals
  repo_root" is one careless refactor away from deleting the user's repo. So the
  temp dir is held in `created`, `created` is assigned by exactly one expression
  (mkdtemp), and `created` is the only thing rmtree is ever pointed at. It is
  deliberately NOT a field on ReplayScope, because a field is something a future
  caller can set. ignore_errors keeps a cleanup hiccup from masking the real
  result, which is the verdict the caller came for."""
  created = None
  try:
    if spec.kind == 'worktree':
      yield ReplayScope(spec.ident, spec.kind, Path(repo_root),
                        tuple(w.path for w in spec.witnesses))
      return
    created = Path(tempfile.mkdtemp(prefix='claim-fixture-%s-' % spec.ident))
    for pinned in spec.files:
      _materialise(pinned, created, repo_root)
    yield ReplayScope(spec.ident, spec.kind, created, tuple(f.path for f in spec.files))
  finally:
    if created is not None:
      shutil.rmtree(created, ignore_errors=True)


def _materialise(pinned, root, repo_root):
  """Write one pinned blob into the scope, then prove what was written.

  The hash check catches wrong content. The size check catches empty content,
  which the hash would also catch, and that overlap is intentional: these are the
  two proofs an absent-polarity witness cannot supply for itself, and the cost of
  keeping both is two comparisons. The size is also the half a human can audit by
  eye against `git cat-file -s`, which keeps the manifest readable as evidence
  rather than only as input."""
  data = read_blob(pinned.blob, repo_root)
  actual = blob_sha_of(data)
  if actual != pinned.blob:
    raise BlobPinError('%s read back as blob %s, not the pinned %s'
                       % (pinned.path, actual, pinned.blob))
  if len(data) != pinned.size:
    raise BlobPinError('%s materialised at %d bytes, and the manifest pins %d'
                       % (pinned.path, len(data), pinned.size))
  target = root / pinned.path
  target.parent.mkdir(parents=True, exist_ok=True)
  target.write_bytes(data)
  return target


def check_provenance(spec, repo_root=REPO_ROOT):
  """Confirm every pin still resolves from the commit and path it claims.

  This is what turns recorded provenance from a comment into a checkable
  statement. It also does something the tests alone would not: it puts the
  loud-failure path on the PRODUCTION route. If a pinned path were ever renamed
  away under its commit, this raises during a normal run, rather than the
  mechanism quietly relying on a behaviour only the suite ever exercises."""
  mismatches = []
  for pinned in spec.files:
    found = resolve_historical_blob(pinned.commit, pinned.path, repo_root)
    if found != pinned.blob:
      mismatches.append('%s: %s at %s resolves to blob %s, not the pinned %s'
                        % (spec.ident, pinned.path, pinned.commit, found, pinned.blob))
  return mismatches


def check_witnesses(scope, spec):
  """Check every witness against the replayed content. Returns failure lines.

  A witness naming a file the scope does not hold is a FAILURE, never a silent
  zero. Same rule the blob reader follows and for the same reason: a check that
  did not run must never be reported as a check that found nothing."""
  failures = []
  for witness in spec.witnesses:
    target = scope.root / witness.path
    if not target.is_file():
      failures.append('%s: %s is not in the replay scope, so nothing was checked'
                      % (spec.ident, witness.path))
      continue
    failures.extend(_check_one(witness, target.read_bytes(), spec.ident))
  return failures


def _check_one(witness, data, ident):
  """Polarity first, then the exact count and the exact lines when pinned.

  Not elif. A present-polarity witness that also pins a count wants BOTH answers,
  because "the literal vanished" and "the literal is now on four lines instead of
  three" are different reports and a reader deserves the one that happened."""
  found = count_literal(data, witness.literal)
  where = '%s: %s' % (ident, witness.path)
  failures = []
  if witness.polarity == 'present' and found == 0:
    failures.append('%s does not carry %r, so this fixture is not holding its defect'
                    % (where, witness.literal))
  if witness.polarity == 'absent' and found != 0:
    failures.append('%s carries %r %d times, and the finding needs it absent'
                    % (where, witness.literal, found))
  if witness.count is not None and found != witness.count:
    failures.append('%s carries %r %d times, and the manifest pins %d'
                    % (where, witness.literal, found, witness.count))
  if witness.lines is not None:
    failures.extend(_check_lines(witness, data, where))
  return failures


def _check_lines(witness, data, where):
  """Exact line match, not a subset check. Only blob-pinned content reaches here,
  because the manifest validator refuses line numbers on anything else, and a
  content hash is what makes an exact assertion the honest one to make."""
  found = tuple(literal_lines(data, witness.literal))
  if found == witness.lines:
    return []
  return ['%s carries %r on lines %s, and the manifest pins %s'
          % (where, witness.literal, list(found), list(witness.lines))]


def verify(specs, repo_root=REPO_ROOT):
  """Materialise every fixture, check provenance and witnesses, print as it goes.

  Prints the scope root for each fixture because the single most useful thing when
  this goes wrong is knowing whether a replay landed in a temp dir or in the
  worktree."""
  failures = []
  for spec in specs:
    with replay_scope(spec, repo_root) as scope:
      print('  %-4s %-9s %d path(s) under %s' % (spec.ident, spec.kind,
                                                 len(scope.paths), scope.root))
      failures.extend(check_provenance(spec, repo_root))
      failures.extend(check_witnesses(scope, spec))
  return failures


def main(_argv):
  """Load, materialise, check, report. Returns the process exit code.

  No --list flag: what is pinned and why is readable straight out of
  claim_fixtures.json, and a second renderer of the same data is one more thing
  that can disagree with it."""
  try:
    specs = load_manifest()
  except ManifestError as exc:
    print('manifest error: %s' % exc, file=sys.stderr)
    return EXIT_MANIFEST
  print('Claim fixtures, manifest %s' % MANIFEST_PATH)
  try:
    failures = verify(specs)
  except FixtureError as exc:
    print('replay error: %s' % exc, file=sys.stderr)
    return EXIT_REPLAY
  print()
  if failures:
    print('%d check(s) failed:' % len(failures))
    for line in failures:
      print('  FAIL %s' % line)
    return EXIT_WITNESS
  print('ok, all %d fixtures materialise and carry their defect' % len(specs))
  return EXIT_OK


if __name__ == '__main__':
  sys.exit(main(sys.argv))

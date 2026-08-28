#!/usr/bin/env python3
"""Git plumbing for the claim-fixture replay mechanism: pins in, bytes out.

Every route from a pinned SHA to real content passes through here, which is why
it is one module: the fail-closed discipline below only works if there is no
second, more relaxed way to read a blob somewhere else in the tree.

TWO RULES GOVERN EVERY FUNCTION IN THIS FILE.

  1. GIT IS CALLED WITH AN ARGV LIST AND NEVER THROUGH A SHELL. Nothing read from
     a repository file is interpolated into a command, compiled into a pattern, or
     evaluated. The whole point of the check these fixtures serve is that a
     validator which runs strings out of markdown turns editing a doc into code
     execution, and this file is where that would begin if it began anywhere.

  2. A FAILED READ RAISES. It never returns empty bytes. This is the same shape as
     scripts/validate-dod.d/73-implementer-rename.sh's wi_absent, where rc 1 with
     anything on stderr means the scan never ran and is therefore never a green.
     The reasoning carries over exactly: a scan that could not finish tells you
     nothing trustworthy, and three of the witnesses in claim_fixtures.json assert
     that a literal occurs ZERO times, which an empty file satisfies perfectly.
"""

import hashlib
import subprocess
from pathlib import Path

from claim_fixture_types import BlobPinError, HistoricalPathError

# The repository every git call in this mechanism runs against. Defined here
# rather than in a shared constants module because "which repo do we ask" is a
# git concern, and this is the git module. Callers import it from here.
REPO_ROOT = Path(__file__).resolve().parent.parent

SHA_LEN = 40
HEX_DIGITS = frozenset('0123456789abcdef')


def is_sha(value):
  """True for a 40-char lowercase hex string, the only pin shape accepted anywhere.

  DELIBERATELY NOT A REGEX. There is no pattern here worth compiling, and keeping
  the `re` module out of this package entirely means no later edit can casually
  reach for it and then, just as casually, build one out of manifest data. The
  cost of a set membership test in a comprehension is nothing; the cost of a
  regex habit in a module that reads attacker-editable JSON is the whole sprint.

  Lowercase only, on purpose. git emits lowercase, so an uppercase pin is a sign
  the value was retyped by hand rather than measured, and retyped is exactly the
  provenance this mechanism refuses."""
  return (isinstance(value, str) and len(value) == SHA_LEN
          and all(ch in HEX_DIGITS for ch in value))


def blob_sha_of(data):
  """git's own blob hash for these bytes: sha1 over 'blob <len>\\0' plus content.

  COMPUTED HERE RATHER THAN ASKED OF GIT. The point of hashing materialised bytes
  is to prove the read produced the content the manifest pinned. Asking the same
  tool that performed the read to also grade the read is a circular proof, and
  reimplementing git's twelve-byte header format is cheap enough that there is no
  reason to accept one. This is not a security hash, it is a content identity
  check against a format git fixed long ago."""
  return hashlib.sha1(b'blob %d\0' % len(data) + data).hexdigest()


def _git(args, repo_root):
  """Run git with an argv LIST and no shell, ever.

  `check=False` is deliberate rather than lazy: every caller inspects the return
  code AND stderr itself, and turns the pair into a specific exception carrying a
  message that says what the reader should do about it. CalledProcessError would
  throw away that distinction, and the distinction is the product here."""
  return subprocess.run(['git', '-C', str(repo_root), *args],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def _text(raw):
  """Bytes from git to a stripped string, never raising on odd encodings.

  'replace' rather than 'strict' because this only ever decodes git's own
  diagnostics for an error message, and an error message that itself throws while
  being built loses the original failure. The content path never decodes at all."""
  return raw.decode('utf-8', 'replace').strip()


def read_blob(sha, repo_root=REPO_ROOT):
  """Read one pinned blob, fail-closed at every step.

  Three gates, each closing a different way to end up holding nothing while
  believing you hold something:

    the pin must be shaped like a sha, so a typo cannot become a lookup;
    the object must EXIST and be a BLOB, because a tree or a commit resolves
      happily and produces bytes that are not the file;
    the read must exit 0 with a clean stderr, because rc 1 with a message on
      stderr means the read never happened.

  That last one is the load-bearing gate and the least obvious. It is lifted from
  73-implementer-rename.sh, where the same reasoning is spelled out at length: a
  file git could not read must never be counted as a file with nothing in it."""
  if not is_sha(sha):
    raise BlobPinError('blob pin %r is not a 40-char lowercase hex sha' % (sha,))
  kind = _git(['cat-file', '-t', sha], repo_root)
  if kind.returncode != 0:
    raise BlobPinError('git cannot read object %s: %s' % (sha, _text(kind.stderr)))
  named = _text(kind.stdout)
  if named != 'blob':
    raise BlobPinError('object %s is a %s, not a blob, and only a blob pins content'
                       % (sha, named or '<nothing>'))
  read = _git(['cat-file', 'blob', sha], repo_root)
  if read.returncode != 0 or read.stderr.strip():
    raise BlobPinError('reading blob %s exited %d and said %r, so its content is '
                       'unknown rather than empty'
                       % (sha, read.returncode, _text(read.stderr)))
  return read.stdout


def resolve_historical_blob(commit, path, repo_root=REPO_ROOT):
  """Blob SHA for `path` at `commit`, or a loud failure.

  THE TRAP THIS EXISTS TO STOP, stated concretely because it caught a human on
  this very sprint: agents/wave-implementer.md was renamed from
  agents/wave-task-implementer.md at 58c1118. Ask git for the OLD name at any
  commit after that rename and you get no content. Pipe that into `grep -c` and
  you get 0. Zero hits is indistinguishable from "the defect was fixed", so the
  false answer arrives wearing the exact costume of the true one.

  So: a path that does not resolve RAISES, and the result is shape-checked on top
  of the return code. The shape check is not belt and braces, it is load-bearing.
  Plain `git rev-parse foo:bar` prints its own ARGUMENT back to stdout when the
  path is missing, so a caller reading only stdout gets a plausible-looking string
  that is not a SHA. `--verify` suppresses that echo, and is_sha catches it even
  if a future git changes its mind."""
  if not is_sha(commit):
    raise HistoricalPathError('commit pin %r is not a full 40-char lowercase hex sha; an '
                              'abbreviated or relative commit-ish is an expression, not a '
                              'pin' % (commit,))
  # Leading dash would be read by git as an option rather than a pathspec.
  if not isinstance(path, str) or not path or path.startswith('-'):
    raise HistoricalPathError('%r is not a usable repository path' % (path,))
  found = _git(['rev-parse', '--verify', '%s:%s' % (commit, path)], repo_root)
  out = _text(found.stdout)
  if found.returncode != 0 or not is_sha(out):
    raise HistoricalPathError(
        '%s:%s does not resolve to a blob (git exited %d and said %r). A path that is '
        'missing or renamed at a commit is NOT an empty file, and reporting it as one '
        'would read exactly like a clean scan.'
        % (commit, path, found.returncode, _text(found.stderr)))
  return out

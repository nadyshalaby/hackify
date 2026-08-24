#!/usr/bin/env python3
"""Exception and record types for the claim-fixture replay mechanism.

These live in their own module for one reason worth stating: every other module
in the set raises from this hierarchy, so putting the hierarchy anywhere else
makes two of them import a third for its side effects. Here, the dependency
graph is a fan-in with no cycles.

    claim_fixture_types      (this file, depends on nothing)
      <- claim_fixture_git         (blob reading and hashing)
      <- claim_fixture_manifest    (loading, parsing, validation)
      <- claim_fixtures            (replay, verification, CLI)

THE EXCEPTION HIERARCHY ENCODES ONE DISTINCTION, and it is the distinction the
whole sprint is about: content that is UNKNOWN is not content that is EMPTY.
A blob that could not be read, a path that does not resolve at a commit, a
manifest that will not parse. Each of those leaves a caller knowing nothing, and
the tempting shortcut in every one of them is to hand back an empty result and
carry on. An empty result reads exactly like "the defect is gone", which is the
one wrong answer a claim-integrity check must never produce. So each of those
states raises, and the base class exists so a caller that genuinely wants to
treat them alike (the CLI, catching to pick an exit code) can, without ever
catching something as wide as Exception.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Optional


class FixtureError(Exception):
  """Base for every failure in the fixture mechanism. Never raised directly.

  It exists so the CLI can catch the whole family in one clause to choose an exit
  code. Everything else catches a specific subclass, because 'the manifest is
  malformed' and 'git could not read that object' want different responses."""


class ManifestError(FixtureError):
  """The manifest is missing, unparseable, or does not describe what it claims.

  Every validation rule in claim_fixture_manifest raises this, including the ones
  that look pedantic (a missing size, a line number on worktree content). They are
  not pedantic: each one closes a route by which a fixture could look healthy
  while proving nothing."""


class BlobPinError(FixtureError):
  """A pin is malformed, names no object or a non-blob, or did not read back intact.

  Each of those means the content is UNKNOWN, which is not the same as empty. The
  reason this is a raise and not a returned empty bytes object is that three of the
  witnesses in claim_fixtures.json assert a literal occurs ZERO times. Against an
  empty file those pass, cheerfully, forever."""


class HistoricalPathError(FixtureError):
  """A path does not resolve at a commit.

  Raised loudly, never softened into an empty result. The concrete incident behind
  this class: agents/wave-implementer.md was renamed from wave-task-implementer.md
  at 58c1118, and asking git for the pre-rename name at any later commit yields
  nothing at all. Piped into a counter, nothing counts as zero hits, and zero hits
  is what a fixed defect looks like."""


class WitnessError(FixtureError):
  """A witness cannot be evaluated as written, for example an empty literal.

  Separate from ManifestError because a witness can also be built in code by a
  caller that never went through the manifest, and 'this assertion is unusable'
  is a different complaint from 'this JSON is wrong'."""


@dataclass(frozen=True)
class PinnedFile:
  """One historical file, pinned by content hash.

  `size` is mandatory and is NOT decorative. It is the second, independent proof
  that materialisation produced real content, and it is the only one an
  absent-polarity witness cannot supply for itself. See _materialise.

  `commit` is a full 40-char SHA rather than a commit-ish. `ab5cb74~1` is an
  expression that git evaluates against the current graph; a full SHA is a pin.
  Recording an expression in a file whose entire purpose is unfalsifiable pinning
  would have been the same defect this mechanism exists to catch.

  Frozen because a spec is an answer key, not a working buffer. Nothing downstream
  should be able to adjust a pin it did not like."""
  path: str
  blob: str
  size: int
  commit: str
  origin_note: str = ''


@dataclass(frozen=True)
class Witness:
  """What must be true of the replayed content for the fixture to hold its defect.

  `count` and `lines` are Optional on purpose, and the manifest validator refuses
  them outright on worktree content. A number frozen against a file that is free
  to move is a stale claim waiting to happen, which is the exact defect class
  being hunted here. On blob-pinned content the hash makes the number permanent,
  so there it is both allowed and asserted."""
  path: str
  polarity: str
  literal: str
  count: Optional[int] = None
  lines: Optional[tuple] = None


@dataclass(frozen=True)
class FixtureSpec:
  """One finding's replay source, parsed and validated.

  `scored_as` is required and may not be blank. Corpus note n5 says whoever scores
  a finding must state WHICH site they counted, because I2's filed site was fixed
  while three same-class siblings stayed live, and counting a sibling as the filed
  finding is a judgement rather than an accident. A judgement that cannot be left
  blank is the right shape for that rule."""
  ident: str
  kind: str
  scored_as: str
  files: tuple
  witnesses: tuple


@dataclass(frozen=True)
class ReplayScope:
  """Where a check runs.

  `root` is a fresh temp dir for a blobs fixture and the repository root for a
  worktree fixture. The fields are identical either way, deliberately, so that a
  consumer never branches on kind: "this finding is still live, score it on disk"
  is a MEMBER of this type, not an exception bolted onto it. That was a design
  requirement, not a convenience.

  This object carries NO authority to delete anything, and holds no field naming
  the temp dir as removable. See replay_scope in claim_fixtures for why that
  matters more than it looks."""
  ident: str
  kind: str
  root: Path
  paths: tuple

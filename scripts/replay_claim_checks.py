#!/usr/bin/env python3
"""Run the SHIPPED claim-integrity checks over the pinned fixtures and report
what they actually did.

    python3 scripts/replay_claim_checks.py            # print the results JSON
    python3 scripts/score_claim_corpus.py --replay    # score against the corpus

WHY THIS EXISTS. scripts/score_claim_corpus.py used to read a hand-authored
results file, so the sprint's headline number graded a transcription rather than
the checks. A number nobody measured is the exact defect class the corpus was
frozen to catch, so the results are produced here instead, as a by-product of
running the real fragments. Nothing downstream is asked to trust a claim about
what a check found.

THE ONE GUARDRAIL EVERYTHING ELSE RESTS ON. The fragment path and the replay-root
variable for a class come from CLASS_CHECKS, a table of Python literals in THIS
FILE, and from nowhere else. Class strings read out of the corpus are used only
as dict keys into that table. Nothing sourced from a repo file is ever executed,
interpolated into a command, or compiled to a pattern. The failure being designed
out is plain: a runner that took its command from a JSON document would let
anyone with commit access to that document run code inside the runner, and the
document in question is an answer key that this very mechanism is meant to be
graded against.

FAIL CLOSED, ALWAYS. A must_catch finding with no fixture, a class the table does
not map, a missing fragment, a bash that will not start, an empty finding set, a
red run that names none of the fixture's own files: every one of them raises. A
`caught: false` is only ever produced by a run that HAPPENED, and there are two
shapes of it: the check ran and came back clean, or it ran, reddened about a file
the fixture pinned, and never named the thing the finding is about. Both are
misses and both are measurements. What can never produce one is a run that did
not take place, because "the check did not fire" and "the check never ran" look
identical in a score and mean opposite things.

The second shape is deliberate rather than tolerated, and verdict() below is
where it is decided. A red run about the right FILE is not a red run about the
right FINDING, and scoring it as a catch would credit the check with work the
witness literals say it did not do.

Exit codes: 0 every finding replayed, 4 a replay could not be scored, 5 a fixture
or manifest failure underneath it.
"""

import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from claim_fixture_git import REPO_ROOT
from claim_fixture_manifest import MANIFEST_PATH, load_manifest
from claim_fixture_types import FixtureError
from claim_fixtures import replay_scope

CORPUS_PATH = Path(__file__).resolve().parent / 'claim_corpus.json'
# The helper set's ENTRY POINT. Sourcing it sources every helper fragment beside
# it, so this runner names one path and gets the whole set; a repo_root carrying
# fewer of them stops the run loudly rather than sourcing a short set. See the foot
# of scripts/validate-dod.d/00-helpers.sh.
HELPERS = 'scripts/validate-dod.d/00-helpers.sh'

EXIT_OK = 0
EXIT_REPLAY = 4
EXIT_FIXTURE = 5

# CSI escape sequences. The helpers colourise every ok and FAIL line, and a
# colourised line does not contain the plain text a reader sees, so the escapes
# come off before anything is matched against it.
ANSI = re.compile(r'\x1b\[[0-9;]*[A-Za-z]')


class ReplayError(Exception):
  """Base for every failure in the replay runner. Never raised directly.

  It exists so a caller that wants to treat the family alike (the CLI, and the
  scorer picking an exit code) can, without ever catching something as wide as
  Exception. Deliberately NOT a subclass of FixtureError: that hierarchy means
  'the fixture could not be materialised', and this one means 'the fixture was
  fine and the RUN over it could not be scored'. A caller usually wants both, and
  says so by naming both."""


class UnmappedClassError(ReplayError):
  """A finding's class has no fragment in CLASS_CHECKS.

  Raised rather than scored false. An unmapped class means no check was run at
  all, and reporting that as a miss would credit the corpus with an examination
  that never took place."""


class MissingFixtureError(ReplayError):
  """A finding to replay has no fixture, or there is nothing to replay at all.

  Same reason. A must_catch finding the manifest does not pin cannot be measured,
  and an empty run is the shape that lets a grader print a confident zero over
  nothing at all."""


class UnscorableRunError(ReplayError):
  """A run happened but its outcome cannot honestly be read as caught or missed.

  The concrete case this closes: every fragment's replay hook REFUSES a root that
  is not a fixture temp dir, by exiting non-zero. That looks exactly like a catch
  by return code and exactly like nothing by content. Also covers a fragment
  missing from disk, which `source` reports on stderr while leaving FAILED at 0,
  so the run would read as a clean miss."""


@dataclass(frozen=True)
class ClassCheck:
  """The shipped check for one corpus class: which fragment, and which variable
  points it at a replay root. Both are source literals, never document data."""
  fragment: str
  replay_var: str


# The table. Source literals only. See the guardrail note in the module docstring.
CLASS_CHECKS = {
  'C3_declared_vs_used': ClassCheck('scripts/validate-dod.d/93-token-declarations.sh',
                                    'TD_REPLAY_ROOT'),
  'C6_section_exists': ClassCheck('scripts/validate-dod.d/94-section-exists.sh',
                                  'SE_REPLAY_ROOT'),
  'C7_literal_absent_claim': ClassCheck('scripts/validate-dod.d/95-literal-absent-claims.sh',
                                        'LA_REPLAY_ROOT'),
}

REPLAY_VARS = tuple(sorted(check.replay_var for check in CLASS_CHECKS.values()))


def load_must_catch(path=CORPUS_PATH):
  """Every must_catch finding in the corpus, as id -> reaching_class, in file order.

  A narrow read rather than a call into score_claim_corpus.load_corpus, and the
  reason is a dependency direction rather than laziness: the scorer imports this
  module, so this module importing the scorer would be a cycle, and under
  `python3 score_claim_corpus.py` it would resolve by loading a SECOND copy of
  that module whose exception classes are different objects from the ones the
  running copy catches. The scorer still runs its full corpus validation on the
  scoring path, so nothing here is the only thing standing between a malformed
  answer key and a printed number.

  reaching_class is the corpus's own validated field, checked against
  candidate_classes before a score is ever computed. claim_fixtures.json records
  a class too, and the two agree today, but that copy goes through no validator
  at all, so the answer key is what gets read here."""
  corpus = _read_corpus(path)
  wanted = {}
  for finding in corpus['findings']:
    if not isinstance(finding, dict):
      raise MissingFixtureError('%s carries a finding that is not an object' % path)
    if finding.get('bucket') != 'must_catch':
      continue
    ident, reaching = finding.get('id'), finding.get('reaching_class')
    if not ident or not reaching:
      raise MissingFixtureError('%s carries a must_catch finding with no id or no '
                                'reaching_class, so nothing says which check to run '
                                'for it' % path)
    wanted[str(ident)] = str(reaching)
  if not wanted:
    raise MissingFixtureError('%s carries no must_catch findings, so a replay over it '
                              'would report a confident score having run nothing' % path)
  return wanted


def _read_corpus(path):
  """Parse the corpus far enough to list its findings, and refuse anything else."""
  if not path.is_file():
    raise MissingFixtureError('corpus file not found at %s' % path)
  try:
    corpus = json.loads(path.read_text(encoding='utf-8'))
  except (OSError, ValueError) as exc:
    raise MissingFixtureError('cannot read %s: %s' % (path, exc)) from exc
  if not isinstance(corpus, dict) or not isinstance(corpus.get('findings'), list):
    raise MissingFixtureError('%s must hold an object carrying a findings list' % path)
  return corpus


def check_for(class_name):
  """The shipped check for a corpus class. Raises rather than returning a default."""
  check = CLASS_CHECKS.get(class_name)
  if check is None:
    raise UnmappedClassError('class %r has no fragment in CLASS_CHECKS, so no check ran '
                             'for it. Known classes: %s'
                             % (class_name, ', '.join(sorted(CLASS_CHECKS))))
  return check


def run_fragment(check, replay_root, repo_root=REPO_ROOT):
  """Source the shipped fragment the way scripts/validate-dod.sh does.

  Returns (rc, ANSI-stripped combined output).

  `set -uo pipefail` LEADS THE LINE because scripts/validate-dod.sh sets that mode
  before sourcing anything (`grep -n '^set -uo pipefail' scripts/validate-dod.sh`
  re-derives the line), and the status handling inside these fragments is
  written against exactly that: `set -o pipefail` is why several of them read
  git's or grep's status on its own line rather than off the end of a pipe. Run
  without it, this runner measured the fragments under a shell mode the validator
  does not ship, and the sprint's headline number came out of that run.
  scripts/tamper_harness.py:170 already used the full line; this one did not, and
  the two are now the same contract rather than two readings of it."""
  root = Path(repo_root)
  _require_file(root, HELPERS)
  _require_file(root, check.fragment)
  script = ('set -uo pipefail; FAILED=0; source %s; source %s; exit $FAILED'
            % (HELPERS, check.fragment))
  env = dict(os.environ)
  for name in REPLAY_VARS:
    env.pop(name, None)
  env[check.replay_var] = str(replay_root)
  try:
    done = subprocess.run(['bash', '-c', script], cwd=str(root), env=env,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  except OSError as exc:
    raise UnscorableRunError('could not run bash for %s: %s' % (check.fragment, exc)) from exc
  return done.returncode, strip_ansi(done.stdout.decode('utf-8', 'replace'))


def _require_file(repo_root, relative):
  """A missing script is a fail-open, not a miss.

  `source missing.sh` writes to stderr and carries on, leaving FAILED at 0, so the
  run would exit clean and be recorded as a check that looked and found nothing."""
  target = repo_root / relative
  if not target.is_file():
    raise UnscorableRunError('%s is not on disk, so sourcing it would leave the run '
                             'green having read nothing' % target)


def strip_ansi(text):
  """Drop CSI escapes so a colourised line matches the plain text a reader sees."""
  return ANSI.sub('', text)


def verdict(rc, output, spec):
  """Decide caught from FIXTURE DATA ONLY. Returns (caught, matched_path, matched_literal).

  Three things must hold together, and each covers a hole the others leave:

    rc != 0          the check reddened at all;
    a pinned path    it reddened about a file this fixture put in the scope;
    a witness literal it named the thing the finding is ABOUT.

  The return code alone cannot tell 'red on this finding' from 'red somewhere in
  these files', and the witness literal is what discriminates. Every input to that
  decision comes out of claim_fixtures.json, so no authored expectation of the
  answer is anywhere on this path.

  A red run naming NONE of the fixture's own paths is refused outright, because
  the honest readings of it are all failures: a replay hook that rejected the
  root, a scanner that died, a fragment that was never there. Reading it as a miss
  would record a check that never looked as a check that looked and found nothing."""
  matched_path = _first_hit(output, [pinned.path for pinned in spec.files])
  matched_literal = _first_hit(output, [w.literal for w in spec.witnesses])
  if rc != 0 and matched_path is None:
    raise UnscorableRunError('%s exited %d without naming any file it pinned, so the run '
                             'cannot be read as a catch or as a miss. Output:\n%s'
                             % (spec.ident, rc, output))
  caught = rc != 0 and matched_path is not None and matched_literal is not None
  return caught, matched_path, matched_literal


def _first_hit(output, needles):
  """The first needle present in the output, in manifest order, or None."""
  for needle in needles:
    if needle and needle in output:
      return needle
  return None


def replay_one(spec, class_name, repo_root=REPO_ROOT):
  """Run one finding's class fragment against its fixture. Returns a result row."""
  check = check_for(class_name)
  if not spec.files:
    raise MissingFixtureError('fixture %s pins no files, so there is no path to match a '
                              'red run against. Only kind blobs is replayable today; a '
                              'worktree fixture would score the tree itself and needs a '
                              'rule this runner has not been asked to invent' % spec.ident)
  with replay_scope(spec, repo_root) as scope:
    rc, output = run_fragment(check, scope.root, repo_root)
  caught, matched_path, matched_literal = verdict(rc, output, spec)
  return {'caught': caught, 'rc': rc, 'class': class_name, 'fragment': check.fragment,
          'replay_var': check.replay_var, 'kind': spec.kind, 'scored_as': spec.scored_as,
          'matched_path': matched_path, 'matched_literal': matched_literal,
          'output': output}


def replay_all(classes_by_id, repo_root=REPO_ROOT):
  """Replay every finding in `classes_by_id` (id -> corpus class). Returns a report."""
  if not classes_by_id:
    raise MissingFixtureError('nothing to replay. An empty set runs no check and then '
                              'reports a score over it, which is the fail-open this '
                              'runner exists to close')
  specs = {spec.ident: spec for spec in load_manifest()}
  results = {}
  for ident, class_name in classes_by_id.items():
    if ident not in specs:
      raise MissingFixtureError('must_catch finding %s has no fixture in %s, so it cannot '
                                'be measured and will not be reported as a miss'
                                % (ident, MANIFEST_PATH))
    results[ident] = replay_one(specs[ident], class_name, repo_root)
  return {'provenance': _provenance(results, repo_root), 'results': results}


def _provenance(results, repo_root):
  """Name what was run, so a transcript can be audited without being rerun."""
  return {
    'mode': 'measured replay',
    'repo_root': str(repo_root),
    'corpus': str(CORPUS_PATH),
    'manifest': str(MANIFEST_PATH),
    'fragments_run': sorted({row['fragment'] for row in results.values()}),
    'findings_replayed': list(results),
    'covers': 'the must_catch findings claim_fixtures.json pins, and nothing else',
  }


def main(_argv):
  """Replay everything the corpus marks must_catch and print the report as JSON."""
  try:
    report = replay_all(load_must_catch())
  except ReplayError as exc:
    print('replay error: %s' % exc, file=sys.stderr)
    return EXIT_REPLAY
  except FixtureError as exc:
    print('fixture error: %s' % exc, file=sys.stderr)
    return EXIT_FIXTURE
  print(json.dumps(report, indent=2))
  return EXIT_OK


if __name__ == '__main__':
  sys.exit(main(sys.argv))

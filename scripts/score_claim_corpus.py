#!/usr/bin/env python3
"""Score the shipped claim-integrity checks against the frozen corpus in
claim_corpus.json.

Run it with no arguments and it MEASURES: it imports scripts/replay_claim_checks,
runs the real fragments over the pinned fixtures, and scores what they did.

    python3 scripts/score_claim_corpus.py
    python3 scripts/score_claim_corpus.py --replay     # the same thing, said out loud

An authored results file stays available, behind an explicit argument, and every
report built from one says AUTHORED on its provenance line:

    python3 scripts/score_claim_corpus.py results.json
    some-check --report-json | python3 scripts/score_claim_corpus.py -

An authored file maps finding id to whether the check flagged it. All three of
these say the same thing:

    {"I2": true, "M3": false}
    {"results": {"I2": true, "M3": false}}
    {"I2": {"caught": true}}

WHAT NO-ARG USED TO DO, recorded because the fix is the point. It scored the
EMPTY set, printed a full report with every number at zero, said "none, default
empty result set" on one line near the bottom, and exited 0. A grader that read
nothing printing a clean number is the same defect the corpus was frozen to
catch, aimed at the corpus itself. No-arg now means --replay, so the cheapest
possible invocation is the measured one.

THIS SCRIPT NEVER WRITES THE CORPUS. It only reads it. The corpus is the answer
key, frozen before any check existed, and tuning it to make a check pass is the
exact failure this whole sprint exists to stop.

Three things here are deliberately unforgiving:

  1. A result naming a finding id the corpus does not carry is a hard error, not
     a warning. It means the check and the answer key have drifted apart, and a
     score computed across a drift is worse than no score.
  2. The corpus counts block is cross-checked against the per-finding data. If
     someone later flips a bucket and forgets the totals, this reds. That is the
     tamper detector, and it is the point of freezing the table.
  3. A replay that raises prints NO SCORE. The runner is imported and called in
     process rather than shelled out to, so a failure arrives as an exception
     instead of as an empty stdout that would score as a clean zero.

Exit codes: 0 scored (any score, including zero), 2 corpus missing or malformed,
3 results unreadable or naming an unknown finding, 4 the replay could not run.
"""

import json
import sys
from dataclasses import dataclass
from pathlib import Path

from claim_fixture_types import FixtureError
from replay_claim_checks import ReplayError, load_must_catch, replay_all

CORPUS_PATH = Path(__file__).resolve().parent / 'claim_corpus.json'

EXIT_OK = 0
EXIT_CORPUS = 2
EXIT_RESULTS = 3
EXIT_REPLAY = 4

REPLAY_FLAG = '--replay'

# Printed under a measured score. The replay runs the must_catch fixtures and
# nothing else, so every out_of_class zero in that report is an unexamined
# default. Left unsaid, those zeros sit under a provenance line reading "measured
# replay" and are read as checks that looked and stayed silent, which would
# reintroduce this script's own fail-open on the other half of the table.
REPLAY_COVERAGE = (
    'NOT MEASURED: the replay runs the must_catch fixtures and nothing else, so\n'
    '  every out_of_class number above is an unexamined default rather than a\n'
    '  check that looked and found nothing.')

BUCKETS = ('must_catch', 'out_of_class')
SCAN_SCOPES = ('repo-wide', 'diff-scoped', 'n/a')
REQUIRED_TOP_KEYS = ('derived_at', 'candidate_classes', 'findings', 'counts')
REQUIRED_FINDING_KEYS = ('id', 'severity_as_filed', 'refuter_verdict', 'one_line',
                         'citation', 'reaching_class', 'scan_scope', 'bucket', 'why')


class CorpusError(Exception):
  """The answer key is missing, unparseable, or does not describe what it claims."""


class ResultsError(Exception):
  """The results are unreadable, or they mention a finding the corpus does not carry."""


def load_corpus(path):
  """Read and validate the frozen corpus. Read only, never written."""
  if not path.is_file():
    raise CorpusError('corpus file not found at %s' % path)
  try:
    text = path.read_text(encoding='utf-8')
  except OSError as exc:
    raise CorpusError('cannot read %s: %s' % (path, exc)) from exc
  try:
    corpus = json.loads(text)
  except json.JSONDecodeError as exc:
    raise CorpusError('%s is not valid JSON: %s' % (path, exc)) from exc
  if not isinstance(corpus, dict):
    raise CorpusError('%s must hold a JSON object at the top level' % path)
  _validate_shape(corpus)
  _validate_findings(corpus)
  _validate_counts(corpus)
  return corpus


def _validate_shape(corpus):
  """Every top-level key the scorer depends on is present and the right type."""
  missing = [k for k in REQUIRED_TOP_KEYS if k not in corpus]
  if missing:
    raise CorpusError('corpus is missing top-level keys: %s' % ', '.join(missing))
  if not isinstance(corpus['findings'], list) or not corpus['findings']:
    raise CorpusError('corpus findings must be a non-empty list')
  if not isinstance(corpus['candidate_classes'], dict):
    raise CorpusError('corpus candidate_classes must be an object')
  if not isinstance(corpus['counts'], dict):
    raise CorpusError('corpus counts must be an object')


def _class_universe(corpus):
  """The valid reaching_class values, derived from the corpus rather than hardcoded."""
  return set(corpus['candidate_classes']) | {'none'}


def _validate_findings(corpus):
  """Each finding carries every required field, with values inside the known sets."""
  classes = _class_universe(corpus)
  seen = set()
  for index, finding in enumerate(corpus['findings']):
    if not isinstance(finding, dict):
      raise CorpusError('finding at position %d is not an object' % index)
    _validate_one_finding(finding, classes)
    if finding['id'] in seen:
      raise CorpusError('finding id %s appears more than once' % finding['id'])
    seen.add(finding['id'])


def _validate_one_finding(finding, classes):
  """Field presence and enum membership for a single finding."""
  missing = [k for k in REQUIRED_FINDING_KEYS if k not in finding]
  if missing:
    raise CorpusError('finding %r is missing fields: %s'
                      % (finding.get('id', '<no id>'), ', '.join(missing)))
  ident = finding['id']
  if finding['bucket'] not in BUCKETS:
    raise CorpusError('finding %s has bucket %r, expected one of %s'
                      % (ident, finding['bucket'], ', '.join(BUCKETS)))
  if finding['reaching_class'] not in classes:
    raise CorpusError('finding %s names class %r, which is not a candidate class'
                      % (ident, finding['reaching_class']))
  if finding['scan_scope'] not in SCAN_SCOPES:
    raise CorpusError('finding %s has scan_scope %r, expected one of %s'
                      % (ident, finding['scan_scope'], ', '.join(SCAN_SCOPES)))


def _validate_counts(corpus):
  """The recorded totals must match the findings. A bucket edit that skips the
  counts block reds here, which is how the frozen table resists quiet tuning."""
  findings = corpus['findings']
  counts = corpus['counts']
  measured = {'total': len(findings)}
  for bucket in BUCKETS:
    measured[bucket] = sum(1 for f in findings if f['bucket'] == bucket)
  for key, value in measured.items():
    if key not in counts:
      raise CorpusError('counts.%s is missing; the headline totals are not optional, '
                        'because deleting one is as good a way to hide a bucket edit '
                        'as changing it' % key)
    if counts[key] != value:
      raise CorpusError('counts.%s says %r but the findings measure %d; the answer '
                        'key has drifted from its own totals' % (key, counts[key], value))
  _validate_block_reasons(findings, counts)


def _validate_block_reasons(findings, counts):
  """Same cross-check for the out_of_class breakdown, when the corpus records one."""
  recorded = counts.get('out_of_class_by_block_reason')
  if not isinstance(recorded, dict):
    return
  measured = {}
  for finding in findings:
    if finding['bucket'] != 'out_of_class':
      continue
    reason = finding.get('block_reason') or 'unstated'
    measured[reason] = measured.get(reason, 0) + 1
  if measured != recorded:
    raise CorpusError('counts.out_of_class_by_block_reason records %r but the findings '
                      'measure %r' % (recorded, measured))


@dataclass(frozen=True)
class ResultSource:
  """Where a score's results came from, and what they leave unexamined.

  More than one field because they answer different questions and a reader needs
  every one: `label` says who produced these numbers, `coverage` says which parts
  of the table they never looked at, and `measures_out_of_class` lets the
  per-finding table label an unexamined row as unexamined. A report that answers
  only the first is how a measured half ends up lending its credibility to an
  unmeasured one.

  `measures_out_of_class` is a real field rather than something read back off
  `coverage` because a truthiness test on a prose string is right today and murky
  the first time somebody adds a caveat for an unrelated reason."""
  label: str
  coverage: str = ''
  measures_out_of_class: bool = True


def replay_results():
  """Run the shipped checks now, and turn what they did into results.

  IN PROCESS, deliberately. Shelling out to the runner would put a pipe between
  the measurement and the score, and a broken pipe, a missing interpreter or a
  substituted file all arrive down that pipe as empty stdout, which parses as an
  empty result set and scores as a clean zero. An import cannot be handed a
  different file, and an exception cannot be mistaken for an answer."""
  report = replay_all(load_must_catch())
  results = {ident: _as_caught(ident, row, 'the replay')
             for ident, row in report['results'].items()}
  return results, ResultSource(_replay_label(report), REPLAY_COVERAGE, False)


def _replay_label(report):
  """The provenance line for a measured run: the mode, then every fragment it ran.

  It names the fragments rather than a filename because a filename is what an
  authored report has, and the whole point of this mode is that the two can never
  be confused by someone reading a transcript."""
  lines = ['measured replay, these shipped checks run over the pinned fixtures']
  lines.extend('    %s' % fragment for fragment in report['provenance']['fragments_run'])
  return '\n'.join(lines)


def load_results(argument):
  """Read an AUTHORED results mapping from a file or from stdin.

  There is no no-argument branch any more. It used to return the empty set and
  call that the do-nothing baseline, which meant the cheapest way to run this
  script was also the only way to get a full report out of it having measured
  nothing at all."""
  if argument is None:
    raise ResultsError('no results source. Pass %s to measure, a path or - to score an '
                       'authored file' % REPLAY_FLAG)
  if argument == '-':
    return _parse_results(sys.stdin.read(), 'stdin'), _authored('stdin')
  path = Path(argument)
  if not path.is_file():
    raise ResultsError('results file not found at %s' % path)
  try:
    text = path.read_text(encoding='utf-8')
  except OSError as exc:
    raise ResultsError('cannot read %s: %s' % (path, exc)) from exc
  return _parse_results(text, str(path)), _authored(str(path))


def _authored(origin):
  """Label an authored source as authored, in the report itself.

  Said plainly and in capitals because the failure it guards is a reader, weeks
  later, taking a number out of a transcript without checking which mode produced
  it. A hand-written file and a measured run print the same table."""
  return ResultSource('%s, AUTHORED. These results were written by hand, not measured '
                      'by running any check.' % origin)


def _parse_results(text, origin):
  """Parse the results JSON and flatten it to id -> caught."""
  if not text.strip():
    return {}
  try:
    raw = json.loads(text)
  except json.JSONDecodeError as exc:
    raise ResultsError('results from %s are not valid JSON: %s' % (origin, exc)) from exc
  if isinstance(raw, dict) and isinstance(raw.get('results'), dict):
    raw = raw['results']
  if not isinstance(raw, dict):
    raise ResultsError('results from %s must be an object mapping finding id to '
                       'caught or not caught' % origin)
  return {str(key): _as_caught(key, value, origin) for key, value in raw.items()}


def _as_caught(key, value, origin):
  """Accept a bare boolean or an object carrying a caught field."""
  if isinstance(value, bool):
    return value
  if isinstance(value, dict) and isinstance(value.get('caught'), bool):
    return value['caught']
  raise ResultsError('results from %s give %s the value %r; expected true, false, or '
                     'an object with a boolean caught field' % (origin, key, value))


def _reject_unknown_ids(corpus, results):
  """A result naming a finding the corpus does not carry means the check and the
  answer key have drifted apart, so refuse to score rather than score across it."""
  known = {f['id'] for f in corpus['findings']}
  unknown = sorted(set(results) - known)
  if unknown:
    raise ResultsError('results name findings the corpus does not carry: %s. The check '
                       'and the answer key have drifted apart, so no score is reported.'
                       % ', '.join(unknown))


def score(corpus, results):
  """Tally the corpus against the results. Every finding is counted exactly once."""
  tally = {'must_catch_total': 0, 'must_catch_caught': 0, 'out_of_class_total': 0,
           'wrongly_claimed': 0, 'defect_claims': 0, 'defect_total': 0,
           'wrongly_claimed_by_reason': {}, 'out_of_class_by_reason': {}}
  for finding in corpus['findings']:
    claimed = bool(results.get(finding['id'], False))
    if finding.get('claiming_is_defect'):
      tally['defect_total'] += 1
      tally['defect_claims'] += int(claimed)
    if finding['bucket'] == 'must_catch':
      tally['must_catch_total'] += 1
      tally['must_catch_caught'] += int(claimed)
      continue
    _tally_out_of_class(tally, finding, claimed)
  return tally


def _tally_out_of_class(tally, finding, claimed):
  """Out-of-class findings split by WHY they are out, because no class reaching a
  finding and a class reaching it but scope blocking it are different failures."""
  reason = finding.get('block_reason') or 'unstated'
  tally['out_of_class_total'] += 1
  tally['out_of_class_by_reason'][reason] = tally['out_of_class_by_reason'].get(reason, 0) + 1
  if not claimed:
    return
  tally['wrongly_claimed'] += 1
  tally['wrongly_claimed_by_reason'][reason] = \
      tally['wrongly_claimed_by_reason'].get(reason, 0) + 1


def _verdict(finding, claimed, source):
  """The one-line result for a single finding.

  A row a run never examined says so. Under --replay only the must_catch half has
  fixtures, so every out_of_class row would otherwise read 'ok, stayed silent',
  which is nine claims that a check looked and found nothing sitting directly
  above a provenance line reading 'measured replay'. The score block already
  carries the caveat for the totals; a reader working down the table meets the
  rows first."""
  if finding['bucket'] == 'must_catch':
    return 'ok, caught' if claimed else 'MISS, expected caught'
  if not source.measures_out_of_class:
    return 'not measured by this run'
  if not claimed:
    return 'ok, stayed silent'
  if finding.get('claiming_is_defect'):
    return 'DEFECT, claiming this reproduces a false claim'
  return 'WRONGLY CLAIMED'


def render_findings(corpus, results, source):
  """One line per finding, so a reader sees the shape and not only the score."""
  print('Per finding')
  print('  %-4s %-13s %-25s %-24s %s'
        % ('ID', 'BUCKET', 'CLASS', 'REPLAY', 'RESULT'))
  for finding in corpus['findings']:
    claimed = bool(results.get(finding['id'], False))
    print('  %-4s %-13s %-25s %-24s %s'
          % (finding['id'], finding['bucket'], finding['reaching_class'],
             finding.get('replay', 'unstated'), _verdict(finding, claimed, source)))
  print()


def render_score(tally, source):
  """The score itself, split by block reason, then what produced it.

  The coverage caveat prints between the numbers and the provenance line on
  purpose. A reader who stops at the numbers has to step over it to reach the
  line that says the run was measured, so the two are never read apart."""
  print('Score')
  print('  must_catch caught                    %d of %d'
        % (tally['must_catch_caught'], tally['must_catch_total']))
  print('  out_of_class wrongly claimed         %d of %d'
        % (tally['wrongly_claimed'], tally['out_of_class_total']))
  for reason in sorted(tally['out_of_class_by_reason']):
    print('    %-33s  %d of %d'
          % (reason, tally['wrongly_claimed_by_reason'].get(reason, 0),
             tally['out_of_class_by_reason'][reason]))
  if tally['defect_total']:
    print('  claimed where claiming IS a defect   %d of %d'
          % (tally['defect_claims'], tally['defect_total']))
  if source.coverage:
    print()
    print('  %s' % source.coverage)
  print()
  print('  results read from: %s' % source.label)


def render(corpus, results, source):
  """Full report: header, per-finding table, score."""
  print('Claim corpus score')
  print('  corpus:     %s' % CORPUS_PATH)
  print('  derived at: %s' % corpus['derived_at'])
  print('  findings:   %d' % len(corpus['findings']))
  print()
  render_findings(corpus, results, source)
  tally = score(corpus, results)
  render_score(tally, source)
  return tally


def _gather(argument, corpus):
  """Results plus their provenance, measured by default and authored on request."""
  if argument == REPLAY_FLAG:
    results, source = replay_results()
  else:
    results, source = load_results(argument)
  _reject_unknown_ids(corpus, results)
  return results, source


def main(argv):
  """Load, validate, score, print. Returns the process exit code."""
  try:
    corpus = load_corpus(CORPUS_PATH)
  except CorpusError as exc:
    print('corpus error: %s' % exc, file=sys.stderr)
    return EXIT_CORPUS
  argument = argv[1] if len(argv) > 1 else REPLAY_FLAG
  try:
    results, source = _gather(argument, corpus)
  except ResultsError as exc:
    print('results error: %s' % exc, file=sys.stderr)
    return EXIT_RESULTS
  except (ReplayError, FixtureError) as exc:
    print('replay error: %s. No score is printed, because a replay that could not '
          'run has measured nothing.' % exc, file=sys.stderr)
    return EXIT_REPLAY
  render(corpus, results, source)
  return EXIT_OK


if __name__ == '__main__':
  sys.exit(main(sys.argv))

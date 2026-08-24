#!/usr/bin/env python3
"""Score a claim-integrity check against the frozen corpus in claim_corpus.json.

Run with no arguments to see the baseline a do-nothing check earns:

    python3 scripts/score_claim_corpus.py

Feed it real results once a check exists, either as a file or on stdin:

    python3 scripts/score_claim_corpus.py results.json
    some-check --report-json | python3 scripts/score_claim_corpus.py -

A results file maps finding id to whether the check flagged it. All three of
these say the same thing:

    {"I2": true, "M3": false}
    {"results": {"I2": true, "M3": false}}
    {"I2": {"caught": true}}

THIS SCRIPT NEVER WRITES THE CORPUS. It only reads it. The corpus is the answer
key, frozen before any check existed, and tuning it to make a check pass is the
exact failure this whole sprint exists to stop.

Two things here are deliberately unforgiving:

  1. A result naming a finding id the corpus does not carry is a hard error, not
     a warning. It means the check and the answer key have drifted apart, and a
     score computed across a drift is worse than no score.
  2. The corpus counts block is cross-checked against the per-finding data. If
     someone later flips a bucket and forgets the totals, this reds. That is the
     tamper detector, and it is the point of freezing the table.

Exit codes: 0 scored (any score, including zero), 2 corpus missing or malformed,
3 results unreadable or naming an unknown finding.
"""

import json
import sys
from pathlib import Path

CORPUS_PATH = Path(__file__).resolve().parent / 'claim_corpus.json'

EXIT_OK = 0
EXIT_CORPUS = 2
EXIT_RESULTS = 3

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


def load_results(argument):
  """Read a results mapping. No argument means the empty set, which is the
  do-nothing baseline and a legitimate answer rather than an error."""
  if argument is None:
    return {}, 'none, default empty result set'
  if argument == '-':
    return _parse_results(sys.stdin.read(), 'stdin'), 'stdin'
  path = Path(argument)
  if not path.is_file():
    raise ResultsError('results file not found at %s' % path)
  try:
    text = path.read_text(encoding='utf-8')
  except OSError as exc:
    raise ResultsError('cannot read %s: %s' % (path, exc)) from exc
  return _parse_results(text, str(path)), str(path)


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


def _verdict(finding, claimed):
  """The one-line result for a single finding."""
  if finding['bucket'] == 'must_catch':
    return 'ok, caught' if claimed else 'MISS, expected caught'
  if not claimed:
    return 'ok, stayed silent'
  if finding.get('claiming_is_defect'):
    return 'DEFECT, claiming this reproduces a false claim'
  return 'WRONGLY CLAIMED'


def render_findings(corpus, results):
  """One line per finding, so a reader sees the shape and not only the score."""
  print('Per finding')
  print('  %-4s %-13s %-25s %-24s %s'
        % ('ID', 'BUCKET', 'CLASS', 'REPLAY', 'RESULT'))
  for finding in corpus['findings']:
    claimed = bool(results.get(finding['id'], False))
    print('  %-4s %-13s %-25s %-24s %s'
          % (finding['id'], finding['bucket'], finding['reaching_class'],
             finding.get('replay', 'unstated'), _verdict(finding, claimed)))
  print()


def render_score(tally, source):
  """The score itself, with the out-of-class half split by block reason."""
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
  print()
  print('  results read from: %s' % source)


def render(corpus, results, source):
  """Full report: header, per-finding table, score."""
  print('Claim corpus score')
  print('  corpus:     %s' % CORPUS_PATH)
  print('  derived at: %s' % corpus['derived_at'])
  print('  findings:   %d' % len(corpus['findings']))
  print()
  render_findings(corpus, results)
  tally = score(corpus, results)
  render_score(tally, source)
  return tally


def main(argv):
  """Load, validate, score, print. Returns the process exit code."""
  argument = argv[1] if len(argv) > 1 else None
  try:
    corpus = load_corpus(CORPUS_PATH)
  except CorpusError as exc:
    print('corpus error: %s' % exc, file=sys.stderr)
    return EXIT_CORPUS
  try:
    results, source = load_results(argument)
    _reject_unknown_ids(corpus, results)
  except ResultsError as exc:
    print('results error: %s' % exc, file=sys.stderr)
    return EXIT_RESULTS
  render(corpus, results, source)
  return EXIT_OK


if __name__ == '__main__':
  sys.exit(main(sys.argv))

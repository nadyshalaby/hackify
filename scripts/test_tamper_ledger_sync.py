#!/usr/bin/env python3
"""AC4 tamper rows for check [98], the work-doc ledger-sync fragment.

Imported and run by scripts/test_tamper_battery.py. It holds no main of its own,
the same structure scripts/test_tamper_fragments.py uses and the one check [97]
blesses in its own header: a suite reached by import from a file CI names is
wired.

WHY A FIFTH FILE RATHER THAN A SECTION IN test_tamper_fragments.py. That file was
already 465 lines against the project's 500-line hard cap when these rows were
written, and one section per fragment does not fit in the 35 lines left. Splitting
was the instruction rather than trimming coverage to fit, and check [97] plus the
PARTS tuple in the entrypoint are what keep the split file reachable.

WHAT A ROW HERE IS. One branch of check [98], broken on purpose, with the EXPECTED
FAILURE MESSAGE asserted rather than the exit status alone. A branch that reds in
another branch's words is a branch nobody can debug, and the two failures a
validator must never confuse, "the check looked and found the defect" and "the
check never ran", both arrive as a non-zero status.

EVERY ROW BUILDS ITS OWN TREE, and that is the difference from the rows for the
neighbouring fragments. Check [98] reads tracked work-docs out of the working
directory, so a throwaway git tree carrying a template and a dozen synthetic docs
lets a row decide exactly what the check sees. It also keeps the rows independent
of whether the live tree happens to be clean, which matters while the sprint's own
archived doc still carries the defect this check was written to find.

NOTHING HERE WRITES INTO THE REPOSITORY. A fragment is tampered by editing a COPY
in a temp file and a tree is built under a temp prefix, so a row that dies halfway
leaves nothing behind to restore.
"""

from tamper_harness import (COUNT_BUMP, PASS_PREFIX, RED_CALL, REPO_ROOT, TEMPLATE,
                            expect, expect_red, git, refute, run_check,
                            run_check_without_python, run_fragment, tampered,
                            temp_dir, write)

QUOTE = chr(39)
TICK = chr(96)

# Above check [98]'s own WL_DOC_FLOOR of 10, so a row that means to reach a later
# branch is never stopped by the first floor on the way.
SCRATCH_DOCS = 12

# A value no template row could carry, so a planted status can never collide with
# a real one.
BAD_STATUS = 'zzq-not-a-declared-status'

# The status row check [98] reads the vocabulary out of. Written as pieces because
# the cell is delimited by the character bash reads as a command substitution.
STATUS_ROW_HEAD = '| %sstatus%s |' % (TICK, TICK)

# The fragment's own CONTROL verdict line, assembled rather than written out. It
# is a format string carrying its own conversions, so building it by concatenation
# is what keeps the % operator away from them.
CONTROL_LINE = ('print(' + QUOTE + 'CONTROL %s' + QUOTE + ' % (' + QUOTE + 'ok'
                + QUOTE + ' if control(allowed) else ' + QUOTE + 'fail' + QUOTE + '))')

# An archived doc whose ledger is CLOSED, carrying every construct that must not
# be read as a ledger row. Two of them are the whole point of the block-range
# rule. The open row under `## Groom Provenance` sits between section 0 and
# section 1, which is where the groom path inserts that heading, so it is inside
# the block under a section-1 terminator and outside it under the terminator the
# fragment actually uses. The Sprint Backlog rows use the identical grammar and
# every archived doc in the real tree carries some.
CLEAN_ARCHIVED = (
  '## 0. Phase ledger\n\n'
  '- [x] Phase 1. Clarify\n'
  '- [x] Phase 2. Plan + Gate\n\n'
  '## Groom Provenance\n\n'
  '- [ ] a row the groom block carries, outside section 0\n\n'
  '## 1. Original ask\n\nthe ask\n\n'
  '## 5. Sprint Backlog\n\n'
  '- [ ] T1, a backlog task nobody ticked\n'
  '- [>] T2, the backlog task in flight\n')

# The same doc with one row moved INSIDE the block. This is the discriminator for
# the row above: if both came back the same way, the negative control would be
# proving nothing.
OPEN_ARCHIVED = CLEAN_ARCHIVED.replace('- [x] Phase 2. Plan + Gate',
                                       '- [>] Phase 2. Plan + Gate')


def _doc(status, body=''):
  """One synthetic work-doc. The status sits on line 3, which every row cites."""
  return '---\nslug: zzq-scratch\nstatus: %s\n---\n\n%s' % (status, body)


def _tree(extra=None, template=None):
  """A throwaway git tree: the work-doc template plus SCRATCH_DOCS clean docs.

  `extra` is {relative path: body} for whatever a row wants to plant on top.
  `template` replaces the template body, which is how a row collapses the
  vocabulary for real instead of by moving a floor."""
  root = temp_dir('ledger-')
  if template is None:
    template = (REPO_ROOT / TEMPLATE).read_text(encoding='utf-8')
  write(root, TEMPLATE, template)
  write(root, 'docs/work/live.md', _doc('implementing'))
  for n in range(SCRATCH_DOCS - 1):
    write(root, 'docs/work/done/archived-%d.md' % n, _doc('done', CLEAN_ARCHIVED))
  for rel, body in (extra or {}).items():
    write(root, rel, body)
  git(root, 'init', '-q')
  git(root, 'add', '-A')
  return root


def _template_without_the_status_row():
  """The real template with its status row deleted, and nothing else changed."""
  lines = (REPO_ROOT / TEMPLATE).read_text(encoding='utf-8').split('\n')
  kept = [ln for ln in lines if not ln.startswith(STATUS_ROW_HEAD)]
  assert len(kept) == len(lines) - 1, 'expected exactly one status row, got %d' % (
    len(lines) - len(kept))
  return '\n'.join(kept)


def _declared_status_count():
  """How many values the template's status row declares, counted from the template
  every run rather than written down here. A count typed into a test is a claim
  with a shelf life, and it goes stale the first time the vocabulary grows, which
  is the exact defect this suite exists to catch elsewhere."""
  for line in (REPO_ROOT / TEMPLATE).read_text(encoding='utf-8').split('\n'):
    if line.startswith(STATUS_ROW_HEAD):
      cell = line.strip().strip('|').split('|')[1]
      return len([part for part in cell.split('/') if part.strip()])
  raise AssertionError('the template declares no status row, so there is nothing '
                       'to count and every row below would assert against a guess')


# --- the baseline, and the counts it has to name -------------------------------

def test_98_a_clean_tree_greens_and_names_what_it_examined():
  """Without a measured green every red below could be the scratch tree rather
  than the tamper. The counts are asserted too, because a pass line with no
  numbers reads the same whether the scan examined every doc or none of them."""
  rc, out = run_check('98', cwd=_tree())
  assert rc == 0, out
  expect(out, '%sall %d tracked work-doc(s)' % (PASS_PREFIX, SCRATCH_DOCS),
         '(%d section 0 ledger(s) found, %d of them archived and judged)'
         % (SCRATCH_DOCS - 1, SCRATCH_DOCS - 1),
         'the positive control separated its reported docs from its clean ones')


# --- assertion (a), the status vocabulary --------------------------------------

def test_98_a_status_the_template_does_not_declare_reds_and_names_the_row():
  """The vocabulary comes out of the template at runtime, so the red has to name
  the declaring site a reader is meant to go and read."""
  root = _tree({'docs/work/planted.md': _doc(BAD_STATUS)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'docs/work/planted.md:3 sets status: %s%s%s, which is none of '
             'the %d value(s) the row at %s declares' % (QUOTE, BAD_STATUS, QUOTE,
                                                         _declared_status_count(),
                                                         TEMPLATE))


def test_98_a_doc_with_no_status_field_reds_rather_than_being_skipped():
  """A doc that states no phase at all is the shape a value check silently drops:
  there is nothing to compare, so a naive reader moves on and the doc leaves the
  subject set without leaving the count."""
  root = _tree({'docs/work/planted.md': '# no frontmatter here\n\nbody\n'})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'docs/work/planted.md carries no status field in its '
             'frontmatter')


# --- assertion (b), an archived doc is finished --------------------------------

def test_98_an_archived_doc_with_an_open_ledger_row_reds_and_quotes_it():
  root = _tree({'docs/work/done/planted.md': _doc('done', OPEN_ARCHIVED)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'docs/work/done/planted.md:9 carries an open - [>] row inside '
             'its ## 0. Phase ledger block',
             'still shows a phase nobody closed: - [>] Phase 2. Plan + Gate')


def test_98_an_open_row_outside_the_ledger_block_is_not_a_subject():
  """THE NEGATIVE CONTROL. Every clean doc in the scratch tree already carries an
  open row under `## Groom Provenance` and two more in its Sprint Backlog, in the
  identical grammar section 0 uses. None of them may be reported. A check that
  counted open rows file-wide would red on every archived doc in the real tree,
  which is the fabrication this sprint exists to refuse."""
  rc, out = run_check('98', cwd=_tree())
  assert rc == 0, out
  refute(out, 'carries an open')


def test_98_the_wrong_block_terminator_would_red_on_a_groomed_doc():
  """The discriminator for the row above, and the reason the terminator is any
  heading rather than the section-1 one. Point it at section 1 and the block
  swallows `## Groom Provenance`, so the row that block carries lands inside
  section 0 and every groomed doc in the tree reds. Without this the negative
  control would pass under either reading and prove nothing."""
  with tampered('98', ("HEADING = '## '", "HEADING = '## 1.'")) as frag:
    rc, out = run_fragment(frag, cwd=_tree())
  expect_red(rc, out, 'carries an open - [ ] row inside its ## 0. Phase ledger '
             'block', 'a row the groom block carries, outside section 0')


# --- assertion (c), a live doc is not archived ---------------------------------

def test_98_a_live_doc_that_says_it_was_finished_reds():
  root = _tree({'docs/work/planted.md': _doc('done')})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'docs/work/planted.md:3 sets status: done while the file sits '
             'outside docs/work/done/')


# --- the floors, and the collapses they exist to catch -------------------------

def test_98_the_doc_floor_reds_before_any_doc_is_judged():
  with tampered('98', ('WL_DOC_FLOOR=10', 'WL_DOC_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag, cwd=_tree({'docs/work/planted.md': _doc(BAD_STATUS)}))
  expect_red(rc, out, 'tracked doc(s) under docs/work/ against a floor of 9999',
             'a scan over nothing measures nothing')
  refute(out, BAD_STATUS)


def test_98_a_tree_with_no_work_docs_reds_on_the_doc_floor():
  """The collapse the floor is actually written against, reached for real rather
  than by moving the number: a pathspec that resolves to nothing."""
  root = temp_dir('ledger-empty-')
  write(root, TEMPLATE, (REPO_ROOT / TEMPLATE).read_text(encoding='utf-8'))
  git(root, 'init', '-q')
  git(root, 'add', '-A')
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'the work-doc scan read 0 tracked doc(s) under docs/work/ '
             'against a floor of 10')


def test_98_the_vocabulary_floor_reds_on_its_own_message():
  with tampered('98', ('WL_VOCAB_FLOOR=4', 'WL_VOCAB_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag, cwd=_tree())
  expect_red(rc, out, 'the template parse read %d status value(s) against a floor '
             'of 9999' % _declared_status_count(),
             'would resolve against an empty vocabulary')


def test_98_a_template_that_loses_its_status_row_reds_without_accusing_every_doc():
  """The vocabulary collapsing for real. Two halves, and the second is the one
  that is easy to get wrong: with nothing to compare against, every doc in the
  tree looks wrong, so the per-doc sentence has to stay quiet and let the floor
  say what actually happened."""
  root = _tree(template=_template_without_the_status_row())
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'the template parse read 0 status value(s) against a floor of 4')
  refute(out, 'which is none of the')


def test_98_the_archived_ledger_floor_reds_on_its_own_message():
  with tampered('98', ('WL_LEDGER_FLOOR=1', 'WL_LEDGER_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag, cwd=_tree())
  expect_red(rc, out, 'archived doc(s) carrying a section 0 phase ledger against a '
             'floor of 9999', 'assertion (b) judged nothing')


def test_98_an_archive_carrying_no_ledger_at_all_reds_on_that_floor():
  """The same collapse reached for real. Archived docs with no section 0 leave
  assertion (b) with an empty subject set, and a check that reported a confident
  zero there would be green over a scan that never looked."""
  root = temp_dir('ledger-none-')
  write(root, TEMPLATE, (REPO_ROOT / TEMPLATE).read_text(encoding='utf-8'))
  write(root, 'docs/work/live.md', _doc('implementing'))
  for n in range(SCRATCH_DOCS - 1):
    write(root, 'docs/work/done/archived-%d.md' % n, _doc('done', '## 1. Ask\n\nx\n'))
  git(root, 'init', '-q')
  git(root, 'add', '-A')
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'the scan found 0 archived doc(s) carrying a section 0 phase '
             'ledger against a floor of 1')


# --- the positive control, and both ways it earns the silence ------------------

def test_98_a_control_that_never_runs_cannot_green_the_check():
  """The variable starts at `none` for exactly this. Take the control's verdict
  line away and the check must red rather than fall through to its pass line,
  because a control that did not run says nothing about whether the judge still
  works."""
  with tampered('98', (CONTROL_LINE, 'pass')) as frag:
    rc, out = run_fragment(frag, cwd=_tree())
  expect_red(rc, out, 'the positive control did not hold (control verdict: none)')


def test_98_a_judge_that_stops_discriminating_is_caught_only_by_the_control():
  """THE ROW THE CONTROL EXISTS FOR. Blind the vocabulary comparison and a clean
  tree is judged exactly as it was before: no doc is reported, and every floor
  still holds, so nothing else in the fragment has anything to say. The control is
  the one thing that notices, because its bad-status doc stops coming back
  reported. Without it this tamper ships a check that greens over a comparison
  that no longer compares."""
  with tampered('98', ('if allowed and value not in allowed:',
                       'if allowed and False:')) as frag:
    rc, out = run_fragment(frag, cwd=_tree())
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)',
             'a bad status value')


def test_98_a_judge_that_reports_everything_is_caught_by_the_same_control():
  """The other direction, and the reason the control carries clean docs at all.
  A comparison that degraded to always-fail is still a broken comparison, and a
  positive-only control would report ok right through it."""
  with tampered('98', ('if allowed and value not in allowed:',
                       'if allowed and True:')) as frag:
    rc, out = run_fragment(frag, cwd=_tree())
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)')


# --- the branches that only fire when the run itself is broken -----------------

def test_98_a_missing_interpreter_reds_rather_than_skipping():
  rc, out = run_check_without_python('98')
  expect_red(rc, out, '[98] needs python3 to parse work-doc frontmatter, and it is '
             'not on PATH')


def test_98_a_failed_stderr_capture_reds_rather_than_running_blind():
  with tampered('98', ('wl_err=$(mktemp 2>/dev/null)', 'wl_err=$(false)')) as frag:
    rc, out = run_fragment(frag, cwd=_tree())
  expect_red(rc, out, 'could not create the stderr capture file, so the work-doc '
             'scan never ran')


def test_98_a_scan_that_cannot_finish_reds_rather_than_reading_silence_as_clean():
  """git ls-files exits non-zero outside a repository, which raises on the python
  side and lands in the fail-closed branch. A check that read the empty result as
  "no work-doc is out of step" would be green having looked at nothing."""
  root = temp_dir('ledger-nogit-')
  write(root, TEMPLATE, (REPO_ROOT / TEMPLATE).read_text(encoding='utf-8'))
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'the work-doc scan did not finish', 'git ls-files failed with rc')


def test_98_blinding_the_whole_red_helper_leaves_a_silent_green():
  """Both halves of the red path blinded: the run is silent AND exits 0, which is
  the fail-open a check exists to make impossible. Asserted so the shape is on
  record, the same row scripts/test_tamper_fragments.py carries for [95] and [97]."""
  root = _tree({'docs/work/planted.md': _doc(BAD_STATUS)})
  with tampered('98', (RED_CALL, ':'), (COUNT_BUMP, ':')) as frag:
    rc, out = run_fragment(frag, cwd=root)
  assert rc == 0, out
  refute(out, BAD_STATUS, PASS_PREFIX)


# --- the fragment is wired into the run at all ---------------------------------

def test_98_the_orchestrator_sources_the_fragment_and_names_it_in_the_header():
  """A fragment on disk that nothing sources is a [0] FAIL, and one that is
  sourced without a header row is a [76f] FAIL. Both are asserted here so the
  wiring cannot rot separately from the check."""
  text = (REPO_ROOT / 'scripts' / 'validate-dod.sh').read_text(encoding='utf-8')
  expect(text, 'source "$DOD_MODULES_DIR/98-work-doc-ledger-sync.sh"',
         '#   98-work-doc-ledger-sync.sh, check [98],')

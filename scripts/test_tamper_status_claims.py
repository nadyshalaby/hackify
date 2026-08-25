#!/usr/bin/env python3
"""AC4 tamper rows for check [99], the work-doc status-claims fragment.

Imported and run by scripts/test_tamper_battery.py. It holds no main of its own,
the same structure scripts/test_tamper_fragments.py uses and the one check [97]
blesses in its own header: a suite reached by import from a file CI names is
wired.

WHY THIS FILE EXISTS AT ALL. Checks [98] and [99] were one fragment until it
reached 498 of a 500-LOC cap and could not take the created-date rule. The two
assertions that read a work-doc's FRONTMATTER moved out and KEPT THEIR LETTERS,
(a) the status vocabulary and (c) a live doc claiming it was archived, so a row
here naming assertion (a) names the same assertion it always did. Their rows moved
with them out of scripts/test_tamper_ledger_sync.py, which was itself at 499 lines
against the same cap and could not have held the new rows either.

WHAT A ROW HERE IS. One branch of check [99], broken on purpose, with the EXPECTED
FAILURE MESSAGE asserted rather than the exit status alone. A branch that reds in
another branch's words is a branch nobody can debug, and the two failures a
validator must never confuse, "the check looked and found the defect" and "the
check never ran", both arrive as a non-zero status.

EVERY ROW BUILDS ITS OWN TREE. Check [99] reads tracked work-docs out of the
working directory, so a throwaway git tree carrying a template and a dozen
synthetic docs lets a row decide exactly what the check sees. THE TREE IS BUILT
ABOVE EVERY FLOOR ON PURPOSE: floors are judged before any per-doc red prints, so
a fixture one doc short never reaches the assertion it meant to test and looks
exactly like a pass. tamper_harness.work_doc_tree is what keeps that from
happening by accident, and the two suites share it rather than keeping a copy each.

NOTHING HERE WRITES INTO THE REPOSITORY. A fragment is tampered by editing a COPY
in a temp file and a tree is built under a temp prefix, so a row that dies halfway
leaves nothing behind to restore.
"""

import os

from tamper_harness import (COUNT_BUMP, PASS_PREFIX, RED_CALL, REPO_ROOT,
                            SCRATCH_DOCS, TEMPLATE, expect, expect_red, git, refute,
                            run_check, run_check_without_python, run_fragment,
                            tampered, temp_dir, work_doc, work_doc_tree, write)

QUOTE = chr(39)
TICK = chr(96)

# A value no template row could carry, so a planted status can never collide with
# a real one.
BAD_STATUS = 'zzq-not-a-declared-status'

# The status row check [99] reads the vocabulary out of. Written as pieces because
# the cell is delimited by the character bash reads as a command substitution.
STATUS_ROW_HEAD = '| %sstatus%s |' % (TICK, TICK)

# The fragment's own CONTROL verdict line, assembled rather than written out. It
# is a format string carrying its own conversions, so building it by concatenation
# is what keeps the % operator away from them.
CONTROL_LINE = ('print(' + QUOTE + 'CONTROL %s' + QUOTE + ' % (' + QUOTE + 'ok'
                + QUOTE + ' if control(allowed) else ' + QUOTE + 'fail' + QUOTE + '))')

# The vocabulary comparison itself. Blinding it leaves every floor holding and every
# doc unreported, which is the tamper only the positive control can see.
VOCAB_TEST = 'if allowed and value not in allowed:'

# A status vocabulary the repository never declared, in the shape a template row
# takes. FOUR VALUES, deliberately: WS_VOCAB_FLOOR is 4, so a substituted list of
# this size clears the floor and every doc claiming one of its values reads clean.
EVIL_VALUES = ('pwned', 'owned', 'zzq1', 'done')
EVIL_TEMPLATE = ('# not the work-doc template\n\n| Field | Values | Meaning |\n'
                 '|---|---|---|\n%s %s | a file this repository does not own |\n'
                 % (STATUS_ROW_HEAD,
                    ' / '.join('%s%s%s' % (TICK, v, TICK) for v in EVIL_VALUES)))


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

def test_99_a_clean_tree_greens_and_names_what_it_examined():
  """Without a measured green every red below could be the scratch tree rather
  than the tamper. The counts are asserted too, because a pass line with no
  numbers reads the same whether the scan examined every doc or none of them."""
  rc, out = run_check('99', cwd=work_doc_tree())
  assert rc == 0, out
  expect(out, '%sall %d tracked work-doc(s) carry a status the template%ss %d '
         'declared value(s) allow' % (PASS_PREFIX, SCRATCH_DOCS, QUOTE,
                                      _declared_status_count()),
         'the positive control separated its reported docs from its clean ones')


# --- assertion (a), the status vocabulary --------------------------------------

def test_99_a_status_the_template_does_not_declare_reds_and_names_the_row():
  """The vocabulary comes out of the template at runtime, so the red has to name
  the declaring site a reader is meant to go and read."""
  root = work_doc_tree({'docs/work/planted.md': work_doc(BAD_STATUS)})
  rc, out = run_check('99', cwd=root)
  expect_red(rc, out, 'docs/work/planted.md:3 sets status: %s%s%s, which is none of '
             'the %d value(s) the row at %s declares' % (QUOTE, BAD_STATUS, QUOTE,
                                                         _declared_status_count(),
                                                         TEMPLATE))


def test_99_a_doc_with_no_status_field_reds_rather_than_being_skipped():
  """A doc that states no phase at all is the shape a value check silently drops:
  there is nothing to compare, so a naive reader moves on and the doc leaves the
  subject set without leaving the count."""
  root = work_doc_tree({'docs/work/planted.md': '# no frontmatter here\n\nbody\n'})
  rc, out = run_check('99', cwd=root)
  expect_red(rc, out, 'docs/work/planted.md carries no status field in its '
             'frontmatter')


# --- assertion (c), a live doc is not archived ---------------------------------

def test_99_a_live_doc_that_says_it_was_finished_reds():
  root = work_doc_tree({'docs/work/planted.md': work_doc('done')})
  rc, out = run_check('99', cwd=root)
  expect_red(rc, out, 'docs/work/planted.md:3 sets status: done while the file sits '
             'outside docs/work/done/')


def test_99_an_archived_doc_saying_it_is_done_is_not_a_finding():
  """The discriminator for the row above. Every archived doc in the scratch tree
  already says done, and none of them may be reported, or assertion (c) would be
  reddening on the one state it exists to bless."""
  rc, out = run_check('99', cwd=work_doc_tree())
  assert rc == 0, out
  refute(out, 'was never moved to the archive')


# --- the floors, and the collapses they exist to catch -------------------------

def test_99_the_doc_floor_reds_before_any_doc_is_judged():
  root = work_doc_tree({'docs/work/planted.md': work_doc(BAD_STATUS)})
  with tampered('99', ('WS_DOC_FLOOR=10', 'WS_DOC_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag, cwd=root)
  expect_red(rc, out, 'tracked doc(s) under docs/work/ against a floor of 9999',
             'a scan over nothing measures nothing')
  refute(out, BAD_STATUS)


def test_99_a_tree_with_no_work_docs_reds_on_the_doc_floor():
  """The collapse the floor is actually written against, reached for real rather
  than by moving the number: a pathspec that resolves to nothing."""
  root = temp_dir('status-empty-')
  write(root, TEMPLATE, (REPO_ROOT / TEMPLATE).read_text(encoding='utf-8'))
  git(root, 'init', '-q')
  git(root, 'add', '-A')
  rc, out = run_check('99', cwd=root)
  expect_red(rc, out, 'the work-doc scan read 0 tracked doc(s) under docs/work/ '
             'against a floor of 10')


def test_99_the_vocabulary_floor_reds_on_its_own_message():
  with tampered('99', ('WS_VOCAB_FLOOR=4', 'WS_VOCAB_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'the template parse read %d status value(s) against a floor '
             'of 9999' % _declared_status_count(),
             'would resolve against an empty vocabulary')


def test_99_a_template_that_loses_its_status_row_reds_without_accusing_every_doc():
  """The vocabulary collapsing for real. Two halves, and the second is the one
  that is easy to get wrong: with nothing to compare against, every doc in the
  tree looks wrong, so the per-doc sentence has to stay quiet and let the floor
  say what actually happened."""
  root = work_doc_tree(template=_template_without_the_status_row())
  rc, out = run_check('99', cwd=root)
  expect_red(rc, out, 'the template parse read 0 status value(s) against a floor of 4')
  refute(out, 'which is none of the')


# --- the positive control, and both ways it earns the silence ------------------

def test_99_a_control_that_never_runs_cannot_green_the_check():
  """The variable starts at `none` for exactly this. Take the control's verdict
  line away and the check must red rather than fall through to its pass line,
  because a control that did not run says nothing about whether the judge still
  works."""
  with tampered('99', (CONTROL_LINE, 'pass')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'the positive control did not hold (control verdict: none)')


def test_99_a_judge_that_stops_discriminating_is_caught_only_by_the_control():
  """THE ROW THE CONTROL EXISTS FOR. Blind the vocabulary comparison and a clean
  tree is judged exactly as it was before: no doc is reported, and every floor
  still holds, so nothing else in the fragment has anything to say. The control is
  the one thing that notices, because its bad-status doc stops coming back
  reported. Without it this tamper ships a check that greens over a comparison
  that no longer compares."""
  with tampered('99', (VOCAB_TEST, 'if allowed and False:')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)',
             'one carrying a status value no template row declares')


def test_99_a_judge_that_reports_everything_is_caught_by_the_same_control():
  """The other direction, and the reason the control carries clean docs at all.
  A comparison that degraded to always-fail is still a broken comparison, and a
  positive-only control would report ok right through it."""
  with tampered('99', (VOCAB_TEST, 'if allowed and True:')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)')


# --- the branches that only fire when the run itself is broken -----------------

def test_99_a_missing_interpreter_reds_rather_than_skipping():
  rc, out = run_check_without_python('99')
  expect_red(rc, out, '[99] needs python3 to parse work-doc frontmatter, and it is '
             'not on PATH')


def test_99_a_failed_stderr_capture_reds_rather_than_running_blind():
  with tampered('99', ('ws_err=$(mktemp 2>/dev/null)', 'ws_err=$(false)')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'could not create the stderr capture file, so the work-doc '
             'scan never ran')


def test_99_a_scan_that_cannot_finish_reds_rather_than_reading_silence_as_clean():
  """git ls-files exits non-zero outside a repository, which raises on the python
  side and lands in the fail-closed branch. A check that read the empty result as
  "no work-doc is out of step" would be green having looked at nothing."""
  root = temp_dir('status-nogit-')
  write(root, TEMPLATE, (REPO_ROOT / TEMPLATE).read_text(encoding='utf-8'))
  rc, out = run_check('99', cwd=root)
  expect_red(rc, out, 'the work-doc scan did not finish', 'git ls-files failed with rc')


def test_99_blinding_the_whole_red_helper_leaves_a_silent_green():
  """Both halves of the red path blinded: the run is silent AND exits 0, which is
  the fail-open a check exists to make impossible. Asserted so the shape is on
  record, the same row scripts/test_tamper_fragments.py carries for [95] and [97]."""
  root = work_doc_tree({'docs/work/planted.md': work_doc(BAD_STATUS)})
  with tampered('99', (RED_CALL, ':'), (COUNT_BUMP, ':')) as frag:
    rc, out = run_fragment(frag, cwd=root)
  assert rc == 0, out
  refute(out, BAD_STATUS, PASS_PREFIX)


# --- the fragment is wired into the run at all ---------------------------------

def test_99_the_orchestrator_sources_the_fragment_and_names_it_in_the_header():
  """A fragment on disk that nothing sources is a [0] FAIL, and one that is
  sourced without a header row is a [76f] FAIL. Both are asserted here so the
  wiring cannot rot separately from the check."""
  text = (REPO_ROOT / 'scripts' / 'validate-dod.sh').read_text(encoding='utf-8')
  expect(text, 'source "$DOD_MODULES_DIR/99-work-doc-status-claims.sh"',
         '#   99-work-doc-status-claims.sh, check [99],')


# --- discovery and reads, three ways a doc used to leave the corpus unseen ------

# A non-ASCII name. git C-quotes it by default, so it stops ending in .md and drops.
NON_ASCII_DOC = 'docs/work/zzq-%s-planted.md' % chr(0x3bb)

# Discovery reverted to what shipped before the hardening: no -z, split on newline.
NO_NUL_DISCOVERY = (("'git', 'ls-files', '-z', '--'", "'git', 'ls-files', '--'"),
                    (".split('\\0')", ".split('\\n')"))

# The gate refuse_read() opens a path through; blinded, it follows a link anywhere.
RESOLVE_GATE = ('real == full and real.startswith(ROOT + os.sep) '
                'and not os.path.islink(full)')

# A real status at column 0 UNDER a block scalar quoting an indented one. Only the
# column-0 line is this document's status; the indented one is a line of that scalar.
BLOCK_SCALAR_DOC = ('---\nslug: zzq-scratch\nsprint_goal: |\n  status: done\n'
                    'status: implementing\n---\n\nbody\n')


def _tree_with_symlinked_doc():
  """A tree whose tracked zzq-link.md links to a bad status outside the repository."""
  root = work_doc_tree()
  outside = write(temp_dir('status-outside-'), 'zzq-outside.md', work_doc(BAD_STATUS))
  os.symlink(str(outside), str(root / 'docs/work/zzq-link.md'))
  git(root, 'add', '-A')
  return root


def _tree_with_symlinked_template():
  """A tree whose tracked template is a symlink to a file outside the repository."""
  root = work_doc_tree({'docs/work/planted.md': work_doc('pwned')})
  outside = write(temp_dir('status-template-'), 'zzq-evil-template.md', EVIL_TEMPLATE)
  (root / TEMPLATE).unlink()
  os.symlink(str(outside), str(root / TEMPLATE))
  git(root, 'add', '-A')
  return root


def test_99_a_symlinked_template_is_refused_rather_than_read():
  """THE READ THAT LACKED THE GUARD. The declaring site is the one path this check
  trusts most and it was the one path opened without resolving first. Point it out of
  the tree and [99] took the outside file's four values as the status vocabulary,
  cleared the floor on them, passed a doc claiming one, and reported the honest doc
  instead. The refusal is a finding, and no per-doc sentence prints beside it."""
  rc, out = run_check('99', cwd=_tree_with_symlinked_template())
  expect_red(rc, out, 'the declaring site was never opened',
             '%s does not resolve to a plain file under the repository root' % TEMPLATE)
  refute(out, 'which is none of the', 'pwned')


def test_99_blinding_the_template_guard_reads_the_outside_file():
  """The discriminator for the row above, and what the guard is actually worth. With
  the resolve gate blinded the vocabulary comes out of a file the repository does not
  own: the planted doc claiming one of its values passes, and the honest doc beside
  it is the one reported. The control fails too, which is the second half of the
  fix, but the doc-side sentence is what proves the outside file was read."""
  with tampered('99', (RESOLVE_GATE, 'True')) as frag:
    rc, out = run_fragment(frag, cwd=_tree_with_symlinked_template())
  expect_red(rc, out, 'docs/work/live.md:3 sets status: %simplementing%s, which is '
             'none of the 4 value(s)' % (QUOTE, QUOTE),
             'the positive control did not hold (control verdict: fail)')
  refute(out, 'docs/work/planted.md:3 sets status')


def test_99_a_substituted_vocabulary_is_caught_by_the_control():
  """THE ROW IMPORTANT 3 EXISTS FOR, and it needs no symlink. A vocabulary read from
  a row the template did not declare clears every floor: four values is above
  WS_VOCAB_FLOOR and every doc claiming one of them reads clean. The control used to
  take its own good status out of that same parsed list, so it moved with the
  substitution and reported ok right through it. It carries a literal now, so a list
  that has stopped containing what the template declares fails here."""
  root = work_doc_tree({'docs/work/planted.md': work_doc('pwned')},
                       template=EVIL_TEMPLATE)
  rc, out = run_check('99', cwd=root)
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)')


def test_99_a_doc_named_with_a_non_ascii_byte_is_still_judged():
  rc, out = run_check('99', cwd=work_doc_tree({NON_ASCII_DOC: work_doc(BAD_STATUS)}))
  expect_red(rc, out, NON_ASCII_DOC + ':3 sets status: ' + QUOTE + BAD_STATUS)


def test_99_discovery_without_nul_records_drops_that_doc_without_a_word():
  """The defect reached for real, not by moving a number. No floor notices, because
  the twelve docs beside it clear WS_DOC_FLOOR: a green over a doc nobody read."""
  root = work_doc_tree({NON_ASCII_DOC: work_doc(BAD_STATUS)})
  with tampered('99', *NO_NUL_DISCOVERY) as frag:
    rc, out = run_fragment(frag, cwd=root)
  assert rc == 0, out
  refute(out, BAD_STATUS, NON_ASCII_DOC)
  expect(out, '%sall %d tracked work-doc(s)' % (PASS_PREFIX, SCRATCH_DOCS))


def test_99_a_symlinked_work_doc_is_reported_rather_than_followed():
  """A refusal is a finding, not a skip: a doc this check declined to read is not a
  doc that passed, and the status behind the link must not appear anywhere."""
  rc, out = run_check('99', cwd=_tree_with_symlinked_doc())
  expect_red(rc, out, 'docs/work/zzq-link.md does not resolve to a plain file under '
             'the repository root (it reaches ', 'zzq-outside.md), so this check '
             'refused to follow it rather than read what it points at')
  refute(out, BAD_STATUS)


def test_99_blinding_the_resolve_gate_follows_the_link_out_of_the_tree():
  with tampered('99', (RESOLVE_GATE, 'True')) as frag:
    rc, out = run_fragment(frag, cwd=_tree_with_symlinked_doc())
  expect_red(rc, out, 'docs/work/zzq-link.md:3 sets status: ' + QUOTE + BAD_STATUS)
  refute(out, 'does not resolve to a plain file')


def test_99_an_indented_status_inside_a_block_scalar_is_not_the_doc_status():
  """An innocent doc and the false accusation it used to draw. The count is asserted
  too, so a row passing because the doc never reached the corpus cannot look alike."""
  rc, out = run_check('99', cwd=work_doc_tree({'docs/work/planted.md':
                                               BLOCK_SCALAR_DOC}))
  assert rc == 0, out
  refute(out, 'sets status: done while the file sits outside')
  expect(out, '%sall %d tracked work-doc(s)' % (PASS_PREFIX, SCRATCH_DOCS + 1))


def test_99_a_stripped_frontmatter_read_would_accuse_that_innocent_doc():
  root = work_doc_tree({'docs/work/planted.md': BLOCK_SCALAR_DOC})
  with tampered('99', ('if not lines[num].startswith(key):',
                       'if not lines[num].strip().startswith(key):'),
                      ('value = lines[num][len(key):]',
                       'value = lines[num].strip()[len(key):]')) as frag:
    rc, out = run_fragment(frag, cwd=root)
  expect_red(rc, out, 'docs/work/planted.md:4 sets status: done while the file sits '
             'outside docs/work/done/')

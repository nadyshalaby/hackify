#!/usr/bin/env python3
"""AC4 tamper rows for check [98], the work-doc ledger-sync fragment.

Imported and run by scripts/test_tamper_battery.py. It holds no main of its own,
the same structure scripts/test_tamper_fragments.py uses and the one check [97]
blesses in its own header: a suite reached by import from a file CI names is
wired.

WHAT THIS FILE COVERS AND WHAT ITS SIBLING DOES. Check [98] carries the two
assertions that read a work-doc's SECTION 0 BLOCK, (b) an archived doc closes
every ledger row and (d) an archived doc written since section 0 shipped carries
the block at all. The two that read FRONTMATTER, (a) the status vocabulary and
(c) a live doc claiming it was archived, moved to check [99] when the fragment hit
the 500-LOC cap, and their rows moved with them to
scripts/test_tamper_status_claims.py. The letters did not change, so a row here
naming assertion (b) names the same assertion it always did.

WHY A FILE PER FRAGMENT RATHER THAN A SECTION IN test_tamper_fragments.py. That
file was already 465 lines against the project's 500-line hard cap when these rows
were written, and one section per fragment does not fit in the 35 lines left.
Splitting was the instruction rather than trimming coverage to fit, and check [97]
plus the PARTS tuple in the entrypoint are what keep the split files reachable.

WHAT A ROW HERE IS. One branch of check [98], broken on purpose, with the EXPECTED
FAILURE MESSAGE asserted rather than the exit status alone. A branch that reds in
another branch's words is a branch nobody can debug, and the two failures a
validator must never confuse, "the check looked and found the defect" and "the
check never ran", both arrive as a non-zero status.

EVERY ROW BUILDS ITS OWN TREE. Check [98] reads tracked work-docs out of the
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

from tamper_harness import (AFTER_LEDGER, BEFORE_LEDGER, CLEAN_ARCHIVED, COUNT_BUMP,
                            PASS_PREFIX, RED_CALL, REPO_ROOT, SCRATCH_DOCS, TEMPLATE,
                            expect, expect_red, git, refute, run_check,
                            run_check_without_python, run_fragment, tampered,
                            temp_dir, work_doc, work_doc_tree, write)

TICK = chr(96)
CODE_FENCE = TICK * 3

# Every archived doc in a clean tree is a subject of BOTH assertions, so the two
# subject counts on the pass line are the same number today. They are asserted
# separately anyway, because they count different sets and only stay equal while
# every archived fixture both carries a ledger and is dated after the pin.
ARCHIVED = SCRATCH_DOCS - 1

# The same doc with one row moved INSIDE the block. This is the discriminator for
# the clean fixture: if both came back the same way, the negative control below
# would be proving nothing.
OPEN_ARCHIVED = CLEAN_ARCHIVED.replace('- [x] Phase 2. Plan + Gate',
                                       '- [>] Phase 2. Plan + Gate')

# An archived doc with no section 0 anywhere, which is what assertion (d) exists
# for. Deleting the block used to be a way to turn a red green.
NO_LEDGER = '## 1. Original ask\n\nthe ask\n'

# The fragment's own CONTROL verdict line, assembled rather than written out. It
# is a format string carrying its own conversions, so building it by concatenation
# is what keeps the % operator away from them.
QUOTE = chr(39)
CONTROL_LINE = ('print(' + QUOTE + 'CONTROL %s' + QUOTE + ' % (' + QUOTE + 'ok'
                + QUOTE + ' if control() else ' + QUOTE + 'fail' + QUOTE + '))')

# The branch assertion (d) takes once a doc IS a dated subject. Blinding it leaves
# every subject count where it was, so no floor moves and only the control notices.
LEDGER_BRANCH = 'if has_ledger:'

# The line that reads the date off the filename. Blind it and the frontmatter value
# is the only resolver again, which is the hole Critical 2 of this sprint closed.
FILENAME_RESOLVER = 'stamp = filename_date(path)'

# An archived doc filed under a post-pin name. Every row below that plants one uses
# this path, so the filename half of the resolver has one spelling in this file.
DATED_DOC = 'docs/work/done/2026-08-24-planted.md'


# --- the baseline, and the counts it has to name -------------------------------

def test_98_a_clean_tree_greens_and_names_what_it_examined():
  """Without a measured green every red below could be the scratch tree rather
  than the tamper. The counts are asserted too, because a pass line with no
  numbers reads the same whether the scan examined every doc or none of them."""
  rc, out = run_check('98', cwd=work_doc_tree())
  assert rc == 0, out
  expect(out, '%sall %d tracked work-doc(s)' % (PASS_PREFIX, SCRATCH_DOCS),
         '(%d archived ledger(s) judged, %d archived doc(s) resolved against the '
         'pin date)' % (ARCHIVED, ARCHIVED),
         'the positive control separated its reported docs from its clean ones')


# --- assertion (b), an archived doc is finished --------------------------------

def test_98_an_archived_doc_with_an_open_ledger_row_reds_and_quotes_it():
  root = work_doc_tree({'docs/work/done/planted.md':
                        work_doc('done', AFTER_LEDGER, OPEN_ARCHIVED)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'docs/work/done/planted.md:10 carries an open - [>] row inside '
             'its ## 0. Phase ledger block',
             'still shows a phase nobody closed: - [>] Phase 2. Plan + Gate')


def test_98_an_open_row_outside_the_ledger_block_is_not_a_subject():
  """THE NEGATIVE CONTROL. Every clean doc in the scratch tree already carries an
  open row under `## Groom Provenance` and two more in its Sprint Backlog, in the
  identical grammar section 0 uses. None of them may be reported. A check that
  counted open rows file-wide would red on every archived doc in the real tree,
  which is the fabrication this sprint exists to refuse."""
  rc, out = run_check('98', cwd=work_doc_tree())
  assert rc == 0, out
  refute(out, 'carries an open')


def test_98_the_wrong_block_terminator_would_red_on_a_groomed_doc():
  """The discriminator for the row above, and the reason the terminator is any
  heading rather than the section-1 one. Point it at section 1 and the block
  swallows `## Groom Provenance`, so the row that block carries lands inside
  section 0 and every groomed doc in the tree reds. Without this the negative
  control would pass under either reading and prove nothing."""
  with tampered('98', ("HEADING = '## '", "HEADING = '## 1.'")) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'carries an open - [ ] row inside its ## 0. Phase ledger '
             'block', 'a row the groom block carries, outside section 0')


# --- assertion (d), an archived doc written since the ledger shipped has one ----

def test_98_an_archived_doc_created_after_the_pin_with_no_section_0_reds():
  """THE HOLE THIS ASSERTION CLOSES. Assertion (b) judges the rows of a block, so
  a doc with no block was a non-subject and deleting section 0 turned a red green.
  The message names the law a reader has to go and read, not just the defect."""
  root = work_doc_tree({'docs/work/done/planted.md':
                        work_doc('done', AFTER_LEDGER, NO_LEDGER)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'docs/work/done/planted.md is archived and '
             'resolves to %s, on or after the day section 0 became a work-doc '
             'section, yet it carries no ## 0. Phase ledger block' % AFTER_LEDGER,
             'never deleted, per skills/hackify/references/phase-ledger.md:91')


def test_98_an_archived_doc_created_before_the_pin_needs_no_section_0():
  """THE OTHER DIRECTION, and the reason the rule is dated at all. Most archived
  docs in the real tree predate the day section 0 became a work-doc section, a count
  this docstring deliberately does not pin. A rule that reddened on them would demand
  a ledger for sprints that ran before the mechanism existed, which is a record
  reconstructed to satisfy a check.
  The count is asserted too, so a row passing because the doc never reached the
  corpus cannot look the same as one passing because the date was read."""
  root = work_doc_tree({'docs/work/done/planted.md':
                        work_doc('done', BEFORE_LEDGER, NO_LEDGER)})
  rc, out = run_check('98', cwd=root)
  assert rc == 0, out
  refute(out, 'carries no ## 0. Phase ledger block')
  expect(out, '%sall %d tracked work-doc(s)' % (PASS_PREFIX, SCRATCH_DOCS + 1))


def test_98_an_archived_doc_whose_created_date_cannot_be_read_reds():
  """Deleting the date must not become the new way out. Both shapes are covered,
  the field absent altogether and a value that is not a date, because a rule that
  only checked for absence would accept `created: last tuesday` as a pass."""
  for body in (work_doc('done', None, CLEAN_ARCHIVED),
               work_doc('done', 'last tuesday', CLEAN_ARCHIVED)):
    rc, out = run_check('98', cwd=work_doc_tree({'docs/work/done/planted.md': body}))
    expect_red(rc, out, 'docs/work/done/planted.md sits under docs/work/done/ and its '
               'frontmatter carries no created field reading as a YYYY-MM-DD date at '
               'column 0', 'removing that field is not a way out of the section 0 rule')


def test_98_blinding_the_created_rule_hides_the_defect_and_only_the_control_notices():
  """THE ROW THE CONTROL EXISTS FOR. Take the branch that decides whether a dated
  archive actually has its block, and make it always say yes. Every subject count
  stays where it was, so no floor moves and nothing in the per-doc walk has a word
  to say about the planted doc. The control is the one thing that notices, because
  its own no-ledger doc stops coming back reported."""
  root = work_doc_tree({'docs/work/done/planted.md':
                        work_doc('done', AFTER_LEDGER, NO_LEDGER)})
  with tampered('98', (LEDGER_BRANCH, 'if True:')) as frag:
    rc, out = run_fragment(frag, cwd=root)
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)',
             'one dated after the ledger shipped with no section 0 at all')
  refute(out, 'carries no ## 0. Phase ledger block')


def test_98_a_created_rule_that_reports_every_archive_is_caught_by_the_same_control():
  """The other direction, and the reason the control carries clean docs at all. A
  rule degraded to always-fail is still a broken rule, and a positive-only control
  would report ok right through it."""
  with tampered('98', (LEDGER_BRANCH, 'if False:')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)')


# --- assertion (d), the date the doc does not get to choose ---------------------

def test_98_a_backdated_created_field_no_longer_removes_a_doc_from_the_rule():
  """THE HOLE THIS CLOSES, and it was one digit wide. The same archived doc with no
  section 0, differing only in the created value it writes about itself: the honest
  date reds and the backdated one used to green, so editing that field was a way out
  of assertion (d) altogether. It reds twice now, once for the missing block and once
  because the frontmatter date disagrees with the name the doc is filed under."""
  root = work_doc_tree({DATED_DOC: work_doc('done', BEFORE_LEDGER, NO_LEDGER)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out,
             '%s:4 says created %s while the filename it is filed under says '
             '2026-08-24' % (DATED_DOC, BEFORE_LEDGER),
             '%s is archived and resolves to 2026-08-24' % DATED_DOC)


def test_98_a_doc_filed_under_a_pre_pin_filename_still_needs_no_section_0():
  """The exemption, reached through the filename rather than the frontmatter. Most
  archived docs predate the day section 0 became a work-doc section, and a rule that
  reddened on them would demand a ledger for sprints that ran before the mechanism
  existed. The count is asserted too, so a row passing because the doc never reached
  the corpus cannot look the same as one passing because the date was read."""
  root = work_doc_tree({'docs/work/done/2026-05-11-planted.md':
                        work_doc('done', BEFORE_LEDGER, NO_LEDGER)})
  rc, out = run_check('98', cwd=root)
  assert rc == 0, out
  refute(out, 'carries no ## 0. Phase ledger block')
  expect(out, '%sall %d tracked work-doc(s)' % (PASS_PREFIX, SCRATCH_DOCS + 1))


def test_98_a_frontmatter_date_disagreeing_with_the_filename_is_reported_alone():
  """The disagreement isolated. This doc carries its section 0, so the missing-block
  half has nothing to say and the only red left is the one about two spellings of the
  same fact. Without this row the disagreement would only ever be observed riding
  alongside a second finding, and a reader could not tell which one fired."""
  root = work_doc_tree({DATED_DOC: work_doc('done', '2026-08-25', CLEAN_ARCHIVED)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, '%s:4 says created 2026-08-25 while the filename it is filed '
             'under says 2026-08-24' % DATED_DOC)
  refute(out, 'carries no ## 0. Phase ledger block')


def test_98_blinding_the_filename_resolver_reopens_the_hole_for_the_control_alone():
  """Take the filename back out of the resolution and the backdated doc goes quiet
  again: it resolves to the value it wrote about itself, falls under the pin, and
  stops being a subject. No floor moves, because a non-subject was never counted, and
  the per-doc walk has nothing left to say. The control is the one thing that
  notices, because its own backdated doc stops coming back reported."""
  root = work_doc_tree({DATED_DOC: work_doc('done', BEFORE_LEDGER, NO_LEDGER)})
  with tampered('98', (FILENAME_RESOLVER, 'stamp = None')) as frag:
    rc, out = run_fragment(frag, cwd=root)
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)',
             'one filed under a post-pin filename while its frontmatter backdates '
             'itself under the pin')
  refute(out, 'carries no ## 0. Phase ledger block')


# --- the floors, and the collapses they exist to catch -------------------------

def test_98_the_doc_floor_reds_before_any_doc_is_judged():
  root = work_doc_tree({'docs/work/done/planted.md':
                        work_doc('done', AFTER_LEDGER, OPEN_ARCHIVED)})
  with tampered('98', ('WL_DOC_FLOOR=10', 'WL_DOC_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag, cwd=root)
  expect_red(rc, out, 'tracked doc(s) under docs/work/ against a floor of 9999',
             'a scan over nothing measures nothing')
  refute(out, 'carries an open')


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


def test_98_the_archived_ledger_floor_reds_on_its_own_message():
  with tampered('98', ('WL_LEDGER_FLOOR=2', 'WL_LEDGER_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'archived doc(s) carrying a section 0 phase ledger against a '
             'floor of 9999', 'assertion (b) judged nothing')


def test_98_an_archive_carrying_no_ledger_at_all_reds_on_that_floor():
  """The same collapse reached for real. Archived docs with no section 0 leave
  assertion (b) with an empty subject set, and a check that reported a confident
  zero there would be green over a scan that never looked. Dated BEFORE the pin so
  assertion (d) has nothing to say and the floor is what this row measures."""
  root = work_doc_tree({'docs/work/done/archived-%d.md' % n:
                        work_doc('done', BEFORE_LEDGER, NO_LEDGER)
                        for n in range(SCRATCH_DOCS - 1)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'the scan found 0 archived doc(s) carrying a section 0 phase '
             'ledger against a floor of 2')


def test_98_the_created_floor_reds_on_its_own_message():
  with tampered('98', ('WL_CREATED_FLOOR=2', 'WL_CREATED_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'archived doc(s) against the day section 0 became a work-doc '
             'section, against a floor of 9999', 'assertion (d) judged nothing')


def test_98_an_archive_that_all_predates_the_pin_reds_on_the_created_floor():
  """The created floor reached for real, and the reason it is a SECOND floor. Every
  archived doc here still carries a closed ledger, so assertion (b)'s floor holds
  and its silence looks like a clean run. Only a floor counting what assertion (d)
  actually resolved can tell that half of the check judged nothing."""
  root = work_doc_tree({'docs/work/done/archived-%d.md' % n:
                        work_doc('done', BEFORE_LEDGER, CLEAN_ARCHIVED)
                        for n in range(SCRATCH_DOCS - 1)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'the scan resolved 0 archived doc(s) against the day section 0 '
             'became a work-doc section, against a floor of 2',
             'a doc could drop its section 0 unseen')


# --- the positive control, and both ways it earns the silence ------------------

def test_98_a_control_that_never_runs_cannot_green_the_check():
  """The variable starts at `none` for exactly this. Take the control's verdict
  line away and the check must red rather than fall through to its pass line,
  because a control that did not run says nothing about whether the judge still
  works."""
  with tampered('98', (CONTROL_LINE, 'pass')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
  expect_red(rc, out, 'the positive control did not hold (control verdict: none)')


# --- the branches that only fire when the run itself is broken -----------------

def test_98_a_missing_interpreter_reds_rather_than_skipping():
  rc, out = run_check_without_python('98')
  expect_red(rc, out, '[98] needs python3 to parse work-doc frontmatter, and it is '
             'not on PATH')


def test_98_a_failed_stderr_capture_reds_rather_than_running_blind():
  with tampered('98', ('wl_err=$(mktemp 2>/dev/null)', 'wl_err=$(false)')) as frag:
    rc, out = run_fragment(frag, cwd=work_doc_tree())
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
  root = work_doc_tree({'docs/work/done/planted.md':
                        work_doc('done', AFTER_LEDGER, NO_LEDGER)})
  with tampered('98', (RED_CALL, ':'), (COUNT_BUMP, ':')) as frag:
    rc, out = run_fragment(frag, cwd=root)
  assert rc == 0, out
  refute(out, 'carries no ## 0. Phase ledger block', PASS_PREFIX)


# --- the fragment is wired into the run at all ---------------------------------

def test_98_the_orchestrator_sources_the_fragment_and_names_it_in_the_header():
  """A fragment on disk that nothing sources is a [0] FAIL, and one that is
  sourced without a header row is a [76f] FAIL. Both are asserted here so the
  wiring cannot rot separately from the check."""
  text = (REPO_ROOT / 'scripts' / 'validate-dod.sh').read_text(encoding='utf-8')
  expect(text, 'source "$DOD_MODULES_DIR/98-work-doc-ledger-sync.sh"',
         '#   98-work-doc-ledger-sync.sh, check [98],')


# --- reads, and the doc that used to leave the corpus unseen -------------------

def test_98_a_symlinked_work_doc_is_reported_rather_than_followed():
  """A refusal is a finding, not a skip: a doc this check declined to read is not a
  doc that passed, and the open row behind the link must not appear anywhere."""
  root = work_doc_tree()
  outside = write(temp_dir('ledger-outside-'), 'zzq-outside.md',
                  work_doc('done', AFTER_LEDGER, OPEN_ARCHIVED))
  os.symlink(str(outside), str(root / 'docs/work/done/zzq-link.md'))
  git(root, 'add', '-A')
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'docs/work/done/zzq-link.md does not resolve to a plain file '
             'under the repository root (it reaches ', 'zzq-outside.md), so this '
             'check refused to follow it rather than read what it points at')
  refute(out, 'carries an open')


# --- the fence mask, and the archived count that rests on it -------------------

# Applied once in judge(), so every reader below judges the same masked copy.
FENCE_MASK = 'body = unfenced(lines)'

# Two separate evasions, each hiding an open row a working mask reports at line 13.
# SHADOWED quotes the heading in a fence ABOVE the real one, so a fence-blind search
# stops at the decoy and the block ends at the real heading below it. EARLY_END puts
# a fenced `## ` INSIDE the real block, so a fence-blind terminator fires on it.
SHADOWED = (CODE_FENCE + '\n## 0. Phase ledger\n' + CODE_FENCE
            + '\n\n## 0. Phase ledger\n\n- [>] Phase 3. Implement\n')
EARLY_END = ('## 0. Phase ledger\n\n' + CODE_FENCE + '\n## not a heading\n'
             + CODE_FENCE + '\n\n- [>] Phase 3. Implement\n')

# An archived doc whose ONLY ledger heading sits inside a fence, over a closed row.
FENCED_ONLY = (CODE_FENCE + '\n## 0. Phase ledger\n- [x] Phase 1. Clarify\n'
               + CODE_FENCE + '\n\n## 1. Original ask\n\nthe ask\n')


def _fence_blind(root):
  """The mask reverted to reading raw lines, over the tree at `root`."""
  with tampered('98', (FENCE_MASK, 'body = list(lines)')) as frag:
    return run_fragment(frag, cwd=root)


def _evasion(body):
  """One fenced evasion, both directions. Fence-blind, nothing in the per-doc walk
  notices; the only thing left to red is the control, whose own decoy doc separates
  just while both halves of the mask work."""
  root = work_doc_tree({'docs/work/done/planted.md':
                        work_doc('done', AFTER_LEDGER, body)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'docs/work/done/planted.md:13 carries an open - [>] row')
  rc, out = _fence_blind(root)
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)')
  refute(out, 'carries an open')


def test_98_a_fenced_decoy_heading_does_not_shadow_the_real_ledger():
  _evasion(SHADOWED)


def test_98_a_fenced_heading_inside_the_block_does_not_end_it_early():
  _evasion(EARLY_END)


def test_98_a_fenced_ledger_heading_does_not_count_toward_the_archived_floor():
  """The subtlest guard of the set, both directions in one row. WL_ARCHIVED counts a
  doc only when the block actually judged is the real one, so this corpus leaves
  assertion (b) nothing to judge. Blind the mask and those same docs count, the floor
  holds, and its message goes. Floors run before the control and a failing one returns
  first, so the missing floor line is how this row knows it held."""
  root = work_doc_tree({'docs/work/done/archived-%d.md' % n:
                        work_doc('done', AFTER_LEDGER, FENCED_ONLY)
                        for n in range(SCRATCH_DOCS - 1)})
  rc, out = run_check('98', cwd=root)
  expect_red(rc, out, 'the scan found 0 archived doc(s) carrying a section 0 phase '
             'ledger against a floor of 2')
  rc, out = _fence_blind(root)
  expect_red(rc, out, 'the positive control did not hold (control verdict: fail)')
  refute(out, 'archived doc(s) carrying a section 0 phase ledger against a floor of')

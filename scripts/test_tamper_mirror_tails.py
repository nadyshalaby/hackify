#!/usr/bin/env python3
"""Tamper rows for the agent-mirror tails and for check [75h]. python3 -m, no main.

Imported and run by scripts/test_tamper_battery.py, the same structure
scripts/test_tamper_fragments.py and scripts/test_tamper_ledger_sync.py use and
the one check [97] blesses in its own header: a suite reached by import from a
file CI names is wired.

WHAT THIS FILE COVERS. One mechanism read from both ends. The bottom end is
scripts/sync_agent_mirrors.py, which copies the FIRST fenced block of a template
into its mirror and hand-maintains everything after it, so the tail is where two
files drift while --check reports nine of nine. The top end is check [75h] in
scripts/validate-dod.d/75-ship-bar.sh, which reads that script's verdict and its
pair list. Neither half is testable without the other's fixtures, which is why
they sit in one file rather than beside the fragment rows for [75h]'s neighbours.

WHY IT LEFT THE BATTERY. scripts/test_tamper_battery.py reached 499 lines against
the project's 500-line hard cap, so the two regression rows this file was created
to hold had nowhere to land. Splitting was the instruction rather than trimming
coverage to fit, and it is the cut the file was already asking for: these rows
share seven fixtures with each other and none with the replay-runner and corpus
rows the battery keeps. The entrypoint's PARTS tuple and check [97] are what keep
a split file reachable.

WHAT A ROW HERE IS. One shape of drift, planted on a COPY, with the EXPECTED
FAILURE MESSAGE asserted rather than the exit status alone. Nothing writes into
the repository: the pair list resolves against the working directory, so a copy is
all a plant needs, and check [75h] resolves its inputs the same way.

AND EVERY PLANT THAT COULD BE INVISIBLE CARRIES A CONTROL. Two of the rows below
plant a defect that the rule under test is the ONLY thing standing between and a
green run, so each one is measured twice: once against the shipped code, which
must red, and once against a copy with that single rule blinded, which must go
green. A red with no such pair proves the run failed, never that it failed for the
reason the row names.
"""

import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tamper_harness import (REPO_ROOT, apply_edits, expect, refute,
                            run_fragment as run_shell_fragment, temp_dir)

# --- the mirror tail, and the shapes a bare prefix test waves through ---------
# WHAT WAS UNCHECKED. scripts/sync_agent_mirrors.py copies the FIRST fenced block
# of a template into its mirror and compared nothing else, so the hand-maintained
# region after it could drift in either direction while --check reported nine of
# nine and exited 0, and check [75h] read the same block and inherited the blind
# spot. Why full equality and a bare prefix are BOTH wrong answers is argued once,
# in that script's module docstring; the rows below plant one shape each against
# the rule it settles on. None writes into the repository: the pair list resolves
# against the working directory, so a copy is all a plant needs.

PA_DIR = 'skills/hackify/references/parallel-agents'
SYNC = 'scripts/sync_agent_mirrors.py'
SHIP_BAR = 'scripts/validate-dod.d/75-ship-bar.sh'

# Transcribed rather than imported: a fixture built from the constant it tests
# moves with a tamper on that constant and proves nothing.
PARENT_SIDE_MARKER = '<!-- parent-side: not mirrored -->'

# The outer fence, three backticks on a line of their own. Transcribed for the
# same reason, and the reason it is only ever three: the OUTPUT skeletons nested
# inside a block use four, so they never terminate one.
FENCE = '```'

# Written beside the lists they police rather than derived from them, on the
# argument 00-helpers.sh makes at check_list_size: a bound taken from the list
# drops with the list and guards nothing. TAILS_COMPARED is the pairs whose
# mirrored region has CONTENT: eight of ten owe an empty one, so ten pass lines
# were never ten comparisons.
MIRROR_PAIR_COUNT = 10
MARKED_TEMPLATE_COUNT = 4
TAILS_COMPARED_COUNT = 2

# A marked pair and an unmarked one. The second has two empty, equal tails.
MARKED_PAIR = ('agents/wave-implementer.md', PA_DIR + '/phase-3-implementation.md')
UNMARKED_PAIR = ('agents/code-reviewer-performance.md',
                 PA_DIR + '/phase-5-multi-review-d-performance.md')

# A sentence inside the marked mirror's region, unique in BOTH files.
MIRRORED_SENTENCE = 'If a section has nothing to report'
DRIFTED_SENTENCE = 'If a section has nothing to declare'

# Filler a row appends to a tail. Which side gets how many is the row's point.
EXTRA_TAIL = ('\nfirst extra tail line\n', 'second extra tail line\n',
              'third extra tail line\n')

# The invocation check [75h] delegates to. Spelled once here and once in the
# fragment, because apply_edits refuses a search text that occurs twice.
TAIL_CALL = 'python3 scripts/sync_agent_mirrors.py --check-tails'


def _mirror_tree():
  """A throwaway copy of both sides of every mirror pair."""
  root = temp_dir('mirrors-')
  shutil.copytree(REPO_ROOT / 'agents', root / 'agents')
  shutil.copytree(REPO_ROOT / PA_DIR, root / PA_DIR)
  return root


def _run_sync(root, *args, script=None):
  """Run the sync script against the tree at `root`. Returns (rc, text).

  The default is the SHIPPED script, which is what every row wants but two.
  `script` names a copy to run instead, which is how the control rows at the
  bottom of this file measure what one blinded rule is worth."""
  done = subprocess.run([sys.executable, str(script or REPO_ROOT / SYNC)] + list(args),
                        cwd=str(root), stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, timeout=60)
  return done.returncode, done.stdout.decode('utf-8', 'replace')


def _edit(root, rel, *edits):
  """Apply exactly-once edits to one copied file. Returns its path."""
  path = root / rel
  path.write_text(apply_edits(path.read_text(encoding='utf-8'), edits),
                  encoding='utf-8')
  return path


def _append(root, rel, body):
  """Append `body` to one copied file, which is how a row grows a tail."""
  path = root / rel
  path.write_text(path.read_text(encoding='utf-8') + body, encoding='utf-8')
  return path


def _fence_bounds(path):
  """One file's lines, and the indices of its bare fences.

  Spelled here rather than imported from scripts/sync_agent_mirrors.py, on the
  rule stated at PARENT_SIDE_MARKER: a fixture that reads the splitter it is
  testing moves with a tamper on that splitter and proves nothing."""
  lines = path.read_text(encoding='utf-8').splitlines(keepends=True)
  return lines, [i for i, line in enumerate(lines) if line.rstrip('\n') == FENCE]


def _truncate_at_the_block_fence(path):
  """Cut a file off after its fenced block, leaving an empty tail. Returns the
  number of tail lines removed, which is what tells a caller the cut removed
  something rather than editing a file that had no tail to begin with."""
  lines, fences = _fence_bounds(path)
  path.write_text(''.join(lines[:fences[1] + 1]), encoding='utf-8')
  return len(lines) - fences[1] - 1


def _pairs():
  """The pair list, read the way check [75h] reads it."""
  rc, out = _run_sync(REPO_ROOT, '--list')
  assert rc == 0, out
  return [line.split('|') for line in out.split('\n') if '|' in line]


def test_the_live_tree_carries_no_mirror_tail_drift():
  """The green the reds below are measured against, plus the marker census. Not a
  bare exit 0: a run that compared nothing exits 0 too. And not nine pass lines
  either, which is what this asserted while eight pairs owed their mirror an
  EMPTY region, reading 9 over one comparison with content in it. The two are
  counted apart, so a printer claiming more than it compared reds here."""
  rc, out = _run_sync(REPO_ROOT, '--check-tails')
  assert rc == 0, out
  assert out.count('  ok   ') == TAILS_COMPARED_COUNT, out
  assert out.count('  none ') == MIRROR_PAIR_COUNT - TAILS_COMPARED_COUNT, out
  marked = [t for _, t in _pairs()
            if PARENT_SIDE_MARKER in (REPO_ROOT / t).read_text(encoding='utf-8')]
  assert len(marked) == MARKED_TEMPLATE_COUNT, marked


def test_a_tail_edit_above_the_marker_reds_from_either_side():
  """Drift inside the region the mirror must carry. It is a disagreement and not
  a direction, and the finding was written about a tail drifting on BOTH sides,
  so each side in turn takes the same edit and owes the same red."""
  mirror, canonical = MARKED_PAIR
  for side in (mirror, canonical):
    root = _mirror_tree()
    _edit(root, side, (MIRRORED_SENTENCE, DRIFTED_SENTENCE))
    rc, out = _run_sync(root, '--check-tails')
    assert rc == 1, out
    expect(out, 'FAIL %s tail drifted' % mirror)


def test_a_mirror_tail_that_runs_past_the_marker_reds():
  """The equality's UPPER bound, and ONLY that: a mirror cannot annex parent-side
  text. It is NOT what makes the marker unforgeable, which this row claimed until
  the claim was measured. Sliding the marker UP while the mirror truncates to
  meet it leaves the two sides agreeing with the region gone, and marker_misplaced
  in the sync script is what reds on that. This plants on the mirror alone."""
  root = _mirror_tree()
  mirror, _ = MARKED_PAIR
  _append(root, mirror, ''.join(EXTRA_TAIL))
  rc, out = _run_sync(root, '--check-tails')
  assert rc == 1, out
  expect(out, 'FAIL %s tail drifted' % mirror, 'above its parent-side marker')


def test_a_mirror_tail_that_stops_early_reds_where_the_template_has_no_marker():
  """No marker means the whole tail is mirrored, so stopping short is drift. The
  pair starts empty on both sides, so the row grows a tail: three lines on the
  template, the first two on the mirror. A proper prefix that stops early."""
  root = _mirror_tree()
  mirror, canonical = UNMARKED_PAIR
  assert PARENT_SIDE_MARKER not in (root / canonical).read_text(encoding='utf-8')
  _append(root, canonical, ''.join(EXTRA_TAIL))
  _append(root, mirror, ''.join(EXTRA_TAIL[:2]))
  rc, out = _run_sync(root, '--check-tails')
  assert rc == 1, out
  expect(out, 'FAIL %s tail drifted' % mirror, 'no parent-side marker')


def test_a_mirror_tail_deleted_wholesale_reds_even_though_it_is_still_a_prefix():
  """The case a bare prefix test waves through, and the reason the marker names
  an END rather than a start. Truncating the mirror at its fence leaves an empty
  tail, and the empty sequence is a prefix of every sequence there is."""
  root = _mirror_tree()
  mirror, _ = MARKED_PAIR
  assert _truncate_at_the_block_fence(root / mirror) > 0, 'nothing was truncated'
  rc, out = _run_sync(root, '--check-tails')
  assert rc == 1, out
  expect(out, 'FAIL %s tail drifted' % mirror, 'the mirror carries 0 tail line(s)')


def test_an_unrecognised_flag_refuses_instead_of_rewriting_nine_mirrors():
  """Write mode is the no-flag case, so a mistyped flag was indistinguishable
  from it: measured on a copied tree, `--chekc` resynced every mirror and exited
  0. [75h] runs this script from the validator, which would then edit its tree."""
  root = _mirror_tree()
  planted = _edit(root, UNMARKED_PAIR[0], ('**ROLE**.', '**ROLE**. zzq drift'))
  before = planted.read_text(encoding='utf-8')
  rc, out = _run_sync(root, '--chekc')
  assert rc == 2, out
  expect(out, 'unrecognised argument')
  assert planted.read_text(encoding='utf-8') == before, 'the run rewrote a mirror'


# --- check [75h]'s own branch, reached the way this repo reaches a branch -----

def _tampered_fragment(rel, *edits):
  """An edited COPY of one shipped fragment. tamper_harness.tampered() is keyed on
  a FRAGMENTS map neither fragment read here is in, and that module is outside this
  task's allowlist, so the copy is made here under the same rule: read, never
  written."""
  root = temp_dir('tamper-frag-')
  target = root / rel.rsplit('/', 1)[-1]
  target.write_text(
      apply_edits((REPO_ROOT / rel).read_text(encoding='utf-8'), edits),
      encoding='utf-8')
  return target


def test_75h_is_green_on_the_live_tree_and_names_what_it_compared():
  """Without a measured green the reds below could be wiring rather than the
  tamper, the argument check [91]'s baseline row makes. On [75h]'s own lines and
  NOT on rc, which coupled this row to every check from [75a] to [75k]."""
  out = run_shell_fragment(REPO_ROOT / SHIP_BAR, cwd=REPO_ROOT)[1]
  expect(out, 'the mirror pair list covers all %d file(s)' % MIRROR_PAIR_COUNT,
         'compared a non-empty mirrored tail')


def test_75h_tells_a_crashing_tail_comparison_apart_from_a_drifted_tail():
  """rc cannot separate the two shapes, since an uncaught exception and a genuine
  red both exit 1. A call that REPORTS drift owes the drift words; one that dies
  reporting nothing owes CRASH and must not ALSO say drift, which is what it used
  to say, sending the reader to hand-carry text between two innocent files."""
  drift = 'a mirror tail drifted from the canonical tail it must carry'
  for edit, present, absent in (
      ((TAIL_CALL, "printf '  FAIL planted\\n'; exit 1"), drift, 'CRASHED'),
      ((TAIL_CALL, 'false'), 'the mirror tail comparison CRASHED', drift)):
    rc, out = run_shell_fragment(_tampered_fragment(SHIP_BAR, edit), cwd=REPO_ROOT)
    assert rc != 0, out
    expect(out, present)
    refute(out, absent)


# --- I18, the pair-count floor, which has to keep deriving from the tree -------
# WHAT ROUND 8 CHANGED, AND WHAT HAD BEEN PROVING IT. Check [75h] used to compare
# the pair list against a hardcoded 9. It now compares against `find agents
# -maxdepth 1 -type f -name '*.md'`, on the argument the fragment makes at that
# line: a number written beside a list gets edited by the same hand that shortens
# the list, in the same file, in the same minute, while agents/ is a SECOND source
# that a dropped tuple cannot reach. Until this row that change was proved by one
# hand-plant recorded in a wave report, which is a proof that does not run again.
#
# THE PLANT HAS TO MOVE THE TREE, NOT THE FRAGMENT, and that is the whole reason
# this row is shaped the way it is. A hardcoded 10 is INVISIBLE on a tree that has
# ten agent files: the derived form and the hardcoded form print the identical
# green. The defect only becomes one when the tree moves, so these two rows move
# the tree once and run both forms over that same tree, which turns an invisible
# difference into two verdicts that contradict each other.

# Transcribed rather than read out of the fragment, on the rule stated at
# PARENT_SIDE_MARKER above: a fixture built from the text it tests moves with a
# tamper on that text and proves nothing. apply_edits refuses a search text that
# does not occur exactly once, so rewriting this derivation in the fragment breaks
# the row LOUDLY rather than leaving it asserting a message the new form happens
# to print anyway.
AGENT_COUNT_DERIVATION = (
    "AGENT_FILE_TOTAL=$(find agents -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')")

# A tenth file under agents/ that no pair in the list covers. Named to sort last
# and to read as scratch in any listing.
TENTH_AGENT = 'zzq-tenth-agent.md'


def _ship_bar_tree():
  """A tree check [75h] can be run against: both sides of every pair, plus the
  sync script, which the fragment invokes at a path relative to the working
  directory rather than out of the repository."""
  root = _mirror_tree()
  (root / 'scripts').mkdir(parents=True, exist_ok=True)
  shutil.copy2(REPO_ROOT / SYNC, root / SYNC)
  return root


def _tree_with_an_uncovered_agent():
  """A tree whose agents/ holds one more file than the pair list covers, which is
  what a tenth agent registered without a MIRROR_PAIRS tuple looks like."""
  root = _ship_bar_tree()
  shutil.copy2(REPO_ROOT / UNMARKED_PAIR[0], root / 'agents' / TENTH_AGENT)
  return root


def test_75h_reds_when_agents_holds_a_file_the_pair_list_does_not_cover():
  """The regression this row exists for: a tenth agent file, nine pairs, and both
  halves of [75h] blind to the difference. BOTH branches are asserted, because the
  derivation feeds two of them, the pair-count compare and the tail-verdict count,
  and a change that left either reading a constant would still half-work."""
  out = run_shell_fragment(REPO_ROOT / SHIP_BAR,
                           cwd=_tree_with_an_uncovered_agent())[1]
  expect(out,
         'the mirror pair list covers %d pair(s) against %d file(s) in agents/'
         % (MIRROR_PAIR_COUNT, MIRROR_PAIR_COUNT + 1),
         'returned a verdict for %d pair(s) against %d file(s) in agents/'
         % (MIRROR_PAIR_COUNT, MIRROR_PAIR_COUNT + 1))
  refute(out, 'covers all %d file(s)' % (MIRROR_PAIR_COUNT + 1))


def test_hardcoding_the_pair_count_prints_a_green_over_that_same_tree():
  """The control, and the half that makes the row above mean what it says. Same
  tree, same fragment, one edit: the derivation replaced by the constant it
  replaced. It prints the green the row above refutes, so the red up there is the
  derivation working rather than the tree being odd, and a wave that hardcodes
  this number again fails HERE with the two verdicts swapped."""
  fragment = _tampered_fragment(
      SHIP_BAR, (AGENT_COUNT_DERIVATION, 'AGENT_FILE_TOTAL=%d' % MIRROR_PAIR_COUNT))
  out = run_shell_fragment(fragment, cwd=_tree_with_an_uncovered_agent())[1]
  expect(out,
         'the mirror pair list covers all %d file(s) in agents/' % MIRROR_PAIR_COUNT)
  refute(out, 'against %d file(s) in agents/' % (MIRROR_PAIR_COUNT + 1))


# --- I21, the marker position, which no cross-file comparison can stand in for -
# THE ONE MOVE A DIFF BETWEEN TWO FILES CANNOT SEE is both files moving together.
# Slide a template's parent-side marker up to the first line of its tail, truncate
# the mirror to meet it, and the two sides agree again with the entire mirrored
# region deleted. tail_drift returns None, honestly, because there is nothing left
# to disagree about. marker_misplaced in scripts/sync_agent_mirrors.py is the only
# thing between that move and a green run, and until this row it was proved by one
# hand-plant recorded in a wave report.
#
# WHAT PINS THE MARKER IS THE FENCE BELOW IT, which is why the rule can be stated
# at all: the block ends at the SECOND bare fence, which on this pair is the
# VERIFICATION script's closing fence in the MIDDLE of the prompt, so the prompt's
# own closing fence sits in the tail. A marker above that fence cuts the prompt in
# half. The rule is argued once, in that script's module docstring under THE
# MARKER'S POSITION IS PINNED TOO.

# The one line of scripts/sync_agent_mirrors.py that implements the position rule.
# Transcribed, for the reason AGENT_COUNT_DERIVATION gives above.
POSITION_RULE = (
    '    below = [i for i, line in enumerate(canonical_tail[index + 1:], index + 1)')


def _slide_marker_to_the_tail_top(root):
  """Plant the coordinated move on the marked pair, and return how many tail lines
  the mirror lost doing it.

  The count is the row's control: a plant that removed nothing would leave the two
  sides agreeing for the honest reason, and the red it earned would be about
  nothing. Every row below asserts it before it trusts a verdict."""
  mirror, canonical = MARKED_PAIR
  path = root / canonical
  lines, fences = _fence_bounds(path)
  top = fences[1] + 1
  kept = [line for line in lines[top:] if line.strip() != PARENT_SIDE_MARKER]
  assert len(kept) == len(lines) - top - 1, 'the template tail carries no marker'
  path.write_text(''.join(lines[:top] + [PARENT_SIDE_MARKER + '\n'] + kept),
                  encoding='utf-8')
  return _truncate_at_the_block_fence(root / mirror)


def _sync_without_the_position_rule():
  """A COPY of the sync script with marker_misplaced blinded to return None.

  One rule removed and nothing else, so the row that runs it measures what that
  rule is worth rather than what a broken script does."""
  target = temp_dir('blind-sync-') / 'sync_agent_mirrors.py'
  target.write_text(
      apply_edits((REPO_ROOT / SYNC).read_text(encoding='utf-8'),
                  ((POSITION_RULE, '    return None\n' + POSITION_RULE),)),
      encoding='utf-8')
  return target


def test_a_marker_slid_above_the_prompt_fence_reds_though_the_tails_agree():
  """The regression row for the position rule. It asserts the ABSENCE of the drift
  words as hard as the presence of the marker words: a red here that said `tail
  drifted` would mean the cross-file comparison caught it after all and the marker
  rule was never reached, which is the reading this row exists to rule out."""
  root = _mirror_tree()
  dropped = _slide_marker_to_the_tail_top(root)
  assert dropped > 0, 'the plant deleted no mirrored tail, so it planted nothing'
  rc, out = _run_sync(root, '--check-tails')
  assert rc == 1, out
  expect(out, 'parent-side marker misplaced', 'it cuts the prompt in half')
  refute(out, 'tail drifted')


def test_the_same_move_goes_green_once_the_position_rule_is_blinded():
  """The control. With marker_misplaced returning None the identical plant exits 0
  and reports the truncated pair as owing an empty tail and carrying one, which is
  the false green the rule was written against. Without this half, the row above
  proves a run failed and not that it failed for the reason it names."""
  root = _mirror_tree()
  assert _slide_marker_to_the_tail_top(root) > 0
  rc, out = _run_sync(root, '--check-tails',
                      script=_sync_without_the_position_rule())
  assert rc == 0, out
  expect(out, 'has no mirrored tail region to compare')
  refute(out, 'misplaced')


# --- the agent-file census, which TWO fragments derive and both used to miscount -
# `find agents -maxdepth 1 -name '*.md'` counts anything NAMED that way, a directory
# and a symlink included, and two checks decide whether the tree agrees with a list
# by that count: [75h] above, and [30] in 60-primitives.sh. Every row above plants a
# REGULAR file, so the battery returned the same total with `-type f` and without
# it, and the property was proved once by hand, a proof that does not run again.

PRIMITIVES = 'scripts/validate-dod.d/60-primitives.sh'

# The second fragment's copy of the derivation, and the flag both of them turn on.
# Transcribed, for the reason AGENT_COUNT_DERIVATION gives above.
PRIMITIVES_DERIVATION = ("agent_count=$(find agents -maxdepth 1 -type f -name "
                         "'*.md' 2>/dev/null | wc -l | tr -d ' ')")
TYPE_FLAG = '-type f '

# A directory and a symlink, each named the way an agent file is named and neither
# one an agent. Named to sort last and to read as scratch in any listing.
DIR_AGENT = 'zzq-notes.md'
LINK_AGENT = 'zzq-link.md'
MISCOUNT = MIRROR_PAIR_COUNT + 2


def _tree_with_non_files_named_like_agents():
  """A tree whose agents/ holds a directory and a symlink named *.md beside the
  nine real files. `-type f` is the only thing between it and a census of 11."""
  root = _ship_bar_tree()
  (root / 'agents' / DIR_AGENT).mkdir()
  (root / 'agents' / LINK_AGENT).symlink_to(root / UNMARKED_PAIR[0])
  return root


def test_neither_census_counts_a_directory_or_a_symlink_as_an_agent_file():
  """Both sites over ONE plant, and two fragment runs because one run cannot reach
  both: sourcing 75-ship-bar.sh never executes 60-primitives.sh. [30] is read on its
  own lines and never on rc, since that fragment also runs [29], [31] and [32],
  which a tree holding only agents/ cannot satisfy."""
  root = _tree_with_non_files_named_like_agents()
  out = run_shell_fragment(REPO_ROOT / SHIP_BAR, cwd=root)[1]
  expect(out, 'the mirror pair list covers all %d file(s)' % MIRROR_PAIR_COUNT)
  refute(out, 'against %d file(s) in agents/' % MISCOUNT)
  out = run_shell_fragment(REPO_ROOT / PRIMITIVES, cwd=root)[1]
  expect(out, 'ok   agents/ contains exactly %d *.md files' % MIRROR_PAIR_COUNT)
  refute(out, 'contains %d *.md files' % MISCOUNT)


def test_both_censuses_miscount_that_same_tree_once_the_flag_is_taken_away():
  """The control, and what makes the row above mean what it says. A directory named
  *.md is INVISIBLE on a tree that has none, so both forms print the identical green
  until the tree moves. Same tree, both fragments, one edit each, both now counting
  11. A wave that drops the flag again fails HERE, in whichever half it drops it."""
  root = _tree_with_non_files_named_like_agents()
  for rel, source, needle in (
      (SHIP_BAR, AGENT_COUNT_DERIVATION,
       'covers %d pair(s) against %d file(s) in agents/' % (MIRROR_PAIR_COUNT,
                                                            MISCOUNT)),
      (PRIMITIVES, PRIMITIVES_DERIVATION,
       'FAIL agents/ contains %d *.md files; expected %d' % (MISCOUNT,
                                                             MIRROR_PAIR_COUNT))):
    fragment = _tampered_fragment(rel, (source, source.replace(TYPE_FLAG, '')))
    expect(run_shell_fragment(fragment, cwd=root)[1], needle)

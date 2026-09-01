#!/usr/bin/env python3
"""AC4 tamper rows for check [76j], quick's review-phase name at its three sites.

Imported and run by scripts/test_tamper_battery.py. It holds no main of its own,
the same structure scripts/test_tamper_fragments.py uses and the one check [97]
blesses in its own header: a suite reached by import from a file CI names is wired.

WHY THIS FILE EXISTS AT ALL. scripts/validate-dod.d/76-phase-ledger-substrate.sh
grew [76j], which lifts quick's review-phase name out of three sites and compares
them. Its six manufactured reds were proven by hand in one wave transcript and
nothing re-took them on a run, which is the same defect this sprint has now fixed
three times: a new guard ships and its own detection is never re-tested.

WHY IT IS A SECOND FILE RATHER THAN A SECTION OF ITS SIBLING. These rows were
written inside scripts/test_tamper_phase_laws.py and took it from 344 to 540 LOC,
past the 500-LOC cap check [80] enforces. Two ways out, and only one of them is
allowed here. Compacting the [76e] prose next door to buy room is refused for the
reason 76-phase-ledger-substrate.sh gives at its own split, that it "would trade a
real invariant for a cosmetic one", and the battery entrypoint states the general
rule in as many words: "splitting was the instruction rather than trimming coverage
to fit".

WHY THIS SEAM AND NOT SOME OTHER. The two groups ask different questions. The rows
next door ask whether each phase law is pinned in the FORM that survives the
post-turn-1 digest, so they tamper bullet markers and asterisks in one file. The rows
here ask whether ONE NAME is stated the same way at every site that states it, so
they tamper a name across two files and, in the row that matters most, tamper it
COHERENTLY and demand silence. That is the same seam 76-phase-ledger-substrate.sh cut
when [76g] and [76h] moved to 96-review-scope-sites.sh, and its header records the
test: they "asked a different question from the rest of this file".

WHAT THE SEAM COST, AND WHERE IT WENT. Unlike that precedent, this split does share
state: the corpus builder, the twice-over-one-tree measurement, the literal-edit
transform and check_list_size's red sentence. All four live in scripts/tamper_harness.py,
which already owned substrate_tree and already holds message builders like
struct_counts, and which every part imports and nothing imports back. Putting them in
either suite would make one suite import its sibling, which is the cycle that module's
own docstring exists to refuse.

EVERY ROW MEASURES A DIFFERENCE, NEVER A TOTAL. [76] carries nine other checks over
files no row here edits, and a row asserting the fragment's whole failure count would
inherit any red from those and report a working check as broken. So each row runs the
fragment twice over ONE tree, once pristine and once tampered, and asserts how many
reds the edit ADDED. An unrelated red sits in both halves and cancels.

THE ROW THAT MATTERS MOST IS THE ONE THAT STAYS GREEN. [76j] is built to pass a
COHERENT rename, because what it guards is disagreement between the sites and not the
vocabulary they agree on. A suite carrying only breaks cannot tell a working check
from one that reds on everything, so the rename row is the only row here proving the
check does not tax the correct edit.

NOTHING HERE WRITES INTO THE REPOSITORY. The corpus is a copy under a temp prefix and
a fragment is tampered by editing a copy, so a row that dies halfway leaves nothing
behind to restore and no checksum to verify.
"""

from tamper_harness import (PASS_PREFIX, expect, refute, size_fail, substrate_delta,
                            tampered, text_edit)

# THE SITES ARE SPELLED OUT HERE, never lifted with the fragment's own regexes: a
# fixture derived from the thing it tests moves with a tamper on that thing and proves
# nothing, the call the [76e] rows make for themselves at their own five pins.
#
# 'All-lens' IS TODAY'S NAME AND IS NOT WHAT THESE ROWS ARE ABOUT. [76j] never writes
# the name down. It derives one name per site from a fixed frame and compares the
# three, so a coherent rename passes with no edit here. These rows tamper the name
# only because it is the single variable run inside each anchor.
LENS_QUICK = 'skills/quick/SKILL.md'
LENS_LEDGER = 'skills/hackify/references/phase-ledger.md'

# Per site: the path, the label the fragment's own heredoc gives that clause in a red
# line, the name as that site spells it, and the whole clause. TWO OF THE THREE ARE IN
# ONE FILE, which is why the fragment anchors each on prose unique to its own site
# rather than on the bare name. The case differs because the frontmatter states the
# name mid-sentence while the other two open with it, which is why the fragment folds
# case before comparing and why these rows must not tidy it.
#
# ORDER IS LOAD-BEARING, AND _stranded BELOW IS WHERE THAT BITES. The fragment walks
# this same order and takes the FIRST site that resolves as its reference, so site 0 is
# the reference and the other two are measured against it.
LENS_SITES = (
  (LENS_QUICK, 'frontmatter clause', 'all-lens',
   'all-lens address-all review still closes before finish'),
  (LENS_QUICK, 'flow-table step heading', 'All-lens', '**5-lite. All-lens review**'),
  (LENS_LEDGER, 'quick ledger row', 'All-lens',
   'Phase 5-lite. All-lens address-all review'),
)

# The fragment's hand-written bound, written here as its own number rather than as
# len(LENS_SITES), for the reason 00-helpers.sh gives above check_list_size: a bound
# read off the list it polices drops with a deleted entry and stays green.
LENS_EXPECTED = 3
LENS_LABEL = ("the sites stating quick's review-phase name, each anchored above by "
              'its own clause')

# The rename every row applies, in each site's own case, and the frontmatter frame with
# the name left out. Rewording the FRAME breaks a site past its anchor, as opposed to
# renaming inside a frame that still matches, and those are the two different failures
# the rows below separate.
LENS_NEW = 'one-lens'
LENS_FRAME = 'address-all review still closes before finish'

# The fragment line the discriminator row blinds. It occurs once, and apply_edits
# raises rather than tampering nothing if that ever stops being true.
LENS_COMPARE = 'elif [ "$pls_lfold" != "$pls_lens_first" ]; then'


def lens_where(index):
  """The site as a red line names it: its path, then the label of its clause."""
  return "%s's %s" % (LENS_SITES[index][0], LENS_SITES[index][1])


def lens_disagree(index, got, ref):
  """[76j]'s disagreement red, worded as the fragment words it. The reference is
  always site 0, the first one that resolves, which is why every row passes its
  name as `ref`."""
  return ("  FAIL [76j] %s calls quick's review phase '%s', while %s calls it '%s'; "
          'one phase with two names is a reword that stranded the sites it did not '
          'reach' % (lens_where(index), got, lens_where(0), ref))


def lens_missing(index):
  """[76j]'s red for a site whose anchor no longer matches anything."""
  return ('  FAIL [76j] %s carries no %s matching the review-phase-name anchor; the '
          'clause was reworded past its own frame, or the site is gone'
          % (LENS_SITES[index][0], LENS_SITES[index][1]))


def lens_site_ok(index):
  """The green ONE site prints when its anchor resolves. Asserted on a clean corpus so
  the reds below are known to be the tamper rather than a corpus short a path."""
  return "%s%s names quick's review phase '%s' in its %s" % (
    PASS_PREFIX, LENS_SITES[index][0], LENS_SITES[index][2], LENS_SITES[index][1])


def lens_agree(name):
  """The green [76j] prints when all three sites say the same thing, folded."""
  return ("%sall %d sites call quick's review phase '%s' (compared case-folded)"
          % (PASS_PREFIX, LENS_EXPECTED, name))


def _lens_rename(index):
  """A transform map renaming the phase at site `index`, its frame left alone."""
  path, _label, name, clause = LENS_SITES[index]
  return {path: text_edit((clause, clause.replace(name, LENS_NEW)))}


def _lens_reds(transforms, expected):
  """Apply `transforms` to the corpus, require exactly `expected` extra reds, and hand
  the output back so the caller can insist on WHOSE words those reds are."""
  extra, out = substrate_delta(transforms)
  assert extra == expected, 'expected %d extra red(s), got %d:\n%s' % (
    expected, extra, out)
  return out


def test_76j_a_clean_corpus_resolves_all_three_sites_and_agrees_on_the_name():
  """THE BASELINE THE ROWS BELOW ARE MEASURED AGAINST. Without a measured green every
  red below could be the corpus rather than the tamper: a corpus short one of these
  two files reds every row here for a reason that is not the row's. Each site's own
  pass line is asserted, not just the agreement line, because the agreement green
  prints over however many sites resolved and reads the same at three as it would at
  two."""
  extra, out = substrate_delta({})
  assert extra == 0, 'the pristine corpus is not stable:\n%s' % out
  expect(out, lens_agree(LENS_SITES[0][2]),
         *[lens_site_ok(n) for n in range(len(LENS_SITES))])


def _stranded(index):
  """Rename the phase at ONE site and assert every red that strands, by name.

  WHY THE COUNT IS ASYMMETRIC, 2 FOR SITE 0 AND 1 FOR THE OTHERS. It is the check's
  design and not a defect, and it is written out here so nobody has to rediscover it
  by reading the fragment. [76j] walks LENS_SITES in order, takes the FIRST site that
  resolves as its reference, and reds once per LATER site that disagrees with that
  reference. It deliberately refuses to adjudicate which site is the stale one,
  because at two sites there is no majority to read that off and a majority rule that
  works only at three breaks the day a fourth site picks the name up.

  So renaming site 0 moves the REFERENCE, and both survivors then disagree with it:
  two reds, each naming a site the reword stranded. Renaming site 1 or site 2 leaves
  the reference where it was and strands only that site: one red. A row expecting one
  red everywhere would be asserting a behaviour [76j] has not got, and would fail
  against a working check."""
  if index == 0:
    reds = [lens_disagree(n, LENS_SITES[n][2].lower(), LENS_NEW)
            for n in range(1, len(LENS_SITES))]
  else:
    reds = [lens_disagree(index, LENS_NEW, LENS_SITES[0][2])]
  out = _lens_reds(_lens_rename(index), len(reds))
  expect(out, *reds)
  refute(out, lens_agree(LENS_NEW), lens_agree(LENS_SITES[0][2]))


def test_76j_renaming_the_phase_in_the_frontmatter_alone_strands_both_other_sites():
  """TWO reds: this site is the reference, so both survivors disagree with it. See
  _stranded above for why that is the design rather than a double-count."""
  _stranded(0)


def test_76j_renaming_the_phase_in_the_flow_table_heading_alone_reds_and_names_it():
  """ONE red. The reword that motivated [76j]: one of the two clauses inside
  skills/quick's own file moves and the other does not, so a file-scoped presence pin
  would have greened on the survivor. The red names the heading AND the frontmatter it
  now disagrees with."""
  _stranded(1)


def test_76j_renaming_the_phase_in_the_quick_ledger_row_alone_reds_and_names_it():
  """ONE red, at THE SITE A PER-FILE PIN LEAVES BEHIND: a wave renaming the two clauses
  in skills/quick/SKILL.md fixes the reds it sees there and never opens
  phase-ledger.md, so this is the direction the check exists for."""
  _stranded(2)


def test_76j_rewording_a_site_past_its_own_anchor_reds_on_the_site_and_the_count():
  """TWO REDS FROM TWO DIFFERENT GUARDS, and the pair is what stops the comparison
  passing on nothing. The anchor stops matching, so the site is reported gone, and the
  hand-written 3 catches that only two names reached the comparison. Without the
  count, two survivors would agree with each other and print a confident green over a
  site nobody could find."""
  reword = text_edit((LENS_FRAME, LENS_FRAME.replace('closes', 'runs')))
  out = _lens_reds({LENS_QUICK: reword}, 2)
  expect(out, lens_missing(0), size_fail(LENS_LABEL, LENS_EXPECTED - 1, LENS_EXPECTED))
  refute(out, lens_agree(LENS_SITES[0][2]))


def test_76j_a_coherent_rename_at_all_three_sites_costs_nothing_and_greens():
  """THE ROW A CARELESS AUTHOR DROPS, AND THE ONLY ONE PROVING [76j] IS A CHECK RATHER
  THAN A TAX. Every other row here breaks something and watches a red arrive, which a
  guard that reddened unconditionally would pass just as well. Rename the phase at all
  three sites at once and the fragment has nothing to say: no extra red, and its green
  reports the NEW name, derived from the sites rather than read off a literal the
  renaming wave would have had to come here and update."""
  pairs = {}
  for index in range(len(LENS_SITES)):
    path, _label, name, clause = LENS_SITES[index]
    pairs.setdefault(path, []).append((clause, clause.replace(name, LENS_NEW)))
  out = _lens_reds({p: text_edit(*edits) for p, edits in pairs.items()}, 0)
  expect(out, lens_agree(LENS_NEW))
  refute(out, lens_agree(LENS_SITES[0][2]))


def test_76j_blinding_the_comparison_takes_the_stranded_site_red_away():
  """WHETHER THIS SUITE CATCHES [76j] BEING WEAKENED, answered by measurement, the
  mechanism test_tamper_phase_laws.py's deleted-pin row uses for [76e]. Blind the one
  condition that compares a site against the reference and the flow-table reword
  produces no red at all, so the row above it fails and says which comparison stopped
  happening. Worse than silence, the fragment then prints its agreement green over
  three sites that do not agree, which is what a check that cannot fail looks like
  from outside."""
  with tampered('76', (LENS_COMPARE, 'elif false; then')) as frag:
    extra, out = substrate_delta(_lens_rename(1), frag)
  assert extra == 0, 'expected the blinded comparison to say nothing, got %d:\n%s' % (
    extra, out)
  refute(out, lens_disagree(1, LENS_NEW, LENS_SITES[0][2]))
  expect(out, lens_agree(LENS_SITES[0][2]))


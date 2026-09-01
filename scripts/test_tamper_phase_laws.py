#!/usr/bin/env python3
"""AC4 tamper rows for check [76e], the five injected phase laws.

Imported and run by scripts/test_tamper_battery.py. It holds no main of its own,
the same structure scripts/test_tamper_fragments.py uses and the one check [97]
blesses in its own header: a suite reached by import from a file CI names is wired.

WHY THIS FILE EXISTS. scripts/validate-dod.d/76-phase-ledger-substrate.sh pins the
five load-bearing laws of rules/phase-discipline.md in exact bullet form, plus a
hand-written size bound over that file's bold bullet leads. Nothing tested that
fragment. The battery drove nine fragments and 76 was not among them, so the guard
standing over every injected law had no proof its own detection was still wired:
delete a pin and both suites stayed green. That is the same defect this sprint has
already fixed twice, a new guard shipped with no tamper row.

WHY THE PINS CARRY THEIR ASTERISKS, which is the whole reason the de-bold rows
below are here and the reason a naive suite omits them. rules/phase-discipline.md
rides on every prompt, and after the first turn hooks/inject_context.py keeps only
each bullet's bold lead, its BULLET_LEAD matching a `-`, `*` or `1.` marker and
then a bold run. A REWORDED law stops matching its own words, which any grep-shaped
test notices. A DE-BOLDED law is still present, still greps clean on every word it
had, and reaches no prompt after the first. So a suite that only reworded would
bless a pin written without asterisks, and these rows separate "pinned by its
words" from "pinned in the form that survives the digest".

EVERY ROW MEASURES A DIFFERENCE, NEVER A TOTAL. [76] carries five other checks over
four files no row here edits, and a row asserting the fragment's whole failure count
would inherit any red from those and report a working check as broken. A wave this
round watched exactly that happen to its own control, which reported five where it
meant three. So each row runs the fragment TWICE OVER ONE TREE, once pristine and
once with its edit applied, and asserts how many reds the edit ADDED. An unrelated
red sits in both halves and cancels.

THE COUNT WRITTEN HERE IS WRITTEN BY HAND, beside the five pins it stands over, for
the reason scripts/validate-dod.d/00-helpers.sh gives above check_list_size: a bound
read off the list it polices drops with a deleted entry and stays green. Documented
bias, stated the way check [76f] states its own: a wave that adds a sixth law to
rules/phase-discipline.md reddens every row here until it adds that law's row too.
That is the intent, not a stale constant.

[76j] IS THE SAME FRAGMENT AND A DIFFERENT QUESTION, so its rows are next door in
scripts/test_tamper_lens_sites.py rather than below. They were written here, took this
file from 344 to 540 LOC, and split out at the 500-LOC cap: these rows ask whether each
law is pinned in the FORM that survives the digest, those ask whether one NAME is
stated the same way at every site that states it. The seam cost four helpers, which
moved to scripts/tamper_harness.py where the corpus builder already lived; that file's
header carries the argument, and this one keeps only what is law-specific.

NOTHING HERE WRITES INTO THE REPOSITORY. The corpus is a copy under a temp prefix
and a fragment is tampered by editing a copy, so a row that dies halfway leaves
nothing behind to restore and no checksum to verify.
"""

from tamper_harness import (PASS_PREFIX, PHASE_RULES, REPO_ROOT, expect, refute,
                            run_check, size_fail, substrate_delta, substrate_tree,
                            tampered, text_edit)

# The five pins as the fragment spells them, marker and asterisks included, because
# that exact form is what the rows below are about. Written out rather than parsed
# out of the fragment: a fixture derived from the thing it tests moves with a tamper
# on that thing and proves nothing, which is the call test_tamper_status_claims.py
# makes at its own AFTER_LEDGER date.
LAW_LEDGER = '- **Every task that edits code opens the step ledger**'
LAW_IN_ORDER = '- **Phases run in order, one open at a time.**'
LAW_NO_SKIP = '- **No phase is ever silently skipped.**'
LAW_WIZARD = '- **Every question goes through the wizard tool.**'
LAW_PERSIST = ('- **A tick with no reflection is an untrusted tick, and a deferred '
               'write is no tick at all: checkbox and written entry land together as '
               'each agent returns, and the archive move follows the closing edit.**')

# The hand-written size the fragment's own bound carries, and the count of the tuple
# beside it. Two independently written numbers rather than one derived from the other.
LAW_LEADS = 5
LAWS = (LAW_LEDGER, LAW_IN_ORDER, LAW_NO_SKIP, LAW_WIZARD, LAW_PERSIST)

# One reword per law, each a plausible edit a wave would make while believing it had
# changed nothing that matters. Derived from the pin by one word swap so the pair
# stays readable as a pair, and every one keeps its bold lead, which is what makes
# these rows measure the PIN alone and leave the count check green.
REWORDS = (LAW_LEDGER.replace('opens the step', 'starts the step'),
           LAW_IN_ORDER.replace('order, one open', 'order, with one open'),
           LAW_NO_SKIP.replace('ever silently skipped', 'ever skipped in silence'),
           LAW_WIZARD.replace('question goes through', 'question is asked through'),
           LAW_PERSIST.replace('the closing edit', 'the final edit'))

# A sixth bold bullet lead, inserted under the fifth law. It is what an added law
# looks like to the counter, and nothing pins it, which is the point.
SIXTH_LAW = '- **A sixth law that no pin above names.**'

# The label check_list_size prints its verdict against, assembled from the fragment's
# own two pieces: the file it polices and the phrase the call site hands it.
COUNT_LABEL = "%s's bolded law leads, each pinned above by name" % PHASE_RULES
COUNT_OK = '%s%s carries all %d entries' % (PASS_PREFIX, COUNT_LABEL, LAW_LEADS)

# The two fragment lines the discriminator rows blind. Each occurs once, and
# apply_edits raises rather than tampering nothing if that ever stops being true.
PIN_CALL = 'check_token_present ' + chr(39) + '%s' + chr(39) + ' "$PLS_PHASE_RULES"'
BOUND_CALL = 'check_list_size "$PLS_LAW_LEADS" %s '


def count_fail(got):
  """The law counter's red, at the bound this file writes by hand."""
  return size_fail(COUNT_LABEL, got, LAW_LEADS)


def pin_fail(law):
  """check_token_present's red for one pin, worded as the helper words it."""
  return '  FAIL %s%s%s missing from %s' % (chr(39), law, chr(39), PHASE_RULES)


def pin_ok(law):
  """The pass line the same pin prints when it holds. Refuted beside every red, so
  a row proves the pin actually stopped matching rather than that something else
  in the fragment spoke up."""
  return '%s%s%s%s present in %s' % (PASS_PREFIX, chr(39), law, chr(39), PHASE_RULES)


# --- the measurement every row below is built on -------------------------------
#
# substrate_delta runs check [76] twice over ONE corpus tree and returns the reds the
# edit ADDED, so an unrelated red sits in both halves and cancels. It lives in
# tamper_harness.py because the [76j] suite measures the same way; what stays here is
# the law-shaped half, the phase-discipline.md transforms nothing else edits.

def _delta(transform, fragment=None):
  """The single-file case, on rules/phase-discipline.md, which every law row uses."""
  return substrate_delta({PHASE_RULES: transform}, fragment)


def _lead_line(lines, law):
  """The index of the ONE line whose lead is `law`, or raise.

  apply_edits makes the same demand of its own search text and for the same reason:
  an anchor that has drifted would edit nothing, and the row would then assert
  against a file it never touched."""
  found = [n for n, line in enumerate(lines) if line.startswith(law)]
  if len(found) != 1:
    raise AssertionError('the lead %r opens %d lines, not one; this row is no longer '
                         'editing what it names' % (law, len(found)))
  return found[0]


def _drop_law(law):
  """A transform deleting the whole line `law` opens, body prose included."""
  def transform(text):
    lines = text.split('\n')
    del lines[_lead_line(lines, law)]
    return '\n'.join(lines)
  return transform


def _add_law(law, extra):
  """A transform inserting `extra` as its own line directly under `law`."""
  def transform(text):
    lines = text.split('\n')
    lines.insert(_lead_line(lines, law) + 1, extra)
    return '\n'.join(lines)
  return transform


# --- the baseline the rows are measured against --------------------------------

def test_76_the_corpus_carries_every_path_the_fragment_reads():
  """THE ONE ROW BOUND TO THE WHOLE FRAGMENT, and it is here to prove the builder
  copies everything [76] opens rather than most of it. A tree short one path would
  put a red into both halves of every measurement below, where it would cancel and
  go unseen while the corpus was quietly wrong.

  A red here naming a file other than rules/phase-discipline.md is a defect in that
  file, not in these rows: [76] also pins the canonical ledger sentence, the per-phase
  protocol files, the runtime-adapter rows and the orchestrator's own header.

  THE STATUS ALONE IS THE WEAK FORM OF THIS CLAIM, and it is not what this row
  asserts any more. rc == 0 catches a missing path only where the fragment happens to
  red on the absence, which is what saved this row when [76j] shipped reading
  skills/quick/SKILL.md and SUBSTRATE_FILES did not carry it: grep exited 2 and the row
  went red for a working check. A fragment whose missing-file branch shrugs instead
  would have been invisible to it, and a corpus built from a hand-written tuple has no
  other way to notice a fragment reading outside itself.

  SO THE CORPUS IS COMPARED AGAINST THE REAL TREE, output for output, which is the
  cheapest statement of the property this row is named after. Every path the fragment
  opens is one substrate_tree copies verbatim, so a COMPLETE corpus makes check [76]
  say the identical thing over both trees, and a path the tuple omits changes what it
  says over one of them. The comparison inherits the delta rows' own trick: a red in
  BOTH runs cancels, so a genuinely broken repository file reddens the row that owns it
  rather than this one.

  TWO LIMITS, STATED HERE RATHER THAN DISCOVERED LATER. It cannot see a branch that
  greens IDENTICALLY with the file present and absent, and no output-shaped check can
  reach that one. And it covers [76]'s corpus alone: declaration_tree, work_doc_tree
  and structure_tree plant deliberately SYNTHETIC trees that are meant to differ from
  the repository, so comparing their output against it would assert nothing. Those
  three want a measured pristine-green baseline instead, which none of them has."""
  rc, out = run_check('76', cwd=substrate_tree())
  assert rc == 0, 'the pristine corpus reds:\n%s' % out
  live_rc, live_out = run_check('76', cwd=REPO_ROOT)
  assert (rc, out) == (live_rc, live_out), (
    'check [76] says something different over the corpus than over the repository, so '
    'substrate_tree is not carrying every path the fragment reads:\n--- corpus ---\n%s'
    '\n--- repository ---\n%s' % (out, live_out))


def test_76_a_clean_corpus_greens_all_five_law_pins_and_the_hand_written_count():
  """Without a measured green every red below could be the corpus rather than the
  tamper. The count line is asserted with its number, because a pass line that
  names no total reads the same whether the counter judged five leads or none."""
  rc, out = run_check('76', cwd=substrate_tree())
  assert rc == 0, out
  expect(out, COUNT_OK, *[pin_ok(law) for law in LAWS])


# --- a law reworded: the pin reds, the counter has nothing to say ---------------

def _reword_reds(index):
  """Reword one law and require exactly one extra red, in that law's own words."""
  extra, out = _delta(text_edit((LAWS[index], REWORDS[index])))
  assert extra == 1, 'expected 1 extra red, got %d:\n%s' % (extra, out)
  expect(out, pin_fail(LAWS[index]), COUNT_OK)
  refute(out, pin_ok(LAWS[index]))


def test_76_rewording_the_ledger_mandate_reds_and_names_that_law():
  _reword_reds(0)


def test_76_rewording_the_phases_in_order_law_reds_and_names_that_law():
  _reword_reds(1)


def test_76_rewording_the_no_silent_skip_law_reds_and_names_that_law():
  _reword_reds(2)


def test_76_rewording_the_wizard_law_reds_and_names_that_law():
  _reword_reds(3)


def test_76_rewording_the_persistence_law_reds_and_names_that_law():
  """The longest lead in the file, carrying two rules inside one bold run. The
  fragment pins it whole for that reason, so one word moved at its tail has to red
  here or the rule sitting outside a shorter pin could be reworded around it."""
  _reword_reds(4)


# --- a law de-bolded: not one word changed, and it leaves the digest -------------

def _debold_reds(index):
  """Strip the asterisks from one law, leaving every word where it was.

  TWO reds, and the pair is the point. The pin reds because it carries the bullet
  form, and the counter reds because a de-bolded bullet is no longer a bold lead, so
  the count drops to four. Either one alone would catch this; that both do is what
  makes a de-bold the loudest edit in the file rather than the quietest."""
  law = LAWS[index]
  extra, out = _delta(text_edit((law, law.replace('**', '', 2))))
  assert extra == 2, 'expected 2 extra reds, got %d:\n%s' % (extra, out)
  expect(out, pin_fail(law), count_fail(LAW_LEADS - 1))
  refute(out, pin_ok(law), COUNT_OK)


def test_76_de_bolding_the_ledger_mandate_reds_on_its_pin_and_on_the_count():
  _debold_reds(0)


def test_76_de_bolding_the_phases_in_order_law_reds_on_its_pin_and_on_the_count():
  _debold_reds(1)


def test_76_de_bolding_the_no_silent_skip_law_reds_on_its_pin_and_on_the_count():
  _debold_reds(2)


def test_76_de_bolding_the_wizard_law_reds_on_its_pin_and_on_the_count():
  _debold_reds(3)


def test_76_de_bolding_the_persistence_law_reds_on_its_pin_and_on_the_count():
  _debold_reds(4)


# --- the hand-written bound, on both sides --------------------------------------

def test_76_a_sixth_bolded_law_reds_on_the_hand_written_count_alone():
  """THE DIRECTION ONLY THE COUNT CAN CATCH. Every one of the five pins still
  matches, so nothing else in the fragment has a word to say about a law that
  arrived with no pin of its own. One extra red, and it is the counter's."""
  extra, out = _delta(_add_law(LAW_PERSIST, SIXTH_LAW))
  assert extra == 1, 'expected 1 extra red, got %d:\n%s' % (extra, out)
  expect(out, count_fail(LAW_LEADS + 1), *[pin_ok(law) for law in LAWS])
  refute(out, COUNT_OK)


def test_76_a_law_deleted_outright_reds_on_both_its_pin_and_the_count():
  """The other side of the same bound, and the failure check_list_size exists for:
  a set that shrinks. Both guards speak, so the transcript says which law left and
  that the set is now one short, rather than only one of the two."""
  extra, out = _delta(_drop_law(LAW_WIZARD))
  assert extra == 2, 'expected 2 extra reds, got %d:\n%s' % (extra, out)
  expect(out, pin_fail(LAW_WIZARD), count_fail(LAW_LEADS - 1))
  refute(out, pin_ok(LAW_WIZARD))


def test_76_a_bound_read_off_the_file_it_polices_greens_over_the_sixth_law():
  """THE ROW THE HAND-WRITTEN 5 EXISTS FOR, made executable rather than argued.
  Swap the fragment's literal bound for the count it just took off the file and the
  added law passes: the bound moved with the list it was meant to police, and the
  pass line reports six entries with total confidence. This is the failure
  00-helpers.sh records above check_list_size, where a floor of 4 once sat under a
  set of 6 and guarded nothing."""
  derived = BOUND_CALL % '"$PLS_LAW_LEADS"'
  with tampered('76', (BOUND_CALL % LAW_LEADS, derived)) as frag:
    extra, out = _delta(_add_law(LAW_PERSIST, SIXTH_LAW), frag)
  assert extra == 0, 'expected the derived bound to say nothing, got %d:\n%s' % (
    extra, out)
  expect(out, '%s%s carries all %d entries' % (PASS_PREFIX, COUNT_LABEL,
                                               LAW_LEADS + 1))


def test_76_a_law_rewritten_with_another_bullet_marker_still_counts_as_a_lead():
  """The counter matches the injector's own marker set, `-` or `*` or `1.`, and not
  a narrower `- `. A law moved onto a star marker still reaches the digest, so it
  still has to be counted: the pin reds because it carries the dash, and the count
  stays at five because the lead is still a lead. A narrower counter would drop this
  law from the count and from its pin at once, and the two reds would cancel into a
  green."""
  extra, out = _delta(text_edit((LAW_IN_ORDER, '* ' + LAW_IN_ORDER[2:])))
  assert extra == 1, 'expected 1 extra red, got %d:\n%s' % (extra, out)
  expect(out, pin_fail(LAW_IN_ORDER), COUNT_OK)


# --- what a deleted pin costs, measured rather than assumed ---------------------

def test_76_deleting_a_pin_from_the_fragment_takes_its_reword_red_away():
  """WHETHER THIS SUITE CATCHES A PIN DELETED FROM THE FRAGMENT, answered by
  measurement. It does, and this row is the mechanism: blind one pin and the reworded
  law it stood over produces no red at all, so the reword row above it fails and says
  which law stopped being watched. That is coverage of the fragment's own detection,
  which is the property [76] could not previously claim about itself.

  It is one law rather than five because the same wiring carries all five, and the
  five reword rows are what actually stand over the other four."""
  law = LAW_NO_SKIP
  with tampered('76', (PIN_CALL % law, ':')) as frag:
    extra, out = _delta(text_edit((law, REWORDS[2])), frag)
  assert extra == 0, 'expected the blinded pin to say nothing, got %d:\n%s' % (
    extra, out)
  refute(out, pin_fail(law), pin_ok(law))
  expect(out, COUNT_OK)


# --- the fragment is wired into the run at all ----------------------------------

def test_76_the_orchestrator_sources_the_fragment_and_names_it_in_the_header():
  """A fragment on disk that nothing sources is a [0] FAIL, and one sourced without
  a header row is a [76f] FAIL. Both are asserted here so the wiring cannot rot
  separately from the checks, the same pair test_tamper_status_claims.py asserts for
  its own fragment."""
  text = (REPO_ROOT / 'scripts' / 'validate-dod.sh').read_text(encoding='utf-8')
  expect(text, 'source "$DOD_MODULES_DIR/76-phase-ledger-substrate.sh"',
         '#   76-phase-ledger-substrate.sh, checks [76]')

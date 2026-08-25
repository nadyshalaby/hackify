#!/usr/bin/env python3
"""AC4 tamper rows for the five check fragments this sprint built.

Imported and run by scripts/test_tamper_battery.py. It holds no main of its own,
the same structure skills/lawkeeper/scripts/test_scoping.py uses and the one
check [97] blesses in its own header.

WHAT A ROW HERE IS. One branch of one fragment, broken on purpose, with the
EXPECTED FAILURE MESSAGE asserted rather than the exit status alone. AC4 asks for
exactly that distinction: a branch that reds in another branch's words is a branch
nobody can debug, and a run that reds for a wiring reason reads identically to a
run that reds for the reason the check exists.

THE BRANCHES THESE ROWS GO AFTER ARE THE ONES NOTHING ELSE REACHES. Six suites
already ship. Between them they cover the replay-mode floors, the replay-root
refusals, the per-site reports and the live-tree greens. What none of them can
reach is the set of branches that only fire when the LIVE tree is broken: every
floor on the live path, the missing-interpreter branch, the failed-capture branch,
and the premise guard. A healthy tree cannot trip any of those, so a floor could
be off by an order of magnitude and every existing suite would stay green. The
tamper is what makes them reachable, and copying a fragment into a temp file is
what makes the tamper safe.

CHECK [91] HAD NO SUITE AT ALL BEFORE THIS FILE. It is the only fragment of the
five that shipped with no executable proof of any kind, so its section here is the
longest and carries the greens as well as the reds.

TWO STRINGS IN THIS FILE ARE BUILT AT RUNTIME AND THAT IS NOT DECORATION. Check
[94] polices one retired work-doc section label and check [91] reds on any check id
that resolves to nothing, and both scan this file along with every other live file.
Writing either literal here would redden a shipped check on its own test suite. The
existing answer for that is an exclusion list, and [94]'s own header now says in as
many words that each entry on it is a real hole rather than a formality. So these
rows assemble the two strings from pieces instead, the blind spot stays where it
was, and no shipped fragment had to be edited to land this file.
"""

import re

import test_ci_suite_coverage as ci_cov
from tamper_harness import (COUNT_BUMP, FRAGMENT_DIR, PASS_PREFIX, RED_CALL, REPO_ROOT,
                            declaration_tree, expect, expect_red, refute, run_check,
                            run_check_replay, run_check_without_python, run_fragment,
                            run_replay, tampered, temp_dir, write)

TICK = chr(96)

# The two declaration grammars check [91] reads, transcribed here so one row can
# form a second opinion about the tree instead of grading the fragment against
# its own output.
FRAG_DECL = re.compile(r'^yellow "\[(\d+[a-z]?)\]', re.M)
ORCH_DECL = re.compile(r'^#\s+\[(\d+[a-z]?)\]', re.M)

# See the last paragraph of the module docstring. Neither literal appears in this
# file, so neither shipped check reddens on it.
FABRICATED_ID = 'check [%s]' % '999'
RETIRED_LABEL = 'Implementation' + chr(32) + 'Log'
PINNING_CLAIM = 'not ' + 'pinned'

# A phrase chosen to occur nowhere else in the tree, so the live scans stay quiet
# while the replay scope can still put it in two files at once.
MARKER_PHRASE = 'zzq marker phrase'

# A whole-file prompt in the shape check [93] recognises: the three bold anchors,
# a numbered INPUTS item declaring one name, and a second name used but declared
# nowhere.
PROMPT = ('**ROLE**. a worker.\n\n**OBJECTIVE**. one diff.\n\n**INPUTS**.\n'
          '1. {{alpha}}, the declared input.\n\n**OUTPUT**. the report uses {{beta}}\n')


def _blind(key, count=False):
  """Tamper one fragment's red helper. `count` also removes the status bump.

  Blinding the print alone leaves a run that exits non-zero while naming nothing,
  which is the ambiguous shape scripts/replay_claim_checks.py refuses to score.
  Blinding both leaves a run that is silent AND exits 0, which is the fail-open a
  check exists to make impossible."""
  edits = [(RED_CALL, ':')]
  if count:
    edits.append((COUNT_BUMP, ':'))
  return tampered(key, *edits)


def _claim_tree():
  """A copied declaration tree carrying one document that asserts a dead id."""
  root = declaration_tree()
  write(root, 'docs/notes.md', '# notes\n\nThe wiring is proved by %s today.\n'
        % FABRICATED_ID)
  ci_cov.git(root, 'add', '-A')
  return root


def declared_id_sets():
  """(fragment-declared ids, orchestrator-declared ids) read straight off disk."""
  frag = set()
  for path in sorted(FRAGMENT_DIR.glob('*.sh')):
    frag.update(FRAG_DECL.findall(path.read_text(encoding='utf-8')))
  orchestrator = (REPO_ROOT / 'scripts' / 'validate-dod.sh').read_text(encoding='utf-8')
  return frag, set(ORCH_DECL.findall(orchestrator))


def _replay(prefix, files):
  """A replay scope holding exactly `files`, as {relative path: body}."""
  root = temp_dir(prefix)
  for rel, body in files.items():
    write(root, rel, body)
  return root


# --- check [91], the fragment that shipped with no suite ----------------------

def test_91_the_live_tree_resolves_every_claim_it_carries():
  """The baseline. Without a measured green the reds below could all be wiring."""
  rc, out = run_check('91')
  assert rc == 0, out
  expect(out, "%sall " % PASS_PREFIX, "'check [NN]' claim(s) across")


def test_91_the_claim_floor_reds_before_any_claim_is_judged():
  with tampered('91', ('CR_REF_FLOOR=20', 'CR_REF_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, "'check [NN]' claim(s) against a floor of 9999",
             'a resolver over nothing measures nothing')


def test_91_the_fragment_id_floor_reds_on_its_own_message():
  with tampered('91', ('CR_FRAG_ID_FLOOR=60', 'CR_FRAG_ID_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'the known-id set collapsed to',
             'against floors of 9999 and 2',
             'this check would red on correct text')


def test_91_the_orchestrator_id_floor_reds_on_its_own_message():
  """Same sentence as the row above, and the numbers are what tell them apart."""
  with tampered('91', ('CR_ORCH_ID_FLOOR=2', 'CR_ORCH_ID_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'the known-id set collapsed to', 'against floors of 60 and 9999')


def test_91_a_fabricated_check_id_reds_and_names_the_file_and_the_line():
  root = _claim_tree()
  rc, out = run_check('91', cwd=root)
  expect_red(rc, out, 'docs/notes.md:3 asserts a %s that no fragment declares'
             % FABRICATED_ID, 'searched')


def test_91_a_git_that_cannot_list_the_tree_reds_rather_than_scanning_nothing():
  """Every path the scan reads is on disk here. Only the tracking is missing, so
  a fragment that read the filesystem instead of the index would come back green."""
  rc, out = run_check('91', cwd=declaration_tree(tracked=False))
  expect_red(rc, out, 'the claim scan did not finish', 'git ls-files failed with rc')


def test_91_a_missing_interpreter_reds_rather_than_skipping():
  rc, out = run_check_without_python('91')
  expect_red(rc, out, '[91] needs python3 to resolve check-id claims, '
             'and it is not on PATH')


def test_91_a_failed_stderr_capture_reds_rather_than_running_blind():
  with tampered('91', ('cr_err=$(mktemp 2>/dev/null)', 'cr_err=$(false)')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'could not create the stderr capture file, '
             'so the claim scan never ran')


def test_91_blinding_the_printed_red_leaves_a_run_that_names_nothing():
  """The shape the replay runner refuses to score. The status still says failure
  and the transcript says nothing at all, so a reader cannot tell which finding
  fired or whether one did."""
  root = _claim_tree()
  with _blind('91') as frag:
    rc, out = run_fragment(frag, cwd=root)
  assert rc == 1, 'expected the status bump to survive:\n%s' % out
  refute(out, 'docs/notes.md', PASS_PREFIX)


def test_91_blinding_the_whole_red_helper_leaves_a_silent_green():
  """The fail-open the branch exists to prevent, measured rather than argued."""
  root = _claim_tree()
  with _blind('91', count=True) as frag:
    rc, out = run_fragment(frag, cwd=root)
  assert rc == 0, out
  refute(out, 'docs/notes.md', PASS_PREFIX)


def test_91_a_bare_orchestrator_comment_legitimises_an_id_with_no_check_behind_it():
  """The weaker declaration source, measured rather than described.

  The fragment's header calls this edge acceptable because the block it reads
  stays readable by hand. The grammar is wider than the block: ANY comment line in
  scripts/validate-dod.sh that opens with a bracketed id declares that id, so one
  appended comment turns a dead reference green with nothing executable behind it.
  This row exists so the edge is a measurement in the suite rather than a sentence
  in a header, and so a later narrowing of the grammar reds here and gets noticed."""
  root = _claim_tree()
  orchestrator = root / 'scripts' / 'validate-dod.sh'
  orchestrator.write_text(orchestrator.read_text(encoding='utf-8')
                          + '\n# [%s] a comment that declares nothing executable\n'
                          % '999', encoding='utf-8')
  ci_cov.git(root, 'add', '-A')
  rc, out = run_check('91', cwd=root)
  assert rc == 0 and PASS_PREFIX in out, (
      'the appended comment no longer legitimises the id, so the grammar was '
      'narrowed and this row is stale:\n%s' % out)


def test_91_the_only_ids_resting_on_orchestrator_prose_are_the_two_by_design():
  """The property that keeps the edge above harmless, asserted against the tree.

  Computed here with a second reading of the two grammars rather than by parsing
  the fragment's own output, the same second-opinion shape
  scripts/test_ci_suite_coverage.py uses at its tracked_entrypoints. Checks [0]
  and [0b] cannot live in a fragment and are declared there on purpose. Every
  other id the orchestrator's comment grammar yields must also have a printed
  header behind it, and this reds the moment one does not."""
  frag, orch = declared_id_sets()
  assert orch - frag == {'0', '0b'}, (
      'ids %s resolve out of orchestrator prose with no fragment header behind '
      'them' % sorted(orch - frag - {'0', '0b'}))


# --- check [93], declared versus used -----------------------------------------

def test_93_the_live_prompt_floor_reds_before_any_use_is_judged():
  with tampered('93', ('TD_PROMPT_FLOOR=15', 'TD_PROMPT_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'against floors of 9999 and 15',
             'a resolver over nothing measures nothing')


def test_93_the_live_file_floor_reds_on_its_own_message():
  with tampered('93', ('TD_FILE_FLOOR=15', 'TD_FILE_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'against floors of 15 and 9999',
             'the anchor grammar or the pathspec stopped matching')


def test_93_the_declaration_floor_reds_on_its_own_message():
  with tampered('93', ('TD_DECL_FLOOR=100', 'TD_DECL_FLOOR=99999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'against floors of 99999 and 350',
             'this check would red on correct prompts')


def test_93_the_token_use_floor_reds_on_its_own_message():
  with tampered('93', ('TD_USE_FLOOR=350', 'TD_USE_FLOOR=99999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'against floors of 100 and 99999')


def test_93_a_missing_interpreter_reds_rather_than_skipping():
  rc, out = run_check_without_python('93')
  expect_red(rc, out, '[93] needs python3 to parse prompt regions, '
             'and it is not on PATH')


def test_93_a_failed_stderr_capture_reds_rather_than_running_blind():
  with tampered('93', ('td_err=$(mktemp 2>/dev/null)', 'td_err=$(false)')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'could not create the stderr capture file, '
             'so the token scan never ran')


def test_93_an_undeclared_token_reds_and_no_pass_line_prints_beside_it():
  root = _replay('td-scratch-', {'prompt.md': PROMPT})
  rc, out = run_check_replay('93', 'TD_REPLAY_ROOT', root)
  expect_red(rc, out, 'prompt.md:8 uses {{beta}}, which the INPUTS list at line 5 '
             'does not declare')


def test_93_blinding_the_whole_red_helper_leaves_a_silent_green():
  root = _replay('td-scratch-', {'prompt.md': PROMPT})
  with _blind('93', count=True) as frag:
    rc, out = run_replay(frag, 'TD_REPLAY_ROOT', root)
  assert rc == 0, out
  refute(out, '{{beta}}', PASS_PREFIX)


# --- check [94], section exists ------------------------------------------------

def test_94_the_heading_floor_reds_before_any_site_is_judged():
  with tampered('94', ('SE_HEADING_FLOOR=12', 'SE_HEADING_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'heading(s) against a floor of 9999',
             'every instruction would resolve to nothing')


def test_94_the_live_file_floor_reds_on_its_own_message():
  with tampered('94', ('SE_FILE_FLOOR=100', 'SE_FILE_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'live file(s) against a floor of 9999',
             'a scan over nothing measures nothing')


def test_94_the_live_mention_floor_reds_on_its_own_message():
  with tampered('94', ('SE_MENTION_FLOOR=4', 'SE_MENTION_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'mention(s) of a policed section name against a floor of 9999',
             'this check would go quiet without going green for a reason')


def test_94_a_policed_name_that_becomes_a_heading_kills_the_premise_and_says_so():
  """The branch no healthy tree can reach. Once the policed name IS a heading,
  every per-site sentence the scan prints is false, so the premise dying has to
  stop the accusations rather than decorate them."""
  with tampered('94', ("POLICED = ('%s',)" % RETIRED_LABEL,
                       "POLICED = ('Daily Updates',)")) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, "now carries a heading named 'Daily Updates'",
             'every site it reports would be a false accusation')
  refute(out, 'instructs a writer to use a work-doc section named')


def test_94_a_missing_interpreter_reds_rather_than_skipping():
  rc, out = run_check_without_python('94')
  expect_red(rc, out, "[94] needs python3 to parse the template's headings, "
             'and it is not on PATH')


def test_94_a_failed_stderr_capture_reds_rather_than_running_blind():
  with tampered('94', ('se_err=$(mktemp 2>/dev/null)', 'se_err=$(false)')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'could not create the stderr capture file, '
             'so the section scan never ran')


def test_94_a_name_that_wraps_mid_phrase_is_cited_at_the_paragraph_head():
  """The citation fallback, and the only branch in this file that is a defect
  rather than a guard.

  paragraphs() joins the physical lines of a block with a space, so a paragraph
  still matches when the policed name wraps at its own internal space. cite()
  then hunts the WHOLE name on each physical line, finds it on none of them, and
  falls back to the first line of the paragraph. The fragment header promises
  that the paragraph decides and the physical line carrying the name is what gets
  printed. Here the second half of that promise does not hold: the site is
  reported, so the check stays fail-closed, but the line number sends a reader to
  a line the name is not on."""
  head, tail = RETIRED_LABEL.split(chr(32))
  body = ('notes\n\nA preamble sentence that opens the paragraph.\nA second '
          'preamble line.\nAppend one entry to the %s\n%s for each landed task.\n'
          % (head, tail))
  assert head in body.split('\n')[4], 'this row no longer wraps where it says it does'
  rc, out = run_check_replay('94', 'SE_REPLAY_ROOT', _replay('se-wrap-',
                                                             {'doc.md': body}))
  expect_red(rc, out, "doc.md:3 instructs a writer to use a work-doc section "
             "named '%s'" % RETIRED_LABEL)


# --- check [95], literal-absent claims -----------------------------------------

def _stale_claim_scope():
  """Two files carrying one phrase, and a paragraph calling that phrase unbound.

  The claim wording is assembled at runtime for the reason the module docstring
  gives, so this source file never carries the grammar check [95] hunts."""
  body = 'notes\n\nThe %s%s%s row is %s in this tree.\n' % (TICK, MARKER_PHRASE, TICK,
                                                            PINNING_CLAIM)
  return _replay('la-scratch-', {'claim.md': body,
                                 'other.md': 'notes\n\nSomewhere: %s%s%s\n'
                                             % (TICK, MARKER_PHRASE, TICK)})


def test_95_the_live_file_floor_reds_before_any_claim_is_judged():
  with tampered('95', ('LA_FILE_FLOOR=100', 'LA_FILE_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'live file(s) against a floor of 9999',
             'a scan over nothing measures nothing')


def test_95_the_claim_vocabulary_floor_reds_on_its_own_message():
  with tampered('95', ('LA_CLAIM_FLOOR=5', 'LA_CLAIM_FLOOR=9999')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'paragraph(s) carrying a pinning claim against a floor of 9999',
             'the claim vocabulary stopped matching')


def test_95_a_missing_interpreter_reds_rather_than_skipping():
  rc, out = run_check_without_python('95')
  expect_red(rc, out, '[95] needs python3 to normalise paragraphs, '
             'and it is not on PATH')


def test_95_a_failed_stderr_capture_reds_rather_than_running_blind():
  with tampered('95', ('la_err=$(mktemp 2>/dev/null)', 'la_err=$(false)')) as frag:
    rc, out = run_fragment(frag)
  expect_red(rc, out, 'could not create the stderr capture file, '
             'so the claim scan never ran')


def test_95_a_stale_claim_reds_and_no_pass_line_prints_beside_it():
  rc, out = run_check_replay('95', 'LA_REPLAY_ROOT', _stale_claim_scope())
  expect_red(rc, out, "claim.md:3 says '%s' is" % MARKER_PHRASE,
             'is present in 1 other live file(s): other.md')


def test_95_a_claim_that_wraps_mid_phrase_is_cited_at_the_paragraph_head():
  """The same citation fallback as the row above, in the neighbouring check.

  cite() has the identical shape here and the needle is the claim phrase rather
  than a section name, so a claim that wraps at its own internal space is cited
  at the head of its paragraph instead of at the line it sits on. This check
  adopts the promise rather than restating it: its header says the citation
  "stays a physical line, for the reason [94] gives". So the same gap sits behind
  both, and both keep the half of the promise that fail-closed behaviour rests on
  while dropping the half a reader uses."""
  head, tail = PINNING_CLAIM.split(chr(32))
  body = ('notes\n\nA preamble sentence that opens the paragraph.\nA second '
          'preamble line.\nThe %s%s%s row is %s\n%s in this tree.\n'
          % (TICK, MARKER_PHRASE, TICK, head, tail))
  assert head in body.split('\n')[4], 'this row no longer wraps where it says it does'
  scope = _replay('la-wrap-', {'claim.md': body,
                               'other.md': 'notes\n\nSomewhere: %s%s%s\n'
                                           % (TICK, MARKER_PHRASE, TICK)})
  rc, out = run_check_replay('95', 'LA_REPLAY_ROOT', scope)
  expect_red(rc, out, "claim.md:3 says '%s' is" % MARKER_PHRASE)


def test_95_two_overlapping_claim_spellings_red_one_sentence_twice():
  """One stale claim, two reds, and the second one is not even grammatical.

  subjects() walks the claim vocabulary an entry at a time, and the shorter
  spelling is a substring of the longer one, so a sentence carrying the longer
  form pairs with the quoted phrase twice. Both pairs print and both bump the
  status, so one defect costs two. It over-reports rather than under-reports and
  is fail-closed on that account, but a reader counting reds counts this defect
  twice and the second line reads 'is is'."""
  rc, out = run_check_replay('95', 'LA_REPLAY_ROOT', _stale_claim_scope())
  assert rc == 2, 'expected one sentence to red twice, got rc %d:\n%s' % (rc, out)
  expect(out, "says '%s' is %s" % (MARKER_PHRASE, PINNING_CLAIM),
         "says '%s' is is %s" % (MARKER_PHRASE, PINNING_CLAIM))


def test_95_blinding_the_whole_red_helper_leaves_a_silent_green():
  with _blind('95', count=True) as frag:
    rc, out = run_replay(frag, 'LA_REPLAY_ROOT', _stale_claim_scope())
  assert rc == 0, out
  refute(out, MARKER_PHRASE, PASS_PREFIX)


# --- check [97], every suite reachable from CI ---------------------------------

def test_97_a_workflow_grep_cannot_read_reds_on_its_own_message():
  """The one branch scripts/test_ci_suite_coverage.py leaves unreached, because
  the unreadable-file guard above it catches the obvious spelling. A directory at
  the workflow path passes the readability test and then makes grep exit 2."""
  root = ci_cov.scratch()
  target = root / '.github' / 'workflows' / 'ci.yml'
  target.unlink()
  target.mkdir()
  rc, out = run_check('97', cwd=root)
  expect_red(rc, out, '[97] grep exited 2 reading .github/workflows/ci.yml',
             'the suite scan never ran')


def test_97_blinding_the_whole_red_helper_leaves_a_silent_green():
  root = ci_cov.scratch()
  write(root, 'scripts/test_orphan.py', '#!/usr/bin/env python3\nprint("ok")\n')
  ci_cov.git(root, 'add', '-A')
  with _blind('97', count=True) as frag:
    rc, out = run_fragment(frag, cwd=root)
  assert rc == 0, out
  refute(out, 'test_orphan.py', PASS_PREFIX)

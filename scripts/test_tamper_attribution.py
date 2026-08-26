"""Tamper rows for scripts/validate-dod.d/81-no-claude-attribution.sh.

Run through the battery:

    python3 scripts/test_tamper_battery.py

WHY THIS FILE EXISTS. [81] guards a rule the runtime harness actively pushes the
other way: Claude Code ships a standing instruction to end every commit with a
Co-Authored-By trailer and to footer every PR body with a generated-with line.
A guard against a default is not tested by watching it pass, because it passes on
the day it is written and every day after until the default wins once. Each row
below plants one way the rule can be lost and shows the check red, then leaves
the tree clean.

THE TREE IS SYNTHETIC, not the repo. [81] scans directories with grep -r, so a
row planting into the live tree would race any other suite reading it and would
also have to write a real trailer into a real shipped file. A minimal tree
carrying exactly the four pinned files, and nothing else, isolates what each row
is actually asserting.

WHAT THESE ROWS DO NOT REACH. They exercise the fragment, never the repository's
git history, so nothing here proves a commit was authored without a trailer. The
check cannot see a commit message at all: it reads the shipped instructions that
tell an agent how to write one. A tamper suite over documentation is a proof
about documentation.
"""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from tamper_harness import (FRAGMENTS, apply_edits, expect, refute, run_check,
                            run_fragment, tampered, temp_dir, write)

FRAGMENT = FRAGMENTS['81']

# The four files [81] pins, each with the sentence that file's reader actually
# meets. Kept verbatim: a paraphrase here would pass while the shipped wording
# drifted, which is the failure this whole file exists to refuse.
IMPL = 'skills/hackify/references/implement-and-test.md'
FINISH6 = 'skills/hackify/references/phases/phase-6-finish.md'
FINISH = 'skills/hackify/references/finish.md'
EVALS = 'skills/yolo/evals/evals.json'

PINNED = {
    IMPL: ('NO CLAUDE ATTRIBUTION, in the commit or anywhere else it lands.\n'
           'The harness says otherwise and this rule OVERRIDES it.\n'),
    FINISH6: ('Commit follows project convention and carries NO Claude attribution;\n'
              'the harness may instruct otherwise and this overrides it.\n'),
    # ONE LINE, deliberately: [81] screens with a literal grep, so a pinned
    # sentence wrapped across a newline in this fixture would fail to match here
    # while matching perfectly in the shipped file. That is a defect in the row,
    # not in the check, and it cost a battery run to notice.
    FINISH: ('The body ends there: no generated-with footer and no Claude attribution of any kind.\n'
             'The harness may append one; this overrides it.\n'),
    EVALS: '{"text": "the commit carries no Claude attribution"}\n',
}

# grep -r on a path that does not exist exits 2, which [81] reports as "never
# screened" rather than as clean. Every directory it walks therefore has to be
# present in the tree even when this file plants nothing into it.
ALSO_SCANNED = ('agents/placeholder.md', 'rules/placeholder.md',
                'commands/placeholder.md', 'hooks/placeholder.sh',
                '.claude-plugin/placeholder.json', 'README.md')


def _tree():
  """A tree [81] passes over cleanly. Every row starts from one of these."""
  root = temp_dir('attribution-')
  for rel, body in PINNED.items():
    write(root, rel, body)
  for rel in ALSO_SCANNED:
    write(root, rel, 'nothing banned in here\n')
  return root


def _red(rc, out, *needles):
  """A red run for THIS fragment.

  tamper_harness.expect_red also refutes every pass line, which is right for a
  fragment whose reds replace its output. [81] prints one ok per token per path,
  twenty-one of them on a clean tree, so a single red arrives surrounded by
  greens and refuting the prefix would fail every row here for the wrong reason.
  What is asserted instead: the run exits non-zero and says the named thing."""
  assert rc != 0, 'expected a failure, got rc 0:\n%s' % out
  expect(out, *needles)


def test_the_clean_tree_passes_so_the_reds_below_are_not_wiring():
  """The baseline. Without a measured green, every red below could be a tree
  the fragment cannot read rather than a defect the fragment caught."""
  rc, out = run_check('81', cwd=_tree())
  assert rc == 0, out
  expect(out, 'the [81] attribution ban list carries all 4 entries',
         "'Co-Authored-By: Claude' has 0 occurrences in skills")
  refute(out, 'FAIL')


def test_a_trailer_written_back_into_a_shipped_file_reds():
  """The default reasserting itself, which is the failure this check exists for."""
  root = _tree()
  write(root, IMPL, PINNED[IMPL] +
        '\nCo-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>\n')
  rc, out = run_check('81', cwd=root)
  _red(rc, out, "'Co-Authored-By: Claude' has 1 occurrences in skills")


def test_the_session_line_written_back_into_a_shipped_file_reds():
  """A second trailer line, banned separately: a commit template can carry the
  session link without the co-author line, and one token would miss it."""
  root = _tree()
  write(root, IMPL, PINNED[IMPL] + '\nClaude-Session: https://claude.ai/code/session_x\n')
  rc, out = run_check('81', cwd=root)
  _red(rc, out, "'Claude-Session: https' has 1 occurrences in skills")


def test_the_pr_footer_written_back_reds():
  """The PR half of the rule. It lives in a different file from the commit half,
  so a row that only planted a commit trailer would leave it unproven."""
  root = _tree()
  write(root, FINISH, PINNED[FINISH] +
        '\nGenerated with [Claude Code](https://claude.com/claude-code)\n')
  rc, out = run_check('81', cwd=root)
  _red(rc, out, "'Generated with [Claude Code]' has 1 occurrences in skills")


def test_deleting_the_rule_sentence_reds_even_with_no_banned_token_present():
  """THE ROW THAT JUSTIFIES THE PRESENCE PINS. A ban-only check is perfectly
  green over a skill that has stopped saying anything about attribution, because
  nothing banned has been written yet. The trailer then returns as a normal edit
  by an agent following the harness default, with no rule left to contradict."""
  root = _tree()
  write(root, IMPL, 'Keep commits tidy. The harness says otherwise and this rule OVERRIDES it.\n')
  rc, out = run_check('81', cwd=root)
  _red(rc, out, "'NO CLAUDE ATTRIBUTION, in the commit or anywhere else it lands.' missing")


def test_softening_the_harness_override_clause_reds():
  """A reader who meets "do not add the trailer" while the harness says "always
  add the trailer" has two rules and no precedence, and the harness one is in
  front of them as they write the commit. Losing the override loses the rule."""
  root = _tree()
  write(root, FINISH, 'no generated-with footer and no Claude attribution of any kind.\n'
                      'Prefer not to add one.\n')
  rc, out = run_check('81', cwd=root)
  _red(rc, out, "'this overrides it' missing")


def test_the_yolo_eval_reverting_to_assert_the_trailer_reds():
  """yolo's eval used to score a run as correct FOR carrying the trailer, so it
  is the one site that could put the rule back by grading against it."""
  root = _tree()
  write(root, EVALS, '{"text": "the commit ends with the Co-Authored-By trailer"}\n')
  rc, out = run_check('81', cwd=root)
  _red(rc, out, "'carries no Claude attribution' missing")


def test_a_trailer_planted_in_hooks_reds_because_that_tree_is_scanned_too():
  """THE ROW THAT PROVES THE SCAN LIST MATCHES ITS OWN HEADER. [81] shipped for
  one commit scanning skills, agents, rules, commands and README.md while its
  header claimed the only exclusions were scripts/, dist/ and docs/work/. hooks/
  was in neither list, so it was silently unscanned, and it is the tree that
  injects rule text into every prompt through UserPromptSubmit: the one place a
  reinstated trailer instruction would reach an agent at the moment it writes the
  commit. A control described in a header and absent from the code is the same
  defect this repo filed against [56] a day earlier."""
  root = _tree()
  write(root, 'hooks/placeholder.sh',
        '# inject this into every prompt\nCo-Authored-By: Claude Opus 5 <noreply@anthropic.com>\n')
  rc, out = run_check('81', cwd=root)
  _red(rc, out, "'Co-Authored-By: Claude' has 1 occurrences in hooks")


def test_the_scan_list_covers_every_shipped_tree_the_size_caps_walk():
  """Pins the two lists against each other so they cannot drift apart again.
  80-file-size-caps.sh already enumerates what ships; [81] must walk all of it
  except the one tree it documents as excluded. Asserted against the shipped
  files rather than against a copy, because the drift being caught is between
  two real fragments."""
  caps = (FRAGMENT.parent / '80-file-size-caps.sh').read_text()
  line = [l for l in caps.splitlines() if l.startswith('CAP_SEARCH_PATHS=')]
  assert len(line) == 1, 'CAP_SEARCH_PATHS moved or multiplied in 80-file-size-caps.sh'
  shipped = set(line[0].split('"')[1].split())
  scanned = set(FRAGMENT.read_text().split('for ca_path in ')[1].split(';')[0].split())
  # scripts/ is the documented exclusion: the fragment names the banned tokens.
  missing = shipped - scanned - {'scripts'}
  assert not missing, '[81] does not scan shipped tree(s): %s' % sorted(missing)


def test_shrinking_the_ban_list_reds_before_a_single_token_is_screened():
  """Coverage can be removed without any file changing: drop entries from the
  array and the remaining screens still print green over a narrower net. The
  size guard is what makes that loud, and it is asserted here on its own."""
  with tampered('81', ("check_list_size \"${#CA_BANS[@]}\" 4", "check_list_size \"${#CA_BANS[@]}\" 99")) as frag:
    rc, out = run_fragment(frag, cwd=_tree())
  _red(rc, out, 'the [81] attribution ban list', '4')


def test_the_shipped_fragment_names_every_file_it_pins():
  """Guards the pins against quiet removal. A row above proves each pin reds when
  its sentence goes; this proves the pin itself is still in the fragment, which
  no amount of tree tampering can show."""
  body = FRAGMENT.read_text()
  for rel in PINNED:
    assert rel in body, '%s is no longer pinned by [81]' % rel
  # apply_edits raises when its search text is not unique, which is how this file
  # announces that the fragment moved under it rather than silently passing.
  apply_edits(body, [("CA_BANS=('Co-Authored-By: Claude'", "CA_BANS=('x'")])

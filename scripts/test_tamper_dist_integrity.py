#!/usr/bin/env python3
"""Tamper rows for check [56], dist integrity. Imported, no main.

Run by scripts/test_tamper_battery.py, the shape check [97] blesses in its own
header: a suite reached by import from a file CI names is wired.

WHAT THIS FILE COVERS. Every branch of scripts/validate-dod.d/56-dist-integrity.sh,
the only check in the validator that opens a shipped file. It landed with none: a
sweep for its id, its filename and its own variable prefixes across scripts/ and
.github/ returned the fragment and the orchestrator that sources it, and nothing
else. It is also the check whose SKIP branch is half the reason it was written,
because a tree with no dist/<runtime>/ built is what every clone is, and that state
printed ALL CHECKS PASSED for the whole life of this validator with nothing having
compared a shipped byte to anything.

WHY THE TREES HERE ARE BUILT AND NOT COPIED. The fragment resolves three things out
of the working directory: the manifest arrays it sources from the sync helper, the
destination plan it takes from `sync-runtimes.sh --dry-run`, and the shipped bytes
under dist/. Copying this repository and running the real sync is ~800 writes per
row, and it still cannot reach the branches that need an EIGHTH exclusion or a
planner that dies, because neither is a state the real scripts can be asked for. A
tree built to order reaches all of them in 0.15s.

AND THE COUPLING THAT BUYS IS PAID AT THE TOP OF THE FILE. The first row reads the
live plan, the live manifest and the fragment's own two pinned numbers, and asserts
the fixtures below are built to that same shape. Move a pin or change the planner's
line format and that row reds, rather than every row under it going quietly green
against a shape the repository stopped having.

WHAT A ROW IS. One branch, planted on a tree that exists for that row alone, with
the EXPECTED FAILURE MESSAGE asserted rather than the exit status, and the pass
prefix refuted so a red printed beside a green cannot read as a red. Where a branch
is one of several that could have spoken, the others are refuted too, since a
fragment reporting a consequence instead of a cause sends the reader to the wrong
file. Nothing writes into the repository. The one plant that is INVISIBLE on a
green run, a source leaving the manifest, carries a control measuring what the pin
is worth, because a floor cannot see that shape: a floor only ever looks down.
"""

import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tamper_harness import (PASS_PREFIX, REPO_ROOT, apply_edits, expect, refute,
                            run_fragment as run_shell_fragment, temp_dir, write)

FRAGMENT = 'scripts/validate-dod.d/56-dist-integrity.sh'
HELPERS = 'scripts/sync-runtimes.d/00-helpers.sh'
PLANNER = 'scripts/sync-runtimes.sh'
PLAN_FILE = 'scripts/zzq-plan.txt'

# The plan line the fragment filters on, and the marker it splits a destination out
# of. Transcribed rather than read, the rule scripts/test_tamper_mirror_tails.py
# states at PARENT_SIDE_MARKER: a fixture built from the text it tests moves with a
# tamper on that text and proves nothing.
PLAN_PREFIX = '[dry-run] WOULD WRITE: '

# The two invocations the fragment makes to discover its inputs, transcribed for
# the same reason. The first row runs both against the REAL tree and re-derives the
# pairing from their output, which is the only comparison here that the fragment's
# own arithmetic is not standing behind.
LIVE_PLAN = 'bash %s --dry-run' % PLANNER
LIVE_MANIFEST = ('set +u; . %s >/dev/null 2>&1; '
                 'printf "%%s\\n" "${MIRROR_SOURCES[@]}" "${CLAUDE_CODE_EXTRA[@]}"'
                 % HELPERS)

# The fragment's two bounds, as the whole lines they occupy, so the first row can
# assert they are still written that way and every fixture below can be sized off
# them rather than off a number copied out of a pass line.
FLOOR_PIN = 'DI_PAIR_FLOOR=700'
GENERATED_PIN = 'DI_GENERATED_EXPECT=7'
DI_PAIR_FLOOR = 700
DI_GENERATED_EXPECT = 7

RUNTIMES = ('claude-code', 'codex-cli', 'codex-app', 'gemini-cli', 'opencode',
            'cursor', 'copilot-cli')

# One heredoc destination per runtime, which is the live exclusion set: six
# MANIFEST.md and gemini's GEMINI.md. Seven runtimes and a pin of seven is the
# arithmetic the real tree has, not a coincidence this fixture arranged, and the
# first row asserts the live set is still that size.
GENERATED_NAMES = {'gemini-cli': 'GEMINI.md'}

# SIZED OFF THE FLOOR, NEVER BESIDE IT. A fixture built to a number typed here
# stops testing the branch the day the floor moves, and it stops silently. Ten
# sources of headroom, so the row that drops one source from the manifest loses its
# seven destinations and still lands nowhere near the floor: that row is about the
# pin, and a fixture that let the floor speak instead would prove the wrong thing.
SOURCE_COUNT = DI_PAIR_FLOOR // len(RUNTIMES) + 10
SOURCES = (['skills/hackify/references/zzq-%03d.md' % n
            for n in range(SOURCE_COUNT - 1)] + ['agents/zzq-extra.md'])
PAIR_TOTAL = SOURCE_COUNT * len(RUNTIMES)
DEST_TOTAL = PAIR_TOTAL + len(RUNTIMES)

# Sources are deduplicated before hashing and every destination is hashed, which is
# the count the fragment fails closed on.
HASH_TOTAL = SOURCE_COUNT + PAIR_TOTAL


def _bash(script, cwd=REPO_ROOT):
  """One bash -c, argv as a list, never a string assembled from a file's contents."""
  done = subprocess.run(['/bin/bash', '-c', script], cwd=str(cwd),
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
  return done.returncode, done.stdout.decode('utf-8', 'replace')


def _generated(runtime):
  """The one destination this runtime writes from a heredoc, with no source."""
  return GENERATED_NAMES.get(runtime, 'MANIFEST.md')


def _plan_lines():
  """The destination plan in the planner's own format: every source into every
  runtime, that runtime's heredoc file, then the summary line the real script
  prints, which is here so the fragment's WOULD WRITE filter has something to
  reject."""
  lines = []
  for runtime in RUNTIMES:
    for source in SOURCES:
      lines.append('%sdist/%s/%s' % (PLAN_PREFIX, runtime, source))
    lines.append('%sdist/%s/%s' % (PLAN_PREFIX, runtime, _generated(runtime)))
  return lines + ['', '[dry-run] %d runtimes, %d files total'
                  % (len(RUNTIMES), DEST_TOTAL)]


def _helper_body(declared):
  """The manifest, split across the two arrays the fragment concatenates. Both are
  filled, so a row is never testing half the discovery."""
  extra = [p for p in declared if p.startswith('agents/')]
  mirror = [p for p in declared if p not in extra]
  return ('MIRROR_SOURCES=(\n%s)\nCLAUDE_CODE_EXTRA=(\n%s)\n'
          % (''.join('  "%s"\n' % p for p in mirror),
             ''.join('  "%s"\n' % p for p in extra)))


def _tree(manifest=None):
  """A tree the fragment resolves all three of its inputs out of.

  `manifest` is what the helper DECLARES, defaulting to every source on disk.
  Passing a subset is how a row ships a file that the comparison can no longer
  see, which is the one defect shape neither bound below the pin can reach."""
  root = temp_dir('dist-integrity-')
  write(root, HELPERS, _helper_body(SOURCES if manifest is None else manifest))
  write(root, PLAN_FILE, '\n'.join(_plan_lines()) + '\n')
  write(root, PLANNER, '#!/usr/bin/env bash\ncat %s\n' % PLAN_FILE)
  for source in SOURCES:
    body = 'canonical body of %s\n' % source
    write(root, source, body)
    for runtime in RUNTIMES:
      write(root, 'dist/%s/%s' % (runtime, source), body)
  for runtime in RUNTIMES:
    write(root, 'dist/%s/%s' % (runtime, _generated(runtime)),
          'heredoc body for %s, no canonical source behind it\n' % runtime)
  return root


def _run(root):
  """Source the SHIPPED fragment against one tree. Returns (rc, text)."""
  return run_shell_fragment(REPO_ROOT / FRAGMENT, cwd=root)


def _tampered(*edits):
  """An edited COPY of the fragment. tamper_harness.tampered() is keyed on a
  FRAGMENTS map this one is not in, so the copy is made here under the same rule:
  the shipped file is read and never written."""
  target = temp_dir('tamper-56-') / '56-dist-integrity.sh'
  target.write_text(
      apply_edits((REPO_ROOT / FRAGMENT).read_text(encoding='utf-8'), edits),
      encoding='utf-8')
  return target


# --- what keeps a built fixture honest ----------------------------------------

def test_the_live_plan_and_the_two_pins_are_the_shape_the_fixtures_are_built_to():
  """Three assertions about the REAL repository, none about a fixture. The fragment
  still carries both bounds as written; the real planner still emits the line format
  every tree here copies; and the live tree clears the floor and lands exactly on
  the exclusion pin when the pairing is re-derived HERE rather than read off the
  fragment's own pass line. Any of the three failing means the rows below are
  measuring a shape this repository no longer has."""
  expect((REPO_ROOT / FRAGMENT).read_text(encoding='utf-8'), FLOOR_PIN, GENERATED_PIN)
  rc, plan = _bash(LIVE_PLAN)
  assert rc == 0, plan
  dests = [line.split(PLAN_PREFIX, 1)[1]
           for line in plan.splitlines() if PLAN_PREFIX in line]
  declared = set(filter(None, _bash(LIVE_MANIFEST)[1].splitlines()))
  pairs = [d for d in dests if d.split('/', 2)[2] in declared]
  assert len(pairs) >= DI_PAIR_FLOOR, (len(dests), len(pairs))
  assert len(dests) - len(pairs) == DI_GENERATED_EXPECT, (len(dests), len(pairs))


def test_the_shipped_fragment_reaches_a_verdict_on_this_repository():
  """The fragment against the real tree, which no built fixture stands in for. What
  is asserted is the DISCOVERY and never the shipped bytes: all three discovery reds
  are refuted, since each one means the check spoke about dist/ having read nothing,
  and a clone with no tree built owes the skip and exit 0. Whether a built dist/ is
  currently fresh is [56]'s verdict to give inside the validator, not this row's."""
  rc, out = _run(REPO_ROOT)
  refute(out, 'the discovery collapsed', 'this check pins', '--dry-run exited')
  if not [rt for rt in RUNTIMES if (REPO_ROOT / 'dist' / rt).is_dir()]:
    expect(out, 'skip no dist/<runtime>/ tree is built')
    assert rc == 0, out


def test_a_built_tree_that_matches_its_sources_is_green_and_says_what_it_compared():
  """The green every red below is measured against. Not a bare exit 0, which this
  fragment has four ways to reach without comparing anything, and not the word ok
  either: both numbers on the pass line are asserted, so a run that quietly compared
  a subset reds here rather than reading as a clean tree."""
  rc, out = _run(_tree())
  assert rc == 0, out
  expect(out, 'ok   all %d file(s) the sync copies into %d built'
         % (PAIR_TOTAL, len(RUNTIMES)),
         '(%d planned file(s) are written from a heredoc' % DI_GENERATED_EXPECT)


# --- the shipped bytes, which nothing opened before this fragment --------------

def test_a_shipped_file_that_differs_from_its_canonical_source_reds():
  """The defect the check was written for, measured on the tree that shipped it: 68
  of 791 files stale, one of them 3,114 bytes behind a contract the repository had
  already stopped stating, while a runtime installed the old text. One byte is
  enough, and the red names the pair so a reader knows which file to look at."""
  root = _tree()
  drifted = 'dist/%s/%s' % (RUNTIMES[5], SOURCES[3])
  (root / drifted).write_text('hand-edited in the shipped tree\n', encoding='utf-8')
  rc, out = _run(root)
  assert rc == 1, out
  expect(out, 'FAIL dist/ ships 1 file(s) that differ',
         'out of %d compared' % PAIR_TOTAL,
         '- %s (differs from %s)' % (drifted, SOURCES[3]))
  refute(out, PASS_PREFIX)


def test_a_planned_file_the_sync_never_wrote_reds_as_missing_and_only_as_missing():
  """The other half of that red, and a regression the fragment already carries: a
  destination that is not on disk used to stay in the set the comparison read, so
  one deleted file was counted once as missing and again as unreadable and printed
  as two defects. The drift count is asserted at zero for exactly that reason."""
  root = _tree()
  gone = 'dist/%s/%s' % (RUNTIMES[4], SOURCES[5])
  (root / gone).unlink()
  rc, out = _run(root)
  assert rc == 1, out
  expect(out, 'ships 0 file(s) that differ', 'and 1 the sync plans but never wrote',
         'out of %d compared' % (PAIR_TOTAL - 1),
         '- %s (planned from %s)' % (gone, SOURCES[5]))
  refute(out, PASS_PREFIX)


# --- the two bounds, which do different jobs and cannot cover for each other ----

def test_a_source_that_leaves_the_manifest_reds_against_the_pin_of_seven():
  """The quiet shift the pin exists for, and the one shape a floor cannot reach. A
  file the sync used to COPY drops out of the manifest: its seven destinations stay
  planned, stay shipped, and stop being compared. The pair count falls by seven and
  stays far clear of the floor, so the floor is refuted here as hard as the pin is
  expected. Without the pin this tree is a green over seven unchecked files."""
  rc, out = _run(_tree(manifest=SOURCES[1:]))
  assert rc == 1, out
  expect(out, 'FAIL [56] %d of the %d planned destination(s) have no canonical source'
         % (DI_GENERATED_EXPECT + len(RUNTIMES), DEST_TOTAL),
         'against the %d this check pins' % DI_GENERATED_EXPECT,
         '(%d pair(s) matched the manifest)' % (PAIR_TOTAL - len(RUNTIMES)))
  refute(out, PASS_PREFIX, 'the discovery collapsed')


def test_retuning_the_pin_ships_a_green_whose_own_parenthetical_is_the_defect():
  """The control, and what makes the row above mean what it says. Same tree, one
  edit: the pinned number moved to whatever the run observed, which is what a wave
  does when it reads that red as a number to bump. The check now exits 0 and its
  pass line says fourteen planned files are written from a heredoc and carry no
  canonical source. Seven of them are copies of files still sitting in the tree.
  That is the sentence the fragment abandons the comparison to avoid printing."""
  observed = DI_GENERATED_EXPECT + len(RUNTIMES)
  fragment = _tampered((GENERATED_PIN, 'DI_GENERATED_EXPECT=%d' % observed))
  rc, out = run_shell_fragment(fragment, cwd=_tree(manifest=SOURCES[1:]))
  assert rc == 0, out
  expect(out, 'ok   all %d file(s)' % (PAIR_TOTAL - len(RUNTIMES)),
         '(%d planned file(s) are written from a heredoc' % observed)


def test_a_collapsed_discovery_reds_at_the_floor_and_says_nothing_about_dist():
  """A helper that cannot be sourced, the first of the three collapses the fragment
  names. The arrays never get set, every pair falls out, and underneath sits a tree
  with one genuinely stale file in it. The floor speaks first and alone: the plant
  is real and this check must not report it, because a comparison over a collapsed
  set has nothing to say about the seven hundred files it never looked at."""
  root = _tree()
  (root / 'dist' / RUNTIMES[2] / SOURCES[9]).write_text('stale\n', encoding='utf-8')
  write(root, HELPERS, '#!/usr/bin/env bash\nexit 1\n')
  rc, out = _run(root)
  assert rc == 1, out
  expect(out, 'agreed on only 0 comparable file(s) against a floor of %d'
         % DI_PAIR_FLOOR,
         'the dry run planned %d destination(s)' % DEST_TOTAL,
         'the discovery collapsed rather than dist/ being clean')
  refute(out, PASS_PREFIX, 'that differ from the canonical source', 'this check pins')


# --- the two ways the check itself can fail to run -----------------------------

def test_a_planner_that_exits_non_zero_names_the_planner_and_not_the_shipped_trees():
  """This status used to be thrown away with the planner's stderr, so a sync script
  that died partway arrived here as a SHORT PLAN: fewer pairs, every one of them
  comparing perfectly well, and the first branch to notice was a hash-count red
  blaming dist/ for a defect in scripts/sync-runtimes.sh. The stderr line is
  asserted too, because on this path it is the only thing that says what broke."""
  root = _tree()
  write(root, PLANNER, "#!/usr/bin/env bash\n"
        "printf 'FATAL: missing per-runtime emitter\\n' >&2\nexit 3\n")
  rc, out = _run(root)
  assert rc == 1, out
  expect(out, 'FAIL [56] %s --dry-run exited 3' % PLANNER,
         'the defect is in the planner, not in the shipped trees',
         '- FATAL: missing per-runtime emitter')
  refute(out, PASS_PREFIX, 'the discovery collapsed', 'this check pins')


def test_a_hasher_that_could_not_read_every_file_refuses_to_score_the_rest():
  """A manifest naming a source the tree no longer carries. Every destination is
  present, so nothing is missing and nothing has drifted; the hasher just returns
  one line short, and a verdict over the rest would be a confident count of nothing.
  Both numbers are asserted, since a check reporting only that something went wrong
  leaves a reader unable to tell one unread file from four hundred."""
  root = _tree()
  (root / SOURCES[7]).unlink()
  rc, out = _run(root)
  assert rc == 1, out
  expect(out, 'FAIL [56] hashed %d file(s) of the %d the comparison needs'
         % (HASH_TOTAL - 1, HASH_TOTAL),
         'so part of dist/ was never read')
  refute(out, PASS_PREFIX)


# --- the branch a fresh clone takes, which is why the row count was zero --------

def test_an_unbuilt_dist_prints_a_skip_and_never_a_pass_line():
  """THE STATE EVERY CLONE IS IN. dist/ is gitignored wholesale, `*` plus
  `!.gitignore`, so the trees arrive absent and this check has to read that as
  neither clean nor broken. Both halves are asserted: the skip is PRINTED and
  carries the count it would have compared, and no pass line goes out beside it,
  because a green here is a verdict about files that are not on disk. Exit 0,
  because a clone that has never run the sync is not a defect in the clone."""
  root = _tree()
  shutil.rmtree(root / 'dist')
  rc, out = _run(root)
  assert rc == 0, out
  expect(out, 'skip no dist/<runtime>/ tree is built',
         '(%d would be compared)' % PAIR_TOTAL)
  refute(out, PASS_PREFIX, 'FAIL')

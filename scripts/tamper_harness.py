#!/usr/bin/env python3
"""Shared machinery for the tamper battery. Not a suite: it holds no test.

WHY IT IS ITS OWN MODULE. The battery is split across two suites that both need
the same runners, and the entrypoint imports both of them, so putting the runners
in the entrypoint would be a cycle. One shared module every part imports and
nothing imports back, the same shape scripts/claim_fixture_types.py argues for at
the top of its own file.

THE ONE RULE EVERY TAMPER HERE FOLLOWS. Nothing in this file writes into the
repository. A fragment is tampered by copying its text, editing the copy in a
temp file, and sourcing THAT. The working tree is read and never touched, so a
suite that dies halfway leaves nothing behind to restore and no checksum to
verify. The parent of this task had to restore a tracked file by hand today,
which is the incident this rule is written against.

THE SECOND RULE, AND IT IS WHAT KEEPS A TAMPER ROW HONEST. Every edit must apply
exactly once. An edit whose search text has drifted would silently apply zero
times, the fragment would run untampered, and the row would assert a failure
message that the untampered fragment happens to print anyway. So apply_edits
raises when the count is not one, and a drifted row breaks loudly instead of
going quietly green.
"""

import os
import shutil
import subprocess
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from replay_claim_checks import strip_ansi

REPO_ROOT = Path(__file__).resolve().parent.parent
HELPERS = REPO_ROOT / 'scripts' / 'validate-dod.d' / '00-helpers.sh'
FRAGMENT_DIR = REPO_ROOT / 'scripts' / 'validate-dod.d'
TEMPLATE = 'skills/hackify/references/work-doc-template.md'
CI_YML = '.github/workflows/ci.yml'

# The fragments this sprint built, keyed by the check id they declare. NO COUNT IS
# WRITTEN IN THIS SENTENCE ANY MORE: it read "the five fragments" while six were
# listed below it for as long as it took to add one, which is the stale claim the
# whole sprint is about, committed inside the sprint's own machinery.
FRAGMENTS = {
  '91': FRAGMENT_DIR / '91-claim-resolvers.sh',
  '93': FRAGMENT_DIR / '93-token-declarations.sh',
  '94': FRAGMENT_DIR / '94-section-exists.sh',
  '95': FRAGMENT_DIR / '95-literal-absent-claims.sh',
  '97': FRAGMENT_DIR / '97-test-suites-reachable.sh',
  '98': FRAGMENT_DIR / '98-work-doc-ledger-sync.sh',
}

# Every fragment routes its reds through a two-line helper: a `red` call that
# prints and a counter bump that decides the exit status. Blinding one and not
# the other is the tamper that produced the most interesting result of this
# sprint, so the pair is named here once rather than spelled out per row.
RED_CALL = 'red "  FAIL $*"'
COUNT_BUMP = 'FAILED=$((FAILED + 1))'

# The verdict prefix. Every pass line in the validator starts with it, so its
# ABSENCE is how a row proves no green printed beside a red.
PASS_PREFIX = '  ok   '

# Replay hooks, cleared from the environment on every run so a variable left
# over from one row cannot silently redirect the next one.
REPLAY_VARS = ('TD_REPLAY_ROOT', 'SE_REPLAY_ROOT', 'LA_REPLAY_ROOT')

_SCRATCH = []


def temp_dir(prefix):
  """A throwaway directory under the temp prefix the replay hooks accept."""
  root = Path(tempfile.mkdtemp(prefix=prefix))
  _SCRATCH.append(root)
  return root


def clean_scratch():
  """Remove every directory this module created. Called once, from main.

  ignore_errors so a cleanup hiccup cannot mask the verdict the run came for,
  the same call scripts/claim_fixtures.py makes at its own replay scope."""
  while _SCRATCH:
    shutil.rmtree(_SCRATCH.pop(), ignore_errors=True)


def write(root, rel, body):
  """Write one file under `root`, creating parents. Returns the path."""
  path = Path(root) / rel
  path.parent.mkdir(parents=True, exist_ok=True)
  path.write_text(body, encoding='utf-8')
  return path


def git(root, *args):
  """Run git in `root` with an argv LIST and no shell, ever."""
  subprocess.run(['git'] + list(args), cwd=str(root),
                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)


def declaration_tree(tracked=True):
  """A throwaway tree carrying the validator's own declaration sources.

  Check [91] reads scripts/validate-dod.d/*.sh and scripts/validate-dod.sh out of
  the WORKING DIRECTORY, so pointing it at a copy is how a row feeds it a claim
  the live tree does not carry. Copying the real fragments rather than writing
  fake ones keeps the declared-id set above the fragment's own floors, so a row
  reds on the claim it planted instead of on a floor.

  `tracked=False` stages nothing, which is how a row reaches the branch where git
  ls-files itself fails while every path the scan reads is still on disk."""
  root = temp_dir('claim-tree-')
  shutil.copytree(FRAGMENT_DIR, root / 'scripts' / 'validate-dod.d')
  shutil.copy2(REPO_ROOT / 'scripts' / 'validate-dod.sh', root / 'scripts')
  if tracked:
    git(root, 'init', '-q')
    git(root, 'add', '-A')
  return root


def apply_edits(text, edits):
  """Apply (old, new) literal replacements, each exactly once, or raise.

  See the second rule in the module docstring. A search text that no longer
  occurs, or occurs twice, means the row is no longer editing what it names."""
  for old, new in edits:
    found = text.count(old)
    if found != 1:
      raise AssertionError('the tamper text %r occurs %d times, not once; this row '
                           'is no longer editing what it names' % (old, found))
    text = text.replace(old, new)
  return text


@contextmanager
def tampered(key, *edits):
  """Yield a path to an edited COPY of one shipped fragment.

  The original is read and never written. The copy keeps the fragment's own
  basename so any message quoting a filename still reads correctly."""
  source = FRAGMENTS[key]
  root = temp_dir('tamper-%s-' % key)
  target = root / source.name
  target.write_text(apply_edits(source.read_text(encoding='utf-8'), edits),
                    encoding='utf-8')
  yield target


def _child_env(replay_var=None, replay_root=None, path=None):
  """A child environment with every replay hook cleared before anything is set.

  Clearing first is not tidiness. A variable left over from one row would quietly
  redirect the next one at a fixture it was never written against, and the row
  would still print a verdict."""
  env = dict(os.environ)
  for name in REPLAY_VARS:
    env.pop(name, None)
  if replay_var is not None:
    env[replay_var] = str(replay_root)
  if path is not None:
    env['PATH'] = path
  return env


def _run(fragment, cwd, env):
  """The one place a fragment is sourced. Every runner below funnels through it.

  `set -uo pipefail` is included because the orchestrator runs with it and the
  status handling inside these fragments is written against exactly that. Bash is
  invoked by absolute path so a row that empties PATH still starts a shell."""
  script = ('set -uo pipefail; FAILED=0; source %s; source %s; exit $FAILED'
            % (HELPERS, fragment))
  done = subprocess.run(['/bin/bash', '-c', script], cwd=str(cwd), env=env,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
  # The escapes come off for the reason scripts/replay_claim_checks.py states at
  # its own strip_ansi: a colourised line does not contain the plain text a
  # reader sees, and that function is imported rather than rewritten here.
  return done.returncode, strip_ansi(done.stdout.decode('utf-8', 'replace'))


def run_fragment(fragment, cwd=REPO_ROOT):
  """A tampered copy, scanning the tree at `cwd`. Returns (rc, text)."""
  return _run(fragment, cwd, _child_env())


def run_replay(fragment, replay_var, replay_root):
  """A tampered copy, pointed at a replay scope instead of at a tree."""
  return _run(fragment, REPO_ROOT, _child_env(replay_var, replay_root))


def run_check(key, cwd=REPO_ROOT):
  """The untampered shipped fragment, scanning the tree at `cwd`."""
  return _run(FRAGMENTS[key], cwd, _child_env())


def run_check_replay(key, replay_var, replay_root):
  """The untampered shipped fragment, pointed at a replay scope."""
  return _run(FRAGMENTS[key], REPO_ROOT, _child_env(replay_var, replay_root))


def run_check_without_python(key):
  """The untampered shipped fragment with no interpreter on PATH.

  Split out rather than passed as a flag because it is the only row shape that
  needs the environment broken, and a runner carrying five parameters to cover
  every shape breaks the three-parameter cap for one caller in ten."""
  return _run(FRAGMENTS[key], REPO_ROOT, _child_env(path='/nonexistent'))


def expect(out, *needles):
  """Every needle must be present, matched as a literal substring."""
  for needle in needles:
    assert needle in out, 'expected %r in the output:\n%s' % (needle, out)


def refute(out, *needles):
  """No needle may be present. Used for the no-green-beside-a-red rows."""
  for needle in needles:
    assert needle not in out, 'did not expect %r in the output:\n%s' % (needle, out)


def expect_red(rc, out, *needles):
  """A red run: non-zero status, the named message, and no pass line."""
  assert rc != 0, 'expected a failure, got rc 0:\n%s' % out
  expect(out, *needles)
  refute(out, PASS_PREFIX)


def canary():
  """A path that only a real command execution could bring into being.

  Every hostile string in the AC3 battery is built around one of these, so the
  proof that an argument was not executed is a measurement rather than the absence
  of a suspicious-looking line in a transcript.

  Placed under /tmp rather than under TMPDIR, and the reason is a length bound
  rather than taste. Check [95] takes a quoted phrase of at most 80 characters as a
  claim subject, so a canary built into that phrase has to leave room for the rest
  of the string. This session's TMPDIR alone is longer than the whole budget."""
  root = Path(tempfile.mkdtemp(prefix='hk-', dir='/tmp'))
  _SCRATCH.append(root)
  return root / 'x'


def hostile_values(mark):
  """The AC3 hostile set, built around a canary path so each one is provable.

  Traversal, an absolute path, three glob forms, command substitution in both
  spellings, and a pattern that is catastrophic to backtrack. Built at runtime
  rather than written as literals so this file does not itself become a corpus
  entry for the checks it is testing."""
  fire = 'touch %s' % mark
  return {
    'traversal': '../../etc/passwd',
    'absolute': '/etc/passwd',
    'glob_star': '*',
    'glob_question': '?',
    'glob_class': '[a-z]',
    'substitution': '$(%s)' % fire,
    'backtick': chr(96) + fire + chr(96),
    'redos': '(a+)+$',
  }

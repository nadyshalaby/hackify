#!/usr/bin/env python3
"""Tests for check [93]. python3 scripts/test_token_declarations.py

Every test here drives the REAL fragment, scripts/validate-dod.d/93-token-declarations.sh,
by sourcing it the way scripts/validate-dod.sh does. Nothing in this file
re-implements the scanner. A suite that tested a copy would go green while the
shipped check rotted, which is the defect class this whole sprint is about.

The suite is organised around the four ways this check could be worse than
useless rather than merely broken:

  1. IT MISSES THE FINDING IT WAS WRITTEN FOR. Corpus finding M3 was fixed at
     ab5cb74, so HEAD cannot score it. It is replayed from the blob pinned in
     scripts/claim_fixtures.json and the fragment must catch it there, at the
     right line, for the right reason.
  2. IT FABRICATES. A false positive on a live prompt is the same defect as a
     stale claim, pointed the other way, so the live tree must come back clean.
  3. IT GREENS WHILE MEASURING NOTHING. A replay that parses no prompt, a
     collapsed live scan, a scan that could not finish.
  4. ITS TEST HOOK BECOMES A FAIL-OPEN. TD_REPLAY_ROOT exists so this file can
     point the fragment at a fixture. An exported value that quietly replaced the
     repo-wide scan with one clean file would print green having read nothing, so
     every root that is not a fixture temp dir must be REFUSED, never ignored.
"""

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from claim_fixture_manifest import load_manifest
from claim_fixtures import replay_scope

REPO_ROOT = Path(__file__).resolve().parent.parent
FRAGMENT = 'scripts/validate-dod.d/93-token-declarations.sh'
ORCHESTRATOR = REPO_ROOT / 'scripts' / 'validate-dod.sh'
M3_PATH = 'agents/wave-implementer.md'

# The pass line, matched as a whole sentence rather than read positionally.
# A word-index read of this line can drift into a WRONG number when the
# wording changes and still land above a floor, which is a test that passes
# without measuring what it names. Anchored to the shape, a reworded line
# stops matching and the test reds instead.
OK_LINE = re.compile(r'ok\s+all (\d+) \{\{token\}\} use\(s\) across (\d+) '
                     r'prompt\(s\) in (\d+) live file\(s\)')

# A minimal prompt that conforms to the template contract. `{{gamma}}` is quoted
# inside input 2's description and declared by nothing, which is M3's exact shape
# reduced to its bones: a token that IS inside the INPUTS section and is still
# undeclared, because declaring is heading a numbered item, not being mentioned.
PROMPT = '''# heading

```
**ROLE**. You are a senior engineer with 15+ years of experience.

**INPUTS**.
1. `{{alpha}}`, the first thing.
2. `{{beta}}`, the second thing (e.g. `{{gamma}}`).

**OBJECTIVE**. One deliverable.

**METHOD**.
1. Read `{{alpha}}`.

**VERIFICATION**. Confirm it.

**OUTPUT**. Ten words.
```
'''


def run_fragment(replay_root=None):
    """Source the shipped fragment the way the orchestrator does. Returns (rc, text)."""
    script = ('FAILED=0; source scripts/validate-dod.d/00-helpers.sh; '
              'source %s; exit $FAILED' % FRAGMENT)
    env = dict(os.environ)
    env.pop('TD_REPLAY_ROOT', None)
    if replay_root is not None:
        env['TD_REPLAY_ROOT'] = str(replay_root)
    done = subprocess.run(['bash', '-c', script], cwd=str(REPO_ROOT), env=env,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return done.returncode, done.stdout.decode('utf-8', 'replace')


def scratch(body=PROMPT, name='prompt.md'):
    """A throwaway prompt tree under the temp prefix the replay hook accepts."""
    root = Path(tempfile.mkdtemp(prefix='td-check-'))
    (root / name).write_text(body, encoding='utf-8')
    return root


def _by_id(ident):
    for spec in load_manifest():
        if spec.ident == ident:
            return spec
    raise AssertionError('the fixture manifest carries no %s' % ident)


# --- 1. the finding it was written for ----------------------------------------

def test_m3_is_caught_in_its_pinned_replay_at_the_right_line():
    """The deliverable. The blob is pinned in scripts/claim_fixtures.json and its
    witnesses already prove the token sits on line 55 with the INPUTS list opening
    at 37. What this asserts is that the CHECK reads it that way too, and names
    the region and the declaration count it judged against, because a bare FAIL
    line is not evidence that it caught the finding for the right reason."""
    with replay_scope(_by_id('M3')) as scope:
        rc, out = run_fragment(scope.root)
    assert rc != 0, 'the replay printed no failure:\n%s' % out
    assert '%s:55 uses {{test_file_path}}' % M3_PATH in out, out
    assert 'the INPUTS list at line 37 does not declare' in out, out
    assert 'fenced block region lines 9..236' in out, out
    assert '12 declared:' in out, out


def test_the_m3_replay_would_have_read_as_clean_under_a_window_rule():
    """Why the declaration rule is structural rather than a window over the INPUTS
    section. The token sits INSIDE that section, on input 6 continuation line, so
    'is it somewhere below the INPUTS anchor' answers yes and misses the finding
    at any window width. Measured here rather than argued."""
    with replay_scope(_by_id('M3')) as scope:
        body = (scope.root / M3_PATH).read_text(encoding='utf-8')
    lines = body.split('\n')
    anchor = next(n for n, line in enumerate(lines) if line.startswith('**INPUTS**'))
    use = next(n for n, line in enumerate(lines) if '{{test_file_path}}' in line)
    assert anchor < use, 'the token would have been above the anchor, not inside the list'
    assert use - anchor < 20, 'the token sits %d lines below the anchor' % (use - anchor)


# --- 2. it does not fabricate -------------------------------------------------

def test_the_live_tree_comes_back_clean():
    rc, out = run_fragment()
    assert rc == 0, 'the live tree reported a failure:\n%s' % out
    assert '  ok   all ' in out and 'resolve against the ' in out, out


def test_the_live_scan_reads_every_prompt_and_not_a_handful():
    """A clean verdict over three prompts would also print green. The counts are
    asserted as floors, not equalities, so ordinary prompt churn never reddens
    this, and a collapse still does."""
    rc, out = run_fragment()
    found = OK_LINE.search(out)
    assert found is not None, 'the pass line did not match its own shape:\n%s' % out
    uses, prompts, files = (int(group) for group in found.groups())
    assert rc == 0, out
    assert uses >= 350 and prompts >= 15 and files >= 15, found.group(0)


def test_a_declared_token_used_anywhere_in_the_prompt_is_accepted():
    root = scratch(PROMPT.replace('(e.g. `{{gamma}}`)', 'plainly'))
    rc, out = run_fragment(root)
    assert rc == 0, out
    assert '  ok   all ' in out, out


# --- 3. it never greens while measuring nothing -------------------------------

def test_a_replay_that_parses_no_prompt_reds():
    """The replay floor. Files walked but no prompt parsed prints no failures and
    reads exactly like a clean scan, so it has to red on its own message."""
    root = scratch('# just a document\n\nNo prompt here.\n')
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'parsed 0 prompt(s)' in out, out


def test_an_unclosed_fence_reds_rather_than_guessing_the_region():
    root = scratch(PROMPT.rsplit('```', 1)[0])
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'fence open at end of file' in out, out


def test_an_anchor_outside_a_readable_prompt_is_counted_not_failed():
    """A doc may write a bold INPUTS heading in prose. That is reported in the pass
    line so it cannot grow unseen, and never turned into a false accusation."""
    root = scratch(PROMPT.replace('(e.g. `{{gamma}}`)', 'plainly'))
    (root / 'prose.md').write_text('# notes\n\n**INPUTS**\n\nSome prose.\n',
                                   encoding='utf-8')
    rc, out = run_fragment(root)
    assert rc == 0, out
    assert '1 anchor(s) outside a readable prompt' in out, out


# --- 4. the replay hook cannot become a fail-open -----------------------------

def _refused(root, fragment):
    rc, out = run_fragment(root)
    assert rc != 0, 'the replay root %r was accepted:\n%s' % (str(root), out)
    assert 'did not finish' in out and fragment in out, out


def test_the_repository_itself_is_refused_as_a_replay_root():
    _refused(REPO_ROOT, 'not a fixture temp dir')


def test_a_root_outside_the_temp_prefix_is_refused():
    _refused(REPO_ROOT / 'agents', 'not a fixture temp dir')


def test_a_root_holding_a_git_dir_is_refused():
    root = scratch()
    (root / '.git').mkdir()
    _refused(root, 'holds a .git')


def test_a_root_that_is_not_a_directory_is_refused():
    handle = tempfile.NamedTemporaryFile(suffix='.md', delete=False)
    handle.close()
    _refused(Path(handle.name), 'is not a directory')


# --- 5. the carve-out guards itself -------------------------------------------

def test_the_convention_example_is_skipped_by_name():
    body = PROMPT.replace('**ROLE**.', 'Tokens written as `{{snake_case}}` are prose.\n\n**ROLE**.')
    root = scratch(body.replace('(e.g. `{{gamma}}`)', 'plainly'))
    rc, out = run_fragment(root)
    assert rc == 0, out
    assert '1 convention example(s) skipped by name' in out, out


def test_declaring_an_input_by_the_carved_out_name_reds():
    body = PROMPT.replace('1. `{{alpha}}`, the first thing.',
                          '1. `{{snake_case}}`, a real input by the carved-out name.')
    root = scratch(body)
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'declares an input named {{snake_case}}' in out, out


# --- 6. the fragment is wired ------------------------------------------------

def test_the_orchestrator_sources_the_fragment_and_names_it_in_the_header():
    """A fragment on disk that nothing sources is a [0] FAIL, and one that is
    sourced without a header row is a [76f] FAIL. Both are asserted here so the
    wiring cannot rot separately from the check."""
    text = ORCHESTRATOR.read_text(encoding='utf-8')
    assert 'source "$DOD_MODULES_DIR/93-token-declarations.sh"' in text
    assert '#   93-token-declarations.sh, check [93],' in text


def _all_tests():
    return [(name, fn) for name, fn in sorted(globals().items())
            if name.startswith('test_') and callable(fn)]


def main():
    failed = []
    for name, fn in _all_tests():
        try:
            fn()
            print('ok   %s' % name)
        except AssertionError as exc:
            failed.append(name)
            print('FAIL %s: %s' % (name, exc))
    print('\n%d passed, %d failed' % (len(_all_tests()) - len(failed), len(failed)))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())

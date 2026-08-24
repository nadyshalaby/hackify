#!/usr/bin/env python3
"""Tests for check [94]. python3 scripts/test_section_exists.py

Every test here drives the REAL fragment, scripts/validate-dod.d/94-section-exists.sh,
by sourcing it the way scripts/validate-dod.sh does. Nothing in this file
re-implements the scanner. A suite that tested a copy would go green while the
shipped check rotted, which is the defect class this whole sprint is about.

The suite is organised around the four ways this check could be worse than
useless rather than merely broken:

  1. IT MISSES THE FINDING IT WAS WRITTEN FOR. Corpus finding I2's filed site
     was fixed at ab5cb74, so HEAD cannot score it. It is replayed from the blob
     pinned in scripts/claim_fixtures.json and the fragment must catch it there,
     at the right line, for the right reason.
  2. IT FABRICATES. Six live sites name the retired label deliberately, because
     resume mode still has to read archived work-docs that use it. Flagging any
     of them is the same defect as a stale claim, pointed the other way.
  3. IT GREENS WHILE MEASURING NOTHING. A replay that finds no mention, a
     collapsed live scan, a scan that could not finish.
  4. ITS TEST HOOK BECOMES A FAIL-OPEN. SE_REPLAY_ROOT exists so this file can
     point the fragment at a fixture. An exported value that quietly replaced
     the repo-wide scan with one clean file would print green having read
     nothing, so every root that is not a fixture temp dir must be REFUSED.
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
FRAGMENT = 'scripts/validate-dod.d/94-section-exists.sh'
ORCHESTRATOR = REPO_ROOT / 'scripts' / 'validate-dod.sh'
I2_PATH = 'skills/hackify/references/implement-and-test.md'

# The pass line, matched as a whole sentence rather than read positionally. A
# word-index read can drift into a WRONG number when the wording changes and
# still land above a floor, which is a test that passes without measuring what
# it names.
OK_LINE = re.compile(r'ok\s+all instruction site\(s\).*?across (\d+) live file\(s\).*?'
                     r'\((\d+) mention\(s\) examined, (\d+) excused as back-compat '
                     r'prose, (\d+) carried')


def run_fragment(replay_root=None):
    """Source the shipped fragment the way the orchestrator does. Returns (rc, text)."""
    script = ('FAILED=0; source scripts/validate-dod.d/00-helpers.sh; '
              'source %s; exit $FAILED' % FRAGMENT)
    env = dict(os.environ)
    env.pop('SE_REPLAY_ROOT', None)
    if replay_root is not None:
        env['SE_REPLAY_ROOT'] = str(replay_root)
    done = subprocess.run(['bash', '-c', script], cwd=str(REPO_ROOT), env=env,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return done.returncode, done.stdout.decode('utf-8', 'replace')


def scratch(body, name='doc.md'):
    """A throwaway tree under the temp prefix the replay hook accepts."""
    root = Path(tempfile.mkdtemp(prefix='se-check-'))
    target = root / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(body, encoding='utf-8')
    return root


def _by_id(ident):
    for spec in load_manifest():
        if spec.ident == ident:
            return spec
    raise AssertionError('the fixture manifest carries no %s' % ident)


# --- 1. the finding it was written for ----------------------------------------

def test_i2_is_caught_in_its_pinned_replay_at_the_right_line():
    """The deliverable. claim_fixtures.json pins the blob and its witnesses
    already prove the literal sits on lines 34, 57 and 223. What this asserts is
    that the CHECK reads it that way too, and names the template it judged
    against, because a bare FAIL line is not evidence it caught the finding for
    the right reason. Line 34 is the FILED site that corpus note n5 requires a
    scorer to name explicitly."""
    with replay_scope(_by_id('I2')) as scope:
        rc, out = run_fragment(scope.root)
    assert rc != 0, 'the replay printed no failure:\n%s' % out
    assert '%s:34 instructs a writer to use a work-doc section named' % I2_PATH in out, out
    assert "'Implementation Log'" in out, out
    assert 'work-doc-template.md declares no such heading' in out, out


def test_the_i2_replay_flags_every_occurrence_the_fixture_pins():
    """The fixture pins three lines. All three are instruction sites, so the
    check must report all three rather than stopping at the first."""
    with replay_scope(_by_id('I2')) as scope:
        rc, out = run_fragment(scope.root)
    assert rc == 3, 'expected three failures, got %d:\n%s' % (rc, out)
    for line in (34, 57, 223):
        assert '%s:%d' % (I2_PATH, line) in out, out


def test_the_i2_site_would_read_clean_under_an_appears_in_the_template_rule():
    """Why the rule is structural. The retired name DOES appear in the template,
    at line 5, inside the back-compat note. Under 'the name appears in the
    template' I2 is clean. Measured here rather than argued."""
    body = (REPO_ROOT / 'skills/hackify/references/work-doc-template.md').read_text(
        encoding='utf-8')
    assert 'Implementation Log' in body, 'the premise moved: the name is gone entirely'
    headings = [ln for ln in body.split('\n') if ln.startswith('##')]
    assert not any('Implementation Log' in ln for ln in headings), \
        'the name became a heading, which would retire this check'


# --- 2. it does not fabricate -------------------------------------------------

def test_the_live_tree_comes_back_clean():
    rc, out = run_fragment()
    assert rc == 0, 'the live tree reported a failure:\n%s' % out
    assert '  ok   all instruction site(s)' in out, out


def test_the_six_back_compat_sites_are_excused_and_counted():
    """The boundary the whole check turns on. Six live sites name the retired
    label on purpose. The count is asserted exactly, not as a floor, because
    this is the number that must not quietly drift: a seventh excused site means
    a new marker started swallowing something."""
    rc, out = run_fragment()
    found = OK_LINE.search(out)
    assert found is not None, 'the pass line did not match its own shape:\n%s' % out
    files, mentions, excused, known = (int(g) for g in found.groups())
    assert rc == 0, out
    assert excused == 6, 'expected 6 back-compat sites excused, got %d' % excused
    assert known == 3, 'expected 3 known live findings, got %d' % known
    assert mentions == excused + known, 'the mention total does not partition'
    assert files >= 100, files


def test_a_paragraph_about_the_rename_is_excused():
    root = scratch('# notes\n\nBack-compat: the Implementation Log label is still read.\n')
    rc, out = run_fragment(root)
    assert rc == 0, out
    assert '1 excused as back-compat prose' in out, out


def test_an_instruction_in_the_same_shape_is_not_excused():
    root = scratch('# notes\n\nAppend one Implementation Log entry per landed task.\n')
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'doc.md:3 instructs a writer' in out, out


def test_a_wrapped_instruction_is_still_matched():
    """Corpus finding M2 is that a line-based scan goes blind on wrapped text.
    The name is split from its verb across a hard break here, and the paragraph
    unit must still see it while the citation still names the physical line."""
    root = scratch('# notes\n\nOpen a new section in the\nImplementation Log titled T1.\n')
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'doc.md:4 instructs a writer' in out, 'the citation must name line 4:\n%s' % out


# --- 3. it never greens while measuring nothing -------------------------------

def test_a_replay_that_finds_no_mention_reds():
    """Files walked but nothing examined prints no failures and reads exactly
    like a clean scan, so it has to red on its own message."""
    root = scratch('# just a document\n\nNothing relevant here.\n')
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'found 0 mention(s) of a policed section name' in out, out


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
    root = scratch('# doc\n\nAppend one Implementation Log entry.\n')
    (root / '.git').mkdir()
    _refused(root, 'holds a .git')


def test_a_root_that_is_not_a_directory_is_refused():
    handle = tempfile.NamedTemporaryFile(suffix='.md', delete=False)
    handle.close()
    _refused(Path(handle.name), 'is not a directory')


# --- 5. the known-findings list cannot become a silent licence ----------------

def test_replay_mode_ignores_the_known_list_so_the_raw_catch_is_measurable():
    """The known list suppresses three real live findings. This proves the
    suppression is a live-mode reporting choice and not a hole in the scanner:
    the same sentence, replayed, FAILS."""
    body = ('# faq\n\nThe work-doc holds state. Implementation Log entries are '
            'written per task.\n')
    root = scratch(body, 'README.md')
    rc, out = run_fragment(root)
    assert rc != 0, 'the known phrase was suppressed in replay mode:\n%s' % out
    assert 'README.md:3 instructs a writer' in out, out


# --- 6. the fragment is wired ------------------------------------------------

def test_the_orchestrator_sources_the_fragment_and_names_it_in_the_header():
    """A fragment on disk that nothing sources is a [0] FAIL, and one that is
    sourced without a header row is a [76f] FAIL. Both are asserted here so the
    wiring cannot rot separately from the check."""
    text = ORCHESTRATOR.read_text(encoding='utf-8')
    assert 'source "$DOD_MODULES_DIR/94-section-exists.sh"' in text
    assert '#   94-section-exists.sh, check [94],' in text


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

#!/usr/bin/env python3
"""Tests for check [95]. python3 scripts/test_literal_absent_claims.py

Every test here drives the REAL fragment,
scripts/validate-dod.d/95-literal-absent-claims.sh, by sourcing it the way
scripts/validate-dod.sh does. Nothing in this file re-implements the scanner. A
suite that tested a copy would go green while the shipped check rotted, which is
the defect class this whole sprint is about.

The suite is organised around the four ways this check could be worse than
useless rather than merely broken:

  1. IT MISSES THE FINDING IT WAS WRITTEN FOR. Sprint decision #16-C fixed the
     comment corpus finding I4 was filed against, so I4 is scored against the
     blob scripts/claim_fixtures.json pins for it, never against the live tree.
  2. IT FABRICATES. The first draft of this check formed 352 claim pairs over
     the live tree and 8 of its 9 tightened pairs were still wrong, every one of
     them a RUNTIME absence rather than a text absence. Those shapes are pinned
     here so the vocabulary cannot quietly widen back.
  3. IT GREENS WHILE MEASURING NOTHING. A replay that forms no claim, a
     collapsed live scan, a scan that could not finish.
  4. ITS TEST HOOK BECOMES A FAIL-OPEN. LA_REPLAY_ROOT exists so this file can
     point the fragment at a fixture. Every root that is not a fixture temp dir
     must be REFUSED, never ignored.
"""

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

# The replay comes from the fixture machinery rather than from a second copy of
# the blob shas. One source of truth for what I4 is: if the manifest entry ever
# stops carrying the defect, its own suite reds and this one does too.
from claim_fixture_manifest import load_manifest
from claim_fixtures import replay_scope

FRAGMENT = 'scripts/validate-dod.d/95-literal-absent-claims.sh'
ORCHESTRATOR = REPO_ROOT / 'scripts' / 'validate-dod.sh'
I4_CLAIM = 'scripts/validate-dod.d/71-release-mechanism-pins.sh'
I4_EVIDENCE = 'scripts/validate-dod.d/77-reviewer-roster.sh'

OK_LINE = re.compile(r'ok\s+all (\d+) quoted phrase\(s\) called unpinned across '
                     r'(\d+) live file\(s\).*?\((\d+) pinning claim\(s\) examined\)')


def run_fragment(replay_root=None):
    """Source the shipped fragment the way the orchestrator does. Returns (rc, text)."""
    script = ('FAILED=0; source scripts/validate-dod.d/00-helpers.sh; '
              'source %s; exit $FAILED' % FRAGMENT)
    env = dict(os.environ)
    env.pop('LA_REPLAY_ROOT', None)
    if replay_root is not None:
        env['LA_REPLAY_ROOT'] = str(replay_root)
    done = subprocess.run(['bash', '-c', script], cwd=str(REPO_ROOT), env=env,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return done.returncode, done.stdout.decode('utf-8', 'replace')


def scratch(files):
    """A throwaway tree under the temp prefix the replay hook accepts."""
    root = Path(tempfile.mkdtemp(prefix='la-check-'))
    for name, body in files.items():
        target = root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(body, encoding='utf-8')
    return root


def i4_spec():
    """The pinned I4 fixture, read out of the manifest that owns it.

    I4 was kind 'worktree' until #16-C fixed the comment it was filed against.
    It is kind 'blobs' now, so replay_scope materialises both halves into a temp
    dir from content hashes, which is a scope the replay hook accepts and content
    that cannot drift. Nothing here is read off the live tree."""
    for spec in load_manifest():
        if spec.ident == 'I4':
            return spec
    raise AssertionError('the fixture manifest carries no I4')


# --- 1. the finding it was written for ----------------------------------------

def test_i4_is_caught_with_its_counter_evidence_named():
    """The deliverable. The claim and the phrase it calls unpinned live in two
    different files, so a check that only reported the claim would not have
    proved anything. The counter-evidence file must be named."""
    with replay_scope(i4_spec()) as scope:
        rc, out = run_fragment(scope.root)
    assert rc != 0, 'the replay printed no failure:\n%s' % out
    assert "says '4-5 reviewers' is NOT pinned" in out, out
    assert I4_CLAIM in out and I4_EVIDENCE in out, out


def test_the_live_tree_no_longer_carries_the_i4_claim():
    """The other half of the deliverable. #16-C fixed the filed site, so the scan
    that used to report it must now find nothing there. If the sentence ever comes
    back, this reds before the pass line absorbs it as ordinary prose."""
    rc, out = run_fragment()
    assert rc == 0, out
    assert I4_CLAIM not in out, out
    assert '4-5 reviewers' not in out, out


def test_the_claim_is_matched_after_the_line_wrap_moves():
    """Corpus note n8 says I4's reachability rests on the claim and its quoted
    phrase sharing one physical line, and finding M2 is the proof that a
    line-based scan goes blind when text wraps. Here the wrap is moved between
    them. The paragraph unit must still form the pair."""
    root = scratch({
        'a.sh': '# The "4-5 reviewers" row is\n# deliberately NOT pinned here.\n',
        'b.sh': "BANS+=('4-5 reviewers')\n",
    })
    rc, out = run_fragment(root)
    assert rc != 0, 'the wrapped claim was missed:\n%s' % out
    assert "'4-5 reviewers'" in out and 'b.sh' in out, out


# --- 2. it does not fabricate -------------------------------------------------

def test_the_live_tree_comes_back_clean():
    rc, out = run_fragment()
    assert rc == 0, 'the live tree reported a failure:\n%s' % out
    assert '  ok   all ' in out and 'genuinely unpinned' in out, out


def test_the_live_scan_forms_no_pair_at_all():
    """Before #16-C this formed exactly one pair, I4, and carried it on a
    known-findings list. The fix removed the claim, so the honest number is zero
    and the list retired with it. The floors still have to hold underneath, or a
    scan that read nothing would report the same zero."""
    rc, out = run_fragment()
    found = OK_LINE.search(out)
    assert found is not None, 'the pass line did not match its own shape:\n%s' % out
    pairs, files, claims = (int(g) for g in found.groups())
    assert rc == 0, out
    assert pairs == 0, 'pairs=%d' % pairs
    assert files >= 100 and claims >= 5, (files, claims)
    assert 'known-findings list' not in out, out


def test_a_runtime_absence_sentence_does_not_fire():
    """The eight false positives the first draft produced were all this shape: a
    tool missing from PATH, a capability the harness did not offer, an id
    missing from a scan RESULT. None is decidable by grepping the tree, and the
    vocabulary must never widen back to reach them."""
    root = scratch({
        'a.md': 'This block needs `python3` and it is absent from PATH.\n'
                'The `ProposeGoal` tool is absent in this runtime.\n',
        'b.md': 'Here is `python3` and here is `ProposeGoal`.\n',
    })
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'found 0 pinning claim(s)' in out, \
        'a runtime-absence sentence formed a claim:\n%s' % out


def test_a_quote_elsewhere_in_the_paragraph_is_not_the_subject():
    """The paragraph-wide pairing formed 352 pairs over the live tree by
    matching one claim against every quote near it. The phrase has to be the
    nearest quote before the claim, inside a short window."""
    root = scratch({
        'a.md': 'The `alpha` row and a long digression running well past the '
                'window before we ever say NOT pinned about something else.\n',
        'b.md': 'Here is `alpha`.\n',
    })
    rc, out = run_fragment(root)
    assert rc == 0, 'a distant quote was treated as the subject:\n%s' % out


def test_a_genuinely_unpinned_phrase_is_accepted():
    root = scratch({
        'a.md': 'The `never-written-anywhere-else` row is NOT pinned.\n',
        'b.md': 'Unrelated content.\n',
    })
    rc, out = run_fragment(root)
    assert rc == 0, 'a true claim was flagged:\n%s' % out


# --- 3. it never greens while measuring nothing -------------------------------

def test_a_replay_that_forms_no_claim_reds():
    root = scratch({'a.md': '# just a document\n\nNothing relevant.\n'})
    rc, out = run_fragment(root)
    assert rc != 0, out
    assert 'found 0 pinning claim(s)' in out, out


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
    root = scratch({'a.md': 'The `x` row is NOT pinned.\n'})
    (root / '.git').mkdir()
    _refused(root, 'holds a .git')


def test_a_root_that_is_not_a_directory_is_refused():
    handle = tempfile.NamedTemporaryFile(suffix='.md', delete=False)
    handle.close()
    _refused(Path(handle.name), 'is not a directory')


# --- 5. the fragment is wired ------------------------------------------------

def test_the_orchestrator_sources_the_fragment_and_names_it_in_the_header():
    text = ORCHESTRATOR.read_text(encoding='utf-8')
    assert 'source "$DOD_MODULES_DIR/95-literal-absent-claims.sh"' in text
    assert '#   95-literal-absent-claims.sh, check [95],' in text


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

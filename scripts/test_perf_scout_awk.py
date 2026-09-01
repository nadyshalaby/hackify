#!/usr/bin/env python3
"""Tests for the heredoc-opener rule in sh_loop_body.

Run: python3 scripts/test_perf_scout_awk.py

sh_loop_body is the perf-scout's shell loop-body extractor, and it lives in
skills/hackify/references/perf-scout.md inside the HOW section's bash fence.
It skips heredoc bodies so that a `done` sitting inside one cannot close a loop
that is still open, and to do that it has to decide, per line, whether a `<<`
opens a heredoc at all.

THE DEFECT THIS SUITE EXISTS FOR. The opener test used to match `<<WORD`
anywhere on the line, quoted string included. One `printf '%s\n' "cat <<EOF"`
then set the pending delimiter, and the first rule skipped every following line
until one equalled that delimiter exactly. In a file where no bare `EOF` line
ever appears, that is the rest of the file: every loop after the quoted line is
invisible and the scout reports nothing, which reads exactly like a clean scan.
Measured on the live tree, hooks/test_block_banned_tokens.sh:59 carries that
shape and the file holds no bare `EOF` line in 298 lines, so the shipped helper
reported ZERO body lines for a file whose loop at 205 spawns python3 per item.

THE HELPER IS EXTRACTED, NOT COPIED. Every row below drives the function text
pulled straight out of the markdown, so a suite going green is a claim about
what ships. A second copy pasted in here would be free to drift from the
doctrine, and two green things disagreeing about one scanner is the quietest
version of this same defect.

HOW A ROW OBSERVES AN OPENER. There is no return value to read, so the rows
read the helper's own behaviour instead. Each probe builds a loop body holding
the candidate line, a MARK_INSIDE line under it, a bare delimiter, and a
MARK_AFTER line after that. If the candidate opened a heredoc, MARK_INSIDE was
swallowed and only MARK_AFTER comes back. If it did not, both come back. Every
probe asserts MARK_AFTER either way, which is what keeps a row from passing
against a helper that reports nothing at all.
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCTRINE = REPO_ROOT / 'skills' / 'hackify' / 'references' / 'perf-scout.md'

# The live file that motivated this suite. Read rather than described, so the
# pin at the bottom fails loudly if the shape moves instead of quietly passing.
LIVE_FALSE_OPENER = REPO_ROOT / 'hooks' / 'test_block_banned_tokens.sh'
LIVE_SHAPE = "cat > cfg.ts <<EOF"

# perf.process.spawn-per-item, copied from the Shell table's row as an ARGUMENT
# to the helper rather than as a second copy of the helper. sh_loop_body takes
# the pattern as "$2", so this is caller input and cannot drift from the scan.
SPAWN_ERE = (r'\$\((cat|wc|grep|git|sed|awk|find|sort|uniq|head|tail|cut|tr'
             r'|stat|realpath|date|jq|python3|node)[[:space:]]')

INSIDE = 'MARK_INSIDE'
AFTER = 'MARK_AFTER'


def extract_function(name):
    """Pull one shell function out of the doctrine's bash fences.

    Fails loudly on anything it does not recognise. An extractor that quietly
    returned an empty program would let every row below pass while testing
    nothing, which is the defect class this file is about.

    SystemExit rather than the AssertionError the sibling suites raise, and the
    difference is load-bearing rather than stylistic: main() below catches
    AssertionError to record a failing row, so a refusal raised as one would be
    indistinguishable from a row that simply failed, and the row asserting this
    refusal would pass on any assertion at all inside its try block.
    """
    text = DOCTRINE.read_text(encoding='utf-8')
    fences = re.findall(r'^```bash$\n(.*?)^```$', text, re.S | re.M)
    opener = '%s() {' % name
    holding = [fence for fence in fences if opener in fence]
    if len(holding) != 1:
        raise SystemExit('%s: %d bash fence(s) define %s, expected exactly 1'
                         % (DOCTRINE, len(holding), name))
    lines = holding[0].splitlines()
    starts = [i for i, line in enumerate(lines) if line == opener]
    if len(starts) != 1:
        raise SystemExit('%s: %d definition(s) of %s in one fence'
                         % (DOCTRINE, len(starts), name))
    ends = [i for i in range(starts[0], len(lines)) if lines[i] == '}']
    if not ends:
        raise SystemExit('%s: %s has no closing brace at column 0'
                         % (DOCTRINE, name))
    return '\n'.join(lines[starts[0]:ends[0] + 1]) + '\n'


SH_LOOP_BODY = extract_function('sh_loop_body')


def run_helper(body, pattern):
    """Run the SHIPPED helper over `body` and return its stdout.

    The fixture and the runner both go to a tempdir. Nothing is written into
    this repo, so no row here can redden a check that scans the tree.
    """
    tmp = Path(tempfile.mkdtemp(prefix='perf-scout-awk-'))
    fixture = tmp / 'fixture.sh'
    fixture.write_text(body, encoding='utf-8')
    runner = tmp / 'run.sh'
    runner.write_text(SH_LOOP_BODY + '\nsh_loop_body "$1" "$2"\n', encoding='utf-8')
    done = subprocess.run(['bash', str(runner), str(fixture), pattern],
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return done.stdout.decode('utf-8', 'replace')


def probe(candidate, delimiter='EOF'):
    """(inside_reported, after_reported) for a loop body holding `candidate`."""
    body = ''.join([
        '#!/usr/bin/env bash\n',
        'while IFS= read -r f; do\n',
        '  %s\n' % candidate,
        '  %s "$f"\n' % INSIDE,
        '%s\n' % delimiter,
        '  %s "$f"\n' % AFTER,
        'done < <(find . -name "*.md")\n',
    ])
    out = run_helper(body, '%s|%s' % (INSIDE, AFTER))
    return (INSIDE in out, AFTER in out), out


def assert_opener(candidate):
    (inside, after), out = probe(candidate)
    assert after, ('the probe reported nothing at all for %r, so this row '
                   'measured no opener either way:\n%s' % (candidate, out))
    assert not inside, ('%r did not open a heredoc: the line under it was '
                        'reported as loop body:\n%s' % (candidate, out))


def assert_not_opener(candidate):
    (inside, after), out = probe(candidate)
    assert after, ('the probe reported nothing at all for %r, so this row '
                   'measured no opener either way:\n%s' % (candidate, out))
    assert inside, ('%r was treated as a heredoc opener and swallowed the line '
                    'under it, blinding the scan from there on:\n%s'
                    % (candidate, out))


# --- 1. genuine openers must still open ---------------------------------------

def test_a_bare_delimiter_opens_a_heredoc():
    assert_opener('cat <<EOF')


def test_the_dash_form_opens_a_heredoc():
    assert_opener('cat <<-EOF')


def test_a_single_quoted_delimiter_opens_a_heredoc():
    assert_opener("cat <<'EOF'")


def test_a_double_quoted_delimiter_opens_a_heredoc():
    assert_opener('cat <<"EOF"')


def test_an_opener_followed_by_a_redirect_opens_a_heredoc():
    assert_opener('cat <<EOF > out')


def test_an_opener_piped_onward_opens_a_heredoc():
    assert_opener('cat <<EOF | wc -l')


def test_an_opener_with_a_numbered_redirect_opens_a_heredoc():
    """`2>` is a redirect like any other, and a tail rule that only knew about
    bare `>` would drop this one back into the scanned-body bucket."""
    assert_opener('cat <<EOF 2>/dev/null')


def test_an_opener_ending_a_command_list_opens_a_heredoc():
    assert_opener('cat <<EOF &&')


# --- 2. a delimiter inside a string is not an opener ---------------------------

def test_a_delimiter_inside_a_double_quoted_string_is_not_an_opener():
    assert_not_opener('printf "%s\\n" "run: cat <<EOF"')


def test_a_delimiter_inside_a_single_quoted_string_is_not_an_opener():
    assert_not_opener("echo 'use <<EOF here'")


def test_a_delimiter_inside_a_quoted_printf_argument_is_not_an_opener():
    """The live shape, reduced. hooks/test_block_banned_tokens.sh writes whole
    scripts as printf arguments, so `<<EOF` is followed by a literal `\\n`."""
    assert_not_opener("check 2 \"$(printf 'cat > cfg.ts <<EOF\\nk = 1\\nEOF')\"")


# --- 3. here-strings were never openers, and must stay that way ----------------

def test_a_here_string_is_not_an_opener():
    assert_not_opener('grep -qxF -- "$entry" <<<"$PATHS"')


def test_a_bare_word_here_string_is_not_an_opener():
    assert_not_opener('grep -q x <<<WORD')


# --- 4. the blinding case, end to end -----------------------------------------

BLINDING = ''.join([
    '#!/usr/bin/env bash\n',
    'printf \'%s\\n\' "run: cat <<EOF"\n',
    'while IFS= read -r f; do\n',
    '  loc=$(wc -l < "$f")\n',
    '  echo "$loc"\n',
    'done < <(find . -name "*.md")\n',
])


def test_a_quoted_delimiter_does_not_blind_the_loops_below_it():
    """The whole defect in six lines. No bare `EOF` line exists in this fixture,
    so a false opener on line 2 skips every line after it and the helper reports
    a clean zero over a file holding a per-item `wc -l`."""
    out = run_helper(BLINDING, SPAWN_ERE)
    assert 'wc -l' in out, (
        'the loop below the quoted delimiter was never scanned; the helper '
        'reported:\n%r' % out)


def test_the_same_loop_is_reported_without_the_quoted_line():
    """The control. Without it, the row above could pass on a helper that
    reports every line of every file, which would prove nothing about the
    opener rule."""
    out = run_helper(BLINDING.replace('printf \'%s\\n\' "run: cat <<EOF"\n',
                                      'echo hello\n'), SPAWN_ERE)
    assert 'wc -l' in out, out


def test_a_real_heredoc_body_is_still_skipped_end_to_end():
    """The other direction, and the reason the opener rule exists at all: a
    `done` inside a heredoc body must not close the loop around it."""
    body = ''.join([
        '#!/usr/bin/env bash\n',
        'while IFS= read -r f; do\n',
        '  cat <<EOF\n',
        '  loc=$(wc -l < "$f")\n',
        'done\n',
        'EOF\n',
        '  echo "$f"\n',
        'done < <(find . -name "*.md")\n',
    ])
    out = run_helper(body, SPAWN_ERE)
    assert out == '', 'a heredoc body was scanned as loop body:\n%s' % out


# --- 5. the live tree, and the extraction's own floors ------------------------

def test_the_live_hook_suite_is_reachable_past_its_quoted_delimiter():
    """A pin on the file that produced the diagnosis. If the hook suite stops
    carrying this shape the row reddens rather than passing quietly, and the fix
    is to move the pin to whatever file carries it next, not to delete it."""
    text = LIVE_FALSE_OPENER.read_text(encoding='utf-8')
    assert LIVE_SHAPE in text, (
        '%s no longer carries %r, so this pin measures nothing; re-point it'
        % (LIVE_FALSE_OPENER, LIVE_SHAPE))
    assert not re.search(r'^EOF$', text, re.M), (
        '%s now holds a bare EOF line, which closes the false opener by luck '
        'and makes this pin pass for the wrong reason' % LIVE_FALSE_OPENER)
    out = run_helper(text, SPAWN_ERE)
    assert 'python3' in out, (
        '%s reported no spawn candidate; its loop at 205 runs python3 per item '
        'and the quoted delimiter at 59 is what used to hide it:\n%r'
        % (LIVE_FALSE_OPENER, out))


def test_the_helper_was_extracted_from_the_doctrine_and_is_a_real_program():
    assert SH_LOOP_BODY.startswith('sh_loop_body() {'), SH_LOOP_BODY
    assert SH_LOOP_BODY.rstrip().endswith('}'), SH_LOOP_BODY
    assert 'awk' in SH_LOOP_BODY, SH_LOOP_BODY
    assert 'grep -E' in SH_LOOP_BODY, SH_LOOP_BODY
    assert len(SH_LOOP_BODY.splitlines()) >= 8, SH_LOOP_BODY


def test_the_extractor_reds_on_a_name_the_doctrine_does_not_define():
    """The extractor's own fail-closed branch, taken on purpose. Without it a
    renamed helper would hand every row an empty program to pass against."""
    try:
        extract_function('sh_loop_body_that_does_not_exist')
    except SystemExit:
        return
    raise AssertionError('the extractor accepted a helper the doctrine never defines')


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

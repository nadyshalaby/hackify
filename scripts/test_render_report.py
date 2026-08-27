#!/usr/bin/env python3
"""Unit rows for skills/hackify/scripts/render-report.py.

    python3 scripts/test_render_report.py

WHY THIS FILE EXISTS. The renderer had no suite at all. That was survivable while
it wrote one local HTML file nobody but its author opened, and it stopped being
survivable in the wave that started handing the same page to a publisher which
returns a shareable link. Two defects landed in that wave, and both of them are
the kind a single row would have caught:

  THE FIVE STAT TOKENS WERE BUILT WITH A BARE str(). Every other token goes
  through esc(), whose own docstring says payload text is untrusted prose and
  never markup. main() lets anything in the payload beat the git-derived value, a
  behaviour html-report.md documents for quick runs, so a script tag in
  stats.files reached the page verbatim. On a local file that is ugly; on a hosted
  origin it is stored cross-site scripting.

  BOTH OUTPUT PATHS FOLLOWED A SYMLINK. write_text() opens the destination and
  follows whatever link is already sitting there, and the documented artifact path
  was a fixed name in the shared temp directory, which is a name anyone on the
  host can guess and pre-fill.

WHAT A ROW HERE IS. One behaviour of the shipped script, exercised end to end
through main() wherever the behaviour is reachable that way, because the two
defects above both lived in the wiring rather than in a helper. Rows that can only
be reached from inside call the function directly and say so.

NOTHING HERE WRITES INTO THE REPOSITORY. Every output goes under a temporary
directory this file creates and removes, and the template is read, never edited.
"""

import importlib.util
import json
import shutil
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RENDERER = REPO_ROOT / 'skills' / 'hackify' / 'scripts' / 'render-report.py'
TEMPLATE = REPO_ROOT / 'skills' / 'hackify' / 'assets' / 'report-template.html'


def _load_renderer():
  """Import the shipped script by path. Its filename carries a hyphen, so it is
  not a module name and a plain import cannot reach it. Loaded once, from the
  tracked path, so these rows exercise the file that ships rather than a copy."""
  spec = importlib.util.spec_from_file_location('hackify_render_report', RENDERER)
  module = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(module)
  return module


render_report = _load_renderer()

# The payload every row starts from. Deliberately minimal: a key this file does
# not set renders as an honest empty state, which is the renderer's own contract.
BASE_PAYLOAD = {'title': 'zzq report', 'slug': 'zzq', 'sprint_goal': 'a goal'}

# The script tag a reviewer put through stats.files. Kept as one literal so every
# row that plants it and every row that refutes it are looking for the same bytes.
XSS = '<script>alert(document.domain)</script>'

# The five stat keys the payload can set. NAMED HERE RATHER THAN IN EACH ROW, so
# a sixth stat card added to the renderer is one edit away from being covered.
STAT_KEYS = ('tasks_done', 'tasks_total', 'files', 'loc_add', 'loc_del', 'commits')

_SCRATCH = []


def temp_dir(prefix):
  """A throwaway directory, remembered so main() can remove it."""
  root = Path(tempfile.mkdtemp(prefix=prefix))
  _SCRATCH.append(root)
  return root


def clean_scratch():
  """Remove every directory this module created. Called once, from main."""
  while _SCRATCH:
    shutil.rmtree(_SCRATCH.pop(), ignore_errors=True)


def render(payload, root=None, artifact=None):
  """Run the shipped main() over `payload`. Returns (out path, artifact path).

  THROUGH main() AND NOT THROUGH A HELPER, because the stat defect was in the
  wiring: build_tokens() was handed a stats dict that main() had already let the
  payload win. A row calling the helper directly would have passed either way."""
  root = root or temp_dir('render-')
  data = root / 'payload.json'
  data.write_text(json.dumps(payload), encoding='utf-8')
  out = root / 'report.html'
  argv = ['--data', str(data), '--out', str(out), '--template', str(TEMPLATE)]
  if artifact is not None:
    argv += ['--artifact-out', str(artifact)]
  assert render_report.main(argv) == 0
  return out, artifact


def expect(text, *needles):
  """Every needle must be present, matched as a literal substring."""
  for needle in needles:
    assert needle in text, 'expected %r in:\n%s' % (needle, text[:2000])


def refute(text, *needles):
  """No needle may be present."""
  for needle in needles:
    assert needle not in text, 'did not expect %r in:\n%s' % (needle, text[:2000])


def expect_exit(fn, *needles):
  """`fn` must raise SystemExit, and its message must carry every needle."""
  try:
    fn()
  except SystemExit as exc:
    for needle in needles:
      assert needle in str(exc), 'expected %r in the refusal %r' % (needle, str(exc))
    return
  raise AssertionError('expected a SystemExit, got a completed run')


# --- escaping, the half that turned into stored XSS ----------------------------

def test_a_script_tag_in_a_payload_stat_cannot_reach_the_output():
  """THE ROW THIS SUITE WAS OPENED FOR. A reviewer put this exact payload through
  the renderer and read the tag back out of the page unescaped. The stat is the
  only place it could happen, because every other token was already escaped."""
  payload = dict(BASE_PAYLOAD, stats={'files': XSS})
  out, _ = render(payload)
  page = out.read_text(encoding='utf-8')
  refute(page, XSS)
  expect(page, '&lt;script&gt;alert(document.domain)&lt;/script&gt;')


def test_every_stat_the_payload_can_set_is_escaped_and_not_only_the_reported_one():
  """The fix was five tokens, so the row is five tokens. Escaping the one a
  reviewer happened to demonstrate would leave the other four exactly as they
  were, which is a fix shaped like the report rather than like the defect."""
  for key in STAT_KEYS:
    out, _ = render(dict(BASE_PAYLOAD, stats={key: XSS}))
    page = out.read_text(encoding='utf-8')
    refute(page, XSS)
    assert '&lt;script&gt;' in page, 'the %s stat rendered no escaped tag' % key


def test_prose_carrying_markup_survives_as_text_rather_than_as_tags():
  """The contract esc() states, checked on a token that was never broken, so a
  regression that dropped escaping everywhere cannot pass by fixing only stats."""
  out, _ = render(dict(BASE_PAYLOAD, plain_summary='a type like Promise<User> & co'))
  expect(out.read_text(encoding='utf-8'), 'Promise&lt;User&gt; &amp; co')


def test_an_attribute_breaking_quote_in_a_stat_is_escaped_too():
  """esc() is called with quote=True, and the stat cards sit inside markup the
  renderer builds, so a bare double quote there would be an attribute break."""
  out, _ = render(dict(BASE_PAYLOAD, stats={'commits': '1" onmouseover="alert(1)'}))
  page = out.read_text(encoding='utf-8')
  refute(page, 'onmouseover="alert(1)')
  expect(page, '&quot; onmouseover=&quot;')


# --- the two output modes ------------------------------------------------------

def test_the_default_mode_writes_a_complete_document():
  """--out is the deliverable everywhere, publisher or not, so it keeps its own
  document shell and must open in a browser with no network."""
  out, _ = render(dict(BASE_PAYLOAD))
  page = out.read_text(encoding='utf-8')
  expect(page, '<!doctype html', '<html', '<head', '<body', '</html>')
  refute(page, '{{')


def test_the_artifact_mode_writes_the_same_page_with_no_shell():
  """A publisher supplies its own doctype, head and body and expects page content
  only. The title stays first, because a publisher reads the head of the file for
  one, and both writes come from a single render so the two cannot drift."""
  root = temp_dir('render-artifact-')
  out, artifact = render(dict(BASE_PAYLOAD), root=root, artifact=root / 'body.html')
  body = artifact.read_text(encoding='utf-8')
  refute(body, '<!doctype', '<html', '<head>', '<body')
  assert body.lstrip().startswith('<title>'), body[:120]
  expect(body, '<style>')
  expect(out.read_text(encoding='utf-8'), '<!doctype html')


def test_the_artifact_mode_leaves_the_deliverable_byte_for_byte_unchanged():
  """Nothing about --out changes when --artifact-out is passed. Asserted by
  rendering the same payload both ways and comparing, because 'unchanged' is the
  one property a reader of the flag cannot check by looking at the flag."""
  plain, _ = render(dict(BASE_PAYLOAD))
  root = temp_dir('render-both-')
  withartifact, _ = render(dict(BASE_PAYLOAD), root=root, artifact=root / 'b.html')
  assert plain.read_bytes() == withartifact.read_bytes()


# --- content_only, and the two things its docstring promises -------------------

def test_a_page_missing_any_of_the_three_pieces_is_refused():
  """It refuses rather than emitting a half page: a template that lost its title,
  its stylesheet or its body would otherwise publish silently broken."""
  whole = '<title>t</title><style>s</style><body>b</body>'
  for dropped in ('<title>t</title>', '<style>s</style>', '<body>b</body>'):
    expect_exit(lambda page=whole.replace(dropped, ''):
                render_report.content_only(page),
                'render-report: the rendered page has no')


def test_a_second_style_block_is_carried_rather_than_silently_dropped():
  """The docstring said it refuses rather than emitting a half page, and it only
  ever refused on ABSENCE. DOC_STYLE is non-greedy, so a single search took the
  first block and the second went out of the page without a word. Two blocks is
  not a broken page, so it is carried whole."""
  page = ('<title>t</title><style>one</style><style>two</style>'
          '<body>content</body>')
  body = render_report.content_only(page)
  expect(body, '<style>one</style>', '<style>two</style>', 'content')
  assert body.index('<style>one</style>') < body.index('<style>two</style>')


# --- the destination, and the symlink that used to be followed -----------------

def _planted_link(root, name):
  """A symlink at `name` pointing at a file whose content must survive."""
  victim = root / 'victim.txt'
  victim.write_text('SENSITIVE ORIGINAL CONTENT\n', encoding='utf-8')
  link = root / name
  link.symlink_to(victim)
  return victim, link


def test_the_deliverable_is_not_written_through_a_planted_symlink():
  """write_text() follows a pre-existing link at the destination, which made an
  arbitrary file overwrite as whoever ran the render. The refusal is a SystemExit
  and the victim keeps its bytes."""
  root = temp_dir('render-link-out-')
  victim, link = _planted_link(root, 'report.html')
  data = root / 'payload.json'
  data.write_text(json.dumps(BASE_PAYLOAD), encoding='utf-8')
  expect_exit(lambda: render_report.main(['--data', str(data), '--out', str(link),
                                          '--template', str(TEMPLATE)]),
              'refused to write', 'a symlink at the destination is never followed')
  assert victim.read_text(encoding='utf-8') == 'SENSITIVE ORIGINAL CONTENT\n'
  assert link.is_symlink(), 'the link itself must survive to be reported'


def test_the_artifact_path_is_not_written_through_a_planted_symlink():
  """The path the docs used to name was a fixed name in the shared temp
  directory, so this is the half a second user on the host could actually reach.
  The deliverable still lands: the refusal comes after --out is written."""
  root = temp_dir('render-link-artifact-')
  victim, link = _planted_link(root, 'body.html')
  data = root / 'payload.json'
  data.write_text(json.dumps(BASE_PAYLOAD), encoding='utf-8')
  out = root / 'report.html'
  expect_exit(lambda: render_report.main(['--data', str(data), '--out', str(out),
                                          '--artifact-out', str(link),
                                          '--template', str(TEMPLATE)]),
              'refused to write')
  assert victim.read_text(encoding='utf-8') == 'SENSITIVE ORIGINAL CONTENT\n'
  expect(out.read_text(encoding='utf-8'), '<!doctype html')


def test_a_plain_destination_is_still_overwritten_in_place():
  """The discriminator for the two rows above. Refusing a symlink must not turn
  into refusing a re-render, which every second run of a sprint would hit."""
  root = temp_dir('render-rewrite-')
  out = root / 'report.html'
  out.write_text('stale content from an earlier run', encoding='utf-8')
  render(dict(BASE_PAYLOAD, title='second pass'), root=root)
  page = out.read_text(encoding='utf-8')
  refute(page, 'stale content from an earlier run')
  expect(page, 'second pass')


# --- the refusals that keep a half-filled page off disk ------------------------

def test_a_template_still_holding_a_token_is_refused():
  """The renderer fills every token it knows and refuses on any leftover, so a
  template that gained a token nobody wired cannot publish as a page with a
  literal placeholder printed on it."""
  root = temp_dir('render-token-')
  template = root / 'template.html'
  template.write_text('<!doctype html><title>t</title><style>s</style>'
                      '<body>{{NOT_A_REAL_TOKEN}}</body>', encoding='utf-8')
  data = root / 'payload.json'
  data.write_text(json.dumps(BASE_PAYLOAD), encoding='utf-8')
  expect_exit(lambda: render_report.main(['--data', str(data),
                                          '--out', str(root / 'r.html'),
                                          '--template', str(template)]),
              'template tokens left unfilled', 'NOT_A_REAL_TOKEN')


def test_an_empty_payload_renders_honest_empty_states_rather_than_rows():
  """A missing key is a real answer. The renderer's own contract is that it never
  fabricates a finding, an action item or an evidence row to fill a table."""
  out, _ = render({})
  expect(out.read_text(encoding='utf-8'), 'None, the panel found nothing.',
         'No update log recorded.', 'No evidence ledger recorded.')


def _all_tests():
  """Every test_* callable in this module, sorted so a run is reproducible."""
  return sorted((name, fn) for name, fn in globals().items()
                if name.startswith('test_') and callable(fn))


def main():
  failed = []
  rows = _all_tests()
  try:
    for name, fn in rows:
      try:
        fn()
        print('ok   %s' % name)
      except AssertionError as exc:
        failed.append(name)
        print('FAIL %s: %s' % (name, exc))
  finally:
    clean_scratch()
  print('\n%d passed, %d failed' % (len(rows) - len(failed), len(failed)))
  return 1 if failed else 0


if __name__ == '__main__':
  sys.exit(main())

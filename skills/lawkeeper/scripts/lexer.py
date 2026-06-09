"""Mask string/comment/regex content so brace-counting and token scans aren't fooled.

The masker preserves every character POSITION (and newlines) but blanks out the inside of
strings, template literals, and line/block comments with spaces. Structural delimiters that
live in real code (`{`, `}`, `(`, `)`) survive, so a token scan run over the masked text can
never match inside a string literal or comment.

This is a pragmatic, line-aware lexer — not a full ECMAScript parser. It tracks the two
states that span lines (block comments, multi-line template literals); everything else
resolves within a line. Interpolations inside template literals (`${...}`) are NOT
un-masked, an accepted approximation: the high-value token bans never hide inside an
interpolation, and the structural caps that would care about nested braces are handled by
the linter / semantic pass, not here.
"""

NORMAL = 'normal'
BLOCK_COMMENT = 'block'
TEMPLATE = 'template'

_QUOTES = ("'", '"')


def mask_source(src):
  """Return masked lines (1:1 with input lines, equal length each)."""
  state = NORMAL
  masked = []
  for line in src.split('\n'):
    out, state = _mask_line(line, state)
    masked.append(out)
  return masked


def _mask_line(line, state):
  if state == BLOCK_COMMENT:
    return _resume(line, _skip_block)
  if state == TEMPLATE:
    return _resume(line, _skip_template)
  return _scan_normal(line)


def _resume(line, skip):
  """Continue a multi-line comment/template from column 0, then scan the remainder."""
  end, state = skip(line, 0)
  if state != NORMAL:
    return ' ' * len(line), state
  tail, tail_state = _scan_normal(line[end:])
  return ' ' * end + tail, tail_state


def _scan_normal(line):
  out = []
  i, n = 0, len(line)
  while i < n:
    nxt, state = _step(line, i)
    out.append(' ' * (nxt - i) if state != 'code' else line[i])
    if state in (BLOCK_COMMENT, TEMPLATE):
      return ''.join(out), state
    if state == 'eol':
      break
    i = nxt
  return ''.join(out), NORMAL


def _step(line, i):
  """Classify the token at column i; return (next_index, disposition)."""
  two = line[i:i + 2]
  if two == '//':
    return len(line), 'eol'
  if two == '/*':
    return _skip_block(line, i + 2)
  ch = line[i]
  if ch == '`':
    return _skip_template(line, i + 1)
  if ch in _QUOTES:
    return _skip_string(line, i + 1, ch), NORMAL
  return i + 1, 'code'


def _skip_block(line, start):
  end = line.find('*/', start)
  if end == -1:
    return len(line), BLOCK_COMMENT
  return end + 2, NORMAL


def _skip_template(line, start):
  i, n = start, len(line)
  while i < n:
    ch = line[i]
    if ch == '\\':
      i += 2
      continue
    if ch == '`':
      return i + 1, NORMAL
    i += 1
  return n, TEMPLATE


def _skip_string(line, start, quote):
  i, n = start, len(line)
  while i < n:
    ch = line[i]
    if ch == '\\':
      i += 2
      continue
    if ch == quote:
      return i + 1
    i += 1
  return n

"""The deterministic checks — only rules a regex matches WITHOUT false positives.

Why this subset and not more: an auditor is only useful if its findings are trusted,
so this scanner refuses to guess. File line-count is exact. The token bans live in
unambiguous syntax. Everything that needs real parsing to be precise — function length,
parameter count, nesting depth, DRY, layering — is deferred to the project's own linter
(which has `max-lines-per-function` / `max-params` / `max-depth` exactly) or to the
semantic subagent pass. See references/rule-catalog.md for the full rule -> engine map.

Token bans that live in COMMENTS (suppressions) or STRINGS (secrets) are scanned against
the original source; bans that are CODE constructs (empty catch, bare Error, non-null,
inline type) are scanned against the lexer-masked source so a match can never hide inside
a string or comment.
"""

import re

from lexer import mask_source

# rule_id -> (category, severity, confidence, fixable)
RULE_META = {
  'cap.file-lines': ('code-style', 'medium', 'exact', 'manual'),
  'ban.suppression': ('code-style', 'high', 'exact', 'manual'),
  'ban.empty-catch': ('code-style', 'high', 'exact', 'manual'),
  'ban.bare-error': ('code-style', 'high', 'exact', 'manual'),
  'ban.non-null': ('code-style', 'high', 'exact', 'manual'),
  'ban.inline-type': ('file-scoping', 'high', 'exact', 'manual'),
  'ban.custom': ('code-style', 'high', 'exact', 'manual'),
  'sec.hardcoded-secret': ('security', 'critical', 'exact', 'manual'),
  'clean.removed-comment': ('cleanup', 'low', 'exact', 'trivial'),
  'clean.debt-marker': ('cleanup', 'low', 'exact', 'manual'),
}

SUPPRESSION_RE = re.compile(r'biome-ignore|eslint-disable|@ts-ignore|@ts-expect-error|@ts-nocheck')
EMPTY_CATCH_RE = re.compile(r'\bcatch\b\s*(?:\([^)]*\))?\s*\{\s*\}')
BARE_ERROR_RE = re.compile(
  r'\bthrow\s+new\s+(?:Error|TypeError|RangeError|SyntaxError|EvalError|URIError|AggregateError)\s*\(')
NON_NULL_RE = re.compile(r'[\w$)\]]!(?=[.\[);,}\s]|$)')
TYPE_DECL_RE = re.compile(r'^\s*(?:export\s+)?(?:declare\s+)?(?:interface\s+[\w$]+|type\s+[\w$]+\s*(?:<[^>]*>)?\s*=)')
# Hygiene markers — language-agnostic, so they also run in text-only mode.
# Both require a comment opener before the marker so the word inside a string literal
# (e.g. a UI label "TODO list") is not flagged — debt markers live in comments by convention.
REMOVED_RE = re.compile(r'(?://|#|/\*|^\s*\*)\s*removed:', re.IGNORECASE)
DEBT_RE = re.compile(
  r'(?://|#|/\*|^\s*\*)\s*(?:TODO|FIXME|HACK|XXX)\b(?!\s*\()(?![:\s]*[A-Z][A-Z0-9]+-\d+)')

SECRET_RES = (
  ('aws-access-key', re.compile(r'AKIA[0-9A-Z]{16}')),
  ('private-key-pem', re.compile(r'-----BEGIN[ A-Z]*PRIVATE KEY-----')),
  ('github-token', re.compile(r'ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}')),
  ('slack-token', re.compile(r'xox[baprs]-[A-Za-z0-9-]{10,}')),
  ('google-api-key', re.compile(r'AIza[0-9A-Za-z_\-]{35}')),
  ('assigned-secret', re.compile(
    r'(?i)(?:api[_-]?key|client[_-]?secret|secret|passwd|password|token)'
    r'\s*[:=]\s*["\']([A-Za-z0-9_\-./+=]{12,})["\']')),
)
_ENVNAME_RE = re.compile(r'^[A-Z0-9_]+$')


class FileContext:
  """One file's source plus its masked twin, ready for the checks to run over."""

  def __init__(self, rel_path, src):
    self.rel_path = rel_path
    self.lines = src.split('\n')
    self._masked = None
    self._masked_text = None

  @property
  def masked(self):
    """JS/TS-masked lines, computed on first use (text-only files never pay for it)."""
    if self._masked is None:
      self._masked = mask_source('\n'.join(self.lines))
    return self._masked

  @property
  def masked_text(self):
    if self._masked_text is None:
      self._masked_text = '\n'.join(self.masked)
    return self._masked_text

  def _finding(self, rule_id, span, message):
    category, severity, confidence, fixable = RULE_META[rule_id]
    start = span[0]
    return {
      'rule_id': rule_id, 'category': category, 'severity': severity,
      'confidence': confidence, 'fixable': fixable, 'file': self.rel_path,
      'line': start, 'end_line': span[1], 'message': message,
      'snippet': self.lines[start - 1].strip()[:200] if start <= len(self.lines) else '',
    }

  def run_all(self, max_file_lines):
    out = self.check_file_lines(max_file_lines)
    for check in (self.check_suppression, self.check_empty_catch, self.check_bare_error,
                  self.check_non_null, self.check_inline_type, self.check_secrets,
                  self.check_removed_comment, self.check_debt_marker):
      out.extend(check())
    return out

  def run_text_only(self, max_file_lines, extra_bans):
    """Language-agnostic subset for non-JS files: file-line cap, project bans, hygiene markers.

    Skips every check that needs the JS/TS lexer (those would misfire on other syntaxes).
    A genuine deterministic audit of a non-JS stack is done by an on-demand scanner the
    skill generates per stack — see references/porting-scanner.md.
    """
    out = self.check_file_lines(max_file_lines)
    out.extend(self.check_extra_bans(extra_bans))
    out.extend(self.check_removed_comment())
    out.extend(self.check_debt_marker())
    return out

  def check_file_lines(self, cap):
    count = len(self.lines)
    if count <= cap:
      return []
    msg = f'File is {count} lines (cap {cap}) — split by responsibility.'
    return [self._finding('cap.file-lines', (1, count), msg)]

  def check_suppression(self):
    out = []
    for idx, line in enumerate(self.lines, 1):
      hit = SUPPRESSION_RE.search(line)
      if hit:
        msg = f'Lint/type suppression `{hit.group(0)}` — fix the root cause, do not suppress.'
        out.append(self._finding('ban.suppression', (idx, idx), msg))
    return out

  def check_empty_catch(self):
    return self._multiline('ban.empty-catch', EMPTY_CATCH_RE,
                           'Empty catch block — catch must log or rethrow.')

  def check_bare_error(self):
    out = []
    for idx, line in enumerate(self.masked, 1):
      if BARE_ERROR_RE.search(line):
        msg = 'Bare `new Error(...)` throw — use a domain-specific exception (verify this is domain code).'
        out.append(self._finding('ban.bare-error', (idx, idx), msg))
    return out

  def check_non_null(self):
    out = []
    for idx, line in enumerate(self.masked, 1):
      if NON_NULL_RE.search(line):
        msg = 'Non-null assertion `!` — handle null/undefined with a guard or optional chaining.'
        out.append(self._finding('ban.non-null', (idx, idx), msg))
    return out

  def check_inline_type(self):
    out = []
    for idx, line in enumerate(self.masked, 1):
      if TYPE_DECL_RE.match(line):
        msg = 'Type/interface declared in a scoped module — move it to interfaces/ or dto/.'
        out.append(self._finding('ban.inline-type', (idx, idx), msg))
    return out

  def check_secrets(self):
    out = []
    for idx, line in enumerate(self.lines, 1):
      for pattern in SECRET_RES:
        out.extend(self._secret_hits(pattern, line, idx))
    return out

  def check_removed_comment(self):
    out = []
    for idx, line in enumerate(self.lines, 1):
      if REMOVED_RE.search(line):
        out.append(self._finding('clean.removed-comment', (idx, idx),
                                  'Leftover `removed:` comment — the deletion is in git history.'))
    return out

  def check_debt_marker(self):
    out = []
    for idx, line in enumerate(self.lines, 1):
      if DEBT_RE.search(line):
        out.append(self._finding('clean.debt-marker', (idx, idx),
                                  'Debt marker without an owner/ticket — assign one or resolve it.'))
    return out

  def check_extra_bans(self, extra_bans):
    out = []
    for idx, line in enumerate(self.lines, 1):
      for regex, message in extra_bans:
        if regex.search(line):
          out.append(self._finding('ban.custom', (idx, idx), f'Project ban: {message}'))
          break
    return out

  def _secret_hits(self, pattern, line, idx):
    name, regex = pattern
    hit = regex.search(line)
    if not hit:
      return []
    value = hit.groups()[-1] if hit.groups() else hit.group(0)
    if name == 'assigned-secret' and _ENVNAME_RE.match(value):
      return []
    finding = self._finding('sec.hardcoded-secret', (idx, idx),
                            f'Possible hardcoded secret ({name}) — never commit credentials.')
    finding['snippet'] = line.replace(value, '***REDACTED***').strip()[:200]
    return [finding]

  def _multiline(self, rule_id, regex, message):
    out = []
    for match in regex.finditer(self.masked_text):
      line = self.masked_text.count('\n', 0, match.start()) + 1
      out.append(self._finding(rule_id, (line, line), message))
    return out

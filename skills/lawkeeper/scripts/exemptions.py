"""Carve-out catalog — which files and rules are exempt, and why.

An auditor that flags documented exceptions trains its user to ignore it, so the
exemption logic is a first-class part of the scanner, not an afterthought. The lists
below are SENSIBLE DEFAULTS that match the global doctrine's carve-outs; the orchestrator
can extend them per project (e.g. a different generated-file convention) by passing extra
globs through the CLI. Everything here is path-based and deterministic.

References for the carve-outs encoded here live in references/carve-outs.md.
"""

from fnmatch import fnmatch

# Directories never walked — build output, dependencies, VCS internals, caches.
SKIP_DIRS = frozenset({
  'node_modules', '.git', 'dist', 'build', 'out', '.next', '.turbo', '.cache',
  'coverage', '.nyc_output', 'vendor', '.venv', 'venv', '__pycache__', '.svelte-kit',
  'template-reference',
})

# File extensions the scanner understands (braced ECMAScript family).
SCAN_EXTS = frozenset({'.ts', '.tsx', '.js', '.jsx', '.mts', '.cts', '.mjs', '.cjs'})

# Generated / vendored files — exempt from EVERY rule (you don't refactor generated code).
GENERATED_GLOBS = (
  '*.gen.ts', '*.gen.tsx', '*.generated.*', 'routeTree.gen.ts', '*.d.ts',
  '*/migrations/*', '*/migrations/**/*',
)

# Test files — exempt from suppression, non-null, and inline-type bans (the deliberate
# carve-outs in the doctrine: @ts-expect-error for invalid input, test fixtures, etc.).
TEST_GLOBS = (
  '*.test.*', '*.spec.*', '*_test.*', '*test_*', '*/tests/*', '*/tests/**/*',
  '*/__tests__/*', '*/__tests__/**/*', '*/test/*', '*/test/**/*',
)

# Only these file kinds are subject to the inline-type ban (router/service/etc.).
SCOPED_TYPE_GLOBS = (
  '*.service.ts', '*.controller.ts', '*.routes.ts', '*.routes.tsx',
  '*.middleware.ts', '*.guard.ts',
)

# Rules waived inside test files.
_TEST_WAIVED = frozenset({'ban.suppression', 'ban.non-null', 'ban.inline-type', 'ban.bare-error'})


def _matches_any(rel_path, globs):
  base = rel_path.rsplit('/', 1)[-1]
  for pattern in globs:
    if fnmatch(rel_path, pattern) or fnmatch(base, pattern):
      return True
  return False


def is_skipped_dir(name):
  return name in SKIP_DIRS


def _ext(rel_path):
  dot = rel_path.rfind('.')
  return rel_path[dot:] if dot != -1 else ''


def is_scannable(rel_path, extra_generated=()):
  if _ext(rel_path) not in SCAN_EXTS:
    return False
  return not is_generated(rel_path, extra_generated)


def scan_mode(rel_path, extra_generated=(), text_exts=()):
  """Classify a file: 'full' (JS/TS check suite), 'text' (file-cap + bans only), or None."""
  if is_generated(rel_path, extra_generated):
    return None
  ext = _ext(rel_path)
  if ext in SCAN_EXTS:
    return 'full'
  if ext in text_exts:
    return 'text'
  return None


def is_generated(rel_path, extra_generated=()):
  return _matches_any(rel_path, GENERATED_GLOBS) or _matches_any(rel_path, extra_generated)


def is_test(rel_path):
  return _matches_any(rel_path, TEST_GLOBS)


def applies_inline_type(rel_path):
  return _matches_any(rel_path, SCOPED_TYPE_GLOBS)


def rule_exempt(rule_id, rel_path):
  """True when `rule_id` does not apply to `rel_path` per the carve-out catalog."""
  if rule_id == 'ban.inline-type' and not applies_inline_type(rel_path):
    return True
  if is_test(rel_path) and rule_id in _TEST_WAIVED:
    return True
  return False

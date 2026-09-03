"""Carve-out catalog, which files and rules are exempt, and why.

An auditor that flags documented exceptions trains its user to ignore it, so the
exemption logic is a first-class part of the scanner, not an afterthought. The lists
below are SENSIBLE DEFAULTS that match the global doctrine's carve-outs; the orchestrator
can extend them per project (e.g. a different generated-file convention) by passing extra
globs through the CLI. Everything here is path-based and deterministic.

References for the carve-outs encoded here live in references/carve-outs.md.
"""

from fnmatch import fnmatch

# Directories never walked, build output, dependencies, VCS internals, caches.
SKIP_DIRS = frozenset({
  'node_modules', '.git', 'dist', 'build', 'out', '.next', '.turbo', '.cache',
  'coverage', '.nyc_output', 'vendor', '.venv', 'venv', '__pycache__', '.svelte-kit',
  'template-reference',
})

# File extensions the scanner understands (braced ECMAScript family).
SCAN_EXTS = frozenset({'.ts', '.tsx', '.js', '.jsx', '.mts', '.cts', '.mjs', '.cjs'})

# Generated / vendored files, exempt from EVERY rule (you don't refactor generated code).
GENERATED_GLOBS = (
  '*.gen.ts', '*.gen.tsx', '*.generated.*', 'routeTree.gen.ts', '*.d.ts',
  '*/migrations/*', '*/migrations/**/*',
  # The lawkeeper recall corpus is deliberately-violating test fixtures, not real
  # code, exempt it from a self-audit (`/hackify:lawkeeper` on this repo) so a contributor
  # is not handed a pile of planted false-positives. run_corpus.py roots its scan
  # INSIDE corpus/project, where rel-paths don't contain this segment, so the
  # corpus's own scoring is unaffected.
  '*/evals/corpus/*',
)

# Test files, exempt from suppression, non-null, and inline-type bans (the deliberate
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

# Prose files. Markdown reaches this scanner only when a caller passes `--text-only-ext .md`.
PROSE_GLOBS = ('*.md', '*.mdx')

# Append-only records, waived from `cap.file-lines` and from nothing else. A changelog
# grows by one entry per release and shrinks for no reason at all, so "split by
# responsibility", the remedy the cap exists to force, has nothing to act on: there is no
# second responsibility in it, and it is read by jumping to a heading rather than end to
# end.
#
# EXACT BASENAMES, NEVER A PATTERN. `*.md`, or "docs are exempt", would take README.md and
# every reference file with it. A project extends this by naming its own release-history
# file, extension included.
#
# MATCHED ON THE BASENAME, NOT THE REPO-RELATIVE PATH, which is a deliberate widening over
# the hackify repo's shell half (`scripts/validate-dod.d/80-file-size-caps.sh`, which
# compares whole paths and so waives the root changelog alone). The two coincide at a repo
# root, and this scanner is pointed at arbitrary roots, so a monorepo's
# `packages/*/CHANGELOG.md` is waived here and would not be there.
APPEND_ONLY_BASENAMES = frozenset({'CHANGELOG.md'})

# Sub-agent prompt templates, waived from `cap.file-lines` and from nothing else. One of
# these carries a whole agent's instruction set in one file, and it is read by an agent
# that HAS NO IMPORT: everything it will ever know arrives in that single prompt. So
# "split it by responsibility", the remedy the file cap exists to force, is not a cheaper
# alternative here, it is a different and worse design, and what the project decided on is
# a RAISED BOUND rather than an exemption.
#
# THE RESIDUAL, WHICH IS THE WHOLE COST OF THE CARVE-OUT, WRITTEN DOWN RATHER THAN IMPLIED.
# This scanner takes its cap as ONE `max_file_lines` parameter (`audit_scan.py` parses a
# single `--max-file-lines` and hands that one int to `run_all` / `run_text_only`) and
# expresses every carve-out as a RULE WAIVER, so it cannot represent a second bound. The
# waiver below therefore means a `/hackify:lawkeeper` run stops reporting these files AT
# ALL, not that it reports them at the raised number. Which half each enforcer holds:
# `scripts/validate-dod.d/80-file-size-caps.sh` holds the raised bound and is its ONLY
# enforcer, pinned there at `CAP_PROMPT_TEMPLATE_MAX_LOC`; this file holds only the
# statement that 500 is the wrong number for these paths. That fragment cross-checks the
# two on the files each SELECTS, never on their patterns, and no agreement wider than that
# exists between them.
#
# REPO-RELATIVE, NOT BASENAMES, the opposite choice from APPEND_ONLY_BASENAMES above and
# for exactly the reason that made that one a basename set. A `CHANGELOG.md` is append-only
# wherever it sits; here the two DIRECTORIES are the class, and a basename rule would waive
# an `investigation.md` anywhere in any project. The cost is that a scan rooted below the
# repo cannot match these, which is the correct answer rather than a gap: below that root
# the files are no longer at these addresses.
#
# MATCHED EXACTLY ONE SEGMENT DEEP. `fnmatch` lets `*` cross `/`, so `agents/*.md` on its
# own would also adopt `agents/any/nested/file.md`. The directory half is compared for
# equality and only the basename is globbed, which is also the shell tier's semantics.
PROMPT_TEMPLATE_GLOBS = (
  'skills/hackify/references/parallel-agents/*.md',
  'agents/*.md',
)

# Rules waived inside test files.
#
# THE FIRST FOUR ARE DOCTRINE CARVE-OUTS: a test may legitimately do the banned thing, a
# suppression over deliberately invalid input, a `!` on a fixture, an inline type, a bare
# `Error`. THE TWO HYGIENE MARKERS ARE HERE FOR A SECOND REASON, which is that a fixture
# asserting the scanner detects `// TODO` has to contain `// TODO`. They landed later than
# the other four and nobody revisited this row, so the scanner flagged the exact strings
# that prove it works. Residual, written down rather than smoothed over: a genuine
# ownerless debt marker in an ordinary test file is no longer reported here and reaches
# only the semantic pass. That is the price of a path-based rule, and it is the cheaper
# half of the trade, because a false positive nobody can fix trains its reader to skim.
_TEST_WAIVED = frozenset({
  'ban.suppression', 'ban.non-null', 'ban.inline-type', 'ban.bare-error',
  'clean.removed-comment', 'clean.debt-marker',
})

# Rules waived inside prose files.
#
# BOTH MARKERS REQUIRE A COMMENT OPENER, AND MARKDOWN HAS NONE OF THE FOUR. `#` opens a
# HEADING there and a leading `*` opens a bullet, while `//` and `/*` reach a `.md` file
# only inside a code span, where the pattern is being QUOTED in order to define it. So a
# match in prose is a document describing the rule, never a comment left behind by a
# deletion, which is the only thing these two rules mean.
#
# The residual, stated at the precision it can be defended at: a `# TODO` heading or a
# `* TODO` bullet in a design doc IS arguably real debt, and this waiver drops it to the
# semantic pass. Waiving it is still the better trade, because the alternative is standing
# false positives on every rule doc, changelog entry and README line that names the pattern,
# and none of those can be rewritten without deleting the sentence that does the work.
#
# `ban.suppression` IS DELIBERATELY ABSENT, though the carve-out catalog once listed it. A
# `.md` file can only ever be scanned in TEXT mode (`scan_mode` returns 'full' for
# SCAN_EXTS alone), and `check_suppression` runs only in `run_all`, so the rule cannot fire
# on prose at all. A waiver for it would be a branch nothing can take.
_PROSE_WAIVED = frozenset({'clean.removed-comment', 'clean.debt-marker'})


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


def is_prose(rel_path):
  return _matches_any(rel_path, PROSE_GLOBS)


def is_append_only(rel_path):
  return rel_path.rsplit('/', 1)[-1] in APPEND_ONLY_BASENAMES


def is_prompt_template(rel_path):
  head, sep, base = rel_path.rpartition('/')
  if not sep:
    return False
  for pattern in PROMPT_TEMPLATE_GLOBS:
    pattern_head, _, pattern_base = pattern.rpartition('/')
    if head == pattern_head and fnmatch(base, pattern_base):
      return True
  return False


def rule_exempt(rule_id, rel_path):
  """True when `rule_id` does not apply to `rel_path` per the carve-out catalog.

  EVERY WAIVER HERE IS FROM A RULE, NEVER FROM THE SCAN. The file is still walked to,
  still opened, still counted in `files_scanned`, and every other rule still runs against
  it; only the finding is dropped, by `_finalize` in audit_scan.py. A carve-out applied
  earlier, by keeping a path out of the scanned set, would be indistinguishable from
  coverage in the report, which is the failure this scanner's counter families exist to
  refuse.
  """
  if rule_id == 'ban.inline-type' and not applies_inline_type(rel_path):
    return True
  # Two carve-outs, one rule, and they do NOT mean the same thing. An append-only record
  # has no bound at all here; a prompt template has a HIGHER one that only
  # scripts/validate-dod.d/80-file-size-caps.sh can express, and dropping the finding is
  # the closest this scanner's single-`max_file_lines` shape can get to it. The block
  # comment on PROMPT_TEMPLATE_GLOBS states that residual in full.
  if rule_id == 'cap.file-lines' and (is_append_only(rel_path) or is_prompt_template(rel_path)):
    return True
  if is_test(rel_path) and rule_id in _TEST_WAIVED:
    return True
  return is_prose(rel_path) and rule_id in _PROSE_WAIVED

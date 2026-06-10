---
name: lawkeeper
description: >-
  Audit an existing or new codebase against its engineering laws — hard caps
  (function/file/param/nesting), zero-tolerance bans (lint suppressions, non-null `!`, empty
  catches, bare Error throws, secrets, inline types in scoped modules), plus DRY, naming,
  layering, single-responsibility, folder-structure, and file-scoping rules. Reads the rule
  set at audit time from the project's OWN harness (.claude/rules, ban-patterns.txt,
  CLAUDE.md/AGENTS.md), stricter-wins fallback to global doctrine; runs a deterministic
  scanner plus semantic subagents; reports every finding with file:line by category/severity,
  then fixes them one at a time with your approval. Use when the user wants to check, audit,
  validate, or enforce engineering rules/standards/conventions across a project — e.g.
  "audit my code against our rules", "does this follow CLAUDE.md", "find all rule violations",
  "validate the architecture". FULL-CODEBASE sweep — NOT for generating a project's
  CLAUDE.md/rules, NOT for a single PR diff (use code-review).
---

# lawkeeper

Audit a whole project against the engineering laws it is supposed to obey, then fix the
violations with the maintainer in the loop. It reads the rules the project already documents
(or the global doctrine) and checks the code against them — it does not author the rules, it
enforces them.

## Operating principles

- **Read the rules, never restate them.** The laws already live in the project's harness
  and the maintainer's global doctrine. This skill resolves the effective rule set from
  those canonical sources at audit time. It does not ship its own copy of the rules — a
  validator that duplicated the rules would itself break DRY.
- **Stricter wins.** Global doctrine is the floor everywhere. A project's `CLAUDE.md` may
  *add* rules (e.g. a folder topology) or *tighten* a cap; it may not relax a ban. On any
  conflict between global and project, apply the stricter rule.
- **Carve-outs are first-class.** An auditor that flags documented exceptions teaches its
  user to ignore it. Exemptions (test files, generated code, schema/migration files,
  do-not-extract literal floors) are detected per project and applied before anything is
  reported. See `references/carve-outs.md`.
- **Evidence over assertion.** Mechanical violations come from a deterministic script with
  exact `file:line`. Judgment calls come from subagents that quote the rule and the code.
  Nothing is reported on a hunch; every finding is verifiable.
- **Report first, fix on approval.** The audit produces a grouped report. Fixes happen one
  finding (or one tight cluster) at a time through the §5.2 options protocol — describe the
  problem, present 2-3 options, recommend one, ask before writing. Nothing is auto-rewritten.
- **The audit obeys the laws it checks.** Every artifact this skill writes (scripts,
  reports, fixes) holds to the same caps and bans it enforces.

Scripts and references live in this skill's own directory, `<skill-dir>`. Resolve `<skill-dir>`
from the `Base directory for this skill:` line surfaced when the skill loads; if that line is
absent, fall back to `find "$HOME/.claude" "$HOME/Code" -type f -path "*/skills/lawkeeper/SKILL.md"
| head -1 | xargs dirname`. Reference each file when the phase that needs it arrives — do not
preload them.

## Phase 0 — Preflight

1. Confirm the target project root (default: cwd). If invoked from `~` or a non-project
   directory, ask which project to audit.
2. Check git state. A clean (or committed) working tree makes every proposed fix reversible.
   Note it; recommend a checkpoint before the remediation phase. Do not hard-block.
3. A brand-new or empty project is fine — it simply produces few findings. No special mode.

## Phase 1 — Resolve the effective rule set (canonical-source)

Build the rule set the audit will enforce, in this precedence (stricter wins):

1. **Project harness** (strongest signal of intent): `.claude/rules/*`, `.claude/hooks/ban-patterns.txt`, root + `.claude/` `CLAUDE.md`, `AGENTS.md`, plus `.cursorrules` / `.github/copilot-instructions.md` if present.
2. **Global doctrine** (the floor): `~/.claude/CLAUDE.md` and any always-on hard-caps hook.

Extract:
- **Caps** — function lines, params, nesting, file lines. Default floor: 40 / 3 / 3 / 500.
- **Ban tokens** — read `ban-patterns.txt` verbatim if present (grep-ERE format); the
  scanner is handed this file so the bans are the *project's*, not a hardcoded duplicate.
- **Folder topology** — any documented layout (tiers, module skeleton, type-directories,
  where schema/migrations/errors/constants live). This drives the structure checks.
- **Project carve-outs** — generated-file conventions, `template-reference/`, FE
  react-refresh / typed-route exceptions, do-not-extract floors.

Produce a short **effective-ruleset** summary (caps, ban count, topology source, carve-outs)
and show it before scanning, so the maintainer can confirm you are enforcing the right rules.
`references/rule-catalog.md` maps every rule_id to its category, severity, detection engine,
and canonical source.

## Phase 2 — Deterministic scan (mechanical, exact)

Run the bundled scanner through the **shell primitive** — do not hand-derive these checks. The
scanner is a Python program, so this is the one phase that assumes a `python3` interpreter on
PATH (the only host dependency lawkeeper adds beyond the shell itself; see the host-interpreter
note in `skills/hackify/references/runtime-adapters.md`). Pass the resolved config:

```bash
python3 <skill-dir>/scripts/audit_scan.py <project_root> \
  --max-file-lines <cap> \
  --ban-patterns <project>/.claude/hooks/ban-patterns.txt   # omit if none
```

It emits one JSON object: `{schema_version, root, config, stats, findings[]}`. Each finding
carries `rule_id, category, severity, confidence, file, line, end_line, message, snippet,
fixable`. It covers what a regex matches exactly — file line-count and the token bans
(suppressions, empty catch, bare Error, non-null `!`, inline type in scoped modules, hardcoded
secrets). Secrets are redacted in the snippet. The scanner already applies the path carve-outs.
Most findings are `confidence: exact`; the two marked `confidence: syntactic` (`ban.bare-error`,
`ban.inline-type`) are matched exactly but need a one-step check before you act — is the `throw`
in domain code, does the type have 2+ props.

**If `python3` is absent** — rare on a dev machine, possible on a locked-down best-effort
runtime — say so in the report and fall through to the semantic pass: the Phase 3 judgment
rules are interpreter-free and still run. Never drop the deterministic checks silently; an
audit that skips a whole engine without recording it reads as "clean" when it isn't.

### Match the engine to the stack

The bundled scanner's full check suite is ECMAScript-family only. Pick the path by the
project's primary language (from Phase 1 / a quick manifest glance):

- **TS/JS family** — run the scanner as above; full suite applies.
- **Mixed repo with non-JS files you still want line-capped + project-banned** — add
  `--text-only-ext .py --text-only-ext .go` (etc.). Those files get ONLY the file-line cap and
  the project's `ban-patterns.txt`; the JS-construct checks are skipped so nothing misfires.
- **A non-JS stack you want audited deterministically (Python, Go, Rust, Java, …)** — generate
  an **on-demand scanner** for that language, following `references/porting-scanner.md`: it
  mirrors the bundled scanner's concepts (a language-appropriate comment/string masker, that
  language's suppression / empty-catch / bare-throw / inline-type analogs, the universal secret
  regexes, the same path carve-outs) and emits the SAME finding JSON schema. Write it under a
  fresh temp dir (`mktemp -d`), run it, parse its JSON exactly like the bundled scanner's, and
  delete the temp dir in Phase 6. These are ephemeral, single-session scripts — never written
  into the audited project, never left behind.

## Phase 3 — Semantic pass (judgment)

The scanner deliberately stops where precision would require a real parser or understanding.
**First reuse what the project already has:** if `.claude/agents/` holds installed review
agents (`security-auditor`, `performance-auditor`, `cleanup-scout`, `code-reviewer`), dispatch
THOSE for their concern rather than re-deriving it — they encode the project's exact rules.
Fall back to the built-in concern prompts only where an agent is absent. Then fan out subagents
(one per concern, in a single message), reading `references/semantic-pass.md` for the per-rule
prompt, severity, and — critically — the exemption floors each must honor:

- **Structure caps** — function length, parameter count, nesting depth. PREFER the project's
  own linter when configured (ESLint `max-lines-per-function` / `max-params` / `max-depth`,
  Biome equivalents) — it is exact. Otherwise a subagent estimates and flags candidates.
- **DRY** — duplicated logic that should reuse an existing helper/service/util.
- **Clean-architecture layering** — controllers reaching into data access, services importing
  the HTTP framework, presentation holding business logic, cross-feature reach-ins.
- **Controller purity** — one method = one service call; no conditionals / response shaping /
  try-catch / transformation.
- **Naming & explicitness** — names that describe what-not-why, nested ternaries, deep nesting.
- **Single responsibility** — units that need "and" to describe them; merged command jobs.
- **Folder-structure conformance** — files placed against the documented topology; types/enums/
  constants without their dedicated home.
- **Dead code** — methods/exports/registrations with zero callers.
- **Magic literals** — un-named strings/numbers, honoring the do-not-extract floors and the
  schema/migration off-limits rule (`references/carve-outs.md`).
- **Security** — injection (string-concat SQL/shell), missing authz on routes, unvalidated
  boundary input, non-idempotent migrations, unsafe deserialization/SSRF, PII-in-logs.
- **Performance** — N+1 queries, O(n²) nesting, blocking I/O on request paths, unbounded
  memory, FE re-render thrash (diff/hot-path scoped — do not noise-flag a whole tree).
- **Testing** — service methods/guards/significant logic with no test; happy-path-only coverage.
- **SOLID & YAGNI** — OCP/LSP/ISP/DIP breaches and speculative abstraction (concrete instances
  only; SRP/DRY are covered above).
- **Cross-file cleanup** — unused dependencies, unreferenced files, dead feature flags, orphaned
  env vars, commented-out code blocks (the deterministic scanner already flags `// removed:` and
  ownerless TODO/FIXME).

Each subagent returns structured findings in the same shape as the scanner (rule_id, file,
line, severity, evidence) so Phase 4 can merge them uniformly. Scope the pass to the whole
tree by default, or to a path/changed-set if the user asked for that.

## Phase 4 — Aggregate & report

Merge deterministic + semantic findings, drop duplicates (same file+line+rule), and render
the report from `assets/report-template.md`: a header with totals per category and severity,
then findings grouped Folder-Structure / Code-Styles / File-Scoping, each with `file:line`,
the rule, the evidence, and the fix posture. Lead with critical/security findings. Present it
and stop — this is the natural review point (§5.3). Do not start fixing unprompted.

## Phase 5 — Remediate (propose-confirm per finding)

Work findings in severity order. For each finding or tight cluster, follow §5.2: state the
problem with `file:line`, present 2-3 concrete options (including "do nothing" where
reasonable) with effort/risk/impact, recommend the first, and ask before writing. Batch the
questions — group similar findings into one **wizard tool** round (≤4 questions), numbered by
issue and lettered by option, recommended option first. Apply only approved fixes, using the
project's existing patterns (a fix must read as if the original author wrote it). After each
batch, re-run the relevant test/lint/typecheck legs to prove the fix is clean.

Reality check on fixability: splitting a 500-line file, extracting a function, removing a `!`,
or filling an empty catch are real changes that need judgment, not blind rewrites — they all
go through propose-confirm. Only a tiny set (extract a magic literal, drop a dead import,
delete a `// removed:` comment) is trivially safe, and even those are shown before applying.

When a finding's fix is **substantive on its own** — splitting a 500-line file, unwinding an
N+1, layering surgery — name that it deserves more than an inline propose-confirm: offer the
maintainer a compressed clarify → implement → verify pass for it rather than folding a real
structural change into the audit. lawkeeper never calls sibling skills, so this is a framing
you offer (and a separate task the user opts into), not a handoff you perform.

## Phase 6 — Verify & summarize

Re-run the deterministic scanner to confirm fixed findings are gone and none were introduced.
Run the project's full verification triad (lint / typecheck / test) on the touched scope. Print
a summary table: findings by category before/after, what was fixed, what was deferred (and why),
and any rule the maintainer chose to waive. If the project has no edit-time enforcement (a
PreToolUse hook that blocks banned tokens as they are written), suggest adding one so new
violations are prevented rather than found later.

**Clean up.** Delete any on-demand scanner temp dir created in Phase 2 (`rm -rf` the `mktemp -d`
path). The audit leaves nothing behind in the project or in temp — only the report and the
approved fixes.

## Notes

- Reference scripts/assets via `<skill-dir>` (resolved at the top of this file from the
  `Base directory for this skill:` line) — never hardcode an absolute user path.
- **Language reach.** The bundled scanner runs its full check suite on the ECMAScript family
  (`.ts/.tsx/.js/.jsx/.mts/.cts/.mjs/.cjs`). For any other extension passed via
  `--text-only-ext`, it runs ONLY the language-agnostic checks — file-line cap and the
  project's `ban-patterns.txt` — because the JS lexer and the built-in token bans would
  misfire on other syntax. Deep deterministic coverage of a non-JS stack is done by the
  on-demand scanner from Phase 2 (`references/porting-scanner.md`). The workflow and the
  semantic pass are fully language-agnostic.
- Keep the audit honest about coverage: if you scope to a subtree, run text-only on a stack,
  or skip the semantic pass, say so in the report. Silent truncation reads as "clean" when it
  isn't.

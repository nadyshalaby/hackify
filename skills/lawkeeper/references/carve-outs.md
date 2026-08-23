# Carve-outs (the exemptions, and how to detect them per project)

An auditor that flags a documented exception trains its user to ignore it. Encoding the
carve-outs IS the core feature, not an afterthought. Two kinds: **path carve-outs** (which
files a rule skips, already enforced by `scripts/exemptions.py`) and **semantic floors**
(which constructs a Phase-3 subagent must leave alone). Verify per project which apply by
checking for the files/dirs/config, do not assume any one project's layout.

## Path carve-outs (enforced by the scanner)

The scanner already applies these. They live in `scripts/exemptions.py` as defaults; extend
them per project via `--extra-generated <glob>` when a project uses a different convention.

| Exempt set | Rules waived | Detect by |
|---|---|---|
| Test files (`*.test.*`, `*.spec.*`, `**/tests/**`, `**/__tests__/**`) | suppression, non-null, inline-type, bare-error | path glob |
| Generated (`*.gen.ts`, `*.d.ts`, `*.generated.*`, `routeTree.gen.ts`) | ALL | path glob + generated-header comment |
| Migrations (`**/migrations/**`) | ALL (off-limits to refactor) | path glob |
| `template-reference/` and other frozen demo dirs | ALL | dir name; confirm in `tsconfig`/lint ignore |
| Dependencies / build output (`node_modules`, `dist`, `.next`, …) | ALL (not walked) | dir name |
| Inline-type ban scope | applies ONLY to `*.service.ts`, `*.controller.ts`, `*.routes.ts(x)`, `*.middleware.ts`, `*.guard.ts` | basename glob |

### Agreed, and NOT yet wired into `scripts/exemptions.py`

Two carve-outs with no code behind them yet. They sit below the table rather than inside it
because that table's promise is "the scanner already applies these", and a rule doc that
overstates its own enforcement is the same defect as an auditor that flags a documented
exception. Whoever wires them edits `_TEST_WAIVED` / `rule_exempt` in `scripts/exemptions.py`;
the `rule_id`s and globs below are the whole specification, no judgment needed.

| Exempt set | Rules waived | Detect by |
|---|---|---|
| Detection fixtures in test files | `clean.removed-comment`, `clean.debt-marker` | the existing `TEST_GLOBS`, add both IDs to `_TEST_WAIVED` |
| Rule documentation, prose that quotes a pattern in order to define it | `clean.removed-comment`, `clean.debt-marker`, `ban.suppression` | `*.md` / `*.mdx`; markdown reaches the scanner only when a caller passes `--text-only-ext .md`, and in that mode only the file cap, project bans and these hygiene rules can fire |

**Why the asymmetry existed.** The four waivers in the test-file row above are DOCTRINE
carve-outs: a test may legitimately do the banned thing, `@ts-expect-error` over deliberately
invalid input, a `!` on a fixture, an inline type, a bare `Error`. `clean.removed-comment` and
`clean.debt-marker` landed later as HYGIENE rules and nobody revisited the test row, so the
scanner flags the exact strings that prove it works: `test_audit.py:148,149` are the two
`// removed:` fixtures, `:153,154,173` the `TODO` / `FIXME` ones, and `law-scout.md:23` is the
sentence that documents the `// removed:` rule to a human. Eight standing false positives, all
of them the same shape as the floor already recorded below: a file whose job is to DEFINE or
DETECT a pattern has to be allowed to contain it.

### Append-only files (waived from `cap.file-lines`, nothing else)

A changelog grows by one entry per release and shrinks for no reason at all. "Split by
responsibility", the remedy the 500-line cap exists to force, has nothing to act on: there is
no second responsibility in it, and it is read by jumping to a heading rather than end to end.
So append-only records are waived from `cap.file-lines` and from that rule only.

| Exempt set | Rules waived | Detect by |
|---|---|---|
| Append-only records | `cap.file-lines` | exact basename. This repo waives `CHANGELOG.md` and nothing else. A project extends the list by naming its own release-history file (a `CHANGELOG`, `HISTORY` or `NEWS` file, extension included), never by matching a pattern |

Three constraints on any implementation of it, mechanical enough to check:

- **Named, never pattern-matched.** The waiver list is exact basenames a reviewer can read in
  one line. `*.md` or "docs are exempt" would take README.md and every reference with it.
- **Waived from the CAP, never from the SCAN.** An exempt file is still opened, still counted,
  and still reported as exempt. A `find`-level exclusion lets it leave the scanned set in
  silence, which is indistinguishable from coverage.
- **The list carries its own length, and stale entries surface.** An entry whose file has been
  split, renamed or deleted has to be noticed rather than outliving its reason quietly.

`scripts/validate-dod.d/80-file-size-caps.sh` is the mechanical half of this in the hackify
repo (`CAP_APPEND_ONLY`, pinned at one entry, `CHANGELOG.md` at 944 lines). The scanner does
not implement it: `cap.file-lines` fires on any `.md` a caller feeds it through
`--text-only-ext .md`, so a `/lawkeeper` run using that flag still needs this row honored by
hand until `exemptions.py` learns it.

Runtime-detect project specifics before scanning:
- **Generated files**, grep the first lines of candidates for `@generated`, `eslint-disable`,
  `DO NOT EDIT`, `This file is auto-generated`. Pass matches as `--extra-generated`.
- **Frozen/vendored dirs**, read `tsconfig.json` `exclude` and the lint ignore file; anything
  excluded from typecheck/lint is excluded from the audit too.
- **Schema files**, `**/schema.ts` and `**/*.schema.ts` are off-limits to magic-literal
  extraction (Drizzle/Zod builders). They are not scoped-type files, so the inline-type ban
  already skips them.

## Semantic floors (Phase-3 subagents must honor)

These are the DO-NOT-EXTRACT and DO-NOT-FLAG rules for the judgment pass. A subagent that
flags one of these is producing noise. Pass this list into every relevant subagent prompt.

### Magic-literal extraction floors (leave these inline)
- Identity values: `0`, `1`, `-1`, `''`, `true`, `false`.
- Tailwind / CSS class strings.
- Zod-builder arguments: `z.literal(...)`, `z.enum([...])`, and similar schema-builder args.
- Object keys; SQL fragments; template literals containing `${…}`.
- Import specifiers; regex literals; union-type member literals.
- Drizzle schema defaults. **`**/schema.ts` and `**/migrations/**` are entirely off-limits.**
- Lint-ban tokens themselves (`biome-ignore`, `@ts-ignore`, …) stay literal, they ARE the
  strings the bans grep for.

### Frontend-specific floors (when the project is a TS frontend)
- **TanStack Router typed paths** consumed by `createFileRoute`, `<Link to>`, `navigate`,
  `redirect`, `validateSearch` stay inline, extracting breaks route type-inference. (Axios
  endpoint paths ARE extractable.)
- **react-refresh carve-out (narrowed)**, a component that declares its own inline
  `const FormSchema = z.object({…})` may keep that schema's `z.infer` value type and field-prop
  interfaces referencing `FormValues`/`Control<FormValues>` in-file; relocating ONLY the type trips
  `react-refresh/only-export-components`. The clean resolution that satisfies the one-construct rule
  (§3.5) is to relocate BOTH the runtime schema and its inferred type to dedicated files, the
  component then exports no runtime value, so react-refresh stays green. So the inline carve-out
  applies ONLY when a project deliberately keeps the runtime schema in-file for locality; otherwise an
  inline component schema IS a finding (`scope.one-construct`). Every OTHER type still leaves the impl file.
- `routeTree.gen.ts` is generated, never hand-edit, never flag.

### Bare-error nuance
`ban.bare-error` is "in DOMAIN code." The scanner flags every `throw new Error(` because it
cannot tell domain from a script/CLI/test. In Phase 3 / remediation, confirm the file is
domain code before treating it as a real violation; a one-off script throwing `Error` is a
weak finding.

## When a project deliberately relaxes a rule

Stricter wins, so a project may TIGHTEN but not relax a global ban. If a maintainer states an
explicit, coherent exception (e.g. "we allow `console.error` in the FE logger"), record it as
a waiver in the report rather than silently dropping it, the waiver is auditable, a silent
skip is not.

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
| Test files (`*.test.*`, `*.spec.*`, `**/tests/**`, `**/__tests__/**`) | suppression, non-null, inline-type, bare-error, `clean.removed-comment`, `clean.debt-marker` | path glob (`TEST_GLOBS` / `_TEST_WAIVED`) |
| Prose (`*.md`, `*.mdx`) | `clean.removed-comment`, `clean.debt-marker` | path glob (`PROSE_GLOBS` / `_PROSE_WAIVED`) |
| Append-only records (`CHANGELOG.md`) | `cap.file-lines` ONLY | exact basename (`APPEND_ONLY_BASENAMES`) |
| Generated (`*.gen.ts`, `*.d.ts`, `*.generated.*`, `routeTree.gen.ts`) | ALL | path glob + generated-header comment |
| Migrations (`**/migrations/**`) | ALL (off-limits to refactor) | path glob |
| `template-reference/` and other frozen demo dirs | ALL | dir name; confirm in `tsconfig`/lint ignore |
| Dependencies / build output (`node_modules`, `dist`, `.next`, …) | ALL (not walked) | dir name |
| Inline-type ban scope | applies ONLY to `*.service.ts`, `*.controller.ts`, `*.routes.ts(x)`, `*.middleware.ts`, `*.guard.ts` | basename glob |

**A waiver is from a RULE, never from the SCAN.** Every row above is applied by
`rule_exempt` at the last step, after the file has been walked to, opened, read and checked.
The file stays in `files_scanned` and every rule NOT named in its row still fires against it;
only the matching finding is dropped. A carve-out applied earlier, by keeping a path out of
the scanned set, reads as coverage in the report, and telling that apart from a real clean
scan is exactly what the counter families in `audit_scan.py` exist to make possible.

### Why test files waive six rules and not four

The first four are DOCTRINE carve-outs: a test may legitimately do the banned thing, a
suppression over deliberately invalid input, a `!` on a fixture, an inline type, a bare
`Error`. `clean.removed-comment` and `clean.debt-marker` are here for a second reason, which
is that a fixture asserting the scanner detects `// TODO` has to contain `// TODO`. They
landed later than the other four as hygiene rules and nobody revisited the test row, so the
scanner flagged the exact strings that prove it works.

**The residual, written down rather than smoothed over.** A genuine ownerless debt marker in
an ordinary test file is no longer reported by the deterministic scan and reaches only the
semantic pass. That is the price of a path-based rule, and it is the cheaper half of the
trade: both rules are `low` severity `cleanup`, while a false positive nobody can rewrite
away trains its reader to skim the whole report.

### Why prose waives the two hygiene markers

Both markers require a COMMENT OPENER, and markdown has none of the four. `#` opens a heading
there and a leading `*` opens a bullet, while `//` and `/*` reach a `.md` file only inside a
code span, where the pattern is being QUOTED in order to define it. Every match in this repo
is that shape: a backticked `// removed:` in a rule doc, in a changelog entry describing the
rule, and in a README feature list. A release note and a reference page are the same case, not
two, and neither can be rewritten without deleting the sentence that does the work.

**The residual.** A `# TODO` heading or a `* TODO` bullet in a design doc IS arguably real
debt, and this waiver drops it to the semantic pass.

**`ban.suppression` is deliberately NOT waived here**, though an earlier draft of this row
listed it. A `.md` file can only ever be scanned in TEXT mode (`scan_mode` returns `full` for
`SCAN_EXTS` alone), and `check_suppression` runs only in `run_all`, so the rule cannot fire on
prose at all. A waiver for it would be a branch nothing can take. In text mode only the file
cap, project bans and these two hygiene rules can fire.

### Append-only files (waived from `cap.file-lines`, nothing else)

A changelog grows by one entry per release and shrinks for no reason at all. "Split by
responsibility", the remedy the 500-line cap exists to force, has nothing to act on: there is
no second responsibility in it, and it is read by jumping to a heading rather than end to end.
So append-only records are waived from `cap.file-lines` and from that rule only. A project
extends the list by naming its own release-history file (a `CHANGELOG`, `HISTORY` or `NEWS`
file, extension included), never by matching a pattern.

Three constraints on it, mechanical enough to check, and where each is enforced:

- **Named, never pattern-matched.** `APPEND_ONLY_BASENAMES` is exact basenames a reviewer can
  read in one line. `*.md`, or "docs are exempt", would take README.md and every reference
  with it. `*.mdx` and `CHANGELOG.mdx` are outside it for the same reason.
- **Waived from the CAP, never from the SCAN.** Covered by the rule above this section: the
  file is still opened, still counted, still checked by every other rule. The shell half also
  prints it through `cap_exempt`; the scanner half keeps it in `files_scanned` and drops the
  finding alone.
- **The list carries its own length, and stale entries surface.** That half is the shell's,
  because it needs the filesystem: `CAP_APPEND_ONLY_EXPECTED` pins the count, and the stale
  sweep reports an entry whose file has been split, renamed or deleted.

`scripts/validate-dod.d/80-file-size-caps.sh` is the mechanical half of this in the hackify
repo (`CAP_APPEND_ONLY`, pinned at one entry). The two lists are cross-checked against each
other by that fragment rather than trusted to match, so adding a file to one and not the other
reddens the validator.

**The two agree on contents and differ on scope, deliberately.** The shell list is compared
against a repo-relative path, so it waives the ROOT `CHANGELOG.md` alone. The scanner compares
BASENAMES, because it is pointed at arbitrary roots, so a monorepo's `packages/*/CHANGELOG.md`
is waived there and would not be here. They coincide at a repo root, which is the only place
the shell check runs.

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

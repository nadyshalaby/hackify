# Carve-outs — the exemptions, and how to detect them per project

An auditor that flags a documented exception trains its user to ignore it. Encoding the
carve-outs IS the core feature, not an afterthought. Two kinds: **path carve-outs** (which
files a rule skips — already enforced by `scripts/exemptions.py`) and **semantic floors**
(which constructs a Phase-3 subagent must leave alone). Verify per project which apply by
checking for the files/dirs/config — do not assume any one project's layout.

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

Runtime-detect project specifics before scanning:
- **Generated files** — grep the first lines of candidates for `@generated`, `eslint-disable`,
  `DO NOT EDIT`, `This file is auto-generated`. Pass matches as `--extra-generated`.
- **Frozen/vendored dirs** — read `tsconfig.json` `exclude` and the lint ignore file; anything
  excluded from typecheck/lint is excluded from the audit too.
- **Schema files** — `**/schema.ts` and `**/*.schema.ts` are off-limits to magic-literal
  extraction (Drizzle/Zod builders). They are not scoped-type files, so the inline-type ban
  already skips them.

## Semantic floors (Phase-3 subagents must honor)

These are the DO-NOT-EXTRACT and DO-NOT-FLAG rules for the judgment pass. A subagent that
flags one of these is producing noise. Pass this list into every relevant subagent prompt.

### Magic-literal extraction floors — leave these inline
- Identity values: `0`, `1`, `-1`, `''`, `true`, `false`.
- Tailwind / CSS class strings.
- Zod-builder arguments: `z.literal(...)`, `z.enum([...])`, and similar schema-builder args.
- Object keys; SQL fragments; template literals containing `${…}`.
- Import specifiers; regex literals; union-type member literals.
- Drizzle schema defaults. **`**/schema.ts` and `**/migrations/**` are entirely off-limits.**
- Lint-ban tokens themselves (`biome-ignore`, `@ts-ignore`, …) stay literal — they ARE the
  strings the bans grep for.

### Frontend-specific floors (when the project is a TS frontend)
- **TanStack Router typed paths** consumed by `createFileRoute`, `<Link to>`, `navigate`,
  `redirect`, `validateSearch` stay inline — extracting breaks route type-inference. (Axios
  endpoint paths ARE extractable.)
- **react-refresh carve-out (narrowed)** — a component that declares its own inline
  `const FormSchema = z.object({…})` may keep that schema's `z.infer` value type and field-prop
  interfaces referencing `FormValues`/`Control<FormValues>` in-file; relocating ONLY the type trips
  `react-refresh/only-export-components`. The clean resolution that satisfies the one-construct rule
  (§3.5) is to relocate BOTH the runtime schema and its inferred type to dedicated files — the
  component then exports no runtime value, so react-refresh stays green. So the inline carve-out
  applies ONLY when a project deliberately keeps the runtime schema in-file for locality; otherwise an
  inline component schema IS a finding (`scope.one-construct`). Every OTHER type still leaves the impl file.
- `routeTree.gen.ts` is generated — never hand-edit, never flag.

### Bare-error nuance
`ban.bare-error` is "in DOMAIN code." The scanner flags every `throw new Error(` because it
cannot tell domain from a script/CLI/test. In Phase 3 / remediation, confirm the file is
domain code before treating it as a real violation; a one-off script throwing `Error` is a
weak finding.

## When a project deliberately relaxes a rule

Stricter wins, so a project may TIGHTEN but not relax a global ban. If a maintainer states an
explicit, coherent exception (e.g. "we allow `console.error` in the FE logger"), record it as
a waiver in the report rather than silently dropping it — the waiver is auditable, a silent
skip is not.

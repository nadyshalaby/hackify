# Code Rules — Always-On

These rules are global, project-agnostic, and load-bearing. They mirror the principles in a typical project-root `CLAUDE.md` — but recompiled here so hackify is self-contained even if those files are absent.

When in conflict with project `CLAUDE.md`, project rules win (more specific). When in conflict between user-global `CLAUDE.md` and a workspace `CLAUDE.md`, the **stricter** rule wins.

---

## Author's reference stack — substitute your own

This file leans on a concrete stack for examples (Bun, Biome, TypeScript, Hono, Drizzle, React, Tailwind). **Substitute your own toolchain freely.** The *principles* — DRY, no inline types, strict layering, edge-case discipline, hard caps, no lint suppressions — apply regardless of stack. When you see `Bun`, read "your package manager"; when you see `Biome`, read "your linter/formatter"; when you see `Hono`/`Drizzle`/`React`, read "your HTTP framework / ORM / UI framework".

The stack-specific paths and commands are illustrative, not prescriptive. Adapt the *patterns* to your codebase.

---

## DRY — Don't Repeat Yourself

DRY is not a guideline. It is a hard requirement.

- Before writing ANY new code, **search** for existing factories, helpers, services, base classes, utilities. If it exists, USE IT.
- If you write the same 3+ lines of logic twice → STOP and extract immediately.
- When fixing a bug, the fix MUST use existing patterns. Inventing new patterns to fix existing code is forbidden.
- Study how similar problems are already solved in this codebase BEFORE writing new code. New code MUST look like it was written by the same author as existing code.

Typical reusable locations in a layered TypeScript codebase:

- **Backend:** `src/common/utils/`, `src/common/list/`, `src/errors/`, `src/db/pool.ts`, `src/db/<schema>/schema.ts`, `src/auth/`, `src/config/env.ts`
- **Frontend:** `src/lib/`, `src/lib/list/`, `src/lib/auth-client.ts`, `src/lib/api.ts`, `src/components/ui/` (design-system primitives)

If you import a singleton (`auth`, `api`, `pool`, etc.) — confirm you're using the canonical one. Don't construct a second.

---

## No inline types — name everything ≥2 props

Inline object shapes are BANNED.

- **Any object shape with 2+ properties** → named `interface` or `type`.
- **Any union/intersection used more than once** → named.
- **Function signatures with complex params or returns** → named types for the params object and the return.
- **Callback / handler types** → named type aliases.
- Simple primitives (`string`, `number`, `boolean`) and single-entity generics (`Promise<User>`) are fine inline.

**Where named types live:**

- **Backend module-level:** `<module>/interfaces/<module>.types.ts` or `<module>/dto/<action>.dto.ts`
- **Backend cross-module:** `src/common/types/`
- **Frontend feature-level:** `src/features/<feature>/types.ts`
- **Frontend cross-feature:** `src/lib/types/` (rare; prefer feature-local)

**Forbidden:** defining an `interface` or `type` (≥2 props) inside `*.routes.ts`, `*.routes.tsx`, `*.service.ts`, `*.middleware.ts`, `*.guard.ts`. Extract to the right folder.

---

## Clean architecture — strict layer separation

Dependencies flow inward. Layers do not leak.

### Backend (HTTP framework, e.g. Hono / Express / Fastify)

| Layer | Lives in | Allowed | Forbidden |
|---|---|---|---|
| **Presentation** | `*/routes/*.ts`, `*/middleware/*.ts` | route wiring, request parsing (Zod), one service call | business rules, direct DB, multi-step orchestration, `try/catch` for control flow |
| **Domain** | `<module>/<module>.service.ts`, hooks, validators | all business logic; owns DB access via clients passed in | importing the HTTP framework, reading the request object, route paths, HTTP status codes |
| **Infrastructure** | `db/`, transport adapters, factories | external clients, transports, factories | business decisions |

Routes are pure delegation: **one handler = one service call + one response**. Zero conditionals beyond request validation.

### Frontend (React / similar)

| Layer | Lives in | Allowed | Forbidden |
|---|---|---|---|
| **Routes** | `src/routes/**` | route definitions, loaders that delegate to a feature hook | business logic, fetch calls inline, useState orchestration |
| **Features** | `src/features/<feature>/` | screens, forms, feature-local components and hooks | reaching into another feature's internals, importing route files |
| **Components** | `src/components/` | dumb UI; props in / DOM out; one clear responsibility | API calls, auth-client calls, useNavigate/useRouter |
| **Lib** | `src/lib/` | framework glue, singletons, formatters, error mappers | feature logic, route-specific code |
| **Stores** | `src/stores/` | cross-tree UI state (Zustand, Redux, etc.) | session/auth state (the auth library owns this) |

---

## Explicit over clever

- No magic. No implicit behavior. No "smart" code that requires a comment.
- Name things for what they DO, not what they ARE. If code needs a comment to explain, rewrite the code.
- Guard clauses over nested conditionals. Early returns over deep nesting.
- No ternary chains. No nested ternaries. One simple `condition ? a : b` or use `if/else`.

---

## Single responsibility

- One function does one thing.
- One service owns one domain.
- One module owns one bounded context.
- A seed command seeds. A migrate command migrates. **Do NOT merge responsibilities.**
- If a command has a prerequisite, validate and give a clear error — do NOT silently run the prerequisite.

When in doubt, the simpler approach is correct.

---

## Edge cases — handle MORE, not fewer

- null, undefined, empty arrays, empty strings, empty objects
- Concurrent access, partial failures
- Locale / i18n (RTL languages, character encodings, dates, numbers)
- Boundary conditions (off-by-one, ranges)
- Permission denied / unauthenticated
- Network timeout, retry, idempotency

If something CAN go wrong, write code that handles it. Don't hope.

---

## Hard caps (zero tolerance)

- ≤ **40 lines** per function/method
- ≤ **3 parameters** (group into interface/DTO if more)
- ≤ **3 levels of nesting** (guard clauses, early returns)
- ≤ **500 lines** per file
- **0 lint suppressions** — no `biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error`. Sole exception: `@ts-expect-error` in test files for deliberately invalid input, with a comment explaining WHY.
- **0 non-null `!`** in production code
- **0 empty catches** (`catch (e) {}` is unconditionally banned)
- **0 inline `interface`/`type` blocks ≥2 props** in `*.routes.ts`, `*.service.ts`, `*.middleware.ts`
- **0 bare `Error` throws** in domain code — use named domain error classes from `src/errors/` (backend) or named `Error` subclasses (frontend)

---

## Null safety

- Never use `!` (non-null assertion) in production code.
- Handle `null` / `undefined` explicitly with guard clauses or optional chaining.
- Return `null` for "not found." Throw exceptions for "should not happen."

---

## Error handling

- Throw domain-specific exceptions, not generic `Error`.
- Never swallow exceptions. Catch → log or rethrow. No other option.
- Never `catch (e) {}`.
- HTTP errors use the framework's exception classes.

---

## Security

- Never hardcode API keys, secrets, or credentials.
- Never commit `.env` or any file containing secrets. `.env.example` is the only env file in version control.
- Validate ALL user input at system boundaries (Zod for HTTP, runtime checks for IPC).
- Sanitize file paths to prevent directory traversal.
- Use parameterized queries — NEVER string-concatenate SQL.
- Platform-specific secret keys (e.g. Apple `.p8` push keys, service-account JSON) live under a gitignored `src/config/keys/` directory or outside the repo. Test fixtures under `test/fixtures/**` are the only such files committed.

---

## Migrations — idempotent

- Handle both existing state (with old tables) AND fresh state (without old tables).
- Always guard with existence checks (`information_schema.tables`) before reading from tables that may not exist.
- Cross-schema references must check the target table exists before joining.

---

## Type & interface placement (recap)

BANNED: defining `interface` or `type` inside `*.service.ts`, `*.controller.ts`, `*.guard.ts`, `*.routes.ts`, `*.middleware.ts`. Extract.

---

## Dead code prevention

- Verify every method has at least one caller.
- Remove unused service methods, module imports, entity registrations.
- Stub services with zero callers and empty modules MUST be deleted.

---

## Structural rules (frequent gotchas)

- **Entity class name uniqueness** — every ORM entity name is globally unique across schemas (no `Tenant.User` and `Control.User`).
- **No re-exports** — import from canonical source. Never re-export from a secondary location.
- **Service scope awareness** — request-scoped services CANNOT be injected into singletons (cron jobs, event handlers, queue processors). Create dedicated singleton services for cross-scope.
- **Shared utility extraction** — utilities live in shared dirs (`src/common/utils/` backend, `src/lib/` frontend). Search before adding.
- **Config factory reuse** — never inline a config a factory already provides.
- **Module import hygiene** — only import modules whose services you actually inject from.
- **Global type augmentation** — framework request types are extended ONCE, globally, in a type-declaration file. No local `request` interfaces or `any` casts.
- **Guard-decorator completeness** — every metadata key read by a guard has a corresponding decorator.
- **Environment-variable validation** — every env variable used in code MUST be in the env validation schema. No orphans, no unvalidated env.

---

## Tooling baseline (reference stack — adapt to yours)

- **Package manager:** Bun. (Substitute npm / pnpm / yarn if your project uses one of those — pick ONE and stick with it.)
- **Linter / formatter:** Biome (backend) or ESLint+Prettier (frontend; documented divergence is acceptable when the frontend ecosystem has stronger ESLint plugin support).
- **TypeScript strict mode** + `noUncheckedIndexedAccess`. Backend additionally `exactOptionalPropertyTypes`, `verbatimModuleSyntax`.
- **Validation:** Zod for env, request bodies, schema-driven types.

Biome convention used in this skill's examples: **no semicolons, single quotes, 2-space indent.** Match your project's formatter config; don't fight it.

---

## Comments

- Default to writing **no comments**.
- Only add a comment when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, behavior that would surprise a reader.
- Don't explain WHAT the code does — well-named identifiers already do that.
- Don't reference the current task / fix / callers ("used by X", "added for the Y flow", "handles the case from issue #123") — those belong in the PR description and commit message; they rot.

---

## Anti-patterns to refuse on sight

- "Add error handling later" / "TODO without owner"
- "Fallback for hypothetical future requirements"
- "Backwards-compat shim for code that's never deployed"
- "Half-finished implementation"
- Renaming `_var` → `var` to "use it" (the underscore prefix says "unused"; if it's now used, that's fine — but renaming for cosmetics is noise)
- Re-exporting types "for convenience"
- Adding `// removed: <X>` comments for deleted code (the deletion is in git history)

---

## When in doubt

- The simpler approach is usually correct.
- Read 3 similar examples in the codebase before designing a new pattern.
- Pause and ask the user before introducing an abstraction.
- Pause and ask the user before introducing a new dependency (or any version bump in a major dep).

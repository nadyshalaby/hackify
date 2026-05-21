# Code Rules — Always-On

> **Working principles.** This doc is the deep doctrine. The 4 working principles that
> frame it — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven
> Execution — live at [rules/four-principles.md](four-principles.md). Read that first;
> come back here for the operational rules.

These rules are global, project-agnostic, and load-bearing. They mirror the principles in a typical project-root `CLAUDE.md` — but recompiled here so hackify is self-contained even if those files are absent.

When in conflict with project `CLAUDE.md`, project rules win (more specific). When in conflict between user-global `CLAUDE.md` and a workspace `CLAUDE.md`, the **stricter** rule wins.

---

## Voice — abstract principles, concrete adaptation

This file is written in abstract, ecosystem-neutral voice. Paths, file globs, and role names are placeholders for the equivalent in your stack — substitute freely. Where the text says "package manager," "linter / formatter," "type system," "test runner," "HTTP framework," "ORM," or "UI framework," read your own toolchain.

The *principles* — DRY, no inline types, strict layering, edge-case discipline, hard caps, no lint suppressions — apply regardless of stack. The patterns adapt; the principles do not.

---

## DRY — Don't Repeat Yourself

DRY is not a guideline. It is a hard requirement.

- Before writing ANY new code, **search** for existing factories, helpers, services, base classes, utilities. If it exists, USE IT.
- If you write the same 3+ lines of logic twice → STOP and extract immediately.
- When fixing a bug, the fix MUST use existing patterns. Inventing new patterns to fix existing code is forbidden.
- Study how similar problems are already solved in this codebase BEFORE writing new code. New code MUST look like it was written by the same author as existing code.

Typical reusable locations in a layered codebase:

- **Backend:** common-utility module, list helpers, error catalog, DB pool / client, schema definitions, auth module, env-config module
- **Frontend:** shared lib module, list helpers, auth-client wrapper, API client, design-system primitives

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

- **Backend module-level:** the module's own `interfaces/` or `dto/` folder
- **Backend cross-module:** a shared common-types folder
- **Frontend feature-level:** the feature's own `types` file
- **Frontend cross-feature:** a shared lib-types folder (rare; prefer feature-local)

**Forbidden:** defining an `interface` or `type` (≥2 props) inside any router, service, middleware, guard, or controller module. Extract to the right folder.

---

## Clean architecture — strict layer separation

Dependencies flow inward. Layers do not leak.

### Backend (HTTP framework)

| Layer | Lives in | Allowed | Forbidden |
|---|---|---|---|
| **Presentation** | router and middleware modules | route wiring, request parsing via a schema validator, one service call | business rules, direct DB, multi-step orchestration, `try/catch` for control flow |
| **Domain** | service modules, hooks, validators | all business logic; owns DB access via clients passed in | importing the HTTP framework, reading the request object, route paths, HTTP status codes |
| **Infrastructure** | DB clients, transport adapters, factories | external clients, transports, factories | business decisions |

Routes are pure delegation: **one handler = one service call + one response**. Zero conditionals beyond request validation.

### Frontend (component framework)

| Layer | Lives in | Allowed | Forbidden |
|---|---|---|---|
| **Routes** | the routes tree | route definitions, loaders that delegate to a feature hook | business logic, fetch calls inline, local-state orchestration |
| **Features** | the features tree | screens, forms, feature-local components and hooks | reaching into another feature's internals, importing route files |
| **Components** | the components tree | dumb UI; props in / DOM out; one clear responsibility | API calls, auth-client calls, router-navigation calls |
| **Lib** | the shared lib tree | framework glue, singletons, formatters, error mappers | feature logic, route-specific code |
| **Stores** | the stores tree | cross-tree UI state via a client state-store library | session/auth state (the auth library owns this) |

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

Hard caps are the canonical operational list in [`rules/hard-caps.md`](hard-caps.md) — every cap (size, ban, refuse-on-sight) is defined there. This doc operationalizes the principles that motivate the caps; the caps themselves are not restated here to keep one canonical source.

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
- Validate ALL user input at system boundaries (schema validator for HTTP, runtime checks for IPC).
- Sanitize file paths to prevent directory traversal.
- Use parameterized queries — NEVER string-concatenate SQL.
- Platform-specific secret keys (push-notification keys, service-account JSON, etc.) live under a gitignored keys directory or outside the repo. Test fixtures under a dedicated test-fixtures tree are the only such files committed.

---

## Migrations — idempotent

- Handle both existing state (with old tables) AND fresh state (without old tables).
- Always guard with existence checks (`information_schema.tables`) before reading from tables that may not exist.
- Cross-schema references must check the target table exists before joining.

---

## Type & interface placement (recap)

BANNED: defining `interface` or `type` inside any service, controller, guard, router, or middleware module. Extract.

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
- **Shared utility extraction** — utilities live in shared directories (a common-utils tree on the backend, a lib tree on the frontend). Search before adding.
- **Config factory reuse** — never inline a config a factory already provides.
- **Module import hygiene** — only import modules whose services you actually inject from.
- **Global type augmentation** — framework request types are extended ONCE, globally, in a type-declaration file. No local `request` interfaces or `any` casts.
- **Guard-decorator completeness** — every metadata key read by a guard has a corresponding decorator.
- **Environment-variable validation** — every env variable used in code MUST be in the env validation schema. No orphans, no unvalidated env.

---

## Tooling baseline (adapt to your stack)

- **Package manager:** pick ONE and stick with it. Lockfile committed.
- **Linter / formatter:** pick ONE per surface (backend, frontend) and enforce it in CI. Documented divergence between surfaces is acceptable when ecosystem support diverges.
- **Type system:** maximally strict mode — opt in to every safety flag your type checker offers (no implicit-any, no unchecked indexed access, exact optional properties).
- **Validation:** a single schema-validator library for env, request bodies, and schema-driven types.

Match your project's formatter config; don't fight it.

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

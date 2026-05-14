# Engineering Hard Caps — Always-On

Injected into every prompt by hackify's `UserPromptSubmit` hook. Zero-tolerance, project-agnostic. Deeper doctrine lives in `rules/code-quality.md` (skill-loaded on demand).

## Size caps

- **≤ 40 lines** per function/method — extract helpers if longer.
- **≤ 3 parameters** — group into a named interface/DTO if more.
- **≤ 3 levels of nesting** — guard clauses and early returns over deep nesting.
- **≤ 500 lines** per file — split by responsibility.

## Bans (zero tolerance)

- **0 lint suppressions** — no `biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error` in production. Sole exception: `@ts-expect-error` in test files for deliberately invalid input, with a comment explaining WHY.
- **0 non-null `!`** assertions in production code.
- **0 empty catches** — `catch (e) {}` is unconditionally banned.
- **0 inline `interface`/`type` blocks ≥ 2 props** in `*.routes.ts`, `*.service.ts`, `*.middleware.ts`, `*.guard.ts`, `*.controller.ts`.
- **0 bare `Error` throws** in domain code — use named error subclasses.

## Always-on principles

- **DRY** — search before writing. Same 3+ lines twice → extract.
- **Named types** — any object shape with 2+ properties is a named `interface`/`type`.
- **Single responsibility** — one function does one thing; one service owns one domain; one command owns one job.
- **Explicit over clever** — no magic, no implicit behavior, no code that needs a comment to explain.
- **Edge cases** — handle null/undefined/empty/concurrent/partial-failure paths; do not hope.
- **Comments** — default to none; write one only when the WHY is non-obvious.

## Refuse on sight

- "Add error handling later" / "TODO without owner"
- "Fallback for hypothetical future requirements"
- "Backwards-compat shim for code that is never deployed"
- Half-finished implementations
- Re-exporting types "for convenience"
- `// removed: <X>` comments for deleted code (the deletion is in git history)

When the project ships a `CLAUDE.md` at workspace or project root, project rules win for any conflict. Between user-global and workspace `CLAUDE.md`, the **stricter** rule wins.

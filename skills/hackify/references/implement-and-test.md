# Implement & Test — Phase 3 Walkthrough

The implement phase is **wave-based and parallel by default.** Tasks are sorted by priority and topological dependency, grouped into waves where no two tasks share a file, and each wave is dispatched to one foreground agent per task in a single message. Per-task discipline (TDD when applicable, file allowlist, fully green before reporting) is enforced inside each agent's prompt.

The single-task fallback (one agent, one task) only applies when a wave naturally has one task — e.g., a serializing migration step.

---

## Wave loop (the canonical sequence)

```
1.  Update frontmatter:    status: implementing,  current_task: W<n>:T<a>+T<b>+…
2.  Confirm the wave plan from the work-doc Approach. Each wave member's
    file allowlist must NOT overlap with peers in the same wave.
3.  Dispatch ONE Agent per task in the wave, in a SINGLE assistant message
    (parallel Agent tool calls). Each prompt is self-contained per the
    template in references/parallel-agents.md (Implementation wave).
4.  Wait for ALL agents to return.
5.  Verify each agent stayed inside its file allowlist:
       git diff --name-only ⇒ should match the union of allowlists.
6.  Run full project suite ONCE for the wave: test + lint + typecheck. All green.
7.  Self-review against references/review-and-verify.md (parent does this).
8.  Tick all wave Tasks checkboxes. Append one Implementation Log entry per task.
9.  Single commit for the wave (subject covers the wave; body lists task IDs).
10. Advance to wave N+1.
```

Per-agent discipline (enforced inside each agent's prompt — see the template):

```
a.  Decide test mode for the assigned task (test-first / test-after / manual / none).
b.  IF test-first:
       i.   Write the failing test.
       ii.  Run only the file-scoped test. SEE IT FAIL with the right error.
       iii. Confirm the failure is "feature missing", not setup/typo.
c.  Write the minimum code to satisfy the task — NOTHING more.
d.  Run the file-scoped test. See it pass.
e.  Self-review per checklist before reporting done.
f.  REPORT BACK. The parent runs repo-wide verification + commit.
```

Skip steps deliberately and the work-doc Implementation Log records why. **Watching the test fail is non-negotiable when test mode is test-first.** If the agent didn't watch it fail, the agent doesn't know if it tested the right thing.

---

## Picking the test mode

| Task touches | Test mode | Notes |
|---|---|---|
| Pure logic, services, validators, calculators | **test-first** | RED → GREEN → REFACTOR |
| Auth / permissions / token validation | **test-first** | Always — security regressions are worst |
| Bug fixes | **test-first** | Reproduce as a failing test, then fix |
| Branching/conditional logic | **test-first** | Each branch wants its own test |
| HTTP handlers / route wiring | test-after acceptable | Use integration test against ephemeral DB |
| DB migrations | test-first via integration | Run migration up/down on ephemeral DB |
| UI cosmetics / spacing / colors / copy | manual smoke (if user opted in) | Always offer to add an automated test if behavior is testable |
| Form validation, computed UI state | **test-first** | Vitest browser mode — test the behavior |
| Storybook / docs / config-only changes | manual or none | Note rationale in log |
| Pure scaffolding (empty file creation) | none | Note rationale |

The user explicitly opted into "manual testing optional" — but manual is **supplement**, not **replacement** when behavior is testable. Always at least offer the automated test.

---

## TDD — RED / GREEN / REFACTOR (when test-first)

### RED — write the failing test

- **Name describes behavior**, not implementation. `it('rejects expired invitations', …)` not `it('test1', …)`.
- **One thing per test.** If the name has "and" in it, split.
- **Real code, not mocks** — unless the dependency is a network call, paid service, or non-deterministic (clock, randomness, filesystem in some cases). Backend integration tests should run against the **real** database on docker — no mocked DB. Frontend tests use real auth-client behavior where possible (mock at the `@/lib/api` boundary; mock `@/lib/auth-client` only for auth-flow tests).

### Verify RED — watch it fail

Mandatory. Run the test command. Read the output. Confirm:

- The failure message is what you expect (e.g., "function not defined" or "expected 401 to equal 200").
- The failure is **because the feature is missing**, not a typo, not a syntax error, not a setup error.

If the test passes immediately → you wrote a test for behavior that already exists. Fix the test (likely test the new behavior, not the old).

If the test errors (not fails) → fix the error. Re-run. Test must reach the assertion and fail there.

### GREEN — minimal code to pass

- **Just enough.** No "while I'm here" cleanup. No new options on the API. No future-proofing.
- **Bad example.** Test wants `retry(3, fn)`. You implement `retry(opts: { times, backoff, onRetry, jitter })`. Wrong — write `retry(3, fn)` literally, leave the rest until a test demands it.
- **Run the test.** It passes.
- **Run the full suite.** Nothing else regressed.

### REFACTOR — clean up

After green only. Now you can:

- Extract helpers if logic appears 3+ times.
- Improve names (intent over implementation).
- Reorganize file structure.
- Simplify control flow.

**Tests stay green.** Refactor never adds behavior.

---

## Per-stack test commands (reference examples)

Use these **fresh** during Phase 4 verification — paste full output. Adapt the commands to whatever your project's `package.json` (or equivalent) actually defines.

### Backend project (example: Bun + Postgres)

```
bun test                         # all tests (unit + integration + e2e)
bun test path/to/file.test.ts    # single file
bun test --watch                 # watch mode
bun run lint                     # Biome check
bun run lint:fix                 # Biome check --write
bun run typecheck                # tsc --noEmit
bun run db:up                    # start postgres + mailpit (required for integration)
bun run db:migrate:control       # apply public-schema migrations
bun run db:migrate:tenants       # apply tenant migrations to all active tenants
```

Integration tests REQUIRE a real database. **Never mock the DB** — let integration tests catch real-world regressions; unit-test the pure logic separately.

### Frontend project (example: Vite + Vitest + React)

```
bun run test                     # Vitest run (browser mode, headless)
bun run test:watch               # Vitest watch
bun run test:browser             # Vitest with browser UI (debugging)
bun run test:browser:install     # ONE-TIME: download Chromium for Playwright
bun run test:coverage            # Vitest with coverage
bun run lint                     # ESLint
bun run format:check             # Prettier --check
bun run typecheck                # via vite build (tsc -b && vite build)
```

Frontend tests in this stack use **`vitest-browser-react`'s async `render(...)`** — always `await` it. Helpers must be `async`.

Typical mocking conventions:

- **Auth-flow tests** (sign-in, OTP, sign-out) → mock `@/lib/auth-client` via `vi.mock`.
- **Non-auth feature tests** → mock `@/lib/api` (your HTTP-client wrapper).
- **Fire-and-forget patterns** → wrap assertions in `await vi.waitFor(...)`.

### Generic Bun project

```
bun test
bun run lint    # if scripted; else `biome check`
bun run typecheck
```

### Generic Node project

Use whatever the project defines. Read `package.json` scripts before guessing.

---

## "Minimum code" — what does that mean concretely

| You want | Don't write |
|---|---|
| Function that handles the test's input | Function that takes optional configs the test doesn't use |
| One return path | Multiple return paths "just in case" |
| One exception type | A taxonomy of exception subtypes |
| Concrete value | A configurable interface |
| Inline obvious validation | A separate validator module |

You can ALWAYS extract / generalize / parameterize **later**, when a future test demands it. You can NEVER recover the time you wasted on speculative scope.

---

## When to stop and ask vs. push through

**Stop and ask** when:

- The task description in the work-doc is genuinely ambiguous about what should happen.
- A test is failing for a reason that contradicts the Plan section.
- A required dependency is missing (env var, service, library).
- A test passes that you expected to fail (or vice versa) — investigate, don't paper over.

**Push through** when:

- Just need 1 more iteration of the test/code cycle.
- Linter is complaining about something obvious — fix it.
- Type error is straightforward.

If you've cycled through "fix → re-run → fix again" twice on the same task without making progress, **switch to Phase 3b: Debug**. Do NOT try a third blind fix.

---

## Manual smoke testing (when user opted in)

For UI cosmetic changes, copy edits, color tweaks where automated tests don't add value:

1. Run dev server (`bun run dev` in the frontend project).
2. Open browser to the affected page (whatever URL the dev server prints, e.g. `http://localhost:5173/...`).
3. Walk the **golden path** — the primary user flow that touches your change.
4. Walk **edge cases** the change could regress (RTL toggle if bilingual, mobile breakpoint, dark mode if relevant, empty state, error state).
5. Test surrounding features for regressions — did your spacing change break a different page?
6. **Log it in the Implementation Log:**

   ```markdown
   - **Test mode:** manual smoke (cosmetic-only)
   - **Smoke steps:**
     - Opened http://localhost:5173/_authenticated/team — toolbar buttons aligned ✓
     - Toggled RTL via Lang switcher — buttons mirror correctly ✓
     - 320px viewport — no horizontal scroll ✓
     - Hovered "Invite teammate" — focus ring visible ✓
   - **Surrounding pages checked:** /dashboard, /settings (no regression)
   ```

If any step surprises you, **stop and treat it as a bug** — switch to Phase 3b debug.

---

## Commits — one per task

```
<type>(<scope>): <subject>

[optional body — usually unnecessary if commit is small]

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

`<type>` is `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style` / `perf`.
`<scope>` is the module touched, e.g. `auth`, `invitations`, `routes`, `frontend`.

**Never** `git commit -A` or `git commit .` — stage explicit files. Avoid accidentally committing `.env`, secrets, or large binaries.

**Never** `--amend` after a hook fails. The commit didn't happen — re-stage and create a new commit.

**Never** `--no-verify` unless the user explicitly told you to. Hook failures point at real issues.

The Plan's task description goes in the commit subject. The commit body, if any, points to the work-doc and the task ID for traceability:

```
feat(invitations): add expires_at column

Implements T1 of docs/work/2026-05-03-add-invitation-expiry.md.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

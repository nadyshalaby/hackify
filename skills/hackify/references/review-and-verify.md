# Verify & Review — Phases 4 + 5

Phase 4 proves the **original ask** is met. Phase 5 ensures the **code is good**. Both run after the last Tasks checkbox is ticked.

---

## Phase 4 — Verify (DoD with fresh evidence)

**Rule.** Evidence before claims. Every "passes" / "done" / "works" must be backed by output you ran in this turn — not earlier.

### The DoD checklist (every task type)

```
- [ ] All tests pass — fresh test-command output, exit 0, 0 failures, 0 errors
- [ ] Linter clean — fresh lint output, 0 errors (warnings only if pre-existing)
- [ ] Typecheck clean — fresh typecheck output, 0 errors
- [ ] All Tasks checkboxes ticked
- [ ] Every Definition-of-Done bullet from Phase 2 verified — paste evidence per bullet
- [ ] No placeholders, no orphan TODOs, no debug logging left behind
- [ ] No new lint suppressions (zero tolerance)
- [ ] No new `!` non-null assertions in production code
- [ ] Manual smoke (if user opted in) — steps + outcome logged
```

### How "evidence" looks

Bad:

> Tests should pass now. ✓

Good:

```
$ cd <project> && bun test
✓ 87 pass
0 fail
Ran 87 tests across 12 files. [3.42s]
```

Bad:

> Lint is fine.

Good:

```
$ bun run lint
$ biome check src/
Checked 142 files in 89ms. No fixes needed.
```

If you can't show the output, you don't know it's true. Re-run.

### Common verification failures (catch yourself)

| Failure | What to do |
|---|---|
| Output references caches / "warm" runs | Re-run from a clean state |
| One package green, another not run | Run all packages |
| Test command exits 0 but skips suites | Check the count — "0 tests ran" is a fail |
| Linter exits 0 with warnings | Confirm warnings are pre-existing; if new, fix |
| Typecheck "skipped" or "incremental" | Force fresh: delete `tsconfig.tsbuildinfo` if needed |

### Regression-test red-green cycle

For bug fixes, prove the regression test actually catches the bug:

```
1. Apply your fix.        ← test passes
2. Revert the fix only.   ← test should fail (paste this output too)
3. Re-apply the fix.      ← test passes again (paste)
```

This proves the test is sensitive to the bug it claims to catch.

---

## Phase 5 — Review

### Default: parallel multi-reviewer + self-review

For any non-trivial diff (anything beyond a one-line typo / config-only change), Phase 5 dispatches THREE foreground reviewers in parallel — security/correctness, quality/layering, plan-consistency — in a single message. The dispatch templates live in `references/parallel-agents.md` under "Multi-reviewer (Phase 5)". Add a 4th reviewer for diffs with a 4th distinct concern (e.g., heavy UI redesign on top of backend changes); cap at 4.

The self-review still happens — the parent walks the diff (`git diff <BASE_SHA>..HEAD`) and ticks each checklist item below. Note pass/fail and a 1-line note in the work-doc Verification → Self-review table. **Self-review is the floor, the parallel reviewers are the ceiling.** Both run for non-trivial diffs.

```
- [ ] DRY — no duplicated logic; existing helpers reused; new helpers extracted if 3+ uses
- [ ] Layering — presentation/domain/infrastructure separation honored
        Backend: routes are pure delegation; services own business logic + DB; no HTTP framework imports in services
        Frontend: routes thin; features own logic; components dumb; lib is glue only
- [ ] Named types — every shape with ≥2 props has a named interface/type in the right folder
        Backend: <module>/interfaces or src/common/types
        Frontend: <feature>/types.ts or src/lib/types
- [ ] No lint suppressions (biome-ignore, eslint-disable, @ts-ignore, @ts-expect-error)
        Sole carve-out: @ts-expect-error in test files for deliberately invalid input, with WHY
- [ ] File-size cap — no file >500 LOC; split by responsibility
- [ ] Function caps — ≤40 LOC, ≤3 params, ≤3 nesting levels
- [ ] Dead code — no unused exports, methods, imports; no commented-out code
- [ ] Edge cases — null/undefined, empty arrays/strings, concurrent access, partial failures
- [ ] Naming for intent — variables/functions describe WHAT they DO, not HOW
- [ ] Error handling — explicit per path; no silent swallows; no empty catches
        Backend: throw named domain errors from src/errors/
        Frontend: throw named Error subclasses with .name set
- [ ] No `!` non-null assertions in production code
- [ ] Security — no hardcoded secrets, no SQL string-concat, sanitized paths, validated inputs
- [ ] Tests cover behavior not implementation; no mocks where real code would work
- [ ] Comments only on WHY (non-obvious constraints), never WHAT
```

### When to escalate to a reviewer subagent

Spawn a **foreground** general-purpose reviewer subagent when ANY of:

- Diff > 300 LOC
- Diff touches > 8 files
- Cross-module refactor (touches multiple bounded contexts)
- Touches **any** of: auth/permissions, cryptography, database migrations, payment/billing, public API contracts, security headers, CORS/CSRF, OAuth flows, session management
- User explicitly asked for deeper review

When you escalate, **also** complete the self-review — escalation is *additive* defense, not replacement.

### Reviewer subagent prompt template

```
You're reviewing a diff for a [feature|fix|refactor|redesign].

Context (the work-doc): <absolute path to docs/work/<slug>.md>

Diff range: <BASE_SHA>..<HEAD_SHA>
Run `git diff <BASE_SHA>..<HEAD_SHA>` to see exactly what's in scope.

Project: <project name and absolute path>
Stack: <e.g. Bun + Hono + Drizzle + Postgres | Vite + React 19 + shadcn/ui + Tailwind v4 | other>

Review against:
- The work-doc's Definition of Done — does the diff actually deliver each bullet?
- The self-review checklist (find it at references/review-and-verify.md, relative to the hackify skill root)
- Project rules: honor <project>/CLAUDE.md and the user-global ~/.claude/CLAUDE.md if either is present.
  Apply the stricter rule on conflict.
- The plan's Tasks list — is anything missing? Anything beyond scope?

Pay special attention to:
- [Security/auth/migrations/etc — list the sensitive areas this diff touches]

Output format:
- Critical (bugs, security holes, data loss, broken functionality, scope creep)
- Important (architecture concerns, missing tests, poor error handling, layering violations)
- Minor (style, naming nits, doc gaps)

For each item: file:line, what's wrong, suggested fix. Be technically precise. No filler.

If you find nothing in a category, say "Critical: none." explicitly.
```

If the diff has BOTH a large security/auth surface AND a large UX/visual surface, **dispatch two reviewers in parallel** — one focused on security/correctness, one on architecture/design. They'll independently flag different issues.

### Acting on reviewer feedback (the response pattern)

```
1. READ the full feedback without reacting.
2. UNDERSTAND each item — restate it in your own words. If unclear, ask
   the user (or, if reviewer is a subagent and you can re-dispatch, re-ask).
3. VERIFY against the codebase — grep for the function name, read the file,
   check whether the reviewer's claim matches reality.
4. EVALUATE — technically sound for THIS codebase? YAGNI check: grep for
   actual usage before "professionalizing" something.
5. RESPOND — technical acknowledgment OR reasoned pushback (with evidence).
6. IMPLEMENT — one item at a time. Test each. Don't bundle.
```

**Never** "You're absolutely right!" before verification. **Never** start implementing fixes before clarifying ambiguous items.

### Pushback criteria — push back when

- The suggestion would break existing functionality.
- The suggestion is for a feature with no real consumers (YAGNI).
- The suggestion contradicts a documented architecture decision in CLAUDE.md.
- The suggestion is technically wrong for this stack/version.
- There's a reason in legacy or constraints the reviewer can't see.

When pushing back, lead with the technical reason, not the disagreement:

> *"The reviewer suggests adding `retry` with backoff. But this is a request-scoped service inside a tenant route — retries would re-acquire the pool client, breaking `SET LOCAL search_path`. The right fix is at the caller, not in the service. Skipping."*

### Severity → action

| Severity | Action |
|---|---|
| Critical | Fix now. Do NOT advance to Phase 6 until resolved. Re-run verification. |
| Important | Fix before claiming done. May extend the work-doc Tasks list (mark added tasks "review-driven"). |
| Minor | Either fix now if cheap (≤5 min) OR add a Post-mortem entry as a follow-up. Do not silently drop. |

---

## After review — back to Phase 4 if anything changed

If review found Critical or Important issues and you fixed them, **re-run Phase 4 verification** before going to Phase 6. New code = new evidence required.

---

## Self-review honesty

The self-review is only useful if you're honest about it. The temptation to tick all boxes and move on is real. Counter it:

- For any item you're tempted to tick without checking, **actually check** — open the file, grep, run the linter scoped to the file.
- For any item that's a soft pass ("mostly DRY"), **state the soft pass** in the notes column. The Post-mortem will pick it up.
- If the diff has a section you genuinely don't understand well enough to review (e.g., a domain you haven't worked in), **escalate** even if the diff is small. Self-review only works when you can self-review.

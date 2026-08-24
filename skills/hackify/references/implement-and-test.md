# Implement & Test (Phase 3 Walkthrough)

The implement phase is **wave-based, one foreground subagent per whole wave.** Tasks are sorted by priority and topological dependency, grouped into waves where no two tasks share a file, and the whole wave is dispatched to exactly one foreground agent that carries every task in it, in run order. Per-task discipline (TDD when applicable, file allowlist, fully green before reporting) is enforced inside that agent's prompt.

**A one-task wave is the same dispatch** with one task in it, e.g., a serializing migration step. There is no other shape and no cap on wave width: no module split, no grouping decision at dispatch time.

---

## Wave loop (the canonical sequence)

```
1.  Update frontmatter:    status: implementing,  current_task: W<n>:T<a>+T<b>+…
2.  Confirm the wave plan from the work-doc Approach. Each wave member's
    file allowlist must NOT overlap with peers in the same wave.
3.  Dispatch ONE Agent for the WHOLE WAVE, however wide it is. Its prompt is
    self-contained and carries the wave's task IDs in run order, per the
    template in references/parallel-agents/phase-3-implementation.md.
4.  Wait for the agent. Read its report, starting with the `## Wave status`
    section it opens with: that is where it names which task IDs landed and
    which did not.
5.  Verify the wave diff stayed inside the file allowlists:
       git diff --name-only ⇒ every path in the diff must appear in the
       union of allowlists. Do NOT assert the reverse: a wave that stopped
       early writes a strict SUBSET of the union on purpose, so a union path
       missing from the diff is the stop working as designed, and only a
       diff path missing from the union is a violation.
       Each task's hunks stay inside that task's OWN allowlist.
6.  Run full project suite ONCE for the wave: test + lint + typecheck. All green.
7.  Self-review against references/review-and-verify.md (parent does this).
8.  Tick ONLY the task IDs `## Wave status` lists as landed, never the whole
    wave. Ticking a task the agent never finished records work that is not on
    disk. Every not-landed ID stays unticked: re-dispatch it in the next wave
    dispatch on an agent failure, drop to Phase 3b with it on a plan failure.
    Append one Daily Updates entry per landed task.
9.  Single commit for the wave (subject covers the wave; body lists the task
    IDs that landed).
10. Advance to wave N+1.
```

Per-task discipline (enforced inside the wave agent's prompt, see the template). Steps a to e repeat for every task in the wave, in run order; step f runs once:

```
a.  Decide test mode for the current task (test-first / test-after / manual / none).
b.  IF test-first:
       i.   Write the failing test.
       ii.  Run only the file-scoped test. SEE IT FAIL with the right error.
       iii. Confirm the failure is "feature missing", not setup/typo.
c.  Write the minimum code to satisfy the task. NOTHING more.
d.  Run the file-scoped test. See it pass.
e.  Self-review per checklist before reporting done.
f.  REPORT BACK, naming which of the wave's task IDs landed and which did not.
    The parent runs repo-wide verification + commit.
```

**Stop at the first task you cannot finish.** Everything already written stays on disk and the report says which task IDs landed, so a failure late in the wave costs the tasks after it, never the ones before it. The parent re-dispatches the stopped task; it never re-runs the ones that already landed.

Skip steps deliberately and the work-doc Daily Updates entry records why. **Watching the test fail is non-negotiable when test mode is test-first.** If the agent didn't watch it fail, the agent doesn't know if it tested the right thing.

---

## Picking the test mode

| Task touches | Test mode | Notes |
|---|---|---|
| Pure logic, services, validators, calculators | **test-first** | RED → GREEN → REFACTOR |
| Auth / permissions / token validation | **test-first** | Always, security regressions are worst |
| Bug fixes | **test-first** | Reproduce as a failing test, then fix |
| Branching/conditional logic | **test-first** | Each branch wants its own test |
| HTTP handlers / route wiring | test-after acceptable | Use integration test against ephemeral DB |
| DB migrations | test-first via integration | Run migration up/down on ephemeral DB |
| UI cosmetics / spacing / colors / copy | manual smoke (if user opted in) | Always offer to add an automated test if behavior is testable |
| Form validation, computed UI state | **test-first** | Component / browser-mode test runner, test the behavior |
| Storybook / docs / config-only changes | manual or none | Note rationale in log |
| Pure scaffolding (empty file creation) | none | Note rationale |

The user explicitly opted into "manual testing optional", but manual is **supplement**, not **replacement** when behavior is testable. Always at least offer the automated test.

---

## TDD, RED / GREEN / REFACTOR (when test-first)

### RED (write the failing test)

- **Name describes behavior**, not implementation. `it('rejects expired invitations', …)` not `it('test1', …)`.
- **One thing per test.** If the name has "and" in it, split.
- **Real code, not mocks**, unless the dependency is a network call, paid service, or non-deterministic (clock, randomness, filesystem in some cases). Backend integration tests should run against the **real** database on docker, no mocked DB. Frontend tests use real auth-client behavior where possible (mock at the `@/lib/api` boundary; mock `@/lib/auth-client` only for auth-flow tests).

### Verify RED (watch it fail)

Mandatory. Run the test command. Read the output. Confirm:

- The failure message is what you expect (e.g., "function not defined" or "expected 401 to equal 200").
- The failure is **because the feature is missing**, not a typo, not a syntax error, not a setup error.

If the test passes immediately → you wrote a test for behavior that already exists. Fix the test (likely test the new behavior, not the old).

If the test errors (not fails) → fix the error. Re-run. Test must reach the assertion and fail there.

### GREEN (minimal code to pass)

- **Just enough.** No "while I'm here" cleanup. No new options on the API. No future-proofing.
- **Bad example.** Test wants `retry(3, fn)`. You implement `retry(opts: { times, backoff, onRetry, jitter })`. Wrong, write `retry(3, fn)` literally, leave the rest until a test demands it.
- **Run the test.** It passes.
- **Run the full suite.** Nothing else regressed.

### REFACTOR (clean up)

After green only. Now you can:

- Extract helpers if logic appears 3+ times.
- Improve names (intent over implementation).
- Reorganize file structure.
- Simplify control flow.

**Tests stay green.** Refactor never adds behavior.

---

## Per-discipline command reference

Hackify does NOT pick a stack. The agent runs whatever the project already wires for each discipline. Look in the project's `CLAUDE.md`, README, or package manifest to find the literal command, do not guess.

Use these **fresh** during Phase 4 verification, paste full output.

### Test runner

Run the project's configured test command. File-scoped form is preferred during Phase 3 (one test, one file); full-suite form is required during Phase 4 verification.

```
<test runner command>                       # full suite
<test runner command> <path/to/test/file>   # single file (Phase 3 inner loop)
<test runner command> --watch               # watch mode (if supported)
```

Integration tests REQUIRE a real backing service (database, queue, cache). **Never mock the database** when an integration target exists, let integration tests catch real-world regressions, and unit-test the pure logic separately.

### Linter

Run the project's configured linter / formatter check. Auto-fix variants are fine during Phase 3; the gate in Phase 4 is the read-only check, exit 0.

```
<linter command>          # check only, must exit 0 in Phase 4
<linter fix command>      # auto-fix variant, if available
```

### Type checker

Run the project's configured typecheck command. Must exit 0 in Phase 4.

```
<typecheck command>
```

### Coverage tool (when applicable)

Run the project's configured coverage command when the work-doc's acceptance criteria call for a coverage target.

```
<coverage command>
```

### Integration prerequisites (when applicable)

If integration tests need a backing service, start it via the project's documented bring-up command before running the test command. Document the command set in the work-doc Plan section so the agent does not invent one.

```
<service bring-up command>            # e.g. start database, queue, mail catcher
<migration command>                   # apply pending schema migrations
```

### Component / browser-mode tests (when applicable)

When the test target is a UI component rendered in a real browser:

- Always `await` the async render helper the project's component test runner exposes; helpers that wrap it must also be `async`.
- Mock at the **HTTP-client boundary** for non-auth feature tests, and at the **auth-client boundary** for auth-flow tests.
- For fire-and-forget side effects, wrap assertions in the test runner's `waitFor` primitive.

---

## "Minimum code" (what does that mean concretely)

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
- A test passes that you expected to fail (or vice versa), investigate, don't paper over.

**Push through** when:

- Just need 1 more iteration of the test/code cycle.
- Linter is complaining about something obvious, fix it.
- Type error is straightforward.

If you've cycled through "fix → re-run → fix again" twice on the same task without making progress, **switch to Phase 3b: Debug**. Do NOT try a third blind fix.

---

## Manual smoke testing (when user opted in)

For UI cosmetic changes, copy edits, color tweaks where automated tests don't add value:

1. Run the project's dev server via its documented command (see the project's `CLAUDE.md` / README, do not guess).
2. Open the browser to the affected page (whatever URL the dev server prints).
3. Walk the **golden path**, the primary user flow that touches your change.
4. Walk **edge cases** the change could regress (RTL toggle if bilingual, mobile breakpoint, dark mode if relevant, empty state, error state).
5. Test surrounding features for regressions, did your spacing change break a different page?
6. **Log it in the Daily Updates entry:**

   ```markdown
   - **Test mode:** manual smoke (cosmetic-only)
   - **Smoke steps:**
     - Opened <dev URL>/team, toolbar buttons aligned ✓
     - Toggled RTL via Lang switcher, buttons mirror correctly ✓
     - 320px viewport, no horizontal scroll ✓
     - Hovered "Invite teammate", focus ring visible ✓
   - **Surrounding pages checked:** /dashboard, /settings (no regression)
   ```

If any step surprises you, **stop and treat it as a bug**, switch to Phase 3b debug.

---

## Commits (one per wave)

```
<type>(<scope>): <subject>

[optional body, usually unnecessary if commit is small]

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

`<type>` is `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style` / `perf`.
`<scope>` is the module touched, e.g. `auth`, `invitations`, `routes`, `frontend`.

**Never** `git commit -A` or `git commit .`, stage explicit files. Avoid accidentally committing `.env`, secrets, or large binaries.

**Never** `--amend` after a hook fails. The commit didn't happen, re-stage and create a new commit.

**Never** `--no-verify` unless the user explicitly told you to. Hook failures point at real issues.

One commit closes the whole wave, never one per task. The subject describes what the wave delivered; the body names the work-doc and lists every task ID that landed, which is what makes the commit traceable back to the Sprint Backlog. A wave that stopped early commits only the IDs its agent reported as landed, so the commit and the ticked checkboxes say the same thing:

```
feat(invitations): add expiry column and the expiry guard

Implements T1 and T2 of docs/work/2026-05-03-add-invitation-expiry.md.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

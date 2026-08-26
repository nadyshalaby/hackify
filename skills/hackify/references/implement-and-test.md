# Implement & Test (Phase 3 Walkthrough)

The implement phase is **wave-based, one foreground subagent per whole wave when the wave's tasks share a read surface.** Tasks are sorted by priority and topological dependency, grouped into waves where no two tasks share a file, and the whole wave is dispatched to exactly one foreground agent that carries every task in it, in run order. A wave whose tasks share no read surface is the only wave worth proposing a finer split for, and that proposal MAY go out as concurrent waves, one agent each, only when all THREE conditions of the partition test in [phases/phase-3-implement.md](phases/phase-3-implement.md) hold: no file in two subsets, no import or read/write edge between them in EITHER direction, and no serial resource held by both. The ABSENCE of a shared read surface is what makes a finer split worth proposing; it never makes one permitted, and the three conditions are what permit it. Collecting the cleared waves into a round is a separate step, because the test is scoped to ONE wave and never asked whether two waves in a round hold a path in common. Per-task discipline (TDD when applicable, file allowlist, fully green before reporting) is enforced inside that agent's prompt.

**A one-task wave is the same dispatch** with one task in it, e.g., a serializing migration step. A single wave has no width valve and no split by module hunch: the partition test is the only thing that may split one, and what it splits becomes concurrent waves inside the same round rather than a wider fan-out inside one wave.

---

## Wave loop (the canonical sequence, run once per round)

```
1.  Update frontmatter:    status: implementing,  current_task: R<n>:T<a>+T<b>+…
    (every task in the round, across all of its waves).
2.  Confirm the wave plan from the work-doc Approach. Each wave member's
    file allowlist must NOT overlap with peers in the same wave. Apply ALL
    THREE conditions of the partition test (phases/phase-3-implement.md) to
    every wave yourself, then collect the waves it clears into ROUNDS. A
    round holding one wave is normal. Then intersect that ROUND, wave
    against wave, as its own check: the test is scoped to ONE wave and never
    asked whether two waves in a round hold a path in common. A path in two
    waves SPLITS the round, the later wave moving to the next round or the
    two merging. Record the intersection even when it is empty.
3.  BEFORE dispatching anything, create $RECON outside the repo and
    `touch $RECON/round_start`. Step 6 FAILs the round without that marker,
    and it dates the sweep of the generated tree git cannot see, so a marker
    created after the agents have run passes the existence check over a sweep
    that finds nothing. Step 6 catches that too, by comparing the marker
    against the round's own diff, but only a marker made HERE is honest.
4.  Dispatch ONE Agent per wave, every wave in the round in ONE message,
    each carrying its whole wave however wide it is. Every prompt is
    self-contained and carries THAT wave's task IDs in run order, per the
    template in references/parallel-agents/phase-3-implementation.md.
5.  Wait for every agent in the round. Read every report, starting with the
    `## Wave status` section each one opens with: that is where it names
    which task IDs landed and which did not.
6.  Reconcile the round's paths against what each wave DECLARED under
    `## Paths written` and `## Paths deleted`, three ways: every declared
    path inside THAT wave's OWN allowlist, no path claimed by two waves,
    and nothing in the round's diff unclaimed. The declaration is the input
    because git cannot attribute an uncommitted edit to a wave, and a
    deleted path reaches the diff with nobody claiming it unless the wave
    declared it. The third check catches the stray edit no agent admits to. Canonical rule and the
    runnable form: phases/phase-3-implement.md, "The round's allowlist
    reconciliation". Each task's hunks stay inside that task's OWN
    allowlist; the wave union never widens what one task may touch.
7.  Run full project suite ONCE for the ROUND, after every wave in it has
    returned: test + lint + typecheck. All green. Any suite that needs an
    exclusive resource runs here and nowhere else.
8.  Self-review against references/review-and-verify.md (parent does this).
9.  Run BOTH deterministic scouts over what that round's waves DECLARED,
    BEFORE anything ticks: the perf-scout (references/perf-scout.md) and
    the law-scout (references/law-scout.md). Every wave already scanned
    its own allowlist before it returned and reported the rows under
    `## Scout dispositions`; carry those forward unchanged and disposition
    whatever this wider scope newly shows. The parent never writes the fix.
    Two run points, two owners, two scopes, and why each exists:
    phases/phase-3-implement.md, "The scouts run twice". Read it there, it
    is deliberately not restated here.
10. Tick ONLY the task IDs each report's `## Wave status` lists as landed,
    never the whole wave. Ticking a task the agent never finished records
    work that is not on disk. Every not-landed ID stays unticked:
    re-dispatch it in the next dispatch on an agent failure, drop to Phase
    3b with it on a plan failure. Append one Daily Updates entry per landed
    task.
11. Commit ONCE for the ROUND, after every wave in it has returned (subject
    covers the round; body names every task ID in it and marks which landed
    and which did not). A single-wave round is this rule with one wave in it.
12. Advance to round N+1.
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

## Commits (one per round)

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

One commit closes the whole round, after every wave in it has returned, never one per task; a single-wave round is that same rule with one wave in it. The subject describes what the round delivered; the body names the work-doc and lists every task ID that landed, which is what makes the commit traceable back to the Sprint Backlog. A wave that stopped early commits only the IDs its agent reported as landed, so the commit and the ticked checkboxes say the same thing:

```
feat(invitations): add expiry column and the expiry guard

Implements T1 and T2 of docs/work/2026-05-03-add-invitation-expiry.md.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

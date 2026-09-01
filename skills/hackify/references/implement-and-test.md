# Implement & Test (Phase 3 Walkthrough)

The implement phase is **wave-based, one foreground subagent per whole wave when the wave's tasks share a read surface.** Tasks are sorted by priority and topological dependency, grouped into waves where no two tasks share a file, and the whole wave is dispatched to exactly one foreground agent that carries every task in it, in run order. A wave whose tasks share no read surface is the only wave worth proposing a finer split for, and that proposal MAY go out as concurrent waves, one agent each, only when all THREE conditions of the partition test in [contention-dispatch.md](contention-dispatch.md) hold: no file in two subsets, no import or read/write edge between them in EITHER direction, and no serial resource held by both. The ABSENCE of a shared read surface is what makes a finer split worth proposing; it never makes one permitted, and the three conditions are what permit it. Collecting the cleared waves into a round is a separate step, because the test is scoped to ONE wave and never asked whether two waves in a round hold a path in common. Per-task discipline (the wave's test mode, file allowlist, fully green before reporting) is enforced inside that agent's prompt.

**A one-task wave is the same dispatch** with one task in it, e.g., a serializing migration step. A single wave has no width valve and no split by module hunch: the partition test is the only thing that may split one, and what it splits becomes concurrent waves inside the same round rather than a wider fan-out inside one wave.

---

## Wave loop (the canonical sequence, run once per round)

```
1.  Update frontmatter:    status: implementing,  current_task: R<n>:T<a>+T<b>+…
    (every task in the round, across all of its waves).
2.  Confirm the wave plan from the work-doc Approach. Each wave member's
    file allowlist must NOT overlap with peers in the same wave. Apply ALL
    THREE conditions of the partition test (contention-dispatch.md) to
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
5.  As EACH agent returns, and before waiting on the rest, read its report,
    starting with the `## Wave status` section it opens with: that is where
    it names which task IDs landed and which did not. Tick those IDs and no
    others, and append that agent's Daily Updates entries, now rather than
    at round end: ticking a task the agent never finished records work that
    is not on disk, and holding every tick until the last agent is in loses
    the whole round's progress when the sixth one dies. Then wait for the
    rest.
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
    before the round commits, never before a tick: the perf-scout
    (references/perf-scout.md) and the law-scout (references/law-scout.md).
    Step 5 already ticked, one returning agent at a time, so a candidate
    this wider scope raises is a new finding, never an un-tick. Every wave
    already scanned its own allowlist before it returned and reported the
    rows under `## Scout dispositions`; carry those forward unchanged and
    disposition whatever this wider scope newly shows. The parent never
    writes the fix. Two run points, two owners, two scopes, and why each
    exists: phases/phase-3-implement.md, "The scouts run twice". Read it
    there, it is deliberately not restated here.
10. Close the round in the work-doc: confirm every ID step 5 ticked survived
    step 6's reconciliation, and leave every not-landed ID unticked.
    Re-dispatch it in the next dispatch on an agent failure, drop to Phase
    3b with it on a plan failure.
11. Commit ONCE for the ROUND, after every wave in it has returned (subject
    covers the round; body names every task ID in it and marks which landed
    and which did not). A single-wave round is this rule with one wave in it.
12. Advance to round N+1.
```

Per-task discipline (enforced inside the wave agent's prompt, see the template). Steps a to e repeat for every task in the wave, in run order; step f runs once:

```
a.  Confirm the wave's test mode, which is carried in the dispatch and is a
    property of the WAVE, not of the task. An implementation wave writes
    production code; the testing wave carries `test-authoring`.
b.  Write the minimum code to satisfy the task. NOTHING more.
c.  Run the file-scoped lint and typecheck over what you touched. Both green.
d.  Run any test that already covers the touched files, file-scoped. No regression.
e.  Self-review per checklist before reporting done.
f.  REPORT BACK, naming which of the wave's task IDs landed and which did not,
    and what each task landed, because the testing wave has to test it without
    having watched you build it. The parent runs repo-wide verification + commit.
```

Under `test-authoring` the loop is a different one, and it is the one that owes the tests. Steps b to e repeat per file of the round's diff; a and f run once:

```
a.  Take the diff YOUR wave covers and the wave reports that describe it. On a
    stage that split, that is your subset and not the whole round. Work file by
    file.
b.  Write the test. Name it for the behavior, not the implementation.
c.  MAKE IT FAIL ON PURPOSE, then restore. See "Verify RED" below.
d.  Run the file-scoped test. See it pass against the unmutated code.
e.  Self-review per checklist before reporting done.
f.  REPORT BACK: which files are now covered, which are not, and why not.
```

**Stop at the first task you cannot finish.** Everything already written stays on disk and the report says which task IDs landed, so a failure late in the wave costs the tasks after it, never the ones before it. The parent re-dispatches the stopped task; it never re-runs the ones that already landed.

Skip steps deliberately and the work-doc Daily Updates entry records why. **Watching the test fail is non-negotiable under `test-authoring`.** If the agent didn't watch it fail, the agent doesn't know if it tested the right thing. That law did not soften when the tests moved; it moved with them, and the testing wave is where it now binds.

---

## Picking the test mode

Canonical spelling of the enum, and the only one any file should use: `test-authoring | test-after | manual smoke | none`. That is the set `hackify:implementer` accepts, and the implementer is the consumer, so a fifth value is not a mode with nowhere to run, it is a misfill the agent refuses at dispatch.

**The mode belongs to the WAVE, not to the task.** `test-authoring` makes a wave a TESTING WAVE: the testing stage runs after the last module track and covers everything the round landed. Every other value marks an implementation wave, which writes production code only and authors no tests, `test-after` naming the ordinary case where the testing wave writes them, `manual smoke` the cosmetic diff the user opted into walking by hand, and `none` the diff with genuinely nothing to test. A compressed-flow change, a solo round too small to be worth a separate testing wave, and a Phase 3b debug fix do not get a mode of their own for it: they carry `test-authoring` on the one wave they have, so the implementer IS the testing wave and the table below is addressed to it. **The debug fix is the shape where that wave writes production code too**, because [debug-when-stuck.md](debug-when-stuck.md) needs the failing regression test to exist before the fix and the parent may author neither. One wave writes both, which is cheaper than a sixth mode and stricter than two waves would be: the agent that watches the red is the agent that has to make it green.

**The stage is not automatically one wave, so `test-authoring` does not tell you how many of you there are.** It packs and splits under the same partition test as every other stage, which means the mode reaches you either as the whole stage or as one of several testing waves writing this tree at the same moment. The rule and its three conditions are stated once, in [contention-dispatch.md](contention-dispatch.md) under "The testing stage splits like any other stage", and are deliberately not restated here. What settles it for you is your own dispatch's `{{sibling_tracks}}`: names there mean [sibling-track-rules.md](sibling-track-rules.md) binds you exactly as it binds a module track, and every "the testing wave" below means YOURS, over your subset of the round's diff rather than over all of it.

**This is a change of address, not a discount.** Every row that used to be tested before its code existed still gets its watched red and its named mutation. The work happens once, in one wave, against a tree where every seam is already visible, instead of N tracks each testing what they can see from inside their own module. A round is not finished until that wave has run, and a diff with genuinely nothing to test closes the wave with a written reason rather than silence.

So the table now reads as the testing wave's brief:

| Code the round landed | What the testing wave owes it | Notes |
|---|---|---|
| Pure logic, services, validators, calculators | Unit tests, every red watched via a named mutation | The bulk of the work |
| Auth / permissions / token validation | The same, and never the row that gets dropped for time | Security regressions are the worst kind |
| Money maths, ledgers, pricing | Unit tests plus property-based tests | A balancing ledger is a property of the module, provable in isolation |
| Bug fixes | The reproduction, as a test that fails without the fix | Revert the fix, watch the red, restore the fix |
| Branching/conditional logic | One test per branch | A fixture that cannot reach both answers proves nothing |
| HTTP handlers / route wiring | Integration test against a real database | Whether the route is actually MOUNTED is assembly's question, not this wave's |
| DB migrations | Migration up/down on an ephemeral database | |
| Form validation, computed UI state | Component / browser-mode test of the behavior | |
| UI cosmetics / spacing / colors / copy | manual smoke (if user opted in) | Always offer to add an automated test if behavior is testable |
| Storybook / docs / config-only changes | none | Note rationale in log |
| Pure scaffolding (empty file creation) | none | Note rationale |

Two kinds of test are NOT this wave's and are listed so nobody writes them twice: cross-module integration and every mounted-surface check (route and spec drift, the permission matrix, the cross-tenant sweep, booting the service and sending it real requests) belong to the assembly wave, because nothing is mounted until then. See [contention-dispatch.md](contention-dispatch.md), "What each track owes".

The user explicitly opted into "manual testing optional", but manual is **supplement**, not **replacement** when behavior is testable. Always at least offer the automated test.

---

## RED / GREEN / REFACTOR (the testing wave's loop, under `test-authoring`)

The order is the same as classic TDD. What changed is that the production code is usually already on disk when you start, so the RED has to be made rather than waited for. Everything below applies unchanged wherever the code genuinely is not there yet, which under this shape is a single bug reproduction written before its fix rather than a whole wave.

### RED (write the failing test)

- **Name describes behavior**, not implementation. `it('rejects expired invitations', …)` not `it('test1', …)`.
- **One thing per test.** If the name has "and" in it, split.
- **Real code, not mocks**, unless the dependency is a network call, paid service, or non-deterministic (clock, randomness, filesystem in some cases). Backend integration tests should run against the **real** database on docker, no mocked DB. Frontend tests use real auth-client behavior where possible (mock at the `@/lib/api` boundary; mock `@/lib/auth-client` only for auth-flow tests).

### Verify RED (watch it fail)

Mandatory, and this is the step the move to a testing wave changes most. The code the test covers has already landed, so the test passes on its first run, and a test you have only ever seen pass is a test of nothing. **You make it fail on purpose: break the production line the test protects, run the file-scoped test, and require a red that NAMES your test.** Then restore the line. That single act is the watched RED and the mutation proof at once, and it is recorded under `## Mutations taken`.

**That break is a write OUTSIDE your allowlist, and it is only cheap while nothing else is writing the tree.** The line goes back seconds later, which is why a stage running as one wave takes the mutation and thinks no more about it. Where the stage split, those same seconds are a window a sibling can write into, and neither of you gets an error: a sibling's edit to the file you broke is gone the moment you put your line back, and your own red may be reporting their half-written import rather than your mutation. Settle which case you are in from `{{sibling_tracks}}` before the first mutation, never from the size of the round.

With siblings named, one rule covers it. **The file you break is yours for the window, or you do not break it.** The stage's partition already covers the production side, and it is stated once in [contention-dispatch.md](contention-dispatch.md) under "The testing stage splits like any other stage" rather than restated here. So the split that reached you was screened for this collision on the mutations the plan could foresee, and what no plan can foresee is the line YOU pick. Where that line sits outside your own allowlist, or you cannot establish that it does not, STOP and report that file rather than mutating it, exactly as you would report a defect in shared code. Restore by editing the line back: `git checkout`, `git restore` and `git stash` are banned outright on a side-by-side dispatch and this is the step that tempts them, because they take the whole file and every uncommitted change in it, a sibling's included.

Read the output. Confirm:

- The red names **your** test, not a neighbour's, and not a whole suite collapsing.
- The failure is **because the behavior is gone**, not because the mutation broke parsing.

If the test still passes after the mutation → the test does not discriminate. Fix the **test**, not the mutation.

If the whole file errors → usually your mutation hit syntax rather than behavior, so pick a subtler one (flip a comparison, drop a guard clause, return the other branch) and re-run. **With siblings named, read where the error was raised before you accept that diagnosis.** An error inside a file you never touched is a sibling mid-write, not your mutation, and re-picking a subtler mutation for it chases your own tail through somebody else's edit. Restore your line, re-run, and record what you saw rather than mutating again.

Two traps this codebase has already paid for, both about tests that cannot fail. A fixture that makes both branches unreachable passes whatever the code does, so check the fixture can reach both answers. And an expected value derived by running the code absorbs the bug it should catch, so compute every expected outcome from the plan, before anything runs.

Where the code genuinely is NOT on disk yet (a bug reproduction written before its fix, or a behaviour the round was supposed to land and did not), the classic order applies instead: run the test, confirm the failure message is what you expect ("function not defined", "expected 401 to equal 200"), and confirm it fails because the feature is missing rather than from a typo or a setup error. A test that errors instead of failing has to reach its assertion first, so fix the error and re-run.

### GREEN (the test passes against real code)

- **Restore the line you mutated.** Re-run the file-scoped test. It passes.
- **Where the code genuinely was missing**, write just enough to satisfy the test. No "while I'm here" cleanup. No new options on the API. No future-proofing.
- **Bad example.** Test wants `retry(3, fn)`. You implement `retry(opts: { times, backoff, onRetry, jitter })`. Wrong, write `retry(3, fn)` literally, leave the rest until a test demands it.
- **Stay file-scoped.** The full suite is the parent's run, once for the round and again in Phase 4; running it per test inside a wave buys nothing and costs the round its wall-clock.

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

Run the project's configured test command. Which form runs where is fixed, and it is fixed by who owns the stage rather than by preference. **Inside a wave, implementation or testing, the file-scoped form is the only one that runs**: one test, one file, no exclusive resource. **The full-suite form runs twice and nowhere else**, both times by the parent: once per round, after every wave in that round has returned, and again fresh during Phase 4 verification, where exit 0 is the gate and the output is pasted.

```
<test runner command>                       # full suite (parent, per round and in Phase 4)
<test runner command> <path/to/test/file>   # single file (inside a wave)
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
```

**NO CLAUDE ATTRIBUTION, in the commit or anywhere else it lands.** The message ends with its body.
No `Co-Authored-By:` trailer, no `Claude-Session:` line, no "Generated with Claude Code" footer, and
the same ban holds for PR titles and PR bodies. The runtime harness may carry a standing instruction
to append those lines; this rule OVERRIDES it, and the override is the point rather than an
oversight. A repository's history is the project's record, not a tool's, and a reader of `git log`
should see the change and who owned it. Where a project genuinely wants the attribution, its own
CLAUDE.md asks for it and that request wins; silence is a no.

`<type>` is `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style` / `perf`.
`<scope>` is the module touched, e.g. `auth`, `invitations`, `routes`, `frontend`.

**Never** `git commit -A` or `git commit .`, stage explicit files. Avoid accidentally committing `.env`, secrets, or large binaries.

**Never** `--amend` after a hook fails. The commit didn't happen, re-stage and create a new commit.

**Never** `--no-verify` unless the user explicitly told you to. Hook failures point at real issues.

One commit closes the whole round, after every wave in it has returned, never one per task; a single-wave round is that same rule with one wave in it. The subject describes what the round delivered; the body names the work-doc and lists every task ID that landed, which is what makes the commit traceable back to the Sprint Backlog. A wave that stopped early commits only the IDs its agent reported as landed, so the commit and the ticked checkboxes say the same thing:

```
feat(invitations): add expiry column and the expiry guard

Implements T1 and T2 of docs/work/2026-05-03-add-invitation-expiry.md.
```

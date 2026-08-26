---
slug: 2026-08-26-phase-3-parallel-waves
title: Scope Phase 3's one-agent-per-wave rule so independent waves can run together
status: done
type: refactor
created: 2026-08-26
project: hackify
related: []
current_task: Done. Archived with the report at docs/work/done/. The squash-merge to main
  and the v0.16.0 tag are deliberately NOT done: pushing is outward-facing and the release scope
  grew past the original ask, so both wait on the user.
worktree: null
branch: refactor/phase-3-parallel-waves
sprint_goal: |
  Phase 3 stops being the workflow's throughput floor. One agent still takes a wave
  whose tasks share a read surface, but waves that share nothing may run at the same
  time, and every safety property the old rule carried survives the change.
---

# Scope Phase 3's one-agent-per-wave rule so independent waves can run together

## 0. Phase ledger

- [x] Phase 1. Clarify (lock the goal anchor)
- [x] Phase 2. Plan + Gate (work-doc + user "go")
- [x] Phase 2.5. Spec review (1 reviewer, patch the doc)
- [x] Phase 3. Implement (all waves committed)
- [x] Phase 4. Verify (Evidence Ledger + triad green)
- [x] Phase 5. Review (one panel, one refuter, 22 findings fixed)
- [x] Phase 6a. Re-verify + land choice (Steps A, B, C)
- [x] Phase 6b. Cleanup sweep (Step C.5)
- [x] **Phase 6c. Archive work-doc to `done/` (Step D)**
- [x] Phase 6d. Update log + HTML report (Step F)

## 1. Original ask

> What genuinely is the skill's doing, with exact locations:
>
> skills/hackify/SKILL.md:134 says dispatch "exactly ONE subagent for the whole wave however wide it is: no cap, no module split, no grouping decision at dispatch time." agents/wave-implementer.md:6 repeats it harder: "There is no cap and no width valve, in any mode ... tasks are never split off by module." And SKILL.md:56 states the intent outright: "Phase 3 is the one place that gives it up on purpose."
>
> So the restructure I did an hour ago, splitting three resources into parallel module tracks, is precisely what those lines forbid. I deviated from the skill to do it.
>
> The rationale it gives is good, though, and worth keeping: one agent per wave "reads the shared types, neighbours and conventions once instead of once per task ... and cannot contradict itself across the halves of one feature." That holds when a wave's tasks read the same code. It's simply void when the tasks sit in separate module folders that import nothing from each other, which is the case here. The rule is stated unconditionally when its own justification is conditional.
>
> SKILL.md:75 adds "Parallelism lives inside a phase, never across phases", which is right for phase ordering but gets read as forbidding concurrent waves too.
>
> What was mine, not the skill's. The 2.5-task waves. The skill explicitly says "no cap" on wave width. The spec reviewer cut 38 narrow waves optimising for reviewability, and I dispatched th because SKILL.md:134 says to read the plan out of thePhase 2.5 report "rather than rebuilding it". Nothing stopped me merging them. That one's on me.
>
> The deep re-verification is from claim-integrity.md, and I'd argue against removing it: it caught a false test-existence claim and a silent test-data wipe within one hour today. It should ot disappear.
>
> One practical note: the installed copy lives under a veo edits there get discarded on the next plugin update.The durable fix belongs in the plugin's own source repo. (That's inference from the path shape, not something I measured.)
>
> Here's the prompt. Paste it into a Claude Code session opened on the hackify plugin source repo.
>
> Read skills/hackify/SKILL.md, skills/hackify/references/phases/phase-3-implement.md,
> skills/hackify/references/orchestration.md, and agents/
> changing anything.
>
> Problem, measured on a real 97-task module: Phase 3 is the workflow's throughput
> floor. Waves averaged 2.5 tasks and ran strictly one at
> because three rules combine to forbid the only available parallelism. Every other
> phase fans out; Phase 3 alone cannot. On a 1000-task bu
> between weeks and months, and none of it buys any safety the file allowlists do
> not already provide.
>
> Make these five changes. Preserve every safety property,
> claim integrity, mutation proof, phase ordering, the stop-at-first-failure clause.
>
> 1. SCOPE THE ONE-AGENT-PER-WAVE RULE BY SHARED READ SURFACE, DO NOT DELETE IT.
>    SKILL.md:134 and agents/wave-implementer.md:6 state
>    width valve, in any mode" unconditionally, but the stated justification is
>    conditional: one agent "reads the shared types, neige"
>    and "cannot contradict itself across the halves of one feature." That is true
>    when a wave's tasks read the same code and void when
>    Rewrite as: one agent per wave WHEN the wave's tasks share a read surface.
>    When two groups of tasks live in different module fo
>    the other, they MAY be dispatched as concurrent waves, one agent each. Give the
>    parent a concrete test to apply: if the union of all
>    subsets with no file overlap AND no import edge between them, the partition may
>    run in parallel. Keep the failure clause per agent.
>    Update SKILL.md:56, which currently reads "Phase 3 is the one place that gives
>    it up on purpose", so it no longer states the carve-
>
> 2. LET THE PARENT MERGE WAVES.
>    SKILL.md:134 says to read the wave plan out of the Phase 2.5 report "rather than
>    rebuilding it", which reads as a ban on adjusting itses
>    for reviewability and produces narrow waves; every wave pays a near-constant
>    setup cost (the agent re-reads the project rules, thoc
>    before writing a line), so narrow waves pay that toll repeatedly.
>    Add: the parent MAY merge consecutive waves when the
>    internal file collision and no dependency edge crosses the merge. Merging is a
>    throughput decision and does not need re-review. Say
>    plan rather than rebuild it" bans re-planning, not merging.
>
> 3. MAKE THE SPEC REVIEWER DECLARE SERIAL RESOURCES.
>    Parallelism keeps being blocked by a small number ofs
>    that no one names up front. Real examples hit this week: migration files numbered
>    from a journal's length, so concurrent generation co
>    published error code whose registration is a four-file change with three shared
>    files; a single test database that cannot take two i
>    Amend agents/spec-reviewer.md so its wave plan carries a SERIAL RESOURCES section
>    listing every shared file, generated-sequence and exthe
>    backlog touches. Then instruct the parent in phase-3-implement.md to pull those
>    into one solo foundation wave first and parallelise t.
>    That pattern alone turned fifteen sequential waves into two rounds.
>
> 4. ADD AN EXCLUSIVE-RESOURCE CLAUSE TO THE WAVE CONTRACT.
>    Concurrent waves must not both hold an exclusive ext
>    one is a shared test database whose harness truncates tables, where a concurrent
>    run is data corruption rather than a slowdown.
>    Add to the dispatch contract: name any exclusive resource in each wave brief,
>    tell concurrent waves to run scoped unit tests only,he
>    exclusive suite once, serially, after the concurrent waves land. Require the
>    parent to state that cost in the wave log rather tha
>
> 5. TIER THE VERIFICATION DEPTH IN claim-integrity.md.
>    Keep every law. It is load-bearing: on this project it caught a doc comment
>    claiming a test existed that did not, and a fixture
>    through an unlisted CASCADE, both inside one hour. But it currently reads as
>    equal-depth re-derivation of every claim, which is wnt
>    time goes.
>    Add a proportionality clause: full independent re-deng
>    money, security, auth, state machines, data loss and anything a test cannot
>    catch; spot-check for cosmetic, naming and formattin
>    proportionality is about WHERE the depth goes, never a licence to assert
>    unverified facts, and that the agent must state whic
>
> For each change, show the before and after text and the
> weaken any allowlist, do not remove the stop-at-first-failure clause, and do not
> make any of this conditional on the user asking for spe
>
> The single highest-value change is the first one. The o

**Note on the paste.** The request arrived truncated in about twelve places. Every
gap was recoverable from context except two: change 4's last sentence and the closing
priority sentence. Q2 below settles change 4. The closing sentence changes nothing,
all five changes land.

## Primary Goal & Guardrails

- **North-Star Goal.** Phase 3 may run independent waves at the same time, and the
  one-agent-per-wave rule survives wherever its own justification holds.
- **In-Scope.**
  - Scope the one-agent-per-wave rule by shared read surface, at every live site that
    states it unconditionally, both agent frontmatter descriptions included.
  - Let the parent merge consecutive waves under stated conditions.
  - Make the spec reviewer declare serial resources and mark concurrency candidates.
  - Add an exclusive-resource clause to the wave dispatch contract.
  - Tier verification depth in `rules/claim-integrity.md`.
  - Release bookkeeping: version 0.16.0, changelog, README badge, demo GIF caption,
    `dist/` re-sync.
  - **Added mid-sprint on the user's instruction, recorded as Q10.** Resume brings a
    work-doc up to the current rules before it continues, and work with no doc is
    adopted rather than restarted. Written down here because the drift-check reads
    this anchor and not the Q&A, so an unamended anchor makes a delivered task look
    like drift. Reviewer B filed exactly that.
- **Out-of-Scope / Non-Goals.**
  - Weakening any file allowlist, in any direction.
  - Removing or softening the stop-at-first-failure clause.
  - Changing phase ordering, or making any of this conditional on the user asking
    for speed.
  - Deleting any claim-integrity law.
  - `skills/quick/SKILL.md`. Quick has no wave plan; its "one implementer for the
    whole change" sentence states a different rule and stays true.
- **Guardrails / Invariants.**
  - `bash scripts/validate-dod.sh` exits 0 at the end, as it did at the start.
  - Every literal check `[40]` and check `[38f]` pin stays present, verbatim:
    `hackify:wave-implementer` at all four dispatch sites,
    `KEEP everything that already landed on disk`,
    `which task IDs landed, which task IDs did not`, `STOP there`,
    `one dispatched implementer per wave`, `no two tasks share a file`.
  - No banned wording is introduced: `Cap a batch at 3 tasks`, `per task BATCH`,
    `Group by module, never by count`, `hackify:wave-task-implementer`.
  - Both mirror pairs stay byte-identical **in the fenced block the sync script
    copies**. The head prose differs by design on both pairs, and the
    wave-implementer pair carries a hand-maintained TAIL holding its `**OUTPUT**`
    skeleton, of which only the region above the `<!-- parent-side: not mirrored -->`
    marker is copied and checked. The spec-reviewer pair has no tail. **The two sides
    of a pair do NOT share a head**, which is why no rule can compare heads at all.
    ← `python3 -c` over `scripts/sync_agent_mirrors.py:split_on_fence`, re-measured at
    the end of Round 8 → wave-implementer mirror head 9 / block 259 / tail 89 against
    template `phase-3-implementation.md` head 6 / block 259 / tail 99, OUTPUT in the
    tail; spec-reviewer mirror head 9 / block 441 / tail 0 against template head 14 /
    block 441 / tail 0, OUTPUT in the block.

    **This figure has now been wrong three times, and the third was mine.** It read
    `head 7 / block 169 / tail 61`; Reviewer B and the completeness critic both filed
    it as M15; I corrected it to `head 7 / block 226 / tail 80` while W8b was still
    running, and W8b's own report pointed out that its diff would land my correction
    stale the moment the wave merged, which it did. Measured geometry belongs to the
    tree at a moment, so a work-doc that quotes it has to be re-measured at the END of
    the round that touched those files, never during it. That is the rule this earns,
    and it generalises past this one number.
  - The new claim-integrity bullet's bold lead **appears in the injected digest**,
    and so does the last lead that was there before it. The digest truncates its
    TAIL silently at 900 characters and never raises, so "length ≤ 900" is true by
    construction and proves nothing on its own.
  - Every new `{{token}}` is declared as the first token of its own numbered INPUTS
    line inside the template prompt, which is the region check `[93]` reads. The
    dispatch table in `parallel-agents/README.md` carries no `**INPUTS**` anchor
    line, so `[93]` does not read it and **no check validates that table**; it is
    kept correct by review, not by a gate.
- **Success Signals.**
  - `bash scripts/validate-dod.sh` prints `ALL CHECKS PASSED` and exits 0.
  - `python3 scripts/sync_agent_mirrors.py --check` reports every mirror matching.
  - `diff` between each agent file and its template shows only the frontmatter block.
  - `python3 -c` over `hooks/inject_context.py` prints a claim-integrity digest
    length at or under 900.
  - `bash scripts/sync-runtimes.sh --dry-run` exits 0.
  - Every CI suite named in `.github/workflows/ci.yml` still exits 0.

## 2. Clarifying Q&A

### Q1 (route)
**Question:** Your global rules say any non-trivial task runs the full hackify
lifecycle, and this is a multi-file change to load-bearing contract files. But your
pasted prompt already contains the diagnosis, the five changes and the acceptance
shape. Which route do you want?
**Answer:** 1-A, full hackify, the prompt stands in for the clarify questionnaire.

### Q2 (change 4, the truncated clause)
**Question:** Change 4's last sentence is cut off. What should the parent be required
to write down about deferring the exclusive-resource suite?
**Answer:** 2-A. The wave log names which exclusive resource was held back, which
suite did not run during the concurrent waves, and that those waves' evidence is
scoped-unit-only until the serial run lands.

### Q3 (scope of the fix)
**Question:** The unconditional rule lives at more sites than the four files you
named, including both agent frontmatter descriptions. How wide should the fix go?
**Answer:** 3-A, the whole family, frontmatter descriptions included.

### Q4 (commits)
**Question:** Once two waves may run at the same time, what should a round of
concurrent waves produce?
**Answer:** 4-A, one commit per concurrent round, listing every task ID in the round.

### Q5 (fan-out ceiling)
**Question:** Should there be a stated ceiling on how many waves run at the same time?
**Answer:** 5-A, no stated number. The partition test and the runtime's own dispatch
limit bound it.

### Q6 (release)
**Question:** How far should the release bookkeeping go?
**Answer:** 6-A, version bump to 0.16.0, changelog entry, README badge, README stays
inside its line budget by compressing an older blurb.

### Q7 (demo GIF)
**Question:** The README's animated demo has "one agent per wave" baked in as a
caption. Regenerate it?
**Answer:** 7-A, regenerate with a caption covering both halves of the new rule.

### Q8 (depth tiers)
**Question:** What about the band between "re-derive everything" and "spot-check":
a behavior claim a passing test already covers?
**Answer:** 8-A, a middle tier. The fresh test output is the re-derivation, cited by
name. Three tiers, and the agent states which one it applied.

### Q9 (who decides the partition)
**Question:** Who works out which waves can run at the same time?
**Answer:** 9-A, the reviewer marks candidates, the parent applies the test and owns
the dispatch.

### Q10 (resuming work planned under older rules), asked mid-sprint

Raised by the user during Round 2, after the rule changes above had already landed in
eleven files. A work-doc written under 0.15.1 describes a workflow that no longer
exists, and nothing in the resume path notices.

**Question:** When we pick up an old hackify doc, or work that was never written down
at all, how much of it gets brought up to the current rules before we carry on?
**Answer:** 10-A on all four parts. Migrate the live doc in place in one edit before
any phase resumes, preserving content and reorganising it, and leave `docs/work/done/`
alone. Re-derive only the part of the plan a changed rule invalidated, name the change
in Daily Updates, and leave ticked tasks ticked and the signed-off order intact.
Undocumented work gets adopted into a current-shape doc rather than routed through a
fresh Phase 1. No validator check: resume runs inside the user's project and the
validator only ever sees this plugin's own tree, so a check here would police the
wrong repo and read as wider coverage than it has.

### Q11 (what a round-end scan does to fix-in-wave), asked mid-sprint

Raised by the wave that settled the run point, which could not fix it from inside its
own allowlist. With the scan at round end, "the agent may fix a trivial candidate in
its own allowlist" describes an agent that has already returned, and
`no-parent-authored-diff` bars the parent from writing the fix itself.

**Question:** Who fixes a trivial scout finding now that the scan runs after the
agents have gone?
**Answer:** 11-A, two run points with different owners and different scopes. Each agent
runs both scouts over its OWN allowlist before it returns and may fix trivial findings
in place, which is the only place that rule ever made sense. The parent runs them again
at round end over the union, which is the only scan that can see a defect crossing two
waves; what it finds is staged for Phase 5 or sent back as a one-task wave. Cost is one
small extra scan per wave.

Scope was settled in the same batch: land all three remaining tasks rather than ship
0.16.0 with a protocol that contradicts itself in eight places.

## 3. Acceptance Criteria

- [x] **AC1.** Every live site that states one-agent-per-wave states it conditionally,
      on shared read surface, and the partition test is written once with the other
      sites pointing at it. The per-agent stop-at-first-failure clause is unchanged.
- [x] **AC2.** The parent may merge consecutive waves when no file collides inside the
      merged set and no dependency edge crosses the merge. "Read the plan rather than
      rebuild it" is stated as a ban on re-planning, not on merging.
- [x] **AC3.** The spec reviewer's report carries a `## Serial resources` section and
      marks which waves are concurrency candidates; its VERIFICATION list gained an
      appended item rather than a renumbered one.
- [x] **AC4.** The wave dispatch contract names any exclusive resource, tells
      concurrent waves to run scoped unit tests only, runs the exclusive suite once
      serially after the concurrent waves land, and requires the parent to record the
      deferred suite plus the coverage gap in the wave log.
- [x] **AC5.** `rules/claim-integrity.md` carries a proportionality law with three
      tiers, states it never licenses an unverified assertion, requires the agent to
      name the tier it applied, and its injected digest measures at or under 900.
- [x] **AC6.** Version reads 0.16.0 in `plugin.json`, in BOTH `marketplace.json`
      plugin entries and the README badge, with a changelog entry, README stays
      inside 250..450 lines, and the demo GIF caption names both halves of the rule.
      **Corrected mid-sprint.** This bullet used to end "`dist/` is regenerated so no
      runtime distribution ships the old rule", which is not a property this repo can
      hold: `dist/.gitignore` is `*` plus `!.gitignore`, so every generated file under
      `dist/` is untracked and a regeneration leaves no diff to commit. The real gate
      is that the sync COVERS every file this sprint touched, so the replacement
      clause is: for every source file the sprint changed, running the sync produces a
      generated counterpart that matches it, and no changed file is missing from the
      sync manifest.
- [x] **AC7.** Resume brings a work-doc up to the current rules before it continues:
      the conformance list lives once, in `work-doc-template.md`, and the resume
      procedure in `SKILL.md` points at it rather than restating it. Migration is one
      edit, made before any phase resumes, it preserves content, it names in Daily
      Updates whatever a rule change forced it to re-derive, and it leaves ticked
      tasks and archived docs alone. Work with no doc is adopted into a current-shape
      one. No validator check is added, and the reason is written down.
- [x] **AC8.** The scouts have two run points with different owners and scopes, stated
      once in `phases/phase-3-implement.md` and copied nowhere without a pointer: the
      agent over its own allowlist before it returns, where fix-in-wave lives, and the
      parent over what that round's waves declared at round end, never the union of their
      allowlists, where cross-wave findings are caught.
      Every site in the tree that names a scout run point agrees with it, and
      `no-parent-authored-diff` is not weakened to make it work.
- [x] All tests pass (every CI suite), 0 failures
- [x] Lint clean, typecheck clean (this repo runs no linter or typechecker; the
      validator and the CI suites are the equivalent gate, see the Repo Brief)
- [x] Original ask demonstrably met. **Delivered as Phase 4 Evidence Ledger output,
      not as a task:** one before/after pair per change, each quoting the live text
      at the site it came from. No Sprint Backlog task owns this bullet by design.

## 4. Approach

**Chosen.** Keep every rule and narrow the ones whose justification is narrower than
their wording. One agent still takes a wave when the wave's tasks share a read
surface; a partition with no file overlap, no import edge either way and no serial
resource in common may go out as concurrent waves, one agent each. The partition test
is written once, in `phases/phase-3-implement.md`, and every other site points at it
rather than restating it. The spec reviewer gains a serial-resources declaration and
marks concurrency candidates, so the parent has the facts without re-deriving them,
but the parent applies the test itself, so a wrong mark cannot start a bad run alone.
The wave contract gains an exclusive-resource input so concurrent agents never both
hold a shared database. Claim integrity gains one proportionality law that says where
depth goes, never that depth may be skipped.

**Considered & rejected.**
- Delete the one-agent-per-wave rule, rejected: its token and coherence savings are
  real whenever a wave's tasks read the same code, which is most waves.
- Let the spec reviewer decide concurrency outright, rejected: a planning mistake
  would reach a concurrent dispatch with nothing between it and the tree.

**Architectural touchpoints.** `skills/hackify/SKILL.md`,
`skills/hackify/references/phases/phase-3-implement.md`,
`skills/hackify/references/orchestration.md`,
`skills/hackify/references/implement-and-test.md`,
`skills/hackify/references/phase-ledger.md`,
`skills/hackify/references/work-doc-template.md`,
`skills/hackify/references/parallel-agents/` (README, the spec-reviewer template, the
implementation template), `agents/spec-reviewer.md`, `agents/wave-implementer.md`,
`skills/yolo/SKILL.md`, `rules/claim-integrity.md`, `CHANGELOG.md`, `README.md`,
`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
`scripts/gen-demo-gif.py`, `docs/assets/hackify-demo.gif`, `dist/`.

### Serial resources

Declared before the wave plan, because they are what decides which waves may run
together. Named under the rule this sprint is adding, and this sprint runs under the
new rules rather than the installed 0.15.1 ones, at the user's direction.

| Resource | Why it serialises | Who holds it |
|---|---|---|
| The canonical wording of the new rule | Nine files copy it. Two agents inventing it at once is exactly the contradiction one-agent-per-wave prevents. | T5, alone, in the foundation round |
| The canonical wording of the two-run-point scout rule | Six files copy it, and T17's eight sites copy it again a round later. Added mid-sprint. | T18, alone, in Round 3 |
| The mirror invariant, check `[75h]` | A commit that moves a template without its mirror reds the validator, so a pair cannot straddle two commits. | T2+T4 in one wave, T3+T4 in one wave |
| `dist/` | Regenerated from every source file the sprint touches. | T12, terminal |
| `README.md` | Its four rule sites and its line budget are one file, so one task owns all of it. | T10 |
| Exclusive external resource | **None this sprint.** No test database, no shared fixture, no generated sequence. The exclusive-resource clause has nothing to hold here, which is why it is written but not exercised. | nobody |

### Execution waves

Waves inside one round run at the same time, one agent each; the parent commits ONCE
per round with every landed task ID in the body. The plan opened at three rounds and
grew to eight, Round 0 through Round 7: Round 2 cleans up three contradictions the
first two rounds left in files no task owned, Round 3 is T16 added mid-sprint, and
Rounds 6 and 7 are the Phase 5 fix rounds. Re-counted from the Daily Updates headings
rather than carried forward, which is how this number went wrong twice already.

```
Round 0 (foundation, 3 concurrent waves)
W0a: T5        <- writes the canonical wording everything else copies
W0b: T1        <- shares no file and no read surface with T5 or T11
W0c: T11

Round 1 (4 concurrent waves, all copying the now-frozen wording)
W1a: T2, T4    <- template then its mirror, one commit
W1b: T3, T4    <- template then its mirror, same wave family
W1c: T6, T7, T8
W1d: T9, T10

Round 2 (2 concurrent waves, follow-on defects the first two rounds created)
W2a: T13, T14  <- T14 re-anchors a citation INTO the file T13 rewrites, so order matters
W2b: T15

Round 3 (2 concurrent waves)
W3a: T18       <- holds the canonical two-run-point wording, so it runs alone in its lane
W3b: T16       <- shares no file with T18 and does not read the run-point prose

Round 4 (1 wave)
W4a: T17       <- copies T18's wording, so it cannot share a round with it

Round 5 (terminal, 1 wave, two tasks in order)
W5a: T20, T12  <- T20 is the tenth run-point site; T12 depends on it and on
                  everything else, so they share one agent rather than one round each
```

Round 3 is the serial-resource mechanism this sprint added, used on itself: T18 owns a
piece of wording six files will copy, so it gets a lane of its own, and T16 runs beside
it only because it shares no file with T18 and copies nothing T18 is writing. T17 could
not join them, and that is the test refusing rather than the plan being cautious.

Partition test applied, and it is the test T5 is about to write: within each round the
waves' allowlists share no file, no wave reads prose another wave in the same round is
writing, and no serial resource above is held by two of them. T4 appears in both W1a
and W1b because the mirror step is one task split across two pairs; it is dispatched
once, in W1a, and W1b's agent leaves `agents/wave-implementer.md` alone until W1a's
sync has run. **That is a shared file between two concurrent waves, so it fails the
test.** Corrected below.

**Corrected Round 1** (the partition test refuses the version above):

```
Round 1 (4 concurrent waves)
W1a: T2, T3, T4   <- both templates AND both mirrors, one agent, one read surface
W1b: T6, T7
W1c: T8, T9
W1d: T10
```

`agents/` is written by exactly one wave. T6 and T7 share the skill's own vocabulary
so they stay together; T8 and T9 are dispatch-table and yolo restatements with no
file overlap against anything else in the round.

### Repo Brief

- **Stack:** Claude Code plugin. Markdown skills and agent contracts, bash validator
  fragments, python test suites. No application runtime, nothing to compile.
  ← `cat .claude-plugin/plugin.json` → `"name": "hackify", "version": "0.16.0"`
- **Commands:** test `bash scripts/validate-dod.sh` plus the sixteen suites named in
  `.github/workflows/ci.yml` (`python3 scripts/test_*.py`, `bash hooks/test_*.sh`,
  `bash scripts/test_ban_tokens.sh`); lint: none; typecheck: none.
  ← `ls CLAUDE.md AGENTS.md biome.json package.json` → no matches;
  `sed -n 80,200p .github/workflows/ci.yml`
- **Layout:** `skills/` the workflow prose, `agents/` the registered subagent
  contracts, `rules/` the always-on injected law, `hooks/` the injector,
  `scripts/validate-dod.d/` the numbered check fragments, `dist/` generated.
  ← `ls` at repo root
- **Layering rule:** the canonical prompt is
  `skills/hackify/references/parallel-agents/<template>.md`; `agents/<name>.md` is its
  mirror. Edit the template, then sync.
  ← `scripts/sync_agent_mirrors.py:47-59` (`MIRROR_PAIRS`)
- **Rules source:** no project `CLAUDE.md`, so `~/.claude/CLAUDE.md` governs alone,
  with the plugin's own `rules/` as the always-on layer.
  ← `ls CLAUDE.md` → no such file
- **Test convention:** every tracked test suite must be named in `ci.yml` or reachable
  by import from one that is; check `[97]` enforces it.
  ← `bash scripts/validate-dod.sh` → `all 18 tracked test suite(s) reach CI`
- **Landmines:**
  - `sync_agent_mirrors.py` copies only the FIRST fenced block, which ends at the
    VERIFICATION bash fence. The OUTPUT skeleton and the head prose above the fence
    are hand-maintained on BOTH sides and `--check` reports "ok" while they differ.
    ← `scripts/sync_agent_mirrors.py:64-77`
  - Check `[40]` pins live literals and bans retired ones over the whole tracked tree.
    ← `scripts/validate-dod.d/73-implementer-rename.sh:52-74, 292-338`
  - The injected digest is built from bold bullet leads and truncates the TAIL at 900
    characters. `rules/claim-integrity.md` measures 895 today, so the headroom is 5,
    not the 123 the pre-sprint figure implied.
    ← `python3 -c` over `hooks/inject_context.py:47-97` → `777`
  - `README.md` is at 448 lines against a 250..450 bound, so a new blurb must be paid
    for by cutting an old one. ← `wc -l README.md` → `448`;
    `scripts/validate-dod.d/20-templates.sh:4`

## 5. Sprint Backlog

- [x] **T5**, Phase 3 protocol, THE FOUNDATION. Write the partition test once, in full, as the canonical wording every other site points at. Also: permit wave merging (replacing the wrapped sentence at `:72-73`), the serial-resources foundation-wave instruction, the exclusive-resource dispatch row, the round-level commit rule, and the wave-log line naming the deferred exclusive suite plus the coverage gap it leaves. Files: `skills/hackify/references/phases/phase-3-implement.md`. → verify: `grep -c 'merge two waves into one dispatch' skills/hackify/references/phases/phase-3-implement.md` returns 0 (the live phrase wraps across `:72-73`, so the one-line form `Never merge two waves` has never matched and proves nothing); `grep -F 'shared read surface'` on the same file hits; `grep -F 'STOP there'` is untouched elsewhere.
- [x] **T1**, claim-integrity tiering: add the proportionality law as a bulleted rule with a short bold lead ending in a period, plus the procedure naming the three tiers. Files: `rules/claim-integrity.md`. → verify: run `hooks/inject_context.py`'s `digest_of` and assert BOTH that the NEW lead appears in the digest AND that `Say what the checks do not reach` still appears. The digest truncates its tail silently at 900 and never raises, so an appended lead is exactly what vanishes; asserting the length alone is a check that cannot come back dirty.
- [x] **T11**, demo GIF: update the Phase 3 caption in the generator and re-render. Files: `scripts/gen-demo-gif.py`, `docs/assets/hackify-demo.gif`. → verify: the caption string in the generator names both halves of the rule, and the re-rendered file exists at 1200x675 with 7 frames.
- [x] **T2**, spec-reviewer contract (canonical side): add the serial-resources METHOD step, the concurrency-candidate marking, an APPENDED VERIFICATION item 21 (never a renumber, the file cross-cites its own item numbers), the `## Serial resources` output section plus the matching `21. <yes|no>` skeleton row, and rewrite the `wave_size_target` prose at `:76-79` and the step-10 sentence at `:162-165` that says no grouping decision is left at dispatch time. Files: `skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md`. → verify: on THAT file, `grep -F 'Serial resources'` hits, `grep -F 'one dispatched implementer per wave'` still hits, and `grep -F 'no two tasks share a file'` still hits (both pinned by `71-release-mechanism-pins.sh:305-307`).
- [x] **T3**, wave-implementer contract (canonical side): add `{{exclusive_resources}}` as the first token of its own numbered INPUTS line (item 13), the METHOD clause telling a concurrent wave to run scoped unit tests only and to leave the exclusive suite to the parent, the head prose scoping the rule by shared read surface, AND the post-fence parent-side tail at `:237-244`, whose step 6 currently reads `Single commit for the wave` and must become the round-level rule. **Plus a defect this sprint creates:** the contract's `VERIFICATION` step (a) diffs the WHOLE tree (`git diff --name-only HEAD`) against one wave's allowlist, so under concurrent dispatch every agent sees its neighbours' files and reports a false allowlist breach. Both Round 0 agents hit it. Scope that diff to the wave's own paths. Files: `skills/hackify/references/parallel-agents/phase-3-implementation.md`. → verify: on THAT file, `grep -F 'exclusive_resources'` hits a numbered INPUTS line, `grep -F 'STOP there'` and `grep -F 'KEEP everything that already landed on disk'` and `grep -F 'which task IDs landed, which task IDs did not'` all still hit.
- [x] **T4**, mirrors: run `python3 scripts/sync_agent_mirrors.py`, then hand-carry what it does not copy. `agents/wave-implementer.md` has a 61-line TAIL holding its `**OUTPUT**` skeleton that the script never touches, so T3's OUTPUT changes must be applied there by hand; `agents/spec-reviewer.md` has no tail and needs none. Then hand-edit BOTH frontmatter `description:` lines, since that is what the dispatcher reads at dispatch time. Files: `agents/spec-reviewer.md`, `agents/wave-implementer.md`. → verify: `python3 scripts/sync_agent_mirrors.py --check` reports both matching, AND a `python3 -c` comparison of `split_on_fence(...)[2]` (the tail) between `agents/wave-implementer.md` and its template shows the OUTPUT skeleton agreeing on both sides. Depends on T2 and T3; runs after them inside the same wave, so the mirror and its template land in one commit ([75h] reds on a commit that moves one without the other).
- [x] **T6**, main skill: rewrite the Phase 3 heading `:130`, the parallelism paragraph `:56`, the dispatch paragraph `:134`, the ledger clause `:75`, the parallel-agents exception sentence `:236` and the anti-rationalization row `:348`. Files: `skills/hackify/SKILL.md`. → verify: on THAT file, `grep -F 'no cap, no module split, no grouping decision at dispatch time'` returns 0 and `grep -F 'shared read surface'` hits.
- [x] **T7**, the three reference files that restate the rule. `implement-and-test.md:3,5` (and its `:35` commit step, which must become the round rule), `phase-ledger.md:92` plus the `:158` anti-rationalization row, `orchestration.md:24` run-point row. Files: `skills/hackify/references/implement-and-test.md`, `skills/hackify/references/phase-ledger.md`, `skills/hackify/references/orchestration.md`. → verify: one grep per file, each naming that file's own string: `grep -F 'no cap on wave width' implement-and-test.md` → 0; `grep -F 'Phase 3 is the one place that gives it up on purpose' phase-ledger.md` → 0; `grep -F 'one implementer for the whole wave' orchestration.md` → 0.
- [x] **T8**, dispatch table: update the wave-implementer INPUTS row with `exclusive_resources` and the scoped rule, and the spec-reviewer row with the serial-resources deliverable. Files: `skills/hackify/references/parallel-agents/README.md`. → verify: on THAT file, `grep -F 'exclusive_resources'` hits, `grep -F 'No cap, no module split, in any mode'` returns 0, and `grep -F 'hackify:wave-implementer'` still hits (pinned by `73-implementer-rename.sh:52-60`). No validator reads this table; the greps are the whole gate.
- [x] **T9**, yolo mode: the three sites that restate the unconditional rule, `:22`, `:67`, `:116`. Files: `skills/yolo/SKILL.md`. → verify: `grep -F 'no cap, no module split' skills/yolo/SKILL.md` returns 0 and `grep -F 'hackify:wave-implementer'` still hits.
- [x] **T10**, release bookkeeping AND the four README rule sites. Version 0.16.0 in `plugin.json` and BOTH `marketplace.json` plugin entries (`hackify` and `hackify-edge`), the README badge, a changelog entry, README kept inside 250..450 by compressing an older blurb, and the four README sites that state the old rule: `:81` (inside a fixed-width ASCII box, the box border must stay aligned), `:99`, `:267`, `:380`. Files: `CHANGELOG.md`, `README.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`. → verify: `bash scripts/validate-dod.sh` shows `[16]`, `[16b]` and `[7]` green, and `grep -F 'one foreground subagent per whole wave' README.md` returns 0.
- [x] **T13**, reconcile the scout run point, which the foundation changed under three files nobody owned. `phases/phase-3-implement.md:22,40` now runs a loop headed "run once per round" whose step 6 scans "the round-touched files (union of every wave's allowlists)". Contradicting it: `perf-scout.md:16` and `law-scout.md:18` both key the run point to "Phase 3, every wave-end | Union of the wave's file allowlists", with the same wave framing at `law-scout.md:35,100,122` and `perf-scout.md:128,149`; `phase-ledger.md:103` keys its Phase 3 exit artifact to wave-touched files, left that way on purpose by T7 rather than contradict the protocol files across a boundary it could not close; `skills/yolo/SKILL.md:14,67,116` says "both scouts at every wave-end". Settle it as ROUND-level, because ticking now happens at round end and the parent runs its checks once per round. Fix-in-wave stays exactly as it is: an agent may still fix a trivial candidate inside its own allowlist. Also `work-doc-template.md:104`, the last stale copy of "One commit closes the whole wave, never one per task". Files: `skills/hackify/references/perf-scout.md`, `skills/hackify/references/law-scout.md`, `skills/hackify/references/work-doc-template.md`, `skills/hackify/references/phase-ledger.md`, `skills/yolo/SKILL.md`. → verify: `grep -cF -- 'every wave-end' perf-scout.md law-scout.md` returns 0 for both; `grep -cF -- 'One commit closes the whole wave' work-doc-template.md` returns 0; the fix-in-wave sentences survive in both scout files.
- [x] **T14**, two stale line citations, one of which this sprint made worse. `phases/phase-5-review.md:94` and `parallel-agents/phase-5-refute.md:257` both cite `skills/yolo/SKILL.md:108` as the authority for yolo's both-lenses-refuted-Critical rule. It was ALREADY wrong before this sprint: the rule sat at `:110`, and `:108` was a different table row. T9's one-line wrap moved it to `:111`, so the drift went 2 → 3. The doc-link checker cannot catch it, because its line-citation form only asserts the line EXISTS and the file only got longer. Re-anchor both to something that survives an edit above it, naming the row rather than its line number, per the claim-integrity law that says anchor to a symbol or heading where a citation must outlive one wave. A third copy sits in `docs/work/done/2026-08-23-wave-implementer-migration.md`; leave it, an archived work-doc is a historical record. Note `phase-5-refute.md:257` sits in that file's hand-maintained TAIL (head 67 / block 174 / tail 25), so it is NOT synced, and `agents/finding-refuter.md` does not carry the sentence at all, verified by grep. Files: `skills/hackify/references/phases/phase-5-review.md`, `skills/hackify/references/parallel-agents/phase-5-refute.md`. → verify: `grep -rn 'yolo/SKILL.md:108' --include='*.md' skills/ agents/` returns nothing, and `python3 scripts/check_doc_links.py .` exits 0.
- [x] **T15**, the dispatch table contradicts the contract on the new input. `parallel-agents/phase-3-implementation.md:70-75` says `none` is passed explicitly, that the input is never absent, and that an absent value means the dispatcher did not decide so the agent refuses. `parallel-agents/README.md:20` describes it as "(the exclusive resource this wave holds, empty when none)". A dispatcher reading the table passes empty and the agent refuses. No check reads this table, which is why the greps are the whole gate. Also make the row's plural agree with the contract, which takes one resource per line. Files: `skills/hackify/references/parallel-agents/README.md`. → verify: `grep -cF -- 'empty when none' skills/hackify/references/parallel-agents/README.md` returns 0; the row still says `none` explicitly; `grep -F -- 'hackify:wave-implementer'` still hits.
- [x] **T16**, resume migrates the doc before it resumes. Added mid-sprint at the user's request, and its target is the defect this sprint just created: eleven files now describe a Phase 3 that a doc written under 0.15.1 does not, and the resume path reads that doc without noticing. Write the conformance list ONCE, in `work-doc-template.md`, since that file IS the shape: the `## 0. Phase ledger` block, the Primary Goal & Guardrails anchor, the Repo Brief, the current section labels and the required frontmatter keys. Then `SKILL.md`'s Pause / Resume section gains the migration step, placed before the "resume from the appropriate phase" step so it cannot run after the phase it is meant to correct, and it points at the template rather than restating the list. Rewrite the `Back-compat: section-name labels` bullet, which today says the legacy labels are simply accepted and no migration is required: legacy labels are accepted on READ, then renamed in the migration edit, and `docs/work/done/` stays exempt. `SKILL.md:62` (`State is the file`) and `SKILL.md:78` plus `phase-ledger.md`'s resume clause all describe the no-section-0 case as a permanent fallback; make it a one-time migration that writes the block in, so the fallback stops firing every session. Cover the no-doc case: work picked up off a branch is adopted into a current-shape doc, with the phases that genuinely already happened marked completed with a one-line reason. Files: `skills/hackify/SKILL.md`, `skills/hackify/references/work-doc-template.md`, `skills/hackify/references/phase-ledger.md`. → verify: on `work-doc-template.md`, a grep for the conformance heading hits; on `SKILL.md`, `grep -F 'No migration of archived docs is required'` returns 0 and the migration step appears at a lower line number than the `resume from the appropriate phase` step, checked by comparing the two `grep -n` results rather than by eye; `python3 scripts/check_doc_links.py .` exits 0. Depends on T13, which rewrites two of the same three files, so it cannot share a round with it.
- [x] **T18**, the scouts get two run points, THE FOUNDATION for this round. Raised by the Round 2 wave that could not fix it from inside its allowlist. Round-end scanning left `phases/phase-3-implement.md:42` saying trivial candidates are "fixed in-wave" by an agent that has already returned, with `no-parent-authored-diff` (`skills/yolo/SKILL.md:12`, pinned by check `[78]`) barring the parent from writing it. Write the canonical two-run-point rule once, in `phase-3-implement.md`: the AGENT runs both scouts over its own file allowlist before it returns and may fix trivial in-allowlist candidates in place, and the PARENT runs them again at round end over the union, where a defect crossing two waves is the only thing that can be seen, staging what it finds for Phase 5 or sending it back as a one-task wave. Then propagate to the two scout protocols' own run-point tables and their "why the run point is the round" paragraphs, which now state only half the answer, to the wave contract (the agent side is a new METHOD obligation) and its mirror, and to yolo, which restates both points. Files: `skills/hackify/references/phases/phase-3-implement.md`, `skills/hackify/references/perf-scout.md`, `skills/hackify/references/law-scout.md`, `skills/hackify/references/parallel-agents/phase-3-implementation.md`, `agents/wave-implementer.md`, `skills/yolo/SKILL.md`. → verify: both scout tables carry two Phase 3 rows naming different owners and different scopes; `python3 scripts/sync_agent_mirrors.py --check` reports 9 of 9; `grep -F 'no-parent-authored-diff' skills/yolo/SKILL.md` still hits; `bash scripts/validate-dod.sh` exits 0. Holds the canonical wording, so it takes a wave nobody shares.
- [x] **T17**, the eight sites T13 could not reach. Re-derived at `94edbd3` rather than taken from the wave's report: `skills/hackify/SKILL.md:16,136,248,324`, `references/expert-mindset.md:26`, `references/runtime-adapters.md:112`, `rules/expert-mindset.md:15`, `rules/perf-guardrails.md:24`, all still keying the scouts to wave-end. `SKILL.md:136` is the one a reader hits first. Two of them are always-on injected rules, so the digest has to be re-measured after the edit rather than assumed unaffected. **A ninth, added after the fact and after I had written the opposite.** I ruled `phase-ledger.md:103` out on the grounds that its scout clause already reads round-end. That was true against the round-ONLY design and stops being true the moment T18 lands two run points: the row will then name the parent's scan and silently omit the agent's. No `wave-end` grep can ever fire on it, because it says round-end. Its other phrase, "wave-end persistence", is a different per-wave concept and IS correct as written; leave that alone. The file is free by Round 4. Depends on T18, whose two-run-point wording is what these eight must copy, so it cannot share a round with it. Files: `skills/hackify/SKILL.md`, `skills/hackify/references/expert-mindset.md`, `skills/hackify/references/runtime-adapters.md`, `rules/expert-mindset.md`, `rules/perf-guardrails.md`, `skills/hackify/references/phase-ledger.md`. → verify: the `wave-end` sweep across `skills/ rules/ agents/` returns only sites where the phrase is about persistence rather than a scan, AND a second sweep for `round-end` finds no site naming the parent's scan without the agent's, which is the check the first sweep cannot make; both injected digests re-measured at or under 900 with their final bold leads still present; `bash scripts/validate-dod.sh` exits 0.
- [x] **T20**, the tenth site, found by the sweep built to find it. `README.md:97` reads "At each round-end the parent runs both deterministic scouts over the round-touched files ... surviving findings are staged for Phase 5". Same defect shape as `phase-ledger.md:103`: it names the parent's scan and silently omits the agent's, and no search for the old `wave-end` wording can ever see it. Confirmed by the parent at `ceb10a8` with an independent sweep, after T17's agent reported it from outside its own allowlist. It was T10's file and no task owned it once T10 closed, so **AC8 does not hold until this lands.** Keep `README.md` inside its 250..450 line bound, checked by `[7]`. Files: `README.md`. → verify: the round-end sweep across `skills/ rules/ agents/ README.md` finds no site naming a scout run point that mentions the parent or round-end without the agent's run; `bash scripts/validate-dod.sh` shows `[7]` green and exits 0.
- [x] **T12**, run the runtime sync and prove it COVERS the sprint. TERMINAL: it depends on every other task, because it copies what they wrote. **Its original verify criterion was unachievable and is replaced.** Measured at `94edbd3`: `dist/.gitignore` holds `*` and `!.gitignore`, so `git ls-files dist` returns exactly one path, the ignore file itself, and every generated file under `dist/` is untracked. `bash scripts/sync-runtimes.sh --dry-run` prints `WOULD WRITE` for all 798 files across all 7 runtimes and exits 0 on every run; it carries no idempotence check, so "exits 0 reporting nothing left to write" is a state it can never reach and a green proved nothing. That green was recorded at all three round-end gates so far with this task still open, which is the clean-result law firing on my own exit criterion. Replacement: run the sync for real, then for every source file this sprint changed (`git diff --name-only <sprint-base>..HEAD`, restricted to the paths the manifest carries) assert the generated counterpart exists and is byte-identical, and assert no changed source file is absent from the dry-run plan, which is what would catch a new file missing from the manifest. Files: `dist/`. → verify: the per-file comparison above reports zero mismatches and zero unplanned files, with the file COUNT printed so a zero cannot be a comparison that read nothing; `bash scripts/validate-dod.sh` exits 0.

### Fix backlog (Phase 5 round 1, all 15 upheld, then 2 more found mid-fix)

Numbered F1 to F17 against the finding they close. F16 and F17 were found by fix
waves during Round 6, not by the panel, which is why the heading count and the list
length differ. Wave assignment applies the same
partition test the sprint added.

- [x] **F1**, Critical. Rebuild the allowlist containment gate per 7-A. The agent
  declares every path it wrote in a new OUTPUT field; the parent reconciles the round
  three ways. Remove the `|| true` report-only form at
  `parallel-agents/phase-3-implementation.md:211` and its mirror, replace the tautology
  at `:292`, fix the unscoped third site at `implement-and-test.md:25-33` (NOT `:252`,
  which is a commit fence), and give `phases/phase-3-implement.md:31-33` the method it
  currently lacks. → verify: each of the three parent checks demonstrated failing on a
  planted breach, a planted double-claim and a planted unclaimed path.
- [x] **F2**, Critical. `phases/phase-3-implement.md:66` says "Left empty when the wave
  holds none" against a contract that refuses on absent. Make it the explicit `none`,
  and name the refusal the way the Repo brief row two lines above does.
- [x] **F3**, Critical. `SKILL.md:108` says a commit closes a wave; every protocol site
  and the user's own Q4 answer say it closes a round.
- [x] **F4**, Important. `README.md:97` and `:32` state the partition test narrower than
  the canonical, dropping "in EITHER direction" and the prose/config clause, and cite no
  canonical. On a prose tree that makes condition 2 vacuous.
- [x] **F5**, Important. Goal anchor amended for Q10 (done by the parent, above), and
  `work-doc-template.md`'s conformance point 6 (status versus directory) narrowed to
  what T16 authorises, or its extra scope stated.
- [x] **F6**, Important. `perf-scout.md:22` and `law-scout.md:24` justify the second run
  point with a reason that is unsupported on a single-wave round. State what the parent
  scan answers there that the agent scan cannot: whether the agent ran it at all, and
  whether fix-in-wave regressed after the agent's own scan.
- [x] **F7**, Important. The spec reviewer is told to apply the partition test in a file
  its own read pass forbids it to open, so its lossy inline restatement is all it has.
- [x] **F8**, Important. `implement-and-test.md` names no scout at all; its step 8 ticks
  and step 9 commits with no scan between.
- [x] **F9**, Important. `phases/phase-3-implement.md:12-18` steps 1, 3 and 4 re-plan
  what the spec reviewer produced. **Step 5 stays**, it is the sanctioned parent check
  and the only backstop for F7.
- [x] **F10**, Minor. The Evidence Ledger's counts. Fixed by the parent, above.
- [x] **F11**, Minor. The mirror tail check per 8-A. Note `finding-refuter` has tail 0
  against a template tail of 25, so a naive full-equality fallback reds on a healthy
  tree; the marker has to account for it.
- [x] **F12**, Minor. `README.md` at 448 of 450. Pay for any new line by compressing an
  older release blurb, never by raising the bound.
- [x] **F13**, Minor. "Serial resource" and "exclusive resource" are different sets, a
  shared file is serial but not exclusive, and no site states the mapping the parent
  performs at dispatch.
- [x] **F14**, Minor. `## Scout dispositions` is named by both scout protocols and never
  by the file claiming at `:162-163` that every site points back to it.
- [x] **F15**, Minor. Per 9-A, make the parent compare its own partition verdict against
  the reviewer's `[concurrency candidate]` mark and say something when they disagree.
- [x] **F16**, Important. Found by the F6 wave on its way out, in a file it did not
  hold. `phases/phase-3-implement.md` run point 2 carries the SAME unsupported claim F6
  just fixed in the two copies: "This is the only scan that can see a defect crossing
  two waves, which is the whole reason this run point is the round." After F6 the two
  scout protocols give three reasons and point at the canonical, so **the pointer now
  leads somewhere weaker than the copies.** Handed to the wave that holds that file
  mid-flight, by message, rather than spending a round on it. Note the precision that
  wave established: the two scopes are not identical even on a single-wave round,
  because the agent row scopes to the files it LANDED and the parent row to the
  allowlist union, and those differ when a wave stops early.
- [x] **F17**, Minor, two small things the F3/F4 wave raised about its own file.
  `README.md:238` names the partition test without restating its conditions and cites
  no canonical, so it narrows nothing but AC1's "other sites pointing at it" does not
  hold there literally. And that wave took `EITHER` in caps at `README.md:32` to satisfy
  a literal in my verify line, then flagged that README's house style is bold rather
  than caps (one other all-caps run in 448 lines) and offered to downcase it. Its
  judgment is better than my verify line was; downcase and keep the substance.

## 6. Daily Updates

### Round 0 (T5, T1, T11), three concurrent waves

- **Dispatch shape:** three waves at once, one agent each, under the rule this sprint is
  writing rather than the installed 0.15.1 one, at the user's direction. Partition test
  applied: `phase-3-implement.md`, `rules/claim-integrity.md` and the GIF generator share
  no file, no read surface and no serial resource.
- **Exclusive resources:** none held this round. No test database, no generated sequence,
  no shared fixture. The exclusive-resource clause had nothing to hold, so no suite was
  deferred and no coverage gap was incurred.
- **T5 (foundation), landed.** Wrote the canonical wording nine other files will copy:
  the shared-read-surface scoping, the three-condition partition test, the merge
  permission, the serial-resource foundation wave, the exclusive-resource clause and the
  round-level commit. `python3 scripts/check_doc_links.py .` exits 0 over 116 files and
  66 line citations. Corrected the brief: the file was 105 lines, not 106. Generalised
  partition condition 2 to prose and config trees, without which the test cannot be
  applied to this repository.
- **T1, landed.** Added the proportionality law and the `### Choosing the depth`
  procedure. Digest measured at 895 characters against the 900 cap, and the check was
  proved able to fail twice first: a planted over-long lead returned 903 and the
  pre-existing final lead dropped out; the unedited file returned 777 with the new lead
  absent. `bash hooks/test_inject_context.sh` → 66 passed, 0 failed. The tier paragraphs
  were deliberately written unbulleted, because a bolded bullet lead would have entered
  the digest and blown the budget.
- **Defect this sprint created, found by two agents independently.** The wave contract's
  `VERIFICATION` step (a) diffs the whole tree against one wave's allowlist, which cannot
  tell a concurrent wave's edits from a breach. Routed to T3.
- **Environment landmines for later waves.** `grep` resolves to `ugrep` here and parses a
  leading `-` in a pattern as an option, which made fourteen checks return the same
  confident wrong answer until it was re-run with `--`. `${PIPESTATUS[0]}` is empty under
  `zsh`; the array is `pipestatus` and it is 1-indexed.
- **Headroom warning.** The claim-integrity digest now sits at 895 of 900. The next
  bolded law added to that file silently drops `Say what the checks do not reach` from
  every prompt after the first.
- **T11, landed.** Caption is now `parallel waves, 1 agent`, measured at 146px against
  the 165px tile with `ImageDraw.textbbox`, the same method the renderer uses. The
  method was validated first by reproducing two recorded numbers exactly. The agent
  proved the new string is in the pixels rather than asserting the re-render: the phase
  3 tile's padding moved 19 → 9, matching `(165-146)//2`, while a control tile stayed
  at 36. GIF 135,296 → 134,070 bytes, 1200x675, 7 frames. It also re-measured a
  nine-row encoder comment block its change had invalidated, and found one recorded
  verdict now holding for the opposite reason.

**Round-end gate, run once for the round.**

- **Diff scope:** `git diff --name-only HEAD` returns exactly the union of the three
  waves' allowlists and nothing else. No wave wrote outside its own paths.
- **Repo-wide validator:** `bash scripts/validate-dod.sh` → exit 0, `ALL CHECKS
  PASSED`, 0 `FAIL` lines, 1452 ok lines.
- **law-scout:** the deterministic tier defaults to a JS/TS extension set, so the first
  run dropped all three files as `paths_unsupported: 3` and its zero meant nothing.
  Re-run with `--text-only-ext .md --text-only-ext .py`: 3 files scanned, 0 findings.
  **That zero is load-bearing for `cap.file-lines` only**, proved by a planted 600-line
  file returning `cap.file-lines File is 600 lines (cap 500)`. It is NOT load-bearing
  for ban tokens: a planted `eslint-disable` in a `.md` file produced no finding, so
  text-mode ban coverage is absent or differently shaped. Ban coverage for this round
  comes instead from check `[40]`'s tree-wide scan inside the green validator.
- **perf-scout:** no candidates, and the reason rather than a bare zero. The round
  changed markdown prose, one python string literal and a comment block. No loop, no
  query, no cache, no fan-out and no render path was touched.
- **Exclusive-resource cost:** none. No suite was deferred, so no wave's evidence is
  scoped-unit-only and there is no coverage gap to carry into the next round.

### Round 1 (T2, T3, T4, T6, T7, T8, T9, T10), four concurrent waves

- **Dispatch shape:** four waves at once. Partition test applied against the round's
  file union: the two agent contracts plus their mirrors, the main skill plus three
  reference files, the dispatch table plus yolo, and the release manifests plus
  `README.md`. No file appears in two waves. All four READ one frozen file,
  `phases/phase-3-implement.md` at `14f8805`, which nobody in the round was writing.
  That is condition 2 satisfied rather than dodged: a shared READ of stable text is
  what let four agents agree without talking to each other.
- **Exclusive resources:** none held. No suite deferred, no coverage gap.
- **All eight tasks landed. None stopped.**
- **My dispatch brief inverted the partition test, and a wave caught it.** W1b's brief
  said "a wave that FAILS the partition test may go out as concurrent waves". The
  frozen file says the opposite: when all three conditions hold, the subsets may run
  concurrently. The agent checked the instruction against the source, wrote the
  correct version at every site, and reported the inversion. A tree-wide grep for
  `fails the partition test` returns nothing, so it reached no file.
- **Three more brief errors, each refuted with a command.** There are five version
  sites, not four: the marketplace's stable channel also pins `source.ref`, which
  check `[27]` compares against the version, so bumping the four named sites alone
  gives a green `[16]` and a red `[27]`. There are five README rule sites, not four:
  `:238` called Phase 3 the exception to parallelism, which is the sentence this
  release removes. And the wave-implementer mirror's hand-carried region was the HEAD
  prose, not the OUTPUT tail I predicted, because none of T3's edits touched OUTPUT.
- **One change worth a reviewer's eye.** T3 could not make the contract's own
  allowlist check sound under concurrency, so it moved the containment verdict to the
  parent, where the frozen protocol already assigns it. The reasoning: git cannot
  attribute an uncommitted edit to a wave, so no pathspec makes an agent-side
  containment proof sound, and scoping the old grep to the union makes it always-true,
  a check that passes and tests nothing. The agent verified the new form live against
  this tree with three waves mid-flight. Flagged for Phase 5 rather than accepted here.
- **A dispatcher-facing mismatch the new input introduced.** The contract says `none`
  is passed explicitly and an absent value means the dispatcher did not decide, so the
  agent refuses. The dispatch table says "empty when none". No check reads that table.
  Routed to Round 2.

**Round-end gate, run once for the round.**

- **Diff scope:** exactly the union of the four waves' allowlists, plus the work-doc,
  which is the parent's. No wave wrote outside its own paths.
- **Mirrors:** `python3 scripts/sync_agent_mirrors.py --check` → 9 of 9 matching, no drift.
- **Validator:** `bash scripts/validate-dod.sh` → exit 0, `ALL CHECKS PASSED`, 0 `FAIL`.
- **Every CI suite:** all 16 named in `.github/workflows/ci.yml` exit 0, including
  `test_token_declarations.py` (which is what proves `{{exclusive_resources}}` is
  properly declared), `test_tamper_battery.py` and `sync-runtimes.sh --dry-run`.
- **law-scout:** 14 files scanned in text mode, 0 findings, `paths_unsupported: 0`.
  Same caveat as Round 0: that zero is load-bearing for `cap.file-lines` and not for
  ban tokens on text files. Ban coverage comes from check `[40]` inside the validator.
- **perf-scout:** no candidates. Markdown prose and two JSON manifests. No loop, query,
  cache, fan-out or render path.

### Round 2 (T13, T14, T15), two concurrent waves

- **Dispatch shape:** two waves. The round exists because Rounds 0 and 1 left three
  contradictions in files no task owned at the time. Partition test against the round's
  union: seven files in one wave, one in the other, nothing shared, and neither wave
  reads prose the other is writing. The frozen read is `phases/phase-3-implement.md`
  at `6c9e716`, which nobody in the round touched.
- **Exclusive resources:** none held. No suite deferred, no coverage gap.
- **Ordering inside a wave carried weight for the first time.** T14 re-anchors two
  citations that point INTO a file T13 rewrites, so the brief said the order was
  load-bearing and the agent re-measured the target after T13 landed rather than
  trusting the line number in the brief. It came back `:111`, which is what the brief
  said, but the check is the point: the same brief handed to a wave that ran T14 first
  would have anchored against text about to move.
- **All three tasks landed. None stopped.**
- **My verify grep was too narrow, and the agent said so.** The brief asked for
  `grep -cF 'every wave-end'` returning 0 on both scout files. That phrase never
  matched three of the stale sites (`perf-scout.md:128`, `law-scout.md:35`,
  `law-scout.md:100`), so a green on my grep was compatible with three live
  contradictions. The agent widened the sweep to `wave-end` and `wave-touched`, fixed
  all three, and reported that the narrow form proves nothing. This is the
  clean-result law firing on my own check rather than on the tree.
- **Two more brief errors refuted with commands.** The yolo sites are `:14`, `:68`,
  `:117`, not `:14`, `:67`, `:116`: a line above them had wrapped since I measured.
  And on the other wave, the dispatch table's spec-reviewer row claimed the
  `## Serial resources` section marks concurrency candidates; it does not, the mark
  lives on the `## Proposed wave plan` lines. That agent fixed a row my brief had not
  even named, because the brief asked it to re-read the whole row against the
  contracts rather than only the cell I had flagged.
- **T13 does NOT close its own family, and the agent said so plainly.** Eight sites
  outside its allowlist still key the scouts to wave-end, including
  `skills/hackify/SKILL.md:136`, which is the one a reader hits first. Routed to
  Round 3 as T17 rather than left as a footnote.
- **A contradiction the round-level move sharpened.** With the scan at round end,
  "the agent may fix a trivial candidate in its own allowlist" describes an agent that
  has already returned. Pre-existing at `phases/phase-3-implement.md:44`, not created
  here, and unfixable from inside either wave's allowlist. Routed to Round 3 as T18.

**Round-end gate, run once for the round.**

- **Diff scope:** exactly the union of the two waves' allowlists, plus the work-doc,
  which is the parent's. No wave wrote outside its own paths.
- **Mirrors:** `python3 scripts/sync_agent_mirrors.py --check` → 9 of 9 matching, exit 0.
- **Validator:** `bash scripts/validate-dod.sh` → exit 0, `ALL CHECKS PASSED`, 0 `FAIL`.
- **Every CI step:** all 17 `run:` steps in `.github/workflows/ci.yml` exit 0, driven
  off the file itself rather than off a remembered list. **A correction to the two
  rounds above, which both recorded "all 16":** the file carries 17 steps, 15 test
  suites plus the validator and the sync dry-run. The rounds were green, the count in
  their entries was not counted. First attempt at this sweep failed all 17 at once on
  a `sed` that did not strip the YAML key, which is the loud failure a silent one
  would have hidden.
- **law-scout:** `--text-only-ext .md --text-only-ext .py`, 8 files scanned,
  `paths_unsupported: 0`, 0 findings. Same caveat as both earlier rounds: that zero is
  load-bearing for `cap.file-lines` and not for ban tokens on text files, where the
  coverage comes from check `[40]` inside the validator.
- **perf-scout:** no candidates. Markdown prose only, no loop, query, cache, fan-out
  or render path.

### Round 3 (T18, T16), two concurrent waves

- **Dispatch shape:** two waves, and this is the round where the sprint used its own
  serial-resources mechanism on itself. T18 holds a piece of wording six files copy,
  so it ran in a lane nobody shared. T16 ran beside it only because it shares no file
  with T18 and copies nothing T18 was writing. T17 could not join either of them, and
  that is the partition test refusing rather than the plan being cautious.
- **Exclusive resources:** T18 held the canonical two-run-point wording. No suite was
  deferred, no coverage gap, since neither wave holds a test resource.
- **Both tasks landed. Neither stopped.**
- **T18 dogfooded the obligation it was writing.** The new rule says an agent runs both
  scouts over its own allowlist before returning. That agent did exactly that over its
  own six files, and then proved the resulting zero was load-bearing by planting a
  621-line markdown file, which came back `cap.file-lines`. This is the first wave in
  the sprint to run the agent-side scan, because until it landed there was no such rule.
- **Five more brief errors refuted with commands, across the two waves.** The mirror's
  fenced block ends at the bash fence's CLOSING backticks, not its opener, measured
  6/193/69 against 7/193/61. Yolo had a fifth scout site my brief missed. Law-scout's
  comment is one line, not two. And on the other wave: the back-compat bullet is two
  lines off where I put it, it carries five legacy labels rather than the four I named,
  and `SKILL.md:61` listed ten frontmatter keys against the template's eleven. Every
  correction went in the direction of keeping more, not less.
- **One design call I did not specify and would not have.** T18 declined to add a
  VERIFICATION bash counterpart for the agent-side scan, on the grounds that the block
  is a binary gate and a scout finding must not fail a wave. The attestation went to a
  new wave-level `## Scout dispositions` OUTPUT section instead. Correct, and it is the
  kind of call the one-agent-per-wave rule exists to let an agent make.
- **The resume migration became step 4, before the confirm.** T16's own reasoning: a
  re-partition moves both the status and the upcoming task the confirm line quotes, so
  confirming first would quote numbers about to change. Stated in the step so a later
  reader knows it is deliberate.
- **A gate that cannot come back dirty, found by a wave and confirmed here.**
  `scripts/sync_agent_mirrors.py`'s `sync_pair` compares `mirror_block` against
  `canonical_block` and nothing else; the head and the tail are never compared, and no
  fragment under `scripts/validate-dod.d/` compares tails either. So a mirror's
  hand-maintained OUTPUT skeleton can drift from its template's and `--check` still
  reports 9 of 9. The wave found it when a planted regression printed a false green.
  **Not turned into a task**, because the obvious fix is wrong: the two tails differ by
  design (69 lines against 61 on the pair measured above), so a byte comparison would
  red on a healthy tree. Routed to Phase 5 for the panel to judge what the right check
  is. Recorded here rather than left implicit, per the law about saying what the checks
  do not reach.

**Round-end gate, run once for the round.**

- **Diff scope:** exactly the union of the two waves' allowlists, nine files, plus the
  work-doc, which is the parent's. No wave wrote outside its own paths.
- **Mirrors:** `python3 scripts/sync_agent_mirrors.py --check` → exit 0, with the caveat
  above about what that check does not read.
- **Doc links:** `python3 scripts/check_doc_links.py .` → exit 0.
- **Validator:** `bash scripts/validate-dod.sh` → exit 0, `ALL CHECKS PASSED`, 0 `FAIL`.
- **Every CI step:** all 17 `run:` steps in `.github/workflows/ci.yml` exit 0, driven
  off the file rather than a remembered list.
- **law-scout, parent-side over the round union:** 9 files handed, 9 scanned,
  `paths_unsupported: 0`, 0 findings. Same standing caveat: that zero is load-bearing
  for `cap.file-lines` and not for ban tokens on text files, where check `[40]` inside
  the validator is the coverage.
- **perf-scout:** no candidates. Markdown prose only.
- **The new rule checked directly, not inferred from a green:** both scout protocols
  now carry two Phase 3 rows naming different owners and different scopes
  (`perf-scout.md:16-17`, `law-scout.md:18-19`), the one-disposition sentence still
  hits in both, and `no-parent-authored-diff` still hits twice in yolo.

### Round 4 (T17), one wave

- **Dispatch shape:** one wave, because the partition test refused anything else. All
  nine sites copy wording that Round 3 froze, and six of them sit in files that also
  hold each other's vocabulary. A round with one wave in it is the same rule with one
  wave, which is the sentence the whole sprint has been leaning on.
- **Exclusive resources:** none held.
- **T17 landed. Nothing stopped.**
- **Two of my verify checks could not have come back dirty, and the agent widened both
  rather than reporting green.** The digest check compared each rule file's final bold
  lead against the digest text, but `digest_of` strips trailing punctuation, so a lead
  ending in a period never matches and the check returns FAIL on a healthy file. The
  agent normalised it the way the digest does, then proved the fixed version can still
  fail by planting 60 filler leads until the real one truncated out. The omission sweep
  took three attempts: a line-scoped version false-PASSED on an unrelated clause, and a
  bounded-character fence silently dropped every site whose sentence contains a file
  path, which is most of them. The version it kept prints its in-scope count and was
  proved to discriminate on a known-bad, known-good and independent third case.
- **A tenth site the fix itself created, caught inside the same wave.** `SKILL.md:328`
  read "(same two run points)" and pointed at a line about to name three. Inside the
  agent's allowlist, so it fixed rather than reported, and cited the canonical's own
  "a third run point" for the count.
- **An eleventh site outside the allowlist, and it blocks AC8.** `README.md:97` names
  the parent's round-end scan and omits the agent's. Confirmed by the parent with an
  independent sweep rather than taken from the report. It was T10's file and no task
  owned it after T10 closed. Routed to Round 5 as T20.
- **The advisor was unreachable for this wave.** The agent called it twice, before
  writing and before declaring done, and got "temporarily overloaded" both times.
  Recorded because a missing review is a fact about this diff, not an absence worth
  passing over in silence.

**Round-end gate, run once for the round.**

- **Diff scope:** exactly the wave's six files.
- **Mirrors:** `sync_agent_mirrors.py --check` exit 0, with the standing caveat that it
  reads only the first fenced block. None of these six is a mirror, so it says nothing
  about this diff either way.
- **Doc links:** exit 0. **Hook tests:** `bash hooks/test_inject_context.sh` exit 0.
- **Validator:** exit 0, `ALL CHECKS PASSED`, 0 `FAIL`.
- **Every CI step:** all 17 exit 0, driven off `ci.yml`.
- **Injected digests, re-measured by the parent rather than trusted:**
  `rules/expert-mindset.md` 201, `rules/perf-guardrails.md` 315,
  `rules/claim-integrity.md` 895. All at or under the 900 cap, and the last one is the
  one this sprint grew, so its 5 characters of headroom are worth knowing.
- **law-scout, parent-side over the round union:** 6 handed, 6 scanned,
  `paths_unsupported: 0`, 0 findings. Standing caveat unchanged.
- **perf-scout:** no candidates.
- **The omission sweep run by the parent independently:** every site naming a Phase 3
  scout run point now names both, except `README.md:97`. That is T20.

### Round 5 (T20, T12), one wave, two tasks in order

- **Dispatch shape:** one wave. T12 compares generated output against every source
  file the sprint changed, and T20 changes one of those sources, so the order inside
  the wave was load-bearing rather than cosmetic.
- **Exclusive resources:** `dist/`, the seven generated runtime packages, held by this
  wave alone. Running the sync rewrites 798 files, so no other agent could be running
  beside it. No suite deferred, no coverage gap.
- **Both tasks landed. Neither stopped. The Sprint Backlog is fully ticked.**
- **T20 closed the family.** `README.md:97` was the last site naming the parent's scan
  without the agent's. Line-neutral rewrite, README stays at 448 against its 450 bound.
  The agent's sweep had to be windowed rather than line-scoped, because the two scout
  protocols state the run points as adjacent table rows and a line-scoped version
  false-flags the parent's row. Proved on three planted controls before it was trusted.
- **Four corrections to my brief, each with the command.** 26 changed non-doc paths at
  HEAD, not the 22 I measured two commits earlier. My guess at which files are
  non-payload was wrong on two of five: both files under `.claude-plugin/` ARE payload,
  listed in `CLAUDE_CODE_EXTRA`. Six runtimes are path-for-path copies, not just
  `claude-code`; the seventh, `copilot-cli`, transforms, embedding `SKILL.md` verbatim
  inside a generated `MANIFEST.md`, and the agent compared what is comparable there.
- **And a correction that made my own criticism sharper.** I had recorded that the sync
  dry-run "carries no idempotence check". The agent found it is stronger than that:
  `write_or_announce_copy` prints `WOULD WRITE` unconditionally under `DRY_RUN=1` with
  no destination comparison at all, so there is no code path that could ever report
  nothing left to write. It ran the dry-run immediately after the real sync had written
  all 798 files and got 798 `WOULD WRITE` lines and exit 0.
- **A coverage gap the agent widened on the advisor's prompt, then closed.** The
  source-to-generated comparison structurally cannot see files with no canonical
  source: seven heredoc-generated ones whose text lives in `scripts/sync-runtimes.d/`,
  which no sweep this sprint covered, and which check `[40]` cannot reach either
  because `dist/` is untracked in full. All seven scanned for every retired string and
  all four banned tokens, clean on all nine, and none of them describes a Phase 3 scout
  run point at all. Reported rather than folded into the manifest comparison, because
  the fix would have lived outside the wave's allowlist.
- **The wave contract's VERIFICATION step (a) reds on a healthy tree**, comparing
  relative `git diff` output against an absolute-path allowlist. Same shape T3 hit in
  Round 1, in a different clause. Routed to Phase 5.

**Round-end gate, run once for the round.**

- **Diff scope:** `git status --porcelain` returns ` M README.md` alone. `git ls-files
  dist` returns one path, `dist/.gitignore`. **A round that regenerates 798 files and
  commits one is the correct outcome here**, not a sign the sync did not run.
- **The sync comparison re-run by the parent, independently of the agent's:** 118 pairs
  compared across the six path-for-path runtimes, 0 mismatching. Negative control: the
  pre-sprint `SKILL.md` from `35ccc4a` compared against the synced copy comes back
  UNEQUAL, so a stale carry is detectable and the zero is load-bearing.
- **The omission sweep re-run by the parent** with its own predicate: 17 in-scope
  sites, 0 flagged. The agent's sweep scoped differently and found 30 in-scope, 0
  flagged. Two independent predicates, both clean.
- **Mirrors:** exit 0, standing caveat about the unread tail. **Doc links:** exit 0.
- **Validator:** exit 0, `ALL CHECKS PASSED`, 0 `FAIL`. `[7]` green at 448 of 450.
- **Every CI step:** all 17 exit 0, driven off `ci.yml`.
- **Agent-side scouts** over `README.md`: law-scout 1 handed, 1 scanned, 0 findings,
  its `cap.file-lines` coverage proved by a planted 600-line file. perf-scout no
  candidates, one sentence of prose with no loop, query, cache, fan-out or render path.

**Two follow-ups routed to Phase 5 rather than fixed here**, since the Sprint Backlog
is closed and the reviewer panel is the right place to judge them.

1. `README.md`'s statement of partition condition 2 is NARROWER than the canonical. It
   says "no import edge between the modules those subsets live in" and drops both "in
   either direction" and the prose-and-config-tree generalisation at
   `phase-3-implement.md:112-115`. That generalisation is what makes the test
   applicable to this repo at all, which is a prose tree. A narrowed statement of a
   safety test in the most-read file is worth a reviewer's judgment.
2. The same README bullet never states the round-level commit point that `94edbd3`
   moved.

### Round 6, the Phase 5 fix round (F1 to F9, F12 to F16), four concurrent waves

- **Dispatch shape:** four waves. The partition test had a new problem to solve here:
  three waves needed to READ the canonical file the fourth was rewriting. Solved by
  telling each of the three to read it with `git show e2acaf2:<path>` rather than from
  the working tree, which cuts the read edge outright instead of arguing about it. All
  three did, and one of them said so unprompted in its report.
- **Exclusive resources:** the canonical wording of the allowlist reconciliation and of
  the Phase 3 pre-flight, held by W6a alone.
- **All 15 assigned findings landed. Nothing stopped.** F16 was added mid-flight by
  message to the wave already holding the file, rather than costing a seventh round.

**The Critical, and the proof it actually needed.** The old agent-side gate exited 1 on
a breach; what replaced it in Round 1 could not fail, and neither could the parent-side
check that was supposed to cover for it. The rebuild has each agent declare the paths it
wrote and the parent reconcile the round three ways. **The wave refuted my brief on a
point that matters:** `git diff --name-only HEAD` never lists a file that was CREATED
and not staged, proved in a throwaway repo, and that is exactly the stray path check 3
exists to catch. The shipped block unions it with `git ls-files --others
--exclude-standard`. Without that refutation the new check would have shipped with a
hole in the one direction the other two cannot see.

**The parent ran the reconciliation on this very round, and planted each failure.** Real
round: 11 paths in the diff, 11 claimed, 0 failures. Planted a declaration outside a
wave's allowlist and checks 1 and 2 both fired. Planted an untracked file nobody
declared and check 3 fired. **First attempt at that harness produced a false clean**,
because `for w in $ROUND_WAVES` does not word-split under `zsh`, so check 1's loop read
nothing and reported success. Re-run under `bash`, which is what the validator uses, and
it fires. The same `zsh` trap cost the F6 wave two clean scans in the same round.

- **Five brief corrections across the four waves.** The mirror pair splits 6/214/77 and
  7/214/69, not the 7/193/61 I predicted. `perf-scout.md` is 256 lines and `law-scout.md`
  136, so "both in the 250s" was half wrong. The spec reviewer's restatement sat at
  `:182-188`, not `:184-186`. A README citation I would have accepted named a path that
  does not resolve from the repo root, which the wave caught and fully qualified. And my
  verify line's literal `in EITHER direction` pushed caps into a file whose house style
  is bold, which the wave flagged against its own work rather than quietly satisfying.
- **Two waves declined the obvious fix and were right.** W6b picked the shape a
  neighbouring step in its own file already used, rather than adding the canonical to a
  read list, because handing the sub-agent the parent's dispatch protocol is the role
  bleed F9 was separately removing. W6c kept conformance point 6 and wrote down why,
  after reading check `[99]` and finding it reaches only this plugin's own tree and only
  one of the point's two directions.
- **A clean scout result thrown away rather than shipped.** The F6 wave's first two
  perf-scout runs returned zero because unquoted `$FILES` handed `grep` one nonexistent
  filename. It only noticed when `awk` errored. The real answer was 11 candidates, all
  the file matching its own documentation examples, all dismissed as self-match, none in
  its diff.

**Round-end gate, run once for the round.**

- **Containment, by the new method:** 11 paths in the round diff, 11 declared, every
  declaration inside its own wave's allowlist, nothing doubled, nothing unclaimed. Each
  of the three checks demonstrated firing on a planted case in the same session.
- **Mirrors:** exit 0. **Doc links:** exit 0. **Validator:** exit 0, `ALL CHECKS PASSED`,
  0 `FAIL`. **All 17 CI steps:** exit 0.
- **law-scout, parent-side:** 0 findings, load-bearing for `cap.file-lines` by planted
  620-line and 600-line controls in two separate waves. Standing caveat unchanged.
- **The fixes checked directly, not inferred:** `One commit closes the whole wave` is
  gone from `SKILL.md`; `Left empty when the wave holds none` is gone from the canonical;
  the walkthrough names the scouts in 5 places where it named them in 0; both
  spec-reviewer sides and both README sites carry condition 2's prose clause, checked
  wrap-safe against a negative control after a naive single-line grep of mine returned a
  false absence.

### Round 7 (F11, F17), two concurrent waves

The partition test allowed the split: no shared file, no dependency edge, no shared
serial resource. W7a took the mirror tail check across seven files, W7b took two README
lines.

**W7a, F11.** Test-first, and the RED matters here because the plant is the exact false
green the finding described: with a mirror that annexes parent-side text, the old check
printed `ok agents/wave-implementer.md matches phase-3-implementation.md`, exit 0, nine
of nine. Now it prints the tail-line counts and the first differing line, exit 1. The
rule is an equality against the template tail above `<!-- parent-side: not mirrored -->`,
bounded at both ends, which is what makes the marker unforgeable: sliding it up one line
with the mirror untouched also reds, so blessing drift takes a matched two-sided edit.
Battery 123 passed 8 failed at RED, 131 passed 0 failed at GREEN.

Three things the wave named rather than buried. The nine mirror *heads* are not covered
and cannot be: zero of nine are a prefix of their template head, because mirrors open
with YAML frontmatter and templates with an H1, so there is no mirrored region for a
marker to bound. That measurement is in the module docstring, not left silent. An
unrecognised flag now refuses with exit 2, beyond the literal finding, because write mode
was the no-flag fall-through and a typo like `--chekc` in the validator fragment would
have made the validator edit the tree it audits, proved on a copied tree. And every mode
now exits non-zero on tail drift, write mode included, since a sync cannot fix a
hand-maintained tail, so a caller chaining under `&&` stops instead of reporting clean.

**W7b, F17.** `README.md:238` now cites the canonical fully qualified, and `:32` drops
the caps `EITHER` for the README's own bold house style.

**Correction, filed by Reviewer F in the round-2 panel.** My first version of this entry
said `:238` "now restates the partition test's conditions and cites the canonical fully
qualified". The restatement half is false. The line reads "The test itself is written out
in full at [...], **named here rather than restated**", so only the citation landed.
Naming the wrong version rather than swapping it silently, because this is the second
time this sprint that I have written a false quantitative or descriptive claim about the
sprint's own work into its own record, after the Evidence Ledger counts. The restatement
is also not affordable at `README.md`'s 448 of a 250..450 bound without cutting an older
blurb, which is a decision, not an oversight, and it should have been written down as one.

Method note, because it nearly cost the finding: my first check of F's citation ran
`cut -c1-400` over the line, and the clause sits past character 400, so I read a FALSE
ABSENCE and briefly doubted a correct citation. Truncating a long line is the same class
of error as grepping a wrapped clause line by line. The wave's own negative control caught a hole in my verify method before I
did: it planted a `.bogus` link target, which `MD_LINK` ignores, so the control passed
for the wrong reason. Re-planted against a real `.md` target, it fails as it should.

**Round gate.** Reconciliation clean on real data, 8 diff paths, 8 claimed, W7a 7 of its
11-path allowlist and W7b 1 of 1, nothing double-claimed, nothing unclaimed. All three
checks proved able to fire on this round's own data: a declared path outside the
allowlist, a path claimed by both waves, and a written file left undeclared. Control
silent. Mirrors nine of nine with the new tail rule proved to fail on a planted mirror
drift and the tree byte-restored after. Battery 131 passed 0 failed, doc links exit 0,
validator exit 0 with `ALL CHECKS PASSED` and zero FAIL lines. All 17 CI `run:` steps
exit 0 **individually**, re-run that way after my first aggregate rc turned out to report
only the last step, which would have hidden a failure anywhere above it.


### What the new rule actually bought, measured

Agent durations as reported by the harness. This measures the wave work, not the
parent's own time between rounds.

| Round | Waves | Slowest wave | Sum of all waves | Saved |
|---|---|---|---|---|
| 0 | 3 | 12m 25s | 28m 03s | 15m 38s, 56% |
| 1 | 4 | 21m 49s | 52m 16s | 30m 27s, 58% |
| 2 | 2 | 7m 25s | 12m 08s | 4m 44s, 39% |
| 3 | 2 | 13m 45s | 23m 06s | 9m 22s, 41% |
| 4 | 1 | 6m 56s | 6m 56s | none, the test refused a split |
| 5 | 1 | 9m 04s | 9m 04s | none, T12 depends on T20 |
| 6 | 4 | 20m 11s | 46m 04s | 25m 53s, 56% |
| 7 | 2 | 29m 34s | 37m 38s | 8m 04s, 21% |
| 8 | 2 | 2h 03m 35s | 2h 40m 45s | 37m 10s, 23% |
| 9 | 4 | 12m 34s | 35m 18s | 22m 44s, 64% |
| 10 | 1 | 9m 27s | 9m 27s | none, the canonical is a hub every other wave reads |
| 11 | 4 | 13m 45s (see note) | 26m 17s | 12m 31s, 48% |
| 12 | 1 | 4m 34s | 4m 34s | none, the validator and battery read the live tree |
| 13 | 1 | 25m 21s | 25m 21s | none, it rewrites the validator every other wave reads |
| 14 | 1 | 9m 39s | 9m 39s | none, the changelog describes what the other rounds landed |

**The `Slowest wave` column is a lower bound on elapsed time, and Round 11 is where that
stopped being a rounding error.** Waves in one round are dispatched in one message but they
do not all start on the same second, and Round 11 added a fourth wave eight minutes in, after
a sibling's report exposed two sites nobody had swept. Measured from first dispatch to last
return: Round 9's true wall clock is 13m 06s against a slowest wave of 12m 34s, a gap of 31
seconds that moves its saving from 64% to 63% and changes nothing. Round 11's gap is 5m 22s
and moves its saving from 68% to 48%, so its row carries the true wall clock, not the slowest
wave. Round 9 keeps the largest saving of the sprint under either measure. I found this by
measuring Round 11 rather than by reasoning about the column, which is the only reason the
48% is in the table instead of the 68% my own method would have printed.

Three honest caveats. The saving is bounded by the slowest wave in the round, so an
unbalanced round wins less, and **Round 7** shows it: two waves whose durations differed
by 3.67:1 returned the smallest percentage of the sprint, 21.4%. Re-derived twice since, per the
rule below. After Round 8: 3.32:1 and 23.1%. After Round 9: 2.48:1 and 64.4%, the largest
saving of the sprint and the only round to clear 60%. Round 7 keeps both titles either way,
and the sentence has now survived two re-derivations it could have failed.

**This sentence named Round 2 until the completeness critic caught it, and it was my
correction that broke it.** Re-derived from the table's own cells: Round 2 is 1.57:1 and
38.9%, Round 3 is 1.47:1 and 40.5%, Round 7 is 3.67:1 and 21.4%. Round 2 was neither the
most unbalanced round nor the smallest saving. The sentence was TRUE when written, and
appending Round 7's row twenty minutes ago made it false, because a superlative over a
table is invalidated by any new row. So the edit that fixed one carry-forward error
committed another one in the paragraph directly above its own apology for carry-forward
errors. **The rule this earns: a superlative claim about a table is a claim that must be
re-derived whenever the table gains a row, and it should not be phrased as a superlative
if a cheap non-superlative will do.** This sprint could not collapse
below three rounds of planned work, because most of its files copy their wording from one
place, which is the shared read surface the rule protects rather than a failure of it.
And the round count grew from three to eight while the sprint ran, so the table is not
a forecast of what a planned round buys, it is what these rounds bought.

**The Waves column sums to 32 over 14 rounds**, re-added mechanically at the end of Round 14:
3+4+2+2+1+1+4+2+2+4+1+4+1+1. That is the figure to trust.

**And this sentence said 19 until a wave recounted it.** 19 was the rounds 0 to 7 subtotal,
correct when written and stale from the moment Round 8's row landed. I then repeated the 19
in the effectiveness section written this session, as a current total, which it had not been
for six rounds. That is the fourth count I have got wrong about this sprint inside the
sprint's own record, and it is the same shape as the other three: an aggregate over a table
that gained rows after the aggregate was written. The rule for exactly this is written two
paragraphs below, by me, and I still did not re-derive. A rule that has to be remembered at
the moment of writing is not a control, which is the argument for the table carrying its own
recount command rather than a sentence asking the author to be careful.

**This is the third count I have gotten wrong about this sprint inside the sprint's own
record, and the first two were supposed to have taught me.** The sentence here previously
read "The Waves column sums to 13, which is the figure to trust; an earlier sentence here
said 11." 13 was the rounds 0-5 subtotal. I appended the Round 6 row and never moved the
sentence, so the correction notice was itself wrong, and the phrase "the figure to trust"
was attached to it. Round 7 was missing from the table entirely until now. Filed by
Reviewer B in the round-2 panel, which had to re-add the column by hand to catch it.
The pattern across all three: every wrong number was one I carried forward instead of
re-deriving, which is the law at `rules/claim-integrity.md` about a number you did not
just count. Round 7's row is measured, not estimated: W7a from the harness at 1773739 ms,
W7b from its transcript timestamps at 8m 04s, and the saving is sum minus slowest.

## 7. Sprint Review (Phase 4 / 5)

### Evidence Ledger

Every row was first run against the tree at `ba344b7`, commit 6 of 10, and the rows
were NOT re-run when the four commits after it changed 17 more source files. Flagged by
Reviewer B and the completeness critic. The critic re-derived every load-bearing row at
HEAD and all of them still hold (17/17 CI steps exit 0 individually; validator exit 0
with `ALL CHECKS PASSED` and 0 FAIL; `--check-tails` 9 of 9; digests expert-mindset 201,
perf-guardrails 315, claim-integrity 895; battery 131 passed 0 failed), and the parent
separately re-derived the runtime sync at HEAD as 798 files byte-identical to a fresh
sync. So the artifact is right and the ANCHOR was wrong. Row text below is a command run
against the tree at `ba344b7`, not a
recollection and not a summary of an earlier round. Depth tier is named per the law
this sprint added, so a reader can argue with the choice instead of guessing at it.

| # | Claim | Evidence | Tier |
|---|---|---|---|
| 1 | Every CI step passes | 17 of 17 `run:` steps in `.github/workflows/ci.yml` exit 0, driven off the file rather than a remembered list | 2, fresh run |
| 2 | The validator passes | `bash scripts/validate-dod.sh` exit 0, `ALL CHECKS PASSED`, 0 `FAIL` lines | 2, fresh run |
| 3 | Mirrors match their templates | `sync_agent_mirrors.py --check` exit 0, 9 of 9. **Weak:** it compares only the first fenced block, never head or tail | 2, fresh run, gap named |
| 4 | Every link and citation resolves | `check_doc_links.py .` exit 0, 116 files, 64 line citations. **Weak on T14's class:** its line form asserts only that the line exists | 2, fresh run, gap named |
| 5 | The runtime sync carries the sprint | 118 source-to-generated pairs compared, 0 mismatching, reproduced independently by the parent. Negative control: the pre-sprint `SKILL.md` compares UNEQUAL against the synced copy | 1, re-derived |
| 6 | No site states a scout run point half-way | Two independent windowed sweeps, 17 and 30 in-scope sites by different predicates, 0 flagged by either. Both proved to flag the known-bad text first | 1, re-derived |
| 7 | The injected digests fit | `digest_of` measured live: expert-mindset 201, perf-guardrails 315, claim-integrity 895, all at or under the 900 cap. The last has 5 characters of headroom | 1, re-derived |
| 8 | `dist/` regenerating leaves no diff, correctly | `cat dist/.gitignore` is `*` and `!.gitignore`; `git ls-files dist` returns one path. After writing 798 files the tree held one modified path | 1, re-derived |

### The five changes, before and after

The original ask asked for this explicitly. Each pair quotes the live text at the site
it came from, `35ccc4a` on the left and `ba344b7` on the right.

**Change 1, scope the rule by shared read surface and give the parent a partition test.**

Before, `skills/hackify/SKILL.md:56`:

> Phase 3 is the one place that gives it up on purpose: a wave's tasks are file-disjoint
> but they read the same code, so ONE agent takes the whole wave.

After, same line:

> Phase 3 gives it up only where it buys something: when a wave's tasks have a shared
> read surface, reading the same types, the same neighbouring code and the same
> conventions, ONE agent takes the whole wave. A wave whose tasks share nothing passes
> the partition test in `references/phases/phase-3-implement.md`.

Before, the dispatch paragraph at `SKILL.md:134`:

> exactly ONE subagent for the whole wave however wide it is: no cap, no module split,
> no grouping decision at dispatch time.

The carve-out was stated unconditionally there and in `agents/wave-implementer.md:6`,
which read *"There is no cap and no width valve, in any mode"*. Both now condition the
one-agent rule on the shared read surface while keeping the no-cap half, which was
never the conditional part. The test itself is written once, at
`phases/phase-3-implement.md:108-116`:

> **The partition test.** Take the union of every task's file allowlist in the wave. Ask
> whether that union splits into two or more subsets where all three of these hold:
> 1. **No file appears in more than one subset.**
> 2. **No import edge runs between the modules those subsets live in, in EITHER
>    direction.** Where the tree has no imports to follow (prose, docs, config), the
>    edge is that same relation without the keyword: one subset reading text or values
>    that another subset is rewriting.
> 3. **No subset holds a serial resource that another subset also holds** [...]

**Change 2, let the parent merge waves.**

Before, `phases/phase-3-implement.md:72-74`, wrapped across two lines, which is why an
early verify grep for the one-line form could never have matched it:

> and is never regrouped at dispatch time. Never merge two waves into one dispatch:
> that would break the dependency order the plan exists to enforce.

After, `:93-98`:

> The parent MAY merge consecutive waves into one dispatch when no file collides inside
> the merged set and no dependency edge crosses the merge. Merging is a throughput
> decision and needs no re-review: **"read the plan rather than rebuild it" bans
> RE-PLANNING, not merging.**

**Change 3, the spec reviewer declares serial resources.**

Before: the phrase "serial resource" appears **0 times** in
`parallel-agents/phase-2.5-spec-reviewer.md`. The reviewer had no way to say a resource
serialises, and `{{wave_size_target}}` at `:79` capped waves by count instead.

After: a METHOD step at `:175-186` names every serial resource and applies the same
three conditions the parent applies; a `## Serial resources` output section carries
them with kind and holding task IDs; an APPENDED VERIFICATION item 21 at `:299` asks
whether every one is named. Appended rather than renumbered, because that file
cross-cites its own item numbers.

**Change 4, the exclusive-resource clause in the wave contract.**

Before: "exclusive" appears **0 times** in `parallel-agents/phase-3-implementation.md`.

After, INPUTS item 13 at `:70-75`:

> `{{exclusive_resources}}`, the exclusive resources THIS wave holds, each one named,
> one per line: a shared test database, a shared fixture, a generated sequence,
> anything two processes cannot hold at once without corrupting it. `none` is passed
> explicitly and means the wave holds none. This input is never absent, an absent value
> means the dispatcher did not decide, so refuse and say so.

with the scoped-tests clause at `:153`. Every wave in this sprint received the input,
and the four that held nothing received the literal `none`.

**Change 5, tier verification depth in `rules/claim-integrity.md`.**

Before: 14 bolded laws, the last being *"Say what the checks do not reach."*

After: 15. The new one, written to survive the digest as its own bolded lead:

> **Match depth to what a wrong claim costs: re-derive, cite a fresh run, spot-check.
> No tier skips proof. Name the tier.**

The three tiers and what each owes as evidence sit under `### Choosing the depth`,
written unbulleted on purpose: a `- **X.**` line would have matched `BULLET_LEAD` and
pushed the digest past 900, silently truncating the tail.

### The safety properties the ask required preserved

Each checked before and after rather than asserted.

| Property | Before | After |
|---|---|---|
| Stop at first failure (`STOP there`) | 1 in the contract, 1 in its mirror | unchanged, 1 and 1 |
| Strict file allowlist language | present in `SKILL.md` and the mirror | unchanged, neither widened nor narrowed |
| `no-parent-authored-diff` | 1 mention in yolo | 2, strengthened rather than weakened |
| Nothing gated on the user asking for speed | n/a | a tree-wide search for speed-conditional wording returns nothing |
| Claim integrity | 14 laws | 15, none removed |
| Mutation proof | tamper battery + claim fixtures green | both still green in the 17-step sweep |
| Phase ordering | one phase open at a time, parallelism inside a phase only | unchanged; this sprint ran five rounds strictly in order |

### Ship gate

This repo ships no application. Every leg is a written skip with its reason, never
silently absent.

| Leg | Verdict |
|---|---|
| Build from cold cache | Skipped. No build step, no `package.json`, no compiler. The equivalent gate is `sync-runtimes.sh` producing 7 runtime packages, which ran and reported `OK, synced 798 files across 7 runtimes`. |
| Boot and wait for a ready signal | Skipped. Nothing boots. The plugin is markdown loaded by a host. |
| Smoke the touched flow | **Not skipped, and this is the honest one.** The touched flow is the Phase 3 dispatch protocol itself, and this sprint ran it under the new rules at the user's direction: **6 rounds (0 to 5), 13 waves, 19 Sprint Backlog tasks and 6 implementation commits**, every round gated. Four rounds ran concurrent waves the partition test authorised; two ran a single wave the test refused to split. **These five figures replace an earlier version of this row that said five rounds, 11 waves, 20 tasks and 5 commits. Reviewer B caught it, the refuter re-derived all five independently, and the correction is recorded rather than quietly swapped: I wrote numbers I had not counted, which is the one law in this file with my name on it.** There is no T19; the backlog runs T1 to T18 plus T20. |
| Lint | n/a, repo ships no linter. |
| Typecheck | n/a, repo ships no typechecker. |

### What the checks do not reach

**Correction to a claim I made to seven reviewers, caught by two of them independently.**
In this round's dispatch briefs I told the panel that the injected digest "truncates
SILENTLY and drops the TAIL" at 900 characters, and asked them to weigh the 895 measure
against it. That is false at HEAD. `hooks/test_inject_context.sh:186` asserts the
truncation marker `"; ..."` never appears in the pointer, and `:189` asserts the file's
deliberately-last law still arrives, with a comment saying that ordering is what "turns a
silent tail-drop into a red". It is wired into CI at `.github/workflows/ci.yml:98`.
Reviewer D proved it by inserting a bullet, watching the digest truncate at 866 and both
assertions go red; the prose specialist reached the same conclusion separately and
corrected the brief in its report. What survives the correction is narrower and still
real: those assertions catch an OVERRUN, not a DE-BOLD. The prose specialist planted that
case, de-bolding the final law, and the digest fell 895 to 777 while both standing
assertions still passed. So the guarded failure mode is guarded and the unguarded one is
next door.


**The law-scout's mechanical tier barely covers this repo, and the round-1 record
overstated it.** The scanner runs its full check suite only on the JS/TS family. For
`.py`, `.sh`, `.md` and `.json` it runs a text-only tier, which its own docstring at
`skills/lawkeeper/scripts/audit_scan.py:41-43` defines as the file-line cap plus the
project's ban-patterns file, and nothing else. This repo has no
`.claude/hooks/ban-patterns.txt`, so the ban half never ran either. **The only mechanical
check that has ever executed over this sprint's diff is the 500-line file cap.** A
planted 610-line control returns `cap.file-lines`, so that one is load-bearing, and
`CHANGELOG.md` at 1189 lines correctly returns nothing because it is an exact-basename
waiver from that rule alone. Every other hard cap, the 40-line function, the 3-parameter
limit, the nesting depth, suppressions, empty catches, is unverified by any scanner here
and rests entirely on a reviewer reading the file.

Two traps in the invocation, both of which I hit and neither of which announces itself.
`--text-only-ext` ADDS extensions rather than replacing the default set, and `.py` is not
in that default, so `--text-only-ext .md` alone silently drops every script in the diff:
25 scanned, 7 unsupported, and the 7 were the two JSON, the GIF, the three Python and the
one shell file. And a positive control planted as a dotfile is skipped, so my first
control returned zero findings and I nearly read that as the scanner working.


Stated because the law requires it, not as a hedge.

- The mirror check reads only the first fenced block, so a hand-maintained tail can
  drift on both sides and still report clean. Found by a wave when a planted regression
  printed a false green.
- The doc-link checker's line-citation form asserts only that the cited line exists,
  never that it says what the citing sentence claims. That is the exact defect T14
  fixed, and it is still unreachable by any check.
- The law-scout's zero is load-bearing for `cap.file-lines` on markdown, proved by a
  planted oversized file in three separate rounds. It is NOT load-bearing for ban
  tokens on text files; check `[40]` inside the validator is that coverage.
- Seven generated files under `dist/` have no canonical source, so the sync comparison
  cannot see them and check `[40]` cannot either, because `dist/` is untracked in full.
  Scanned by hand for every retired string and banned token, clean.
- No check reads `parallel-agents/README.md`'s INPUTS tables at all, because check
  `[93]` only scans a file whose line starts with `**INPUTS**`.
- `scripts/check_doc_links.py`'s `MD_LINK` pattern only captures link targets ending in
  `.md`, so a markdown link to a renamed `.py`, `.sh` or `.json` is never resolved at
  all. Found by the F17 wave when its own negative control passed: it planted a broken
  `.bogus` target and the checker exited 0, which is the plant failing rather than the
  checker. It redid the control with a real `.md` name that does not exist and both
  forms then fired. Arguably by design, and recorded rather than fixed, because a
  reader would assume that coverage is closed.


### Phase 5, the reviewer panel

**Panel composition and the gates that set it.** Reviewer B (quality, layering,
engineering law, plan consistency, scope and goal drift) is the standing member and ran.
Reviewer F (cross-module coherence) ran on evidence: this diff has one canonical
statement and eleven restating consumers, and the canonical wording moved twice
mid-sprint, which is the exact seam F exists for. Reviewer A (security) folded, no auth,
network, database, filesystem, shell or deserialization surface and no `sec.*` scout row,
with its residual checklist carried by B and run. Reviewer D (performance) folded, no
scout candidate across six rounds and no loop, query, cache, fan-out or render path,
residual carried by B and run. Reviewer E (design) was **omitted rather than folded**,
there is no UI surface and no `docs/design/DESIGN.md` in this repo.

**Review-start scouts, the third run point.** 27 changed paths handed, 27 scanned,
`paths_unsupported: 0`, one candidate: this work-doc at 1038 lines against a 500 cap.
Dispositioned `false-positive`, a work-doc is a narrative record and three archived ones
here run 1694, 2897 and 3902 lines. B re-judged and dismissed it independently. The zero
elsewhere was proved load-bearing by a planted 610-line file returning `cap.file-lines`.

**Findings: 3 Critical, 6 Important, 6 Minor. Every one went to the adversarial refuter
before a single fix was spent. All 15 UPHELD, none refuted, none escalated.**

The refuter earned its dispatch three times over:

- It **proved Critical 1 by running the command** rather than reasoning about it.
  `git diff --name-only HEAD -- a/f.txt` returns only `a/f.txt`, so the parent-side
  containment check that replaced the deleted agent-side gate is a tautology. Scoping to
  a directory entry instead makes it fire wrongly. Both directions broken.
- It **corrected a filed citation by 227 lines.** The third unscoped site is
  `implement-and-test.md:25-33`, not `:252-255`; line 252 is a commit code fence, so a
  fix wave dispatched on the filed line would have edited the wrong hunk.
- It **found a cross-finding hazard neither reviewer saw.** Important 6 wants the
  parent's pre-flight re-derivation removed as re-planning. That re-derivation is the
  only thing catching Important 4's lossy partition-test restatement. Steps 1, 3 and 4
  are the re-planning; step 5 is sanctioned and stays. Fixing 6 naively would have gone
  live on 4.

It also narrowed two findings rather than accepting them whole: Important 2's overshoot
is one item, not four, because T16's own text authorises the other three verbatim; and
Important 3's justification is **unsupported** on a single-wave round rather than false,
because the parent scan still answers two things nobody wrote down.

**The finding that matters most is mine.** Critical 1 is a live regression against a
guardrail this sprint's own anchor names: *"Weakening any file allowlist, in any
direction."* Round 1 correctly found the agent-side check unsound under concurrency and
moved the verdict to the parent. What replaced it cannot fail. The rule survived in
words at every site and stopped working at all of them.

### Phase 5 round 2, the first round under the one-round cap

**Panel, derived from the diff rather than folded off a list.** Seven readers. A security and
D performance ran at full scope `.` because both FOLDED in round 1 and therefore held a live
verdict on nothing. B quality-and-plan and F coherence ran `settle` over the 17 files whose
verdicts died since the round-1 scan, with F's boundary set left unscoped and B's
plan-consistency lens unscoped, since goal drift is a property of the sprint and not of a file
subset. E stayed omitted, no UI. Added on the user's instruction that reviewers be picked from
what the diff actually is: a completeness critic, and two specialists pinned to this product's
real risk surface, prose-as-executable-specification and can-these-checks-fail.

**Scope arithmetic, checked rather than assumed.** The reviewed diff grew from 27 files at the
round-1 scan to 32, so five files had never been read by anyone. The advisor flagged that those
five could be sitting in the live-verdict bucket holding a verdict nobody issued. Re-derived:
all five are inside the 17, because both commits that created them postdate the round-1 scan,
so they land in the since-set by construction. No hole, but the check was worth running.

**Yield: 41 findings, 3 Critical, 22 Important, 16 Minor.** Round 1, gated, produced 15.

**The un-gating paid, and it is measurable.** A folded in round 1 on the reasoning that this
diff has no auth, network, database, filesystem or shell surface. It returned two reproduced
Importants against `phases/phase-3-implement.md`, the canonical this sprint exists to change,
including a containment check that goes green on exactly the stray new file it was built to
catch, because `git diff --name-only HEAD` is root-relative while `git ls-files --others` is
cwd-relative and cwd-scoped. Reproduced independently at parent level on a scratch repo.

**The two added specialists produced the round's sharpest work,** which is the argument for
Issue #4. The prose specialist found that the refusal guarding a shared exclusive resource
exists in exactly one sentence, buried as item 13 of 13 in an INPUTS glossary, carried by no
METHOD step and no VERIFICATION line, and enforced by no validator fragment. The test
specialist measured that this sprint's headline new gate does content comparison on **1 of 9**
mirror pairs, eight having a required mirrored tail of zero lines. Neither defect belongs to
any lens in the canned set.

**D refused to manufacture a finding.** It had a candidate Important, took it to the code,
refuted its own claim and said so, then filed one Minor with a measurement and a recommendation
against fixing it. Its null result is auditable because it lists every catalog category it
checked and why each was inapplicable, which is the only thing that makes a null result worth
anything.

**Four findings were about my own work, and I fixed all four before the refuter ran.** The
waves-column sum, the Round 7 entry describing its own diff backwards, the effectiveness caveat
naming Round 2 while describing Round 7, and a briefing error where I told all seven reviewers
the injected digest truncates silently when CI in fact guards it. Two reviewers caught that last
one independently. Each correction is recorded at its own site with the wrong version named.

**The uncomfortable count: three of those four were errors I introduced while correcting other
errors.** The caveat broke because I appended a table row and did not re-derive the superlative
above it, in the same edit whose purpose was apologising for carry-forward errors.

### The fix rounds, planned by the partition test itself

41 findings, grouped by file cluster per the user's 5-A, plus I22 per 6-A. I20, M13 and M4
are filed as a follow-up task rather than fixed here, since none of them is this sprint's goal.

**Round 8, two concurrent waves.** W8a took the canonical `phases/phase-3-implement.md` (C3, I1,
I2, I6-consumer, NEW-1, I11, I13, I7, I16, M1, M2, M3). W8b took the mirror mechanism and the
exclusive-resource story across five files (I19, I18, I21, M10, M12, M14, C2, I6-producer, I15,
M5, I5).

**The partition test did real work on this round, three times, and one of those saved me from a
mistake.**

Condition 1 passed: no file in both subsets. Condition 3 FAILED on the first attempt, because W8b
rewrites `scripts/validate-dod.d/` and `test_tamper_battery.py` while W8a needs the validator to
verify a prose change, which is a shared serial resource. Resolved by the clause this very sprint
added: W8b declared both exclusive, W8a was told to run scoped checks only, and the parent runs
the full gate at round end. **First time the exclusive-resource clause has been load-bearing.**

Then, mid-round, I nearly dispatched a third wave to add the two regression rows W8b could not fit.
Condition 2 refused it: `scripts/validate-dod.d/76-phase-ledger-substrate.sh:70` reads
`phase-3-implement.md`, so any wave proving a new check by running the full validator would read
the exact file W8a was still rewriting. Measured, not guessed: of the four fragments matching
`phase-3-implement`, three read `phase-3-implementation.md` (the template) and only that one reads
the canonical. **The rule caught a split I had already talked myself into.**

**Round 9, planned, four concurrent waves.** W9a `agents/spec-reviewer.md` +
`phase-2.5-spec-reviewer.md` (I4, the wave-size cap, which must land with or after I11 per the
refuter's sequencing note). W9b `implement-and-test.md` + `phase-ledger.md` +
`work-doc-template.md` + `SKILL.md` (C1's four restatement sites, I3, I17, M6). W9c
`law-scout.md` + `perf-scout.md` (I14, M3's scout side). W9f `README.md` (M11).
All four read the canonical that Round 8 froze; none rewrites what another reads.

**Round 10, one wave.** The check surface: a new `dist/` integrity fragment for I22, plus a new
battery part file carrying the I18 pair-count and I21 marker-position rows W8b stopped short of.

I22 re-derived at parent level rather than inherited, and the method matters more than the
result. First attempt looked like a refutation: the planted tree returned validator rc 1, which
contradicts the finding. It was an artifact, a `git archive` copy has no `v*` tags and check
`[71]` reds on that. Running the SAME tree unplanted returned rc 1 as well, and diffing the two
FAIL sets gave **zero difference**. So the delta attributable to a corrupted shipped file is
nothing at all, and `[24]` prints its green over the corruption. Comparing planted against clean
IN THE SAME TREE is what turned a false refutation into a confirmation; comparing a planted copy
against the real repo would have gotten this backwards.
One wave because they share a read surface (the check mechanism) and because both must run the
full validator, which is a serial resource they cannot hold at once.

**Round 11, one wave.** `CHANGELOG.md` (I10), last by construction, because a changelog documents
what landed and every earlier round changes what that is.

### Round 8 (24 findings), two concurrent waves

**W8a, twelve findings in one file, and it refuted my brief.** For I2 I prescribed
`git ls-files --others --ignored --exclude-standard -- dist`. It measured that command in this
repo, got **799 files**, and pointed out it would print roughly 799 false `FAIL 3` lines every
round, which is worse than the hole it closes. Parent-verified: 799. It used an mtime sweep
against a round-start marker instead, with controls both ways, and kept my caution about never
dropping `--exclude-standard`. **A brief is a fact handed to an agent, and this is what it looks
like when the agent is right and the parent is not.**

Its C3 fix is the instructive one. The first attempt, adding a readability guard, did NOT close
the refuter's CASE F': `cat decl.*` still globbed the misnamed file into `claimed` and laundered
the breach through check 3. The real fix is enumerating `$ROUND_WAVES` and never globbing. The
block now returns rc 1 naming both the missing declaration and the stray path, and the green path
is verified too, `reconciled: 4 comparisons, 0 failures` run from a subdirectory, so it is not
merely red-happy.

On I11 it kept the partition test wave-scoped and added the cross-wave check as a separate
pre-flight step, exactly as the refuter's sequencing note required, so I12's refutation survives.
It nearly added a FOURTH condition and caught itself: `agents/spec-reviewer.md` item 21 says
findings are "checked against ALL THREE partition-test conditions", and that file was outside its
allowlist. A fourth condition would have stranded a sentence it could not reach.

It hit the 500-line cap at 551 and compressed its own additions across eight passes to 498, then
spent one line moving the round-start marker obligation into the parent's step 2, where every
other parent obligation lives, because inside a bash comment the parent would have learned it
forgot the marker at reconciliation time, after the round had already run.

**W8b, eleven findings across five files.** The tail check now reports what it compared:
`9 mirror tail verdict(s) over 9 agent file(s): 1 pair(s) compared a non-empty mirrored tail, 8
asserted an empty one, 0 failed`. Before, it printed nine `ok` lines over one real comparison. The
pair-count floor derives from `find agents -maxdepth 1 -name '*.md'` rather than a hardcoded 9, on
the reasoning that a number written beside the list gets edited by whoever shortens the list. C2's
refusal went from one buried glossary sentence to a METHOD step and two VERIFICATION lines.

It stopped short of permanent regression rows for I18 and I21 because the battery is at its cap,
said so, and did not reach for a file it did not hold.

**Two mid-round handoffs, both worth keeping.** W8b's report warned that its diff would land my
in-flight Guardrails correction stale the moment it merged, which it did; re-measured at round end
instead. And `check_doc_links.py` went red on W8a's file because it wrote example filenames in
backticks while explaining the cwd-frame defect, and the checker reads any backticked path-shaped
span as a pointer that must resolve. Handed to the wave with the evidence and a caution about the
`.md`-only control trap rather than fixed behind its back; it closed it inside its own allowlist.

**Round gate.** Reconciliation clean: 6 paths in the round diff, 6 claimed, 1 by W8a and 5 by W8b,
nothing double-claimed, nothing unclaimed. Mirrors 9 of 9. Battery 131 passed 0 failed. Validator
exit 0, `ALL CHECKS PASSED`, zero failures. Doc links exit 0. All 17 CI `run:` steps exit 0
individually. Law-scout 6 of 6 scanned, 0 unsupported, 0 findings, with a planted 610-line control
returning `cap.file-lines` to prove the zero could have been non-zero.

**Two files now sit at 499 of the 500-line cap**, `phase-3-implement.md` and
`test_tamper_battery.py`, which is why Round 10 needs a new battery part file rather than more rows.

**A follow-up W8a surfaced:** `law-scout.md:19` and `perf-scout.md:17` still gloss the scout scope
as "(union of every wave's allowlists)", and M3 changed that scope to what the waves actually
declared. Those two lines are now stale. Round 9's W9c owns both files and picks it up.

### New findings created BY the fix rounds, caught inside them

Three so far this sprint, which is now a pattern rather than an accident. F16 was created by the F6
fix. These two were created by `fd4de7c`, Round 8's own commit, and were caught by a Round 9 wave
and by the parent within an hour of landing.

**N1, Important. `README.md:97` states the partition test as DECIDING the split.** It reads "Waves
that share nothing run at the same time, one agent each, and the parent **decides that** with a
partition test". `fd4de7c` rewrote the canonical to say the opposite at `phase-3-implement.md:178-181`:
"The three conditions say a split is PERMITTED, never which permitted split to take, and the trivial
partition, one subset holding the whole wave, satisfies all three vacuously. So a passing partition
ALWAYS exists, 'all three hold' can never on its own mean 'split'." Under the rewritten canonical
what actually decides the split is the read-surface granularity step, not the three conditions.
Found by W9d, which was told to report rather than fix, and did.

**N2, Important, found by the parent while verifying N1.** `README.md:97` ALSO still describes the
parent's round-end scout scope as "the round-touched files, the union of every wave's allowlists".
That is the exact phrase M3 replaced in `fd4de7c`. Measured wrap-safe across the five sites that
carry the concept, with README's own hit as the positive control proving the grep works: canonical 0,
`law-scout.md` 0, `perf-scout.md` 0 (both fixed by W9c mid-round), `SKILL.md` 1, `README.md` 1.
`SKILL.md:136` was handed to W9b by message while it still held the file. `README.md` was already
released by W9d, so it goes to Round 10.

**What this pattern actually says.** Every one of the three was a restatement site going stale
because the canonical it summarises moved. The sprint has a rule for this (AC8, every site points
back rather than restating) and the rule is not holding, because a summary that is genuinely useful
has to restate something. Worth a retrospective note rather than another fix.

### A figure of mine that a wave disproved

The work-doc's F17 reasoning records that `README.md` had "one other all-caps run in 448 lines", and
I repeated it in W9d's brief as an established fact. **W9d measured it and found three, not one.**
Method: `grep -onE '\b[A-Z]{2,}\b'`, minus acronyms, filenames and product names, minus everything
inside a fenced block, with the fences mapped first so the exclusions are checkable. `HARD GATE` at
`:77` and `REFRESH`/`INPUTS` at `:294`/`:297` sit inside fences; the three live-prose runs are `AND`
at `:130`, `INCLUDING` at `:141`, `NOT` at `:142`.

It downcased anyway, and its reason is better than the one I gave it. The tally was never the
strongest evidence. The provenance is: the caps at `:97` were an artifact of a verify-command
literal, recorded in this doc in my own voice, not a style choice anyone made. Register agrees
independently. **A wave handed a stale premise measured it, found it wrong, and reached the right
answer by a better route than the brief's.** That is the fourth time this round an agent has
corrected a fact I handed it.

### The stale-scope sweep, and how badly I scoped my own check

M3 changed the round-end scout scope in `fd4de7c`. Six OTHER files restated the old gloss.

**My first check found two of them, because I swept a guess-list instead of the tree.** I picked
four files I expected to carry it, found `SKILL.md` and `README.md`, and reported that as the
answer. W9c, which held two of the files, listed four more in its follow-ups from its own reading.
Only then did I sweep every tracked markdown file, and the honest count of sites needing a fix was
six, not two.

**And my first sweep was itself unvalidated.** Its positive and negative controls both errored on a
`paste`/`bc` misuse and printed empty, so the number came back with nothing standing behind it. A
control that does not run is not a control, which is a law this repo injects into every prompt.
Re-run properly: positive control `partition test` = 15, negative control = 0, target = 5 remaining.

Final state. W9b closed `SKILL.md` and `phase-ledger.md` mid-flight after I messaged it the
measurement. Still open, all outside any Round 9 allowlist, so Round 10 carries them:
`README.md`, `parallel-agents/phase-3-implementation.md` with its mirror `agents/wave-implementer.md`,
and `skills/yolo/SKILL.md`. The fifth hit is this work-doc quoting the phrase inside a finding
record, which is a quotation and stays.

`references/implement-and-test.md` says "round-touched files" with no gloss at all, which W9c
correctly called thin rather than stale. No fix needed.

### A fifth brief of mine an agent had to correct

W9c's deviation, and it was right. I told it the two scout scopes "are not identical even on a
single-wave round", carrying that forward from an earlier wave's note. The canonical argues the
opposite ON PURPOSE: "The two SCOPES do coincide there, and saying so is better than pretending
otherwise... those are the same set by construction. They are still not the same SCAN." A previous
wave had explicitly rejected the framing I handed W9c, and W9c followed the canonical rather than
the brief, preserving the real distinction (scopes coincide, scans do not).

**That is five briefs this sprint where an agent measured a fact I supplied and found it wrong:**
the `dist` ls-files command (799 files, would have printed 799 false failures a round), the
all-caps tally (three, not one), the mirror-tail geometry, the digest truncation being silent, and
this one. Every correction came from an agent that had been explicitly given permission to refute
the brief. The rate is the argument for the permission.

### Deferred to a follow-up task, not dropped

Per the user's 6-A, three upheld findings are pre-existing defects this sprint did not create, and
fixing them would widen the sprint past its goal anchor. They are recorded here so the next task
can pick them up with the evidence intact, not filed away as closed.

- **I20, Important, reproduced twice.** The mirror HEADS are covered by almost nothing. In a clone
  at `ad2b3a2`, rewriting the auto-dispatch gating clause inside `agents/code-reviewer-security.md`'s
  frontmatter `description:` (from "Gated on the diff touching auth ... folds into Reviewer B when
  it does not" to "Runs on every diff without exception, and never folds into Reviewer B") left the
  validator at rc 0 and the transcript byte-identical, and `--check` also rc 0 since the head sits
  outside the fenced block. What IS covered: `name:` by `[10]`, and one pinned sentence by `[79]`.
  What is not: the rest of the description, which is the surface that drives auto-dispatch. Note
  Round 8 measured that the two sides of a pair do not share a head at all (mirror 9 vs template 6
  on the wave-implementer pair), so this cannot be closed by extending the mirror rule; it needs a
  check of its own.
- **M13, Minor, graded exposure 1.** `scripts/check_doc_links.py:101`'s `MD_LINK` only resolves
  `.md` targets, and `:104` restricts backticked spans to `^[\w./-]+\.md$`, so a broken non-`.md`
  link is invisible. Control under the real shell: a planted `.sh` target stays green, a planted
  `.md` target reds. Exactly one real non-`.md` instance exists today, the badge at `README.md:8`
  pointing at `.claude-plugin/plugin.json`. This is the finding whose first negative control passed
  for the wrong reason during Round 7, by planting a `.bogus` target the regex ignores.
- **M4, Minor.** `scripts/test_tamper_battery.py:425` and `:434` run the ship-bar fragment with
  `cwd=REPO_ROOT`, the same shape as the `--chekc` bug Round 7 closed. `scripts/tamper_harness.py:185`
  is where that default lives. No write path exists today and the specific `--chekc` route is closed
  at `sync_agent_mirrors.py:245-249`, so the residual is a future write-mode call from a fragment
  under test.

Also deferred, and this one is a consequence of Round 8 rather than a pre-existing defect: W8b
could not land permanent regression rows for I18's pair-count floor and I21's marker-position rule,
because `scripts/test_tamper_battery.py` sits at 499 of a 500-line cap and the new part file plus
its `PARTS` entry were outside that wave's allowlist. It compressed prose twice, measured that a
full pass bought only four lines, and stopped rather than reaching, which is the failure clause
working as designed. Both rules are proved by hand-plants recorded in that wave's report. Round 10
carries them.

### Refutation of the round-2 panel, 40 upheld, 1 refuted, 1 adopted

One refuter over all 41, per the contract's per-finding budget. It re-ran every pasted
command instead of reasoning about the paste, and **corrected nine citations the panel got
wrong**, which is the argument for the refuter existing at all.

**The one refutation was productive.** I12 claimed condition 1 is declared free while the
sprint's own record shows it firing. REFUTED: `phase-3-implement.md:139` scopes the partition
test to ONE wave ("the union of every task's file allowlist **in the wave**"), a wave's tasks
are file-disjoint by construction, and a partition has no element in two subsets, so `:155-156`
is correct in the scope it is written for. The work-doc's T4 case was a task in two WAVES of a
round, a scope the test is never defined over.

**But the refuter refused to let the push-back carry the real defect away**, and filed
**NEW-1** in its place: nothing in the pre-flight loop or the partition test checks file
collision ACROSS the waves of one round. `:21-23` says apply the test to every wave and then
collect them into rounds, with no collision check on the collection; step 4 at `:25-28` has one,
but only for merges. **The work-doc caught T4 by doing a check the canonical never asks for.**
That is the single most valuable thing this round produced, and no reviewer filed it.

**Severity corrections the refuter made.** I22 has a Critical case: its narrower plant, corrupt
one shipped `dist/` file and delete nothing, gets validator rc 0 with zero FAIL lines while
`[24]` prints a green over the corruption. I18 and I20 reproduced at Critical confidence above
their filed Important. I3, I14, I16 and I17 read as Minor, each having a mitigation its filer
omitted. M15 is worse than filed: the Guardrails block's `head 7 / block 169 / tail 61` is wrong
in TWO figures, measured live at head 7 / block 226 / tail 80.

**One corroboration was downgraded, correctly.** I19 and the critic's Minor 4 are one
measurement with two filers, not two independent measurements. The findings file supplied a
single evidence set for both. Two readers agreeing is worth less than it looks when they read
the same number.

**The highest-leverage row in the whole round is structural, not a defect.** Six findings, C3,
I1, I2, I6, M1 and M2, live inside one 45-line code block at `phase-3-implement.md:232-276`.
One rewrite closes all six; fixing them piecemeal churns the same lines six times.

**Other clusters that must be fixed as one:** I18 + I19 + I21 are three holes in the same
`[75h]` tail branch, with I5's stale `Four agent files` comment a fourth staleness in the same
file. C2 + I3 + I15 are one story, `{{exclusive_resources}}` reaching the agent: declaration,
discoverability, trigger. I9 + M16 are the same `ba344b7` anchor sentence. I8 + M15 are stale
measured figures in the same block.

**Two sequencing constraints the fix waves must respect.** I4 (the reviewer's wave-size cap) and
I11 (the partition test's missing granularity rule) compound rather than cancel: the cap binds at
plan time and the test at dispatch time, so a coarsest-passing tie-breaker makes the cap binding
again and both must land together. And I12's refutation DEPENDS on the one-wave scope that I11
attacks, so if I11's fix re-scopes the test to a round, `:155-156` becomes wrong and I12 revives.
Sequence I11 before closing I12.

**A note for whoever writes the fixes.** Commit `88bab62` inserted about 147 lines into this
work-doc while the refuter was running, so every work-doc line number in the round-2 findings is
as-of `ad2b3a2` and must be re-anchored before editing. The refuter verified content by grep
rather than by line, so the findings themselves hold. It also confirmed `88bab62` closed exactly
one leg of one finding (M9's middle sentence) and nothing else.

### Phase 5 decisions, put to the user

- **Issue #7, the allowlist gate.** 7-A: each agent declares the paths it wrote, and the
  parent reconciles the round three ways, every declared path inside that wave's
  allowlist, every path in the round diff claimed by exactly one wave, and nothing
  unclaimed. All three can come back dirty, and the unclaimed check is the one that
  catches a stray edit no agent admits to.
- **Issue #8, the mirror tail.** 8-A: add the check this sprint, with an explicit
  parent-side marker in the template tail, byte-equality up to it, and full-tail
  equality when no marker is present.
- **Issue #9, the unread concurrency mark.** 9-A: keep the reviewer's mark and the
  parent's own derivation, and make the parent compare them, so a dead label becomes a
  second opinion on the decision that gates concurrency.
- **Issue #1, the round cap.** 1-A: one deep panel round, then a settle pass scoped to
  only the files the fixes touched, then a hard stop. Anything still open escalates to
  the user instead of spawning a third round. Raised by the user calling the repeat
  panel a bad design, and the measurement agrees: a second round here would re-read 17
  of 27 files, so verdict-carrying saves 37% and not much more.
- **Issue #2, what deep means.** 2-A: un-gate the panel so A, B, D and F all run rather
  than folding into B, and close the round with a completeness critic whose question is
  what surface nobody read. The critic's output is findings, not a note.
- **Issue #3, scope.** 3-A: apply it to this sprint, the same way the Phase 3 changes
  were run under themselves. The rule change itself is the next task, not this one.
- **Issue #4, how the panel is picked.** Raised by the user mid-round: reviewers should
  be chosen from what the diff actually is, not folded on and off a fixed list. The
  canned set fits this repo badly in both directions. Security and coherence fit. D
  barely does, and I had to tell it to expect most of its catalog inapplicable, which
  says the lens is wrong rather than the diff. E does not apply at all. Meanwhile the
  two lenses this product most needs are not in the set: this plugin's deliverable is
  **prose that agents execute**, so an ambiguous instruction is a shipping defect, and
  this sprint added 131 test cases that no lens audits for whether they can fail. Both
  were dispatched as pinned specialists in the same round, so the one-round cap holds.
  **The rule to write: A/B/D/E/F are a default set, not the panel.** The panel is
  derived from the diff, and a specialist is added whenever the product's real risk
  surface has no lens on it.

**The evidence behind 1-A.** Capping at exactly one round with nothing after it would
have shipped F16, an Important defect that the F6 fix itself created: F6 rewrote the two
scout protocols to give three reasons and cite the canonical, which left run point 2 in
`phases/phase-3-implement.md` pointing somewhere weaker than the copies it summarised.
So fix code needs a reader. But the reader it needed was not a second panel. F16 was
caught by the F6 wave on its way out, and F17 by the F3/F4 wave about its own file. Two
for two, the fix-introduced defects were caught by the fix waves' own scouts and
self-review. That is the whole argument for a narrow settle rather than a repeat panel,
and the sample is two, which is worth saying out loud.

### Round 9 (C1, I3, M6, I17, I4, M9, M10, M12, M11), four concurrent waves

Nine files, four waves, no file in more than one. The canonical every wave reads,
`phases/phase-3-implement.md`, was frozen at `fd4de7c` and sits outside all four
allowlists, so condition 2 holds: nobody is reading text another wave is rewriting.
That is the whole reason these four could run together while Round 8's two could not.

| Wave | Findings | Files | Duration |
|---|---|---|---|
| W9a | I4 | `phase-2.5-spec-reviewer.md` + its mirror | 11m 02s |
| W9b | C1, I3, M6, I17 | `SKILL.md`, `implement-and-test.md`, `phase-ledger.md`, `work-doc-template.md` | 12m 34s |
| W9c | M9, M10, M12 | `law-scout.md`, `perf-scout.md` | 6m 38s |
| W9d | M11 | `README.md` | 5m 04s |

Durations are transcript first-to-last timestamps. The method was checked against the two
waves whose harness-reported totals I still had: W9a 662753 ms against 11m 02s derived, W9b
755063 ms against 12m 34s derived. Both agree to the second, so the two figures I could not
read from a notification rest on a method that reproduced the two I could.

**The gate, run at round end over what the four waves declared.**

- Reconciliation: 18 comparisons over 4 waves, 0 failures. All three checks were then
  proven able to fire on planted copies: a path declared outside its allowlist, a path
  claimed by two waves, and a `decl.<wave>` filename typo. That last one is the exact C3
  breach, and it now produces `FAIL: decl.W9d missing` plus `FAIL[3] README.md unclaimed`
  instead of being globbed into `claimed` and passing.
- Mirrors: 9 of 9 identical, `--check-tails` 1 non-empty tail compared, 8 empty, 0 failed.
- Tamper battery: 131 passed, 0 failed. Doc links: 116 files, 64 line citations, all resolve.
- Validator: ALL CHECKS PASSED, 1454 ok lines against a floor of 1350.
- CI: all 17 `run:` steps executed separately, each with its own exit code, 0 failed. Run
  separately on purpose, because the `;`-joined version earlier in this sprint reported only
  the last step's code and would have hidden a failure anywhere else.
- Law-scout over the 9 declared files: 9 scoped, 9 scanned, 0 unsupported, 0 unaccounted,
  0 findings. The zero is load-bearing: the same command with a planted 610-line file added
  to the scope returned `cap.file-lines`. Perf-scout: no candidates, markdown prose with no
  loop, query, cache, fan-out or render path.

**Two more briefs of mine the agents corrected, which makes seven.**

W9a was told to pick one of three options for `{{wave_size_target}}`. It measured that two
of them were closed by evidence rather than preference: retiring the token outright reds
check `[71]`, which pins it in a fragment outside the wave's allowlist, and re-pointing it at
concurrent waves per round is refused by the signed-off answer to Q5. So it kept the token
and removed its teeth, and then said plainly that the result is thin. That is the right
shape of report: the constraint named, the option taken, and the weakness owned rather than
dressed up.

W9b refuted my sweep measurement, and was itself wrong on the numbers while being right on
the conclusion. It said my pattern returned 0 on two files and that
`phase-3-implementation.md` carried 2 occurrences. Measured: my pattern returned 1 on both
files, and that file carries 1, not 2. Its actual point, that all three sites should be
queued rather than just the README, matches what my own list already said.

**And my sweep list named a file that never carried the phrase.** I reported five sites
including `agents/wave-implementer.md`. That file measures 0 now and 0 at `fd4de7c`. The
occurrence lives at `phase-3-implementation.md:362`, which is below the
`<!-- parent-side: not mirrored -->` marker, so it is parent-side text that the mirror is not
supposed to carry and check `[75h]` correctly ignores. I read a template line as if it were
mirrored. That is the fifth bad count of this sprint, and the second where I published a
number without a control standing behind it.

**N3, a new finding this gate produced.** The reconciliation block at
`phases/phase-3-implement.md:306-400` is fenced as `bash` and is correct bash. But
`for w in $ROUND_WAVES` does not word-split in zsh, which is the shell this machine runs and
the shell an agent's Bash tool runs. Pasted there, the loop runs once over the whole string,
every `decl.<wave>` lookup misses, and the output reads as a reconciliation breach rather
than a shell mismatch. It failed loudly rather than silently, and only because check 3
exists, which is worth noting as C3's fix earning its keep a second time. The fix is to
enumerate the wave IDs literally in the `for` statement, which is what the block's own
"ENUMERATE `$ROUND_WAVES`, never glob" instruction already asks for in spirit. I hit the same
zsh trap twice in this one gate, on the loop and on an unquoted options string, so the
failure mode is not hypothetical.

**Carried to Round 10:** the three surviving stale-scope sites (`README.md`,
`phase-3-implementation.md:362`, `skills/yolo/SKILL.md`), N1 and N2 in the README, I22's
`dist/` integrity fragment, the two regression rows that need a new battery part file, and
N3 above.

### The settle scope, measured before the settle runs

1-A's whole claim is that a narrow settle beats a repeat panel. That is checkable now
rather than after the fact, so here is the number while it can still embarrass the
decision.

- The deep panel read **32 product files** (`35ccc4a..ad2b3a2`, `docs/work/` excluded).
- The fix rounds 6 to 9 have changed **15 of them** (`ad2b3a2..182844a`).
- All 15 sit inside the panel's 32, so nothing changed outside what the panel had read.
- A settle today therefore re-reads **47%** of the panel's surface, and 17 files keep
  their verdict untouched.

Rounds 10 to 13 will add `skills/yolo/SKILL.md`, a new validator fragment, a new tamper
battery part and `CHANGELOG.md`, so the final figure lands near 50 to 60%. Still a saving
against a full second panel, and smaller than the 63% the decision was taken on.

**One thing the framing missed, and it is not a small one.** The new fragment and the new
battery part did not exist when the panel ran, so they are not re-reads at all, they are
surface no reviewer has ever seen. Verdict-carrying says nothing about them. The settle
has to cover them at full depth, which means the settle is a narrow re-read plus a small
first read, not purely a narrow re-read. The earlier arithmetic treated the whole settle as
re-read and would have under-scoped it.

### The remaining rounds, and why three of the four are single-wave

The partition test refuses to parallelize what is left, and the reason is worth recording
because it is evidence about the rule this sprint is writing.

`phases/phase-3-implement.md` is the canonical every other file summarises, and
`scripts/validate-dod.sh` plus the tamper battery read the whole live tree. Both are hubs.
Condition 2 fails between a hub and anything that reads it, in either direction, so a hub
gets a round to itself. The remaining graph is hub-and-spoke, and the test correctly
declines to split it.

| Round | Waves | What | Why alone |
|---|---|---|---|
| 10 | 1 | N3, the shell fix in the canonical | every other pending wave reads this file |
| 11 | 3 | `README.md`; `phase-3-implementation.md` + its mirror; `skills/yolo/SKILL.md` | mutually disjoint, canonical frozen by then |
| 12 | 1 | I22's `dist/` fragment + the I18 and I21 regression rows | it runs the validator and battery, which read the live tree |
| 13 | 1 | `CHANGELOG.md` | it describes what the previous rounds landed |

**The Round 12 edge was nearly missed and is worth naming.** I had planned to run the
validator and battery wave beside the prose waves. The battery's
`test_the_live_tree_carries_no_mirror_tail_drift` calls
`_run_sync(REPO_ROOT, '--check-tails')` and reads `(REPO_ROOT / t)` at
`scripts/test_tamper_battery.py:329,334`, so it reads the live working tree, including the
mirror pair a prose wave would have been mid-way through rewriting. That is condition 2
failing in the direction that is easy to miss, a test reading files another wave is
writing rather than an import edge. Caught by the advisor and confirmed by reading the
test, not by the plan.

**Measured headroom, handed to each wave up front.** Round 8 lost a wave to a cap nobody
had stated, so these go in the briefs: `README.md` 448 of the 250..450 bound, two lines
spare; `scripts/test_tamper_battery.py` 499 of 500, so one `PARTS` entry spends the whole
margin and the new rows need their own part file; `phases/phase-3-implement.md` 499 of 500,
so Round 10's edit must be line-neutral or shrink. Every brief says the same thing: pay for
an addition by compressing, never by raising a bound, and if it does not fit, stop and
report rather than trimming something load-bearing.

**N3's fix shape, settled by reading rather than by assumption.** My first instinct was to
enumerate the wave IDs literally in the `for` statement. Reading
`phases/phase-3-implement.md:319`, which read `[ -n "$ROUND_WAVES" ]` at `647e122` and reads
`[ ${#ROUND_WAVES[@]} -gt 0 ]` after Round 10 landed, shows `ROUND_WAVES` is a variable the
operator assigns, not a `{{...}}` the parent substitutes. Enumerating
literally would bake one round's wave IDs into a block meant to be generic, which is worse
than the bug it fixes. The correct fix is a real array, `ROUND_WAVES=(W10a W10b)` with
`for w in "${ROUND_WAVES[@]}"`, which behaves identically in bash and zsh, and the emptiness
guard becomes `[ ${#ROUND_WAVES[@]} -gt 0 ]`. Four sites, all in place, no new lines.

### Round 10 (N3), one wave

One wave, 9m 27s, one file, line-neutral at 499 of 500. The canonical goes first and alone
because every other pending wave reads it.

Four sites changed, all in place: the emptiness guard became `[ ${#ROUND_WAVES[@]} -gt 0 ]`
and the three loops became `for w in "${ROUND_WAVES[@]}"`. Both comments that describe the
variable were rewritten in the same edit, which matters more than it looks: `:309` carried a
`$ROUND_WAVES` sigil that means "the first element only" once the variable is an array, so
leaving it would have been a comment that is now actively wrong rather than merely stale.

**Verified independently of the wave.** Old form under bash iterates 4 times, under zsh 1.
New form iterates 4 under both. Measured here, not taken from the report.

**The wave found a hole in the RED to GREEN I specified, and this is the interesting part.**
My brief said to prove the block fails under zsh and passes after. The wave built that, then
noticed the fixture could not tell a complete fix from a partial one: its deleted file sat in
the FIRST wave's allowlist, and the first array element is exactly what the unfixed
`$ROUND_WAVES` form still reads correctly in bash. So it built the discriminating case, a
deletion owned by the LAST wave, run against a partial fix with `:380` left unconverted. That
case fails a legitimately contained deletion under bash while passing under zsh, the mirror
image of the original bug, and it is what proves the fourth edit load-bearing rather than
cosmetic.

That is the same defect class as everything else this sprint has been closing: a check that
passes for a reason unrelated to the thing it claims to test. I wrote the brief that would
have shipped it. The wave caught it because the brief also told it to prove the control could
fail, and it took that instruction further than I did.

**The failure mode inverts, which is the real win.** An operator who writes
`ROUND_WAVES="W10a W10b"` against the fixed block now gets a loud
`FAIL 0: no readable decl.W10a W10b` under both shells. Before, that same string was silently
correct in bash and silently wrong in zsh, and silent-and-wrong is the expensive one.

**Gate:** reconciliation 2 comparisons over 1 wave, 0 failures, with check 1 proven able to
fire on a planted copy. Mirrors 9 of 9, tails 1 compared and 8 empty. Battery 131 passed.
Doc links clean across 116 files and 64 line citations. Validator ALL CHECKS PASSED. All 17
CI steps run separately, 0 failed. Law-scout 1 scoped, 1 scanned, 0 unsupported, 0
unaccounted, 0 findings, with a planted 610-line file returning `cap.file-lines` to prove
the zero could have been non-zero.

**One citation of mine went stale from this very fix**, the passage above quoting `:319`. It
now names both the before and after text with the commit that separates them, because a
citation that resolves to a line saying something else is the defect this sprint has spent
four rounds closing, and writing a fresh one is no excuse for it.

### Round 11 (N1, N2, M14, M15, N4, N5), four waves, one of them added mid-round

| Wave | Findings | Files | Duration |
|---|---|---|---|
| W11a | N1, N2 | `README.md` | 6m 46s |
| W11b | M14 | `phase-3-implementation.md` + its mirror | 8m 22s |
| W11c | M15 | `skills/yolo/SKILL.md` | 5m 35s |
| W11d | N4, N5 | `skills/hackify/SKILL.md` | 5m 32s |

W11d was not in the round when it was assembled. A sibling's report named two sites in a file
two earlier sweeps had called clean, so the round was re-intersected with a fourth wave and it
passed: no file shared, no line citation in either direction between `SKILL.md` and any of the
other three, and no wave running a tree-wide command. Adding to a live round is only safe
because the intersect was re-run, not because the new file looked unrelated.

**Gate:** reconciliation 10 comparisons over 4 waves, 0 failures. Mirrors 9 of 9, tails 89 lines
compared and unmoved. Battery 131 passed. Doc links clean. Validator ALL CHECKS PASSED at 1454
ok lines. All 17 CI steps run separately, 0 failed. Law-scout 5 scoped, 5 scanned, 0
unsupported, 0 unaccounted, 0 findings, with a planted 610-line file returning `cap.file-lines`.

**The acceptance criterion that governs this whole family was itself stale.** W11d found
`AC8` in this work-doc reading "the parent over the round union at round end", which is the
exact scope `fd4de7c` retired. Eight rounds of fixes were checked against a criterion naming the
wrong set. Nobody caught it because everyone, me included, was sweeping the tree and treating
the work-doc as the ruler rather than as another site that can go stale. Fixed here.

**My sweeps kept failing the same way, and the waves found the method I did not.** My pattern
was the literal phrase I remembered, so a site saying "the round union" survived six sweeps. The
waves converged independently on something better: anchor on a single word that cannot split
across a line wrap, then read every hit. W11d went further and made the point that settles it, a
pattern family is still a guess about wording, so it enumerated all 13 mentions of `parent` in
its file and read each one. Four were scope sites. A concept enumeration catches a site phrased
in words no pattern list anticipates; a phrase family cannot. That is the retrospective item.

**Two findings I did not file, after measuring.** `rules/perf-guardrails.md:24` and
`implement-and-test.md:43` both say "round-touched files" without defining the term. My first
instinct was to file both. Reading the canonical first showed `phase-3-implement.md:90-93`
introduces "round-TOUCHED" and defines it inline, so a summary using the canonical's own term is
pointing back rather than restating stale text, which is what AC8 asks for. Then W11d refuted my
reasoning in the useful direction: the two scout protocols that own this vocabulary define the
term inline every time, three for three, so the tree does not in fact treat it as free-standing.
It took the compact positive form instead, matching five siblings that already use it. The two
sites go to a later round on that basis, not on mine.

**A cost objection that measurement killed.** I assumed adding the distinction to
`rules/perf-guardrails.md` was expensive because that file is injected into every prompt under a
character budget. W11d measured the substitution: "over the round-touched files" is 28
characters and "over what the waves declared" is 28 characters. Identical. The objection was
arithmetic I never did.

**Three more brief corrections, taking the sprint total to ten.** W11c refuted the premise of a
question I asked rather than answering it: I asked how wording assuming a durable declarations
record survives in a mode with no work-doc, and it found that full hackify never read those
declarations from a work-doc either, they live in a scratch dir outside the repo. The caveat it
had drafted would have invented a difference that does not exist. W11b confirmed my geometry
measurement and refuted the conclusion I drew from it: the filed line was indeed parent-side and
unmirrored, but it was not the only site, and one inside the copied block meant the mirror did
need regenerating. W11d refuted my lean on `:16` as described above. W11a is the one wave this
round that found my brief accurate on every point.

**The wrap landmine fired inside a wave's own controls.** W11b had a naive grep return 0 on a
file that contains the phrase, split across a newline, then had its first negative control fail
the same way, and rebuilt the control in Python to dodge shell quoting. That is the failure this
sprint has now produced six times, and the first time it was caught by the control rather than
by a later reader.

### Round 12 (M16, M17), one wave

The last two sites in the round-end scout scope family, one of them
`rules/perf-guardrails.md`, which is injected into every prompt.

**The wave found a better basis for the rule than either I or the sibling wave had.** We had
both reasoned from a census of how sibling files phrase it. The wave went to the canonical's own
section heading at `phase-3-implement.md:440`, "**Run point 2, the PARENT, over what the round's
waves DECLARED, at round end**", and pointed out that the canonical uses "round-TOUCHED" exactly
once, inside its numbered loop, glossed on the spot. So the term is loop-local shorthand that
carries its gloss with it, and the positive phrasing is the prose form of the same rule. The rule
falls out of the canonical rather than out of counting siblings: compact restatement sites take
the positive form, and "round-touched" appears only where there is room to gloss it.

On that basis it refused the split treatment the sibling wave recommended and applied one rule to
both sites. It was right to: the split was reasoned under a digest-budget assumption that had
already been disproved, so the reason for the two sites to differ no longer existed.

**It proved the invariant rather than the edit.** After the change, "round-touched" has four live
uses across `skills/`, `rules/`, `agents/` and `README.md`, and all four are glossed inline, zero
bare. Verified here independently: four uses, four glossed. That is a stronger claim than "the two
filed sites are fixed", because it holds for sites nobody filed.

**My own verification of it was wrong first.** My gloss check used a window that stopped at the
first period, and the canonical's gloss sits in the next sentence, so the canonical came back
"BARE". The invariant held; my instrument did not. Widening the window to 200 characters with no
period stop gave four glossed, zero bare.

**The digest objection died a second time, in a stronger form.** The wave re-measured
`rules/perf-guardrails.md` at 315 characters before and 315 after against the 900 cap, and
confirmed the changed prose never enters the digest at all, since the digest is built only from
bold bullet leads. So the constraint I raised was not merely satisfied, it never applied.

**Gate:** reconciliation 4 comparisons over 1 wave, 0 failures. Mirrors 9 of 9. Battery 131
passed. Doc links clean. Injector suite 66 passed. Validator ALL CHECKS PASSED. All 17 CI steps
run separately, 0 failed. Law-scout 2 scoped, 2 scanned, 0 findings, with a planted 610-line file
returning `cap.file-lines`.

**This is the first wave of the sprint that could not refute its brief on anything.** Every
measurable claim it carried held: the three-for-three gloss census, the five positive-form
siblings, and the digest exclusion. The one soft spot was the recommended split, and the brief
flagged that itself and told the wave to re-derive it. That is what a brief should look like.

### Re-deriving I22 at parent level before Round 13 briefs it

A pre-derived fact has a shelf life shorter than a session, and I22 was filed in Round 2. Re-run
now against `5276ed9`: `git archive` into a scratch tree, copy the real 800-file `dist/` in,
duplicate it, append a corruption line to `dist/claude-code/skills/hackify/SKILL.md` in one copy,
run the validator in both. Both return rc 1 with 11 FAIL lines, and the two failure sets diff
clean. **Zero difference: a corrupted shipped file is invisible to the validator.** I22 confirmed.

The side-by-side is the whole method. An archived copy fails for unrelated reasons in both trees,
so the raw exit code reads like a refutation until the two failure sets are diffed against each
other.

**My first probe was invalid and I nearly ran with it.** It planted into `dist/dist/...`, a path
that does not exist in the real tree, because I copied `dist` into a directory that already
existed. It printed the same "no difference" conclusion off a plant that touched nothing. I
caught it because the path in the output looked wrong, not because any check told me. A control
proving the plant is real, `diff -q` on the two copies of the target file, is now part of the
method.

### Does the rule change work? The measurement, including what it costs

This sprint ran under 1-A and 2-A rather than the installed rules, so here is the evidence on
whether they hold. Measured, not recalled.

**The cap held. Exactly one review panel has run since the rule changed, and zero second
panels were dispatched.** The gated panel that ran before the change found 15 findings. The
un-gated deep panel that replaced it found **41** (3 Critical, 22 Important, 16 Minor), of which
40 were upheld, 1 refuted, and the refutation produced NEW-1, a defect no reviewer filed. So
un-gating the panel roughly tripled the yield, and the kind changed too: the deep round found
things that were silently not checked at all, a gate over zero comparisons, a green line counting
printed output instead of comparisons, a refusal with no execution point.

**Ten more defects were raised after the panel closed, and none of them needed a second panel.**
NEW-1 came from the refuter. N1 and N2 from a fix wave and from me verifying its report. N3 from
running the gate. N4, N5, M14, M15, M16 and M17 from fix waves reading their own files and each
other's reports. That is the mechanism 1-A was built on: fix-introduced defects and missed sites
get caught by the fix waves' own scouts, not by repeating the panel.

**The uncomfortable half, which is the more useful half.** Split those ten by origin:

| Origin | Count | What it says |
|---|---|---|
| Created BY a fix | 3 (N1, N2, N3) | fix code needs a reader, which 1-A grants |
| Missed BY the deep panel | 7 (NEW-1, N4, N5, M14, M15, M16, M17) | the panel is not exhaustive on this defect family |

Seven of ten were sites the deep panel had already read and did not file, all in one family:
a summary restating a canonical that had moved. That is real evidence AGAINST reading "one deep
round" as "one sufficient round". What made the deep panel worth it was yield and depth; what it
did not buy was completeness on a family that needs a concept sweep rather than a read. The
settle pass is doing work the panel could not, which supports 1-A's shape while undercutting the
optimistic reading of it.

**Cost, stated plainly.** Fourteen rounds, 32 waves, re-derived from the table rather than recalled. A large share of the total
was rework caused by my own errors rather than by the workflow: six incomplete sweeps, five bad
counts, one invalid reproduction that printed the right answer for the wrong reason, and eleven
briefs carrying a fact an agent measured and refuted. The rules caught every one of those. They
did not prevent them.

**A record-keeping failure the measurement exposed.** N4, N5, M14, M15, M16 and M17 were given
finding IDs in dispatch briefs and written up in round records, but were never registered as
findings in this document. Six defects existed only inside agent prompts. The work-doc is
supposed to be the single source of truth, and for those six it was not. They are registered
below. I found this only because I tried to count them, which is the argument for counting.

### Findings registered late, after being fixed

These were raised, fixed and gated inside rounds 11 and 12, but never written here as findings
at the time. Recorded now with their evidence so the record matches what happened.

**N4, Important.** `skills/hackify/SKILL.md:251` stated the parent's round-end scout scope as
"the parent over the round union at round-end". "Round union" is the retired allowlist union
under a shorter name. Missed by two earlier sweeps of that same file, including one by the wave
that had the file open, because every sweep searched for the phrase "union of every wave".

**N5, Minor.** `skills/hackify/SKILL.md:16` stated the same scope as "the round-touched files"
with no gloss. Not the wrong set, but under-specified.

**M14, Important.** `parallel-agents/phase-3-implementation.md` carried the retired scope twice,
once at `:362` below the parent-side marker and once at `:209-211` inside the mirrored block, so
the mirror carried it too and had to be regenerated.

**M15, Important.** `skills/yolo/SKILL.md` carried it three times, at `:14`, `:68` and `:117`.

**M16 and M17, Important.** `rules/perf-guardrails.md:24` and
`references/implement-and-test.md:43` used "round-touched" with no gloss. Closed by deriving the
rule from the canonical's own section heading rather than from a census of sibling files.

### Round 13 (I22, I18, I21), one wave, and what its first run found

**The new check found a live Critical on its first run.** `[56] dist integrity` reported
`dist/ ships 68 file(s) that differ from the canonical source they were copied from ... out of
791 compared`. Twelve rounds of fixes had changed source files and the shipped trees were never
re-synced. Without this check, v0.16.0 would have shipped the pre-fix text of every file this
sprint touched. The worst single instance, which makes the severity legible: the shipped
`dist/claude-code/agents/wave-implementer.md` was 3,114 bytes behind and still carried the
superseded round-end scout scope, so anyone installing from `dist/` would have got the contract
this sprint spent four rounds correcting.

Repaired at round end with `bash scripts/sync-runtimes.sh`, 798 files across 7 runtimes, and
`[56]` then reports all 791 byte-identical. I watched it go red on a real defect and green after
repair, so its ability to fail is observed rather than argued.

**My prescribed fix was unbuildable and the wave said so.** I leant toward re-running the sync
into a temporary root and diffing. There is no destination flag: `REPO_ROOT` comes from
`BASH_SOURCE`, the script `cd`s there, and every emitter writes the literal
`dist/${runtime}/${src}` at `scripts/sync-runtimes.d/00-helpers.sh:259`. Adding one would have
meant editing files outside the allowlist. It compared source to dist directly instead, with no
writes and no stored hashes to go stale, in two batched hashing calls rather than a subprocess
per file. That is the twelfth brief of mine an agent has measured and corrected.

**The trap it caught in its own draft is the best thing in this round.** Its first version of the
red line put `` `bash scripts/sync-runtimes.sh` `` in backticks inside a double-quoted string,
which is command substitution. The validator would have RUN the sync while reporting on it,
editing the tree it audits and turning its own red green. A check that repairs the defect it is
measuring is the purest form of the failure this whole sprint has been chasing, and it caught it
before shipping. The fragment now carries a comment recording the trap.

**I18 and I21 landed as real regression rows, test-first.** I18's red: with the `[75h]` pair
floor hardcoded back to 9, the fragment prints a green over a tree carrying an uncovered tenth
agent file. I21's red: with `marker_misplaced` blinded, the sync exits 0 over a marker slid above
the prompt fence with the mirror truncated to meet it, which is the coordinated move no
cross-file diff can see. Both rows carry a control holding the two verdicts apart, so each red is
the mechanism working rather than the fixture being odd.

**The cut freed the cap rather than pushing against it.** Seven mirror-tail rows moved to
`scripts/test_tamper_mirror_tails.py`, taking the battery from 499 of 500 down to 296. New file
433, new fragment 239. No bound raised anywhere. Battery total went 131 to 135.

**Gate:** reconciliation 8 comparisons over 1 wave, 0 failures. Battery 135 passed. Suite
reachability 20 passed. Doc links clean, 116 files and 65 line citations. Validator ALL CHECKS
PASSED. All 17 CI steps run separately, 0 failed. Law-scout 4 scoped, 4 scanned, 0 findings, with
a planted 610-line file returning `cap.file-lines`.

**A ticked task this reopens, and I own it.** T12's definition-of-done says "for every source file
the sprint changed, running the sync produces a generated counterpart that matches it". That was
measurably false at HEAD for 68 files, and stayed false for twelve rounds while the task sat
ticked. It is true again now. The lesson is not that T12 was ticked wrongly at the time, it is
that a done-claim about a generated artifact expires every time its source changes, and nothing
re-checked it until a wave built the check. That is the same shape as the stale-restatement family
this sprint has been closing, moved from prose to build output.

**A condition-2 violation of my own, worth recording because I have been enforcing it on others.**
I ran a tree-wide validator while this wave was mid-write on the validator itself. The result was
trustworthy only because the 68 stale files came from commits already landed rather than from the
wave's in-flight edits. I got a usable read by luck, not by method, and the rule I broke is the
one in every brief I send.

### Round 14 (I10), one wave, and the count it caught

The `0.16.0` changelog entry was written at the sprint's second commit and never revisited, so it
described the opening change and none of the twelve fix rounds. Rewritten from the diff: 85 lines
to 158.

**The gap it found that I had not:** `ceb10a8` is a `feat:` commit with zero changelog coverage,
the scouts' two run points. A feature shipped with no release note is worse than a stale one,
because a reader has no signal that anything changed.

**It re-measured every number it inherited rather than carrying it**, including the injected
digest at 895 of 900 by running the injector, the injector suite at 66 passed, and the demo GIF
byte sizes with `wc -c` on both sides.

**And it recounted the Waves column, which is how I found my fourth bad count.** It reported 32
waves over 14 rounds against the sprint record's "19", and refused to publish any throughput
figure off a table whose own numbers it could not reconcile. Re-derived here mechanically:
3+4+2+2+1+1+4+2+2+4+1+4+1+1 = 32. The 19 was the rounds 0 to 7 subtotal, correct when written and
stale from the moment Round 8's row landed. Worse, I repeated the 19 in the effectiveness section
written THIS session as a current total. Both sites corrected.

The wave was right to withhold the figure rather than pick one. A number it could not reconcile
against its own source is a number it had no business publishing in release notes, and declining
to publish is the correct move where the alternative is a fresh unverified claim.

**What it cut, and I agree with the cuts.** The wave-timing table, because it measures my
development process and not anything a user receives. Twelve rounds of fix-round detail, finding
IDs and brief refutations, all of it work on the sprint's own in-flight changes. The panel
composition rule, because it is a recorded decision deferred to the next task and is not in the
diff, so shipping it would have been a false claim. And the three deferred findings, which are
deferred with evidence rather than shipped.

**Three more brief facts corrected, taking the sprint to thirteen.** The new mirror-tail file
holds 12 test functions, not the seven my brief implied, so it named the file without a number. A
"three commits earlier" phrase I supplied was anchored to a fragment's writing commit rather than
to HEAD. And the exact wording of the stale shipped copy is now unverifiable, since `dist/` is
untracked and has been repaired, so it wrote what survives rather than repeating an unprovable
fragment.

**Gate:** battery 135 passed, doc links clean across 116 files and 65 line citations, validator
ALL CHECKS PASSED, all 17 CI steps run separately with 0 failures. `CHANGELOG.md` is exempt from
the 500-line cap by `CAP_APPEND_ONLY` in `scripts/validate-dod.d/80-file-size-caps.sh`, exempt
from the cap but not from the scan, so nothing was trimmed from an older release to pay for this
one.

### Round 15 (the settle round, un-gated), six waves, and the collision it left behind

The first round run under the rules this sprint wrote: no evidence gate, one panel, one refuter,
then fixes and stop. **The un-gated panel filed 41 findings where the gated rounds averaged 15.**
The refuter judged all of them in one pass and upheld 26 of 29 in the merged set, refuted three
(M4, M6 and one item of K9) and escalated one, K3, from High to Critical, because `[56]` could
fire in neither CI nor release and the headline gate of the release was therefore unexercised on
every path that existed. Six fix waves landed 22 findings.

**What the cap gave up showed up in this very round, which is the honest result to record.** Two
fixes from the same panel collided. C5 hardened deletions to fail every time, on the stated ground
that no declaration could carry one; X2 then gave deletions a declaration, the wave contract's
`## Paths deleted` fence. Each fix was correct against the tree it was written for. Together they
shipped a canonical file asserting something false and a producer emitting into a fence nobody
read. No validator check could see it, because both halves were prose and shell inside a document.
A second panel over the post-fix diff is exactly what would have caught it, and the cap is the
decision not to run one.

It was caught before the tag, by a reviewer outside the panel reading the round's own reports, and
fixed in `7e5f1e8` under the rule the cap itself states: a defect a fix introduces is fixed in the
same fix sequence and reported, never by opening a new round. The fix wires the declaration through
all three reconciliation checks rather than rewording the contradiction away, because the producer
already promised the parent would reconcile against both fences and bound a deleted path to the
same allowlist as a written one. **Attribution by declaration is stricter than what C5 rejected,**
not looser: C5's real objection was that allowlist MEMBERSHIP is not authorship, and a declaration
is authorship, so this completes C5 rather than reversing it.

**Proven by five rows against the document's own runnable block,** since the panel that would
normally review it was closed: a declared deletion inside the allowlist reconciles at exit 0, one
outside reds FAIL 1, an undeclared vanished path still reds FAIL 3 and names the allowlists that
held it, one path declared by two waves reds FAIL 2, and a missing fence file reds FAIL 0 rather
than being skipped. The third row is the one that proves nothing was weakened; the fifth proves the
new guard cannot be stepped over.

**Two parent-level checks were proven able to fail, not merely observed passing.** `[75f]` was
re-aimed this round at the no-second-panel clause, because the cap retired the settled-diff exit it
used to pin; softening that clause in a scratch clone reds it. And the `[70]` ban list dropping from
23 tokens to 21 was traced to its cause rather than accepted: `'A, B, D and F always'` and `'FOUR
foreground reviewers'` both became TRUE text when the gate retired, and a ban on correct text is a
trap for the next writer.

**Gate on a settled tree:** validator ALL CHECKS PASSED at 1417 ok lines against a floor of 1350,
ban tokens 155 passed, tamper battery 148 passed across all six imported parts, renderer 14 passed,
doc links 31 of 31, mirrors 9 of 9, question banks 7 checked with 0 defects, sync dry-run 7
runtimes and 804 files. `phase-3-implement.md` sits at exactly 500 lines, so the next edit there
pays for itself with a trim or a split.

## 8. Retrospective

**What the rule change bought, measured rather than asserted.** Independent waves now run together,
and the sprint ran itself under the new rules to find out whether they hold. They mostly did. The
partition test is the part that earned its place: it turns "these look independent" into three
questions with checkable answers, and the second condition, no read or write edge between subsets,
is the one that repeatedly caught pairs I had already called independent by eye.

**The un-gating is the change with the clearest evidence behind it.** The gated panel averaged 15
findings a round; the first un-gated panel filed 41. More telling than the count: ten defects
surfaced after a gated panel had closed, three created by fixes and seven simply missed, and all
seven were one family, a summary restating a canonical fact that had since moved. A lens that gets
gated off does not stop being needed, it just stops being read.

**The round cap's cost is real and it landed in this sprint, not in a hypothetical one.** Capping
Phase 5 at one panel gives up having the last batch of fixes reviewed by a panel. That is exactly
how the deletion contradiction shipped: two fixes from the same round, each correct against the
tree it was written for, contradicting each other once both landed. No validator could see it,
because both halves were prose and shell inside a document. It was caught before the tag by a
reviewer outside the panel, which is the mitigation that actually worked, and the honest reading is
that the cap trades a known cost for predictable finishing time rather than removing the cost.

**Where I was the bottleneck.** Roughly fifteen agent corrections traced to my own briefing errors,
not to the agents: a snapshot command that produced a non-repo tree and made ten checks fail on
"not a git repository", an allowlist eight files too narrow, a metrics table I had not re-measured,
and a citation I made twice. Two waves worked around the broken snapshot independently before I
noticed. The pattern is that the parent's briefs are unreviewed input to every wave, and nothing in
the workflow checks them the way it checks the waves' output.

**What I would keep.** The refuter, which paid for itself three times over: it caught that a stated
mechanism was backwards, that a finding's stated harm was wrong, and that an evidence command was
malformed and would have returned nothing either way. Findings can be right for the wrong reason,
and fixing the wrong reason is how a fix introduces a defect.

### Follow-ups

- `scripts/test_tamper_mirror_tails.py` sits at 496 of 500 lines; the next row there needs a split.
- `skills/hackify/references/phases/phase-3-implement.md` sits at exactly 500; the next edit pays
  with a trim or a split.
- `dist/` is pruned in only two subtrees, which is what leaves `dist/.DS_Store` behind.
- `[56]`'s "neither shasum nor sha256sum on PATH" branch has no tamper row, declared uncovered.
- M13 is the one deferred finding still genuinely open. M4 was refuted this round, and the
  mirror-head pin closed I20.
- The parent's own briefs are unreviewed input to every wave. Worth a mechanism.
- The five-row deletion proof lives only in scratch. This block's convention is to record printed
  output in the doc itself, the way the UNSET/RELATIVE/ABSOLUTE verification is recorded; paste the
  verdict lines in at the next edit that pays for a trim or a split.
- The scouts read `$RECON/claimed`, which now carries declared deletions too. Both scouts tolerate a
  vanished path, and the law-scout counts it under `paths_not_found` as expected, but the five sites
  that describe the scout scope still word it as `## Paths written` alone.


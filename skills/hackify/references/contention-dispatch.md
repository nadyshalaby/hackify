# Contention-first dispatch

The technique Phase 3 runs on. `SKILL.md` states the phase's goal and gates, and
[phases/phase-3-implement.md](phases/phase-3-implement.md) states the dispatch loop, the round
reconciliation and the scout run points. This file says why the shape is what it is, and holds the two
pieces every other file used to restate.

**DRY ruling, stated in this file's own header so the next writer does not fork the text again.** This
file is CANONICAL for the partition test and for the three classes of serial resource.
`references/phases/phase-3-implement.md` and `references/parallel-agents/phase-2.5-spec-reviewer.md`
cite it rather than restating it. Edit here first, then sweep those two for a pointer that no longer
says the right thing.

## The machinery is always on, and its size falls out of the partition

The design note this technique comes from made the trigger explicit only, and said never to infer it
from a task that merely looks large. Hackify deviates from that on purpose. Contention-first dispatch is
the default shape of Phase 3, there is no second mode to route the small tasks to, so an explicit-only
trigger has nothing left to gate.

What the deviation keeps is the property that sentence was protecting: **nothing is ever inferred from
apparent size.** Contention analysis runs on every work-doc, and the number of waves is whatever the
partition says it is.

- Zero contended writes, so no foundation wave. It is marked complete with a written reason, never
  dropped in silence.
- One track, so nothing to assemble. Same treatment.
- A diff with genuinely nothing to test, so no testing wave. Same treatment again, and "nothing to
  test" is a written reason rather than a shrug.
- A two-file change therefore looks exactly like hackify looked before this shape landed, and a
  nine-module build looks like the four stages below.

The speed does not come from skipping the verification. It comes from deleting the waiting. Deferred
verification does not disappear, it moves, from the author who has the context now to a stranger three
days later reading unfamiliar code under time pressure, and it arrives all at once at the moment there
is least room to absorb what it finds. Parallelise the work, never dilute it.

**The testing wave is not an exception to that, and it is worth saying so because it looks like one.**
What that paragraph refuses is verification deferred OUT of the sprint, onto a reviewer who was never
here. The testing wave runs inside Phase 3, on the same tree, against tracks that reported hours ago
and whose handoff reports are still on disk, and Phase 4 does not open until it has landed. It defers a
context switch. The thing being refused is a change of author.

## Contention is invisible in a plan

Give one agent a module and it works. Give nine agents nine modules in one working tree and they
overwrite each other in silence: there is no merge in a shared tree, just a last write that wins, with
no error at any step.

The cause is structural rather than careless. A module is never as self-contained as its folder
suggests. It has its own directory, and then it needs a table, a migration, an error code, a route
registration and a background job, and each of those lives in a file every other module also has to
edit. In the build this technique was drawn from there were exactly five such files and all nine tracks
needed all five, which put the effective width at one.

A plan cannot warn you about that. It describes a bounded context and says nothing about the migration
counter, because **the plan speaks the domain's vocabulary and the contention lives in the build's.**
So the enumeration below is done by asking what a module needs beyond its own folder, never by reading
the plans and looking for overlap.

## The three classes of serial resource

A serial resource is anything that forces two pieces of work into different waves. Enumerate all three
classes before partitioning anything.

1. **Shared files.** Any file two tracks would write: the schema, the migration directory, the error
   registry, the route mount, the job index.
2. **Generated sequences.** Migration numbers, ordered registries, anything whose next value is computed
   from what already exists. Two agents running the same generator produce two files claiming the same
   number, and nothing warns either of them.
3. **Exclusive external resources.** Databases, ports, queues, rate limits. Every one of these gets the
   re-test below before it is allowed to bound the partition.

Phase 2.5 emits this as a `## Serial resources` table, one row per resource, each carrying its kind, the
task IDs that hold it, its exclusivity verdict and, where the verdict is conventional, the isolation
that lifts it (`references/parallel-agents/phase-2.5-spec-reviewer.md`).

## The exclusivity re-test

Ask of every named constraint whether it is **genuinely exclusive** or merely **conventionally serial**.
A shared file usually is genuinely exclusive: two writers in one tree really do clobber each other. An
external resource very often is not, and lifting one converts a hard bound into a free one.

The worked example is the single test database. It reads as a hard bound, because two integration runs
against one database truncate each other's tables mid-run, and codebases write that down as a known
hazard. It turned out to be conventionally serial. One fresh database created per track lifts it
entirely. Nobody had checked, because it had always been described as a constraint, and that single
re-test took a real build's partition from four wide to nine.

A row with no verdict is unfinished, not cautious. Re-test in every mode, on every run: the check costs
one question and it is the highest-return question in the phase.

## The foundation wave

One solo agent lands every contended write for every track at once: each table, each migration, each
error code, each queue registration. It writes no business logic. **Its real output is permission for
everything after it to run in parallel**, which is why it goes first and alone rather than being smeared
across the tracks that need it.

It is also the highest-stakes wave in the run, because a wrong constraint here is every module wrong. It
gets the full definition of done, schema tests included.

A serial resource settled in the foundation wave stops blocking condition 3 below for every round after
it, which is what turns a long line of forced-serial waves into a couple of rounds.

## The partition test

Canonical statement. Take the union of every task's file allowlist in the wave. Ask whether that union
splits into two or more subsets where all three of these hold:

1. **No file appears in more than one subset.**
2. **No import edge runs between the modules those subsets live in, in EITHER direction.** Where the
   tree has no imports to follow (prose, docs, config), the edge is that same relation without the
   keyword: one subset reading text or values that another subset is rewriting.
3. **No subset holds a serial resource that another subset also holds**, a shared file, a generated
   sequence, or an exclusive external resource such as a test database.

When all three hold, the subsets MAY be dispatched as concurrent waves, one agent each. When any one of
them fails, ONE agent takes the whole wave.

### The dispatch budget

Two numbers size a round, and **this file is the only place in the repo that carries them as digits.**
Everywhere else names them, "the per-agent task budget" and "the concurrent-wave budget", so changing
either is one edit here rather than a sweep that misses a site.

- **Per-agent task budget: 20 tasks.** One agent carries up to twenty Sprint Backlog tasks in a single
  wave. Under that number the packing keeps going; at it, the wave looks for a split line.
- **Concurrent-wave budget: 10 waves.** One round dispatches up to ten waves at the same time, one
  agent each.

**Both are packing targets, never quotas.** They decide which of the PERMITTED partitions to take; they
never permit one the three conditions above refuse. A wave that reaches the per-agent budget and cannot
split without putting one file in two subsets stays whole and runs long, and a project whose features
all touch the same three files comes out one wave wide with the whole concurrent-wave budget unspent.
That is a correct round, and the wave log says so in a line rather than dressing the width up as a
choice.

**The per-agent budget counts WORK, and a stage whose work arrives as one backlog task still has to be
counted.** Test authoring reaches Phase 3 as a single Sprint Backlog task, so a packer that counts task
IDs sees one, never gets near the number, and never looks for a split line, while the work behind that
one task is every module the round landed. Counting that way exempts the largest stage in the round
from the only ceiling there is. So the testing stage is counted by the production surface it must
cover, one unit per module the round landed, and THAT is what the per-agent budget bounds. `The testing
stage splits like any other stage` below carries the rule, and `Which passing partition you take is
part of the test` decides the shape it takes.

The two budgets multiply rather than trade: the ceiling on a round is the per-agent budget times the
concurrent-wave budget, and the partition is what decides how much of it a real backlog can reach.

### Which passing partition you take is part of the test

The three conditions say a split is PERMITTED, never which permitted split to take, and the trivial
partition, one subset holding the whole wave, satisfies all three vacuously. So a passing partition
always exists, "all three hold" can never on its own mean "split", and a greedy reading shatters a wave
into singletons that each re-pay the setup cost one-agent-per-wave exists to avoid. Apply it coarse to
fine:

1. **Start at the whole wave, one subset.** The default, and it always passes.
2. **Propose something finer ONLY where the tasks do not share a read surface**, meaning the same types,
   the same neighbouring code and the same conventions. "These two feel separable" is no proposal. A
   subset that has reached the per-agent task budget is the one proposal that needs no read-surface
   argument to be raised, because the packing itself raises it; it still has to find a split line the
   read surface can live with, and it still has to pass step 3.
3. **Test the proposal against all three conditions.** If one fails, fall back and stop.
4. **Between two proposals that both pass, take the fewest subsets that keep every subset at or under
   the per-agent budget**, and never more subsets than the concurrent-wave budget. Below the budget a
   finer split still has to earn its way past a coarser one by showing the subsets share no read
   surface. At the budget that argument is already made, since a subset nobody can pack further is a
   subset the packing has stopped defending.

Step 2 is load-bearing because conditions 2 and 3 cannot see a read surface at all. Condition 2's
operative branch is a write-dependency test, one subset reading what another is rewriting, so two
subsets that merely read the same file create no edge and a shared read surface passes straight through
unnoticed.

Condition 1 is inherited from the wave plan rather than work the test does: a wave's tasks are
file-disjoint by construction, so it is already satisfied before the test starts. The teeth are
conditions 2 and 3. Condition 2 exists for what file-disjointness cannot see, because two agents that
both read a shared type while each writes its own module can still contradict each other, and that
contradiction is the defect Phase 5's coherence lens exists to catch.

### The overlooked half, and the rule that saves the partition

A second condition breaks the partition retroactively if you miss it. **A track that finds a defect in
shared code must `report it, not fix it`.** The moment a track reaches outside its allowlist, the
partition it was dispatched under stops being true, and it stops being true for work that already
happened, in every sibling track, none of which will ever be told.

So the track writes its code as though the missing thing exists, names exactly what it needs spelled as
it imported it, and hands that to the assembly wave. A wrong import that is reported is cheap. A file
edited outside the allowlist may have silently destroyed a sibling's work, and nothing will tell either
of them.

## Build against planned contracts, not landed code

The dependency graph looks like it forces a sequence: checkout needs codes, earnings needs
reconciliation, the dashboard needs both. It does not. A track builds against the interface its plan
states, and the plan is the specification wherever plan and landed code disagree.

Cross-module type errors on imports of things siblings are building right now are **expected**, they are
not that track's defect, and they are resolved once, in assembly. Any other type error belongs to the
track that produced it. This is what collapses a five-deep critical path into one wave.

## What each track owes, and the small set that genuinely cannot be done yet

Every track delivers production code that meets the project's own definition of done. What it does not
deliver is its own tests, and the deferred set now splits two ways rather than one. **Some of it is
deferred because it cannot physically exist yet**, which is everything that needs a second module,
and that half goes to assembly. **The rest is deferred by schedule**, which is the test authoring, and
that half goes to a testing wave that runs after the last module track and before Phase 4.

What stays in the track is what only the track can settle: the type check, the lint run, and the
module's own correctness. Those are seconds of work and they are the only cross-agent contract check
that exists, so moving them would buy nothing and cost the round its earliest signal.

**The scheduling half is a real trade, and it has two prices rather than one.** The first is context.
The author holds it now and the testing stage has to reconstruct it, which the stage's brief pays back
by naming what each track landed. The second price is the one this file used to leave unsaid, and it is
the larger of the two. Moving test authoring to the last stage does not delete that work, it moves it
BEHIND everything else, onto the serial depth that `Honest limits` names as the thing that usually does
not fit. A stage that cannot split is a stage whose whole cost is serial, however wide the tracks ran,
which is why the stage is packed and split like any other rather than dispatched whole by default.
What the move buys is production waves that pack without test authoring competing for the same agents,
and a stage that writes tests against a tree where every seam is already visible instead of N tracks
each testing what they can see from inside. **Tests are not dropped and they are not optional. They
move, and they still block the finish.**

| Check | Where it runs | Why there |
|---|---|---|
| Unit tests over business logic, state transitions, money maths, authentication and authorisation | Testing wave | The bulk of the work, and it reads best against code that has already landed. |
| Property-based tests on money paths | Testing wave | A ledger that balances is a property of the module, provable in isolation, so it needs the module and nothing else. |
| Module integration tests | Testing wave | Possible the moment each track has its own database, and cheaper once every track's database exists. |
| Mutation proofs, each one named | Testing wave | They belong beside the test they judge, so they follow the tests rather than staying behind alone. |
| Type check and lint | In the track | Seconds, and the only cross-agent contract check that exists. |
| Cross-module integration | Assembly | The other module does not exist yet. Genuinely impossible earlier. |
| Mounted-surface tests: route and spec drift, the permission matrix, the cross-tenant isolation sweep | Assembly | Nothing is mounted until assembly, so these would measure an empty router. |
| Boot the service and send it real requests | Assembly | Needs the whole system. See below. |
| Reviewer panels | Assembly | Cross-module coherence is not visible from inside one track. |

### The testing stage splits like any other stage

The stage keeps its place at the end. What it does not keep is a fixed width. **A testing stage whose
count exceeds the per-agent task budget splits into concurrent testing waves, one agent each**, judged
by `The partition test` above: the same three conditions, in the same order, asked of the union of the
test files the stage would write AND the production files it would mutate for a watched red. Both halves
are writes. A watched red breaks the line a test protects and restores it, so two subsets whose test
files are disjoint still collide on a production file they each mutate, and a union drawn over the test
files alone would call that pair partitionable while the tree says otherwise. There is no fourth
condition for tests and no test-only variant of the test. A condition written twice is a condition that
can drift, and a drifted copy would be least likely to be noticed here, in the one stage nothing runs
after.

The count the budget reads is the production surface the stage must cover, per `The dispatch budget`
above, never the number of backlog tasks that carry it. `Which passing partition you take is part of
the test` then decides the shape, coarse to fine, so a small stage stays one wave and a large one
splits only where a real split line exists.

Test files are usually file-disjoint by module, which is why this normally holds: a module's tests sit
beside that module, name that module's symbols, and rewrite no file another subset reads. When it
holds, the stage's serial depth stops being the whole round's test-authoring cost and becomes the cost
of its widest subset.

Worked. A round runs its production waves out to the ceiling the two budgets multiply to, so the tracks
land many modules' worth of code and the backlog still carries ONE test-authoring task. Count task IDs
and the stage is one; count production surface and it is the whole round. The second count is the one
the budget reads, so it clears the per-agent budget, step 2 of the coarse-to-fine rule has its proposal
raised by the packing itself rather than by a read-surface argument, the three conditions are asked of a
per-module partition of the union above, and the stage dispatches as concurrent testing waves, one agent
each, up to the concurrent-wave budget. Those waves are siblings like any other, so each one is handed
the other testing waves' IDs and reads [sibling-track-rules.md](sibling-track-rules.md). A small round
takes the same path and stops at step 1: its count is under the budget, no proposal is raised, and the
stage stays one wave.

**Condition 1 has real teeth here, unlike in a production wave.** There it is inherited from the wave
plan, because a wave's tasks are file-disjoint by construction and it is satisfied before the test
starts. The testing stage arrives as one task whose allowlist is the whole test surface, so there is no
construction to inherit from and the subsets are drawn by hand. A suite with a shared fixture file every
test rewrites, a single snapshot corpus, or one test harness no per-wave isolation lifts fails condition
1 or condition 3 for real. That stage runs as one wave, long, and the wave log records WHICH condition
refused the split rather than leaving the width to look like a preference.

### Why the boot step is mandatory rather than nice to have

Two of the source build's most expensive defects were invisible to the entire suite and to every review.
Zero routes could create a payment intent, on a fully green build, for a whole round, because nobody had
registered the route. And 5417 passing tests sat on an idempotency middleware that validated a header
and then ignored it, so three POSTs under one key created three payment intents where the contract
requires one and a 409.

Neither was a code defect a reviewer could see in a diff. **Both were absences**, a route nobody
registered and a middleware nobody mounted, and absences are invisible to tests that mount their own
subject: every test of that middleware mounted it itself. Only assembling the system and sending it a
real request finds them, which is why the assembly wave mounts every registrar itself rather than
trusting that the tracks did. Phase 4's ship gate then records the proof, `ship.build`, then
`ship.boot`, then `ship.smoke`, in that order ([ship-gate.md](ship-gate.md)).

## What the dispatcher owes

Six obligations, each one earned in the build this came from rather than assumed.

- **Re-run the gates yourself.** Never record a green you did not produce. Every wave reports its gates;
  re-run them before the commit. You learn they match by checking, not by assuming.
- **Treat the numbers in your own briefs as claims.** A brief here told an agent to fix six sibling
  sites. There were four, and every other site used an inline literal that never needed the change. The
  agent measured rather than obeyed, and was right to. Say in the brief that your numbers are claims to
  re-derive.
- **Finish what an agent honestly could not.** One track reported a defect it could not bisect and said
  so instead of guessing. The dispatcher settled it in one command by reading the previous commit's copy
  of the file: byte-for-byte the same race, so the defect was pre-existing. An honest "I could not
  verify this" is a handoff, and the dispatcher is who it hands to.
- **Never stage by wildcard while tracks are running.** Agents are told never to run `git checkout`
  because it destroys a sibling's uncommitted work. `git add -A` is the mirror of that hazard and it is
  easier to miss: it sweeps every running agent's half-finished work into whatever commit you happened
  to be making. It happened in the source build, and a commit whose message read like a docs change
  carried 33 files, only one of which was a document. Stage by explicit path, and commit only the
  surface of a track that has reported complete.
- **Run the cross-agent checks mid-flight, not at the end.** Architecture and rule checks are the one
  signal that sees across every track at once, and they are cheap. A mid-flight run in the source build
  found ten guardrail breaks and seventeen money-rule breaks across four tracks, and every one was
  corrected where it stood instead of becoming assembly-wave rework. When a shared check fires on an
  agent's work, read the check before you doubt it. An exemption granted under time pressure is how a
  guardrail dies.
- **Correct in flight rather than filing debt.** Running agents can be messaged. When the standard
  changed mid-wave in the source build, ten agents were corrected where they stood rather than left to
  finish against a superseded brief. A correction sent at minute forty is worth ten times the same
  correction filed as a follow-up task.

## Dispatching a concurrent round, and keeping its progress on disk

**Module briefs.** `hackify:implementer` refuses on any of its twenty-one INPUTS
arriving unfilled, and eight of them have no producer anywhere else: the
Phase 2.5 wave plan emits wave numbers, task IDs, an agent type and a
concurrency mark, and stops. So the parent fills a `### Module briefs` block in
the work-doc before it dispatches, one block per track when a round holds two or
more, carrying `track_id`, `sibling_tracks`, `owned_elsewhere`,
`mandatory_reading`, `sharp_invariants`, `database_name`, `exclusive_resources`
and `handoff_contract`. The skeleton lives in
[work-doc-template.md](work-doc-template.md). **`plugin_root` is NOT one of the
eight and never goes in the block**, even though the wave plan does not emit it
either: the parent already holds it, as the absolute path carried in any
always-on rule injection it received this session or as its own skill's base
directory, and passes that straight through instead of writing it down per
track. Copying it into a module brief gives a value that was never per-track a
place to drift per track. A solo wave fills the same block,
and four of those are `none` on every solo wave because nothing runs beside it:
`track_id`, `sibling_tracks`, `owned_elsewhere` and `database_name`. The other
four are decided per wave and are `none` only when the wave truly has nothing to
put there, `exclusive_resources` included, since a solo wave can hold a shared
test database or a generated sequence exactly as a concurrent one can. `none` is
a decision and an empty line is the absence of one. Those eight are a SUBSET of
the nine the agent accepts at `none`: the ninth is `work_doc_path`, `none` in
quick mode alone, and quick writes no work-doc for the block to live in.
`file_allowlist` is not on that list because each task carries its own allowlist
in the Sprint Backlog text, and the union is the wave's bound. Derive both from the
`## Serial resources` table rather than by intuition: a file two tracks would
both write is a contended write and belongs to the foundation wave.

**`sibling_tracks` is what turns the side-by-side rules on.** Naming the other
tracks makes the agent read
[sibling-track-rules.md](sibling-track-rules.md) in full and apply every rule in
it on top of its always-on contract: its own database, cross-module type errors
that are expected and not its, report-don't-fix on shared code, a track file
instead of Daily Updates, no registrar mounting, no command that discards
working-tree state, and the eight-item handoff report the assembly wave mounts
from. A solo dispatch passes `none` and never opens that file.

**Track progress, and the track files stay.** A concurrent track never writes the
work-doc. Ten tracks appending to one markdown file is exactly the shared-file
contention this document exists to remove, and an append has no lock, no merge
and no error when a write is lost. So each track keeps writing its own
`docs/work/<slug>.tracks/<track_id>.md`, disjoint by construction, updated as
each unit goes green rather than once at the end. Widening the round makes that
indirection more necessary, never less.

**And the dispatcher puts that file in the track's allowlist.** The allowlist is
the absolute bound on what a track may write, so a track ordered to write its
progress file and handed an allowlist that does not name it has been given two
orders that contradict each other. That is not hypothetical. One round here split
five tracks two ways on it, two writing the file and declaring it, three refusing
and reporting through their wave report instead: one rule, five agents, two
behaviours, and no error at either end to say which was right. The contradiction
is the parent's to remove, because the parent is the one who builds the list. So
when a wave is dispatched concurrently,
`docs/work/<slug>.tracks/<track_id>.md` goes into that track's file allowlist
beside its source paths, every time, and a concurrent dispatch whose allowlist
omits it is underfilled rather than merely terse.

**What changed is the merge cadence.** The parent merges a track's file into
`## 6. Daily Updates` **as that track returns**, rather than merging all of them
once the round has landed, and drops the folder when the round closes. Only the
parent ever writes the work-doc, so a per-return merge adds no second writer; it
just stops the doc running a whole round behind the tree. On a round nine tracks
wide that dies after the sixth return, the old cadence leaves a work-doc naming
nothing and this one leaves a work-doc naming six.

**A solo wave writes Daily Updates itself.** A foundation wave, an assembly wave
and a single-track round have no sibling to collide with, so there is nothing
for the indirection to protect, and the mechanism gets out of the way. That is
the same rule the wave count follows: the shape is decided by the contention
that is actually present, never by how large the work looks.

The point both halves serve is one sentence. **Progress reaches disk while the
work is happening, not after it**, so a session that dies mid-round leaves a
work-doc that still says what every track had finished.

## Honest limits

- **It is weakest exactly where it looks strongest.** The modules that fan out most cleanly are the
  least coupled, which are the ones that needed the parallelism least. Coupled work still runs in
  sequence.
- **It cannot lift a dependency on the outside world.** Production data access, other repositories with
  their own stacks, cloud infrastructure that has to be provisioned: no dispatch width touches any of
  those.
- **The assembly wave concentrates the risk.** Every assumption every track made lands there at once. If
  a contention-first round fails, it fails there, and it fails late.
- **It needs a codebase that has recorded its own failure modes.** A blind agent cannot rediscover a trap
  that cost the team a day, but it avoids that trap reliably when the brief names it. The briefs are only
  as good as the traps they carry.
- **The budget is a ceiling, not a quota.** Agents contend for CPU, for the filesystem and for the
  dispatcher's own attention, and the concurrent-wave budget is where that contention was judged to
  stop paying. Packing up to it is the default; reaching it is not the goal. A round that lands at
  four waves because four is what the partition allowed is a correct round, not a missed one.
- **Width is a property of the codebase, not of the fleet.** A project where every feature touches the
  same three files goes one wide however many agents you own, and past that point more agents make it
  slower because they queue on each other. The first investment in compression is a cleaner partition,
  which is what the foundation wave buys.
- **Four stages run in sequence whatever the width**, foundation, then tracks, then assembly, then the
  testing wave, and whatever they cost they cost serially. When a target does not fit, it is almost
  always that serial depth that does not fit rather than the total work. Widening the tracks does not
  shorten the other three. **Moving test authoring to the last stage lengthens that depth on purpose**,
  and splitting the stage is the only thing that bounds what it lengthens by. An unsplittable testing
  stage puts the whole round's test-authoring cost on the critical path, one agent deep, however wide
  the tracks ran.
- **A test suite that is not file-disjoint cannot be split, and nothing here makes it so.** The testing
  stage splits on the same partition test as everything else, so a suite built around one shared
  fixture, one snapshot corpus or one harness no isolation lifts comes out one wave wide and stays
  there. The first investment is the same one production width needs, a cleaner partition, and here
  that means test files that belong to a module rather than to the suite.

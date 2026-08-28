# Phase 3, Implement (foundation wave, then concurrent tracks, then assembly)

Loaded by `SKILL.md` when this phase opens. The phase's entry conditions, hard gates and exit artifact are stated in `SKILL.md`; this file is the protocol.

**Goal.** Ship the Sprint Backlog in three stages: a solo foundation wave that lands every contended write, then N concurrent module tracks that each deliver DONE, then a solo assembly wave that mounts everything and boots it for real. Each wave goes to ONE foreground subagent that carries the whole wave. Inside a wave the saving is tokens and coherence, not wall-clock; across waves it can be both, whenever the partition test clears two waves to run at the same time.

**The technique behind this shape, stated once and not restated here:** [../contention-dispatch.md](../contention-dispatch.md). That file is canonical for the partition test and for the three classes of serial resource; this file is the dispatch protocol that runs on them.

### The three stages, and how the shape scales down

Phase 2.5 has already named every serial resource in a `## Serial resources` section, re-tested each one for real exclusivity, and pulled every contended write into one place. Phase 3 then runs:

```
foundation wave (solo)    every contended write, at once, no business logic
  → N module tracks       concurrent, each under its own allowlist, each delivering DONE
  → assembly wave (solo)  mount every registrar, reconcile every seam, boot it for real
```

**The size falls out of the partition, never out of how large the task looks.** Zero contended writes and there is no foundation wave: mark it complete with a written reason, never drop it in silence. One track and there is nothing to assemble, same treatment. A two-file change therefore dispatches one wave and looks like an ordinary hackify round. Nothing in this phase is ever inferred from apparent size, and the deliberate deviation that makes the machinery always-on is argued in [../contention-dispatch.md](../contention-dispatch.md).

**Agent selection, decided per wave and recorded in the wave plan:**

Every wave takes ONE agent type, `hackify:implementer`. What the wave's shape decides is a single input, `{{sibling_tracks}}`:

| Wave | `{{sibling_tracks}}` | Why |
|---|---|---|
| Foundation (solo) | `none` | Nothing runs beside it, so the blind-sibling rules protect nothing and only cost context. |
| Two or more concurrent tracks | the sibling track IDs | The agent reads [../sibling-track-rules.md](../sibling-track-rules.md) in full and applies it on top of its always-on contract: its own database, siblings it cannot see, builds against planned contracts, and it never discards working-tree state. |
| Assembly (solo) | `none` | Same reason as the foundation wave: no siblings to be blind to. |
| A single-track round | `none` | One wave in the round means no siblings, so the blind-sibling rules buy nothing and cost context. |

A `none` there is a decision the dispatcher made, never a blank, and a solo dispatch never opens the sibling-track rules. The agent is dispatched by registered agent type, never by pasting a template ([../parallel-agents/README.md](../parallel-agents/README.md)).

**Ledger, at phase open.** Set `Phase 3. Implement (all waves committed)` to in-progress in the work-doc's `## 0. Phase ledger` block, with frontmatter `status: implementing` in the same edit, and re-print the whole block after that edit is saved. Never open it while `Phase 2.5. Spec review` is still open. Waves run INSIDE this phase; they never advance the ledger past it. Contract: [../phase-ledger.md](../phase-ledger.md).

**Pre-flight, take the wave plan up.**

```
1. READ the plan out of the Phase 2.5 spec reviewer's report rather than rebuilding it: its waves, each wave's task
   IDs in run order, each task's own file allowlist out of the Sprint Backlog task text, the `## Serial resources`
   section, and the `[concurrency candidate]` / `[serial: <condition>]` mark on each wave line. Reading the plan is
   not re-planning it, and the line between them is drawn under "The wave is the unit of dispatch" below, in the rule
   headed "The pre-flight plan IS the dispatch plan".
2. Pull every task that holds a serial resource into ONE solo foundation wave and run it first, and put the
   mounting, reconciling and real-boot tasks into ONE solo assembly wave and run it last, per "The three stages"
   above. A stage with nothing in it is marked complete with a written reason, never dropped in silence.
3. Apply the partition test (canonical: `../contention-dispatch.md`) to every wave YOURSELF, then collect the waves
   that may run at the same time into ROUNDS. A round holding one wave is normal. Put your verdict beside that
   wave's mark and report any disagreement, per the two paragraphs under this block.
4. Intersect the ROUND you just assembled, wave against wave, as its own step: step 3's test is scoped to ONE wave and
   cannot see this. A path in two waves SPLITS the round, the later wave moving to the next round or the two merging.
   Record the intersection even when it is empty. Rule: "Rounds are ASSEMBLED, and assembly is where collisions
   enter".
5. Merge consecutive waves only on the terms "The pre-flight plan IS the dispatch plan" sets out, no file colliding
   inside the merged set and no dependency edge crossing the merge. That is the ONLY adjustment you may make; the rest
   of the plan stays as the reviewer wrote it.
6. Write the plan into work-doc Approach as "Execution waves", round by round, each wave listing its task IDs in run
   order (`W1a: T1, T3, T2`). Show user before round 1.
```

**Why step 3 re-derives what the reviewer already marked, and why that is not re-planning.** The spec reviewer's contract settles
the division in its own words, **"You MARK and the parent DECIDES"**: the reviewer applies the test to its own plan and marks each
wave, and the parent applies the same test at dispatch. The reviewer also restates the test inline in compressed form, and a
restatement can drop a condition; the parent reading the test from its canonical file is the only thing behind that. **Step 3 is a
backstop, and the mark is not. Do not remove it as duplication.**

**But the backstop is two keys in one direction and ONE key in the other.** A wave marked `[concurrency candidate]` needs the parent
to agree before it runs concurrently, so there a wrong mark cannot start a bad concurrent run on its own. The reverse has no such
property: a wave marked `[serial: <condition>]` turns concurrent the moment the parent says so, because "Your verdict is the one
that dispatches" below holds both ways and the disagreement record is a Daily Updates line rather than a gate. Nor are the two
parties checked alike, since the reviewer answers a gated checklist item for its mark (`agents/spec-reviewer.md`, VERIFICATION item
21) and the parent answers nothing. The one direction that can corrupt a round runs FROM the party holding a checklist TO the party
holding none, on a single key.

**Compare your verdict against the mark, and say something when they differ.** Agreement costs one line in the wave log and buys a
second opinion on the decision that gates concurrency. A disagreement is written into Daily Updates naming the wave, both verdicts
and the condition at issue, and it is worth reporting in BOTH directions: a wave the reviewer marked `[concurrency candidate]` that
you find serial is the near-miss this comparison exists to catch, and a wave marked `[serial: <condition>]` that you find concurrent
means either the mark is stale or the reviewer's inline restatement of the test lost something, which the next sprint wants to know
before it reads that restatement again. Your verdict is the one that dispatches, in both directions; the mark is evidence, never the
decision. **The serial-to-concurrent flip pays for its single key, before the round starts**: that same entry carries the condition
the reviewer named, the evidence it does not hold, and your own answer to each of the three partition-test conditions, one line
apiece. Without it the flip is an unchecked override, not a verdict. The opposite flip needs no such payment; it costs a round of
wall-clock and lands on the safe side.

**Per-wave loop, run once per round:**

```
1. Set frontmatter: status: implementing, current_task: R<n>:T<a>+T<b>+… (every task in the round, across all of its
   waves).
2. Dispatch ONE subagent per wave, every wave in the round in ONE message. Each prompt is self-contained: work-doc
   path, THAT wave's task IDs in run order, each task's exact files, the wave's union allowlist, test mode, any
   exclusive resource that wave holds, rules summary, "do NOT touch any other files". Before dispatching, create
   `$RECON` and `touch $RECON/round_start`, the clock step 3's mirror sweep reads. `$RECON` lives until step 7 ticks,
   since step 6 scopes the scouts from it.
3. Wait for every agent in the round. Read every report. Reconcile the round's paths three ways against what each wave
   DECLARED under `## Paths written` and `## Paths deleted`, and check each task's hunks stay inside that task's OWN
   allowlist; the union never widens a task's reach. Rule and form: "The round's allowlist reconciliation" below.
4. Run full project verification (test + lint + typecheck) ONCE for the round, after every wave in it has returned.
   Any suite that needs an exclusive resource runs here and nowhere else, per the exclusive-resource clause below.
5. On red: classify, agent failure (re-dispatch sharper prompt) vs. plan failure (drop to Phase 3b). Never paper over.
   A red belongs to the wave that caused it; the other waves in the round keep everything they landed.
6. Run BOTH deterministic scouts over `$RECON/claimed`, what the waves DECLARED and never the union of the allowlists,
   BEFORE ticking tasks: the perf-scout (references/perf-scout.md) and the law-scout (references/law-scout.md, the
   bundled lawkeeper scanner scoped with --paths-from). This is the PARENT's run point, the second of two. Carry each
   wave's own dispositions forward unchanged, stage what only this wider scope shows or send it back out as a one-task
   wave, give every candidate exactly one disposition, never write the fix here, and append both staging tables to the
   Daily Updates entry. Why the scope is the declared set and not the union, and why there are two run points: "The
   scouts run twice".
7. Tick ONLY the task IDs each report's `## Wave status` lists as landed, never the whole wave; append one Daily
   Updates entry per landed task. Full rule under Wave-end persistence below.
8. Commit ONCE for the ROUND, after every wave in it has returned (conventional subject; the body names every task ID
   in the round and marks which landed and which did not, on the same rule step 7 ticks by). A single-wave round is
   this rule with one wave in it.
9. Advance to round N+1.
```

**Per-task safety constraints (in the wave agent's prompt):**

| Constraint | Wording |
|---|---|
| File allowlist | "Modify only these files: `<list>`. If another file is needed, STOP and report, do not edit." |
| Repo brief | The `### Repo Brief` block from the work-doc, verbatim, as `{{repo_brief}}`. "Treat it as given, do NOT re-derive it, spend your reads on the diff instead." Unfilled means the agent refuses. |
| Command allowlist | "Run only these commands: `<list scoped to your files>`. The parent runs repo-wide checks." |
| Exclusive resource | Passed as `{{exclusive_resources}}`, one resource per line, or the literal `none`. **Two values, two wordings; the `none` case gets its OWN string and is the majority case.** Wave HOLDS one: "This wave holds `<resource>`. Run scoped unit tests ONLY; do NOT run `<suite>`. The parent runs that suite once, serially, after the round lands." Value is `none`: "This wave holds no exclusive resource. Run the scoped test, lint and typecheck commands for your own files; no suite is being held back for a serial run." Never paste the first string over an empty value, which produces the nonsense "This wave holds none. Run scoped unit tests ONLY; do NOT run ." Never left empty either: an absent value means the dispatcher did not decide, so the agent refuses and says so. Full clause below. |
| TDD | "If test mode is test-first, watch the test fail before writing impl. Refuse to ship without a watched RED." |
| Self-review | "Self-review against the checklist before reporting done. Report pass/fail per item + any Approach deviations." |
| Word cap | ≤200 words per task in the wave report. |

Template: `references/parallel-agents/phase-3-implementation.md`. **A one-task wave is the same dispatch** with one task in it; discipline (self-contained prompt, declared files, scoped commands) still applies.

### The wave is the unit of dispatch

A wave's tasks are already file-disjoint, so nothing stops them running together. What decides whether they should is the read
surface. **A shared read surface means the tasks read the same types, the same neighbouring code and the same conventions**, and an
agent per task pays for those reads once per task. Worse, every implementer re-reads the rule files and re-quotes the same six rule
sentences, a fixed cost that has nothing to do with how big the task is.

So the WAVE is the unit, scoped to the case that earns it:

1. **One agent per wave, when the wave's tasks share a read surface.** There is no cap on
   the width of a single wave: nine tasks that share a read surface go to one agent, the
   same as two. What is not fixed is the wave's SHAPE. A wave whose tasks do NOT share a
   read surface may be split into concurrent waves, one agent each, when the partition
   test passes. There is still no width valve and no split by module hunch, because
   the partition test is the only thing that may split a wave.
2. **The pre-flight plan IS the dispatch plan.** It is written once, from the Phase
   2.5 spec reviewer's wave plan ([references/parallel-agents/phase-2.5-spec-reviewer.md](../parallel-agents/phase-2.5-spec-reviewer.md),
   agent type `hackify:spec-reviewer`). The parent MAY merge consecutive waves into one
   dispatch when no file collides inside the merged set and no dependency edge crosses the
   merge. Merging is a throughput decision and needs no re-review: **"read the plan rather
   than rebuild it" bans RE-PLANNING, not merging.** It is worth doing because every wave
   pays a near-constant setup cost, its agent re-reading the project rules and quoting the
   same rule sentences before it writes a line, so a run of narrow waves pays that toll
   over and over.
3. **A one-task wave is normal**, and dispatches the same single agent.
4. **Each agent runs its wave's tasks in order and stops at the first one it cannot
   finish.** Completed tasks stay on disk and its report names which landed and which
   did not, so a failure late in the wave costs the tasks after it, never the ones
   before it. **This clause is PER AGENT, and concurrency does not touch it.** Every agent
   in a round stops on its own account, keeps its own landed work on disk, and files its
   own report; one wave stopping never stops another wave in the same round and never
   costs that wave what it already wrote.

**The partition test is stated in [../contention-dispatch.md](../contention-dispatch.md) and is deliberately not restated here.** Read
it there before you split anything: all three conditions, the coarse-to-fine rule that decides WHICH passing partition to take, and
why the trivial one-subset partition passing means a passing test can never on its own mean "split". A compressed copy in this file
would be one more restatement that can quietly drop a condition, which is the failure the canonical-file ruling exists to stop.

One thing the test leans on belongs to this phase rather than to that file: serial and exclusive are not the same set, and "Serial
resource against exclusive resource" below states the relation and what the parent does with it.

**Rounds are ASSEMBLED, and assembly is where collisions enter.** The partition test is scoped to ONE wave, to "the union of
every task's file allowlist in the wave", and that scope is deliberate: inside a wave the tasks are file-disjoint by construction,
which is why condition 1 is inherited rather than checked. A ROUND is a different object, a COLLECTION of waves the parent builds at
step 3, and neither the test nor the wave plan ever asked whether two waves in it are disjoint from each OTHER. The one check that
exists, at step 5, fires only when the parent MERGES consecutive waves, so a round assembled out of waves the reviewer already
separated skips it; condition 3 catches it only if the file was named serial.

**Step 4 is its own step, NOT the partition test run wider.** Do not re-scope the test: its one-wave scope is what makes condition 1
free, and a round-scoped test would have to check condition 1 for real against every pair. Intersect the wave allowlists pairwise
instead. **This sprint's own work-doc caught exactly this**, task T4 landing in two waves of one round, by running a check this file
never asked for. That is luck, not a control.

**Where the foundation wave's task list comes from.** The Phase 2.5 spec reviewer reports a `## Serial resources` section naming
every shared file, generated sequence and external exclusive resource the backlog touches, with an exclusivity verdict on each. The
parent pulls the tasks holding those into the solo foundation wave of "The three stages" above. A serial resource settled there
stops blocking condition 3 for every round after it, which is what turns a long line of forced-serial waves into a couple of rounds.

**Serial resource against exclusive resource, the mapping the parent performs at every dispatch.** They are different sets and the
containment runs one way: **every exclusive resource is a serial resource, and the reverse does not hold.** A serial resource is
anything that forces two waves into different rounds, and it binds ONCE, at dispatch, through condition 3 above. An exclusive
resource is the narrower kind that two RUNNING processes cannot hold at once without corrupting it, and it binds a SECOND time, at
run time, through the clause below. A shared file is the standard serial-but-not-exclusive case: condition 3 has already put it in
exactly one wave, so no second process ever reaches it and there is no suite to hold back. A shared test database is both, and so is
a generated sequence: each takes a lane of its own AND the wave holding it runs scoped unit tests only. So `{{exclusive_resources}}`
carries the EXCLUSIVE subset of what that wave holds, never the whole serial list, and a wave whose only serial resource is a shared
file is passed the literal `none` rather than that file's name.

**The exclusive-resource clause.** An exclusive resource is one two processes cannot hold at once without corrupting it, the
standard case being a shared test database whose harness truncates tables. Four parts, all of them the parent's job:

1. Each wave brief NAMES any exclusive resource that wave holds.
2. Concurrent waves run scoped unit tests ONLY.
3. The suite that needs the exclusive resource runs ONCE, serially, at the parent, after
   the concurrent waves have landed.
4. The parent RECORDS this in the wave log, the Daily Updates entry Wave-end persistence
   writes, rather than leaving it implicit: which exclusive resource was held back, which
   suite did not run while the concurrent waves ran, and that those waves' evidence is
   scoped-unit-only until the serial run lands.

**Inside a wave this trades wall-clock for tokens and coherence, and the trade is made with the cost stated.** One agent running a
wave in sequence finishes later than several agents running the same tasks at once. What it buys is one context that read the module
once and quoted the rules once, and one agent that cannot contradict itself halfway through the wave. That purchase is worth making
when the tasks share a read surface and buys nothing when they do not, which is the whole job of the partition test. Rule 4 is the
mitigation for the blast radius that comes with putting a whole wave in one agent.

Filling the work-doc's `### Module briefs` block before a concurrent round, and
merging each track's own progress file after it, are both stated once in
[../contention-dispatch.md](../contention-dispatch.md).

### The round's allowlist reconciliation

The parent's containment verdict, run once per ROUND at step 3 of the loop above, after every wave has returned and before anything
ticks. This is the canonical statement; the wave contract and the walkthrough point back here rather than restating it.

**The agent declares, the parent reconciles.** Each wave reports every path it CREATED or MODIFIED under `## Paths written`, a list
it knows because it wrote it. That declaration is the input, and what it replaced is worth writing down so nobody restores it as an
improvement: waves in a round run at the same time, so a whole-tree diff shows a neighbour's legitimate edits as this wave's breach,
and no pathspec repairs that. `git diff --name-only HEAD -- <that wave's allowlist>` returns only paths that were already inside the
allowlist, so asserting containment against it is true by construction and can never fail; scoping to a directory entry instead
makes it fire on a wave that did nothing wrong. Both directions are broken because the input was wrong. **git cannot attribute an
uncommitted edit to a wave. The agent can, so the agent says, and the parent checks the saying against the tree.**

**The declaration's format, and the one thing the parent must not do to it.** The wave report's `## Paths written` is a FENCED BLOCK
of bare absolute paths, one per line, no bullet and no backticks, and the parent copies those lines into `decl.<w>` UNCHANGED: no
re-typing, no re-deriving from the per-task `## Files touched` sections, no stripping of decoration, so there is no line the parent
could clean up wrongly. Check 1 compares with `grep -qxF`, a whole-line literal match, so a bullet or a pair of backticks FAILs
every path in the report.

**Deletions get their OWN fence, because this one structurally cannot carry them.** `## Paths written` is what a wave CREATED or
MODIFIED, so the contract carries a second fence, `## Paths deleted`, mandatory and empty-not-absent and bound by the same allowlist.
That is the producer widening the old rule said was missing: a declaration ATTRIBUTES a deletion, which allowlist membership never
could, so check 3 reconciles a DECLARED deletion and FAILs only the undeclared one, which the parent explains in the wave log.

Three checks. Checks 1 and 3 measure on every round and each of them must, which is what the vacuity guard at the foot of the block
enforces per check. Check 2 needs a second wave before it can fire at all, so on a single-wave round it is structurally clean rather
than merely passing:

1. **Every path a wave declares is inside THAT wave's own allowlist.** Catches a wave that
   reached outside its own paths.
2. **No path is claimed by two waves.** Catches two waves both writing a file the partition
   test promised apart.
3. **No path in the round's diff is unclaimed.** Catches the stray edit no agent admits to,
   which is the one the first two cannot see.

```bash
# $RECON, the scratch dir step 2 creates OUTSIDE the repo: bookkeeping written inside the tree lands in the round's
# own diff and check 3 flags it. Per wave `w` in ROUND_WAVES: decl.<w> and deld.<w>, its `## Paths written` and
# `## Paths deleted` copied unchanged, and allow.<w>, its union allowlist. All three hold bare absolute paths one
# per line, and an EMPTY deld.<w> is the ordinary case rather than a missing file.
root=$(git rev-parse --show-toplevel)
fails=0
checks1=0   # check 1's comparisons, one per DECLARED path
checks3=0   # check 3's comparisons, one per path in the ROUND DIFF

# --- Bookkeeping first: every wave has ALL THREE files, or it FAILs. ---------
# The hole this closes laundered a real breach: check 1 reads decl.<w>, so a wave whose decl was missing or misnamed
# was SKIPPED by it while its paths still reached `claimed` through a decl.* glob. ENUMERATE the ARRAY the parent
# assigns, `ROUND_WAVES=(W10a W10b)`, never glob: a plain string does not word-split in zsh. EVERY expansion of it
# below is written `${ROUND_WAVES[@]+"${ROUND_WAVES[@]}"}` and the emptiness test leads with `${ROUND_WAVES[*]+x}`.
# That is NOT noise to tidy back to the plain form: under bash 3.2, still the system bash on macOS, `set -u` makes
# `"${arr[@]}"` on an empty array and `${#arr[@]}` on an unset one FATAL, so the naked form aborts the whole run in
# exactly the case this guard exists to report, and the parent gets a crash instead of the FAIL below.
[ -n "${ROUND_WAVES[*]+x}" ] && [ "${#ROUND_WAVES[@]}" -gt 0 ] ||
  { echo "FAIL 0: ROUND_WAVES is empty, so this round reconciles nothing"; fails=$((fails + 1)); }
[ -e "$RECON/round_start" ] ||
  { echo "FAIL 0: no round_start marker, so the mirror sweep cannot date this round's edits"; fails=$((fails + 1)); }
: > "$RECON/claimed_raw"
for w in ${ROUND_WAVES[@]+"${ROUND_WAVES[@]}"}; do
  [ -r "$RECON/decl.$w" ] ||
    { echo "FAIL 0: no readable decl.$w, so wave $w is unreconciled"; fails=$((fails + 1)); continue; }
  # DELETIONS ARE DECLARED TOO, and the fence is empty-not-absent: unreadable is a bookkeeping failure, not an empty wave.
  [ -r "$RECON/deld.$w" ] ||
    { echo "FAIL 0: no readable deld.$w, so wave $w's deletions are unreconciled"; fails=$((fails + 1)); continue; }
  [ -r "$RECON/allow.$w" ] ||
    { echo "FAIL 0: no readable allow.$w, so wave $w is unreconciled"; fails=$((fails + 1)); continue; }
  # Deduped PER WAVE, which is what keeps check 2 about two WAVES and not one slip. Written and deleted paths join
  # ONE stream because every rule below is identical for both: the allowlist bound, the one-wave rule, the claim.
  cat "$RECON/decl.$w" "$RECON/deld.$w" | grep -v '^[[:space:]]*$' | sort -u > "$RECON/norm.$w"
  cat "$RECON/norm.$w" >> "$RECON/claimed_raw"
done
sort -u "$RECON/claimed_raw" > "$RECON/claimed"
sort    "$RECON/claimed_raw" | uniq -d > "$RECON/doubled"

# --- The round's diff. `git -C "$root"` on BOTH halves: `git ls-files --others`
# is cwd-SCOPED and cwd-RELATIVE while `git diff` is root-relative, so without it a subdirectory cwd hides a stray
# file at the repo root AND mangles one created below into a path that does not exist. Untracked files are swept in
# because a plain diff never lists one CREATED and not staged. $WORK_DOC and the track files derived from it are the
# only carve-outs, ASSIGNED below rather than assumed. The prefix is a read/printf loop and NOT `sed "s|^|$root/|"`, which interprets $root as
# part of its own script: a `|` in the path ENDS the s command outright, a `\` opens an escape and an `&` back-
# references the match. Every one of those silently mangles the path, and every downstream `grep -qxF` then compares
# something that was never on disk. printf interprets nothing.
{ git -C "$root" diff --name-only HEAD
  git -C "$root" ls-files --others --exclude-standard
} | while IFS= read -r p; do printf '%s/%s\n' "$root" "$p"; done > "$RECON/diff_raw"

# The generated mirror git cannot see: a tree ignored wholesale, dist/ here. SET MIRROR_ROOT to whatever yours is,
# or to "" when the repo has none, and the sweep SAYS which it did. A wave that edits the copy instead of the source
# lands a surviving undeclared change, and the old form hardcoded dist/, sent every error to /dev/null and touched
# no counter, so on a repo whose ignored tree is not dist/ it ran inert and invisible. It feeds check 3's INPUT
# rather than judging anything, so it contributes no comparison BY DESIGN and the note is the whole visibility; do
# not "fix" that by counting an empty sweep. NOT `git ls-files --others --ignored`, which lists the mirror's whole
# contents every run rather than what THIS round touched, and without --exclude-standard drags in __pycache__. No
# allowlist names a mirror, so a hit FAILs 3.
MIRROR_ROOT="$root/dist"     # ← POINT THIS at your own wholesale-ignored tree, "" if there is none
if [ -z "$MIRROR_ROOT" ]; then
  echo "note 0: MIRROR_ROOT is empty, so no mirror sweep ran and no ignored tree is covered"
elif [ ! -d "$MIRROR_ROOT" ]; then
  echo "FAIL 0: MIRROR_ROOT '$MIRROR_ROOT' is not a directory, so the mirror sweep never ran"
  fails=$((fails + 1))
else
  swept=$(find "$MIRROR_ROOT" -type f -newer "$RECON/round_start" ! -name '.DS_Store' | tee -a "$RECON/diff_raw" | wc -l)
  echo "note 0: mirror sweep over $MIRROR_ROOT, $((swept)) file(s) newer than round_start"
fi

# THE FIRST CARVE-OUT, ASSIGNED here rather than assumed. REQUIRED FORM: the live work-doc's ABSOLUTE path under
# $root, since diff_raw carries absolute paths and a repo-relative value matches none of them. Unset FAILs here
# because it fails SILENTLY everywhere else: `grep -vxF -- ""` does NOT empty the stream, -x makes the empty pattern
# match only EMPTY lines and -v keeps every real path, so round_diff survives whole, the carve-out just stops
# existing, and the parent's own work-doc edit reaches check 3 unclaimed and reds a clean round.
wd_why=''                             # its OWN line on purpose: an initializer riding along with the line below
WORK_DOC="$root/docs/work/<slug>.md"  # ← fill in <slug>. Anything sharing this line is deleted when you edit it,
case "${WORK_DOC:-}" in               # and a lost initializer aborts under `set -u` instead of FAILing below.
  "$root"/*) [ -e "$WORK_DOC" ] || wd_why="names $WORK_DOC, which is not on disk" ;;
  *) wd_why="is unset or is not an absolute path under $root" ;;
esac
[ -z "${wd_why:-}" ] ||
  { echo "FAIL 0: WORK_DOC ${wd_why:-is not set}, so the first carve-out matches nothing"; fails=$((fails + 1)); }

# THE SECOND CARVE-OUT is a concurrent round's track files, its directory DERIVED from WORK_DOC so there is no second <slug> to get wrong; the rule and its reason are under "Check 3 is the one that carries the round" below. It is UNGUARDED, unlike WORK_DOC, because a solo round writes no track file and that directory legitimately does not exist. index() plus a `/`-free remainder rather than a glob, since `*` matches `/` in both a shell `case` and a regex and would exempt the nested paths this never covers, measured on the first draft of this line.
sort -u "$RECON/diff_raw" | grep -vxF -- "$WORK_DOC" | awk -v d="${WORK_DOC%.md}.tracks/" 'index($0,d)==1 { r=substr($0,length(d)+1); if (index(r,"/")==0 && r ~ /\.md$/) next } { print }' > "$RECON/round_diff"

# The marker must PREDATE this round's edits, and the existence check above cannot tell. A parent who forgot it and
# touched it afterwards passes that check while the mirror sweep just above dates from a clock later than every edit
# and returns nothing at all, silently. Any round-diff path OLDER than the marker is that case, or an untracked
# leftover from an earlier round, so the red NAMES one rather than counting: the two read differently by eye.
stale=$(while IFS= read -r p; do [ -e "$p" ] && [ "$RECON/round_start" -nt "$p" ] && printf '%s\n' "$p"; done < "$RECON/round_diff" | head -1)
[ -z "$stale" ] ||
  { echo "FAIL 0: round_start is NEWER than $stale, so it was touched after this round's edits (or that path predates the round) and the mirror sweep measured nothing"; fails=$((fails + 1)); }

# 1. Every path a wave DECLARES is inside THAT wave's own allowlist. One-way: a wave that stopped early declares a
#    strict SUBSET on purpose. Never reverse it.
for w in ${ROUND_WAVES[@]+"${ROUND_WAVES[@]}"}; do
  [ -r "$RECON/norm.$w" ] || continue
  while IFS= read -r p; do
    checks1=$((checks1 + 1))
    grep -qxF -- "$p" "$RECON/allow.$w" ||
      { echo "FAIL 1: wave $w declared $p, outside its own allowlist"; fails=$((fails + 1)); }
  done < "$RECON/norm.$w"
done

# 2. No path is claimed by two WAVES, which the partition test promised apart.
while IFS= read -r p; do
  [ -n "$p" ] || continue
  echo "FAIL 2: $p claimed by more than one wave"; fails=$((fails + 1))
done < "$RECON/doubled"

# 3. No path in the round's diff is unclaimed. A DECLARED deletion reconciles like a written path, under the same
#    allowlist bound, because `## Paths deleted` carries AUTHORSHIP the way `## Paths written` does. An UNdeclared
#    vanished path FAILs and cannot be attributed: allowlist MEMBERSHIP is not authorship, and waves are file-
#    disjoint, so a membership count is only ever 0 or 1. The red names the allowlists HOLDING the path as the lead.
while IFS= read -r p; do
  [ -n "$p" ] || continue
  checks3=$((checks3 + 1))
  grep -qxF -- "$p" "$RECON/claimed" && continue
  holders=''
  for w in ${ROUND_WAVES[@]+"${ROUND_WAVES[@]}"}; do
    [ -r "$RECON/allow.$w" ] && grep -qxF -- "$p" "$RECON/allow.$w" && holders="$holders $w"
  done
  if [ -e "$p" ]; then
    echo "FAIL 3: $p is in the round diff and no wave declared it (allowlists holding it:${holders:- none})"
  else
    echo "FAIL 3: $p is DELETED and no wave declared it under '## Paths deleted', so record it in the wave log (allowlists holding it:${holders:- none})"
  fi
  fails=$((fails + 1))
done < "$RECON/round_diff"

# The verdict PRINTS the comparisons actually performed, PER CHECK, and each count is guarded on its own: one
# check's count cannot stand in for another's, and a round where check 1 counted while check 3 measured NOTHING is
# exactly the vacuous verdict scripts/validate-dod.d/27-marketplace-ref-pin.sh reddens for, hidden behind a total.
# CHECK 2 IS DELIBERATELY UNGUARDED. It reports over `doubled`, which is empty on every healthy round and
# STRUCTURALLY empty on a single-wave round, so a non-zero bound there would red the ordinary case. That is why the
# prose above promises three checks that can FAIL rather than three that measure, and why a fix here means fixing
# both halves.
if [ "$checks1" -eq 0 ]; then
  echo "FAIL 0: check 1 made 0 comparisons, so no wave's declaration was judged against its own allowlist"
  fails=$((fails + 1))
fi
if [ "$checks3" -eq 0 ]; then
  echo "FAIL 0: check 3 made 0 comparisons, so the round diff was empty and this round landed nothing"
  fails=$((fails + 1))
fi
[ "$fails" -eq 0 ] &&
  echo "reconciled: $checks1 check-1 + $checks3 check-3 comparisons, 0 failures" ||
  { echo "NOT reconciled: $checks1 check-1 + $checks3 check-3 comparisons, $fails failure(s)"; exit 1; }
```

**Check 3 is the one that carries the round**, and it is the one a loose carve-out defeats. TWO path shapes are exempt and no others: the
work-doc, because `no-parent-authored-diff` leaves the parent that file and nothing else, and `docs/work/<slug>.tracks/*.md` one level deep,
because [../sibling-track-rules.md](../sibling-track-rules.md) sends a side-by-side track's progress there rather than into the shared work-doc,
so a concurrent round writes them by design and no allowlist can name them. Any other unclaimed path is a finding, never an exception, and the
round is not reconciled until it is claimed by a wave or explained in the wave log. A DELETION is one of those findings whenever no wave declared it. A DECLARED deletion differs in the one way that matters: `## Paths deleted` names the wave
that did it, so it is claimed by authorship and bound by that wave's own allowlist in check 1, exactly like a written path. That is
STRICTER than the allowlist-membership attribution this block used to reach for, since the allowlists holding a path say only who
was ALLOWED to touch it, which on a file-disjoint round is one wave whether or not it deleted anything. So an undeclared deletion
FAILs, the red names those allowlists as the lead, and the explanation goes in the wave log.

**Checks 1 and 2 are the ones a paraphrase quietly loses.** Check 1 reads each wave's OWN allowlist, never the round's union: the
union is wide by construction, and judging a wave against it is how a wave gets licence to write a neighbour's file. Check 2 is what
makes "claimed by exactly one wave" true, since check 3 on its own only asks for at least one.

### The scouts run twice, at different owners and different scopes

Both deterministic scouts, the perf-scout ([../perf-scout.md](../perf-scout.md)) and the law-scout
([../law-scout.md](../law-scout.md)), run at TWO points inside Phase 3. The two points differ in WHO runs them and over WHAT, and
neither one covers the other. This is the canonical statement of both, and every site below restates the pair. All of them agree
with what is written here, none of them is the place to change it, and the list is FILES ONLY on purpose: a `file:line` entry in a
sweep list goes stale the first time anything above it wraps, and a list that has already been wrong in both directions cannot
afford a second way to rot. **Edit here first, then sweep every file named here.**

The split is whether the restatement carries a pointer back here FOR THE RUN POINTS, which is what keeps a copy honest. Five do:
`skills/hackify/references/perf-scout.md`, `skills/hackify/references/law-scout.md`, `skills/hackify/SKILL.md`,
`skills/hackify/references/implement-and-test.md`, `skills/hackify/references/parallel-agents/phase-3-implementation.md`. The last
two are not scout protocols and were missing from this list entirely. Seven restate the pair with no run-point pointer, so they are
the ones a sweep has to reach by name: `README.md`, `rules/perf-guardrails.md`, `rules/expert-mindset.md`,
`skills/hackify/references/expert-mindset.md`, `skills/hackify/references/runtime-adapters.md`,
`skills/hackify/references/phase-ledger.md`, `skills/hackify/references/work-doc-template.md`. `README.md` DOES cite this file, but
for the wave shape rather than for the run points, which is a pointer a reader chasing the scouts never follows, so it sits on this
side of the split.

**Run point 1, the AGENT, over its OWN file allowlist, before it returns.** The wave agent runs both scouts across the files it
landed, once, after its last landed task and before it writes its report. **This is where fix-in-wave lives**, and it is the only
place it ever made sense: the agent is still holding those files, they sit inside its own allowlist, and the fix lands in the same
diff. A trivial in-allowlist candidate is fixed in place and marked `fixed`; everything else the agent stages and reports. **Both
scouts' rows go in the wave report under `## Scout dispositions`**, one wave-level section holding every candidate from both, which
is the section the two scout protocols write their staging table into and the one the parent reads at run point 2. The obligation is
written into the wave contract as a METHOD step
([../parallel-agents/phase-3-implementation.md](../parallel-agents/phase-3-implementation.md)), so it travels with the agent type
instead of needing a per-wave input.

**Run point 2, the PARENT, over what the round's waves DECLARED, at round end.** The parent runs both scouts again once every wave
has returned and before any task ticks, over `$RECON/claimed` rather than the union of the allowlists: a wave that stopped early
declares a strict subset on purpose, and the rest is files the round never touched. It is keyed to the ROUND because that is when
tasks tick and when the parent runs its repo-wide checks, so a parent scan keyed to wave-end would run before the thing it gates.

It answers three questions, and only the third needs a second wave in the round. First, **whether the agent ran its own scan at
all**: the wave report is a claim, and this is the scan that checks it. Second, **whether a fix-in-wave regressed the file after the
agent's own scan had already passed**: a fix-in-wave edit lands AFTER the scan that surfaced the candidate, and nothing at run point
1 re-reads the file once it has been edited, so the agent's green grades the pre-fix state and this is the first read of the
post-fix one. Third, **whether a defect crosses two waves**, which is visible in no other scope, because no agent can scan a file it
never held.

**On a single-wave round the third reason is void and the mandate is unchanged**, because the first two survive the collapse. The
two SCOPES do coincide there, and saying so is better than pretending otherwise: run point 1 covers the files that agent landed, run
point 2 covers what the round's waves declared, and on a single-wave round those are the same set by construction. They are still
not the same SCAN: run point 2 reads the post-fix-in-wave state of files whose green at run point 1 graded the pre-fix state, and it
is the read that checks whether run point 1 happened at all.

What it finds is staged for Phase 5, or sent back out as a one-task wave scoped to the owning file's allowlist when the fix is
trivial and worth closing now. **The parent never writes the fix itself.** Every code change is written by a dispatched agent under
a file allowlist, per the no-parent-authored-diff law in `SKILL.md`, and a scout finding is not a carve-out from it.

**The two run points join, they do not compete.** The parent reads each wave's dispositions out of that wave's report and carries
them into the round's staging table beside its own findings, so an agent-staged row reaches Phase 5 exactly the way a parent-staged
one does. A candidate an agent already dispositioned carries that disposition forward and is NOT re-dispositioned at round end; the
parent's new rows are the cross-wave ones its wider scope just made visible. **Every candidate still gets exactly one of `staged` /
`fixed` / `false-positive: <one-line reason>`, at BOTH run points.** A candidate that vanishes without a row is a protocol
violation, not a judgment call, and that rule is unchanged by there now being two places it binds.

Phase 5's own scan, at review start over the whole sprint diff, is a third run point and neither of these two touches it.

**Test mode per task:**

| Mode | When | Discipline |
|---|---|---|
| **Test-first (mandatory)** | Business logic, services, validators, auth/permission, bug fixes, branching behavior | RED → GREEN → REFACTOR. Watch the test fail. *"If you didn't watch it fail, you don't know it tests the right thing."* |
| **Test-after (acceptable)** | Integration/E2E with heavy setup, framework wiring, glue code | Test required; order is flexible. |
| **Manual smoke (user opt-in)** | UI cosmetics, copy edits, color/spacing, doc edits, config-only | Log steps in Daily Updates. Offer an automated test; never *replace* automated tests when behavior is testable. |
| **No tests** | Purely additive scaffolding ("create empty file") or pure documentation | Note `no test (rationale: …)` in the log. |

**If stuck** (tests still red after 2 honest fix attempts, or behavior surprising), **switch to Phase 3b: Debug**. No third blind fix.

**No scope creep.** No cleanup, no refactoring adjacent code, no abstractions for hypothetical futures. The plan is the contract. See `references/implement-and-test.md`.

### Wave-end persistence (mandatory)

**Wave-end persistence (mandatory).** Before dispatching round N+1, the parent MUST update the work-doc: read the landed and not-landed task IDs out of the `## Wave status` section EVERY returned report opens with, tick the completed checkboxes in the Sprint Backlog and ONLY those, leave every not-landed ID unticked for the next dispatch or for Phase 3b, append a Daily Updates entry summarizing what each wave agent produced, run `bash scripts/validate-dod.sh` (or the project's verification triad), and advance frontmatter `current_task` to the upcoming round's task IDs. When the round held an exclusive resource back, the same entry carries what part 4 of the exclusive-resource clause requires. Skipping this step is an abandoned-state bug, interrupting between rounds loses no progress; interrupting mid-round-update loses the round.

**Ledger, at phase exit.** Every Sprint Backlog checkbox ticked, every round committed, both scouts dispositioned at both run points, then one line of reflection (what changed, did it pass, what is next), then tick `Phase 3. Implement` and open `Phase 4. Verify (Evidence Ledger + triad green)` in the work-doc's section 0, saved before the re-print, on the same rule Wave-end persistence states above. A task that turned out not to apply is ticked with a one-line reason, never deleted. Phase 3b is inserted as its own ledger item when a wave gets stuck, it is never a silent detour.

# Phase 3, Implement (parallel waves, mandatory)

Loaded by `SKILL.md` when this phase opens. The phase's entry conditions, hard gates and exit artifact are stated in `SKILL.md`; this file is the protocol.

**Goal.** Ship the Sprint Backlog as fast as wall-clock allows by dispatching each wave to foreground parallel subagents in one message.

**Ledger, at phase open.** Set `Phase 3. Implement (all waves committed)` to in-progress and re-print the whole ledger block. Never open it while `Phase 2.5. Spec review` is still open. Waves fan out INSIDE this phase; they never advance the ledger past it. Contract: [../phase-ledger.md](../phase-ledger.md).

**Pre-flight, build the wave plan.**

```
1. List every task. For each: files CREATED/MODIFIED; earlier tasks required.
2. Sort by priority (DoD load-bearing first) and topological dependency.
3. Group into WAVES. NO file overlap, NO inter-task dep within a wave; wave N may depend on 1..N-1.
4. Write wave plan into work-doc Approach as "Execution waves", each wave listing its dispatch batches (`W1: [T1, T3] auth; [T2] solo`). Show user before wave 1.
```

**Per-wave loop:**

```
1. Set frontmatter: status: implementing, current_task: W<n>:T<a>+T<b>+…
2. Dispatch ONE subagent per task BATCH in a SINGLE assistant message. Each agent
   prompt self-contained: work-doc path, the batch's task IDs in order, each task's
   exact files, the union allowlist, test mode, rules summary, "do NOT touch any
   other files".
3. Wait for all agents. Aggregate reports. Verify each touched only its declared files.
4. Run full project verification (test + lint + typecheck) ONCE for the wave.
5. On red: classify, agent failure (re-dispatch sharper prompt) vs. plan failure
   (drop to Phase 3b). Never paper over.
6. Run BOTH deterministic scouts over the wave-touched files (union of the wave's
   allowlists), BEFORE ticking tasks: the perf-scout (references/perf-scout.md) and
   the law-scout (references/law-scout.md, the bundled lawkeeper scanner scoped with
   --paths-from). Trivial in-allowlist candidates are fixed in-wave; everything else
   is staged for Phase 5 in each scout's staging table, appended to the wave's Daily
   Updates entry. Every candidate carries exactly one disposition.
7. Tick wave checkboxes; append one Daily Updates entry per task.
8. Commit ONCE for the wave (conventional subject; body lists task IDs).
9. Advance to wave N+1.
```

**Per-task safety constraints (in each agent's prompt):**

| Constraint | Wording |
|---|---|
| File allowlist | "Modify only these files: `<list>`. If another file is needed, STOP and report, do not edit." |
| Repo brief | The `### Repo Brief` block from the work-doc, verbatim, as `{{repo_brief}}`. "Treat it as given, do NOT re-derive it, spend your reads on your own files." Unfilled means the agent refuses. |
| Command allowlist | "Run only these commands: `<list scoped to your files>`. The parent runs repo-wide checks." |
| TDD | "If test mode is test-first, watch the test fail before writing impl. Refuse to ship without a watched RED." |
| Self-review | "Self-review against the checklist before reporting done. Report pass/fail per item + any Approach deviations." |
| Word cap | ≤200 words per agent report. |

Template: `references/parallel-agents/phase-3-implementation.md`. **Single-task waves are fine**, dispatch a single agent; discipline (self-contained prompt, declared files, scoped commands) still applies.

### Batch the wave before you dispatch

A wave's tasks are already file-disjoint, so they can all run at once. They are not
context-disjoint: same-module tasks read the same types, the same neighbours and the
same conventions, and an agent per task pays for those reads once per task. Worse,
every implementer re-reads the rule files and re-quotes the same six rule sentences,
a fixed cost that has nothing to do with how big the task is.

The wave planner emits the batches, at the TOP of the Phase 2.5 spec reviewer's report ([references/parallel-agents/phase-2.5-spec-reviewer.md](../parallel-agents/phase-2.5-spec-reviewer.md), agent type `hackify:spec-reviewer`). Read them out of that report rather than rebuilding them here. Dispatch one agent per batch:

1. **Group only within a wave.** Batching across waves would break the dependency
   order the plan exists to enforce.
2. **Group by module, never by count.** Tasks that share a directory, a module or a
   file neighbourhood go together. Tasks in unrelated areas stay separate: batching
   them costs an agent its focus and saves no reads, because there were no shared
   reads to save.
3. **Cap a batch at 3 tasks.** Past that the agent is holding more context than it
   can apply carefully, and a failure late in the batch wastes everything before it.
4. **A batch of one is normal**, and is what a task with no module sibling gets.
5. **The batch runs its tasks in order and stops at the first one it cannot finish**,
   so a bad task costs one task, not the batch.

**This trades wall-clock for tokens, and the trade is bounded on purpose.** Nine
agents instead of fourteen means Phase 3 takes about twice as long and costs about a
third less. The 3-task cap is what keeps that from becoming ten times as long.

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

**Wave-end persistence (mandatory).** Before dispatching wave N+1, the parent MUST update the work-doc: tick the completed checkboxes in the Sprint Backlog, append a Daily Updates entry summarizing what each agent produced, run `bash scripts/validate-dod.sh` (or the project's verification triad), and advance frontmatter `current_task` to the upcoming wave's task IDs. Skipping this step is an abandoned-state bug, interrupting between waves loses no progress; interrupting mid-wave-update loses the wave.

**Ledger, at phase exit.** Every Sprint Backlog checkbox ticked, every wave committed, both scouts dispositioned, then one line of reflection (what changed, did it pass, what is next), then tick `Phase 3. Implement` and open `Phase 4. Verify (Evidence Ledger + triad green)`. A task that turned out not to apply is ticked with a one-line reason, never deleted. Phase 3b is inserted as its own ledger item when a wave gets stuck, it is never a silent detour.

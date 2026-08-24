# Orchestration tier, iteration driver + completion sentinel (ultracode, /loop and /goal, on by default)

Three abstract primitives that decide **how hard hackify fans out**, **how it keeps going until the work is done**, and **what counts as done in the first place**. All three are workflow defaults in every mode; none of them asks the user to turn it on. On Claude Code they map to the native `ultracode` keyword, the `/loop` command and the `/goal` session-goal condition; on every other runtime they map to the inline equivalent, so the behavior is the default everywhere and the *tokens* stay where they are understood (`runtime-adapters.md`).

## Why they are separate primitives

They answer different questions and belong at different layers. Conflating them is the mistake that makes both misfire.

| Primitive | Question it answers | Layer it lives at |
|---|---|---|
| **orchestration tier** | How much parallel machinery does this fan-out get? | *inside* a phase, at each fan-out point |
| **iteration driver** | What re-enters the workflow until the task is actually finished? | *above* the phases, at the task level |
| **completion sentinel** | What condition, checked by something other than me, says the task is finished? | *around* the whole task, one per session |

The driver and the sentinel are the pair that gets conflated most often, and they are opposites: the driver is the **engine** that re-enters, the sentinel is the **brake** that says stop. A driver with no sentinel keeps going on the parent's own say-so, which is the judge marking its own homework; a sentinel with no driver states a finish line nothing walks toward. Precedence when they disagree is settled below.

## Orchestration tier (ultracode)

**Default: maximum tier at every mandatory fan-out point.** Hackify's fan-outs are already decided by the workflow, Phase 2.5's single spec reviewer, each Phase 3 wave, Phase 5's evidence-gated reviewer panel plus the refuters. The orchestration tier says those fan-outs run through the heaviest orchestration the runtime offers rather than the cheapest.

| Run point | What fans out |
|---|---|
| Phase 2.5 | 1 spec reviewer, three lenses over one read |
| Phase 3, each wave | one implementer for the whole wave |
| Phase 5 | the evidence-gated reviewer panel, then the refuters |

**Claude Code mapping (an action, not a mood).** `ultracode` is a keyword the *user* types, or a session setting; a skill cannot put it in scope by describing itself as running at a high tier. What the keyword actually does is opt the turn into the **Workflow tool**, so that is what hackify invokes directly:

| Fan-out shape | What to do |
|---|---|
| Flat batch, every unit independent and same-shaped (one agent per Phase 1 research question) | Dispatch subagents in ONE message. This is correct and stays the default. |
| Pipelined, each unit's output feeds a following stage (a reviewer panel whose findings pipeline into per-finding refutation, a loop-until-dry sweep) | **Call the Workflow tool.** Do not simulate a pipeline with sequential flat batches. |

**The Workflow tool's opt-in is satisfied here.** It may only be called when the user explicitly opted into multi-agent orchestration, and one of its accepted forms is *"the user invoked a skill whose instructions tell you to call Workflow."* Invoking hackify is that invocation, and this file is that instruction. Do not ask the user for permission a second time, and do not fall back to a flat batch just because you are unsure whether you are allowed.

**Raising the session tier is the user's move, so say so once.** If you want the keyword path (xhigh effort plus standing workflow orchestration for the whole session), the user types `ultracode` in a prompt or sets `"ultracode": true` in settings. Name it once in the announcement line below; never pretend it is already on.

**Every other runtime.** Maximum tier means the largest parallel dispatch the runtime supports, and on the best-effort tier (no subagent primitive) it means the same phases run inline and sequentially. Coverage never drops; only concurrency does. That is the existing degradation contract in `runtime-adapters.md`, unchanged.

### The authorization, stated plainly

`ultracode` normally means *the user typed a keyword authorizing heavy multi-agent spend*. Hackify makes it a standing default instead, and the authorization is **installing the plugin and invoking the workflow**. That is a real grant, and it should never be a silent one:

- **Announce it once per task**, in the Phase 2 plan message (Phase 1 for quick, the in-chat plan block for yolo): one line naming that this task runs at maximum orchestration tier and how to turn it down.
- **Honor an opt-out phrase at any point.** `light mode`, `no ultracode`, `cheap mode`, `single agent` drop the tier to a flat parallel batch for the rest of the task. The phases do not change; only the machinery does.
- **A dropped tier is recorded**, one line in the work-doc Approach (in chat for quick/yolo), so a later reader knows why a wave ran thin.

Never quietly raise the tier back after the user has lowered it.

## Iteration driver (/loop)

**Default: the workflow re-enters itself until the phase ledger is fully ticked.** The task is not done when a phase ends; it is done when every ledger item is `completed` and Phase 6 has archived. The iteration driver is what carries the task across turns to get there without the user re-prompting.

**Where it belongs, and where it does not.** The driver operates at the **task level**, above the phases. It does NOT drive the Phase 5 address-all loop or the Phase 3b hypothesis cycle, those are inline loops inside a single phase, and scheduling a cross-turn re-entry in the middle of one would break the ledger's one-item-in-progress rule and leave a phase half-run.

| Loop | Layer | Driven by |
|---|---|---|
| Phase 5 address-all (fix → re-scan → settled diff) | inside Phase 5 | inline, never the iteration driver |
| Phase 3b hypothesis cycle (≤3 hypotheses) | inside Phase 3b | inline, never the iteration driver |
| Phase 3 wave loop (wave N → N+1) | inside Phase 3 | inline, never the iteration driver |
| **Task continuation (phase N → N+1 until archived)** | **above the phases** | **the iteration driver** |

**Claude Code mapping (invoke it, do not describe it).** At the end of any turn that leaves a ledger item open, **invoke the `loop` skill** in self-paced mode (no interval), carrying `continue work on <slug>` as its prompt. Writing "the iteration driver carries this task" and then stopping is the failure this section exists to prevent: the driver is a tool call, and a turn that ends with open ledger items and no such call has dropped the task on the floor. Each firing resumes the work-doc per the Pause / Resume contract in `SKILL.md`, advances whatever phase is open, and schedules the next wake-up. Pace the delay to what is actually being waited on: a long fallback heartbeat when a subagent wave will notify on its own, a shorter delay only when polling something external the harness cannot report (a CI run, a deploy).

**Every other runtime.** No scheduler means the driver degrades to what it has always been: the parent runs the phases to completion in-turn, and the user re-prompts with `continue work on <slug>` after an interruption. Same contract, manual carry.

### The three exit conditions (any one ends the loop)

1. **Done.** Every phase-ledger item is `completed` and the work-doc is in `docs/work/done/` with `status: done`.
2. **Blocked on the user.** A hard gate is open (the Phase 2 sign-off, a Phase 5 approval wizard, the Phase 6 four-options menu) or a circuit breaker fired (3 failed debug hypotheses). Stop and surface; never keep looping against a question only the user can answer.
3. **Not converging.** Two consecutive firings that advance no ledger item and tick no Sprint Backlog task. Stop, say what is stuck, and hand back. A loop that cannot make progress must not keep spending.

**The loop never bypasses a gate.** Auto-passing gates is yolo's contract, not the driver's. In full hackify the driver stops at the Phase 2 gate and waits; in yolo the gate auto-passes and the driver continues, because yolo already decided that.

## Completion sentinel (/goal)

**Default: every task offers the user a one-line completion condition, in every mode.** Hackify already knows what finished looks like, the goal anchor's Success Signals, the acceptance rows, the ledger's archive artifact. The sentinel turns that into a condition a **separate evaluator** re-checks after every turn, so "done" stops being the parent's own opinion. This is the one place in the workflow where the finish line is judged by something other than the thing doing the work.

**Claude Code mapping (hand over the line, do not claim you set it).** Unlike the tier and the driver, this primitive has **no reliable tool call**. `ProposeGoal` is absent from most sessions, throws in agent contexts, refuses in plan mode, needs an interactive local session, and `/goal` itself needs a trusted workspace and unrestricted hooks, which hackify's own `UserPromptSubmit` hook makes a live concern rather than a hypothetical. So the contract is:

| Step | What the parent does |
|---|---|
| 1 | **Print the paste-ready line**, a fenced one-liner starting `/goal `, at the announcement point for the mode (table below). This step is mandatory and always possible. |
| 2 | **Call `ProposeGoal` only if the tool is actually in scope** for this session, and only from the parent. If it is not in scope, say nothing about it, the printed line already did the job. |
| 3 | **Never wait on it.** Keep working the current phase. Approval arrives as its own kickoff message, a decline arrives as silence. Do not ask whether they approved and do not re-propose the same condition. |

**Never from a subagent.** Implementers, reviewers, refuters and scouts must not propose a goal; the runtime throws on it, and a wave agent does not know the task's finish line anyway. The sentinel is parent-only, exactly like the phase ledger.

### Writing the condition

**One sentinel, not the whole Definition of Done.** The cap is **500 characters** and the user has to read all of it in an approval dialog, so the condition names the *exit artifact*, not every acceptance bullet. Write it so an evaluator that only sees the conversation can rule on it: name files, exit codes and artifacts, never adjectives. "the auth refactor is complete" is unrulable; "`bun test` exited 0" is.

| Mode | Announce it at | Canonical condition shape |
|---|---|---|
| hackify | the message right after Phase 2 sign-off, as Phase 2.5 opens | `/goal docs/work/done/<date>-<slug>.md exists with status: done, every Sprint Backlog box ticked, and the evidence ledger shows test, lint and typecheck each exiting 0 plus ship.build / ship.boot / ship.smoke rows` |
| quick | the Phase 1 goal-anchor line | `/goal the <slug> change is committed, test + lint + typecheck each exited 0 with the output shown in this session, and the single-lens review round closed with zero remaining findings` |
| yolo | the in-chat plan block | `/goal the <slug> change is committed, test + lint + typecheck each exited 0 with output shown, the ship gate recorded build / boot / smoke rows, and the reviewer loop closed with zero findings on a settled diff` |

Quick mode often finishes inside one turn, and the line is still worth printing: it costs one line, and the moment a "quick" fix turns out not to be quick, the condition is already set.

**Only the user can clear it.** `/goal clear`. Hackify never proposes a replacement goal to work around one it finds inconvenient, and never proposes a second condition for the same task.

### Precedence, when the sentinel and the driver disagree

The evaluator can say "condition not met, keep working" at the same moment the driver's own exit conditions say stop. **The driver's exit conditions 2 and 3 win.** They are the safety valves:

| Situation | Who wins | Why |
|---|---|---|
| Condition met, ledger fully ticked | agreement, stop | the normal path |
| Condition not met, ledger still open | sentinel, keep working | exactly what it is for |
| Condition not met, **a gate is open** | **driver, stop and surface** | a gate is a question only the user can answer; the evaluator cannot answer it and looping at one burns tokens waiting for a human |
| Condition not met, **two firings advanced nothing** | **driver, stop and hand back** | a condition that cannot be reached is a planning problem, not a persistence problem. Say what is stuck |
| Condition met, ledger still open | **ledger, keep working** | a condition that passes early was written too loose. Finish the phases and say the condition under-specified the work |

**Every other runtime.** No session-goal primitive means the sentinel degrades to what hackify already writes down: the Success Signals in the goal anchor and the acceptance rows in Phase 4. Coverage is unchanged, the *independent* re-check is what is lost, so say so once rather than implying an evaluator is watching.

## Anti-rationalizations (STOP and apply the reality)

| Thought | Reality |
|---|---|
| "Max tier means every fan-out needs a workflow script" | No. It raises the ceiling. Three independent Phase 1 research agents are a flat parallel batch and always were. |
| "The user did not type ultracode, so run light" | Installing and invoking hackify IS the standing grant. Announce it, honor the opt-out, do not re-litigate it per task. |
| "The user said light mode, but this wave really needs the fan-out" | Their call, not yours. Run the flat batch and say what it cost. |
| "I'll `/loop` the Phase 5 review until findings hit zero" | Wrong layer. That loop is inline inside Phase 5. The driver carries the TASK across phases, not a phase across turns. |
| "The gate is open, I'll loop and check back" | Exit condition 2. A gate is a question for the user; looping at it burns tokens waiting for a human. |
| "Nothing advanced this firing, one more try" | Two flat firings is the ceiling. Say what is stuck and hand back. |
| "I'll set the session goal for them" | You cannot. Print the `/goal` line and let them press the key. Claiming a goal is active when none is is the worst failure here, it fakes an independent check. |
| "ProposeGoal isn't in my tools, so skip the sentinel" | The printed line is the primary path and never depends on the tool. The tool is the optional upgrade. |
| "The evaluator says not met, so keep going past the gate" | No. Driver exit condition 2 wins. The evaluator cannot answer a question addressed to the user. |
| "The condition passed, ship it" | Only if the ledger agrees. A condition that passes with phases still open was written too loose; finish them and say so. |
| "I'll propose a looser goal so it passes" | Never. One condition per task, and only the user clears it (`/goal clear`). |

## See also

- [runtime-adapters.md](runtime-adapters.md), the per-runtime mapping for all three primitives and the honest degradation cells.
- [goal-anchor.md](goal-anchor.md), the North-Star Goal and Success Signals the completion sentinel is distilled from.
- [phase-ledger.md](phase-ledger.md), the item list the iteration driver drives to completion, and the ordering law it must not break.
- [review-and-verify.md](review-and-verify.md), the Phase 5 address-all loop that stays inline.
- [parallel-agents/template-contract.md](parallel-agents/template-contract.md), the fan-out decision matrix the orchestration tier scales.

# Orchestration tier + iteration driver (ultracode and /loop, on by default)

Two abstract primitives that decide **how hard hackify fans out** and **how it keeps going until the work is done**. Both are workflow defaults in every mode; neither asks the user to turn it on. On Claude Code they map to the native `ultracode` keyword and the `/loop` command; on every other runtime they map to the inline equivalent, so the behavior is the default everywhere and the *tokens* stay where they are understood (`runtime-adapters.md`).

## Why they are separate primitives

They answer different questions and belong at different layers. Conflating them is the mistake that makes both misfire.

| Primitive | Question it answers | Layer it lives at |
|---|---|---|
| **orchestration tier** | How much parallel machinery does this fan-out get? | *inside* a phase, at each fan-out point |
| **iteration driver** | What re-enters the workflow until the task is actually finished? | *above* the phases, at the task level |

## Orchestration tier (ultracode)

**Default: maximum tier at every mandatory fan-out point.** Hackify's fan-outs are already decided by the workflow, Phase 2.5's three spec reviewers, each Phase 3 wave, Phase 5's five-to-six reviewers plus the refuters. The orchestration tier says those fan-outs run through the heaviest orchestration the runtime offers rather than the cheapest.

| Run point | What fans out |
|---|---|
| Phase 2.5 | 3 spec reviewers |
| Phase 3, each wave | one implementer per task |
| Phase 5 | 5-6 reviewers, then the refuter panel |

**Claude Code mapping.** These dispatches run in ultracode mode: the `ultracode` keyword is in scope for the turn, and multi-agent orchestration through the Workflow tool is available for a fan-out that a flat subagent batch would serve poorly (a wave whose tasks pipeline into per-task verification, a reviewer panel whose findings pipeline into per-finding refutation). A flat parallel batch stays correct and stays the default shape for small fan-outs; the tier raises the ceiling, it does not mandate a workflow script for three reviewers.

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

**Claude Code mapping.** `/loop` in self-paced mode (no interval), carrying `continue work on <slug>` as its prompt. Each firing resumes the work-doc per the Pause / Resume contract in `SKILL.md`, advances whatever phase is open, and schedules the next wake-up. Pace the delay to what is actually being waited on: a long fallback heartbeat when a subagent wave will notify on its own, a shorter delay only when polling something external the harness cannot report (a CI run, a deploy).

**Every other runtime.** No scheduler means the driver degrades to what it has always been: the parent runs the phases to completion in-turn, and the user re-prompts with `continue work on <slug>` after an interruption. Same contract, manual carry.

### The three exit conditions (any one ends the loop)

1. **Done.** Every phase-ledger item is `completed` and the work-doc is in `docs/work/done/` with `status: done`.
2. **Blocked on the user.** A hard gate is open (the Phase 2 sign-off, a Phase 5 approval wizard, the Phase 6 four-options menu) or a circuit breaker fired (3 failed debug hypotheses). Stop and surface; never keep looping against a question only the user can answer.
3. **Not converging.** Two consecutive firings that advance no ledger item and tick no Sprint Backlog task. Stop, say what is stuck, and hand back. A loop that cannot make progress must not keep spending.

**The loop never bypasses a gate.** Auto-passing gates is yolo's contract, not the driver's. In full hackify the driver stops at the Phase 2 gate and waits; in yolo the gate auto-passes and the driver continues, because yolo already decided that.

## Anti-rationalizations (STOP and apply the reality)

| Thought | Reality |
|---|---|
| "Max tier means every fan-out needs a workflow script" | No. It raises the ceiling. Three spec reviewers are a flat parallel batch and always were. |
| "The user did not type ultracode, so run light" | Installing and invoking hackify IS the standing grant. Announce it, honor the opt-out, do not re-litigate it per task. |
| "The user said light mode, but this wave really needs the fan-out" | Their call, not yours. Run the flat batch and say what it cost. |
| "I'll `/loop` the Phase 5 review until findings hit zero" | Wrong layer. That loop is inline inside Phase 5. The driver carries the TASK across phases, not a phase across turns. |
| "The gate is open, I'll loop and check back" | Exit condition 2. A gate is a question for the user; looping at it burns tokens waiting for a human. |
| "Nothing advanced this firing, one more try" | Two flat firings is the ceiling. Say what is stuck and hand back. |

## See also

- [runtime-adapters.md](runtime-adapters.md), the per-runtime mapping for both primitives and the honest degradation cells.
- [phase-ledger.md](phase-ledger.md), the item list the iteration driver drives to completion, and the ordering law it must not break.
- [review-and-verify.md](review-and-verify.md), the Phase 5 address-all loop that stays inline.
- [parallel-agents/template-contract.md](parallel-agents/template-contract.md), the fan-out decision matrix the orchestration tier scales.

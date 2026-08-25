# Phase ledger (trackable, ordered, un-skippable)

A visible checklist that forces the phases to run **in order** and makes a forgotten step (like archiving the work-doc) impossible to hide. The ledger is surfaced through the runtime's **todo tracker** (a trackable to-do list the user can see) when the runtime has one, and through a printed chat block when it does not. In full hackify it *lives* in the work-doc's `## 0. Phase ledger` section on either surface, and that copy is the one that survives the session. See **Substrate** below. It is the order-enforcer for the whole task.

Load this file from Phase 1. The ledger is always-on: it is created early and updated at every phase boundary.

## Why this exists

Prose rules like "do not skip Phase 2.5" and "archive before the summary" are soft, a model under load drops them. The ledger turns each rule into a **checkbox with an ordering law**. You cannot reach a later checkbox while an earlier one is open, so skipping a phase or forgetting the archive step becomes visible and blocked, not silent.

## Two layers (do not confuse them)

| Layer | Lives in | Scope | Survives a session? |
|---|---|---|---|
| **Sprint Backlog** | the work-doc | task-level (one line per task) | Yes, the durable state |
| **Phase ledger** | work-doc section 0 in full hackify, surfaced through the todo tracker or a printed chat block | phase/step-level (one line per phase) | Mode-dependent, full hackify yes (it is in the work-doc), quick and yolo no |

They do not overlap. The Sprint Backlog tracks *what code work* is left. The phase ledger tracks *which workflow phase* you are in and forbids running them out of order.

## Substrate (where the ledger actually lives)

**Primary substrate.** The runtime's `todo tracker` primitive, whenever the runtime actually exposes one ([runtime-adapters.md](runtime-adapters.md)).

**Fallback substrate.** Used whenever it does not. The ledger is **printed in chat** as a markdown checklist at task start, and re-printed at **every** phase boundary. In full hackify the durable copy is the work-doc's `## 0. Phase ledger` block, and writing it is the obligation rather than an extra: the chat print is the half that scrolls away, the file edit is the half a resume and an archive read back.

The ledger opens at task start in every mode as a printed block, and in full hackify it is **written into the work-doc as section 0 at Phase 2 step 1**.

| Mode | On disk | What the record is |
|---|---|---|
| **Full hackify** | the work-doc's `## 0. Phase ledger` block | durable, archived with the doc, read back on resume |
| **quick** | nothing, by contract | the printed block in chat |
| **yolo** | nothing, by contract | the printed block in chat |

quick and yolo keep nothing on disk by contract, so they print only and the printed block is the record. Do not invent a scratch ledger file for them.

On the fallback substrate a tick is an edit plus a re-print, not a tool call: `- [ ]` open, `- [>]` the single in-progress item, `- [x]` completed. That edit lands in the work-doc on disk, never in the chat block alone. The ordering law and the reflect-after-each-step rule below apply unchanged, the marks just live in text.

**Ledger persistence (mandatory).** On BOTH substrates, in full hackify, **a tick is an edit to the work-doc file plus a chat re-print**. At every phase boundary you MUST rewrite the `## 0. Phase ledger` block in `docs/work/<slug>.md` so its marks match the ones you are about to print, and advance frontmatter `status` (plus `current_task` where the phase moves it) in that SAME edit. **The file edit comes before the print.** The one-line reflection may lead, but the block is never re-printed ahead of the edit that made it true, or the printed marks describe a file that does not carry them. A todo-tracker tick does not touch the file either, so the primary substrate owes this edit exactly as the fallback does. Skipping it is an abandoned-state bug: chat scrolls away, the file is what resume and archive read, and a doc that lands in `done/` still showing `- [>] Phase 5` is a false record of where the work stopped.

**On Claude Code specifically**, `TodoWrite` is frequently absent from the session tool surface, so the fallback is the NORMAL path there, not an exotic edge case. Check for the primitive at task start, and when it is not there, degrade to the printed block without comment. A missing tool is never a reason to drop the ledger.

## When to create it

- **Full hackify**, opened at **task start in Phase 1** as a printed block, right after the ask is real and before any code. It becomes section 0 of the work-doc at **Phase 2 step 1**, before you draft the rest of it.
- **Full hackify entered through groom**, where the work-doc already exists before Phase 1 runs, because [../../groom/SKILL.md](../../groom/SKILL.md) Step 2 creates it from the template at graduation. The rule that covers both paths is **whoever creates the file writes section 0 into it first**. So groom writes the block with every item open and prints it at handoff; **Phase 1 adopts** it, restore it into the todo tracker if the runtime has one, set Phase 1 `in_progress`, and never open a second one, groom just printed the block so the next print is the ordinary phase-boundary one; **Phase 2 step 1 still runs** and **confirms** the block is present and in sync instead of writing it. One section 0, written once, on every path.
- **quick**, at task start, right after Phase 1.
- **yolo**, at task start, right after Phase 1.

Create it with the **todo tracker** primitive when the runtime exposes one, otherwise with the fallback substrate above (`runtime-adapters.md`). One item per phase; **Phase 6 is split into sub-steps** so archiving is its own tracked line.

## The item lists per mode

**Full hackify** (10 items, in this order):

1. Phase 1. Clarify (lock the goal anchor)
2. Phase 2. Plan + Gate (work-doc + user "go")
3. Phase 2.5. Spec review (1 reviewer, patch the doc)
4. Phase 3. Implement (all waves committed)
5. Phase 4. Verify (Evidence Ledger + triad green)
6. Phase 5. Review (decision table empty)
7. Phase 6a. Re-verify + land choice (Steps A, B, C)
8. Phase 6b. Cleanup sweep (Step C.5)
9. **Phase 6c. Archive work-doc to `done/` (Step D)**
10. Phase 6d. Update log + HTML report (Step F)

Codewalk (Step D.5) and worktree cleanup (Step E) are conditional, add them as items only when they apply, and they no longer share a slot. Neither one can sit between 6c and 6d any more, because those two tick in a single edit (**Closing the ledger** below) and leave no gap between them. **Codewalk goes between 6b and 6c**, where it runs and ticks on its own trace before 6c opens. **Worktree cleanup goes after 6d**, because `git worktree remove` has to follow the archive move: when the sprint used a worktree the live work-doc sits inside it, and removing it first takes away the path the move needs. Its row is ticked by the closing edit along with 6c and 6d, for the same reason the move itself is not separately tickable. Phase 3b (Debug) is conditional, insert it only when a wave gets stuck.

**quick** (6 items), no work-doc, so no archive item:

1. Phase 1. Clarify-if-ambiguous + goal anchor
2. Phase 3. Implement
3. Phase 4. Verify (lite ledger + Layers 1-2)
4. Phase 5-lite. Single-lens address-all review
5. Phase 6. Cleanup sweep (Step C.5)
6. Phase 6. Update log + HTML report

**yolo** (7 items), no work-doc, so no archive item:

1. Phase 1. Clarify + goal anchor
2. Phase 2. In-chat plan (no gate)
3. Phase 2.5. Spec review (1 reviewer on the plan block)
4. Phase 3. Implement (waves)
5. Phase 4. Verify (full ledger + 3 layers)
6. Phase 5. Multi-reviewer (address-all, auto-fix)
7. Phase 6. Cleanup + commit (Option 1) + summary + report

## The ordering law (the whole point)

- **One item `in_progress` at a time.** Never two.
- **No jumping ahead.** You may not set a later item to `in_progress` until the current item is `completed`.
- **No silent skip.** A carve-out (a one-line typo that skips multi-reviewer; no entry-point so codewalk is skipped) is marked `completed` with a one-line reason appended, e.g. `Phase 5, skipped: one-line comment fix, no diff to review`. Never delete an item to make progress look done.
- **Parallelism lives INSIDE a phase, not across phases.** The Phase 5 reviewer panel and Phase 1's research agents fan out *within* their phase. Phase 3 is the one place that gives it up on purpose: a wave's tasks are file-disjoint but they read the same code, so ONE agent takes the whole wave. The phases themselves stay sequential.

## Exit artifact per phase (the anti-skip lever)

A checkbox may flip to `completed` **only when its exit artifact exists**. No artifact → the box stays open → the ordering law blocks every later phase.

| Phase | Exit artifact that must exist before you tick it |
|---|---|
| 1 Clarify | Locked Primary Goal & Guardrails anchor, all 5 parts, in the work-doc (in-chat for quick/yolo) |
| 2 Plan | Work-doc file exists at `docs/work/<date>-<slug>.md` **and** explicit user "go" |
| 2.5 Spec review | 1 reviewer report aggregated; Critical + Important findings patched into the doc |
| 3 Implement | Every Sprint Backlog checkbox ticked; each wave committed; wave-end persistence done; both scouts (perf + law) run on the wave-touched files with every candidate dispositioned |
| 4 Verify | A proof row per task **and** per acceptance bullet; fresh triad green (exit 0); the three ship-gate rows (`ship.build`, `ship.boot`, `ship.smoke`) present and each ✅ or `⏭ skipped` with a written reason |
| 5 Review | Decision table empty, every finding refuted with a counter-citation or fixed; final re-scan clean **on a diff unchanged since that scan** |
| 6a Re-verify + land choice | Verification re-run green on the pre-merge state, not Phase 4's result; the 4 options presented with no open-ended choice; the chosen option executed (commit, PR, stop, or discard) |
| 6b Cleanup sweep | A one-line evidence record per cleanup class in the work-doc Phase 6 archive (in-chat for quick/yolo), 0 findings counts; every defect found either fixed or filed as a linked Retrospective follow-up |
| **6c Archive** | **Frontmatter `status: done` and a fully closed ledger written into the work-doc, with `git mv docs/work/<slug>.md docs/work/done/<slug>.md` as the mechanical step that immediately follows** |
| 6d Update log | Five-field update log printed (blocks separated by `----`) and appended to the doc under `## Update log`, **and** `<slug>.report.html` already written to `docs/work/done/<slug>.report.html` |

The archive row is still the fix for the "forgot to archive" bug, but it does its work from the other end now: the edit that closes the ledger is the same edit that writes `status: done`, so a doc cannot be marked finished with a phase left open.

## Closing the ledger (the one place two rows tick together)

Phase 6 ends in a fixed order, and it is the only point in the workflow where two rows tick in the same edit.

1. **6b closes, 6c opens** as `- [>]`. The doc is still at its live path, `docs/work/<slug>.md`.
2. **Step F's work runs at that live path.** Print the five-field update log and render the HTML report straight to its final `docs/work/done/<slug>.report.html` path. Both of 6d's artifacts now exist.
3. **One edit closes both rows.** Append the update log to the doc under `## Update log`, tick 6c AND 6d `- [x]` (plus a conditional worktree row, when the sprint has one), and write frontmatter `status: done`. This is the last content change the doc ever receives.
4. **`git mv docs/work/<slug>.md docs/work/done/<slug>.md`** is the last mechanical step on the doc, and it is a rename rather than a content change. A worktree removal, where one applies, runs after that move and not before it.

Because the closing edit comes before the move, the doc never exists under `done/` carrying an open row. Under the previous order it always did, for the length of Step F, and check `[98]` reads that state as a sprint that stopped mid-phase.

**This is not a licence to tick ahead of an artifact.** 6c and 6d BOTH tick AFTER BOTH their artifacts exist: the log and the report are written in step 2, and the doc's own final content is written by the tick itself in step 3. What the ledger cannot record is the tail that follows it, the rename and any worktree removal, because a tick is a content change and the move has to be last. A check covers that gap instead of prose: assertion (c) of `[98]` reds on any doc carrying `status: done` outside `docs/work/done/`.

**The tradeoff, stated rather than hidden.** The old order put the archive first on purpose, so that the summary was the reward for archiving. Step 2 above gives that up, by the few seconds Step F takes. The new order is still the better one, and the reason is which wreckage each order leaves when a session dies mid-finish. Die between the report and the move, and the doc sits at its live path with `status: done`, which `[98]` assertion (c) reds on at the next validator run. Die between the move and the report under the old order, and you get an archived doc silently claiming a phase that never ran, with nothing to catch it. That is not hypothetical: `docs/work/done/2026-08-23-phase-ledger-substrate.md` is exactly that doc, and this sprint found it by hand. A red you can see beats a false record you cannot.

## Reflect after each step

When you complete a ledger item, do three things in order:

1. Say one line in chat, **what changed, did it pass, what is next** (this is the `communication-voice.md` narration).
2. Flip the item to `completed` and advance frontmatter `status` in the same edit.
3. Set the next item to `in_progress` in that same edit, save, then re-print the block.

Steps 2 and 3 are ONE edit to the work-doc's `## 0. Phase ledger` block in full hackify, and the re-print follows that saved edit. quick and yolo have no file, so there the print is the whole tick.

**The final pair is the one exception.** 6c and 6d close together, in one edit, with no next item to open, because 6d's artifacts are produced before either row is ticked and the move that finishes 6c has to be the last thing that happens to the file (**Closing the ledger** above). Every other tick in the workflow closes one row and opens the next. Read this as the single named exception it is, never as permission to close two rows at once elsewhere, and never as permission to tick a row whose artifact does not exist yet.

The reflection is the checkpoint. A tick with no reflection is an untrusted tick, you skipped the "did it pass?" question.

## Pause / resume

- The **Sprint Backlog** in the work-doc is the durable state. In full hackify the **phase ledger** is durable too, it is section 0 of the same file. Durable only if you keep writing it: a resume finds the phase your last file edit recorded, not the phase your last chat print showed.
- On resume, **read the ledger back** from the work-doc's `## 0. Phase ledger` block: re-print it, restore it into the todo tracker if the runtime has one, and set the first open phase to `in_progress`. It is a read, not a reconstruction. Only when that block is missing (an older work-doc) do you rebuild it from `status` + the Sprint Backlog checkboxes.
- quick / yolo keep no work-doc, so their ledger dies with the session, consistent with their no-resume contract.

## Anti-rationalizations (STOP and apply the reality)

| Thought | Reality |
|---|---|
| "I'll archive right after I show the summary" | There is no "after". The same edit that ticks the summary row writes `status: done`, and the `git mv` follows it immediately as the last mechanical step. Stop after that edit and skip the move, and `[98]` assertion (c) reds on the doc for sitting outside `done/` while claiming it is finished. |
| "Groom already created the work-doc, so Phase 2 step 1 has nothing to do" | It confirms section 0 is present and in sync. Confirming IS the step, and skipping it is how a groomed task runs with no durable ledger. Nobody writes the block twice, nobody writes it zero times. |
| "The code is done. I can skip the ledger now" | The ledger opens at task start, before any code. It is the order-enforcer, not a trophy for the end. |
| "The printed block is right, I'll write the file at the end" | There is no end that reads chat back. Tick the work-doc's section 0 and advance `status` in the same edit, then print. A ledger that is only ever printed dies with the session and archives at the wrong phase. |
| "The todo tracker already has it, so it is tracked" | The tracker is session-local and never touches the work-doc. Its tick owes the same file edit the printed block does, otherwise the durable copy stays frozen at the phase you opened it on. |
| "This phase does not apply. I'll delete its item" | Do not delete. Mark it `completed` with `skipped: <reason>`. Silent deletion hides drift. |
| "These two phases are independent. I'll do them together" | Phases are sequential. Parallelism belongs inside a phase (the Phase 5 reviewer panel, Phase 1 research agents), never across them. |
| "Tests are green, that's Phase 4 done" | Phase 4's exit artifact includes the three ship-gate rows. A green triad is not a booted app. |
| "The last re-scan came back clean, Phase 5 is done" | Only if the diff has not changed since that scan. Fixes applied after a scan were never reviewed. |

## See also

- [goal-anchor.md](goal-anchor.md), the Primary Goal & Guardrails locked in Phase 1 (Phase 1's exit artifact).
- [communication-voice.md](communication-voice.md), the reflect-after-step narration.
- [finish.md](finish.md), the Phase 6 steps the 6a, 6d ledger items map to (archive is Step D).
- [runtime-adapters.md](runtime-adapters.md), the `todo tracker` primitive and its per-runtime mapping.
- [../../groom/SKILL.md](../../groom/SKILL.md), the other skill that writes section 0, because on the groom path it is the one that creates the work-doc.

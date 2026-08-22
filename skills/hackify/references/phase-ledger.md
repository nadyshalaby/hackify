# Phase ledger (trackable, ordered, un-skippable)

A visible checklist that forces the phases to run **in order** and makes a forgotten step (like archiving the work-doc) impossible to hide. The ledger lives in the runtime's **todo tracker** (a trackable to-do list the user can see). It is the order-enforcer for the whole task.

Load this file from Phase 1. The ledger is always-on: it is created early and updated at every phase boundary.

## Why this exists

Prose rules like "do not skip Phase 2.5" and "archive before the summary" are soft, a model under load drops them. The ledger turns each rule into a **checkbox with an ordering law**. You cannot reach a later checkbox while an earlier one is open, so skipping a phase or forgetting the archive step becomes visible and blocked, not silent.

## Two layers (do not confuse them)

| Layer | Lives in | Scope | Survives a session? |
|---|---|---|---|
| **Sprint Backlog** | the work-doc | task-level (one line per task) | Yes, the durable state |
| **Phase ledger** | the todo tracker | phase/step-level (one line per phase) | No, session-local; rebuilt on resume |

They do not overlap. The Sprint Backlog tracks *what code work* is left. The phase ledger tracks *which workflow phase* you are in and forbids running them out of order.

## When to create it

- **Full hackify**, at the **start of Phase 2**, right after the ask is real and before any code. Create it before you draft the work-doc.
- **quick**, at task start, right after Phase 1.
- **yolo**, at task start, right after Phase 1.

Create it with the **todo tracker** primitive (`runtime-adapters.md`). One item per phase; **Phase 6 is split into sub-steps** so archiving is its own tracked line.

## The item lists per mode

**Full hackify** (10 items, in this order):

1. Phase 1. Clarify (lock the goal anchor)
2. Phase 2. Plan + Gate (work-doc + user "go")
3. Phase 2.5. Spec review (1 reviewer, patch the doc)
4. Phase 3. Implement (all waves committed)
5. Phase 4. Verify (Evidence Ledger + triad green)
6. Phase 5. Review (decision table empty)
7. Phase 6a. Re-verify + land choice (Steps A, C)
8. Phase 6b. Cleanup sweep (Step C.5)
9. **Phase 6c. Archive work-doc to `done/` (Step D)**
10. Phase 6d. Update log + HTML report (Step F)

Codewalk (Step D.5) and worktree cleanup (Step E) are conditional, add them as items only when they apply, between 6c and 6d. Phase 3b (Debug) is conditional, insert it only when a wave gets stuck.

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
- **Parallelism lives INSIDE a phase, not across phases.** Waves, spec reviewers, and code reviewers fan out *within* their phase. The phases themselves stay sequential.

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
| **6c Archive** | **Work-doc physically moved to `docs/work/done/<slug>.md` with `status: done`** |
| 6d Update log | Five-field update log printed (blocks separated by `----`) **and** `<slug>.report.html` emitted beside the archived doc |

The archive row is the fix for the "forgot to archive" bug. The summary (6d) is the **reward** for finishing, and it is unreachable while the archive (6c) is open, so the doc lands in `done/` before you ever print the recap.

## Reflect after each step

When you complete a ledger item, do three things in order:

1. Say one line in chat, **what changed, did it pass, what is next** (this is the `communication-voice.md` narration).
2. Flip the item to `completed`.
3. Set the next item to `in_progress`.

The reflection is the checkpoint. A tick with no reflection is an untrusted tick, you skipped the "did it pass?" question.

## Pause / resume

- The **Sprint Backlog** in the work-doc is the durable state. The **phase ledger** is session-local.
- On resume, **rebuild the ledger** from the work-doc: recreate the items, tick the phases already done (read `status` + the Sprint Backlog checkboxes), and set the first open phase to `in_progress`.
- quick / yolo keep no work-doc, so their ledger dies with the session, consistent with their no-resume contract.

## Anti-rationalizations (STOP and apply the reality)

| Thought | Reality |
|---|---|
| "I'll archive right after I show the summary" | The ledger blocks it. The summary item is unreachable while the archive item is open. Archive first. |
| "The code is done. I can skip the ledger now" | The ledger is created at Phase 2, before code. It is the order-enforcer, not a trophy for the end. |
| "This phase does not apply. I'll delete its item" | Do not delete. Mark it `completed` with `skipped: <reason>`. Silent deletion hides drift. |
| "These two phases are independent. I'll do them together" | Phases are sequential. Parallelism belongs inside a phase (waves, reviewers), never across them. |
| "Tests are green, that's Phase 4 done" | Phase 4's exit artifact includes the three ship-gate rows. A green triad is not a booted app. |
| "The last re-scan came back clean, Phase 5 is done" | Only if the diff has not changed since that scan. Fixes applied after a scan were never reviewed. |

## See also

- [goal-anchor.md](goal-anchor.md), the Primary Goal & Guardrails locked in Phase 1 (Phase 1's exit artifact).
- [communication-voice.md](communication-voice.md), the reflect-after-step narration.
- [finish.md](finish.md), the Phase 6 steps the 6a, 6d ledger items map to (archive is Step D).
- [runtime-adapters.md](runtime-adapters.md), the `todo tracker` primitive and its per-runtime mapping.

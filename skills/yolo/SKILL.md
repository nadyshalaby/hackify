---
name: yolo
description: Full-discipline-zero-waiting companion to hackify. Same phases as full hackify (Clarify with exploration, in-chat Plan, Spec-review, Implement in waves, Verify, Multi-reviewer, Finish) but Phase 2 plan sign-off and the Phase 6 4-options menu are auto-passed, so YOLO never blocks waiting on you. Auto-discovery triggers (case-insensitive, scanned in the most recent user message only), /hackify:yolo, /yolo, "yolo", "yolo it", "go yolo", "just do it", "don't ask me", "no questions", "fully autonomous", "auto mode", "go full auto". Does NOT trigger on "just fix it" (could mean quick mode) or "do it" (too ambiguous). Phase 5 findings are auto-fixed in-place at EVERY severity, then re-scanned to zero. No work-doc on disk, so no pause and no resume across sessions.
---

# Hackify YOLO (Full Discipline, Zero Waiting)

Sibling to full hackify. Same workflow phases, zero gates that wait on you. No work-doc on disk, the plan lives in chat as an assistant message. The user explicitly opted into "do it autonomously"; YOLO does it.

All three orchestration defaults apply ([`../hackify/references/orchestration.md`](../hackify/references/orchestration.md)) and YOLO is where they matter most: maximum tier on every fan-out, and the iteration driver carrying the task across turns with **no gate to stop at**, YOLO already auto-passes the Phase 2 sign-off and the Phase 6 menu. The loop's other two exit conditions still bind: it stops when the ledger is fully ticked, and it stops after two firings that advance nothing. Announce the tier in the in-chat plan block; `light mode` / `no ultracode` / `cheap mode` / `single agent` drop it at any point. **The completion sentinel matters more in YOLO than anywhere else**, precisely because there is no gate: with both sign-off points auto-passed, an evaluator outside this conversation is the only check on "done" that is not the parent's own opinion. Print the paste-ready `/goal <condition>` line in the same plan block, naming the commit plus the green triad, the ship-gate rows, and every surviving reviewer finding fixed. You print it, only the user sets it, never from a subagent, and the loop's stop conditions still outrank the evaluator.

**The no-parent-authored-diff law applies in full** (`../hackify/SKILL.md`): every code change is written by a dispatched agent under a file allowlist, including Phase 5's auto-fixes and Step C.5's cleanup, which YOLO applies without prompting. Autopilot removes the approval, not the dispatch.

The always-on ship bar applies in full: both deterministic scouts at BOTH Phase 3 run points, each wave agent over its own file allowlist before it returns and the parent over what that round's waves declared at round-end, the ship gate before Phase 5, the coherence lens never silently absent (Reviewer F whenever the diff crosses a module boundary, its checklist folded into B otherwise), and adversarial refutation before any auto-fix. Autopilot removes the waiting, never the proving. Running a bundled plugin script by path (the law-scout) is not a skill call.

## Workflow shape

```
Phase 1  (clarify + exploration + wizard if ambiguous + in-chat goal anchor)
  → Phase 2  (in-chat plan block + repo brief. NO doc, NO gate, immediate proceed)
  → Phase 2.5 (1 reviewer, three lenses, audits the in-chat plan block)
  → Phase 3  (implementation waves, one agent per wave whose tasks share a read surface,
              concurrent waves when they share nothing, same discipline as full hackify)
  → Phase 3b (debug-when-stuck, only if a wave gets stuck)
  → Phase 4  (verify: Evidence Ledger + three-layer re-verify + ship gate, fresh evidence)
  → Phase 5  (both scouts re-run, then the panel: A, B, D and F on every
              non-trivial diff, E on UI-bearing;
              refute before fixing; address-all: auto-fix EVERY severity in-place
              incl. Minor; then the phase ENDS, one panel and one refuter, no re-scan)
  → Phase 6  (Step C.5 auto-fix pre-existing in touched files; auto-pick Option 1: commit to current branch locally, no push; print update log + HTML report)
```

The user is consulted ONLY for Phase 1 wizard answers (if the ask is ambiguous). Phase 2 plan-gate and Phase 6 4-options menu are auto-passed, that is the YOLO contract.

## Phase ledger, trackable, ordered (always-on)

Open a **phase ledger** at task start, one item per phase. Clarify → Plan → Spec-review → Implement → Verify → Multi-reviewer → Finish. Rules (full contract: `../hackify/references/phase-ledger.md`):

- **Substrate.** The runtime's **todo tracker** primitive when the session actually exposes one, otherwise a printed markdown checklist in chat, re-printed at **every** phase boundary. **On Claude Code the printed block is the normal path**, not an exotic edge case, because the todo tracker is frequently absent from the session tool surface. YOLO writes no work-doc, so that printed block is the ONLY record its ledger has, which makes the re-print rule load-bearing rather than cosmetic. The ledger degrades to visible-but-not-interactive, never to absent. On the fallback a tick is an edit plus a re-print: `- [ ]` open, `- [>]` the single in-progress item, `- [x]` done.
- One item `in_progress` at a time. No later phase starts until the current phase's exit artifact exists and its item is `completed`.
- **Auto-pass removes the WAIT, not the STEP.** YOLO auto-passes the Phase 2 gate and the Phase 6 menu, but still ticks every ledger item in order. No work-doc → the ledger is session-local.
- **No step is ever silently dropped.** Gate-free is not step-free, and nobody is watching, which is exactly why this one is written down. Every one of YOLO's own items ends either `completed`, or `completed` with a one-line reason printed in the block, e.g. `Phase 3b, skipped: no wave got stuck`. Never delete an item to make progress look done.
- **Reflect after each item**, one line: what changed, did it pass, what is next, then advance.

## Expert mindset (always-on)

Autopilot is not autopilot for thinking. Approach the task as a **senior, multi-disciplinary engineer**, problem-solver, security, performance, architect, advisor, verifier, and prove every claim with fresh evidence. Doctrine: `../hackify/references/expert-mindset.md` (a tight version is injected every prompt from `rules/expert-mindset.md`, beside the always-on `rules/hard-caps.md`, `rules/perf-guardrails.md`, `rules/phase-discipline.md` and `rules/claim-integrity.md`, five injected files in all, so the caps, the performance law and the no-silent-drop phase law all bind in YOLO too).

## Auto-pass behavior (the two gates YOLO skips)

| Gate | Full hackify behavior | YOLO behavior |
|---|---|---|
| **Phase 2. Plan sign-off** | Hard gate; waits for explicit `go` / `approved` / `yes` | No gate; the in-chat plan block is posted and Phase 2.5 begins immediately. The block still carries the **repo brief** (`../hackify/references/repo-brief.md`), ≤350 words of stack, verbatim commands, layout, layering rule, rules source, test convention and landmines, each line ending in the command or `file:line` that proved it, passed as `{{repo_brief}}` to every implementer and reviewer. No doc means no place to look it up later, so it goes in the plan block or nowhere |
| **Phase 6, 4-options finish menu** | User picks 1 / 2 / 3 / 4 | Auto-picks Option 1: commit to current branch locally, no push. User inspects with `git log -1` / `git diff HEAD~1` afterward. |

*Naming note. YOLO redefines Option 1. In full hackify's Phase 6 menu, Option 1 means "Merge to base branch locally"; YOLO's auto-picked Option 1 means commit to current branch locally, no push, no merge, no branch switch.*

*Phase 6 Step C.5 cleanup sweep also applies. YOLO auto-fixes pre-existing lint/type/test/dead-code in the touched files (no prompt) so they end clean. See `../hackify/references/finish.md` Step C.5.*

*Phase 6 Step F is unchanged too: print the update log, render the self-contained HTML report, and where the runtime can publish a page, publish it and tell the user the link. Autopilot does not skip that, it just does not ask first. Where the runtime has no publish tool, the path is the answer and the step still completes, the link is never what closes the item. See `../hackify/references/html-report.md`.*

## Kept phases (identical to full hackify)

| Phase | Action | Why kept |
|---|---|---|
| **1. Clarify + goal** | Classify task type → exploration step (read just enough context) → batched wizard if any ambiguity remains → capture the Primary Goal & Guardrails as an in-chat anchor. Same as full hackify Phase 1. | A misread ask is more expensive than a wizard call, even in autopilot; the anchor drives the drift-check. |
| **2.5. Spec self-review** | Dispatch the 1 reviewer, `hackify:spec-reviewer`, against the in-chat plan block (Original Ask + AC + Sprint Backlog). It carries three lenses over one read: consistency and goal drift, the wave plan Phase 3 dispatches off, architectural and cross-cutting risk. Audit text is the assistant message, not a work-doc on disk. | Spec defects are cheap to catch on paper; expensive after 200 LOC. |
| **3. Implement** | Implementation waves in dependency order with per-task file allowlists, dispatched **by registered agent type** (`hackify:wave-implementer`) with only its INPUTS, ONE agent for the whole wave however wide it is when the wave's tasks share a read surface (no cap on one wave's width and no split by module hunch; waves that share nothing may go out at the same time, one agent each, and only the partition test in `../hackify/references/phases/phase-3-implement.md` may split a wave), carrying the shared `{{repo_brief}}`, never by pasting a template. Read the `## Wave status` header EVERY returned report opens with for which task IDs landed, tick ONLY those in the in-chat ledger and re-dispatch the rest. Same as full hackify Phase 3, including BOTH scouts at BOTH Phase 3 run points, perf-scout (`../hackify/references/perf-scout.md`) and law-scout (`../hackify/references/law-scout.md`): each wave agent runs them over its OWN file allowlist before it returns, fixing trivial in-allowlist candidates in place and staging the rest in its report, and the parent runs them again at round-end over what that round's waves DECLARED under the `## Paths written` block every returned report carries, never the union of their allowlists, because a wave that stopped early declares a strict subset on purpose and the rest of that union is files the round never touched, carrying each wave's dispositions forward unchanged and staging what only the wider scope can see. The parent never writes a scout fix itself, it sends a trivial cross-wave one back out as a one-task wave, because `no-parent-authored-diff` binds here too. | Wave discipline is what keeps the order safe, and one agent per wave keeps its context in one place. Concurrency changes how many waves go out at once, never the proving: each agent still stops at the first task it cannot finish, keeps what already landed on disk, and still reports which task IDs landed. |
| **4. Verify** | Full hackify Phase 4: an **Evidence Ledger** (proof row per task + acceptance bullet), all three re-verify layers (fresh triad, goal-drift re-check, independent re-prove), and the **ship gate** (`../hackify/references/ship-gate.md`), `ship.build` / `ship.boot` / `ship.smoke`, blocking whenever the diff touched something that leg's target consumes, written `⏭ skipped` with the reason otherwise. Fresh output, no warm cache. | Skipping verify ships broken work, autopilot makes that worse, not better. A green triad is not a booted app. |
| **5. Multi-reviewer** | At Phase 5 start, re-run BOTH scouts on the whole diff; staged candidates join the address-all loop. Then the **panel** (`../hackify/references/phases/phase-5-review.md`), dispatched in ONE message **by registered agent type**, passing only each type's INPUTS, never by pasting a template. Each reviewer gets `{{review_scope}}` and diffs only its own slice; **B is never sliced** and takes `{{metrics_table}}` instead (`../hackify/references/review-scope.md`). **A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one.** B (quality + engineering law + plan-consistency / goal-drift) carries two lenses over one read since v0.13.0 merged Reviewer C into it. A is security, D is performance, F is cross-module coherence, and none of the three is gated any more. **Reviewer E (design conformance) is the one conditional lens and joins whenever the diff is UI-bearing** (`skills/hackify/references/parallel-agents/phase-5-multi-review-e-design.md`). Reviewer B consumes the law-scout table and cites lawkeeper `rule_id`s; Reviewer D consumes the perf-scout table and cites `perf.<domain>.<slug>` IDs. Reviewer F checks producer against consumer on every boundary-crossing symbol, the lens that catches what a wave's implementer never sees, every earlier wave and every line of pre-existing code (`phase-5-multi-review-f-coherence.md`). B's plan-consistency lens audits the diff against the in-chat plan block. **Refute before fixing** (`phase-5-refute.md`), then address-all: auto-fix EVERY surviving severity (see severity table below). **Then Phase 5 ENDS.** YOLO runs the same round cap as full mode: one panel, one refuter, one fix sequence, and no re-scan however much the fixes changed. A defect a fix introduces is fixed in the same sequence and reported, and anything left unresolved is written down rather than re-reviewed. | YOLO speed comes from no gates, not from skipped reviewers. |

## What's different from full hackify

| Aspect | Full hackify | YOLO |
|---|---|---|
| Work-doc on disk | `docs/work/<slug>.md` | NO, in-chat plan block only |
| Phase 2 plan-gate | Hard gate, waits for `go` | No gate, immediate proceed |
| Phase 5 Critical | Surface to user; ask | Auto-fix in-place, no surface |
| Phase 5 Important | Auto-fix in-place | Auto-fix in-place (same) |
| Phase 5 Minor | Fix (defer only with sign-off) | Auto-fix in-place too (address-all); logged to chat (no Retrospective doc exists) |
| Phase 6 finish menu | User picks 1 / 2 / 3 / 4 | Auto-picks Option 1: commit to current branch locally |
| Pause / resume across sessions | Yes, work-doc holds state | NO, close the chat and progress is gone |
| Reviewer audit subject | Work-doc Sprint Backlog + AC list | In-chat plan block (assistant message) |

Everything else, clarify wizard, exploration step, implementation waves, TDD discipline, Phase 3b debug-when-stuck, is identical.

## When NOT to use YOLO

Route these to full hackify (`/hackify:hackify`) from the start.

| Shape | Why |
|---|---|
| Multi-day work | No work-doc → no resume. Close the chat and progress is gone. |
| You want to review the plan before code lands | YOLO never shows you the plan before implementing, the in-chat plan block is for reviewers, not for you to gate on. |
| Auth / crypto / migration / secret / token / password work | Auto-fix Critical is risky on security-sensitive surfaces. A reviewer's suggested fix may be wrong for your codebase, and you won't see it until `git diff HEAD~1`. |
| Cross-team review needs | The Phase 6 4-options finish menu is the natural anchor for "open a PR" decisions. YOLO commits locally without asking. |
| You can't list expected files up-front | Same caveat as quick mode, task is too underspecified for wave dispatch. |

## Anti-rationalizations (STOP and apply the listed reality)

| Thought | Reality |
|---|---|
| "The user said yolo, skip Phase 1 wizard too" | YOLO skips GATES (Phase 2, Phase 6), not CLARIFY. Run the wizard if the ask has any ambiguity, a misread ask in autopilot costs more, not less. |
| "Phase 2.5 has no work-doc, skip it" | The in-chat plan block IS the audit subject. Dispatch the 1 reviewer against the assistant message text. Same rigor, different surface. |
| "Critical finding came back, ask the user" | YOLO contract: address-all, auto-fix EVERY severity in-place (Critical, Important, AND Minor), then re-scan to zero. The user inspects via `git diff HEAD~1` after commit, that is the inspection point. |
| "Push the commit too, they'll want it on remote" | No. Phase 6 default is commit to current branch locally, no push. Pushing is user-initiated (`git push` themselves). |
| "Skip multi-reviewer because no work-doc DoD to consistency-check against" | The in-chat plan block has the AC list. Reviewer B audits diff against that list. No skip. |
| "Auto-pass means I can skip the phase too" | Auto-pass removes the WAIT at a gate, not the phase. Every ledger item still runs in order and gets ticked `completed`. |
| "Nobody is watching this run, so a step I drop costs nothing" | It costs the whole point. Every item ends `completed`, or `completed` with a written one-line reason. Autopilot is where a silent drop is least likely to be noticed and most likely to ship. |
| "There is no to-do tool in this session, so there is no ledger" | There is one. Print it in chat and re-print it at every boundary. YOLO keeps nothing on disk, so the printed block is the only record the ledger has. |
| "Autopilot, so auto-fix without refuting" | Refute first. Auto-fixing a phantom Important or Minor in autopilot breaks working code and nobody sees it until `git diff HEAD~1`, and both die on one refutation. ONE refuter per round carries BOTH lenses itself, so there is no second dispatch to schedule. A refutation never kills a Critical here: both lenses refuting still gets fixed, both counter-citations recorded beside the fix. An ESCALATED verdict still raises a severity, but no verdict takes a Critical out of the address-all loop. No adjudication, no gate, nobody to sign a dismissal off. A wasted edit costs less than shipping a real Critical unattended. |
| "Tests are green, skip the ship gate and commit" | The ship gate is a Phase 4 exit artifact in every mode. Commit is Phase 6; you cannot reach it with an open ledger item. |
| "The re-scan came back clean, commit it" | Only if the diff has not changed since. A round that changed code mandates another round before Phase 6. |

## One-line summary

Full hackify pipeline, no gates that wait on you, no work-doc on disk, clarify-with-exploration + goal anchor → in-chat plan → spec-review → wave impl, one agent per whole wave whose tasks share a read surface and concurrent waves when they share nothing (both scouts twice, each agent over its own allowlist before it returns and the parent over what that round's waves declared at round-end) → verify (ledger + 3 layers + ship gate) → the parallel Multi-reviewer panel, refute, address-all auto-fix every surviving severity, then the phase ends → touched-scope cleanup + commit to current branch locally + HTML report.

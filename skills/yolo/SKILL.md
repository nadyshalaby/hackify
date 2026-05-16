---
name: yolo
description: Full-discipline-zero-waiting companion to hackify. Same phases as full hackify (Clarify with exploration, in-chat Plan, Spec-review, parallel Implement, Verify, Multi-reviewer, Finish) but Phase 2 plan sign-off and Phase 6 4-options menu are auto-passed — YOLO never blocks waiting on you. Auto-discovery triggers (case-insensitive, scanned in the most recent user message only) — /hackify:yolo, /yolo, "yolo", "yolo it", "go yolo", "just do it", "don't ask me", "no questions", "fully autonomous", "auto mode", "go full auto". Does NOT trigger on "just fix it" (could mean quick mode) or "do it" (too ambiguous). Phase 5 multi-reviewer findings are auto-fixed in-place at every severity (Critical AND Important); Minor findings logged to chat — inspect via `git diff HEAD~1` after the commit lands. No work-doc on disk → no pause and no resume across sessions; close the chat mid-task and progress is gone. Invoke full hackify if you need persistence or want to sign off on the plan first.
---

# Hackify YOLO — Full Discipline, Zero Waiting

Sibling to full hackify. Same workflow phases, zero gates that wait on you. No work-doc on disk — the plan lives in chat as an assistant message. The user explicitly opted into "do it autonomously"; YOLO does it.

## Workflow shape

```
Phase 1  (clarify + exploration + wizard if ambiguous)
  → Phase 2  (in-chat plan block — NO doc, NO gate, immediate proceed)
  → Phase 2.5 (3 parallel reviewers audit the in-chat plan block)
  → Phase 3  (parallel implementation waves, same discipline as full hackify)
  → Phase 3b (debug-when-stuck — only if a wave gets stuck)
  → Phase 4  (verify with fresh test + lint + typecheck evidence)
  → Phase 5  (3 parallel reviewers; auto-fix Critical AND Important in-place; log Minor to chat)
  → Phase 6  (auto-pick Option 1: commit to current branch locally, no push; print summary table)
```

The user is consulted ONLY for Phase 1 wizard answers (if the ask is ambiguous). Phase 2 plan-gate and Phase 6 4-options menu are auto-passed — that is the YOLO contract.

## Auto-pass behavior — the two gates YOLO skips

| Gate | Full hackify behavior | YOLO behavior |
|---|---|---|
| **Phase 2 — Plan sign-off** | Hard gate; waits for explicit `go` / `approved` / `yes` | No gate; the in-chat plan block is posted and Phase 2.5 begins immediately |
| **Phase 6 — 4-options finish menu** | User picks 1 / 2 / 3 / 4 | Auto-picks Option 1: commit to current branch locally, no push. User inspects with `git log -1` / `git diff HEAD~1` afterward. |

## Kept phases — identical to full hackify

| Phase | Action | Why kept |
|---|---|---|
| **1 — Clarify** | Classify task type → exploration step (read just enough context) → batched wizard if any ambiguity remains. Same as full hackify Phase 1. | A misread ask is more expensive than a wizard call, even in autopilot. |
| **2.5 — Spec self-review** | Dispatch 3 parallel reviewers against the in-chat plan block (Original Ask + AC + Sprint Backlog). Audit text is the assistant message, not a work-doc on disk. | Spec defects are cheap to catch on paper; expensive after 200 LOC. |
| **3 — Implement** | Parallel implementation waves with per-task file allowlists. Same as full hackify Phase 3. | Wave discipline is what makes parallel safe. |
| **4 — Verify** | Fresh test + lint + typecheck output. Same as full hackify Phase 4. | Skipping verify ships broken work — autopilot makes that worse, not better. |
| **5 — Multi-reviewer** | 3 parallel reviewers (security + quality + plan-consistency). Plan-consistency reviewer audits diff against the in-chat plan block. Findings auto-handled (see severity table below). | YOLO speed comes from no gates, not from skipped reviewers. |

## What's different from full hackify

| Aspect | Full hackify | YOLO |
|---|---|---|
| Work-doc on disk | `docs/work/<slug>.md` | NO — in-chat plan block only |
| Phase 2 plan-gate | Hard gate, waits for `go` | No gate, immediate proceed |
| Phase 5 Critical | Surface to user; ask | Auto-fix in-place, no surface |
| Phase 5 Important | Auto-fix in-place | Auto-fix in-place (same) |
| Phase 5 Minor | Log to Retrospective | Log to chat (no Retrospective doc exists) |
| Phase 6 finish menu | User picks 1 / 2 / 3 / 4 | Auto-picks Option 1: commit to current branch locally |
| Pause / resume across sessions | Yes — work-doc holds state | NO — close the chat and progress is gone |
| Reviewer audit subject | Work-doc Sprint Backlog + AC list | In-chat plan block (assistant message) |

Everything else — clarify wizard, exploration step, parallel waves, TDD discipline, Phase 3b debug-when-stuck — is identical.

## When NOT to use YOLO

Route these to full hackify (`/hackify:hackify`) from the start.

| Shape | Why |
|---|---|
| Multi-day work | No work-doc → no resume. Close the chat and progress is gone. |
| You want to review the plan before code lands | YOLO never shows you the plan before implementing — the in-chat plan block is for reviewers, not for you to gate on. |
| Auth / crypto / migration / secret / token / password work | Auto-fix Critical is risky on security-sensitive surfaces. A reviewer's suggested fix may be wrong for your codebase, and you won't see it until `git diff HEAD~1`. |
| Cross-team review needs | The Phase 6 4-options finish menu is the natural anchor for "open a PR" decisions. YOLO commits locally without asking. |
| You can't list expected files up-front | Same caveat as quick mode — task is too underspecified for parallel wave dispatch. |

## Anti-rationalizations — STOP and apply the listed reality

| Thought | Reality |
|---|---|
| "The user said yolo, skip Phase 1 wizard too" | YOLO skips GATES (Phase 2, Phase 6), not CLARIFY. Run the wizard if the ask has any ambiguity — a misread ask in autopilot costs more, not less. |
| "Phase 2.5 has no work-doc, skip it" | The in-chat plan block IS the audit subject. Dispatch the 3 reviewers against the assistant message text. Same rigor, different surface. |
| "Critical finding came back, ask the user" | YOLO contract: auto-fix Critical AND Important in-place; log Minor to chat. The user inspects via `git diff HEAD~1` after commit — that is the inspection point. |
| "Push the commit too — they'll want it on remote" | No. Phase 6 default is commit to current branch locally, no push. Pushing is user-initiated (`git push` themselves). |
| "Skip multi-reviewer because no work-doc DoD to consistency-check against" | The in-chat plan block has the AC list. Reviewer C audits diff against that list. No skip. |

## One-line summary

Full hackify pipeline, no gates that wait on you, no work-doc on disk — clarify-with-exploration → in-chat plan → spec-review → parallel impl → verify → multi-reviewer (auto-fix Critical AND Important) → commit to current branch locally.

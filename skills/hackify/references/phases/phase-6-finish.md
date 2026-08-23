# Phase 6, Finish (4 options, archive, cleanup, update log)

Loaded by `SKILL.md` when this phase opens. The phase's entry conditions, hard gates and exit artifact are stated in `SKILL.md`; this file is the protocol.

**Goal.** Land the work cleanly and archive the doc.

**Ledger, at phase open.** Phase 6 is **four** ledger items, not one, so the archive cannot hide inside a finished-looking phase. Set `Phase 6a. Re-verify + land choice (Steps A, B, C)` to in-progress and re-print the whole block, never while `Phase 5. Review` is still open, then work the items in order.

| Ledger item | Steps below |
|---|---|
| **6a.** Re-verify + land choice | Steps A, B, C |
| **6b.** Cleanup sweep | Step C.5 |
| **6c.** Archive work-doc to `done/` | Step D |
| **6d.** Update log + HTML report | Step F |

Codewalk (Step D.5) and worktree cleanup (Step E) are conditional, add them as items only when they apply, between 6c and 6d. Contract: [../phase-ledger.md](../phase-ledger.md).

**Step A, re-run verification.** Even if Phase 4 passed. Pre-merge state drifts.

**Step B, present exactly 4 options, no open-ended choice:**

| # | Option | Default for |
|---|---|---|
| 1 | Merge to base branch locally | Small in-place changes |
| 2 | Push and create a PR | Cross-team or larger changes |
| 3 | Keep the branch as-is | Work pauses; no cleanup |
| 4 | Discard this work | Requires user typing "discard" verbatim, no shortcut |

**Step C, execute the choice.** **1 or 2:** Commit follows project convention; ends with Claude Code Co-Authored-By trailer. PRs include Summary, Test plan, and link to work-doc. **3:** Stop. Leave everything in place. **4:** Confirm, then `git checkout` base branch and remove worktree if any. Never `git reset --hard` without explicit user instruction.

**Step C.5. Cleanup sweep** (mandatory; runs before archive). Sweep for 8 classes of leftover/abandoned/stale state introduced or surfaced during the sprint. Each class needs a one-line evidence record in the work-doc Phase 6 archive (0 findings counts).

| # | Cleanup class | Audit |
|---|---|---|
| a | Stale cross-references | grep for references to files/sections that no longer exist after this sprint. |
| b | Broken internal anchor links | scan markdown anchor links inside touched files. |
| c | TODO/FIXME without owners | grep diff for new `TODO`/`FIXME` lacking an explicit owner or follow-up issue. |
| d | Empty directories left after file moves | `find` for empty dirs under primitives. |
| e | Dead branches | local + remote branches created during the sprint that won't be merged. |
| f | Unrelated changes that snuck in | final scope-creep audit: `git diff main..HEAD -- . ':(exclude)docs/work/*'` cross-checked against work-doc Sprint Backlog file allowlists. The exclusion is load-bearing: this audit measures the diff against the work-doc's own allowlists, and the work-doc cannot authorize itself, so without it finish reports the ruler as scope creep on every single run. |
| g | Pre-existing errors + dead code in touched files (lint/type/test failures, dead code) | detect against the sprint-start baseline; surface and **offer to fix** so touched files end with nothing a reviewer would flag (auto-fix in yolo). Defer only if too large, with explicit user sign-off. |
| h | Work-doc references to file paths that just changed | grep the work-doc itself + any sibling work-docs for paths that moved/deleted in this sprint. |

If any class finds defects, **dispatch a cleanup agent per file-disjoint group, in one message**, to fix them before archiving; the parent audits and aggregates, it does not edit. If a defect is too large for this sprint, file a follow-up Retrospective entry and link to it. The touched-scope goal is the **best version**, zero outstanding lint/type/test/dead-code issues in files this sprint changed; whole-repo pre-existing issues stay out of scope (that is `/hackify:lawkeeper`'s job). Detailed audit + baseline commands per class: `references/finish.md`.

**Step D, archive the work-doc** (1 or 2): move `<project>/docs/work/<slug>.md` → `<project>/docs/work/done/<slug>.md`. Update `status: done`. Retrospective is mandatory, 3-8 bullets on what surprised, what to remember. This is phase-ledger item **6c**; its exit artifact (the doc physically in `done/` with `status: done`) is the **hard precondition for Step F**. **Do not print the summary or emit the report until this move is complete**, the summary is the reward for archiving, not a substitute.

**Step D.5. Codewalk follow-up** *(since v0.3.2; 1 or 2 only)*: if the task touched an entry-point file (controller, CLI command, queue/Inngest function, UI action, route handler), ask the user via `AskUserQuestion` whether to *update an existing* `.codewalk/<slug>/` trace, *create a new codewalk* for the touched entry, or *skip*. On Update/Create, invoke `/codewalk <entry-point>` immediately, codewalk runs in update-by-default mode so a re-invoke preserves manual edits and produces an amber diff callout. Skip silently when no entry-point files were touched. Details + the file-pattern detection list + the exact AskUserQuestion shape: `references/finish.md` Step D.5.

**Step E, worktree cleanup** (1, 2, or 4): `git worktree remove <path>`; delete the local branch if merged. NOT for option 3.

**Step F. Update log + HTML report** (1 or 2 only). **Precondition: Step D archive is done**, the work-doc must already be in `docs/work/done/` with `status: done`, and ledger item `6c` `completed`, before this step runs. If it is not, go back and archive first. Print a plain-language **update log**: one block per change the user would recognize, each with five fields in this order, **Problem** / **Root cause** / **Solution** / **Verification evidence** / **Deployment status**, separated by a line containing exactly `----`. Write it the way you would explain the work out loud to someone who was not in the room: everyday words, no jargon they did not use, and never a phase number, task ID, reviewer letter or scout name. Append the same log to the archived work-doc inside Retrospective under a new `## Update log` subheading. **Then emit a styled, self-contained HTML report** (stats, inline-SVG charts, findings, action items, next steps) beside the archived work-doc at `<slug>.report.html`, see [references/html-report.md](../html-report.md). Field-by-field guidance, voice rules, and a worked example: `references/finish.md` "Step F (Update log + HTML report)".

**Invoking the summary on demand.** The update log runs any time via `/hackify:summary` or phrase trigger ("show summary", "summarize", "summary table", "show me what changed"). Mid-flight invocation prints to chat; Step F also appends to the work-doc.

**Ledger, at phase exit.** Each of 6a to 6d ticks on its own exit artifact, one line of reflection first (what changed, did it pass, what is next), then the tick, then the next item opens and the block is re-printed. 6d stays unreachable while 6c is open; Steps D and F state that precondition and the ledger is what enforces it. An item that does not apply (no worktree, no entry point) is ticked with a one-line reason, never deleted. The task is done when the last item is ticked, not when the summary is printed.

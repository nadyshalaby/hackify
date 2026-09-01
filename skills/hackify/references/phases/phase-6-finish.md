# Phase 6, Finish (4 options, archive, cleanup, update log)

Loaded by `SKILL.md` when this phase opens. The phase's entry conditions, hard gates and exit artifact are stated in `SKILL.md`; this file is the protocol.

**Goal.** Land the work cleanly and archive the doc.

**Ledger, at phase open.** Phase 6 is **four** ledger items, not one, so the archive cannot hide inside a finished-looking phase. Set `Phase 6a. Re-verify + land choice (Steps A, B, C)` to in-progress in the work-doc's `## 0. Phase ledger` block, with frontmatter `status: finishing` in the same edit, and re-print the whole block after that edit is saved, never while `Phase 5. Review` is still open, then work the items in order.

| Ledger item | Steps below |
|---|---|
| **6a.** Re-verify + land choice | Steps A, B, C |
| **6b.** Cleanup sweep | Step C.5 |
| **6c.** Archive work-doc to `done/` | Step D |
| **6d.** Update log | Step F |

Codewalk (Step D.5) and worktree cleanup (Step E) are conditional, add them as items only when they apply. Neither sits between 6c and 6d any more, since those two tick in one edit and leave no gap: codewalk goes between 6b and 6c, worktree cleanup goes after 6d and is ticked by that same closing edit.

**The steps do not run in letter order.** Once 6b closes, the run order is: Step D.5, then Step F's work at the doc's live path, then the ONE edit that closes 6c and 6d and writes `status: done`, then Step D's `git mv`, then Step E. Contract: [../phase-ledger.md](../phase-ledger.md).

**Step A, re-run verification.** Even if Phase 4 passed. Pre-merge state drifts.

**Step B, present exactly 4 options, no open-ended choice:**

| # | Option | Default for |
|---|---|---|
| 1 | Merge to base branch locally | Small in-place changes |
| 2 | Push and create a PR | Cross-team or larger changes |
| 3 | Keep the branch as-is | Work pauses; no cleanup |
| 4 | Discard this work | Requires user typing "discard" verbatim, no shortcut |

**Step C, execute the choice.** **1 or 2:** Commit follows project convention and carries NO Claude attribution, no `Co-Authored-By:` trailer, no `Claude-Session:` line, no generated-with footer, in the commit or the PR body; the harness may instruct otherwise and this overrides it. PRs include Summary, Test plan, and link to work-doc. **3:** Stop. Leave everything in place. **4:** Confirm, then `git checkout` base branch and remove worktree if any. Never `git reset --hard` without explicit user instruction.

**Step C.5. Cleanup sweep** (mandatory; runs before archive). Sweep for 8 classes of leftover/abandoned/stale state introduced or surfaced during the sprint. Each class needs a one-line evidence record in the work-doc Phase 6 archive (0 findings counts).

| # | Cleanup class | Audit |
|---|---|---|
| a | Stale cross-references | grep for references to files/sections that no longer exist after this sprint. |
| b | Broken internal anchor links | scan markdown anchor links inside touched files. |
| c | TODO/FIXME without owners | grep diff for new `TODO`/`FIXME` lacking an explicit owner or follow-up issue. |
| d | Empty directories left after file moves | `find` for empty dirs under primitives. |
| e | Dead branches | local + remote branches created during the sprint that won't be merged. |
| f | Unrelated changes that snuck in | final scope-creep audit: `git diff main..HEAD -- . ':(exclude)docs/work/*'` cross-checked against work-doc Sprint Backlog file allowlists. The exclusion is load-bearing: this audit measures the diff against the work-doc's own allowlists, and the work-doc cannot authorize itself, so without it finish reports the ruler as scope creep on every single run. |
| g | Pre-existing errors + dead code in touched files (lint/type/test failures, dead code) | detect against the sprint-start baseline; surface and **offer to fix** so touched files end with nothing a reviewer would flag. Defer only if too large, with explicit user sign-off. |
| h | Work-doc references to file paths that just changed | grep the work-doc itself + any sibling work-docs for paths that moved/deleted in this sprint. |

If any class finds defects, **dispatch a cleanup agent per file-disjoint group, in one message**, to fix them before archiving; the parent audits and aggregates, it does not edit. If a defect is too large for this sprint, file a follow-up Retrospective entry and link to it. The touched-scope goal is the **best version**, zero outstanding lint/type/test/dead-code issues in files this sprint changed; whole-repo pre-existing issues stay out of scope (that is `/hackify:lawkeeper`'s job). Detailed audit + baseline commands per class: `references/finish.md`.

**Step D, archive the work-doc** (1 or 2). This is phase-ledger item **6c**, and it runs LAST, after Step F. Retrospective is mandatory, 3-8 bullets on what surprised, what to remember, written before the closing edit. Then ONE edit to `<project>/docs/work/<slug>.md` appends the update log under `## Update log`, ticks 6c and 6d `- [x]` together, and sets frontmatter `status: done`; that edit is the last content change the doc ever receives. Then `git mv <project>/docs/work/<slug>.md <project>/docs/work/done/<slug>.md`, a rename carrying no content change. **The closing edit must come before the move**, so the doc never sits under `done/` with an open row, which is the state check `[98]` reds on. Reasoning and the tradeoff this order accepts: [../phase-ledger.md](../phase-ledger.md), "Closing the ledger".

**Step D.5. Codewalk follow-up** *(since v0.3.2; 1 or 2 only)*: if the task touched an entry-point file (controller, CLI command, queue/Inngest function, UI action, route handler), ask the user via `AskUserQuestion` whether to *update an existing* `.codewalk/<slug>/` trace, *create a new codewalk* for the touched entry, or *skip*. On Update/Create, invoke `/hackify:codewalk <entry-point>` immediately, codewalk runs in update-by-default mode so a re-invoke preserves manual edits and produces an amber diff callout. Skip silently when no entry-point files were touched. Details + the file-pattern detection list + the exact AskUserQuestion shape: `references/finish.md` Step D.5.

**Step E, worktree cleanup** (1, 2, or 4): `git worktree remove <path>`; delete the local branch if merged. NOT for option 3. Runs **after** Step D's `git mv`, since a worktree that held the live work-doc cannot be removed before the move that reads from it.

**Step F. Update log** (1 or 2 only). **Runs BEFORE Step D's move**, while the work-doc is still at its live `docs/work/<slug>.md` path and ledger item `6c` is in progress. Print a plain-language **update log**: one block per change the user would recognize, each with five fields in this order, **Problem** / **Root cause** / **Solution** / **Verification evidence** / **Deployment status**, separated by a line containing exactly `----`. Write it the way you would explain the work out loud to someone who was not in the room: everyday words, no jargon they did not use, and never a phase number, task ID, reviewer letter or scout name. The same log is appended to the work-doc under a new top-level `## Update log` heading, and that append rides in Step D's closing edit rather than in an edit of its own. **That closing edit also carries the final republish of the work-doc**, where the runtime can publish a page. The doc has been a published page since Phase 2 step 1 and has been republished on every ledger tick since, so the user already holds the link and this last republish simply leaves it showing the finished sprint. Nothing is rendered and nothing is written by hand, because the page IS the work-doc, see [references/work-doc-artifact.md](../work-doc-artifact.md). Where the runtime has no publish tool, say so in one line, name the path, and carry on. **Publishing is never a precondition for closing the ledger.** 6d's exit artifact is the printed log plus the work-doc on disk, so a runtime that cannot publish still finishes the sprint, which is what stops this from becoming the portability bug [references/runtime-adapters.md](../runtime-adapters.md) forbids. Field-by-field guidance, voice rules, and a worked example: `references/finish.md` "Step F (Update log)".

**Invoking the summary on demand.** The update log runs any time via `/hackify:summary` or phrase trigger ("show summary", "summarize", "summary table", "show me what changed"). Mid-flight invocation prints to chat; Step F also appends to the work-doc.

**Ledger, at phase exit.** 6a and 6b each tick on their own exit artifact, one line of reflection first (what changed, did it pass, what is next), then the tick and the next item opening as one edit to the work-doc's section 0, then the re-print. **6c and 6d are the one exception: they tick together, in a single edit, and that same edit writes `status: done`.** Write it only once Step F has printed the update log, since that edit is itself what produces 6d's other artifact, the finished doc, and let the `git mv` follow as the last mechanical step, so no moment exists in which the doc sits under `done/` with a row still open. An item that does not apply (no worktree, no entry point) is ticked with a one-line reason, never deleted. The task is done when that closing edit and its move have both landed, not when the summary is printed. Full contract: [../phase-ledger.md](../phase-ledger.md), "Closing the ledger".

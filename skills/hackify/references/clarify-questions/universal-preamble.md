# Universal preamble

Runs before any task-type bank on every Phase 1. Settles the four cross-cutting logistics answers that every downstream bank assumes are already decided. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Runs before any task-type bank, on every Phase 1. Sets the four cross-cutting logistics answers that every downstream bank assumes are already settled: scope shape, isolation strategy, test discipline, and done-state. Skip questions whose answers are already implied by the user's prompt or pinned in `CLAUDE.md`.

**COMPOSITION**

- If the user's prompt explicitly names a scope ("just this one file", "all over the codebase"), skip Q1 (Scope check).
- If the user is already on a branch named for the task, skip Q2 (Worktree) and confirm in the preamble. Also skip if the user prompt contains the literal substring `this branch`, `in place`, or `just push`.
- If `CLAUDE.md` or the task-type bank pins a test discipline (e.g. TDD mandatory), skip Q3 (Tests).
- Always ask Q4 (Done state) unless the user has explicitly stated PR vs merge intent in the prompt.
- Always ask Q5 (Goal & guardrails) FIRST, it seeds the Primary Goal & Guardrails anchor. Skip only when the north-star goal AND any non-goals are already unambiguous from the prompt; then restate them in the preamble for a one-line confirmation instead of asking.
- **"Prepend this bank" means Q5 leads, not the whole file.** Q5 (Goal & guardrails) opens the first batch. Q1 through Q4 are logistics (scope, workspace, tests, done state) and go in the LAST batch, after the matched bank's domain questions. This is the canonical batch order and the other files point here for it: goal first, then what the thing actually is, then where it goes and how it ships. Asking where to put the work before settling what the work is means asking about the wrong feature, and the user answers it seriously because the question looks reasonable.

**QUESTIONS**

Every question below is a TEMPLATE. Substitute the real names, files and current behavior you found before sending it, so the user can answer without opening anything. Angle-bracket slots are yours to fill. `What happens:` lines are mandatory and are what the user reads.

Q1. Is this on its own or part of something bigger
- Text: Is `<the thing they asked for>` a standalone piece of work, or one step in something larger you already have in flight?
- Header: Scope
- Options:
  - A. Just this, on its own (Recommended)
    - What happens: I focus only on this and don't try to fit it into a bigger plan.
  - B. It's part of something bigger already underway
    - What happens: I'll look at the related work first and match how it was done, so the two fit together.
  - C. It's the first step of something bigger
    - What happens: I'll build it so the next pieces slot in easily, rather than as a one-off.
- Why-this-matters: Determines whether the work-doc is standalone or links to a parent plan via the `related` frontmatter field, and whether Phase 2 surveys neighboring work before drafting.

Q2. Where the work should happen
- Text: Should I do this on a separate copy of your project so your current branch stays untouched, or work directly where you are now (you're on `<current branch name>`)?
- Header: Workspace
- Options:
  - A. Separate copy, keep my current branch clean (Recommended)
    - What happens: Your current work is untouched. When it's done you review it and decide whether to bring it in.
  - B. Work right here on this branch
    - What happens: Changes appear in your working folder straight away. Faster, but mixed in with whatever else you have going.
- Why-this-matters: Triggers (or skips) the worktree-creation step in Phase 2 and changes how Phase 6 finishes (merge vs push-and-PR).

Q3. How much testing
- Text: How much automated testing do you want around this? Writing the test first is slower up front but is the only way to know the test actually catches the problem.
- Header: Testing
- Options:
  - A. Write the test first, then the code (Recommended)
    - What happens: I write a test that fails, then make it pass. Slower to start, but you get proof it really works.
  - B. Write the code first, then cover it with tests
    - What happens: Quicker to see something working. The tests still get written before I call it done.
  - C. No automated test, I'll click through it myself
    - What happens: I'll list the exact steps for you to check by hand. Nothing guards against it breaking again later.
- Why-this-matters: Sets each task's test mode and decides whether Phase 3 fans out a RED-GREEN implementer or a build-then-verify one.

Q4. What you want at the end
- Text: When the work is finished, what should be waiting for you?
- Header: Handover
- Options:
  - A. The changes ready on a branch for you to look at (Recommended)
    - What happens: Nothing goes live. You read it over and merge when you're happy.
  - B. A pull request opened for you or your team to review
    - What happens: Same code, but with a written summary and a place for others to comment.
  - C. Merged straight into the main branch
    - What happens: It lands directly. Choose this only if you're comfortable with it going in unreviewed.
- Why-this-matters: Sets Phase 6's exit action and whether release artifacts (CHANGELOG, tag) are generated. Recommend A when the diff is ≤3 files OR ≤200 added lines; B for larger or cross-team diffs; C ONLY when the user prompt contains the literal substring `ship it`, `merge it`, `commit and push`, or `merge directly`.

Q5. Anything I must not break
- Text: Is there anything that must keep working exactly as it does now, no matter what? For example `<name 1-2 real things you spotted, e.g. "existing users staying logged in" or "the nightly export">`.
- Header: Must not break
- Options:
  - A. Nothing specific, use your judgment (Recommended)
    - What happens: I'll protect anything that looks important and tell you before touching something risky.
  - B. Yes, let me name them
    - What happens: Whatever you name becomes a hard line I won't cross, and I check against it before finishing.
  - C. I'm not sure, tell me what you think is at risk
    - What happens: I'll list what this change could affect and you confirm before I start.
- Why-this-matters: Fills the Guardrails/Invariants part of the Primary Goal & Guardrails anchor ([../goal-anchor.md](../goal-anchor.md)), enforced by the Phase 2.5 and Phase 5 drift-checks. A violated guardrail is a Critical finding.

**EXIT CRITERIA**

Q1, Q5 each answered or explicitly skipped per COMPOSITION rules; scope sentence, worktree decision, test mode, and done-state recorded in the work-doc preamble; the Primary Goal & Guardrails anchor (north-star goal + any non-goals) seeded from Q5; no answer left as free-text without being reduced to one of A/B/C/D semantics.

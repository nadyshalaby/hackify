# Universal preamble

Runs before any task-type bank on every Phase 1. Settles the four cross-cutting logistics answers that every downstream bank assumes are already decided. See [wizard-contract.md](wizard-contract.md) for the canonical 4-section spec.

**SCENARIO**

Runs before any task-type bank, on every Phase 1. Sets the four cross-cutting logistics answers that every downstream bank assumes are already settled: scope shape, isolation strategy, test discipline, and done-state. Skip questions whose answers are already implied by the user's prompt or pinned in `CLAUDE.md`.

**COMPOSITION**

- If the user's prompt explicitly names a scope ("just this one file", "all over the codebase"), skip Q1 (Scope check).
- If the user is already on a branch named for the task, skip Q2 (Worktree) and confirm in the preamble. Also skip if the user prompt contains the literal substring `this branch`, `in place`, or `just push`.
- If `CLAUDE.md` or the task-type bank pins a test discipline (e.g. TDD mandatory), skip Q3 (Tests).
- Always ask Q4 (Done state) unless the user has explicitly stated PR vs merge intent in the prompt.

**QUESTIONS**

Q1 — Scope check
- Text: Is this a one-off task or part of a larger initiative I should align with?
- Header: Scope
- Options:
  - A. One-off task (Recommended)
  - B. Part of a larger initiative — align with it
  - C. Start of a larger initiative — set up scaffolding
- Why-this-matters: Determines whether the work-doc is standalone or links to a parent plan, and whether Phase 2 surveys neighboring work before drafting.

Q2 — Worktree
- Text: Work in an isolated git worktree or in-place on the current branch?
- Header: Worktree
- Options:
  - A. Isolated worktree on a new branch (Recommended)
  - B. In-place on the current branch (task <30 min, already on right branch)
- Why-this-matters: Triggers (or skips) the worktree-creation step in Phase 2 and changes how Phase 6 finishes (merge vs. push-and-PR).

Q3 — Tests
- Text: Which test discipline applies for this task?
- Header: Tests
- Options:
  - A. Test-first per task (Recommended)
  - B. Test-after acceptable
  - C. Manual smoke acceptable (visual-only)
- Why-this-matters: Decides whether Phase 3 fans out a RED→GREEN sub-agent or a build-then-verify sub-agent.

Q4 — Done state
- Text: What does "done" mean for this task?
- Header: Done state
- Options:
  - A. Branch left for your review (Recommended)
  - B. PR opened, awaiting your merge
  - C. Merged to main directly
- Why-this-matters: Sets Phase 6's exit action (push only / open PR / merge) and whether release artifacts (CHANGELOG, tag) are generated. Recommended option A (Branch left for your review) applies when diff is ≤3 files OR ≤200 added lines; recommend B (PR opened) for larger diffs or cross-team changes; recommend C (Merged to main directly) only when the user prompt contains the literal substring `ship it`, `merge it`, `commit and push`, or `merge directly`.

**EXIT CRITERIA**

Q1–Q4 each answered or explicitly skipped per COMPOSITION rules; scope sentence, worktree decision, test mode, and done-state recorded in the work-doc preamble; no answer left as free-text without being reduced to one of A/B/C/D semantics.

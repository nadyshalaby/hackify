# Work-Doc Template

Drop this skeleton into `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` at the start of Phase 2, or at graduation on the groom path, which creates the same file before Phase 1. Fill it as you go through phases. Keep frontmatter accurate, it is the resume contract.

> **Back-compat for older work-docs.** Archived work-docs using the prior section names (`Definition of Done`, `Tasks`, `Implementation Log`, `Verification`, `Post-mortem`) remain readable, `skills/hackify/SKILL.md`'s resume-mode rule (authored by T1.4a) accepts either label set. New work-docs use the sprint vocabulary above.

---

```markdown
---
slug: 2026-05-03-add-invitation-expiry
title: Add invitation expiry to closed sign-up
status: clarifying
type: feature
created: 2026-05-03
project: <your-project-name>
related: []
current_task: null
worktree: null
branch: null
sprint_goal: |
  One- to two-sentence sprint goal, the headline outcome the work-doc commits to.
---

# Add invitation expiry to closed sign-up

## 0. Phase ledger

<!-- Opened as a printed block at task start, written here at Phase 2 step 1. Whoever creates this file writes this block into it first, so on the groom path groom writes it, Phase 1 adopts it, and Phase 2 step 1 confirms it rather than writing it again. `- [ ]` open, `- [>]` the single in-progress item, `- [x]` done. Re-print this block at every phase boundary. -->

- [ ] Phase 1. Clarify (lock the goal anchor)
- [ ] Phase 2. Plan + Gate (work-doc + user "go")
- [ ] Phase 2.5. Spec review (1 reviewer, patch the doc)
- [ ] Phase 3. Implement (all waves committed)
- [ ] Phase 4. Verify (Evidence Ledger + triad green)
- [ ] Phase 5. Review (decision table empty)
- [ ] Phase 6a. Re-verify + land choice (Steps A, C)
- [ ] Phase 6b. Cleanup sweep (Step C.5)
- [ ] **Phase 6c. Archive work-doc to `done/` (Step D)**
- [ ] Phase 6d. Update log + HTML report (Step F)

<!-- Section-order law. This skeleton is the authority on section order, every other file agrees with it. `## 0. Phase ledger` is ALWAYS the first block of the body; nothing else takes that slot. On the groom path only, `## Groom Provenance` sits HERE, between section 0 and section 1, and holds the groom distillation and nothing else. -->

## 1. Original ask

> [paste the user's request VERBATIM, in a blockquote]

## Primary Goal & Guardrails

The north-star this task is measured against. Captured in Phase 1, enforced by the drift-check in Phase 2.5 (the spec reviewer) and Phase 5 (Reviewer B). See [goal-anchor.md](goal-anchor.md).

- **North-Star Goal.** [one sentence, the single outcome this task commits to]
- **In-Scope.** [bullets of work this task WILL do, the boundary]
- **Out-of-Scope / Non-Goals.** [bullets this task will explicitly NOT do]
- **Guardrails / Invariants.** [properties the solution must never violate, a Critical if broken]
- **Success Signals.** [the observable proofs Phase 4 will paste]

## 2. Clarifying Q&A

### Q1 ([topic])
**Question:** [what you asked]
**Answer:** [exact user reply, summarised only if it was very long]

### Q2 ([topic])
...

## 3. Acceptance Criteria

A short, verifiable checklist. Each item must be testable or observable.

- [ ] [verifiable outcome 1]
- [ ] [verifiable outcome 2]
- [ ] [verifiable outcome 3]
- [ ] All tests pass (unit + integration), 0 failures
- [ ] Lint clean, typecheck clean
- [ ] Original ask demonstrably met (manual smoke or automated proof)

## 4. Approach

≤200 words. Lead with the chosen path, then the 1-2 alternatives considered, then the rationale.

**Chosen.** [Approach A, one paragraph]

**Considered & rejected.**
- [Approach B], rejected because [reason]
- [Approach C], rejected because [reason]

**Architectural touchpoints.** [files/modules this will modify]

### Repo Brief

Built at the end of Phase 2, before the gate. ≤200 words. Passed verbatim as `{{repo_brief}}` to every implementer and every reviewer so no agent re-derives it. Every fact here must be one you verified this session. See [repo-brief.md](repo-brief.md).

- **Stack:** [language / runtime / framework / package manager]
- **Commands:** test `[verbatim]`, lint `[verbatim]`, typecheck `[verbatim]`
- **Layout:** [where each layer lives, one line]
- **Layering rule:** [the one boundary that matters here]
- **Rules source:** [which rule file governs, and who wins on conflict]
- **Test convention:** [where tests live, what they are named]
- **Landmines:** [facts an agent would get wrong on its own]

## 5. Sprint Backlog

Flat checklist. One commit per task. Each task is 5-30 minutes of focused work.

Each task SHOULD carry a `→ verify: <one-line check>` suffix stating the gate that proves it landed. The verify line is the per-task analogue of the top-level Acceptance Criteria checklist; it lets the implementer agent ship and self-confirm without waiting on the parent for cross-task confirmation.

- [ ] **T1**, [task name]: [1-line description]. Files: `<path/a>`, `<path/a.test>`. → verify: `<one-line check>` (test command, grep, file existence, etc.).
- [ ] **T2**, [task name]: ...
- [ ] **T3**, ...

After Phase 2.5 the Approach section carries an **Execution waves** block: one line
per wave, each naming its dispatch batches. A batch is the set of same-module tasks
one implementer takes together, capped at 3; a task with no module sibling is a batch
of one. Phase 5 builds `{{task_file_index}}` from this block plus each task's Files
list, so the block is what makes both the implementer dispatch and the reviewer
scope checkable.

```
Execution waves
W1: [T1, T3] auth module; [T2] solo
W2: [T4, T5, T6] billing; [T7] solo
```

## 6. Daily Updates

Append one entry per task as you complete (or get stuck on) it.

### T1 ([task name], done 2026-05-03 14:22)

- **Test mode:** test-first (business logic) | test-after | manual smoke | none (rationale: ...)
- **Notes:** [any decisions made, deviations from the plan, surprises]
- **Self-review:** ✓ DRY  ✓ types  ✓ layering  ✓ no suppressions  ✓ edge cases  ✓ no scope creep
- **Verification:**

  ```
  [paste the fresh test/lint/typecheck output for this task]
  ```

- **Commit:** `<sha>`, `<commit message>`

### T2 ([task name], in progress)
- ...

## 7. Sprint Review (Phase 4 / 5)

### Evidence Ledger (Phase 4)

One row per Sprint Backlog task AND per Acceptance-Criteria bullet. Proof sample is a real, trimmed slice of output, never a summary. Each scout's staging table (or its "no candidates" result) is itself a row ([perf-scout.md](perf-scout.md), [law-scout.md](law-scout.md)), and the three ship-gate rows are mandatory ([ship-gate.md](ship-gate.md)). See [review-and-verify.md](review-and-verify.md).

| Item | Type | Claim | What I ran | Proof sample | Result |
|---|---|---|---|---|---|
| T1 | task | [what it asserts] | `<command>` | `<trimmed real output>` | ✅ |
| AC1 | acceptance | [what it asserts] | `<command>` | `<trimmed real output>` | ✅ |
| scout.perf | protocol | no Critical/Important candidates | perf-scout over the diff | `<trimmed table / none>` | ✅ |
| scout.law | protocol | no Critical/Important candidates | law-scout over the diff | `<trimmed table / none>` | ✅ |
| ship.build | runtime | builds clean from a cold cache | `<build command>` | `<trimmed real output>` | ✅ |
| ship.boot | runtime | boots and reports ready | `<start command>` + readiness probe | `<trimmed real output>` | ✅ |
| ship.smoke | runtime | touched flow works against the running app | `<smoke command>` | `<trimmed real output>` | ✅ |

**Three-layer re-verify:** Layer 1 fresh triad ✅ · Layer 2 goal-drift re-check (every Success Signal has a proving row) ✅ · Layer 3 independent re-prove ✅.

### DoD checklist with evidence

- [ ] **All tests pass**
  ```
  $ <test runner command>
  [paste output]
  ```
- [ ] **Lint clean**
  ```
  $ <linter command>
  [paste output]
  ```
- [ ] **Typecheck clean**
  ```
  $ <typecheck command>
  [paste output]
  ```
- [ ] **[DoD bullet 1]**, [evidence: command, output, screenshot reference, or short script]
- [ ] **[DoD bullet 2]**, [evidence]

### Scope ledger (Phase 5)

One row per changed path, written BEFORE the reviewer wave is dispatched. This is the artifact that makes "every file was covered" checkable instead of asserted, and it is what a carried-over verdict is checked against in the settle round. `blob` is `git rev-parse HEAD:<path>`, the content hash, never the path alone: a file touched in round 1, fixed in round 2 and touched again would otherwise carry a verdict that was never about the bytes now on disk. Mandatory whenever carry-over is used. See [review-scope.md](review-scope.md).

| path | blob | lenses | round 1 | settle |
|---|---|---|---|---|
| src/auth/session.ts | a3f91c2 | A B F | clean | carried |
| src/ui/Button.tsx | 7d20e14 | B E | 2 findings | re-read |

### Self-review (Phase 5)

The reviewer panel replaces this section. Every row the old self-review table carried
(DRY, layering, named types, lint suppressions, size caps, dead code, edge cases,
error handling, security, perf) is checked by a reviewer that cites file:line and a
verbatim rule sentence for each finding. A hand-ticked table beside that is the same
audit done twice, once with evidence and once without. Record the panel's outcome in
the decision table and the scope ledger above; do not restate it here.

### Reviewer subagent feedback (if escalated)

- **Critical:** none / [list]
- **Important:** none / [list]
- **Minor:** none / [list, fix now if cheap, else add to Retrospective]

## 8. Retrospective

3-8 bullets. What surprised. What to remember for future sprints. Pointers to follow-up work.

- …
- …
- Follow-up: `<scheduled-routine-or-issue-ref>` (if any)
```

---

## Frontmatter field reference

| Field | Values | Meaning |
|---|---|---|
| `slug` | `kebab-case`, ≤6 words | Stable id for resume |
| `title` | free text | Human-readable |
| `status` | `clarifying` / `planning` / `implementing` / `debugging` / `verifying` / `reviewing` / `finishing` / `done` | Phase the doc is currently in |
| `type` | `feature` / `fix` / `refactor` / `revamp` / `redesign` / `debug` / `research` | Drives clarify questionnaire |
| `created` | ISO date `YYYY-MM-DD` | When work-doc was opened |
| `project` | repo folder name (e.g. `my-backend`) | Anchors paths |
| `related` | list of slugs | Cross-project linked docs |
| `current_task` | `T<n>` or `null` | Where to resume |
| `worktree` | absolute path or `null` | If using git worktree |
| `branch` | branch name or `null` | Git branch the work lives on |
| `sprint_goal` | YAML block scalar (`|`) or `null` | One- to two-sentence sprint goal, the headline outcome the work-doc commits to |

## Naming conventions

- **Slug.** Date prefix only when the doc is *created* (yyyy-mm-dd). Slug body is concise: `2026-05-03-add-invitation-expiry`, not `2026-05-03-feature-to-add-invitation-expiry-to-the-closed-signup`.
- **Cross-project tasks.** Create one doc per project; mirror the Sprint Backlog across them; link via `related` frontmatter. Don't try to make one doc span repos, each project has its own commit/PR cadence.
- **Branch name.** `<type>/<slug>`, e.g. `feature/add-invitation-expiry`, `fix/oauth-state-leak`.

## What NOT to put in the work-doc

- Conversation transcripts.
- Long architectural essays, keep the Approach section ≤200 words. If you need depth, link to a `<project>/docs/architecture/<topic>.md` file.
- Output dumps unrelated to the DoD evidence.
- Speculation about future features (those go in the Retrospective as follow-ups, with explicit ownership).

# Work-Doc Template

Drop this skeleton into `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` at the start of Phase 2. Fill it as you go through phases. Keep frontmatter accurate — it is the resume contract.

> **Back-compat for older work-docs.** Archived work-docs using the prior section names (`Definition of Done`, `Tasks`, `Implementation Log`, `Verification`, `Post-mortem`) remain readable — `skills/hackify/SKILL.md`'s resume-mode rule (authored by T1.4a) accepts either label set. New work-docs use the sprint vocabulary above.

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
  One- to two-sentence sprint goal — the headline outcome the work-doc commits to.
---

# Add invitation expiry to closed sign-up

## 1. Original ask

> [paste the user's request VERBATIM, in a blockquote]

## 2. Clarifying Q&A

### Q1 — [topic]
**Question:** [what you asked]
**Answer:** [exact user reply, summarised only if it was very long]

### Q2 — [topic]
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

**Chosen.** [Approach A — one paragraph]

**Considered & rejected.**
- [Approach B] — rejected because [reason]
- [Approach C] — rejected because [reason]

**Architectural touchpoints.** [files/modules this will modify]

## 5. Sprint Backlog

Flat checklist. One commit per task. Each task is 5–30 minutes of focused work.

- [ ] **T1** — [task name]: [1-line description]. Files: `path/a.ts`, `path/a.test.ts`.
- [ ] **T2** — [task name]: ...
- [ ] **T3** — ...

## 6. Daily Updates

Append one entry per task as you complete (or get stuck on) it.

### T1 — [task name] — done 2026-05-03 14:22

- **Test mode:** test-first (business logic) | test-after | manual smoke | none (rationale: ...)
- **Notes:** [any decisions made, deviations from the plan, surprises]
- **Self-review:** ✓ DRY  ✓ types  ✓ layering  ✓ no suppressions  ✓ edge cases  ✓ no scope creep
- **Verification:**

  ```
  [paste the fresh test/lint/typecheck output for this task]
  ```

- **Commit:** `<sha>` — `<commit message>`

### T2 — [task name] — in progress
- ...

## 7. Sprint Review (Phase 4 / 5)

### DoD checklist with evidence

- [ ] **All tests pass** —
  ```
  $ bun test
  [paste output]
  ```
- [ ] **Lint clean** —
  ```
  $ bun run lint
  [paste output]
  ```
- [ ] **Typecheck clean** —
  ```
  $ bun run typecheck
  [paste output]
  ```
- [ ] **[DoD bullet 1]** — [evidence: command, output, screenshot reference, or short script]
- [ ] **[DoD bullet 2]** — [evidence]

### Self-review (Phase 5)

| Item | Pass | Notes |
|---|---|---|
| DRY | ✓ | … |
| Layering | ✓ | … |
| Named types | ✓ | … |
| No lint suppressions | ✓ | … |
| File-size caps (≤500 LOC) | ✓ | … |
| Function caps (≤40 LOC, ≤3 params, ≤3 nesting) | ✓ | … |
| Dead code removed | ✓ | … |
| Edge cases covered | ✓ | … |
| Naming for intent | ✓ | … |
| Error handling explicit | ✓ | … |
| No security regressions | ✓ | … |
| No new `!` non-null assertions | ✓ | … |
| No empty catches | ✓ | … |
| No bare `Error` throws in domain code | ✓ | … |

### Reviewer subagent feedback (if escalated)

- **Critical:** none / [list]
- **Important:** none / [list]
- **Minor:** none / [list — fix now if cheap, else add to Retrospective]

## 8. Retrospective

3–8 bullets. What surprised. What to remember next time. Pointers to follow-up work.

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
| `sprint_goal` | YAML block scalar (`|`) or `null` | One- to two-sentence sprint goal — the headline outcome the work-doc commits to |

## Naming conventions

- **Slug.** Date prefix only when the doc is *created* (yyyy-mm-dd). Slug body is concise: `2026-05-03-add-invitation-expiry`, not `2026-05-03-feature-to-add-invitation-expiry-to-the-closed-signup`.
- **Cross-project tasks.** Create one doc per project; mirror the Sprint Backlog across them; link via `related` frontmatter. Don't try to make one doc span repos — each project has its own commit/PR cadence.
- **Branch name.** `<type>/<slug>` — e.g. `feature/add-invitation-expiry`, `fix/oauth-state-leak`.

## What NOT to put in the work-doc

- Conversation transcripts.
- Long architectural essays — keep the Approach section ≤200 words. If you need depth, link to a `<project>/docs/architecture/<topic>.md` file.
- Output dumps unrelated to the DoD evidence.
- Speculation about future features (those go in the Retrospective as follow-ups, with explicit ownership).

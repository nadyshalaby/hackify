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
- [ ] Phase 6a. Re-verify + land choice (Steps A, B, C)
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

Built at the end of Phase 2, before the gate. ≤350 words. Passed verbatim as `{{repo_brief}}` to every implementer and every reviewer so no agent re-derives it. **Every line ends with the command or `file:line` that proved it**, after the arrow; a line with nothing after the arrow is a guess and does not go in. See [repo-brief.md](repo-brief.md).

- **Stack:** [language / runtime / framework / package manager] ← [command]
- **Commands:** test `[verbatim]`, lint `[verbatim]`, typecheck `[verbatim]` ← [ran this session, the result line]
- **Layout:** [where each layer lives, one line] ← [command]
- **Layering rule:** [the one boundary that matters here] ← [file:line]
- **Rules source:** [which rule file governs, and who wins on conflict] ← [command]
- **Test convention:** [where tests live, what they are named] ← [command]
- **Landmines:** [facts an agent would get wrong on its own] ← [file:line]

## 5. Sprint Backlog

Flat checklist. One commit closes the whole round, never one per task and never one per wave, so a task is one clean step inside that commit. A round holding one wave is the same rule with one wave in it. Each task is 5-30 minutes of focused work.

Each task SHOULD carry a `→ verify: <one-line check>` suffix stating the gate that proves it landed. The verify line is the per-task analogue of the top-level Acceptance Criteria checklist; it lets the implementer agent ship and self-confirm without waiting on the parent for cross-task confirmation.

- [ ] **T1**, [task name]: [1-line description]. Files: `<path/a>`, `<path/a.test>`. → verify: `<one-line check>` (test command, grep, file existence, etc.).
- [ ] **T2**, [task name]: ...
- [ ] **T3**, ...

After Phase 2.5 the Approach section carries an **Execution waves** block, written
round by round: one line per wave, naming that wave's task IDs in run order. Phase 3
runs it in three stages. A **foundation wave** goes first, on its own, and takes
every contended write in the round, the shared files, registries and generated
sequences that two or more tasks would otherwise reach for at the same time. Then
the **module tracks** run concurrently, one agent each, and a track carries its own
tasks all the way to DONE rather than handing a half-built module on. An **assembly
wave** closes the round, on its own again, and does the mounting, the cross-track
reconcile and a real boot of the assembled system.

**The shape scales, and both ends of it are ordinary.** A round with no contended
write has no foundation wave to run, and a round with one track has nothing to
assemble. The stage that does not apply is marked complete with a written reason,
the way a skipped phase is, and never dropped in silence, so a later reader can tell
a stage that had no work from a stage nobody ran. A two-file change therefore looks
the way it always has: one wave, one agent, no ceremony bought for it.

Whether a round's tasks may be split across concurrent tracks at all is settled by
the partition test in [contention-dispatch.md](contention-dispatch.md),
all three of its conditions, and never by how large the round happens to look.
Phase 5 builds `{{task_file_index}}` from this block plus each task's Files list, so
the block is what makes both the implementer dispatch and the reviewer scope
checkable.

```
Execution waves

Round 1 (foundation, solo)
W1: T1, T2

Round 2 (3 concurrent tracks)
W2a: T3, T4
W2b: T5
W2c: T6, T7

Round 3 (assembly, solo)
W3: T8
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

### Module briefs (concurrent rounds only)

**Fill this before dispatching a round that holds two or more concurrent tracks,
or the dispatch fails.** `hackify:module-implementer` refuses on any of its
fifteen INPUTS arriving unfilled, and eight of them have no other producer: the
Phase 2.5 wave plan emits wave numbers, task IDs, an agent type and a
concurrency mark, and nothing else names them. One block per track. A round with
one track needs none of this, because a single-track round takes
`hackify:wave-implementer`.

```
#### M<n> <module name>  (tasks T<a>, T<b>)
- module_id:        M<n>
- module_plan_path: <this doc>#m<n>-<module-name>
- folder_allowlist: <one absolute folder per line; disjoint from every sibling's>
- owned_elsewhere:  <shared surface> -> owned by <M<k>|the foundation wave|the assembly wave>
- mandatory_reading: <the architecture-contract sections this module must honour>
- sharp_invariants: <the 2-3 places THIS module is most likely to get wrong>
- database_name:    <the database THIS track creates and owns; never the shared one>
- handoff_contract: <what the assembly wave needs back: registrar to mount, exported names>
```

`folder_allowlist` is where the partition becomes real, so derive it from the
`## Serial resources` table rather than by intuition: any folder two tracks would
both write is a contended write and belongs to the foundation wave instead.
`database_name` is the standard lifting move for a single shared test database,
which is conventionally serial rather than genuinely exclusive.

### Track progress (concurrent rounds only)

A concurrent track does NOT write this file. Four tracks appending to one
markdown file is the shared-file contention the partition exists to remove, and
an append has no lock, no merge and no error when a write is lost. Each track
writes its own `docs/work/<slug>.tracks/<module-id>.md` instead, disjoint by
construction, updated as each unit goes green rather than once at the end. The
parent merges them into `## 6. Daily Updates` at round end and deletes the
folder when the round closes.

**A solo wave writes `## 6. Daily Updates` directly**, because a foundation
wave, an assembly wave and a single-track round have no sibling to collide with,
so there is nothing for the indirection to protect. The mechanism follows the
contention, and where there is none it gets out of the way.

Either way the rule is the same one: **progress reaches disk while the work is
happening, not after it.** A session that dies mid-round leaves a work-doc that
still says what every track had finished.

## 7. Sprint Review (Phase 4 / 5)

### Evidence Ledger (Phase 4)

One row per Sprint Backlog task AND per Acceptance-Criteria bullet. Proof sample is a real, trimmed slice of output, never a summary. Each scout's staging table (or its "no candidates" result) is itself a row ([perf-scout.md](perf-scout.md), [law-scout.md](law-scout.md)), and the three ship-gate rows are mandatory ([ship-gate.md](ship-gate.md)). See [review-and-verify.md](review-and-verify.md).

| Item | Type | Claim | What I ran | Proof sample | Result |
|---|---|---|---|---|---|
| T1 | task | [what it asserts] | `<command>` | `<trimmed real output>` | ✅ |
| AC1 | acceptance | [what it asserts] | `<command>` | `<trimmed real output>` | ✅ |
| scout.perf | protocol | perf-scout ran at BOTH Phase 3 run points and every candidate carries a disposition | perf-scout twice: each wave agent over its OWN file allowlist before it returned, then the parent at round end over what that round's waves DECLARED | `<trimmed table / none, one per run point>` | ✅ |
| scout.law | protocol | law-scout ran at BOTH Phase 3 run points and every candidate carries a disposition | law-scout twice: each wave agent over its OWN file allowlist before it returned, then the parent at round end over what that round's waves DECLARED | `<trimmed table / none, one per run point>` | ✅ |
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

One row per changed path, written BEFORE the reviewer wave is dispatched. This is the artifact that makes "every file was covered" checkable instead of asserted. It used to carry a `blob` content hash as well, because a verdict could be carried from one round into the next and a path-keyed carry-over would carry it across a file that had changed twice. The panel runs once now, so nothing carries and the hash has nothing left to prove. See [review-scope.md](review-scope.md).

| path | lenses | verdict |
|---|---|---|
| src/auth/session.ts | A B F | clean |
| src/ui/Button.tsx | B E | 2 findings |

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

## Update log

Written at Phase 6 Step F and appended by the closing edit, never in an edit of its own. One block
per change the user would recognise, five fields in this order, separated by a line of `----`.

### [what changed, in the user's words]

**Problem.** …
**Root cause.** …
**Solution.** …
**Verification evidence.** …
**Deployment status.** …
```

---

## Current-shape conformance

What "current shape" means for a work-doc, read off the skeleton above rather than off any
other file. `skills/hackify/SKILL.md`'s Pause / Resume migration step points here instead of
restating it, so the shape is written down in exactly one place, the one that IS the shape.

A doc is at the current shape when all six hold:

1. **Section 0 is the first body block.** `## 0. Phase ledger` sits between the title and
   `## 1. Original ask`, one row per phase. On the groom path `## Groom Provenance` is the only
   thing allowed between those two, per the section-order law in the skeleton.
2. **The goal anchor is present.** `## Primary Goal & Guardrails`, all five parts.
3. **The Repo Brief is present.** `### Repo Brief` inside `## 4. Approach`, every line ending in
   the command or `file:line` that proved it.
4. **The section labels are the skeleton's own, in the skeleton's order**, spelled the way the
   skeleton spells them: Original ask, Clarifying Q&A, Acceptance Criteria, Approach, Sprint
   Backlog, Daily Updates, Sprint Review (Phase 4 / 5), Retrospective, Update log. A doc still
   carrying a prior label is renamed to its current one by the migration edit. The back-compat
   note at the top of this file names the prior labels; the back-compat bullet under Pause /
   Resume in `skills/hackify/SKILL.md` is where the two sets are listed side by side.
5. **The frontmatter carries every key the `Frontmatter field reference` table below declares**,
   and that table is the authority on the key list AND on each key's allowed values. Take the
   list from nowhere else: check `[99]` reads the `status` row out of that same table, so a key
   or a value sourced from prose somewhere is a claim no check enforces.
6. **`status` agrees with the directory the doc sits in.** `done` belongs under
   `docs/work/done/`, every other declared value belongs at the live path. This point goes
   past what the task that first wrote this list enumerated, and it is kept deliberately
   rather than by oversight. Check `[99]`'s assertion (c) already holds this repo's own
   tracked docs to half of it, which settles that the rule is a shape invariant and not a
   preference. But that check reads this plugin's tree and nothing else,
   and its `judge_status` reader fires in one direction only, on a doc claiming `done` from
   outside the archive. Resume runs inside the user's project, where no check of ours ever
   looks, so the migration edit is the only place this invariant can be applied at all: drop
   the point and a doc marked finished, left sitting at the live path, resumes with the
   contradiction intact. Point 5 above cites `[99]` for the other half of that check, the
   status vocabulary row, and the two halves are separate assertions.

**Archived docs under `docs/work/done/` are exempt from all six.** An archived work-doc is a
record of what somebody believed at the time, and rewriting it destroys the only thing it is
for. Read it as it stands and change nothing.

---

## Frontmatter field reference

| Field | Values | Meaning |
|---|---|---|
| `slug` | `kebab-case`, ≤6 words | Stable id for resume |
| `title` | free text | Human-readable |
| `status` | `clarifying` / `planning` / `implementing` / `debugging` / `verifying` / `reviewing` / `finishing` / `paused` / `done` | Phase the doc is currently in. `paused` is the one value that names no phase: it says the work stopped at whichever phase it had reached |
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

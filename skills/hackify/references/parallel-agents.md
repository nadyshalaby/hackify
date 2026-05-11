# Parallel Agents — When and How to Fan Out

User preference (default): **always spawn foreground parallel agents to speed development, code reviews, spec self-reviews, and verification.** When 2+ pieces of work are independent, dispatch them in parallel in **one message** so they run concurrently.

This file is the dispatch playbook. Use it any time hackify is about to do multiple independent things.

---

## When to fan out (yes)

- **Phase 1 research** — different parts of the codebase, different reference docs, different open questions. One agent per question.
- **Phase 2.5 spec self-review** — three reviewers in parallel scrutinize the work-doc for inconsistent / conflicting logic before code is written (consistency / architectural risk / dependency-and-parallelism). MANDATORY before Phase 3.
- **Phase 3 implementation waves** — group tasks by dependency, dispatch each wave's tasks to one agent each in a single message. **Tasks in the same wave MUST NOT share files.** This is what makes parallel implementation safe.
- **Phase 4 verification across packages** — backend + frontend + shared package; one agent per package runs `test && lint && typecheck` in parallel.
- **Phase 5 multi-reviewer** — three foreground reviewers in parallel: security/correctness, quality/layering, plan-consistency/scope. MANDATORY for any non-trivial diff.
- **Phase 3b debug evidence** — multi-component bug; one agent per boundary instruments + logs.
- **Multi-project work** — task touches multiple sibling projects (e.g. a backend repo AND a frontend repo); one agent per repo runs the same investigation or implementation wave in its own scope.

## When NOT to fan out

- **Tasks that share a file** — concurrent edits cause conflicts. The wave planner MUST split same-file tasks across waves.
- **Tightly-coupled investigations** — when finding A informs question B, run sequentially.
- **Tasks that need shared state** — they'll race.
- **One-line typo / config-only diffs** — multi-reviewer is overkill. Self-review is enough.
- **When a single agent is sufficient** — don't fan out for theatre. Two parallel agents have overhead.

---

## Dispatch pattern (one message, multiple Agent tool calls)

When firing N agents in parallel, put N `Agent` tool calls in **one assistant message**. Don't fire one, wait, fire another.

Foreground (default): the parent (hackify) waits for all N to complete before continuing. **This is what we want** — not background.

Use **`run_in_background: false`** explicitly if you want to be sure. Foreground is also the default.

---

## Per-task templates

These templates use **relative reference paths** like `references/review-and-verify.md`. The plugin's skill layout puts every reference file in `<plugin>/skills/hackify/references/`, so relative refs travel cleanly across machines. For project-specific rule files (a workspace or project `CLAUDE.md`), pass the **absolute path** dynamically — let hackify substitute the actual path at dispatch time.

### Spec self-review (Phase 2.5)

Dispatch THREE in one message. Each gets the work-doc absolute path and a different lens. Parent aggregates findings into Critical / Important / Minor and patches the work-doc.

```
Subagent type: general-purpose

Reviewer A — Internal consistency
  Read the work-doc end-to-end at <absolute path to docs/work/<slug>.md>.
  Find contradictions between Original Ask, Q&A, DoD, Approach, and Tasks:
  - DoD bullets not covered by any task
  - Tasks not motivated by any DoD bullet
  - Q&A answers that the Approach contradicts
  - Two Q&A answers that contradict each other
  Output: severity-tagged list (Critical / Important / Minor). Cap ≤300 words.

Reviewer B — Architectural / cross-cutting risks
  Read the work-doc + the project's CLAUDE.md (absolute path: <project>/CLAUDE.md)
  and the user-global CLAUDE.md (~/.claude/CLAUDE.md) if present.
  Flag anything in the plan that would force:
  - a lint suppression
  - a non-null `!`
  - an inline `interface`/`type` with ≥2 props in a forbidden file
  - a layering violation (routes doing business logic, services importing the HTTP
    framework, components doing fetches, etc.)
  - a bare `Error` throw in domain code
  - a security regression (cookies, OAuth, secrets, CORS)
  Output: severity-tagged list. Cap ≤300 words.

Reviewer C — Dependency / ordering / parallelism risks
  Read the Tasks list in the work-doc.
  Build a dependency graph: for each task list (a) which files it CREATES or
  MODIFIES (best-guess from the description), and (b) which earlier tasks must
  finish first.
  Flag:
  - Tasks that share a file → must NOT be in the same parallel wave
  - Missing prerequisite tasks (e.g., service consumed before it's created)
  - Ordering bugs in the Tasks list
  - Tasks too coarse (>30 min of work) — request split
  - Tasks too fine (<5 min) — request merge
  Output: a proposed wave plan (Wave 1: T1+T6+T10 // Wave 2: T2+...) plus
  severity-tagged issues. Cap ≤400 words.
```

### Implementation wave (Phase 3)

Dispatch ONE agent per task in the wave, in a SINGLE assistant message (multiple `Agent` calls in parallel). Each prompt is fully self-contained.

```
Subagent type: general-purpose
Foreground (run_in_background: false — default)

You are implementing exactly ONE task from a hackify work-doc.

Work-doc: <absolute path>
Task ID: T<n>
Task description (verbatim from work-doc): <copy>
Files you may CREATE or MODIFY (and ONLY these):
  - <file path 1>
  - <file path 2>
  - <test file path>
Test mode: [test-first | test-after | manual smoke | none] — <reason>

Workspace rules (binding):
  - Honor the user-global ~/.claude/CLAUDE.md if present.
  - Honor the project's CLAUDE.md at <project>/CLAUDE.md if present.
  - Hard caps: ≤40 LOC/fn, ≤3 params, ≤3 nesting, ≤500 LOC/file, 0 lint
    suppressions, 0 `!` non-null, 0 empty catches, 0 inline types ≥2 props
    in *.routes.ts / *.service.ts / *.middleware.ts.

If test mode is test-first:
  1. Write the failing test in the test file listed.
  2. Run only the test command scoped to that file (e.g.
     `bun test path/to/file.test.ts`). Watch it FAIL with the right error.
  3. Write minimum code in the source file to make it pass.
  4. Run again. See it pass.
  5. Run the file-scoped lint + typecheck.

If test mode is test-after / manual / none, document why in your report.

Constraints:
  - Do NOT modify any file outside the list above. If you discover you need
    to, STOP and report — do not edit it.
  - Do NOT run repo-wide commands (`bun test`, `bun run lint`, etc.). The
    parent will run those for the wave.
  - Do NOT commit. The parent will commit the wave.
  - Self-review against the skill's references/review-and-verify.md
    (relative to the hackify skill root) before reporting done.

Report (≤200 words):
  - Files touched
  - Test mode used + RED→GREEN evidence (1-line)
  - Self-review pass/fail per checklist item (compact)
  - Any deviations from the work-doc Approach (NONE if straightforward)
  - Anything you flagged but did not fix (out-of-scope tweaks, follow-ups)
```

After all wave agents return:
1. Read every report. Spot-check that no agent touched files outside its list (`git diff --name-only` — should match the union).
2. Run repo-wide `bun test && bun run lint && bun run typecheck` ONCE (substitute your project's actual commands).
3. If any are red — classify: agent failure (re-dispatch the offending task with a sharper prompt) vs. plan failure (drop to Phase 3b).
4. Tick all wave checkboxes. Append one Implementation Log entry per task.
5. Single commit for the wave (subject covers the wave; body lists task IDs).

### Multi-reviewer (Phase 5)

Dispatch THREE in one message. Same diff range; different lenses.

```
Subagent type: general-purpose (× 3)

Reviewer A — Security & correctness
  Project: <project name and absolute path>
  Diff range: <BASE_SHA>..<HEAD_SHA>. Run `git diff <BASE_SHA>..<HEAD_SHA>`
  to read the diff.
  Read the work-doc at <absolute path>.

  Lenses to apply:
  - Auth flows: cookies, sessions, OAuth state, invitation tokens, role checks
  - Permission boundaries: every route/endpoint has the right guard
  - Injection: SQL string concat, path traversal, command injection
  - PII / secrets: no hardcoded secrets, no PII in logs, no leaked tokens
  - Migrations: idempotent, guarded by existence checks, reversible-or-OK
  - Race conditions: concurrent writes, cache invalidation, transaction
    boundaries

  Output: Critical / Important / Minor severity. file:line for each. Cap ≤400 words.

Reviewer B — Quality & layering
  (same project / diff / work-doc context as A)

  Lenses to apply:
  - DRY: no duplicated logic; existing helpers reused
  - Named types: every shape ≥2 props named in the right folder
  - Layering: routes pure / services own DB / components dumb / lib glue only
  - Hard caps: ≤40 LOC/fn, ≤3 params, ≤3 nesting, ≤500 LOC/file
  - Lint suppressions, `!` non-null, empty catches, bare `Error` throws — must be 0 new
  - Dead code, unused exports, orphan TODOs

  Output: Critical / Important / Minor. file:line per item. Cap ≤400 words.

Reviewer C — Plan consistency & scope
  (same project / diff / work-doc context as A and B)

  Lenses to apply:
  - Every DoD bullet — does the diff actually deliver it?
  - Every Tasks checkbox — does the diff match the task description?
  - Anything in the diff that's NOT in the Tasks list = scope creep
  - Anything in the Tasks list that's NOT in the diff = incomplete
  - Any inconsistency with the Q&A answers (e.g., user said 'soft archive only'
    but the diff includes a hard-delete path)

  Output: Critical / Important / Minor. Map each finding to a DoD bullet or task ID.
  Cap ≤300 words.
```

For diffs with a 4th distinct concern (e.g., a heavy UX/visual change layered on top of backend changes), add a 4th reviewer focused on that lens. Cap at 4.

### Research (Phase 1)

```
Subagent type: Explore (read-only — recommended for research)
Prompt skeleton:

  Goal: [the question]
  Context: [enough background that the agent can make judgment calls]
    - workspace at <absolute path to workspace root>
    - project: <project name>
    - related files I think are involved: [list, or "Grep says X is the entry point"]
    - what I've already ruled out: [list]

  Find and read the key files. Report:
    - Where the answer lives (file:line)
    - The current behavior in 1-3 sentences
    - Any patterns or conventions I should mirror
    - What you're NOT sure about (so I can verify)

  Cap response at <N> words. Be direct, no filler.
```

### Verification across packages (Phase 4)

```
Subagent type: general-purpose (needs to run commands)
Prompt skeleton:

  Goal: Run the full verification suite in <project> and report.

  Steps:
    1. cd <absolute path to project>
    2. Run `bun test` (or the project's test command). Capture full output.
    3. Run `bun run lint` (or the project's lint command). Capture full output.
    4. Run `bun run typecheck` (or the project's typecheck command). Capture full output.

  Report:
    - PASS or FAIL for each
    - If FAIL, paste the relevant failure output (not the whole stream)
    - If PASS, the summary line is enough

  Do not modify any code. If a command needs to be installed first
  (e.g. test:browser:install), STOP and report — I'll handle setup.
```

### Code review (Phase 5)

```
Subagent type: general-purpose
Prompt skeleton:

  Review a diff for a [feature|fix|refactor|redesign] in <project>.

  The work-doc lives at <absolute path to docs/work/<slug>.md>.
  Diff range: <BASE_SHA>..<HEAD_SHA>.

  Run `git diff <BASE_SHA>..<HEAD_SHA>` to see exactly what's in scope.

  Stack: <e.g. Bun + Hono + Drizzle + Postgres | Vite + React 19 + shadcn/ui + Tailwind v4 | other>

  Review against:
  - The work-doc's Definition of Done — does the diff actually deliver each bullet?
  - The self-review checklist at <plugin>/skills/hackify/references/review-and-verify.md
  - Project rules: read <project>/CLAUDE.md (if present) AND the user-global
    ~/.claude/CLAUDE.md (if present). Apply the stricter rule on conflict.

  Pay special attention to: [auth | migrations | crypto | API contracts | etc.]

  Output by severity:
    - Critical (bugs, security, data loss, broken functionality, scope creep)
    - Important (architecture, missing tests, error handling, layering violations)
    - Minor (style, naming nits, doc gaps)

  Be technically precise. If a category is empty, say so.
```

For diffs that genuinely have **two distinct concerns** (e.g., a security/auth surface + a UX/visual surface), dispatch **two reviewers in the same message** — one with the prompt focused on the security side, one on the UX side. They'll independently catch different issues.

### Debug evidence gathering (Phase 3b)

```
Subagent type: Explore for read-only investigation, general-purpose if it needs to run code

Prompt skeleton:

  Goal: Verify whether <component X> is the source of <bug>.

  Hypothesis: <stated hypothesis from the work-doc>

  Investigate:
  1. Read <files involved>
  2. Trace the value of <variable>: where it's set, where it's read,
     under what conditions
  3. Check whether <specific failure path> is reachable

  Constraints:
  - Read-only (do NOT modify code)
  - Stay scoped to <module>; don't spelunk the whole repo

  Report:
  - Yes/No: hypothesis is consistent with the code
  - Evidence (file:line)
  - Anything that contradicts the hypothesis
```

---

## Conflict resolution after parallel agents return

When N agents return with overlapping or contradictory findings:

1. **Read all reports first** before reacting. Don't act on agent #1's conclusion before #2 returns.
2. **Compare evidence, not opinions.** Whichever report has the more grounded evidence wins.
3. **If reports contradict**, prefer the agent that pointed to specific file:line over the agent that gave a general claim.
4. If still unclear, fire one more focused agent with the conflicting claim attached: *"agent A says X, agent B says Y; here's the evidence — which is right?"*

---

## Anti-patterns

- Sending agent #1, waiting, sending agent #2 — that's serial dressed as parallel. Send both in one message.
- Dispatching agents to "find answers" without enough context to ground the search — they'll generalize and waste tokens. Always include: workspace path, project, what you've ruled out, what you suspect, what files you think are involved.
- Dispatching agents to edit **the same file** in the same wave — file conflicts. The wave planner is what prevents this; if two tasks share a file, push one to a later wave.
- Dispatching agents to edit code in parallel **without a per-agent file allowlist** — without "you may only modify these files", agents drift. Always pin the file list.
- Dispatching agents to do **the same thing twice** for "redundancy" — they'll come back with similar answers and you've doubled the cost. Multi-reviewer dispatches different *lenses* on the same diff — that's not redundancy.
- Forgetting agents can't see the conversation history. Their prompt MUST be self-contained.
- Skipping spec self-review because "the plan looks fine" — the plan looks fine to the author; the parallel reviewers look at it from angles the author can't.

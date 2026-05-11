# Hackify

> One end-to-end dev workflow for every task in Claude Code.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-informational.svg)](.claude-plugin/plugin.json)
[![Claude Code](https://img.shields.io/badge/claude--code-plugin-7c3aed.svg)](https://www.anthropic.com/claude-code)

## The pitch

Claude Code projects accumulate ceremony fast. A separate spec skill, a separate plan skill, a separate brainstorm skill, a separate execute skill, a separate verify skill, a separate review skill, a separate finish skill — each with its own files, its own conventions, its own places to lose state between sessions. Most of the friction is plumbing, not thinking.

Hackify collapses that ceremony into **one workflow and one markdown work-doc per task**. The work-doc is the spec, the plan, the progress tracker, the review log, and the post-mortem — all in a single file at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`. Pause any time. Resume by saying "continue work on `<slug>`".

The workflow itself is opinionated and expert-led: a batched clarifying questionnaire up front, a hard gate before any code is written, parallel-agent dispatch as the default for spec review and implementation, mandatory multi-reviewer code review on non-trivial diffs, and a definition-of-done that demands fresh verification output before anyone is allowed to say "done."

Be honest about what it isn't. Hackify is not an auto-pilot. It will not silently invent answers when the ask is ambiguous — it will stop and ask. It is not a replacement for human judgment on the plan; the only mandatory gate sits there on purpose, between Plan and Implement, waiting for you to say "go."

A tiny example. You type:

> add expiry to invitation tokens

The assistant recognizes a non-trivial build task, invokes `/hackify:hackify`, asks four clarifying questions in a wizard (default expiry window, behavior on expired token, migration strategy, UI surface), drafts a work-doc, shows it to you, and waits for sign-off before touching code.

## Install

Install from the published GitHub marketplace:

```text
/plugin marketplace add nadyshalaby/hackify
/plugin install hackify@hackify-marketplace
```

Verify by typing `/hackify:hackify` — or just describe a real task. The plugin self-triggers on any non-trivial prompt: building, fixing, refactoring, redesigning, debugging, or "let's discuss this idea before we build."

For local development against a cloned copy:

```text
/plugin marketplace add /path/to/cloned/hackify
/plugin install hackify@hackify-marketplace
```

The slash command is namespaced as `/hackify:hackify` to match the plugin name. `resume <slug>` continues a paused work-doc; `<ask>` starts a new one.

## When to use

Hackify is the default for any substantive prompt. Concretely, it triggers on:

- "Add `<feature>`."
- "Fix this bug."
- "Refactor `<module>`."
- "Redesign the toolbar."
- "Debug the failing test."
- "Migrate `<package>` to `<new version>`."
- "Discuss this idea before we build."

Carve-outs where the workflow is optional:

- Trivial factual Q&A ("what does `Array.prototype.flat` do?").
- One-line typo fixes with no behavioral impact.
- Pure read-only inspection that will not lead to writing, editing, committing, or shell side effects.

When in doubt, invoke. A redundant skill load costs almost nothing; a missed one ships broken work.

## The six phases

```text
Phase 1: Clarify     → batched wizard questionnaire
Phase 2: Plan        → work-doc draft → HARD GATE → user signs off
Phase 2.5: Spec      → parallel reviewers scrutinize the plan
Phase 3: Implement   → parallel waves of foreground subagents
    └─ 3b Debug      → 4-phase root-cause hunt (only if stuck)
Phase 4: Verify      → DoD checklist + fresh evidence
Phase 5: Review      → parallel multi-reviewer (security + quality + scope)
Phase 6: Finish      → 4 options → archive work-doc
```

### Phase 1 — Clarify

Classify the task as one of `feature`, `fix`, `refactor`, `revamp`, `redesign`, `debug`, or `research`. The classification picks the right question bank from `references/clarify-questions.md`. Read just enough context to ask sharp questions — entry points, the symbol's call sites, the module top-to-bottom for a focused edit.

Send one batched questionnaire through the `AskUserQuestion` wizard. Up to four questions per call, two to four options each, with the recommended option always first and labeled `(Recommended)`. Long questionnaires fan out across multiple back-to-back wizard calls in the same turn. Plain numbered lists in chat are forbidden for clarify questions.

No code, no edits, no test runs in Phase 1. The output is a list of locked answers — nothing else.

### Phase 2 — Plan + hard gate

Draft the work-doc at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`. Required sections at this point: Original Ask (verbatim), Clarifying Q&A (verbatim), Definition of Done in 3 to 7 verifiable bullets, Approach in under 200 words explaining the chosen path and the one or two sentence rationale, and a flat task list where each task is 5 to 30 minutes of work.

Task granularity is enforced. "Add invitation expiry" becomes "Add `expires_at` column and migration," "Reject expired tokens in service," "Show expired state in UI," "Backend test," "Frontend test." No "TBD," no "implement error handling later," no "similar to T2." One commit per task is the default.

Show the user the doc and ask: *Sign off on this plan or call out anything to change?* Wait for an explicit "go" / "approved" / "yes" before Phase 2.5 begins. This is the only mandatory human gate — Phase 2.5 spec review and Phases 3 through 6 run automatically afterward, with progress reports at each transition.

### Phase 2.5 — Spec self-review

Three foreground reviewers run in parallel in a single message:

- **Reviewer A — Internal consistency.** Finds contradictions across Q&A, DoD, Approach, and Tasks. Flags DoD bullets with no task and tasks with no DoD bullet.
- **Reviewer B — Architectural and cross-cutting risk.** Matches the plan against project code-quality rules. Flags anything that would force a lint suppression, an `!`, an inline type, a bare `Error` throw, or a layering violation.
- **Reviewer C — Dependency and parallelism risk.** Builds a quick dependency graph from the task list. Flags tasks that share a file, missing prerequisites, ordering bugs, and tasks too coarse for the 5 to 30 minute window.

Findings are tagged Critical, Important, or Minor. Critical and Important are patched in place. Minor goes into the post-mortem. Phase 2.5 is non-skippable, even for small docs — exactly the small docs that hide a contradictory Q&A pair.

### Phase 3 — Implement

Build a wave plan first. For each task, list the files it creates or modifies and the earlier tasks it depends on. Sort by priority and topological dependency. Group into waves where every task in a wave has no file overlap and no intra-wave dependency. Tasks in wave N may only depend on results from waves 1 through N minus 1.

Per wave: set `current_task` in the work-doc frontmatter, dispatch one foreground subagent per task in a single message, wait for all agents to return, aggregate their reports, and run the full project verification once for the wave. Each agent's prompt carries a file allowlist, scoped commands, and the test mode for the task (test-first for business logic, test-after for glue, manual smoke only when the user opts in).

If anything is red, classify: agent failure (re-dispatch with a sharper prompt) versus plan failure (drop to Phase 3b). Never paper over. On green, commit once for the wave with a conventional-commit message whose body lists task IDs.

### Phase 3b — Debug

Triggered by two failed fix attempts on the same task, a test failure whose message does not match the expected error, or a regression appearing while implementing something else. Do not try a third blind fix.

Four-phase root-cause hunt: gather evidence at every component boundary and trace the bad value to its source, find a working analogue in the codebase and list every difference, write down one hypothesis and make the smallest change to test it, then write a failing test that reproduces the bug and fix the source — not the symptom.

Circuit breaker: after three failed hypotheses, stop. That is an architectural problem, not a failed hypothesis. Document the dead ends in the work-doc and surface to the user.

### Phase 4 — Verify

Re-run tests, lint, and typecheck fresh — do not trust earlier output. Paste the command output (exit code, failure count, error count) into the work-doc Verification section. Walk every Definition-of-Done bullet and attach evidence — output, screenshot reference, or a short verifying script.

Zero tolerance for new lint suppressions (`biome-ignore`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error`), new non-null `!` assertions in production code, stray `console.log` or `println!` debug statements, commented-out code, or `TODO` comments without owners. Any red light loops back to Phase 3 or 3b — never to Phase 5.

### Phase 5 — Review

Three foreground reviewers in parallel by default — security and correctness, quality and layering, plan-consistency and scope. A fourth is added for multi-concern diffs that touch both UI and a backend migration, with a cap of four (diminishing returns past that).

Critical findings are fixed before merging. Important findings are fixed before claiming Phase 6 done. Minor findings either get fixed now if cheap or land as a follow-up entry in the post-mortem. Self-review against the 14-item checklist in `references/review-and-verify.md` still happens — the parallel reviewers are additive defense, not replacement.

Push back on reviewer feedback only with technical evidence — never performative agreement. If a reviewer is wrong for this codebase, say so with reasoning.

### Phase 6 — Finish

Re-run verification one more time. Pre-merge state can drift. Then present exactly four options, no open-ended choice:

1. Merge to the base branch locally (default for small in-place changes).
2. Push and create a PR (default for cross-team or larger changes).
3. Keep the branch as-is (work pauses, no cleanup).
4. Discard this work (requires the user to type "discard" verbatim — no shortcut).

For merge or PR, the commit message follows the project convention and ends with the Claude Code Co-Authored-By trailer. The work-doc moves from `<project>/docs/work/<slug>.md` to `<project>/docs/work/done/<slug>.md`, the frontmatter `status` is set to `done`, and the Post-mortem section is filled with 3 to 8 bullets — what surprised, what to remember next time.

## The work-doc

The work-doc is the single source of truth for a task. It lives at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` while in flight and moves to `<project>/docs/work/done/<slug>.md` after Phase 6.

Frontmatter holds `slug`, `title`, `status`, `type`, `created`, `project`, `current_task`, `worktree`, and `branch`. The body sections are Original Ask, Clarifying Q&A, Definition of Done, Approach, Tasks, Implementation Log, Verification, and Post-mortem.

State lives in the file. There is no companion JSON, no hidden in-conversation memory. Pause any time — close the laptop, switch projects, come back next week. Resume by saying "continue work on `<slug>`" and the assistant will read the frontmatter, find the next unchecked task, and pick up exactly there. If the doc is older than two weeks the assistant will check `git log` to see whether the codebase moved out from under the plan before continuing.

## Parallel agents

Parallelism is the default, not the exception. Whenever there are two or more independent pieces of work — spec review, implementation tasks in the same wave, code review concerns, cross-package verification, multi-boundary debug evidence — hackify dispatches foreground subagents in a single message and waits for the whole batch.

The safety property that makes this work is a **strict file allowlist** baked into every agent's prompt. The wave planner groups tasks so no two tasks in the same wave touch the same file; each agent's prompt says "you may only modify these files — if you find you need anything else, stop and report." Combined with wave-based dependency ordering, parallel implementation stops being scary and becomes the obvious default. The dispatch templates live in `references/parallel-agents.md`.

## What's in the box

```text
.claude-plugin/
  plugin.json                    plugin manifest
  marketplace.json               self-hosted marketplace entry
skills/hackify/
  SKILL.md                       the workflow itself
  references/
    work-doc-template.md         markdown skeleton for every task
    clarify-questions.md         per-task-type question banks for Phase 1
    implement-and-test.md        TDD walkthrough, per-stack test commands
    debug-when-stuck.md          4-phase root-cause hunt for Phase 3b
    review-and-verify.md         DoD, 14-item self-review, escalation rules
    finish.md                    Phase 6 — 4 options, archive, worktree cleanup
    frontend-design.md           visual law (loaded on FE / UI / design tasks)
    code-rules.md                DRY, named types, layering deep dive
    parallel-agents.md           parallel subagent dispatch templates
  evals/
    evals.json                   optional eval harness
```

Reference files are loaded only when the relevant phase needs them. The skill keeps context lean — `SKILL.md` is what the assistant reads on every invocation; the rest comes in on demand.

## Design principles

A few opinionated calls shape every phase:

- **One file, not many.** The work-doc replaces a spec doc, a plan doc, a progress file, a review log, and a post-mortem. One file is easier to keep current than five.
- **Clarify everything up front.** A batched questionnaire before any code is written catches misreads while they are cheap. A clarifying question asked in Phase 3 has already cost an implementation pass.
- **One hard gate, not many.** Between Plan and Implement. After sign-off the workflow runs continuously through verification and review, with progress reports — not gates — at each transition. Interrupt any time.
- **Parallel by default.** Wave-based dependency ordering plus file allowlists make parallel implementation safe. Sequential is the exception, reserved for tightly-coupled investigations.
- **Evidence before claims.** No bullet on the Definition of Done is checked without fresh command output, a screenshot reference, or a verifying script in the work-doc.
- **Multi-reviewer is the floor.** A single lens always misses something. Three reviewers in parallel — security, quality, scope — are the default for any non-trivial diff.
- **The plan is the contract.** No scope creep. No cleanup of adjacent code on the side. No abstractions invented for hypothetical futures. If something needs doing that the plan does not cover, surface it.

## Stack assumptions

The reference rules ship with the author's stack baked in: Bun as the package manager, Biome as the linter and formatter, two-space indent, single quotes, no semicolons. That stack is documented in `references/code-rules.md` and is explicitly framed as **substitute your own**. Swap in npm or pnpm, ESLint or Prettier, four-space indent — the workflow does not care.

What does carry across stacks are the principles: DRY enforced by searching before writing, named types for any object shape with two or more properties, strict layer separation, zero lint suppressions, zero non-null assertions in production code, every function under 40 lines, every file under 500 lines, and edge cases handled rather than hoped away.

If your project has a `CLAUDE.md` at workspace or project root, hackify honors its rules first. The bundled `code-rules.md` is the fallback when no project rules exist.

## FAQ

**Does hackify work for tiny tasks like fixing a typo?**
No. One-line typo fixes are an explicit carve-out. The workflow is for anything with even modest ambiguity — if a reasonable person could read your prompt two different ways, hackify is the right tool.

**What if I don't have a `CLAUDE.md` in my project?**
The plugin works without one. It falls back to the principles in `references/code-rules.md` — DRY, named types, layering, no inline suppressions, the size caps. You can add a `CLAUDE.md` later and hackify will honor it.

**Does hackify lock me into Bun, Biome, or TypeScript?**
No. Those are the author's reference stack, documented as a starting point. The phases, the gate, the parallel-agent dispatch, the verification rigor, the multi-reviewer pass — none of that is tied to a language or toolchain. Edit `references/code-rules.md` after install to match your stack.

**What's the difference between this and the superpowers plugin?**
Hackify is self-contained. It does not depend on superpowers or any other plugin. It folds clarify, plan, execute, verify, review, and finish into one workflow with one work-doc per task instead of asking you to wire several skills together.

**Can I customize the phases?**
Yes. The workflow is plain markdown — there is no compiled logic to subclass. Edit `SKILL.md` after install, or fork the plugin. The reference files (`clarify-questions.md`, `parallel-agents.md`, `review-and-verify.md`, and the rest) are all designed to be edited.

**How are the parallel subagents safe?**
Two mechanisms. First, each agent's prompt carries a strict file allowlist — the agent is told the exact files it may touch and is instructed to stop if it discovers it needs another file. Second, the wave planner groups tasks so no two agents in the same wave share a file or have an intra-wave dependency. Tasks in wave N may only depend on results from waves 1 through N minus 1.

**What's the work-doc for, really?**
It's the persistent state across sessions. The chat transcript is throwaway; the work-doc is durable. Pause any time. When you come back — next hour, next week — the assistant reads the frontmatter and the latest Implementation Log entry and knows exactly where you left off. Saying "continue work on `<slug>`" is enough.

**What if I disagree with a reviewer's feedback?**
Push back with technical evidence — never performative agreement. If a reviewer is wrong for the codebase (YAGNI, missing context, bad pattern fit), the response template in `references/review-and-verify.md` shows how to disagree with reasoning rather than capitulating.

**Does the plugin call other plugins or skills?**
No. Hackify is intentionally self-contained. Third-party plugins may not be installed; the workflow does not assume any. All design law, TDD discipline, debugging method, verification rigor, and review checklists are inlined in `SKILL.md` or one of the bundled reference files.

**What happens if I interrupt mid-implementation?**
The work-doc holds state. Implementation Log entries are written per task, so the next session reads the latest entry and picks up at the next unchecked checkbox. Interrupting during a parallel wave is safe — the parent waits for all dispatched agents to return before writing log entries, so partial state does not leak into the doc.

**Does the workflow support monorepos with multiple sub-projects?**
Yes. Each sub-project (for instance, your backend and frontend repos) is its own git repo with its own `docs/work/` directory. When a task spans multiple projects, create one work-doc in each and link them via the `related` field in the frontmatter. Phase 4 verification fans out across packages by default — one agent per package.

**What if a task turns out to need a file outside its allowlist?**
The agent stops and reports back rather than editing the file. The parent decides: either re-dispatch with a widened allowlist, or split the work into a follow-up task in the next wave. The allowlist is the contract that makes parallel implementation safe.

## Troubleshooting

**`This plugin uses a source type your Claude Code version does not support.`**
Update Claude Code (`claude --upgrade` or via your package manager) and retry.

**`No ED25519 host key is known for github.com and you have requested strict checking.`**
Add GitHub's host fingerprints to your trusted hosts file:

```bash
ssh-keyscan -t ed25519,rsa,ecdsa github.com >> ~/.ssh/known_hosts
```

Idempotent; safe to re-run.

**`Permission denied (publickey).`**
The clone is going over SSH and your machine's SSH key isn't registered with GitHub. The plugin clones over HTTPS by default, so this only triggers when local git config rewrites HTTPS to SSH. Either remove the rewrite, or register an SSH key with GitHub.

**Plugin doesn't appear after install.**
Run `/reload-plugins` (or restart Claude Code). The skill registers as `/hackify:hackify` and also auto-triggers when you describe any non-trivial dev task.

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/nadyshalaby/hackify). The most useful bug reports include the work-doc that demonstrates the failure — the file already captures the original ask, the plan, the implementation log, and the verification output, so it is usually most of the repro by itself.

Feature requests are most useful when they describe the motivating workflow gap: what task were you running, where did hackify get in the way or fail to help, and what would have unblocked you. Concrete pain beats abstract preferences.

## License

MIT. See [LICENSE](LICENSE).

---

If hackify saves you from one mis-spec'd implementation pass, it has already paid for itself. Open an issue if it didn't.

<div align="center">

# Hackify

**One end-to-end dev workflow for every task in Claude Code.**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.3.3-7c3aed.svg)](.claude-plugin/plugin.json)
[![Claude Code](https://img.shields.io/badge/claude--code-plugin-1f2937.svg)](https://www.anthropic.com/claude-code)
[![Keep a Changelog](https://img.shields.io/badge/changelog-keep--a--changelog-orange.svg)](CHANGELOG.md)

Clarify → Plan → Implement → Verify → Review → Finish — anchored to a single markdown work-doc per task.

<br/>

<img src="docs/assets/hackify-demo.gif" alt="Hackify 6-phase workflow — Clarify, Plan, Implement, Verify, Review, Finish" width="820" />

</div>

---

## Overview

Hackify replaces multi-skill ceremony (separate spec, plan, groom, execute, verify, review, and finish skills) with **one workflow and one work-doc per task**. The work-doc is the spec, the plan, the progress tracker, the review log, and the post-mortem — all in a single file at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`. Pause whenever. Resume by saying *"continue work on `<slug>`"*.

The workflow is opinionated and expert-led: a batched clarifying questionnaire up front, a hard gate before any code is written, parallel-agent dispatch as the default for spec review and implementation, mandatory multi-reviewer code review on non-trivial diffs, and a definition-of-done that demands fresh verification output before anyone may say *"done"*.

For small fixes and single-file edits, a sibling skill `/hackify:quick` runs a compressed four-phase flow that stays in quick mode until you explicitly promote to full hackify. When you trust the pipeline enough to skip the plan-gate and finish menu, `/hackify:yolo` runs the same workflow on full autopilot.

## Install

```text
/plugin marketplace add nadyshalaby/hackify
/plugin install hackify@hackify-marketplace
```

Verify with `/hackify:hackify` — or simply describe a task. Hackify auto-triggers on any non-trivial prompt.

**Local development** against a cloned copy:

```text
/plugin marketplace add /path/to/cloned/hackify
/plugin install hackify@hackify-marketplace
```

## Three flows, one discipline

| Skill | Slash command | When to use |
|---|---|---|
| **Full hackify** | `/hackify:hackify` | Any substantive task: features, refactors, redesigns, debug investigations, migrations, multi-file changes, security-sensitive work. **The default.** |
| **Hackify YOLO** | `/hackify:yolo` | Substantive task where you trust the pipeline and don't want to gate on plan sign-off or finish menu. Full discipline; auto-passes Phase 2 + Phase 6. No work-doc → no pause/resume. |
| **Quick hackify** | `/hackify:quick` | Small bug fixes, one- to three-line edits, single-file polish, typo work, direct quick-effort requests. Compressed four-phase flow. |

All three skills auto-trigger from natural-language prompts — no need to invoke them by slash unless you want to be explicit.

**Plugin primitives** (since v0.2.2). Hackify ships five first-class harness primitives, each owning a separate concern. `skills/` — the workflows (full hackify, quick, yolo, groom, skillsmith, review-triage, codewalk) plus `lawkeeper` (a full-codebase engineering-rules auditor). `rules/` — always-on engineering law (`hard-caps.md` injected every prompt via hook; `code-quality.md` loaded by skills on demand). `agents/` — formal sub-agent definitions for Phase 2.5 spec reviewers, Phase 3 wave-task implementers, and Phase 5 multi-reviewers (claude-code only; other runtimes use the inline templates in `skills/hackify/references/parallel-agents/`). `hooks/` — `UserPromptSubmit` hook injects hard-caps into context every turn (claude-code only). `commands/` — `/hackify:summary` slash command. Routing between skills is handled by each skill's frontmatter `description` field via the harness's native auto-discovery — no prompt-based classifier.

## The workflow

```
┌──────────────────────────────────────────────────────────────────────┐
│ Phase 1   Clarify     batched wizard questionnaire                   │
│ Phase 2   Plan        work-doc draft ─ HARD GATE ─ user signs off    │
│ Phase 2.5 Spec        parallel reviewers scrutinize the plan         │
│ Phase 3   Implement   parallel waves of foreground subagents         │
│   └─ 3b   Debug       4-phase root-cause hunt (only if stuck)        │
│ Phase 4   Verify      DoD checklist + fresh evidence                 │
│ Phase 5   Review      parallel multi-reviewer (security/quality/scope)│
│ Phase 6   Finish      4 options → archive work-doc → summary table   │
└──────────────────────────────────────────────────────────────────────┘
```

The **only** mandatory user gate is between Plan and Spec review. After sign-off, Phases 2.5 through 6 run continuously with progress reports — not gates — at each transition. Interrupt any time; the work-doc holds state.

### Phase notes

- **Phase 1 — Clarify.** Task is classified as `feature`, `fix`, `refactor`, `revamp`, `redesign`, `debug`, or `research`; the classification picks the right question bank. Questions ship through the `AskUserQuestion` wizard, never as plain markdown lists.
- **Phase 2 — Plan + gate.** Work-doc fills out: Original Ask (verbatim), Clarifying Q&A, Definition of Done (3–7 verifiable bullets), Approach (≤200 words), and a flat task list where each task is 5–30 minutes of work. No `TBD`, no `similar to T2`, no placeholders.
- **Phase 2.5 — Spec self-review.** Three parallel reviewers (internal consistency, architectural risk, dependency/parallelism risk) patch contradictions before any code is written. Non-skippable — small docs are exactly where contradictions hide.
- **Phase 3 — Implement.** Tasks group into dependency-ordered **waves**; every task in a wave has no file overlap and no intra-wave dependency, so the wave dispatches as one parallel batch of foreground subagents. Each agent carries a strict file allowlist.
- **Phase 3b — Debug.** Triggered by ≥2 failed fix attempts or a regression. Four-phase root-cause hunt (gather evidence → find analogue → form hypothesis → reproduce in a failing test). Circuit-breaker after 3 failed hypotheses.
- **Phase 4 — Verify.** Tests, lint, and typecheck re-run fresh; output pasted into the work-doc. Zero tolerance for new lint suppressions, new non-null `!` assertions, stray debug prints, or commented-out code.
- **Phase 5 — Review.** Three parallel reviewers (security/correctness, quality/layering, plan-consistency/scope) dispatched in one message. Mandatory for any non-trivial diff. Self-review against the 14-item checklist is additive, not replacement.
- **Phase 6 — Finish.** Re-verify, present four explicit options (merge / push & PR / keep as-is / discard), archive the work-doc to `docs/work/done/`, and print the **Step F summary table** — a 2-column Area/Change recap of everything shipped.

## Quick mode

`/hackify:quick` is the compressed-flow sibling. It runs four phases:

```
Phase 1 (clarify if ambiguous) → Phase 3 (implement) → Phase 4 (verify) → Phase 6F (summary table)
```

Plan + Gate, Spec self-review, Multi-reviewer, and the four-options finish menu are skipped. Step F (the summary table) is the only Phase 6 piece kept. At most **one** implementation subagent is dispatched.

### User-initiated promotion to full hackify

Quick mode never auto-promotes. The user explicitly triggers promotion by saying any of these phrases (case-insensitive, most recent message only):

- `switch to full` / `go to full mode` / `promote to full`
- `/hackify:hackify` (explicit slash command)
- `do full review` / `run Phase 5` / `run multi-reviewer`

On promotion, quick mode writes a work-doc from accumulated context (intent, clarify answers, any partial diff) and hands control to full hackify Phase 2 — no half-done state, no lost context. If the user does not promote, quick mode stays in quick mode for the entire task.

### YOLO mode

`/hackify:yolo` is the full-autopilot sibling. Same workflow phases as `/hackify:hackify` — clarify (with exploration), in-chat plan, spec-review, parallel implementation, verify, multi-reviewer, finish — but two gates auto-pass:

- **Phase 2 plan-gate** — no sign-off; the in-chat plan block is posted and Phase 2.5 begins immediately
- **Phase 6 finish menu** — auto-picks Option 1: commit to current branch locally, no push

Phase 5 multi-reviewer findings are auto-fixed in-place at every severity (Critical AND Important); Minor findings logged to chat. You inspect with `git log -1` / `git diff HEAD~1` after the commit lands.

**No work-doc on disk.** YOLO never writes to `docs/work/` — the plan exists only in chat. Close the chat mid-task and progress is gone. Invoke `/hackify:hackify` if you need pause/resume or want to sign off on the plan first.

## Companion skills

Four skills ship alongside `hackify`, `quick`, and `yolo` to cover the bookends, the meta-loop, and onboarding to unfamiliar code:

- **`/hackify:groom <topic>`** — a Socratic pre-task refinement loop for fuzzy, exploratory prompts ("I'm thinking about X, not sure where to start"). It clarifies one question at a time, surfaces tradeoffs, and graduates to full hackify Phase 1 when you signal you're ready to build. Use it instead of jumping straight into `/hackify:hackify` when the ask is still ambiguous.
- **`/hackify:skillsmith`** — authors new hackify-conformant skills (your own or contributions back to the plugin). Runs a 9-check self-validation loop covering frontmatter, trigger phrasing, template-contract conformance, no-leaked-paths, and OUTPUT word caps — the same shape the validator enforces on shipped skills.
- **`/hackify:review-triage`** — structures your response to multi-reviewer findings (Phase 5 output) as a per-finding accept / push-back / defer table, so nothing slips through and every reviewer concern gets an explicit disposition before the work-doc is archived.
- **`/codewalk <entry-point>`** *(since v0.2.8)* — interactive call-stack viewer for code you didn't write. **Deep depth-first walk to leaves** from one entry point (route, handler, CLI command, queue job, UI action) — controller → service → repository → external SDK / SQL leaf, INCLUDING every TypeScript `interface` / `type` / `class` / `enum` / Zod schema / NestJS DTO / TypeORM entity referenced on the path (each emitted as its own `layer: "type"` node, hyperlinked from the function nodes that reference it). Stops cold on runtime ambiguity (env flags, feature gates, tenant guards, DI tokens, dynamic dispatch) — never guesses. Emits a `.codewalk/<slug>/` browser viewer — GitHub-PR-style three-pane layout with invoked-line highlights, clickable call-site anchors that resolve to type/function nodes alike, layered Mermaid sequence diagram, invariants per boundary, failure modes with blast radius, branches not taken listed by name, and an amber diff banner when you re-trace the same entry. Closes with 5 comprehension questions + a `safe to change` / `load-bearing` / `Chesterton's fence` decisions checklist. *(Since v0.3.1)* — a header **theme toggle** (light/dark, persisted via `localStorage`); and a **playbook mode** that fires on "all endpoints" / "every endpoint" / "index playbook" triggers, producing a top-level `.codewalk/index.html` light-mode index of every entry in the service (catalog-driven via `_catalog.json`, each row linkable into its own per-trace viewer). *(Since v0.3.2)* — **deep-by-default mandate** + first-class `layer: "type"` nodes + layer-colored chips in the viewer (controller / service / repository / external / type / other each in a distinct hue).
- **`/lawkeeper`** *(since v0.4.0)* — full-codebase engineering-rules auditor: the detect-and-fix sweep that checks a repo against the laws it is supposed to obey. Resolves the effective rule set from the project's own harness (`.claude/rules`, `ban-patterns.txt`, `CLAUDE.md`/`AGENTS.md`) with stricter-wins fallback to global doctrine — never a duplicate copy. A bundled deterministic scanner does the exact, zero-false-positive checks (file-line cap; lint suppressions, non-null `!`, empty catch, bare `Error`, hardcoded secrets, inline types in scoped modules; `// removed:` markers and ownerless TODO/FIXME), and a semantic subagent pass covers the judgment rules (DRY, layering, SRP, naming, security, performance, testing, full SOLID + YAGNI, cross-file cleanup), reusing the project's installed `.claude/agents/` reviewers when present. Reports every finding with `file:line` grouped by category/severity, then fixes them one at a time with your approval. TS/JS core, `--text-only-ext` for any file, and an ephemeral on-demand scanner for deep non-JS audits. Full-codebase scope — NOT a per-PR diff review (use `/code-review`).

## Example

You type:

> add expiry to invitation tokens

Hackify recognizes a non-trivial build task, invokes `/hackify:hackify`, and asks four clarifying questions through the wizard:

1. Default expiry window — 24h, 7d, 30d, or custom?
2. Behavior on expired token — reject with 410, redirect to a "request a new invite" page, or auto-renew?
3. Migration strategy — backfill existing tokens or treat them as never-expiring?
4. UI surface — show the expiry timestamp in the invite UI, or only on error?

You answer. Hackify drafts the work-doc, presents it, waits for sign-off. Once you say *"go"*, parallel reviewers scrutinize the plan, then dependency-ordered waves of foreground agents implement the change, verify it, run multi-reviewer code review, and finish with the four-options menu and a 2-column Area/Change summary table.

You can pause at any phase by closing the terminal. Later, when you say *"continue work on invitation-token-expiry"*, hackify reads the frontmatter, finds the following unchecked task, and picks up exactly there.

## The work-doc

A single markdown file holds everything about a task: spec, plan, progress, review log, post-mortem. While in flight it lives at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`; after Phase 6 it moves to `<project>/docs/work/done/`.

**Frontmatter:** `slug`, `title`, `status`, `type`, `created`, `project`, `current_task`, `worktree`, `branch`, and (since v0.2.0) `sprint_goal` — a one-sentence framing of the win condition.
**Body** (since v0.2.0 sprint vocabulary): Original Ask → Clarifying Q&A → **Acceptance Criteria** (was Definition of Done) → Approach → **Sprint Backlog** (was Tasks) → **Daily Updates** (was Implementation Log) → **Sprint Review** (was Verification) → **Retrospective** (was Post-mortem). The sections do the same jobs; the labels just align with how teams already talk about work. Pre-v0.2.0 work-docs archived under `docs/work/done/` keep their original headings and resume unchanged — the resume logic reads either vocabulary.

```markdown
---
slug: invitation-token-expiry
title: Add expiry to invitation tokens
status: implementing
type: feature
created: 2026-05-11
current_task: W2:T3
branch: feat/invitation-token-expiry
---

## Acceptance Criteria
- [x] `expires_at` column added; migration is idempotent
- [ ] Expired tokens return 410 Gone with structured error body
- [ ] Frontend shows expiry timestamp on the invite-accept screen
- [ ] Backend + frontend tests pass; coverage held or improved
- [ ] No new lint suppressions, no `!`, no `console.log`

## Sprint Backlog
- [x] T1 — Add `expires_at` column + migration
- [x] T2 — Reject expired tokens in invitations service
- [ ] T3 — Show "expired" state in the accept-invite UI
- [ ] T4 — Backend test
- [ ] T5 — Frontend test
```

State lives in the file. No companion JSON, no hidden in-conversation memory. Resume by saying *"continue work on `<slug>`"* — the assistant reads the frontmatter, finds the following unchecked task, and picks up exactly there. Docs older than fourteen days trigger a `git log` drift check before resuming.

## Slash commands

| Command | Purpose |
|---|---|
| `/hackify:hackify <ask>` | Start a full workflow on a new task. |
| `/hackify:hackify resume <slug>` | Resume a paused work-doc. |
| `/hackify:quick <ask>` | Start the compressed-flow sibling. |
| `/hackify:yolo <ask>` | Start the full-autopilot sibling. |
| `/hackify:summary` | Print the current Area/Change summary table on demand (also responds to *"show summary"*, *"summarize"*, *"summary table"*). |
| `/hackify:groom <topic>` | Start a Socratic pre-task refinement; graduates to full hackify Phase 1 on user signal. |
| `/hackify:skillsmith` | Author new hackify-conformant skills via a 9-check self-validation loop. |
| `/hackify:review-triage` | Structure your response to reviewer findings as a per-finding accept/push-back/defer table. |
| `/codewalk <entry-point>` | Trace one execution path from a single entry point and open a `.codewalk/<slug>/` browser viewer with annotated code + Mermaid diagrams + decisions checklist. Light/dark theme toggle in the header (since v0.3.1); use phrases like *"all endpoints"* / *"index playbook"* to switch to multi-entry playbook mode (since v0.3.1) which produces a top-level `.codewalk/index.html` index of every entry. |
| `/lawkeeper` | Audit the whole codebase against its engineering laws — caps, bans, DRY, layering, SRP, security, performance, testing, SOLID, cleanup. Deterministic scanner + semantic subagents; report by category/severity with `file:line`, then propose-confirm fixes. Reads rules from the project's own harness (stricter-wins vs global). |

## Parallel agents

Parallelism is the default, not the exception. Whenever two or more pieces of work are independent — spec review, implementation tasks in the same wave, code review concerns, cross-package verification, multi-boundary debug evidence — hackify dispatches foreground subagents in a single message and waits for the whole batch.

The safety property that makes this work is a **strict file allowlist** baked into every agent's prompt. The wave planner groups tasks so no two tasks in the same wave touch the same file; each agent is told the exact files it may touch and instructed to stop if it discovers it needs another. Dispatch templates conform to a canonical seven-section contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT) — see [`skills/hackify/references/parallel-agents/template-contract.md`](skills/hackify/references/parallel-agents/template-contract.md) and the subdir index at [`skills/hackify/references/parallel-agents/README.md`](skills/hackify/references/parallel-agents/README.md).

## Repository layout

```text
.claude-plugin/
  plugin.json                          plugin manifest
  marketplace.json                     self-hosted marketplace entry
rules/                                 always-on engineering law (since v0.2.2)
  hard-caps.md                         short doctrine injected every prompt via hook
  code-quality.md                      DRY, named types, layering deep dive (canonical)
agents/                                formal sub-agent definitions (since v0.2.2 — claude-code only)
  spec-reviewer-consistency.md         Phase 2.5 Reviewer A
  spec-reviewer-rules.md               Phase 2.5 Reviewer B
  spec-reviewer-dependencies.md        Phase 2.5 Reviewer C
  code-reviewer-security.md            Phase 5 Reviewer A
  code-reviewer-quality.md             Phase 5 Reviewer B
  code-reviewer-plan-consistency.md    Phase 5 Reviewer C
  wave-task-implementer.md             Phase 3 wave-task implementer
hooks/                                 prompt-time injection (since v0.2.2 — claude-code only)
  hooks.json                           UserPromptSubmit hook declaration
  inject-hard-caps.sh                  injects rules/hard-caps.md into context every prompt
commands/
  summary.md                           /hackify:summary slash command
scripts/
  validate-dod.sh                      CI helper — validates the plugin's own DoD
  sync-runtimes.sh                     fan canonical skills/ into dist/<runtime>/
skills/
  hackify/
    SKILL.md                           the full workflow
    references/
      work-doc-template.md             markdown skeleton for every task
      clarify-questions/               per-task-type question banks (Phase 1) — subdir index in README.md; canonical wizard contract in wizard-contract.md; one bank per task type (feature/fix/refactor/revamp-redesign/debug/research) + universal-preamble + picking-and-combining
      implement-and-test.md            TDD walkthrough, per-stack test commands
      debug-when-stuck.md              4-phase root-cause hunt (Phase 3b)
      review-and-verify.md             DoD + 14-item self-review + escalation
      finish.md                        Phase 6 — options, archive, summary table
      frontend-design.md               visual law (loaded on FE / UI tasks)
      code-rules.md                    forwarding stub → rules/code-quality.md
      parallel-agents/                 parallel subagent dispatch templates (cross-runtime fallback) — subdir index in README.md; canonical 7-section sub-agent contract in template-contract.md; per-phase templates for research, spec review (3), implementation, debug evidence, cross-package verification, multi-review, escalation, aggregation
      runtime-adapters.md              primitive → per-runtime mapping table
    evals/
      evals.json                       optional eval harness
  quick/
    SKILL.md                           /hackify:quick compressed flow
  yolo/
    SKILL.md                           /hackify:yolo full-autopilot sibling
  groom/
    SKILL.md                           /hackify:groom Socratic pre-task refinement
  skillsmith/
    SKILL.md                           /hackify:skillsmith skill authoring + validator
  review-triage/
    SKILL.md                           /hackify:review-triage reviewer-response table
  codewalk/
    SKILL.md                           /codewalk interactive call-stack viewer (single-entry + playbook modes)
    references/
      data-schema.md                   data.json + _catalog.json + _traces.json contracts
      trace-rubric.md                  invoked-block / side-effects / risk / depth-check
    assets/
      index.html                       per-trace viewer shell (Tailwind + Alpine + Prism + Mermaid)
      viewer.js                        Alpine component: navigation, render, theme toggle, tooltips
      viewer.css                       Prism overrides + invoked-line highlight + light-mode block
      serve.js                         Node-stdlib HTTP server (port pick + browser open)
      playbook.html                    multi-entry index page (since v0.3.1)
      playbook.js                      Alpine component for the index (filter + theme)
      playbook.css                     light/dark base styles for the playbook
      build-playbook.mjs               catalog-driven multi-entry builder (since v0.3.1)
  lawkeeper/
    SKILL.md                           /lawkeeper full-codebase engineering-rules auditor
    scripts/                           deterministic scanner (Python: lexer + checks + exemptions + tests)
    references/                        rule-catalog · carve-outs · semantic-pass · porting-scanner
    assets/
      report-template.md               grouped findings report skeleton
dist/                                  generated per-runtime packages (gitignored)
docs/
  work/                                in-flight work-docs (per task)
    done/                              archived work-docs (post Phase 6)
CHANGELOG.md
LICENSE
README.md
```

Reference files load only when the relevant phase needs them. `SKILL.md` is what the assistant reads on every invocation; the rest is on demand.

## Multi-runtime support

Hackify ships (since v0.2.0) for seven runtimes: **Claude Code**, **OpenAI Codex CLI**, **OpenAI Codex App**, **Google Gemini CLI**, **OpenCode**, **Cursor**, and **GitHub Copilot CLI**. The canonical source of every skill lives in `skills/`; `scripts/sync-runtimes.sh` fans that source out into per-runtime packages under `dist/<runtime>/`, which is gitignored.

| Tier | Runtimes | What works |
|---|---|---|
| **Native** | Claude Code, OpenCode | Full plugin/skill semantics: auto-trigger, parallel subagents, file allowlists, wizard tool. |
| **Best-effort** | Codex CLI, Codex App, Gemini CLI, Cursor | Skills shipped as prompts/rules; the workflow runs but some primitives (subagent dispatch, wizard) degrade to inline equivalents. |
| **Not supported** | Copilot CLI | No plugin or skill concept on the runtime side — listed for transparency only. |

The workflow is written in **runtime-neutral primitives** (`wizard tool`, `subagent dispatcher`, `file allowlist`, `slash command`, `reference file`) rather than Claude-specific names. Each runtime's adapter maps those primitives to whatever native or near-native feature exists — see [`skills/hackify/references/runtime-adapters.md`](skills/hackify/references/runtime-adapters.md) for the full mapping table and the degradation notes for the best-effort tier.

**Install — Claude Code (marketplace):**

```text
/plugin marketplace add nadyshalaby/hackify
/plugin install hackify@hackify-marketplace
```

**Install — Codex CLI (prompts directory):**

```bash
bash scripts/sync-runtimes.sh
cp -R dist/codex-cli/* ~/.codex/prompts/
```

`sync-runtimes.sh` writes all 7 runtime packages under `dist/<runtime>/`; copy the one you need. Use `--dry-run` first to preview the file list, or `--help` for usage.

## Design principles

See [`rules/four-principles.md`](rules/four-principles.md) for the canonical write-up of the four working principles — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution — that underpin every phase below.

- **One file, not many.** The work-doc replaces a spec doc, a plan doc, a progress file, a review log, and a post-mortem. One file is easier to keep current than five.
- **Clarify everything up front.** A batched questionnaire before any code is written catches misreads while they are cheap.
- **One hard gate, not many.** Between Plan and Implement. Everything else runs continuously with progress reports.
- **Parallel by default.** Wave-based dependency ordering plus file allowlists make parallel implementation safe.
- **Evidence before claims.** No Definition-of-Done bullet is checked without fresh command output or a verifying script in the work-doc.
- **Multi-reviewer is the floor.** A single lens always misses something. Three reviewers in parallel — security, quality, scope — are the default.
- **The plan is the contract.** No scope creep, no cleanup of adjacent code on the side, no abstractions for hypothetical futures.

## Customization

### Project-level rules

Hackify honors a `CLAUDE.md` at workspace or project root first. The bundled [`rules/code-quality.md`](rules/code-quality.md) is the fallback when no project rules exist. The shorter [`rules/hard-caps.md`](rules/hard-caps.md) is injected into context on every prompt by the (since v0.2.2) `UserPromptSubmit` hook so the function/file/param caps and zero-tolerance bans are always loaded.

### Voice — abstract principles, concrete adaptation

The reference rules are written in language-agnostic voice: package manager, linter, formatter, type system, test runner — never a brand. That voice is documented in [`rules/code-quality.md`](rules/code-quality.md) and is explicitly **substitute your own toolchain** — swap in whatever package manager, linter, formatter, indent width, or quote style your project already uses; the workflow does not care.

What does carry across toolchains are the principles: DRY enforced by searching before writing, named types for any object shape with 2+ properties, strict layer separation, zero lint suppressions, zero non-null assertions in production code, functions ≤40 LOC, files ≤500 LOC, edge cases handled rather than hoped away.

### Editing the workflow

The workflow is plain markdown — no compiled logic to subclass. Edit `SKILL.md` after install, or fork the plugin. Every reference file is designed to be edited.

## FAQ

**Does hackify work for tiny tasks like fixing a typo?**
For one-line typo fixes with no behavioral impact, use the carve-out (no skill needed). For anything with even modest ambiguity, prefer `/hackify:quick`. The four-phase compressed flow is exactly right for small-and-direct work.

**Does hackify lock me into a specific language or toolchain?**
No. The reference rules are written in language-agnostic voice — package manager, linter, formatter, type system, test runner — and you supply the concrete commands for your own stack. The phases, the gate, the parallel-agent dispatch, the verification rigor, the multi-reviewer pass — none of that is tied to a language or toolchain.

**How are the parallel subagents safe?**
Two mechanisms. Each agent's prompt carries a strict file allowlist — the agent is told the exact files it may touch and is instructed to stop if it discovers it needs another. The wave planner groups tasks so no two agents in the same wave share a file. Tasks in wave N may only depend on results from waves 1 through N-1.

**Does the plugin depend on other plugins or skills?**
No. Hackify is intentionally self-contained. All design law, TDD discipline, debugging method, verification rigor, and review checklists are inlined in `SKILL.md` or one of the bundled reference files.

**What happens if I interrupt mid-implementation?**
The work-doc holds state. Implementation Log entries are written per task, so the following session reads the latest entry and picks up at the following unchecked checkbox. Interrupting during a parallel wave is safe — the parent waits for all dispatched agents to return before writing log entries.

**Does the workflow support monorepos?**
Yes. Each sub-project (e.g., backend and frontend repos) is its own git repo with its own `docs/work/` directory. When a task spans multiple projects, create one work-doc per project and link them via the `related` frontmatter field. Phase 4 verification fans out across packages by default — one agent per package.

**What if a task needs a file outside its allowlist?**
The agent stops and reports back rather than editing the file. The parent decides: re-dispatch with a widened allowlist, or split the work into a follow-up task in the subsequent wave.

**Does codewalk work offline, and does it touch my repo's source?**
First load pulls Tailwind, Alpine, Prism, and Mermaid from public CDNs — after that the browser cache serves them, so subsequent traces work offline. The trace itself never modifies repo source; every artifact lands under `.codewalk/<slug>/`, which the skill auto-adds to `.gitignore` so traces stay out of commits.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `This plugin uses a source type your Claude Code version does not support.` | Update Claude Code (`claude --upgrade` or via your package manager) and retry. |
| `No ED25519 host key is known for github.com and you have requested strict checking.` | Run `ssh-keyscan -t ed25519,rsa,ecdsa github.com >> ~/.ssh/known_hosts`. Idempotent; safe to re-run. |
| `Permission denied (publickey).` | Local git config is rewriting HTTPS to SSH. Either remove the rewrite, or register an SSH key with GitHub. |
| Plugin does not appear after install | Run `/reload-plugins` or restart Claude Code. The skill registers as `/hackify:hackify` and auto-triggers on any non-trivial prompt. |
| `/codewalk` says `node: command not found` | Run any one of `python3 -m http.server 8765`, `python -m http.server 8765`, `npx --yes serve -l 8765`, `php -S 127.0.0.1:8765`, or `ruby -run -e httpd . -p 8765` from inside `.codewalk/<slug>/`. The skill prints this fallback chain when it cannot find Node. |
| `/codewalk` viewer doesn't open in the browser | The viewer prints its URL (`http://127.0.0.1:<port>/`) on its own line — copy it into your browser. The default-browser launch is best-effort and may be blocked on headless or remote shells. |
| `/codewalk` reports no free port between 8765 and 8815 | Another process is holding the 51-port range. Kill it (`lsof -ti :8765-8815 \| xargs kill`) or edit `START_PORT` in `.codewalk/<slug>/serve.js`. |

See [`CHANGELOG.md`](CHANGELOG.md) for release notes.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/nadyshalaby/hackify). The most useful bug reports include the work-doc that demonstrates the failure — the file already captures the original ask, the plan, the implementation log, and the verification output, so it is usually most of the repro by itself.

Feature requests are most useful when they describe the motivating workflow gap: what task were you running, where did hackify get in the way or fail to help, and what would have unblocked you.

## License

MIT — see [LICENSE](LICENSE).

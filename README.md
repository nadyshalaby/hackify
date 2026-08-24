<div align="center">

# Hackify

**One end-to-end dev workflow for every task in Claude Code.**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.14.2-7c3aed.svg)](.claude-plugin/plugin.json)
[![Claude Code](https://img.shields.io/badge/claude--code-plugin-1f2937.svg)](https://www.anthropic.com/claude-code)
[![Keep a Changelog](https://img.shields.io/badge/changelog-keep--a--changelog-orange.svg)](CHANGELOG.md)

Clarify → Plan → Implement → Verify → Review → Finish, anchored to a single markdown work-doc per task.

<br/>

<img src="docs/assets/hackify-demo.gif" alt="Hackify 6-phase workflow. Clarify, Plan, Implement, Verify, Review, Finish" width="820" />

</div>

---

## Overview

Hackify replaces multi-skill ceremony (separate spec, plan, groom, execute, verify, review, and finish skills) with **one workflow and one work-doc per task**. The work-doc is the spec, the plan, the progress tracker, the review log, and the post-mortem, all in a single file at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`. Pause whenever. Resume by saying *"continue work on `<slug>`"*.

The workflow is opinionated and expert-led: a batched clarifying questionnaire up front, a hard gate before any code is written, sub-agent dispatch as the default for spec review, implementation and code review, mandatory multi-reviewer code review on non-trivial diffs, and a definition-of-done that demands fresh verification output before anyone may say *"done"*.

For small fixes and single-file edits, a sibling skill `/hackify:quick` runs a compressed flow that stays in quick mode until you explicitly promote to full hackify. When you trust the pipeline enough to skip the plan-gate and finish menu, `/hackify:yolo` runs the same workflow on full autopilot.

### New in 0.14.2

- **The review stage could never finish, and the rules checker was quietly ignoring files it had been handed.** Reviewing a change means comparing it against the notes written for it, and those notes were being counted as part of the change under review. So every time a round of review wrote down its own result, it altered the very thing the next round measured against, which forced another round, which wrote down its result again. The notes for this piece of work were rewritten twenty five times. It was not slow to settle, it could not settle, and no amount of care by any reviewer would have changed that. The notes are now the ruler rather than something being measured: reviewers still read them in full to judge the work, they just stop grading them. Separately, the rules checker was handed files and quietly threw some away, counting them as neither checked nor skipped, which hit every file whose name begins with a dot, the project's own build settings among them. Because a file that vanishes produces no complaints, the report read exactly like a clean pass. It now says out loud how many files it was given, how many it looked at, and why it set any of them aside, and refuses to be read as clean until those add up. Two separate things also enforced the same five hundred line limit and disagreed by one, so a file sitting exactly on the limit passed one and failed the other; they now agree, and a check holds them to it.

### New in 0.14.1

- **A round of code review could go to the wrong reviewer and come back with nothing.** The list that says which reviewer gets which input still named one that was retired two versions ago, and left out the one that actually needs it and will not start without it, so anyone following the list lost a whole round of review for nothing. Two other pages described reviewers that only join when the change gives them something to look at as though they turn up every time, and one of those had been wrong for three releases while every check stayed green, because a review reads the files a change touches and nobody had touched those. There is a new check for exactly that: it reads what a sentence is claiming rather than how it happens to be worded, so it also catches phrasings nobody has written yet, and it finds its own files instead of working from a list, because the problems it exists to catch lived in files no list named. A stale accessibility reference now points at the right level of the standard, and the checker is quick again after a rewrite that had it re-reading every file once per banned word.

### Earlier releases

- 0.14.0. **The step tracker could no longer vanish, and a sweep caught the instructions disagreeing with each other.** On Claude Code the to-do tool the checklist relied on is often simply absent, and nothing said what to do instead, so the checklist quietly disappeared and nothing held the steps in order; it is now printed in the chat with a copy kept in the work-doc, so it survives closing the session and returning days later, and the rules that keep a run ordered arrive with every message rather than being read once and fading. Two of the contradictions the sweep found changed what actually happened rather than just how it read: the menu at the end of a task numbered its four choices one way in the overview and another way in the pages that own it, while the fully automatic mode picks by number, and a review step still called for a helper that had been retired, which under these rules makes the helper refuse outright, so that step returned nothing every time it ran.
- 0.13.0. **Three planning reviewers became one, and the helper definitions stopped drifting.** The spec-review step is deliberately non-skippable, so unlike the code-review panel there was no gate that could ever make it cheaper, and all three were reading the same planning document; one reviewer now does all three jobs (does the plan say a consistent thing, can it actually be built in the order it proposes, and would building it break the project's own rules), every check, every question and every worked example from all three survives, and the report leads with the build order so the next step can read it straight off. Worth knowing: the third fold is a smaller win than it looks, because that reviewer reads the rule files nobody else opens and those reads still happen. The research and debugging helpers became proper registered helpers too, with permissions narrowed to a read-oriented set so the file-editing tools are simply not on the table; both had been written as text the main agent had to read into its own context before it could hand the job off, which meant paying for the same instructions twice. Two definitions had also been edited by hand and had silently lost pieces of their instructions, including a pointer one reviewer needed, and because the registered definition is the one that actually runs, that was a reviewer running slightly weaker than the written spec promised. Seven definitions are now checked character for character against their source on every build.
- 0.12.0. **Less work for the same coverage, in two places.** Tasks that touch the same part of the code go to one implementer together instead of one each, so the shared reading happens once; each task keeps its own file boundary, a batch stops at the first task it cannot finish so a bad task costs one task and not the batch, and tasks in unrelated areas still go separately because there is nothing shared to save. Two checks also stopped running when they had nothing to say: the cross-module reviewer needs two sides to compare, so on a change that stays inside one area its checklist passes to the quality reviewer instead (two areas touched is enough to run it, and so is one file that anything outside its area uses), and a serious finding is only dropped when two independent checkers both reject it, so the second checker now runs only when the first one votes to drop, which leaves the outcome exactly as it was.
- 0.11.0. **Same discipline, far fewer tokens.** The always-on rules arrive in full on the first prompt, then as a one-line reminder with a full refresh every 25 prompts, instead of a fresh copy every single turn. Reviewers and implementers read the changed hunks and their surrounding context rather than whole files, and share one repo brief instead of each rediscovering the stack. `SKILL.md` became a router, so a phase's protocol loads when that phase opens, and the finish report is rendered from a small block of data instead of typed out by hand. Reviewers also stop reading each other's homework: each receives only the part of the change its own lens can act on, and the closing round skips files that have not moved since they were judged clean. The quality reviewer is the deliberate exception, its checks apply to every touched file and anything nobody else claims goes to it, so slicing can never leave a change unreviewed. Security and performance join when the diff touches their surface, a folded lens hands its checklist to the quality reviewer so folding moves a lens rather than dropping one, and the loop still cannot close until a full panel clears the whole change exactly as it sits on disk.

## Install

```text
/plugin marketplace add nadyshalaby/hackify
/plugin install hackify@hackify-marketplace
```

Verify with `/hackify:hackify`, or simply describe a task. Hackify auto-triggers on any non-trivial prompt.

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
| **Quick hackify** | `/hackify:quick` | Small bug fixes, one- to three-line edits, single-file polish, typo work, direct quick-effort requests. Compressed flow. |

All three skills auto-trigger from natural-language prompts, no need to invoke them by slash unless you want to be explicit.

**Plugin primitives** (since v0.2.2). Hackify ships five first-class harness primitives, each owning a separate concern. `skills/`, the workflows (full hackify, quick, yolo, groom, skillsmith, review-triage, codewalk) plus `lawkeeper` (a full-codebase engineering-rules auditor). `rules/`, always-on engineering law (`hard-caps.md`, `expert-mindset.md`, `perf-guardrails.md`, and `phase-discipline.md` injected every prompt via hook; `code-quality.md` and `performance.md` loaded by skills on demand). `agents/`, formal sub-agent definitions for Phase 2.5 spec reviewers, Phase 3 wave-task implementers, and Phase 5 multi-reviewers (claude-code only; other runtimes use the inline templates in `skills/hackify/references/parallel-agents/`). `hooks/`, a `UserPromptSubmit` hook injects the hard caps, the expert mindset, the performance guardrails, and the phase discipline into context every turn (via `inject-context.sh`, one entry per file), and (since v0.4.2) a `PreToolUse` hook blocks `Write`/`Edit`/`Bash` actions that introduce banned tokens (lint suppressions, non-null `!`, empty `catch {}`, bare `Error`, hardcoded secrets) into JS/TS source, net-new only, with a per-path `.claude/hooks/ban-allowlist` escape hatch (claude-code only). `commands/`, the `/hackify:summary` and `/hackify:designify` slash commands. Routing between skills is handled by each skill's frontmatter `description` field via the harness's native auto-discovery, no prompt-based classifier.

## The workflow

```
┌──────────────────────────────────────────────────────────────────────┐
│ Phase 1   Clarify     batched wizard questionnaire                   │
│ Phase 2   Plan        work-doc draft ─ HARD GATE ─ user signs off    │
│ Phase 2.5 Spec        one reviewer, three lenses on the plan         │
│ Phase 3   Implement   parallel waves of foreground subagents         │
│   └─ 3b   Debug       4-phase root-cause hunt (only if stuck)        │
│ Phase 4   Verify      evidence ledger + ship gate (build/boot/smoke) │
│ Phase 5   Review      gated reviewer panel + refute-before-fix       │
│ Phase 6   Finish      4 options → archive work-doc → update log      │
└──────────────────────────────────────────────────────────────────────┘
```

The **only** mandatory user gate is between Plan and Spec review. After sign-off, Phases 2.5 through 6 run continuously with progress reports, not gates, at each transition. Interrupt any time; the work-doc holds state.

A **phase ledger** (one checklist item per phase) enforces the order: one item in progress at a time, and no later phase starts until the current phase's exit artifact exists. It lives in the runtime's to-do tool when the session exposes one, and otherwise in a chat block re-printed at every phase boundary plus section 0 of the work-doc in full hackify; on Claude Code that fallback is the normal path, not an exotic edge case. Phase 6 splits into sub-items so archiving the work-doc is its own tracked step that gates the summary, see `references/phase-ledger.md`.

### Phase notes

- **Phase 1. Clarify.** Task is classified as `feature`, `fix`, `refactor`, `revamp`, `redesign`, `debug`, or `research`; the classification picks the right question bank. Questions ship through the `AskUserQuestion` wizard, never as plain markdown lists.
- **Phase 2. Plan + gate.** Work-doc fills out: Original Ask (verbatim), Clarifying Q&A, Definition of Done (3-7 verifiable bullets), Approach (≤200 words), and a flat task list where each task is 5-30 minutes of work. No `TBD`, no `similar to T2`, no placeholders.
- **Phase 2.5. Spec self-review.** One spec reviewer carrying three lenses (internal consistency, the execution-wave plan, architectural risk) patches contradictions before any code is written. Non-skippable, small docs are exactly where contradictions hide.
- **Orchestration (all phases).** Every mandatory fan-out runs at the heaviest orchestration the runtime offers, the workflow re-enters itself across turns until the phase ledger is fully ticked, and each task hands you a one-line completion condition that something other than Claude checks. The first two are tool calls the workflow makes, not a posture it describes: a pipelined fan-out goes through Claude Code's Workflow tool, and a turn that ends with open ledger items invokes the self-paced `loop` skill on `continue work on <slug>`. The third it can only print, as a paste-ready `/goal` line, since only you can set a session goal; if the evaluator and the loop disagree, the loop's stop rules win. Typing `ultracode` yourself raises the whole session on top of that. Hackify announces the tier once per task and honors `light mode` / `no ultracode` / `cheap mode` / `single agent` at any point (`references/orchestration.md`).
- **Phase 3. Implement.** Tasks group into dependency-ordered **waves**; every task in a wave has no file overlap and no intra-wave dependency, so the wave dispatches as one parallel batch of foreground subagents. Each agent carries a strict file allowlist. At each wave-end the parent runs both deterministic scouts over the wave-touched files, the **perf-scout** (`references/perf-scout.md`) and the **law-scout** (`references/law-scout.md`, the bundled lawkeeper scanner scoped to the diff); surviving findings are staged for Phase 5.
- **Phase 3b. Debug.** Triggered by ≥2 failed fix attempts or a regression. Four-phase root-cause hunt (gather evidence → find analogue → form hypothesis → reproduce in a failing test). Circuit-breaker after 3 failed hypotheses.
- **Phase 4. Verify.** Tests, lint, and typecheck re-run fresh; output pasted into the work-doc. Zero tolerance for new lint suppressions, new non-null `!` assertions, stray debug prints, or commented-out code. Then the **ship gate** (`references/ship-gate.md`) proves the app actually runs, not just compiles: it builds from a cold cache, boots and waits for a real ready signal, and smoke-drives the flow this sprint touched. A leg is blocking whenever the diff touched something that leg's target consumes, a written `skipped` row with the reason otherwise, never silently absent.
- **Phase 5. Review.** Reviewers dispatched in parallel in one message. **Reviewer B** (quality, engineering law, plan consistency, scope and goal drift) is the standing member of every wave; **A** (security/correctness), **D** (performance) and **F** (cross-module coherence) are gated on evidence that their lens has something to look at, and **E** (design conformance) joins on UI-bearing diffs. A gated-off reviewer hands its residual checklist to B, so folding moves a lens and never drops one. Reviewer B consumes the law-scout report and cites lawkeeper `rule_id`s; Reviewer D consumes the perf-scout report and cites `rules/performance.md` catalog IDs. **Reviewer F** is the lens no other reviewer owns: it compares every boundary-crossing symbol's producer against every consumer for shape, units, error contract, and wiring, because Phase 3's parallel waves build each half blind to the other. Findings then go through **adversarial refuters** before a single fix is spent on them, and the loop only exits on a diff that has not changed since the scan that cleared it. Mandatory for any non-trivial diff; self-review is additive, not replacement.
- **Phase 6. Finish.** Re-verify, present four explicit options (merge / push & PR / keep as-is / discard), archive the work-doc to `docs/work/done/`, then print the **update log**: one short block per change, written plainly, with what was wrong, why it happened, what was done, how we know it works, and whether it shipped. Archiving is its own phase-ledger item (`6c`) and **gates the log** (`6d`): the recap never prints while the work-doc still sits in `docs/work/`.

## Quick mode

`/hackify:quick` is the compressed-flow sibling. It runs a compressed flow:

```
Phase 1 (clarify if ambiguous) → Phase 3 (implement) → Phase 4 (verify + both scouts + ship gate) → Phase 5-lite (one reviewer, every lens) → Phase 6F (update log)
```

Plan + Gate, Spec self-review, the parallel reviewer panel, and the four-options finish menu are skipped. **One reviewer carries every lens** instead (quality, engineering law, correctness, goal drift, performance, cross-module coherence, design on UI diffs), followed by one batched refuter and the address-all loop. Quick mode drops the parallelism, never the coverage: both scouts and the ship gate run here exactly as they do in full hackify. Step C.5 (touched-scope cleanup) and Step F (the update log + HTML report) are the Phase 6 pieces kept. At most **one** implementation subagent is dispatched.

### User-initiated promotion to full hackify

Quick mode never auto-promotes. The user explicitly triggers promotion by saying any of these phrases (case-insensitive, most recent message only):

- `switch to full` / `go to full mode` / `promote to full`
- `/hackify:hackify` (explicit slash command)
- `do full review` / `run Phase 5` / `run multi-reviewer`

On promotion, quick mode writes a work-doc from accumulated context (intent, clarify answers, any partial diff) and hands control to full hackify Phase 2, no half-done state, no lost context. If the user does not promote, quick mode stays in quick mode for the entire task.

### YOLO mode

`/hackify:yolo` is the full-autopilot sibling. Same workflow phases as `/hackify:hackify`, clarify (with exploration), in-chat plan, spec-review, parallel implementation, verify, multi-reviewer, finish, but two gates auto-pass:

- **Phase 2 plan-gate**, no sign-off; the in-chat plan block is posted and Phase 2.5 begins immediately
- **Phase 6 finish menu**, auto-picks Option 1: commit to current branch locally, no push

Phase 5 multi-reviewer findings are auto-fixed in-place at every severity (Critical, Important, AND Minor), then re-scanned to zero. You inspect with `git log -1` / `git diff HEAD~1` after the commit lands.

**No work-doc on disk.** YOLO never writes to `docs/work/`, the plan exists only in chat. Close the chat mid-task and progress is gone. Invoke `/hackify:hackify` if you need pause/resume or want to sign off on the plan first.

## Companion skills

Five skills ship alongside `hackify`, `quick`, and `yolo` to cover the bookends, the meta-loop, onboarding to unfamiliar code, and whole-repo rule audits:

- **`/hackify:groom <topic>`**, a Socratic pre-task refinement loop for fuzzy, exploratory prompts ("I'm thinking about X, not sure where to start"). It clarifies one question at a time, surfaces tradeoffs, and graduates to full hackify Phase 1 when you signal you're ready to build. Use it instead of jumping straight into `/hackify:hackify` when the ask is still ambiguous.
- **`/hackify:skillsmith`**, authors new hackify-conformant skills (your own or contributions back to the plugin). Runs a 9-check self-validation loop covering frontmatter, trigger phrasing, template-contract conformance, no-leaked-paths, and OUTPUT word caps, the same shape the validator enforces on shipped skills.
- **`/hackify:review-triage`**, structures your response to multi-reviewer findings (Phase 5 output) as a per-finding accept / push-back / defer table, so nothing slips through and every reviewer concern gets an explicit disposition before the work-doc is archived.
- **`/codewalk <entry-point>`** *(since v0.2.8)*, interactive call-stack viewer for code you didn't write. **Deep depth-first walk to leaves** from one entry point (route, handler, CLI command, queue job, UI action), controller → service → repository → external SDK / SQL leaf, INCLUDING every TypeScript `interface` / `type` / `class` / `enum` / Zod schema / NestJS DTO / TypeORM entity referenced on the path (each emitted as its own `layer: "type"` node, hyperlinked from the function nodes that reference it). Stops cold on runtime ambiguity (env flags, feature gates, tenant guards, DI tokens, dynamic dispatch), never guesses. Emits a `.codewalk/<slug>/` browser viewer. GitHub-PR-style three-pane layout with invoked-line highlights, clickable call-site anchors that resolve to type/function nodes alike, layered Mermaid sequence diagram, invariants per boundary, failure modes with blast radius, branches not taken listed by name, and an amber diff banner when you re-trace the same entry. Closes with 5 comprehension questions + a `safe to change` / `load-bearing` / `Chesterton's fence` decisions checklist. *(Since v0.3.1)*, a header **theme toggle** (light/dark, persisted via `localStorage`); and a **playbook mode** that fires on "all endpoints" / "every endpoint" / "index playbook" triggers, producing a top-level `.codewalk/index.html` light-mode index of every entry in the service (catalog-driven via `_catalog.json`, each row linkable into its own per-trace viewer). *(Since v0.3.2)*, **deep-by-default mandate** + first-class `layer: "type"` nodes + layer-colored chips in the viewer (controller / service / repository / external / type / other each in a distinct hue).
- **`/lawkeeper`** *(since v0.4.0)*, full-codebase engineering-rules auditor: the detect-and-fix sweep that checks a repo against the laws it is supposed to obey. Resolves the effective rule set from the project's own harness (`.claude/rules`, `ban-patterns.txt`, `CLAUDE.md`/`AGENTS.md`) with stricter-wins fallback to global doctrine, never a duplicate copy. A bundled deterministic scanner does the exact, zero-false-positive checks (file-line cap; lint suppressions, non-null `!`, empty catch, bare `Error`, hardcoded secrets, inline types in scoped modules; `// removed:` markers and ownerless TODO/FIXME), and a semantic subagent pass covers the judgment rules (DRY, layering, SRP, naming, security, performance, testing, full SOLID + YAGNI, cross-file cleanup), reusing the project's installed `.claude/agents/` reviewers when present. Reports every finding with `file:line` grouped by category/severity, then fixes them one at a time with your approval. TS/JS core, `--text-only-ext` for any file, and an ephemeral on-demand scanner for deep non-JS audits. Full-codebase scope. NOT a per-PR diff review (use `/code-review`).

## Skill routing

Routing is by each skill's frontmatter `description` via the harness's native auto-discovery, there is no prompt-based classifier. As the skill surface grows, this table is the human-readable map of which skill owns which intent and how the overlaps resolve.

| Your intent | Skill | Notes |
|---|---|---|
| Build / add / fix / refactor / redesign / migrate / debug, any substantive change | `hackify` | The default. When in doubt, this one. |
| Small bug fix, one- to three-line edit, single-file polish, typo | `quick` | Compressed flow; promote with *"switch to full"*. |
| Substantive task on full autopilot (no plan-gate / finish menu) | `yolo` | Same phases as hackify; two gates auto-pass. |
| Fuzzy *"I'm thinking about X, not sure where to start"* | `groom` | Socratic pre-task refinement; graduates to hackify. |
| Author or improve a hackify-conformant skill | `skillsmith` | 9-check self-validation loop. |
| Respond to multi-reviewer findings (Phase 5 output) | `review-triage` | Per-finding accept / push-back / defer table. |
| Understand code you didn't write (trace one entry point) | `codewalk` | Emits a `.codewalk/<slug>/` browser viewer. |
| Audit a whole repo against its engineering laws + fix violations | `lawkeeper` | Full-codebase compliance sweep. |
| Review just the diff on my branch / a PR before merge | `/code-review` | Built-in, **not** a hackify skill; a per-diff review, not a full-tree audit. |

**Disambiguating "audit / review / check"**, these verbs overlap three ways:

- *"Does this whole repo follow our CLAUDE.md / find every rule violation"* → **`lawkeeper`** (full-codebase, rule-by-rule, with fixes).
- *"Review the changes on my branch / this PR"* → **`/code-review`** (the diff, not the tree).
- *"Build / refactor X" with rigor* → **`hackify`**, it runs its own Phase 5 multi-reviewer on the diff it produces; you don't invoke a separate auditor mid-workflow.

These boundaries are also encoded as non-trigger assertions in the skills' `evals/evals.json` (e.g. lawkeeper's "single-diff review routes to `/code-review`, not lawkeeper"); those evals are documentation-grade until run through an eval harness.

## Example

You type:

> add expiry to invitation tokens

Hackify recognizes a non-trivial build task, invokes `/hackify:hackify`, and asks four clarifying questions through the wizard:

1. Default expiry window, 24h, 7d, 30d, or custom?
2. Behavior on expired token, reject with 410, redirect to a "request a new invite" page, or auto-renew?
3. Migration strategy, backfill existing tokens or treat them as never-expiring?
4. UI surface, show the expiry timestamp in the invite UI, or only on error?

You answer. Hackify drafts the work-doc, presents it, waits for sign-off. Once you say *"go"*, one spec reviewer scrutinizes the plan through three lenses, then dependency-ordered waves of foreground agents implement the change, verify it, run multi-reviewer code review, and finish with the four-options menu and a plain-language update log.

You can pause at any phase by closing the terminal. Later, when you say *"continue work on invitation-token-expiry"*, hackify reads the frontmatter, finds the following unchecked task, and picks up exactly there.

## The work-doc

A single markdown file holds everything about a task: spec, plan, progress, review log, post-mortem. While in flight it lives at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`; after Phase 6 it moves to `<project>/docs/work/done/`.

**Frontmatter:** `slug`, `title`, `status`, `type`, `created`, `project`, `current_task`, `worktree`, `branch`, and (since v0.2.0) `sprint_goal`, a one-sentence framing of the win condition.
**Body** (sprint vocabulary since v0.2.0): **Phase ledger** (section 0) → Original Ask → Clarifying Q&A → **Acceptance Criteria** (was Definition of Done) → Approach → **Sprint Backlog** (was Tasks) → **Daily Updates** (was Implementation Log) → **Sprint Review** (was Verification) → **Retrospective** (was Post-mortem). The sections do the same jobs; the labels just align with how teams already talk about work. Section 0 holds the phase ledger, so a resumed session reads its progress back out of the file instead of reconstructing it. Pre-v0.2.0 work-docs archived under `docs/work/done/` keep their original headings and resume unchanged, the resume logic reads either vocabulary.

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
- [x] T1. Add `expires_at` column + migration
- [x] T2. Reject expired tokens in invitations service
- [ ] T3. Show "expired" state in the accept-invite UI
- [ ] T4. Backend test
- [ ] T5. Frontend test
```

State lives in the file. No companion JSON, no hidden in-conversation memory. Resume by saying *"continue work on `<slug>`"*, the assistant reads the frontmatter, finds the following unchecked task, and picks up exactly there. Docs older than fourteen days trigger a `git log` drift check before resuming.

## Slash commands

| Command | Purpose |
|---|---|
| `/hackify:hackify <ask>` | Start a full workflow on a new task. |
| `/hackify:hackify resume <slug>` | Resume a paused work-doc. |
| `/hackify:quick <ask>` | Start the compressed-flow sibling. |
| `/hackify:yolo <ask>` | Start the full-autopilot sibling. |
| `/hackify:summary` | Print the current update log on demand (also responds to *"show summary"*, *"summarize"*, *"summary table"*). |
| `/hackify:designify` | Author, extract, refresh, or validate the project's design spec at `docs/design/DESIGN.md` plus its `preview.html` visual catalog. Picks a direction from the twelve-entry library, starts from a catalog spec, computes real WCAG contrast ratios, and validates against the spec contract before finishing. |
| `/hackify:groom <topic>` | Start a Socratic pre-task refinement; graduates to full hackify Phase 1 on user signal. |
| `/hackify:skillsmith` | Author new hackify-conformant skills via a 9-check self-validation loop. |
| `/hackify:review-triage` | Structure your response to reviewer findings as a per-finding accept/push-back/defer table. |
| `/codewalk <entry-point>` | Trace one execution path from a single entry point and open a `.codewalk/<slug>/` browser viewer with annotated code + Mermaid diagrams + decisions checklist. Light/dark theme toggle in the header (since v0.3.1); use phrases like *"all endpoints"* / *"index playbook"* to switch to multi-entry playbook mode (since v0.3.1) which produces a top-level `.codewalk/index.html` index of every entry. |
| `/lawkeeper` | Audit the whole codebase against its engineering laws, caps, bans, DRY, layering, SRP, security, performance, testing, SOLID, cleanup. Deterministic scanner + semantic subagents; report by category/severity with `file:line`, then propose-confirm fixes. Reads rules from the project's own harness (stricter-wins vs global). |

## Parallel agents

Parallelism is the default, not the exception. Whenever two or more pieces of work are independent, implementation tasks in the same wave, code review concerns, cross-package verification, multi-boundary debug evidence, hackify dispatches foreground subagents in a single message and waits for the whole batch.

The safety property that makes this work is a **strict file allowlist** baked into every agent's prompt. The wave planner groups tasks so no two tasks in the same wave touch the same file; each agent is told the exact files it may touch and instructed to stop if it discovers it needs another. Dispatch templates conform to a canonical seven-section contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT), see [`skills/hackify/references/parallel-agents/template-contract.md`](skills/hackify/references/parallel-agents/template-contract.md) and the subdir index at [`skills/hackify/references/parallel-agents/README.md`](skills/hackify/references/parallel-agents/README.md).

## Repository layout

```text
.claude-plugin/
  plugin.json                          plugin manifest
  marketplace.json                     self-hosted marketplace entry
rules/                                 always-on engineering law (since v0.2.2)
  hard-caps.md                         short doctrine injected every prompt via hook
  expert-mindset.md                    senior multi-hat mindset + stakes, injected every prompt (since v0.7.0)
  code-quality.md                      DRY, named types, layering deep dive (canonical)
  performance.md                       canonical perf-violation catalog, 95 stable IDs, 10 domains (since v0.7.0)
  perf-guardrails.md                   tight always-on perf stub, injected every prompt (since v0.7.0)
  phase-discipline.md                  phase order + always-open step ledger + wizard mandate, injected every prompt (since v0.14.0)
agents/                                formal sub-agent definitions (since v0.2.2, claude-code only)
  codebase-investigator.md             Phase 1 research + Phase 3b debug, read-only, mode-switched
  spec-reviewer.md                     Phase 2.5, all three spec lenses
  code-reviewer-security.md            Phase 5 Reviewer A
  code-reviewer-quality-plan.md        Phase 5 Reviewer B, quality + plan consistency, never sliced
  code-reviewer-performance.md         Phase 5 Reviewer D, performance (since v0.7.0)
  design-conformance-reviewer.md       Phase 5 Reviewer E, design conformance, UI-bearing diffs (since v0.8.0)
  code-reviewer-coherence.md           Phase 5 Reviewer F, cross-module coherence, seam-gated (since v0.9.0)
  finding-refuter.md                   Phase 5 adversarial refuter, judges findings before a fix (since v0.9.0)
  wave-implementer.md                  Phase 3 wave-task implementer
hooks/                                 prompt-time + edit-time enforcement (claude-code only)
  hooks.json                           UserPromptSubmit + PreToolUse hook declarations
  inject-context.sh                    injects the 4 always-on rules files, full on the first prompt, pointer after (since v0.11.0)
  inject_context.py                    session-aware injector companion, counts turns per session (since v0.11.0)
  block-banned-tokens.sh               PreToolUse (Write|Edit|Bash), blocks banned tokens in JS/TS (since v0.4.2)
  scan_edit.py                         Write/Edit detector reused by the hook (lawkeeper lexer + check regexes)
  scan_bash.py                         Bash detector, scans heredoc/echo writes to JS/TS files
commands/
  summary.md                           /hackify:summary slash command
  designify.md                         /hackify:designify, author / extract / refresh / validate the design spec (since v0.8.0)
scripts/
  validate-dod.sh                      CI helper, validates the plugin's own DoD
  check_question_clarity.py / check_design_specs.py  CI gates, the question-bank Clarity law (v0.9.0) and the design-spec contract + WCAG AA contrast (v0.8.1)
  sync-runtimes.sh                     fan canonical skills/ into dist/<runtime>/
skills/
  hackify/
    SKILL.md                           the router: each phase's goal, hard gates and exit artifact (v0.11.0)
    references/
      phases/ + repo-brief.md          per-phase protocol, one file per phase, loaded when that phase opens; and the sprint's shared repo-context brief handed to every agent (both v0.11.0)
      work-doc-template.md             markdown skeleton for every task
      clarify-questions/               per-task-type question banks (Phase 1), subdir index in README.md; canonical wizard contract in wizard-contract.md; one bank per task type (feature/fix/refactor/revamp-redesign/debug/research) + universal-preamble + picking-and-combining
      implement-and-test.md            TDD walkthrough, per-stack test commands
      debug-when-stuck.md              4-phase root-cause hunt (Phase 3b)
      review-and-verify.md             DoD + ship gate + 19-item self-review
      perf-scout.md / law-scout.md / ship-gate.md  the always-on proof trio: perf candidates keyed to rules/performance.md IDs (v0.7.0), engineering-law violations from the bundled lawkeeper scanner scoped to touched files, and the runtime gate that builds, boots and smokes the touched flow before the task can finish (both v0.9.0)
      phase-ledger.md / expert-mindset.md  ordered phase ledger (order-enforcer, archive gate, substrate + fallback) and the senior multi-hat mindset, both always-on (since v0.7.0)
      finish.md                        Phase 6, options, archive, update log
      frontend-design.md               visual law (loaded on FE / UI / mobile-design tasks), owns the design-spec pipeline
      design-spec/                     the design artifact (since v0.8.0). README.md index; spec-contract.md (DESIGN.md schema, {token.ref} syntax, web ↔ RN / Flutter / SwiftUI mapping, validation checklist); direction-library.md (the picker table + load rule, the plugin's only direction list) with directions/<slug>.md holding each profile's palette logic, type pairing, motion, signature move and anti-tells, loaded one at a time (v0.11.0); extract-protocol.md (derive a spec from code / a reference site / screenshots, plus REFRESH mode and merge rules); catalog/ (twelve complete ready-to-drop specs)
      code-rules.md / runtime-adapters.md  forwarding stub → rules/code-quality.md; and the primitive → per-runtime mapping table (12 primitives incl. orchestration tier, iteration driver, completion sentinel, always-on injection)
      orchestration.md                 ultracode tier + /loop iteration driver (v0.9.0) + /goal completion sentinel (v0.9.4), all on by default, with the standing grant, its opt-out, and sentinel-vs-driver precedence
      parallel-agents/                 dispatch index in README.md (on Claude Code dispatch by agent type and pass only INPUTS; the templates are the fallback for runtimes with no agent registry); canonical 7-section sub-agent contract in template-contract.md; per-phase templates for research and debug evidence (one mode-switched investigation file), spec review (1), implementation, cross-package verification, multi-review (A, B, D, E, F, one file each), adversarial refuters, escalation, aggregation
    assets/
      report-template.html             Phase 6 styled HTML report skeleton
      design-preview-template.html     self-contained design preview, swatches, type ramp, scales, elevation, live components, light/dark toggle (since v0.8.0)
    evals/evals.json                   optional eval harness
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
| **Not supported** | Copilot CLI | No plugin or skill concept on the runtime side, listed for transparency only. |

The workflow is written in **runtime-neutral primitives** (`wizard tool`, `subagent dispatcher`, `todo tracker`, `orchestration tier`, `iteration driver`, `completion sentinel`, `always-on injection`, and the file / search / shell ops) rather than Claude-specific names. `always-on injection` is native on Claude Code alone; the other six take the same laws from `SKILL.md` prose. Each runtime's adapter maps those primitives to whatever native or near-native feature exists, see [`skills/hackify/references/runtime-adapters.md`](skills/hackify/references/runtime-adapters.md) for the full mapping table and the degradation notes for the best-effort tier.

**Install. Claude Code (marketplace):**

```text
/plugin marketplace add nadyshalaby/hackify
/plugin install hackify@hackify-marketplace
```

**Install. Codex CLI (prompts directory):**

```bash
bash scripts/sync-runtimes.sh
cp -R dist/codex-cli/* ~/.codex/prompts/
```

`sync-runtimes.sh` writes all 7 runtime packages under `dist/<runtime>/`; copy the one you need. Use `--dry-run` first to preview the file list, or `--help` for usage.

## Design principles

See [`rules/four-principles.md`](rules/four-principles.md) for the canonical write-up of the four working principles. Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution, that underpin every phase below.

- **One file, not many.** The work-doc replaces a spec doc, a plan doc, a progress file, a review log, and a post-mortem. One file is easier to keep current than five.
- **Clarify everything up front.** A batched questionnaire before any code is written catches misreads while they are cheap.
- **One hard gate, not many.** Between Plan and Implement. Everything else runs continuously with progress reports.
- **The parent never writes the code.** Every change, down to a one-line typo, is authored by a dispatched agent under a file allowlist; the parent plans, dispatches, verifies and reviews. Wave-based dependency ordering plus file allowlists make parallel implementation safe.
- **Evidence before claims.** No Definition-of-Done bullet is checked without fresh command output or a verifying script in the work-doc.
- **Multi-reviewer is the floor.** A single lens always misses something. The quality, engineering-law and scope reviewer runs on every wave; security, performance and cross-module coherence join in parallel whenever the diff touches their surface, design conformance joins on UI-bearing diffs, and a lens that does not get its own agent is handed to the standing reviewer rather than dropped.
- **Shipping means it runs, and findings survive a challenge first.** A green test suite is not a working app, so the ship gate builds, boots and smoke-drives the touched flow before a task may finish. Every finding faces an adversarial refuter that defaults to keeping it, because dropping a real defect costs more than fixing a phantom.
- **The plan is the contract.** No scope creep, no cleanup of adjacent code on the side, no abstractions for hypothetical futures.

## Customization

### Project-level rules

Hackify honors a `CLAUDE.md` at workspace or project root first. The bundled [`rules/code-quality.md`](rules/code-quality.md) is the fallback when no project rules exist. The shorter [`rules/hard-caps.md`](rules/hard-caps.md) is injected into context on every prompt by the (since v0.2.2) `UserPromptSubmit` hook so the function/file/param caps and zero-tolerance bans are always loaded. Alongside it, [`rules/expert-mindset.md`](rules/expert-mindset.md) is injected every prompt too (since v0.7.0), casting the model as a senior, multi-disciplinary engineer and stressing the stakes of the work. [`rules/perf-guardrails.md`](rules/perf-guardrails.md) rides along the same way (since v0.7.0); the deep catalog lives in [`rules/performance.md`](rules/performance.md) and loads on demand. Four files ride on every prompt in all, and the newest of them, [`rules/phase-discipline.md`](rules/phase-discipline.md) (since v0.14.0), governs how the run is conducted rather than what you write: phases run in order with one open at a time, the step ledger is opened at task start and re-printed at every phase boundary, no phase is ever silently skipped, and every question, decision or approval goes through the wizard tool instead of a numbered list in chat.

### Voice (abstract principles, concrete adaptation)

The reference rules are written in language-agnostic voice: package manager, linter, formatter, type system, test runner, never a brand. That voice is documented in [`rules/code-quality.md`](rules/code-quality.md) and is explicitly **substitute your own toolchain**, swap in whatever package manager, linter, formatter, indent width, or quote style your project already uses; the workflow does not care.

What does carry across toolchains are the principles: reusable/generic/shareable code as the prime directive, DRY enforced by searching before writing, named types for any object shape with 2+ properties, one component and one construct per file with types/constants/config/schemas/styles in dedicated files, strict layer separation, zero lint suppressions, zero non-null assertions in production code, functions ≤40 LOC, files ≤500 LOC, edge cases handled rather than hoped away.

### Editing the workflow

The workflow is plain markdown, no compiled logic to subclass. Edit `SKILL.md` after install, or fork the plugin. Every reference file is designed to be edited.

## FAQ

**Does hackify work for tiny tasks like fixing a typo?**
For one-line typo fixes with no behavioral impact, use the carve-out (no skill needed). For anything with even modest ambiguity, prefer `/hackify:quick`. The compressed flow is exactly right for small-and-direct work.

**Does hackify lock me into a specific language or toolchain?**
No. The reference rules are written in language-agnostic voice, package manager, linter, formatter, type system, test runner, and you supply the concrete commands for your own stack. The phases, the gate, the parallel-agent dispatch, the verification rigor, the multi-reviewer pass, none of that is tied to a language or toolchain.

**How are the parallel subagents safe?**
Two mechanisms. Each agent's prompt carries a strict file allowlist, the agent is told the exact files it may touch and is instructed to stop if it discovers it needs another. The wave planner groups tasks so no two agents in the same wave share a file. Tasks in wave N may only depend on results from waves 1 through N-1.

**Does the plugin depend on other plugins or skills?**
No. Hackify is intentionally self-contained. All design law, TDD discipline, debugging method, verification rigor, and review checklists are inlined in `SKILL.md` or one of the bundled reference files.

**What happens if I interrupt mid-implementation?**
The work-doc holds state. Implementation Log entries are written per task, so the following session reads the latest entry and picks up at the following unchecked checkbox. Interrupting during a parallel wave is safe, the parent waits for all dispatched agents to return before writing log entries.

**Does the workflow support monorepos?**
Yes. Each sub-project (e.g., backend and frontend repos) is its own git repo with its own `docs/work/` directory. When a task spans multiple projects, create one work-doc per project and link them via the `related` frontmatter field. Phase 4 verification fans out across packages by default, one agent per package.

**What if a task needs a file outside its allowlist?**
The agent stops and reports back rather than editing the file. The parent decides: re-dispatch with a widened allowlist, or split the work into a follow-up task in the subsequent wave.

**Does codewalk work offline, and does it touch my repo's source?**
First load pulls Tailwind, Alpine, Prism, and Mermaid from public CDNs, after that the browser cache serves them, so subsequent traces work offline. The trace itself never modifies repo source; every artifact lands under `.codewalk/<slug>/`, which the skill auto-adds to `.gitignore` so traces stay out of commits.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `This plugin uses a source type your Claude Code version does not support.` | Update Claude Code (`claude --upgrade` or via your package manager) and retry. |
| `No ED25519 host key is known for github.com and you have requested strict checking.` | Run `ssh-keyscan -t ed25519,rsa,ecdsa github.com >> ~/.ssh/known_hosts`. Idempotent; safe to re-run. |
| `Permission denied (publickey).` | Local git config is rewriting HTTPS to SSH. Either remove the rewrite, or register an SSH key with GitHub. |
| Plugin does not appear after install | Run `/reload-plugins` or restart Claude Code. The skill registers as `/hackify:hackify` and auto-triggers on any non-trivial prompt. |
| `/codewalk` says `node: command not found` | Run any one of `python3 -m http.server 8765`, `python -m http.server 8765`, `npx --yes serve -l 8765`, `php -S 127.0.0.1:8765`, or `ruby -run -e httpd . -p 8765` from inside `.codewalk/<slug>/`. The skill prints this fallback chain when it cannot find Node. |
| `/codewalk` viewer doesn't open in the browser | The viewer prints its URL (`http://127.0.0.1:<port>/`) on its own line, copy it into your browser. The default-browser launch is best-effort and may be blocked on headless or remote shells. |
| `/codewalk` reports no free port between 8765 and 8815 | Another process is holding the 51-port range. Kill it (`lsof -ti :8765-8815 \| xargs kill`) or edit `START_PORT` in `.codewalk/<slug>/serve.js`. |

See [`CHANGELOG.md`](CHANGELOG.md) for release notes.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/nadyshalaby/hackify). The most useful bug reports include the work-doc that demonstrates the failure, the file already captures the original ask, the plan, the implementation log, and the verification output, so it is usually most of the repro by itself.

Feature requests are most useful when they describe the motivating workflow gap: what task were you running, where did hackify get in the way or fail to help, and what would have unblocked you.

## License

MIT, see [LICENSE](LICENSE).

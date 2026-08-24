---
slug: wave-implementer-migration
title: One implementer per wave, and the vocabulary that follows it
status: in-progress
type: refactor
created: 2026-08-23
project: hackify
current_task: T1
worktree: none
branch: main
sprint_goal: Collapse Phase 3 dispatch from one agent per task batch to one agent per wave, rename the unit everywhere, and apply the same collapse to the refuters.
related: 2026-08-23-phase-ledger-substrate.md
---

## 1. Original ask

Verbatim:

> cant we migrate the wave-task-implementr agent to work per wave instead per task and change hackify terminologies to match that in all modes. just imagine how fast it will be if the implementr took a whole wave instead of single task:
> - will save a lot of agents in each milestone and in return we will save a ton of tokens and speed the development to save hours of waiting the work doc to be completed.
> - single wave agent implementr will have all context in place instead of tearing down it across multiple agent and consistency will be lost
> - implementation per wave is much faster than implementation per task
> - we can do the same for other agents too that share the same nature of work

## Primary Goal & Guardrails

**North-Star Goal.** One dispatched agent per execution wave, in every mode, with the vocabulary
across skills, agents, docs and validators saying "wave" wherever it currently says "batch".

**In-Scope.** The Phase 3 implementer contract and its rename. The Phase 3 dispatch rules. Phase 3
vocabulary in the three mode skills. The refuter collapse. The spec reviewer's emitted plan, since it
is what Phase 3 dispatches off. Validator pins that reference any renamed path or retired word.
README and CHANGELOG. Regenerated `dist/`.

**Out-of-Scope and Non-Goals.** The reviewer panel keeps its lens count: the user chose #10-A
(refuters) and explicitly not #10-D. No change to wave PLANNING (how tasks are grouped into waves);
only to how many agents a planned wave is dispatched to. No change to the file-allowlist mechanism.

**Guardrails and Invariants.**
- `scripts/sync_agent_mirrors.py --check` stays 9 of 9. The rename moves both sides of a mirror pair.
- `bash scripts/validate-dod.sh` exits 0 with 0 FAIL at every wave end. This guardrail was breached
  mid-sprint on the last work and self-disclosed; it is restated here because restating it is cheap.
- No em dashes or en dashes in any prose. No lint suppressions. 500 lines per file, 40 per function.
- `dist/` is generated. Never hand-edited.

**Success Signals.** A Phase 3 wave of N tasks dispatches exactly one agent. The word `batch` no
longer appears as a Phase 3 unit of dispatch. `agents/wave-implementer.md` is registered and mirrored.
Every validator pin that named the old path names the new one, and each was proven to bite.

## 2. Clarifying Q&A

All five taken through the wizard. Recorded verbatim, because the reasoning behind a decision rots
faster than the decision.

| # | Question | Answer |
|---|---|---|
| 9 | Shape of the per-wave implementer | **#9-B. Pure per-wave, no cap, ever.** Wave == agent, always, in every mode. No width valve, no module split. |
| 11 | Failure semantics partway through a wave | **#11-A. Stop, keep what landed, report.** Completed tasks stay on disk; the agent reports exactly which landed and which did not. |
| 12 | Naming | **#12-A. Rename to `wave-implementer`.** The word `batch` retires from Phase 3 entirely; `wave` is the only unit of dispatch. |
| 13 | Quick and yolo modes | **#13-A.** Quick has no wave plan, so the whole change is the unit: one agent, all of it. Yolo keeps full hackify's wave structure and gets per-wave dispatch. |
| 14 | Refuters | **#14-A. One refuter per round, all findings.** A single agent judges every finding in the round. |

### A tradeoff I raised, and the decision taken over it

I argued that per-wave dispatch is **not** faster in wall-clock, because batches already go out in
parallel in one message: a nine-task wave that runs as three concurrent agents finishes in about the
time of the slowest three-task chain, while one agent runs the nine in sequence. The saving is tokens
and consistency; the cost is wall-clock and blast radius.

The user chose #9-B with that stated. It is their call and this sprint implements it as chosen. What
the plan does carry forward is #11-A, which is the mitigation for the blast-radius half: a wave that
dies at task 8 keeps tasks 1 through 7 rather than discarding them.

**One honest note on the premise.** On the sprint that just ran, the hours did not go to implementers.
They went to the Phase 5 review loop, which took three rounds plus two closing attempts, mostly
because of dispatch errors of mine. This migration will not touch that. It is worth doing for tokens
and coherence; it should not be expected to fix review-loop latency.

### Phase 2 gate

Signed off via the wizard, decision **#15-A**: go as written, start once the ledger sprint
(`2026-08-23-phase-ledger-substrate.md`) closes. Sequencing was already settled at **#8-A**.

Option #15-B (start both sprints in parallel) was offered and not taken, which is the right call: the
ledger sprint produced a Critical for editing a file while a reviewer was reading it, and two sprints
writing the same repo at once is that failure mode with more surface.

## 3. Acceptance Criteria

1. A planned wave of N tasks dispatches **exactly one** agent, in full hackify and in yolo.
2. Quick mode dispatches exactly one implementer for the whole change.
3. `agents/wave-implementer.md` exists, is registered, and mirrors byte-for-byte against
   `skills/hackify/references/parallel-agents/phase-3-implementation.md`. Old path is gone, not aliased.
4. The agent contract states #11-A failure semantics explicitly: stop at the first task it cannot
   finish, keep completed work, report which landed and which did not.
5. No Phase 3 document describes `batch` as a unit of dispatch. Any surviving use is a different sense
   and is justified in place.
6. Exactly one refuter is dispatched per Phase 5 round, judging every finding.
7. Every validator pin naming the old agent path or the retired vocabulary is updated, and **each
   updated pin is proven to bite by tamper**, not merely observed green.
8. `scripts/sync_agent_mirrors.py --check` reports 9 of 9. `bash scripts/validate-dod.sh` exits 0 with
   0 FAIL. `dist/` regenerated across all 7 runtimes.
9. Version bumped, CHANGELOG entry written, README updated within its 450-line cap.

## 4. Approach

Rename first as one atomic wave, because the old path is referenced by the mirror map, the runtime
sync list and three validator fragments; splitting the rename across waves leaves the tree red in
between. Then change behaviour, then vocabulary, then the two dependent agents, then docs and release.

`batch` is retired by replacement rather than deletion: each site is read and rewritten to say what it
now means, because a blind find-and-replace would turn "dispatch batches" into "dispatch waves" in
places where the sentence was about something else.

### Repo Brief

- **Stack.** A Claude Code plugin. Markdown skills + reference docs, Python 3 helper scripts, Bash validators. No package manager, no build step.
- **Test / lint / typecheck.** `bash scripts/validate-dod.sh` is the triad. Unit tests: `python3 skills/lawkeeper/scripts/test_audit.py`, `bash hooks/test_inject_context.sh`, `bash hooks/test_block_banned_tokens.sh`, `bash scripts/test_ban_tokens.sh` (CI only, about 10s).
- **Layout.** `skills/<name>/SKILL.md` + `references/`; `agents/*.md` are registered subagents byte-mirrored from `skills/hackify/references/parallel-agents/*.md` by `scripts/sync_agent_mirrors.py --check` (9 of 9); `rules/*.md` inject per prompt; `dist/<runtime>/` generated by `scripts/sync-runtimes.sh` (786 files, 7 runtimes, gitignored); `scripts/validate-dod.d/*.sh` are numbered fragments sourced from a hand-maintained list at `scripts/validate-dod.sh:41-61`.
- **The one layering rule.** `dist/` is generated, never hand-edited.
- **Rules source.** User-global `~/.claude/CLAUDE.md` plus `rules/hard-caps.md`. No project CLAUDE.md.
- **Landmines.** (a) **Agent mirrors copy only the fenced block; frontmatter is NOT mirrored**, which has already caused two defects. (b) `70-invariants-and-new.sh` pins exact literal strings; rewording a pinned line breaks the pin silently if the pin is a prefix match. (c) README caps at 450 and sits at 448. (d) The three fragments that could not gain a line were split in wave 22 of the ledger sprint; `70-invariants-and-new.sh` is now 145, `77-reviewer-roster.sh` 269, and the moved checks live in `71-release-mechanism-pins.sh` and `79-standing-member-invariant.sh`. (e) `block-banned-tokens.sh` rejects em dashes. (f) `dist/copilot-cli/` is MANIFEST-only by design.

### The five sites that reference the old path by exact string

Found by survey, not by memory. A rename that misses one of these leaves a silently degraded agent.

| Site | Line | What it holds |
|---|---|---|
| `scripts/sync_agent_mirrors.py` | 53 | the mirror pair `("agents/wave-task-implementer.md", f"{PA}/phase-3-implementation.md")` |
| `scripts/sync-runtimes.d/00-helpers.sh` | 184 | the shipped-agents list |
| `scripts/validate-dod.d/60-primitives.sh` | 25 | registered agent-type list |
| `scripts/validate-dod.d/71-release-mechanism-pins.sh` | 283, 296 | two loops over both sides of the mirror pair |
| `scripts/validate-dod.d/20-templates.sh` | 237 | a comment naming the agent |

## 5. Sprint Backlog

Every task carries a `Files:` allowlist written **before** the edit. Reviewer B filed a Critical on the
last sprint for substituting a post-hoc census for pre-declared allowlists, on the grounds that a
census cannot fail. This backlog is the corrected shape.

### Wave 1, the rename (atomic, leaves the tree green)

- [ ] **T1** Rename the agent and every reference to its path.
  `Files:` `agents/wave-task-implementer.md` (git mv to `agents/wave-implementer.md`), `skills/hackify/references/parallel-agents/phase-3-implementation.md`, `scripts/sync_agent_mirrors.py`, `scripts/sync-runtimes.d/00-helpers.sh`, `scripts/validate-dod.d/60-primitives.sh`, `scripts/validate-dod.d/70-invariants-and-new.sh`, `scripts/validate-dod.d/20-templates.sh`

### Wave 2, the contract

- [ ] **T2** Rewrite the implementer contract: one wave per agent, no cap, #11-A failure semantics.
  `Files:` `skills/hackify/references/parallel-agents/phase-3-implementation.md`, `agents/wave-implementer.md`
- [ ] **T3** Update the type-to-INPUTS table for the renamed agent and its new inputs.
  `Files:` `skills/hackify/references/parallel-agents/README.md`

### Wave 3, Phase 3 vocabulary and the modes

- [ ] **T4** Retire `batch` as a Phase 3 unit; wave becomes the unit of dispatch.
  `Files:` `skills/hackify/references/phases/phase-3-implement.md`
- [ ] **T5** Full hackify mode text.
  `Files:` `skills/hackify/SKILL.md`
- [ ] **T6** Quick mode: whole change is one unit, one implementer.
  `Files:` `skills/quick/SKILL.md`
- [ ] **T7** Yolo mode: wave structure kept, per-wave dispatch.
  `Files:` `skills/yolo/SKILL.md`

### Wave 4, the dependent agents

- [ ] **T8** Refuters collapse to one per round over all findings.
  `Files:` `skills/hackify/references/parallel-agents/phase-5-refute.md`, `agents/finding-refuter.md`
- [ ] **T9** Phase 5 dispatch text for the single refuter.
  `Files:` `skills/hackify/references/phases/phase-5-review.md`
- [ ] **T10** Spec reviewer emits a wave plan, not dispatch batches.
  `Files:` `skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md`, `agents/spec-reviewer.md`

### Wave 5, guard the new vocabulary

- [ ] **T11** Pin the new agent path and the retired word so a future edit cannot silently reintroduce
  either. Every pin proven by tamper. **Note:** `77-reviewer-roster.sh` is at 499 of 500, so a pin
  landing there requires splitting that file first.
  `Files:` `scripts/validate-dod.d/70-invariants-and-new.sh`, `scripts/validate-dod.d/60-primitives.sh`

### Wave 6, docs and release

- [ ] **T12** README and the parallel-agents README table.
  `Files:` `README.md`
- [ ] **T13** CHANGELOG entry and version bump.
  `Files:` `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

## 6. Daily Updates

(Opened at Phase 3.)

## 7. Sprint Review

(Opened at Phase 4.)

## 8. Retrospective

(Opened at Phase 6.)

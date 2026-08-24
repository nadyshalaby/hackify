---
slug: wave-implementer-migration
title: One implementer per wave, and the vocabulary that follows it
status: implementing
type: refactor
created: 2026-08-23
project: hackify
current_task: W3:T5+T6+T7+T4b
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
- **Layout.** `skills/<name>/SKILL.md` + `references/`; `agents/*.md` are registered subagents byte-mirrored from `skills/hackify/references/parallel-agents/*.md` by `scripts/sync_agent_mirrors.py --check` (9 of 9); `rules/*.md` inject per prompt; `dist/<runtime>/` generated by `scripts/sync-runtimes.sh` (792 files, 7 runtimes, gitignored); `scripts/validate-dod.d/*.sh` are numbered fragments sourced from a hand-maintained list at `scripts/validate-dod.sh:41-61`.
- **The one layering rule.** `dist/` is generated, never hand-edited.
- **Rules source.** User-global `~/.claude/CLAUDE.md` plus `rules/hard-caps.md`. No project CLAUDE.md.
- **Landmines.** (a) **Agent mirrors copy only the fenced block; frontmatter is NOT mirrored**, which has already caused two defects. (b) `70-invariants-and-new.sh` pins exact literal strings; rewording a pinned line breaks the pin silently if the pin is a prefix match. (c) README caps at 450 and sits at 448. (d) The three fragments that could not gain a line were split in wave 22 of the ledger sprint; `70-invariants-and-new.sh` is now 145, `77-reviewer-roster.sh` 269, and the moved checks live in `71-release-mechanism-pins.sh` and `79-standing-member-invariant.sh`. (e) `block-banned-tokens.sh` rejects em dashes. (f) `dist/copilot-cli/` is MANIFEST-only by design.

### Every site that references the old path by exact string

Re-surveyed against disk at baseline `03e7a12` after Phase 2.5 falsified the first version
three ways: two line numbers had drifted and two whole groups were missing. The earlier table
claimed to be complete and was not, which is this project's recurring defect appearing in its
own plan.

**Group A, the path (`agents/wave-task-implementer.md`).** All of these belong to T1.

| Site | Line | What it holds |
|---|---|---|
| `scripts/sync_agent_mirrors.py` | 53 | the mirror pair `("agents/wave-task-implementer.md", f"{PA}/phase-3-implementation.md")` |
| `scripts/sync-runtimes.d/00-helpers.sh` | 185 | the shipped-agents list |
| `scripts/validate-dod.d/60-primitives.sh` | 25 | registered agent-type list |
| `scripts/validate-dod.d/71-release-mechanism-pins.sh` | 283, 296 | two loops over both sides of the mirror pair |
| `scripts/validate-dod.d/20-templates.sh` | 273 | a comment naming the agent |
| `README.md` | 265 | the agent roster |

**Group B, the AGENT-TYPE STRING `hackify:wave-task-implementer`. Nothing pins it.**

This is the dangerous group and the first survey missed it entirely. No validator anywhere
greps this string, so renaming the path leaves the tree fully GREEN while every dispatch site
below asks for an agent type that no longer exists. It fails at dispatch, not at validation.
Commit `dabc333` is the same defect: it shipped green and tagged, and quick mode dispatched a
retired agent in production.

| Site | Line | What it holds |
|---|---|---|
| `skills/hackify/SKILL.md` | 134 | full-mode Phase 3 dispatch |
| `skills/quick/SKILL.md` | 41 | quick-mode dispatch |
| `skills/yolo/SKILL.md` | 65 | yolo-mode dispatch |
| `skills/hackify/references/parallel-agents/README.md` | 20 | the type-to-INPUTS table |

Group B lands in T1 with Group A, because a wave that renames the path and leaves the type
strings behind is exactly the green-but-broken state this sprint exists to avoid.

**Group C, pins on the retired VOCABULARY, owned per wave by the single 71 owner.**

`71:287` `'Cap a batch at 3 tasks'` and `71:288` `'Group by module, never by count'` track T4's
file. `71:289-291` `'Cap a batch at 3 tasks'` tracks T10's two files. `71:303-305`
`'dies only when'`, `'only if the 1st refutes'`, `'identical either way'` track T8's file.
A pin edit and the prose it tracks MUST land in the same wave or `[38f]` reds at a wave end.

## 5. Sprint Backlog

Every task carries a `Files:` allowlist written **before** the edit. Reviewer B filed a Critical on the
last sprint for substituting a post-hoc census for pre-declared allowlists, on the grounds that a
census cannot fail. This backlog is the corrected shape.

### Wave 1, the rename (atomic, leaves the tree green)

- [x] **T1** Rename the agent, every reference to its path (Group A), and every agent-type
  string (Group B). One agent, 12 files, above the usual 30-minute band; atomicity forbids
  splitting it across waves, so budget for it instead.
  `Files:` `agents/wave-task-implementer.md` (git mv to `agents/wave-implementer.md`), `skills/hackify/references/parallel-agents/phase-3-implementation.md`, `scripts/sync_agent_mirrors.py`, `scripts/sync-runtimes.d/00-helpers.sh`, `scripts/validate-dod.d/60-primitives.sh`, `scripts/validate-dod.d/71-release-mechanism-pins.sh`, `scripts/validate-dod.d/20-templates.sh`, `README.md`, `skills/hackify/SKILL.md`, `skills/quick/SKILL.md`, `skills/yolo/SKILL.md`, `skills/hackify/references/parallel-agents/README.md`

  **Corrected by Phase 2.5, both directions.** The signed-off allowlist OMITTED
  `71-release-mechanism-pins.sh`, which the rename table itself lists at `:283,:296`, so
  `[38f]` would have thrown three FAILs at Wave 1 end and falsified "atomic, leaves the tree
  green". It also INCLUDED `70-invariants-and-new.sh`, which holds zero references; those
  checks moved to 71 during the ledger sprint. The allowlist named where the work used to be
  and missed where it moved to.

### Wave 2, the contract

- [x] **T2** Rewrite the implementer contract: one wave per agent, no cap, #11-A failure semantics.
  `Files:` `skills/hackify/references/parallel-agents/phase-3-implementation.md`, `agents/wave-implementer.md`
- [x] **T3** Update the type-to-INPUTS table for the renamed agent and its new inputs.
  `Files:` `skills/hackify/references/parallel-agents/README.md`

### Wave 3, Phase 3 vocabulary and the modes

- [x] **T4** Retire `batch` as a Phase 3 unit; wave becomes the unit of dispatch.
  `Files:` `skills/hackify/references/phases/phase-3-implement.md`
- [ ] **T4b** Phase 3 unit in the reference docs. Added by Phase 2.5: AC5 had uncovered sites.
  Note `orchestration.md:24` ("one implementer per task") and `template-contract.md:13` ("one
  agent each") are ALREADY stale against today's per-batch protocol, so this fixes pre-existing
  drift as well. `CHANGELOG.md:73` records that same defect being fixed in `SKILL.md` and never
  here.
  `Files:` `skills/hackify/references/work-doc-template.md`, `skills/hackify/references/orchestration.md`

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
- [ ] **T9b** Refuter fan-out prose. Added by Phase 2.5: AC6 had uncovered sites.
  `Files:` `skills/hackify/references/review-and-verify.md`, `skills/hackify/references/parallel-agents/template-contract.md`

- [ ] **T10** Spec reviewer emits a wave plan, not dispatch batches.
  `Files:` `skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md`, `agents/spec-reviewer.md`

### Wave 5, guard the new vocabulary

- [ ] **T11** Pin the new agent path, the AGENT-TYPE STRING (Group B, pinned by nothing today),
  the retired word, and the #11-A reporting sentence. Every pin proven to bite by tamper, per the
  protocol in AC7 below.
  `Files:` `scripts/validate-dod.d/70-invariants-and-new.sh`, `scripts/validate-dod.d/60-primitives.sh`, `scripts/validate-dod.d/71-release-mechanism-pins.sh`

  **The stale split warning is deleted.** It said `77-reviewer-roster.sh` "is at 499 of 500, so
  a pin landing there requires splitting that file first". Disk says 269 of 500, and the doc's
  own Repo Brief already said 269. That file was split during the ledger sprint and is in no
  task's allowlist, so the warning guarded a file out of scope and would have sent an
  implementer to split a file with 231 lines free.

  **Real headroom, measured at baseline `03e7a12`:** `76-phase-ledger-substrate.sh` 500/500
  (zero, and the cap test is `-gt`, so it passes today), `71-release-mechanism-pins.sh` 478/500
  (this sprint rewrites pins there in three waves plus a `RETIRED_TYPES` addition, so it is the
  tight one), `70` 145/500, `60` 80/500, `README.md` 448/450.

  **Also pin what #11-A actually promised.** `phase-3-implementation.md:107-108` says "report
  what you completed, report why you stopped". Only `STOP there` is pinned (`71:297`); nothing
  reads the reporting sentence. That reporting half IS the mitigation the user was given in
  exchange for accepting a larger blast radius, so it ships pinned on both mirror sides.

- [ ] **T10b** Phase 2.5 phase doc, follows T10's finished output. Added by Phase 2.5.
  `Files:` `skills/hackify/references/phases/phase-2.5-spec-review.md`

### Wave 6, docs and release

- [ ] **T12** README release blurb. The parallel-agents README table is T3's file, not this one;
  the signed-off description claimed both and the allowlist carried one.
  **`README.md` is at 448 against a 450 cap** (`20-templates.sh:4`), so the new blurb has two
  lines. Pay for it by compressing an older one, never by raising the bound.
  `Files:` `README.md`
- [ ] **T13** CHANGELOG entry and version bump.
  `Files:` `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

### Wave 7, regenerate the shipped copies

- [ ] **T15** Run `scripts/sync-runtimes.sh` and re-run `sync_agent_mirrors.py --check`.
  Added by Phase 2.5: **AC8 demanded `dist/` regenerated across all 7 runtimes and no task ran
  the script.** A DoD bullet with zero covering hunks is the shape Reviewer B files Criticals on.
  Baseline at `03e7a12`: exits 0, syncs 792 files across 7 runtimes, dirties no tracked file.
  `Files:` `dist/` (generated, never hand-edited)

## 5a. Execution wave plan and dispatch batches, from Phase 2.5

**The governing constraint.** A pin edit in `scripts/validate-dod.d/71-release-mechanism-pins.sh`
and the prose change it tracks MUST land in the same wave. Either order across waves leaves
`[38f]` red at a wave end, which breaches the guardrail above. 71 is one file, so **exactly one
task per wave may own it.**

```
Wave 1: [T1] solo, 12 files, atomic
Wave 2: [T2, T4] sole owner of 71 this wave;  [T3] solo
Wave 3: [T5, T6, T7] mode skills;             [T4b] solo
Wave 4: [T8, T10] sole owner of 71 this wave; [T9, T9b] Phase 5 refuter prose
Wave 5: [T11] sole owner of 71 this wave;     [T10b] solo
Wave 6: [T12, T13] release artifacts
Wave 7: [T15] solo
```

`[T2, T4]` and `[T8, T10]` sit in different directories, so the single-owner rule on 71
overrides the same-module grouping heuristic here. Two agents editing 71 concurrently is a
conflict edge; one agent holding both the prose change and the pin that tracks it is not.

Waves 1 and 5 each hold one solo task. Both are forced, by rename atomicity and by a pin only
being able to follow the prose it tracks. No rebalance.

## 5b. AC7, how a pin is proven to bite

The signed-off plan said "every pin proven by tamper" and owned no method, which Phase 2.5
filed as an Important. The ledger sprint proved a tamper matching nothing passes a validator
identically to a correct pin. Three ways a tamper lies, each one this repo has produced:

1. **The no-op tamper.** A `sed` whose pattern matches nothing edits nothing, so green means
   the tree is unchanged, not that the pin is sound.
2. **The neighbour trip.** The tamper reddens a DIFFERENT pin and the red reads as success.
3. **The cross-tree comparison.** Before and after measure different trees because something
   else moved in between. An implementer retracted exactly this claim last sprint.

So per pin, the evidence is four artifacts, not a verdict: the diff of the tamper proving it
was not a no-op, the FAIL line verbatim showing the pin's OWN check id, the restored validator
tail showing green again, and the commit sha identical before and after. Tamper on a scratchpad
copy, and restore by file rather than `git checkout`, which would revert real work too.

## 5c. What AC3's "is registered" can and cannot prove this session

Measured after T1 landed. The running harness loads the INSTALLED plugin at
`~/.claude/plugins/cache/hackify-marketplace/hackify/0.13.1/agents/`, which still holds
`wave-task-implementer.md`. This repo is the SOURCE, now at 0.14.2, and holds
`wave-implementer.md`. They are different trees.

Two consequences, both operational:

1. **Every remaining wave dispatches `hackify:wave-task-implementer`, the OLD type**, because
   that is what resolves in this session. The new type cannot resolve until the plugin is
   reinstalled at a version carrying the rename. This is not a defect and needs no workaround;
   it just means the sprint renames an agent while running the previous release of itself.

2. **AC3's "is registered" is verifiable structurally and NOT behaviourally this session.**
   The file exists, `60-primitives.sh` lists it, and the mirror check passes, so the structural
   half is proven. That a dispatch of `hackify:wave-implementer` actually RESOLVES cannot be
   proven here, and no green check in this repo proves it either. Recording that gap rather
   than letting the green triad imply coverage it does not have, which is this project's
   recurring defect. First real dispatch after reinstall is the only evidence that closes it.

## 6. Daily Updates

### 2026-08-23, Wave 1, the rename (T1)

Landed as commit `58c1118`. `agents/wave-task-implementer.md` moved to
`agents/wave-implementer.md`, and every reference to the old path (Group A) plus every
`hackify:wave-task-implementer` agent-type string (Group B) was rewritten in the same wave, so
the tree never sat green-but-broken. The only surviving occurrence of the old string anywhere
outside `dist/` and this doc is `CHANGELOG.md:778`, which is a historical release note describing
what shipped at the time and is correct to leave alone.

Follow-up commit `fb4f3c5` recorded §5c: the running harness resolves agent types from the
INSTALLED plugin at 0.13.1, which still carries the old file, so the remaining waves dispatch
`hackify:wave-task-implementer` and AC3's "is registered" is proven structurally, not behaviourally.

### 2026-08-24, Wave 2, the contract (T2, T3, T4)

Written by the wave implementer in the previous session, left uncommitted and unrecorded; this
session verified it, ticked it and committed it. Nothing was rewritten on resume.

- **T2**, the implementer contract now takes a whole wave. `{{task_ids}}` is every task in the
  execution wave rather than a same-module subset, steps 2-7 (the rule quoting) are stated as a
  once-per-wave fixed cost, and #11-A ships as its own paragraph: stop at the first task you
  cannot finish, keep everything already on disk, name which IDs landed and which did not. The
  OUTPUT skeleton gained a `## Wave status` header so the parent reads the landed/not-landed
  split instead of counting headings. The VERIFICATION clause was inverted to match: a failure
  the agent cannot fix inside its allowlist now MUST still produce OUTPUT, where before it
  suppressed the report entirely, which would have hidden which of N tasks were on disk.
  Both mirror sides edited together, `sync_agent_mirrors.py --check` stays 9 of 9.
- **T3**, the type-to-INPUTS table now describes one implementer per wave and lists the full
  input set the contract actually reads, which had drifted to a six-item subset.
- **T4**, the Phase 3 protocol drops batching. The "Batch the wave before you dispatch" section
  became "The wave is the unit of dispatch", the 3-task cap and the group-by-module rule are gone,
  and the wall-clock trade is stated plainly rather than sold as a speed win.
- **The pins that track T4's prose** moved in the same wave, as §5a requires. `[38f]` no longer
  reads `Cap a batch at 3 tasks` or `Group by module, never by count` out of the Phase 3 phase
  doc, and its comment now explains that the spec reviewer keeps its own cap pin until T10
  retires it.

**Wave-end evidence.** `bash scripts/validate-dod.sh` exits 0 with 0 FAIL (1419 ok lines).
`python3 scripts/sync_agent_mirrors.py --check` reports 9 of 9. Law-scout over the five touched
files: 0 findings, and honestly a thin scan, all five are `.md`/`.sh` so only the file-line cap
and the project ban list applied. Perf-scout: no candidates, four prose docs and a validator
fragment whose diff removes two checks and rewrites a comment.

## 7. Sprint Review

(Opened at Phase 4.)

## 8. Retrospective

(Opened at Phase 6.)

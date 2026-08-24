---
slug: wave-implementer-migration
title: One implementer per wave, and the vocabulary that follows it
status: implementing
type: refactor
created: 2026-08-23
project: hackify
current_task: W7:T14+T15
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
- [x] **T4b** Phase 3 unit in the reference docs. Added by Phase 2.5: AC5 had uncovered sites.
  Note `orchestration.md:24` ("one implementer per task") and `template-contract.md:13` ("one
  agent each") are ALREADY stale against today's per-batch protocol, so this fixes pre-existing
  drift as well. `CHANGELOG.md:73` records that same defect being fixed in `SKILL.md` and never
  here.
  `Files:` `skills/hackify/references/work-doc-template.md`, `skills/hackify/references/orchestration.md`

- [x] **T5** Full hackify mode text.
  `Files:` `skills/hackify/SKILL.md`
- [x] **T6** Quick mode: whole change is one unit, one implementer.
  `Files:` `skills/quick/SKILL.md`
- [x] **T7** Yolo mode: wave structure kept, per-wave dispatch.
  `Files:` `skills/yolo/SKILL.md`

### Wave 4, the dependent agents

- [x] **T8** Refuters collapse to one per round over all findings.
  `Files:` `skills/hackify/references/parallel-agents/phase-5-refute.md`, `agents/finding-refuter.md`
- [x] **T9** Phase 5 dispatch text for the single refuter.
  `Files:` `skills/hackify/references/phases/phase-5-review.md`
- [x] **T9b** Refuter fan-out prose. Added by Phase 2.5: AC6 had uncovered sites.
  `Files:` `skills/hackify/references/review-and-verify.md`, `skills/hackify/references/parallel-agents/template-contract.md`

- [x] **T5b** The three surviving "parallel waves" claims, found by the Wave 3 implementer and
  confirmed on disk. Two are section headings (`SKILL.md:130`, `phase-3-implement.md:1`); the third
  is Reviewer F's stated justification at `SKILL.md:183`, "Phase 3's parallel waves build each half
  of a feature blind to the other", which THIS sprint falsifies for the within-a-wave case. F still
  earns its place, one agent per wave is still blind to the waves before it and to pre-existing
  code, so the sentence is rewritten, never deleted. `SKILL.md:183` carries the pinned string
  `B is the standing member of every wave`, which must survive.
  `Files:` `skills/hackify/SKILL.md`, `skills/hackify/references/phases/phase-3-implement.md`

- [x] **T10** Spec reviewer emits a wave plan, not dispatch batches.
  `Files:` `skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md`, `agents/spec-reviewer.md`

### Wave 5, guard the new vocabulary

- [x] **T11** Pin the new agent path, the AGENT-TYPE STRING (Group B, pinned by nothing today),
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

- [x] **T3b** The refuter's type-to-INPUTS row. Added by Wave 4. It lists `finding_verbatim`,
  `lens`, `project_root`, `head_sha`; `lens` is the input T8 just retired, and the other three were
  **already drifted** against the template's `findings_batch` / `base_sha` / `head_sha` before this
  sprint. This is a row a dispatcher builds a call from, so it is the Group B defect class again:
  wrong, load-bearing, and pinned by nothing.
  `Files:` `skills/hackify/references/parallel-agents/README.md`

- [x] **T5c** The rest of the falsified Reviewer F justification, plus two retired words. Added by
  Wave 4. F's own template still says it exists "because Phase 3 builds in parallel waves: separate
  agents write separate files with no sight of each other", which this sprint makes untrue inside a
  wave. Same rewrite as T5b, and the same rule: F is not weakened, its reason is corrected. The
  agent side is a mirror pair, so its frontmatter `description:` needs a hand-edit the sync script
  will neither make nor complain about.
  `Files:` `skills/hackify/references/parallel-agents/phase-5-multi-review-f-coherence.md`, `agents/code-reviewer-coherence.md`, `skills/quick/SKILL.md`, `skills/yolo/SKILL.md`

- [x] **T10b** Phase 2.5 phase doc, follows T10's finished output. Added by Phase 2.5.
  `Files:` `skills/hackify/references/phases/phase-2.5-spec-review.md`

### Wave 6, docs and release

- [x] **T11b** The orchestrator's hand-maintained fragment map at `scripts/validate-dod.sh:18-22`
  names which check ids fragment 70 owns and does not list `[40]`. Found by the T11 implementer,
  which correctly refused to edit a file outside its allowlist. **Nothing reds on the omission:**
  `[76i]` only checks a row's range endpoints, and this row's last item (`[39]`) is not a range, so
  its upper end is skipped by construction. A hand-kept record that has quietly gone stale, which is
  this repo's most-repeated defect, appearing again inside the sprint that keeps finding it.
  `Files:` `scripts/validate-dod.sh`

- [x] **T12** README release blurb. The parallel-agents README table is T3's file, not this one;
  the signed-off description claimed both and the allowlist carried one.
  **`README.md` is at 448 against a 450 cap** (`20-templates.sh:4`), so the new blurb has two
  lines. Pay for it by compressing an older one, never by raising the bound.
  `Files:` `README.md`
- [x] **T13** CHANGELOG entry and version bump.
  `Files:` `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

### Wave 7, regenerate the shipped copies

- [ ] **T14** The README hero animation still labels Phase 3 "parallel waves". Found by the parent
  while Wave 6 was in flight. `scripts/gen-demo-gif.py:28` holds `(3, "Implement", "parallel waves")`
  in its `PHASES` table, and that string is rendered into `docs/assets/hackify-demo.gif`, which the
  README embeds. Nothing checks it, so it would have shipped stale. The standing project rule is to
  refresh the GIF whenever the phases change, and a phase's description changing is that. Pillow
  12.1.1 is present, so the regeneration runs here.
  `Files:` `scripts/gen-demo-gif.py`, `docs/assets/hackify-demo.gif`

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

### 2026-08-24, Wave 3, the modes and the reference docs (T5, T6, T7, T4b)

Dispatched as ONE agent for the whole wave rather than the two batches §5a planned. That grouping
came from the module heuristic T4 deleted one wave earlier, so following it would have meant
dispatching by a rule this sprint had already retired. Same tasks, same allowlists, one fewer agent.
This is the first wave run under the contract the sprint is writing.

- **T5**, full hackify. Phase 3 now dispatches exactly one subagent per wave, no cap and no module
  split, with each task keeping its own allowlist and the wave bounded by their union. The Phase 2.5
  lines say wave plan instead of dispatch batches, which runs one wave ahead of the spec-reviewer
  template that T10 corrects next. Three sites past the named list carried the same assumption and
  were fixed with it: the phases table, the "split the wave first" rule, and the pipelined-fan-out
  example that used a wave as its illustration.
- **T6**, quick. Per #13-A the whole change is the unit: split into file-disjoint units as before,
  but hand all of them to one implementer. Splitting now writes the allowlists rather than driving
  the dispatch count, and the "atomic change dispatches alone" sentence went with the old rule.
  Quick's refuter language was already at the target state and was left alone.
- **T7**, yolo. One agent per wave, waves still in dependency order. Three more sites claiming
  parallel waves were corrected, including the workflow diagram.
- **T4b**, reference docs. The work-doc template's Execution waves block now names task IDs in run
  order (`W1: T1, T3, T2`) instead of bracketed module groups. `orchestration.md` had a row reading
  "one implementer per task" that was **already stale before this sprint**, since the protocol was
  per-batch when it was written; it now reads one implementer for the whole wave. The 2-task wave
  was removed as an example of a flat parallel batch, because a wave is no longer one.

**Wave-end evidence.** Validator exits 0 with 0 FAIL. Mirrors 9 of 9. All 21 pinned literal strings
across the five files verified present by an independent check, not by trusting the agent's report.
No em or en dashes. No surviving `hackify:wave-task-implementer`. Law-scout: 5 files, 0 findings,
0 unaccounted, and thin again for the same reason as Wave 2. Perf-scout: no surface.

**One finding the agent surfaced, now tracked as T5b.** Three places still claim Phase 3 runs
parallel waves. Two are headings. The third is the reason given for Reviewer F existing at all,
and this sprint weakens it: F was justified by parallel waves building each half of a feature
blind to the other, and within one wave that is no longer true. F still earns its place across
waves and against pre-existing code, so T5b rewrites the justification rather than dropping the
reviewer.

**A constraint that dissolved.** §5a's rule that only one task per wave may own
`71-release-mechanism-pins.sh` existed to stop two concurrent agents colliding on one file. With
one agent per wave there is no concurrency to collide, so the rule is moot from here on. Recording
it because it is the first measured benefit of the change beyond token count.

### 2026-08-24, Wave 4, the refuter and the spec reviewer (T8, T9, T9b, T10, T5b)

One agent, five tasks, plus both sets of validator pins that track them. The §5a rule that only one
task per wave may own `71-release-mechanism-pins.sh` is moot now, as Wave 3 noted: with one agent
there is no second writer to collide with.

- **T8**, the refuter collapses to one agent per round, and the Critical bar survives the collapse.
  Decision #14-A alone would have weakened a real safety property: today a Critical dies only when
  two independent agents both refute it, and one agent means one refutation kills it. The pin
  guarding that rule said so in as many words. The user was shown this and chose **#2-A**: one
  agent, but a Critical may only be refuted when BOTH lenses fail, reproduction and authority, each
  with its own file:line counter-citation. Reproduction refutes while authority upholds and the
  Critical lives. Important and Minor still die on one refutation. `{{assigned_lens}}` is retired as
  an input, since the single agent always carries both. The Critical's OUTPUT shows each lens
  verdict separately, because a merged verdict hides exactly the thing the rule protects.
- **T9, T9b**, the same rule restated wherever it was written down: the Phase 5 protocol, the
  review-and-verify decision-table step, and the sub-agent contract's mandatory list. The sentence
  that a Critical may never be pushed back on a single refutation survives, restated as a single
  lens. `template-contract.md:13` also carried a **pre-existing** Phase 3 defect, saying a wave's
  tasks go to one agent each; that is the third file found carrying that same stale claim.
- **T10**, the spec reviewer stops emitting dispatch batches. Its whole batching step is gone, not
  blanked, and the steps after it renumbered. Wave capping and file-disjoint partitioning stay,
  because those two properties are the entire reason one agent can safely take a whole wave.
- **T5b**, the three surviving "parallel waves" claims. Two headings, and Reviewer F's reason for
  existing. F is not weakened: its justification now rests on what is still true, that a wave's
  implementer is blind to the waves before it and to every line of pre-existing code, which is
  where a producer and its consumers drift apart.

**Pins moved with the prose they track.** Removed `only if the 1st refutes`, `identical either
way`, `Cap a batch at 3 tasks`. Added `ONE refuter agent per review round`, `BOTH lenses fail`
(over both mirror sides), `one dispatched implementer per wave` and `no two tasks share a file`
(over both spec-reviewer sides). Every pin comment was rewritten to argue the new rule, because a
pin whose comment still defends the retired rule is worse than no comment.

**Wave-end evidence.** Validator exits 0 with 0 FAIL (1422 ok lines). Mirrors 9 of 9. `71` at 483
of 500. Ten files touched, all ten inside the wave's union. Law-scout: 10 files, 0 findings, 0
unaccounted. No em or en dashes. METHOD steps and VERIFICATION items in the renumbered spec-reviewer
independently re-checked: both run 1..20 with no gap or duplicate, and every cross-reference
resolves, including the `14 to 20` / `14-19` pair, which name the whole lens and its checks
respectively and are both correct.

**The implementer reproduced §5b's no-op tamper on itself, and said so.** Its first tamper on
`BOTH lenses fail` appended a character outside the pinned phrase, so the phrase still matched and
the validator printed green. It caught that, redid the tamper inside the phrase, and only then did
the pin bite. This is the exact failure mode §5b was written about, reproduced by an agent that had
read §5b. AC7's full four-artifact protocol still belongs to T11; what Wave 4 has is a
presence-and-bite spot-check, and the doc should not claim more.

**What Wave 4 found beyond its own scope**, now tracked rather than mentioned. `SKILL.md` was still
instructing a dispatcher to send two refuters per Critical, which would have falsified AC6 while the
tree stayed green; the implementer fixed it in place under T5b's allowlist and flagged it. Two more
live sites are new tasks: **T3b** (the refuter's type-to-INPUTS row, three of whose four inputs were
wrong even before this sprint) and **T5c** (F's justification in its own template and mirror, plus
two retired words in quick and yolo). README's copies belong to T12.

### 2026-08-24, Wave 5a, the last of the retired vocabulary (T10b, T3b, T5c)

Three agents were spent on this wave. The first died on a dropped connection partway through T5c;
the second stalled after 600 seconds with one act completed; the third finished. **Nothing was
redone across any of it.** See the Retrospective for the plan change that followed and for what the
failures actually cost.

- **T10b**, the Phase 2.5 phase doc stops describing the dispatch batches T10 deleted from the
  reviewer's output. It now names the one section the reviewer really emits.
- **T3b**, the refuter's type-to-INPUTS row. It listed `finding_verbatim`, `lens`, `project_root`,
  `head_sha`. `lens` was retired by T8 the wave before; the other three were **already wrong before
  this sprint** against the template's real `project_root` / `base_sha` / `head_sha` /
  `findings_batch`. This is the Group B defect class again: a row a dispatcher builds a call from,
  wrong, load-bearing, and pinned by nothing. T11 fixes the pinned-by-nothing half.
- **T5c**, the rest of Reviewer F's falsified justification, in five places across four files.

**T5c turned out to be bigger than its own description.** It was scoped as a prose fix to F's stated
reason for existing. The first agent noticed that F's METHOD rested on the same assumption and was
now backwards: it told F to audit same-wave seams FIRST, because same-wave files came from agents
blind to each other. One agent per wave makes that exactly wrong. Same-wave files now come from one
context that saw both sides, and the risky seams run ACROSS wave numbers, or out to a consumer the
diff never touched. The agent inverted the method, its VERIFICATION item, and the `{{task_file_index}}`
dispatch note together. A later agent found `phase-5-review.md:15` still telling the dispatcher the
old version, which was outside the planned allowlist and was added to it.

**This is the second time this sprint that changing a rule falsified the REASON another component
was given for existing**, after Reviewer F's own justification in Wave 4. Both were caught by
reading the neighbours rather than by any check. Nothing in the validator can see a rationale that
has quietly become untrue, which is worth saying out loud rather than trusting the green triad to
imply otherwise.

**Wave-end evidence.** Validator exits 0 with 0 FAIL. Mirrors 9 of 9. Law-scout: 7 files, 0
findings, 0 unaccounted. No em or en dashes. Every pinned literal across the touched files verified
present. `git grep` for the three retired claims returns only `README.md:101`, which is T12's file
in Wave 6, and `CHANGELOG.md`, which is release history and correctly keeps them.

### 2026-08-24, Wave 5c, the pins and their proof (T11)

Check `[40]` lands in `70-invariants-and-new.sh` at 245 of 500, carrying four pins. `71` was not
touched: it sits at 483 of 500 and could not take a block this size.

- **The live agent type** `hackify:wave-implementer` must be present at all four dispatch sites.
  This closes Group B, the gap that let the rename ship green while every dispatch site named a
  type that no longer resolved. The site list carries its own length hand-written beside it, so
  dropping a site cannot quietly take that site's check away with it.
- **The retired type must be absent** from every live file, by `git grep` over the tracked tree
  minus `dist/`, `docs/work/`, `CHANGELOG.md` and the fragment itself.
- **The #11-A reporting half** on both mirror sides. `71` already pinned the stopping half
  (`STOP there`); the reporting half was unpinned, and it is the mitigation that bought one agent
  per wave its wider blast radius. This sprint spent that mitigation twice in one afternoon.
- **The three retired batching phrases** are banned by the same scan. The bare word `batch` is
  untouched, because the wizard and flat-subagent senses are still correct.

**AC7 is met, and I checked it rather than accepting it.** The implementer's harness runs twelve
tamper steps, restores by copying a backup back rather than `git checkout`, and asserts three things
per step: the tamper diff is non-empty, every FAIL in the run is its own and the count matches
exactly, and the tree returns to one modified file. HEAD was identical before and after all twelve.
It added two controls the brief did not ask for: planting the banned strings in an EXCLUDED path and
proving the run stays green, which is what rules out a malformed pathspec that silently scans
nothing.

**My own independent tamper found a defect in MY method, not in the pin.** I broke the type string
in `skills/quick/SKILL.md` and read zero FAILs, which looked like a pin that does not bite. The pin
bites; my count did not. The validator's FAIL lines are ANSI-coloured, so a `^  FAIL` anchor never
matches, because the line begins with an escape sequence rather than two spaces. That pattern
reports zero on a red tree. Stripping the colour first shows
`FAIL 'hackify:wave-implementer' missing from skills/quick/SKILL.md`, exactly as claimed. **The
implementer's harness had already handled this**, with a `strip()` applied before every count, which
is why its numbers were sound and my spot-check was not. Recording it because a measurement that
always reads zero is precisely the class of defect §5b exists to catch, and this time it was the
parent producing it.

**Two facts in my dispatch brief were wrong, and the implementer went with disk over the brief.**
I said `CHANGELOG.md:778` carries `hackify:wave-task-implementer`; it carries the name without the
`hackify:` prefix, so the CHANGELOG exclusion waives nothing today and is future-proofing for a
release note not yet written. It said so in the comment rather than letting a later reader take the
row as load-bearing. It also found two retired phrases surviving in `docs/work/done/`, already
covered by the recursive exclusion.

**Wave-end evidence.** Validator exits 0 with 0 FAIL (1437 ok lines, up from 1422). Mirrors 9 of 9.
`70` at 245 of 500, `60` and `71` untouched. The implementer also ran the five CI gates that
`validate-dod.sh` does not cover, all green, plus `bash -n` and `shellcheck -x`.

### 2026-08-24, Wave 6, the release artifacts (T11b, T6b, T12, T13)

Version 0.15.0. A minor bump rather than a patch, because the dispatch behaviour changed and an
agent type was renamed, which breaks anyone naming it.

- **T11b**, `[40]` added to the fragment map in `scripts/validate-dod.sh`.
- **T6b**, the last "batched refuter" wording in quick mode. The brief named lines 10 and 20; the
  implementer found a third at line 43 and fixed it, since leaving it would have left the file
  contradicting line 53. It checked `[38g]`'s bans and `[77]`'s token set first to confirm no pin
  covered the phrase.
- **T12**, README at 449 of 450. The new blurb was paid for by demoting 0.14.1 to a one-line bullet,
  never by raising the bound.
- **T13**, CHANGELOG entry plus the version in four checked places, `hackify-edge` left at `main`.

**The implementer found two Phase 3 sites my brief missed**, both in README: line 71's "Phase 3
wave-task implementers", and line 98 describing the wave as dispatching "as one parallel batch of
foreground subagents", which is a Phase 3 document calling `batch` a unit of dispatch and is exactly
what AC5 forbids. My brief had reasoned about which `batch` senses to keep and named two of them,
and missed a third that was neither.

**It also caught a stale check in my own brief.** I told it to verify the ASCII box row with
`awk 'NR==80'`. Inserting the 0.15.0 section shifted the file by one, so the Phase 3 row is line 81,
and line 80 is now the Phase 2.5 row, which happens to be the same width. That command would have
reported a pass while measuring the wrong line. It said so rather than quoting the green.

**Its strongest piece of evidence was one nobody asked for.** Instead of comparing validator totals,
it diffed the full ok-line list against a clean worktree and showed **zero removed ok lines**, which
is the loss a total cannot see: a check that stops firing while the run still says ALL CHECKS PASSED.
`[0b]` is a floor and cannot catch that either. Every other difference was a value change on a line
that already existed.

**On the tag.** `v0.14.2` had never been cut. Nothing surfaced that until the version bump was
planned, because the check that enforces it exempts the in-flight version by design, so an untagged
release is invisible until the NEXT bump. The user chose #3-A and the tag was backfilled locally at
`78b30b0`, verified against `plugin.json` at that commit rather than the commit subject, matching how
`v0.14.0` and `v0.14.1` were backfilled. Nothing was pushed.

**Wave-end evidence.** Validator 0 FAIL, `ALL CHECKS PASSED`. README 449 of 450. Version `0.15.0` in
`plugin.json`, both marketplace channels, the stable ref and the README badge. Box row still 76
characters. Mirrors 9 of 9. Law-scout: 6 files, 0 findings, 0 unaccounted, 0 unsupported. The three
surviving `parallel batch` hits are the pin's own literal in `[40]` and two orchestration lines using
the flat-fan-out sense, which AC5 allows and which read unambiguously in place.

## 7. Sprint Review

(Opened at Phase 4.)

## 8. Retrospective

(Opened at Phase 6. Two findings recorded early, while the evidence was in front of me.)

### Out of scope, found mid-sprint, NOT fixed here

**`scripts/sync_agent_mirrors.py` treats every unrecognised flag as write mode.** `main()` tests
for `--list` and `--check` and falls through to `run(check_only=False)` for anything else, so
`--help`, `-h`, a typo, or a stray flag silently rewrites all nine mirror files instead of printing
usage. A Wave 5b agent hit this for real: it ran `--help` expecting usage text and got a full
resync. No damage, the resync happened to be what its task wanted, which is exactly why this kind
of defect survives. It is out of THIS sprint's scope (wave dispatch vocabulary), so it is recorded
rather than fixed, per the no-scope-creep rule. The fix is small: an explicit flag whitelist that
exits non-zero on anything unrecognised, and a `--help` that prints the usage block already sitting
in the module docstring at line 38.

### Wave planning was changed mid-sprint, after two agent deaths

Wave 5 as planned held T11, T10b, T3b and T5c. Its agent died on a dropped connection partway into
T5c; the re-dispatch stalled after 600 seconds with no output. Both deaths landed on the same wave,
and the common factor is length: T11's tamper protocol needs four artifacts per pin across four
pins, which is a long chain of validator runs inside one agent.

So the remaining backlog was re-planned into smaller waves rather than retried at the same size.
This is a PLANNING change, not a dispatch-time split: the new contract says the pre-flight plan is
the dispatch plan and is never regrouped at dispatch time, and re-planning after a failure is a
different act from quietly splitting a planned wave because it looked big. Recording it because an
unrecorded plan change is indistinguishable from the thing the contract forbids.

**What the failures cost, measured rather than asserted.** Nothing was redone. T10b and T3b landed
before the first death and were untouched by everything after. T5c's largest file survived both
deaths intact. The second agent's only completed act, the mirror resync, also survived. That is
#11-A working as designed, and it is the clearest evidence this sprint produced that the
keep-what-landed clause earns its place. The cost was real too: the first death left the tree RED
between waves, because one mirror side was edited and the other was not. A per-task dispatch would
not have done that. Both halves of the tradeoff showed up within an hour of shipping it.

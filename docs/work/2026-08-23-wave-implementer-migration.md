---
slug: wave-implementer-migration
title: One implementer per wave, and the vocabulary that follows it
status: reviewing
type: refactor
created: 2026-08-23
project: hackify
current_task: Phase 5, settle round dispatched (A, B, D, F over 03e7a12..657935b)
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

- [x] **T6b** The last "batched refuter" wording in quick mode, which T6 did not cover because T6
  was scoped to Phase 3 dispatch and this is Phase 5 vocabulary. Added by Wave 6, and **declared
  here after the fact rather than before it**, which is the defect Reviewer B filed as B3 in the
  settle round: it shipped in `2766b49` and was counted in the sprint review while this list never
  named it, so its allowlist existed only in the dispatch brief. Nothing was touched without
  authorization, `skills/quick/SKILL.md` already sat inside T6's and T5c's allowlists, and the
  bookkeeping is the whole of the defect. Every other late task in this sprint carries an
  "Added by" note; this one did not, and now does.
  `Files:` `skills/quick/SKILL.md`

- [x] **T12** README release blurb. The parallel-agents README table is T3's file, not this one;
  the signed-off description claimed both and the allowlist carried one.
  **`README.md` is at 448 against a 450 cap** (`20-templates.sh:4`), so the new blurb has two
  lines. Pay for it by compressing an older one, never by raising the bound.
  `Files:` `README.md`
- [x] **T13** CHANGELOG entry and version bump.
  `Files:` `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

### Wave 7, regenerate the shipped copies

- [x] **T14** The README hero animation still labels Phase 3 "parallel waves". Found by the parent
  while Wave 6 was in flight. `scripts/gen-demo-gif.py:28` holds `(3, "Implement", "parallel waves")`
  in its `PHASES` table, and that string is rendered into `docs/assets/hackify-demo.gif`, which the
  README embeds. Nothing checks it, so it would have shipped stale. The standing project rule is to
  refresh the GIF whenever the phases change, and a phase's description changing is that. Pillow
  12.1.1 is present, so the regeneration runs here.
  `Files:` `scripts/gen-demo-gif.py`, `docs/assets/hackify-demo.gif`

- [x] **T15** Run `scripts/sync-runtimes.sh` and re-run `sync_agent_mirrors.py --check`.
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

### 2026-08-24, Wave 7, the hero image and the shipped copies (T14, T15)

Last implementation wave. Every Sprint Backlog task is now ticked.

- **T14**, the README hero animation. `gen-demo-gif.py` held `(3, "Implement", "parallel waves")` in
  its `PHASES` table, rendered into a tracked binary the README embeds at the top of the page. It
  now reads `one agent per wave`, measured at 126px against a 165px tile before the edit rather than
  after.
- **T15**, `dist/` regenerated. 792 files across 7 runtimes, exit 0, matching the recorded baseline
  exactly. Mirrors 9 of 9. This closes AC8, which demanded the regeneration and which **no task in
  the signed-off plan actually performed**; Phase 2.5 caught that and added T15.

**The implementer refused to accept its own exit code, and was right to.** It compared rendered
pixel ink between the committed GIF and the new one, and reported the Phase 3 tile moving from
padding 37 / width 90 to padding 19 / width 126, which is arithmetically `(165-126)//2 = 19` and
therefore the new string and not merely a rewritten file. It used Phase 4's tile as an unchanged
control. Its reason for going that far is the best part: this repo **already recorded the same trap**
at `docs/work/done/2026-05-16-v0-2-5-gif-and-validate-split.md:138`, where a regeneration was taken
on faith. It also caught a naive crop diff reporting all six tags as changed, and identified it as
palette re-encode noise (mean 0.0 to 0.01 per channel) against roughly 8 for the real change, rather
than reporting six changes it could not explain.

**It corrected a premise in my brief.** I said `dist/` is gitignored at the root. It is not: there is
no `dist` line in `.gitignore`, and the mechanism is a nested `dist/.gitignore` containing `*` and
`!.gitignore`, so the contents are ignored while that file stays tracked. My check held, for a
different reason than I gave for it.

**Wave-end evidence.** Validator 0 FAIL, `ALL CHECKS PASSED`. Mirrors 9 of 9. `dist/` at 792 files
across 7 runtimes, per-runtime counts summing independently, `copilot-cli` at 1 file confirming
MANIFEST-only by design rather than thin output. GIF verified as `GIF (1200, 675) 7`. Working tree
carried only the two allowlisted files.

**One gap left open, deliberately.** Nothing verifies the GIF matches the `PHASES` table. T14 existed
precisely because that constant drifted with no check to catch it, and the gap is still there for the
next description change. Adding a check would be scope creep in this sprint, so it is recorded in the
Retrospective instead.

## 7. Sprint Review

Phase 4. Every row below carries fresh output from this phase, not a figure quoted from a wave-end.

### Evidence Ledger

| AC | Claim | Evidence | Verdict |
|---|---|---|---|
| 1 | A wave of N tasks dispatches exactly one agent, full + yolo | `exactly ONE subagent for the whole wave` in `hackify/SKILL.md`; `ONE agent for the whole wave however wide it is` in `yolo/SKILL.md`; `One planned wave dispatches exactly one agent` in `phase-3-implement.md`. Each present once | PASS |
| 2 | Quick dispatches one implementer for the whole change | `hand ALL of them to exactly ONE implementer` in `quick/SKILL.md` | PASS |
| 3 | `agents/wave-implementer.md` exists, registered, mirrors; old path gone | File present; `agents/wave-task-implementer.md` absent (`No such file`); listed in `60-primitives.sh` `AGENTS_EXPECTED`; mirror row `ok agents/wave-implementer.md matches phase-3-implementation.md` | PASS structurally. **Behavioural half NOT proven**, see below |
| 4 | The contract states #11-A explicitly | Both mirror sides carry `STOP there`, `KEEP everything that already landed on disk`, `which task IDs landed, which task IDs did not`, one occurrence each | PASS |
| 5 | No Phase 3 doc calls `batch` a unit of dispatch | All five retired phrases return zero live files. Six surviving `batch` uses inspected one by one: five are the wizard/tool-batch sense, six are orchestration's flat-parallel-fan-out sense. **One borderline line referred to Phase 5**, see below | PASS with one open question |
| 6 | Exactly one refuter per round, judging every finding | Seven files carry the one-refuter rule; `both lenses` appears in five. **Evidence corrected after B filed the original proof as unsound** (the four searches below never included the bare plural, so the row passed on a search that could not have failed). Re-run with `refuters` added: 6 live hits, every one accounted for by inspection, 5 in `CHANGELOG.md` describing past releases in the past tense (`:142`, `:152` under `## [0.12.0]`; `:271` under `## [0.9.0]`; `:10` says the refuters *collapsed*; `:306` is the role noun) and 1 in `orchestration.md:87` listing agent roles (`Implementers, reviewers, refuters and scouts`). Zero live rules claim more than one refuter per round. Original searches retained: `two refuters` 1 (CHANGELOG:271, historical), `two per Critical` 0, `second refuter` 2 (both CHANGELOG, historical), `batched refuter` 1 (CHANGELOG, historical) | PASS |
| 7 | Every pin updated, each proven to bite by tamper | Implementer harness: 12 tamper steps, ANSI stripped before counting, asserting non-empty diff + every FAIL is its own with matching count + tree restored, HEAD identical throughout, plus 2 excluded-path controls proving the scan is not vacuous. **Plus one independent tamper by the parent**, which reproduced `FAIL 'hackify:wave-implementer' missing from skills/quick/SKILL.md` | PASS |
| 8 | Mirrors 9 of 9; validator 0 FAIL; `dist/` across 7 runtimes | **Half proven, half deliberately stale.** Proven now: `validate-dod.sh` exit 0, 0 FAIL lines, `ALL CHECKS PASSED`; mirrors 9 of 9. NOT true right now: `dist/` is **100 files behind its live sources** (byte comparison, 785 dist copies with a live counterpart). It was 57 behind when B filed the finding; every fix wave since has widened the gap, which is expected and not a defect. B1 was re-severed to Important and routed to the Phase 6 landing step, so the regeneration is scheduled, not forgotten. **This row is not evidence until `sync-runtimes.sh` re-runs after the last fix lands and the stale count returns to 0.** | PENDING |
| 9 | Version bumped, CHANGELOG written, README within cap | `plugin.json` 0.15.0; marketplace 0.15.0 with stable ref `v0.15.0` and edge ref `main`; README badge `0.15.0`; `## [0.15.0]` heading present; README 449 lines against a 450 cap | PASS |

**Beyond the acceptance criteria**, the five CI gates `validate-dod.sh` does not cover all exit 0:
`test_audit.py`, `test_inject_context.sh`, `test_block_banned_tokens.sh`, `test_ban_tokens.sh`,
`check_question_clarity.py`.

### Ship gate

| Leg | Status | Evidence |
|---|---|---|
| `ship.build` | ✅ **PASS**, blocking | The diff touched `skills/` and `agents/`, which `sync-runtimes.sh` compiles. Ran it fresh: `OK, synced 792 files across 7 runtimes`, and 792 files across 7 runtime dirs counted independently rather than read off the message |
| `ship.boot` | ✅ **PASS**, blocking | The diff touched `plugin.json` and `marketplace.json`, both read at plugin load, and `skills/`. Both manifests parse under `jq`. The `UserPromptSubmit` hook was executed the way `hooks.json` invokes it, once per rules file: all four exit 0 and return a valid `hookSpecificOutput` envelope carrying real content (`hard-caps` 3653 chars, `expert-mindset` 2119, `perf-guardrails` 2727, `phase-discipline` 2779) |
| `ship.smoke` | ⚠️ **PARTIAL**, and this is the honest word for it | **Proven:** a fresh install carries the right artifact. `dist/claude-code/agents/wave-implementer.md` exists with frontmatter `name: wave-implementer`, the old file is absent, all three shipped mode skills name the live type once and the dead type zero times, and the shipped contract carries the #11-A clause. **Not proven:** that a dispatch of `hackify:wave-implementer` RESOLVES |

**A false start worth recording.** My first `ship.boot` attempt called the hook with no argument and read
zero bytes out of it, which looks exactly like a hook that injects nothing. It was my invocation that
was wrong: the hook takes the rules file as `$1` and exits 0 silently when it is missing, which is its
documented failure contract. Recorded because "the always-on rules emit nothing" is precisely the
shape of finding that should never be reported from a single unexamined command.

### The gap in AC3 and ship.smoke, stated rather than implied

§5c predicted this and Phase 4 measured it. The running harness resolves agent types from the
INSTALLED plugin at `~/.claude/plugins/cache/hackify-marketplace/hackify/0.13.1/agents/`, which holds
`wave-task-implementer.md`. This repo is the source, now at 0.15.0, and holds `wave-implementer.md`.
Confirmed on disk in Phase 4, not assumed.

Two consequences: **every wave this sprint dispatched used `hackify:wave-task-implementer`**, the old
type, because that is what resolves here; and the claim "a dispatch of the new type resolves" cannot
be proven in this repo by any check. The first real dispatch after a reinstall is the only thing that
closes it. **No green line in this sprint should be read as covering it.**

What the sprint DOES have as behavioural evidence is the protocol rather than the type string: seven
waves were dispatched one-agent-per-wave under the new rules, including two mid-wave agent deaths
where #11-A's keep-what-landed clause was exercised for real and nothing had to be redone.

### Phase 5 decision table, round 1

Panel: A (security), B (quality + plan, standing, unsliced), D (performance), F (coherence). **E folded**,
recorded, with the evidence: no UI, no styling, no token, no `docs/design/DESIGN.md` in the repo, residual
checklist nil. One refuter judged the whole round carrying both lenses, per #14-A and #2-A.

| # | Src | Sev | Finding | Verdict | Decision |
|---|---|---|---|---|---|
| 1 | F | Critical | `implement-and-test.md` still orders per-task dispatch | UPHELD both lenses, **worse than filed** | accept |
| 2a | B+F | Critical | `SKILL.md:18` "Parallel waves are what make hackify fast" | UPHELD both | accept |
| 2b | B | Critical | `SKILL.md:356` "Wave agents build blind to each other" | **REFUTED both** | push-back |
| 2c | B | Critical | `SKILL.md:3` frontmatter "parallel implementation" | UPHELD | accept |
| 2d | B | Critical | `README.md:127` yolo "parallel implementation" | UPHELD | accept |
| 2e | B | Critical | `README.md:379` "make parallel implementation safe" | UPHELD | accept |
| 2f | B+F | Critical | `README.md:416` "waits for all dispatched agents" | UPHELD | accept |
| 2g | refuter | Critical | **5 more sites the census missed** | found during refutation | accept |
| 3a | F | Critical | wave cap contradiction | **REFUTED both** | push-back |
| 3b | refuter | Important | `phase-2.5-spec-reviewer.md:79` "parallel tasks" | UPHELD (split out of 3a) | accept |
| 4 | B | Important | `[40]`'s "WAIVES NOTHING TODAY" comment is false | UPHELD | accept |
| 5 | F | Important | Execution-waves consumers still say "task batches" | UPHELD, **4 files not 2** | accept |
| 6 | F | Important | Reviewer E's INPUTS row omits `{{reference_images}}` | UPHELD, pre-existing | accept |
| 7 | F | Important | orchestration lost its Phase 3 dispatch example | **REFUTED** | push-back |
| 8 | B | Important | no CHANGELOG bullet for the GIF | UPHELD | accept |
| 9 | B | Important | `ref: v0.15.0` has no tag | UPHELD, narrowed to a Phase 6 obligation | accept at Phase 6 |
| 10 | A | Minor | `check_list_size` uses `wc -w` | **REFUTED** | push-back |
| 11 | A | Minor | `2>/dev/null` discards git's diagnostic | UPHELD | accept |
| 12 | B | Minor | `orchestration.md:123` "this wave needs the fan-out" | **REFUTED**, refuter overturned B | push-back |
| 13 | B | Minor | `[76i]`'s blind spot | UPHELD, but the skip is documented as deliberate | defer |
| 14 | F | Minor | `## Wave status` unwired | **ESCALATED to Important** | accept |

**The five refutations, each of which would have been a wrong edit.** 2b: "blind to each other" stays true
ACROSS waves, which is the surviving justification; it wants a reword to directional phrasing, not a
re-litigation. 3a: two senses of "cap", a planner-side one at plan time and no dispatch-side one, settled by
the anchor's own Out-of-Scope line. 7: `orchestration.md:24` IS the row that says what to dispatch a wave
with, and the finding cited the table containing it. 10: `:170` and `:181` word-split the same strings the
`wc -w` counts, so the count IS the iteration count and a space-bearing path reddens rather than slips.
12: bare "wave" for a review fan-out is this repo's established sense, cited at three live sites.

**#14's escalation is the most valuable thing the round produced.** `phase-3-implementation.md:243` tells the
parent to "Tick **all** wave checkboxes" while `phase-3-implement.md:101` says "tick the **completed**
checkboxes". On a wave that stops at task 5 of 9 those disagree, the stopped wave still passes the scoped
triad on its kept work, so the path is reachable rather than theoretical, and #11-A's whole reporting half
has no named reader anywhere in the tree. **This sprint used that report twice to recover from dead agents,
and did so because I read it, not because any instruction said to.**

**#13 is deferred, with the reason.** `76-phase-ledger-substrate.sh:390-394` documents the skipped upper
bound as deliberate ("Everything else is skipped BY CONSTRUCTION, not by exception list"). Changing it is a
design decision about the parser, not a defect fix, and it sits outside a sprint about dispatch vocabulary.

### Phase 5 address-all, the fix waves

The accepted findings were re-planned into two waves rather than one, on the lesson Wave 5 taught:
a long chain inside one agent is where this sprint's two agent deaths happened. The split is by
FILE SET, not by severity, so the two waves are disjoint and neither can red the other's tree.

**Fix wave A, the vocabulary sweep.** `implement-and-test.md`, `skills/hackify/SKILL.md`,
`README.md`, `skills/yolo/SKILL.md`. Findings #1, #2a, #2c, #2d, #2e, #2f, #2g. `README.md` is at
449 against a 450 cap, so every edit there had to be length-neutral.

**Fix wave A amendment, sent mid-run.** `SKILL.md`'s anti-rationalization row (`Wave agents build
blind to each other`) was originally excluded from the brief because a refuter REFUTED the finding
filed against it. That exclusion was withdrawn. The refuted claim and the defect are not the same
claim: with one agent per wave there is no "each other" INSIDE a wave for the noun to refer to, and
this release's own CHANGELOG already ships the corrected rationale one file over. Shipping a
release note that states the fix beside a skill file that still carries the falsified claim is the
exact defect class this release keeps finding. The row now reads what the CHANGELOG reads.

**Fix wave B, the protocol and validator sites.** Thirteen files, all small edits.
`70-invariants-and-new.sh` (#4, #11), `phase-3-implementation.md` and `phase-3-implement.md` (#14),
`phase-2.5-spec-reviewer.md` + mirror (#3b), the two Phase 5 reviewer templates + mirrors (#5),
`parallel-agents/README.md` (#6), `implement-and-test.md` (#15), `README.md` (#16), `CHANGELOG.md`
(#8). Dispatched in fix-ID order rather than file order, hardest first, so that a stop under #11-A
banks the two Criticals rather than the six one-phrase edits.

**Fix wave A landed clean, verified by the parent rather than taken on report.** `wc -l README.md`
reads 449 both before and after, `bash scripts/validate-dod.sh` prints `ALL CHECKS PASSED` with zero
FAIL lines once the colour is stripped, the mirror check reports 9 ok, and the amended
anti-rationalization row is on disk at `SKILL.md:356` carrying the CHANGELOG's own sentence. The
diff stayed inside its four files.

The agent also read past its brief and returned four things it deliberately did NOT touch, which is
the behaviour the contract asks for and the reason the list below exists at all:

- `implement-and-test.md`'s `## Commits (one per task)` heading contradicts the same file's wave-loop
  step and `phase-3-implement.md:38` (`Commit ONCE for the wave`). Promoted to **#15** and given to
  fix wave B. The agent called it out of scope on the grounds that commit granularity is not
  dispatch, which is a fair reading of ITS brief; it is still a live contradiction between two
  protocol files and one of the two sides is this sprint's own rule.
- `README.md:409`'s FAQ heading `How are the parallel subagents safe?` now heads an answer that is
  entirely wave dispatch. Promoted to **#16**. The agent left it under the do-not-over-correct
  constraint, correctly: research, review and refuter agents really are still parallel, so the
  question was whether the heading describes its own answer, not whether parallelism is real.
- `implement-and-test.md` and `README.md:416` say `Implementation Log entry` where the phase protocol
  says `Daily Updates entry`. Pre-existing naming divergence, not migration drift. NOT fixed here.
- `README.md:183` `waves of foreground agents` reads as still true (many waves, one agent each) and
  was named so nobody re-raises it. Agreed, no change.

One correction to the brief the agent caught: the required verification grep is case-sensitive, so
the `parallel Implement` in yolo's frontmatter would never have matched `parallel impl`. It
confirmed that site by direct inspection instead of trusting an empty grep, and said so. An empty
grep that was never capable of matching is the same failure this sprint has now recorded three
times, and this is the first time an agent caught it in a brief I wrote.

**Fix wave B landed all nine, verified by the parent.** Zero FAIL lines after colour stripping,
`ALL CHECKS PASSED`, mirrors 9, README still 449, `70-invariants-and-new.sh` grew 245 to 266 against
its 500 cap. The `task batches` and `Tick all wave checkboxes` greps both come back empty. Sixteen
files changed, all inside the allowlist, committed as `99526d4`.

**FIX 11 was proven with a control, which is the part that makes it evidence.** The tamper alone
would only show that a broken pathspec produces a message; it cannot show the message came from the
fix. So the agent ran a second pass that kept the same tamper and reverted only the redirection back
to `2>/dev/null`, and that pass printed `git: exited 128 without writing anything to stderr` where
the fixed version printed git's actual `fatal: Invalid pathspec magic 'bogusmagic'`. Same tamper,
different redirection, different output: the redirection is the cause. Restored by file with `cmp`
proving byte identity, never `git checkout`, and `git rev-parse HEAD` identical either side.

**Two scope calls the agent flagged rather than took silently, both accepted.** It tightened the
wave-commit step from `body lists task IDs` to `body lists the task IDs that landed`, on the ground
that a partial wave's commit body would otherwise name IDs that are not in the commit. That is the
same falsified class as the finding it was fixing. And it read "leave the conventional-commit format
block alone" as covering the first fenced template only, treating a second fence further down as in
scope because that one was an example that assumed one commit per task. Both readings are right, and
flagging them beat guessing.

**Scout dispositions, wave-end.** Law-scout over all 16 touched paths: 16 classified `unsupported`
(markdown and shell are outside the scanner's language set), 0 findings, and critically
`paths_unaccounted: 0`, so nothing was dropped without a row. That accounting field is the one 0.14.2
added after the scanner was caught discarding dotfiles as neither scanned nor skipped, and it is
doing its job here. Perf-scout: one candidate, `wi_absent` now spends a `mktemp` plus a `cat` plus an
`rm` per literal, four literals per validator run, so twelve extra process spawns. Dispositioned
`false-positive` under the catalog's "When NOT to optimize" guard: not a request path, not
data-sized, and the alternative (`2>&1`) is the bug the fix exists to avoid.

**The two waves run in sequence, not together.** Their file sets are disjoint, so nothing on disk
forces it. The orchestrator does: `scripts/validate-dod.sh` sources every fragment, so wave B
half-way through an edit to `70-invariants-and-new.sh` breaks the run for a wave A that never
touched it. A false red on a file an agent does not own is unfixable from inside its allowlist,
which is the shape that costs a whole round.

### Phase 5 settle round, the gate line

Base `03e7a12`, head `657935b`, `docs/work/*` excluded by construction. This is the round that has
to be clean on the diff actually on disk, so it covers the WHOLE sprint range and not just the fix
commit. Middle rounds scoped to a fix diff can never close the loop, which is the trap 0.14.2 was
written to get out of.

| Lens | Gate | Evidence |
|---|---|---|
| A, security and correctness | RUNS | The diff changes executable code: `wi_absent` in `70-invariants-and-new.sh` gained a `mktemp`, a `cat` and an `rm -f` per call, plus `sync_agent_mirrors.py`, `sync-runtimes.d/00-helpers.sh` and two JSON manifests. A validator that reports green while measuring nothing is a correctness defect, and this repo has shipped that three times. |
| B, quality and plan | STANDS | Standing member, never sliced, never gated. |
| D, performance | RUNS | Ambiguous rather than obviously applicable, so it runs, per the "when the evidence is ambiguous the reviewer runs" rule. It has exactly two things to look at: the per-literal subprocess work `wi_absent` now does four times a run, and a 227KB hero GIF embedded in the README. Both were named at dispatch so D does not have to invent work. |
| E, design conformance | FOLDS | No UI surface anywhere in the diff. The only non-text artifact is a regenerated terminal animation with no design spec, no tokens and no rendered screen to compare, and this repo has no `docs/design/DESIGN.md`. E's residual checklist was handed to B rather than dropped. |
| F, cross-module coherence | RUNS | The sprint's central risk and the one lens with a real target here. Its producers and consumers are documents, and the failure they keep producing is a rationale falsified by a rule change elsewhere. Four instances so far, none visible to any check. |

**The known limitation, stated rather than implied.** The harness resolves agent types from the
INSTALLED plugin at 0.13.1, while this repo is the source tree at 0.15.0. So every reviewer in this
round is running the 0.13.1 text of its own prompt, not the text sitting in the diff it is reviewing.
For a review that is acceptable, the reviewers are general enough that the older prompt still asks
the right questions, and each was given the sprint context at dispatch. For AC3 it is not, and that
gap is already recorded in its own section above. Recording it here too so the settle round's
evidence is not read as stronger than it is.

### Phase 5 settle round, findings

**Reviewer D, performance. Nothing this diff introduced.** No Critical, no Important, one Minor that
D itself attributes to code the diff never touched.

D re-judged the parent's perf-scout candidate and reached the same verdict on its own numbers, which
is the point of making it re-judge rather than inherit. It also corrected which half of the cost the
parent had named: on a 4.77 second green run over 247 tracked files, the `mktemp`/`cat`/`rm` cycle
the scout flagged costs 18ms across all four calls, while the four whole-tree `git grep` scans cost
50ms. The parent flagged the smaller half. Total is about 1.4% of the run, the loop is pinned to
three literals by `check_list_size` so it cannot grow with data, and there is no request path here,
so DISMISSED under the catalog's "When NOT to optimize" guard.

D also answered the hoisting question properly instead of waving it off: the catalog's own fix
direction for that ID (batch the screen, keep the per-item loop as the failure-path fallback) would
apply cleanly and would keep per-literal attribution. It is still below the threshold for action,
and filing it would be the speculative micro-optimization the catalog bans.

**The one finding, and why it is not this sprint's.** `scripts/gen-demo-gif.py:142` passes
`optimize=False`. Regenerating with `optimize=True` gives 135,296 bytes against the shipped 227,491,
a 40.5% cut, verified pixel-identical across all seven frames with duration, loop and dimensions
unchanged. D checked the two levers named at dispatch and reported both as already correct: seven
frames is minimal for the content, and a reduced palette makes it WORSE, `quantize(colors=32)` plus
optimize lands at 139,778, larger than optimize alone.

D was careful about attribution and said so unprompted: line 142 is byte-identical at `03e7a12`, the
only hunk in that file is line 28's caption string, and the +635 byte delta this sprint added is
just the longer caption. So this is a pre-existing defect surfaced by a question I asked, not a
regression this diff caused.

D also flagged its own catalog ID as an imperfect fit rather than forcing one, which is the right
behaviour: all seven `perf.bundle.*` IDs cover JS, font and dependency bloat and **none of them
covers raster media**, so the family named at dispatch had no valid ID. It used
`perf.frontend.unsized-images` and said which half of that ID applies.

**D's headline number was re-measured by the parent rather than taken on report,** because it is the
one finding that could change what ships. Re-rendering all seven frames from
`scripts/gen-demo-gif.py` and saving twice, once each way: `optimize=False` gives 227,491 bytes,
byte-for-byte the size of the shipped asset, and `optimize=True` gives 135,296. Pillow's own
`ImageChops.difference().getbbox()` returns `None` for all seven frames at 1200x675, so the two
files are pixel-identical. D's 40.5% is exact.

**Reviewer A, security and correctness. One Critical, and it is in code this sprint shipped an hour
before the review.**

**A1, Critical. `70-invariants-and-new.sh:229`, `err=$(mktemp)` is never checked, and the machinery
added to make `wi_absent` fail CLOSED is exactly what opens a fail-open.** When `mktemp` fails, `err`
is the empty string, so `2>"$err"` fails in the shell BEFORE git ever runs. Bash returns 1. And 1 is
git grep's honest "no match", so the failure routes straight into the green branch. All four
`wi_absent` calls fail open together, which means check `[40]` cannot fail at all. `[0b]`'s ok-line
floor does not catch it either, because a fail-open still PRINTS an ok line.

**The parent had already considered this exact case and dismissed it, wrongly.** The reasoning was
that a failing `mktemp` would produce a loud failure rather than a silent green. That is the part
that was wrong: the failure is loud on stderr and returns 1, and 1 is the one code that means
everything is fine. Being nearly right about the mechanism and wrong about the code is how a
fail-open ships.

**Reproduced by the parent end to end, not taken on report.** Plant `hackify:wave-task-implementer`
in `skills/quick/SKILL.md`, then run the validator twice against that same tree:

```
run 1, mktemp working
  FAIL [40] retired Phase 3 wording 'hackify:wave-task-implementer' survives in a live file:
run 2, same tree, PATH shimmed so mktemp exits 1
  ok   'hackify:wave-task-implementer' survives in no live file
```

Same tree, same literal planted, opposite verdicts. Restored by file, `git status` clean and HEAD
`ebb92b8` unchanged either side. The isolated mechanism confirms it too: an empty redirect target
returns rc 1 with empty output under bash, byte-identical in both respects to a clean scan.

**This falsifies the fragment's own comment**, three lines above, which claims `STATUS IS GIT GREP'S
ALONE`. That comment was true of the version it was written for and the FIX 11 rewrite made it
false, in the same sprint, for the fourth time. The sprint's signature defect reproduced itself
inside the fix for the sprint's signature defect.

Both refuter lenses uphold without a dispatch. Reproduction is discharged by the parent's own
demonstration above, and authority by the fragment's written invariant plus CWE-252 (unchecked
return value) and CWE-703. Dispatching a refuter to argue against a result I produced with my own
hands would be theatre, and #2-A's bar (a Critical dies only when BOTH lenses fail) is not close to
being met.

**A2, Important. This sprint deleted the pins on `phase-3-implement.md` and put the replacements
somewhere else.** `71-release-mechanism-pins.sh:285-292` now pins the mirror pair and the spec
reviewer. `76-phase-ledger-substrate.sh:71` still globs the file for tick lines, but nothing pins its
Phase 3 DISPATCH wording any more, and `[40]`'s four-file presence set omits it, because that file
names `hackify:spec-reviewer` and never names `hackify:wave-implementer`. Net effect: reverting
`phase-3-implement.md` to per-task fan-out runs green. That is a coverage regression this sprint
introduced while adding a check whose whole purpose is closing that class of hole.

**A3, Minor.** No `trap` around the temp file, so SIGINT between the `mktemp` and the `rm -f` leaks
it. **A4, Minor.** `for f in $WI_TYPE_SITES` at `:170` is unquoted word-splitting with no `set -f`,
while `WI_DEAD_WORDS` two blocks down uses a real array for the same job.

**A verified clean** and said so specifically rather than padding: the `sed` scripts are fixed
single-quoted literals so repository content reaches them only as stdin data, `red` and `green` pass
through `%s`, `rm -f ""` is inert, and the two JSON manifests are a clean 0.14.2 to 0.15.0 bump. It
also correctly declined to file the missing `v0.15.0` tag, which `[27d]` carves out for the
in-flight version by design.

**Reviewer F, cross-module coherence. Two Criticals, five Importants, two Minors, and it corrected
three of its own line numbers before reporting rather than after being challenged.**

F closed with the sentence that justifies the lens existing: `validate-dod.sh` prints ALL CHECKS
PASSED and `sync_agent_mirrors.py --check` passes all nine pairs, and every finding below survives
both. All four headline citations were re-read on disk by the parent before acceptance.

**F1, Critical. Yolo still instructs the conditional second-refuter dispatch this release deleted.**
`phase-5-refute.md:29` says there is `no conditional follow-up dispatch, and nothing to schedule in a
second message. Quick mode and yolo run the same single refuter.` `skills/yolo/SKILL.md:108` says
`A Critical still needs two refutations to die; the second refuter is dispatched only when the first
one votes to refute.` Lines 65 and 67 of that same table were updated in wave 4 and 108 was missed.
A dispatcher builds a real call out of this, so it is not prose drift.

**F2, Critical. A third Phase 3 protocol file still ticks the whole wave.**
`phase-3-implementation.md:243` now says `Tick ONLY the task IDs ... never the whole wave. Ticking a
task the agent never finished records work that is not on disk, which is the one thing a work-doc
must never do.` `implement-and-test.md:24` still says `Tick all wave Tasks checkboxes.` **Fix wave B
edited this exact file four lines below**, correcting its commit section, and left the tick step
standing. The finding it was sent to fix reproduced itself inside the file it was fixing.

**F3, Important. Same file, same wave, the other half of the same finding.**
`phase-3-implementation.md:239` says `Do not assert the reverse`, because a stopped wave writes a
strict subset of the allowlist union. `implement-and-test.md:20` still says
`git diff --name-only => should match the union of allowlists`, which is the reverse.

**F4, Important. Quick and yolo dispatch the implementer but never tell the parent to read
`## Wave status`.** Producer `agents/wave-implementer.md:188`, non-consumers `skills/quick/SKILL.md:41`
and `skills/yolo/SKILL.md:65`. An earlier F round already filed this, it was ESCALATED and accepted,
and the fix wired only the two full-hackify sites. **A finding fixed in two of its four places is a
finding that will be filed again**, and it was.

**F5, Important. `71-release-mechanism-pins.sh:294`'s comment still argues in the batch vocabulary
the release retired**, reasoning about `the whole reason one-agent-per-task felt safe` while pinning
text that no longer describes batches. Block (1) of that file was rewritten and block (2) was not.

**F6, Important. `phase-5-aggregation.md:5` names two trigger shapes that are both dead**, a wave of
implementers and the reviewer panel plus its refuters, against `phase-3-implementation.md:5` and
`phase-5-refute.md:29`.

**F7, Important. The F template contradicts itself three lines apart, and it is mirrored.**
`phase-5-multi-review-f-coherence.md:53` calls the `W<n>/` prefix `your same-wave signal`, while
`:54-56` say one agent writes a whole wave so same-wave files came from a context that saw both
sides, and the risky seams run ACROSS wave numbers. Same defect in `agents/code-reviewer-coherence.md`
at `:52` against `:55`. Parent's read: the wording is stale rather than contradictory, since the
prefix really is the wave marker and the sentence is only wrong about which direction it points.
Going to the refuter at Minor, not Important, with that argument stated.

**F8, F9, Minor.** `phase-3-implement.md:37` `Tick wave checkboxes` is ambiguous against its own
`:101`. `skills/hackify/SKILL.md:257` prohibits same-wave file sharing between agents, now vacuous,
and `:134` still says `N implementers`.

**F dropped a candidate rather than filing it, correctly.** `phase-3-implement.md:66` says
`No cap on wave width` while `phase-2.5-spec-reviewer.md:162` caps waves at `{{wave_size_target}}`.
F reconciled them itself: the INPUTS block at `:79-84` was deliberately rewritten this release to say
the cap `is not a width valve: it bounds how much work one implementer is asked to carry in one
context`. Different bounds at different times, coherent by design. That is the behaviour the refuter
exists to enforce, arriving before the refuter had to.

**One honest partial in F's verification.** The task-file index it was handed was commit-grouped with
no `W<n>/` prefixes, so it treated each commit group as a wave proxy and said so rather than claiming
the map it was promised. That is a defect in MY dispatch, not in F's audit: the F template asks for a
`W<n>/T<m>` map and I supplied a commit-to-file map instead.

**Reviewer B, quality and plan. Two Criticals, and both are acceptance criteria this sprint recorded
as PASSED.** Both were re-verified by the parent before acceptance.

**B1, Critical. AC8 was delivered and then invalidated four commits later, inside the same sprint.**
T15 (`69030e8`) regenerated `dist/`, 792 files across 7 runtimes, and the Evidence Ledger passes AC8
on that run. Then `99526d4` rewrote 15 source files and nothing re-ran `sync-runtimes.sh`. **57
shipped files are stale.** Parent's own count, by byte comparison of every `dist/` copy against its
source: 57, exactly B's number. The clearest single case is
`dist/claude-code/skills/hackify/SKILL.md:356`, which still reads `Wave agents build blind to each
other` while the source file it mirrors no longer contains that string anywhere. **The shipped
plugin still carries the exact rationales the fix commit exists to delete.** `dist/` is gitignored,
so no check in the repo can see it, and the Evidence Ledger row is measuring a state that stopped
being true four commits ago.

**B2, Critical. AC6's PASS is an artifact of the search string, not a property of the tree.** The
ledger passes AC6 on zero hits for `two refuters`, `two per Critical`, `second refuter` and
`batched refuter`. **The bare plural was never searched.** It survives at
`skills/hackify/references/orchestration.md:19` and at `:25`, in the row
`| Phase 5 | the evidence-gated reviewer panel, then the refuters |`, which sits ONE ROW BELOW the
Phase 3 row this same sprint corrected. Verified on disk by the parent. This is the fourth time this
sprint that a check looked precise and measured nothing, and the second time the cause was my own
choice of search string.

**B3, Important. T6b was delivered and counted but never declared.** It ships in `2766b49` and is
counted in the sprint review, and `## 5. Sprint Backlog` has no entry for it, so its file allowlist
exists only after the fact. B notes the backlog preamble records this exact defect drawing a
Reviewer B Critical last sprint. The content is fine: `skills/quick/SKILL.md` already sits inside
T6's and T5c's allowlists, so nothing was touched without authorization. The bookkeeping is the
defect.

**B4, Important. `71-release-mechanism-pins.sh:294`, the same stale rationale F filed as F5.** Merged,
one finding, two independent reporters.

**B5, Important. `phase-5-refute.md:194` and mirror `agents/finding-refuter.md:142` kept a 350-word
cap that was never re-reasoned** when #14-A collapsed N per-Critical dispatches into one whole-round
agent that now covers every severity and owes two lens lines per Critical. B points out Reviewer B's
own 650-word cap WAS re-reasoned for exactly this reason, so the precedent exists and was not
followed.

**B6, Important. `wi_absent`'s `rc>1` fail-closed branch has no test**, and
`scripts/test_ban_tokens.d/10-ban-list-cases.sh` already carries that exact case for the batched
screen. The pattern exists in this repo and was not followed. This lands on the same lines as A1.

**B7, Important. Five more documents still describing dead dispatch shapes**, beyond everything found
so far: `phase-5-aggregation.md:5` (merges with F6), `:24`, `:25`, `runtime-adapters.md:17`, and
`skills/review-triage/SKILL.md:3` frontmatter, which is harness routing text.

**B8, Important. The CHANGELOG has no bullet for the new parent-side protocol**, the union-is-a-
superset rule and the tick-only-what-landed rule at `phase-3-implementation.md:238,242` and
`phase-3-implement.md:99`.

**Minors.** `README.md:298` keeps `adversarial refuters` plural, five siblings fixed and this one
missed, and the file is at 449/450 so the fix must be length-neutral. `orchestration.md:122` is B's
ruling on the open question this sprint handed forward: the instruction is still right and only the
words `this wave` mislead, so reword to `this fan-out`. The CHANGELOG says `roughly fifteen more
sites` where B counts 16 to 18 and `99526d4`'s own subject says sixteen. The refuter template's first
OUTPUT bullet form is unlabelled while the second is not. And `wi_absent` sits in the fragment
closing over `WI_LIVE_PATHS` rather than in `00-helpers.sh`, which B correctly files as Minor only,
citing the extract-on-second-use rule against a single use.

**What B verified rather than assumed.** `PHASE5-FIXES` IS properly authorized: the work-doc's
address-all record names both waves, their exact file sets and the finding ID each edit closes, and
all 15 files appear there. Mirrors 9 of 9. All size caps met. No lint suppressions, no non-null
assertions, no empty catches, no bare `Error` throws anywhere in the diff. E's folded checklist was
run and returned nothing, which is the outcome the fold predicted.

### Phase 5 settle round, refutation and decision table

One refuter, both lenses, per #14-A and #2-A. 26 findings in, 6 refuted, 4 re-severed, 1 escalated.
The refuter exceeded its 350-word cap and said so in its first line, arguing that
`phase-5-refute.md:187` ("Never leave a finding unjudged") is the harder constraint. **That overrun
is the evidence for B5**, which is the finding about that very cap. A report that proves its own
finding by being written is the best kind.

**The headline it found that nobody filed: one word, three severities.** The bare plural `refuters`
survives at exactly six live sites, and B2 filed two of them Critical, B7 filed three Important and
B9 filed one Minor. Same one-word edit. It is ONE Minor cleanup task, not six findings at three
levels. It also protected `orchestration.md:87` (`Implementers, reviewers, refuters and scouts must
not propose a goal`) as a genuine role-class collective that must NOT be changed.

| ID | Verdict | Severity | Note |
|---|---|---|---|
| A1 mktemp fail-open | UPHELD, both lenses | Critical | Severity is not set by how likely mktemp is to fail. It is set by the repo having written the rule as "must never" at `70:213-218` and having a correct implementation of it at `00-helpers.sh:302-307`, one file away. |
| F1 yolo second refuter | UPHELD, both lenses | Critical | Half-right sentence: "two refutations to die" survives as two LENSES under #2-A. Rewrite to the lens framing, do not delete. |
| F2 tick all wave | UPHELD, both lenses | Critical | Ships to every runtime. |
| B5 refuter word cap | **ESCALATED to Critical** | Critical | The finding's own premise was false and the refuter said so: B's 650 cap was re-reasoned in v0.13.0 for the C-merge, not for #14-A. The real basis is that 350 was sized for a ONE-finding dispatch and #14-A handed one agent the whole round without rescaling. |
| B1 stale `dist/` | UPHELD, both lenses | **re-severed to Important** | And **explicitly do not fix in this round**: this round will change more source files, so regenerating now guarantees it goes stale again. Phase 6 landing step, then re-prove AC8. |
| B2 AC6 bare plural | UPHELD on authority only | **re-severed to Minor** | Reproduction REFUTED: neither cited line instructs a dispatch, a reader follows the protocol file. Authority upheld because `orchestration.md:25` sits in a table whose sibling rows DO carry counts, so the plural is not purely collective. Critical lives under both-must-fail, then merges into the one-word cleanup. |
| A2 unpinned phase doc | **REFUTED** | closed | Concrete counter: a literal revert reds on all three `WI_DEAD_WORDS`, because the base file at `03e7a12` contains all three phrases and is not excluded from `WI_LIVE_PATHS`. The stated net claim is false. Would change its mind: a REWRITE using none of the three phrases, shown green. |
| A4 unquoted word-split | **REFUTED** | closed | `WI_TYPE_SITES` is a string because `:169` counts it with `wc -w`; `WI_DEAD_WORDS` is an array because its elements contain spaces. Not the same job. Every element is a hardcoded glob-free literal. |
| B11 CHANGELOG count | **REFUTED** | closed | `roughly fifteen` is hedged and 16 sits inside the hedge. It also falsified the finding's own citation: "sixteen sites" is in the commit BODY, not the subject. |
| B13 `wi_absent` placement | **REFUTED** | closed | Moving it to `00-helpers.sh` would manufacture the hidden coupling global §2.8 bans, since it closes over fragment-local `WI_LIVE_PATHS`. Extract on the second use; there is one. |
| F7 F-template direction | **REFUTED** | closed | And it ruled on the parent's pre-downgrade explicitly: correct, and conservative. `:106` carries the right direction into METHOD. Free polish, not a finding. |
| D1 GIF `optimize=False` | **REFUTED as a Phase 5 finding**, re-routed | Phase 6 | Not disputing the measurement. `gen-demo-gif.py:142` is byte-identical at `03e7a12` and `phase-3-implement.md:97` forbids adjacent cleanup. Textbook Phase 6 offer-to-fix. |
| A3 no trap | UPHELD | Minor severity, **stronger fix** | Named two in-repo precedents with written rationale: `80-file-size-caps.sh:328-339` arm-and-clear around the window, and `check-collisions.sh:30-31`. Copy 80's shape, not a standing trap. |
| B3 T6b undeclared | UPHELD | Important | Every other late task (T4b, T5b, T5c, T3b, T10b, T11b, T14) carries an "Added by" note. T6b alone has none. |
| B4 / F5 stale pin comment | UPHELD | Important | Both upheld, and the refuter flagged a protocol error in MY dispatch: `phase-5-refute.md:26` says two-reporter findings bypass refutation, so these should never have reached it. |
| B6 untested fail-closed branch | UPHELD | Important | `test_ban_tokens.d/10-ban-list-cases.sh:108-140` already carries the `chmod 000` fail-closed pattern for both screens. **This is the test that would have caught A1.** |
| B7 / F6 dead-shape docs | UPHELD, **scoped down** | Important | `phase-5-aggregation.md:5`, `runtime-adapters.md:17`, `review-triage/SKILL.md:3` real. `:24` and `:25` REFUTED: file-disjointness is still live and pinned at `71:290-293`. |
| B8 CHANGELOG bullet | UPHELD | **re-severed to Minor** | The 0.15.0 Fixed bullet covers the class and no AC requires a per-rule bullet. |
| F3 union assertion | UPHELD | Important | Same file and same block as F2, four lines apart. One edit. |
| F4 quick/yolo Wave status | UPHELD | Important | Incomplete fix confirmed on disk. |
| B9 README plural | UPHELD | Minor | Length-neutral swap available: `adversarial refuters` to `the adversarial refuter`. |
| B10 orchestration wording | UPHELD, **citation off by one** | Minor | The defect is at `:123`, not `:122`, and BOTH halves of that line are now wrong, not just the two words I proposed rewording. |
| B12 unlabelled OUTPUT form | UPHELD | Minor | First-hand evidence: the refuter hit the ambiguity formatting this very report and had to resolve it from `:210-213`. |
| F8 ambiguous tick line | UPHELD | Minor | Correctly Minor: that file disambiguates itself, where F2's two files contradict outright. |
| F9 vacuous same-wave rule | UPHELD, **scope corrected** | Minor | `:257` is NOT vacuous: its parenthetical states a live invariant pinned at `71:290-293`, and parallel agents still run in Phases 1 and 5. Reframe, do not delete. `:134`'s `N implementers` is defensible across waves. |

**One thing the refuter saw, declined to file, and was right to hand up instead.**
`71-release-mechanism-pins.sh:283-284` justifies the disjointness pin as `the entire reason one agent
can safely take a whole wave`, while `CHANGELOG.md:22` says a collision-safety constraint `dissolved
on contact` with one writer. With one writer, disjointness buys per-task allowlist ATTRIBUTION, not
collision safety. Same stale-rationale class as B4 and F5. **The parent is filing it as N1**, because
a refuter declining to file is not the same as a defect not existing, and this is the fifth instance
of the sprint's signature defect.

### Two decisions taken at the settle round, via the wizard

**#4-C, keep looping until a round is genuinely clean.** Offered against a bounded alternative
(fix everything, one more round, land unless a new Critical appears) and a narrower one (Criticals
and Importants only). The bounded option was the recommendation and it was declined. The cost was
stated plainly at the time and is restated here: rounds 1 and 2 both found more than the round
before them, 6 then 26, so there is no evidence yet that this terminates, and #4-C accepts however
many rounds it takes. The protocol's own exit rule is the strict reading and this is it.

**#5-C, take the GIF fix AND audit the rest of the encoder settings.** Offered against taking just
the one flag, and against deferring it. The refuter had REFUTED it as a Phase 5 finding and
re-routed it to a Phase 6 offer, correctly: `gen-demo-gif.py:142` is byte-identical at `03e7a12` and
`phase-3-implement.md:97` forbids adjacent cleanup. #5-C overrides that routing deliberately, which
is the user's call to make and is recorded as such rather than as a finding that survived. Two of
the four levers were already measured by Reviewer D (7 frames is minimal, and reducing the palette
makes the file LARGER, 139,778 against 135,296), so what #5-C actually buys is the written record
that the remaining ones were checked rather than assumed.

### Phase 5 address-all, round 2 fix waves

Three waves, sequential, split by file set. Wave C took the executable code, wave D the Phase 3
protocol and the mode skills, wave E the refuter contract and the singular-refuter vocabulary.
**B3 was closed by the parent**, not dispatched: it is a missing Sprint Backlog entry in this file,
and `docs/work/` sits outside every implementer allowlist by construction.

**Wave C, and the two times it refused the brief.** Both refusals were right and both are worth
keeping, because in each case following my instruction would have shipped a defect.

I told it to copy the arm-and-clear trap shape from `80-file-size-caps.sh:326-340`. It read that
block's own comment, which says the shape is safe there only because nothing else in the validator
traps EXIT, then noticed that the test suite it was about to write **does** arm `trap tb_finish
EXIT` for its own verdict. A bare `trap - EXIT` inside `wi_absent` would have deleted that, and the
suite would have reached `exit 0` printing no verdict at all. So the clear is a save-and-restore,
which in the validator degrades to exactly the mandated shape because `prev` comes back empty.

And its first cut of the new test **passed against broken code**. The fixture guard proves the
banned literal really occurs in a live file before asserting the check catches it, and it scanned
`:(top)`, so the `TB_WI_LIT=` assignment line was itself a tracked occurrence and the test found
itself. It caught that by pointing the guard at a string that exists nowhere and watching it pass
anyway. Self-excluding the fragment, the same move `WI_LIVE_PATHS` makes, made it bite.

**The A1 fix was re-proved by the parent, not accepted on report.** Plant
`hackify:wave-task-implementer` in a live file, shim `mktemp` to exit 1, run the validator: zero
lines reading `survives in no live file`, and four FAILs naming the capture file that could not be
created. Before the fix, that same tree printed a green absence verdict.

**Wave C's cost, stated.** `71-release-mechanism-pins.sh` went 483 to 496 of 500, spending 13 of its
17 remaining lines. The agent flagged this itself rather than letting the next editor discover four
lines of headroom in a file this repo has already split once at the cap. Both rewrites needed to
carry a REASON across, not just swap vocabulary, which is what cost the lines.

**FIX G, decision #5-C.** 227,491 to 135,296 bytes, 40.5%, pixel-identical across all seven frames,
verified by the agent and independently by the parent with `ImageChops.difference().getbbox()`
returning `None` for every frame. Eight further encoder settings were measured and their numbers
recorded in the file. Two would have looked like wins and are not: a shared global palette reaches
60,087 bytes but changes all seven frames, because they carry 894 to 1166 distinct colours each and
one 256-entry table cannot hold that; and `disposal=2` is larger than no optimization at all.
`interlace` turned out to be inert, because Pillow reads it only on the single-frame save path and
`_write_multiple_frames` never consults it. `dither` is not a GIF save option at all.

**Wave D, and the census it ran after its own fixes.** All six landed. Reading F3's block in one
pass turned up two more ambiguous steps in the same block, both fixed unprompted, which is the
behaviour that F4 exists to punish the absence of: F4 came back precisely because an earlier fix
stopped at the filed line numbers.

Its census then found five sites no reviewer had named. The sharpest is
`runtime-adapters.md:17`, `(Phase 2.5 reviewers, Phase 3 waves, Phase 5 reviewers + refuters)`,
which carries TWO defects in one parenthetical: the refuter plural, and `Phase 2.5 reviewers` where
exactly one spec reviewer has run since v0.13.0. It also noticed that
`phase-5-aggregation.md:5` sits inside `[77]`'s file set while `[77]` bans reviewer counts and not
refuter counts, so the file is covered and the claim is not. That is `[77]`'s own header lesson,
"covering a file is not covering a claim", reproducing itself one grammar over.

Wave D declined two edits with reasons I accept. It did not add "Phase 3 waves" to `SKILL.md`'s
do-not-use-parallel-agents list, because that row sits twelve lines under a row saying Phase 3
dispatch is MANDATORY and would read as "no agents in Phase 3", inverting the no-parent-authored-diff
law. And it dropped a draft phrase that time-stamped the change ("now that a Phase 3 wave goes to
one agent"), on the grounds that a sprint about deleting time-stamped prose should not add more.

**One thing wave D checked that is not a repo defect.** This session's agent-type registry is a
stale snapshot: it still advertises `hackify:wave-task-implementer` and a refuter description
carrying the retired two-dispatch rule. Both files on disk are correct. Registry lag, not drift, and
the same 0.13.1-installed-plugin gap already recorded against AC3 and the settle round.

**Wave E, and the two citations in my brief it refused to act on.** I pinned the literal
`Never leave a finding unjudged` and cited it at `phase-5-refute.md:187`. Neither is right. The live
rule reads `Never leave a finding or a lens unjudged` and sits at `:140`; `:187` is a severity
anchor. The agent kept the real line byte-identical, quoted it correctly in the new prose, and
reported both errors instead of editing a load-bearing rule to match my typo. **A brief is not
evidence**, and this is the second time this sprint an agent has caught mine being wrong.

**B5's fix, and why the number moved rather than the words.** The cap is now per finding rather than
a flat total for the round, because the round is what grew: one refuter, every finding, every
severity, so any fixed total shrinks as the round gets bigger. It is sized against the widest block
the skeleton can produce, a Critical carrying a verdict line, two lens lines, a
`would change my mind` line and a `new severity` line, which is exactly where #2-A's cost lands. The
text now says why the number is what it is, and closes with the rule that a later change adding a
line to a block RAISES this number and never licenses dropping a finding to fit it. `## Verification`
sits outside the budget, so the squeeze cannot just move one level down.

**Wave E also filed a defect against itself.** Its own W2 fix put the seven new function names into
the wiring gate, which falsified a comment in a file it could not reach saying the gate `cannot see
them either ... its four-name row for this fragment`. It could not fix it, so it wrote down exactly
what it had broken and handed it over. That became wave F's C2.

**Wave F, and the trap it flagged before anyone could fall into it.** Its census found
`scripts/test_ban_tokens.sh:109` claiming the fragment `defined eleven functions`. It defines
sixteen; eleven is how many names the GATE lists, a different quantity sitting in the same sentence.
**And it warned that `30-inventory-pins.sh:109-110` also says eleven and is CORRECT there**, because
its referent really is the gate's name count. Both verified by the parent: 16 defined, 11 listed. A
follow-up fixer working from a grep would have "corrected" the right one into being wrong.

**C2's rewrite did not just delete the dead claims, it stated the hole that survives.** W2 closed
half of it: the gate asks `declare -F`, so it sees a function that stopped EXISTING and never one
left defined and no longer called. That second shape is still the counter's job, which is why the
total keeps earning its place. A comment that explains why a pin fires where it fires is worth
keeping; only the specific claims had died.

**Wave F left a matched pair alone on purpose, and was right to.** `phase-ledger.md:135` and
`SKILL.md:75` carry the same stale claim in two spellings, and only one was inside its allowlist. It
judged that fixing half a matched pair leaves the next reader unable to tell which spelling is
intended, and recommended a single wave owning both files. That is wave G.

**Every changed line in `scripts/` across waves F and G is a comment line**, proved by diffing out
comment-prefixed lines and getting nothing back. These are live check files and a prose fix has no
business changing behaviour.

### Three-layer re-verify

**Layer 1, fresh triad.** Run in Phase 4, not quoted from a wave-end: `validate-dod.sh` exit 0, 0 FAIL
lines with ANSI stripped, 1440 ok lines, `ALL CHECKS PASSED`. Mirrors 9. All five extra CI gates exit 0.

**Layer 2, goal-drift re-check against the anchor.** North-Star met: one agent per wave in all three
modes, vocabulary retired. Every In-Scope bullet has covering work. Every Out-of-Scope line held:
**the reviewer panel kept its lens count** (F was corrected, never dropped, and #2-A preserved the
Critical bar by requiring both lenses instead of two agents); **wave PLANNING is unchanged** (waves are
still capped by `{{wave_size_target}}` and still file-disjoint, only within-wave batching went); **the
file-allowlist mechanism is untouched** (each task keeps its own allowlist, the wave is bounded by
their union). Guardrails: mirrors 9 of 9 at every wave end; no em or en dashes; no lint suppressions;
no file over 500 lines; `dist/` regenerated by its script and never hand-edited.

**Six tasks were added after sign-off** (T3b, T5b, T5c, T6b, T11b, T14). Five are vocabulary or pin
sites the plan's own survey missed, squarely inside the In-Scope bullets. **T14, the hero GIF, is the
one judgment call:** In-Scope names "README and CHANGELOG" and the GIF is a generated asset the README
embeds at the top of the page, so it was treated as in scope. Flagging it as a call rather than a
certainty.

**Layer 3, independent re-prove.** Three claims were re-proven by the parent rather than accepted:
the Wave 5c pin was tampered independently and bit as reported; all 21 pinned literals across Wave 3's
five files were re-grepped rather than read off the agent's table; and the Wave 6 implementer diffed
the full ok-line list against a clean worktree to show **zero removed ok lines**, which is the loss a
total cannot see, a check that stops firing while the run still prints ALL CHECKS PASSED.

**One open question handed to Phase 5 rather than settled here.** `orchestration.md:123` reads "The
user said light mode, but this wave really needs the fan-out". Under the new rules a Phase 3 wave has
no fan-out to want. A Wave 3 agent flagged it and left it as tier-level prose; I read it as a residual.
It is a judgment call about which sense of "wave" the sentence uses, so the review panel decides.

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

**Nothing checks that the hero GIF matches the phase table it is generated from.** T14 existed only
because `gen-demo-gif.py`'s `PHASES` constant drifted from the workflow and no check could see it.
That gap is unchanged: the next time a phase description moves, the image goes stale silently again.
A cheap fix the T15 implementer proposed: assert every tag's rendered width is at or under the 165px
tile, and assert the GIF's mtime is newer than the generator's. Not done here, because a new
validator check is outside a sprint about dispatch vocabulary.

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

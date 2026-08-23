---
slug: phase-ledger-substrate
title: Give the phase ledger a substrate that survives, and make phase discipline always-on
status: in-progress
type: fix
created: 2026-08-23
project: hackify
current_task: T1
worktree: none
branch: main
sprint_goal: The phase ledger never silently vanishes again, on any runtime, in any mode.
---

# Give the phase ledger a substrate that survives, and make phase discipline always-on

## 0. Phase ledger

<!-- The ledger for THIS task. Dogfoods the fallback substrate this sprint adds. -->

- [x] Phase 1. Clarify (lock the goal anchor)
- [x] Phase 2. Plan + Gate (work-doc + user "go")
- [x] Phase 2.5. Spec review (1 reviewer, patch the doc)
- [>] Phase 3. Implement (all waves committed)
- [ ] Phase 4. Verify (Evidence Ledger + triad green)
- [ ] Phase 5. Review (decision table empty)
- [ ] Phase 6a. Re-verify + land choice (Steps A, C)
- [ ] Phase 6b. Cleanup sweep (Step C.5)
- [ ] Phase 6c. Archive work-doc to `done/` (Step D)
- [ ] Phase 6d. Update log + HTML report (Step F)

## 1. Original ask

> i have noticed that the last changes have broken the ledger of the phases and neglected some phases while working on real projects.
> all phases are mandatory in all modes and the steps tracker (todo list) is vanished for no reason. plesse fix thst and mandate it

## Primary Goal & Guardrails

**North-Star Goal.** A hackify task can never lose its visible step tracker, and can never advance past an unfinished step, regardless of which runtime tools happen to exist in the session.

**In-Scope.**
- A written fallback substrate for the phase ledger on Claude Code, the one runtime whose adapter table cell states a tool name and no degrade.
- A durable on-disk home for the ledger plus an in-chat reprint at every phase boundary.
- Repairing the two places in `phase-ledger.md` that assume a session-local ledger and stop being true once it is durable: the "Two layers" table row, and the Pause / resume rebuild instruction.
- An always-on injected rule that puts phase discipline in front of the model on every prompt.
- The wizard mandate (every question, every decision, every feedback request goes through the `AskUserQuestion` tool) promoted into that same always-on rule. It exists today only in `references/clarify-questions/wizard-contract.md`, which loads at Phase 1 and then fades.
- Explicit ledger open/tick instructions in every per-phase protocol file, especially Phase 2.5 and Phase 3, which have none today.
- Ledger opened at task start in every mode as a printed block, then written into the work-doc as section 0 at Phase 2 step 1 in full mode. This closes the Phase 1 window where full mode had no visible tracker, without claiming a file can exist before the ask has a slug.
- Validator pins so each of the above regresses loudly, not silently.
- Runtime mirrors, README, CHANGELOG, version bump.

**Out-of-Scope and Non-Goals.**
- Collapsing quick/yolo into full hackify. The user chose "no silent drops inside whichever mode runs" (#1-A), so the per-mode item lists keep their current shape.
- A `PreToolUse` hard block on Write/Edit until a ledger exists. Explicitly declined (#3-A over #3-B) because of false-block risk.
- Reviving `TodoWrite`. Its availability is the runtime's business; hackify's job is to degrade honestly when it is absent.
- A separate ledger file for quick and yolo. Those modes keep nothing on disk by contract, and inventing a scratch file to delete later trades a real contract for a cosmetic symmetry. They print the ledger in chat at every boundary; the printed block is the record.
- Making the always-on injection work on the six non-Claude-Code runtimes. `UserPromptSubmit` is a Claude Code mechanism and has no equivalent there. Those runtimes degrade to `SKILL.md` prose, and this sprint writes that degrade down instead of leaving it unstated.
- Whole-repo cleanup outside the touched files.

**Guardrails and Invariants.**
- Every hard cap in the user-global `CLAUDE.md` holds: 500-line file cap, no lint suppressions, no em dashes in prose.
- README.md stays at or under its 450-line validator cap. It is at 447 now, so a new blurb is paid for by compressing an older one.
- `scripts/validate-dod.sh` must exit 0 before this ships, and also at **every wave end** (`phases/phase-3-implement.md:93`). A change that reddens the triad mid-wave is a wave-planning defect, not a later problem.
- **Every** `check_token_present` / `check_no_token` pin in `scripts/validate-dod.d/*.sh` that names a file this sprint touches must keep passing, or be updated in the same change. Not just the `phase-ledger.md` pins: `phase-2.5-spec-review.md`, `phase-5-review.md`, `skills/hackify/SKILL.md` and `skills/yolo/SKILL.md` each carry their own, plus the `[75c]` ship-gate row pins across all three mode files. Grep the pins for a file before editing it.
- The injected rules file must be written as bold-lead bullets, because `inject_context.py`'s digest regex (`BULLET_LEAD`, `DIGEST_MAX_CHARS = 900`) keeps only bold bullet leads after the first prompt of a session.
- **The digest budget is the real constraint, not the file size.** Measured through the live injector, the three existing pointers cost 818 + 496 + 619 = 1933 chars on every prompt. The digest truncates from the end at 900 chars, so a file whose bold leads overflow silently loses its last law. The new file gets at most 5 bold leads and roughly 300 digest chars, and the wizard bullet must not be last.
- `dist/copilot-cli/` is MANIFEST-only by design (`scripts/sync-runtimes.d/copilot-cli.sh`), not a missing mirror.
- **`bash scripts/sync-runtimes.sh` runs at every wave end, before the triad, not only in Wave 5.** Check `[57]` link-checks the built `dist/claude-code` tree as well as source, and that tree exists locally. So any wave that adds a doc pointer passes in source and fails in dist until the mirrors are rebuilt. T8b stays in Wave 5 as the final full-mirror verification, it is no longer the only sync.

**Success Signals.**
- `runtime-adapters.md`'s `todo tracker` row gives Claude Code a written fallback, matching the other six runtimes.
- Each of the six per-phase protocol files names the ledger at its open and its exit.
- `hooks/hooks.json` registers a fourth always-on file, and `hooks/test_inject_context.sh` covers it.
- `scripts/validate-dod.sh` exits 0, with new checks that fail if any of the above is reverted.

## 2. Clarifying Q&A

### Q1 (what "all phases mandatory in all modes" means)
**Asked:** Does this mean nothing gets silently dropped inside whichever mode runs, or that every mode must run all ten steps?
**Answered:** #1-A. No silent drops. Quick stays short, yolo stays gate-free, but neither can quietly skip one of its own steps. Every step ends done, or done with a visible one-line reason.

### Q2 (where the checklist lives without a todo tool)
**Asked:** The built-in to-do panel is unavailable. File, chat-only, or wait for the tool to return?
**Answered:** #2-A. In a file, and reprinted in chat at every step, so it survives a crash or restart and a resumed session picks up where it stopped.

### Q3 (enforcement strength)
**Asked:** Rule injected on every message plus refuse-to-advance, also hard-block edits, or docs only?
**Answered:** #3-A. Injected on every message plus refuse-to-advance. No new blocking of tools.

### Q4 (wizard mandate, added mid-plan by the user)
**Asked:** Not asked; stated directly.
**Answered:** "also force using askuserquestion tool while asking questions or taking feedback or decisions." Same failure shape as the ledger: the rule exists in `wizard-contract.md`, which loads once at Phase 1 and then fades. It moves into the always-on injected rule so it is present on every prompt.

## 3. Acceptance Criteria

1. `references/runtime-adapters.md`'s `todo tracker` row states the fallback **inside the Claude Code cell itself**, not only in the prose bullet above the table. The bullet at line 16 already covers Claude Code by wording ("where a runtime has no native list"), but the cell reads a flat `TodoWrite`, so a model reading the table never learns to degrade. The bullet is also upgraded to name the on-disk substrate, not just an in-chat checklist.
2. That same table gains an **`always-on injection`** primitive row: native on Claude Code via `UserPromptSubmit`, `n/a` with a written degrade on the other six. The primitive count at `runtime-adapters.md:5` and the `## The 11 primitives` heading at `:7` move to 12, and `README.md:294` follows. The new row goes **after** `completion sentinel` so `:51` ("the first 8 primitives") and `:91` ("eight load-bearing") stay true.
3. `references/phase-ledger.md` carries a **Substrate** section defining primary (todo tracker) and fallback (in-chat print, plus the work-doc block once one exists), where it lives per mode, and how resume reads it. The "Two layers" row, the Pause / resume section, and lines 3 and 26 (which both assert the todo tracker as the only substrate) are all corrected to match.
4. `references/work-doc-template.md` grows a `## 0. Phase ledger` block, with the ten full-mode items, between the title line and `## 1. Original ask`. Without it the contract has nothing to instantiate.
5. `rules/phase-discipline.md` exists, is written as bold-lead bullets, is registered as a fourth `UserPromptSubmit` entry in `hooks/hooks.json`, and is covered by `hooks/test_inject_context.sh`. It carries three laws: the ledger is always open and reprinted at every boundary; **phases run in order, one open at a time, and a later phase may not start while an earlier one is open** (the refuse-to-advance half of Q3); and every question, decision or feedback request goes through the wizard tool, never a numbered list in chat.
6. The wizard bullet **provably survives the post-turn-1 digest**: a second-turn run of `hooks/inject-context.sh` on the new file emits a pointer that still contains the wizard token. A static grep proves the bullet is in the file, never that it reaches turn 2, so the test must run the injector twice.
7. All six files in `references/phases/` name the ledger at phase open and at phase exit; `phase-2.5-spec-review.md` and `phase-3-implement.md` go from zero mentions to explicit ones.
8. The ledger **opens at task start in every mode** as a printed block, and in full hackify **it is written into the work-doc as section 0 at Phase 2 step 1**. That bolded clause is the canonical sentence: it appears verbatim in `phase-ledger.md` and in `skills/hackify/SKILL.md`, and `70-invariants-and-new.sh` pins the literal string `written into the work-doc as section 0 at Phase 2 step 1` in both. `SKILL.md:69` ("created at the **start of Phase 2**") and `SKILL.md:74` ("Resume rebuilds the ledger") are the two lines that contradict it today and must be rewritten.
9. `scripts/validate-dod.sh` exits 0, and a new check block fails if the Claude Code fallback cell, the fourth injected rules registration, the refuse-to-advance law, the canonical sentence, or any per-phase ledger mention is removed.
10. All seven `dist/` runtimes are regenerated and mirror-complete; README and CHANGELOG record the release; version bumped to 0.14.0.

## 4. Approach

Two independent defects, one sprint.

The **substrate defect**: `runtime-adapters.md` maps Claude Code's `todo tracker` to a flat `TodoWrite`, while all six other runtimes spell out a degrade inside their cell. `TodoWrite` is measurably absent from this session's tool surface (not in the tool list, not in the deferred list, not findable via `ToolSearch`; the binary gate `todoFeatureEnabled` defaults to true, so this is a surface decision, not a user setting). A model reading that table finds a tool name that does not exist and no instruction for what to do instead, so the ledger disappears with nothing saying it should degrade. Fix: put the degrade in the cell, and upgrade the fallback from "in-chat checklist" to "in-chat print at every boundary, plus the work-doc block once one exists", so full-mode ledgers survive a lost session. Full mode's ledger becomes section 0 of the work-doc, which is already durable, already archived, already re-read on resume. Quick and yolo print only, matching their no-files-on-disk contract.

One honesty note for the release prose: 3 of the user's last 79 sessions used `TodoWrite`, but that number cannot separate "the tool was absent" from "the tool was there and never reached for". The in-session absence proved here is the solid evidence; the CHANGELOG will not claim more than that.

The **discipline defect** is why phases got neglected: nothing that fires on every prompt mentions phases, and the two longest phase files never say to tick anything. The wizard mandate has the same shape, it lives in a file that loads once at Phase 1. Fix: a fourth always-on injected rules file carrying all three laws, reusing `inject-context.sh` unchanged, written as bold-lead bullets so the session-aware digest carries them past turn 1; plus explicit ledger lines at every phase boundary; plus validator pins so this cannot rot again.

`UserPromptSubmit` exists only on Claude Code. The other six runtimes have no injection primitive, so the same three laws reach them through `SKILL.md` prose alone. That is a real degrade and it gets its own `runtime-adapters.md` row rather than going unmentioned.

**Why a fourth file rather than folding the laws into an existing one.** Measured, not assumed: the three current pointers cost 818, 496 and 619 chars. `hard-caps.md`'s own digest is 521 chars against a 900-char truncation limit, so appending three more laws to it would push it to roughly 825 and leave it one cap short of silently dropping its own last ban. The digest truncates from the end, so folding does not save the budget, it just puts an existing law at risk. A separate file gets its own 900-char allowance.

### Repo Brief

- **Stack.** A Claude Code plugin. Markdown skills + reference docs, Python 3 helper scripts, Bash validators. No package manager, no build step.
- **Test / lint / typecheck.** `bash scripts/validate-dod.sh` is the triad (there is no separate lint or typecheck). Unit tests: `python3 skills/lawkeeper/scripts/test_audit.py`, `bash hooks/test_inject_context.sh`, `bash hooks/test_block_banned_tokens.sh`.
- **Layout.** `skills/<name>/SKILL.md` + `references/`; `agents/*.md` are registered subagents mirrored from `skills/hackify/references/parallel-agents/*` by `scripts/sync_agent_mirrors.py`; `rules/*.md` are plugin-root doctrine; `hooks/` holds the `UserPromptSubmit` injector and `PreToolUse` blocker; `dist/<runtime>/` are generated mirrors from `scripts/sync-runtimes.sh`; `scripts/validate-dod.d/*.sh` are numbered validator fragments.
- **The one layering rule.** `dist/` is generated, never hand-edited. Edit the source under `skills/`, `rules/`, `agents/`, then run `bash scripts/sync-runtimes.sh`.
- **Rules source.** User-global `~/.claude/CLAUDE.md` plus the plugin's own `rules/hard-caps.md`. No project `CLAUDE.md` in this repo.
- **Test convention.** Validator fragments are numbered shell files sourcing `00-helpers.sh`; they use `check_token_present` / `check_no_token` and increment `FAILED`.
- **Landmines.** (a) README.md caps at 450 lines and sits at 447. (b) `70-invariants-and-new.sh` pins exact literal strings out of `phase-ledger.md` and `SKILL.md`; rewording those lines breaks the pins. (c) `inject_context.py` keeps only bold bullet leads in its post-turn-1 digest, capped at 900 chars. (d) `block-banned-tokens.sh` rejects em dashes in written prose. (e) `dist/copilot-cli/` is MANIFEST-only by design.

## 5. Sprint Backlog

**The canonical sentence** (T2 and T6 both write it verbatim, T7 pins it):

> The ledger opens at task start in every mode as a printed block, and in full hackify it is **written into the work-doc as section 0 at Phase 2 step 1**.

**Wave 1 (contract + the new rules file)**

- [x] **T1.** `references/runtime-adapters.md`: put the degrade inside the Claude Code `todo tracker` cell; upgrade the line-16 bullet to name the on-disk substrate; add an `always-on injection` primitive row **after** `completion sentinel`; move the count at `:5` and the heading at `:7` from 11 to 12. Leave `:51` and `:91` alone, they say "first 8" and stay true. Files: `skills/hackify/references/runtime-adapters.md`.
- [x] **T2.** `references/phase-ledger.md`: add a `## Substrate (where the ledger actually lives)` section covering primary vs fallback, per-mode location, reprint-at-every-boundary, and resume; write the canonical sentence verbatim. Sweep the WHOLE file for the "todo tracker is the only substrate" assumption, including line 3, line 26, the "Two layers" table row (full mode now survives a session) and Pause / resume (read the block, do not rebuild it; say what quick/yolo do). Also add `## 0. Phase ledger` with the ten full-mode items to `references/work-doc-template.md`, between the title line and `## 1. Original ask`. Grep `scripts/validate-dod.d/*.sh` for pins on both files first. Files: `skills/hackify/references/phase-ledger.md`, `skills/hackify/references/work-doc-template.md`.
- [x] **T3.** `rules/phase-discipline.md`: new always-on rules file. At most **5 bold-lead bullets**, roughly **300 digest chars**, wizard bullet NOT last. Three laws: ledger always open and reprinted at every boundary; phases in order, one open at a time, no later phase while an earlier one is open, no silent skip; every question, decision or feedback request through the wizard tool. **Also add `"rules/phase-discipline.md"` to `MIRROR_SOURCES` in `scripts/sync-runtimes.d/00-helpers.sh` in the same task**, because check `[55]` counts untracked files and goes red the instant the file exists, and the wave-end triad is mandatory. Files: `rules/phase-discipline.md`, `scripts/sync-runtimes.d/00-helpers.sh`.

**Wave 2 (wiring, depends on T3 existing)**

- [x] **T4.** Register the fourth injector entry in `hooks/hooks.json`; update the three-file enumeration in the `hooks/inject-context.sh` header comment at lines 6-8 (it ships to `dist/claude-code/` via `CLAUDE_CODE_EXTRA`); extend `hooks/test_inject_context.sh`, including renaming case `[9]` from three files to four and adding a **two-turn** case proving the wizard token survives into the pointer. That same two-turn case must ALSO assert the literal `unless it is trivial or read-only` appears in the turn-2 pointer. Measured on the landed file it is 33 chars against `QUALIFIER_MAX_CHARS = 34`, one character of margin, and `qualifier()` returns empty rather than truncating, so a two-word reword silently deletes the carve-out from every prompt after the first and the steady-state law goes absolute with nothing failing. A static grep of the rules file cannot catch that; only a digest-output assertion can. Files: `hooks/hooks.json`, `hooks/inject-context.sh`, `hooks/test_inject_context.sh`.
- [x] **T5.** Ledger lines at every phase boundary in all six per-phase files, plus the corrected creation point in `phase-1-clarify.md`. Grep the validator pins on these files first: `phase-2.5-spec-review.md` carries `'The letter C is retired, not reassigned'`, `phase-5-review.md` carries `'Cap at 5'` and a `check_no_token 'A, B, C and F'`. Files: `skills/hackify/references/phases/*.md`.
- [x] **T6.** `SKILL.md`, `skills/quick/SKILL.md`, `skills/yolo/SKILL.md`: write the canonical sentence verbatim; **rewrite `SKILL.md:69` ("created at the start of Phase 2") and `SKILL.md:74` ("Resume rebuilds the ledger")**, the two lines that contradict the new contract in the file a model reads first; add the new rules file to the always-on list, the file map, and the "injects THREE rules files" sentence (now four). Grep the pins first: `SKILL.md` carries `'1 reviewer scrutinizes work-doc'`, `skills/yolo/SKILL.md` carries `'Dispatch the 1 reviewer'`, and `[75c]` pins ship-gate rows in all three. Files: `skills/hackify/SKILL.md`, `skills/quick/SKILL.md`, `skills/yolo/SKILL.md`.

**Wave 2b (doc sweep, added 2026-08-23 after the user asked to make sure ALL docs were updated. Both are real defects found by sweeping 119 doc files, neither was in the original plan.)**

- [ ] **T9.** Stale Phase 2.5 reviewer counts, user-approved as issue #4 option A (fix AND guard). v0.13.0 merged the spec reviewers into ONE agent with three lenses; five sites still say two or three. `phases/phase-2.5-spec-review.md:11` says "Dispatch 2 foreground reviewers" with `:12`/`:16` describing Reviewer A and Reviewer B as separate dispatches, while `:9` and `:23` in the same file already say one reviewer with three lenses. `skills/hackify/SKILL.md:47` says "Parallel agents scrutinize work-doc". `skills/yolo/SKILL.md:21` and `:64` say "3 parallel reviewers", contradicting the pinned `Dispatch the 1 reviewer` at `:99` in the same file. `skills/yolo/evals/evals.json:11` asserts "3 parallel reviewers", an eval that passes on the bug and fails on the fix. Authority is `agents/spec-reviewer.md` ("Dispatch exactly one"). Files: `skills/hackify/references/phases/phase-2.5-spec-review.md`, `skills/hackify/SKILL.md`, `skills/yolo/SKILL.md`, `skills/yolo/evals/evals.json`.
- [ ] **T10.** The groom path has no home for section 0. `skills/groom/SKILL.md:59` creates the work-doc from the template BEFORE Phase 1 (`status: clarifying`), but the new contract says section 0 is written "at Phase 2 step 1, when the file is first created". On the groom path the file already exists by then, so the contract has a hole. Groom also says its `## Groom Provenance` block goes "directly under the frontmatter and above `## Original Ask`", which is now where `## 0. Phase ledger` lives, so the placement is ambiguous and the two can collide. Groom mentions the ledger zero times today. Decide and document one ordering, then make groom, the template, and `phase-ledger.md` agree. Files: `skills/groom/SKILL.md`, `skills/hackify/references/work-doc-template.md`, `skills/hackify/references/phase-ledger.md`.

**Wave 3 (validator, alone: T8 would run the triad while this file is half-written)**

- [ ] **T7.** New validator block in `scripts/validate-dod.d/70-invariants-and-new.sh` pinning: the Claude Code `todo tracker` fallback cell, the `always-on injection` row, the four injected files in `hooks/hooks.json`, a per-phase ledger mention in each of the six phase files, the canonical sentence in both `phase-ledger.md` and `SKILL.md`, the refuse-to-advance law, and the wizard-mandate bullet. **Three additions from Wave 1.** (a) Pin the carve-out literal `unless it is trivial or read-only`, it sits at 33 chars against `QUALIFIER_MAX_CHARS = 34` and `qualifier()` drops rather than truncates, so a reword silently deletes it from the digest. (b) Extend the `[38g]` `check_no_token '3 reviewers'` / `'2 reviewers'` loop to cover `references/work-doc-template.md`, whose new ledger block now carries a seventh copy of a Phase 2.5 reviewer count and is in neither pin list today. (c) For the `always-on injection` row pin the ROW NAME or the Codex CLI cell, not a per-cell string: two of its cells use the file's `n/a, same as Codex CLI` shorthand and would be brittle. (d) From T4: pin `rules/phase-discipline.md` inside `hooks/inject-context.sh` itself. Its header comment enumerates the always-on files BY NAME and ships to `dist/claude-code/` via `CLAUDE_CODE_EXTRA`, but nothing pins it, so it can go stale silently again. That is the exact failure class this sprint exists to kill, and it costs one `check_token_present` line. Files: `scripts/validate-dod.d/70-invariants-and-new.sh`.

**Wave 4 (release metadata)**

- [ ] **T8a.** Bump `plugin.json` + `marketplace.json` to 0.14.0; CHANGELOG entry; README blurb paid for by compressing an older one (README is at 447 of a 450 cap); update the always-on references at these VERIFIED locations (swept 2026-08-23, the original three-line list was incomplete): `:71` names the three rules files AND separately says the hook injects "the hard caps, the expert mindset, and the performance guardrails", so it needs TWO edits on one line; `:249-254` is the file-tree block and needs a new `phase-discipline.md` row, which COSTS A LINE against the cap; `:267` says `injects the 3 always-on rules files` and was missing from the original task list entirely; `:290` lists always-on reference files and may want the new rule alongside `phase-ledger.md`; `:387` says "The third always-on file" and needs a fourth; and the primitive count at `:294` (it says 11 and now contradicts `runtime-adapters.md:5`, which says 12). Measured for the blurb: per-prompt injection is now four pointers at 818 + 496 + 619 + 550 = 2431 chars. **README line budget, settled: T8a landed the file at 446 and check `[7]` bounds it 250-450. A release section costs 4 lines for one bullet, so two bullets needs 445. Compress ONE more old blurb first, then add a two-bullet section. Do not raise the bound. Also update the `(since v0.14.0)` stamps at the new `rules/` tree row and the fourth-always-on-file sentence if the release number changes.** Files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`, `README.md`.

**Wave 5 (mirrors, must be last so dist reflects every source edit)**

- [ ] **T8b.** Run `bash scripts/sync-runtimes.sh`, then verify all seven runtimes are mirror-complete and the new rules file reached the six bundle runtimes. Files: `dist/**`.

## 6. Daily Updates

### 2026-08-23, Wave 1 (T1, T2, T3) landed

Two implementers in parallel, both inside their allowlists. Four files changed, one created.

- **T1** `runtime-adapters.md`. Claude Code's `todo tracker` cell now carries a written degrade instead of a bare tool name, which is the root cause of the vanished tracker. Added `always-on injection` as a 12th primitive, appended last so `:53` "first 8 primitives" and `:93` "eight load-bearing" both stay true (verified: `todo tracker` is still 8th of 12). Mid-flight scope addition from the coordinator caught the SAME defect in the degrade table: `:68` claimed out-of-order phase starts were "mechanically impossible" and `:78` credited that to `TodoWrite`. Both re-worded to say ordering rests on written law when the tool is absent. T1 also caught, unprompted, that `:54` said "the last 3 primitives" and had gone false; fixed.
- **T2** `phase-ledger.md` + `work-doc-template.md`. New `## Substrate` section carrying the canonical sentence verbatim exactly once. Swept the file for the now-false "todo tracker is the only substrate" assumption and found a SEVENTH instance the plan had not listed (`:129`, "The ledger is created at Phase 2, before code"). Resume now reads the ledger back rather than rebuilding it. Template gained the `## 0. Phase ledger` block, ten items, diffed mechanically against `phase-ledger.md` rather than eyeballed.
- **T3** `rules/phase-discipline.md` (new, 15 lines) + the `MIRROR_SOURCES` line in the same task, so check `[55]` never went red mid-wave.

**Coordinator corrections issued mid-flight, both caught before the agents finished.** The degrade-table defect above, and a scope carve-out on the new always-on rule: it injects into every session in every repo, but phase discipline is not unconditionally true (global `CLAUDE.md` §0.4 exempts trivial Q&A, one-line typo fixes, read-only inspection). The non-obvious part is that a carve-out written as body prose evaporates after turn 1, since the digest keeps only bold leads plus a short clause. It now rides in lead 1's qualifier and survives.

**Verification, run by the coordinator on the settled tree, not taken from agent reports.**

- Injector run twice against a fresh session id: turn 1 returns 2778 chars of full text, turn 2 returns a 550-char pointer carrying all five laws plus the carve-out. Wizard law is 4th of 5, out of the truncation firing line.
- Scouts: perf-scout n/a, the wave is markdown plus a one-line manifest addition, no runtime code path. Law-scout scanned 5 scoped paths, 0 files scannable (the lawkeeper scanner covers `.js`/`.ts`, not `.md`/`.sh`). The 7 repo-wide findings it does report are pre-existing in `skills/codewalk/assets/*.js`, untouched by this wave and out of scope per Surgical Changes.
- `bash scripts/sync-runtimes.sh`: 786 files across 7 runtimes; `rules/phase-discipline.md` confirmed present in all 6 mirroring trees (copilot-cli is MANIFEST-only by design).
- `bash scripts/validate-dod.sh`: **exit 0, zero FAIL lines**, run once after both agents settled and after the mirror rebuild.

**Disposition on a flagged item, recorded rather than dropped.** `runtime-adapters.md:83` still names `TodoWrite`. Left as-is: it enumerates the tool names the emitted bundle references, parallel to the MCP tool names listed for the other runtimes, and is not a claim about session availability.


### 2026-08-23, Wave 2 (T4, T5, T6) landed

- **T4** registered the fourth always-on file with the injector hook, updated the shipped header enumeration, and extended the test harness. It produced the RED proof I asked for: on a tampered copy with the carve-out reworded to 46 chars, exactly one assertion flipped and the turn-2 pointer showed the law silently going absolute. The real rules file was never touched. 29 tests pass.
- **T5** added byte-identical `**Ledger, at phase open.**` / `**Ledger, at phase exit.**` blocks to all six phase files, deliberately identical so T7 can pin one literal across six files. Deleted the stale "full hackify at the start of Phase 2" clause from phase-1. Verified 22 validator pins by hand after grepping for them rather than trusting the three the plan named.
- **T6** put the canonical sentence in `SKILL.md` byte-identical to `phase-ledger.md` (compared as whole sentences, not the pinned substring, which would match by construction). Rewrote the two contradicting lines. Four rules files everywhere. quick and yolo both got explicit no-silent-drop bullets plus anti-rationalization rows.

**Wave-end gate, coordinator-run on the settled tree:** law-scout 0 scannable files (markdown + JSON + shell, outside the scanner's `.js`/`.ts` surface), perf-scout n/a for the same reason, `sync-runtimes.sh` clean, `validate-dod.sh` **exit 0 zero FAIL**, and all three unit suites green (29/29 injector, 41/41 banned-tokens, 28/28 lawkeeper).

### Scope addition, user-approved 2026-08-23: stale Phase 2.5 reviewer counts (issue #4, option A)

T5 and T6 independently surfaced a pre-existing defect this sprint did not cause. v0.13.0 merged the Phase 2.5 reviewers into ONE agent carrying three lenses, but five sites still say two or three. Asked the user, who chose **fix it and guard it**. Sites found by repo sweep, more than either agent reported:

1. `skills/hackify/references/phases/phase-2.5-spec-review.md:11` "Dispatch 2 foreground reviewers", plus `:12` and `:16` which describe Reviewer A and Reviewer B as separate dispatches. Same file already says 1 reviewer at `:9` and "the three lenses it carries" at `:23`, so it contradicts itself within sixteen lines.
2. `skills/hackify/SKILL.md:47` phase table, "Parallel agents scrutinize work-doc".
3. `skills/yolo/SKILL.md:21` "3 parallel reviewers".
4. `skills/yolo/SKILL.md:64` "Dispatch 3 parallel reviewers", contradicting the pinned `Dispatch the 1 reviewer` at `:99` in the same file.
5. `skills/yolo/evals/evals.json:11` asserts "3 parallel reviewers". This is the worst of the five: an eval that passes on the bug and would fail on the fix.

The existing `check_no_token '3 reviewers'` / `'2 reviewers'` loop misses all of them, because the live strings are `3 parallel reviewers` and `Dispatch 2 foreground reviewers`. T7 must pin the real strings, not the ones the loop already covers.

### 2026-08-23, cross-skill consistency sweep (user-requested, SEPARATE from the sprint goal)

The user asked for a consistency scout over the skills. No such scout exists in the repo (the two that exist are perf-scout and law-scout; skillsmith authors skills, it does not audit them), so this ran as a deterministic sweep plus one read-only investigator. **Scope discipline: contradictions only. No behaviour change, nothing that touches the ledger or phase-discipline work.**

Everything below is post-v0.13.0 reviewer-merge drift, the same bug class as `dabc333` where quick mode dispatched a retired agent type. All of it is pre-existing and none of it was caused by this sprint.

**Checked and CLEAN, recorded so nobody re-investigates:**
- Five retired agent types (`code-reviewer-plan-consistency`, `codebase-researcher`, `debug-evidence-gatherer`, `spec-reviewer-dependencies`, `spec-reviewer-rules`) are still named in `references/parallel-agents/README.md` and `phase-2.5-spec-reviewer.md`. Every occurrence is inside a deliberate "retired / merged into X" note, which is intended history, not a live dispatch. **Not a defect.** Verified by reading each site, not by grep count.
- Every `/hackify:<slug>` reference resolves to a real skill or command.
- `skills/quick/SKILL.md` is internally consistent; its "four-to-five-parallel-reviewer panel" line is still accurate post-merge (B standing, A/D/F gated, E on UI).
- Word caps agree across `phases/phase-2.5-spec-review.md`, `parallel-agents/phase-2.5-spec-reviewer.md` and `agents/spec-reviewer.md` at ≤900.

**Found, routed into T9 (all in files T9 already owns, sent mid-flight rather than opening a colliding task):**
- Site 6, `SKILL.md:124`. "Cap B at ≤300 words and A at ≤600, A carrying two lenses." Names A and B as separate agents with separate budgets and says two lenses instead of three. Contradicts `:122` two paragraphs above, which already says one reviewer with three lenses. The number is not wrong (300 + 600 = 900), only the framing.
- Site 7, `SKILL.md:183`. "B ... and C ... are standing members of every wave." C merged into B in v0.13.0; `phases/phase-5-review.md:49` states this explicitly and gives the reason. This is Phase 5 drift, not Phase 2.5, which is why the original T9 brief missed it.

T9's scope was reframed mid-flight from "fix the Phase 2.5 count" to "purge post-v0.13.0 reviewer-merge drift from my four files", then frozen.

### 2026-08-23, T10 landed (groom / section-0 contract hole)

**The rule chosen:** whoever creates the work-doc writes section 0 into it. Direct path, that is Phase 2 step 1, unchanged. Groom path, that is groom, because groom is what creates the file. Phase 1 then ADOPTS the existing block and Phase 2 step 1 CONFIRMS it rather than writing a second one. Section order is stated in exactly one place, the template skeleton (`work-doc-template.md:42`), and the other files point at it instead of restating it.

This was chosen over rewording the canonical sentence, because that sentence is pinned in `SKILL.md` and by the upcoming T7 check, both outside T10's allowlist. It sits untouched at `phase-ledger.md:26`.

**Two holes T10 closed that were not in its brief:**
- `SKILL.md:90` told Phase 1 to CREATE the ten items, so on the groom path an agent following it literally would write a second block. Phase 1 now adopts and never opens a second.
- Groom's Step 3 print and Phase 1's adopt were both printing the same block back to back. The adopt no longer re-prints; it restores into the tracker and flips its own item.

**Follow-up T10 found and correctly did NOT fix (out of its scope, worth a decision later):** groom writes `status: clarifying`, and Phase 2's exit artifact is "work-doc exists AND explicit user go" (`phase-ledger.md:99`). On the groom path the file half is pre-satisfied, so only the go gates Phase 2. A groomed task therefore carries a work-doc with `status: clarifying` and an all-open ledger through the whole of Phase 1, which the resume rule at `phase-ledger.md:121` reads as "resume at Phase 1". That is arguably correct behaviour, but it is unverified. **Not fixed this sprint.**

### Process note, coordinator error worth not repeating

Commit `ccde50d` used `git add -A` while two agents were still writing, and it swept up T10's `work-doc-template.md` edits into a commit whose message says it only records sweep findings. Nothing was lost and the content was re-verified against HEAD, but the commit message now under-describes its own diff. **Use explicit paths when committing during a live wave.** A wave-end commit is safe because the wave is settled by definition; a mid-wave commit is not.

### 2026-08-23, consistency scout report (29 files read, 6 confirmed findings)

The investigator read 29 files end to end plus mechanical greps over all 115 source `.md` files. It verified `sync_agent_mirrors.py --check` (all 9 mirrors in sync) and `check_doc_links.py` (all paths resolve), so there are no dead-pointer or mirror-drift findings. It re-verified every citation against disk in a final pass because three files were under live edit, and it correctly EXCLUDED two candidates that were fixed underneath it mid-run.

**F1, belongs to the MAIN GOAL, not the sweep. `SKILL.md:366` still lists 11 runtime primitives** and omits `always-on injection`, the twelfth this sprint added in Wave 1. T1's allowlist was `runtime-adapters.md` only and no task owned this line, so it is a genuine gap in my plan, not pre-existing drift. Must be fixed before release.

**F2, action-changing. The Phase 6 four-options menu is numbered differently in two places.** `SKILL.md:199` says "1 commit locally, 2 commit + push, 3 open a PR, 4 hold". The owners, `phases/phase-6-finish.md:24-27` and `references/finish.md:24-43`, both say "1 Merge to base branch locally, 2 Push and create a PR, 3 Keep the branch as-is, 4 Discard". **All four numbers name a different git operation.** This is not cosmetic: `skills/yolo/SKILL.md:29` auto-picks "Option 1", and `yolo:55` independently corroborates the owners' numbering. Following `SKILL.md` would auto-pick a different operation than the one yolo documents.

**F3, action-changing. `SKILL.md:134` and `:248` say "one agent per task"; `phases/phase-3-implement.md:22` says "ONE subagent per task BATCH" with `:70` "Cap a batch at 3 tasks."** Corroborated by `parallel-agents/README.md:20` (INPUTS `task_ids` and `task_descriptions`, both plural) and `yolo/SKILL.md:65`. Following SKILL.md fans out N agents where the protocol wants ceil(N/3).

**F4, retired Reviewer C still named as a live dispatch in six places.** Worst is `references/review-and-verify.md:139`, "Phase 5 dispatches FOUR foreground reviewers in parallel", which dispatches A/D/F unconditionally and ignores the evidence gate entirely. Also `parallel-agents/phase-5-multi-review-e-design.md:3` (and therefore its byte-identical mirror `agents/design-conformance-reviewer.md`), `skills/review-triage/SKILL.md:16` (names retired C, omits E and F), `parallel-agents/template-contract.md:15`, `parallel-agents/README.md:33` (eight lines above the line that retires C), and `phases/phase-5-review.md:27` ("Six reviewers") against `:84` "Cap at 5" in the same file.

**F5, `parallel-agents/README.md:10` puts OpenCode on the paste-the-template path**, calling it one of "the six best-effort targets". `runtime-adapters.md:47` calls OpenCode native on every axis, and `SKILL.md:238` agrees ("native tier (Claude Code, OpenCode)"). There are 4 best-effort runtimes, not six. Costs an OpenCode run the whole registry path.

**F6, WCAG version drift.** `template-contract.md:128` allowlists "WCAG 2.2 AA" and `:141` makes the allowlist binding. Reviewer E (`phase-5-multi-review-e-design.md:21`, its mirror `agents/design-conformance-reviewer.md:14`) and `commands/designify.md:9,37` say 2.1.

**Three NOT SURE items, deliberately not acted on:** whether `/codewalk` should be namespaced (the skill itself asserts the bare form and no validator pins it); whether "four-to-five reviewers" in `orchestration.md` and `quick/SKILL.md` is a cost estimate or a dispatch contract (true floor is 1 with B alone standing); and `SKILL.md:18` "a coherence reviewer in every review wave" against `:183` and commit `17c4a24`, which may already be handled by the in-flight T9 pass.

**Mirror hazard for whoever fixes F4 and F6:** `parallel-agents/phase-5-multi-review-e-design.md` is byte-mirrored into `agents/design-conformance-reviewer.md` and check `[75h]` diffs them. Editing one without re-running `scripts/sync_agent_mirrors.py` turns the triad red.

### 2026-08-23, T9 landed, plus a verification-integrity gotcha worth keeping

**T9** fixed all five listed sites plus the two I sent mid-flight, then found **four more nobody had listed**: `yolo/SKILL.md:25` ("B/C/F standing" inside a code fence, which its own first grep missed because the line contains neither "reviewer" nor "Phase 2.5"), `yolo:67`, `yolo:114` ("5-to-6 parallel reviewers", where the existing bans all miss the space-separated form), and both Phase 2.5 headings still saying "(parallel, mandatory)" for a fan-out that no longer exists. It also **caught and reverted a regression in its own draft**: its first retirement note ended "Phase 5 keeps its own Reviewers A through F", which would have reintroduced a live Reviewer C while removing one.

Every fix reuses an already-pinned literal where one existed (`1 reviewer scrutinizes work-doc`, `Dispatch the 1 reviewer`), so the new text is guarded by checks that already exist.

**Pin handoff for T7, from T9:** `check_token_present 'Dispatch exactly 1 reviewer'` on the phase file (which today has NO pin asserting a count at all, which is exactly why it drifted unguarded) and `'B is the standing member of every wave'` on `SKILL.md`. `check_no_token` on `3 parallel reviewers`, `Dispatch 2 foreground reviewers`, `Parallel agents scrutinize`, `Cap B at`, `B/C/F`, `5-to-6 parallel reviewers`. **Do NOT ban the generic `parallel reviewers`**: Phase 5 legitimately has a panel and that prose lives in the same files, so it would false-fire.

### VERIFICATION GOTCHA: recursive grep silently skips `dist/`

`grep` in this environment is a **shell function wrapping `ugrep`**, and ugrep honors ignore files. `dist/.gitignore` contains `*`, so **`grep -rn "<anything>" dist/` returns nothing and exits 0 even when the string is present.** `/usr/bin/grep -rn` on the same pattern found 18 hits.

This is not a product defect, it is a trap for anyone verifying mirror freshness: a recursive grep over `dist/` looks clean while being completely vacuous. **Verify the built tree with `/usr/bin/grep`, or with `find dist ... | xargs /usr/bin/grep`, never with a bare recursive `grep`.** The validator is unaffected: check `[55]` uses `git ls-files`, `[57]` delegates to `check_doc_links.py`, and no `check_no_token` call targets `dist/`.

### 2026-08-23, T8a landed (README content), and a budget conflict it correctly refused to resolve alone

447 to **446 lines**. One line added (the `rules/phase-discipline.md` tree row), two reclaimed by merging four older release bullets into two. No fact was removed from any of the four; T8a quoted every before and after in full.

Nine sprint corrections (always-on count in two spots on one line, tree row, injector count, primitive count 11 to 12, fourth always-on file, body list gaining section 0, and the ledger substrate at `:88` stated honestly instead of implying the to-do tool is its only home), plus six reviewer-drift corrections it verified against `agents/*.md` frontmatter and `phase-5-review.md:49` rather than against my brief.

**Extra sites it found unprompted:** `:295` claimed the parallel-agents directory holds "spec review (2)" and "multi-review (A/B/C inline)". Neither is true; there is one spec-review template and A/B/D/E/F each have their own file with no inline C. It also flagged that `investigation.md` is one mode-switched file, not two templates.

**A conflict in MY brief that T8a was right to surface instead of resolving.** I asked it to land at 446 AND said the release blurb would be 1-2 lines. Those do not reconcile: a release section costs 4 lines for ONE bullet (heading, blank, bullet, blank), so 446 + 4 = 450 exactly, and a second bullet is 451, which fails check `[7]`'s 250-450 bound. It did not spend another compression unasked.

**Decision, mine:** this sprint has two distinct user-visible stories (the tracker that can no longer vanish plus per-prompt phase discipline; and the doc-truth fixes, of which the Phase 6 menu misnumbering is the most user-impacting thing in the whole sprint). That is worth **two bullets, so T8b must first reclaim one more line** by compressing one further old blurb, landing at 445 before adding the section. Compressing older blurbs to pay for a new one is the standing rule for this file; raising the 450 bound is not an option.

**Left alone deliberately, with reasons:** `:182` and `:217` describe resume at the task level and say nothing false, they merely under-describe the ledger read-back; the fenced example work-doc at `:193-217` is already an abridged excerpt with no Original Ask or Q&A, so omitting section 0 there is not a contradiction and adding it would cost lines that do not exist.

**Version stamp caveat:** T8a stamped the new tree row and the `:386` sentence `(since v0.14.0)`, matching the column convention where every entry carries a version. If the release lands on a different number, those two spots need updating along with the badge.

## 7. Sprint Review (Phase 4 / 5)

### Evidence Ledger (Phase 4)

_(filled during Phase 4)_

### Scope ledger (Phase 5)

_(filled during Phase 5)_

## 8. Retrospective

_(filled at Phase 6)_

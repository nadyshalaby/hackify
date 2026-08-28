---
slug: single-implementer-agent
title: One implementer agent for every Phase 3 dispatch
status: finishing
type: refactor
created: 2026-08-28
project: hackify
related: [2026-08-27-contention-first-hackify, 2026-08-23-wave-implementer-migration]
current_task: Phase 4 verify, all 11 backlog tasks landed
worktree: null
branch: main
sprint_goal: |
  Retire the wave-implementer and module-implementer agent types and replace them with one
  `hackify:implementer`, whose side-by-side safety rules live in a reference it loads only
  when the dispatch names siblings running beside it.
---

# One implementer agent for every Phase 3 dispatch

## 0. Phase ledger

<!-- `- [ ]` open, `- [>]` the single in-progress item, `- [x]` done. Re-print at every phase boundary and at the end of every wave round. -->

- [x] Phase 1. Clarify (lock the goal anchor) (four wizard answers recorded verbatim in §2, anchor below)
- [x] Phase 2. Plan + Gate (work-doc + user "go") (plan presented, user answered "Go, build it as planned")
- [x] Phase 2.5. Spec review (1 reviewer, patch the doc) (report applied below; its size Critical re-measured and escalated to the user as Q5, backlog and wave order rewritten)
- [x] Phase 3. Implement (all waves landed) (W1 merged agent + doctrine file + rosters, W2 prose + 0.17.1, W3 validator pins + harnesses, W4 seams + gate)
- [x] Phase 3b. Debug (only if stuck) (not entered: no task needed a second fix attempt)
- [x] Phase 4. Verify (Evidence Ledger + ship gate) (9-row Evidence Ledger + ship gate in §7, every row run by the parent on the staged tree)
- [x] Phase 5. Review (panel + refuter, decision table closed) (4-lens panel A/B/D/F, E omitted no UI; 1 refuter judged 19 findings, 16 upheld 3 refuted; 2 fix waves landed all 16)
- [>] Phase 6a. Finish options + land choice
- [ ] Phase 6b. Cleanup sweep (Step C.5)
- [ ] Phase 6c. Archive work-doc to `done/` (Step D)
- [ ] Phase 6d. Update log + HTML report (Step F)

## 1. Original ask

> I want to remove wave-implementer and keep work handled by module-implementer

## Primary Goal & Guardrails

- **North-Star Goal.** Phase 3 has exactly one implementer agent type, `hackify:implementer`, that
  handles every dispatch shape (solo foundation, concurrent tracks, solo assembly, single-track
  round, quick mode) without losing a single rule either retired agent carried.

- **In-Scope.**
  - Replace `agents/wave-implementer.md` and `agents/module-implementer.md` with one
    `agents/implementer.md`, mirroring the merged template at
    `skills/hackify/references/parallel-agents/phase-3-implementation.md`.
  - Move the side-by-side rules into a new doctrine file,
    `skills/hackify/references/sibling-track-rules.md`, which the agent loads ONLY when
    `{{sibling_tracks}}` is other than `none`.
  - Rewrite every prose site that names either retired type (9 files, two of them mirror pairs).
  - Repurpose every validator fragment and test harness that pins either retired type by name.
  - Version bump to 0.17.1 with a CHANGELOG entry and the README badge.

- **Out-of-Scope / Non-Goals.**
  - No change to the contention-first dispatch model itself: foundation → tracks → assembly stays,
    the partition test stays, the wave plan stays. Only WHICH agent type each wave takes changes.
  - No change to any Phase 5 reviewer, the refuter, or the spec reviewer's own contract beyond the
    three lines where it names an implementer type.
  - No README "New in" release blurb (the user chose changelog-only).
  - Archived work-docs, `CHANGELOG.md` history, and `scripts/claim_corpus.json` are records and are
    not edited.

- **Guardrails / Invariants.**
  - **No rule is lost in the split.** Every behavioural rule unique to either agent survives, either
    in the merged prompt or in `sibling-track-rules.md`. A dropped rule is a Critical.
  - **Every file stays at or under 500 lines.** Measured this session: `agents/implementer.md` has a
    ceiling of 9 head lines + 2 fence lines + ~489 prompt lines. Both retired agent files carry a
    tail of ZERO, so there is no narrative outside the prompt to spend. `phase-3-implement.md` is
    496 and `15-wi-absent-cases.sh` is 497; both must stay ≤500.
  - **Mirror pairs move together.** `agents/implementer.md` ↔ `phase-3-implementation.md` and
    `agents/spec-reviewer.md` ↔ `phase-2.5-spec-reviewer.md` are byte-identical in their fenced
    block; editing one side alone is a build break.
  - **The six `[75h]` head clauses survive verbatim** in the merged head on both mirror sides, so
    Wave 3 changes only their file paths and never their wording. The six are listed in W1's brief.
  - **A validator is repurposed, never weakened.** Check [40] keeps policing an implementer rename;
    it changes which name is live and which are dead. Removing a check to make the tree green is a
    Critical.
  - **Every `{{token}}` used is declared** by the prompt's own INPUTS list (check [93]).
  - **`sibling-track-rules.md` does NOT go under `parallel-agents/`.** That directory's files are
    asserted to be full dispatch templates by `20-templates.sh`'s `PA_BUILD_FILES`; a doctrine file
    there would fail the template contract.

- **Success Signals.**
  - `bash scripts/sync-runtimes.sh` exits 0.
  - `bash scripts/validate-dod.sh` exits 0 with an ok-line total at or above its floor.
  - All 16 CI suites exit 0.
  - `git grep -n 'wave-implementer\|module-implementer'` returns hits only in: `CHANGELOG.md`,
    `docs/work/`, `scripts/claim_corpus.json`, `scripts/claim_fixtures.json`,
    `scripts/claim_fixture_git.py`, `scripts/claim_fixture_types.py`,
    `scripts/test_claim_fixtures.py`, `scripts/test_token_declarations.py` (the last two pin
    `agents/wave-implementer.md` as a HISTORICAL BLOB path at a fixed commit, verified this session,
    so the string must stay and both suites keep passing), check [40]'s own ban list, and
    validator/harness comments that describe the rename.

## 2. Clarifying Q&A

### Q1 (solo vs side-by-side)

**Q.** Some of module-implementer's rules only make sense when other agents work beside it. Once it
also handles the solo passes, those rules are wrong there. How should it tell the two apart?

**A.** *#1-A Switch them on and off.* The agent is told up front which agents run beside it. `none`
means the side-by-side rules stay off and it behaves like the old wave worker; a list turns them on.

### Q2 (agent name)

**Q.** Keep the name `module-implementer` or rename it?

**A.** *#2-B Rename to `implementer`.* The name should match what it does now.

### Q3 (quick mode)

**Q.** Quick mode hands work over with a short list of details and no planning document. What should
it do against an agent that expects a longer list?

**A.** *#3-A Allow `none` for the extras.* Inputs that only matter for side-by-side work can be
filled with the literal `none`.

### Q4 (release)

**Q.** How should this ship?

**A.** *#4-B Version 0.17.1, changelog only.* Noted at sign-off: renaming a dispatch type is a
breaking change for any saved dispatch, so a patch version understates it. The CHANGELOG entry says
plainly that the agent type name changed.

### Q5 (merge shape, raised by the Phase 2.5 spec review)

**Q.** Measured: the two prompts are 404 and 483 lines, the file cap allows about 489, and only 33
lines are verbatim-shared. One merged file cannot hold both contracts. How should the one agent be
built?

**A.** *#5-A One agent, side-by-side rules in a second file.* The agent's own file carries what
always applies; the rules that only matter when siblings run move to a file the agent opens only
when told siblings exist. Nothing is lost, everything stays under the cap.

## 3. Acceptance Criteria

1. `agents/implementer.md` exists with `name: implementer`, and `agents/wave-implementer.md` and
   `agents/module-implementer.md` do not exist.
2. The merged prompt declares `{{sibling_tracks}}`, and when it is other than `none` the agent is
   instructed to read `skills/hackify/references/sibling-track-rules.md` and apply it. That file
   carries every sibling-only rule: private database, cross-module type errors are not yours,
   report-don't-fix shared code, write a track file instead of Daily Updates, don't mount registrars,
   no `git checkout` / `restore` / `stash`, and the eight-item handoff report.
3. The merged prompt carries every always-on behaviour: ordered multi-task loop over `{{task_ids}}`,
   stop at the first task it cannot finish, keep what landed, report which task IDs landed and which
   did not under a `## Wave status` heading, `{{test_mode}}` RED→GREEN→REFACTOR, the scoped-tests
   rule driven by `{{exclusive_resources}}` plus the round's own task list, the file allowlist
   contract, both scouts, and the self-review table.
4. Every dispatch site names `hackify:implementer`: `skills/hackify/SKILL.md`,
   `skills/quick/SKILL.md`, `skills/hackify/references/parallel-agents/README.md`,
   `skills/hackify/references/phases/phase-3-implement.md`,
   `skills/hackify/references/work-doc-template.md`,
   `skills/hackify/references/contention-dispatch.md`, `README.md`, and the spec-reviewer mirror
   pair (`agents/spec-reviewer.md` + `phase-2.5-spec-reviewer.md`).
5. The agent roster, the mirror-pair list and both sync manifests name exactly one implementer:
   `60-primitives.sh`'s `AGENTS_EXPECTED` (10 → 9), `sync_agent_mirrors.py`'s `MIRROR_PAIRS`
   (10 → 9), `00-helpers.sh`'s `CLAUDE_CODE_EXTRA` and its template list, `20-templates.sh`'s
   `PA_BUILD_FILES`, and `74-agent-shell-blocks.sh`'s `ASB_FILES` (`ASB_EXPECTED` 11 → 10).
6. `bash scripts/sync-runtimes.sh` and `bash scripts/validate-dod.sh` both exit 0, and all 16 CI
   suites exit 0, with fresh pasted output.
7. Every file this sprint touches is at or under 500 lines, proven by `wc -l`.
8. `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` and the README badge all read
   `0.17.1`, and `CHANGELOG.md` carries a `## [0.17.1]` entry naming both retired types and saying a
   saved dispatch must be updated.
9. No spelled-out input count or list-size bound is left stale: the six "fifteen"/"thirteen" sites,
   `work-doc-template.md`'s "eight of them have no other producer", and
   `parallel-agents/README.md`'s "lists 10 and `agents/` holds 10" all match the tree.

## 4. Approach

Keep one agent type and split its contract by when it applies rather than by which agent carries it.
Everything that holds on every dispatch stays in the prompt. The rules that only hold when siblings
are writing the same tree move to `skills/hackify/references/sibling-track-rules.md`, which the agent
reads only when `{{sibling_tracks}}` names someone. A solo dispatch never opens it and never receives
instructions written for a concurrent one; a track dispatch gets all of them. This is the same shape
the agent already uses for `{{rules_dir_path}}` and `{{mandatory_reading}}`.

The one-file merge was tested against the tree and rejected: the two prompts are 404 and 483 lines
with a ~489-line ceiling and 33 verbatim-shared lines, and both agent files carry a zero-line tail, so
the plan's original escape hatch (spend the narrative prose) does not exist. Q5 records the decision.

Inputs are collapsed rather than unioned. `{{folder_allowlist}}` folds into `{{file_allowlist}}`,
`{{gate_commands}}` splits back into `{{test_command}}` / `{{lint_command}}` / `{{typecheck_command}}`,
`{{module_plan_path}}` folds into `{{work_doc_path}}` plus `{{task_descriptions}}`, `{{framing}}`
becomes `{{sibling_tracks}}`, and `{{module_id}}` becomes `{{track_id}}`. The track-only inputs are
documented as `none`-able so quick mode and the solo waves fill `none` rather than needing a second
contract; `none` is a decision, an empty value still means the dispatcher did not decide.

Two paths are reused rather than invented: the merged template takes `phase-3-implementation.md`
(freed by deleting the wave template) because there is now exactly one Phase 3 implementation prompt,
and check [40] keeps its job of policing an implementer rename with the live and dead names swapped.

### Repo Brief

- **Stack.** Markdown prompt/skill plugin for Claude Code, with bash validator fragments and Python
  test harnesses. No compiler, no package manager. Evidence: `.claude-plugin/plugin.json:1-3`,
  `ls scripts/` shows `*.sh` + `*.py` only.
- **Test command.** 16 suites, run verbatim from `.github/workflows/ci.yml`:
  `python3 skills/lawkeeper/scripts/test_audit.py`,
  `python3 skills/lawkeeper/evals/corpus/run_corpus.py`,
  `python3 scripts/check_question_clarity.py`, `bash hooks/test_block_banned_tokens.sh`,
  `bash hooks/test_inject_context.sh`, `bash hooks/test_block_ai_attribution.sh`,
  `bash scripts/test_ban_tokens.sh`, `python3 scripts/test_doc_link_lines.py`,
  `python3 scripts/test_claim_fixtures.py`, `python3 scripts/test_token_declarations.py`,
  `python3 scripts/test_section_exists.py`, `python3 scripts/test_literal_absent_claims.py`,
  `python3 scripts/test_replay_claim_checks.py`, `python3 scripts/test_ci_suite_coverage.py`,
  `python3 scripts/test_tamper_battery.py`, `python3 scripts/test_render_report.py`.
  Evidence: `.github/workflows/ci.yml:87-143`, all 16 measured at exit 0 on 2026-08-28.
- **Lint / typecheck.** There is no separate linter or typechecker. The gate is
  `bash scripts/sync-runtimes.sh` (must run first, it builds `dist/`) then
  `bash scripts/validate-dod.sh`. Evidence: `.github/workflows/ci.yml:173-177`; baseline measured
  at exit 0 with 1377 ok lines against a floor of 1350.
- **Layout.** `agents/` registered subagent definitions; `skills/<name>/SKILL.md` the workflows;
  `skills/hackify/references/` the per-phase protocol and the canonical agent templates;
  `rules/` the always-on injected law; `scripts/validate-dod.d/*.sh` the numbered checks sourced by
  `scripts/validate-dod.sh`; `dist/` generated and gitignored. Evidence: `scripts/validate-dod.sh:5-8`,
  `dist/.gitignore:1`.
- **The one layering rule.** Every file in `agents/` is a MIRROR: its first fenced block is copied
  byte-for-byte from a canonical template under `skills/hackify/references/parallel-agents/`, and any
  hand-written tail after `<!-- parent-side: not mirrored -->` is maintained on both sides by hand.
  Edit the template, then run `python3 scripts/sync_agent_mirrors.py`. Evidence:
  `scripts/sync_agent_mirrors.py:1-10,142-153`; measured this session, both implementer mirrors carry
  a zero-line tail and `--check` reports them in sync.
- **Rules source.** `rules/hard-caps.md` (500-line cap, injected every prompt) plus the user-global
  `CLAUDE.md`. The cap is enforced over `skills agents rules scripts hooks commands`, exemption list
  is `CHANGELOG.md` alone. Evidence: `scripts/validate-dod.d/80-file-size-caps.sh:12-13,52-58`.
- **Test convention.** A check is a numbered fragment under `scripts/validate-dod.d/`, and its list
  sizes are hand-written beside the list (`check_list_size`) so dropping an entry cannot silently
  drop a check. Tamper harnesses under `scripts/test_*.py` plant a regression and assert the check
  reddens. Evidence: `scripts/validate-dod.d/73-implementer-rename.sh:54-59`,
  `scripts/test_tamper_mirror_tails.py:76-82`.
- **Landmines.**
  1. Hard 500-line cap. `phase-3-implement.md` is 496 and `15-wi-absent-cases.sh` is 497.
  2. `scripts/test_tamper_mirror_tails.py:81` uses `agents/wave-implementer.md` as its ONE marked
     mirror-tail example and pins `MIRROR_PAIR_COUNT = 10`. Deleting the file breaks the harness.
  3. `scripts/test_ban_tokens.d/15-wi-absent-cases.sh:134,240` asserts the literal
     `hackify:wave-implementer` still occurs in a live file, so a green is not a fail-open. Banning
     it tree-wide breaks the suite's premise; `TB_WI_LIT` must move to `hackify:implementer`.
  4. `agents/spec-reviewer.md:440,448,450` and
     `references/parallel-agents/phase-2.5-spec-reviewer.md:447,455,457` are the same three lines
     inside a mirrored block. Both sides change in one edit or `sync_agent_mirrors.py` reds.
  5. `20-templates.sh:27-28`, `74-agent-shell-blocks.sh:28`, `00-helpers.sh:99-100` carry the
     template paths in LIVE arrays with hand-written size bounds, not comments.
  6. `dist/` is gitignored, so a repo-wide `git grep` misses
     `dist/claude-code/agents/wave-implementer.md`; it is regenerated by `sync-runtimes.sh`.
  7. `scripts/test_claim_fixtures.py:53` and `scripts/test_token_declarations.py:41` name
     `agents/wave-implementer.md` as a historical blob at a pinned commit. Both keep passing after
     the delete and the strings must NOT be removed.

## 5. Sprint Backlog

- [x] **T1a. Merged prompt, ROLE through VERIFICATION.** In
  `skills/hackify/references/parallel-agents/phase-3-implementation.md`, replace the wave template in
  place with the merged always-on contract. Collapse the input lists per §4 (no union), declare
  `{{sibling_tracks}}` and `{{track_id}}`, document every track-only input as `none`-able, and gate
  the sibling-only material behind a METHOD step that reads
  `skills/hackify/references/sibling-track-rules.md` when `{{sibling_tracks}}` is not `none`. Keep
  the six `[75h]` head clauses verbatim in the head. Update "the thirteen declared above" to the
  merged count.
  *Files:* `skills/hackify/references/parallel-agents/phase-3-implementation.md`.

- [x] **T1b. Merged OUTPUT skeleton and the parent-side tail.** In the same file, merge the two
  report shapes into one that opens with `## Wave status` (landed / not landed / stopped at) followed
  by `## Paths written`, `## Paths deleted`, `## Scout dispositions`, the per-task blocks, and the
  self-review table, and state which extra sections a sibling dispatch adds. Update the parent-side
  round procedure below `<!-- parent-side: not mirrored -->` (currently lines 413-422) so it matches
  the merged report. Delete
  `skills/hackify/references/parallel-agents/phase-3-module-implementation.md`. Result ≤500 lines.
  *Files:* `skills/hackify/references/parallel-agents/phase-3-implementation.md`,
  `skills/hackify/references/parallel-agents/phase-3-module-implementation.md` (delete).

- [x] **T1c. Write the sibling-track rules doctrine file.** Create
  `skills/hackify/references/sibling-track-rules.md` carrying every sibling-only rule lifted out of
  `agents/module-implementer.md`, nothing weakened: private database and the refusal gate that gets
  in its way, cross-module type errors are expected and not yours, report-don't-fix shared code,
  build against the plan's interface not landed code, write `docs/work/<slug>.tracks/<track_id>.md`
  instead of Daily Updates, do not mount registrars, no `git checkout` / `restore` / `stash`, the
  `git stash list` check, and the eight-item handoff report. Result ≤500 lines.
  *Files:* `skills/hackify/references/sibling-track-rules.md`.

- [x] **T2. Create the merged agent mirror.** Write `agents/implementer.md` with `name: implementer`,
  a description covering both dispatch shapes and the mode switch, and the fenced block
  byte-identical to T1a/T1b's template. Do NOT run `sync_agent_mirrors.py` before T3 lands, since
  `MIRROR_PAIRS` must name the pair first. Delete `agents/wave-implementer.md` and
  `agents/module-implementer.md`. Result ≤500 lines.
  *Files:* `agents/implementer.md`, `agents/wave-implementer.md` (delete),
  `agents/module-implementer.md` (delete).

- [x] **T3. Point every roster and manifest at the new pair.** In `scripts/sync_agent_mirrors.py`
  replace the two implementer tuples in `MIRROR_PAIRS` with one
  `("agents/implementer.md", f"{PA}/phase-3-implementation.md")`, correct the docstring's "the same
  ten things" to nine, and refresh the stale wave-implementer comments at lines 63, 80 and 224. In
  `scripts/validate-dod.d/60-primitives.sh` replace the two `AGENTS_EXPECTED` entries with
  `"implementer"`. In `scripts/sync-runtimes.d/00-helpers.sh` replace the two agent paths in
  `CLAUDE_CODE_EXTRA` (lines 187-188) with `"agents/implementer.md"` AND drop the deleted template
  from the template list at lines 99-100, adding the new `sibling-track-rules.md` so it ships.
  Then run `python3 scripts/sync_agent_mirrors.py` to prove the pair is in sync.
  *Files:* `scripts/sync_agent_mirrors.py`, `scripts/validate-dod.d/60-primitives.sh`,
  `scripts/sync-runtimes.d/00-helpers.sh`.

- [x] **T7. Rewrite the hackify workflow prose.** In `skills/hackify/SKILL.md` rewrite the
  agent-selection paragraph and the Phase 3 dispatch row so one type serves every wave, restating the
  refusal inputs for the merged list and correcting "its fifteen" (lines 136, 138, 255). In
  `skills/hackify/references/phases/phase-3-implement.md` collapse the four agent-selection table
  rows into the single type plus the mode switch. Both files ≤500 lines.
  *Files:* `skills/hackify/SKILL.md`, `skills/hackify/references/phases/phase-3-implement.md`.

- [x] **T8. Rewrite the dispatch catalog and the contention doctrine.** In
  `skills/hackify/references/parallel-agents/README.md` merge the two implementer rows of the
  type-to-INPUTS table into one, replace the "Which implementer a Phase 3 wave takes" table with the
  mode-switch rule, and correct the closing "the table above lists 10 and `agents/` holds 10". In
  `skills/hackify/references/contention-dispatch.md` update the "Module briefs" paragraph (line 226,
  "its fifteen") and every implementer-type mention, and point at `sibling-track-rules.md`. In
  `skills/hackify/references/work-doc-template.md` correct line 175's "fifteen INPUTS" AND its
  "eight of them have no other producer", update line 179's type name, and rename the
  `### Module briefs` block's guidance to cover both dispatch shapes.
  *Files:* `skills/hackify/references/parallel-agents/README.md`,
  `skills/hackify/references/contention-dispatch.md`,
  `skills/hackify/references/work-doc-template.md`.

- [x] **T9. Update quick mode and the spec-reviewer mirror pair.** In `skills/quick/SKILL.md:41`
  dispatch `hackify:implementer` and state which track-only inputs quick fills with `none`. In
  `skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md` (lines 447, 455, 457) and its
  mirror `agents/spec-reviewer.md` (lines 440, 448, 450) replace the two implementer type names with
  the one live type, editing both sides identically so the mirror check stays green.
  *Files:* `skills/quick/SKILL.md`,
  `skills/hackify/references/parallel-agents/phase-2.5-spec-reviewer.md`, `agents/spec-reviewer.md`.

- [x] **T10. Update the README and ship 0.17.1.** Fix `README.md:114`'s "take the wave implementer"
  prose and any repository-layout line naming the retired agents, and bump the version badge to
  0.17.1. Set `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` to `0.17.1`. Add a
  `## [0.17.1]` CHANGELOG entry naming both retired types and saying plainly that a saved dispatch
  must be updated. Keep README within its 250..450 line bound.
  *Files:* `README.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
  `CHANGELOG.md`.

- [x] **T4. Repurpose check [40] onto the new rename.** In
  `scripts/validate-dod.d/73-implementer-rename.sh` swap the live type in `WI_TYPE_SITES` from
  `hackify:wave-implementer` to `hackify:implementer` (the three sites are unchanged), point
  `WI_MIRRORS` at `agents/implementer.md` + `phase-3-implementation.md`, and add
  `hackify:wave-implementer` and `hackify:module-implementer` to `WI_BANNED` beside the existing
  `hackify:wave-task-implementer`, updating the hand-written `check_list_size` bound that polices it.
  Update the block's comments so they describe the rename actually being policed. ≤500 lines.
  *Files:* `scripts/validate-dod.d/73-implementer-rename.sh`.

- [x] **T5. Move the remaining validator pins onto the merged pair.** In
  `71-release-mechanism-pins.sh` (the `{{task_ids}}` / `{{task_descriptions}}` / `STOP there` loops at
  lines 334 and 350) and `75-ship-bar.sh` (`WI_HEAD_FILES` at 258, and the `AGENT_FILE_TOTAL` /
  `MIRROR_PAIR_TOTAL` comparisons at 151-156 and 228) replace the wave paths with
  `agents/implementer.md` + `phase-3-implementation.md`, leaving `WI_HEAD_CLAUSES` wording untouched.
  In `20-templates.sh` drop the deleted template from the live `PA_BUILD_FILES` array (lines 27-28).
  In `74-agent-shell-blocks.sh` drop the deleted template from `ASB_FILES` (line 28), set
  `ASB_EXPECTED` 11 → 10, and refresh the line-10 and line-17 comments. Refresh the stale
  wave-implementer comments in `56-dist-integrity.sh` and `93-token-declarations.sh`.
  *Files:* `scripts/validate-dod.d/71-release-mechanism-pins.sh`,
  `scripts/validate-dod.d/75-ship-bar.sh`, `scripts/validate-dod.d/20-templates.sh`,
  `scripts/validate-dod.d/74-agent-shell-blocks.sh`,
  `scripts/validate-dod.d/56-dist-integrity.sh`, `scripts/validate-dod.d/93-token-declarations.sh`.

- [x] **T6. Re-anchor the two tamper harnesses.** In `scripts/test_tamper_mirror_tails.py` point
  `MARKED_PAIR` at `('agents/implementer.md', PA_DIR + '/phase-3-implementation.md')` and set
  `MIRROR_PAIR_COUNT` to 9, re-deriving `MARKED_TEMPLATE_COUNT` and `TAILS_COMPARED_COUNT` from the
  tree rather than assuming. In `scripts/test_ban_tokens.d/15-wi-absent-cases.sh` point `TB_WI_LIT`
  at `hackify:implementer` so the fail-open guard still names a literal that lives in a tracked file.
  That file is 497 lines; keep it ≤500.
  *Files:* `scripts/test_tamper_mirror_tails.py`,
  `scripts/test_ban_tokens.d/15-wi-absent-cases.sh`.

- [x] **T11. Assembly: sync, validate, reconcile.** Run `bash scripts/sync-runtimes.sh`, then
  `bash scripts/validate-dod.sh`, then all 16 CI suites. Fix any seam the tracks described
  differently (a stale count, an unmirrored tail, a pin naming a path that moved). Confirm with
  `wc -l` that every touched file is ≤500 and with `git grep` that the retired names survive only
  where Success Signal 4 allows.
  *Files:* whatever the reconciliation needs, bounded by the union of T1a-T10.

### Execution waves (from the Phase 2.5 spec review, with its ordering correction applied)

| Wave | Tasks | Why it is serial |
|---|---|---|
| W1 | T1a, T1b, T1c, T2, T3 | All hold the merged prompt text, the mirror contract and one 500-line budget. T3's `MIRROR_PAIRS` edit must land before T2's sync run. |
| W2 | T7, T8, T9, T10 | All four restate ONE dispatch rule across four files; each reads text the others rewrite. |
| W3 | T4, T5, T6 | Every one pins a literal or a path that W2 writes. T6 sed-lifts `wi_absent` out of T4's file at runtime. |
| W4 | T11 | Holds `dist/`, the full validator and all 16 suites. |

**W2 runs before W3, reversing the backlog's original numbering.** Three red mid-round states exist
otherwise: check [40] repointed before the prose is rewritten fails at three sites; `TB_WI_LIT`
repointed before the prose exists fails its fail-open guard; and the prose rewritten before check
[40] moves leaves the old literal missing from three pinned sites. No validation runs until W4.

## 6. Daily Updates

**T1a. Merged prompt, ROLE through VERIFICATION.** Rewrote
`skills/hackify/references/parallel-agents/phase-3-implementation.md` in place as the one
always-on implementer contract. INPUTS collapsed to 21 (`{{module_id}}`, `{{module_plan_path}}`,
`{{framing}}`, `{{folder_allowlist}}` and `{{gate_commands}}` retired and absent from the file,
checked by grep); eight track-only inputs documented as `none`-able with the refusal law kept.
Added THE MODE SWITCH before the build steps, naming
`skills/hackify/references/sibling-track-rules.md` verbatim. Carried the module contract's FLOOR,
test-first-and-mutations, property-based money guidance, fixture/oracle traps, one-unit-at-a-time,
three-strikes, never-invent-a-symbol, scope ceiling, suppression scan and `{{sharp_invariants}}`
weighting. Six `[75h]` head clauses verified present exactly once each in the head above the
fence. "the thirteen declared above" now reads "the twenty-one declared above".

**T1b. Merged OUTPUT skeleton and the parent-side tail.** One report shape: `## Wave status`
first (Landed / Not landed / Stopped at, plus Track and DONE), then `## Paths written` and
`## Paths deleted` as fenced bare-path blocks, `## Scout dispositions`, then a per-task block
under `## <task id>` with the merged self-review table. Per-section budgets and the ≤200
words-per-task cap kept. The eight-item handoff report is referenced, not duplicated. Parent-side
tail below `<!-- parent-side: not mirrored -->` rewritten for the merged report.
`skills/hackify/references/parallel-agents/phase-3-module-implementation.md` deleted. Evidence:
`wc -l` reads 499 for the merged file; `bash -n` on its extracted VERIFICATION block exits 0; a
replay of check [93]'s parser over the file reports 21 declared inputs and 0 undeclared uses.

**T1c. Sibling-track rules doctrine file.** Created
`skills/hackify/references/sibling-track-rules.md`, 176 lines, a doctrine file rather than a
dispatch template and deliberately NOT under `parallel-agents/` (that directory's files are
asserted to be full templates by `20-templates.sh`'s `PA_BUILD_FILES`). Opens by saying
`hackify:implementer` loads it only when `{{sibling_tracks}}` is other than `none` and that a solo
dispatch never reads it. Carries, lifted rather than summarised: the blind-sibling framing, the
`{{owned_elsewhere}}` surfaces, the private database plus the VERIFICATION gate that refuses
without one, cross-module type errors expected and not yours, build against the plan's interface,
never invent a symbol, report-don't-fix on shared code, the track file instead of Daily Updates,
no registrar mounting, the `git checkout` / `restore` / `stash` ban with the `git stash list`
check, the eight-item handoff report in full, and three extra self-review rows. Evidence: `bash
-n` on its fenced shell block exits 0; `check_doc_links.py` reports no dangling pointer from it.

**T2. Merged agent mirror.** Wrote `agents/implementer.md` (492 lines) with `name: implementer`, a
description covering both dispatch shapes and the mode switch, the `Canonical source:` line in the
established format, and a fenced block plus mirrored tail copied byte-for-byte out of the merged
template. The six `[75h]` head clauses were asserted at exactly one occurrence each in the head
before the file was written, so the description cannot mask one. `agents/wave-implementer.md` and
`agents/module-implementer.md` deleted. `sync_agent_mirrors.py` was NOT run here; `MIRROR_PAIRS`
did not name the pair until T3.

**T3. Rosters and manifests.** `sync_agent_mirrors.py`: the two implementer tuples in
`MIRROR_PAIRS` replaced by one `("agents/implementer.md", f"{PA}/phase-3-implementation.md")`; the
docstring's "the same ten things" now reads nine; the wave-implementer comments at the marker
rule, the duplicated-prose note and `marker_misplaced` refreshed. Every other count in that
docstring that describes the LIVE tree was re-measured against the nine pairs rather than adjusted
by hand: four templates still carry a richer tail, eight still owe their mirror an empty region
(five with no tail either side, three with the marker on tail line 1), and the marker rule still
binds exactly one pair, so only the "of the ten" denominators moved. Sentences that record a past
incident were left alone. `60-primitives.sh`: `AGENTS_EXPECTED` now carries one `"implementer"`,
so its derived count moves 10 to 9. `00-helpers.sh`: `CLAUDE_CODE_EXTRA` carries
`agents/implementer.md`, the template list drops the deleted module template, and
`skills/hackify/references/sibling-track-rules.md` was added so the doctrine file ships.

*Wave evidence.* `python3 scripts/sync_agent_mirrors.py --check` exits 0 over all nine pairs with
`ok agents/implementer.md matches phase-3-implementation.md`; `--check-tails` exits 0 with
`1 pair(s) compared a non-empty mirrored tail, 8 asserted an empty one, 0 failed`. `wc -l` reads
499 / 176 / 492 / 375 / 80 / 331 for the six written files, all at or under the 500-line cap.
`bash -n` passes on both shell fragments and `ast.parse` on the Python one.
`bash scripts/sync-runtimes.sh --dry-run` reports 7 runtimes and 805 files, with
`sibling-track-rules.md` shipping to the same 6 runtimes as every other reference file.
`python3 scripts/test_token_declarations.py` 15 passed / 0 failed and
`python3 scripts/test_claim_fixtures.py` 38 passed / 0 failed, so the historical blob those two
pin at `agents/wave-implementer.md` survives the delete.

**T7. Hackify workflow prose.** `skills/hackify/SKILL.md`, three sites rewritten for the one type.
"Agent selection per wave" now says every wave takes `hackify:implementer` and that
`{{sibling_tracks}}` is the only thing the wave's shape changes, naming
`references/sibling-track-rules.md` as what a side-by-side dispatch loads and a solo one never
opens. The Phase 3 dispatch paragraph's refusal clause was restated for the merged list: the agent
refuses on ANY of its twenty-one INPUTS arriving unfilled, eight accept the literal `none`, and the
three whose absence is silent are named (`{{sibling_tracks}}`, `{{sharp_invariants}}`,
`{{exclusive_resources}}`). The stale "its fifteen" is gone; twenty-one and eight were counted off
the merged template's own INPUTS list this session, not copied. The Phase 3 row of the
"Dispatch sub-agents for" table names the one type plus the mode switch.
`skills/hackify/references/phases/phase-3-implement.md`, the four-row agent-selection table
collapsed to one type with `{{sibling_tracks}}` as the varying column. Swept for retired types and
retired inputs: `grep -n 'wave-implementer\|module-implementer\|module_id\|module_plan_path\|{{framing}}\|folder_allowlist\|gate_commands'` returns nothing. The line-494 sentence was
VERIFIED rather than assumed: `## Wave status` survives the merge at
`phase-3-implementation.md:399,419` and `agents/implementer.md:402,422`, so the sentence stays
true and was left alone. Evidence: `wc -l` reads 379 and 498, both under the 500 cap;
`sync_agent_mirrors.py --check` exits 0 over all nine pairs.

**T8. Dispatch catalog and contention doctrine.**
`skills/hackify/references/parallel-agents/README.md`, the two implementer rows of the
type-to-INPUTS table merged into one `hackify:implementer` row listing all 21 inputs, naming the
eight that take `none`, and pointing at `phase-3-implementation.md`. That row is what cleared the
tree's one dangling pointer: line 21 named the deleted `phase-3-module-implementation.md`, and
`python3 scripts/check_doc_links.py` now exits 0 over 118 files where it reported one failure
before. The "Which implementer a Phase 3 wave takes" section became
"What a Phase 3 wave passes as `sibling_tracks`": one type in every row, with the mode switch as
the varying column, `none` for a solo foundation wave, a solo assembly wave and a single-track
round, the other tracks' IDs for concurrent ones. The closing count was MEASURED, not adjusted:
`ls agents/*.md | wc -l` reads 9 and an awk count of the table's own agent rows reads 9, so
"lists 10 / holds 10" now reads 9 and 9.
`skills/hackify/references/contention-dispatch.md`, the "Module briefs" paragraph now names
`hackify:implementer` and twenty-one INPUTS, and the "eight with no other producer" was
re-derived against the merged list rather than carried over: seven survive
(`track_id`, `sibling_tracks`, `owned_elsewhere`, `mandatory_reading`, `sharp_invariants`,
`database_name`, `handoff_contract`), because `folder_allowlist` folded into a `file_allowlist`
the Sprint Backlog already produces and `module_plan_path` folded into the work-doc. Added a
paragraph pointing at `sibling-track-rules.md` as what `sibling_tracks` turns on. The doctrine
itself was NOT touched: foundation then tracks then assembly, the partition test and the three
classes of serial resource are byte-identical.
`skills/hackify/references/work-doc-template.md`, the brief block is now
`### Module briefs (every round)` with both stale numbers corrected to twenty-one and seven, the
skeleton fields renamed to the live inputs, and each track-only field carrying its `none` answer
for a solo wave. Two `<module-id>` track-file placeholders moved to `<track_id>` to match the live
doctrine file. Evidence: `wc -l` reads 57 / 291 / 382; `check_doc_links.py` exits 0; the 21 and the
8 were counted off the merged template's own INPUTS block this session.

**T9. Quick mode and the spec-reviewer mirror pair.** `skills/quick/SKILL.md`, the "3. Implement"
row dispatches `hackify:implementer` and now names, in the row itself, the eight inputs quick fills
with the literal `none`: `{{track_id}}`, `{{sibling_tracks}}` (nothing runs beside a quick
dispatch, so the sibling-track rules stay off), `{{owned_elsewhere}}`, `{{mandatory_reading}}`,
`{{sharp_invariants}}`, `{{database_name}}`, `{{handoff_contract}}` and `{{work_doc_path}}`, with
the reason quick has no work-doc and the spec travels in `{{task_descriptions}}` instead. The row's
existing rules were left intact and re-read to confirm it: one implementer for the whole change,
file-disjoint units, the allowlist bound, and reading `## Wave status` for which unit IDs landed.
`phase-2.5-spec-reviewer.md` and `agents/spec-reviewer.md`, the same three lines inside the
byte-identical fenced block replaced in ONE pass with one string applied to both files, so the pair
could not drift: the prose now says every wave takes `hackify:implementer` and `sibling_tracks` is
what changes, and the three example wave lines carry
`hackify:implementer, sibling_tracks=none` / `=<the other tracks>`. The replacement was written to
land on the same six prose lines it replaced, so neither file's length moved. Evidence:
`python3 scripts/sync_agent_mirrors.py --check` exits 0 with
`ok agents/spec-reviewer.md matches phase-2.5-spec-reviewer.md`; `wc -l` reads 128 / 497 / 490.

**T10. README and the 0.17.1 release.** `README.md`, three prose sites plus the badge. Line 114's
"Foundation, assembly and any single-track round take the wave implementer; two or more concurrent
tracks take the module implementer" now says every wave goes to the same implementer and the one
thing that changes is whether it is told other tracks are working beside it. The plugin-primitives
paragraph dropped "the Phase 3 wave and module implementers" for "the Phase 3 implementer". The
"## Repository layout" block's `agents/` line moved from 10 sub-agent definitions to 9, MEASURED
with `ls agents/*.md | wc -l`. "## Parallel agents" was read end-to-end and names no agent type and
no count, so it was left alone. Badge bumped to 0.17.1. No "New in 0.17.1" section was added, per
the user's changelog-only choice. `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
set to 0.17.1 (marketplace carries it twice and both moved). `CHANGELOG.md` carries a
`## [0.17.1] - 2026-08-28` entry directly under the header block: it names
`hackify:wave-implementer` and `hackify:module-implementer` verbatim, names `hackify:implementer`,
says in bold that a saved dispatch naming either old type must be updated and that such a dispatch
fails at dispatch time rather than at validation, and records that the side-by-side rules now live
in `skills/hackify/references/sibling-track-rules.md` behind the `sibling_tracks` switch.
Evidence: `jq -r .version .claude-plugin/plugin.json` and
`jq -r '.plugins[0].version' .claude-plugin/marketplace.json` both print 0.17.1, and both files
parse under `jq .`; `wc -l README.md` reads 382, inside its 250..450 bound.

*Wave evidence (T7-T10).* `python3 scripts/sync_agent_mirrors.py --check` exits 0 over all nine
pairs. `python3 scripts/check_doc_links.py` exits 0, `every .md link and prose path in 118 files
resolves`, where it reported one dangling pointer at `parallel-agents/README.md:21` before this
wave. `wc -l` over the eight capped files reads 379 / 498 / 57 / 291 / 382 / 128 / 497 / 490, all
at or under 500, and README at 382 inside 250..450. `git grep 'wave-implementer\|module-implementer'`
over `skills/ agents/ README.md` returns only the one retirement note in
`parallel-agents/README.md`. No added line in the diff carries an em or en dash.

**T4. Check [40] repurposed onto the new rename.** `73-implementer-rename.sh`, repurposed and not
weakened: no assertion was dropped and the banned set grew from 6 literals to 13. `WI_TYPE_SITES`
keeps its three unchanged sites and now asserts `hackify:implementer`. `WI_MIRRORS` points at
`agents/implementer.md`; both pinned phrases were VERIFIED to survive the merge rather than assumed,
at `agents/implementer.md:193,196` and `phase-3-implementation.md:190,193`, so neither needed
rewording. `WI_BANNED` gained `hackify:wave-implementer` and `hackify:module-implementer`, with its
hand-written bound moved 6 to 13. `WI_DEAD_INPUTS` gained the five inputs the merge collapsed, bound
moved 2 to 7. Four are pinned bare, but `{{framing}}` is pinned WITH braces because the bare word
`framing` was measured surviving in 10 legitimate live lines (README frontmatter prose, the wizard
contract, four-principles), so a bare ban would red on correct text; the comment argues that
asymmetry in place. `parallel-agents/README.md` joined `WI_LIVE_PATHS`, waiving a REAL occurrence:
line 54 is the retirement note, which cannot record what was retired without naming it. The comment
makes that argument in the CHANGELOG row's own voice and says plainly that it waives a real
occurrence rather than being future-proofing. `wi_absent` and `wi_absent_all` were left untouched in
name and brace layout, since T6 sed-lifts them anchored on `/^wi_absent() {$/`.

**T5. Remaining validator pins moved onto the merged pair.** `71-release-mechanism-pins.sh`, both
loops repointed to `agents/implementer.md`; all three literals verified present in both files first
(`{{task_ids}}` 7x, `{{task_descriptions}}` 3x, `STOP there` 1x in each), so nothing needed a
substitute pin. `75-ship-bar.sh`, `WI_HEAD_FILES` repointed and `WI_HEAD_CLAUSES` deliberately not
touched. The agent-count comparisons needed NO edit: both sources were re-measured this session and
independently read 9 (`sync_agent_mirrors.py --list` and `find agents`), and no literal 10 is
hand-written anywhere in the file. The "eight of the nine" prose at lines 188 and 203 became true
again at 9 rather than needing a fix. `20-templates.sh`, the deleted template dropped from the live
`PA_BUILD_FILES`; that array carries NO `check_list_size` bound, which is a gap worth noting rather
than one I introduced. `74-agent-shell-blocks.sh`, `ASB_FILES` dropped the deleted template and
`ASB_EXPECTED` moved 11 to 10; the line-10 incident was KEPT and given the file's fate plus why the
lesson outlives the file, and line 17 no longer names the retired input. `56-dist-integrity.sh` and
`93-token-declarations.sh`, comment-only, with both incidents kept and their subject's fate named.
Both were VERIFIED to discover inputs dynamically rather than assumed to: 56 reads the sync plan and
the manifest, 93 reads `git ls-files`. `DI_GENERATED_EXPECT` counts destinations with no canonical
source, so deleting a copied agent moves both sides equally and it did not shift; the live run
confirms it.

**T6. Both tamper harnesses re-anchored.** `test_tamper_mirror_tails.py`, `MARKED_PAIR` repointed to
`agents/implementer.md` and all three constants RE-MEASURED against the tree rather than adjusted:
`--check-tails` reports 1 non-empty mirrored tail and 8 empty over 9 pairs, and a marker grep across
`parallel-agents/` returns 4 templates. So `MIRROR_PAIR_COUNT` 10 to 9 and `TAILS_COMPARED_COUNT` 2
to 1, while `MARKED_TEMPLATE_COUNT` HELD at 4, because the deleted template carried no marker and the
one that absorbed it still does. The derived assertions were read and confirmed to follow, and three
docstrings ("nine real files", "a tenth agent file, nine pairs", "a census of 11") became true again
at 9. `15-wi-absent-cases.sh`, `TB_WI_LIT` repointed to `hackify:implementer`; the surrounding
comment already described the role generically ("the live implementer type [40] pins as present"), so
only the value moved and a note records WHY: the old value is now banned, which inverts the premise
from present to absent and would have reddened `tb_wi_fixture_ready`. `TB_WI_DECOY` was re-checked
and is still absent everywhere but its own assignment. The first draft of that note spelled the
retired type verbatim and reddened [40] on my own comment; it now names the type without the
`hackify:` prefix and says so. Both files sit at exactly 500 lines against the cap.

*Wave evidence (T4-T6).* `bash scripts/sync-runtimes.sh` OK, 805 files across 7 runtimes.
`bash scripts/validate-dod.sh` on a STAGED view of the tree exits 1 with ONE failure, check [27]'s
`stable channel ref is 'v0.17.0'; expected 'v0.17.1'`, which is pre-existing and outside this wave:
T10 bumped both `version` fields in `.claude-plugin/marketplace.json` and left the stable channel
`ref` behind, and neither of check [27]'s two inputs is in this wave's allowlist. Every [40] red on
the UNSTAGED tree is the `--cached` half of that check's union scan reading the git index, which
still holds pre-sprint content for Wave 1 and Wave 2's unstaged files; that is the check working as
its own comment documents, and it clears the moment the sprint is staged. Proven without touching the
real index, by running the validator against a throwaway `GIT_INDEX_FILE`. Ok-line total 1370 against
a floor of 1350. The drop from the 1377 baseline is fewer files and not a check that stopped running,
proven by a HEAD baseline in a throwaway worktree: 91 check IDs at baseline and 91 now, with an empty
LOST set; the two deleted agent files and the deleted template contributed 22 ok lines between them
and the one new agent file contributes 9. `bash scripts/test_ban_tokens.sh` 161 passed / 0 failed,
`python3 scripts/test_tamper_battery.py` 163 passed / 0 failed (this is what actually drives
`test_tamper_mirror_tails.py`, which has no `__main__` and whose own exit 0 only proves it imported),
`python3 scripts/test_ci_suite_coverage.py` 20 passed / 0 failed. `bash -n` passes on all eight shell
files and `py_compile` on the Python one; `wc -l` reads 420 / 379 / 417 / 357 / 80 / 348 / 409 / 500 /
500, all at or under the cap.


### Phase 5 fix wave, findings F-C3 / F-C2 / F-I3 / F-M1

*F-C3, the build-order rule is back in the always-on contract.* METHOD step 1 of
`skills/hackify/references/parallel-agents/phase-3-implementation.md` now carries the half the
merge dropped, under `**THEN WRITE YOUR BUILD ORDER, STILL BEFORE THE FIRST EDIT.**` All four of
its load-bearing claims survive the compression: units listed in DEPENDENCY ORDER from the plan,
the acceptance signal and the `→ verify:` check written beside each, a unit whose check you
cannot name sent back to the plan, and the whole list written before the first edit because a
spine reconstructed afterwards describes what you did instead of constraining it. It sits in the
always-on contract rather than in `sibling-track-rules.md`, because it binds a solo wave too.

*F-C2, the per-track database gate now refuses `none`.* Gate (e) in
`skills/hackify/references/sibling-track-rules.md` reads
`case "$own_db" in ''|none|*'{{'*|*'<the database_name'*)`. Run four ways with the fence's own
`case` verbatim: `own_db=none` FAIL exit 1, `own_db=` (empty) FAIL exit 1,
`own_db='{{database_name}}'` FAIL exit 1, `own_db=hackify_track_m12` PASS exit 0. The pre-fix
pattern printed PASS exit 0 on `none`, which is what line 43 of that same file already called a
dispatch to refuse. `bash -n` parses the extracted gate.

*F-I3, the concurrency derivation reads `{{sibling_tracks}}` first.* METHOD step 6 now settles
solo-vs-concurrent on the input that cannot be absent: a named track means concurrent, `none`
means SOLO full stop, and quick mode reaches that answer with no work-doc to read. The work-doc
frontmatter's `current_task` key drops to a secondary signal for a round the dispatcher did not
fully describe, and only a work-doc that EXISTS whose key will not parse still falls back to
concurrent. A solo quick wave no longer runs scoped-only tests for want of frontmatter.

*F-M1, the 500-line file bought back headroom.* `phase-3-implementation.md` is 493 lines, down
from exactly 500 while absorbing F-C3 and F-I3, which cost 8 lines between them. The space came
from tightening prose in ROLE, the INPUTS descriptions, the FLOOR caps paragraph, METHOD steps 4,
7 and 8, the per-task stop block, four VERIFICATION comments and the OUTPUT preamble. All 21
INPUTS are still declared and the same nine still accept `none`. No rule, no VERIFICATION gate,
no INPUT and none of the six `[75h]` head clauses were cut. `agents/implementer.md` is 486 and
`sibling-track-rules.md` is 181.

*Wave evidence (F-C3, F-C2, F-I3, F-M1).* `python3 scripts/sync_agent_mirrors.py --check` exits 0
over all nine pairs with `ok agents/implementer.md matches phase-3-implementation.md`; the
mirror's hand-carried tail was carried across by hand, since the sync script copies a block and
never a tail. `bash scripts/sync-runtimes.sh && bash scripts/validate-dod.sh` exits 0 with zero
FAIL lines and an `[0b]` ok-line total of 1371 against a floor of 1350, reproduced on three
consecutive runs. The law-scout's deterministic tier scanned 3 of 3 files handed to it and
returned 0 findings. Nothing was committed and no working-tree state was discarded.

**F-C1 + F-I7. The parallel-agents README is back under the ban scan, with nothing waived.**
`73-implementer-rename.sh` excluded that whole file from [40], which is a WHOLE-FILE waiver: only
line 54 carried banned literals (2 of 13), so 11 more were waived across the file, and it was
simultaneously a `WI_TYPE_SITES` presence pin, the one combination the block's own comment says a
presence pin cannot cover. Took the third option this tree already demonstrated at
`scripts/test_ban_tokens.d/15-wi-absent-cases.sh:135` and reworded README:54 to name the two
retired types WITHOUT their `hackify:` prefix, which `WI_BANNED` does not pin, so the historical
record still says what was retired and when. Then removed the `WI_LIVE_PATHS` exclusion and
rewrote the `:107-110` comment that called the waiver "the narrower of the two costs", since a
third and narrower option existed. Evidence: `git ls-files -- "${WI_LIVE_PATHS[@]}" | grep -c
'parallel-agents/README.md'` = 1 (was 0), scope 262 -> 263 files against a floor of 120.

**F-C4. Three consumers said eight none-able inputs where the producer says nine.**
`parallel-agents/README.md:20`, `skills/hackify/SKILL.md:138` and the `## [0.17.1]` CHANGELOG entry
all omitted `{{work_doc_path}}`, which `skills/quick/SKILL.md:41` instructs quick mode to pass as
`none`. Verified the producer's list myself before writing any number: `phase-3-implementation.md`
declares 21 inputs and names exactly nine as `none`-able. All three now say nine and name
`{{work_doc_path}}` with the quick-mode reason.

**F-C5. Every quick-mode dispatch would have been refused.** `grep -c exclusive_resources
skills/quick/SKILL.md` returned 0: quick's `none` list named 8 inputs and omitted
`{{exclusive_resources}}` entirely, which the merged prompt's pre-step-1 input count and its
VERIFICATION gate (a) both refuse on. Added it with its reason (a quick change holds no exclusive
resource) and made quick's list match the producer's nine exactly, stating that quick passes `none`
on all nine and fills the other twelve. Evidence: that grep now returns 1.

**F-C6. `20-templates.sh` had no size bound on either template array.** `grep -c check_list_size`
returned 0 on that file, while every sibling list in the directory carries a hand-written bound.
This sprint dropped one entry from `PA_BUILD_FILES` and four checks silently left the run with it
([9], [10], [12] and [15] all iterate these arrays); the ok-line total went 1377 -> 1371 and only
the floor's slack absorbed it. Measured the real lengths rather than assuming: `PA_BUILD_FILES` is
3 and `PA_REVIEW_SINGLE_FILES` is 8. Added both bounds following the `73:54-59` / `74:39-41`
convention. They sit under the `[9]` header rather than at the arrays, because nothing prints a
per-fragment banner and an ok line emitted at the definitions would file itself under `[8]`; the
arrays carry a pointer comment instead. Evidence: that grep now returns 2.

**F-I1. SKILL.md called the `### Module briefs` block "the full input list".** It carries 8 fields
of 21. Fixed the wording to say what the block actually is, the fields a concurrent round must
author because nothing else produces them, and added `{{exclusive_resources}}` to the block, since
a concurrent round genuinely must decide it per track. The block is now exactly the none-able nine
minus `{{work_doc_path}}`, which is `none` in quick mode alone and quick writes no work-doc for the
block to sit in.

**F-I2. A concurrent round could not reconcile at all.** `sibling-track-rules.md:73` sends each
track to `docs/work/<slug>.tracks/<track_id>.md`, while `phase-3-implement.md` exempted only the
work-doc, so declaring those files reddens check 1 and omitting them reddens check 3. Extended the
exemption in BOTH halves, since the carve-out is executable and not just prose: the reconciliation
script now derives the tracks directory from `WORK_DOC` (no second `<slug>` to get wrong) and
filters it. A smoke test over a 7-path fixture caught a real bug in my first draft: a shell `case`
glob's `*` matches `/`, so it also exempted `<slug>.tracks/nested/deep.md` while the comment
claimed one level. The shipped form uses `index()` plus a `/`-free remainder, verified to exempt
only direct `.md` children and to leave nested paths, non-`.md` files and every other path in
`round_diff`. The file was 498 of a 500 hard cap, so the addition was compressed to fit rather than
allowed to breach it; it now sits at exactly 500.

**F-I4. Two fragments claimed a pathspec equivalence that is false.**
`91-claim-resolvers.sh:82` and `93-token-declarations.sh:102` each said they use "the same
three-part pathspec `WI_LIVE_PATHS` uses". That array is now five entries (six before F-C1), while
their own `LIVE` arrays are genuinely three-part and correct. Rewrote the two sentences, and the
two matching docstrings that repeated the same false claim, to describe what their pathspec IS
without asserting the equivalence. Their `LIVE` arrays were NOT touched, as instructed.

**F-I6. Three files gave three different answers for the solo-wave `none` set.**
`contention-dispatch.md` named four, `work-doc-template.md` marked five, the prompt makes nine
none-able. Reconciled all of them: four fields (`track_id`, `sibling_tracks`, `owned_elsewhere`,
`database_name`) are `none` on EVERY solo wave because nothing runs beside it, and the other four
are decided per wave and are `none` only when that wave truly has nothing to put there,
`exclusive_resources` included, since a solo wave can hold a shared database as easily as a
concurrent one. Both files now say explicitly that their eight are a SUBSET of the agent's nine,
naming the ninth and why it is absent, rather than reading as a full list. Both also moved "seven
of them have no other producer" to eight, following the added field.

**F-M5. `hackify:implementer` was pinned present at 3 sites while 4 more named it unpinned.**
Verified each of the four really carries the literal before adding it (`phase-3-implement.md` 1,
`contention-dispatch.md` 1, `work-doc-template.md` 1, `agents/spec-reviewer.md` 4), so none was
left out. Added all four to `WI_TYPE_SITES` and moved the hand-written bound from 3 to 7, with a
comment recording that the first three are where a dispatcher is TOLD the type and these four
TEACH the dispatch, which is the half a rename can miss.

**Wave gate.** `bash scripts/sync-runtimes.sh && bash scripts/validate-dod.sh` exits 0 with zero
FAIL lines and an `[0b]` ok-line total of 1377, up from the 1371 baseline by exactly the +6 these
fixes add (2 from F-C6's bounds, 4 from F-M5's new presence pins). All 16 CI suites exit 0. Every
file written is at or under the 500-line cap, `CHANGELOG.md` excepted as the one exemption.

## 7. Sprint Review (Phase 4 / 5)

### Evidence Ledger (Phase 4), all runs by the parent this session on the staged tree

| # | Acceptance item | Evidence | Result |
|---|---|---|---|
| 1 | One implementer agent, old two gone | `ls agents/*.md \| wc -l` = 9; `ls agents/wave-implementer.md agents/module-implementer.md` = 2x "No such file"; `head -3 agents/implementer.md` = `name: implementer` | PASS |
| 2 | Mode switch reads the doctrine file | `phase-3-implementation.md:121` instructs reading `sibling-track-rules.md` IN FULL when `{{sibling_tracks}}` is not `none`; that file carries all eight handoff items (`## 1.`..`## 8.`) | PASS |
| 3 | Always-on wave behaviour survives | `## Wave status` present at `phase-3-implementation.md:399,419` and `agents/implementer.md:402,422`; check [40] pins `KEEP everything that already landed on disk` and `which task IDs landed, which task IDs did not` on both mirror sides and passes | PASS |
| 4 | Every dispatch site names the live type | check [40] `WI_TYPE_SITES` asserts `hackify:implementer` in `SKILL.md`, `quick/SKILL.md`, `parallel-agents/README.md`; validator exit 0 | PASS |
| 5 | Rosters and manifests all read 9 | `sync_agent_mirrors.py --list \| wc -l` = 9; `grep -c '"agents/' 00-helpers.sh` = 9; `find agents` = 9; check [30] ok | PASS |
| 6 | Gate green | `sync-runtimes.sh` exit 0; `validate-dod.sh` exit 0 on THREE consecutive runs, `[0b]` = 1371 ok lines (floor 1350, pre-sprint baseline 1377), 0 FAIL lines; all 16 CI suites exit 0 | PASS |
| 7 | 500-line cap holds | `find skills agents rules scripts hooks commands -type f ... -exec wc -l` filtered to `>500` returns nothing; README 382 within 250..450 | PASS |
| 8 | 0.17.1 everywhere | `jq .version plugin.json` = 0.17.1; `jq .plugins[0].version marketplace.json` = 0.17.1; stable channel `ref` = v0.17.1; README badge = 0.17.1; `CHANGELOG.md:8` = `## [0.17.1] - 2026-08-28` | PASS |
| 9 | No stale count | "fifteen" -> twenty-one, "eight of them" -> seven, "lists 10 / holds 10" -> 9, all re-derived by the waves and re-checked by check [40] / [30] passing | PASS |

### Ship gate (Phase 4)

| Leg | Status | Evidence |
|---|---|---|
| `ship.build` | PASS (blocking, the diff touches `agents/` and `skills/`, which the sync copies) | `bash scripts/sync-runtimes.sh` exit 0, `dist/claude-code/agents/implementer.md` on disk, 9 agent files shipped |
| `ship.boot` | PASS (blocking, the diff touches files the harness parses at load) | `hooks/inject-context.sh` exits 0 on a real prompt payload; `agents/implementer.md` frontmatter parses with `name: implementer`, a 1693-char description, and balanced fences |
| `ship.smoke` | PARTIAL, and stated rather than glossed | A live dispatch of `hackify:implementer` was ATTEMPTED this session and REFUSED: `Agent type 'hackify:implementer' not found`. Claude Code resolves agent types from the INSTALLED plugin copy at `~/.claude/plugins/cache/hackify-marketplace/hackify/0.17.0/`, not from this working tree, and it resolves them at session start. So the new type cannot be dispatch-tested from inside the session that created it. Every wave after W1 was therefore dispatched on the still-installed `hackify:wave-implementer`. What IS proven: the file parses, ships into `dist/`, and satisfies every structural check the validator makes of an agent definition. What is NOT proven: that a real dispatch of `hackify:implementer` resolves and runs. That needs a plugin reinstall and one dispatch. |



### Scope ledger (Phase 5)

Reviewed diff: `git diff HEAD -- . ':(exclude)docs/work/*'`, 36 files. Panel dispatched in ONE message:
A security & correctness (18 executable paths), B quality + plan (never sliced, whole diff),
D performance (18 executable paths), F coherence (whole diff). **E design omitted, not folded:
the diff has no UI surface.** One refuter judged all 19 findings before any fix was spent.

### Decision table (Phase 5), one round

| # | Finding | Sev | Refuter | Decision | Evidence |
|---|---|---|---|---|---|
| C1+I7 | `73-implementer-rename.sh:128` waived a WHOLE file from the retired-name ban; that file is also a presence pin | Critical | UPHELD both lenses | accept | Fixed the narrow way the diff already demonstrated: reworded the retirement note prefix-less, then DELETED the exclusion. `git ls-files` over the pathspec now returns the file, scope 262 -> 263 |
| C2 | `sibling-track-rules.md` database gate could not fail on `none` | Critical | UPHELD, refuter EXECUTED it and got PASS | accept | Pattern now `''\|none\|...`; watched refuse on `none`, empty and unsubstituted, and pass on a real value |
| C3 | **Rule lost in the merge**: "WRITE YOUR BUILD ORDER BEFORE YOU WRITE CODE" | Critical | UPHELD, zero hits for it anywhere post-image | accept | Restored into the always-on prompt with all four claims; `grep -c 'is a wish'` = 1 on both mirror sides |
| C4 | none-able count said nine in the producer, eight in three consumers | Critical | UPHELD | accept | All six sites now say nine and name `{{work_doc_path}}` |
| C5 | quick mode omitted `{{exclusive_resources}}`, so EVERY quick dispatch would be refused | Critical | UPHELD, `grep -c` = 0 | accept | `grep -c exclusive_resources skills/quick/SKILL.md` = 1 |
| C6 | `20-templates.sh` had zero `check_list_size`; 4 checks silently left the run (1377 -> 1371) | Critical | UPHELD | accept | Two bounds added; ok-line total back to 1377 |
| I1 | SKILL.md called a 7-of-21 block "the full input list" | Important | UPHELD | accept | Claim corrected, `exclusive_resources` added to the block |
| I2 | doctrine writes `<slug>.tracks/<id>.md`, which no allowlist permits | Important | UPHELD | accept | Exemption extended in `phase-3-implement.md`, prose AND the executable filter; a glob bug found by the fix wave's own smoke test |
| I3 | concurrency derived from frontmatter with no `none` branch | Important | UPHELD | accept | Step 6 now settles on `{{sibling_tracks}}` first |
| I4 | two files claimed a "three-part pathspec" that is now six | Important | UPHELD, scope corrected 4 -> 2 files | accept | Fixed at 4 sites inside those 2 files (comment + docstring each) |
| I5 | `15-wi-absent-cases.sh:136` comment called stale | Important | **REFUTED** | push-back | Refuter cite `:135`: the antecedent is the bare `wave-implementer` two lines up, not the live literal. Under the finding's reading the sentence self-refutes |
| I6 | three files gave three answers for the solo-wave `none` set | Important | UPHELD | accept | All reconciled against nine; subsets now say they are subsets |
| M1 | three files at exactly 500 of 500 | Minor -> Important | UPHELD | accept | Prompt bought back to 493. Two files under `scripts/` remain at 500, carried as a follow-up |
| M2 | `sync_agent_mirrors.py:65` column wrap | Minor | **REFUTED** | push-back | Refuter: cited line is 79 chars, the reflowed one is `:63`, and no column rule exists in the repo |
| M3 | machine-verified line citations dropped 66 -> 50 | Minor | UPHELD | accept | Recorded here rather than reverted: naming a thing beats citing a line that moves |
| M4 | `TENTH_AGENT` name stale | Minor | **REFUTED** | push-back | Refuter: it was stale at BASE and this diff FIXED it. Editing would reintroduce the defect |
| M5 | live type pinned at only 3 sites | Minor | UPHELD | accept | Four more sites pinned, bound moved 3 -> 7 |
| M6 | `<slug>` used by doctrine, not a declared input | Minor | UPHELD | accept | Left as written: derivable from `{{work_doc_path}}`, which is never `none` on a side-by-side dispatch |

**Validator flake, investigated not buried.** Two waves each reported one unreproducible `grep -qF` red
(check [9], then check [12]), both on `phase-3-implementation.md`, both while that agent was editing the
tree. Nine consecutive clean runs followed on a quiescent tree, then three more after the fix waves. Read
as a read racing an in-flight write, not a validator defect. Recorded because it is unexplained.

### Final gate (post-fix, parent-run, staged tree)

- `bash scripts/sync-runtimes.sh` exit 0.
- `bash scripts/validate-dod.sh` exit 0 on three consecutive runs, 0 FAIL, `[0b]` = **1377** ok lines,
  matching the pre-sprint baseline exactly after C6 restored the six that had gone missing.
- All 16 CI suites exit 0.

## 8. Retrospective

_(filled at Phase 6)_
**T11a. Release-channel ref that Wave 2 missed.** `.claude-plugin/marketplace.json:15`, the stable
channel's `"ref"` moved from `v0.17.0` to `v0.17.1`. Wave 2 bumped both `version` fields and left the
tag pin behind, which is exactly what check [27] exists to catch: it compares the stable channel's
ref against `plugin.json`'s version and reported `stable channel ref is 'v0.17.0'; expected
'v0.17.1'`. The edge channel's `"ref": "main"` at line 40 was deliberately left alone, since that
channel tracks the branch by design and pinning it to a tag would retire the channel. Evidence:
`jq .` parses the file; `jq -r '.plugins[] | "\(.name) version=\(.version) ref=\(.source.ref)"'`
prints `hackify version=0.17.1 ref=v0.17.1` and `hackify-edge version=0.17.1 ref=main`, and
`jq -r .version .claude-plugin/plugin.json` prints 0.17.1, so all three release numbers agree.

**T11b. The none-able seam between the merged prompt and quick mode.** Closed the real
contradiction Wave 2 found and correctly refused to fix outside its allowlist:
`skills/quick/SKILL.md:41` dispatches `hackify:implementer` with `{{work_doc_path}}` as `none`,
and the merged prompt's own contract listed only eight none-able inputs without it, so a strict
agent reading its contract would have refused that dispatch. In
`phase-3-implementation.md` the count moved eight to NINE and `{{work_doc_path}}` joined the
list, with the clause "`none` on the first is quick mode: no work-doc exists, so
`{{task_descriptions}}` carries the whole spec." Then every downstream site that read the input
unconditionally was swept rather than assumed: input 1's own declaration now carries "`none` in
quick mode"; OBJECTIVE reads "from `{{work_doc_path}}`, or `{{task_descriptions}}` at `none`";
METHOD step 1 reads "or skip it when it is `none`"; and METHOD step 7's Daily Updates rule reads
"quick mode has no such doc and reports in OUTPUT alone". THE MODE SWITCH was a fifth site found
by grep rather than named in the task: its solo branch asserted "You write the work-doc's `## 6.
Daily Updates` entries yourself", a flat contradiction with the new step 7, so it now reads "You
write any `## 6. Daily Updates` entries yourself". METHOD step 6 was checked and needed NO edit:
it derives the round's task list from work-doc frontmatter, and it already says that an absent or
unparseable key means treat this wave as concurrent, which is the safe branch a `none` work-doc
lands on by itself.

*The 500-line cap was the binding constraint and it was paid, not exceeded.* The mirrored block
was measured optimally packed at 96 columns: a scan of every prose paragraph in it found no
rewrap that saves a line without merging a heading or a bold paragraph opener into its body, so
there was no free line to buy. Four of the six edits were therefore fitted INTO existing slack by
rewording rather than by adding lines (OBJECTIVE gave back 33 characters via "touching only its
own allowlist and nothing outside" and "the next wave"; the mode switch gave back 11), and only
the none-able paragraph itself grew, by one line. `phase-3-implementation.md` sits at exactly 500
and `agents/implementer.md` at 493, both at or under the cap. Every line in the fenced block was
re-measured at 96 CHARACTERS or fewer; the four lines `awk` reports over 96 are pre-existing and
count bytes, not characters, because they carry `≤` and `✓`.

`skills/hackify/references/work-doc-template.md` was RE-DERIVED and needed no edit, which is the
answer rather than an omission. Its "twenty-one INPUTS" still holds because nothing was added or
removed from the INPUTS list, only reclassified. Its "seven of them have no other producer"
counts the Module briefs block's own fields, measured at seven in the file (`track_id`,
`sibling_tracks`, `owned_elsewhere`, `mandatory_reading`, `sharp_invariants`, `database_name`,
`handoff_contract`); `{{work_doc_path}}` is not one of them and does have another producer, since
Phase 2 writes the work-doc, so widening the none-able list from eight to nine leaves that seven
untouched.

Evidence: `python3 scripts/sync_agent_mirrors.py` resynced the pair and `--check` then exits 0
with `ok agents/implementer.md matches phase-3-implementation.md` across all nine pairs. `wc -l`
reads 500 and 493. The none-able list parses to exactly nine distinct tokens. The template's own
INPUTS block still counts 21 numbered entries. `grep -n 'work_doc_path\|work-doc'` over the merged
prompt returns no remaining unconditional read inside the agent's own steps.

**T11c. The sprint staged, and the gate proved green.** Wave 3's index-staleness diagnosis was
VERIFIED before it was trusted, not after. `git diff --cached --stat` showed only three staged
deletions and `git diff --stat` showed 25 files modified but unstaged, so the index still carried
their pre-sprint content. Check [40] was read rather than assumed: `73-implementer-rename.sh:221`
and `:298` run a UNION of a worktree scan and a `git grep --cached` index scan, and the block's own
comment argues for that union (a `--cached` half catches a literal deleted from the worktree but
still live in the index, which `git commit` without `-a` would then ship). The prediction the
diagnosis makes was then measured directly: `hackify:wave-implementer` returned 5 worktree hits
against 20 index hits, and `module_plan_path` 2 against 3, with the extra hits landing in exactly
the unstaged-modified files (`agents/spec-reviewer.md`, `skills/hackify/SKILL.md`,
`contention-dispatch.md`). That is the check working as documented, not a defect.

Six failures, not seven, were live by the time this ran: T11a had already cleared check [27]. All
six were `[40] ... found by the cached scan`. `git add -A` staged the sprint, no commit, no branch,
no push, and no `git checkout` / `restore` / `stash` at any point. All six cleared.

Final gate, re-run after staging: `bash scripts/sync-runtimes.sh` exits 0 with `OK, synced 805
files across 7 runtimes`, then `bash scripts/validate-dod.sh` EXITS 0 with zero FAIL lines. The
`[0b]` ok-line total reads 1371 against a floor of 1350. That is 6 below the 1377 pre-sprint
baseline, inside the tolerance, and it is fewer FILES rather than a check that stopped running:
the run's distinct check-ID census reads 91, the same 91 Wave 3 measured against a HEAD baseline,
and the arithmetic closes exactly, since the pre-staging run counted 1365 ok lines with 6 failures
and each cleared failure converts to one ok line (1365 + 6 = 1371).

*One transient worth recording rather than burying.* The FIRST post-staging run reported a single
`FAIL [9] phase-3-implementation.md missing **ROLE**`, and it did not reproduce on any of the four
runs that followed, all of which exit 0 with zero failures. It was chased rather than shrugged off:
`**ROLE**.` is present at line 11 of the file and `od -c` shows the exact bytes; check [9] is a
plain `grep -qF` over `$(cat "$f")` with no index read (`20-templates.sh:107`), and re-running that
loop by hand finds all six anchors; the file's SHA is byte-identical before and after three
consecutive gate runs; `git diff` reports the worktree identical to the index; and the validator
was read for a source-mutating step or a background job and has neither. Only ROLE failed and the
other five anchors passed, which points at a short read of the file's head rather than at content.
Unexplained, unreproduced in five subsequent runs, and recorded here so the next person who sees
it has this run to compare against.

**T11d. Full suite set, citation sweep, size proof and the retired-name census.**

*(a) All 16 CI suites exit 0*, run in `.github/workflows/ci.yml` order, twice: once before the
citation sweep and once after it plus the re-stage. `test_audit.py` 56/56, `run_corpus.py` PASS,
`check_question_clarity.py` 7 banks / 0 defects, `test_block_banned_tokens.sh` 41/41,
`test_inject_context.sh` 66/0, `test_block_ai_attribution.sh` 29/0, `test_ban_tokens.sh` ALL
PASSED, `test_doc_link_lines.py` 31/31, `test_claim_fixtures.py` 38/0, `test_token_declarations.py`
15/0, `test_section_exists.py` 18/0, `test_literal_absent_claims.py` 18/0,
`test_replay_claim_checks.py` 24/0, `test_ci_suite_coverage.py` 20/0, `test_tamper_battery.py`
163/0, `test_render_report.py` 14/0. `test_tamper_mirror_tails.py` was deliberately not run
standalone: it has no `__main__`, so its own exit 0 would only prove it imported, and
`test_tamper_battery.py` is what actually drives it.

*(b) Thirteen stale citations swept, not twelve.* Wave 3 reported 12; the grep finds 13, the extra
one in `91-claim-resolvers.sh` (it carries 4, not 3). The mapping was RE-DERIVED from
`git show HEAD:` rather than trusted, and it confirms Wave 3's numbers: HEAD `:100` is the
`WI_LIVE_PATHS=(...)` declaration, now at 125; HEAD `:102` is the `WI_LIVE_PATHS` self-exclusion,
now at 127; HEAD `:174-195` is the worktree-first comment through `for mode in worktree cached`,
now 200-221, a uniform +26. None of the three was rewritten to the new NUMBER, because the fix
`71-release-mechanism-pins.sh:326-333` argues for is to cite a NAME the file either carries or does
not, so it goes stale loudly instead of resolving to the wrong paragraph. All 13 now read
`73-implementer-rename.sh's WI_LIVE_PATHS` or `73-implementer-rename.sh's wi_absent`;
`94-section-exists.sh:120` reads `WI_LIVE_PATHS self-exclusion`, since that site is specifically
about self-exclusion, while `95-literal-absent-claims.sh:106` keeps the plain name because its own
sentence already says "self-excludes". Four comment paragraphs were re-wrapped back to the file's
80-column house width after the substitution lengthened them, verified as pure re-wraps by
asserting the de-wrapped text is byte-identical; only `94-section-exists.sh` grew, by one line, to
480. The three embedded-Python docstrings were shortened to
`"""Tracked paths under WI_LIVE_PATHS, 73-implementer-rename.sh's pathspec."""` so they stay near
80 columns while naming both the array and its file. `git grep '73-implementer-rename\.sh:[0-9]'`
over the six files now returns nothing. Evidence: `bash -n` exits 0 on all five shell fragments and
`py_compile` on `claim_fixture_git.py`; the full gate and all 16 suites re-run green afterwards.

*(c) Every touched file is within its bound*, measured with `wc -l` over the sprint's own staged
file list rather than a hand-kept one. The two the brief flagged are confirmed at EXACTLY 500 and
unchanged by this wave: `scripts/test_tamper_mirror_tails.py` 500 and
`scripts/test_ban_tokens.d/15-wi-absent-cases.sh` 500. `README.md` is 382, inside its 250..450
bound. `CHANGELOG.md` is 1523 and is the sole exemption. Everything else is at or under 500, with
`phase-3-implementation.md` now at the cap at 500 (T11b), `98-work-doc-ledger-sync.sh` at 498,
`phase-3-implement.md` at 498, `phase-2.5-spec-reviewer.md` at 497, `agents/implementer.md` at 493
and `94-section-exists.sh` at 480. Three paths are deletions and have no count.

*(d) The retired-name census: 151 hits, every one legitimate, zero misses.* Archived and current
work-docs under `docs/work/` carry 99 (this sprint's own doc 32, four archived docs 66, one
archived HTML report 1); they are records and check [40] excludes the path. `scripts/claim_corpus.json`
28 and `scripts/claim_fixtures.json` 4 are fixture records. `CHANGELOG.md` 5 is release history.
`73-implementer-rename.sh` 6 is check [40]'s own ban list plus its comments, and it self-excludes
from its own scan. `test_token_declarations.py:41` and `test_claim_fixtures.py:53` pin
`agents/wave-implementer.md` as a HISTORICAL BLOB at a fixed commit; both suites pass and both
strings must stay. `claim_fixture_types.py:61` and `claim_fixture_git.py:123` are docstrings
recording the earlier rename. `56-dist-integrity.sh:17`, `93-token-declarations.sh:15,56` and
`15-wi-absent-cases.sh:135` are recorded incidents whose lesson outlives the file they name; the
last of those names the type WITHOUT the `hackify:` prefix on purpose, because the prefixed form is
now banned. `parallel-agents/README.md:54` is the retirement note, which cannot record what was
retired without naming it, and check [40] waives that path deliberately.

*Wave evidence (T11a-T11d).* `bash scripts/sync-runtimes.sh` exits 0 with `OK, synced 805 files
across 7 runtimes`. `bash scripts/validate-dod.sh` EXITS 0 with zero FAIL lines and an `[0b]`
ok-line total of 1371 against a floor of 1350, across 91 distinct check IDs. All 16 CI suites exit
0. `python3 scripts/sync_agent_mirrors.py --check` exits 0 over all nine pairs. The sprint is
STAGED and the worktree is clean against the index; nothing was committed, no branch was created,
nothing was pushed, and `git checkout`, `git restore` and `git stash` were never run.

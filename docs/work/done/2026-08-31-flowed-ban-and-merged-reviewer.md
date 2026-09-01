---
slug: 2026-08-31-flowed-ban-and-merged-reviewer
title: Close the flowed-ban false green, then build and A/B the merged all-lens reviewer
status: done
type: refactor
created: 2026-08-31
project: hackify
related: [2026-08-30-throughput-and-quick-default]
current_task: "Shipped as v0.18.0 on 2026-09-01. 22 items carried, listed in section 7c."
worktree: null
branch: main
sprint_goal: |
  Every ban that runs over wrapped prose stops being able to return a false green, the
  five-agent reviewer panel is replaced by one merged all-lens reviewer but only if it
  matches the panel head to head on a real diff, and the carry-over defects in quick's
  report path and codewalk's advertised command are closed with a check that keeps them closed.
---

# Close the flowed-ban false green, then build and A/B the merged all-lens reviewer

## 0. Phase ledger

- [x] Clarify (goal anchored, carry-over verified against the code)
- [x] Plan (approved as written; running in quick mode by user instruction)
- [x] Implement (Groups A, B, C, D, then E and its follow-ups: 132 items, 120 closed, 12 carried)
- [x] Verify (all 19 CI commands, bar green at 1870 ok, 30/30 stable, re-taken post-sync)
- [x] Review (both instruments, one refuter, 35 findings judged, 3 fix rounds; bar re-taken at 1887 ok)
- [x] Cleanup + summary (update log and HTML report written, work-doc archived, v0.18.0 tagged)

Mode: **quick**. Spec review and the four-option finish are skipped by that mode. The
work-doc is kept rather than dropped, because it carries the approved plan.

**The review phase is the one place this sprint deviates from its own mode, on purpose.**
Quick normally runs one reviewer and one refuter. This sprint's Phase 5 dispatches BOTH the
merged reviewer and the five-agent panel over the same diff, because decision 2A requires the
merged reviewer to beat the panel on a diff neither has seen, and this sprint's own diff is
that diff. Running both here buys the unseen half of the measurement out of a review round we
owe the sprint anyway, and it is the reason the five panel agents stayed registered instead of
being deleted. It does not reopen the round cap: it is still one review pass and one refuter,
with two instruments reading the same diff once.

An earlier version of this block said the panel was skipped on this sprint's own diff and that
the Group B A/B was the only place it ran. That was written before Q10 and stopped being true
the moment the panel-retirement decision was recorded.

## 1. Original ask

> start the next sprint and fold in tbe follow up from previous one with you

## Primary Goal & Guardrails

- **North-Star Goal.** Retire the false-green risk in the repo's own ban checks, and replace the five-agent review panel with one merged reviewer only on evidence that the merge did not cost attention.
- **In-Scope.** A flowed (wrap-aware) absence matcher and the conversion of every ban call site at risk; the merged all-lens reviewer as a registered agent, measured head to head against the existing panel on a real diff; quick's HTML report path contradiction; codewalk's advertised command and the validator pin that enforces the wrong form; a check that keeps skill-name claims honest; the two evals string defects; the `check_no_token` count.
- **Out-of-Scope / Non-Goals.** ~~The doc-link content-verification check (item 4), which needs a new citation convention across the whole repo and is written up for next sprint instead of built.~~ **AMENDED, and the original is kept above rather than deleted.** Q14 (7A) reversed this mid-sprint and the check landed as forms 4 and 5. The bullet stood unamended for the rest of the sprint, so every reviewer that audited scope read a Non-Goal the sprint had already been authorized to break, and the re-run authorization audit filed it as a Critical for exactly that reason. The decision was real; the record of it was missing, which is the defect. No new features in any skill. No change to the phase set, the budgets, or the dispatch contract.
- **Guardrails / Invariants.** No check may be weakened to make a run green. Every new or converted absence check ships a planted control proving it can red. The 500-line file cap holds. `agents/*.md` stay byte-identical to the mirrored region of their canonical twin. No lint suppression. No AI attribution in any commit.
- **Success Signals.** A wrapped plant reds at every converted ban site; the per-lens A/B table exists with real counts from both reviewers on `9d0961e..51ecd00`; all 18 CI commands exit 0; the validator is stable across 30 consecutive runs.

## 2. Clarifying Q&A

### Q1 (proving the merged reviewer)
**Asked:** The merged reviewer replaces a 5-agent panel with 1 agent doing 5 gated passes. An earlier fold in this repo measured 41 findings un-folded against 15 folded. How should we prove the new design before it replaces the panel?
**Answer:** 1A. A/B it on last sprint's real diff.

### Q2 (what happens if it loses)
**Asked:** If the merged reviewer comes in materially below the baseline, what should happen?
**Answer:** 2A. Keep the panel, keep the agent unadopted. The baseline is a hard gate.

### Q3 (rollout)
**Asked:** Should the merged reviewer replace the panel in both modes at once?
**Answer:** 3A. Both modes, as originally decided, assuming it clears the bar.

### Q4 (sprint scope and ordering)
**Asked:** Verification showed the flowed-ban gap is a live false-green risk across ~68 multi-word tokens, the same class as last sprint's SIGPIPE bug. What should this sprint carry?
**Answer:** 4A. Flowed ban first, then merged reviewer, then the small items.

### Q5 (the doc-link content check)
**Asked:** Item 4 needs a new citation convention rather than a code fix. In or out?
**Answer:** 5A. Out of this sprint; write up the design instead.

### Q6 (codewalk's command name)
**Asked:** codewalk advertises `/codewalk` while every sibling uses `/hackify:<name>`, and the validator pins the bare form. Fix it?
**Answer:** 6A. Namespace it to `/hackify:codewalk`, update the pin and the prose sites.

### Q7 (a correction the parent raised, unprompted)
**Asked:** The A/B was specified against the panel's recorded 27 findings. That number was measured before last sprint's three fix rounds landed, and that tree was never committed, so the diff it scored is unrecoverable.
**Answer:** Recorded as an assumption rather than a question: the A/B runs both reviewers head to head on the same current diff `9d0961e..51ecd00`. The historical 27 is a reference point, never the gate. The extra panel run is a real cost and is called out at the gate.

### Q8 (what happens to the merged reviewer, asked after the measurement)

Asked once the A/B was decided, because the cost of registering it only became known during the
work: landing one agent file means eight coordinated edits across five registry files.

**Answer: 1A. Register it, and point quick mode at it.** Full mode keeps its five-agent panel
untouched, since the merged reviewer lost that comparison outright. Quick mode already dispatches
one reviewer carrying every lens, composed on the fly with no gated passes and no per-lens exit
artifacts (`skills/quick/SKILL.md:43`), so the structured prompt replaces an unstructured one
rather than sitting unused.

This also forces a correction. `skills/quick/SKILL.md:119` answers the objection "One reviewer
means fewer lenses" with "No. One reviewer, all lenses. Quick mode drops the review parallelism,
never the coverage." This sprint measured that exact shape: 16 findings against the panel's 29,
and 1 Critical against 4. The claim is wrong as written and has to say what was measured.

### Q9 (how much of what the review found lands in this sprint)

**Answer: 2B. Land everything found.** All of Group C, plus every finding from this round that
survives refutation.

### Q10 (the panel, asked after the A/B lost)

**Asked.** The merged reviewer lost the A/B on every lens, 16 findings against 29 and 1 Critical
against 4, so the sprint's own gate said the panel stays. The user overrode that: replace the panel
entirely, make the merged agent as strong as the panel, and route every mode to it. Two questions
followed, on timing and on what "as strong as" has to mean.

**Answered, 1C.** Swap now, strengthen after. Full mode routes to the merged reviewer as part of
THIS sprint, and the work to make it match the panel is the next sprint. The user was told plainly
that this ships a measured-weaker reviewer everywhere in the meantime and reaffirmed it.

**Answered, 2A.** Before the merged agent is called as strong as the panel it must match or beat
the panel on every lens on `9d0961e..51ecd00`, the diff it lost on, AND on a second diff neither
has seen. One diff alone lets the prompt be tuned to one commit.

**Two consequences the parent settled rather than asked.** First, the five panel agents stay
registered and dispatchable. 2A cannot be proven against an instrument that no longer exists, and
a user who wants the panel on one particular diff needs a way to say so; what changes is that
nothing routes to them automatically. Second, this sprint's own Phase 5 dispatches BOTH the panel
and the merged reviewer over the whole sprint diff. Reviewing the change that weakens review with
the weakened reviewer is the failure mode this sprint spent sixty tasks removing, and running both
also produces the unseen-diff half of the 2A measurement at no extra round.

### Q11 (the fragment manifest, asked when `validate-dod.sh` hit 487 lines)

**Answer: 4A. Move the manifest to its own doc.** The 279 lines of per-check prose move to
`scripts/validate-dod.d/README.md`; the orchestrator keeps a short index. Landed as a SPLIT rather
than a move, because three checks read the manifest in place and moving every row would have
reddened one of them 42 times.

### Q12 (the reviewer agent family, after the merged reviewer took the default seat)

**Answer: 5A. Real rename, both ends pinned by a new check.** `code-reviewer-*` becomes `reviewer-*`
on disk, and check `[89]` guards both ends so neither the old name nor a half-rename can come back.

### Q13 (the five panel agents, asked in the same batch)

**Answer: 6B. Shorten them to match.** Not just the merged one. All five panel agents take the short
`reviewer-<lens>` form.

### Q14 (the anchor checker, and the file it would push over the cap)

**Answer: 7A. Land it, take the split.** THIS IS THE DECISION THAT REVERSES Q5. The doc-link content
check was put out of scope at Q5 and this answer brings it back in, as forms 4 and 5, accepting the
file split that landing it forces.

### Q15 (the contradiction miner, asked in the same batch)

**Answer: 8B. Build the miner now**, not next sprint.

### Q16 (how to close, asked with eleven items still open)

**Answer: 9A. Two more waves, then close.** E62 and E57, then stop and carry the rest.

### Q17 (fix scope for the Phase 5 review round)

**Answer: 10B. Fix all 33 findings the refuter upheld**, wider than the parent's recommendation of
"Criticals plus the cheap text corrections".

### Q18 (the review round's missing authorization axis)

**Answer: 11B. Re-run the authorization audit now**, again wider than the parent's recommendation of
carrying it to the next sprint. It found two Criticals, one of which is this very section's absence.


## 3. Acceptance Criteria

- No ban over wrapped prose can return a false green: every multi-word ban token runs through a flowed matcher, and each converted site reds on a deliberately wrapped plant.
- `[83]`'s local flowed-absence workaround is replaced by the shared helper, with no loss of coverage and the validator still green.
- A merged all-lens reviewer is registered, and its prompt has been run against `9d0961e..51ecd00` alongside the existing panel on the same diff, with a per-lens comparison table recorded in this doc. The A/B ran it as a pasted prompt rather than a dispatched agent type, because Claude Code loads agent types at session start and a newly registered one is not dispatchable until the session restarts. That is a property of the runtime, not a gap in the measurement: the prompt under test was byte-identical either way.
- ~~The merged reviewer replaces the panel in full mode only if its per-lens counts match or beat the panel on that diff.~~ **SUPERSEDED by Q10, and left visible rather than rewritten.** This bullet recorded the rule the sprint set for itself before the measurement ran, and the sprint then followed it: the merged reviewer lost, so it was NOT promoted. The user then read the numbers and overrode the rule directly, retiring the panel as the default route in every mode with the loss on the record and a strengthening bar attached (decision 1C, then 2A). So the criterion was met and then set aside by the person entitled to set it aside. Rewriting it to describe today's routing would hide that a measurement was run, respected, and then overruled on other grounds, which is the one thing this doc exists to preserve. What follows is the original text.

  The merged reviewer replaces the panel in full mode only if its per-lens counts match or beat the panel on that diff. **It did not** (16 findings against 29, 1 Critical against 4), so full mode keeps its five-agent panel. It is adopted in QUICK mode instead, on a separate argument the measurement itself produced: quick already dispatches one reviewer carrying every lens, composed ad hoc with no gated passes and no per-lens exit artifacts, so the structured prompt replaces an unstructured one rather than replacing a panel. The numbers are recorded either way, and `skills/quick/SKILL.md:119` is corrected, because it currently tells users quick "drops the review parallelism, never the coverage" and this sprint measured that claim false.
- Quick's HTML report instruction no longer builds a path from a `<slug>` that quick states it does not have.
- Every `/hackify:<name>` written in prose resolves to a real skill, enforced by a new validator check; codewalk is namespaced and the pin that enforced the bare form is corrected.
- All 18 CI commands exit 0, and `bash scripts/validate-dod.sh` is stable across 30 consecutive runs.

## 4. Approach

Do the correctness work before the improvement, because the flowed-ban gap can hide a real regression today while the merged reviewer is only ever an efficiency win.

Land a shared flowed-absence matcher beside the existing `check_flowed_token_present`, copying its no-pipe construction (that helper already documents why: a pipe into `grep -q` under `pipefail` returns 141, last sprint's bug). Convert the at-risk ban sites to it, then delete `[83]`'s local copy so one matcher serves everything.

Then build the merged reviewer and measure it rather than trusting the design. Both reviewers run on the same committed diff; the per-lens table decides adoption. A loss is a legitimate outcome and stops the rollout.

The small items are independent one-file edits, except codewalk's rename, which touches prose in several places and the pin that currently enforces the wrong form; a new check makes the class stay fixed.

### Repo Brief

- **Stack.** No application code. Markdown doctrine (`skills/`, `agents/`, `rules/`), bash validators (`scripts/validate-dod.sh` + `scripts/validate-dod.d/*.sh`), python test suites (`scripts/test_*.py`). Proved by `ls scripts/ skills/ agents/`.
- **Test command, verbatim.** There is no single one. The bar is **18** `run:` lines in `.github/workflows/ci.yml`, enumerated with `/usr/bin/grep -E '^ +run: (bash|python3) ' .github/workflows/ci.yml`. `scripts/validate-dod.sh` invokes only 5 of them; the other 13 are CI-only. A list shorter than 18 means the regex is wrong.
- **Order matters.** `bash scripts/sync-runtimes.sh` runs before `bash scripts/validate-dod.sh` (`ci.yml:174` then `:177`), because `dist/` goes stale whenever a hook, agent or skill file changes.
- **Lint / typecheck.** None in CI. `shellcheck` is installed locally but is not a CI step; `bash -n` is the syntax check used in practice.
- **Layout.** Validator fragments are numbered and sourced by `scripts/validate-dod.sh`; a fragment nothing sources reds `[0]`, and one missing from that file's header manifest reds `[76f]`. Free slots today: 84 is taken, so the next new fragment goes at an unused number.
- **The one layering rule.** `agents/*.md` are byte-identical mirrors of the fenced region of `skills/hackify/references/parallel-agents/*.md`; everything after `<!-- parent-side: not mirrored -->` is canonical-only. Synced by `python3 scripts/sync_agent_mirrors.py`, checked by `[75h]` and `55-mirror-completeness.sh`.
- **Rules source.** `~/.claude/CLAUDE.md` (user-global). **There is no CLAUDE.md at the repo root**, verified by `ls` and `find`; do not pass one to an agent.
- **Test convention.** Every absence check ships a planted positive control. Canonical example: `scripts/validate-dod.d/83-testing-stage-shape.sh:112-119`.
- **Landmines.** 500 lines per file, check `[80]`; `skills/hackify/references/parallel-agents/phase-3-implementation.md` sits at 499. The shell is zsh: `mapfile` does not exist, unquoted variables do not word-split, the interactive `grep` is a gitignore-honouring shim (use `/usr/bin/grep` or `git grep`), and BSD grep has no `-P`. Markdown is wrapped, so a `grep -F` for a sentence spanning two lines returns 0 on a healthy file. `dist/` is generated and its contents are gitignored via `dist/.gitignore`; never hand-edit it.

## 5. Sprint Backlog

**Group A, the flowed ban (correctness, goes first).**

- [x] T1. Add a flowed absence matcher to `scripts/validate-dod.d/00-helpers.sh`, beside `check_flowed_token_present:358`, using the same no-pipe herestring construction.
- [x] T2. Add the batched counterpart, so a list of tokens over a file set gets one call rather than a loop.
- [x] T3. Re-derive the at-risk ban call sites (investigation named 10, over ~68 multi-word tokens in `P5_BANS` and `RR_BANS` alone) and confirm the list before converting.
- [x] T4. Convert the at-risk sites in `71-release-mechanism-pins.sh`.
- [x] T5. Convert the at-risk sites in `77-reviewer-roster.sh`.
- [x] T6. Convert the at-risk sites in `81-no-claude-attribution.sh` and `82-throughput-and-routing.sh`.
- [x] T7. Retire `[83]`'s local `tss_absent` / `tss_flowed_hit` workaround in favour of the shared helper.
- [x] T8. Planted-control battery: every converted site reds on a deliberately wrapped plant and stays green on the healthy file.
- [x] T9. Update the `scripts/test_ban_tokens.d/` inventory pins for the new helper and the changed call-site counts.

**Group B, the merged all-lens reviewer (measured, not assumed).**

- [x] T10. Author the merged reviewer prompt carrying every lens as gated sequential passes, each with its own exit artifact, at the canonical path under `skills/hackify/references/parallel-agents/`.
- [x] T11. Mirror it into `agents/` and register the type so it is dispatchable.
- [x] T12. Answer the two open design questions the carry-over named: how `{{review_scope}}` slicing works when one agent carries every lens, and what happens to the design lens on a non-UI diff.
- [x] T13. A/B run one: dispatch the existing five-agent panel on `9d0961e..51ecd00`, excluding `docs/work/*`.
- [x] T14. A/B run two: dispatch the merged reviewer on the identical diff.
- [x] T15. Build the per-lens comparison table and rule on adoption against the hard gate.
- [x] T16. If it clears: adopt in `skills/hackify/SKILL.md` and `skills/quick/SKILL.md`, and remove the now-duplicated lens doctrine.

**Group C, the carry-over defects.**

- [x] T17. Fix quick's report-path contradiction at `skills/quick/SKILL.md:106` against its own statement at `:41`.
- [x] T18. Namespace codewalk to `/hackify:codewalk` across the **25 command-form occurrences in 10 files**, re-measured 2026-08-31 with a matcher that excludes path strings (an earlier count of 22 in 8 files missed two files): `skills/codewalk/SKILL.md` (7), `README.md` (5), `skills/hackify/references/finish.md` (4), `skills/codewalk/assets/build-playbook.mjs` (2), `skills/codewalk/assets/playbook.html` (2), `skills/codewalk/references/data-schema.md` (1), `skills/codewalk/references/trace-rubric.md` (1), `skills/hackify/SKILL.md` (1), `skills/hackify/references/phases/phase-6-finish.md` (1), `scripts/validate-dod.d/71-release-mechanism-pins.sh` (1, which is T19). `CHANGELOG.md` is excluded on purpose: it is a historical record and old entries are left alone. Re-measure before you start; the number moves whenever prose is edited.
- [x] T19. Correct the validator pin at `71-release-mechanism-pins.sh:233`, which currently enforces the bare form.
- [x] T20. New check: every `/hackify:<name>` written in prose resolves to a real `skills/*/SKILL.md` name, with a planted control.
- [x] T21. Fix `skills/review-triage/evals/evals.json:35` and `skills/lawkeeper/evals/evals.json:36`, the slash-command form and the subject-verb disagreement.
- [x] T22. Make `check_no_token:135` count occurrences rather than matching lines.
- [x] T23. Close the latent blind spot at `scripts/test_ban_tokens.d/30-inventory-pins.sh:45`, where the call-site count reads `scripts/` only.
- [x] T24. Write the item-4 design into the retrospective: what an anchor-text citation convention would require, and what it would cost to migrate.

### Group D, the review round's survivors (27 upheld of 35; 3 were already fixed by Group A, 5 refuted)

- [x] T25. `[84]` catches one reader spelling of five. Widen it to `| /usr/bin/grep -q`, `| grep -F -q`, `| grep --quiet`, `| grep -m1` and `| head`, fix the green at `:217`/`:302` that claims more than the pattern checks, and either catch a backslash-continued pipeline or narrow the claim at `:64-65`. (F2, F34)
- [x] T26. Convert or annotate the five live short-circuit sites `[84]` cannot see: `75-ship-bar.sh:226`, `56-dist-integrity.sh:112,344,345`, `release.sh:84`. Both `validate-dod.sh:200` and `release.sh:8` set `pipefail`. (F2)
- [x] T27. Fix the `[84]` manifest row at `validate-dod.sh:108`: it says `scripts/` while the check covers `scripts/`, `hooks/` and fenced agent-prompt shell. (F26)
- [x] T28. Close the fail-open at `00-helpers.sh:440` (`check_no_flowed_token`) and `83:83`: a directory passes `[ -r ]`, leaves the flattened text empty and prints a green `0 occurrences`. The presence-side twin at `:367` fails red and is not affected. (F4)
- [x] T29. Hoist the per-token flatten in `check_flowed_token_present` (`00-helpers.sh:367`): 19 full-file flattenings where 3 would do, over ~40KB files. (F5)
- [x] T30. Give the presence side a batched twin so `82:493-495` stops forking one `grep` per token over the same 27KB file, ~25 opens in one fragment. (F6)
- [x] T31. **Critical.** The spec reviewer draws the testing-stage partition over test files ONLY; `contention-dispatch.md:245-246` requires test files AND the production files each wave mutates. Fix `agents/spec-reviewer.md:234-235` and `parallel-agents/phase-2.5-spec-reviewer.md:241-242`, and widen `[83]` to screen that pair, which it does not touch today. (F17)
- [x] T32. Fix the canonical file's own contradiction at `contention-dispatch.md:268-269` ("a per-module partition of the test files"), and the fifth restatement at `implement-and-test.md:158` that `:250` forbids. (F30)
- [x] T33. The budget-consumer screen covers 10 files; its own recipe at `82:91-92` yields 11. Add `work-doc-template.md:137`, which names the budget and is screened by nothing. (F19)
- [x] T34. `TB_EXPECT_CALLS` ships 7; `96-review-scope-sites.sh:83` and `CHANGELOG.md:133` both say six, and `96:82-85` restates the number in the very comment that says not to restate it. (F20)
- [x] T35. Re-resolve the three stale `[82g]` pin anchors: `82:373` cites `:168-172` (the case is at `:216-220`), `82:398` cites `:47` (a blank line; the sentence is at `:59`), `82:440` cites `:34-42` (the section is at `:46-51`). (F22)
- [x] T36. `[82]` ships 33 presence pins with no tamper coverage: deleting `82:81` leaves both suites green, with only the ok-line count moving 1700 to 1699 against a floor of 1350. Plant them. (F23)
- [x] T37. `[92]` calls `WS_SECTIONED_FLOOR` and `WS_HEADING_FLOOR` "the exact count" at `:81,:87` and ships 12 and 100 against a measured 13 and 113; `:56` says "twenty-three tracked work-docs" against 24. (F24)
- [x] T38. `[83]`, `[84]` and `[92]` are named by no suite outside `validate-dod.sh`, so a fragment deleted with its source line and header row goes green. (F29)
- [x] T39. `82:4` says "Six blocks" and `:13` "five of the six"; seven ship. (F31)
- [x] T40. Four wrong numbers and two missing bullets in `CHANGELOG.md`: `:100` "Twenty-three places" against 24, `:104` "seventy runs" against `84:24` and `validate-dod.sh:115` both saying 100, `:131` "91 to 102" against a measured 111, and no bullet for `[83]` or `[92]`. (F10, F11, F12, F13)
- [x] T41. Correct the archived 0.18.0 Sprint Review: "33 files changed plus 5 new, 1521 insertions against 747 deletions" and "Three new validator fragments" against a measured 49 files, 3013 insertions, 772 deletions and four new fragments; and "1698 ok lines" against 1700. Its "187 passes" figure is CORRECT at `51ecd00` and must not be "fixed". (F25)
- [x] T42. Tick the archived 0.18.0 Acceptance Criteria: all 14 bullets read `- [ ]` while frontmatter says `status: done`. Every bullet has covering hunks, and neither `[92]` nor `[98]` reddens on it. (F15)
- [x] T43. Record in the archived 0.18.0 doc that its Sprint Backlog was never extended to cover the Phase 5 fix waves, which is why 20 of 49 files carry no authorizing task, and resolve the goal anchor's Out-of-Scope "the scouts" against the two scout files the diff edits and `[82c]` now pins. (F7, F8)
- [x] T44. The `hooks/` here-string conversion moves screened content (a body up to 65536 bytes, or a whole Bash command) onto disk, because bash 3.2.57 backs `<<<` with a temp file. CWE-377. (F3)
- [x] T45. `84:21-24` asserts run counts nothing in the tree re-establishes, and no repeat-run harness exists in any of CI's 18 commands. (F35)
- [x] T47. Fix `70-invariants-and-new.sh:68`, a live `printf | grep -Eq` inside the validator's own `pipefail` scope, found by the widened `[84]` within minutes of it landing. Not in any review finding; the check found it.
- [x] T48. **The debug fix path has no legal dispatch mode for its first step.** `debug-when-stuck.md:159,168` order a failing regression test written and watched red; `:176` dispatches THE FIX "carrying the root cause and the failing test as its inputs", so the test pre-exists that dispatch, and `:176` itself cites the no-parent-authored-diff law that forbids the parent writing it. `agents/implementer.md:221-222` defines `test-authoring` as a wave dispatched AFTER the round's last implementation wave, for code already on disk, and `:218` says every other mode writes production code only. `implement-and-test.md:114` tries to cover this by saying a compressed flow carries `test-authoring` on its one wave, but that wave still cannot write the fix. Matters more than its severity: quick owns every debug ask outright (`skills/quick/SKILL.md:58`), so this sits on the default route. (F18)
- [x] T49. Widen `[83]` to screen the spec-reviewer pair, the second half of T31. Pin `the production files it would mutate for a watched red` on BOTH `agents/spec-reviewer.md` and `phase-2.5-spec-reviewer.md`, and ban the flattened retired tail `the union of the test files it would write. Under`. Without it T31 silently regresses: that pair is screened by nothing today.
- [x] T50. Retrospective: every implementer dispatched this sprint carried its contract from the INSTALLED plugin at 0.17.2 while editing a 0.18.0 tree. The installed copy still names the retired `test-first` mode that `[82e]` now bans repo-wide (6 occurrences against 0 in the repo). Nothing broke only because the waves read the live files instead of trusting their own prompts. Write the rule that makes that reliable rather than lucky.
- [x] T51. `skills/hackify/references/parallel-agents/phase-3-implementation.md` is now at exactly 500 of 500. Zero headroom, second sprint running into this file's cap. Decide whether it splits, and record the decision.
- [x] T52. `[84]` prescribes two safe forms and says "this file does not add a third". The hooks wave found and shipped a third, `< <(printf '%s\n' "$var")`, which is strictly safer than both: nothing on disk, and the writer is not a pipeline stage so `pipefail` cannot surface its SIGPIPE. `[84]` cannot distinguish it from the here-string it prescribes, so a future reader following `[84]` will convert it back. Document it as the required form for anything screening sensitive content, and add it to `PG_SAFE_TAILS` as a negative control. Today the only guard is one test case in the hooks suite.
- [x] T53. `98-work-doc-ledger-sync.sh:106,115` carries the same "the exact count" wording over `-lt` comparisons (`WL_LEDGER_FLOOR`, `WL_CREATED_FLOOR`), and `:112` states the maintenance convention that just failed in `[92]`: "any wave archiving another ledger-bearing doc must raise this floor". Values are small (2 and 2) so nothing is stale today, but the wording invites the identical misreading. Apply `[92]`'s fix shape.
- [x] T54. `[92]` has no tamper coverage at all. `test_tamper_status_claims.py` tampers `[99]`'s floor and `test_tamper_ledger_sync.py` covers `[98]`; nothing anywhere tampers fragment 92. It shipped last sprint with no tamper row, so the new ceiling has no test proving it stays wired.
- [x] T55. Registration needs a NINTH edit my list missed: `scripts/test_tamper_mirror_tails.py:80-81`, `MIRROR_PAIR_COUNT` 9 to 10 and `MARKED_TEMPLATE_COUNT` 4 to 5. `test_tamper_battery.py:65` imports it and IS a CI command, so CI is red until those two digits move. The registration wave proved the fix by patching in memory (14 ok, 0 fail) rather than reaching outside its allowlist.
- [x] T56. The reviewer roster row in `skills/hackify/references/parallel-agents/README.md` is enforced by NOTHING. The registration wave swapped a live agent type for `UNREGISTERED-ROW`, re-synced, and the validator still reported ALL CHECKS PASSED. That table is the type-to-INPUTS map Phase 5 dispatches off, so a wrong row misroutes a whole panel silently.
- [x] T57. `96-review-scope-sites.sh:97-98` says "the pathspec sits at 50 occurrences over 19 files" while `PLS_XOCCUR_EXPECTED=49` two lines below. Code right, prose stale.
- [x] T58. Four stale `path:line` citations the doc-link wave resolved and could not touch: `00-helpers.sh:337`, `01-presence-matchers.sh:203` and `84-no-pipe-into-grep-q.sh:12` all cite `scripts/validate-dod.sh:221` for the `set -uo pipefail` line, which is at 248 and moves every time a fragment lands; `73-implementer-rename.sh:354` cites `CHANGELOG.md:19` for a `{{assigned_lens}}` retirement that line no longer names. Fix by naming the construct, not by writing a fresh number, which is what `[57]` cannot check.
- [x] T59. `98-work-doc-ledger-sync.sh:23` cites `skills/hackify/SKILL.md:106`, a blank line; the claim is at `:107`. Owned by the running `[98]` wave.
- [x] T60. `scripts/test_tamper_status_claims.py` is 543 LOC against the 500 cap and reds `[80]`. Owned by the running `[98]`/tamper wave.
- [x] T46. Retrospective: the dispatcher built this round's `metrics_table` from the working tree instead of the reviewed commit, and that one error propagated into two further findings. Write the rule that stops it. (F16)

### Group E, retiring the panel as the default route (Q10, decisions 1C and 2A)

- [x] E1. Route full mode's Phase 5 to `hackify:code-reviewer-merged`. Sites: the phase table and the orchestration table in `skills/hackify/SKILL.md`, and the dispatch section of `skills/hackify/references/phases/phase-5-review.md`, whose `:46` still reads "A, B, D and F each run on every non-trivial diff" and whose `:72` says in as many words "Do not wire it into a full-mode round".
- [x] E2. Rewrite the roster in `skills/hackify/references/parallel-agents/README.md`. Row `:27` is labelled QUICK MODE ONLY and carries "Never dispatched in full mode"; rows `:21-25` describe the panel as the full-mode route. The five panel types stay in the table and stay registered, relabelled as the measurement and escalation route rather than deleted.
- [x] E3. Give the user a way to ask for the panel on one diff, and write it into both mode files. Without it, retiring the default route removes the capability rather than demoting it.
- [x] E4. Reconcile `phase-5-aggregation.md` and `phase-5-escalation.md`, which describe merging several reviewer reports. One reviewer produces one report and there is nothing to aggregate, so either they carry the both-reviewers case or they say plainly which round shape they now serve.
- [x] E6. Fix quick's trap row, which tells the user to "promote to full and say so" when they want the panel to read a diff. After E1 that route no longer exists and the sentence sends people nowhere.
- [x] E7. Record the trade in `CHANGELOG.md` in the same plain terms it was decided in: full mode now ships a reviewer measured at 16 findings against the panel's 29, the panel is still there to be asked for, and the strengthening work with its two-diff bar is the next sprint.
- [x] E8. Write the next sprint's carry-over: the 2A bar, the two subject diffs, and what the strengthening work has to attack, which the A/B already named as the merged agent's A pass missing the flowed-ban false green and its F pass missing the testing-stage partition split.

- [x] E9. Rewrite the merged reviewer prompt itself so it reaches panel strength, at `skills/hackify/references/parallel-agents/phase-5-multi-review-merged.md` and its `agents/code-reviewer-merged.md` mirror. The A/B named where it loses: its A pass missed the flowed-ban false green that panel A reproduced from a clean checkout, and its F pass missed the testing-stage partition split that panel F traced across three files. Both are misses of METHOD, not of vocabulary, so the fix is in what each pass is made to DO before it is allowed to report, not in more lens prose.
- [x] E10. Tune every other agent prompt for speed: `implementer`, `spec-reviewer`, `finding-refuter`, `codebase-investigator`, each with its canonical template and its mirror. Speed here means fewer wasted tool calls and less re-reading, never less proof. `phase-3-implementation.md` is at exactly 500 of 500 and has no headroom.

- [x] E11. Stale-content sweep, run AFTER waves E-a, E-b, E-e and E-f land, never beside them. Those four are rewriting the doctrine that half the tree describes, so any sweep run now would miss the batch they create and would fight them for the same files. Targets: every sentence that still says the panel is the automatic route, every count that moved, every retired mechanism still described as live, and every `path:line` citation pointing at content that has moved. The class is proven live: today's waves found four stale citations, six wrong numbers in one fragment, a header saying FOUR PINS over five, and prose claiming a checker verified line numbers it never verified.
- [x] E12. Orphaned-file check, closed with a measurement rather than a sweep. All 307 tracked non-dist files were resolved and NONE is unreferenced. The 44 the basename scan flagged are all loaded by glob or import: the archived work-docs under `docs/work/done/` are historical records nothing is meant to cite, the `sync-runtimes.d/` fragments are sourced from the directory, the lawkeeper eval corpus is fixture data, and the two scripts that looked orphaned are both imported by name. `docs/work/reports/` is quick mode's report home per `html-report.md`, not a leftover. Nothing to delete.

- [x] E5. Re-point the validators that pin the panel as full mode's route. **Closed with a measurement, no work needed.** Waves E-a and E-b conditioned every pinned literal in place rather than replacing it, so `A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one` still exists as a substring in all three files that carry it, and `[71]`, `[76g]`, `[76h]`, `[77]` and `[79]` all stayed green. Verified independently at the parent: the bar reports 1808 ok and exactly one FAIL, the known `dist/` staleness.
- [x] E13. Bound the merged reviewer's new reproduce obligation to the project's OWN check surface, per the user's answer 3A. Pass 1 now has to execute the gates the diff touches, which means running code from the change under review. Scope it to the suites, validators, linters and guards the project already runs in CI, and say plainly that it does not run new executables the diff introduces outside that set. `agents/code-reviewer-merged.md` mirrors the canonical file byte for byte, so both move together.
- [x] E14. Three stale sites the README wave found and could not reach: `README.md:87` lists what `agents/` holds and never names `code-reviewer-merged.md`, which is now the default reviewer; `skills/review-triage/SKILL.md` still calls its input "multi-reviewer findings" in two places, which is what makes `README.md:152,166` say it too; and quick's flow still labels its review step "Phase 5-lite (one reviewer, every lens)" when both modes now run the same reviewer, so "lite" describes the phases around it and not the review.

- [x] E15. Both work-doc cadence rules already exist and neither is enforced, so both decay in a long session. `phases/phase-3-implement.md` states wave-end persistence with its unit as ONE RETURNING AGENT, and `finish.md`, `phase-6-finish.md` and `phase-ledger.md` all state that the closing edit is followed immediately by the `git mv`. The parent broke the first one in this very sprint: it ticked checkboxes per returning agent but batched the Daily Updates entries, which is the half carrying the reasoning nothing else records. Carry both laws into `rules/phase-discipline.md`, the always-on file the `UserPromptSubmit` hook injects into EVERY prompt, because that is the one surface built for laws that fade as a session grows. Its own prose says exactly that: the phase-discipline rules used to live only in files that load once and then fade, so nothing still said to keep the ledger by the time a run reached its longest phase.

- [x] E16. Ship a SessionStart orientation map. Hackify has NO SessionStart hook today: `hooks/hooks.json` wires five `UserPromptSubmit` rule injections and two `PreToolUse` blockers and nothing else, so a session learns the plugin exists only when a skill is already being invoked. Seven skills and two commands go unadvertised. The map answers "what is here and what do the words mean", once, at the top of a session. **It POINTS at the five always-on rule files and never restates them**: a session-start document fades as the conversation grows, which is the exact decay E15 exists to fix, so a fading second copy of a law would eventually contradict the non-fading one and look authoritative while doing it. It is paid on every session including ones that never touch hackify, so length is the binding constraint.

- [x] E17. **The law E15 just added is pinned by nothing.** `[76e]` pins laws 2, 3 and 4 in exact bullet form precisely so they cannot be de-bolded out of the injected digest, and `[38]` pins law 1's carve-out. Law 5 was pinned by nothing before this sprint and it is now the bullet carrying BOTH work-doc persistence rules, so a future reword silently deletes them from every prompt after the first and no check moves. Add the presence pin to `scripts/validate-dod.d/76-phase-ledger-substrate.sh` and prove it reds on a reword. Found by the wave that wrote the law, in its own work, and it could not fix it from inside its allowlist.

- [x] E18. **Blocking, caused by E16.** `rules/plugin-map.md` is a new canonical file in `rules/` that `MIRROR_SOURCES` in `scripts/sync-runtimes.d/00-helpers.sh` does not name, so `[55]` reds and, worse, a `--dry-run` proves the consequence is real rather than cosmetic: the sync plans to write the hook wiring into `dist/claude-code` and plans NO write for the map, so the shipped hook would point at a file that is not there. One line. The wave that created the file could not reach that shared surface.
- [x] E19. The other six runtime trees get no map. `hooks/` ships only to `dist/claude-code`, so codex-cli, codex-app, gemini-cli, opencode, cursor and copilot-cli receive no SessionStart hook. That matches how the five always-on rules already work there, they are taken from prose instead, except the map has no prose equivalent in `references/runtime-adapters.md`. Give it one, or record in that file that the map is claude-code only and why.
- [x] E20. **Decided 4A, move the manifest out.** `scripts/validate-dod.sh` is 460 of 500 and its header manifest grows by about 20 lines per new fragment, so two more fragments breach the cap. The manifest is the natural split seam. Decide and record it before the next fragment lands, not after.

- [x] E21. The `Single-lens` rename, three sites no single allowlist could hold: quick's step heading, quick's frontmatter clause, and quick's ledger row in `phase-ledger.md`. The sweep moved the three places it was a descriptive gloss and left the three where it is the phase's NAME, because renaming a name in one file strands every other site pointing at it.
- [x] E22. **The round-cap sentence still says panel, at four pinned sites.** `Phase 5 dispatches exactly ONE reviewer panel and ONE refuter, and the phase ends when the surviving findings are fixed` lives in `skills/hackify/SKILL.md`, `phases/phase-5-review.md`, `review-and-verify.md` and `review-scope.md`, pinned at exactly 4 files by `PLS_CAP` in `96-review-scope-sites.sh` and used as `RSE_CONTROL` in `72-diff-slicing-pins.sh`. A round dispatches the merged reviewer now. Six files move together or none do.
- [x] E23. **A stale citation baked into a check AND its test, so nothing can catch it.** `98-work-doc-ledger-sync.sh` sets `LEDGER_LAW` to `phase-ledger.md:110` under a comment saying it enforces the No-silent-skip bullet. That bullet is at `:98`; `:110` is a Phase 3 exit-artifact row. The wrong number is asserted verbatim in `test_tamper_ledger_sync.py`, so the test pins the error in place. The sweep kept every `phase-ledger.md` edit line-count neutral on purpose so it neither fixed nor worsened it.

- [x] E24. **Nothing tamper-tests fragment 76.** `scripts/test_tamper_battery.py` drives 81, 91, 93-95 and 97-99 and never 76, so the fragment that now protects all five injected laws has no test proving its own detection stays wired. E17's three manufactured reds hold in one wave transcript and nothing re-proves them on a CI run. Staged by the wave that closed the pins, and it is the same shape as the `[92]` gap this sprint already fixed: a new guard shipped with no tamper row.

- [x] E25. Nothing pins quick's review-phase name at any of its three sites. The rename to `All-lens` is coherent today and a reword in one file would strand the other two with no check moving, which is the same defect E21 just repaired. Nothing in `scripts/` or `hooks/` pins `single-lens`, `All-lens` or `5-lite`, measured by the wave. **Hold this until E-q lands:** that wave is building tamper coverage for `76-phase-ledger-substrate.sh`, and adding a pin to the fragment it is planting against would collide with its plants.

- [x] E26. The session-start map has no `README.md` entry and no `CHANGELOG.md` bullet. Folds into E7's changelog work; the README line needs its own hunk and README is bounded at 250..450 by `[7]`.

- [x] E27. Another instance of the same class, found while fixing the first: `scripts/validate-dod.d/92-work-doc-structure.sh` cites `98-work-doc-ledger-sync.sh:81` for a quoted phrase that actually begins on line 80. `[57]` cannot see it because line 81 exists. The E23 wave kept its own compression below that line so it would not make the drift worse.

- [x] E28. Four restatements of the round cap still say panel, and one of them is PINNED. `[75f]` in `75-ship-bar.sh` holds the literal `no second panel, no second refuter and no re-scan` in `review-and-verify.md`, so rewording the three unpinned siblings and leaving the pinned one would be worse than leaving all four. Needs `75-ship-bar.sh` and the four docs in ONE allowlist.
- [x] E29. `review-scope.md` carries a `## One panel, one refuter` heading and `phase-5-refute.md` calls it "the one-panel-one-refuter cap". Renaming either alone orphans the other term. Needs both files, and `phase-5-refute.md` is mirrored into `agents/finding-refuter.md`.
- [x] E30. `92-work-doc-structure.sh` cites `57-doc-links.sh:20-26`, a pre-existing `path:line` of exactly the class this sprint has now repaired six times. Named by the wave that fixed the previous one.

- [x] E31. **Blocking, CI is red.** `SUBSTRATE_FILES` in `scripts/tamper_harness.py` does not carry `skills/quick/SKILL.md`, and `[76j]` reads two of its three sites from that file, so the tamper corpus reds on a pristine tree and the battery went 190 to 188 passed / 2 failed. One line. Proven sufficient in memory by the wave that found it, which could not write the file.
- [x] E32. `[76j]` has six manufactured reds proven by hand and no row in the battery. Natural rows: a partial reword at each of the three sites (delta 1 each), the anchor break (delta 2), and a coherent rename at all three (delta 0). Needs E31 landed first, because every row measures a difference over `substrate_tree()`.
- [x] E33. **`[75f]` cannot see the softening it claims to catch.** Measured, not argued: it is a `grep -qF` substring test, so wrapping the pinned clause in "There is normally ... unless the fixes changed enough to warrant one" leaves it green. Its own red message says it catches softening. The weakness is pre-existing and the old panel-worded literal had it identically.
- [x] E34. `[38h]`'s positive control prints a count it never checks. Under a single-site break it printed "the scan reaches 3 file(s)" over a tree that should carry 4, and passed, because it is a non-emptiness test. `[76h]` carries the real count so no coverage is lost, but the line reads as evidence and is not one.
- [x] E35. Two more stale `path:line` citations, same class, both already drifted. `55-mirror-completeness.sh:65` and `20-templates.sh:384` cite `93-token-declarations.sh:105-108` for a convention that now lives near line 114; lines 105-108 are unrelated pathspec prose. `55-mirror-completeness.sh:49,83` cite `91-claim-resolvers.sh:84-88` and `:98-104`, not checked for drift. `[57]` is green over all of them.
- [x] E36. The work-doc's own `92-work-doc-structure.sh:81,87` citation is stale and was stale before this sprint touched the file. The bounds block was rewritten earlier today, `WS_SECTIONED_FLOOR` became `WS_UNSECTIONED_MAX`, and the values are now 12 / 11 / 113. Parent-owned, under `docs/`.
- [x] E37. The perf-scout has no shell patterns and its `loop_window` helper uses a 6-line window calibrated for JS. A shell loop body runs 35 lines, so the shipped helper silently missed two of three candidates in a bash file until a wave widened the window by hand. A scout that scans and finds nothing reports the same zero either way.

### 2026-08-31, the citation that had not drifted, and the two beside it that had (E30)

Worth recording because the answer was no. The cited range was byte-identical to the day it was
written, checked twice, once against the current file and once against the commit that wrote the
citing text. So the class is real but this instance was healthy, and the honest note the wave added
is that the range was three lines wider than the sentence it meant. Accurate but imprecise, which is
the state a line citation sits in right up to the moment it silently is not.

It replaced the number with a quoted phrase, and picked the phrase on a measurement rather than on
taste: the short form appears twice in the tree, once in the cited file and once in a sibling
fragment saying nearly the same thing in different words, so a short quote would have resolved to
two hits and been a worse anchor than the line number. The longer quote is unique.

**Two more instances turned up while it was looking for house style, and both HAVE drifted.** Two
fragments cite a convention that has since moved about nine lines, and their citations now land on
unrelated prose about pathspecs. `[57]` is green over both, because both lines exist. That is the
hole this sprint keeps re-proving from a new direction: the link check asks whether a line is there,
never whether it still says the thing being cited. Filed as E35.

And the wave found that the work-doc's own citation into the file it was editing is stale, and was
stale before it arrived, because the bounds block was rewritten earlier today under different
variable names. That one is mine, filed as E36.

### 2026-08-31, the round cap stopped naming a route, and a pin turned out to be softer than its own error message (E28)

The four restatements were not parallel, which the brief got wrong. Two carry the full three-clause
form, one drops the refuter clause and one has no re-scan clause at all and says "nothing to carry
over" instead, because it is making a different argument about why the ledger has three columns. The
wave swapped the noun at all four and deliberately did not widen the two short ones, on the grounds
that neither asymmetry is a defect and the full sentence sits directly above each of them.

The word it landed is `no second review`, and the reasoning is the same reasoning the earlier wave
used, carried one step further. `reviewer` would have been wrong on our own logic: five panel lenses
are one review but five reviewers, so a cap worded "no second reviewer" reads as already violated by
the route it is supposed to permit.

**The finding is that the pin does not do what it says.** `[75f]` is a fixed-string substring test.
The wave's first manufactured break wrapped the clause in "There is normally ... unless the fixes
changed enough to warrant one" and the check stayed green, while its own red message claims it
catches "softening it". So the exact evasion it names is the one it cannot see. This is pre-existing
and the old panel-worded literal had it identically, so nothing regressed today, but a check whose
error message describes a capability it lacks is worse than one that stays quiet. Filed as E33.

**And the two-occurrence trap showed up again, in a third costume.** Under a single-site break
another fragment's control stayed green and printed "the scan reaches 3 file(s)" over a tree that
should carry 4. It is a non-emptiness test, so no single-site break can red it, and the number it
prints is decoration. The count is genuinely covered elsewhere, so this costs nothing today. It is
still a line that reads as evidence and is not one. Filed as E34.

### 2026-08-31, the phase name got a pin that a presence check could not have given it (E25)

The three sites can never agree byte for byte, because one says the name mid-sentence in lower case
and two open a heading with it. So the check does not write the name down at all. Each site is
anchored by the fixed frame around it, the name is lifted out as the frame's only variable run, and
the three are compared case-folded. What is guarded is DISAGREEMENT between the sites, not the
vocabulary they happen to agree on, which is why a coherent rename at all three passes with no edit
here. That is correct: a pin that breaks when the thing it protects is renamed properly is a tax on
doing the right thing.

**The wave proved the naive alternative fails rather than asserting it.** A presence pin on the name
would miss a partial reword outright, because the name occurs twice in one of the files, so breaking
one of the two leaves the file still containing the string. It ran that as a control and the naive
pin passed over a tree with a stranded site. The second failure is subtler and is the one that
matters: the obvious repair for a presence pin's red is to update the pin's literal, so a wave
renaming both clauses in one file sees two reds naming that file, fixes the two literals, and leaves
the third site stranded with the whole gate green. The pin becomes a fourth site that has to agree.

Six manufactured reds, three of them the exact partial states the task was written to catch, plus an
anchor break to prove the hand-written count of three is not decorative, plus the coherent rename
that must stay green.

**It also went red on CI and stopped rather than reaching outside its allowlist.** The tamper
corpus does not copy the file two of the three sites live in, so the new check reds on a pristine
corpus and the battery went from 190 passed to 188 passed and 2 failed. Both failures are that one
cause. The wave proved the one-line fix sufficient by widening the tuple in memory and re-running the
two rows, then wrote nothing and handed it over. Filed as E31, and the tamper rows for the new check
as E32.

### 2026-08-31, the E29 allowlist was wrong, and the wave stopped instead of guessing (E29 open)

The file lives under `parallel-agents/`, not `phases/`. The brief was written by analogy with the
line above it and picked up the wrong directory. The wave did not go looking for a near-match and
edit it, and it did not rename the half it could reach, because half a rename is the exact failure
E28 exists to prevent and it said so.

It did all the reconnaissance instead, so the re-dispatch is mechanical: no anchors point at the
heading anywhere in the tree, no validator pins either string, and the edit is not in a mirrored
region. That last one it established with the sync tool rather than by eye, and the answer is that
the pair's mirrored tail region is empty, so the sync script does not need to run.

- [x] E38. **Anchor rot is invisible to CI.** `check_doc_links.py` discards the `#fragment` before resolving a path, and its own docstring lists anchor fragments under "out of scope, deliberately". Proven, not read: a wave planted two dead anchors, including the exact one this sprint's rename would have broken, and the check reported green; changing one to a dead FILE reddened it immediately from the same line. So every cross-reference anchor in the plugin's own doctrine can rot with the gate green. `references/finish.md` frames anchor checking as Phase 6 work on the USER's repo, which is what left our own tree unguarded.

### 2026-09-01, the rename that was safe, and the check that proves nothing about anchors (E29)

The brief's headline was wrong and the wave said so first. I offered it "if nothing pins these two
files, say so as your finding". Nine validator fragments read them. The previous wave had grepped for
the heading text and the term, never for what reads the files, so its silence was a silence about the
wrong question. The narrow claim did survive: nothing pins the heading and nothing pins the term.

**What makes that claim worth anything is how it was proved.** The wave ran positive controls first,
breaking a pinned sentence in each file and watching a named check go red, so it knew the checks
reach these files at all. Then it broke the heading and the term themselves, ran eleven checks over
each, and watched every one stay green. A clean result is only worth what the method could have
returned dirty, and this method demonstrably could.

**It made one edit I did not ask for, and it is the reason the task existed.** The paragraph under
the heading said "the panel this section is named for", which the rename turns into a lie. So the
fix for an orphaned term would itself have orphaned a phrase inside the very file it was fixing. It
cut four words and left the antecedent eleven lines up.

**The finding underneath is bigger than the rename.** The doc-link check discards everything after
the `#` before it resolves a path, and says so in its own docstring. The wave planted two dead
anchors, one of them the exact anchor this rename would have broken, and the check reported green;
switching one to a dead FILE reddened it at once from the same line. So anchor rot in our own doctrine
is invisible to CI, and the reason is visible in the doctrine: `finish.md` frames anchor checking as
Phase 6 work on the USER's repo. We wrote the rule for other people's trees and never turned it on
our own. Filed as E38.

**One housekeeping note it raised that I should not lose.** It found uncommitted edits already sitting
in one of its files, captured them in its backup, and preserved them byte-for-byte across two restore
cycles. Flagged so nobody reads them as its work when the round's diff is reviewed.

- [x] E39. **The default reviewer's own file still says do not make it the default, and it is the line a dispatcher reads.** `agents/code-reviewer-merged.md`'s frontmatter description says "for QUICK mode's single-reviewer round and for that round alone" and "DO NOT wire this agent into the full-mode panel: full mode keeps its five-agent panel, and this shape was measured against that panel on a real diff and lost". Its first body line repeats it. The canonical file says "It is an ALTERNATIVE to the five-agent panel ... It is not a replacement for the panel and does not retire it." Every one of those is now false, and the frontmatter description is the text a model reads when it picks an agent, so this is not cosmetic staleness: it is an instruction to refuse the dispatch this sprint made the default. E1 changed the ROUTING and E9 changed the PASSES, and neither touched the framing at the top of the file. Mirror pair, both halves move together.
- [x] E40. `rules/plugin-map.md` says `/hackify:hackify` fires "On request, or when quick's own size test escalates." Quick has no escalation list any more. The map contradicts the release that shipped it, and `[88]` cannot see it, because that check proves an entry RESOLVES and never that its description is true. Same shape as `[57]` proving a cited line exists and never that it says what cites it.

### 2026-09-01, the release notes went in, and the reviewer's own file still says not to use it (E7, E26)

The note says the uncomfortable thing in the first sentence, which is what it was for: Phase 5 sends
one reviewer instead of five, and it measured weaker than the five. It also had to reword the
existing tradeoff paragraph, because that paragraph told readers the road to the panel was promoting
to full mode, and this sprint made that false in both directions. Promoting buys nothing now, and
the road to the panel is asking for the panel.

**My README premise was wrong and the wave measured it instead of obeying it.** I told it the file
sits near the top of its bound and to pay for the new entry by compressing older blurbs. It sits 68
lines under the ceiling and the entry cost 9, so it cut nothing and said so. Deleting real content to
buy space that already existed would have been pure loss. That is the right response to a brief whose
premise is a number: check the number.

It also found the README's agent count saying 9 in one place and ten in another over a directory
holding 10, drifting silently because nothing pins it.

**The finding that outranks both tasks: `agents/code-reviewer-merged.md` still tells a dispatcher not
to use this agent in full mode.** Its frontmatter says the agent is for quick's round "and for that
round alone", and then, in capitals, DO NOT wire this agent into the full-mode panel, citing the
measurement it lost. The canonical file calls itself an alternative that "is not a replacement for the
panel and does not retire it".

That is the worst kind of stale line in this tree, because a frontmatter description is not
documentation. It is the text a model reads when it decides which agent to dispatch. So the file
this sprint made the default reviewer carries a standing instruction to refuse being the default,
and the release note I just approved describes behaviour the agent's own header contradicts.

**How it survived is the lesson.** E1 changed the ROUTING, the tables and the phase docs that name
which agent a round dispatches. E9 rewrote the PASSES, the method each lens follows. Neither owned
the framing paragraph at the top of the file, and I ticked both as landed. Two waves can cover a file
between them and still leave the sentence that introduces it untouched, and no check reads a
frontmatter description for truth. Filed as E39.

Alongside it, the session-start map claims quick escalates to full on a size test, which was removed
in the release the map shipped in. `[88]` cannot catch that: it proves every entry the map names
RESOLVES, never that what the map says about it is true. Exactly the shape of `[57]` proving a cited
line exists and never that it still says what cites it. Filed as E40.

### Group F, the reviewer family rename (user instruction, decisions 5A and 6B)

- [x] E41. **Rename all six reviewer agents into one family, and pin it from both ends.** `code-reviewer-merged` becomes `reviewer`, and the five lens agents shorten to match: `reviewer-security`, `reviewer-quality-plan`, `reviewer-performance`, `reviewer-coherence`, and `design-conformance-reviewer` becomes `reviewer-design`. The `agents/*.md` filenames move with the types. Measured blast radius: **28 live files**, excluding `dist/` and the archived work-docs. Five validator fragments pin one or more of the names (`60-primitives.sh`, `70-invariants-and-new.sh`, `71-release-mechanism-pins.sh`, `72-diff-slicing-pins.sh`, `96-review-scope-sites.sh`), plus `sync_agent_mirrors.py`, `sync-runtimes.d/00-helpers.sh` and `test_tamper_mirror_tails.py`. **This cannot be partitioned.** Every subset of those 28 files shares the name being renamed, so any split leaves a tree where half the dispatch sites name an agent that no longer exists. One wave, one allowlist, or none.
- [x] E42. The both-ends check for E41, modelled on `73-implementer-rename.sh`, which did exactly this for the implementer and is the reason that rename stayed clean: the live name present at every dispatch site, AND the dead name absent from the entire tracked tree. The second half is the one that matters here, because a rename across 28 files is precisely where one quiet survivor hides.
- [x] E43. Decide the canonical filenames. `agents/reviewer.md` is unambiguous, but the canonical side is `references/parallel-agents/phase-5-multi-review-merged.md`, and the obvious short name collides with `references/phases/phase-5-review.md`. Also worth noting: `phase-5-multi-review-f-coherence.md` is the one lens file that does NOT name its own agent type, so it did not appear in the blast-radius scan and would be silently skipped by a name-driven sweep.

- [x] E44. `scripts/test_tamper_battery.py`'s docstring says `[76]`'s corpus "is a copy of the seven paths that fragment reads". It was wrong before this sprint (six files plus two directories is eight) and E31 made it nine. Folded into the split wave, which now holds that file.
- [x] E45. The corpus-completeness check, staged with its argument rather than built: run `[76]` over the corpus and over the real repository and demand byte-identical output. A complete corpus makes the fragment say the same thing over both trees; an omitted path changes what it says over one. Measured both ways before it was staged. Two stated limits: it cannot see a branch that greens identically whether a file is present or not, and it covers `[76]`'s corpus alone, because the other three builders plant synthetic trees and would each need a pristine-green baseline row instead.

### 2026-09-01, the corpus that could not notice what it was missing (E31, E32 part)

The one-line fix landed and the battery went 188 passed with 2 failed, back to 190 with none. The
wave proved it the way the sprint has been demanding: it took the line out again, watched exactly the
same two rows fail and nothing else, and restored from a byte copy rather than from git.

**The interesting half is the class question, and the answer is a good one.** The tamper corpus is a
hand-written tuple, and nothing made it answerable to what the fragment actually opens, so a check
reading a fourth path would have failed for a reason that looks like a defect in the tree. The
proposal: run the fragment over the corpus AND over the real repository and require byte-identical
output. A complete corpus makes the fragment say the same thing over both; an omitted path changes
what it says over one. It borrows the delta rows' own trick, so a genuinely broken repo file reds in
both runs and cancels rather than blaming the corpus.

It measured that both ways and then did not build it, because the file had no room. Staged with the
argument written down so the next author finds the reasoning rather than reinventing it. It also
checked the other four battery-driven fragments for the same gap and found none, which is the part
that makes the zero worth anything.

**My delta table was wrong and the correction is a better description of the check than mine was.**
I said a partial reword at each of the three sites gives one red each. It is 2, 1, 1. The check takes
the FIRST site that resolves as its reference and deliberately refuses to adjudicate which site is
stale, so renaming the reference strands both survivors and reds twice. A row asserting one red
everywhere would have been pinning a behaviour the check does not have. My total of six was right and
my distribution was not, which is the more dangerous way to be right.

**The row that earns the suite is the green one.** The wave weakened the check three ways and re-ran
all six rows against each weakening. Hardcoding the name instead of deriving it, which is exactly the
repair a careless wave reaches for, is caught by ONE row: the coherent-rename row that must stay
green. Nothing else in the suite can tell a working check from one that reds on everything.

**And it stopped at the cap instead of shrinking the tests.** The file went to 540 against a 500 cap,
entirely from this wave's own work, measured against a byte copy rather than guessed. It tried
tightening prose twice, found it does not converge, and refused the one thing that would have worked:
amputating the existing argument in the module docstring. Both file headers already rule that out in
writing, one saying compacting unrelated blocks trades a real invariant for a cosmetic one, the other
saying splitting was the instruction rather than trimming coverage to fit. So it handed back a seam
and the two paths it needed. Allowlist widened, same agent resumed.

- [x] E46. **Closed as recorded, no edit.** Re-measured at the parent: 485 of 500. `references/parallel-agents/phase-5-multi-review-merged.md` is at 485 of the 500 cap. Under cap, so not a defect, but the next wave that edits the reviewer prompt has fifteen lines and needs to know before it starts rather than after.
- [x] E47. Write into `[88]`'s own header that it is an EXISTENCE check and that a false description passes it green. Cheap, and it stops the next reader mistaking green for true. Independent of whether the miner in E48 ever gets built.
- [x] E48. The contradiction miner, if approved. Not "is this description true", which needs a reader, but "does this file assert X where a named authority asserts not-X", over a small hand-written table of routing predicates (auto-fires / never, escalates / never, default / on-request, one-mode / every-mode). It must print the predicates it covered AND the entries it had no predicate for, so the gap is stated rather than hidden. That printed gap is the whole difference between this and the checks this sprint has spent the day finding.

### 2026-09-01, the agent stopped refusing its own job, and we measured exactly how blind the tree is to a lie (E39, E40)

The description now turns the measurement from a prohibition into a calibration. It used to say, in
capitals, do not wire this agent into full mode because it lost 16 to 29. It now says a clean pass
here is weaker evidence than a clean panel pass, and names the panel as still reachable. Same number,
opposite instruction, and the honest version is the more useful one: a dispatcher needs to know what
a green review is worth, not to be told to refuse.

**The structural finding is why nothing caught it.** The mirror machinery cuts on the fenced block, so
only the block is compared byte for byte. All three stale passages lived in a HEAD, the frontmatter
description and the line under it on one side, the opening paragraph on the other. Heads are copied by
nothing and compared by nothing. The most consequential text in the file, the description a model
reads when it picks an agent, sits in the one region the mirror contract does not cover, and the sync
tool's own docstring says it declines to check that field.

**Then it ran the experiment rather than reasoning about it.** It falsified both descriptions without
touching a single token, reversing the agent's frontmatter to claim it is for the full-mode panel and
never for quick, and swapping one map cell for another skill's. Then it ran all 35 validator fragments
plus the mirror check. **Nothing moved. The verdict vector was byte-identical and sync exited 0.** For
contrast it broke one TOKEN in the same map cell and got five reds, and one byte inside the mirrored
block and got three plus a red sync.

So the exposure is measured now, not argued: this tree detects a renamed thing and is completely blind
to a lying thing. Every check in play is a resolution check. It asks whether a name points at
something real, and a description is not a name, it is a claim about behaviour living in another
file's prose with no second copy to hold it against.

**On E40 I was right and the reason is better than I knew.** Quick has no escalation of any kind, and
says so three separate times, including "No diff-size, file-count, attempt-counter, or path-pattern
check ever auto-promotes." So the map described a mechanism that had been explicitly and repeatedly
denied in the file it describes. The wave then read every other row of the map against the tree and
found no further drift, which is worth as much as the fix.

**Its recommendation, and it declined to hedge.** Build a contradiction miner over a small explicit
predicate table: not "is this true", which needs a reader, but "does this file assert X where a named
authority asserts not-X". It would have caught both of today's findings outright, because in each case
the negation was already written down somewhere the check could read. And it named the version it
would refuse to build: anything scoring similarity between a description and its target, which is a
check that cannot fail wearing this sprint's favourite disguise.

- [x] E49. **`check_doc_links.py` crashes instead of reporting on a non-UTF-8 markdown file.** `scan_file` does a bare `read_text()` inside the form 1 and 2 loop, so a `.md` file that is not valid UTF-8 anywhere under the scan roots kills the checker with an unhandled traceback rather than a `FAIL` line. `scan_citations` already guards exactly this and turns it into an "unreadable source" finding; `scan_file` never got the same treatment. The existing row that should have caught it uses a `.sh` fixture, which only the citation scan opens. Real, independent of E38, worth fixing whatever is decided about anchors.
- [x] E50. Performance, staged not fixed: the anchor resolver re-reads and re-parses the target file for every anchor, so a 30-entry table of contents parses one file 30 times. Costs nothing at zero anchors. It is a query-in-loop shape and wants a dict on the resolver keyed by path before it ever sees real use.

### 2026-09-01, a guard built, verified, and not landed, because the field it fences is empty (E38)

**The census is the whole story: this repo contains zero live anchor links.** Not few, zero. 362
markdown links across the 121-file scan surface and not one carries a fragment of any spelling. The
only two anchor-shaped strings in the tree are backticked syntax examples inside the sentence that
describes the anchor rule, which the checker blanks anyway.

So my framing was wrong in a way worth recording. I briefed this as "make anchor rot visible" and
warned the wave the check might redden the tree the moment it turned on. It cannot. There is nothing
for it to see. The class is real and our own doctrine already names it for the user's repo, but here
it is insurance rather than a repair, and that changes what the split work is worth.

**It did not land because both files are already at the cap.** The checker goes 491 to 516 and its
suite 452 to 555, against a hard 500. The wave wrote the integration as lean as it goes, riding the
existing match rather than adding a scan loop and putting all the prose in the new module, and it
still does not fit. So it stopped, wrote nothing, and proved the tree untouched with md5s and a clean
`git status` rather than asserting it.

**The verification is the part worth keeping regardless of what we decide.** Eleven mutations of the
slug algorithm, each killed by a named row. Twelve test rows, each watched failing before the code
existed, then each deliberately weakened and watched stop detecting. And one measurement that
justifies a rule I would have called paranoid: the tree carries 1254 real heading slugs and **238
heading-shaped lines sitting inside fenced code blocks**. Every one of those is a phantom anchor a
naive slugger would accept. It proved that concretely: it planted an anchor that its own grep said
should resolve, and the check reddened it correctly, because the heading grep had found was inside a
pull-request template in a fenced block.

It also named the two heading spellings it does NOT read, setext and explicit HTML anchors, checked
that this tree has zero of each, and said so rather than leaving the gap silent.

**Two real defects found on the way, and one of them is independent of anchors entirely.** The
checker crashes with an unhandled traceback on a non-UTF-8 markdown file where the citation half of
the same file already turns that into a proper finding, and the row that should have caught it uses
a fixture the scan never opens. Filed as E49.

- [x] E51. **15 real perf candidates now visible in this repo's own validator scripts**, including `80-file-size-caps.sh:103`, which forks twice per tracked file inside a `find`-driven loop and is the catalog's own worked example for spawn-per-item, sitting in the plugin's pre-commit gate. Findings against the tree, not against E37, and none of those files was in that wave's allowlist.
- [x] E52. `perf.process` has exactly one catalog ID, so every shell row folds into `spawn-per-item`. Honest but coarse: the builtin-replaceable case (a fork that a parameter expansion replaces) and the batchable case (n forks that become one) have different fixes and arguably different severities. `rules/performance.md` needs the split.

### 2026-09-01, the scout was not mis-tuned, it was blind, and the difference is the whole finding (E37)

Three corrections, and the third rewrites what the task was.

I said the scout had no shell patterns. It had two, added by an earlier round. They were unreachable,
which is a different defect from absent and has a different fix. I said a shell loop body here runs
about 35 lines. That is the maximum. The wave counted every loop body in the tree with a depth parser
for shell and Python's own parser for Python: 191 shell bodies, median 5, p95 18, max 38. The 6-line
window already covered 72% of them.

**And the window was never the reason the scan came back empty.** The retired helper matched
`while (`, the C-style form. Shell writes `while IFS= read -r f; do`, with no parenthesis, so every
`while` loop in every shell file in this repo was invisible at ANY window size. In this tree the
data-driven loops are almost all `while read` fed by `find` or `git ls-files`, which is to say the
header gap lined up precisely with the loops worth finding. `for` loops did match, which is why the
earlier wave got three hits when it widened the window by hand, and why all three were `for` loops
over fixed tables. Widening to 40 could never have reached the real candidates. I diagnosed a
mis-sized window and the defect was a pattern that could not match the language.

**It killed the single number rather than retuning it.** Shell ends a loop with `done` and Python with
a dedent, both unambiguous, so both now get exact-extent helpers with no window at all. Brace
languages keep a window, but it is an argument with a measured default of 12, the p95 across all 386
bodies here, and the file says to re-derive it per tree rather than inherit ours.

**The bounded-versus-data problem, which I flagged as the hard part, turned out to be fully
mechanical, and the safety comes from which way it fails.** The discriminator is the loop's DRIVER,
never its body. Only an explicit `bounded` verdict suppresses; `unknown` never does. So a misread
driver costs one row to disposition instead of a missed defect, and the wave has a real instance of
being wrong in that direction and wrote it into the file as such.

**The proof is on the same file that proves the miss.** `80-file-size-caps.sh:103` forks twice per
tracked file inside a `find`-driven loop, 152 files today, and it is the catalog's own worked example
for spawn-per-item sitting inside the plugin's own pre-commit gate. Old protocol over that file: exit
1, zero candidates. New protocol: finds it, and separately finds a heredoc-driven line beside it and
classifies that one as noise. Whole tree, 60 shell files: the old protocol surfaced 12 candidates of
which 11 were bounded noise and exactly 1 was real. The new one surfaces 50, 15 real after
resolution. Fourteen findings the old protocol could not see.

**On the honesty machinery, my suspicion was right and worse than I put it.** The word "coverage" did
not appear in the file at all. The sibling scout has a whole reconcile section with an arithmetic
identity and a written rule that unread is never covered; this one had none of it. So the earlier
wave reported its zero honestly because that agent was careful, not because anything asked it to.
Care is not a mechanism. There is now a coverage pass that runs before any candidate is read, and a
specific rule for the case that keeps arising here: a markdown-only wave must report "covered 0 of N,
no executable file in scope", never "no candidates", because those two sentences mean opposite things.

- [x] E53. **Closed as recorded, no edit.** Re-measured at the parent: 486 of 500. Splitting a file that is under its cap to pre-empt a future edit is churn, and the seam would be guessed rather than driven by a real second question, which is what the three good splits this sprint were driven by. `scripts/tamper_harness.py` is at 486 of 500. The split solved the suite's cap problem by moving shared state into the module both suites import, so the module everything depends on now has 14 lines of headroom and is the next file to hit this wall. Green today; flagged rather than pre-emptively split, because nothing needs it yet.

### 2026-09-01, the split, and a completeness check that catches what an exit code cannot (E32, E44, E45)

Battery at 197 passing, both caps green. The seam went where the wave argued it should, and the new
file's header carries the argument rather than the boundary: why the file exists, why it is a second
file, why THIS seam, and what the seam cost. That last one is the part most split headers omit. This
one cost four shared helpers, which went to the module both suites already import, because putting
them in either suite would make one suite import its sibling and that module's own docstring exists
to refuse exactly that cycle.

**Two judgement calls inside the seam, both the right way round.** It did NOT copy the
orchestrator-wiring assertion into the new file, because both suites drive the same fragment and a
second copy is a second thing to drift. It DID add a clean-corpus baseline row, because without a
measured green every red in that file could be the corpus rather than the tamper. And the baseline
asserts each site's own pass line rather than the agreement line alone, since the agreement green
prints over however many sites resolved and reads identically at three as at two.

**The completeness check was built and it earned its place with a measurement, not an argument.** The
wave constructed the exact blind spot the old assertion had: a fragment that shrugs at a file it
cannot open, with the count guard blinded too. Over a corpus missing a path, the return code is ZERO.
The old `assert rc == 0` would have passed in silence. The output comparison caught it and named the
cause. Both of its limits are in the code as comments, and the comment also names what the other
three corpus builders want instead, which is a pristine-green baseline none of them has.

**The asymmetry I got wrong is now written where it will be read.** The helper carrying it explains
that the check takes the first resolving site as its reference and refuses to adjudicate which site is
stale, because at two sites there is no majority and a majority rule that works only at three breaks
when a fourth site picks the name up. The site table also warns that its order is load-bearing and
points at the helper, so someone reordering it meets the warning at the table instead of in a failure
three rows down.

**And the fixed docstring says what it used to say.** It no longer carries a count, and it records
that it used to claim seven while the tuple listed eight and then nine. A stale claim inside the
machinery built to catch stale claims, left visible on purpose.

- [ ] E54. **The anchor wave's scouts never ran.** Its own last words were that the scout searches errored and returned a false zero, and it died before redoing them. So E38's files carry no perf-scout or law-scout disposition. The work itself is verified by its gates, but the scout pass is genuinely missing rather than clean, and that is the distinction the perf-scout coverage section (E37) now exists to force. Re-run both over the five files when the limit lifts.

### 2026-09-01, the anchor split landed while its wave was dying (E38, E49, E50)

Both waves hit a weekly account limit mid-flight. The rename had written nothing, it died on the line
"now the baselines, before I touch anything", so there was no half-rename to unpick, which is the one
outcome that would have hurt: 28 files still carry the old names and all ten agent files are intact.

The anchor wave died later and its work was already on disk. Verified rather than assumed, at the
parent: every file under the 500 cap (388, 163, 218, 486, 240), the checker green over 121 files,
both suites passing at 32 and 13, the CI row mounted, `[80]` clean and the tamper battery still at
197. The crash guard is in `scan_file` catching both error types, the slug cache is on the resolver,
and the census sits in the new module's header saying in the first paragraph that this tree holds 362
links and ZERO fragments, so a future reader meets the reason before the code.

**What did NOT happen is worth more than what did.** Its last words were that the scout searches had
errored and returned a false zero, and it was going back to redo them with a real matcher when it
died. So these five files have no scout disposition at all. The gates prove the code works; nothing
has looked at it for perf waste or law breaks. That is exactly the distinction the coverage section
added this morning exists to force, and this is the first wave to be caught by it, retroactively and
by its own honesty. Filed as E54, not written off.

- [x] E55. `[89]` has no presence pin outside the validator itself. Only 3 of roughly 40 fragments are covered in `test_ban_tokens.d/40-fragment-coverage.sh`, so deleting `[89]`, its source line and its manifest row leaves the whole bar green. Found by the wave that wrote it, about its own work, and it could not reach that file. This is the general gap, not a defect of `[89]`.
- [x] E56. `rrn_absent`/`rrn_absent_all` in `89-reviewer-rename.sh` are 21-of-31 lines identical to `wi_absent`/`wi_absent_all` in `73-implementer-rename.sh`. The real differences are `--untracked` added and `--cached` dropped, both argued. The generalized form belongs in `validate-dod.d/00-helpers.sh`, which was outside that wave's allowlist. Second rename means second use, which is when this repo extracts.

### 2026-09-01, the rename landed, and the convention I told it to restore does not exist (E41, E42, E43)

All six agents renamed across 27 files, six files moved, one new check, and the bar went 1821 to 1853
ok lines with the same single `dist/` FAIL. Verified at the parent rather than taken from the report:
the roster reads `reviewer.md` plus five `reviewer-*.md`, no dead name survives outside `docs/`,
`CHANGELOG.md` and the fragment's own ban literals, mirrors 10/10, battery still 197.

**I was wrong about the silent file, and the correction inverts the lesson.** I said one canonical
file fails to name its own agent type. Two do, and the second is the merged reviewer's own file, the
newest of the six. More to the point, the wave walked the whole roster instead of the pattern and
found that **6 of 10 canonical files never name their mirror**. Silence is the majority. The four
that carry a pointer are an artifact of being split out of one file in v0.13.0. So adding the pointer
to the silent ones would invent a convention, not restore one, and the real registry is the pair map
in the sync script, which is what it drove the sweep off. My framing was "these files should name
their mirror and one forgot", and that was backwards.

**It also split my 28 into two classes, which I had collapsed.** `CHANGELOG.md` has ten hits and
exactly one of them is live: a claim inside the unreleased section about which type Phase 5
dispatches. The other nine are shipped entries. Getting that backwards in either direction is a
defect, rewriting the nine falsifies history and skipping the one ships a false claim, and my brief
treated all 28 files as one kind of thing.

**It went wider than I asked on the exclusion, and the argument is better than mine.** I said exclude
`docs/work/done/` narrowly. It excluded all of `docs/work/`, because a work-doc carrying out a rename
cannot describe its own backlog task without naming what it renamed, which this very file does eight
times. The narrow version would force the next rename's author to falsify their live work-doc to keep
a validator green, which is the same lie as rewriting an archived one, one directory up.

**Two divergences from the implementer-rename precedent, both measured rather than reasoned.** It
scans untracked files, because the precedent's argument that another check covers them has a hole:
that check does not cover `scripts/`, and there were seven untracked files under `scripts/` while the
rename ran. It proved the gap by planting a dead name and watching the precedent's shape miss it. And
it dropped the index scan, because at the moment the rename finished a `--cached` scan returned ten
files whose worktree copies were already correct, so that half would be red for the entire life of any
uncommitted rename while adding nothing in CI.

**The check caught its own manifest row on the first run**, and it reworded the row rather than
widening the exclusion to hide it.

- [x] E57. **The repair for the stale-citation class trades a machine-checked anchor for an unchecked one, and nothing closes that.** `[57]` verified the old `path:line` form only in the sense that the line existed; it could never tell right paragraph from wrong. After eight repairs this sprint, it now verifies only that the PATH resolves. Nothing reds if a future wave rewords a quoted anchor phrase out of its file or renames a cited construct. Strictly better than what was there, because it survives line shifts, which was the whole point, but it is not verified and calling it verified would be wrong. Both anchor forms are a `grep -F` away, so a check that resolves quoted-phrase and construct-name anchors back into the cited file would close the class properly. Named by the wave that did the eighth repair, about its own work.
- [x] E58. `sh_accum` in `perf-scout.md` cannot see an accumulator written inside a `case` arm. Its matcher anchors on a line starting with an identifier, so `*) unknown="$unknown $t" ;;` is invisible. Found by reading, not by the helper, on a live instance at `20-templates.sh:360`. Every accumulator in a case arm is unreachable to the shell coverage that landed this morning.

### 2026-09-01, four for four, and the repair that is not verified (E35)

The healthy-citation hypothesis did not survive. Zero of four were accurate. The two nobody had
checked had drifted FURTHER than the two that were reported, both by the same eleven lines, which
says they moved together in one paragraph insertion rather than four independent rots.

**It rejected three anchor candidates on measurement, which is the part I would have got wrong.** One
short phrase appeared twice, once in the cited file and once in a sibling fragment saying nearly the
same thing in nearly the same words, the exact near-miss that nearly caught an earlier repair today,
repeating on a different pair. One heading it considered was in the citing file itself, so citing it
would have been circular. And one candidate returned ZERO hits, because the phrase wraps across two
lines and grep is line-based, so a multi-line quote is not an anchor at all. That last one is worth
keeping: the obvious way to pick a distinctive phrase is to pick a long one, and a long one is
exactly the one likely to be wrapped.

**Line neutrality was proved harder than I asked for.** Not just equal file lengths: all four
citations still sit on their original line numbers, and the doc-link checker independently confirms it
by reporting 61 line citations before and 57 after, a delta of exactly the four removed with nothing
else moving.

**And the finding that finishes the class.** After eight repairs this sprint, the anchors we have been
landing are not checked by anything. `[57]` used to prove a cited line EXISTS, which is why it could
never catch the drift. Now it proves only that the path resolves, so nobody reds if a future wave
rewords the quoted phrase out of the file or renames the cited construct. That is still strictly
better, because it survives line shifts and that was the whole point, but it is not verification and
saying otherwise would be the same overclaim we have been fixing. The wave named it about its own
work, and noted both anchor forms are a `grep -F` away. Filed as E57.

**One honesty note it volunteered rather than smoothed over.** Its restores overwrote whole files from
snapshots taken a second earlier, so a sibling writing inside that sub-second window would have been
silently reverted with no error at either end. It has no evidence that happened and the diffs show
only its own lines, but it said the window existed, and named the temp-copy shape that would have
removed it. That is the right way to report a risk you did not hit.

- [x] E59. **Caused by E52, and live now.** `perf-scout.md:192` is the builtin-replaceable grep row and it still cites `perf.process.spawn-per-item`, which the split narrowed to the batchable case. Its own note already says the zero-fork fix is worth splitting out, so the row was written knowing it wanted a second ID. Repoint it to `perf.process.fork-for-builtin`, plus the staging example at `:264`. Also at `:261`, the staging example cites the very defect E51 just fixed with disposition `staged` and an abbreviated path. Folds with [[E58]], same file.

### 2026-09-01, the catalog split, and a severity difference that is not there (E51, E52)

**It extended rather than renamed, on the catalog's own written rule** that renaming an ID breaks
every surface that greps for it. The old ID keeps the batchable half, which is what makes this a split
rather than a rename: its row already led with the batching fix, so every existing citation of it
stays correct with no edit anywhere.

**I said the two cases arguably differ in severity. They do not, and it measured rather than
agreeing.** 307 forks for the builtin case took 0.42s against 0.00s for the parameter expansion; the
batchable case 0.45s against 0.03s. Same cost per item, same scaling. So both rows ship at the same
severity and say why, instead of implying a difference that does not exist. It offered the axis that
does separate them: fix RISK, not harm. The builtin fix is local to one line; the batchable fix
restructures a loop and can under-read the set.

**The measurement of its own fix is honest in the direction that costs it.** 0.45s saved per run, 5.5x
on that fragment, about 80% of its runtime. It said plainly that half a second on a gate with forty
fragments is real but modest, and that the better argument is scaling, since the tree grew from 250 to
252 scanned files while the wave was working in it.

**And it noticed that batching removed a guarantee, so it replaced it.** Measuring inside the loop
proved every file had been opened; measuring in one batch does not. It added a reconcile between the
batch row count and the list count, then proved that guard can fire by making one file unreadable and
watching it red. Without that, the speedup would have quietly traded away the assurance that nothing
was skipped, which is this sprint's defect in its purest form.

**Two things it corrected.** My file count was low: the scan reaches 250-odd files across six
directories plus the repo root, not the 152 I quoted, so the loop was costing about 500 forks a run
rather than 300. And its output-equality proof had to be run against a frozen corpus, because the tree
was moving under it: a sibling's file changed size between two of its runs. The single differing line
in the diff is the check reporting the length of the file it had just edited, which is the check doing
its job.

**The split created one live defect and it named it first.** The scout row for the builtin case now
cites the ID that no longer covers it. Filed as E59 and dispatched immediately.

- [ ] E60. `scripts/validate-dod.sh:84` runs `cd "$REPO_ROOT"` with no `|| exit`. A failed `cd` runs the ENTIRE validator against whatever directory the shell was in, and every check would report on the wrong tree. Pre-existing, flagged by the wave that was editing the file around it and correctly left alone as outside its task.
- [ ] E61. `88-plugin-map.sh` forks a `grep` per shipped entry point, and the driver is discovered rather than bounded, so it scales with the plugin. Fourteen forks in a once-per-commit gate is small, but the fix changes that check's exactly-one counting logic, which is not a thing to do inside an unrelated task.

### 2026-09-01, the manifest that could not leave, and a check for lying rather than renaming (E20, E47, E48)

**My line count was a commit stale and the wave said so first.** The file was 487, not 460. That is
the exact failure the always-on rule names, a number I did not recount, and I passed it into a brief
as fact.

**The bigger correction is that decision 4A was not possible as stated.** I told the user we would
move the manifest out. Three checks read it IN PLACE: one requires every sourced fragment to be named
in that header, one parses each row's check-id range out of it and compares both endpoints against
the fragment, and a ban-token test greps the validator for a literal row shape including its trailing
comma. Moving all 42 rows out would have reddened the first one 42 times. So the wave split instead:
all 279 lines of prose went to the README byte-for-byte, verified with a diff, and a 43-line index
stayed behind, one line per fragment. 487 to 271, and a new fragment now costs one line instead of a
paragraph. The user chose 4A and got its intent; the mechanism had to change and that is worth saying
plainly rather than reporting 4A as landed.

It also found, while transcribing, that one row had been spliced into the middle of another's
sentence, so one fragment's description read as a fragment of a sentence and its tail sat under its
neighbour. One row per line makes that shape impossible.

**The miner's hardest problem was one I never anticipated, and it found it by being wrong first.** Its
first version cleared a suspected contradiction when the same LINE carried a negator. The real defect,
still in the committed tree, is a single markdown cell reading "The full workflow. On request, or when
quick's own size test escalates. Never auto-fires." Three sentences on one line: the contradiction is
in the second and the word that clears it is in the third. So the line-scoped version swallowed
precisely the defect it was built to catch and printed green. Sentence-scoped clearing fixed it, and
the residual limit, a contradiction and a negator inside ONE sentence, is written in the header with
the cleared count printed per predicate so the subtraction can be audited.

**It covers 9 of 19 entry points and prints the other 10 by name**, as a note rather than a red,
because reddening on them would make the only route to a green bar a table claiming predicates it does
not have. Three predicates were mechanical; the rest were left out and listed, including everything
about groom's cadence and codewalk's trace depth, because no authority in the tree states their
opposite. That printed list is the whole difference between this and a check that examines four things
and reports clean.

One detail worth keeping: the first predicate's matcher needed two shapes, because the contradiction
that actually shipped contained neither the word "auto" nor "promote". It asserted a CONDITION, which
is the same claim spelled as a trigger.

- [x] E62. **The sibling-track database gate self-matches, and it has taxed EVERY wave this session.** The gate excludes `*.md` from its content search precisely so a file discussing databases is not read as having one. But `82-throughput-and-routing.sh` pins the gate's own matcher string as a `.sh` literal, so the exclusion misses it and the gate reports the validator as evidence of a database. Every wave today, roughly ten of them, has reported opening that same file plus two lawkeeper fixtures and ruling all three out by hand. The rules file already documents this exact failure happening to itself one file over. Fix the exclusion so it covers a file that pins the pattern rather than uses it.
- [ ] E63. The pipeline row in `perf-scout.md` straddles both process IDs: a pipeline that exists only to trim one variable (`| tr -d ' '`, `| cut -d: -f1`) is builtin-replaceable, not batchable. Splitting it means classifying by what the pipeline is FOR, which no regular expression reaches. Named and deliberately left, rather than fixed badly inside a repointing task.
- [ ] E64. The catalog's detect hint for `fork-for-builtin` names `$(echo` and `$(expr`, which no pattern row covers. That is new detection, not repointing.

### 2026-09-01, the row that claimed a builtin replaces a filesystem call (E58, E59)

**The correction I did not see coming.** I sent it to repoint one row to the new builtin-replaceable
ID. It found the row also matched `realpath`, and `realpath` is not builtin-replaceable at all: it
resolves symlinks against the filesystem and no parameter expansion does that. It IS batchable, since
it takes many operands in one call. So it narrowed the row and moved `realpath` to the batchable one.
Repointing the row as briefed would have shipped a scout asserting that `${f##*/}` replaces a
`realpath` call, which is simply false.

It also flagged the inverse case in one clause rather than a new row: `$(cat "$f")` on a SINGLE file
is the builtin case, because `$(<file)` replaces it outright.

**On the accumulator, the fix keeps the anchor rather than loosening it**, which is what I asked for
and is the part most likely to have been done badly. One substitution strips at most one case-arm
prefix and hands the arm's command to the existing branches untouched, and it demands a closing paren
before any opening paren, which is exactly what stops an array append or a command substitution from
being mistaken for an arm.

**Its control is the best one I have seen this session.** "Not reported" proves nothing on its own, so
it proved three things instead: the excluded lines ARE emitted into the matcher, so they are suppressed
by judgment rather than by never arriving; changing only their SHAPE while keeping the same lines in
the same positions makes them fire; and the two pre-existing rows are byte-identical before and after.
That is an absence measured by its method's ability to have found the thing present.

**And it caught its own false alarm before reporting it.** An isolated fragment run printed a
command-not-found that looked exactly like a sibling breaking a shared helper. It was its own runner
failing to source a second helper file. It said so plainly, so nobody else reads that as another
track's red.

**The finding I want fixed is the one about our own tooling.** The sibling-track database gate excludes
markdown so that a file discussing databases is not mistaken for one that has a database. A validator
pins the gate's own search pattern as a shell literal, so the exclusion sails past it and the gate
reports the validator as evidence. Every wave today has independently opened that file and two
lawkeeper fixtures and ruled all three out by hand. That is the same failure the rules file already
documents happening to itself, one file over, and it is now a tax on every dispatch. Filed as E62.

- [ ] E65. **Two fragments sit at exactly 500 of 500.** Re-measured at the parent: `00-helpers.sh` and `75-ship-bar.sh`. Zero headroom on both, and `00-helpers.sh` is the file four CI commands source by name, so it is the one most likely to be edited next. Unlike [[E53]], this is not a warning about a file with room; it is a file with none, where the next line added must be paid for first. The seam wants deciding before somebody needs it mid-task.
- [ ] E66. `[75f]`'s new softener ban covers ONE site. The same cap is stated in two other files in their own words, and neither is guarded against being qualified. Same fix shape, different literal per site, and the wave that built the first one named the other two.
- [ ] E67. `75-ship-bar.sh` forks `basename` twice per mirror pair on a data-driven loop. Staged rather than fixed because the file is at the 500 cap, which is a defect blocking a fix rather than a defect being tolerated. Folds into [[E65]].

### 2026-09-01, four checks that could not fail, and the one number a deletion cannot shrink (E33, E34, E55, E56)

Bar at 1869 ok lines against 1821 this morning, battery 197, ban-token suite 207 against a 202
baseline, one FAIL and it is the `dist/` staleness I clear at close.

**On `[75f]` the finding was worse than I reported it.** I said the softened wording leaves the pin
green. It does, and the check's own ok line then reads that the file "states the cap WITHOUT AN ESCAPE
HATCH" over a sentence that is nothing but escape hatch. Both qualifiers sit outside the pinned run of
words, one before and one after, so the pin could never have seen either. The fix leaves the pin
alone, because a longer literal breaks on the next honest reword, and adds a ban over the extracted
SENTENCE. Ten hedge words, hand-counted. The bare word "if" is deliberately excluded, because "even if
the fixes changed everything" is a correct absolute statement of the cap and banning it would red on
the right text.

**On `[38h]` it chose to stop printing the number rather than pin it, and the argument is better than
the one I would have made.** Pinning it would put two hand-written bounds over one fact in two
fragments, each free to rot alone and each needing an edit for one legitimate reword. The control's
job was only ever that the scan reached the tree. It now claims that and names where the count really
lives.

**The fragment sweep is the piece I would keep if I could keep one.** Three of 43 fragments were
covered, so 40 could leave the run on a three-line edit with the bar fully green. The mechanism turns
on the constraint I gave it: a set discovered from the directory goes short exactly when a fragment is
DELETED, so discovery alone can never catch a deletion. So the set is discovered, and the TOTAL is
hand-written outside the directory, because that is the only number a deletion cannot shrink. It chose
equality over a floor for a reason it argued against two neighbouring checks: those police numbers
that move every wave, while this directory gains a fragment twice a sprint, so a floor would tolerate
seventeen deletions at sixty fragments and still read green.

Its own first draft had a real bug it found and wrote down: command substitution strips trailing
newlines, so the newline-fenced match missed the LAST manifest row and false-redded a fragment.

**On the extraction, it refused the thing I was most worried about.** The two rename checks disagree
deliberately, one scanning the index and one scanning untracked files, each for a measured reason. It
parameterised the mode list rather than picking a winner, and proved BOTH callers still red correctly:
a dead name in an untracked file reds the newer caller, and a dead name living only in the index
leaves it green, which is the older caller's behaviour deliberately not inherited.

**The cost is that `00-helpers.sh` is now at exactly 500.** It fit the extraction by condensing five
prose blocks that were each stated twice, keeping every argument and one copy of each, and it flagged
that as prose it did not write rather than letting it pass. `75-ship-bar.sh` is also at exactly 500,
which is already blocking a small fix inside it. Filed as E65.

## 6. Daily Updates

### 2026-08-31, Phase 1 closed

Two read-only investigators checked all eight carry-over items against the code rather than trusting the list. Three items came back re-scoped.

Item 3 is far larger than its one line suggested. The ban helper is deliberately line-oriented and `00-helpers.sh:350-352` says so: *"The ban side keeps the line-oriented matcher, where a missed hit would be a false green."* Counted at the parent: `P5_BANS` holds 21 tokens of which 18 carry a space, `RR_BANS` holds 60 of which 50 do. Those can straddle a wrap and pass.

Item 2 is real but nothing consumes the count, so it is report accuracy rather than a detection bug. Item 5 is latent, not live, because `hooks/` carries zero call sites of the pinned kind today. Item 4 needs a citation convention that does not exist, so it leaves the sprint as a written design.

Item 7 is a genuine self-contradiction, verified verbatim: `skills/quick/SKILL.md:41` says *"Quick has neither a work-doc nor a slug to build that path out of"* while `:106` orders a report at a path built from `<slug>`.

Item 6 resolved to the skill-name mapping being unguarded in one direction: the validator catches a retired agent name but never a name that never existed, and `skills/codewalk/SKILL.md:3` advertises `/codewalk` where every sibling advertises `/hackify:<name>`.

**A correction to the sprint's own premise.** The A/B was specified against the panel's recorded 27 findings. That number was measured before last sprint's three fix rounds landed, and the whole sprint went in as one squashed commit, so the tree the panel actually scored was never committed and cannot be recovered. Comparing a new reviewer against 27 would compare two different diffs. The A/B therefore runs both reviewers head to head on the same current diff.

### 2026-08-31, the codewalk rename is four times the size the carry-over implied

The note said one line plus six prose sites. Measured at the parent: **22 command-form occurrences across 8 files**, and the count only came out right on the third attempt. The first scan used an ERE with `\b` that git grep returned 0 for, on a file I could see the match in. The second filtered out whole LINES containing `skills/codewalk` or `.codewalk/`, which silently dropped every line carrying both a command and a path, and undercounted to 6. The third counts occurrences rather than filtering lines, and carries a control: `README.md:153` must appear or the scan is vacuous.

Two boundaries came out of it. `CHANGELOG.md` holds many more occurrences and is excluded deliberately, because it is a historical record and this repo's convention is to leave old entries alone. `dist/` is excluded because it is generated.

### 2026-08-31, wave A1 landed the shared helper, and corrected the sprint's own premise

**Three functions went in** at `scripts/validate-dod.d/00-helpers.sh`: `flowed_flatten:414`, `check_no_flowed_token:436`, `check_no_flowed_tokens_in:465`. 118 lines added, **zero removed**, so `check_no_token`, `check_no_tokens_in` and `check_flowed_token_present` are byte-identical to what they were. Verified at the parent.

**The gap is LATENT, not live, and the parent said otherwise earlier.** I told the user this was a live false-green risk and used it to argue Group A should run first. It is not live. Verified independently at the parent by sourcing the real fragments with the flowed matcher swapped in for the line-oriented one, so the real token lists ran over the real file sets: `71`, `77`, `82` and `81` all returned a FAILED delta of **0**. Converting raises no new reds on today's tree.

**And that zero is trustworthy, because the method was shown able to return non-zero.** A multi-word token from `RR_BANS` was planted into `skills/quick/SKILL.md` deliberately wrapped across two physical lines. The line-oriented `grep -F` found **0** occurrences, which is the false green in miniature; the flowed run returned `FAILED = 1`. Restore verified byte-identical by `cmp` and md5.

The work is still worth doing, because the hole is real and a future edit can walk into it. The priority argument for doing it first was weaker than stated.

**Corrections the wave made to the parent's brief, all three upheld:**

`pipefail` is at `scripts/validate-dod.sh:200`, not `:186`. The brief said `:186`, and so do two live source comments, `00-helpers.sh:210` and `84-no-pipe-into-grep-q.sh:11`. The number was right when written and the file grew by 14 lines under it. The substance held: `pipefail` IS set, which is the only reason a SIGPIPE surfaces as 141 rather than vanishing. Folded into Group C as a follow-up, since both stale citations are the kind a reviewer opens and then distrusts the surrounding block over.

The positive control cannot ship inside `00-helpers.sh`, and the brief was wrong to ask for it there. That file states its own contract at `:9`, *"No check groups live here"*, and it is sourced by four things that are not the validator, including `scripts/test_ban_tokens.sh:38` and `scripts/tamper_harness.py:38`. A control firing on source would print into all of them and move `FAILED` inside suites that read `FAILED` as their own instrument. The control belongs to T8, where the call sites exist. The wave proved both directions live instead, including two mutations of its own matcher that each flip the assertion back to green.

`[81]` bans over **directories**, not files, so the flowed helper needed directory support the presence-side matcher never had. It flattens per file rather than per tree, deliberately, so a phrase split across two different files cannot manufacture a match. Proved on a planted tree.

**A constraint the next wave inherits.** `00-helpers.sh` is now **492 of its 500-line cap**. The wave's first draft came in at 517 and it trimmed comments twice to fit. The next addition to that file will not fit; it will need a split.

**An accounting trap flagged for T9.** `TB_EXPECT_CALLS=7` counts `check_no_tokens_in` call sites specifically. Converting sites makes that number go **down**, not up. The wave recommends adding a second counter for the flowed name rather than letting the original drift downward, because the coverage half of that assertion is the part that bites.

### 2026-08-31, wave A2 converted all ten sites, and the payoff showed up on the rule that matters most

**All ten sites now flatten wrapping before they judge**, and each was proved with a plant split across two physical lines in a file that site really scans: ten plants, ten reds, ten byte-clean restores, and the old `grep -cFiI` returned 0 on every one of them. `[83]`'s private copies of that machinery are retired onto the shared helper.

**The concrete win, verified at the parent on the user's own hard rule.** Check `[81]` guards against AI attribution. A `Co-Authored-By: Claude` trailer planted on one line is caught, as before. The same trailer planted **wrapped across two lines** is now also caught, where the line-oriented matcher reported **0 occurrences**. So "latent, not live" was accurate about existing content, and it understated what the gap allowed: a trailer that wrapped would have walked through the attribution guard.

**The wave proved zero-new-reds harder than asked.** Rather than a FAILED delta it diffed the whole transcript: both runs 1809 lines, 867 lines differing, and every difference only the appended `, line wrapping flattened first`. Unexplained differences: zero.

**It refused A1's recommendation on the counter, with a better reason.** Letting `TB_EXPECT_CALLS` drift downward would read a conversion as a deletion and would break the coverage assertion outright, since `total == lists` would compare one matcher's call count against all seven parsed lists. Instead the counter now counts both names and returns three numbers: the total stays 7, with `TB_EXPECT_CALLS_LINE=1` and `TB_EXPECT_CALLS_FLOWED=6` pinning the split.

**And it widened its own scope for a measured reason.** The tamper suite was planting all 111 tokens through the line-oriented matcher while the validator now runs six of seven lists through the flowed twin, so the plants were exercising a matcher those lists no longer use. It made each sweep declare the matcher its list really ships under. The measurement that justifies it: blinding the shared flowed matcher now fails 105 of 111 plants; before the change all 111 would have stayed green.

**One red it did not plant, and it is the parent's fault.** `scripts/test_tamper_attribution.py` asserts on `[81]`'s exact red wording, which the conversion changed, and that file was not in the wave's allowlist. CI command 15 is red at 159 passed / 4 failed. The wave reported rather than reaching outside its allowlist, which is correct. My brief told it to search for fixtures pinning red strings and then failed to give it the one file that does. Dispatched as B1.

**A deviation it argued for rather than hid.** `tss_absent` survives as a two-line annotation over the shared helper instead of being deleted, because `83:92-95` records that baking the consequence into the message once produced "a red that misnames its own defect", and the shared helper cannot know what breaks when a specific token returns.

**Two things to watch.** `check_no_tokens_in` is down to one shipped caller, so one more conversion makes it dead. And the flowed helpers still have no green-path or corrupt-token-list case of their own in the tamper suite; their dirty path is covered by 105 plants and their fail-closed branch by `[83]`'s control.

### 2026-08-31, wave B1 cleared the red my brief caused, and found a hole inside its own fix

**The tamper battery is green again**, 163 passed / 0 failed, up from 159/4. The four failures were fixtures pinning `[81]`'s old red wording; they now assert the flowed form, and the one green-path assertion needed no change because that wording never moved.

**It found something my task description had wrong.** T22 was written as "report accuracy, not detection", on the reasoning that a line count versus an occurrence count only changes the number printed. That stops being true under the fix itself: counting with `grep -o` means an empty token produces no output at all, so it counts as zero and the check goes green on a corrupt ban list. The wave closed that hole with a guard and a test before shipping the change that opened it.

**And it proved the guard was worth having** by reverting the counter to its old form and watching both suites stay green. A silent revert nobody catches is the definition of a missing test, so the guard test is now the thing that would catch it.

**Both carry-over defects are closed.** The call-site counter reads `scripts/validate-dod.d` and `hooks` now, and it exits loudly when a named directory globs to zero files rather than quietly counting nothing.

**Two stale comments it flagged but could not touch**, both outside its allowlist: `96-review-scope-sites.sh:80` still says the pin counts one directory when it now counts two, and `test_tamper_attribution.py:15` still says `[81]` scans with `grep -r` directly when it now goes through the shared helper. Folded into Group C.

### 2026-08-31, the merged reviewer's first wave stopped before writing, and it was right to

**Nothing landed, and nothing should have.** The wave took a baseline, planted two placeholder
files to see what would happen, read the reds, removed them, and reported. The tree came back
byte-identical.

**"Registered but not adopted" is not a state this repo has.** I wrote the brief as though
`agents/` were a directory you can drop a file into. It is a registry. Landing one file there
needs three coordinated edits in files the wave was not given: `MIRROR_SOURCES` and
`CLAUDE_CODE_EXTRA` in `scripts/sync-runtimes.d/00-helpers.sh`, `AGENTS_EXPECTED` in
`scripts/validate-dod.d/60-primitives.sh`, and `MIRROR_PAIRS` at `scripts/sync_agent_mirrors.py:142`.
Landing only the canonical file with no mirror still reds `[55]`. There is no partial version
that leaves the build green.

That also made my own mirror instruction unexecutable: I told the wave to run
`sync_agent_mirrors.py` rather than hand-copy, but the script only knows the pairs in that
tuple, so it cannot produce a mirror that has not already been registered by hand.

**Two pins my brief did not know about, both proved by planting the literal and watching it red.**
Check `[76h]` pins `## What the review did not reach` and `A check that cannot fail passed for
the wrong reason` at exactly two files and two occurrences each, which is Reviewer B's canonical
file plus its mirror; the comment beside the pin says a third copy SHOULD redden, because that
is a roster change rather than a wording change. And `[79]` subject-checks the phrase
`conditional lens`: it reads the last standalone capital A-F before the phrase and requires E.

**What this changes about the order of work.** The head-to-head measurement never needed a
registered agent, only the prompt text. So the prompt is being authored as a measurement
artifact outside the tree, the A/B runs on it, and registration becomes a decision made with
the result in hand rather than before it. If the merged reviewer wins, those three registry
edits are the cost of adopting it. If it loses, the question the user answered as 2A ("the
agent ships unadopted") turns out to cost three edits in core registry files for something
deliberately never dispatched, which is worth re-asking with the number visible.

### 2026-08-31, the A/B ran, and the merged reviewer lost on every lens

**Both reviewers ran on the same commit range, the same tree, and the same inputs**, dispatched
in one message so neither saw a tree the other did not. Subject `9d0961e..51ecd00`, 49 files,
work-docs excluded. The panel ran four agents, because lens E's scope resolved to zero
UI-bearing files and `phase-5-review.md` step 5 says an empty lens is not dispatched. The
merged reviewer ran five passes.

| Lens | Panel | Merged |
|---|---|---|
| A security | 1C 1I 2m = 4 | 0C 0I 2m = 2 |
| D performance | 0C 0I 2m = 2 | 0C 0I 1m = 1 |
| E design | not dispatched (empty scope) | not UI-bearing |
| F coherence | 1C 4I 3m = 8 | 0C 1I 1m = 2 |
| B quality + plan | 2C 6I 3m = 11 | 1C 4I 1m = 6 |
| completeness | 0C 2I 2m = 4 | 0C 3I 2m = 5 |
| total | 4C 13I 12m = 29 | 1C 8I 7m = 16 |

**Verdict: it fails the gate.** The sprint's own acceptance criterion was that the merged
reviewer is adopted only if its per-lens counts match or beat the panel. It beat the panel on
nothing. The Critical column is the sharpest: four against one. Its A pass missed the
flowed-ban false green that panel A reproduced from a clean checkout, and its F pass missed the
testing-stage partition split that panel F traced across three files.

This repeats a result this repo already had. `phases/phase-5-review.md:58` records that on the
diff which retired the fold-in gate, the un-gated panel returned 41 findings where the gated one
returned 15, and concludes "Folding moved the words and lost the attention." That was 37 percent;
this run is 55 percent. Gated sequential passes with per-pass exit artifacts clearly recover
some of the loss, and they do not close it.

**What the merged reviewer got right, recorded so the design is judged fairly.** It did not fall
into the trap its own prompt set for it: pass 3 reported `not UI-bearing` and named all 49 files
rather than reporting a clean design review over a surface that was never there, which its own
SEVERITY section grades Critical. And it found four real defects no panel agent found, each
verified at the parent:

- `debug-when-stuck.md:159` orders the debug fix path to write a failing regression test and
  `:176` dispatches that to an implementer, while `agents/implementer.md:218` says every mode but
  `test-authoring` is "PRODUCTION CODE ONLY. Author no tests, watch no red." The fix path has no
  legal dispatch mode. Its F and B passes found this independently of each other; the panel found
  it zero times, across four agents.
- `CHANGELOG.md:131` says the plant total goes "from 91 to 102". The suite prints 111.
- `92-work-doc-structure.sh`'s `WS_DOC_FLOOR` and the sectioned-doc bound beside it describe
  themselves as "the exact count" and ship a floor. Cited by line number when the reviewer
  reported it, and the block has been rewritten since, so the numbers in the original citation
  no longer resolve. Named by construct here rather than corrected, because what the reviewer
  saw is the record and the finding stands either way.
- `[82]` carries 35 presence pins with no tamper coverage at all, where 83, 84 and 92 each ship
  an in-fragment control.

So the honest reading is not that the merged reviewer is bad. It is that one context cannot hold
five lenses at full attention, and that its unique finds argue for a sixth lens rather than for
replacing five.

**A defect in my own dispatch, caught by the reviewer I was measuring.** The `metrics_table` I
built measured the working tree instead of the commit under review: `00-helpers.sh` reads 492
now and 374 at `51ecd00`. Panel B caught it, re-measured all 49 files and all 80 bash functions
by hand, and reported it rather than using the wrong numbers quietly. Both sides received the
same bad table, so the comparison stays fair, but the input was wrong and the error was mine.

**Two numbers I wrote into the 0.18.0 changelog do not hold**, each found independently by two
lenses. `CHANGELOG.md:100` says "Twenty-three places had the same shape" where the diff removes
24, and `:104` says "none in the seventy runs" where `84-no-pipe-into-grep-q.sh:24` and
`validate-dod.sh:105` both say 100.

### 2026-08-31, wave C1 widened [84], and the widened check immediately caught a live site nobody had named

**`[84]` was catching one reader spelling out of nineteen.** The shipped matcher was
`'\| *grep -q'`, which needs `q` to be the first letter of the flag cluster. The wave built a
probe table of 19 banned spellings and 9 prescribed safe forms and measured the old matcher
against it: **3 caught, 16 missed**. The new one catches all 19 and stays off all 9.

**The miss that mattered was one my brief did not contain.** I listed five missed spellings. The
wave found a sixth, `grep -Eq`, and it was live at `70-invariants-and-new.sh:68`, inside
`validate-dod.sh`'s own `pipefail` scope, in the same directory as the check that exists to ban
it. So the check shipped in 0.18.0 to forbid this pattern could not see the instance sitting
next to it. The wave left it alone, because it was outside its allowlist, proved the one-line
fix in an off-tree copy of the whole repo, and reported the tree as red rather than reaching
outside. That is the third wave this sprint to stop at an allowlist edge and be right to.

**It corrected two things I told it.** I said a here-string does not help. It does, for eight
existing sites and for the `70:68` fix; where it fails is `head`, and for a different reason than
I gave: three of the five `head` sites have a `grep` stage between writer and reader, so moving
the writer's output into a here-string just changes which process takes the signal. And my reader
list was short at exactly the end that was live, the flag-cluster reorderings `-Eq`, `-Fq`, `-iqE`.

**The `head` idiom, argued and measured.** `awk 'NR<=N'` replaces `head -N`: same output, but it
drains its input, so nothing upstream is ever signalled. Measured on an 80KB body under
`pipefail`: `head` form rc=141 and `grep | head` rc=141, against rc=0 for both awk forms, with
identical output checksums. One of the five converted sites executed for real during
verification, `release.sh --dry-run` hit its dirty-tree branch and printed exactly five lines.

**All five sites proved harmless today, mechanically rather than by assumption.** Neither
enclosing file sets `-e`, and every one of the five pipelines is followed by a statement that
overwrites `$?` before anything reads it. Latent, not live, exactly as the refuter judged. Fixed
anyway.

**Eleven manufactured reds, plus two negative controls.** Each banned spelling planted as a live
code line, each producing a red naming `[84]` and the planted line, restored byte-identically
between every plant (`cmp` clean, md5 stable). The two controls, `awk 'NR<=6'` and `tail -6`,
correctly produced no red. Without those, a matcher widened past the defect would redden on the
very conversion the check prescribes.

**On T45 it argued against building the harness, and I agree.** Re-establishing "0 failures in
100 runs" costs about 100 validator runs, roughly 17 minutes, and still would not be a proof,
since a clean 100 is consistent with a true rate of 1 in 200. What a check can own is the
property those runs were evidence for, that no such pipeline is in the tree, and that is what the
scan does on every run. The numbers stay, dated and labelled as unreproduced.

**Follow-up it raised:** the fenced-markdown surface shares `PG_RX` with the directory scan but
has no planted proof of its own, because the agent `.md` files were outside the allowlist.

### 2026-08-31, the refuter fabricated its own evidence, then retracted

**It reported verdicts on citations it had not read.** Its first report opened with "Agent 1's
evidence is in" and "All evidence is in" while neither evidence agent had returned. Twelve of the
thirty-five findings (F5, F7, F8, F15, F18, F19, F20, F22, F23, F24, F28, F32, F33) carried
citations nobody had opened. It caught itself, went back, read every one, and reissued.

**One verdict flipped, and it is the one I had already passed to the user.** F18 was reported
REFUTED on a counter-citation, `implement-and-test.md:114`, that does not say what the refuter
claimed. On re-reading it reversed itself to UPHELD. I verified the reversal independently rather
than accepting it: `debug-when-stuck.md:176` dispatches the FIX carrying "the failing test as its
inputs", so the test pre-exists that dispatch and the parent may not write it, while
`implementer.md:221-222` puts `test-authoring` after the last implementation wave for code already
on disk. One wave cannot write both. F18 is real and is now T48.

**A second fabrication inside the same report.** Its "33 non-comment pin sites" for F23 was
invented; `grep -c` returns 35, which is what the finding said. The tamper experiment behind F23
was real, so the verdict held, but the number did not.

**What this costs, beyond the one finding.** I relayed the F18 refutation to the user, including
a self-correction saying my own verification had been too shallow. Both halves were wrong. The
lesson is not "refuters are unreliable"; it is that a REVERSAL of a parent-verified finding is
exactly the claim to re-derive before repeating, because it is the one that talks you out of work
you were otherwise going to do. A refutation is a claim like any other and gets the same tier of
proof as the finding it kills.

**Revised round tally: 35 findings, 29 upheld, 4 refuted (F14, F28, F32, F33), 3 of the upheld
already fixed by this sprint's own Group A (F1, F9, F21).**

### 2026-08-31, four waves closed Group D, and three of them found more than their brief named

Ran four waves concurrently on file-disjoint sets rather than serialising them behind the shared
validator. That worked, with one cost worth recording: every wave watched the bar change under it
mid-run, and one reported a manufactured red that came back silent because a sibling rewrote the
tree between the plant and the scan. It re-ran and reproduced correctly twice. Nobody reacted to a
sibling's failure, which is what the brief asked for and what makes concurrent waves safe here.

**The new namespace check paid for itself on its first run.** T20 shipped `[86]`, which reads every
`/hackify:<name>` and every bare plugin command in the tracked tree. The brief expected two known
sites. It found six. Two were in the README the same wave was already editing, and four were
outside anyone's allowlist: the fragment that enforces the 500-line cap, hackify's own finish
doctrine telling users how to resume, and two files in lawkeeper including its test suite. A
follow-up wave read each in context and confirmed all four were genuine command references, not
over-matching. That is the whole argument of the sprint in one check: the codewalk rename existed
because nothing enforced the namespace, and the thing built to stop it recurring immediately found
more of the same class.

**The pin-count finding was stale rather than ambiguous, and the honest fix was bigger.** F23 said
`[82]` ships 33 presence pins with no tamper coverage. Both 35 and 33 were correct at the reviewed
commit; today the tree returns 34, because this sprint's own wave A2 replaced a fifteen-iteration
loop with one batched call. A counter keyed only to the single-token helper would have passed while
leaving 17 tokens behind that batched call covered by nothing. The new coverage fragment counts
both forms and fails them apart, proven with three planted reds including the refuter's original
deletion.

**One control was asserting something about the tree, not about its plant.** The roster guard's
positive control originally asserted its own total red count. Run over a tampered tree it inherited
the live roster's two reds, reported five, and announced that one of its branches was dead, over a
check whose branches were all working and whose real verdict was three lines below. It now measures
the live roster first and asserts the difference. Same class as the floors we spent this sprint
rewriting: a bound that moves with what it is measuring cannot police it.

**Where the bar stands.** One failure left, and it is the expected one: `dist/` ships 18 files that
differ from source, which the closing `scripts/sync-runtimes.sh` repairs and which no wave is
allowed to run. 1809 ok lines, 202 ban-token assertions, 172 tamper rows, all green. The 543-line
cap breach two waves reported on `test_tamper_status_claims.py` is closed at 499.

**Three stale citations came out of the sweep and are now their own task.** Resolving all 118
`path:line` citations outside `docs/work/` turned up six stale ones, and three of those were correct
this morning: they cite `scripts/validate-dod.sh:221` for the `set -uo pipefail` line, which is at
248 now and moved twice today, once per fragment landed. The rot is not carelessness, it is a normal
edit above the target, and `[57]` cannot see it because it only asks whether the cited line exists.
The fix is to name the construct instead of the number, which is what item 4 of the retrospective
argues at length.

### 2026-08-31, the reviewer's reproduce obligation got a boundary (E13)

The strengthened pass 1 orders the reviewer to RUN the gates a diff touches rather than reason
about them, which is what recovers the false green the panel caught and the merged agent missed.
The wave that wrote it flagged the consequence itself instead of shipping it quietly: the reviewer
now executes code out of the diff it is reviewing, and the prompt mandates it rather than leaving
it to judgment. That went to the user, who kept the obligation and bounded it.

**The bound, in the user's terms.** The reviewer runs the project's own check surface, its test
suites, validators, linters, guards and CI commands, and nothing else. A binary, a server, a
migration runner or an install script the diff introduces that the surface does not already invoke
is not executed, whatever the diff claims it does. The reasoning the user accepted is that those
commands already run on every push, so a review adds no exposure the build does not already carry.

**Two decisions inside the wave worth keeping.** It refused to hard-code this repo's CI grep, which
would be useless in a repo driven by GitLab or a Makefile, and named the two universal sources
instead: whatever the project's CI configuration invokes, plus the three commands the repo brief
already states verbatim to every agent. And it added the sentence that closes the real hole, that
those two sources name the surface and the agent's sense of what looks harmless does not, because
the failure mode here is an agent talking itself into an exception.

**The skipped gate does not go silent.** A gate outside the surface is reported UNVERIFIED and
filed as a coverage gap, never omitted, which is the same move pass 4 already makes for a seam
whose far side it never opened. One convention rather than two, and the file says so, so a later
editor does not split them apart.

**What nobody has proven.** No dispatch has exercised this. The prompt is well-formed, mirrored
byte for byte and green against every check that grades it, and none of that shows a reviewer
reading the clause actually refuses a new entry point rather than quietly running it.

### 2026-08-31, three stale reviewer references, and a fourth the brief did not name (E14)

The wave fixed the three sites it was sent for and found a fourth by reading the whole skill
instead of just the lines it was pointed at. `skills/review-triage/SKILL.md` opened its Path A
by asserting that the parent "has just received one report per lens on the Phase 5 panel", which
is false under the new routing and would have survived every check in the repo.

**A ruling worth keeping: the contract did not move, only the vocabulary.** review-triage takes a
batch of findings, each severity-tagged, arriving after the refuter, one row per finding, four
decision values. The merged reviewer emits exactly that. What changed is the container, one report
carrying five gated passes instead of five reports, and the skill never read the container. The
wave checked this by looking at what WOULD have had to change if the contract had moved, the table
spec, the severity rubric, the four decision rules, the Critical guardrail, and confirmed none of
it did.

**It refused a rename that would have fragmented a name across files it could not reach.** Quick's
`Phase 5-lite` is not pinned by any validator, so renaming it was permitted. It is, however, the
phase's canonical name in five files outside the allowlist, including quick's ledger row and both
scout run-point tables. Renaming it in three files would have left five sites pointing at a name
that no longer existed. It kept every token and fixed the claim around them instead.

**Two follow-ups it could not reach, both the same defect.** `orchestration.md`, `perf-scout.md`,
`law-scout.md` and `phase-ledger.md` describe the merged reviewer as a "single-lens review", which
is backwards: it is one reviewer carrying every lens. And the two scout files still name Reviewer A
and Reviewer D as the co-signers of a dismissal, agents that are no longer on the default route in
either mode. Both go to the E11 sweep.

### 2026-08-31, the two work-doc laws went into the injected prompt (E15)

Both rules already existed in the doctrine and neither was enforced, which is why they decayed
in this very session: the parent ticked backlog checkboxes as each agent returned and batched the
Daily Updates entries into occasional catch-ups. The checkbox half survived, the written half did
not, and the written half is the one carrying the reasoning nothing else records.

**The wave folded rather than added, and argued it on substance first.** It ruled the two rules
are one law, because both fail the same way, a durable write deferred to a catch-up that never
comes, and because `phase-ledger.md` already treats them as two rows of one anti-rationalization
table. It then folded that law into the existing fifth rather than adding a sixth, on the ground
that the observed failure IS law 5 at a finer granularity: the law already said a tick without its
written half is untrusted, it just never said the unit is one returning agent. A second reason
confirmed the choice rather than driving it, `## The five laws` is pinned as a positive assertion
by a suite outside every track's allowlist, so a sixth law would have red a test nobody owned.

**It designed for the digest, which is the part that decides whether a law survives.** Only the
first bold run of each bullet reaches later turns, so everything operational went into the lead:
the general law, the Phase 3 instance and the Phase 6 instance, with nothing resting on a later
sentence. It proved the result rather than asserting it, showing the full law on turn 1 and the
compressed pointer on turn 2 with all five leads intact and 402 chars against a 900 cap.

**And it found the hole in its own work.** Laws 2, 3 and 4 are pinned in exact bullet form so
nobody can de-bold them out of the digest, and law 1's carve-out is pinned too. Law 5 is pinned by
nothing, and it is now the bullet carrying both persistence rules. A future reword would delete
them from every prompt after the first with no check moving. It could not reach the fragment to
fix it and handed over the exact line to add. That is E17.

### 2026-08-31, the session-start map shipped, and its check is bidirectional (E16)

The user asked for an orientation document injected at session start, the way other plugins teach
a model their surface. Hackify had no SessionStart hook at all: five per-prompt rule injections,
two tool blockers, and nothing telling a fresh session that seven skills and two commands exist.

**The wave rejected the cheaper option on a substantive argument, not on cost.** Reusing the
existing per-prompt injector was tempting because that script already does full-text-then-pointer
and would have given the behaviour for free. It would also have emitted, on every prompt of every
session forever, a digest of the map prefixed `is binding verbatim`. That is the two-copies failure
the brief warned about with the roles reversed: the fading copy would have been claiming the
authority the real rules have. It took a real SessionStart hook instead, after confirming the
runtime supports it by finding a first-party plugin that ships exactly that shape.

**The arrival proof is the result that matters, and it carries a negative control.** A fresh
session was asked, with every read tool disabled, to quote the map's title and one row. It quoted
them. The same prompt without the working tree loaded returned the sentinel `NO MAP`. Without that
second run the first proves nothing, since a model can know about hackify without being told.

**The check reads the roster from both ends, and the coverage direction is the one that matters.**
Resolution catches a map row pointing at something deleted; coverage catches a shipped entry point
with no row, which is the direction that rots on EXTENSION and the direction a resolution-only
check passes in silence. The wave ran four separate plants rather than the two it was asked for:
a bogus entry, a deleted entry, a sixth rule wired in with the map untouched (the literal extension
case), and a rule the map calls law that nothing actually injects. All four red, each naming what
it caught. The plant now reruns on every validator invocation and reds if it raises two instead of
four, because two would mean the coverage half had died.

**It also caught its own check breaking a sibling check.** Its first draft wrote the plant's fake
command as a literal, and `[86]` scanned the fragment and reddened on it, exactly as it should.
The fragment now assembles the token at run time, the way `[86]` solves the same problem for itself.

**One blocker it correctly refused to fix.** The new file is not in the sync manifest, and a
dry-run proves the hook would ship into the runtime tree pointing at a map that is not there. One
line, on a shared surface outside its allowlist. That is E18.

### 2026-08-31, the stale sweep: 31 edits, and a check that has been pointing 12 lines off (E11)

**A keyword search would have found perhaps a third of this.** The sweep read six files end to end
and one of them, `implement-and-test.md`, needed nothing at all, which is itself worth recording:
the wave said so rather than manufacturing an edit to look productive.

**What nobody had listed.** `phase-ledger.md` still demanded a Phase 5 exit artifact the round cap
retired, a final re-scan on a diff unchanged since that scan, where `phase-5-review.md` says
plainly there is no re-scan however much the fixes changed. `review-scope.md` governs an input the
default reviewer does not take and had no idea it was off the route, and it described lens folding
as a live mechanism two sprints after folding was retired. `orchestration.md` advertised per-finding
refutation pipelining and a loop-until-dry sweep, neither of which exists; there is one refuter per
round judging the whole batch.

**The co-sign rules got fixed at the right level.** Both scouts said a dismissal is co-signed by
Reviewer A or Reviewer D, agents no longer on the default route in either mode. The wave did not
swap one agent name for another. It named the LENS and then said which agent carries it on each
route, so the rule survives the next routing change instead of needing this same edit again.

**The rename it refused, twice over.** `Phase 5-lite` is live at four sites outside its allowlist,
so retiring it strands them. `Single-lens` is the same problem one level down: it is the phase's
NAME in quick's step heading, quick's frontmatter and quick's ledger row, and renaming it in one
file would leave one phase called two things. It moved only the three sites where the phrase was a
descriptive gloss, checked first that nothing pins the string anywhere in `scripts/` or `hooks/`,
and handed the rename over as one atomic edit.

**And the finding worth the most.** `98-work-doc-ledger-sync.sh` cites `phase-ledger.md:110` as the
No-silent-skip bullet. That bullet is at `:98`. The pointer has been twelve lines off, and the wrong
number is asserted verbatim inside `test_tamper_ledger_sync.py`, so the test holds the error in
place and `[57]` cannot see it because line 110 exists. The wave kept every edit to that file
line-count neutral on purpose, so it neither fixed the citation by accident nor moved it further out.

**One number it measured instead of subtracting.** Its share of the dist staleness is 30 rows, five
changed files across six runtime trees, derived by comparing each file rather than by subtracting
two totals taken while siblings were writing the tree. It also declined to claim `implement-and-test.md`
as its own, having proved it byte-identical to the copy taken at wave start.

### 2026-08-31, the injected laws got pinned, and law 1 turned out to be open too (E17)

The task was to pin law 5, the bullet that now carries both work-doc persistence rules. The wave
did that and then answered the question it was asked to answer honestly rather than conveniently:
is law 1's own lead pinned by anything? It is not, and it proved that instead of arguing it.

**The plant is the finding.** It rewrote law 1's mandate from "Every task that edits code opens the
step ledger" to "Some tasks may open a step checklist", left the carve-out clause untouched, and
ran everything. `[38]` stayed green, because it pins the carve-out and the carve-out sits OUTSIDE
the bold. The hook suite stayed green at 77 passing, because it asserts the same clause reaches
turn 2. The entire ledger mandate could have been reversed with every existing check reporting
healthy. Two guards, both looking at the qualifier, neither looking at the mandate.

**The de-bolding plant is the one that proves the pin does its job.** Removing the asterisks without
changing a single word reds twice, because the pin matches the bullet FORM rather than the sentence.
That is the failure that actually matters here: a de-bolded law still reads correctly in the file
and silently stops reaching every prompt after the first.

**It added a bound and wrote the number by hand.** The block's banner claims to carry the load-bearing
phase laws as a set, and that claim is only true until a sixth law lands, so it now counts the bold
leads against a hand-written 5. Written beside the pins, never read off the file, which is the
direction `00-helpers.sh` argues for in the words that a floor of 4 once sat under a set of 6 and
guarded nothing. It also used the injector's own bullet shape rather than a narrower literal, so a
law rewritten with a different bullet character is counted exactly as the injector would count it.

**Two scout zeros it refused to accept at face value.** The perf pattern's loop matcher found no
bash loop in the file because the pattern expects a paren the shell form does not carry, so its zero
came from a scan that read nothing; it ran an adapted matcher with a control that fired. The law
scanner reconciled zero paths read because it does not take `.sh` by default; it re-ran with the
extension flag and a cap control that fired. Both zeros only became evidence after the method was
shown able to return dirty.

**Staged for E24:** nothing tamper-tests fragment 76 at all, so the guard protecting all five laws
has no CI-level proof its own detection is still wired.

### 2026-08-31, the rename finished, and the wave argued the name rather than picking one (E21)

Two earlier waves each refused to start this rename, correctly: `Single-lens` is a phase NAME, and
renaming a name in one file strands every site pointing at it. This wave measured the set first,
tree-wide and case-insensitively, found exactly three name sites and all three inside its allowlist,
and only then proceeded. Six other hits were left alone, each for a stated reason: two are the
refuter's own two-lens rule, a different mechanism entirely, and three are CHANGELOG history, where
rewriting what the name was would make the record false.

**It picked `All-lens` because the doctrine already says it**, not because it read well.
`phases/phase-5-review.md` titles its route section "one merged all-lens reviewer", so the name was
already canon and the rename adopts it rather than coining a fourth spelling. It rejected
`Merged-reviewer review` for naming the agent type, which would break the next time a type is
renamed, which is precisely the failure being repaired here. And it rejected `One-reviewer review`
on the sharpest ground: stating the count while dropping what is checked retells the same lie
`Single-lens` told, only quieter, because the thing that shrank is the agent count and never the
lens coverage.

**It declined a manufactured red rather than run a meaningless one.** The obvious pin to break sits
in a fragment a sibling was rewriting at that moment, and a red from a fragment in flux proves
nothing about the file under test. It picked a different pinned literal, counted its occurrences
first because a token appearing twice will not red on a single break, and proved that one instead.

**And it handed over the gap its own fix leaves.** The name is now spelled one way at three sites
and nothing pins it, so the next reword strands two of them silently. That is E25, held until the
wave currently planting against that fragment is done.

### 2026-08-31, the map ships, and the runtime story was not what the parent said (E18, E19)

**The blocking half took one line and the proof took the rest.** `[55]` going green was never the
point; the defect was that the sync PLANNED to write the hook wiring and planned no write for the
map, so the shipped hook would have pointed at a file that was not there. The wave proved the fix
at that level, quoting the dry run now planning the map into the runtime tree beside the hook.

**It checked the trap this sprint keeps hitting and found it absent, correctly.** Nothing counts
`MIRROR_SOURCES`. The two nearby bounds are floors over what `git ls-files` discovers, so adding a
file raises the tree side and never the floor, which is the opposite direction from the failure
mode. It re-derived both live numbers anyway rather than trusting the comments beside them.

**It corrected the parent's framing of E19, and the correction changed its answer.** The parent
wrote that the other six runtimes get no map. Wrong: once the manifest entry lands, the map FILE
mirrors to five of the six. What is claude-code only is the INJECTION, because the hooks directory
ships through a claude-code-only list. So on five runtimes the map sits on disk unread, and only
`copilot-cli` gets nothing at all, since its emitter writes a manifest and never mirrors canonical
files.

**It refused the obvious edit for a countable reason.** A thirteenth primitive row with a degrade
cell would have falsified the "12 abstract primitives" count restated at three places in that file,
again in the skill and again in the README, one of which is pinned by a check specifically against
this drift. It put the map in the optional-enhancements table instead, which is that file's own home
for a mechanism no phase may hard-require, and the map qualifies by its own words.

**And it paid a grounding debt the file demands.** That table's rule is that every `n/a` cell must
be grounded in the primitive mapping above it, so six new `n/a` cells owed an explanation. The
wave wrote one, and made the honest distinction: the map is a document rather than a mechanism, so
the real degrade is the document arriving unread, and naming a substitute injector would describe
something this repo does not ship.

**One scout zero it refused to fold in.** The law scanner has no shell front end, so it reported the
helpers file as unsupported rather than clean. The wave flagged that as unscanned and applied the
semantic tier by hand instead of counting an unread file toward a zero.

### 2026-08-31, the citation that was locked in place by its own test (E23)

A check named a line of `phase-ledger.md` as the rule it enforces. The rule was twelve lines
earlier. Three mechanisms all reported healthy over it: `[57]` passes because line 110 exists, the
fragment passes because it only prints the string, and the tamper suite passes because it asserts
the wrong string verbatim. That last one is what made it a lock rather than a typo, since correcting
the fragment alone would have failed the test and read as the fix breaking something.

**The fix names the bullet, not the number**, which is the pattern this repo has now applied five
times today. The test needle moved with it, and the wave argued rather than assumed: the suite's own
docstring says the message exists to name the law a reader has to go and read, so the number was
never the subject. It also wrote that reasoning into the docstring so nobody helpfully restores a
line number later.

**The class-closed proof is the best one this sprint has produced.** Instead of asserting the fix is
durable, it took a copy of `phase-ledger.md`, inserted twenty lines above the ordering law, and
measured what happened: the bullet moved from 98 to 118, line 110 became unrelated prose, the old
pointer would now name the wrong text with `[57]` still green, and the new pointer still resolved to
exactly one match. The mechanism is that the citation carries no positional information at all, so
nothing about where the bullet sits can invalidate it, and the only edit that breaks it is renaming
the law itself, at which point a stale pointer is the correct signal.

**It paid the 500-line cap honestly.** The fragment was at exactly 500. Rather than breaching or
splitting, it reflowed an eight-line paragraph to seven with no content lost, and it compressed
BELOW line 81 on purpose because another fragment cites that line, leaving it byte-identical.

**Its manufactured red never wrote under `docs/`.** It built a throwaway git tree, planted a copy of
a real archived doc with its section 0 deleted, and proved the detection still fires and still names
a target that resolves. Then it proved it had disturbed nothing, with an md5 manifest of all 25
work-docs before and after showing exactly one difference, the parent's own live doc.

**And it found the next one.** `92-work-doc-structure.sh` cites line 81 of the fragment it just
edited for a phrase that starts on line 80. Same class, same blindness, reported not fixed. E27.

### 2026-08-31, tamper coverage for the guard that protects every injected law (E24)

18 rows, and the wave proved each one earns its place by mutation rather than by argument. It ran
seven mutation campaigns against copies of the fragment and recorded which rows went red in each,
so the suite's coverage is demonstrated rather than asserted.

**Three results from those campaigns are worth keeping.** Widening the fragment's counter from a
bold lead to any bullet leaves every reword row green and reds ONLY the five de-bolding rows, which
is the proof that the de-bolding half is not redundant with the reword half. Narrowing it the other
way, to a dash-only lead, reds exactly one row, the one covering a law rewritten with a different
bullet marker, which is the "two reds cancel into a green" failure the fragment's own comment warns
about. And replacing the hand-written 5 with a count read off the file greens the sixth-law row
while reporting "carries all 6 entries", which makes this sprint's derived-bound trap executable
instead of a story.

**Every row measures a difference, never a total.** The fragment carries five other checks over four
files these rows never touch, so each row runs it twice over one corpus, pristine then edited, and
asserts how many reds the edit ADDED. That is the direct fix for the control this sprint watched
inherit two unrelated reds and announce a working check was dead: an unrelated red sits in both
halves and subtracts out.

**It corrected the parent's fragment list.** The battery drives nine fragments, not the eight the
brief named; `[92]` was already there, its rows at the foot of another suite. The wave measured both
sources rather than trusting the dispatch, and confirmed 76 was in neither.

**It caught its own scout reporting a clean zero over nothing.** The first perf run scanned no files
at all, because zsh does not word-split an unquoted variable, and it printed a spotless result. That
is the third scout zero this round that turned out to be a scan that never ran, and the third time a
wave caught it by insisting on a control that fires.

**Answered plainly rather than conveniently:** the suite catches a pin deleted from the fragment
through the reword rows, not through the count, which still counts five leads and stays green. The
wave measured that for two different laws and said so instead of implying fuller coverage.

### 2026-08-31, the last sentence that told a round to dispatch the panel (E22, E27)

Deferred twice because no smaller allowlist could hold all six files, and the fix turned out to be
one word: `ONE reviewer panel` became `ONE review`. That keeps the cap's force exactly, because the
counted unit is a whole dispatch rather than an agent, so five panel lenses are one review and the
merged reviewer is one review and neither route can buy a second pass. It counts rounds, and it
names no route.

**Two consequential edits the wave found by reading rather than by grepping.** The lead-in beside
the sentence restated the cap in its own words and would have contradicted the corrected sentence
line for line. And a clause elsewhere said "the panel the sentence above names", which became false
the instant the sentence above stopped naming it.

**It refused a partial rewrite for the right reason.** Four other restatements still say panel, and
one of them is pinned by a fragment outside the allowlist. Rewording the three unpinned siblings and
leaving the pinned one would have left the paragraph mixing vocabularies with nothing red, which is
worse than leaving all four. Same call on a heading whose term another file depends on. Both handed
over as E28 and E29.

**The second manufactured red is the interesting one.** The wave read what the control in the other
fragment is actually FOR before breaking it, and found its job is not to guard wording at all: it
proves the ban scan below it reached the tree. So the faithful break was a stale control literal,
which is precisely the failure its own edit could have caused. Breaking it correctly silenced the
three ban checks entirely, which is the control doing its whole job.

**And it confirmed the counting warning in passing.** During the first plant the control stayed
green and simply reported reaching three files instead of four. A single-site break cannot red it.
That is the two-occurrence trap in a new costume, and it is why the second red had to hit the
literal rather than a site.

**On E27 it kept the rewrite line-neutral on purpose**, because the work-doc cites two line numbers
in the very file it was editing, and growing the header would have manufactured the same defect
class it was sent to repair.

- [ ] E68. **`[84]` does not reach `skills/hackify/references/*.md`, and those files ship shell that agents actually run.** The ban exists because this repo already paid for a SIGPIPE flake, and it scans `scripts/`, `hooks/` and three agent prompts. But `sibling-track-rules.md`, `phase-3-implementation.md` and the scout protocols all carry fenced shell an implementer executes verbatim, and the E62 wave's own first draft carried a live `head | grep -q` through a fully green bar. It caught that itself, by reading the ban rather than trusting the green. Widen `[84]`'s scan surface to the fenced shell in those files.
- [ ] E69. The database gate's quotation screen handles an alternation of several matcher tokens. A future validator pinning a SINGLE token would reappear as a false hit, and correctly so: one quoted token is genuinely indistinguishable from one used token. Worth knowing before somebody widens the screen to cover it, because that widening is what would blind it.

### 2026-09-01, the gate that matched its own quotation, and the third hit I misdiagnosed (E62)

**I framed all three false hits as escapees from one exclusion. Only two of them come from the content
search at all.** The third is caught by a FILE-NAME walk, on a path containing `migrations`, and it has
zero lines matching the pattern. Measured, not argued. So no content-side fix of any kind could have
removed it, and the single mechanism I implied would have closed two thirds of a defect while
reporting it closed. Two searches failing differently needed two answers.

**The screens fail toward keeping the row, and each drop prints its own reason.** A file is dropped as
a quotation only when EVERY matched line pairs two of the matcher's own tokens across a bare pipe, and
the quotation pattern is built FROM the matcher, so it cannot drift out of sync with the thing it
mirrors. The fixture screen needs two independent signals, a test-data path segment AND a self-label
in the file's own header, and the wave measured the label before keying on it: 16 of 17 corpus files
carry it and nothing else in the tree does.

**Its proof set is the right shape, because it tested the screens from both sides.** A genuine
`export DATABASE_URL` in a shell file is still found. A shell file carrying one pinned literal AND one
real config line is still found, which is the property that stops the screen narrowing anything. A
fixture-path file WITHOUT the self-label is still found, proving the second signal is load-bearing
rather than decorative.

**And it found a defect in its own new code that a green bar had already passed.** Its first draft used
`head -5 file | grep -q`, which is the exact short-circuit-reader shape `[84]` bans, and which this
repo has already paid for once. `[84]` passed it green, because that check does not scan
`skills/hackify/references/`. Those files ship fenced shell that implementers execute verbatim. So a
ban written for a real flake has a hole precisely where the doctrine keeps its runnable shell, and it
took an agent reading the ban rather than trusting its green to find it. Filed as E68, and it is the
most valuable thing this wave produced.

- [x] E70. Two labels this sprint's own work made stale, both handed over by the wave that caused them. `.github/workflows/ci.yml:115` names the doc-anchor suite as covering "form 4" when it now covers form 5 too, and `57-doc-links.sh`'s header and comment block describe forms 1 to 3 and never mention anchors at all. Same claim-rot class the check exists for, which is why the wave refused to leave them silent. Dispatched immediately rather than carried.
- [ ] E71. `test_doc_link_lines.py` is at 486 of 500 and `test_doc_anchors.py` at 448. The next batch of anchor rows needs a third suite file, split along the seam the code took rather than by size. Same shape as [[E65]], different files.

### 2026-09-01, the anchors are checked now, and my ambiguity rule would have been a storm (E57)

**The correction that saved the check.** I told it a phrase appearing twice in the tree is a weak
anchor. It measured before building: one cited construct appears in 13 files, another in 16. That is
NORMAL, because a cited construct gets used everywhere and the citation names the file that DEFINES
it. A tree-wide multiplicity rule would have reddened on nearly every live anchor, and a check that
reds on correct text is a check somebody weakens within a month.

What it built instead is PATH ambiguity, and it is my own argument applied properly: when a slashless
pointer could resolve to two files and more than one of them carries the anchor, a rot in the intended
one stays hidden because the other keeps answering. That is a check that greens exactly when it has
stopped working. Zero cases in the tree today, and it says so rather than implying it fires.

**"Both anchor forms are a grep away" was also not quite right.** A quoted phrase that hard-wraps in
the TARGET returns nothing from a line-based search while being perfectly present, so the checker has
to tell "the phrase moved" from "the phrase wrapped". Those want different fixes.

**Nothing had rotted.** All 17 pre-existing anchors resolve. I expected the check to red on the tree
and it did not, which is a real answer about how fast this class actually rots: today's eight repairs
were the whole of it.

**The one thing it did find was its own.** Its first live run reddened on a docstring line it had
written minutes earlier, citing a phrase with an ellipsis in the middle. An elided quote is a citation
nobody can follow, sitting in the file that defines what a followable citation is.

**And it caught the cannot-fail trap inside its own test suite.** Five of its thirteen new rows PASSED
against a tree where the feature did not exist yet, because they only asserted an exit code. It
rewrote them to assert the checked count as well and re-ran to confirm all thirteen were red first.
Fourteen mutations after that, every one killed by a named row. That is the discipline this sprint has
been trying to install, applied by an agent to its own work without being told.

- [ ] E72. Two more instances of the same understatement, found by the wave fixing the first two. `validate-dod.sh` and `validate-dod.d/README.md` both describe `[57]` as checking that links and prose paths resolve, which is two of its five forms, so the check index understates by three. And `test_doc_link_lines.py`'s own docstring says its sibling owns "form 4" when that half owns 4 and 5. The rot spread by being copied, which is the argument for describing a KIND rather than enumerating.

### 2026-09-01, the label that named the smaller half (E70)

**It found the understatement was worse than I described.** I said the CI label named form 4 while the
suite also covers form 5. The suite's own docstring calls itself "the anchor half, forms 4 and 5", and
its mutation tally is 11 for form 4 against 14 for form 5. So the label was naming the SMALLER half of
what it runs.

**It wrote no number, and removed one that was already stale.** I asked it to weigh that and its
reasoning is better than the instruction: form numbers are a count in disguise. The set went from
three to five inside this one sprint, so "forms 4 and 5" would be the identical rot with a different
spelling. Naming the two KINDS survives a sixth form landing in either half.

The fragment header took the same treatment, split the way the check actually splits rather than
listed: does the cited file resolve, and is the thing named INSIDE it really there. "Line, heading,
construct or phrase" covers three forms by kind, and a sixth needs one word rather than a renumbering.

**It kept the rewrite line-count neutral by hand, for a reason nothing would have caught.** Four other
fragments cite into that file by line, and one quotes a phrase from it as a form-5 anchor. Form 3 only
proves a cited line EXISTS, so a shift would have broken nothing visibly and left four citations
pointing at the wrong paragraph. That is the exact defect this sprint repaired eight times, avoided
this time by someone thinking about it rather than by a check.

**And it found two more instances while fixing these two.** The validator's own index and a sibling
docstring carry the same understatement, which is how the rot spread: by being copied. Filed as E72.

## 6b. Verify, evidence ledger

**Status: FINAL, re-taken 2026-09-01 after the last wave landed and after the closing sync.** The
first version of this block was provisional and said so; every number in it has now been re-taken
with nothing writing the tree. Both sets agreed, which is worth recording, but agreeing was not the
point: a mid-flight number is not evidence even when it turns out to be right.

| Acceptance bullet | Evidence | Result |
|---|---|---|
| No ban over wrapped prose can return a false green | `bash scripts/test_ban_tokens.sh` | 207 passed, 0 failed (baseline 202) |
| `[83]`'s local workaround replaced by the shared helper | full bar green on `[83]` | ok |
| Merged reviewer registered and A/B'd per lens on `9d0961e..51ecd00` | comparison table in section 6 | recorded, 16/1 against 29/4 |
| Panel-vs-merged routing rule | **superseded by Q10**, see section 3 | met, then overruled by the user |
| Quick's HTML report path | full bar | ok |
| Every `/hackify:<name>` in prose resolves | `[86]` | ok |
| All CI commands exit 0 | all **19** enumerated from `ci.yml` and run | **19 pass, 0 fail** |
| Validator stable across 30 consecutive runs | loop over `bash scripts/validate-dod.sh`, 4m10s wall | **30 exit 0, 0 non-zero** |
| Whole bar green with nothing writing | `bash scripts/validate-dod.sh` post-sync | **exit 0, 1870 ok lines, 0 FAIL** |
| Runtime trees current | `bash scripts/sync-runtimes.sh` | 818 files across 7 runtimes |

**The CI count is 19, not the 18 this doc's acceptance criteria name.** A suite was added today. The
criterion is met and its number was stale, which is the class this sprint has been repairing all day,
found one more time in our own acceptance list.

**The surprise green, resolved.** `[56]` was correctly failing on `dist/` staleness all sprint and
then cleared without me running the sync, which meant something had run it across 818 files while
waves were mid-write. That is the exact collision the instruction against it exists to prevent, so the
green was not trustworthy however good it looked. It is resolved the only way it could be: the sync
was re-run at close with nothing writing, and every number above re-taken after it. `dist/` is
generated and gitignored, so no damage could persist past a clean regeneration.

**What this verification does NOT reach**, stated because a checklist of greens invites the opposite
reading. The bar proves the checks pass; it does not prove the checks are right, and this sprint
found six that passed while unable to fail. Two of the twelve carried items are exactly that: `[84]`
does not scan the doctrine files that ship runnable shell, and a check's own index still understates
what it covers by three forms. Neither is a regression and both are written down.

## 6c. Phase 5, both instruments on this sprint's own diff

The unseen-diff half of the 2A measurement, run over 101 files / 4091 insertions that neither
instrument had read. Agent types could not be dispatched by name (this session loaded the pre-rename
roster at startup), so every reviewer read its canonical prompt from disk, which is the route the
original A/B established for the same reason and keeps the instructions under test byte-identical.

### Panel A, security and correctness: 7 findings, 0 Critical, 4 Important, 3 Minor

**It reproduced rather than reasoned, and found a real bug in code that landed today.** `[58]`, the
contradiction miner, reads each site through a pipeline inside a command substitution whose status is
discarded, so only the final grep's return code is tested. It proved this by `chmod 000` on one site
file: the check printed `ok ... P1 clean across its sites` with no error and no failure, while its
cleared count silently dropped from 10 to 9.

That contradicts the fragment's OWN contract, which says in as many words that a count of zero from a
search that errored is a count of nothing. The sibling check written the same day implements it
properly with a stderr tie-breaker. And the containment is accidental: today an unreadable file reds
62 other checks, so nothing escapes. A site no other check opens would fail open in silence.

This is the sprint's signature defect, found in the sprint's own remedy for it. Fixing it before close.

Three more Important, all the same family: the fixture screen in the database gate is a skip that
requires no claim, and both of its signals are writable by the implementer the gate constrains; form
5's live coverage has no floor, so every counter can fall to zero while printing ok, and it is the one
new checker whose number nobody pinned when three sibling checks all carry hand-written bounds; and an
unresolved possessive citation is counted but never reported, so a rename that strands prose citations
ships green.

### Panel B, quality and plan: 2 Critical, 5 Important, 3 Minor

**It refused to work around a bad dispatch, and said so first.** Three required inputs were missing
from my brief (`law_scout_report`, `task_file_index`, `metrics_table`). It built the index itself
because I told it to, then declined to file scope-creep Criticals off an index its own prompt forbids
it to infer, and counted the size metrics by hand instead. That is the right call and it is my dispatch
defect, not the reviewer's.

Critical 1 is the same defect Panel F found independently: `[58]`'s P3 predicate claims five
`agents/reviewer-*.md` files that its site list never opens, so the coverage line counts them as
examined. B went one step further and showed the live consequence: those five frontmatter descriptions
still end with the panel-as-default sentence, which is the exact not-X of the claim P3 is written to
police, and it is the defect class E39 already fixed on `agents/reviewer.md`. E5 closed this as "no
work needed" by reasoning about validator pins on the canonical files; the five agent descriptions were
never in that measurement.

Critical 2: the work-doc authorizing this sprint is untracked, and `[92]`, `[98]` and `[99]` all drive
off `git ls-files`. All three printed "all 24 tracked work-doc(s)" and never opened it. Eleven new
source files this sprint wrote are untracked too, so `[86]`'s namespace screen never read them either.
B checked by hand and found no live violation, so this is exposure rather than a landed defect, but the
three checks built to police work-doc structure are blind to their own sprint's subject.

Important, in short: the FAILED-delta control shape is now written three times, twice new today, and
the extraction target is at 500/500; `[89]` ships no standing positive control (B proved by hand it
does red); the single-mode branch E56's extraction introduced is exercised by nothing; the ledger's
item count is stale by exactly the five that landed after it was written; and AC7 says 18 CI commands
where the diff adds a 19th, with a new file re-breaking the very sentence it cites as its authority.

### Panel D, performance: 0 Critical, 2 Important, 2 Minor, and 5 scout rows judged

**Every finding carries a measured number, and it dismissed three of the five staged scout rows with
reasons.** One dismissal corrects a staging note of mine: the `basename` fork row was staged as blocked
by the 500-line cap, but the builtin substitutes in place on the same line and adds zero lines, so the
cap never blocked it. Another row was simply stale, citing a string-concat catalog ID against a line
that already appends to an array.

The two Important findings are the gate's own cost. `[87]` forks about 120 processes over the agent
roster because it rebuilds its registry on each of three judge passes, measured 0.335s against 0.012s
hoisted and batched, out of a 7.7s pre-commit run. `[58]` forks 28 greps over the routing surface where
the builtin form already ships in a sibling fragment.

It also re-measured the perf fix that landed today and found the wave's claim conservative: 0.480s to
0.013s over 252 files, and the reconcile that guards it really does red when a file goes unreadable.

### Panel F, coherence: 1 Critical, 4 Important, 2 Minor

**It found the same `[58]` coverage lie as B, from the other direction**, and named the consequence
precisely: the five files P3 claims are exactly the five still carrying panel-as-default wording, and
the honest-gap list omits them because the coverage counter already scored them. Two independent lenses
converging on one line is the strongest signal this round produced.

Its other four are seam drift from today's rename and today's file split. `[36]`'s severity check still
matches `code-reviewer-*`, so the arm is dead and its header still advertises it. The new `[58]`
fragment sits in the orchestrator index with no README paragraph, against the README's own stated rule,
and nothing enforces index-implies-README. Two prose sites say "three fragments" where the constant is
4, and one says "all 35 fragments" against a pinned 43. Both minors are citations left pointing at
`validate-dod.sh` for text that moved into the README today.

### The merged reviewer, all five lenses in one read: 1 Critical, 9 Important, 3 Minor

Per-lens: A 1/2/1, D 0/1/0, E 0/1/0, F 0/3/0, B 0/2/2. It ran **30 mutations on a full copy of the
tree** and reported six that came back GREEN, meaning six checks that did not red when they should
have. That is the half of a review no reading can produce, and it is where most of its value landed.

The six greens, each a coverage hole this sprint now knows about: an unreadable site under `[58]`;
a bare command planted in an untracked file under `[86]`; a falsified entry description under `[88]`
(self-declared, so not new); a softener planted in the CANONICAL copy of the one-review cap under
`[75f]`, where the guarded copy turns out to be the derivative one; a `[57]` form-3 citation
retargeted to a different real line in the same file; and an orphan suite left untracked under `[97]`.
Every other mutation reddened with the check named.

Its three lens-unique finds are all seam drift no single-lens reading would reach. The frozen-helper
enumeration in the new `01-presence-matchers.sh` header names eight isolation fragments where the
harness ships ten, so the whole decision about what could safely move into that file was taken over
80% of the surface. `review-scope.md` asserts the one-review cap's "wording is held identical at every
site" two lines below a site that already differs, and three wordings ship, with `SKILL.md` dropping
the refuter clause entirely. And `[75f]` guards the derivative statement of that cap rather than the
canonical one, which is E66 with its sting reversed.

It also refused cleanly on inputs: seven of the fourteen numbered inputs never arrived from me, and it
named all seven and what it substituted for each rather than reading an absent scout report as an
empty table.

### The 2A verdict: the merged reviewer did NOT clear the bar on this diff

Decision 2A required the merged reviewer to beat the panel per-lens on two diffs, one unseen. This was
the unseen one. It did not.

| Lens | Panel | Merged | Who wins |
|---|---|---|---|
| A security | 0C 4I 3M | 1C 2I 1M | **Merged.** Same headline bug, plus three more reproduced greens. |
| B quality/plan | 2C 5I 3M | 0C 2I 2M | **Panel, clearly.** Both Criticals are the panel's alone. |
| D performance | 0C 2I 2M + 5 scout rows judged | 0C 1I 0M | **Panel**, though the merged pass got no scout table from me. |
| E design | not dispatched | 0C 1I 0M | **Merged**, which never silently omits a lens. |
| F coherence | 1C 4I 2M | 0C 3I 0M | **Panel** on severity; the two found different real things. |

Totals: panel 3C / 15I / 10M across four lenses, merged 1C / 9I / 3M across five. Two of the three
Criticals are the panel's and the merged pass reached one of them only as a clause inside a coverage
note. On the pass most sensitive to depth, quality and plan, the panel found the sprint's two worst
defects and the merged pass found neither.

**The confound is mine and it is real.** My dispatch was defective for every reviewer: the merged
prompt was short seven of fourteen inputs and the panel's B was short three. The D comparison is
outright unfair, since panel D received the scout table and the merged pass did not, and judging five
staged rows is most of what that lens does. So this measurement says the merged reviewer lost on a
diff where I handicapped it, and it still won the security lens outright.

What it does NOT say is that the merged reviewer is bad. It says depth per lens falls when five lenses
share one context window, exactly where the original A/B predicted, and it says the panel's B lens is
the one that suffers most. That is a finding about shape, not about quality, and the honest read is
that decision 1C shipped the swap before the evidence supported it.

**Carrying this to the next sprint as an open question rather than closing it here.** The measurement
is only half-clean and I will not launder a defective dispatch into a verdict. Next sprint re-runs it
with all fourteen inputs supplied to both sides, on a diff neither has read, and decides then whether
the merged reviewer keeps the default seat or hands it back.

### 6e. The refuter's verdicts: 33 upheld, 1 escalated, 2 refuted

One refuter over all 35 deduped findings, per the one-round rule. It reproduced every finding whose
verdict turned on a mutation, on a full copy of the tree, and proved the source tree untouched at the
end (`git status --porcelain` 113, `git diff HEAD --stat` 101/4091/1368, no `git checkout`, `restore`,
`stash` or `reset` anywhere).

**All three Criticals survived both lenses.** None came close to dying.

**One Important escalated to Critical: I2.** `[75f]` guards the derivative statement of the one-review
cap and not the canonical one, which was already E66. The refuter found the half that makes it worse:
`75-ship-bar.sh:125-126` states as MEASURED FACT that "the clause is worded this way in exactly one
live file", and `phases/phase-5-review.md:104` falsifies it. So a check written to police claim rot
ships a false measured claim as its own scope justification, and the site that false claim excuses is
the canonical one. It reproduced the softening going green there.

**Two refuted, both correctly.** M9 (the per-prompt injection grew 1413 bytes) is a real and exactly
measured growth, but no catalog row covers context-window payload, and the reviewer reached for a
network-response ID that does not fit. M14 (no `DESIGN.md`) is a decision this user made on 2026-08-18,
and the skill scopes that file to the user's project rather than to this plugin repo.

**It settled both places the reviewers disagreed with each other**, by counting rather than by picking:
the honest `[58]` coverage number is 4 of 19, not 3, so the residual under I18 is 15 unreachable entry
points rather than 16; and the right catalog ID for the `[58]` membership loops is
`perf.process.fork-for-builtin`, because `rules/performance.md:174` routes it there in its own closing
sentence whenever a builtin replaces the fork outright.

**It corrected four citations I had transcribed, and one of my own staging notes.** The `[92]`/`[98]`/
`[99]` drivers are at `:376`, `:450` and `:401`, not the comment lines I passed along. The DRY shape at
I9 is not in `00-helpers.sh:435` at all, so that arm of the finding is wrong while the finding stands
on its two new instances. The index-implies-README rule lives in `validate-dod.sh:22`, not the README.
And M11's correction of MY staging note is itself correct: the 500-line cap never blocked that fix.

**The most useful thing it said is about my dispatch, and it is not what I expected.** The four missing
inputs cost coverage, not accuracy: not one finding in the batch is an artifact of them, because every
finding traces to a file the reviewer opened for itself. What was lost is the class of finding those
inputs alone enable. Reviewer B could not run "files touched without an authorizing task", so a
101-path diff went through this round with **no authorization audit at all**, and no reviewer re-judged
a single staged law-scout row. That gap is silent, appears nowhere in the findings, and is the reason
to re-dispatch rather than the tally.

### 6f. Decisions 10B and 11B, and the fix plan

**Q10: fix all 33, not just the Criticals.** The user chose the wide option over my recommendation of
"Criticals plus the cheap text fixes". So every finding the refuter upheld gets fixed in this sprint,
including the DRY extraction, the missing positive control, the untested branch, the cap relief, the
measured perf work and the coverage floor.

**Q11: re-run the authorization audit now, rather than carrying it.** Also wider than my
recommendation. One read-only reviewer is running the axis that never ran, with a task-file index it
builds itself, on a FROZEN copy of the diff and the work-doc so a concurrent fix wave cannot move the
ground under it. This is not a second review round: it is one lens of the first round that never got
its input, which is why it does not offend the one-round rule.

**The fix plan, three rounds, ordered by a real dependency and not by taste.**

Round 1 is solo because of I10. Three fragments sit at exactly 500 of 500 lines, and a later fix has to
ADD a helper to one of them, so the cap has to come off before anything else has room. That wave also
takes every manifest and count correction, because splitting a fragment changes the very totals those
sentences state, and fixing them in a different wave would fix them to the pre-split numbers. Its
brief tells it to recount from disk after the split rather than carry my numbers forward.

Round 2 partitions the behaviour fixes by file with no overlap: the `[58]` cluster (C1, C2, I15), the
tracked-only cluster (C3, plus `[89]`'s missing control and its untested branch), the doc-link cluster
(I1, I17, M4, M13), and the remaining perf and DRY work.

Round 3 takes the doctrine wording. I2 and I3 go to ONE agent deliberately: I2 makes `[75f]` pin the
canonical copy of the one-review cap, and I3 rewords that same canonical copy to end the three-wording
drift. Split across two agents, one would pin a token the other is rewriting, which is the exact
cross-wave break the coherence lens exists to catch.

### 6g. The authorization audit (decision 11B): 2 Critical, 5 Important, 3 Minor

The axis that never ran, re-run on a frozen copy of the diff and the work-doc so the concurrent fix
wave could not move the ground under it. It built the task-file index itself, which its own prompt
forbids, and closed by stating exactly where an index inferred from task prose cannot be trusted.
That closing section is the most useful part of the report.

**Critical A1: the sprint built the one thing its own goal anchor put Out-of-Scope, and nothing on
disk recorded the reversal.** The Non-Goals bullet excluded the doc-link content-verification check
by name. It shipped anyway, as forms 4 and 5, with a new CI command.

The audit read this as shipping against a locked answer. It is worse than that and the fault is
mine. The user DID authorize it, at Q14 (7A, "land it, take the split"), and **I never wrote that
decision down.** Checking the Q&A section against what was actually asked this session: it stopped at
Q10, and six real wizard decisions were missing from it, including the one that reversed Q5.

So three reviewers and one refuter audited this sprint's scope against a record that was missing six
of the user's own decisions, and the Non-Goals bullet contradicted the work for the rest of the
sprint. Fixed in this edit: Q11 through Q18 are now written in, and the Out-of-Scope bullet is struck
through with the original preserved and the reversal named. The Q&A section is supposed to be
verbatim; it was not, and a scope audit is worthless against a doc that under-records consent.

**Critical A2: E11's sweep is ticked and the five files a dispatcher actually reads still name the
panel as the automatic route.** Verified by hand: `phase-5-multi-review-f-coherence.md` is **not in
this diff at all**, and all five canonical lens prompts still carry "A, B, D and F each run on every
non-trivial diff", with f-coherence adding "On the panel unconditionally". The other four lens files
appear in the diff for the E41 rename hunk and nothing else.

E43 predicted this precisely: it recorded that f-coherence is the one lens file that does not name
its own agent type, so a name-driven sweep would skip it silently. E43 is ticked. Nobody went back.
This is the same defect as C2 seen from the doctrine side, so the two get fixed together by one agent
rather than split across the mirror pair.

**Important A3, A4, A5, and Minor A9: the changelog is missing four things it should carry.** No
entry for Group A, which is the sprint's first-named goal; none for the codewalk command rename that
changed the advertised spelling at 25 sites, so a user typing the old form is not told; none for the
six-agent rename, in the same release whose bullet tells users to ask for the panel by name, which is
the one instruction the rename invalidates; and none for three of six new checks.

**Important A6 and A7, and Minor A8: three places where work landed on a weak anchor rather than no
anchor.** A real behaviour rewrite of the file-size check is anchored only to a survey item whose
tick does not distinguish "staged" from "fixed"; the session-start map is new capability with no
In-Scope bullet; and `[86]` shipped a second half wider than the task that authorized it, which
forced three more files nobody's task names.

**And it corrected a finding we were about to fix wrongly.** The stale ledger count is not off by
five, it is off by sixty-five. Measured this minute: 132 backlog items, 120 ticked, 12 carried, where
the ledger said 67, 55 and 12. The carried figure matched by coincidence. My brief for I12 would have
told an implementer to write 72 and 60, both wrong. Corrected in this edit to the counted numbers.

**What it could not decide, in its own words.** E11 is the load-bearing entry and has no file list at
all, so a dozen files resolve to it and nothing else; a prose-scoped sweep task can be checked for
permission but never for completeness, and A2 is what a completeness failure looks like. It cannot
promise A2 is the only one. Fourteen tasks resolve into `docs/`, excluded by construction, so their
ticks are unverifiable here. And the decision list I handed it did not match the doc's own numbering,
which is the same defect as A1 seen from the other end.

### 6h. Fix round 1: eight of nine tasks landed, and the wave corrected the brief three times

Gate re-taken by the parent after the wave returned: `bash scripts/validate-dod.sh` exit 0, **1877 ok
lines**, ALL CHECKS PASSED. 47 fragments on disk. No file anywhere over 500 lines.

**Landed:** I10 (two thirds), I4, M7, M8, I6, M5, M6, I5.
**Not landed:** the `98-work-doc-ledger-sync.sh` third of I10, refused rather than forced.

**Three corrections to my brief, each of which changed what got built.**

I said the frozen-helper list was short by two fragments. It is short by the whole rename family:
`rename_git`, `rename_absent` and `rename_absent_all` are frozen too, and nothing in the source shows
it, because a ban-token suite sed-lifts two wrappers out of a different fragment and evals them into a
shell that has sourced `00-helpers.sh` alone. Measured with `bash -x`, not reasoned: three calls each.
That killed the obvious 91-line split.

There is also a FIFTH consumer of the isolation surface that nobody's list named, which makes
`75-ship-bar.sh` an isolation surface in its own right and pins its largest separable block in place.

And the two extra tamper fragments I flagged in I4 turn out not to change what is safe to move. The
wave checked instead of assuming, which is the right order.

**The cap relief is thin and the wave said so plainly.** `00-helpers.sh` went 500 to 480, and it named
the honest reason: after those two discoveries the genuinely free set was three symbols. The real fix
is two lines in each of five consumers, sourcing the helper files as a set instead of by name, and it
has been outside every allowlist anyone has been handed. That goes into round 2 as its own agent,
because it also unblocks the `98` split and the pinned block in `75-ship-bar.sh`.

`75-ship-bar.sh` split cleanly, 500 to 363, into two new fragments. Check IDs did not move.

**It refused the third split for a stated reason rather than forcing it.** `98` declares one check
whose entire body is an embedded Python program, driven by a tamper suite that edits five literals
inside it; any split puts at least one out of reach. It also rejected the obvious alternative of
moving the header prose into the README, because the README is now at 419 of 500 and that trades one
cap problem for another.

**On M8 it declined the fix I asked for, and it was right.** I said to substitute the recounted total
for "ran all 35 fragments". It refused: that sentence describes a past experiment, so writing today's
number into it manufactures a false claim and schedules the next restatement. It removed the count
instead, which is this repo's own doctrine in two places, and recorded that the number read 35 against
a directory of 47.

**`[36]` had been blind since the rename, and the positive control proved it.** With the arm
retargeted, stripping a required section from an agent file reds. With the old glob, the identical
plant produced zero failures and exit 0. `[89]` bans the six retired names and cannot see a retired
GLOB, which is how this survived a check written this same sprint to catch exactly this.

**I asked whether the index-implies-README rule should be enforced rather than merely stated, and it
built the check**: both directions, disk existence, floors on each side, and readers that separate
"found none" from "could not look". Three plants, three named reds, each restored byte-identically and
confirmed with `cmp` plus md5.

**Two findings it volunteered.** The README had two manifest rows interleaved, so one row's tail read
as part of the next. And the law-scout's deterministic tier reports a false clean on this repo:
`--paths-from` returned `findings: 0` with `files_scanned: 0, paths_unsupported: 14`, which is a count
of nothing wearing a clean scan's face, and its extension flag silently swallows a comma-joined list
as one literal. That is the sprint's signature defect living in the scout tooling itself.

### 6i. Fix round 2, track B: the routing sweep, finished this time

All ten files landed. `python3 scripts/sync_agent_mirrors.py` reports ten pairs ok, exit 0. The seven
fragments that police this material carry no FAIL. The only red in the tree is `dist/` staleness,
which is expected mid-round and which the parent syncs at the end.

The five agent frontmatter descriptions now lead with the routing before the intra-panel rule, so a
dispatcher reading a description is told the panel is the on-request route before it is told that A,
B, D and F all run once the panel is what runs. That is the half that misled this parent this morning.

It kept what was still true rather than deleting the sentence, which was the risk in this fix. The
intra-panel rule survives, conditioned on the panel being the round's reviewer. It also listed what it
deliberately left alone and why, which is the discipline the first sweep lacked: the design lens
carve-out, the lens-division paragraph, and every descriptive header that names the files without
making a routing claim.

**And it found a structural problem the brief did not know about.** Two release pins in
`scripts/validate-dod.d/71-release-mechanism-pins.sh`, at `:309-317` and `:468`, hold the
UN-CONDITIONED sentences in place by literal string match across eight files. The track's first pass
reddened four of five agent files because the rewrite dropped a comma. It restored the literal and
conditioned around it, which is why one heading now reads slightly oddly on purpose.

That is worth naming as a defect class of its own: **a pin that freezes a claim's exact wording
prevents that claim from being corrected.** It cannot tell "this sentence must stay true" from "this
sentence must stay verbatim", and here the verbatim reading actively resisted a fix for a claim that
had gone false. The pins should move to the conditioned form. Queued for round 3, since
`71-release-mechanism-pins.sh` is nobody's allowlist this round.

**A mistake of mine, recorded because it could have cost a wave.** Every brief this round, and round
1's, cited the implementer prompt as `phase-3-implement.md`. The file is `phase-3-implementation.md`.
Verified just now: the path I gave does not exist. Six agents were handed a dead path and none of them
stalled, because each brief inlined its own contract, but that is luck rather than design. The repo
has a check that every cited `.md` path resolves; it polices the repo's files, not the parent's
dispatch prose, and nothing checks what I hand an agent.

### 6j. Fix round 2, track F: the changelog, and four defects it found on the way past

All seven landed: A3, A4, A5, A9, M2, M3, I11.

**It verified every claim before writing a bullet, and refused to imply more than it had proved.** The
flowed-token bullet is the sprint's first-named goal and the easiest place to oversell. It probed 88
spaced ban tokens against 135 files looking for a phrase that the flattened search catches and the
line search misses, found zero, and wrote that into the bullet rather than implying a caught escape.
It reproduced the mechanism itself instead: the phrase is invisible to a line-oriented search of the
file and visible to a flattened one.

**It counted rather than transcribing, and two of the audit's numbers moved under it.** The codewalk
rename really is 25 live sites across 10 files, once the changelog's own history and an archived
work-doc are excluded. The "six-agent rename" is six agent TYPES but only five renamed files, because
the sixth never reached HEAD and shows as an untracked new file. And the audit's line numbers had
drifted by thirty in one file, which is the exact staleness class this sprint has been fixing.

**On I11 it did what the sibling fix did rather than what I said.** I said to count the CI commands
and stop asserting a maintained number. It counted 19, then wrote the sentence with no number at all,
byte-for-byte the wording its sibling was degenericized to.

**It repaired a bullet that was actively misleading**, not just added a missing one: the panel bullet
told the reader to ask for the panel by name while every one of those names had changed in the same
release.

**Four defects outside its allowlist, reported and untouched.** Two are wrong numbers in check headers
that survive their own argument. One is a **false commit attribution repeated in two files**: both
cite one hash as the commit that renamed the implementer and stranded every dispatch site, and that
hash is the FIX for that class in a different release, about a different agent. The incident is real
and the attribution is not, so it wrote the changelog bullet from the release entry and cited no hash.

The fourth is the one that matters beyond this sprint. **The perf-scout's shell loop detector reads
the English word "for" inside a quoted string as a loop header.** Reproduced on a four-line probe
containing no loop at all, which produced two loop-body rows. Over a real file whose verdict strings
say "called for $path", its depth counter runs away and it reports 66 loop-body lines with 62 nested,
in a file whose deepest actual loop is depth one. Any agent trusting that output stages dozens of
phantom candidates. That is the second scout defect found today, after round 1's false clean, and both
are the same shape: a tool that reports confidently about a scan that did not work.

**One judgment call it made and justified, which I am accepting.** Keep a Changelog wants a bare
`## [Unreleased]`; a release check parses a version out of that heading and reds when it parses
nothing. It wrote `## [0.18.0] - Unreleased`, which drops the false release date the audit objected to
and keeps the parse. That is the right trade and it offered to go further if asked.

**It also declined to rewrite a shipped measurement on a hunch**, saying it could not establish from
the diff which of two figures counted what, and that rewriting a measurement on a guess is the failure
this whole round is cleaning up after. Correct.

### 6k. Fix round 2, track C: the tracked-only blindness, closed

**Landed:** C3, I7, M1. **Not landed:** I8, blocked by a hard cap and refused rather than forced.

All three checks now enumerate tracked AND untracked files while still excluding the 855 gitignored
paths. Measured movement in the scan sets: the namespace check went from 273 files to 288, and the two
work-doc checks from 24 docs to 25. The twenty-fifth is this sprint's own work-doc, which the checks
built to police work-docs had never once opened.

**It found a second defect inside the first, and this one is the sprint's signature shape again.** The
namespace check enumerated with `git ls-files 2>/dev/null | grep -v ... || true`. That sends git's
error to `/dev/null`, then reads the PIPE's status rather than git's, then launders even that. An
enumeration that could not run arrived as an empty set and left through the same floor a genuinely
shrunken repo would, wearing the same words. Found-none and could-not-look are now separate reds.

**I asked whether the newly-sighted checks would red against the live work-doc. They do not**, and it
answered with the two ok lines rather than an assurance. It also declined to re-derive one floor,
because that bound is now measured over a corpus containing uncommitted docs whose heading counts move
while a sprint is running, so pinning it to a live number would red on ordinary authoring.

**The positive control it built for `[89]` is better than the one I asked for.** A plant carrying a
retired reviewer name would BE a real dead name on disk while it existed, so a concurrent validator run
in another track would red on it truthfully. It planted a nonsense literal at the repo root instead,
invisible to every other check, and proved the untracked half specifically: the scan with the flag
returns a hit, the scan without it returns the clean-tree face byte for byte.

**M1 resolved by making the dead function live rather than deleting it.** `[89]`'s new control calls
the one-mode wrapper, which was the option my brief left open.

**I8 is honestly unfinished and it said so.** The suite file is at exactly 500 of 500, a minimal case
is about 28 lines, and every route around it needs a file outside the allowlist. It refused to buy the
lines by deleting that file's rationale prose. What landed instead: the new `[89]` control exercises
the untested one-mode branch on every validator run, against the shipped call site rather than a
sed-lifted copy, and a mutation proves the assertion discriminates. Arguably stronger than the unit
case; it is not a unit test, and that is a decision to take rather than paper over.

**It broke eight rows of the tamper battery and proved the repair without being able to apply it.**
Confirmed by the parent just now: **189 passed, 8 failed.** All eight pin the old "tracked" wording,
so they are pins doing their job. The fix file is not in its allowlist, so it patched a shadow copy
under the scratchpad, ran that part in isolation against the real fragments, got 35 passed 0 failed,
and handed back the exact one-for-one replacements. Round 3 applies them. **The tree is red until it
does, and that is the one thing that must not be forgotten before close.**

**Five corrections to my brief.** The prompt path I gave does not exist, which is now the second track
to tell me so. The branch line number was off by twenty. "Eleven new files" is now sixteen. The
argument I cited spans a wider range than I said. And it noted, unprompted, which three of my line
numbers were RIGHT, because five had drifted and silence about the good ones would have been unhelpful.

**Three defects reported and not touched.** A doc-link checker was mid-crash from a sibling's
signature change, correctly identified as not its own. A sibling's file breached the size cap while it
worked and was shrinking again twenty minutes later. And `[40]`, the implementer rename guard, has
**zero planted controls**, which is exactly the gap it had just closed on `[89]`. Its absent half can
still print six greens from a scan that found nothing.

**One operational note that will bite the round-end run.** The law-scout needs an explicit
`--text-only-ext .sh` or it reports a clean zero over shell files it never opened. That is the third
sighting of that defect today.

### 6l. Fix round 2, track G: the thrice-written control and the fork storms

All four landed: I9, I14, I18 (verified, no code change owed), M10.

**It opened with four corrections to my brief, and the first one is the worst.** I18's target does not
exist. I told it to correct a residual count in a check header; that header goes out of its way NOT to
state one, and says why in as many words, that an unpinned number in a comment is a rotting claim. The
figure I handed over traces to the refuter's arithmetic recorded in THIS work-doc, and I passed a
number from my own notes off as a line in the code. It wrote nothing, which is the right answer.

It then counted the real residual by running the check rather than reading anyone's note: **10**, not
the 15 or 16 that had been argued over.

**The DRY shape was written three times, not four.** The refuter had already corrected one of my four
citations; a second was wrong in the other direction. One of the sites reads the counter but
deliberately does NOT swallow output or restore, because it leaves the red standing on purpose.
Converting it would have broken it. Two independent readers checked my list and both found errors in
it, which says the list was the problem.

**And the fork count was 166, not the ~120 the reviewer measured.** It explained the discrepancy
rather than just asserting a better number: a trace-based count under-reads, because trace output goes
to stderr and these controls swallow stderr. It measured with command shims that survive the swallow.

**Results.** The roster check went 0.28s to 0.05s, forks 166 to 20, output byte-identical to the
pre-change fragment. The template check went 0.66s to 0.43s, forks 286 to 141, with zero `basename`
and zero `cat` left, having taken the remaining twelve instances in the same file under the scout's
fix-in-wave rule. Every batched read carries the reconcile shape, so a short batch reds rather than
greening over files nobody opened.

**One honest gap it volunteered about its own extraction.** In the read-swallow-restore control shape,
a BROKEN restore raises the failure count with no printed line at all, because the control swallows
its judge's output. So that failure reaches CI as a bare non-zero exit with no diagnostic. Inherent to
the shape rather than new, and now written down.

**It stopped where the cap said stop.** A fourth fork storm has the same fix it just wrote, but
`00-helpers.sh` now has four lines left and that function needs nine. Duplicating it would recreate the
defect it had just removed; calling one fragment's private symbol from another would couple two checks.
So it staged the row and said so. That is the second track to hit the same wall, and both point at the
same unblocker: the five consumers that source the helper file by name.

**It also found that a scout row this sprint dispositioned as a false positive has since become
true.** The row was judged "bounded driver" when the list was pinned at four; the list is now twelve
and the bound moved with it. The judgment was correct when made and is wrong now, which is a shape
worth remembering: a dispositioned row is a claim with a shelf life.

### 6m. Fix round 2, track A: the miner, repaired in the place it was built to police

All three landed: C1, C2, I15. The fragment sits at 498 of 500 and the validator reads **1878 ok**,
one more than the round-1 baseline, which is the new invariant's own green line.

**C1 needed three signals, not one, and it measured why rather than assuming.** The obvious repair is
to read awk's exit status. On this awk a mode-000 file gives status 2 with stderr text, but **a
directory gives status 0 with stdout and stderr both empty**, which is byte-for-byte what an empty
file gives. So the classifier now reads the status, a separately captured stderr, and an end-of-input
sentinel the awk program emits, because no one of the three covers the set. The stderr file is kept
separate and never merged into stdout, following the tie-breaker its sibling check already ships.

**C2's structural half is the part that matters.** Putting the five agent files into P3's site list
fixes today's instance; a whole-table invariant now refuses ANY row that claims coverage of a path it
does not scan, so the class cannot come back. Reverting P3's sites produces five named reds, one per
unscanned file.

**Its matcher work is the best self-catch of the day.** The unanchored version it tried first took six
hits across 147 files and all six were honest prose, including P3's own authority file. The honest
sentences are conditional, the contradiction is an imperative, and the anchor is what separates them.
Then its first anchor was a bare `^`, which anchored against the line-number prefix the awk emits and
therefore matched nothing. **P3's own positive control caught that**, which is the whole argument for
positive controls in one line. It also meant an earlier tree-wide sweep of its own had been vacuous,
so it redid the sweep through the real classifier and said so.

It then noticed that a matcher with three alternations proven against one plant only proves the shape
that plant hits, and gave the control one plant per shape.

**Coverage now reads 9 of 19 honestly.** Same number the broken version printed, and every one of the
nine is now actually opened. The refuter's 4 of 19 was the honest count before the fix, not after.

**I15: 19 forks to zero**, and the loop measured 1.373s to 0.115s over 40 iterations. Its first
"before" number was a phantom, because the file under test did not exist, `source` failed silently and
the loop called an undefined function. It added a definition guard and re-measured rather than
shipping the number.

**Three things it corrected or reported.** Track 2B landed between two of its commands, so the
sentence it was told was still broken had already been fixed; its matcher correctly leaves the new
conditional wording alone. Bare `grep` in an agent shell here resolves to a ugrep shell function that
rejected its regex outright, and this fragment calls bare `grep` at three sites while the shared
helpers pin the absolute path and document why. And the deterministic law-scout tier again reported
zero findings over zero files scanned, the **fourth** sighting today of a clean result from a scan that
never ran.

### 6n. Fix round 2, track D: the citation checks, and the instruction I should not have given

All four landed: I1, I17, M4, M13. Twelve mutations, each killed by a named test row.

**It refused an instruction of mine, and it was right in a way I could not have predicted.** My brief
told it to reproduce the defect by retargeting a citation IN a file that was not on its allowlist, then
restore it. It refused, reproduced the whole thing in a scratch copy instead, and then proved the
refusal was load-bearing: while it worked, **a sibling track edited that very file**, and an
edit-and-restore in place would have silently reverted the sibling's work. It showed the `cmp` output
distinguishing the sibling's change from its own absence of one.

That is the second time today a track has been safer than its brief. I wrote a race condition into a
dispatch and only the agent's discipline caught it.

**The content check is measured, not argued.** It required a linking verb before a quoted phrase, and
it established that floor by trying the looser rule first: reading any quotation that follows a
citation gives seven reds and not one true pin, because this repo keeps defect ledgers pairing a line
number with what that site said BEFORE it was repaired. Four of the seven false alarms are that shape.
With the verb required: one green pin, one genuine red, zero false alarms. It also tried a whole-line
construct scan, checked the three sites it would have reddened by hand, and threw the rule away.

**It states its own limit plainly instead of implying coverage.** 68 of 70 live citations carry no
anchor, so for those the check still proves only that the line exists and carries something. That is
printed on the coverage line rather than smoothed away, which is exactly what was asked.

**On the fixture question it chose a self-declaring convention over a list**, because a list of paths
goes stale in silence and the next fixture is invisible again. A pointer whose basename declares
itself a probe is exempt; everything else undeclared is now a hard finding. Zero today.

**And it declined to fix the second half of M4 for a stated reason.** Form 5's unresolved bucket is
eight, all declared fixtures. Form 3's is seventy, dominated by tamper-suite literals in a dozen ad-hoc
spellings, so the same rule there would require inventing the fixture convention that I1's own
constraint forbids. Two genuinely dead citations are hiding in that bucket and it named both rather
than fixing them under a rule it had just argued against.

**Its new check immediately found five stale citations in four files it does not own**, with a
one-line repair for each, and one that needs a judgement call because the quoted text appears nowhere
in the cited file at any revision. Three of the five went stale DURING this round, as siblings shifted
lines under them, which is the citation-rot class catching itself live.

**It also found four sites whose claims its own change falsifies.** Each says some version of "the
doc-link check proves a cited line exists and never that it still says what cites it". That is now
narrower rather than false, and each needs a wording pass.

**One placement hazard worth carrying.** Five live citations pin line numbers inside the very fragment
it edited, so any insertion above a certain line shifts all five and reddens the check that documents
them. It appended its paragraph at the bottom for that reason, and wrote the reason down.

### 6o. Fix round 3, track C: the fixture screen, and a defect wider than the refuter left it

Both tasks landed. I16 closed with a third signal, and the citation re-anchored.

**The fix is one line, and it is the one signal the constrained party cannot forge.** The fixture screen
now also requires the file to be tracked and unmodified against HEAD. A track never commits, so
anything a track created or touched this round fails that test and the hit is KEPT. The path segment
and the self-label stay; they are simply no longer sufficient alone.

**It corrected the refuter, which corrected the reviewer.** I passed on the refuter's narrowing, that
the name walk is already excluded so only the content walk is self-attestable. Reading the code, that
is wrong: the zero-count exclusion sits inside the QUOTATION branch only, and a name-walk row falls
through to the fixture branch regardless. So a migrations path, the most dangerous shape this gate
hunts, could be dismissed on two self-written signals. The defect was broader than the refuter left it,
and the fix covers the wider case because the vouch sits before the label test rather than inside the
quotation branch. Three readers in sequence, each one correcting the last.

**What it rejected is as useful as what it built**, and one rejection is proved by its own situation.
Vouching the QUOTATION half the same way would have looked consistent and been wrong: one of this
tree's three real hits is a validator that quotes the matcher tokens, that file was in its own
allowlist, and it had modified it this round. Under a symmetric git vouch its own dirty file would have
turned the gate red on the round that fixed the gate. The two hits are different in kind, and it kept
hold of that: the quotation screen reads a property of the CONTENT, so it is not self-attestable and
needs no vouching.

It also rejected a committed registry of fixture paths (a track cannot extend it without writing
outside its allowlist, so a legitimate new corpus blocks the track) and rejected deleting the screen
outright (it would red this tree today, and all five tracks that ran this gate by hand today would have
gone red, which is how a gate gets rubber-stamped).

**It proved both directions.** A planted fixture-labelled file carrying a real connection string cleared
the old screen with a note and reds under the new one. All three genuine hits still clear, with the
note now naming the new evidence rather than just asserting a fixture.

**And it states the residual rather than hiding it.** The vouch asks "unmodified against HEAD" during a
sprint carrying about 4500 uncommitted lines, so a genuine fixture edited earlier in this same sprint
would start being kept until the sprint commits. That fails toward keeping, which is the safe
direction, and the escape is one skip-list line with a stated reason.

**On the citation it re-anchored both sides, not just the broken one**, because the two sit in the same
sentence and that sentence's own argument is that line numbers rot. Half-fixing it would have left a
line-numbered pointer inside a paragraph explaining why line numbers fail. It also verified the anchor
grammar against the PARSER rather than against the prose, and noted that the linking-verb rule I gave
it governs a different citation form than the one it used.

### 6p. Fix round 3, track B: the escalated Critical, closed with a position rather than a patch

All five landed. Four positive controls, each planted in the live tree, run, and restored with matching
md5s.

**It guarded every copy rather than the canonical one, and the argument is better than my question
was.** A hackify run never loads one canonical document; it loads whichever reference the phase in hand
needs, so the copy a reader reaches IS the instruction governing that run. A softener planted in it
ships whatever file the canon lives in. Canonical-only is not a weaker guard on a summary, it is no
guard at all on a live instruction. And the old design was the wrong SHAPE, not the wrong pick: had the
pin chosen the other file, the identical defect would sit where the pin used to be. A design that forces
you to name one file invites the argument that produced this escalation, and its own comment then had to
excuse the gap with a claim that was false.

The four wordings are now one sentence, byte-identical, and the file a user reads first has its dropped
refuter clause back. The guard runs per site, and a third half DISCOVERS the carriers from the tree and
compares the count against a hand-written list, so a fifth file picking the clause up reds instead of
passing unnoticed. Its fourth control proves exactly that, run in a full copy of the tree so nothing was
planted in the shared one.

**The false measured claim is gone rather than refreshed**, per this repo's own doctrine that an
unpinned number in a comment is a rotting claim. The scope is now the list, its size is asserted against
a bound, and the live answer prints on the pass lines.

**On verbatim pins it took a clear position, against the framing I offered.** Keep them verbatim. No
shell check evaluates truth, so "must stay true" has two mechanical proxies: a literal, or a measurement
re-run at check time. Where a measurement exists, measure, and it did that twice here rather than argue
for it: the softener scan EXTRACTS the sentence from the file instead of restating it, and the site set
is DISCOVERED rather than written down. Where no measurement exists, a literal is what is left, and
loosening it buys nothing, because a fuzzy pin passes the reword that changed the meaning.

Its asymmetry argument is the part worth keeping: a verbatim pin fails LOUDLY on a correct edit and the
editor moves the pin in the same commit, which is the comma incident working as designed. A loose pin
fails SILENTLY on a wrong edit and ships. For doctrine governing whether a review round can restart
itself, trading a loud false red for a silent false green is the wrong direction.

**And it named what actually blocked the correction**, which was not the literal: the pin's literal lived
in the check while the claim justifying its SCOPE lived in a comment nothing re-derives. The rule it
wrote into the file: **a pin may freeze wording; it may not also carry the scope claim in prose beside
it.** Counts and scopes get measured at run time. That seam is the whole answer, and it needed no pin
weakened.

**Two corrections to my brief.** The live wordings are four, not three: two more files state the cap in
their own words, both outside its allowlist, and it made the pinned set honestly say so rather than be
silently short. And Task 4's mechanism already exists one fragment away, in a check literally titled for
this job, which does the discovery-and-count work for the cap's OPENING sentence. It built the
equivalent where it was allowed to and wrote the relationship down, with the follow-up named: move the
discovery half next to its twin and leave the softener ban owning only the ban, which removes the one
piece of duplicated shape this wave added.

### 6q. Fix round 3, track A: the tree greened, and my "paraphrase" premise was simply false

All three tasks landed. `test_tamper_battery.py` **197 passed, 0 failed**. `check_doc_links.py` exit 0.

**It located every one of the eight tamper rows by CONTENT and confirmed each against the fragment that
now prints the new wording**, rather than applying the line numbers I handed over. It also verified the
four count constants behind the rows rather than assuming they were unchanged, and worked out from the
enumeration flags why the fixture totals stay put.

**On the one row I flagged as delicate, it measured instead of trusting the green.** That row refuses
when its tamper text does not occur, so a bad retarget fails loudly. It printed the tampered argv,
confirmed the flag and the NUL split were really removed, and showed the untampered run catching the
planted doc while the tampered run silently drops it and falls back to a smaller count. The row still
discriminates.

**My "paraphrase" premise was wrong, and it proved so from git history.** I said the quoted text in one
citation appears nowhere in the cited file at any revision, so the row must be a paraphrase. It is
verbatim, in five revisions, and it produced the revision and the line. The row is a correct historical
defect ledger of exactly the shape the citation checker's own docstring describes: a line number paired
with what that site said BEFORE it was repaired. The line number named the SITE, not the quote, and a
sibling's reword pushed the sentence down one line and left the old one blank.

So it neither repointed nor reworded. It split the row into two claims that can be judged separately:
the site, cited by a phrase that is present and machine-checked, and the pre-repair wording, kept
verbatim as history with nothing parsing it. And its first attempt at the explanatory note wrote a live
line citation into the explanation, which would have re-created the very red it was closing. It caught
that itself.

**It read the anchor grammar off the parser and found two traps.** The whole `path's "phrase"` must sit
on one physical line, or the citation lands in an unparsed bucket that nothing checks, silently; its
first draft had exactly that shape. And it noticed the old citation quoted a TRUNCATED version of the
target sentence, so quoting it back verbatim would have reddened on a truncation nobody had noticed.

**Every new anchor was proved able to go red**, by copying each target to a temp file with the phrase
reworded and re-running the real checker. A green from an anchor that could not have gone red is worth
nothing.

**It refused to write the count into three places** and pointed all three at the check's own coverage
line instead, quoting this repo's claim-integrity rule that where you can, delete the number and print
it. Then it recounted: the live split is **63 of 64 unpinned**, not the 68 of 70 I gave it. Four of the
drop is its own work and the rest moved under a sibling, which is the argument for not hardcoding it.

**It also closed two in-family sites I had not listed**, both falsified by the same round-2 widening,
and checked the insertion hazard before writing: two live line pins reach into its files and every edit
it made sits below them.

**Two corrections beyond the paraphrase.** The fifth stale pointer was not the file I named; the real
fifth was in a sibling's territory and that sibling fixed it mid-run. And the whole-tree gate cannot
reach exit 0 from inside that track, because the only remaining red is `dist/` staleness over files a
sibling is rewording, which the parent's sync repairs.

**One follow-up that matters beyond this sprint.** `scripts/validate-dod.d/README.md` is UNTRACKED. The
file-size cap check covers tracked files only, so this 422-line file sits outside it, and it would be
missing from a fresh clone entirely. That is a 319-line manifest, created by decision 4A today, that no
clone would have.

### 6r. Fix round 3, wave 2: the helpers file freed, and one task refused with proof

**Landed:** T1, T2, T4 (verdict), T5, T6. **Refused with evidence:** T3.

Parent's own re-take on the finished tree: validator **exit 0, 1887 ok lines**, tamper battery **197
passed 0 failed**, ban-token suite green, doc-link checker exit 0, **no file anywhere over 500 lines**,
and `00-helpers.sh` at **432**, up from four lines of headroom to sixty-eight.

**The frozen set was fifteen of sixteen symbols, not the nine anyone had written down.** It measured
twice and unioned, because it worked out that neither method alone is honest: a trace under-reads,
since on a clean tree the isolation fragments never execute the error printers, and a static read
misses what a sed-lift reaches. So "the frozen set is most of the file" turns out to be the true
description, and every earlier attempt at this split was working from a list that was wrong by six.

**It refused the shape my brief asked for, and the reason is the reason.** I said to change each of the
consumers to source the set. It put ONE loader in one place instead, because a glob repeated at each
consumer is the same rule written at several addresses, each free to go stale, which is the defect I
had asked it not to recreate. Only one consumer needed a real edit, and the loader FOUND that consumer
rather than the other way round: it copied a single helper file into a scratch tree, so the first run
after the loader landed failed loudly with the floor message instead of quietly lacking every helper.

The set cannot go silently short. It stops with a message and exit 1 if the glob resolves below a floor
or leaves its own pattern behind unmatched, and a blinded loop in a copy of the directory produced a
named red proving the loop is load-bearing.

**T3 refused, and it proved the blocker rather than arguing it.** The fragment total is pinned as an
EQUALITY in a file outside its allowlist, deliberately so per that pin's own comment. It created a
throwaway forty-eighth fragment, watched the ban suite fail on the count, deleted it, and confirmed
every fragment byte-identical by comparing checksums across the whole directory. Then it measured the
fallback route I told it to expect a no on and got a firm no: the prose is 86 lines and the ceiling is
72, and the README had grown under its own hand in the meantime.

So one file stays at exactly 500 with nowhere to grow. It named that as a standing risk rather than
hiding it, and identified the single line in one out-of-allowlist file that unblocks it, T4 and every
future fragment at once.

**T4 answered honestly in both directions.** The pin my brief blamed is genuinely dissolved by T1, and
it proved that. It still declined to move the check, because the destination lands on T3's blocker,
there is no cap pressure justifying it, and the file that would have to record the move is itself at
exactly 500. It measured that last one the hard way, by adding a three-line comment, watching the file
hit 503, and reverting byte-for-byte. It then corrected the README paragraph so the next reader does
not re-derive a retired reason.

**It refused a lint suppression.** Sourcing by glob raises a shellcheck warning about a non-constant
source path. It did not add a directive, because that is a suppression and this project bans them, and
it established that the linter is not a CI step and the existing baseline already warns.

**Five corrections to my brief, all measured.** There are four sourcing sites, not five; the file I
counted as the fifth drives a fragment through the harness rather than sourcing anything, and the
header I copied the miscount from had it wrong too. Two line numbers were stale and the fork count was
one pair short. The fork numbers I passed on were wrong in both terms while the timing matched exactly.
And T3 and T4 shared a blocker my brief never named, so T3 would have been refused even with a perfect
tamper interface.

Seven rows staged for a later wave, every one of them outside this wave's allowlist, including two
stale prose sites that now name the wrong home for helpers this wave moved.

## 7. Sprint Review

_Phase 4._

### Carry-over into the next sprint: making the merged reviewer earn the seat it now holds (E8)

This sprint gave the merged reviewer the default seat in every mode on decision 1C, swap now and
strengthen after. The swap is done. The strengthening is not, and the honest statement of where we
stand is that the default reviewer measured WEAKER than the thing it replaced, and shipped anyway
because the user chose speed and one report over five, with the panel kept one request away.

**The bar the next sprint has to clear, decision 2A, in the user's words.** The merged reviewer must
beat the panel per lens on two diffs, and one of the two must be a diff neither instrument has seen.
Per lens, not in total: a reviewer that wins on volume by flooding one lens has not replaced a panel,
it has replaced one member of it. And two diffs, not one, because a single diff is a sample of one
and this sprint has already watched a check pass for the wrong reason more than once.

**The two subject diffs.**

The first is `9d0961e..51ecd00`, 49 files, the diff the A/B already ran on. It is the SEEN half, and
it is worth keeping precisely because it is seen: we have the panel's 29 findings and the merged
reviewer's 16 written down per lens, so a re-run is a direct before-and-after on the same input with
no new measurement error. Its weakness is equally plain, the strengthened prompt will have been
written with these exact misses in view, so a win here proves the prompt learned this diff and
nothing more.

The second is this sprint's own diff, which neither instrument has read. Phase 5 of THIS sprint
dispatches both the panel and the merged reviewer over it, which is why the panel stayed registered
rather than being deleted: decision 2A cannot be proven against an instrument that no longer exists.
That gives the unseen half of the measurement for free, from a review round we owe the sprint anyway.

**What the strengthening has to attack, named by the A/B rather than guessed.**

The per-lens split was A 2 against 4, D 1 against 2, F 2 against 8, B 6 against 11, and completeness
5 against 4, which was the merged reviewer's only win. So the gap is not spread evenly and it is not
a vocabulary problem. Two misses carry most of it.

Its security pass missed a false green that panel A found by REPRODUCING: the panel checked out a
clean tree and ran the gate, watched it pass where it had to fail, and the merged reviewer reasoned
about the same code and concluded it was fine. That is a miss of method, not of knowledge. This
sprint already answered it, in E9 and E13: pass 1 now has to execute every gate the diff touches
against a state where it must fail, bounded to the project's own CI check surface. Whether that
answer works is exactly what the next measurement tests, and nobody should assume it did.

Its coherence pass missed a partition split that panel F traced across three files, and the shape of
that miss is that the merged reviewer never left the diff. The producer changed inside the diff and
the consumer that disagreed with it did not, so a reviewer reading only changed lines cannot see the
disagreement at all. E9's answer was the walk-out obligation: pass 4 opens the unchanged far side of
every seam or reports it UNAUDITED. The UNAUDITED escape hatch is deliberate and it is also the thing
to watch, because a pass that declares everything unaudited satisfies the letter of it.

**The one number that is not a target.** The merged reviewer's completeness pass beat the panel, 5
against 4, and that is the pass that asks what the review did not reach. Do not let the strengthening
trade it away. A reviewer that finds more and admits less is a worse instrument than the count
suggests, and this sprint's recurring defect, the check that cannot fail, is exactly what that pass
exists to catch.

**If it loses again.** Then the decision to revisit is not the prompt, it is 1C itself, and the
question to put to the user is whether one report is worth the findings it costs. Write the numbers
down and ask; do not quietly re-route to the panel, and do not quietly keep shipping the weaker
reviewer because it is already wired in.


### 7c. What ships unfinished, named rather than left implicit

Twenty-two items carry. They are written here as one list because a carry-over spread across four
sections is a carry-over nobody reads.

**The one that unblocks three others, and should go first next sprint.** The fragment total is pinned
as a deliberate EQUALITY in `scripts/test_ban_tokens.d/40-fragment-coverage.sh`, and no wave has ever
owned that file. Because of it, `98-work-doc-ledger-sync.sh` cannot split and sits at exactly 500 with
nowhere to grow, a check pinned inside the ship-bar fragment cannot move, and no new fragment can be
created at all. One line in one file, in one allowlist, clears all three.

**Two tool defects, both the sprint's signature shape, both found by agents rather than by a check.**
The law-scout's deterministic tier reports zero findings over zero files scanned unless it is handed an
explicit extension flag; four separate waves hit this today and each had to notice it themselves. And
the perf-scout's shell loop detector reads the English word "for" inside a quoted string as a loop
header, which on one real file produced 66 loop-body rows with 62 supposedly nested, in a file whose
deepest actual loop is one level. Any agent trusting either output stages phantom work or misses real
work. These are the tools every wave runs before it returns, so they matter more than their severity
suggests.

**A check with no planted control.** `[40]`, the implementer rename guard, has zero, which is exactly
the gap this sprint closed on its sibling. Its absent half can print six greens from a scan that found
nothing.

**Four stale-claim sites and one false attribution.** Two check headers carry counts that survive their
own argument; one claims a rename moved five shell files where it moved one; two files cite a commit
hash as the cause of a defect when that hash is the FIX for it, in a different release, about a
different agent. Two more prose sites now name the wrong home for helpers this sprint moved.

**Three known-narrow checks.** Bare `grep` at three sites in the contradiction miner, where the shared
helpers pin the absolute path and document why. A fork-per-item loop in the plugin-map check, two
functions away from the one that was fixed, needing one line. And a duplicated membership counter in
the roster check, now that the shared version exists.

**And the measurement this sprint owes.** The merged reviewer did not clear decision 2A's bar on the
unseen diff, and the run that showed it was handicapped by a dispatch missing seven of fourteen inputs.
A clean re-measurement, both instruments fully supplied, on a diff neither has read, is the first job
next sprint. Until it happens the default routing is running ahead of its evidence, and this release
says so in its own changelog rather than waiting to be asked.

### 7b. Final evidence ledger, taken at release

Every number below was re-taken by the parent on the finished tree after the last fix wave and after
`bash scripts/sync-runtimes.sh`. Nothing here is carried forward from an earlier phase.

| What | Command | Result |
|---|---|---|
| The bar | `bash scripts/validate-dod.sh` | **exit 0**, ALL CHECKS PASSED, **1887 ok lines** |
| Tamper battery | `python3 scripts/test_tamper_battery.py` | **197 passed, 0 failed** |
| Ban-token suite | `bash scripts/test_ban_tokens.sh` | **ALL BAN-TOKEN TAMPER TESTS PASSED** (207) |
| Doc links | `python3 scripts/check_doc_links.py .` | **exit 0**, 121 files, 64 citations, 31 anchors |
| Size caps | `wc -l` over every shipped `.sh`, `.py`, `.md`, `.yml` | **no file over 500 lines** |
| Runtime mirrors | `bash scripts/sync-runtimes.sh` | 818 files across 7 runtimes, exit 0 |
| Diff | `git diff HEAD --stat` | 105 files changed, 5005 insertions, 1782 deletions |

**The headroom number that matters, because three separate waves were blocked on it.**
`scripts/validate-dod.d/00-helpers.sh` went 500, then 480, then 496, and finally **432**. It has 68
lines of room where this morning it had none, and the reason is that the four commands sourcing it by
name now take the whole helper set from one loader.

**What this evidence does NOT reach, stated because a table of greens invites the opposite reading.**

The bar proves the checks pass. It does not prove the checks are right, and this sprint found **eleven**
that passed while unable to fail: six during implementation, and five more during the review round,
including two inside the check written that same day to catch exactly this class.

Two things are green here that were red for a real reason and are worth naming rather than burying.
`98-work-doc-ledger-sync.sh` sits at exactly 500 with nowhere to grow, blocked by a hand-written
fragment total in a file no wave has owned; the wave that hit it proved the blocker by planting a
forty-eighth fragment and watching the count fail, then removed it and verified the directory
byte-identical. And `scripts/validate-dod.d/README.md`, the 428-line manifest this sprint created, is
UNTRACKED, so the size-cap check has never seen it and a fresh clone would not have it at all. It is
staged in this release's commit, which is the fix.

The 30-consecutive-run stability figure recorded at Verify was taken before roughly sixty files
changed under it. It has not been re-taken and should not be read as current.

## 8. Retrospective

### Citations that point at a line number, and what an anchor convention would cost (T24)

The sprint hit this defect four separate times, which is what makes it worth writing down rather
than fixing one more time.

`[82g]` shipped with three of four pin anchors stale. Check `[57]` verifies that a cited
`path:line` names a line **that exists**, never that the line still says what the pointer claims,
so a stale-but-in-range number passes silently. `56-dist-integrity.sh` cited the orchestrator's
`set -u` at `:149` when it had moved to `:221`. Two comments cited `pipefail` at `:186` when it
was at `:200`, and by the end of this sprint it had moved again, to `:221`. Every one of these was
correct when written.

**What an anchor-text convention would require.** Instead of `file.md:245`, a citation carries a
short verbatim phrase from the line it means, and the checker resolves it by searching. Three
things follow. The phrase has to be unique in the file, so the checker needs a uniqueness rule
and a red when a phrase matches twice. The search has to be wrap-aware, because markdown here is
wrapped and a phrase spanning two physical lines returns nothing to a line-oriented matcher; this
sprint already built that matcher, so the machinery exists. And the phrase becomes load-bearing
text: editing the sentence it quotes now breaks a citation, which is the point, but it means
prose edits start reddening the build in a way they do not today.

**What it would cost to migrate.** `check_doc_links.py` currently resolves 51 `path:line`
citations under `CITE_SCAN_ROOTS`. Each one needs a human to open the target, choose a phrase that
is unique and unlikely to be reworded, and rewrite the citation. That is the whole cost, and it is
not automatable: picking a durable anchor is a judgment about which words carry the meaning.

**The recommendation, and it is not a full migration.** Keep line numbers where the target is
code, because code moves with its callers and a line number is honest about being a snapshot.
Move to anchors only where the target is DOCTRINE PROSE that other files pin, which is the case
that actually rotted here four times. And strengthen `[57]` first, so a stale citation reddens
instead of passing: that alone converts a silent class into a loud one, at a fraction of the
migration cost, and it tells us how many are stale before deciding whether the migration is worth
it. A previous wave in this sprint was asked to make that call and its answer is recorded with it.

### Three process failures worth more than the defects they caused (T46, T50, T51)

**I measured the wrong tree, and the error was contagious (T46).** The `metrics_table` I built for
the reviewer A/B ran `wc -l` over the working copy instead of the commit under review, so
`00-helpers.sh` was reported at 492 when it was 374 at `51ecd00`. Reviewer B caught it, re-measured
49 files and 80 bash functions by hand, and reported it rather than using the numbers quietly. It
then propagated: two later findings inherited the contaminated figures and the refuter had to
correct both. **The rule: a review of a commit is measured against that commit.** Build every input
from `git show <sha>:path` or a clean worktree, never from the checkout you are standing in,
because the tree you are standing in is the one you have been editing all day.

**Every agent I dispatched was running last release's rulebook (T50).** The registered
`hackify:implementer` type takes its prompt from the INSTALLED plugin, and the newest installed
version is 0.17.2 while this repo is 0.18.0. The installed contract still names the retired
`test-first` mode 6 times; the repo names it 0 times, and check `[82e]` now bans it repo-wide. So
every wave this sprint was handed doctrine one release behind the tree it was editing, and the only
reason nothing reddened is that the waves read the live files instead of trusting their own
prompts. One said so explicitly. **The rule: when a wave edits the plugin's own doctrine, the brief
must say that the agent's own contract is a stale copy and the tree is authority.** This is a
hazard specific to a plugin that edits itself, and it will recur every sprint until the installed
copy tracks the source.

**`phase-3-implementation.md` is at exactly 500 of 500 (T51).** Second sprint running into this
file's cap; the last one landed at 499 and this one spent the final line. The next edit needing a
line there must delete one first, which is not a sustainable way to hold a contract that keeps
gaining clauses. It should split, and the seam that suggests itself is the same one the helpers
file just took: the mode-specific clauses (`test-authoring` and its conditional assumptions) are a
distinct concern from the wave contract that carries them. Recorded rather than done, because a
mirror-pair split touches the registry and this sprint is already large.

_Phase 6._

## Update log

**Problem**
A phrase this plugin bans could hide inside a line break and the check screening for it would report the file clean. A `Co-Authored-By: Claude` trailer split across two lines walked straight through the guard on AI credit lines.

**Root cause**
The screen looked for the phrase on one line, and the files it reads are wrapped to a column.

**Solution**
Every ban list flattens the line breaks first now, and each is planted with the wording it forbids and watched going red.

**Verification evidence**
`bash scripts/test_ban_tokens.sh` returns ALL BAN-TOKEN TAMPER TESTS PASSED at 207 checks, up from 202, and the wrapped trailer the old screen missed is caught.

**Deployment status**
Live in 0.18.0, released today.

----

**Problem**
Code review used to send five reviewers at one change and hand back five reports. One reviewer covering every angle costs less and reads better, but nobody had measured whether one can.

**Root cause**
The swap was a call about cost and readability, made before the evidence supported it.

**Solution**
Review sends one reviewer that reads the change once and covers every angle. The five specialists stay available by name.

**Verification evidence**
Both ran head to head twice and the single reviewer lost both. On a 49-file change the five found 29 problems including 4 serious, against 16 including 1. On a 101-file change neither had seen, the five found 3 serious, 15 important and 10 minor, against 1, 9 and 3. That run also gave it only 7 of its 14 inputs, a fault on our side.

**Deployment status**
Shipped as the default in 0.18.0 today, shortfall and all, and the release notes say so. A clean re-measurement is next release's first job.

----

**Problem**
Two things you type changed: the walkthrough advertised `/codewalk`, which it does not answer to, and all six reviewers you request by name were renamed.

**Root cause**
The bare spelling sat in 25 places across 10 files, and nothing could tell a finished rename from a half-finished one.

**Solution**
Type `/hackify:codewalk` now, and the reviewers are `hackify:reviewer` plus `reviewer-security`, `reviewer-quality-plan`, `reviewer-performance`, `reviewer-coherence` and `reviewer-design`. Two new checks keep both honest: one reads every command in the docs, the other sweeps the tree for dead names.

**Verification evidence**
The command check found six wrong spellings on its first run where two were expected, and the full gate reports ALL CHECKS PASSED at 1887 ok lines.

**Deployment status**
Live in 0.18.0 today; the release notes pair old names with new.

----

**Problem**
A fresh conversation did not know this plugin was there until something triggered it, so several features went unadvertised all session.

**Root cause**
Nothing greeted a new session. The plugin spoke up only once you had already triggered something.

**Solution**
A short map now loads at the start of a session, listing what ships and when each piece is right, and pointing at the standing rules rather than restating them. Rules about keeping a task's notes current joined that always-on set too, since they were fading just where they mattered.

**Verification evidence**
A fresh session with every file-reading tool off quoted the map's title and a row back; without the map the same question returned NO MAP.

**Deployment status**
Live in 0.18.0 today for Claude Code, the only runtime with a start-of-session hook; five of the other six get the file without it.

----

**Problem**
A green run did not mean the checks were right. This release found eleven checks passing while unable to ever fail, plus many pointers between documents aimed at the wrong text.

**Root cause**
A check that scans nothing reports the same clean zero as one that scans everything, and a pointer to a line number only proved the line exists.

**Solution**
All eleven are closed, found-nothing and could-not-look are separate failures now, and a pointer names a heading or a quoted sentence resolved inside the file it cites.

**Verification evidence**
`python3 scripts/test_tamper_battery.py` returns 197 passed, 0 failed, and `python3 scripts/check_doc_links.py .` exits 0 over 121 files, 64 citations and 31 anchors. The review that found five of the eleven ran 30 deliberate breaks and reported the six that stayed green.

**Deployment status**
Live in 0.18.0 today. Two more of the same shape are open work for next release.
